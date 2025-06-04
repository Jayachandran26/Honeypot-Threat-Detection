import { NextResponse } from "next/server"
import { emailServiceFixed } from "@/lib/email-service-fixed"

export async function GET() {
  try {
    const debugInfo = await emailServiceFixed.getDebugInfo()

    // Add recommendations based on the debug info
    const recommendations: string[] = []

    if (!debugInfo.environmentVariables.SMTP_HOST || debugInfo.environmentVariables.SMTP_HOST === "NOT SET") {
      recommendations.push("Set the SMTP_HOST environment variable (e.g., smtp.gmail.com)")
    }

    if (!debugInfo.environmentVariables.SMTP_USER || debugInfo.environmentVariables.SMTP_USER === "NOT SET") {
      recommendations.push("Set the SMTP_USER environment variable (your email address)")
    }

    if (!debugInfo.environmentVariables.SMTP_PASSWORD || debugInfo.environmentVariables.SMTP_PASSWORD === "NOT SET") {
      recommendations.push("Set the SMTP_PASSWORD environment variable (your app password)")
    }

    if (!debugInfo.environmentVariables.ADMIN_EMAIL || debugInfo.environmentVariables.ADMIN_EMAIL === "NOT SET") {
      recommendations.push("Set the ADMIN_EMAIL environment variable (where alerts will be sent)")
    }

    if (debugInfo.environmentVariables.SMTP_HOST?.includes("gmail") && recommendations.length === 0) {
      recommendations.push("For Gmail: Make sure you're using an App Password, not your regular password")
      recommendations.push("Enable 2FA on your Gmail account and generate an App Password")
    }

    return NextResponse.json({
      success: true,
      debug: debugInfo,
      recommendations,
      timestamp: new Date().toISOString(),
    })
  } catch (error) {
    console.error("Error in debug API:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Failed to get debug information",
        message: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}
