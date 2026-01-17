"use client";

import { Bell, ChevronDown, User } from "lucide-react";

export function TopBar() {
    return (
        <header className="flex h-16 w-full items-center justify-between border-b border-border bg-background px-6 sticky top-0 z-10">
            <div className="flex items-center text-sm font-medium text-secondary">
                {/* Placeholder for Breadcrumbs or Page Title */}
                <span className="text-primary">Dashboard</span>
            </div>

            <div className="flex items-center gap-4">
                {/* Time Range Selector */}
                <button className="flex items-center gap-2 rounded-md border border-border bg-surface px-3 py-1.5 text-sm text-secondary hover:bg-surface-highlight hover:text-primary transition-colors">
                    <span>Last 24 Hours</span>
                    <ChevronDown className="h-4 w-4" />
                </button>

                <div className="h-6 w-px bg-border" />

                {/* Notifications */}
                <button className="relative rounded-full p-2 text-secondary hover:bg-surface-highlight hover:text-primary transition-colors">
                    <Bell className="h-5 w-5" />
                    <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-critical ring-2 ring-background" />
                </button>

                {/* User Profile */}
                <div className="flex items-center gap-3 pl-2">
                    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-surface-highlight ring-1 ring-border">
                        <User className="h-4 w-4 text-primary" />
                    </div>
                </div>
            </div>
        </header>
    );
}
