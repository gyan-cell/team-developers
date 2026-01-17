"use client";

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { FileText, Download, ArrowRight } from "lucide-react";
import Link from "next/link";

export default function ReportingPage() {
    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold tracking-tight text-primary">Reporting</h1>
                    <p className="text-secondary text-sm">Generate and export security reports.</p>
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
                <Card className="bg-surface border-border">
                    <CardHeader>
                        <CardTitle>Executive Summary</CardTitle>
                        <CardDescription>High-level overview of security posture.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="flex flex-col items-center justify-center py-8">
                            <p className="text-secondary text-sm text-center">
                                Complete a scan to generate an executive summary.
                            </p>
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-surface border-border">
                    <CardHeader>
                        <CardTitle>Recent Reports</CardTitle>
                        <CardDescription>Download previously generated reports.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="flex flex-col items-center justify-center py-8">
                            <FileText className="h-8 w-8 text-secondary mb-3" />
                            <p className="text-secondary text-sm text-center">
                                No reports generated yet.
                            </p>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Empty State */}
            <Card className="bg-surface border-border">
                <CardContent className="flex flex-col items-center justify-center py-12">
                    <div className="rounded-full bg-surface-highlight p-4 mb-4">
                        <FileText className="h-8 w-8 text-secondary" />
                    </div>
                    <h2 className="text-xl font-semibold text-primary mb-2">No Reports Available</h2>
                    <p className="text-secondary text-center max-w-md mb-6">
                        Complete a vulnerability scan first. Reports will be generated automatically based on scan results.
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
