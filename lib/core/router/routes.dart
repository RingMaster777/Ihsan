abstract final class AppRoutes {
  static const profiles = '/profiles';
  static const home = '/home';
  static const history = '/history';
  static const stats = '/stats';
  static const settings = '/settings';
  static const entryPattern = '/entry/:date';
  static String entry(String dateKey) => '/entry/$dateKey';
}
