"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
    LayoutDashboard,
    Globe,
    Target,
    Activity,
    ShieldAlert,
    FileText,
    Settings,
    Shield
} from "lucide-react";
import { cn } from "@/lib/utils";

const navigation = [
    { name: "Dashboard", href: "/", icon: LayoutDashboard },
    { name: "Attack Surface", href: "/attack-surface", icon: Globe },
    { name: "New Scan", href: "/new-scan", icon: Target },
    { name: "Scans", href: "/scans", icon: Activity },
    { name: "Vulnerabilities", href: "/vulnerabilities", icon: ShieldAlert },
    { name: "Reporting", href: "/reporting", icon: FileText },
    { name: "Settings", href: "/settings", icon: Settings },
];

export function Sidebar() {
    const pathname = usePathname();

    return (
        <div className="flex h-screen w-64 flex-col border-r border-border bg-surface text-secondary fixed left-0 top-0">
            <div className="flex h-16 items-center px-6 border-b border-border">
                <Shield className="h-6 w-6 text-primary mr-2" />
                <span className="text-lg font-semibold text-primary">VulnScanner</span>
            </div>

            <nav className="flex-1 space-y-1 px-3 py-4">
                {navigation.map((item) => {
                    const isActive = pathname === item.href;
                    return (
                        <Link
                            key={item.name}
                            href={item.href}
                            className={cn(
                                "group flex items-center px-3 py-2.5 text-sm font-medium rounded-md transition-colors",
                                isActive
                                    ? "bg-surface-highlight text-primary"
                                    : "text-secondary hover:bg-surface-highlight/50 hover:text-primary"
                            )}
                        >
                            <item.icon
                                className={cn(
                                    "mr-3 h-5 w-5 flex-shrink-0",
                                    isActive ? "text-primary" : "text-secondary group-hover:text-primary"
                                )}
                            />
                            {item.name}
                        </Link>
                    );
                })}
            </nav>

            <div className="p-4 border-t border-border">
                <div className="flex items-center">
                    <div className="h-8 w-8 rounded-full bg-surface-highlight flex items-center justify-center">
                        <span className="text-xs font-semibold text-primary">JD</span>
                    </div>
                    <div className="ml-3">
                        <p className="text-sm font-medium text-primary">John Doe</p>
                        <p className="text-xs text-secondary">Admin</p>
                    </div>
                </div>
            </div>
        </div>
    );
}
