"use client";

import { use } from "react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { ShieldAlert, AlertTriangle, ExternalLink, CheckCircle, Terminal, Bug } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";

// Mock Data
const vulnerabilityData = {
    id: "VULN-001",
    name: "SQL Injection in Login Endpoint",
    severity: "Critical",
    asset: "auth.company.com",
    cvss: 9.8,
    status: "Open",
    cwe: "CWE-89",
    description: "The application's login endpoint (`/api/v1/login`) is vulnerable to SQL Injection. The `username` parameter is not properly sanitized before being used in a SQL query, allowing an attacker to manipulate the query logic.",
    impact: "An attacker could bypass authentication, access unauthorized data, modify or delete data, or even gain administrative rights to the database.",
    evidence: `POST /api/v1/login HTTP/1.1
Host: auth.company.com
Content-Type: application/json

{
  "username": "admin' OR '1'='1",
  "password": "password"
}`,
    remediation: [
        "Use parameterized queries (Prepared Statements) for all database access.",
        "Validate and sanitize all user inputs on the server side.",
        "Implement a Web Application Firewall (WAF) to detect and block SQL injection attempts."
    ],
    references: [
        { label: "OWASP Top 10 - A03:2021 Injection", url: "#" },
        { label: "CWE-89: Improper Neutralization of Special Elements used in an SQL Command", url: "#" }
    ]
};

export default function VulnerabilityDetailsPage({ params }: { params: Promise<{ id: string }> }) {
    // Unwrapp params
    const resolvedParams = use(params);
    const { id } = resolvedParams;

    return (
        <div className="space-y-6 max-w-5xl">
            <div className="flex items-center gap-2 text-sm text-secondary mb-4">
                <Link href="/vulnerabilities" className="hover:text-primary transition-colors">Vulnerabilities</Link>
                <span>/</span>
                <span className="text-primary font-medium">{id}</span>
            </div>

            <div className="flex items-start justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-primary mb-2 flex items-center gap-3">
                        <ShieldAlert className="text-critical h-8 w-8" />
                        {vulnerabilityData.name}
                    </h1>
                    <div className="flex items-center gap-3 mt-4">
                        <Badge variant="critical" className="px-3 py-1 text-sm">Critical</Badge>
                        <span className="text-secondary text-sm flex items-center gap-1">
                            <span className="font-semibold text-primary">CVSS:</span> {vulnerabilityData.cvss}
                        </span>
                        <span className="text-secondary text-sm border-l border-border pl-3 flex items-center gap-1">
                            <span className="font-semibold text-primary">CWE:</span> {vulnerabilityData.cwe}
                        </span>
                        <span className="text-secondary text-sm border-l border-border pl-3 flex items-center gap-1">
                            <span className="font-semibold text-primary">Status:</span> {vulnerabilityData.status}
                        </span>
                    </div>
                </div>
                <button className="bg-primary hover:bg-zinc-200 text-background px-4 py-2 rounded-md font-medium text-sm transition-colors">
                    Start Remediation
                </button>
            </div>

            <div className="grid grid-cols-3 gap-6">
                <div className="col-span-2 space-y-6">
                    {/* Description Card */}
                    <Card className="bg-surface border-border">
                        <CardHeader>
                            <CardTitle className="text-lg flex items-center gap-2">
                                <Bug className="h-5 w-5 text-secondary" />
                                Description
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="text-secondary leading-relaxed">
                            {vulnerabilityData.description}
                        </CardContent>
                    </Card>

                    {/* Evidence Card */}
                    <Card className="bg-surface border-border">
                        <CardHeader>
                            <CardTitle className="text-lg flex items-center gap-2">
                                <Terminal className="h-5 w-5 text-secondary" />
                                Evidence / Payload
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="bg-background rounded-md border border-border p-4 font-mono text-xs text-green-400 overflow-x-auto">
                                <pre>{vulnerabilityData.evidence}</pre>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Remediation Card */}
                    <Card className="bg-surface border-border">
                        <CardHeader>
                            <CardTitle className="text-lg flex items-center gap-2">
                                <CheckCircle className="h-5 w-5 text-secondary" />
                                Remediation
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <ul className="space-y-3">
                                {vulnerabilityData.remediation.map((step, i) => (
                                    <li key={i} className="flex items-start gap-3 text-secondary text-sm">
                                        <div className="h-5 w-5 rounded-full bg-surface-highlight flex items-center justify-center shrink-0 border border-border text-xs font-mono text-primary">
                                            {i + 1}
                                        </div>
                                        <span>{step}</span>
                                    </li>
                                ))}
                            </ul>
                        </CardContent>
                    </Card>
                </div>

                <div className="space-y-6">
                    {/* Impact Card */}
                    <Card className="bg-surface border-border">
                        <CardHeader>
                            <CardTitle className="text-lg flex items-center gap-2">
                                <AlertTriangle className="h-5 w-5 text-secondary" />
                                Impact
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="text-sm text-secondary">
                            {vulnerabilityData.impact}
                        </CardContent>
                    </Card>

                    {/* Affected Asset Card */}
                    <Card className="bg-surface border-border">
                        <CardHeader>
                            <CardTitle className="text-lg">Affected Asset</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex items-center justify-between p-3 rounded-md bg-surface-highlight/50 border border-border">
                                <div>
                                    <p className="text-sm font-medium text-primary">{vulnerabilityData.asset}</p>
                                    <p className="text-xs text-secondary mt-1">192.168.1.10</p>
                                </div>
                                <ExternalLink className="h-4 w-4 text-secondary hover:text-primary cursor-pointer" />
                            </div>
                        </CardContent>
                    </Card>

                    {/* References Card */}
                    <Card className="bg-surface border-border">
                        <CardHeader>
                            <CardTitle className="text-lg">References</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <ul className="space-y-2">
                                {vulnerabilityData.references.map((ref, i) => (
                                    <li key={i}>
                                        <a href={ref.url} className="text-sm text-info hover:underline flex items-center gap-1">
                                            {ref.label}
                                            <ExternalLink className="h-3 w-3" />
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
}
