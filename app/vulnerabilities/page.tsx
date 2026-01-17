"use client";

import { Card, CardContent } from "@/components/ui/card";
import { ShieldAlert, Search, ArrowRight } from "lucide-react";
import Link from "next/link";

export default function VulnerabilitiesPage() {
    return (
        <div className="space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold tracking-tight text-primary">Vulnerabilities</h1>
                    <p className="text-secondary text-sm">Manage and remediate security findings.</p>
                </div>
            </div>

            {/* Empty State */}
            <Card className="bg-surface border-border">
                <CardContent className="flex flex-col items-center justify-center py-16">
                    <div className="rounded-full bg-surface-highlight p-4 mb-4">
                        <ShieldAlert className="h-8 w-8 text-secondary" />
                    </div>
                    <h2 className="text-xl font-semibold text-primary mb-2">No Vulnerabilities Found</h2>
                    <p className="text-secondary text-center max-w-md mb-6">
                        Run a vulnerability scan to discover security issues. All findings will be displayed here in real-time.
                    </p>
                    <Link
                        href="/new-scan"
                        className="bg-primary text-background hover:bg-zinc-200 px-6 py-2.5 rounded-md font-medium text-sm transition-colors inline-flex items-center gap-2"
                    >
                        Start a Scan
                        <ArrowRight className="h-4 w-4" />
                    </Link>
                </CardContent>
            </Card>

            <p className="text-center text-sm text-secondary">
                Tip: After starting a scan, visit the <Link href="/new-scan" className="text-info hover:underline">Scan Monitor</Link> to see real-time findings.
            </p>
        </div>
    );
}
