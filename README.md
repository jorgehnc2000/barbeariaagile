# barbearia_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Upload de imagens

O painel admin envia imagens para a Edge Function `upload-image`. A chave do
ImgBB não fica no Flutter Web, no `.env` publicado nem no código cliente.

Configure o segredo no projeto Supabase e publique a função:

```bash
npx supabase secrets set --project-ref <project-ref> IMGBB_API_KEY=<nova-chave>
npx supabase functions deploy upload-image --project-ref <project-ref>
```

Não adicione `.env` como asset Flutter. Chaves que já foram usadas em builds
Web devem ser revogadas/rotacionadas no ImgBB.
