/// URLs públicas do app em produção.
abstract final class AppUrls {
  static const productionOrigin = 'https://barbeariaagile.vercel.app';

  static String clientUrlForSlug(String slug) {
    final clean = slug.trim();
    if (clean.isEmpty) return '';
    return '$productionOrigin/$clean';
  }

  static const subscriptionSuccessPath = '/sucesso-assinatura';

  static String get subscriptionSuccessUrl =>
      '$productionOrigin$subscriptionSuccessPath';
}
