import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../model/slot_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SlotSelectionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<SlotModel> availableSlots = <SlotModel>[].obs;
  RxBool isLoading = false.obs;
  RxString selectedSlotId = ''.obs;

  // Date tabs state
  RxList<String> availableDates = <String>[].obs;
  RxString selectedDateLabel = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSlots();
  }

  Future<void> fetchSlots() async {
    isLoading.value = true;
    try {
      final now = DateTime.now();
      // Fetch upcoming slots, order by endTime to show chronological order
      // Limit to 50 to ensure we get plenty of slots for today and tomorrow
      final snap = await _firestore
          .collection('slots')
          .where('endTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('endTime', descending: false)
          .limit(50)
          .get();

      availableSlots.value = snap.docs
          .map((doc) => SlotModel.fromJson(doc.data(), id: doc.id))
          .toList();

      // Extract unique dates for tab headers
      final Set<String> dates = {};
      for (var slot in availableSlots) {
        dates.add(_formatDateGroup(slot.startTime));
      }
      availableDates.value = dates.toList();

      // Auto-select first date if available
      if (availableDates.isNotEmpty) {
        selectedDateLabel.value = availableDates.first;
      }

      // If a selected slot exists from before, ensure it's in the valid date range
      // or clear it if the user comes back.
      if (selectedSlotId.value.isNotEmpty) {
        final slotExists = availableSlots.any(
          (s) => s.id == selectedSlotId.value,
        );
        if (!slotExists) selectedSlotId.value = '';
      }
    } catch (e) {
      debugPrint("Error fetching slots: $e");
      Get.snackbar(
        'Error',
        'Could not fetch delivery slots. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectSlot(String slotId) {
    selectedSlotId.value = slotId;
  }

  void selectDate(String dateLabel) {
    selectedDateLabel.value = dateLabel;
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return "Today";
    } else if (targetDate == tomorrow) {
      return "Tomorrow";
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  List<SlotModel> get slotsForSelectedDate {
    return availableSlots
        .where(
          (slot) => _formatDateGroup(slot.startTime) == selectedDateLabel.value,
        )
        .toList();
  }
}
