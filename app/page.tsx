import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ShieldAlert, Globe, Activity, Search, ArrowRight } from "lucide-react";
import Link from "next/link";

export default function Home() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight text-primary">Overview</h1>
      </div>

      {/* Quick Stats - Will be populated from real scans */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card className="bg-surface border-border">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-secondary">
              Risk Score
            </CardTitle>
            <Activity className="h-4 w-4 text-secondary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-primary">--</div>
            <p className="text-xs text-secondary mt-1">Run a scan to calculate</p>
          </CardContent>
        </Card>

        <Card className="bg-surface border-border">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-secondary">
              Active Vulnerabilities
            </CardTitle>
            <ShieldAlert className="h-4 w-4 text-secondary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-primary">--</div>
            <p className="text-xs text-secondary mt-1">No scans completed</p>
          </CardContent>
        </Card>

        <Card className="bg-surface border-border">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-secondary">
              Total Assets
            </CardTitle>
            <Globe className="h-4 w-4 text-secondary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-primary">--</div>
            <p className="text-xs text-secondary mt-1">No assets discovered</p>
          </CardContent>
        </Card>

        <Card className="bg-surface border-border">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-secondary">
              Active Scans
            </CardTitle>
            <Search className="h-4 w-4 text-secondary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-primary">0</div>
            <p className="text-xs text-secondary mt-1">No scans running</p>
          </CardContent>
        </Card>
      </div>

      {/* Empty State - Prompt to start scanning */}
      <Card className="bg-surface border-border">
        <CardContent className="flex flex-col items-center justify-center py-16">
          <div className="rounded-full bg-surface-highlight p-4 mb-4">
            <Search className="h-8 w-8 text-secondary" />
          </div>
          <h2 className="text-xl font-semibold text-primary mb-2">No Scans Yet</h2>
          <p className="text-secondary text-center max-w-md mb-6">
            Start your first vulnerability scan to discover security issues and populate this dashboard with real-time data.
          </p>
          <Link
            href="/new-scan"
            className="bg-primary text-background hover:bg-zinc-200 px-6 py-2.5 rounded-md font-medium text-sm transition-colors inline-flex items-center gap-2"
          >
            Start Your First Scan
            <ArrowRight className="h-4 w-4" />
          </Link>
        </CardContent>
      </Card>
    </div>
  );
}
