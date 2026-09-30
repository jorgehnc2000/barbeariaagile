import 'dart:typed_data';

import 'package:barbearia_app/services/imgbb_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImgBBService.validateImage', () {
    test('aceita PNG mínimo', () {
      final png = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x00,
      ]);
      expect(
        () => ImgBBService.validateImage(bytes: png, fileName: 'a.png'),
        returnsNormally,
      );
    });

    test('aceita JPEG mínimo', () {
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      expect(
        () => ImgBBService.validateImage(bytes: jpeg, fileName: 'a.jpg'),
        returnsNormally,
      );
    });

    test('rejeita bytes vazios', () {
      expect(
        () => ImgBBService.validateImage(bytes: Uint8List(0)),
        throwsA(isA<ImgBBException>()),
      );
    });

    test('rejeita arquivo sem assinatura de imagem', () {
      expect(
        () => ImgBBService.validateImage(
          bytes: Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]),
        ),
        throwsA(
          isA<ImgBBException>().having(
            (e) => e.message,
            'message',
            contains('inválido'),
          ),
        ),
      );
    });

    test('rejeita arquivo maior que 5 MB', () {
      expect(
        () => ImgBBService.validateFileSize(5 * 1024 * 1024 + 1),
        throwsA(
          isA<ImgBBException>().having(
            (e) => e.message,
            'message',
            contains('5 MB'),
          ),
        ),
      );
    });
  });
}
