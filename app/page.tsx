"use client"

import { useState, useEffect } from "react"
import { Shield, Terminal, AlertTriangle, Users, Globe, Clock, Key, RefreshCw, Mail } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

interface AttackEvent {
  id: string
  timestamp: string
  sourceIP: string
  country: string
  attackType: string
  username: string
  password: string
  command: string
  session: string
  severity: "low" | "medium" | "high"
}

interface Stats {
  totalAttempts: number
  uniqueIPs: number
  activeSessions: number
  topCountries: { country: string; count: number }[]
  topCommands: { command: string; count: number }[]
  topCredentials: { credential: string; count: number }[]
}

interface CowrieStatus {
  cowrieRunning: boolean
  logFileExists: boolean
  logFileSize: number
  lastModified: string | null
  sshPort: number
  telnetPort: number
  processes: {
    cowrie: boolean
    ssh: boolean
    telnet: boolean
  }
}

export default function CowrieHoneypotDashboard() {
  const [events, setEvents] = useState<AttackEvent[]>([])
  const [stats, setStats] = useState<Stats>({
    totalAttempts: 0,
    uniqueIPs: 0,
    activeSessions: 0,
    topCountries: [],
    topCommands: [],
    topCredentials: [],
  })
  const [cowrieStatus, setCowrieStatus] = useState<CowrieStatus | null>(null)
  const [isClient, setIsClient] = useState(false)
  const [searchTerm, setSearchTerm] = useState("")
  const [selectedSeverity, setSelectedSeverity] = useState("all")
  const [timeRange, setTimeRange] = useState("24h")
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setIsClient(true)
  }, [])

  const fetchCowrieData = async () => {
    setIsLoading(true)
    setError(null)

    try {
      // Fetch events with better error handling
      const eventsResponse = await fetch("/api/cowrie/events?limit=100")

      if (!eventsResponse.ok) {
        throw new Error(`HTTP error! status: ${eventsResponse.status}`)
      }

      const eventsText = await eventsResponse.text()
      let eventsData

      try {
        eventsData = JSON.parse(eventsText)
      } catch (parseError) {
        console.error("Failed to parse events response:", eventsText)
        throw new Error("Invalid JSON response from events API")
      }

      if (eventsData.success === false) {
        setError(eventsData.message || "Failed to fetch events")
        setEvents([])
      } else {
        setEvents(eventsData.events || eventsData || [])
      }

      // Fetch stats with better error handling
      const statsResponse = await fetch("/api/cowrie/stats")

      if (!statsResponse.ok) {
        throw new Error(`HTTP error! status: ${statsResponse.status}`)
      }

      const statsText = await statsResponse.text()
      let statsData

      try {
        statsData = JSON.parse(statsText)
      } catch (parseError) {
        console.error("Failed to parse stats response:", statsText)
        // Use default stats if parsing fails
        statsData = {
          totalAttempts: 0,
          uniqueIPs: 0,
          activeSessions: 0,
          topCountries: [],
          topCommands: [],
          topCredentials: [],
        }
      }

      setStats(statsData)

      // Fetch status with better error handling
      const statusResponse = await fetch("/api/cowrie/status")

      if (!statusResponse.ok) {
        throw new Error(`HTTP error! status: ${statusResponse.status}`)
      }

      const statusText = await statusResponse.text()
      let statusData

      try {
        statusData = JSON.parse(statusText)
      } catch (parseError) {
        console.error("Failed to parse status response:", statusText)
        statusData = null
      }

      setCowrieStatus(statusData)
    } catch (error) {
      console.error("Error fetching Cowrie data:", error)
      setError(error instanceof Error ? error.message : "Failed to connect to Cowrie API")
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    if (!isClient) return

    // Initial fetch
    fetchCowrieData()

    // Set up polling for real-time updates
    const interval = setInterval(fetchCowrieData, 5000) // Poll every 5 seconds

    return () => clearInterval(interval)
  }, [isClient])

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case "high":
        return "bg-red-500"
      case "medium":
        return "bg-yellow-500"
      case "low":
        return "bg-green-500"
      default:
        return "bg-gray-500"
    }
  }

  const getSeverityBadgeVariant = (severity: string) => {
    switch (severity) {
      case "high":
        return "destructive"
      case "medium":
        return "secondary"
      case "low":
        return "outline"
      default:
        return "outline"
    }
  }

  const filteredEvents = events.filter((event) => {
    const matchesSearch =
      searchTerm === "" ||
      event.sourceIP.includes(searchTerm) ||
      event.country.toLowerCase().includes(searchTerm.toLowerCase()) ||
      event.attackType.toLowerCase().includes(searchTerm.toLowerCase())

    const matchesSeverity = selectedSeverity === "all" || event.severity === selectedSeverity

    return matchesSearch && matchesSeverity
  })

  if (!isClient) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <Shield className="h-12 w-12 text-blue-600 mx-auto mb-4 animate-pulse" />
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Loading Dashboard...</h1>
          <p className="text-gray-500 dark:text-gray-400">Connecting to Cowrie Honeypot</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 shadow-md border-b border-blue-500/20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center">
              <div className="relative">
                <Shield className="h-8 w-8 text-blue-600 mr-3" />
                {cowrieStatus?.cowrieRunning && (
                  <span className="absolute -top-1 -right-1 flex h-3 w-3">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                  </span>
                )}
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900 dark:text-white">Cowrie Honeypot Dashboard</h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Real-time SSH/Telnet Attack Monitoring
                  {cowrieStatus && (
                    <span className="ml-2">
                      • SSH:{cowrieStatus.sshPort} • Telnet:{cowrieStatus.telnetPort}
                    </span>
                  )}
                </p>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center">
                <div
                  className={`w-3 h-3 rounded-full mr-2 ${cowrieStatus?.cowrieRunning ? "bg-green-500" : "bg-red-500"}`}
                />
                <span className="text-sm text-gray-600 dark:text-gray-300">
                  {cowrieStatus?.cowrieRunning ? "Cowrie Running" : "Cowrie Stopped"}
                </span>
              </div>
              <Button variant="outline" size="sm" onClick={fetchCowrieData} disabled={isLoading}>
                <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? "animate-spin" : ""}`} />
                Refresh
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Error Message */}
        {error && (
          <div className="mb-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-900 rounded-lg">
            <div className="flex items-center">
              <AlertTriangle className="h-5 w-5 text-red-500 mr-2" />
              <div>
                <h3 className="text-sm font-medium text-red-800 dark:text-red-200">Connection Error</h3>
                <p className="text-sm text-red-700 dark:text-red-300 mt-1">{error}</p>
                <p className="text-xs text-red-600 dark:text-red-400 mt-2">
                  Make sure Cowrie is running and the log path is configured correctly.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Connection Instructions */}
        {cowrieStatus && !cowrieStatus.cowrieRunning && (
          <div className="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-900 rounded-lg">
            <div className="flex items-center">
              <Terminal className="h-5 w-5 text-blue-500 mr-2" />
              <div>
                <h3 className="text-sm font-medium text-blue-800 dark:text-blue-200">How to Attack the Honeypot</h3>
                <p className="text-sm text-blue-700 dark:text-blue-300 mt-1">
                  To see real attack data, try connecting to the honeypot:
                </p>
                <div className="mt-2 space-y-1">
                  <code className="block text-xs bg-blue-100 dark:bg-blue-900 p-2 rounded">
                    ssh root@localhost -p 2222
                  </code>
                  <code className="block text-xs bg-blue-100 dark:bg-blue-900 p-2 rounded">telnet localhost 2223</code>
                </div>
                <p className="text-xs text-blue-600 dark:text-blue-400 mt-2">
                  Try different usernames/passwords and commands to generate attack data.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Filter Controls */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div>
            <Input
              placeholder="Search by IP, country, or attack type..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full"
            />
          </div>
          <div>
            <Select value={selectedSeverity} onValueChange={setSelectedSeverity}>
              <SelectTrigger>
                <SelectValue placeholder="Filter by severity" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Severities</SelectItem>
                <SelectItem value="high">High</SelectItem>
                <SelectItem value="medium">Medium</SelectItem>
                <SelectItem value="low">Low</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div>
            <Select value={timeRange} onValueChange={setTimeRange}>
              <SelectTrigger>
                <SelectValue placeholder="Time range" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="1h">Last Hour</SelectItem>
                <SelectItem value="6h">Last 6 Hours</SelectItem>
                <SelectItem value="24h">Last 24 Hours</SelectItem>
                <SelectItem value="7d">Last 7 Days</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <Card className="border-l-4 border-l-blue-500">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Attempts</CardTitle>
              <Shield className="h-4 w-4 text-blue-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalAttempts.toLocaleString()}</div>
              <p className="text-xs text-muted-foreground">Attack attempts logged</p>
            </CardContent>
          </Card>

          <Card className="border-l-4 border-l-green-500">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Unique IPs</CardTitle>
              <Globe className="h-4 w-4 text-green-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.uniqueIPs}</div>
              <p className="text-xs text-muted-foreground">Distinct attack sources</p>
            </CardContent>
          </Card>

          <Card className="border-l-4 border-l-yellow-500">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Sessions</CardTitle>
              <Users className="h-4 w-4 text-yellow-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.activeSessions}</div>
              <p className="text-xs text-muted-foreground">Currently connected</p>
            </CardContent>
          </Card>

          <Card className="border-l-4 border-l-red-500">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">High Severity</CardTitle>
              <AlertTriangle className="h-4 w-4 text-red-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{events.filter((e) => e.severity === "high").length}</div>
              <p className="text-xs text-muted-foreground">Critical incidents</p>
            </CardContent>
          </Card>
        </div>

        {/* Main Content */}
        <Tabs defaultValue="events" className="space-y-6">
          <TabsList className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
            <TabsTrigger
              value="events"
              className="data-[state=active]:bg-blue-50 dark:data-[state=active]:bg-blue-900/20"
            >
              Live Events ({filteredEvents.length})
            </TabsTrigger>
            <TabsTrigger
              value="commands"
              className="data-[state=active]:bg-blue-50 dark:data-[state=active]:bg-blue-900/20"
            >
              Commands ({stats.topCommands.length})
            </TabsTrigger>
            <TabsTrigger
              value="credentials"
              className="data-[state=active]:bg-blue-50 dark:data-[state=active]:bg-blue-900/20"
            >
              Credentials ({stats.topCredentials.length})
            </TabsTrigger>
            <TabsTrigger
              value="geography"
              className="data-[state=active]:bg-blue-50 dark:data-[state=active]:bg-blue-900/20"
            >
              Geography ({stats.topCountries.length})
            </TabsTrigger>
            <TabsTrigger
              value="system"
              className="data-[state=active]:bg-blue-50 dark:data-[state=active]:bg-blue-900/20"
            >
              System Status
            </TabsTrigger>
            <TabsTrigger
              value="alerts"
              className="data-[state=active]:bg-blue-50 dark:data-[state=active]:bg-blue-900/20"
            >
              Alert Management
            </TabsTrigger>
          </TabsList>

          <TabsContent value="events" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Real-time Attack Events</CardTitle>
                <CardDescription>
                  Live feed from Cowrie honeypot logs
                  {cowrieStatus?.lastModified && (
                    <span className="ml-2 text-xs">
                      Last updated: {new Date(cowrieStatus.lastModified).toLocaleString()}
                    </span>
                  )}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {filteredEvents.length === 0 ? (
                  <div className="text-center py-8">
                    <Terminal className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No Attack Data</h3>
                    <p className="text-gray-500 dark:text-gray-400 mb-4">
                      No attacks detected yet. Try connecting to the honeypot to generate data.
                    </p>
                    <div className="space-y-2">
                      <code className="block text-sm bg-gray-100 dark:bg-gray-800 p-2 rounded">
                        ssh root@localhost -p 2222
                      </code>
                      <code className="block text-sm bg-gray-100 dark:bg-gray-800 p-2 rounded">
                        telnet localhost 2223
                      </code>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4 max-h-[500px] overflow-y-auto pr-2">
                    {filteredEvents.slice(0, 20).map((event) => (
                      <div
                        key={event.id}
                        className="flex items-start justify-between p-4 border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                      >
                        <div className="flex items-start space-x-4">
                          <div className={`w-3 h-3 rounded-full mt-1.5 ${getSeverityColor(event.severity)}`} />
                          <div>
                            <div className="flex items-center space-x-2">
                              <span className="font-mono text-sm font-medium">{event.sourceIP}</span>
                              <Badge variant="outline" className="text-xs">
                                {event.country}
                              </Badge>
                              <Badge variant={getSeverityBadgeVariant(event.severity)} className="text-xs">
                                {event.severity}
                              </Badge>
                            </div>
                            <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                              {event.attackType}
                              {event.username && event.password && (
                                <span>
                                  {" "}
                                  • {event.username}:{event.password}
                                </span>
                              )}
                            </div>
                            {event.command && (
                              <div className="text-xs font-mono bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded mt-1 border-l-2 border-blue-500">
                                $ {event.command}
                              </div>
                            )}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="flex items-center text-xs text-gray-500">
                            <Clock className="h-3 w-3 mr-1" />
                            {new Date(event.timestamp).toLocaleTimeString()}
                          </div>
                          <div className="text-xs text-gray-400 mt-1">{event.session}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
              <CardFooter className="flex justify-between">
                <div className="text-sm text-gray-500">
                  Showing {Math.min(filteredEvents.length, 20)} of {filteredEvents.length} events
                </div>
                <Button variant="outline" size="sm" onClick={fetchCowrieData} disabled={isLoading}>
                  <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? "animate-spin" : ""}`} />
                  Refresh
                </Button>
              </CardFooter>
            </Card>
          </TabsContent>

          <TabsContent value="commands" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Command Analysis</CardTitle>
                <CardDescription>Commands executed by attackers in the honeypot</CardDescription>
              </CardHeader>
              <CardContent>
                {stats.topCommands.length === 0 ? (
                  <div className="text-center py-8">
                    <Terminal className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-500 dark:text-gray-400">No commands executed yet</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {stats.topCommands.map((item, index) => (
                      <div key={index} className="group">
                        <div className="flex items-center justify-between mb-1">
                          <div className="flex items-center">
                            <span className="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center text-xs font-medium text-blue-800 dark:text-blue-200 mr-2">
                              {index + 1}
                            </span>
                            <code className="text-sm font-mono bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded group-hover:bg-blue-50 dark:group-hover:bg-blue-900/20 transition-colors">
                              {item.command}
                            </code>
                          </div>
                          <div className="flex items-center space-x-2">
                            <div className="w-24 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                              <div
                                className="bg-blue-600 h-2 rounded-full"
                                style={{
                                  width: `${Math.max((item.count / (stats.topCommands[0]?.count || 1)) * 100, 5)}%`,
                                }}
                              />
                            </div>
                            <span className="text-sm font-medium">{item.count}</span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="credentials" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Credential Analysis</CardTitle>
                <CardDescription>Username/password combinations attempted by attackers</CardDescription>
              </CardHeader>
              <CardContent>
                {stats.topCredentials.length === 0 ? (
                  <div className="text-center py-8">
                    <Key className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-500 dark:text-gray-400">No login attempts yet</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {stats.topCredentials.map((item, index) => (
                      <div key={index} className="group">
                        <div className="flex items-center justify-between mb-1">
                          <div className="flex items-center">
                            <span className="w-6 h-6 rounded-full bg-purple-100 dark:bg-purple-900 flex items-center justify-center text-xs font-medium text-purple-800 dark:text-purple-200 mr-2">
                              {index + 1}
                            </span>
                            <div className="flex items-center">
                              <Key className="h-4 w-4 mr-2 text-purple-500" />
                              <code className="text-sm font-mono bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded group-hover:bg-purple-50 dark:group-hover:bg-purple-900/20 transition-colors">
                                {item.credential}
                              </code>
                            </div>
                          </div>
                          <div className="flex items-center space-x-2">
                            <div className="w-24 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                              <div
                                className="bg-purple-600 h-2 rounded-full"
                                style={{
                                  width: `${Math.max((item.count / (stats.topCredentials[0]?.count || 1)) * 100, 5)}%`,
                                }}
                              />
                            </div>
                            <span className="text-sm font-medium">{item.count}</span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="geography" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Geographic Attack Distribution</CardTitle>
                <CardDescription>Attack sources by country</CardDescription>
              </CardHeader>
              <CardContent>
                {stats.topCountries.length === 0 ? (
                  <div className="text-center py-8">
                    <Globe className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-500 dark:text-gray-400">No geographic data yet</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {stats.topCountries.map((country, index) => (
                      <div
                        key={country.country}
                        className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg border"
                      >
                        <div className="flex items-center space-x-3">
                          <div className="flex items-center justify-center w-6 h-6 bg-blue-100 dark:bg-blue-900 rounded-full text-xs font-medium text-blue-800 dark:text-blue-200">
                            {index + 1}
                          </div>
                          <span className="font-medium">{country.country}</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <div className="w-24 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                            <div
                              className="bg-blue-600 h-2 rounded-full"
                              style={{
                                width: `${Math.max((country.count / (stats.topCountries[0]?.count || 1)) * 100, 5)}%`,
                              }}
                            />
                          </div>
                          <span className="text-sm text-gray-600 dark:text-gray-400">{country.count}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="system" className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle>Cowrie Status</CardTitle>
                  <CardDescription>Honeypot system status and health</CardDescription>
                </CardHeader>
                <CardContent>
                  {cowrieStatus ? (
                    <div className="space-y-4">
                      <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        <span className="font-medium">Log File</span>
                        <Badge variant={cowrieStatus.logFileExists ? "default" : "destructive"}>
                          {cowrieStatus.logFileExists ? "Found" : "Missing"}
                        </Badge>
                      </div>

                      {cowrieStatus.logFileExists && (
                        <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                          <span className="font-medium">Log Size</span>
                          <span className="text-sm">{(cowrieStatus.logFileSize / 1024).toFixed(1)} KB</span>
                        </div>
                      )}

                      <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        <span className="font-medium">SSH Port ({cowrieStatus.sshPort})</span>
                        <Badge variant={cowrieStatus.processes.ssh ? "default" : "destructive"}>
                          {cowrieStatus.processes.ssh ? "Listening" : "Closed"}
                        </Badge>
                      </div>

                      <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        <span className="font-medium">Telnet Port ({cowrieStatus.telnetPort})</span>
                        <Badge variant={cowrieStatus.processes.telnet ? "default" : "destructive"}>
                          {cowrieStatus.processes.telnet ? "Listening" : "Closed"}
                        </Badge>
                      </div>
                    </div>
                  ) : (
                    <div className="text-center py-4">
                      <p className="text-gray-500 dark:text-gray-400">Loading status...</p>
                    </div>
                  )}
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Quick Actions</CardTitle>
                  <CardDescription>Test the honeypot functionality</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-900 rounded-lg">
                      <h3 className="font-medium text-blue-800 dark:text-blue-200 mb-2">Test SSH Connection</h3>
                      <code className="block text-xs bg-blue-100 dark:bg-blue-900 p-2 rounded mb-2">
                        ssh root@localhost -p 2222
                      </code>
                      <p className="text-xs text-blue-600 dark:text-blue-400">
                        Try passwords like: admin, password, 123456
                      </p>
                    </div>

                    <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-900 rounded-lg">
                      <h3 className="font-medium text-green-800 dark:text-green-200 mb-2">Test Telnet Connection</h3>
                      <code className="block text-xs bg-green-100 dark:bg-green-900 p-2 rounded mb-2">
                        telnet localhost 2223
                      </code>
                      <p className="text-xs text-green-600 dark:text-green-400">
                        Try usernames like: admin, user, guest
                      </p>
                    </div>

                    <Button variant="outline" className="w-full" onClick={fetchCowrieData} disabled={isLoading}>
                      <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? "animate-spin" : ""}`} />
                      Refresh Data
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="alerts" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Email Alert System</CardTitle>
                <CardDescription>Configure real-time email notifications for honeypot attacks</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8">
                  <Mail className="h-12 w-12 text-blue-500 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">Alert System Available</h3>
                  <p className="text-gray-500 dark:text-gray-400 mb-4">
                    Get instant email notifications when attackers interact with your honeypot
                  </p>
                  <Button asChild>
                    <a href="/alerts">Configure Alerts</a>
                  </Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
