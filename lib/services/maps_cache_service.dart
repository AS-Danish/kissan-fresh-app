import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsCacheService {
  static String get _apiKey => dotenv.env['MAPS_API_KEY'] ?? '';
  static const String _boxName = 'maps_cache';
  static const String _collectionName = 'maps_cache';

  // Get box
  Box get _box => Hive.box(_boxName);
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _checkLocalCache(String key) async {
    if (_box.containsKey(key)) {
      final dataStr = _box.get(key);
      if (dataStr != null) {
        final data = Map<String, dynamic>.from(json.decode(dataStr));
        if (_isCacheValid(data)) {
          debugPrint('Served from Hive Local Cache: $key');
          return data['result'];
        } else {
          debugPrint('Local Cache Expired: $key');
          await _box.delete(key);
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _checkGlobalCache(String key) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(key).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (_isCacheValid(data)) {
          debugPrint('Served from Firestore Global Cache: $key');
          // Save valid data back to local cache
          await _saveToLocalCache(key, data);
          return data['result'];
        } else {
          debugPrint('Global Cache Expired: $key');
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Firestore Cache Error: $e');
    }
    return null;
  }

  bool _isCacheValid(Map<String, dynamic> data) {
    if (!data.containsKey('timestamp')) return false;
    final timestamp = DateTime.parse(data['timestamp']);
    return DateTime.now().difference(timestamp).inDays <= 30;
  }

  Future<void> _saveToLocalCache(String key, Map<String, dynamic> data) async {
    await _box.put(key, json.encode(data));
  }

  Future<void> _saveToGlobalCache(String key, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collectionName).doc(key).set(data);
    } catch (e) {
      debugPrint('Firestore Save Error: $e');
    }
  }

  Future<void> _saveToCache(String key, dynamic resultData) async {
    debugPrint('Saved to Firebase and Hive: $key');
    final cacheWrapper = {
      'timestamp': DateTime.now().toIso8601String(),
      'result': resultData,
    };
    await _saveToLocalCache(key, cacheWrapper);
    await _saveToGlobalCache(key, cacheWrapper);
  }

  Future<String?> reverseGeocode(LatLng point) async {
    // Create a unique key for the coordinates
    // We round to 4 decimal places to increase cache hits for very close points
    final lat = point.latitude.toStringAsFixed(4);
    final lng = point.longitude.toStringAsFixed(4);
    final key = 'rev_${lat}_$lng';

    // 1. Check Local Cache (Hive)
    final localData = await _checkLocalCache(key);
    if (localData != null) return localData['address'];

    // 2. Check Global Cache (Firestore)
    final globalData = await _checkGlobalCache(key);
    if (globalData != null) return globalData['address'];

    // 3. Google Maps API Fallback
    debugPrint('Fetching from Google Maps API: $key');
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${point.latitude},${point.longitude}&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'];
          
          // Save to Both Caches
          await _saveToCache(key, {'address': address});
          
          return address;
        }
      }
    } catch (e) {
      debugPrint('Reverse Geocoding Error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> searchAddress(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    // Create a key from the query string
    // Firestore keys cannot contain slashes or some special chars, so we format it safely
    final key = 'search_${trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9]'), "_")}';

    // 1. Check Local Cache (Hive)
    final localData = await _checkLocalCache(key);
    if (localData != null) return localData;

    // 2. Check Global Cache (Firestore)
    final globalData = await _checkGlobalCache(key);
    if (globalData != null) return globalData;

    // 3. Google Maps API Fallback
    debugPrint('Fetching from Google Maps API: $key');
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(query.trim())}&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          final address = data['results'][0]['formatted_address'];
          
          final resultData = {
            'lat': loc['lat'],
            'lng': loc['lng'],
            'address': address
          };

          // Save to Both Caches
          await _saveToCache(key, resultData);
          
          return resultData;
        }
      }
    } catch (e) {
      debugPrint('Search Error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAutocompletePredictions(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    final key = 'auto_${trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9]'), "_")}';

    // 1. Check Local Cache (Hive)
    final localData = await _checkLocalCache(key);
    if (localData != null) return List<Map<String, dynamic>>.from(localData['predictions'] ?? []);

    // 2. Check Global Cache (Firestore)
    final globalData = await _checkGlobalCache(key);
    if (globalData != null) return List<Map<String, dynamic>>.from(globalData['predictions'] ?? []);

    // 3. Google API Fallback
    debugPrint('Fetching from Google Places Autocomplete API: $key');
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query.trim())}&key=$_apiKey'
          // Optional: Add session tokens or components to narrow down results (e.g. '&components=country:in')
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final List<Map<String, dynamic>> predictions = (data['predictions'] as List)
              .map((p) => {
                    'description': p['description'],
                    'place_id': p['place_id'],
                  })
              .toList();

          await _saveToCache(key, {'predictions': predictions});
          return predictions;
        }
      }
    } catch (e) {
      debugPrint('Autocomplete Error: $e');
    }
    return [];
  }
}
