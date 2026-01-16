from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import subprocess
import json
from pathlib import Path
from enum import Enum

app = FastAPI(title="Team Developers API", version="1.0.0")

# Engine paths
BASE_DIR = Path(__file__).parent
ENGINES = {
    "recon": BASE_DIR / "recon-engine" / "recon-engine",
    "scan": BASE_DIR / "scan-engine" / "scan-engine",
    "result": BASE_DIR / "result-engine" / "result-engine",
}

# Recon types
class ReconType(str, Enum):
    QUICK = "quick"
    FULL = "full"
    DEPTH = "depth"

# Request models
class ReconRequest(BaseModel):
    domain: str
    type: ReconType = ReconType.QUICK
    sources: str = "all"
    parallel: bool = False

class ScanRequest(BaseModel):
    target: str
    ports: Optional[str] = None

class ResultRequest(BaseModel):
    data: str

# Helper to run command
def run_command(cmd: List[str], input_data: str = "") -> dict:
    try:
        process = subprocess.run(
            cmd,
            input=input_data,
            capture_output=True,
            text=True,
            timeout=300
        )
        
        if process.returncode != 0:
            return {"error": process.stderr or "Command failed"}
        
        output = process.stdout.strip()
        return {"output": output, "success": True}
    
    except subprocess.TimeoutExpired:
        return {"error": "Timeout"}
    except Exception as e:
        return {"error": str(e)}

# Helper to run engine
def run_engine(engine: str, input_data: str, args: List[str] = []) -> dict:
    if engine not in ENGINES or not ENGINES[engine].exists():
        raise HTTPException(503, f"{engine}-engine not available")
    
    cmd = [str(ENGINES[engine])] + args
    
    try:
        process = subprocess.run(
            cmd,
            input=input_data,
            capture_output=True,
            text=True,
            timeout=300
        )
        
        if process.returncode != 0:
            return {"error": process.stderr or "Unknown error"}
        
        results = [line.strip() for line in process.stdout.strip().split("\n") if line.strip()]
        return {"results": results, "count": len(results)}
    
    except subprocess.TimeoutExpired:
        return {"error": "Timeout"}
    except Exception as e:
        return {"error": str(e)}

# Quick scan: katana -> mantra -> arjun
def quick_scan(domain: str) -> dict:
    result = {
        "type": "quick",
        "domain": domain,
        "js_files": [],
        "credentials": [],
        "parameters": []
    }
    
    # Step 1: Katana - Extract JS files
    katana_result = run_command(["katana", "-u", domain, "-jc"])
    if "error" in katana_result:
        result["katana_error"] = katana_result["error"]
    else:
        js_files = [line for line in katana_result["output"].split("\n") if line.strip()]
        result["js_files"] = js_files
        result["js_count"] = len(js_files)
    
    # Step 2: Mantra - Find hardcoded credentials
    # Mantra reads from stdin: echo "url" | mantra
    mantra_result = run_command(["mantra"], domain + "\n")
    if "error" in mantra_result:
        result["mantra_error"] = mantra_result["error"]
    else:
        credentials = [line for line in mantra_result["output"].split("\n") if line.strip()]
        result["credentials"] = credentials
        result["creds_count"] = len(credentials)
    
    # Step 3: Arjun - Find parameters
    arjun_result = run_command(["arjun", "-u", domain])
    if "error" in arjun_result:
        result["arjun_error"] = arjun_result["error"]
    else:
        parameters = [line for line in arjun_result["output"].split("\n") if line.strip()]
        result["parameters"] = parameters
        result["params_count"] = len(parameters)
    
    return result

# Full scan: TBD
def full_scan(domain: str, sources: str, parallel: bool) -> dict:
    # Run subdomain enumeration first
    args = ["--silent"]
    if sources != "all":
        args.extend(["--source", sources])
    if parallel:
        args.append("--parallel")
    
    subdomains = run_engine("recon", domain + "\n", args)
    
    return {
        "type": "full",
        "domain": domain,
        "subdomains": subdomains,
        "status": "Full scan - add more tools here"
    }

# Depth scan: TBD
def depth_scan(domain: str) -> dict:
    return {
        "type": "depth",
        "domain": domain,
        "status": "Depth scan - add more tools here"
    }

# Endpoints
@app.get("/")
def root():
    return {
        "name": "Team Developers API",
        "engines": ["recon", "scan", "result"],
        "recon_types": ["quick", "full", "depth"],
        "endpoints": {
            "recon": "POST /recon - supports type: quick/full/depth",
            "scan": "POST /scan", 
            "result": "POST /result"
        }
    }

@app.post("/recon")
def recon(req: ReconRequest):
    if req.type == ReconType.QUICK:
        return quick_scan(req.domain)
    elif req.type == ReconType.FULL:
        return full_scan(req.domain, req.sources, req.parallel)
    elif req.type == ReconType.DEPTH:
        return depth_scan(req.domain)

@app.post("/scan")
def scan(req: ScanRequest):
    args = []
    if req.ports:
        args.extend(["--ports", req.ports])
    
    return run_engine("scan", req.target + "\n", args)

@app.post("/result")
def result(req: ResultRequest):
    return run_engine("result", req.data + "\n", [])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
