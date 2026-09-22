import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';

void main() {
  test('asks Android for a fix about every second after 5 meters', () {
    final settings = navigationLocationSettings(TargetPlatform.android);

    expect(settings, isA<AndroidSettings>());
    expect(settings.accuracy, LocationAccuracy.high);
    expect(settings.distanceFilter, 5);
    expect((settings as AndroidSettings).intervalDuration, const Duration(seconds: 1));
  });

  test('lets iOS update often enough to follow someone walking', () {
    final settings = navigationLocationSettings(TargetPlatform.iOS) as AppleSettings;

    expect(settings.accuracy, LocationAccuracy.high);
    expect(settings.distanceFilter, 5);
    expect(settings.activityType, ActivityType.other);
    expect(settings.pauseLocationUpdatesAutomatically, isTrue);
    expect(settings.allowBackgroundLocationUpdates, isFalse);
  });
}
