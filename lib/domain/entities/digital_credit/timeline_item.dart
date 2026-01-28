class TimelineItem {
  final String status;
  final DateTime? at;
  final bool done;

  TimelineItem({
    required this.status,
    this.at,
    required this.done,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      status: json['status'] as String,
      at: json['at'] != null ? DateTime.parse(json['at']) : null,
      done: json['done'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'at': at?.toIso8601String(),
      'done': done,
    };
  }
}
