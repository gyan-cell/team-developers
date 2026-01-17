// Proxy API route for scan results
import { NextRequest, NextResponse } from "next/server";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8060";
const API_KEY = process.env.NEXT_PUBLIC_API_KEY || "secret-api-key";

export async function GET(
    request: NextRequest,
    { params }: { params: Promise<{ scanId: string }> }
) {
    const { scanId } = await params;

    try {
        const response = await fetch(`${API_BASE_URL}/scans/${scanId}`, {
            headers: {
                "X-API-Key": API_KEY,
            },
            cache: "no-store",
        });

        const data = await response.json();

        if (!response.ok) {
            return NextResponse.json(data, { status: response.status });
        }

        return NextResponse.json(data, {
            headers: {
                "Cache-Control": "no-cache, no-store, must-revalidate",
            },
        });
    } catch (error: any) {
        return NextResponse.json(
            { error: error.message || "Failed to get scan results" },
            { status: 500 }
        );
    }
}
