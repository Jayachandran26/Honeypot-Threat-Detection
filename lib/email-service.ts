import nodemailer from "nodemailer"

interface EmailConfig {
  host: string
  port: number
  secure: boolean
  user: string
  password: string
  adminEmail: string
}

interface AlertData {
  type: "login_attempt" | "command_execution" | "malware_download" | "high_severity" | "multiple_attempts"
  sourceIP: string
  country: string
  username?: string
  password?: string
  command?: string
  timestamp: string
  severity: "low" | "medium" | "high"
  session: string
}

class EmailService {
  private transporter: nodemailer.Transporter | null = null
  private config: EmailConfig | null = null

  constructor() {
    this.initializeTransporter()
  }

  private initializeTransporter() {
    try {
      this.config = {
        host: process.env.SMTP_HOST || "smtp.gmail.com",
        port: Number.parseInt(process.env.SMTP_PORT || "587"),
        secure: process.env.SMTP_SECURE === "true",
        user: process.env.SMTP_USER || "",
        password: process.env.SMTP_PASSWORD || "",
        adminEmail: process.env.ADMIN_EMAIL || "",
      }

      if (!this.config.user || !this.config.password || !this.config.adminEmail) {
        console.log("Email service not configured - missing credentials")
        return
      }

      this.transporter = nodemailer.createTransport({
        host: this.config.host,
        port: this.config.port,
        secure: this.config.secure,
        auth: {
          user: this.config.user,
          pass: this.config.password,
        },
      })

      console.log("Email service initialized successfully")
    } catch (error) {
      console.error("Failed to initialize email service:", error)
    }
  }

  async sendAlert(alertData: AlertData): Promise<boolean> {
    if (!this.transporter || !this.config) {
      console.log("Email service not configured")
      return false
    }

    try {
      const subject = this.generateSubject(alertData)
      const htmlContent = this.generateHtmlContent(alertData)
      const textContent = this.generateTextContent(alertData)

      const mailOptions = {
        from: `"Cowrie Honeypot Alert" <${this.config.user}>`,
        to: this.config.adminEmail,
        subject: subject,
        text: textContent,
        html: htmlContent,
      }

      const result = await this.transporter.sendMail(mailOptions)
      console.log("Alert email sent successfully:", result.messageId)
      return true
    } catch (error) {
      console.error("Failed to send alert email:", error)
      return false
    }
  }

  private generateSubject(alertData: AlertData): string {
    const severityEmoji = {
      low: "🟡",
      medium: "🟠",
      high: "🔴",
    }

    const typeMessages = {
      login_attempt: "Login Attempt Detected",
      command_execution: "Malicious Command Executed",
      malware_download: "Malware Download Attempt",
      high_severity: "High Severity Attack",
      multiple_attempts: "Multiple Attack Attempts",
    }

    return `${severityEmoji[alertData.severity]} Honeypot Alert: ${typeMessages[alertData.type]} from ${alertData.sourceIP}`
  }

  private generateHtmlContent(alertData: AlertData): string {
    const severityColor = {
      low: "#fbbf24",
      medium: "#f97316",
      high: "#ef4444",
    }

    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Cowrie Honeypot Alert</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 20px; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); overflow: hidden; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; }
            .alert-badge { display: inline-block; padding: 8px 16px; border-radius: 20px; color: white; font-weight: bold; margin-bottom: 20px; }
            .details-grid { display: grid; grid-template-columns: 1fr 2fr; gap: 10px; margin: 20px 0; }
            .detail-label { font-weight: bold; color: #555; }
            .detail-value { color: #333; font-family: monospace; background: #f8f9fa; padding: 4px 8px; border-radius: 4px; }
            .command-box { background: #1a1a1a; color: #00ff00; padding: 15px; border-radius: 6px; font-family: monospace; margin: 15px 0; border-left: 4px solid #00ff00; }
            .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #666; border-top: 1px solid #eee; }
            .btn { display: inline-block; padding: 12px 24px; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 10px 5px; }
            .warning { background: #fef3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 6px; margin: 15px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🍯 Cowrie Honeypot Alert</h1>
                <p>Security incident detected on your honeypot</p>
            </div>
            
            <div class="content">
                <div class="alert-badge" style="background-color: ${severityColor[alertData.severity]}">
                    ${alertData.severity.toUpperCase()} SEVERITY ALERT
                </div>
                
                <h2>🚨 ${this.getAlertTitle(alertData.type)}</h2>
                
                <div class="details-grid">
                    <div class="detail-label">🌍 Source IP:</div>
                    <div class="detail-value">${alertData.sourceIP}</div>
                    
                    <div class="detail-label">🏳️ Country:</div>
                    <div class="detail-value">${alertData.country}</div>
                    
                    <div class="detail-label">⏰ Timestamp:</div>
                    <div class="detail-value">${new Date(alertData.timestamp).toLocaleString()}</div>
                    
                    <div class="detail-label">🔗 Session:</div>
                    <div class="detail-value">${alertData.session}</div>
                    
                    ${
                      alertData.username
                        ? `
                    <div class="detail-label">👤 Username:</div>
                    <div class="detail-value">${alertData.username}</div>
                    `
                        : ""
                    }
                    
                    ${
                      alertData.password
                        ? `
                    <div class="detail-label">🔑 Password:</div>
                    <div class="detail-value">${alertData.password}</div>
                    `
                        : ""
                    }
                </div>
                
                ${
                  alertData.command
                    ? `
                <h3>💻 Command Executed:</h3>
                <div class="command-box">$ ${alertData.command}</div>
                `
                    : ""
                }
                
                <div class="warning">
                    <strong>⚠️ Security Recommendation:</strong><br>
                    This attack attempt has been safely contained in the honeypot. Monitor for additional attempts from this IP address and consider blocking it at your firewall level if attacks persist.
                </div>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="http://localhost:3000" class="btn">📊 View Dashboard</a>
                    <a href="http://localhost:3000" class="btn">🔍 Analyze Logs</a>
                </div>
            </div>
            
            <div class="footer">
                <p>This alert was generated by your Cowrie Honeypot monitoring system.</p>
                <p>Dashboard: <a href="http://localhost:3000">http://localhost:3000</a></p>
                <p><small>Alert ID: ${alertData.session}-${Date.now()}</small></p>
            </div>
        </div>
    </body>
    </html>
    `
  }

  private generateTextContent(alertData: AlertData): string {
    return `
🍯 COWRIE HONEYPOT ALERT

${alertData.severity.toUpperCase()} SEVERITY: ${this.getAlertTitle(alertData.type)}

ATTACK DETAILS:
- Source IP: ${alertData.sourceIP}
- Country: ${alertData.country}
- Timestamp: ${new Date(alertData.timestamp).toLocaleString()}
- Session: ${alertData.session}
${alertData.username ? `- Username: ${alertData.username}` : ""}
${alertData.password ? `- Password: ${alertData.password}` : ""}
${alertData.command ? `- Command: ${alertData.command}` : ""}

This attack has been safely contained in the honeypot.

Dashboard: http://localhost:3000
    `
  }

  private getAlertTitle(type: AlertData["type"]): string {
    const titles = {
      login_attempt: "Unauthorized Login Attempt",
      command_execution: "Malicious Command Execution",
      malware_download: "Malware Download Attempt",
      high_severity: "High Severity Attack Detected",
      multiple_attempts: "Multiple Attack Attempts from Same IP",
    }
    return titles[type]
  }

  async testConnection(): Promise<boolean> {
    if (!this.transporter) {
      return false
    }

    try {
      await this.transporter.verify()
      return true
    } catch (error) {
      console.error("Email connection test failed:", error)
      return false
    }
  }

  async debugEmailConfig(): Promise<{
    configured: boolean
    error?: string
    config: {
      host: string
      port: number
      secure: boolean
      user: string
      hasPassword: boolean
      adminEmail: string
    }
  }> {
    try {
      const configured = !!(this.config?.host && this.config?.user && this.config?.password && this.config?.adminEmail)

      return {
        configured,
        config: {
          host: this.config?.host || "Not configured",
          port: this.config?.port || 587,
          secure: this.config?.secure || false,
          user: this.config?.user || "Not configured",
          hasPassword: !!this.config?.password,
          adminEmail: this.config?.adminEmail || "Not configured",
        },
      }
    } catch (error) {
      return {
        configured: false,
        error: error instanceof Error ? error.message : "Unknown error",
        config: {
          host: "Error",
          port: 0,
          secure: false,
          user: "Error",
          hasPassword: false,
          adminEmail: "Error",
        },
      }
    }
  }
}

export const emailService = new EmailService()
export type { AlertData }
