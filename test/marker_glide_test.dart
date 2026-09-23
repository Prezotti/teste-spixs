import 'package:flutter_test/flutter_test.dart';
import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/marker_glide.dart';

void main() {
  test('places the marker halfway along the segment', () {
    final point = MarkerGlide.pointBetween(const GeoPoint(0, 0), const GeoPoint(0, 0.002), 0.5);

    expect(point.latitude, 0);
    expect(point.longitude, closeTo(0.001, 0.0000001));
  });

  test('turns the heading across north without spinning the long way', () {
    expect(MarkerGlide.headingBetween(350, 10, 0.5), closeTo(0, 0.001));
    expect(MarkerGlide.headingBetween(10, 350, 0.5), closeTo(0, 0.001));
  });
}
