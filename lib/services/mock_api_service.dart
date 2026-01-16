import '../models/scan.dart';
import '../models/vulnerability.dart';

class DashboardSummary {
  final int totalTargets;
  final int totalScans;
  final int highVulnerabilities;
  final int mediumVulnerabilities;
  final int lowVulnerabilities;

  DashboardSummary({
    required this.totalTargets,
    required this.totalScans,
    required this.highVulnerabilities,
    required this.mediumVulnerabilities,
    required this.lowVulnerabilities,
  });
}

class MockApiService {
  static Future<DashboardSummary> getDashboardSummary() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DashboardSummary(
      totalTargets: 12,
      totalScans: 47,
      highVulnerabilities: 8,
      mediumVulnerabilities: 23,
      lowVulnerabilities: 45,
    );
  }

  static Future<List<Scan>> getRecentScans() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Scan(
        id: '1',
        targetName: 'api.example.com',
        status: ScanStatus.running,
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
        vulnerabilitiesFound: 3,
      ),
      Scan(
        id: '2',
        targetName: 'dashboard.myapp.io',
        status: ScanStatus.completed,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        vulnerabilitiesFound: 12,
      ),
      Scan(
        id: '3',
        targetName: 'auth.service.net',
        status: ScanStatus.completed,
        startTime: DateTime.now().subtract(const Duration(hours: 5)),
        vulnerabilitiesFound: 7,
      ),
      Scan(
        id: '4',
        targetName: 'payment.gateway.com',
        status: ScanStatus.failed,
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        vulnerabilitiesFound: 0,
      ),
      Scan(
        id: '5',
        targetName: 'cdn.assets.io',
        status: ScanStatus.completed,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        vulnerabilitiesFound: 2,
      ),
    ];
  }

  static Future<List<Vulnerability>> getVulnerabilities({
    Severity? severity,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final allVulnerabilities = [
      Vulnerability(
        id: '1',
        name: 'SQL Injection',
        severity: Severity.high,
        targetId: '1',
        description: 'SQL injection vulnerability in login endpoint',
      ),
      Vulnerability(
        id: '2',
        name: 'Cross-Site Scripting (XSS)',
        severity: Severity.high,
        targetId: '2',
        description: 'Reflected XSS in search parameter',
      ),
      Vulnerability(
        id: '3',
        name: 'Insecure Direct Object Reference',
        severity: Severity.high,
        targetId: '1',
        description: 'IDOR vulnerability in user profile API',
      ),
      Vulnerability(
        id: '4',
        name: 'Missing Security Headers',
        severity: Severity.medium,
        targetId: '3',
        description: 'X-Frame-Options header not set',
      ),
      Vulnerability(
        id: '5',
        name: 'Outdated SSL/TLS Version',
        severity: Severity.medium,
        targetId: '2',
        description: 'Server supports TLS 1.0 which is deprecated',
      ),
      Vulnerability(
        id: '6',
        name: 'Session Fixation',
        severity: Severity.medium,
        targetId: '1',
        description: 'Session ID not regenerated after login',
      ),
      Vulnerability(
        id: '7',
        name: 'Information Disclosure',
        severity: Severity.low,
        targetId: '4',
        description: 'Server version exposed in headers',
      ),
      Vulnerability(
        id: '8',
        name: 'Cookie Without Secure Flag',
        severity: Severity.low,
        targetId: '2',
        description: 'Session cookie missing secure attribute',
      ),
    ];

    if (severity != null) {
      return allVulnerabilities.where((v) => v.severity == severity).toList();
    }
    return allVulnerabilities;
  }
}
