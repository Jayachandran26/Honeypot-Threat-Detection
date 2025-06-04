import { NextResponse } from "next/server"
import { existsSync, statSync } from "fs"
import { exec } from "child_process"
import { promisify } from "util"

const execAsync = promisify(exec)
const COWRIE_LOG_PATH = process.env.COWRIE_LOG_PATH || "/home/cowrie/cowrie/var/log/cowrie/cowrie.json"

export async function GET() {
  try {
    const status = {
      success: true,
      cowrieRunning: false,
      logFileExists: false,
      logFileSize: 0,
      lastModified: null as string | null,
      sshPort: 2222,
      telnetPort: 2223,
      processes: {
        cowrie: false,
        ssh: false,
        telnet: false,
      },
      logPath: COWRIE_LOG_PATH,
    }

    // Check if log file exists
    try {
      if (existsSync(COWRIE_LOG_PATH)) {
        status.logFileExists = true
        const stats = statSync(COWRIE_LOG_PATH)
        status.logFileSize = stats.size
        status.lastModified = stats.mtime.toISOString()
      }
    } catch (fileError) {
      console.error("Error checking log file:", fileError)
    }

    // Check if Cowrie processes are running
    try {
      const { stdout } = await execAsync("ps aux | grep cowrie | grep -v grep")
      status.cowrieRunning = stdout.trim().length > 0
      status.processes.cowrie = status.cowrieRunning
    } catch (error) {
      // Process not found - this is normal if cowrie isn't running
      status.cowrieRunning = false
      status.processes.cowrie = false
    }

    // Check if SSH port is listening
    try {
      const { stdout } = await execAsync("netstat -ln | grep :2222 || ss -ln | grep :2222")
      status.processes.ssh = stdout.trim().length > 0
    } catch (error) {
      // Port not listening
      status.processes.ssh = false
    }

    // Check if Telnet port is listening
    try {
      const { stdout } = await execAsync("netstat -ln | grep :2223 || ss -ln | grep :2223")
      status.processes.telnet = stdout.trim().length > 0
    } catch (error) {
      // Port not listening
      status.processes.telnet = false
    }

    return NextResponse.json(status)
  } catch (error) {
    console.error("Error checking Cowrie status:", error)
    return NextResponse.json(
      {
        success: false,
        error: "Status check failed",
        message: error instanceof Error ? error.message : "Unknown error",
        cowrieRunning: false,
        logFileExists: false,
        logFileSize: 0,
        lastModified: null,
        sshPort: 2222,
        telnetPort: 2223,
        processes: {
          cowrie: false,
          ssh: false,
          telnet: false,
        },
        logPath: COWRIE_LOG_PATH,
      },
      { status: 500 },
    )
  }
}
