"use client";

import { use, useEffect, useRef, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Loader2, Terminal, CheckCircle2, XCircle, AlertTriangle, ShieldAlert } from "lucide-react";
import { cn } from "@/lib/utils";
import { getScanResults, getScanLogs, getScanSummary, type ScanResult, type ScanStatus, type ScanSummary } from "@/lib/api";
import Link from "next/link";

const POLL_INTERVAL = 1000; // 1 second for faster updates

export default function ScanMonitorPage({ params }: { params: Promise<{ scanId: string }> }) {
    const resolvedParams = use(params);
    const { scanId } = resolvedParams;

    const [scanResult, setScanResult] = useState<ScanResult | null>(null);
    const [logs, setLogs] = useState<string[]>([]);
    const [summary, setSummary] = useState<ScanSummary | null>(null);
    const [error, setError] = useState<string | null>(null);
    const scrollRef = useRef<HTMLDivElement>(null);

    // Poll for scan status, logs, and summary
    useEffect(() => {
        let isActive = true;
        let intervalId: NodeJS.Timeout;

        const fetchData = async () => {
            try {
                const [result, logsData, summaryData] = await Promise.all([
                    getScanResults(scanId),
                    getScanLogs(scanId),
                    getScanSummary(scanId),
                ]);

                if (isActive) {
                    setScanResult(result);
                    setLogs(logsData);
                    setSummary(summaryData);
                    setError(null);

                    // Stop polling if scan is completed or failed
                    if (result.status === "completed" || result.status === "failed") {
                        clearInterval(intervalId);
                    }
                }
            } catch (err: any) {
                if (isActive) {
                    setError(err.message || "Failed to fetch scan data");
                }
            }
        };

        // Initial fetch
        fetchData();

        // Start polling
        intervalId = setInterval(fetchData, POLL_INTERVAL);

        return () => {
            isActive = false;
            clearInterval(intervalId);
        };
    }, [scanId]);

    // Auto-scroll logs
    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [logs]);

    const getStatusColor = (status: ScanStatus) => {
        switch (status) {
            case "started":
            case "running":
                return "text-info";
            case "completed":
                return "text-success";
            case "failed":
                return "text-critical";
            default:
                return "text-secondary";
        }
    };

    const getStatusIcon = (status: ScanStatus) => {
        switch (status) {
            case "started":
            case "running":
                return <Loader2 className="h-5 w-5 animate-spin text-info" />;
            case "completed":
                return <CheckCircle2 className="h-5 w-5 text-success" />;
            case "failed":
                return <XCircle className="h-5 w-5 text-critical" />;
            default:
                return null;
        }
    };

    if (error && !scanResult) {
        return (
            <div className="flex items-center justify-center h-96">
                <Card className="bg-surface border-border p-8 text-center">
                    <XCircle className="h-12 w-12 text-critical mx-auto mb-4" />
                    <h2 className="text-xl font-semibold text-primary mb-2">Error Loading Scan</h2>
                    <p className="text-secondary">{error}</p>
                    <Link href="/new-scan" className="mt-4 inline-block text-info hover:underline">
                        Start a new scan
                    </Link>
                </Card>
            </div>
        );
    }

    return (
        <div className="space-y-6 max-w-6xl mx-auto">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold tracking-tight text-primary">Scan Monitor</h1>
                    <p className="text-secondary text-sm">Real-time scan execution and findings.</p>
                </div>
                <div className="flex items-center gap-3">
                    {scanResult && (
                        <>
                            <Badge variant="outline" className="border-border text-secondary bg-surface">
                                Target: {scanResult.target}
                            </Badge>
                            <Badge
                                variant="outline"
                                className={cn("border-border bg-surface", getStatusColor(scanResult.status))}
                            >
                                {getStatusIcon(scanResult.status)}
                                <span className="ml-1 capitalize">{scanResult.status}</span>
                            </Badge>
                        </>
                    )}
                </div>
            </div>

            {/* Summary Cards */}
            {summary && (
                <div className="grid gap-4 md:grid-cols-5">
                    <Card className="bg-surface border-border">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm font-medium text-secondary flex items-center gap-2">
                                <ShieldAlert className="h-4 w-4 text-critical" />
                                Critical
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-critical">{summary.critical}</div>
                        </CardContent>
                    </Card>
                    <Card className="bg-surface border-border">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm font-medium text-secondary flex items-center gap-2">
                                <AlertTriangle className="h-4 w-4 text-high" />
                                High
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-high">{summary.high}</div>
                        </CardContent>
                    </Card>
                    <Card className="bg-surface border-border">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm font-medium text-secondary">Medium</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-medium">{summary.medium}</div>
                        </CardContent>
                    </Card>
                    <Card className="bg-surface border-border">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm font-medium text-secondary">Low</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-low">{summary.low}</div>
                        </CardContent>
                    </Card>
                    <Card className="bg-surface border-border">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm font-medium text-secondary">Info</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold text-secondary">{summary.info}</div>
                        </CardContent>
                    </Card>
                </div>
            )}

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Terminal Output */}
                <Card className="bg-[#0c0c0e] border-border shadow-inner">
                    <CardHeader className="border-b border-border/20 bg-surface/30 py-3">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <Terminal className="h-4 w-4 text-secondary" />
                                <span className="text-sm font-mono text-secondary">Execution Logs</span>
                            </div>
                            <div className="flex gap-1.5">
                                <div className="h-2.5 w-2.5 rounded-full bg-red-500/50" />
                                <div className="h-2.5 w-2.5 rounded-full bg-yellow-500/50" />
                                <div className="h-2.5 w-2.5 rounded-full bg-green-500/50" />
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="p-0">
                        <div
                            ref={scrollRef}
                            className="h-[400px] overflow-y-auto p-4 font-mono text-xs space-y-1"
                        >
                            {logs.length === 0 ? (
                                <div className="flex items-center justify-center h-full text-secondary">
                                    {scanResult ? "Waiting for logs..." : "Loading..."}
                                </div>
                            ) : (
                                logs.map((log, i) => {
                                    if (!log) return null;
                                    const isError = log.toLowerCase().includes("error") || log.toLowerCase().includes("fail");
                                    const isWarning = log.toLowerCase().includes("warn") || log.toLowerCase().includes("vuln");
                                    const isSuccess = log.toLowerCase().includes("success") || log.toLowerCase().includes("found");

                                    return (
                                        <div key={i} className="flex gap-2 text-zinc-300">
                                            <span className="text-zinc-500 select-none opacity-50">$</span>
                                            <span className={cn(
                                                isError ? "text-red-400" :
                                                    isWarning ? "text-yellow-400" :
                                                        isSuccess ? "text-emerald-400" :
                                                            "text-zinc-300"
                                            )}>
                                                {log}
                                            </span>
                                        </div>
                                    );
                                })
                            )}
                            {scanResult?.status === "running" && (
                                <div className="flex gap-2 animate-pulse">
                                    <span className="text-zinc-500 select-none opacity-50">$</span>
                                    <span className="h-4 w-2.5 bg-zinc-500/50" />
                                </div>
                            )}
                        </div>
                    </CardContent>
                </Card>

                {/* Real-time Findings */}
                <Card className="bg-surface border-border">
                    <CardHeader>
                        <CardTitle className="text-lg flex items-center gap-2">
                            <ShieldAlert className="h-5 w-5 text-secondary" />
                            Live Findings
                        </CardTitle>
                        <CardDescription>
                            Vulnerabilities discovered in real-time
                        </CardDescription>
                    </CardHeader>
                    <CardContent className="p-0">
                        <div className="h-[400px] overflow-y-auto">
                            {scanResult?.vulnerabilities && scanResult.vulnerabilities.length > 0 ? (
                                <div className="divide-y divide-border/50">
                                    {scanResult.vulnerabilities.map((finding, i) => (
                                        <div key={i} className="p-4 hover:bg-surface-highlight/30 transition-colors">
                                            <div className="flex items-start justify-between gap-3">
                                                <div className="flex-1 min-w-0">
                                                    <h4 className="font-medium text-primary text-sm truncate">
                                                        {finding.name}
                                                    </h4>
                                                    <p className="text-xs text-secondary truncate mt-1">
                                                        {finding.url}
                                                    </p>
                                                    <div className="flex items-center gap-2 mt-2">
                                                        <Badge variant="outline" className="text-[10px] border-border">
                                                            {finding.scanner}
                                                        </Badge>
                                                        {finding.cwe && (
                                                            <span className="text-[10px] text-muted">{finding.cwe}</span>
                                                        )}
                                                    </div>
                                                </div>
                                                <Badge variant={finding.severity as any} className="shrink-0">
                                                    {finding.severity}
                                                </Badge>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <div className="flex items-center justify-center h-full text-secondary">
                                    {scanResult?.status === "running"
                                        ? "Scanning for vulnerabilities..."
                                        : scanResult?.status === "completed"
                                            ? "No vulnerabilities found"
                                            : "Waiting for scan to start..."}
                                </div>
                            )}
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Action Buttons */}
            {scanResult?.status === "completed" && (
                <div className="flex justify-end gap-4">
                    <Link
                        href="/vulnerabilities"
                        className="bg-surface border border-border hover:bg-surface-highlight text-primary px-4 py-2 rounded-md font-medium text-sm transition-colors"
                    >
                        View All Findings
                    </Link>
                    <Link
                        href="/new-scan"
                        className="bg-primary text-background hover:bg-zinc-200 px-4 py-2 rounded-md font-medium text-sm transition-colors"
                    >
                        Start New Scan
                    </Link>
                </div>
            )}
        </div>
    );
}
