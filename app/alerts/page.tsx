import { AlertDashboard } from "@/components/alert-dashboard"

export default function AlertsPage() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Alert Management</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            Real-time email alerts and monitoring for your Cowrie honeypot
          </p>
        </div>

        <AlertDashboard />
      </div>
    </div>
  )
}
