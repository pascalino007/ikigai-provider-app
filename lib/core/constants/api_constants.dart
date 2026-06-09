/// Default backend (ngrok tunnel). Override at build time, e.g.:
/// `flutter run --dart-define=API_BASE_URL=https://api.ikilist.com`
abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ikilist.com',
  );

  static const List<String> serviceTags = [
    'onglerie',
    'manicure',
    'pedicure',
    'coiffure',
    'makeup',
    'spa',
    'barbershop',
    'facial',
    'waxing',
    'haircut',
    'massages',
    'skincare',
    'beard grooming',
    'hair coloring',
    'nail art',
    'brow lamination',
    'lash extensions',
  ];
}
