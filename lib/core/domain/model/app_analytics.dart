import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_analytics.freezed.dart';
part 'app_analytics.g.dart';

@freezed
class AppAnalytics with _$AppAnalytics {

  factory AppAnalytics({
    required String location,
    required int qty,
  }) = _AppAnalytics;

  factory AppAnalytics.fromJson(Map<String, dynamic> json) =>
      _$$_AppAnalyticsFromJson(json);

}
