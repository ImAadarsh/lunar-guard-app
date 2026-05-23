import 'package:url_launcher/url_launcher.dart';

Future<bool> openGoogleMaps({
  required double lat,
  required double lng,
  String? label,
}) async {
  final query = label == null || label.trim().isEmpty
      ? '$lat,$lng'
      : Uri.encodeComponent('${label.trim()}@$lat,$lng');
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

String googleMapsUrl({required double lat, required double lng}) {
  return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
}
