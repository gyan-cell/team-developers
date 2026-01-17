from enum import Enum
from typing import List, Optional
from uuid import UUID, uuid4
from pydantic import BaseModel, HttpUrl, Field

class Severity(str, Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"

class ScanStatus(str, Enum):
    STARTED = "started"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    PAUSED = "paused"
    ABORTED = "aborted"
    STOPPED = "stopped"

class Finding(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    scanner: str
    name: str
    severity: Severity
    url: str
    description: Optional[str] = None
    cwe: Optional[str] = None
    cvss: Optional[float] = None
    
    class Config:
        frozen = True # Allow hashing for deduplication

class ScanRequest(BaseModel):
    target: HttpUrl

class ScanResponse(BaseModel):
    scan_id: UUID
    status: ScanStatus

class ScanSummary(BaseModel):
    critical: int = 0
    high: int = 0
    medium: int = 0
    low: int = 0
    info: int = 0

class ScanResult(BaseModel):
    scan_id: UUID
    status: ScanStatus
    target: str
    summary: ScanSummary
    vulnerabilities: List[Finding] = []
    logs: List[str] = []
