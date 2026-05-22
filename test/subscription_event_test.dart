// Tests for `SubscriptionEvent` — webhook tracker de Stripe.
// Modelo bien defendido (todos los campos con defaults).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/subscription_event.dart';

void main() {
  group('SubscriptionEvent — defaults', () {
    test('constructor sin params', () {
      final e = SubscriptionEvent();
      expect(e.id, '');
      expect(e.subscriptionId, '');
      expect(e.userId, '');
      expect(e.userName, '');
      expect(e.stripeEventType, '');
      expect(e.emxiStatus, '');
      expect(e.emxiStatusColor, 'grey');
      expect(e.planName, '');
      expect(e.alertCOO, isFalse);
      expect(e.alertCEO, isFalse);
      expect(e.metadata, isEmpty);
      expect(e.createdAt, 0);
      // v2
      expect(e.amount, 0);
      expect(e.currency, '');
      expect(e.stripeFees, 0);
      expect(e.stripeNet, 0);
      expect(e.cancelAtPeriodEnd, isFalse);
      expect(e.discountPercent, 0);
    });
  });

  group('SubscriptionEvent.hasFinancialData', () {
    test('false cuando amount == 0', () {
      expect(SubscriptionEvent().hasFinancialData, isFalse);
    });

    test('true cuando amount > 0', () {
      expect(SubscriptionEvent(amount: 99.0).hasFinancialData, isTrue);
    });
  });

  group('SubscriptionEvent.paymentMethodDisplay', () {
    test('formato "Visa ****1234"', () {
      final e = SubscriptionEvent(
        paymentMethodBrand: 'Visa',
        paymentMethodLast4: '1234',
      );
      expect(e.paymentMethodDisplay, 'Visa ****1234');
    });

    test('vacío sin brand', () {
      expect(
        SubscriptionEvent(paymentMethodLast4: '1234').paymentMethodDisplay,
        '',
      );
    });

    test('vacío sin last4', () {
      expect(
        SubscriptionEvent(paymentMethodBrand: 'Visa').paymentMethodDisplay,
        '',
      );
    });
  });

  group('SubscriptionEvent.isScheduledToCancel', () {
    test('false cuando cancelAtPeriodEnd false', () {
      expect(SubscriptionEvent().isScheduledToCancel, isFalse);
    });

    test('false cuando cancelAtPeriodEnd true pero currentPeriodEnd 0', () {
      final e = SubscriptionEvent(cancelAtPeriodEnd: true);
      expect(e.isScheduledToCancel, isFalse);
    });

    test('true cuando ambos están seteados', () {
      final e = SubscriptionEvent(
        cancelAtPeriodEnd: true,
        currentPeriodEnd: 1700100000000,
      );
      expect(e.isScheduledToCancel, isTrue);
    });
  });

  group('SubscriptionEvent.stripeFeePercent', () {
    test('0 cuando amount es 0', () {
      expect(SubscriptionEvent().stripeFeePercent, 0);
    });

    test('porcentaje correcto', () {
      // 5 fees / 100 amount = 5%
      final e = SubscriptionEvent(amount: 100, stripeFees: 5);
      expect(e.stripeFeePercent, 5.0);
    });
  });

  group('SubscriptionEvent — round-trip', () {
    test('preserva campos completos', () {
      final original = SubscriptionEvent(
        id: 'ev1',
        subscriptionId: 'sub_1',
        userId: 'u1',
        userName: 'Ana',
        stripeEventType: 'invoice.payment_failed',
        emxiStatus: 'Fricción de Pago',
        emxiStatusColor: 'red',
        planName: 'Pro',
        alertCOO: true,
        alertCEO: false,
        metadata: {'note': 'retry scheduled'},
        createdAt: 1700000000000,
        amount: 199.0,
        currency: 'MXN',
        stripeFees: 7.5,
        stripeNet: 191.5,
        invoiceId: 'in_1',
        invoiceUrl: 'https://stripe.com/invoice',
        chargeId: 'ch_1',
        paymentMethodBrand: 'Visa',
        paymentMethodLast4: '4242',
        failureReason: 'card_declined',
        failureMessage: 'Tarjeta rechazada',
        currentPeriodEnd: 1700100000000,
        cancelAtPeriodEnd: true,
        customerEmail: 'cliente@x.com',
        couponId: 'coup_1',
        discountPercent: 15.0,
      );
      final restored = SubscriptionEvent.fromJSON(original.toJSON());

      expect(restored.id, original.id);
      expect(restored.subscriptionId, original.subscriptionId);
      expect(restored.userName, original.userName);
      expect(restored.stripeEventType, original.stripeEventType);
      expect(restored.emxiStatus, original.emxiStatus);
      expect(restored.emxiStatusColor, original.emxiStatusColor);
      expect(restored.alertCOO, original.alertCOO);
      expect(restored.alertCEO, original.alertCEO);
      expect(restored.metadata, original.metadata);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.stripeFees, original.stripeFees);
      expect(restored.invoiceId, original.invoiceId);
      expect(restored.paymentMethodBrand, original.paymentMethodBrand);
      expect(restored.failureReason, original.failureReason);
      expect(restored.cancelAtPeriodEnd, original.cancelAtPeriodEnd);
      expect(restored.discountPercent, original.discountPercent);
    });

    test('mapa vacío usa defaults', () {
      final e = SubscriptionEvent.fromJSON(<String, dynamic>{});
      expect(e.id, '');
      expect(e.amount, 0);
      expect(e.emxiStatusColor, 'grey');
      expect(e.metadata, isEmpty);
    });

    test('valores num int se convierten a double', () {
      final e = SubscriptionEvent.fromJSON({
        'amount': 100,
        'stripeFees': 5,
        'discountPercent': 10,
      });
      expect(e.amount, 100.0);
      expect(e.stripeFees, 5.0);
      expect(e.discountPercent, 10.0);
    });
  });
}
