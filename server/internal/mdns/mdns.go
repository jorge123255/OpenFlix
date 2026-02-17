package mdns

import (
	"context"
	"encoding/binary"
	"fmt"
	"net"
	"os"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

const (
	mdnsAddr      = "224.0.0.251:5353"
	mdnsPort      = 5353
	defaultTTL    = 120 // seconds
	goodbyeTTL    = 0
	dnsTypeA      = 1
	dnsTypePTR    = 12
	dnsTypeTXT    = 16
	dnsTypeSRV    = 33
	dnsTypeANY    = 255
	dnsClassIN    = 1
	dnsClassFlush = 0x8001 // Cache flush + IN class
)

// Service is an mDNS service advertiser that responds to queries for
// _openflix._tcp.local. with SRV, TXT, and A records.
type Service struct {
	name        string
	serviceType string
	domain      string
	port        int
	txtRecords  []string
	conn        *net.UDPConn
	ctx         context.Context
	cancel      context.CancelFunc
	mu          sync.Mutex
}

// DiscoveredServer represents a server found via mDNS scanning.
type DiscoveredServer struct {
	Name      string `json:"name"`
	Host      string `json:"host"`
	Port      int    `json:"port"`
	Version   string `json:"version"`
	MachineID string `json:"machineId"`
}

// NewService creates a new mDNS service advertiser.
func NewService(name string, port int, machineID string, version string) *Service {
	platform := runtime.GOOS
	return &Service{
		name:        name,
		serviceType: "_openflix._tcp",
		domain:      "local",
		port:        port,
		txtRecords: []string{
			"version=" + version,
			"machineId=" + machineID,
			"platform=" + platform,
		},
	}
}

// Start begins listening for mDNS queries and responding to them.
func (s *Service) Start() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.conn != nil {
		return fmt.Errorf("mdns service already started")
	}

	s.ctx, s.cancel = context.WithCancel(context.Background())

	multicastAddr, err := net.ResolveUDPAddr("udp4", mdnsAddr)
	if err != nil {
		return fmt.Errorf("failed to resolve mDNS multicast address: %w", err)
	}

	conn, err := net.ListenMulticastUDP("udp4", nil, multicastAddr)
	if err != nil {
		return fmt.Errorf("failed to join mDNS multicast group: %w", err)
	}

	s.conn = conn

	go s.listen()

	logger.Infof("mDNS service started: %s.%s.%s on port %d", s.name, s.serviceType, s.domain, s.port)
	return nil
}

// Stop sends a goodbye packet (TTL=0) and closes the connection.
func (s *Service) Stop() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.conn == nil {
		return nil
	}

	// Send goodbye packet with TTL=0
	s.sendGoodbye()

	s.cancel()
	err := s.conn.Close()
	s.conn = nil

	logger.Info("mDNS service stopped")
	return err
}

// listen reads incoming mDNS queries from the multicast group.
func (s *Service) listen() {
	buf := make([]byte, 1500)
	for {
		select {
		case <-s.ctx.Done():
			return
		default:
		}

		s.conn.SetReadDeadline(time.Now().Add(1 * time.Second))
		n, addr, err := s.conn.ReadFromUDP(buf)
		if err != nil {
			if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
				continue
			}
			select {
			case <-s.ctx.Done():
				return
			default:
				continue
			}
		}

		s.handleQuery(buf[:n], addr)
	}
}

// handleQuery parses a DNS query and, if it asks about our service type,
// responds with SRV + TXT + A records.
func (s *Service) handleQuery(buf []byte, addr *net.UDPAddr) {
	questions, txID, err := parseDNSQuery(buf)
	if err != nil {
		return
	}

	serviceFQDN := s.serviceType + "." + s.domain + "."
	instanceFQDN := s.name + "." + s.serviceType + "." + s.domain + "."

	respond := false
	for _, q := range questions {
		qname := strings.ToLower(q.name)
		if qname == strings.ToLower(serviceFQDN) || qname == strings.ToLower(instanceFQDN) {
			respond = true
			break
		}
		// Also respond to _services._dns-sd._udp.local. enumeration
		if qname == "_services._dns-sd._udp.local." {
			respond = true
			break
		}
	}

	if !respond {
		return
	}

	logger.Debugf("mDNS query from %s for our service, sending response", addr.String())

	resp := s.buildResponse(txID, serviceFQDN, instanceFQDN, defaultTTL)
	if resp == nil {
		return
	}

	// Send response to the multicast group
	multicastAddr, err := net.ResolveUDPAddr("udp4", mdnsAddr)
	if err != nil {
		return
	}

	sendConn, err := net.DialUDP("udp4", nil, multicastAddr)
	if err != nil {
		return
	}
	defer sendConn.Close()

	sendConn.Write(resp)
}

// sendGoodbye sends a goodbye packet (TTL=0) so clients remove us from cache.
func (s *Service) sendGoodbye() {
	serviceFQDN := s.serviceType + "." + s.domain + "."
	instanceFQDN := s.name + "." + s.serviceType + "." + s.domain + "."

	resp := s.buildResponse(0, serviceFQDN, instanceFQDN, goodbyeTTL)
	if resp == nil {
		return
	}

	multicastAddr, err := net.ResolveUDPAddr("udp4", mdnsAddr)
	if err != nil {
		return
	}

	sendConn, err := net.DialUDP("udp4", nil, multicastAddr)
	if err != nil {
		return
	}
	defer sendConn.Close()

	sendConn.Write(resp)
}

// buildResponse constructs a DNS response with PTR, SRV, TXT, and A records.
func (s *Service) buildResponse(txID uint16, serviceFQDN, instanceFQDN string, ttl uint32) []byte {
	hostname, _ := os.Hostname()
	if hostname == "" {
		hostname = "openflix"
	}
	hostFQDN := hostname + "." + s.domain + "."

	localIP := getLocalIPv4()
	if localIP == nil {
		return nil
	}

	// DNS Header (12 bytes)
	var pkt []byte
	header := make([]byte, 12)
	binary.BigEndian.PutUint16(header[0:2], txID)   // Transaction ID
	binary.BigEndian.PutUint16(header[2:4], 0x8400)  // Flags: response, authoritative
	binary.BigEndian.PutUint16(header[4:6], 0)        // Questions
	binary.BigEndian.PutUint16(header[6:8], 4)        // Answer count (PTR + SRV + TXT + A)
	binary.BigEndian.PutUint16(header[8:10], 0)       // Authority
	binary.BigEndian.PutUint16(header[10:12], 0)      // Additional
	pkt = append(pkt, header...)

	// Answer 1: PTR record  _openflix._tcp.local. -> instance._openflix._tcp.local.
	pkt = append(pkt, encodeDNSName(serviceFQDN)...)
	pkt = appendRecordHeader(pkt, dnsTypePTR, dnsClassIN, ttl)
	ptrRdata := encodeDNSName(instanceFQDN)
	pkt = appendUint16(pkt, uint16(len(ptrRdata)))
	pkt = append(pkt, ptrRdata...)

	// Answer 2: SRV record  instance._openflix._tcp.local. -> hostname.local. port
	pkt = append(pkt, encodeDNSName(instanceFQDN)...)
	pkt = appendRecordHeader(pkt, dnsTypeSRV, dnsClassFlush, ttl)
	srvRdata := make([]byte, 6)
	binary.BigEndian.PutUint16(srvRdata[0:2], 0)              // Priority
	binary.BigEndian.PutUint16(srvRdata[2:4], 0)              // Weight
	binary.BigEndian.PutUint16(srvRdata[4:6], uint16(s.port)) // Port
	srvRdata = append(srvRdata, encodeDNSName(hostFQDN)...)
	pkt = appendUint16(pkt, uint16(len(srvRdata)))
	pkt = append(pkt, srvRdata...)

	// Answer 3: TXT record  instance._openflix._tcp.local. -> txt records
	pkt = append(pkt, encodeDNSName(instanceFQDN)...)
	pkt = appendRecordHeader(pkt, dnsTypeTXT, dnsClassFlush, ttl)
	var txtRdata []byte
	for _, txt := range s.txtRecords {
		txtRdata = append(txtRdata, byte(len(txt)))
		txtRdata = append(txtRdata, []byte(txt)...)
	}
	pkt = appendUint16(pkt, uint16(len(txtRdata)))
	pkt = append(pkt, txtRdata...)

	// Answer 4: A record  hostname.local. -> IP
	pkt = append(pkt, encodeDNSName(hostFQDN)...)
	pkt = appendRecordHeader(pkt, dnsTypeA, dnsClassFlush, ttl)
	pkt = appendUint16(pkt, 4)
	pkt = append(pkt, localIP.To4()...)

	return pkt
}

// Scan sends an mDNS query for _openflix._tcp.local. and collects responses
// within the given timeout.
func Scan(timeout time.Duration) ([]DiscoveredServer, error) {
	multicastAddr, err := net.ResolveUDPAddr("udp4", mdnsAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve mDNS address: %w", err)
	}

	// Bind to any available port for sending
	conn, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.IPv4zero, Port: 0})
	if err != nil {
		return nil, fmt.Errorf("failed to create UDP socket: %w", err)
	}
	defer conn.Close()

	// Build and send query for _openflix._tcp.local.
	query := buildMDNSQuery("_openflix._tcp.local.")
	_, err = conn.WriteToUDP(query, multicastAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to send mDNS query: %w", err)
	}

	// Collect responses
	var servers []DiscoveredServer
	seen := make(map[string]bool)
	deadline := time.Now().Add(timeout)

	buf := make([]byte, 1500)
	for time.Now().Before(deadline) {
		conn.SetReadDeadline(deadline)
		n, _, err := conn.ReadFromUDP(buf)
		if err != nil {
			if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
				break
			}
			continue
		}

		server, ok := parseMDNSResponse(buf[:n])
		if !ok {
			continue
		}

		key := fmt.Sprintf("%s:%d", server.Host, server.Port)
		if seen[key] {
			continue
		}
		seen[key] = true
		servers = append(servers, server)
	}

	return servers, nil
}

// ============ DNS Wire Format Helpers ============

// encodeDNSName encodes a domain name in DNS wire format (e.g., "foo.local." -> \x03foo\x05local\x00).
func encodeDNSName(name string) []byte {
	name = strings.TrimSuffix(name, ".")
	var buf []byte
	for _, label := range strings.Split(name, ".") {
		buf = append(buf, byte(len(label)))
		buf = append(buf, []byte(label)...)
	}
	buf = append(buf, 0) // root label
	return buf
}

// appendRecordHeader appends type, class, and TTL fields for a resource record.
func appendRecordHeader(pkt []byte, rrType, rrClass uint16, ttl uint32) []byte {
	b := make([]byte, 8)
	binary.BigEndian.PutUint16(b[0:2], rrType)
	binary.BigEndian.PutUint16(b[2:4], rrClass)
	binary.BigEndian.PutUint32(b[4:8], ttl)
	return append(pkt, b...)
}

// appendUint16 appends a big-endian uint16 to the packet.
func appendUint16(pkt []byte, v uint16) []byte {
	b := make([]byte, 2)
	binary.BigEndian.PutUint16(b, v)
	return append(pkt, b...)
}

type dnsQuestion struct {
	name   string
	qtype  uint16
	qclass uint16
}

// parseDNSQuery parses the question section of a DNS message.
// Returns the list of questions, the transaction ID, and any error.
func parseDNSQuery(buf []byte) ([]dnsQuestion, uint16, error) {
	if len(buf) < 12 {
		return nil, 0, fmt.Errorf("packet too short")
	}

	txID := binary.BigEndian.Uint16(buf[0:2])
	flags := binary.BigEndian.Uint16(buf[2:4])

	// Only process queries (QR bit = 0)
	if flags&0x8000 != 0 {
		return nil, 0, fmt.Errorf("not a query")
	}

	qdCount := binary.BigEndian.Uint16(buf[4:6])
	offset := 12

	var questions []dnsQuestion
	for i := 0; i < int(qdCount); i++ {
		name, newOffset, err := decodeDNSName(buf, offset)
		if err != nil {
			return nil, 0, err
		}
		offset = newOffset

		if offset+4 > len(buf) {
			return nil, 0, fmt.Errorf("truncated question")
		}

		qtype := binary.BigEndian.Uint16(buf[offset : offset+2])
		qclass := binary.BigEndian.Uint16(buf[offset+2 : offset+4])
		offset += 4

		questions = append(questions, dnsQuestion{
			name:   name,
			qtype:  qtype,
			qclass: qclass & 0x7FFF, // mask out unicast-response bit
		})
	}

	return questions, txID, nil
}

// decodeDNSName reads a DNS name from buf starting at offset, handling
// both label sequences and compression pointers.
func decodeDNSName(buf []byte, offset int) (string, int, error) {
	var labels []string
	visited := make(map[int]bool) // loop detection
	jumped := false
	returnOffset := offset

	for {
		if offset >= len(buf) {
			return "", 0, fmt.Errorf("name extends beyond packet")
		}

		length := int(buf[offset])

		if length == 0 {
			if !jumped {
				returnOffset = offset + 1
			}
			break
		}

		// Check for compression pointer (top 2 bits set)
		if length&0xC0 == 0xC0 {
			if offset+1 >= len(buf) {
				return "", 0, fmt.Errorf("truncated pointer")
			}
			ptr := int(binary.BigEndian.Uint16(buf[offset:offset+2])) & 0x3FFF
			if visited[ptr] {
				return "", 0, fmt.Errorf("compression loop detected")
			}
			visited[ptr] = true
			if !jumped {
				returnOffset = offset + 2
			}
			offset = ptr
			jumped = true
			continue
		}

		offset++
		if offset+length > len(buf) {
			return "", 0, fmt.Errorf("label extends beyond packet")
		}

		labels = append(labels, string(buf[offset:offset+length]))
		offset += length

		if !jumped {
			returnOffset = offset
		}
	}

	return strings.Join(labels, ".") + ".", returnOffset, nil
}

// buildMDNSQuery creates a minimal DNS query packet for the given service name.
func buildMDNSQuery(service string) []byte {
	var pkt []byte

	// DNS Header
	header := make([]byte, 12)
	binary.BigEndian.PutUint16(header[0:2], 0)       // Transaction ID
	binary.BigEndian.PutUint16(header[2:4], 0)       // Flags: standard query
	binary.BigEndian.PutUint16(header[4:6], 1)       // Question count
	binary.BigEndian.PutUint16(header[6:8], 0)       // Answer count
	binary.BigEndian.PutUint16(header[8:10], 0)      // Authority count
	binary.BigEndian.PutUint16(header[10:12], 0)     // Additional count
	pkt = append(pkt, header...)

	// Question: _openflix._tcp.local. PTR IN
	pkt = append(pkt, encodeDNSName(service)...)
	pkt = appendUint16(pkt, dnsTypePTR)
	pkt = appendUint16(pkt, dnsClassIN)

	return pkt
}

// parseMDNSResponse attempts to extract a DiscoveredServer from an mDNS response packet.
func parseMDNSResponse(buf []byte) (DiscoveredServer, bool) {
	var server DiscoveredServer

	if len(buf) < 12 {
		return server, false
	}

	flags := binary.BigEndian.Uint16(buf[2:4])
	// Only process responses (QR bit = 1)
	if flags&0x8000 == 0 {
		return server, false
	}

	anCount := binary.BigEndian.Uint16(buf[6:8])

	// Skip questions section
	offset := 12
	qdCount := binary.BigEndian.Uint16(buf[4:6])
	for i := 0; i < int(qdCount); i++ {
		_, newOffset, err := decodeDNSName(buf, offset)
		if err != nil {
			return server, false
		}
		offset = newOffset + 4 // skip qtype + qclass
	}

	// Parse answer records
	foundSRV := false
	for i := 0; i < int(anCount); i++ {
		if offset >= len(buf) {
			break
		}

		_, newOffset, err := decodeDNSName(buf, offset)
		if err != nil {
			break
		}
		offset = newOffset

		if offset+10 > len(buf) {
			break
		}

		rrType := binary.BigEndian.Uint16(buf[offset : offset+2])
		// skip class
		// skip TTL
		rdLength := binary.BigEndian.Uint16(buf[offset+8 : offset+10])
		offset += 10

		if offset+int(rdLength) > len(buf) {
			break
		}

		rdataStart := offset
		rdataEnd := offset + int(rdLength)

		switch rrType {
		case dnsTypeSRV:
			if rdLength >= 6 {
				server.Port = int(binary.BigEndian.Uint16(buf[rdataStart+4 : rdataStart+6]))
				hostName, _, err := decodeDNSName(buf, rdataStart+6)
				if err == nil {
					server.Name = strings.TrimSuffix(hostName, ".")
				}
				foundSRV = true
			}
		case dnsTypeA:
			if rdLength == 4 {
				ip := net.IPv4(buf[rdataStart], buf[rdataStart+1], buf[rdataStart+2], buf[rdataStart+3])
				server.Host = ip.String()
			}
		case dnsTypeTXT:
			txtOffset := rdataStart
			for txtOffset < rdataEnd {
				tlen := int(buf[txtOffset])
				txtOffset++
				if txtOffset+tlen > rdataEnd {
					break
				}
				kv := string(buf[txtOffset : txtOffset+tlen])
				txtOffset += tlen
				if strings.HasPrefix(kv, "version=") {
					server.Version = strings.TrimPrefix(kv, "version=")
				} else if strings.HasPrefix(kv, "machineId=") {
					server.MachineID = strings.TrimPrefix(kv, "machineId=")
				}
			}
		}

		offset = rdataEnd
	}

	if !foundSRV || server.Host == "" {
		return server, false
	}

	return server, true
}

// getLocalIPv4 returns the first non-loopback IPv4 address.
func getLocalIPv4() net.IP {
	interfaces, err := net.Interfaces()
	if err != nil {
		return nil
	}

	for _, iface := range interfaces {
		if iface.Flags&net.FlagLoopback != 0 || iface.Flags&net.FlagUp == 0 {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}

			if ip == nil || ip.IsLoopback() || ip.To4() == nil {
				continue
			}

			return ip
		}
	}

	return nil
}
