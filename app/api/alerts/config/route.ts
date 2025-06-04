import { NextResponse } from "next/server"
import { loadEmailConfig, validateEmailConfig } from "@/lib/env-loader"

export async function GET() {
  try {
    const config = loadEmailConfig()
    const isValid = validateEmailConfig()

    // Don't expose sensitive data
    const safeConfig = {
      SMTP_HOST: config.SMTP_HOST || "Not configured",
      SMTP_PORT: config.SMTP_PORT || "Not configured",
      SMTP_SECURE: config.SMTP_SECURE || "Not configured",
      SMTP_USER: config.SMTP_USER || "Not configured",
      SMTP_PASSWORD: config.SMTP_PASSWORD ? "Configured" : "Not configured",
      ADMIN_EMAIL: config.ADMIN_EMAIL || "Not configured",
      COWRIE_LOG_PATH: config.COWRIE_LOG_PATH || "Not configured",
      isConfigured: isValid,
    }

    return NextResponse.json({
      success: true,
      config: safeConfig,
      timestamp: new Date().toISOString(),
    })
  } catch (error) {
    console.error("Error loading email config:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Failed to load email configuration",
        message: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}
