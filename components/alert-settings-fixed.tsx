"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useToast } from "@/hooks/use-toast"
import { Activity, AlertCircle, Mail, RefreshCw, Send, X } from "lucide-react"

export function AlertSettingsFixed() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(false)
  const [testLoading, setTestLoading] = useState(false)
  const [testResults, setTestResults] = useState<string | null>(null)
  const [testSuccess, setTestSuccess] = useState<boolean | null>(null)
  const [debugInfo, setDebugInfo] = useState<any>(null)
  const [showDebug, setShowDebug] = useState(false)

  const handleSendTestAlert = async () => {
    try {
      setTestLoading(true)
      setTestResults(null)
      setTestSuccess(null)

      const response = await fetch("/api/alerts/test", {
        method: "POST",
      })

      const data = await response.json()
      setTestResults(data.message)
      setTestSuccess(data.success)

      toast({
        title: data.success ? "Test Alert Sent" : "Test Alert Failed",
        description: data.message,
        variant: data.success ? "default" : "destructive",
      })
    } catch (error) {
      console.error("Error sending test alert:", error)
      setTestResults("An error occurred while sending the test alert")
      setTestSuccess(false)
      toast({
        title: "Error",
        description: "An error occurred while sending the test alert",
        variant: "destructive",
      })
    } finally {
      setTestLoading(false)
    }
  }

  const handleDebugConfig = async () => {
    try {
      setLoading(true)
      const response = await fetch("/api/alerts/debug")
      const data = await response.json()
      setDebugInfo(data)
      setShowDebug(true)
    } catch (error) {
      console.error("Error fetching debug info:", error)
      toast({
        title: "Error",
        description: "Failed to fetch debug information",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Mail className="h-5 w-5" />
            Email Configuration
          </CardTitle>
          <CardDescription>SMTP settings and email alert configuration</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="smtp-host">SMTP Host</Label>
              <Input id="smtp-host" value={process.env.SMTP_HOST || "smtp.gmail.com"} disabled />
            </div>
            <div className="space-y-2">
              <Label htmlFor="smtp-port">SMTP Port</Label>
              <Input id="smtp-port" value={process.env.SMTP_PORT || "587"} disabled />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="smtp-user">SMTP User</Label>
            <Input id="smtp-user" value={process.env.SMTP_USER || "your-email@gmail.com"} disabled />
          </div>

          <div className="space-y-2">
            <Label htmlFor="admin-email">Admin Email</Label>
            <Input id="admin-email" value={process.env.ADMIN_EMAIL || "admin@example.com"} disabled />
          </div>

          <div className="space-y-2">
            <Label htmlFor="configuration">Configuration</Label>
            <div className="flex items-center justify-between rounded-md border p-3">
              <div className="space-y-0.5">
                <div className="text-sm font-medium">Complete</div>
                <div className="text-xs text-muted-foreground">Email settings are configured</div>
              </div>
              <Button variant="outline" onClick={handleDebugConfig} disabled={loading}>
                {loading ? <RefreshCw className="mr-2 h-4 w-4 animate-spin" /> : null}
                Debug Config
              </Button>
            </div>
          </div>
        </CardContent>
        <CardFooter>
          <Button className="w-full" onClick={handleSendTestAlert} disabled={testLoading}>
            {testLoading ? <RefreshCw className="mr-2 h-4 w-4 animate-spin" /> : <Send className="mr-2 h-4 w-4" />}
            Send Test Alert
          </Button>
        </CardFooter>
      </Card>

      {testResults && (
        <Card className={testSuccess ? "border-green-500" : "border-red-500"}>
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-base">
              {testSuccess ? (
                <Activity className="h-5 w-5 text-green-500" />
              ) : (
                <AlertCircle className="h-5 w-5 text-red-500" />
              )}
              Test Results
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-2">
              {testSuccess ? (
                <div className="text-green-500">{testResults}</div>
              ) : (
                <div className="text-red-500">{testResults}</div>
              )}
            </div>
          </CardContent>
          <CardFooter className="pt-0">
            <Button variant="outline" size="sm" onClick={() => setTestResults(null)}>
              <X className="mr-2 h-4 w-4" />
              Clear
            </Button>
          </CardFooter>
        </Card>
      )}

      {showDebug && debugInfo && (
        <Card className="border-blue-500">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-base">
              <Activity className="h-5 w-5 text-blue-500" />
              Debug Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <h3 className="text-sm font-medium">Environment Variables</h3>
              <div className="rounded-md bg-muted p-3">
                <pre className="text-xs overflow-auto">
                  {JSON.stringify(debugInfo.debug.environmentVariables, null, 2)}
                </pre>
              </div>
            </div>

            {debugInfo.recommendations && debugInfo.recommendations.length > 0 && (
              <div className="space-y-2">
                <h3 className="text-sm font-medium">Recommendations</h3>
                <ul className="list-disc pl-5 space-y-1">
                  {debugInfo.recommendations.map((rec: string, i: number) => (
                    <li key={i} className="text-sm text-amber-600">
                      {rec}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <div className="space-y-2">
              <h3 className="text-sm font-medium">Configuration Status</h3>
              <div className="flex items-center gap-2">
                {debugInfo.debug.configured ? (
                  <div className="text-green-500">Email service is properly configured</div>
                ) : (
                  <div className="text-red-500">Email service is not properly configured</div>
                )}
              </div>
            </div>
          </CardContent>
          <CardFooter className="pt-0">
            <Button variant="outline" size="sm" onClick={() => setShowDebug(false)}>
              <X className="mr-2 h-4 w-4" />
              Close
            </Button>
          </CardFooter>
        </Card>
      )}
    </div>
  )
}
