import 'package:barbearia_app/models/vip_subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VipSubscriptionStatus.normalize', () {
    test('aceita aliases PT/EN e underscores', () {
      expect(VipSubscriptionStatus.normalize('AUTHORIZED'), 'authorized');
      expect(VipSubscriptionStatus.normalize('Ativo'), 'authorized');
      expect(VipSubscriptionStatus.normalize('EM_ATRASO'), 'past_due');
      expect(VipSubscriptionStatus.normalize('em atraso'), 'past_due');
      expect(VipSubscriptionStatus.normalize('PAUSADO'), 'paused');
      expect(VipSubscriptionStatus.normalize('paused'), 'paused');
      expect(VipSubscriptionStatus.normalize('CANCELADO'), 'canceled');
      expect(VipSubscriptionStatus.normalize('cancelled'), 'canceled');
      expect(VipSubscriptionStatus.normalize('EXPIRED'), 'expired');
    });
  });

  group('VipEntitlementStatus.fromDb', () {
    test('mapeia ACTIVE / PAST_DUE / ATIVO / EM_ATRASO', () {
      expect(VipEntitlementStatus.fromDb('ACTIVE'), VipEntitlementStatus.active);
      expect(VipEntitlementStatus.fromDb('ATIVO'), VipEntitlementStatus.active);
      expect(
        VipEntitlementStatus.fromDb('PAST_DUE'),
        VipEntitlementStatus.pastDue,
      );
      expect(
        VipEntitlementStatus.fromDb('EM_ATRASO'),
        VipEntitlementStatus.pastDue,
      );
      expect(
        VipEntitlementStatus.fromDb('PAUSADO'),
        VipEntitlementStatus.pastDue,
      );
      expect(
        VipEntitlementStatus.fromDb('INACTIVE'),
        VipEntitlementStatus.inactive,
      );
    });
  });

  group('VipSubscription flags', () {
    VipSubscription sub(String status, {String? payment}) {
      return VipSubscription(
        id: '1',
        userId: 'u',
        barbershopId: 'b',
        status: status,
        lastPaymentStatus: payment,
      );
    }

    test('authorized + approved = ativa', () {
      final s = sub('authorized', payment: 'approved');
      expect(s.isAuthorized, isTrue);
      expect(s.isPastDue, isFalse);
      expect(s.hasMembership, isTrue);
      expect(s.statusLabel, 'Ativa');
    });

    test('authorized + rejected = em atraso', () {
      final s = sub('authorized', payment: 'rejected');
      expect(s.isAuthorized, isFalse);
      expect(s.isPastDue, isTrue);
      expect(s.hasMembership, isTrue);
      expect(s.statusLabel, 'Em atraso');
    });

    test('paused mantém membership e pede regularização', () {
      final s = sub('pausado');
      expect(s.isPaused, isTrue);
      expect(s.isPastDue, isTrue);
      expect(s.isCancelled, isFalse);
      expect(s.hasMembership, isTrue);
      expect(s.statusLabel, 'Pausada');
    });

    test('cancelado encerra membership', () {
      final s = sub('CANCELADO');
      expect(s.isCancelled, isTrue);
      expect(s.hasMembership, isFalse);
      expect(s.statusLabel, 'Cancelada');
    });
  });
}
