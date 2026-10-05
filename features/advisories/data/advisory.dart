import '../../../core/date_format.dart';

/// An advisory from GET /dashboard/advisories. [type] is 'tip' | 'weather' | 'alert';
/// [severity] is 'low' | 'medium' | 'high'.
class Advisory {
  const Advisory({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.createdAt,
  });

  factory Advisory.fromJson(Map<String, dynamic> json) => Advisory(
        id: '${json['id']}',
        title: (json['title'] ?? '') as String,
        message: (json['message'] ?? '') as String,
        type: '${json['type'] ?? ''}',
        severity: '${json['severity'] ?? ''}',
        createdAt: parseServerTime(json['created_at'] as String),
      );

  final String id;
  final String title;
  final String message;
  final String type;
  final String severity;
  final DateTime createdAt;
}
