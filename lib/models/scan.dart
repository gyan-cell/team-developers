enum ScanStatus { running, completed, failed }

class Scan {
  final String id;
  final String targetName;
  final ScanStatus status;
  final DateTime startTime;
  final int vulnerabilitiesFound;

  Scan({
    required this.id,
    required this.targetName,
    required this.status,
    required this.startTime,
    required this.vulnerabilitiesFound,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      id: json['id'] as String,
      targetName: json['targetName'] as String,
      status: ScanStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ScanStatus.completed,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      vulnerabilitiesFound: json['vulnerabilitiesFound'] as int,
    );
  }
}
