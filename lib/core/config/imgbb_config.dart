/// Configuração pública do cliente para o proxy de imagens.
///
/// A chave ImgBB nunca deve ser lida pelo Flutter. O segredo fica nas
/// Supabase Edge Function secrets.
abstract final class ImgBBConfig {
  static const maxBytes = 5 * 1024 * 1024; // 5 MB
  static const uploadFunctionName = 'upload-image';
}
