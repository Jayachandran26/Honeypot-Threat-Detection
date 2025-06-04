import { NextResponse } from "next/server"
import { readFileSync, existsSync } from "fs"

const COWRIE_LOG_PATH = process.env.COWRIE_LOG_PATH || "/home/cowrie/cowrie/var/log/cowrie/cowrie.json"

function getCountryFromIP(ip: string): string {
  if (!ip) return "Unknown"

  if (ip.startsWith("192.168") || ip.startsWith("10.") || ip.startsWith("172.") || ip.startsWith("127.")) {
    return "Local"
  }

  // Simple mapping - replace with real GeoIP in production
  const lastOctet = Number.parseInt(ip.split(".")[3] || "0")
  const countries = ["China", "Russia", "USA", "Brazil", "India", "Germany", "France"]
  return countries[lastOctet % countries.length]
}

export async function GET() {
  try {
    if (!existsSync(COWRIE_LOG_PATH)) {
      return NextResponse.json({
        success: true,
        totalAttempts: 0,
        uniqueIPs: 0,
        activeSessions: 0,
        topCountries: [],
        topCommands: [],
        topCredentials: [],
        message: "Log file not found - no data available",
      })
    }

    let logContent: string
    try {
      logContent = readFileSync(COWRIE_LOG_PATH, "utf-8")
    } catch (readError) {
      console.error("Error reading log file:", readError)
      return NextResponse.json({
        success: false,
        error: "Cannot read log file",
        message: `Permission denied: ${COWRIE_LOG_PATH}`,
        totalAttempts: 0,
        uniqueIPs: 0,
        activeSessions: 0,
        topCountries: [],
        topCommands: [],
        topCredentials: [],
      })
    }

    if (!logContent.trim()) {
      return NextResponse.json({
        success: true,
        totalAttempts: 0,
        uniqueIPs: 0,
        activeSessions: 0,
        topCountries: [],
        topCommands: [],
        topCredentials: [],
        message: "Log file is empty",
      })
    }

    const lines = logContent
      .trim()
      .split("\n")
      .filter((line) => line.trim())

    const stats = {
      totalAttempts: 0,
      uniqueIPs: new Set<string>(),
      activeSessions: new Set<string>(),
      countries: {} as Record<string, number>,
      commands: {} as Record<string, number>,
      credentials: {} as Record<string, number>,
    }

    // Process last 1000 lines for statistics
    const recentLines = lines.slice(-1000)

    for (const line of recentLines) {
      try {
        if (!line.trim()) continue
        const entry = JSON.parse(line.trim())

        stats.totalAttempts++

        if (entry.src_ip) {
          stats.uniqueIPs.add(entry.src_ip)
        }

        if (entry.session) {
          stats.activeSessions.add(entry.session)
        }

        const country = getCountryFromIP(entry.src_ip)
        stats.countries[country] = (stats.countries[country] || 0) + 1

        if (entry.input) {
          stats.commands[entry.input] = (stats.commands[entry.input] || 0) + 1
        }

        if (entry.username && entry.password) {
          const credential = `${entry.username}:${entry.password}`
          stats.credentials[credential] = (stats.credentials[credential] || 0) + 1
        }
      } catch (parseError) {
        // Skip invalid JSON lines
        continue
      }
    }

    const response = {
      success: true,
      totalAttempts: stats.totalAttempts,
      uniqueIPs: stats.uniqueIPs.size,
      activeSessions: stats.activeSessions.size,
      topCountries: Object.entries(stats.countries)
        .map(([country, count]) => ({ country, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10),
      topCommands: Object.entries(stats.commands)
        .map(([command, count]) => ({ command, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10),
      topCredentials: Object.entries(stats.credentials)
        .map(([credential, count]) => ({ credential, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10),
    }

    return NextResponse.json(response)
  } catch (error) {
    console.error("Error generating stats:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error",
        totalAttempts: 0,
        uniqueIPs: 0,
        activeSessions: 0,
        topCountries: [],
        topCommands: [],
        topCredentials: [],
      },
      { status: 500 },
    )
  }
}
