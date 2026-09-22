import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';

void main() {
  test('asks Android for a fix at most every 5 seconds and 20 meters', () {
    final settings = navigationLocationSettings(TargetPlatform.android);

    expect(settings, isA<AndroidSettings>());
    expect(settings.accuracy, LocationAccuracy.high);
    expect(settings.distanceFilter, 20);
    expect((settings as AndroidSettings).intervalDuration, const Duration(seconds: 5));
  });

  test('lets iOS pause GPS during vehicle navigation', () {
    final settings = navigationLocationSettings(TargetPlatform.iOS) as AppleSettings;

    expect(settings.accuracy, LocationAccuracy.high);
    expect(settings.distanceFilter, 20);
    expect(settings.activityType, ActivityType.automotiveNavigation);
    expect(settings.pauseLocationUpdatesAutomatically, isTrue);
    expect(settings.allowBackgroundLocationUpdates, isFalse);
  });
}
