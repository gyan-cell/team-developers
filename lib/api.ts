// API Client for DAST Orchestrator Backend (via Next.js proxy)

// Types based on OpenAPI spec
export type ScanStatus = "started" | "running" | "completed" | "failed";
export type Severity = "critical" | "high" | "medium" | "low" | "info";

export interface ScanRequest {
    target: string;
}

export interface ScanResponse {
    scan_id: string;
    status: ScanStatus;
}

export interface Finding {
    scanner: string;
    name: string;
    severity: Severity;
    url: string;
    description?: string | null;
    cwe?: string | null;
    cvss?: number | null;
}

export interface ScanSummary {
    critical: number;
    high: number;
    medium: number;
    low: number;
    info: number;
}

export interface ScanResult {
    scan_id: string;
    status: ScanStatus;
    target: string;
    summary: ScanSummary;
    vulnerabilities: Finding[];
    logs: string[];
}

// API Helper - now calling local Next.js API routes (no CORS issues)
async function apiRequest<T>(
    endpoint: string,
    options: RequestInit = {}
): Promise<T> {
    const url = `/api${endpoint}`;

    const headers: HeadersInit = {
        "Content-Type": "application/json",
        ...options.headers,
    };

    try {
        const response = await fetch(url, {
            ...options,
            headers,
            cache: "no-store", // Prevent caching for real-time updates
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || data.detail || `API Error: ${response.status}`);
        }

        return data;
    } catch (error: any) {
        if (error.name === "TypeError" && error.message.includes("fetch")) {
            throw new Error("Network error. Please check your connection.");
        }
        throw error;
    }
}

// API Functions

/**
 * Start a new DAST scan
 */
export async function startScan(target: string): Promise<ScanResponse> {
    return apiRequest<ScanResponse>("/scans", {
        method: "POST",
        body: JSON.stringify({ target }),
    });
}

/**
 * Get scan status and results
 */
export async function getScanResults(scanId: string): Promise<ScanResult> {
    return apiRequest<ScanResult>(`/scans/${scanId}`);
}

/**
 * Get scan execution logs
 */
export async function getScanLogs(scanId: string): Promise<string[]> {
    return apiRequest<string[]>(`/scans/${scanId}/logs`);
}

/**
 * Get scan findings (optionally filtered by severity)
 */
export async function getScanFindings(
    scanId: string,
    severity?: Severity
): Promise<Finding[]> {
    const query = severity ? `?severity=${severity}` : "";
    return apiRequest<Finding[]>(`/scans/${scanId}/findings${query}`);
}

/**
 * Get scan summary
 */
export async function getScanSummary(scanId: string): Promise<ScanSummary> {
    return apiRequest<ScanSummary>(`/scans/${scanId}/summary`);
}
