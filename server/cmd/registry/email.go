package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"
)

// resendAPIKey is read from RESEND_API_KEY env var at startup.
var resendAPIKey string

const resendEndpoint = "https://api.resend.com/emails"

// sendEmail sends an HTML email via the Resend API.
// If resendAPIKey is empty the call is skipped silently.
func sendEmail(to, subject, htmlBody, textBody string) error {
	if resendAPIKey == "" {
		log.Println("email not configured (RESEND_API_KEY not set) — skipping send")
		return nil
	}

	payload := map[string]any{
		"from":    "OpenFlix <licenses@openflix.io>",
		"to":      []string{to},
		"subject": subject,
		"html":    htmlBody,
		"text":    textBody,
	}

	b, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal email payload: %w", err)
	}

	req, err := http.NewRequest(http.MethodPost, resendEndpoint, bytes.NewReader(b))
	if err != nil {
		return fmt.Errorf("create resend request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+resendAPIKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("resend request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		var buf bytes.Buffer
		buf.ReadFrom(resp.Body)
		return fmt.Errorf("resend API returned %d: %s", resp.StatusCode, buf.String())
	}

	return nil
}

// ── Email template helpers ────────────────────────────────────────────────────

func emailHeader(preheader string) string {
	return fmt.Sprintf(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="x-apple-disable-message-reformatting">
<title>OpenFlix</title>
<style>
  body { margin:0; padding:0; background:#0e0f13; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif; }
  table { border-collapse:collapse; }
  a { color:#3b82f6; text-decoration:none; }
  a:hover { text-decoration:underline; }
</style>
</head>
<body style="background:#0e0f13;margin:0;padding:0;">
<span style="display:none;max-height:0;overflow:hidden;mso-hide:all;">%s</span>
<!-- wrapper -->
<table width="100%%" cellpadding="0" cellspacing="0" style="background:#0e0f13;padding:40px 16px;">
<tr><td align="center">
<table width="580" cellpadding="0" cellspacing="0" style="max-width:580px;width:100%%;">

  <!-- HEADER -->
  <tr>
    <td style="background:#16181f;border:1px solid #2a2d38;border-radius:10px 10px 0 0;padding:28px 36px;text-align:center;">
      <div style="font-size:26px;font-weight:800;letter-spacing:-0.02em;color:#e2e4ed;">
        Open<span style="color:#3b82f6;">Flix</span>
      </div>
      <div style="font-size:12px;color:#6b7280;margin-top:4px;text-transform:uppercase;letter-spacing:0.08em;">License Management</div>
    </td>
  </tr>

  <!-- BODY -->
  <tr>
    <td style="background:#16181f;border-left:1px solid #2a2d38;border-right:1px solid #2a2d38;padding:32px 36px;">
`, preheader)
}

const emailFooter = `
    </td>
  </tr>

  <!-- FOOTER -->
  <tr>
    <td style="background:#0e0f13;border:1px solid #2a2d38;border-top:none;border-radius:0 0 10px 10px;padding:20px 36px;text-align:center;">
      <p style="font-size:12px;color:#6b7280;margin:0;">
        OpenFlix · <a href="https://openflix.io" style="color:#6b7280;">openflix.io</a><br>
        Questions? Email <a href="mailto:support@openflix.io" style="color:#6b7280;">support@openflix.io</a>
      </p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>`

func h1(text string) string {
	return fmt.Sprintf(`<h1 style="font-size:22px;font-weight:700;color:#e2e4ed;margin:0 0 8px 0;">%s</h1>`, text)
}

func paragraph(text string) string {
	return fmt.Sprintf(`<p style="font-size:15px;color:#9ca3af;line-height:1.6;margin:0 0 20px 0;">%s</p>`, text)
}

func keyBox(key string) string {
	return fmt.Sprintf(`
<div style="background:#0e0f13;border:1px solid #2a2d38;border-radius:8px;padding:16px 20px;margin:20px 0;text-align:center;">
  <div style="font-size:11px;text-transform:uppercase;letter-spacing:0.08em;color:#6b7280;margin-bottom:8px;">License Key</div>
  <div style="font-family:'SF Mono','Fira Code','Fira Mono',Menlo,Consolas,monospace;font-size:15px;color:#22c55e;word-break:break-all;letter-spacing:0.04em;">%s</div>
</div>`, key)
}

func calloutBox(label, value, color string) string {
	return fmt.Sprintf(`
<div style="background:#0e0f13;border-left:3px solid %s;border-radius:0 6px 6px 0;padding:12px 16px;margin:16px 0;">
  <div style="font-size:11px;text-transform:uppercase;letter-spacing:0.06em;color:#6b7280;margin-bottom:4px;">%s</div>
  <div style="font-size:14px;color:#e2e4ed;font-weight:600;">%s</div>
</div>`, color, label, value)
}

func actionButton(label, url string) string {
	return fmt.Sprintf(`
<div style="text-align:center;margin:24px 0;">
  <a href="%s" style="display:inline-block;background:#3b82f6;color:#ffffff;font-size:14px;font-weight:700;padding:12px 28px;border-radius:6px;text-decoration:none;">%s</a>
</div>`, url, label)
}

func divider() string {
	return `<hr style="border:none;border-top:1px solid #2a2d38;margin:24px 0;">`
}

// maskKey returns the key with all but the last 4 characters replaced by *.
func maskKey(key string) string {
	if len(key) <= 4 {
		return key
	}
	// UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  (36 chars)
	// Show prefix segment + last 4 of final segment
	parts := strings.Split(key, "-")
	if len(parts) == 5 {
		last := parts[4]
		masked := strings.Repeat("*", len(last)-4) + last[len(last)-4:]
		return parts[0][:4] + "****-****-****-****-" + masked
	}
	return strings.Repeat("*", len(key)-4) + key[len(key)-4:]
}

// ── Specific email senders ────────────────────────────────────────────────────

// sendLicenseCreatedEmail sends the "Your OpenFlix License Key" email.
func sendLicenseCreatedEmail(email, key string, expiresAt *time.Time) error {
	expiryLine := "Never expires"
	expiryText := "never expires"
	if expiresAt != nil {
		formatted := expiresAt.UTC().Format("January 2, 2006")
		expiryLine = formatted
		expiryText = "expires on " + formatted
	}

	var buf strings.Builder
	buf.WriteString(emailHeader("Your OpenFlix license key is ready — activate your server today."))
	buf.WriteString(h1("Welcome to OpenFlix!"))
	buf.WriteString(paragraph("Your license key has been created. Use it to activate cloud discovery on your OpenFlix server."))
	buf.WriteString(keyBox(key))
	buf.WriteString(calloutBox("Valid Until", expiryLine, "#22c55e"))
	buf.WriteString(divider())
	buf.WriteString(`<p style="font-size:14px;font-weight:600;color:#e2e4ed;margin:0 0 12px 0;">How to activate</p>`)
	buf.WriteString(`<ol style="font-size:14px;color:#9ca3af;line-height:2;margin:0 0 20px 0;padding-left:20px;">`)
	buf.WriteString(`<li>Open your OpenFlix server admin panel</li>`)
	buf.WriteString(`<li>Navigate to <strong style="color:#e2e4ed;">Settings → License Key</strong></li>`)
	buf.WriteString(`<li>Paste the key above and click <strong style="color:#e2e4ed;">Activate</strong></li>`)
	buf.WriteString(`</ol>`)
	buf.WriteString(paragraph(`Need help? Contact us at <a href="mailto:support@openflix.io">support@openflix.io</a>`))
	buf.WriteString(emailFooter)

	html := buf.String()
	text := fmt.Sprintf(
		"Welcome to OpenFlix!\n\nYour license key: %s\n\nExpiry: %s\n\nTo activate:\n1. Open your OpenFlix server admin panel\n2. Navigate to Settings → License Key\n3. Paste the key and click Activate\n\nNeed help? Email support@openflix.io",
		key, expiryText,
	)

	return sendEmail(email, "Your OpenFlix License Key", html, text)
}

// sendLicenseRevokedEmail sends the revocation notice.
func sendLicenseRevokedEmail(email, key, reason string) error {
	masked := maskKey(key)

	var buf strings.Builder
	buf.WriteString(emailHeader("Your OpenFlix license has been revoked."))
	buf.WriteString(h1("License Revoked"))
	buf.WriteString(paragraph("The following OpenFlix license key has been deactivated and is no longer valid."))
	buf.WriteString(keyBox(masked))

	if reason != "" {
		buf.WriteString(calloutBox("Reason", reason, "#ef4444"))
	}

	buf.WriteString(divider())
	buf.WriteString(paragraph(`If you believe this is a mistake or would like to resolve this, please reach out to us at <a href="mailto:support@openflix.io">support@openflix.io</a> and we'll be happy to help.`))
	buf.WriteString(emailFooter)

	html := buf.String()

	reasonText := ""
	if reason != "" {
		reasonText = "\nReason: " + reason + "\n"
	}
	text := fmt.Sprintf(
		"Your OpenFlix license has been revoked.\n\nLicense key: %s\n%s\nIf you believe this is a mistake, contact support@openflix.io",
		masked, reasonText,
	)

	return sendEmail(email, "Your OpenFlix License Has Been Revoked", html, text)
}

// sendLicenseExpiringEmail sends the 7-day expiry warning.
func sendLicenseExpiringEmail(email, key string, expiresAt time.Time) error {
	formatted := expiresAt.UTC().Format("January 2, 2006")

	var buf strings.Builder
	buf.WriteString(emailHeader("Your OpenFlix license expires in 7 days — renew to keep cloud discovery active."))
	buf.WriteString(h1("License Expiring Soon"))
	buf.WriteString(paragraph("Your OpenFlix license is expiring in <strong style=\"color:#f59e0b;\">7 days</strong>. Renew now to ensure uninterrupted cloud discovery for your server."))
	buf.WriteString(calloutBox("Expiry Date", formatted, "#f59e0b"))
	buf.WriteString(actionButton("Renew License →", "https://openflix.io/renew"))
	buf.WriteString(divider())
	buf.WriteString(paragraph(`Questions? Contact <a href="mailto:support@openflix.io">support@openflix.io</a>`))
	buf.WriteString(emailFooter)

	html := buf.String()
	text := fmt.Sprintf(
		"Your OpenFlix license expires on %s (in 7 days).\n\nRenew now to keep cloud discovery active: https://openflix.io/renew\n\nQuestions? Email support@openflix.io",
		formatted,
	)

	return sendEmail(email, "Your OpenFlix License Expires in 7 Days", html, text)
}

// sendLicenseExpiredEmail sends the post-expiry notice.
func sendLicenseExpiredEmail(email, key string) error {
	var buf strings.Builder
	buf.WriteString(emailHeader("Your OpenFlix license has expired — renew to restore cloud discovery."))
	buf.WriteString(h1("License Expired"))
	buf.WriteString(paragraph("Your OpenFlix license has expired. Cloud discovery for your server has been suspended."))
	buf.WriteString(paragraph("Renew your license to restore remote access from anywhere."))
	buf.WriteString(actionButton("Renew License →", "https://openflix.io/renew"))
	buf.WriteString(divider())
	buf.WriteString(paragraph(`Questions? Contact <a href="mailto:support@openflix.io">support@openflix.io</a>`))
	buf.WriteString(emailFooter)

	html := buf.String()
	text := "Your OpenFlix license has expired.\n\nRenew now to restore cloud discovery: https://openflix.io/renew\n\nQuestions? Email support@openflix.io"

	return sendEmail(email, "Your OpenFlix License Has Expired", html, text)
}
