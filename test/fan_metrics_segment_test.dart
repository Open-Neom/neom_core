// Tests for FanMetrics y FanSegment (value classes inmutables).
//
// No tienen toJSON/fromJSON — son DTOs computados. Tests cubren constructor
// + getters derivados (isRecurring, isMultiWork).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/fan_metrics.dart';
import 'package:neom_core/domain/model/fan_segment.dart';
import 'package:neom_core/utils/enums/fan_tier.dart';

void main() {
  group('FanMetrics', () {
    test('constructor requiere todos los campos', () {
      const m = FanMetrics(
        email: 'fan@x.com',
        totalEngagement: 100,
        sessionCount: 5,
        worksConsumed: 3,
        activeMonths: 2,
      );
      expect(m.email, 'fan@x.com');
      expect(m.totalEngagement, 100);
      expect(m.sessionCount, 5);
      expect(m.worksConsumed, 3);
      expect(m.activeMonths, 2);
    });

    test('es const-constructible', () {
      const m1 = FanMetrics(
        email: 'a@x.com',
        totalEngagement: 0,
        sessionCount: 0,
        worksConsumed: 0,
        activeMonths: 0,
      );
      const m2 = FanMetrics(
        email: 'a@x.com',
        totalEngagement: 0,
        sessionCount: 0,
        worksConsumed: 0,
        activeMonths: 0,
      );
      expect(identical(m1, m2), isTrue,
          reason: 'consts iguales deben canonicalizarse a la misma instancia');
    });
  });

  group('FanSegment — defaults', () {
    test('constructor requiere todos los campos', () {
      const s = FanSegment(
        email: 'fan@x.com',
        creatorEmail: 'creator@x.com',
        totalEngagement: 200,
        sessionCount: 10,
        worksConsumed: 5,
        activeMonths: 3,
        tier: FanTier.casual,
      );
      expect(s.email, 'fan@x.com');
      expect(s.creatorEmail, 'creator@x.com');
      expect(s.totalEngagement, 200);
      expect(s.sessionCount, 10);
      expect(s.worksConsumed, 5);
      expect(s.activeMonths, 3);
      expect(s.tier, FanTier.casual);
    });
  });

  group('FanSegment.isRecurring', () {
    test('1 sesión NO es recurrente', () {
      const s = FanSegment(
        email: 'a',
        creatorEmail: 'b',
        totalEngagement: 1,
        sessionCount: 1,
        worksConsumed: 1,
        activeMonths: 1,
        tier: FanTier.casual,
      );
      expect(s.isRecurring, isFalse);
    });

    test('2 sesiones SÍ es recurrente', () {
      const s = FanSegment(
        email: 'a',
        creatorEmail: 'b',
        totalEngagement: 10,
        sessionCount: 2,
        worksConsumed: 1,
        activeMonths: 1,
        tier: FanTier.casual,
      );
      expect(s.isRecurring, isTrue);
    });

    test('0 sesiones NO es recurrente (caso límite)', () {
      const s = FanSegment(
        email: 'a',
        creatorEmail: 'b',
        totalEngagement: 0,
        sessionCount: 0,
        worksConsumed: 0,
        activeMonths: 0,
        tier: FanTier.casual,
      );
      expect(s.isRecurring, isFalse);
    });
  });

  group('FanSegment.isMultiWork', () {
    test('1 obra NO es multi-work', () {
      const s = FanSegment(
        email: 'a',
        creatorEmail: 'b',
        totalEngagement: 100,
        sessionCount: 5,
        worksConsumed: 1,
        activeMonths: 1,
        tier: FanTier.casual,
      );
      expect(s.isMultiWork, isFalse);
    });

    test('2 obras SÍ es multi-work', () {
      const s = FanSegment(
        email: 'a',
        creatorEmail: 'b',
        totalEngagement: 100,
        sessionCount: 5,
        worksConsumed: 2,
        activeMonths: 1,
        tier: FanTier.casual,
      );
      expect(s.isMultiWork, isTrue);
    });
  });

  group('FanSegment — combinaciones de flags', () {
    test('un superfan: recurrente + multi-work', () {
      const s = FanSegment(
        email: 'a',
        creatorEmail: 'b',
        totalEngagement: 1000,
        sessionCount: 50,
        worksConsumed: 10,
        activeMonths: 6,
        tier: FanTier.superfan,
      );
      expect(s.isRecurring, isTrue);
      expect(s.isMultiWork, isTrue);
    });

    test('un fan casual: recurrente PERO solo 1 obra', () {
      const s = FanSegment(
        email: 'a',
        creatorEmail: 'b',
        totalEngagement: 50,
        sessionCount: 3,
        worksConsumed: 1,
        activeMonths: 2,
        tier: FanTier.casual,
      );
      expect(s.isRecurring, isTrue);
      expect(s.isMultiWork, isFalse);
    });
  });
}
