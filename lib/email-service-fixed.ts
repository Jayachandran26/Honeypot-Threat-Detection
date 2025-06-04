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

class EmailServiceFixed {
  private transporter: nodemailer.Transporter | null = null
  private config: EmailConfig | null = null
  private isInitialized = false

  constructor() {
    // Don't initialize in constructor - do it when needed
  }

  private async initializeTransporter(): Promise<boolean> {
    try {
      console.log("🔧 Initializing email service...")

      // Get environment variables with detailed logging
      const envVars = {
        SMTP_HOST: process.env.SMTP_HOST,
        SMTP_PORT: process.env.SMTP_PORT,
        SMTP_SECURE: process.env.SMTP_SECURE,
        SMTP_USER: process.env.SMTP_USER,
        SMTP_PASSWORD: process.env.SMTP_PASSWORD,
        ADMIN_EMAIL: process.env.ADMIN_EMAIL,
      }

      console.log("📋 Environment variables check:")
      Object.entries(envVars).forEach(([key, value]) => {
        if (key === "SMTP_PASSWORD") {
          console.log(`  ${key}: ${value ? "***SET***" : "NOT SET"}`)
        } else {
          console.log(`  ${key}: ${value || "NOT SET"}`)
        }
      })

      this.config = {
        host: envVars.SMTP_HOST || "smtp.gmail.com",
        port: Number.parseInt(envVars.SMTP_PORT || "587"),
        secure: envVars.SMTP_SECURE === "true",
        user: envVars.SMTP_USER || "",
        password: envVars.SMTP_PASSWORD || "",
        adminEmail: envVars.ADMIN_EMAIL || "",
      }

      // Validate required fields
      const missingFields = []
      if (!this.config.user) missingFields.push("SMTP_USER")
      if (!this.config.password) missingFields.push("SMTP_PASSWORD")
      if (!this.config.adminEmail) missingFields.push("ADMIN_EMAIL")

      if (missingFields.length > 0) {
        console.error("❌ Missing required environment variables:", missingFields.join(", "))
        return false
      }

      console.log("✅ All required environment variables are set")
      console.log(`📧 Email service config:`)
      console.log(`  Host: ${this.config.host}`)
      console.log(`  Port: ${this.config.port}`)
      console.log(`  Secure: ${this.config.secure}`)
      console.log(`  User: ${this.config.user}`)
      console.log(`  Admin: ${this.config.adminEmail}`)

      // Create transporter
      this.transporter = nodemailer.createTransport({
        host: this.config.host,
        port: this.config.port,
        secure: this.config.secure,
        auth: {
          user: this.config.user,
          pass: this.config.password,
        },
        debug: true, // Enable debug logging
        logger: true, // Enable logging
      })

      // Test the connection
      console.log("🔍 Testing SMTP connection...")
      await this.transporter.verify()
      console.log("✅ SMTP connection verified successfully")

      this.isInitialized = true
      return true
    } catch (error) {
      console.error("❌ Failed to initialize email service:", error)
      this.transporter = null
      this.isInitialized = false
      return false
    }
  }

  async sendAlert(alertData: AlertData): Promise<{ success: boolean; error?: string }> {
    try {
      // Always try to initialize before sending
      if (!this.isInitialized) {
        const initialized = await this.initializeTransporter()
        if (!initialized) {
          return { success: false, error: "Email service initialization failed" }
        }
      }

      if (!this.transporter || !this.config) {
        return { success: false, error: "Email service not properly configured" }
      }

      const subject = this.generateSubject(alertData)
      const htmlContent = this.generateHtmlContent(alertData)
      const textContent = this.generateTextContent(alertData)

      console.log(`📧 Sending alert email to: ${this.config.adminEmail}`)
      console.log(`📋 Subject: ${subject}`)

      const mailOptions = {
        from: `"Cowrie Honeypot Alert" <${this.config.user}>`,
        to: this.config.adminEmail,
        subject: subject,
        text: textContent,
        html: htmlContent,
      }

      const result = await this.transporter.sendMail(mailOptions)
      console.log("✅ Alert email sent successfully:", result.messageId)
      return { success: true }
    } catch (error) {
      console.error("❌ Failed to send alert email:", error)
      return {
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }
    }
  }

  async sendTestAlert(): Promise<{ success: boolean; error?: string }> {
    const testAlertData: AlertData = {
      type: "login_attempt",
      sourceIP: "192.168.1.100",
      country: "Test Country",
      username: "test_user",
      password: "test_password",
      command: "ls -la",
      timestamp: new Date().toISOString(),
      severity: "medium",
      session: "test_session_" + Date.now(),
    }

    console.log("🧪 Sending test alert...")
    return await this.sendAlert(testAlertData)
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
            </div>
            
            <div class="footer">
                <p>This alert was generated by your Cowrie Honeypot monitoring system.</p>
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

  async getDebugInfo(): Promise<{
    configured: boolean
    error?: string
    config: any
    environmentVariables: any
  }> {
    try {
      // Force re-initialization to get fresh environment variables
      this.isInitialized = false
      const initialized = await this.initializeTransporter()

      const envVars = {
        SMTP_HOST: process.env.SMTP_HOST || "NOT SET",
        SMTP_PORT: process.env.SMTP_PORT || "NOT SET",
        SMTP_SECURE: process.env.SMTP_SECURE || "NOT SET",
        SMTP_USER: process.env.SMTP_USER || "NOT SET",
        SMTP_PASSWORD: process.env.SMTP_PASSWORD ? "SET (hidden)" : "NOT SET",
        ADMIN_EMAIL: process.env.ADMIN_EMAIL || "NOT SET",
      }

      return {
        configured: initialized,
        config: this.config || {},
        environmentVariables: envVars,
      }
    } catch (error) {
      return {
        configured: false,
        error: error instanceof Error ? error.message : "Unknown error",
        config: {},
        environmentVariables: {},
      }
    }
  }
}

// Create a singleton instance
export const emailServiceFixed = new EmailServiceFixed()
export type { AlertData }
