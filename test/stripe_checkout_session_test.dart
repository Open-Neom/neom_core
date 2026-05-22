// Tests for `StripeCheckoutSession` — modelo trivial.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/stripe/stripe_session.dart';

void main() {
  group('StripeCheckoutSession', () {
    test('constructor sin params', () {
      final s = StripeCheckoutSession();
      expect(s.id, '');
      expect(s.url, '');
    });

    test('parámetros nombrados', () {
      final s = StripeCheckoutSession(
        id: 'cs_1',
        url: 'https://checkout.stripe.com/session/abc',
      );
      expect(s.id, 'cs_1');
      expect(s.url, 'https://checkout.stripe.com/session/abc');
    });
  });
}
