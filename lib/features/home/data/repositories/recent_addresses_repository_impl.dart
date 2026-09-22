import 'package:teste_spixs/features/home/data/services/recent_addresses_hive_service.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/home/domain/repositories/recent_addresses_repository.dart';

class RecentAddressesRepositoryImpl implements RecentAddressesRepository {
  RecentAddressesRepositoryImpl(this._store);

  static const maxItems = 10;

  final RecentAddressesHiveService _store;

  @override
  Future<List<PlaceDetails>> read() async {
    try {
      final items = await _store.read();
      final places = <PlaceDetails>[];
      for (final item in items) {
        final place = _parse(item);
        if (place != null) places.add(place);
      }
      return places;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> remember(PlaceDetails place) async {
    final current = await read();
    final next = [
      place,
      ...current.where((item) => item.placeId != place.placeId),
    ].take(maxItems);
    await _store.write([for (final item in next) _encode(item)]);
  }

  PlaceDetails? _parse(Map<String, dynamic> item) {
    final placeId = item['placeId'];
    final address = item['address'];
    final latitude = item['latitude'];
    final longitude = item['longitude'];
    if (placeId is! String || address is! String || latitude is! num || longitude is! num) {
      return null;
    }

    return PlaceDetails(
      placeId: placeId,
      address: address,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  Map<String, dynamic> _encode(PlaceDetails place) {
    return {
      'placeId': place.placeId,
      'address': place.address,
      'latitude': place.latitude,
      'longitude': place.longitude,
    };
  }
}
