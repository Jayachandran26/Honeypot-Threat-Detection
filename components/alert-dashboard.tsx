"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Shield, Mail, CheckCircle, XCircle, Activity, Bell, Settings, TestTube, RefreshCw } from "lucide-react"

interface AlertStatus {
  isMonitoring: boolean
  logPath: string
  activeCooldowns: number
  trackedIPs: number
  alertRules: number
}

interface AlertSystemStatus {
  status: AlertStatus
  emailConfigured: boolean
  environment: {
    smtpHost: string
    smtpPort: string
    smtpUser: string
    adminEmail: string
    logPath: string
  }
}

export function AlertDashboard() {
  const [systemStatus, setSystemStatus] = useState<AlertSystemStatus | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [testResult, setTestResult] = useState<string | null>(null)
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date())

  useEffect(() => {
    fetchSystemStatus()

    // Auto-refresh every 30 seconds
    const interval = setInterval(() => {
      fetchSystemStatus()
    }, 30000)

    return () => clearInterval(interval)
  }, [])

  const fetchSystemStatus = async () => {
    try {
      const response = await fetch("/api/alerts/status")
      const data = await response.json()

      if (data.success) {
        setSystemStatus(data)
        setLastUpdate(new Date())
      }
    } catch (error) {
      console.error("Error fetching system status:", error)
    }
  }

  const startMonitoring = async () => {
    setIsLoading(true)
    try {
      const response = await fetch("/api/alerts/monitor", { method: "POST" })
      const data = await response.json()

      if (data.success) {
        setTestResult("✅ Alert monitoring started successfully!")
        await fetchSystemStatus()
      } else {
        setTestResult("❌ Failed to start monitoring: " + data.message)
      }
    } catch (error) {
      setTestResult("❌ Error starting monitoring: " + error)
    } finally {
      setIsLoading(false)
    }
  }

  const stopMonitoring = async () => {
    setIsLoading(true)
    try {
      const response = await fetch("/api/alerts/monitor", { method: "DELETE" })
      const data = await response.json()

      if (data.success) {
        setTestResult("🛑 Alert monitoring stopped")
        await fetchSystemStatus()
      } else {
        setTestResult("❌ Failed to stop monitoring: " + data.message)
      }
    } catch (error) {
      setTestResult("❌ Error stopping monitoring: " + error)
    } finally {
      setIsLoading(false)
    }
  }

  const testEmailAlert = async () => {
    setIsLoading(true)
    try {
      const response = await fetch("/api/alerts/test", { method: "POST" })
      const data = await response.json()

      if (data.success) {
        setTestResult("✅ Test alert sent successfully! Check your email inbox.")
      } else {
        setTestResult("❌ Failed to send test alert: " + data.message)
      }
    } catch (error) {
      setTestResult("❌ Error sending test alert: " + error)
    } finally {
      setIsLoading(false)
    }
  }

  if (!systemStatus) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4 text-blue-500" />
          <p className="text-gray-500">Loading alert system status...</p>
        </div>
      </div>
    )
  }

  const { status, emailConfigured, environment } = systemStatus

  return (
    <div className="space-y-6">
      {/* System Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="border-l-4 border-l-blue-500">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Alert System</CardTitle>
            <Shield className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2">
              {status.isMonitoring ? (
                <CheckCircle className="h-5 w-5 text-green-500" />
              ) : (
                <XCircle className="h-5 w-5 text-red-500" />
              )}
              <span className="text-lg font-semibold">{status.isMonitoring ? "Active" : "Inactive"}</span>
            </div>
            <p className="text-xs text-muted-foreground mt-1">Real-time monitoring status</p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-green-500">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Email Alerts</CardTitle>
            <Mail className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-2">
              {emailConfigured ? (
                <CheckCircle className="h-5 w-5 text-green-500" />
              ) : (
                <XCircle className="h-5 w-5 text-red-500" />
              )}
              <span className="text-lg font-semibold">{emailConfigured ? "Configured" : "Not Configured"}</span>
            </div>
            <p className="text-xs text-muted-foreground mt-1">SMTP configuration status</p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-purple-500">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Alert Rules</CardTitle>
            <Bell className="h-4 w-4 text-purple-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{status.alertRules}</div>
            <p className="text-xs text-muted-foreground">Active monitoring rules</p>
          </CardContent>
        </Card>
      </div>

      {/* Detailed Status */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Activity className="h-5 w-5" />
              Monitoring Status
            </CardTitle>
            <CardDescription>Real-time alert system monitoring details</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">System Status</span>
              <Badge variant={status.isMonitoring ? "default" : "destructive"}>
                {status.isMonitoring ? "Running" : "Stopped"}
              </Badge>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Active Cooldowns</span>
              <span className="font-mono text-sm">{status.activeCooldowns}</span>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Tracked IPs</span>
              <span className="font-mono text-sm">{status.trackedIPs}</span>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Log File</span>
              <Badge variant="outline" className="font-mono text-xs">
                {environment.logPath.split("/").pop()}
              </Badge>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Last Update</span>
              <span className="text-xs text-gray-500">{lastUpdate.toLocaleTimeString()}</span>
            </div>

            <div className="pt-4 space-y-2">
              {status.isMonitoring ? (
                <Button onClick={stopMonitoring} disabled={isLoading} variant="destructive" className="w-full">
                  <XCircle className="h-4 w-4 mr-2" />
                  Stop Monitoring
                </Button>
              ) : (
                <Button onClick={startMonitoring} disabled={isLoading} className="w-full">
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Start Monitoring
                </Button>
              )}

              <Button onClick={fetchSystemStatus} disabled={isLoading} variant="outline" className="w-full">
                <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? "animate-spin" : ""}`} />
                Refresh Status
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Mail className="h-5 w-5" />
              Email Configuration
            </CardTitle>
            <CardDescription>SMTP settings and email alert configuration</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">SMTP Host</span>
                <span className="font-mono text-sm text-gray-600">{environment.smtpHost}</span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">SMTP Port</span>
                <span className="font-mono text-sm text-gray-600">{environment.smtpPort}</span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">SMTP User</span>
                <span className="font-mono text-sm text-gray-600">
                  {environment.smtpUser.length > 20
                    ? environment.smtpUser.substring(0, 20) + "..."
                    : environment.smtpUser}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">Admin Email</span>
                <span className="font-mono text-sm text-gray-600">
                  {environment.adminEmail.length > 20
                    ? environment.adminEmail.substring(0, 20) + "..."
                    : environment.adminEmail}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">Configuration</span>
                <Badge variant={emailConfigured ? "default" : "destructive"}>
                  {emailConfigured ? "Complete" : "Incomplete"}
                </Badge>
              </div>
            </div>

            <div className="pt-4 space-y-2">
              <Button
                onClick={testEmailAlert}
                disabled={isLoading || !emailConfigured}
                variant="outline"
                className="w-full"
              >
                <TestTube className="h-4 w-4 mr-2" />
                Send Test Alert
              </Button>

              {!emailConfigured && (
                <div className="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-900 rounded-lg">
                  <p className="text-sm text-yellow-800 dark:text-yellow-200">
                    Email alerts are not configured. Please set up your SMTP settings in the environment variables.
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Test Results */}
      {testResult && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TestTube className="h-5 w-5" />
              Test Results
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
              <p className="text-sm font-mono">{testResult}</p>
            </div>
            <Button onClick={() => setTestResult(null)} variant="ghost" size="sm" className="mt-2">
              Clear
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Alert Rules Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            Active Alert Rules
          </CardTitle>
          <CardDescription>Currently configured alert rules and their severity levels</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Login Attempts</h4>
                <Badge variant="outline">Low</Badge>
              </div>
              <p className="text-sm text-gray-600">SSH/Telnet brute force detection</p>
              <p className="text-xs text-gray-500 mt-1">Cooldown: 5 minutes</p>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Command Execution</h4>
                <Badge variant="secondary">Medium</Badge>
              </div>
              <p className="text-sm text-gray-600">Malicious command monitoring</p>
              <p className="text-xs text-gray-500 mt-1">Cooldown: 2 minutes</p>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Malware Download</h4>
                <Badge variant="destructive">High</Badge>
              </div>
              <p className="text-sm text-gray-600">wget/curl download attempts</p>
              <p className="text-xs text-gray-500 mt-1">Cooldown: 1 minute</p>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Privilege Escalation</h4>
                <Badge variant="destructive">High</Badge>
              </div>
              <p className="text-sm text-gray-600">chmod, sudo, dangerous commands</p>
              <p className="text-xs text-gray-500 mt-1">Cooldown: 1 minute</p>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Multiple Attempts</h4>
                <Badge variant="secondary">Medium</Badge>
              </div>
              <p className="text-sm text-gray-600">5+ attempts from same IP</p>
              <p className="text-xs text-gray-500 mt-1">Cooldown: 10 minutes</p>
            </div>

            <div className="p-4 border rounded-lg border-dashed">
              <div className="text-center text-gray-500">
                <Settings className="h-8 w-8 mx-auto mb-2 opacity-50" />
                <p className="text-sm">More rules coming soon</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
