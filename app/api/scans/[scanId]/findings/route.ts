// Proxy API route for scan findings
import { NextRequest, NextResponse } from "next/server";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8060";
const API_KEY = process.env.NEXT_PUBLIC_API_KEY || "secret-api-key";

export async function GET(
    request: NextRequest,
    { params }: { params: Promise<{ scanId: string }> }
) {
    const { scanId } = await params;
    const { searchParams } = new URL(request.url);
    const severity = searchParams.get("severity");

    try {
        const query = severity ? `?severity=${severity}` : "";
        const response = await fetch(`${API_BASE_URL}/scans/${scanId}/findings${query}`, {
            headers: {
                "X-API-Key": API_KEY,
            },
        });

        const data = await response.json();

        if (!response.ok) {
            return NextResponse.json(data, { status: response.status });
        }

        return NextResponse.json(data);
    } catch (error: any) {
        return NextResponse.json(
            { error: error.message || "Failed to get scan findings" },
            { status: 500 }
        );
    }
}
