import 'package:cloud_firestore/cloud_firestore.dart';

class SlotModel {
  final String? id;
  final DateTime startTime;
  final DateTime endTime;

  SlotModel({
    this.id,
    required this.startTime,
    required this.endTime,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json, {String? id}) {
    // Handle both Timestamp (Firestore) and String (from cached JSON)
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
      return DateTime.now();
    }

    return SlotModel(
      id: id ?? json['id'],
      startTime: parseDate(json['startTime']),
      endTime: parseDate(json['endTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
}
