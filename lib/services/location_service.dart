import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _defaultAddress = 'Kondhwa, Pune 411048';
  static const String _prefKey = 'precisioncare_user_location';

  /// Get cached or detected location
  static Future<String> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKey) ?? _defaultAddress;
    } catch (_) {
      return _defaultAddress;
    }
  }

  /// Request permission and fetch live device GPS location
  static Future<String?> fetchCurrentDeviceLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // Reverse geocode to address
      final placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }

        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          if (!parts.contains(place.subAdministrativeArea!)) {
            parts.add(place.subAdministrativeArea!);
          }
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }

        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          parts.add(place.postalCode!);
        }

        final address = parts.isNotEmpty ? parts.join(', ') : 'Pune, Maharashtra';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, address);
        return address;
      }
    } catch (e) {
      debugPrint('Location service error: $e');
    }
    return null;
  }
}
