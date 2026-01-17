"use client";

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Globe, Network, Server, Search, ArrowRight } from "lucide-react";
import Link from "next/link";

export default function AttackSurfacePage() {
    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-2xl font-bold tracking-tight text-primary">Attack Surface</h1>
                <p className="text-secondary text-sm">Discovered assets, subdomains, and infrastructure.</p>
            </div>

            <div className="grid gap-4 md:grid-cols-3">
                <Card className="bg-surface border-border">
                    <CardHeader className="flex flex-row items-center justify-between pb-2">
                        <CardTitle className="text-sm font-medium text-secondary">Total Subdomains</CardTitle>
                        <Globe className="h-4 w-4 text-info" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-primary">--</div>
                    </CardContent>
                </Card>
                <Card className="bg-surface border-border">
                    <CardHeader className="flex flex-row items-center justify-between pb-2">
                        <CardTitle className="text-sm font-medium text-secondary">Unique IPs</CardTitle>
                        <Network className="h-4 w-4 text-success" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-primary">--</div>
                    </CardContent>
                </Card>
                <Card className="bg-surface border-border">
                    <CardHeader className="flex flex-row items-center justify-between pb-2">
                        <CardTitle className="text-sm font-medium text-secondary">Open Ports</CardTitle>
                        <Server className="h-4 w-4 text-warning" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-primary">--</div>
                    </CardContent>
                </Card>
            </div>

            {/* Empty State */}
            <Card className="bg-surface border-border">
                <CardContent className="flex flex-col items-center justify-center py-16">
                    <div className="rounded-full bg-surface-highlight p-4 mb-4">
                        <Globe className="h-8 w-8 text-secondary" />
                    </div>
                    <h2 className="text-xl font-semibold text-primary mb-2">No Assets Discovered</h2>
                    <p className="text-secondary text-center max-w-md mb-6">
                        Run a vulnerability scan to discover subdomains, IP addresses, open ports, and technologies on your target.
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
        </div>
    );
}
