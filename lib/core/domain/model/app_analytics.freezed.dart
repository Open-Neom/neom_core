// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_analytics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

AppAnalytics _$AppAnalyticsFromJson(Map<String, dynamic> json) {
  return _AppAnalytics.fromJson(json);
}

/// @nodoc
mixin _$AppAnalytics {
  String get location => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppAnalyticsCopyWith<AppAnalytics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppAnalyticsCopyWith<$Res> {
  factory $AppAnalyticsCopyWith(
          AppAnalytics value, $Res Function(AppAnalytics) then) =
      _$AppAnalyticsCopyWithImpl<$Res, AppAnalytics>;
  @useResult
  $Res call({String location, int qty});
}

/// @nodoc
class _$AppAnalyticsCopyWithImpl<$Res, $Val extends AppAnalytics>
    implements $AppAnalyticsCopyWith<$Res> {
  _$AppAnalyticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? location = null,
    Object? qty = null,
  }) {
    return _then(_value.copyWith(
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_AppAnalyticsCopyWith<$Res>
    implements $AppAnalyticsCopyWith<$Res> {
  factory _$$_AppAnalyticsCopyWith(
          _$_AppAnalytics value, $Res Function(_$_AppAnalytics) then) =
      __$$_AppAnalyticsCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String location, int qty});
}

/// @nodoc
class __$$_AppAnalyticsCopyWithImpl<$Res>
    extends _$AppAnalyticsCopyWithImpl<$Res, _$_AppAnalytics>
    implements _$$_AppAnalyticsCopyWith<$Res> {
  __$$_AppAnalyticsCopyWithImpl(
      _$_AppAnalytics _value, $Res Function(_$_AppAnalytics) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? location = null,
    Object? qty = null,
  }) {
    return _then(_$_AppAnalytics(
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_AppAnalytics implements _AppAnalytics {
  _$_AppAnalytics({required this.location, required this.qty});

  factory _$_AppAnalytics.fromJson(Map<String, dynamic> json) =>
      _$$_AppAnalyticsFromJson(json);

  @override
  final String location;
  @override
  final int qty;

  @override
  String toString() {
    return 'AppAnalytics(location: $location, qty: $qty)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_AppAnalytics &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.qty, qty) || other.qty == qty));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, location, qty);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AppAnalyticsCopyWith<_$_AppAnalytics> get copyWith =>
      __$$_AppAnalyticsCopyWithImpl<_$_AppAnalytics>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_AppAnalyticsToJson(
      this,
    );
  }
}

abstract class _AppAnalytics implements AppAnalytics {
  factory _AppAnalytics(
      {required final String location,
      required final int qty}) = _$_AppAnalytics;

  factory _AppAnalytics.fromJson(Map<String, dynamic> json) =
      _$_AppAnalytics.fromJson;

  @override
  String get location;
  @override
  int get qty;
  @override
  @JsonKey(ignore: true)
  _$$_AppAnalyticsCopyWith<_$_AppAnalytics> get copyWith =>
      throw _privateConstructorUsedError;
}
