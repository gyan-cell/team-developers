from fastapi import FastAPI, Depends, HTTPException, Request
from typing import List
import logging
from contextlib import asynccontextmanager
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from core.models import ScanRequest, ScanResponse, ScanResult, Finding, ScanSummary
from core.orchestrator import scan_manager
from core.security import verify_api_key, validate_target_url
from config import settings

# Rate Limiter Setup
limiter = Limiter(key_func=get_remote_address)

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize scanners?
    yield
    # Shutdown: Clean up?

app = FastAPI(title="DAST Orchestrator", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.post("/scan", response_model=ScanResponse, status_code=202)
@limiter.limit("5/minute")
async def start_scan(
    request: Request,
    scan_request: ScanRequest, 
    api_key: str = Depends(verify_api_key)
):
    """
    Start a new DAST scan against the target.
    """
    # 1. Validate Target (SSRF protection)
    # The Pydantic model validates generic URL, but we need deeper checks
    # However, Pydantic validation runs before this body. 
    # We can perform additional validation here.
    # Note: validate_target_url returns the url or raises generic Exception
    
    validate_target_url(str(scan_request.target))
    
    # 2. Start Scan
    scan_id = await scan_manager.create_scan(str(scan_request.target))
    
    return ScanResponse(scan_id=scan_id, status="started")

@app.get("/scan/{scan_id}", response_model=ScanResult)
async def get_scan_results(
    scan_id: str, 
    api_key: str = Depends(verify_api_key)
):
    """
    Retrieve the status and results of a scan.
    """
    # Convert string to UUID
    try:
        from uuid import UUID
        uuid_obj = UUID(scan_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scan ID format")
        
    result = await scan_manager.get_scan(uuid_obj)
    if not result:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    return result

@app.get("/scan/{scan_id}/logs", response_model=List[str])
async def get_scan_logs(
    scan_id: str,
    api_key: str = Depends(verify_api_key)
):
    """
    Retrieve execution logs for a scan.
    """
    try:
        from uuid import UUID
        uuid_obj = UUID(scan_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scan ID format")
        
    result = await scan_manager.get_scan(uuid_obj)
    if not result:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    return result.logs

    return result.logs

@app.get("/scan/{scan_id}/findings", response_model=List[Finding])
async def get_scan_findings(
    scan_id: str,
    api_key: str = Depends(verify_api_key)
):
    """
    Retrieve realtime findings for a scan.
    """
    try:
        from uuid import UUID
        uuid_obj = UUID(scan_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scan ID format")
        
    result = await scan_manager.get_scan(uuid_obj)
    if not result:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    return result.vulnerabilities

@app.get("/scan/{scan_id}/findings/grouped")
async def get_scan_findings_grouped(
    scan_id: str,
    api_key: str = Depends(verify_api_key)
):
    """
    Retrieve realtime findings grouped by scanner.
    """
    try:
        from uuid import UUID
        uuid_obj = UUID(scan_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scan ID format")
        
    result = await scan_manager.get_scan(uuid_obj)
    if not result:
        raise HTTPException(status_code=404, detail="Scan not found")
    
    # Group findings by scanner
    grouped = {}
    for finding in result.vulnerabilities:
        scanner = finding.scanner
        if scanner not in grouped:
            grouped[scanner] = []
        grouped[scanner].append(finding)
    
    return grouped

@app.get("/scan/{scan_id}/summary", response_model=ScanSummary)
async def get_scan_summary(
    scan_id: str,
    api_key: str = Depends(verify_api_key)
):
    """
    Retrieve realtime summary for a scan.
    """
    try:
        from uuid import UUID
        uuid_obj = UUID(scan_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scan ID format")
        
    result = await scan_manager.get_scan(uuid_obj)
    if not result:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    return result.summary

@app.post("/scan/{scan_id}/abort")
async def abort_scan(
    scan_id: str,
    api_key: str = Depends(verify_api_key)
):
    """
    Abort a running scan.
    """
    try:
        from uuid import UUID
        uuid_obj = UUID(scan_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scan ID format")
        
    result = await scan_manager.abort_scan(uuid_obj)
    if not result:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    return {"status": "aborted", "message": "Scan has been aborted"}

@app.post("/scan/{scan_id}/pause")
async def pause_scan(
    scan_id: str,
    api_key: str = Depends(verify_api_key)
):
    """
    Pause a running scan. (Currently stops the scan as pause is not fully supported by all adapters)
    """
    try:
        from uuid import UUID
        uuid_obj = UUID(scan_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scan ID format")
        
    result = await scan_manager.pause_scan(uuid_obj)
    if not result:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    return {"status": "paused", "message": "Scan has been paused"}

@app.post("/scan/{scan_id}/resume")
async def resume_scan(
    scan_id: str,
    api_key: str = Depends(verify_api_key)
):
    """
    Resume a paused scan.
    """
    try:
        from uuid import UUID
        uuid_obj = UUID(scan_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scan ID format")
        
    result = await scan_manager.resume_scan(uuid_obj)
    if not result:
        raise HTTPException(status_code=404, detail="Scan not found or cannot be resumed")
        
    return {"status": "resumed", "message": "Scan has been resumed"}

@app.get("/health")
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="10.149.135.102", port=8060)
