class VipMercadoPagoConfig {
  const VipMercadoPagoConfig({
    required this.publicKey,
    required this.hasAccessToken,
    this.accessToken,
  });

  final String publicKey;
  final String? accessToken;
  final bool hasAccessToken;

  factory VipMercadoPagoConfig.fromJson(Map<String, dynamic> json) {
    final accessToken = json['mp_access_token']?.toString() ?? '';
    return VipMercadoPagoConfig(
      publicKey: json['mp_public_key']?.toString() ?? '',
      accessToken: accessToken.isEmpty ? null : accessToken,
      hasAccessToken: accessToken.isNotEmpty,
    );
  }
}
