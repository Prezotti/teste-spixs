import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppConfig {
  static const _fromDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static String get googleMapsApiKey {
    if (_fromDefine.isNotEmpty) return _fromDefine;
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('GOOGLE_MAPS_API_KEY')?.trim() ?? '';
  }

  static bool get hasGoogleMapsKey => googleMapsApiKey.isNotEmpty;
}
