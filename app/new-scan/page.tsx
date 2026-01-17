"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from "@/components/ui/card";
import { Target, Zap, Shield, Search, Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { startScan } from "@/lib/api";
import { addStoredScan } from "@/lib/scan-storage";

export default function NewScanPage() {
    const router = useRouter();
    const [scanMode, setScanMode] = useState<"Quick" | "Full" | "Depth">("Quick");
    const [target, setTarget] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const modes = [
        {
            id: "Quick",
            title: "Quick Scan",
            description: "Fast discovery of active subdomains and open ports. No deep inspection.",
            icon: Zap
        },
        {
            id: "Full",
            title: "Full Scan",
            description: "Comprehensive vulnerability assessment including CVE checks and light fuzzing.",
            icon: Shield
        },
        {
            id: "Depth",
            title: "Depth Scan",
            description: "Intensive deep-dive analysis with exhaustive fuzzing and heavy payloads.",
            icon: Search
        }
    ];

    const handleStartScan = async () => {
        if (!target.trim()) {
            setError("Please enter a target URL");
            return;
        }

        // Validate URL format
        let formattedTarget = target.trim();
        if (!formattedTarget.startsWith("http://") && !formattedTarget.startsWith("https://")) {
            formattedTarget = `https://${formattedTarget}`;
        }

        try {
            setIsLoading(true);
            setError(null);

            const response = await startScan(formattedTarget);

            // Store scan in localStorage for tracking
            addStoredScan({
                id: response.scan_id,
                target: formattedTarget,
                startedAt: new Date().toISOString(),
                status: response.status,
            });

            // Navigate to the live monitor page with the scan ID
            router.push(`/scan/${response.scan_id}`);
        } catch (err: any) {
            setError(err.message || "Failed to start scan. Please try again.");
            setIsLoading(false);
        }
    };

    return (
        <div className="space-y-6 max-w-4xl mx-auto">
            <div>
                <h1 className="text-2xl font-bold tracking-tight text-primary">New Scan</h1>
                <p className="text-secondary text-sm">Configure and launch a new vulnerability scan.</p>
            </div>

            <Card className="bg-surface border-border">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Target className="h-5 w-5 text-primary" />
                        Target Configuration
                    </CardTitle>
                    <CardDescription>Enter the target domain, IP address, or URL.</CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4">
                        <div className="flex flex-col space-y-2">
                            <label htmlFor="target" className="text-sm font-medium text-primary">Target URL</label>
                            <input
                                id="target"
                                type="text"
                                value={target}
                                onChange={(e) => setTarget(e.target.value)}
                                placeholder="e.g., https://example.com"
                                className="flex h-10 w-full rounded-md border border-border bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                            />
                            {error && (
                                <p className="text-sm text-critical">{error}</p>
                            )}
                        </div>
                    </div>
                </CardContent>
            </Card>

            <Card className="bg-surface border-border">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Zap className="h-5 w-5 text-primary" />
                        Scan Mode
                    </CardTitle>
                    <CardDescription>Select the intensity and depth of the vulnerability scan.</CardDescription>
                </CardHeader>
                <CardContent className="grid gap-4 md:grid-cols-3">
                    {modes.map((mode) => (
                        <div
                            key={mode.id}
                            onClick={() => setScanMode(mode.id as any)}
                            className={cn(
                                "relative flex flex-col space-y-2 rounded-lg border p-4 cursor-pointer transition-all hover:bg-surface-highlight",
                                scanMode === mode.id
                                    ? "border-primary bg-surface-highlight/50 shadow-sm"
                                    : "border-border bg-surface"
                            )}
                        >
                            <div className="flex items-center justify-between">
                                <mode.icon className={cn(
                                    "h-5 w-5",
                                    scanMode === mode.id ? "text-primary" : "text-secondary"
                                )} />
                                <div className={cn(
                                    "h-4 w-4 rounded-full border flex items-center justify-center",
                                    scanMode === mode.id ? "border-primary" : "border-secondary"
                                )}>
                                    {scanMode === mode.id && <div className="h-2 w-2 rounded-full bg-primary" />}
                                </div>
                            </div>
                            <div>
                                <h3 className={cn(
                                    "font-medium text-sm",
                                    scanMode === mode.id ? "text-primary" : "text-secondary"
                                )}>{mode.title}</h3>
                                <p className="text-xs text-secondary mt-1">{mode.description}</p>
                            </div>
                        </div>
                    ))}
                </CardContent>
                <CardFooter className="flex justify-end pt-4">
                    <button
                        onClick={handleStartScan}
                        disabled={isLoading}
                        className="bg-primary text-background hover:bg-zinc-200 h-10 px-8 py-2 inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
                    >
                        {isLoading ? (
                            <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Starting Scan...
                            </>
                        ) : (
                            "Start Scan"
                        )}
                    </button>
                </CardFooter>
            </Card>
        </div>
    );
}
