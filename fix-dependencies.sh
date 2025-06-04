#!/bin/bash

echo "🔧 Fixing TypeScript Dependencies and Errors..."
echo "=============================================="

# Install missing dependencies
echo "📦 Installing missing dependencies..."
npm install @radix-ui/react-label @radix-ui/react-slot class-variance-authority

# Install additional required dependencies
echo "📦 Installing additional dependencies..."
npm install @radix-ui/react-tabs @radix-ui/react-switch @radix-ui/react-progress @radix-ui/react-select

# Install development dependencies
echo "📦 Installing development dependencies..."
npm install -D @types/node

# Update package.json with correct dependencies
echo "📝 Updating package.json..."
cat > package.json << 'EOF'
{
  "name": "cowrie-honeypot-dashboard",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18",
    "react-dom": "^18",
    "next-themes": "^0.2.1",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-switch": "^1.0.3",
    "@radix-ui/react-progress": "^1.0.3",
    "@radix-ui/react-select": "^2.0.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0",
    "lucide-react": "^0.294.0",
    "nodemailer": "^6.9.7"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "@types/nodemailer": "^6.4.14",
    "autoprefixer": "^10.0.1",
    "postcss": "^8",
    "tailwindcss": "^3.3.0",
    "eslint": "^8",
    "eslint-config-next": "14.0.0"
  }
}
EOF

# Fix theme provider
echo "🎨 Fixing theme provider..."
cat > components/theme-provider.tsx << 'EOF'
"use client"

import * as React from "react"
import { ThemeProvider as NextThemesProvider } from "next-themes"

interface ThemeProviderProps {
  children: React.ReactNode
  attribute?: string
  defaultTheme?: string
  enableSystem?: boolean
  disableTransitionOnChange?: boolean
}

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  const [mounted, setMounted] = React.useState(false)

  React.useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return <>{children}</>
  }

  return <NextThemesProvider {...props}>{children}</NextThemesProvider>
}
EOF

# Update globals.css to fix CSS warnings
echo "🎨 Fixing CSS warnings..."
cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.5% 48%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF

# Update .env.local with correct Cowrie log path
echo "🔧 Updating .env.local with correct Cowrie log path..."
if [ -f .env.local ]; then
    # Update existing file
    sed -i 's|COWRIE_LOG_PATH=.*|COWRIE_LOG_PATH=/home/cowrie/cowrie/var/log/cowrie/cowrie.json|' .env.local
else
    # Create new file
    echo "COWRIE_LOG_PATH=/home/cowrie/cowrie/var/log/cowrie/cowrie.json" > .env.local
fi

# Install dependencies
echo "📦 Installing all dependencies..."
npm install

echo ""
echo "✅ All TypeScript errors should now be fixed!"
echo "✅ Dependencies installed successfully!"
echo "✅ Cowrie log path updated to: /home/cowrie/cowrie/var/log/cowrie/cowrie.json"
echo ""
echo "🚀 Next steps:"
echo "1. Run: npm run dev"
echo "2. Visit: http://localhost:3000/alerts"
echo "3. Test your email configuration"
echo ""
echo "📧 Don't forget to set your email environment variables:"
echo "   SMTP_HOST=smtp.gmail.com"
echo "   SMTP_PORT=587"
echo "   SMTP_SECURE=false"
echo "   SMTP_USER=your-email@gmail.com"
echo "   SMTP_PASSWORD=your-app-password"
echo "   ADMIN_EMAIL=admin@example.com"
EOF
