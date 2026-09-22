import 'package:hive_flutter/hive_flutter.dart';

class RecentAddressesHiveService {
  RecentAddressesHiveService({this._box});

  static const boxName = 'recent_addresses';
  static const itemsKey = 'items';

  Box<dynamic>? _box;

  Future<List<Map<String, dynamic>>> read() async {
    final stored = await _open();
    final raw = stored.get(itemsKey);
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Future<void> write(List<Map<String, dynamic>> items) async {
    final stored = await _open();
    await stored.put(itemsKey, items);
  }

  Future<Box<dynamic>> _open() async {
    final current = _box;
    if (current != null && current.isOpen) return current;
    final opened = await Hive.openBox<dynamic>(boxName);
    _box = opened;
    return opened;
  }
}
