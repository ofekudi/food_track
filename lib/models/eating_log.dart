import 'package:intl/intl.dart';

/// Reason tags for eating
enum EatingReason {
  hungry,
  bored,
  craving,
  social;

  String get displayName {
    switch (this) {
      case EatingReason.hungry:
        return 'Hungry';
      case EatingReason.bored:
        return 'Bored';
      case EatingReason.craving:
        return 'Craving';
      case EatingReason.social:
        return 'Social';
    }
  }

  static EatingReason fromString(String value) {
    return EatingReason.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => EatingReason.hungry,
    );
  }
}

class EatingLog {
  final String id;
  final String description; // "3 schnitzels", "handful of chips"
  final int hungerLevel; // 1-5
  final EatingReason reason;
  final DateTime entryDate;
  final DateTime createdAt; // For time analytics

  EatingLog({
    required this.id,
    required this.description,
    required this.hungerLevel,
    required this.reason,
    required this.entryDate,
    required this.createdAt,
  });

  factory EatingLog.fromMap(Map<String, dynamic> map) {
    DateTime parsedEntryDate;
    try {
      parsedEntryDate =
          DateFormat('yyyy-MM-dd').parseStrict(map['entry_date'] as String);
    } catch (e) {
      try {
        DateTime createdAt = DateTime.parse(map['created_at'] as String);
        parsedEntryDate =
            DateTime(createdAt.year, createdAt.month, createdAt.day);
      } catch (_) {
        parsedEntryDate = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);
      }
    }

    return EatingLog(
      id: map['id'] as String,
      description: map['description'] as String,
      hungerLevel: map['hunger_level'] as int? ?? 3,
      reason: EatingReason.fromString(map['reason'] as String? ?? 'hungry'),
      entryDate: parsedEntryDate,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'hunger_level': hungerLevel,
      'reason': reason.name,
      'entry_date': DateFormat('yyyy-MM-dd').format(entryDate),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns true if this log suggests non-mindful eating (low hunger + bored)
  bool get suggestsIntervention => hungerLevel <= 2 && reason == EatingReason.bored;
}
