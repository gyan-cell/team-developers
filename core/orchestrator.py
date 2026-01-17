import asyncio
import logging
from uuid import uuid4, UUID
from typing import Dict, List, Callable
from datetime import datetime

from core.models import ScanResult, ScanStatus, ScanSummary, Finding
from adapters.base import ScannerAdapter
from adapters.nuclei import NucleiAdapter
from adapters.zap import ZapAdapter
from adapters.acunetix import AcunetixAdapter
from utils.normalizer import deduplicate_findings
from config import settings

logger = logging.getLogger(__name__)

class ScanManager:
    def __init__(self):
        self.scans: Dict[UUID, ScanResult] = {}
        self.scanners: List[ScannerAdapter] = [
            NucleiAdapter(),
            ZapAdapter(),
            AcunetixAdapter()
        ]
    
    async def create_scan(self, target: str) -> UUID:
        scan_id = uuid4()
        
        # Initialize record
        self.scans[scan_id] = ScanResult(
            scan_id=scan_id,
            status=ScanStatus.STARTED,
            target=target,
            summary=ScanSummary(),

            vulnerabilities=[],
            logs=[]
        )
        
        # Start background task
        asyncio.create_task(self._run_scan_workflow(scan_id, target))
        return scan_id
        
    async def get_scan(self, scan_id: UUID) -> ScanResult:
        return self.scans.get(scan_id)
    
    async def abort_scan(self, scan_id: UUID) -> bool:
        """
        Abort a running scan.
        """
        if scan_id not in self.scans:
            return False
        
        scan = self.scans[scan_id]
        if scan.status in [ScanStatus.COMPLETED, ScanStatus.FAILED, ScanStatus.ABORTED]:
            return False
        
        scan.status = ScanStatus.ABORTED
        logger.info(f"Scan {scan_id} has been aborted")
        return True
    
    async def pause_scan(self, scan_id: UUID) -> bool:
        """
        Pause a running scan.
        """
        if scan_id not in self.scans:
            return False
        
        scan = self.scans[scan_id]
        if scan.status != ScanStatus.RUNNING:
            return False
        
        scan.status = ScanStatus.PAUSED
        logger.info(f"Scan {scan_id} has been paused")
        return True
    
    async def resume_scan(self, scan_id: UUID) -> bool:
        """
        Resume a paused scan.
        """
        if scan_id not in self.scans:
            return False
        
        scan = self.scans[scan_id]
        if scan.status != ScanStatus.PAUSED:
            return False
        
        scan.status = ScanStatus.RUNNING
        logger.info(f"Scan {scan_id} has been resumed")
        return True

    async def abort_scan(self, scan_id: UUID) -> bool:
        if scan_id not in self.scans:
            return False
            
        scan_record = self.scans[scan_id]
        if scan_record.status in [ScanStatus.COMPLETED, ScanStatus.FAILED, ScanStatus.STOPPED]:
            return False
            
        # Stop all adapters and move to paused list
        if scan_id in self._active_refs:
            for scanner, ref_id in self._active_refs[scan_id]:
                await scanner.stop_scan(ref_id)
            
            # Move to paused refs
            self._paused_refs[scan_id] = self._active_refs[scan_id]
            del self._active_refs[scan_id]
            
        scan_record.status = ScanStatus.STOPPED
        return True

        scan_record.status = ScanStatus.STOPPED
        return True

    async def resume_scan(self, scan_id: UUID) -> bool:
        if scan_id not in self.scans:
            return False
            
        scan_record = self.scans[scan_id]
        if scan_record.status not in [ScanStatus.STOPPED, ScanStatus.PAUSED]:
            return False
        
        # Resume adapters
        if scan_id in self._paused_refs:
            refs = self._paused_refs[scan_id]
            resumed = False
            for scanner, ref_id in refs:
                # Try to resume
                if await scanner.resume_scan(ref_id):
                    resumed = True
            
            if resumed:
                # Move back to active
                self._active_refs[scan_id] = refs
                del self._paused_refs[scan_id]
                scan_record.status = ScanStatus.RUNNING
                
                # Restart workflow monitoring if needed?
                # The original `_run_scan_workflow` loop might have exited if it saw STOPPED.
                # If so, we need to restart the monitoring loop.
                # However, the original loop had `return` on STOPPED.
                # So we need to spawn a new monitoring task.
                asyncio.create_task(self._resume_monitoring(scan_id))
                return True
                
        return False

    async def _resume_monitoring(self, scan_id: UUID):
        # Simplified monitoring restart
        # Re-use logic or just call _run_scan_workflow again with specific state?
        # _run_scan_workflow initializes everything. We don't want that.
        # We just want to poll.
        target = self.scans[scan_id].target
        active_scans = self._active_refs.get(scan_id, [])
        scan_record = self.scans[scan_id]
        
        while True:
            all_done = True
            for scanner, ref_id in active_scans:
                if scan_record.status == ScanStatus.STOPPED:
                    return
                status = await scanner.get_status(ref_id)
                if status not in ["completed", "failed", "stopped"]:
                    all_done = False
                    break
            
            if all_done:
                break
            await asyncio.sleep(5)
            
        # Collect results again (incremental or full?)
        # Base adapters are stateless mostly, so `get_results` gets all?
        # If so, we might duplicate? 
        # `deduplicate_findings` handles duplicates.
        # So we can just re-run collection.
        
        all_findings = []
        for scanner, ref_id in active_scans:
            try:
                findings = await scanner.get_results(ref_id)
                all_findings.extend(findings)
            except Exception:
                pass
        
        scan_record.vulnerabilities = deduplicate_findings(all_findings + scan_record.vulnerabilities)
        scan_record.status = ScanStatus.COMPLETED

    _active_refs: Dict[UUID, List] = {} 
    _paused_refs: Dict[UUID, List] = {}

    async def _run_scan_workflow(self, scan_id: UUID, target: str):
        scan_record = self.scans[scan_id]
        scan_record.status = ScanStatus.RUNNING
        
        try:
            # 1. Start all scanners in parallel
            # We need to map which scanner returned which ref_id to later get results
            launch_tasks = []
            # Define logging callback
            def log_callback(msg: str):
                if scan_id in self.scans:
                    # Append timestamp
                    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    self.scans[scan_id].logs.append(f"[{timestamp}] {msg}")
            
            # Define finding callback
            def finding_callback(finding: Finding):
                if scan_id in self.scans:
                    scan = self.scans[scan_id]
                    scan.vulnerabilities.append(finding)
                    
                    # Update Summary Realtime
                    sev = finding.severity.lower()
                    if sev == "critical": scan.summary.critical += 1
                    elif sev == "high": scan.summary.high += 1
                    elif sev == "medium": scan.summary.medium += 1
                    elif sev == "low": scan.summary.low += 1
                    else: scan.summary.info += 1

            for scanner in self.scanners:
                launch_tasks.append(scanner.start_scan(target, log_callback, finding_callback))
            
            # These return ref_ids (strings) or raise exceptions
            ref_ids = await asyncio.gather(*launch_tasks, return_exceptions=True)
            
            active_scans = []
            for i, result in enumerate(ref_ids):
                if isinstance(result, Exception):
                    logger.error(f"Scanner {self.scanners[i].__class__.__name__} failed to start: {result}")
                    continue
                active_scans.append((self.scanners[i], result))
            
            self._active_refs[scan_id] = active_scans
            
            # 2. Poll/Wait for completion
            # Simple polling strategy: check all active scans every few seconds
            # In a robust system, we might use callbacks or message queues.
            
            while True:
                all_done = True
                for scanner, ref_id in active_scans:
                    # Check if global status is stopped
                    if scan_record.status == ScanStatus.STOPPED:
                        # Abort workflow
                        return

                    status = await scanner.get_status(ref_id)
                    if status not in ["completed", "failed", "stopped"]:
                        all_done = False
                        break
                
                if all_done:
                    break
                
                await asyncio.sleep(5)
            
            # 3. Collect Results
            all_findings = []
            for scanner, ref_id in active_scans:
                try:
                    findings = await scanner.get_results(ref_id)
                    all_findings.extend(findings)
                except Exception as e:
                    logger.error(f"Failed to get results from {scanner.__class__.__name__}: {e}")
            
            # 4. Normalize & Deduplicate
            normalized_findings = deduplicate_findings(all_findings)
            
            # 5. Update Record
            scan_record.vulnerabilities = normalized_findings
            
            # Update Summary
            summary = ScanSummary()
            for f in normalized_findings:
                if f.severity == "critical": summary.critical += 1
                elif f.severity == "high": summary.high += 1
                elif f.severity == "medium": summary.medium += 1
                elif f.severity == "low": summary.low += 1
                else: summary.info += 1
            
            scan_record.summary = summary
            scan_record.status = ScanStatus.COMPLETED
            
        except Exception as e:
            logger.error(f"Orchestrator workflow failed for {scan_id}: {e}")
            scan_record.status = ScanStatus.FAILED

scan_manager = ScanManager()
