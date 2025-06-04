import { readFileSync, existsSync, watchFile, unwatchFile } from "fs"
import { emailService, type AlertData } from "./email-service"

interface LogEntry {
  eventid: string
  timestamp: string
  src_ip: string
  username?: string
  password?: string
  input?: string
  session: string
  message: string
}

interface AlertRule {
  id: string
  name: string
  condition: (entry: LogEntry) => boolean
  severity: "low" | "medium" | "high"
  type: AlertData["type"]
  cooldown: number
}

class DualLogMonitor {
  private primaryLogPath: string // Real Cowrie log
  private secondaryLogPath: string // Project log copy
  private lastPosition = 0
  private alertCooldowns: Map<string, number> = new Map()
  private ipAttempts: Map<string, number> = new Map()
  private isMonitoring = false

  private alertRules: AlertRule[] = [
    {
      id: "login_attempt",
      name: "Login Attempt",
      condition: (entry) => entry.eventid.includes("login"),
      severity: "low",
      type: "login_attempt",
      cooldown: 5,
    },
    {
      id: "command_execution",
      name: "Command Execution",
      condition: (entry) => entry.eventid.includes("command") && entry.input,
      severity: "medium",
      type: "command_execution",
      cooldown: 2,
    },
    {
      id: "malware_download",
      name: "Malware Download",
      condition: (entry) =>
        entry.input &&
        (entry.input.includes("wget") || entry.input.includes("curl") || entry.input.includes("download")),
      severity: "high",
      type: "malware_download",
      cooldown: 1,
    },
    {
      id: "privilege_escalation",
      name: "Privilege Escalation",
      condition: (entry) =>
        entry.input &&
        (entry.input.includes("chmod +x") ||
          entry.input.includes("sudo") ||
          entry.input.includes("./") ||
          entry.input.includes("rm -rf")),
      severity: "high",
      type: "high_severity",
      cooldown: 1,
    },
    {
      id: "multiple_attempts",
      name: "Multiple Attempts",
      condition: (entry) => {
        const attempts = this.ipAttempts.get(entry.src_ip) || 0
        this.ipAttempts.set(entry.src_ip, attempts + 1)
        return attempts >= 5
      },
      severity: "medium",
      type: "multiple_attempts",
      cooldown: 10,
    },
  ]

  constructor(primaryLogPath: string, secondaryLogPath: string) {
    this.primaryLogPath = primaryLogPath
    this.secondaryLogPath = secondaryLogPath
    this.initializePosition()
  }

  private initializePosition() {
    try {
      // Try primary log first, then secondary
      const logPath = existsSync(this.primaryLogPath) ? this.primaryLogPath : this.secondaryLogPath
      if (existsSync(logPath)) {
        const content = readFileSync(logPath, "utf-8")
        this.lastPosition = Buffer.byteLength(content, "utf-8")
      }
    } catch (error) {
      console.error("Error initializing log position:", error)
    }
  }

  startMonitoring() {
    if (this.isMonitoring) {
      console.log("Dual log monitor is already running")
      return
    }

    this.isMonitoring = true
    console.log("🚨 Starting dual log monitor...")
    console.log(`📁 Primary log: ${this.primaryLogPath}`)
    console.log(`📁 Secondary log: ${this.secondaryLogPath}`)

    // Watch both log files
    this.watchLogFile(this.primaryLogPath, "primary")
    this.watchLogFile(this.secondaryLogPath, "secondary")

    // Clean up old data every 5 minutes
    setInterval(
      () => {
        this.cleanupOldData()
      },
      5 * 60 * 1000,
    )

    console.log("✅ Dual log monitor started successfully")
  }

  stopMonitoring() {
    this.isMonitoring = false
    unwatchFile(this.primaryLogPath)
    unwatchFile(this.secondaryLogPath)
    console.log("🛑 Dual log monitor stopped")
  }

  private watchLogFile(logPath: string, type: "primary" | "secondary") {
    if (!existsSync(logPath)) {
      console.log(`⚠️ Log file not found: ${logPath} (${type})`)
      return
    }

    console.log(`👀 Watching ${type} log: ${logPath}`)

    watchFile(logPath, { interval: 1000 }, () => {
      this.checkForNewEntries(logPath, type)
    })
  }

  private async checkForNewEntries(logPath: string, type: "primary" | "secondary") {
    try {
      if (!existsSync(logPath)) {
        return
      }

      const content = readFileSync(logPath, "utf-8")
      const currentSize = Buffer.byteLength(content, "utf-8")

      if (currentSize <= this.lastPosition) {
        return
      }

      // Get new content since last check
      const newContent = content.slice(this.lastPosition)
      this.lastPosition = currentSize

      // Process new log entries
      const newLines = newContent
        .trim()
        .split("\n")
        .filter((line) => line.trim())

      console.log(`📝 Processing ${newLines.length} new log entries from ${type} log`)

      for (const line of newLines) {
        await this.processLogEntry(line)
      }
    } catch (error) {
      console.error(`Error checking ${type} log entries:`, error)
    }
  }

  private async processLogEntry(line: string) {
    try {
      const entry: LogEntry = JSON.parse(line.trim())

      // Check each alert rule
      for (const rule of this.alertRules) {
        if (this.shouldTriggerAlert(rule, entry)) {
          await this.triggerAlert(rule, entry)
        }
      }
    } catch (error) {
      // Skip invalid JSON lines
      return
    }
  }

  private shouldTriggerAlert(rule: AlertRule, entry: LogEntry): boolean {
    if (!rule.condition(entry)) {
      return false
    }

    const cooldownKey = `${rule.id}-${entry.src_ip}`
    const lastAlert = this.alertCooldowns.get(cooldownKey)
    const now = Date.now()

    if (lastAlert && now - lastAlert < rule.cooldown * 60 * 1000) {
      return false
    }

    return true
  }

  private async triggerAlert(rule: AlertRule, entry: LogEntry) {
    try {
      const alertData: AlertData = {
        type: rule.type,
        sourceIP: entry.src_ip,
        country: this.getCountryFromIP(entry.src_ip),
        username: entry.username,
        password: entry.password,
        command: entry.input,
        timestamp: entry.timestamp,
        severity: rule.severity,
        session: entry.session,
      }

      console.log(`🚨 ALERT TRIGGERED: ${rule.name} from ${entry.src_ip}`)

      // Send email alert
      const emailSent = await emailService.sendAlert(alertData)

      if (emailSent) {
        console.log("✅ Alert email sent successfully")
      } else {
        console.log("❌ Failed to send alert email")
      }

      // Set cooldown
      const cooldownKey = `${rule.id}-${entry.src_ip}`
      this.alertCooldowns.set(cooldownKey, Date.now())

      // Log alert to console
      this.logAlertToConsole(rule, entry)
    } catch (error) {
      console.error("Error triggering alert:", error)
    }
  }

  private logAlertToConsole(rule: AlertRule, entry: LogEntry) {
    console.log("🚨 SECURITY ALERT 🚨")
    console.log("===================")
    console.log(`Rule: ${rule.name}`)
    console.log(`Severity: ${rule.severity.toUpperCase()}`)
    console.log(`Source IP: ${entry.src_ip}`)
    console.log(`Timestamp: ${new Date(entry.timestamp).toLocaleString()}`)
    console.log(`Session: ${entry.session}`)
    if (entry.username) console.log(`Username: ${entry.username}`)
    if (entry.password) console.log(`Password: ${entry.password}`)
    if (entry.input) console.log(`Command: ${entry.input}`)
    console.log("===================")
  }

  private getCountryFromIP(ip: string): string {
    if (ip.startsWith("192.168") || ip.startsWith("10.") || ip.startsWith("127.")) {
      return "Local"
    }

    const lastOctet = Number.parseInt(ip.split(".")[3] || "0")
    const countries = ["China", "Russia", "USA", "Brazil", "India", "Germany", "France"]
    return countries[lastOctet % countries.length]
  }

  private cleanupOldData() {
    const now = Date.now()
    const maxAge = 60 * 60 * 1000

    for (const [key, timestamp] of this.alertCooldowns.entries()) {
      if (now - timestamp > maxAge) {
        this.alertCooldowns.delete(key)
      }
    }

    this.ipAttempts.clear()
  }

  getStatus() {
    return {
      isMonitoring: this.isMonitoring,
      primaryLogPath: this.primaryLogPath,
      secondaryLogPath: this.secondaryLogPath,
      primaryLogExists: existsSync(this.primaryLogPath),
      secondaryLogExists: existsSync(this.secondaryLogPath),
      activeCooldowns: this.alertCooldowns.size,
      trackedIPs: this.ipAttempts.size,
      alertRules: this.alertRules.length,
    }
  }

  static initializeGlobalMonitor() {
    const primaryLogPath = "/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
    const secondaryLogPath = process.env.COWRIE_LOG_PATH || "./cowrie-logs/cowrie.json"

    if (!global.dualLogMonitor) {
      global.dualLogMonitor = new DualLogMonitor(primaryLogPath, secondaryLogPath)
      global.dualLogMonitor.startMonitoring()
      console.log("🚨 Global dual log monitor initialized and started")
    }

    return global.dualLogMonitor
  }
}

export { DualLogMonitor }

declare global {
  var dualLogMonitor: DualLogMonitor | undefined
}
