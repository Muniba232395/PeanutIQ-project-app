import '../../../core/config.dart';
import '../../../core/media_url.dart';

/// A saved scan from GET /scans/.
class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.confidence,
    required this.imageUrl,
    required this.createdAt,
  });

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: '${json['id']}',
        type: (json['type'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        status: (json['status'] ?? '') as String,
        confidence: (json['confidence_score'] as num?)?.toDouble() ?? 0,
        imageUrl: resolveMediaUrl((json['image_url'] ?? '') as String, apiBaseUrl),
        // Shown with the website's `new Date(created_at).toLocaleDateString()`, which reads a
        // zone-less string as local time.
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;

  /// 'Seed Intelligence' | 'Disease Intelligence'
  final String type;
  final String title;

  /// 'Healthy' | 'High Risk' | 'Moderate' | ...
  final String status;
  final double confidence;
  final String imageUrl;
  final DateTime createdAt;

  bool get isSeed => type == 'Seed Intelligence';
}
