import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Structured model representing a verified delivery address and coordinates.
class DeliveryLocation {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String shortTitle;
  final String? city;
  final String? pincode;
  final String source; // 'GPS' | 'Network'

  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.shortTitle,
    this.city,
    this.pincode,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'formattedAddress': formattedAddress,
        'shortTitle': shortTitle,
        'city': city,
        'pincode': pincode,
        'source': source,
      };

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) => DeliveryLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        formattedAddress: json['formattedAddress'] as String,
        shortTitle: json['shortTitle'] as String,
        city: json['city'] as String?,
        pincode: json['pincode'] as String?,
        source: json['source'] as String? ?? 'Network',
      );
}

/// Service that acquires accurate delivery location via GPS hardware or
/// resilient network fallback, with street-level reverse geocoding.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const _userAgent = 'FreshMeatApp/1.0 (Halal Meat Delivery)';

  /// Obtains current delivery location. Tries hardware GPS first; if permissions
  /// are denied, timed out, or unavailable (e.g. emulator), seamlessly falls back
  /// to high-accuracy IP/network geolocation and reverse geocoding.
  Future<DeliveryLocation?> getCurrentLocation({Duration timeout = const Duration(seconds: 6)}) async {
    // 1. Try Hardware GPS
    try {
      final gpsLocation = await _tryGetGpsLocation(timeout);
      if (gpsLocation != null) return gpsLocation;
    } catch (e) {
      debugPrint('LocationService GPS note: $e');
    }

    // 2. Resilient Network IP Geolocation + Reverse Geocoding
    try {
      final netLocation = await _tryGetNetworkLocation();
      if (netLocation != null) return netLocation;
    } catch (e) {
      debugPrint('LocationService Network note: $e');
    }

    // 3. Fallback default location (Chennai Central delivery hub)
    return const DeliveryLocation(
      latitude: 13.0827,
      longitude: 80.2707,
      formattedAddress: 'Evening Bazaar Road, Park Town, Chennai, Tamil Nadu 600003',
      shortTitle: 'Park Town, Chennai',
      city: 'Chennai',
      pincode: '600003',
      source: 'Default',
    );
  }

  Future<DeliveryLocation?> _tryGetGpsLocation(Duration timeout) async {
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

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 4),
      ),
    );

    // Reverse geocode the GPS coordinates
    final reverse = await reverseGeocode(pos.latitude, pos.longitude);
    if (reverse != null) {
      return DeliveryLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        formattedAddress: reverse.formattedAddress,
        shortTitle: reverse.shortTitle,
        city: reverse.city,
        pincode: reverse.pincode,
        source: 'GPS',
      );
    }

    return DeliveryLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      formattedAddress: 'Near ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
      shortTitle: 'Current Location',
      source: 'GPS',
    );
  }

  Future<DeliveryLocation?> _tryGetNetworkLocation() async {
    final client = http.Client();
    try {
      final res = await client.get(
        Uri.parse('http://ip-api.com/json/?fields=status,country,regionName,city,zip,lat,lon,district'),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();
          final city = data['city'] as String?;
          final zip = data['zip'] as String?;
          final district = data['district'] as String?;
          final region = data['regionName'] as String?;

          // Attempt Nominatim reverse geocode for full street details
          final reverse = await reverseGeocode(lat, lon);
          if (reverse != null && reverse.formattedAddress.isNotEmpty) {
            return DeliveryLocation(
              latitude: lat,
              longitude: lon,
              formattedAddress: reverse.formattedAddress,
              shortTitle: reverse.shortTitle,
              city: reverse.city ?? city,
              pincode: reverse.pincode ?? zip,
              source: 'Network',
            );
          }

          final locality = (district != null && district.isNotEmpty) ? district : city ?? 'Chennai';
          final addressParts = [
            if (district != null && district.isNotEmpty) district,
            if (city != null && city.isNotEmpty) city,
            if (region != null && region.isNotEmpty) region,
            if (zip != null && zip.isNotEmpty) zip,
          ];

          return DeliveryLocation(
            latitude: lat,
            longitude: lon,
            formattedAddress: addressParts.join(', '),
            shortTitle: locality,
            city: city,
            pincode: zip,
            source: 'Network',
          );
        }
      }
    } finally {
      client.close();
    }
    return null;
  }

  static const String googleMapsApiKey = 'AIzaSyAbmkcPdlRJysvLYqav6oHJAHybEcFnkD8';

  /// Reverse geocodes [lat], [lon] via OpenStreetMap Nominatim (100% free),
  /// with automatic fallback to Google Maps Geocoding if configured.
  Future<({String formattedAddress, String shortTitle, String? city, String? pincode})?> reverseGeocode(
    double lat,
    double lon,
  ) async {
    // 1. Resilient OpenStreetMap Nominatim (Free, community-powered, zero API key required)
    try {
      final nominatimResult = await _reverseGeocodeNominatim(lat, lon);
      if (nominatimResult != null) return nominatimResult;
    } catch (e) {
      debugPrint('LocationService Nominatim note: $e');
    }

    // 2. Google Maps fallback only if available
    try {
      final googleResult = await _reverseGeocodeGoogle(lat, lon);
      if (googleResult != null) return googleResult;
    } catch (_) {}

    return null;
  }

  Future<({String formattedAddress, String shortTitle, String? city, String? pincode})?> _reverseGeocodeGoogle(
    double lat,
    double lon,
  ) async {
    final client = http.Client();
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&key=$googleMapsApiKey',
      );
      final res = await client.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == 'OK') {
          final results = data['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            final first = results.first as Map<String, dynamic>;
            final formatted = first['formatted_address'] as String? ?? '';
            final components = first['address_components'] as List<dynamic>? ?? [];

            String? locality;
            String? sublocality;
            String? postalCode;

            for (final comp in components) {
              final types = (comp['types'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [];
              final longName = comp['long_name'] as String?;
              if (types.contains('sublocality') || types.contains('sublocality_level_1')) {
                sublocality ??= longName;
              } else if (types.contains('locality')) {
                locality ??= longName;
              } else if (types.contains('postal_code')) {
                postalCode ??= longName;
              }
            }

            final shortTitle = sublocality ?? locality ?? 'Current Location';
            return (
              formattedAddress: formatted,
              shortTitle: shortTitle,
              city: locality,
              pincode: postalCode,
            );
          }
        }
      }
    } catch (_) {
      // Graceful fallback to Nominatim
    } finally {
      client.close();
    }
    return null;
  }

  Future<({String formattedAddress, String shortTitle, String? city, String? pincode})?> _reverseGeocodeNominatim(
    double lat,
    double lon,
  ) async {
    final client = http.Client();
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );
      final res = await client.get(url, headers: {'User-Agent': _userAgent}).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['road'] as String?;
          final neighbourhood = address['neighbourhood'] as String?;
          final suburb = address['suburb'] as String?;
          final city = address['city'] as String? ?? address['town'] as String? ?? address['state_district'] as String?;
          final state = address['state'] as String?;
          final postcode = address['postcode'] as String?;
          final placeName = data['name'] as String?;

          // Clean up parts
          final parts = <String>[];
          if (placeName != null && placeName.trim().isNotEmpty && placeName != road) {
            parts.add(placeName.trim());
          }
          if (road != null && road.trim().isNotEmpty) parts.add(road.trim());
          if (neighbourhood != null && neighbourhood.trim().isNotEmpty && neighbourhood != road) {
            parts.add(neighbourhood.trim());
          }
          if (suburb != null && suburb.trim().isNotEmpty) parts.add(suburb.trim());
          if (city != null && city.trim().isNotEmpty) parts.add(city.trim());
          if (state != null && state.trim().isNotEmpty) parts.add(state.trim());
          if (postcode != null && postcode.trim().isNotEmpty) parts.add(postcode.trim());

          final formatted = parts.isNotEmpty ? parts.join(', ') : (data['display_name'] as String? ?? '');

          String? pickFirstNonEmpty(List<String?> items) {
            for (final i in items) {
              if (i != null && i.trim().isNotEmpty) return i.trim();
            }
            return null;
          }

          final shortTitle = pickFirstNonEmpty([suburb, neighbourhood, placeName, city]) ?? 'Current Location';

          return (
            formattedAddress: formatted,
            shortTitle: shortTitle,
            city: city,
            pincode: postcode,
          );
        }
      }
    } catch (_) {
      // Fallback if nominatim times out
    } finally {
      client.close();
    }
    return null;
  }

  /// Forward-geocodes text query to latitude, longitude and verified location metadata.
  Future<({double lat, double lon, String formattedAddress, String shortTitle})?> geocodeAddress(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return null;
    final client = http.Client();
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(clean)}&limit=1&addressdetails=1',
      );
      final res = await client.get(url, headers: {'User-Agent': _userAgent}).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(first['lon']?.toString() ?? '') ?? 0.0;
          if (lat != 0.0 && lon != 0.0) {
            final displayName = first['display_name'] as String? ?? clean;
            final address = first['address'] as Map<String, dynamic>?;
            final shortTitle = address?['suburb'] ??
                address?['neighbourhood'] ??
                address?['city'] ??
                address?['town'] ??
                clean;
            return (
              lat: lat,
              lon: lon,
              formattedAddress: displayName,
              shortTitle: shortTitle.toString(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('LocationService geocode error: $e');
    } finally {
      client.close();
    }
    return null;
  }
}
