import { NextResponse } from "next/server"
import { readFileSync, existsSync } from "fs"
import { join } from "path"

interface CowrieLogEntry {
  eventid: string
  timestamp: string
  src_ip: string
  src_port: number
  dst_ip: string
  dst_port: number
  session: string
  username?: string
  password?: string
  input?: string
  message: string
  sensor: string
  protocol?: string
}

interface ProcessedEvent {
  id: string
  timestamp: string
  sourceIP: string
  country: string
  attackType: string
  username: string
  password: string
  command: string
  session: string
  severity: "low" | "medium" | "high"
}

// Try multiple possible log file paths
function findLogFile(): string | null {
  const possiblePaths = [
    process.env.COWRIE_LOG_PATH,
    "/home/cowrie/cowrie/var/log/cowrie/cowrie.json",
    join(process.cwd(), "cowrie-logs", "cowrie.json"),
    "./cowrie-logs/cowrie.json",
    "/opt/cowrie/var/log/cowrie/cowrie.json",
    "/var/log/cowrie/cowrie.json",
  ]

  for (const path of possiblePaths) {
    if (path && existsSync(path)) {
      try {
        // Test if we can actually read the file
        readFileSync(path, "utf-8")
        return path
      } catch (error) {
        console.log(`Cannot read ${path}:`, error)
        continue
      }
    }
  }

  return null
}

function getCountryFromIP(ip: string): string {
  if (!ip) return "Unknown"

  // Simple IP to country mapping - in production, use a GeoIP database
  const ipRanges: Record<string, string> = {
    "192.168": "Local",
    "10.": "Local",
    "172.": "Local",
    "127.": "Local",
  }

  for (const [range, country] of Object.entries(ipRanges)) {
    if (ip.startsWith(range)) {
      return country
    }
  }

  // Default country assignment based on IP patterns (simplified)
  const lastOctet = Number.parseInt(ip.split(".")[3] || "0")
  const countries = ["China", "Russia", "USA", "Brazil", "India", "Germany", "France", "Unknown"]
  return countries[lastOctet % countries.length]
}

function determineAttackType(eventid: string, input?: string): string {
  if (eventid.includes("login")) {
    return "SSH Brute Force"
  }
  if (input) {
    if (input.includes("wget") || input.includes("curl")) {
      return "Malware Download"
    }
    if (input.includes("chmod") || input.includes("./")) {
      return "Privilege Escalation"
    }
    if (input.includes("cat") && input.includes("passwd")) {
      return "Information Gathering"
    }
    if (input.includes("ps") || input.includes("netstat")) {
      return "System Reconnaissance"
    }
    return "Command Injection"
  }
  return "Connection Attempt"
}

function determineSeverity(eventid: string, input?: string): "low" | "medium" | "high" {
  if (input) {
    const highRiskCommands = ["wget", "curl", "chmod +x", "rm -rf", "dd if=", "mkfs", "./"]
    const mediumRiskCommands = ["cat /etc/passwd", "ps aux", "netstat", "uname"]

    if (highRiskCommands.some((cmd) => input.includes(cmd))) {
      return "high"
    }
    if (mediumRiskCommands.some((cmd) => input.includes(cmd))) {
      return "medium"
    }
  }

  if (eventid.includes("login.failed")) {
    return "low"
  }
  if (eventid.includes("command")) {
    return "medium"
  }

  return "low"
}

function parseLogLine(line: string): CowrieLogEntry | null {
  try {
    if (!line.trim()) return null
    return JSON.parse(line.trim())
  } catch (error) {
    console.error("Error parsing log line:", error)
    return null
  }
}

function processLogEntry(entry: CowrieLogEntry): ProcessedEvent {
  return {
    id: `${entry.session}-${entry.timestamp}`,
    timestamp: entry.timestamp,
    sourceIP: entry.src_ip || "unknown",
    country: getCountryFromIP(entry.src_ip),
    attackType: determineAttackType(entry.eventid, entry.input),
    username: entry.username || "",
    password: entry.password || "",
    command: entry.input || "",
    session: entry.session || "unknown",
    severity: determineSeverity(entry.eventid, entry.input),
  }
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const limit = Number.parseInt(searchParams.get("limit") || "50")

    // Find an accessible log file
    const logPath = findLogFile()

    if (!logPath) {
      console.log("No accessible Cowrie log file found")
      return NextResponse.json({
        success: false,
        error: "Log file not found",
        message: "No accessible Cowrie log file found. Checked multiple locations.",
        events: [],
        searchedPaths: [
          process.env.COWRIE_LOG_PATH,
          "/home/cowrie/cowrie/var/log/cowrie/cowrie.json",
          join(process.cwd(), "cowrie-logs", "cowrie.json"),
          "./cowrie-logs/cowrie.json",
        ],
      })
    }

    console.log(`Using log file: ${logPath}`)

    // Read the log file
    let logContent: string
    try {
      logContent = readFileSync(logPath, "utf-8")
    } catch (readError) {
      console.error("Error reading log file:", readError)
      return NextResponse.json({
        success: false,
        error: "Cannot read log file",
        message: `Permission denied or file error: ${logPath}`,
        events: [],
      })
    }

    if (!logContent.trim()) {
      return NextResponse.json({
        success: true,
        message: "Log file is empty - no attacks detected yet",
        events: [],
        logPath: logPath,
      })
    }

    const lines = logContent
      .trim()
      .split("\n")
      .filter((line) => line.trim())

    // Process the last N lines (most recent events)
    const recentLines = lines.slice(-limit * 2) // Get more lines to filter
    const events: ProcessedEvent[] = []

    for (const line of recentLines.reverse()) {
      const entry = parseLogLine(line)
      if (entry) {
        const processedEvent = processLogEntry(entry)
        events.push(processedEvent)

        if (events.length >= limit) {
          break
        }
      }
    }

    return NextResponse.json({
      success: true,
      events: events,
      totalLines: lines.length,
      logPath: logPath,
    })
  } catch (error) {
    console.error("Error in events API:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error occurred",
        events: [],
      },
      { status: 500 },
    )
  }
}
