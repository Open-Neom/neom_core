// Tests for `CollectionEvent` — eventos de cobranza ERP.
//
// Cubre defaults, round-trip JSON, y los 3 getters de label
// (typeLabel, escalationLabel, failureReasonLabel, paymentMethodDisplay).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collection_event.dart';

void main() {
  group('CollectionEvent — defaults', () {
    test('constructor sin params', () {
      final e = CollectionEvent();
      expect(e.id, '');
      expect(e.userId, '');
      expect(e.userEmail, '');
      expect(e.userName, '');
      expect(e.userPhone, '');
      expect(e.type, '');
      expect(e.invoiceId, '');
      expect(e.subscriptionId, '');
      expect(e.amount, 0.0);
      expect(e.currency, 'MXN',
          reason: 'currency default es MXN (cobranza local)');
      expect(e.attemptNumber, 0);
      expect(e.whatsappSent, isFalse);
      expect(e.whatsappMessageId, '');
      expect(e.escalationLevel, 1);
      expect(e.createdAt, 0);
      expect(e.failureReason, '');
      expect(e.failureMessage, '');
      expect(e.paymentMethodBrand, '');
      expect(e.paymentMethodLast4, '');
      expect(e.planName, '');
      expect(e.nextRetryDate, 0);
    });
  });

  group('CollectionEvent — round-trip', () {
    test('preserva todos los 21 campos', () {
      final original = CollectionEvent(
        id: 'ce1',
        userId: 'u1',
        userEmail: 'u@x.com',
        userName: 'Ana',
        userPhone: '+5215551234',
        type: 'payment_failed',
        invoiceId: 'inv1',
        subscriptionId: 'sub1',
        amount: 199.0,
        currency: 'MXN',
        attemptNumber: 2,
        whatsappSent: true,
        whatsappMessageId: 'wamsg_xyz',
        escalationLevel: 3,
        createdAt: 1700000000000,
        failureReason: 'card_declined',
        failureMessage: 'Tarjeta rechazada por banco',
        paymentMethodBrand: 'Visa',
        paymentMethodLast4: '4242',
        planName: 'Pro',
        nextRetryDate: 1700100000000,
      );
      final restored = CollectionEvent.fromJSON(original.toJSON());

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.userEmail, original.userEmail);
      expect(restored.userName, original.userName);
      expect(restored.userPhone, original.userPhone);
      expect(restored.type, original.type);
      expect(restored.invoiceId, original.invoiceId);
      expect(restored.subscriptionId, original.subscriptionId);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.attemptNumber, original.attemptNumber);
      expect(restored.whatsappSent, original.whatsappSent);
      expect(restored.whatsappMessageId, original.whatsappMessageId);
      expect(restored.escalationLevel, original.escalationLevel);
      expect(restored.createdAt, original.createdAt);
      expect(restored.failureReason, original.failureReason);
      expect(restored.failureMessage, original.failureMessage);
      expect(restored.paymentMethodBrand, original.paymentMethodBrand);
      expect(restored.paymentMethodLast4, original.paymentMethodLast4);
      expect(restored.planName, original.planName);
      expect(restored.nextRetryDate, original.nextRetryDate);
    });

    test('amount int se convierte a double', () {
      final e = CollectionEvent.fromJSON({'amount': 100});
      expect(e.amount, 100.0);
      expect(e.amount, isA<double>());
    });

    test('mapa vacío usa defaults', () {
      final e = CollectionEvent.fromJSON(<String, dynamic>{});
      expect(e.amount, 0.0);
      expect(e.currency, 'MXN');
      expect(e.escalationLevel, 1);
      expect(e.whatsappSent, isFalse);
    });
  });

  group('CollectionEvent.typeLabel', () {
    test('payment_failed → "Pago Fallido"', () {
      expect(CollectionEvent(type: 'payment_failed').typeLabel, 'Pago Fallido');
    });

    test('reminder_sent → "Recordatorio Enviado"', () {
      expect(CollectionEvent(type: 'reminder_sent').typeLabel, 'Recordatorio Enviado');
    });

    test('suspended → "Suspendido"', () {
      expect(CollectionEvent(type: 'suspended').typeLabel, 'Suspendido');
    });

    test('reactivated → "Reactivado"', () {
      expect(CollectionEvent(type: 'reactivated').typeLabel, 'Reactivado');
    });

    test('tipo desconocido devuelve el type crudo', () {
      expect(CollectionEvent(type: 'random_type').typeLabel, 'random_type');
    });
  });

  group('CollectionEvent.escalationLabel', () {
    test('niveles 1 a 4 tienen labels específicos', () {
      expect(CollectionEvent(escalationLevel: 1).escalationLabel, contains('Aviso 1'));
      expect(CollectionEvent(escalationLevel: 2).escalationLabel, contains('Aviso 2'));
      expect(CollectionEvent(escalationLevel: 3).escalationLabel, contains('Aviso 3'));
      expect(CollectionEvent(escalationLevel: 4).escalationLabel, 'Suspendido');
    });

    test('niveles fuera del rango usan label genérico', () {
      expect(CollectionEvent(escalationLevel: 99).escalationLabel, 'Nivel 99');
    });
  });

  group('CollectionEvent.failureReasonLabel', () {
    test('códigos comunes de Stripe → labels en español', () {
      expect(
        CollectionEvent(failureReason: 'card_declined').failureReasonLabel,
        'Tarjeta rechazada',
      );
      expect(
        CollectionEvent(failureReason: 'insufficient_funds').failureReasonLabel,
        'Fondos insuficientes',
      );
      expect(
        CollectionEvent(failureReason: 'expired_card').failureReasonLabel,
        'Tarjeta expirada',
      );
    });

    test('failureReason vacío devuelve "Desconocido"', () {
      expect(CollectionEvent().failureReasonLabel, 'Desconocido');
    });

    test('failureReason desconocido devuelve el código crudo', () {
      expect(
        CollectionEvent(failureReason: 'unknown_code').failureReasonLabel,
        'unknown_code',
      );
    });
  });

  group('CollectionEvent.paymentMethodDisplay', () {
    test('brand + last4 → "Visa ****4242"', () {
      final e = CollectionEvent(
        paymentMethodBrand: 'Visa',
        paymentMethodLast4: '4242',
      );
      expect(e.paymentMethodDisplay, 'Visa ****4242');
    });

    test('sin brand devuelve cadena vacía', () {
      expect(
        CollectionEvent(paymentMethodLast4: '4242').paymentMethodDisplay,
        '',
      );
    });

    test('sin last4 devuelve cadena vacía', () {
      expect(
        CollectionEvent(paymentMethodBrand: 'Visa').paymentMethodDisplay,
        '',
      );
    });
  });
}
