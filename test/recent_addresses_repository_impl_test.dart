import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:teste_spixs/features/home/data/repositories/recent_addresses_repository_impl.dart';
import 'package:teste_spixs/features/home/data/services/recent_addresses_hive_service.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('recent_addresses');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('stores the latest address first and drops duplicates', () async {
    final repository = RecentAddressesRepositoryImpl(RecentAddressesHiveService());
    const first = PlaceDetails(placeId: 'a', address: 'Rua A', latitude: 1, longitude: 2);
    const second = PlaceDetails(placeId: 'b', address: 'Rua B', latitude: 3, longitude: 4);

    await repository.remember(first);
    await repository.remember(second);
    await repository.remember(first);

    final saved = await repository.read();
    expect(saved.map((place) => place.placeId), ['a', 'b']);
    expect(saved.first.address, 'Rua A');
  });

  test('keeps only the ten most recent addresses', () async {
    final repository = RecentAddressesRepositoryImpl(RecentAddressesHiveService());

    for (var i = 0; i < 12; i++) {
      await repository.remember(
        PlaceDetails(placeId: '$i', address: 'Rua $i', latitude: i.toDouble(), longitude: 0),
      );
    }

    final saved = await repository.read();
    expect(saved, hasLength(RecentAddressesRepositoryImpl.maxItems));
    expect(saved.first.placeId, '11');
    expect(saved.last.placeId, '2');
  });
}
