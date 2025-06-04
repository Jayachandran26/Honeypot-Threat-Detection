import { NextResponse } from "next/server"

// Mock data generator for the API
function generateMockEvents(count = 50) {
  const countries = ["China", "Russia", "Brazil", "India", "USA", "Germany", "France"]
  const attackTypes = ["SSH Brute Force", "Command Injection", "File Download", "Privilege Escalation"]
  const usernames = ["root", "admin", "user", "test", "guest", "ubuntu", "pi"]
  const passwords = ["123456", "password", "admin", "root", "12345", "qwerty"]
  const commands = ["ls -la", "cat /etc/passwd", "wget malware.sh", "chmod +x exploit", "ps aux", "netstat -an"]

  return Array.from({ length: count }, (_, i) => ({
    id: Math.random().toString(36).substr(2, 9),
    timestamp: new Date(Date.now() - Math.random() * 3600000).toISOString(),
    sourceIP: `${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}`,
    country: countries[Math.floor(Math.random() * countries.length)],
    attackType: attackTypes[Math.floor(Math.random() * attackTypes.length)],
    username: usernames[Math.floor(Math.random() * usernames.length)],
    password: passwords[Math.floor(Math.random() * passwords.length)],
    command: Math.random() > 0.3 ? commands[Math.floor(Math.random() * commands.length)] : "",
    session: `session_${Math.random().toString(36).substr(2, 6)}`,
    severity: ["low", "medium", "high"][Math.floor(Math.random() * 3)],
  }))
}

export async function GET(request: Request) {
  // Get query parameters
  const { searchParams } = new URL(request.url)
  const limit = Number.parseInt(searchParams.get("limit") || "50")

  // Generate mock data
  const events = generateMockEvents(limit)

  return NextResponse.json(events)
}
