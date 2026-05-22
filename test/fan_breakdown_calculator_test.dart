// Tests for `FanBreakdown`, `FanSessionData`, `FanSegmentCalculator`.
//
// FanSegmentCalculator es lógica pura de percentiles — testeable sin Firebase.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/fan_breakdown.dart';
import 'package:neom_core/domain/model/fan_segment.dart';
import 'package:neom_core/domain/model/fan_session_data.dart';
import 'package:neom_core/domain/model/fan_segment_calculator.dart';
import 'package:neom_core/utils/enums/fan_tier.dart';

void main() {
  group('FanSessionData', () {
    test('constructor con required fields', () {
      const s = FanSessionData(
        itemId: 'item1',
        engagement: 100,
        monthKey: '2026-03',
      );
      expect(s.itemId, 'item1');
      expect(s.engagement, 100);
      expect(s.monthKey, '2026-03');
    });

    test('es const-constructible', () {
      const a = FanSessionData(itemId: 'i', engagement: 1, monthKey: 'm');
      const b = FanSessionData(itemId: 'i', engagement: 1, monthKey: 'm');
      expect(identical(a, b), isTrue);
    });
  });

  group('FanBreakdown', () {
    test('FanBreakdown.empty es lista vacía', () {
      expect(FanBreakdown.empty.segments, isEmpty);
      expect(FanBreakdown.empty.totalCount, 0);
    });

    test('cuenta por tier', () {
      final segments = [
        for (var i = 0; i < 2; i++) const FanSegment(
          email: 'sf', creatorEmail: 'c',
          totalEngagement: 100, sessionCount: 5,
          worksConsumed: 3, activeMonths: 2,
          tier: FanTier.superfan,
        ),
        for (var i = 0; i < 3; i++) const FanSegment(
          email: 'fa', creatorEmail: 'c',
          totalEngagement: 50, sessionCount: 2,
          worksConsumed: 1, activeMonths: 1,
          tier: FanTier.fan,
        ),
        for (var i = 0; i < 5; i++) const FanSegment(
          email: 'sup', creatorEmail: 'c',
          totalEngagement: 20, sessionCount: 1,
          worksConsumed: 1, activeMonths: 1,
          tier: FanTier.supporter,
        ),
        for (var i = 0; i < 10; i++) const FanSegment(
          email: 'cas', creatorEmail: 'c',
          totalEngagement: 5, sessionCount: 1,
          worksConsumed: 1, activeMonths: 1,
          tier: FanTier.casual,
        ),
      ];
      final breakdown = FanBreakdown(segments);

      expect(breakdown.superfanCount, 2);
      expect(breakdown.fanCount, 3);
      expect(breakdown.supporterCount, 5);
      expect(breakdown.casualCount, 10);
      expect(breakdown.totalCount, 20);
    });

    test('superfans/fans getters devuelven sublistas', () {
      final segments = [
        const FanSegment(
          email: 'sf', creatorEmail: 'c',
          totalEngagement: 100, sessionCount: 5,
          worksConsumed: 3, activeMonths: 2,
          tier: FanTier.superfan,
        ),
        const FanSegment(
          email: 'fa', creatorEmail: 'c',
          totalEngagement: 50, sessionCount: 2,
          worksConsumed: 1, activeMonths: 1,
          tier: FanTier.fan,
        ),
      ];
      final breakdown = FanBreakdown(segments);
      expect(breakdown.superfans.length, 1);
      expect(breakdown.fans.length, 1);
    });
  });

  group('FanSegmentCalculator.calculate', () {
    test('mapa vacío devuelve FanBreakdown.empty', () {
      final result = FanSegmentCalculator.calculate(
        creatorEmail: 'creator@x.com',
        sessionsPerFan: {},
      );
      expect(result.segments, isEmpty);
    });

    test('agrega métricas por fan correctamente', () {
      final result = FanSegmentCalculator.calculate(
        creatorEmail: 'c@x.com',
        sessionsPerFan: {
          'fan1@x.com': const [
            FanSessionData(itemId: 'i1', engagement: 50, monthKey: '2026-01'),
            FanSessionData(itemId: 'i2', engagement: 30, monthKey: '2026-02'),
          ],
          'fan2@x.com': const [
            FanSessionData(itemId: 'i1', engagement: 5, monthKey: '2026-01'),
          ],
        },
      );

      expect(result.segments.length, 2);

      final fan1 = result.segments.firstWhere((s) => s.email == 'fan1@x.com');
      expect(fan1.totalEngagement, 80);
      expect(fan1.sessionCount, 2);
      expect(fan1.worksConsumed, 2);
      expect(fan1.activeMonths, 2);

      final fan2 = result.segments.firstWhere((s) => s.email == 'fan2@x.com');
      expect(fan2.totalEngagement, 5);
      expect(fan2.sessionCount, 1);
      expect(fan2.worksConsumed, 1);
    });

    test('resultados ordenados por tier descendente', () {
      // Generar 10 fans con engagement progresivo
      final sessionsPerFan = <String, List<FanSessionData>>{};
      for (var i = 0; i < 10; i++) {
        sessionsPerFan['fan$i@x.com'] = [
          FanSessionData(
            itemId: 'i1',
            engagement: i * 100,
            monthKey: '2026-01',
          ),
        ];
      }

      final result = FanSegmentCalculator.calculate(
        creatorEmail: 'c@x.com',
        sessionsPerFan: sessionsPerFan,
      );

      // Verificar que están ordenados de mayor a menor tier
      for (var i = 0; i < result.segments.length - 1; i++) {
        final current = result.segments[i];
        final next = result.segments[i + 1];
        expect(
          current.tier.value >= next.tier.value,
          isTrue,
          reason: 'segment $i tier (${current.tier.name}) debe ser >= '
              'tier de $i+1 (${next.tier.name})',
        );
      }
    });

    test('fan con sessionCount < 3 NO es superfan aunque engagement alto', () {
      // 1 sola sesión con muchísima engagement no califica
      final result = FanSegmentCalculator.calculate(
        creatorEmail: 'c@x.com',
        sessionsPerFan: {
          'fan@x.com': const [
            FanSessionData(itemId: 'i1', engagement: 10000, monthKey: '2026-01'),
          ],
          'other@x.com': const [
            FanSessionData(itemId: 'i1', engagement: 1, monthKey: '2026-01'),
          ],
        },
      );

      final fan = result.segments.firstWhere((s) => s.email == 'fan@x.com');
      expect(fan.tier, isNot(FanTier.superfan),
          reason: 'requiere sessionCount >= 3 para ser superfan');
    });
  });

  group('FanSegmentCalculator.tierForUser', () {
    test('lista vacía devuelve casual', () {
      final tier = FanSegmentCalculator.tierForUser(
        userEngagement: 100,
        userSessionCount: 5,
        allEngagements: [],
      );
      expect(tier, FanTier.casual);
    });

    test('user en p95 con 3+ sesiones es superfan', () {
      final tier = FanSegmentCalculator.tierForUser(
        userEngagement: 1000,
        userSessionCount: 5,
        allEngagements: List.generate(100, (i) => i * 10),
      );
      expect(tier, FanTier.superfan);
    });

    test('user con muy poco engagement es casual', () {
      final tier = FanSegmentCalculator.tierForUser(
        userEngagement: 1,
        userSessionCount: 1,
        allEngagements: List.generate(100, (i) => 50 + i * 10),
      );
      expect(tier, FanTier.casual);
    });

    test('user en p95 pero solo 1 sesión NO es superfan', () {
      final tier = FanSegmentCalculator.tierForUser(
        userEngagement: 1000,
        userSessionCount: 1,
        allEngagements: List.generate(100, (i) => i * 10),
      );
      expect(tier, isNot(FanTier.superfan));
    });
  });
}
