import 'package:teste_spixs/features/home/domain/entities/place_details.dart';

abstract class RecentAddressesRepository {
  Future<List<PlaceDetails>> read();

  Future<void> remember(PlaceDetails place);
}
