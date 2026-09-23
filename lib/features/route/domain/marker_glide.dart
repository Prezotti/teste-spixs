import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';

abstract final class MarkerGlide {
  static double eased(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return clamped * clamped * (3 - 2 * clamped);
  }

  static GeoPoint pointBetween(GeoPoint from, GeoPoint to, double t) {
    final easedT = eased(t);
    return GeoPoint(
      from.latitude + (to.latitude - from.latitude) * easedT,
      from.longitude + (to.longitude - from.longitude) * easedT,
    );
  }

  static double headingBetween(double from, double to, double t) {
    var delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    final heading = from + delta * eased(t);
    final wrapped = heading % 360;
    return wrapped < 0 ? wrapped + 360 : wrapped;
  }
}
