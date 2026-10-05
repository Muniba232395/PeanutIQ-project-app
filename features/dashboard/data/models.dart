import '../../../core/date_format.dart';

class ActionItem {
  const ActionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.isCompleted,
    this.dueDate,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) => ActionItem(
        id: '${json['id']}',
        title: (json['title'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        isCompleted: json['is_completed'] == true,
        // The website shows due dates with `new Date(due_date)`, which reads a zone-less
        // string as local time, so the calendar date never shifts. Same here.
        dueDate: json['due_date'] is String ? DateTime.parse(json['due_date'] as String) : null,
      );

  final String id;
  final String title;
  final String category;
  final bool isCompleted;
  final DateTime? dueDate;

  ActionItem copyWith({bool? isCompleted}) => ActionItem(
        id: id,
        title: title,
        category: category,
        isCompleted: isCompleted ?? this.isCompleted,
        dueDate: dueDate,
      );
}

class ActivityEntry {
  const ActivityEntry({required this.action, required this.timestamp, this.details});

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
        action: (json['action'] ?? '') as String,
        details: json['details'] as String?,
        timestamp: parseServerTime(json['timestamp'] as String),
      );

  final String action;
  final String? details;
  final DateTime timestamp;
}

/// GET /dashboard/crop-profile. [stage] is sowing | flowering | pegging | podFill | harvesting.
class CropProfile {
  const CropProfile({
    required this.stage,
    required this.goodPct,
    required this.averagePct,
    required this.poorPct,
  });

  factory CropProfile.fromJson(Map<String, dynamic> json) => CropProfile(
        stage: '${json['stage'] ?? 'pegging'}',
        goodPct: (json['health_good_pct'] as num?)?.toInt() ?? 0,
        averagePct: (json['health_average_pct'] as num?)?.toInt() ?? 0,
        poorPct: (json['health_poor_pct'] as num?)?.toInt() ?? 0,
      );

  final String stage;
  final int goodPct;
  final int averagePct;
  final int poorPct;
}
