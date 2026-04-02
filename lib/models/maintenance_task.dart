import 'package:cloud_firestore/cloud_firestore.dart';

/// Recurrence interval for a maintenance task.
enum TaskRecurrence {
  none,
  weekly,
  biweekly,
  monthly,
  quarterly,
  biannual,
  yearly,
}

extension TaskRecurrenceLabel on TaskRecurrence {
  String get label => switch (this) {
    TaskRecurrence.none => 'One-time',
    TaskRecurrence.weekly => 'Weekly',
    TaskRecurrence.biweekly => 'Every 2 weeks',
    TaskRecurrence.monthly => 'Monthly',
    TaskRecurrence.quarterly => 'Every 3 months',
    TaskRecurrence.biannual => 'Every 6 months',
    TaskRecurrence.yearly => 'Yearly',
  };

  /// Next due date from [from] based on this recurrence.
  DateTime? nextDate(DateTime from) => switch (this) {
    TaskRecurrence.none => null,
    TaskRecurrence.weekly => from.add(const Duration(days: 7)),
    TaskRecurrence.biweekly => from.add(const Duration(days: 14)),
    TaskRecurrence.monthly => DateTime(from.year, from.month + 1, from.day),
    TaskRecurrence.quarterly => DateTime(from.year, from.month + 3, from.day),
    TaskRecurrence.biannual => DateTime(from.year, from.month + 6, from.day),
    TaskRecurrence.yearly => DateTime(from.year + 1, from.month, from.day),
  };
}

/// A maintenance task for the washing machine.
class MaintenanceTask {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskRecurrence recurrence;
  final bool completed;
  final DateTime? completedAt;
  final List<String> photoUrls; // Firebase Storage URLs
  final bool photoRequired; // whether user wants to attach a photo
  final DateTime createdAt;

  MaintenanceTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.recurrence = TaskRecurrence.none,
    this.completed = false,
    this.completedAt,
    this.photoUrls = const [],
    this.photoRequired = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue => !completed && dueDate.isBefore(DateTime.now());
  bool get isDueToday {
    final now = DateTime.now();
    return !completed &&
        dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'dueDate': Timestamp.fromDate(dueDate),
    'recurrence': recurrence.index,
    'completed': completed,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
    'photoUrls': photoUrls,
    'photoRequired': photoRequired,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory MaintenanceTask.fromMap(String id, Map<String, dynamic> data) {
    return MaintenanceTask(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recurrence:
          TaskRecurrence.values.elementAtOrNull(data['recurrence'] ?? 0) ??
          TaskRecurrence.none,
      completed: data['completed'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      photoRequired: data['photoRequired'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MaintenanceTask copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskRecurrence? recurrence,
    bool? completed,
    DateTime? completedAt,
    List<String>? photoUrls,
    bool? photoRequired,
  }) {
    return MaintenanceTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      photoUrls: photoUrls ?? this.photoUrls,
      photoRequired: photoRequired ?? this.photoRequired,
      createdAt: createdAt,
    );
  }
}

/// Preset maintenance tasks for IFB washing machines.
class MaintenancePresets {
  static List<
    ({
      String title,
      String description,
      TaskRecurrence recurrence,
      int daysFromNow,
      bool photoRequired,
    })
  >
  get all => [
    (
      title: 'Clean lint filter',
      description:
          'Remove and clean the lint filter under running water. Let it dry before reinserting.',
      recurrence: TaskRecurrence.monthly,
      daysFromNow: 30,
      photoRequired: false,
    ),
    (
      title: 'Drain pump filter',
      description:
          'Open the drain pump cover at the bottom front. Place a towel, unscrew the filter, drain water, clean debris, and reinsert.',
      recurrence: TaskRecurrence.monthly,
      daysFromNow: 30,
      photoRequired: true,
    ),
    (
      title: 'Run Tub Clean cycle',
      description:
          'Run the Tub Clean program with a washing machine cleaner or baking soda to prevent mold and odor.',
      recurrence: TaskRecurrence.monthly,
      daysFromNow: 30,
      photoRequired: false,
    ),
    (
      title: 'Clean detergent drawer',
      description:
          'Pull out the detergent drawer, soak in warm water, scrub residue, and dry before reinserting.',
      recurrence: TaskRecurrence.biweekly,
      daysFromNow: 14,
      photoRequired: false,
    ),
    (
      title: 'Wipe door seal/gasket',
      description:
          'Wipe the rubber door gasket with a damp cloth and mild detergent. Check for mold in the folds.',
      recurrence: TaskRecurrence.weekly,
      daysFromNow: 7,
      photoRequired: false,
    ),
    (
      title: 'Inspect inlet hose',
      description:
          'Check the water inlet hose for kinks, cracks, or leaks. Replace if damaged.',
      recurrence: TaskRecurrence.quarterly,
      daysFromNow: 90,
      photoRequired: true,
    ),
    (
      title: 'Descale machine',
      description:
          'Run an empty hot cycle with descaling solution or white vinegar to remove limescale buildup.',
      recurrence: TaskRecurrence.quarterly,
      daysFromNow: 90,
      photoRequired: false,
    ),
    (
      title: 'Check drain hose',
      description:
          'Inspect the drain hose for blockages and ensure it\'s properly positioned (elbow height).',
      recurrence: TaskRecurrence.quarterly,
      daysFromNow: 90,
      photoRequired: true,
    ),
  ];
}
