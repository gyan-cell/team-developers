import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Centralized state management for scans with persistence
class ScanProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_scans';

  List<ScanResult> _scans = [];
  bool _isLoading = false;
  Timer? _pollingTimer;

  List<ScanResult> get scans => List.unmodifiable(_scans);
  bool get isLoading => _isLoading;

  // Dashboard metrics
  int get totalScans => _scans.length;
  int get activeScans => _scans.where((s) => s.status.isActive).length;
  int get completedScans =>
      _scans.where((s) => s.status == ScanStatus.completed).length;

  ScanSummary get aggregatedSummary {
    int critical = 0, high = 0, medium = 0, low = 0, info = 0;
    for (final scan in _scans) {
      critical += scan.summary.critical;
      high += scan.summary.high;
      medium += scan.summary.medium;
      low += scan.summary.low;
      info += scan.summary.info;
    }
    return ScanSummary(
      critical: critical,
      high: high,
      medium: medium,
      low: low,
      info: info,
    );
  }

  /// Initialize and load saved scans
  Future<void> initialize() async {
    await loadScans();
    _startPolling();
  }

  /// Load scans from local storage
  Future<void> loadScans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);

      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _scans = jsonList
            .map((json) => ScanResult.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by createdAt descending (newest first)
        _scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      print('Error loading scans: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save scans to local storage
  Future<void> _saveScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _scans.map((s) => s.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving scans: $e');
    }
  }

  /// Add a new scan
  Future<void> addScan(ScanResult scan) async {
    _scans.insert(0, scan);
    await _saveScans();
    notifyListeners();
  }

  /// Remove a scan (only if not running)
  Future<bool> removeScan(String scanId) async {
    final scan = _scans.firstWhere(
      (s) => s.scanId == scanId,
      orElse: () => throw Exception('Scan not found'),
    );

    if (scan.status.isActive) {
      return false; // Cannot delete running scan
    }

    _scans.removeWhere((s) => s.scanId == scanId);
    await _saveScans();
    notifyListeners();
    return true;
  }

  /// Update scan status
  Future<void> updateScanStatus(String scanId, ScanStatus newStatus) async {
    final index = _scans.indexWhere((s) => s.scanId == scanId);
    if (index != -1) {
      _scans[index].status = newStatus;
      await _saveScans();
      notifyListeners();
    }
  }

  /// Update scan with new summary
  Future<void> updateScanSummary(String scanId, ScanSummary summary) async {
    final index = _scans.indexWhere((s) => s.scanId == scanId);
    if (index != -1) {
      _scans[index].summary = summary;
      await _saveScans();
      notifyListeners();
    }
  }

  /// Stop a running scan
  Future<bool> stopScan(String scanId) async {
    try {
      // Note: If API has stop endpoint, call it here
      // await ApiService.stopScan(scanId);

      await updateScanStatus(scanId, ScanStatus.stopped);
      return true;
    } catch (e) {
      print('Error stopping scan: $e');
      return false;
    }
  }

  /// Refresh scan status from API
  Future<void> refreshScanStatus(String scanId) async {
    try {
      final result = await ApiService.getScanResults(scanId);
      final index = _scans.indexWhere((s) => s.scanId == scanId);

      if (index != -1) {
        _scans[index].status = result.status;
        _scans[index].summary = result.summary;
        await _saveScans();
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing scan status: $e');
    }
  }

  /// Refresh all active scans
  Future<void> refreshActiveScans() async {
    final activeScans = _scans.where((s) => s.status.isActive).toList();

    for (final scan in activeScans) {
      try {
        final result = await ApiService.getScanResults(scan.scanId);
        final index = _scans.indexWhere((s) => s.scanId == scan.scanId);

        if (index != -1) {
          _scans[index].status = result.status;
          _scans[index].summary = result.summary;
        }
      } catch (e) {
        print('Error refreshing scan ${scan.scanId}: $e');
      }
    }

    await _saveScans();
    notifyListeners();
  }

  /// Start polling for active scan updates
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_scans.any((s) => s.status.isActive)) {
        refreshActiveScans();
      }
    });
  }

  /// Get scan by ID
  ScanResult? getScan(String scanId) {
    try {
      return _scans.firstWhere((s) => s.scanId == scanId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
