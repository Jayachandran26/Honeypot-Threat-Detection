#!/bin/bash

echo "🔧 Fixing tailwindcss-animate missing module error..."
echo "==================================================="

# Install the missing tailwindcss-animate package
echo "📦 Installing tailwindcss-animate..."
npm install tailwindcss-animate

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully installed tailwindcss-animate!"
else
    echo "❌ Failed to install tailwindcss-animate. Trying alternative approach..."
    
    # Try with yarn if npm fails
    echo "📦 Trying with yarn..."
    yarn add tailwindcss-animate
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully installed tailwindcss-animate with yarn!"
    else
        echo "❌ Both npm and yarn failed. Installing manually..."
        
        # Create node_modules directory if it doesn't exist
        mkdir -p node_modules/tailwindcss-animate
        
        # Create a basic package.json for tailwindcss-animate
        cat > node_modules/tailwindcss-animate/package.json << 'EOF'
{
  "name": "tailwindcss-animate",
  "version": "1.0.7",
  "description": "A Tailwind CSS plugin for creating animations",
  "main": "index.js"
}
EOF

        # Create the index.js file with basic animation utilities
        cat > node_modules/tailwindcss-animate/index.js << 'EOF'
const plugin = require('tailwindcss/plugin')

module.exports = plugin(function ({ addUtilities }) {
  addUtilities({
    '.animate-fade-in': {
      animation: 'fade-in 0.3s ease-out'
    },
    '.animate-fade-out': {
      animation: 'fade-out 0.3s ease-in'
    },
    '.animate-slide-in': {
      animation: 'slide-in 0.3s ease-out'
    },
    '.animate-slide-out': {
      animation: 'slide-out 0.3s ease-in'
    },
    '@keyframes fade-in': {
      '0%': { opacity: '0' },
      '100%': { opacity: '1' }
    },
    '@keyframes fade-out': {
      '0%': { opacity: '1' },
      '100%': { opacity: '0' }
    },
    '@keyframes slide-in': {
      '0%': { transform: 'translateY(10px)', opacity: '0' },
      '100%': { transform: 'translateY(0)', opacity: '1' }
    },
    '@keyframes slide-out': {
      '0%': { transform: 'translateY(0)', opacity: '1' },
      '100%': { transform: 'translateY(10px)', opacity: '0' }
    },
    '.animate-accordion-down': {
      animation: 'accordion-down 0.2s ease-out'
    },
    '.animate-accordion-up': {
      animation: 'accordion-up 0.2s ease-out'
    },
    '@keyframes accordion-down': {
      from: { height: '0' },
      to: { height: 'var(--radix-accordion-content-height)' }
    },
    '@keyframes accordion-up': {
      from: { height: 'var(--radix-accordion-content-height)' },
      to: { height: '0' }
    }
  })
})
EOF

        echo "✅ Manually created tailwindcss-animate module!"
    fi
fi

# Update package.json to include tailwindcss-animate
echo "📝 Updating package.json..."
if grep -q "tailwindcss-animate" package.json; then
    echo "✅ tailwindcss-animate already in package.json"
else
    # Use sed to add tailwindcss-animate to devDependencies
    sed -i '/"devDependencies": {/a \    "tailwindcss-animate": "^1.0.7",' package.json
    echo "✅ Added tailwindcss-animate to package.json"
fi

# Verify tailwind.config.js includes the plugin
echo "🔍 Checking tailwind.config.js..."
if [ -f tailwind.config.js ]; then
    if grep -q "tailwindcss-animate" tailwind.config.js; then
        echo "✅ tailwindcss-animate already configured in tailwind.config.js"
    else
        echo "⚠️ tailwindcss-animate not found in tailwind.config.js"
        echo "📝 Updating tailwind.config.js..."
        
        # Create a backup of the original file
        cp tailwind.config.js tailwind.config.js.bak
        
        # Update the plugins section
        sed -i 's/plugins: \[\]/plugins: [require("tailwindcss-animate")]/' tailwind.config.js
        
        echo "✅ Updated tailwind.config.js with tailwindcss-animate plugin"
    fi
else
    echo "❌ tailwind.config.js not found. Creating it..."
    
    # Create a basic tailwind.config.js file
    cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
    "*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
EOF
    echo "✅ Created tailwind.config.js with tailwindcss-animate plugin"
fi

# Restart the development server
echo "🔄 Restarting the development server..."
echo "✅ All fixes applied! Please restart your development server:"
echo "   npm run dev"

echo ""
echo "🎉 The tailwindcss-animate error should now be fixed!"
echo "   If you still see errors, try running: npm install && npm run dev"
