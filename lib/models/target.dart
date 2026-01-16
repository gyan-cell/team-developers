class Target {
  final String id;
  final String name;
  final String url;
  final DateTime? lastScanned;

  Target({
    required this.id,
    required this.name,
    required this.url,
    this.lastScanned,
  });

  factory Target.fromJson(Map<String, dynamic> json) {
    return Target(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      lastScanned: json['lastScanned'] != null
          ? DateTime.parse(json['lastScanned'] as String)
          : null,
    );
  }
}
