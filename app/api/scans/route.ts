// Proxy API route to bypass CORS
import { NextRequest, NextResponse } from "next/server";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8060";
const API_KEY = process.env.NEXT_PUBLIC_API_KEY || "secret-api-key";

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();

        console.log(`[API Proxy] Starting scan for target: ${body.target}`);
        console.log(`[API Proxy] Backend URL: ${API_BASE_URL}/scans`);

        const response = await fetch(`${API_BASE_URL}/scans`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-API-Key": API_KEY,
            },
            body: JSON.stringify(body),
        });

        console.log(`[API Proxy] Backend response status: ${response.status}`);

        const data = await response.json();

        if (!response.ok) {
            console.error(`[API Proxy] Backend error:`, data);
            return NextResponse.json(data, { status: response.status });
        }

        console.log(`[API Proxy] Scan started with ID: ${data.scan_id}`);
        return NextResponse.json(data);
    } catch (error: any) {
        console.error(`[API Proxy] Error:`, error);

        // More descriptive error message
        let errorMessage = "Failed to start scan";
        if (error.cause?.code === "ECONNREFUSED") {
            errorMessage = `Cannot connect to backend at ${API_BASE_URL}. Make sure the backend server is running.`;
        } else if (error.message) {
            errorMessage = error.message;
        }

        return NextResponse.json(
            { error: errorMessage },
            { status: 500 }
        );
    }
}
