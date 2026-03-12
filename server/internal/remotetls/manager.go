// Package remotetls provisions and renews a Let's Encrypt certificate for
// <machineId>.remote.openflix.io using ACME DNS-01 challenge.
// The certificate is stored in /data/tls/ and an HTTPS listener is started
// on :32443 alongside the existing HTTP server on :32400.
package remotetls

import (
	"bytes"
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

	"golang.org/x/crypto/acme"
)

const (
	acmeStagingURL     = "https://acme-staging-v02.api.letsencrypt.org/directory"
	acmeProductionURL  = "https://acme-v02.api.letsencrypt.org/directory"
	httpsPort          = ":32443"
	certRenewBefore    = 30 * 24 * time.Hour // renew when < 30 days left
	dnsPropagationWait = 30 * time.Second
)

// Manager handles TLS certificate provisioning and HTTPS serving.
type Manager struct {
	mu           sync.RWMutex
	machineID    string
	domain       string // e.g. abc123.remote.openflix.io
	registryURL  string // e.g. https://discover.openflix.io
	dataDir      string // e.g. /data/tls
	staging      bool   // use Let's Encrypt staging for testing
	tlsConfig    *tls.Config
	certExpiry   time.Time
	enabled      bool
	listener     net.Listener
	runCancel    context.CancelFunc
	provisioning bool
	handler      http.Handler
	onReady      func(httpsURL string) // called when HTTPS is ready with the full URL
}

// New creates a Manager. Call Enable() to start provisioning.
func New(machineID, domain, registryURL, dataDir string, staging bool, handler http.Handler) *Manager {
	return &Manager{
		machineID:   machineID,
		domain:      domain,
		registryURL: registryURL,
		dataDir:     dataDir,
		staging:     staging,
		handler:     handler,
	}
}

// SetOnReady sets a callback that is invoked with the HTTPS URL once the
// cert is provisioned and the listener is up. Use this to update the cloud
// registry so clients connect via HTTPS instead of plain HTTP.
func (m *Manager) SetOnReady(fn func(httpsURL string)) {
	m.mu.Lock()
	m.onReady = fn
	m.mu.Unlock()
}

// Status describes the current remote access state.
type Status struct {
	Enabled    bool      `json:"enabled"`
	Domain     string    `json:"domain"`
	URL        string    `json:"url"`
	CertExpiry time.Time `json:"certExpiry,omitempty"`
	HasCert    bool      `json:"hasCert"`
}

func (m *Manager) certPath() string { return filepath.Join(m.dataDir, "cert.pem") }
func (m *Manager) keyPath() string  { return filepath.Join(m.dataDir, "key.pem") }
func (m *Manager) acctPath() string { return filepath.Join(m.dataDir, "acme-account.key") }

// Enable starts the remote access HTTPS server. If a valid cert already exists
// it is loaded immediately; otherwise provisioning runs in the background.
func (m *Manager) Enable(ctx context.Context) error {
	m.mu.Lock()
	if m.enabled {
		m.mu.Unlock()
		return nil
	}
	runCtx, runCancel := context.WithCancel(context.Background())
	m.enabled = true
	m.runCancel = runCancel
	m.mu.Unlock()

	if err := os.MkdirAll(m.dataDir, 0700); err != nil {
		runCancel()
		m.mu.Lock()
		m.enabled = false
		m.runCancel = nil
		m.mu.Unlock()
		return fmt.Errorf("create tls dir: %w", err)
	}

	// Try loading existing cert first.
	if cert, expiry, err := m.loadCert(); err == nil && time.Until(expiry) > certRenewBefore {
		log.Printf("[TLS] Loaded existing cert for %s (expires %s)", m.domain, expiry.Format("2006-01-02"))
		m.mu.Lock()
		m.tlsConfig = &tls.Config{Certificates: []tls.Certificate{cert}}
		m.certExpiry = expiry
		m.mu.Unlock()
		go m.startHTTPS()
		go m.renewLoop(runCtx)
		return nil
	}

	// No valid cert — provision in background so Enable() returns quickly.
	go func() {
		m.mu.Lock()
		m.provisioning = true
		m.mu.Unlock()
		defer func() {
			m.mu.Lock()
			m.provisioning = false
			m.mu.Unlock()
		}()

		if err := m.provision(runCtx); err != nil {
			log.Printf("[TLS] Provisioning failed: %v", err)
			return
		}
		if runCtx.Err() != nil {
			return
		}
		m.startHTTPS()
		go m.renewLoop(runCtx)
	}()
	return nil
}

// Disable stops the HTTPS listener.
func (m *Manager) Disable() {
	m.mu.Lock()
	m.enabled = false
	l := m.listener
	m.listener = nil
	cancel := m.runCancel
	m.runCancel = nil
	m.mu.Unlock()
	if cancel != nil {
		cancel()
	}
	if l != nil {
		l.Close()
	}
}

// GetStatus returns current state.
func (m *Manager) GetStatus() Status {
	m.mu.RLock()
	defer m.mu.RUnlock()
	s := Status{
		Enabled:    m.enabled,
		Domain:     m.domain,
		HasCert:    m.tlsConfig != nil,
		CertExpiry: m.certExpiry,
	}
	if s.HasCert {
		s.URL = "https://" + m.domain + ":32443"
	}
	return s
}

// provision runs the full ACME DNS-01 flow to get a new certificate.
func (m *Manager) provision(ctx context.Context) error {
	log.Printf("[TLS] Provisioning cert for %s", m.domain)

	acctKey, err := m.loadOrCreateAccountKey()
	if err != nil {
		return fmt.Errorf("account key: %w", err)
	}

	directoryURL := acmeProductionURL
	if m.staging {
		directoryURL = acmeStagingURL
	}

	client := &acme.Client{
		Key:          acctKey,
		DirectoryURL: directoryURL,
	}

	// Register or fetch existing account.
	acct := &acme.Account{}
	if _, err := client.Register(ctx, acct, acme.AcceptTOS); err != nil {
		// If already registered, GetReg fetches the existing account.
		if _, err2 := client.GetReg(ctx, ""); err2 != nil {
			return fmt.Errorf("acme register: %w", err)
		}
	}

	// Create order.
	order, err := client.AuthorizeOrder(ctx, acme.DomainIDs(m.domain))
	if err != nil {
		return fmt.Errorf("authorize order: %w", err)
	}

	// Process authorizations.
	for _, authzURL := range order.AuthzURLs {
		authz, err := client.GetAuthorization(ctx, authzURL)
		if err != nil {
			return fmt.Errorf("get authz: %w", err)
		}
		if authz.Status == "valid" {
			continue
		}

		// Find DNS-01 challenge.
		var chal *acme.Challenge
		for _, c := range authz.Challenges {
			if c.Type == "dns-01" {
				chal = c
				break
			}
		}
		if chal == nil {
			return fmt.Errorf("no dns-01 challenge for %s", authz.Identifier.Value)
		}

		txtValue, err := client.DNS01ChallengeRecord(chal.Token)
		if err != nil {
			return fmt.Errorf("dns01 record: %w", err)
		}

		// Set TXT record via registry.
		recordID, err := m.setDNSChallenge(ctx, txtValue)
		if err != nil {
			return fmt.Errorf("set dns challenge: %w", err)
		}
		defer m.deleteDNSChallenge(ctx, recordID) //nolint:errcheck

		// Wait for DNS propagation.
		log.Printf("[TLS] Waiting %s for DNS propagation...", dnsPropagationWait)
		select {
		case <-time.After(dnsPropagationWait):
		case <-ctx.Done():
			return ctx.Err()
		}

		// Accept challenge.
		if _, err := client.Accept(ctx, chal); err != nil {
			return fmt.Errorf("accept challenge: %w", err)
		}

		// Poll for authorization to become valid.
		for {
			authz, err = client.GetAuthorization(ctx, authzURL)
			if err != nil {
				return fmt.Errorf("poll authz: %w", err)
			}
			if authz.Status == "valid" {
				break
			}
			if authz.Status == "invalid" {
				return fmt.Errorf("authorization invalid for %s", authz.Identifier.Value)
			}
			select {
			case <-time.After(3 * time.Second):
			case <-ctx.Done():
				return ctx.Err()
			}
		}
	}

	// Generate certificate key.
	certKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return fmt.Errorf("gen cert key: %w", err)
	}

	csr, err := x509.CreateCertificateRequest(rand.Reader, &x509.CertificateRequest{
		Subject:  pkix.Name{CommonName: m.domain},
		DNSNames: []string{m.domain},
	}, certKey)
	if err != nil {
		return fmt.Errorf("create csr: %w", err)
	}

	// Finalize order.
	der, _, err := client.CreateOrderCert(ctx, order.FinalizeURL, csr, true)
	if err != nil {
		return fmt.Errorf("create cert: %w", err)
	}

	// Save cert + key.
	if err := m.saveCert(der, certKey); err != nil {
		return fmt.Errorf("save cert: %w", err)
	}

	cert, expiry, err := m.loadCert()
	if err != nil {
		return fmt.Errorf("reload cert: %w", err)
	}

	m.mu.Lock()
	m.tlsConfig = &tls.Config{Certificates: []tls.Certificate{cert}}
	m.certExpiry = expiry
	m.mu.Unlock()

	log.Printf("[TLS] Cert provisioned for %s (expires %s)", m.domain, expiry.Format("2006-01-02"))
	return nil
}

// renewLoop checks every 12 hours and renews if within certRenewBefore of expiry.
func (m *Manager) renewLoop(ctx context.Context) {
	ticker := time.NewTicker(12 * time.Hour)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			m.mu.RLock()
			needsRenew := m.enabled && time.Until(m.certExpiry) < certRenewBefore
			m.mu.RUnlock()
			if needsRenew {
				log.Printf("[TLS] Renewing cert for %s", m.domain)
				if err := m.provision(ctx); err != nil {
					log.Printf("[TLS] Renewal failed: %v", err)
				}
			}
		case <-ctx.Done():
			return
		}
	}
}

// startHTTPS starts the HTTPS listener on :32443.
func (m *Manager) startHTTPS() {
	m.mu.RLock()
	if !m.enabled || m.listener != nil {
		m.mu.RUnlock()
		return
	}
	tlsCfg := m.tlsConfig
	m.mu.RUnlock()
	if tlsCfg == nil {
		log.Printf("[TLS] Cannot start HTTPS: no cert loaded")
		return
	}

	ln, err := tls.Listen("tcp", httpsPort, tlsCfg)
	if err != nil {
		log.Printf("[TLS] Listen %s error: %v", httpsPort, err)
		return
	}
	m.mu.Lock()
	m.listener = ln
	cb := m.onReady
	m.mu.Unlock()

	log.Printf("[TLS] HTTPS listening on %s for %s", httpsPort, m.domain)
	if cb != nil {
		cb("https://" + m.domain + ":32443")
	}
	srv := &http.Server{Handler: m.handler}
	if err := srv.Serve(ln); err != nil && m.enabled {
		log.Printf("[TLS] HTTPS server stopped: %v", err)
	}
}

// setDNSChallenge calls the registry to add the ACME TXT record.
func (m *Manager) setDNSChallenge(ctx context.Context, txtValue string) (string, error) {
	body, _ := json.Marshal(map[string]string{
		"machineId": m.machineID,
		"txtValue":  txtValue,
	})
	req, err := http.NewRequestWithContext(ctx, "POST", m.registryURL+"/dns-challenge", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("registry dns-challenge status %d", resp.StatusCode)
	}
	var result struct {
		RecordID string `json:"recordId"`
	}
	json.NewDecoder(resp.Body).Decode(&result) //nolint:errcheck
	return result.RecordID, nil
}

// deleteDNSChallenge removes the ACME TXT record via the registry.
func (m *Manager) deleteDNSChallenge(ctx context.Context, recordID string) error {
	body, _ := json.Marshal(map[string]string{"recordId": recordID})
	req, err := http.NewRequestWithContext(ctx, "DELETE", m.registryURL+"/dns-challenge", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	resp.Body.Close()
	return nil
}

// loadOrCreateAccountKey loads the ACME account private key or generates a new one.
func (m *Manager) loadOrCreateAccountKey() (*ecdsa.PrivateKey, error) {
	data, err := os.ReadFile(m.acctPath())
	if err == nil {
		block, _ := pem.Decode(data)
		if block != nil {
			key, err := x509.ParseECPrivateKey(block.Bytes)
			if err == nil {
				return key, nil
			}
		}
	}
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, err
	}
	der, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		return nil, err
	}
	pemData := pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: der})
	os.WriteFile(m.acctPath(), pemData, 0600) //nolint:errcheck
	return key, nil
}

// saveCert writes cert chain and private key PEM files.
func (m *Manager) saveCert(der [][]byte, key *ecdsa.PrivateKey) error {
	// Write cert chain.
	var certBuf bytes.Buffer
	for _, d := range der {
		pem.Encode(&certBuf, &pem.Block{Type: "CERTIFICATE", Bytes: d}) //nolint:errcheck
	}
	if err := os.WriteFile(m.certPath(), certBuf.Bytes(), 0600); err != nil {
		return err
	}
	// Write private key.
	keyDER, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		return err
	}
	keyPEM := pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: keyDER})
	return os.WriteFile(m.keyPath(), keyPEM, 0600)
}

// loadCert reads cert.pem + key.pem and returns the tls.Certificate and expiry.
func (m *Manager) loadCert() (tls.Certificate, time.Time, error) {
	cert, err := tls.LoadX509KeyPair(m.certPath(), m.keyPath())
	if err != nil {
		return tls.Certificate{}, time.Time{}, err
	}
	// Parse first cert for expiry.
	leaf, err := x509.ParseCertificate(cert.Certificate[0])
	if err != nil {
		return tls.Certificate{}, time.Time{}, err
	}
	return cert, leaf.NotAfter, nil
}
