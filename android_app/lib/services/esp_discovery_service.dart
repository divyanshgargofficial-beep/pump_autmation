import '../models/app_settings.dart';

class EspDiscoveryService {
  const EspDiscoveryService();

  Uri resolveBaseUri(AppSettings settings) {
    final address =
        settings.useMdns ? AppSettings.defaultMdnsAddress : settings.espAddress;
    final uri = Uri.tryParse(address.trim());

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('Invalid ESP address.');
    }

    return uri;
  }
}
