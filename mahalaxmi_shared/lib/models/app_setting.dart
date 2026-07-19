import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_setting.freezed.dart';
part 'app_setting.g.dart';

@freezed
class AppSetting with _$AppSetting {
  const factory AppSetting({
    required String key,
    @Default('') String value,
  }) = _AppSetting;

  factory AppSetting.fromJson(Map<String, Object?> json) =>
      _$AppSettingFromJson(json);
}
