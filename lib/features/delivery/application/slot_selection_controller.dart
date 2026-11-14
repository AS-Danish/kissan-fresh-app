import 'package:kissanfresh/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/core/utils/custom_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/features/delivery/domain/slot_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kissanfresh/core/services/network_service.dart';

class SlotSelectionController extends FeatureController
    with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ObservableList<SlotModel> availableSlots = ObservableList(<SlotModel>[]);
  Observable<bool> isLoading = Observable(false);
  Observable<bool> hasError = Observable(false);
  Observable<String> errorMessage = Observable('');
  Observable<String> selectedSlotId = Observable('');

  // Date tabs state
  ObservableList<String> availableDates = ObservableList(<String>[]);
  Observable<String> selectedDateLabel = Observable('');

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchSlots();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-fetch when customer returns to the app to ensure slots are not stale
      fetchSlots(silent: availableSlots.isNotEmpty);
    }
  }

  Future<void> fetchSlots({
    bool isUserRefresh = false,
    bool silent = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';

    try {
      if (!await NetworkService.isConnected()) {
        hasError.value = true;
        errorMessage.value =
            'No internet connection. Please check your network and try again.';
        NetworkService.showNoInternetSnackbar();
        isLoading.value = false;
        return;
      }

      final now = DateTime.now();
      // Fetch upcoming slots, order by startTime to show chronological order
      // Limit to 50 to ensure we get plenty of slots for today and tomorrow
      final snap = await _firestore
          .collection('slots')
          .where('startTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startTime', descending: false)
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

      // Maintain selection if still valid, otherwise default to first available date
      if (availableDates.isNotEmpty) {
        if (!availableDates.contains(selectedDateLabel.value)) {
          selectedDateLabel.value = availableDates.first;
        }
      } else {
        selectedDateLabel.value = '';
      }

      // If a selected slot exists from before, ensure it's still available and not expired
      if (selectedSlotId.value.isNotEmpty) {
        final slotExistsAndAvailable = availableSlots.any(
          (s) => s.id == selectedSlotId.value && s.isAvailable,
        );
        if (!slotExistsAndAvailable) {
          selectedSlotId.value = '';
        }
      }
    } catch (e) {
      debugPrint("Error fetching slots: $e");
      hasError.value = true;
      errorMessage.value = 'Could not fetch delivery slots. Please try again.';
      if (isUserRefresh || availableSlots.isEmpty) {
        CustomSnackBar.show(
          'Error',
          'Could not fetch delivery slots. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
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

final slotSelectionControllerProvider = Provider(
  (ref) => startController(ref, SlotSelectionController()),
);
