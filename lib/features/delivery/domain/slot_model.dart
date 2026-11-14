import 'package:cloud_firestore/cloud_firestore.dart';

class SlotModel {
  final String? id;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final int assignedOrders;
  final bool isActive;
  final bool isLocked;

  SlotModel({
    this.id,
    required this.startTime,
    required this.endTime,
    this.capacity = 0,
    this.assignedOrders = 0,
    this.isActive = true,
    this.isLocked = false,
  });

  bool get isFull {
    return assignedOrders >= capacity;
  }

  bool get isAvailable {
    return isActive && !isLocked && !isFull && endTime.isAfter(DateTime.now());
  }

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
      capacity: json['capacity'] ?? 0,
      assignedOrders: json['assignedOrders'] ?? 0,
      isActive: json['isActive'] ?? false,
      isLocked: json['isLocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'capacity': capacity,
      'assignedOrders': assignedOrders,
      'isActive': isActive,
      'isLocked': isLocked,
    };
  }
}
