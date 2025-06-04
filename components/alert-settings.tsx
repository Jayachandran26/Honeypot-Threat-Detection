"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Switch } from "@/components/ui/switch"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Mail, Settings, Shield, Play, Square, TestTube } from "lucide-react"

interface AlertStatus {
  isMonitoring: boolean
  logPath: string
  activeCooldowns: number
  trackedIPs: number
  alertRules: number
}

export function AlertSettings() {
  const [alertStatus, setAlertStatus] = useState<AlertStatus | null>(null)
  const [emailConfig, setEmailConfig] = useState({
    smtpHost: "",
    smtpPort: "587",
    smtpUser: "",
    smtpPassword: "",
    adminEmail: "",
  })
  const [isLoading, setIsLoading] = useState(false)
  const [testResult, setTestResult] = useState<string | null>(null)
  const [debugInfo, setDebugInfo] = useState<any>(null)

  useEffect(() => {
    fetchAlertStatus()
    loadEmailConfig()
  }, [])

  const fetchAlertStatus = async () => {
    try {
      const response = await fetch("/api/alerts/monitor")
      const data = await response.json()
      if (data.success) {
        setAlertStatus(data.status)
      }
    } catch (error) {
      console.error("Error fetching alert status:", error)
    }
  }

  const loadEmailConfig = () => {
    // Load from localStorage if available
    const saved = localStorage.getItem("emailConfig")
    if (saved) {
      setEmailConfig(JSON.parse(saved))
    }
  }

  const saveEmailConfig = () => {
    localStorage.setItem("emailConfig", JSON.stringify(emailConfig))
    // In a real app, you'd save this to your backend/environment
    alert(
      "Email configuration saved! Please update your environment variables:\n\n" +
        `SMTP_HOST=${emailConfig.smtpHost}\n` +
        `SMTP_PORT=${emailConfig.smtpPort}\n` +
        `SMTP_USER=${emailConfig.smtpUser}\n` +
        `SMTP_PASSWORD=${emailConfig.smtpPassword}\n` +
        `ADMIN_EMAIL=${emailConfig.adminEmail}`,
    )
  }

  const startMonitoring = async () => {
    setIsLoading(true)
    try {
      const response = await fetch("/api/alerts/monitor", { method: "POST" })
      const data = await response.json()
      if (data.success) {
        setAlertStatus(data.status)
        setTestResult("Alert monitoring started successfully!")
      } else {
        setTestResult("Failed to start monitoring: " + data.message)
      }
    } catch (error) {
      setTestResult("Error starting monitoring: " + error)
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
        setAlertStatus((prev) => (prev ? { ...prev, isMonitoring: false } : null))
        setTestResult("Alert monitoring stopped")
      } else {
        setTestResult("Failed to stop monitoring: " + data.message)
      }
    } catch (error) {
      setTestResult("Error stopping monitoring: " + error)
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
        setTestResult("✅ Test alert sent successfully! Check your email.")
      } else {
        setTestResult("❌ Failed to send test alert: " + data.message)
      }
    } catch (error) {
      setTestResult("❌ Error sending test alert: " + error)
    } finally {
      setIsLoading(false)
    }
  }

  const fetchDebugInfo = async () => {
    setIsLoading(true)
    try {
      const response = await fetch("/api/alerts/debug")
      const data = await response.json()
      if (data.success) {
        setDebugInfo(data)
        setTestResult("✅ Debug information retrieved successfully")
      } else {
        setTestResult("❌ Failed to retrieve debug information: " + data.message)
      }
    } catch (error) {
      setTestResult("❌ Error retrieving debug information: " + error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            Alert System Status
          </CardTitle>
          <CardDescription>Real-time monitoring and email alerts for honeypot attacks</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="font-medium">Monitoring Status</span>
                <Badge variant={alertStatus?.isMonitoring ? "default" : "secondary"}>
                  {alertStatus?.isMonitoring ? "Active" : "Inactive"}
                </Badge>
              </div>

              {alertStatus && (
                <>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">Alert Rules</span>
                    <span className="font-mono">{alertStatus.alertRules}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">Active Cooldowns</span>
                    <span className="font-mono">{alertStatus.activeCooldowns}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">Tracked IPs</span>
                    <span className="font-mono">{alertStatus.trackedIPs}</span>
                  </div>
                </>
              )}
            </div>

            <div className="space-y-4">
              <div className="flex gap-2">
                {alertStatus?.isMonitoring ? (
                  <Button onClick={stopMonitoring} disabled={isLoading} variant="destructive" size="sm">
                    <Square className="h-4 w-4 mr-2" />
                    Stop Monitoring
                  </Button>
                ) : (
                  <Button onClick={startMonitoring} disabled={isLoading} size="sm">
                    <Play className="h-4 w-4 mr-2" />
                    Start Monitoring
                  </Button>
                )}

                <Button onClick={testEmailAlert} disabled={isLoading} variant="outline" size="sm">
                  <TestTube className="h-4 w-4 mr-2" />
                  Test Alert
                </Button>
                <Button onClick={fetchDebugInfo} disabled={isLoading} variant="outline" size="sm">
                  <Settings className="h-4 w-4 mr-2" />
                  Debug Config
                </Button>
              </div>

              {testResult && <div className="p-3 bg-gray-50 dark:bg-gray-800 rounded-lg text-sm">{testResult}</div>}
              {debugInfo && (
                <div className="mt-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg text-sm">
                  <h4 className="font-medium mb-2">Email Configuration Debug</h4>

                  <div className="space-y-2">
                    <div className="grid grid-cols-2 gap-2">
                      <span className="font-medium">Configuration Status:</span>
                      <span>{debugInfo.debug.configured ? "✅ Configured" : "❌ Not Configured"}</span>

                      {debugInfo.debug.error && (
                        <>
                          <span className="font-medium">Error:</span>
                          <span className="text-red-500">{debugInfo.debug.error}</span>
                        </>
                      )}
                    </div>

                    <div className="mt-2">
                      <h5 className="font-medium mb-1">Environment Variables:</h5>
                      <div className="bg-gray-100 dark:bg-gray-700 p-2 rounded">
                        <pre className="text-xs overflow-auto">
                          {Object.entries(debugInfo.environment).map(([key, value]) => (
                            <div key={key}>
                              {key}: {value}
                            </div>
                          ))}
                        </pre>
                      </div>
                    </div>

                    {debugInfo.recommendations.length > 0 && (
                      <div className="mt-2">
                        <h5 className="font-medium mb-1">Recommendations:</h5>
                        <ul className="list-disc pl-5 space-y-1">
                          {debugInfo.recommendations.map((rec: string, i: number) => (
                            <li key={i} className="text-blue-600 dark:text-blue-400">
                              {rec}
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      <Tabs defaultValue="email" className="space-y-4">
        <TabsList>
          <TabsTrigger value="email">Email Configuration</TabsTrigger>
          <TabsTrigger value="rules">Alert Rules</TabsTrigger>
        </TabsList>

        <TabsContent value="email">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Mail className="h-5 w-5" />
                Email Alert Configuration
              </CardTitle>
              <CardDescription>Configure SMTP settings for email notifications</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2">SMTP Host</label>
                  <Input
                    placeholder="smtp.gmail.com"
                    value={emailConfig.smtpHost}
                    onChange={(e) => setEmailConfig((prev) => ({ ...prev, smtpHost: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-2">SMTP Port</label>
                  <Input
                    placeholder="587"
                    value={emailConfig.smtpPort}
                    onChange={(e) => setEmailConfig((prev) => ({ ...prev, smtpPort: e.target.value }))}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">SMTP Username</label>
                <Input
                  placeholder="your-email@gmail.com"
                  value={emailConfig.smtpUser}
                  onChange={(e) => setEmailConfig((prev) => ({ ...prev, smtpUser: e.target.value }))}
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">SMTP Password</label>
                <Input
                  type="password"
                  placeholder="your-app-password"
                  value={emailConfig.smtpPassword}
                  onChange={(e) => setEmailConfig((prev) => ({ ...prev, smtpPassword: e.target.value }))}
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Admin Email</label>
                <Input
                  placeholder="admin@yourdomain.com"
                  value={emailConfig.adminEmail}
                  onChange={(e) => setEmailConfig((prev) => ({ ...prev, adminEmail: e.target.value }))}
                />
              </div>

              <Button onClick={saveEmailConfig} className="w-full">
                Save Email Configuration
              </Button>

              <div className="p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-900 rounded-lg">
                <h4 className="font-medium text-blue-800 dark:text-blue-200 mb-2">Gmail Setup Instructions:</h4>
                <ol className="text-sm text-blue-700 dark:text-blue-300 space-y-1">
                  <li>1. Enable 2-factor authentication on your Gmail account</li>
                  <li>2. Generate an App Password: Google Account → Security → App passwords</li>
                  <li>3. Use the App Password (not your regular password) in the SMTP Password field</li>
                  <li>4. Use smtp.gmail.com as the SMTP host with port 587</li>
                </ol>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="rules">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Settings className="h-5 w-5" />
                Alert Rules
              </CardTitle>
              <CardDescription>Configure when alerts are triggered</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="grid gap-4">
                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <h4 className="font-medium">Login Attempts</h4>
                      <p className="text-sm text-gray-600">Alert on SSH/Telnet login attempts</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="outline">Low</Badge>
                      <Switch defaultChecked />
                    </div>
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <h4 className="font-medium">Command Execution</h4>
                      <p className="text-sm text-gray-600">Alert when attackers execute commands</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="secondary">Medium</Badge>
                      <Switch defaultChecked />
                    </div>
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <h4 className="font-medium">Malware Download</h4>
                      <p className="text-sm text-gray-600">Alert on wget/curl download attempts</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="destructive">High</Badge>
                      <Switch defaultChecked />
                    </div>
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <h4 className="font-medium">Privilege Escalation</h4>
                      <p className="text-sm text-gray-600">Alert on chmod, sudo, or dangerous commands</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="destructive">High</Badge>
                      <Switch defaultChecked />
                    </div>
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <h4 className="font-medium">Multiple Attempts</h4>
                      <p className="text-sm text-gray-600">Alert after 5+ attempts from same IP</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="secondary">Medium</Badge>
                      <Switch defaultChecked />
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
