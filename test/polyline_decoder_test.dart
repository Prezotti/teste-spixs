import 'package:flutter_test/flutter_test.dart';
import 'package:teste_spixs/features/route/data/polyline_decoder.dart';

void main() {
  test('decodes a Google encoded polyline', () {
    final points = PolylineDecoder.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

    expect(points, hasLength(3));
    expect(points[0].latitude, closeTo(38.5, 0.001));
    expect(points[0].longitude, closeTo(-120.2, 0.001));
    expect(points[2].latitude, closeTo(43.252, 0.001));
    expect(points[2].longitude, closeTo(-126.453, 0.001));
  });
}
