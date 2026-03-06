// Package upnp provides UPnP IGD (Internet Gateway Device) support for automatic
// port mapping. This allows the server to open a port on the home router without
// any manual configuration, enabling remote access out of the box.
package upnp

import (
	"context"
	"encoding/xml"
	"fmt"
	"io"
	"net"
	"net/http"
	"strings"
	"time"
)

const (
	ssdpAddr        = "239.255.255.250:1900"
	ssdpSearchDelay = 3 * time.Second
	soapTimeout     = 5 * time.Second
)

// Client talks to a UPnP IGD (router) to manage port mappings.
type Client struct {
	controlURL string
	serviceType string
	httpClient  *http.Client
}

// ssdpResponse holds a parsed SSDP response.
type ssdpResponse struct {
	Location    string
	ServiceType string
}

// Discover finds the first UPnP IGD WANIPConnection device on the LAN.
// It first tries SSDP multicast discovery, then falls back to probing the
// default gateway directly (handles Docker macvlan and other environments
// where multicast is restricted).
func Discover() (*Client, error) {
	// 1. Try SSDP multicast
	for _, st := range []string{
		"urn:schemas-upnp-org:service:WANIPConnection:2",
		"urn:schemas-upnp-org:service:WANIPConnection:1",
		"urn:schemas-upnp-org:service:WANPPPConnection:1",
	} {
		resp, err := ssdpSearch(st, ssdpSearchDelay)
		if err != nil || len(resp) == 0 {
			continue
		}
		for _, r := range resp {
			client, err := newClientFromLocation(r.Location, r.ServiceType)
			if err != nil {
				continue
			}
			return client, nil
		}
	}

	// 2. Fallback: probe the default gateway directly on common UPnP ports.
	// This works in Docker macvlan / environments where SSDP multicast is blocked.
	gw, err := defaultGateway()
	if err != nil {
		return nil, fmt.Errorf("no UPnP IGD found (SSDP failed, gateway unknown: %v)", err)
	}
	return probeGateway(gw)
}

// defaultGateway returns the default IPv4 gateway by parsing the routing table.
func defaultGateway() (string, error) {
	// Connect a UDP socket to an external address — the local address chosen
	// reveals which interface/gateway is used without sending any packets.
	conn, err := net.DialUDP("udp4", nil, &net.UDPAddr{IP: net.ParseIP("8.8.8.8"), Port: 80})
	if err != nil {
		return "", err
	}
	defer conn.Close()
	localIP := conn.LocalAddr().(*net.UDPAddr).IP.To4()
	if localIP == nil {
		return "", fmt.Errorf("no IPv4 local address")
	}
	// Assume gateway is .1 on the same /24 (works for 99% of home networks)
	gw := net.IP{localIP[0], localIP[1], localIP[2], 1}.String()
	return gw, nil
}

// probeGateway tries to find the UPnP IGD description on the gateway IP
// by probing common ports and paths used by home routers.
func probeGateway(gatewayIP string) (*Client, error) {
	httpClient := &http.Client{Timeout: 3 * time.Second}
	ports := []int{1900, 5000, 49152, 49153, 49154, 8080, 80}
	paths := []string{
		"/rootDesc.xml",
		"/igdupnp/desc/WFADevice.xml",
		"/upnp/IGD.xml",
		"/gatedesc.xml",
		"/igd.xml",
		"/wanipconn.xml",
		"/upnp/desc/gateway.xml",
	}

	for _, port := range ports {
		for _, path := range paths {
			url := fmt.Sprintf("http://%s:%d%s", gatewayIP, port, path)
			resp, err := httpClient.Get(url)
			if err != nil {
				continue
			}
			if resp.StatusCode != http.StatusOK {
				resp.Body.Close()
				continue
			}
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()

			var desc deviceDesc
			if err := xml.Unmarshal(body, &desc); err != nil {
				continue
			}
			baseURL := fmt.Sprintf("http://%s:%d", gatewayIP, port)
			controlURL, serviceType := findService(desc.Device, baseURL)
			if controlURL == "" {
				continue
			}
			return &Client{
				controlURL:  controlURL,
				serviceType: serviceType,
				httpClient:  httpClient,
			}, nil
		}
	}
	return nil, fmt.Errorf("no UPnP IGD found via SSDP or direct probe of gateway %s", gatewayIP)
}

// ssdpSearch sends an SSDP M-SEARCH and collects responses for the given duration.
func ssdpSearch(serviceType string, wait time.Duration) ([]ssdpResponse, error) {
	conn, err := net.ListenUDP("udp4", &net.UDPAddr{})
	if err != nil {
		return nil, fmt.Errorf("listen udp: %w", err)
	}
	defer conn.Close()

	dest, _ := net.ResolveUDPAddr("udp4", ssdpAddr)
	search := fmt.Sprintf(
		"M-SEARCH * HTTP/1.1\r\nHOST: %s\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: %s\r\n\r\n",
		ssdpAddr, serviceType,
	)
	if _, err := conn.WriteTo([]byte(search), dest); err != nil {
		return nil, fmt.Errorf("send M-SEARCH: %w", err)
	}

	conn.SetReadDeadline(time.Now().Add(wait))
	buf := make([]byte, 4096)
	var results []ssdpResponse

	for {
		n, _, err := conn.ReadFrom(buf)
		if err != nil {
			break // timeout or closed
		}
		r := parseSSDPResponse(string(buf[:n]), serviceType)
		if r != nil {
			results = append(results, *r)
		}
	}
	return results, nil
}

func parseSSDPResponse(raw, serviceType string) *ssdpResponse {
	var location string
	for _, line := range strings.Split(raw, "\r\n") {
		if strings.HasPrefix(strings.ToLower(line), "location:") {
			location = strings.TrimSpace(line[9:])
			break
		}
	}
	if location == "" {
		return nil
	}
	return &ssdpResponse{Location: location, ServiceType: serviceType}
}

// deviceDesc is a minimal UPnP device description XML structure.
type deviceDesc struct {
	XMLName  xml.Name   `xml:"root"`
	Device   deviceNode `xml:"device"`
}

type deviceNode struct {
	DeviceType   string       `xml:"deviceType"`
	ServiceList  []serviceNode `xml:"serviceList>service"`
	DeviceList   []deviceNode  `xml:"deviceList>device"`
}

type serviceNode struct {
	ServiceType string `xml:"serviceType"`
	ControlURL  string `xml:"controlURL"`
}

func newClientFromLocation(location, preferredST string) (*Client, error) {
	c := &http.Client{Timeout: soapTimeout}
	resp, err := c.Get(location)
	if err != nil {
		return nil, fmt.Errorf("fetch device description: %w", err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)

	var desc deviceDesc
	if err := xml.Unmarshal(body, &desc); err != nil {
		return nil, fmt.Errorf("parse device description: %w", err)
	}

	// Walk all devices (root + embedded) looking for WANIPConnection or WANPPPConnection
	controlURL, serviceType := findService(desc.Device, location)
	if controlURL == "" {
		return nil, fmt.Errorf("WANIPConnection service not found in device description")
	}

	return &Client{
		controlURL:  controlURL,
		serviceType: serviceType,
		httpClient:  c,
	}, nil
}

func findService(d deviceNode, baseURL string) (controlURL, serviceType string) {
	wantTypes := []string{
		"urn:schemas-upnp-org:service:WANIPConnection:2",
		"urn:schemas-upnp-org:service:WANIPConnection:1",
		"urn:schemas-upnp-org:service:WANPPPConnection:1",
	}
	for _, svc := range d.ServiceList {
		for _, want := range wantTypes {
			if svc.ServiceType == want {
				u := resolveURL(baseURL, svc.ControlURL)
				return u, svc.ServiceType
			}
		}
	}
	// Recurse into embedded devices
	for _, sub := range d.DeviceList {
		if u, st := findService(sub, baseURL); u != "" {
			return u, st
		}
	}
	return "", ""
}

func resolveURL(base, ref string) string {
	if strings.HasPrefix(ref, "http") {
		return ref
	}
	// Combine base URL origin with the control path
	idx := strings.Index(base, "://")
	if idx < 0 {
		return ref
	}
	// Find end of host:port
	rest := base[idx+3:]
	slash := strings.Index(rest, "/")
	if slash < 0 {
		return base + ref
	}
	origin := base[:idx+3+slash]
	if !strings.HasPrefix(ref, "/") {
		ref = "/" + ref
	}
	return origin + ref
}

// soap sends a SOAP action and returns the response body.
func (c *Client) soap(ctx context.Context, action, body string) (string, error) {
	envelope := fmt.Sprintf(`<?xml version="1.0"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
            s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>%s</s:Body>
</s:Envelope>`, body)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.controlURL, strings.NewReader(envelope))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", `text/xml; charset="utf-8"`)
	req.Header.Set("SOAPAction", fmt.Sprintf(`"%s#%s"`, c.serviceType, action))

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	return string(raw), nil
}

// GetExternalIP returns the WAN IP address from the router.
func (c *Client) GetExternalIP(ctx context.Context) (string, error) {
	body := `<u:GetExternalIPAddress xmlns:u="` + c.serviceType + `"></u:GetExternalIPAddress>`
	resp, err := c.soap(ctx, "GetExternalIPAddress", body)
	if err != nil {
		return "", fmt.Errorf("GetExternalIPAddress: %w", err)
	}
	// Parse <NewExternalIPAddress>...</NewExternalIPAddress>
	ip := extractXMLValue(resp, "NewExternalIPAddress")
	if ip == "" {
		return "", fmt.Errorf("GetExternalIPAddress: empty response (router returned: %.200s)", resp)
	}
	return ip, nil
}

// AddPortMapping creates a port mapping on the router.
// leaseDuration is in seconds; 0 means permanent (not all routers support this).
func (c *Client) AddPortMapping(ctx context.Context, externalPort, internalPort int, internalIP, protocol, description string, leaseDuration int) error {
	body := fmt.Sprintf(`<u:AddPortMapping xmlns:u="%s">
  <NewRemoteHost></NewRemoteHost>
  <NewExternalPort>%d</NewExternalPort>
  <NewProtocol>%s</NewProtocol>
  <NewInternalPort>%d</NewInternalPort>
  <NewInternalClient>%s</NewInternalClient>
  <NewEnabled>1</NewEnabled>
  <NewPortMappingDescription>%s</NewPortMappingDescription>
  <NewLeaseDuration>%d</NewLeaseDuration>
</u:AddPortMapping>`, c.serviceType, externalPort, protocol, internalPort, internalIP, description, leaseDuration)

	resp, err := c.soap(ctx, "AddPortMapping", body)
	if err != nil {
		return fmt.Errorf("AddPortMapping: %w", err)
	}
	if strings.Contains(resp, "errorCode") || strings.Contains(resp, "UPnPError") {
		code := extractXMLValue(resp, "errorCode")
		desc := extractXMLValue(resp, "errorDescription")
		return fmt.Errorf("AddPortMapping UPnP error %s: %s", code, desc)
	}
	return nil
}

// DeletePortMapping removes a port mapping from the router.
func (c *Client) DeletePortMapping(ctx context.Context, externalPort int, protocol string) error {
	body := fmt.Sprintf(`<u:DeletePortMapping xmlns:u="%s">
  <NewRemoteHost></NewRemoteHost>
  <NewExternalPort>%d</NewExternalPort>
  <NewProtocol>%s</NewProtocol>
</u:DeletePortMapping>`, c.serviceType, externalPort, protocol)

	_, err := c.soap(ctx, "DeletePortMapping", body)
	return err
}

func extractXMLValue(body, tag string) string {
	open := "<" + tag + ">"
	close := "</" + tag + ">"
	// Also handle namespace-prefixed tags like <m:NewExternalIPAddress>
	for _, b := range []string{body} {
		start := strings.Index(b, open)
		if start == -1 {
			// Try with any namespace prefix
			idx := strings.Index(b, ":"+tag+">")
			if idx == -1 {
				continue
			}
			// Find the opening <
			openStart := strings.LastIndex(b[:idx], "<")
			if openStart == -1 {
				continue
			}
			tagEnd := idx + len(":"+tag+">")
			closeTag := b[openStart+1 : idx] + ":" + tag // e.g. "m:NewExternalIPAddress"
			closeStart := strings.Index(b[tagEnd:], "</"+closeTag+">")
			if closeStart == -1 {
				continue
			}
			return b[tagEnd : tagEnd+closeStart]
		}
		start += len(open)
		end := strings.Index(b[start:], close)
		if end == -1 {
			continue
		}
		return b[start : start+end]
	}
	return ""
}
