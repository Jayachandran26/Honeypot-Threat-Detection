import { NextResponse } from "next/server"
import { emailServiceFixed } from "@/lib/email-service-fixed"

export async function POST() {
  try {
    console.log("🧪 Test alert API called")

    // Get debug info first
    const debugInfo = await emailServiceFixed.getDebugInfo()
    console.log("📋 Debug info:", debugInfo)

    if (!debugInfo.configured) {
      return NextResponse.json({
        success: false,
        message: "Email service is not properly configured",
        debug: debugInfo,
      })
    }

    // Send test alert
    const result = await emailServiceFixed.sendTestAlert()

    if (result.success) {
      return NextResponse.json({
        success: true,
        message: "Test alert sent successfully! Check your email inbox.",
      })
    } else {
      return NextResponse.json({
        success: false,
        message: `Failed to send test alert: ${result.error}`,
        debug: debugInfo,
      })
    }
  } catch (error) {
    console.error("❌ Error in test alert API:", error)
    return NextResponse.json(
      {
        success: false,
        message: "Internal server error",
        error: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}
