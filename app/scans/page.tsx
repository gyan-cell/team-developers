"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Loader2, CheckCircle2, XCircle, Activity, Search, ArrowRight, Trash2, RefreshCw } from "lucide-react";
import { cn } from "@/lib/utils";
import { getScanResults, type ScanStatus } from "@/lib/api";
import { getStoredScans, removeStoredScan, updateStoredScan, type StoredScan } from "@/lib/scan-storage";
import Link from "next/link";

export default function ScansPage() {
    const [scans, setScans] = useState<StoredScan[]>([]);
    const [loading, setLoading] = useState(true);

    // Load scans from localStorage and poll for status updates
    useEffect(() => {
        const loadScans = () => {
            const stored = getStoredScans();
            setScans(stored);
            setLoading(false);
        };

        loadScans();

        // Poll for status updates every 2 seconds
        const interval = setInterval(async () => {
            const stored = getStoredScans();

            // Update status for running scans
            for (const scan of stored) {
                if (scan.status === "started" || scan.status === "running") {
                    try {
                        const result = await getScanResults(scan.id);
                        if (result.status !== scan.status) {
                            updateStoredScan(scan.id, { status: result.status });
                        }
                    } catch {
                        // Ignore errors for individual scans
                    }
                }
            }

            setScans(getStoredScans());
        }, 2000);

        return () => clearInterval(interval);
    }, []);

    const handleRemove = (scanId: string) => {
        removeStoredScan(scanId);
        setScans(getStoredScans());
    };

    const getStatusIcon = (status: ScanStatus) => {
        switch (status) {
            case "started":
            case "running":
                return <Loader2 className="h-4 w-4 animate-spin text-info" />;
            case "completed":
                return <CheckCircle2 className="h-4 w-4 text-success" />;
            case "failed":
                return <XCircle className="h-4 w-4 text-critical" />;
            default:
                return <Activity className="h-4 w-4 text-secondary" />;
        }
    };

    const getStatusColor = (status: ScanStatus) => {
        switch (status) {
            case "started":
            case "running":
                return "bg-info/10 text-info border-info/20";
            case "completed":
                return "bg-success/10 text-success border-success/20";
            case "failed":
                return "bg-critical/10 text-critical border-critical/20";
            default:
                return "bg-secondary/10 text-secondary border-secondary/20";
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <Loader2 className="h-8 w-8 animate-spin text-secondary" />
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold tracking-tight text-primary">Scans</h1>
                    <p className="text-secondary text-sm">Monitor all running and completed scans.</p>
                </div>
                <Link
                    href="/new-scan"
                    className="bg-primary text-background hover:bg-zinc-200 px-4 py-2 rounded-md font-medium text-sm transition-colors inline-flex items-center gap-2"
                >
                    New Scan
                    <ArrowRight className="h-4 w-4" />
                </Link>
            </div>

            {scans.length === 0 ? (
                <Card className="bg-surface border-border">
                    <CardContent className="flex flex-col items-center justify-center py-16">
                        <div className="rounded-full bg-surface-highlight p-4 mb-4">
                            <Search className="h-8 w-8 text-secondary" />
                        </div>
                        <h2 className="text-xl font-semibold text-primary mb-2">No Scans Yet</h2>
                        <p className="text-secondary text-center max-w-md mb-6">
                            Start a vulnerability scan to see it listed here.
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
            ) : (
                <div className="space-y-3">
                    {scans.map((scan) => (
                        <Card key={scan.id} className="bg-surface border-border hover:bg-surface-highlight/30 transition-colors">
                            <CardContent className="p-4">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-4 flex-1 min-w-0">
                                        <div className={cn(
                                            "p-2 rounded-lg",
                                            scan.status === "running" || scan.status === "started"
                                                ? "bg-info/10"
                                                : scan.status === "completed"
                                                    ? "bg-success/10"
                                                    : "bg-critical/10"
                                        )}>
                                            {getStatusIcon(scan.status)}
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <Link
                                                href={`/scan/${scan.id}`}
                                                className="font-medium text-primary hover:underline truncate block"
                                            >
                                                {scan.target}
                                            </Link>
                                            <p className="text-xs text-secondary mt-0.5">
                                                Started {new Date(scan.startedAt).toLocaleString()}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <Badge className={cn("capitalize", getStatusColor(scan.status))}>
                                            {scan.status}
                                        </Badge>
                                        <Link
                                            href={`/scan/${scan.id}`}
                                            className="text-secondary hover:text-primary text-sm font-medium"
                                        >
                                            View
                                        </Link>
                                        <button
                                            onClick={() => handleRemove(scan.id)}
                                            className="text-secondary hover:text-critical p-1 rounded"
                                            title="Remove from list"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </button>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    );
}
