// Environment variable loader with validation
export function loadEmailConfig() {
  const config = {
    SMTP_HOST: process.env.SMTP_HOST || "",
    SMTP_PORT: process.env.SMTP_PORT || "587",
    SMTP_SECURE: process.env.SMTP_SECURE || "false",
    SMTP_USER: process.env.SMTP_USER || "",
    SMTP_PASSWORD: process.env.SMTP_PASSWORD || "",
    ADMIN_EMAIL: process.env.ADMIN_EMAIL || "",
    COWRIE_LOG_PATH: process.env.COWRIE_LOG_PATH || "",
  }

  console.log("🔍 Loading email configuration...")
  console.log("Environment variables status:")
  Object.entries(config).forEach(([key, value]) => {
    if (key === "SMTP_PASSWORD") {
      console.log(`  ${key}: ${value ? "***SET***" : "NOT SET"}`)
    } else {
      console.log(`  ${key}: ${value || "NOT SET"}`)
    }
  })

  return config
}

export function validateEmailConfig() {
  const config = loadEmailConfig()

  const required = ["SMTP_HOST", "SMTP_USER", "SMTP_PASSWORD", "ADMIN_EMAIL"]
  const missing = required.filter((key) => !config[key as keyof typeof config])

  if (missing.length > 0) {
    console.error("❌ Missing required environment variables:", missing.join(", "))
    return false
  }

  console.log("✅ All required environment variables are set")
  return true
}
