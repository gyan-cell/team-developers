import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://10.149.135.102:8060';
  static const String _apiKey = 'secret-api-key';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': _apiKey,
  };

  /// POST /scan - Start a new DAST scan
  /// Returns ScanResponse: {scan_id, status}
  static Future<ScanResponse> startScan(String targetUrl) async {
    final url = Uri.parse('$_baseUrl/scan');

    // Ensure URL has protocol
    String normalizedUrl = targetUrl.trim();
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'http://$normalizedUrl';
    }

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'target': normalizedUrl}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ScanResponse.fromJson(data);
      } else {
        throw ApiException(
          'Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET /scan/{scan_id} - Get scan results
  /// Returns ScanResult: {scan_id, status, target, summary, vulnerabilities, logs}
  static Future<ScanResult> getScanResults(String scanId) async {
    final url = Uri.parse('$_baseUrl/scan/$scanId');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ScanResult.fromJson(data);
      } else {
        throw ApiException(
          'Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET /scan/{scan_id}/summary - Get scan summary
  /// Returns ScanSummary: {critical, high, medium, low, info}
  static Future<ScanSummary> getScanSummary(String scanId) async {
    final url = Uri.parse('$_baseUrl/scan/$scanId/summary');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ScanSummary.fromJson(data);
      } else {
        throw ApiException(
          'Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET /scan/{scan_id}/findings - Get all findings, optionally filtered by severity
  /// Returns List<Finding>
  static Future<List<Finding>> getScanFindings(
    String scanId, {
    String? severity,
  }) async {
    var urlString = '$_baseUrl/scan/$scanId/findings';
    if (severity != null) {
      urlString += '?severity=$severity';
    }
    final url = Uri.parse(urlString);

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((f) => Finding.fromJson(f as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET /scan/{scan_id}/findings/grouped - Get findings grouped by scanner
  /// Returns Map<String, List<Finding>>
  static Future<Map<String, List<Finding>>> getScanFindingsGrouped(
    String scanId,
  ) async {
    final url = Uri.parse('$_baseUrl/scan/$scanId/findings/grouped');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, List<Finding>> result = {};

        // Debug: print raw response
        print('DEBUG: Raw grouped findings response: $data');

        data.forEach((scanner, findings) {
          print(
            'DEBUG: Scanner "$scanner" has ${findings is List ? findings.length : 0} findings',
          );
          if (findings is List) {
            result[scanner] = findings
                .map((f) => Finding.fromJson(f as Map<String, dynamic>))
                .toList();
          }
        });

        print('DEBUG: Parsed ${result.length} scanners with findings');

        return result;
      } else {
        throw ApiException(
          'Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET /scan/{scan_id}/logs - Get scan logs
  /// Returns List<String>
  static Future<List<String>> getScanLogs(String scanId) async {
    final url = Uri.parse('$_baseUrl/scan/$scanId/logs');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((s) => s.toString()).toList();
      } else {
        throw ApiException(
          'Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET /health - Health check
  static Future<bool> healthCheck() async {
    final url = Uri.parse('$_baseUrl/health');

    try {
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ==================== API Models ====================

/// Scan status enum
enum ScanStatus {
  queued,
  started,
  running,
  stopped,
  completed,
  failed;

  static ScanStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'queued':
        return ScanStatus.queued;
      case 'started':
        return ScanStatus.started;
      case 'running':
        return ScanStatus.running;
      case 'stopped':
        return ScanStatus.stopped;
      case 'completed':
        return ScanStatus.completed;
      case 'failed':
        return ScanStatus.failed;
      default:
        return ScanStatus.started;
    }
  }

  bool get isActive =>
      this == ScanStatus.started ||
      this == ScanStatus.running ||
      this == ScanStatus.queued;
}

/// Severity enum
enum Severity {
  critical,
  high,
  medium,
  low,
  info;

  static Severity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'critical':
        return Severity.critical;
      case 'high':
        return Severity.high;
      case 'medium':
        return Severity.medium;
      case 'low':
        return Severity.low;
      case 'info':
        return Severity.info;
      default:
        return Severity.info;
    }
  }
}

/// Response from POST /scan
class ScanResponse {
  final String scanId;
  final ScanStatus status;

  ScanResponse({required this.scanId, required this.status});

  factory ScanResponse.fromJson(Map<String, dynamic> json) {
    return ScanResponse(
      scanId: json['scan_id'] as String? ?? '',
      status: ScanStatus.fromString(json['status'] as String? ?? 'started'),
    );
  }
}

/// Summary of scan findings by severity
class ScanSummary {
  final int critical;
  final int high;
  final int medium;
  final int low;
  final int info;

  ScanSummary({
    this.critical = 0,
    this.high = 0,
    this.medium = 0,
    this.low = 0,
    this.info = 0,
  });

  int get total => critical + high + medium + low + info;

  factory ScanSummary.fromJson(Map<String, dynamic> json) {
    return ScanSummary(
      critical: json['critical'] as int? ?? 0,
      high: json['high'] as int? ?? 0,
      medium: json['medium'] as int? ?? 0,
      low: json['low'] as int? ?? 0,
      info: json['info'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'critical': critical,
      'high': high,
      'medium': medium,
      'low': low,
      'info': info,
    };
  }
}

/// Individual finding/vulnerability
class Finding {
  final String scanner;
  final String name;
  final Severity severity;
  final String url;
  final String? description;
  final String? cwe;
  final double? cvss;

  Finding({
    required this.scanner,
    required this.name,
    required this.severity,
    required this.url,
    this.description,
    this.cwe,
    this.cvss,
  });

  factory Finding.fromJson(Map<String, dynamic> json) {
    return Finding(
      scanner: json['scanner'] as String? ?? '',
      name: json['name'] as String? ?? '',
      severity: Severity.fromString(json['severity'] as String? ?? 'info'),
      url: json['url'] as String? ?? '',
      description: json['description'] as String?,
      cwe: json['cwe'] as String?,
      cvss: (json['cvss'] as num?)?.toDouble(),
    );
  }
}

/// Full scan result from GET /scan/{scan_id}
class ScanResult {
  final String scanId;
  ScanStatus status;
  final String target;
  ScanSummary summary;
  List<Finding> vulnerabilities;
  List<String> logs;
  final DateTime createdAt;

  ScanResult({
    required this.scanId,
    required this.status,
    required this.target,
    required this.summary,
    this.vulnerabilities = const [],
    this.logs = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      scanId: json['scan_id'] as String? ?? '',
      status: ScanStatus.fromString(json['status'] as String? ?? 'started'),
      target: json['target'] as String? ?? '',
      summary: json['summary'] != null
          ? ScanSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : ScanSummary(),
      vulnerabilities:
          (json['vulnerabilities'] as List<dynamic>?)
              ?.map((v) => Finding.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      logs:
          (json['logs'] as List<dynamic>?)?.map((s) => s.toString()).toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scan_id': scanId,
      'status': status.name,
      'target': target,
      'summary': summary.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from ScanResponse (initial scan)
  factory ScanResult.fromScanResponse(ScanResponse response, String targetUrl) {
    return ScanResult(
      scanId: response.scanId,
      status: response.status,
      target: targetUrl,
      summary: ScanSummary(),
    );
  }

  /// Create a copy with updated status
  ScanResult copyWith({
    ScanStatus? status,
    ScanSummary? summary,
    List<Finding>? vulnerabilities,
  }) {
    return ScanResult(
      scanId: scanId,
      status: status ?? this.status,
      target: target,
      summary: summary ?? this.summary,
      vulnerabilities: vulnerabilities ?? this.vulnerabilities,
      logs: logs,
      createdAt: createdAt,
    );
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
