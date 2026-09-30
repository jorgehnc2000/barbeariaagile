import 'package:flutter/foundation.dart';

abstract final class OAuthConfig {
  static const mobileRedirectUrl = 'my.barber.app://login-callback';

  static String get redirectUrl {
    if (kIsWeb) {
      return Uri.base.replace(query: '', fragment: '').toString();
    }
    return mobileRedirectUrl;
  }
}
