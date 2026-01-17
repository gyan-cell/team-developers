// Scan storage utilities using localStorage

export interface StoredScan {
    id: string;
    target: string;
    startedAt: string;
    status: "started" | "running" | "completed" | "failed";
}

const STORAGE_KEY = "vulnscanner_scans";

export function getStoredScans(): StoredScan[] {
    if (typeof window === "undefined") return [];
    const data = localStorage.getItem(STORAGE_KEY);
    if (!data) return [];
    try {
        return JSON.parse(data);
    } catch {
        return [];
    }
}

export function addStoredScan(scan: StoredScan): void {
    if (typeof window === "undefined") return;
    const scans = getStoredScans();
    // Add to beginning of list
    scans.unshift(scan);
    // Keep only last 50 scans
    const trimmed = scans.slice(0, 50);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(trimmed));
}

export function updateStoredScan(scanId: string, updates: Partial<StoredScan>): void {
    if (typeof window === "undefined") return;
    const scans = getStoredScans();
    const index = scans.findIndex(s => s.id === scanId);
    if (index !== -1) {
        scans[index] = { ...scans[index], ...updates };
        localStorage.setItem(STORAGE_KEY, JSON.stringify(scans));
    }
}

export function removeStoredScan(scanId: string): void {
    if (typeof window === "undefined") return;
    const scans = getStoredScans().filter(s => s.id !== scanId);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(scans));
}
