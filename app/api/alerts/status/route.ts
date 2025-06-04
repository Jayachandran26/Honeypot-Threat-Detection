import { NextResponse } from "next/server"
import { AlertMonitor } from "@/lib/alert-monitor"

export async function GET() {
  try {
    // Initialize global monitor if not exists
    const monitor = AlertMonitor.initializeGlobalMonitor()

    const status = monitor.getStatus()

    return NextResponse.json({
      success: true,
      status: status,
      emailConfigured: !!(
        process.env.SMTP_HOST &&
        process.env.SMTP_USER &&
        process.env.SMTP_PASSWORD &&
        process.env.ADMIN_EMAIL
      ),
      environment: {
        smtpHost: process.env.SMTP_HOST || "Not configured",
        smtpPort: process.env.SMTP_PORT || "587",
        smtpUser: process.env.SMTP_USER || "Not configured",
        adminEmail: process.env.ADMIN_EMAIL || "Not configured",
        logPath: process.env.COWRIE_LOG_PATH || "./cowrie-logs/cowrie.json",
      },
    })
  } catch (error) {
    console.error("Error getting alert status:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Failed to get alert status",
        message: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}
