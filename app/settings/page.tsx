"use client";

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Bell, Shield, Key, Eye, Lock } from "lucide-react";
import { useState } from "react";

export default function SettingsPage() {
    const [notifications, setNotifications] = useState({
        email: true,
        slack: false,
        criticalAlerts: true,
    });

    return (
        <div className="space-y-6 max-w-4xl">
            <div>
                <h1 className="text-2xl font-bold tracking-tight text-primary">Settings</h1>
                <p className="text-secondary text-sm">Manage preferences and configurations.</p>
            </div>

            <div className="grid gap-6">
                <Card className="bg-surface border-border">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Bell className="h-5 w-5 text-secondary" />
                            Notifications
                        </CardTitle>
                        <CardDescription>Configure how you receive alerts.</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="flex items-center justify-between">
                            <div className="space-y-0.5">
                                <label className="text-sm font-medium text-primary">Email Notifications</label>
                                <p className="text-xs text-secondary">Receive daily summaries and critical alerts via email.</p>
                            </div>
                            <Switch checked={notifications.email} onCheckedChange={(c) => setNotifications({ ...notifications, email: c })} />
                        </div>
                        <div className="flex items-center justify-between">
                            <div className="space-y-0.5">
                                <label className="text-sm font-medium text-primary">Slack Integration</label>
                                <p className="text-xs text-secondary">Post alerts to a configured Slack channel.</p>
                            </div>
                            <Switch checked={notifications.slack} onCheckedChange={(c) => setNotifications({ ...notifications, slack: c })} />
                        </div>
                        <div className="flex items-center justify-between">
                            <div className="space-y-0.5">
                                <label className="text-sm font-medium text-primary">Critical Only</label>
                                <p className="text-xs text-secondary">Only notify for Critical and High severity issues.</p>
                            </div>
                            <Switch checked={notifications.criticalAlerts} onCheckedChange={(c) => setNotifications({ ...notifications, criticalAlerts: c })} />
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-surface border-border">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Shield className="h-5 w-5 text-secondary" />
                            Scan Defaults
                        </CardTitle>
                        <CardDescription>Default settings for new scans.</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-primary">Default User-Agent</label>
                                <input
                                    type="text"
                                    defaultValue="VulnScanner-Enterprise/1.0"
                                    className="flex h-10 w-full rounded-md border border-border bg-background px-3 py-2 text-sm text-primary placeholder:text-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                                />
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-primary">Concurrent Threads</label>
                                <input
                                    type="number"
                                    defaultValue="50"
                                    className="flex h-10 w-full rounded-md border border-border bg-background px-3 py-2 text-sm text-primary placeholder:text-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                                />
                            </div>
                        </div>
                    </CardContent>
                </Card>

                <Card className="bg-surface border-border">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Key className="h-5 w-5 text-secondary" />
                            API Keys
                        </CardTitle>
                        <CardDescription>Manage third-party integration keys.</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-primary">Shodan API Key</label>
                            <div className="relative">
                                <input
                                    type="password"
                                    defaultValue="sk_live_........................"
                                    className="flex h-10 w-full rounded-md border border-border bg-background px-3 py-2 text-sm text-primary placeholder:text-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                                />
                                <button className="absolute right-3 top-2.5 text-secondary hover:text-primary">
                                    <Eye className="h-4 w-4" />
                                </button>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}
