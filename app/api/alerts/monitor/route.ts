import { NextResponse } from "next/server"
import { DualLogMonitor } from "@/lib/dual-log-monitor"

export async function GET() {
  try {
    // Initialize the dual log monitor
    const monitor = DualLogMonitor.initializeGlobalMonitor()
    const status = monitor.getStatus()

    return NextResponse.json({
      success: true,
      message: "Dual log monitoring active",
      status: status,
    })
  } catch (error) {
    console.error("Error in monitor API:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Failed to start monitoring",
        message: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}

export async function POST() {
  try {
    const monitor = DualLogMonitor.initializeGlobalMonitor()

    return NextResponse.json({
      success: true,
      message: "Dual log monitoring started",
      status: monitor.getStatus(),
    })
  } catch (error) {
    console.error("Error starting monitor:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Failed to start monitoring",
        message: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}

export async function DELETE() {
  try {
    if (global.dualLogMonitor) {
      global.dualLogMonitor.stopMonitoring()
      global.dualLogMonitor = undefined
    }

    return NextResponse.json({
      success: true,
      message: "Monitoring stopped",
    })
  } catch (error) {
    console.error("Error stopping monitor:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Failed to stop monitoring",
        message: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}
