package main

// Cloudflare DNS management for remote.openflix.io subdomains.
// Used to:
//  1. Upsert A records: <machineId>.remote.openflix.io → publicIp (on heartbeat)
//  2. Set TXT records: _acme-challenge.<machineId>.remote.openflix.io (ACME DNS-01)
//  3. Delete TXT records after ACME challenge completes

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"
)

const cfAPIBase = "https://api.cloudflare.com/client/v4"

var (
	cfAPIToken   string // CF_API_TOKEN env var
	cfZoneID     string // CF_ZONE_ID env var — zone ID for openflix.io
	remoteDomain string // REMOTE_DOMAIN env var, default "remote.openflix.io"
)

func initCloudflare() {
	cfAPIToken = os.Getenv("CF_API_TOKEN")
	cfZoneID = os.Getenv("CF_ZONE_ID")
	remoteDomain = os.Getenv("REMOTE_DOMAIN")
	if remoteDomain == "" {
		remoteDomain = "remote.openflix.io"
	}
	if cfAPIToken == "" || cfZoneID == "" {
		log.Println("INFO: CF_API_TOKEN or CF_ZONE_ID not set — DNS management disabled")
	} else {
		log.Printf("INFO: Cloudflare DNS enabled for zone %s domain %s", cfZoneID, remoteDomain)
	}
}

func cfEnabled() bool {
	return cfAPIToken != "" && cfZoneID != ""
}

// cfRequest executes a Cloudflare API request and returns the response body.
func cfRequest(method, path string, body any) ([]byte, int, error) {
	var bodyReader io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return nil, 0, fmt.Errorf("marshal: %w", err)
		}
		bodyReader = bytes.NewReader(b)
	}

	req, err := http.NewRequest(method, cfAPIBase+path, bodyReader)
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("Authorization", "Bearer "+cfAPIToken)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	return data, resp.StatusCode, nil
}

// cfFindRecord returns the ID of an existing DNS record by type + name, or "".
func cfFindRecord(recType, name string) (string, error) {
	data, _, err := cfRequest("GET",
		fmt.Sprintf("/zones/%s/dns_records?type=%s&name=%s", cfZoneID, recType, name),
		nil)
	if err != nil {
		return "", err
	}
	var resp struct {
		Result []struct {
			ID string `json:"id"`
		} `json:"result"`
	}
	if err := json.Unmarshal(data, &resp); err != nil {
		return "", err
	}
	if len(resp.Result) > 0 {
		return resp.Result[0].ID, nil
	}
	return "", nil
}

// UpsertARecord creates or updates an A record for <machineId>.remote.openflix.io.
func UpsertARecord(machineID, publicIP string) {
	if !cfEnabled() {
		return
	}
	name := machineID + "." + remoteDomain
	payload := map[string]any{
		"type":    "A",
		"name":    name,
		"content": publicIP,
		"ttl":     60,
		"proxied": false,
	}

	existing, err := cfFindRecord("A", name)
	if err != nil {
		log.Printf("CF: find A record error for %s: %v", name, err)
		return
	}

	if existing != "" {
		_, status, err := cfRequest("PUT",
			fmt.Sprintf("/zones/%s/dns_records/%s", cfZoneID, existing),
			payload)
		if err != nil || status >= 300 {
			log.Printf("CF: update A record %s → %s failed (status %d): %v", name, publicIP, status, err)
		} else {
			log.Printf("CF: updated A record %s → %s", name, publicIP)
		}
	} else {
		_, status, err := cfRequest("POST",
			fmt.Sprintf("/zones/%s/dns_records", cfZoneID),
			payload)
		if err != nil || status >= 300 {
			log.Printf("CF: create A record %s → %s failed (status %d): %v", name, publicIP, status, err)
		} else {
			log.Printf("CF: created A record %s → %s", name, publicIP)
		}
	}
}

// AddTXTRecord creates a TXT record for ACME DNS-01 challenge.
// Returns the record ID (needed to delete it later).
func AddTXTRecord(machineID, txtValue string) (string, error) {
	if !cfEnabled() {
		return "", fmt.Errorf("cloudflare not configured")
	}
	name := "_acme-challenge." + machineID + "." + remoteDomain
	payload := map[string]any{
		"type":    "TXT",
		"name":    name,
		"content": txtValue,
		"ttl":     60,
	}
	data, status, err := cfRequest("POST",
		fmt.Sprintf("/zones/%s/dns_records", cfZoneID),
		payload)
	if err != nil {
		return "", err
	}
	if status >= 300 {
		return "", fmt.Errorf("cloudflare error %d: %s", status, string(data))
	}
	var resp struct {
		Result struct {
			ID string `json:"id"`
		} `json:"result"`
	}
	if err := json.Unmarshal(data, &resp); err != nil {
		return "", err
	}
	log.Printf("CF: added TXT %s = %s (id=%s)", name, txtValue, resp.Result.ID)
	return resp.Result.ID, nil
}

// DeleteTXTRecord removes a DNS record by ID.
func DeleteTXTRecord(recordID string) error {
	if !cfEnabled() {
		return fmt.Errorf("cloudflare not configured")
	}
	_, status, err := cfRequest("DELETE",
		fmt.Sprintf("/zones/%s/dns_records/%s", cfZoneID, recordID),
		nil)
	if err != nil {
		return err
	}
	if status >= 300 {
		return fmt.Errorf("cloudflare delete error %d", status)
	}
	log.Printf("CF: deleted DNS record %s", recordID)
	return nil
}

// RemoteDomainFor returns the full subdomain for a machineId.
func RemoteDomainFor(machineID string) string {
	return machineID + "." + remoteDomain
}
