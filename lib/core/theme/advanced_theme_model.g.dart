// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advanced_theme_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdvancedThemeModel _$AdvancedThemeModelFromJson(Map<String, dynamic> json) =>
    _AdvancedThemeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Modern',
      senderBubble: BubbleTheme.fromJson(
        json['senderBubble'] as Map<String, dynamic>,
      ),
      receiverBubble: BubbleTheme.fromJson(
        json['receiverBubble'] as Map<String, dynamic>,
      ),
      textTheme: ChatTextTheme.fromJson(
        json['textTheme'] as Map<String, dynamic>,
      ),
      backgroundTheme: ChatBackgroundTheme.fromJson(
        json['backgroundTheme'] as Map<String, dynamic>,
      ),
      appAppearance: AppAppearanceTheme.fromJson(
        json['appAppearance'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$AdvancedThemeModelToJson(_AdvancedThemeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'senderBubble': instance.senderBubble,
      'receiverBubble': instance.receiverBubble,
      'textTheme': instance.textTheme,
      'backgroundTheme': instance.backgroundTheme,
      'appAppearance': instance.appAppearance,
    };

_BubbleTheme _$BubbleThemeFromJson(Map<String, dynamic> json) => _BubbleTheme(
  backgroundColor: (json['backgroundColor'] as num).toInt(),
  gradientColors: (json['gradientColors'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  borderColor: (json['borderColor'] as num).toInt(),
  borderWidth: (json['borderWidth'] as num).toDouble(),
  shadowOpacity: (json['shadowOpacity'] as num).toDouble(),
  opacity: (json['opacity'] as num).toDouble(),
  radiusTopLeft: (json['radiusTopLeft'] as num).toDouble(),
  radiusTopRight: (json['radiusTopRight'] as num).toDouble(),
  radiusBottomLeft: (json['radiusBottomLeft'] as num).toDouble(),
  radiusBottomRight: (json['radiusBottomRight'] as num).toDouble(),
  paddingHorizontal: (json['paddingHorizontal'] as num).toDouble(),
  paddingVertical: (json['paddingVertical'] as num).toDouble(),
);

Map<String, dynamic> _$BubbleThemeToJson(_BubbleTheme instance) =>
    <String, dynamic>{
      'backgroundColor': instance.backgroundColor,
      'gradientColors': instance.gradientColors,
      'borderColor': instance.borderColor,
      'borderWidth': instance.borderWidth,
      'shadowOpacity': instance.shadowOpacity,
      'opacity': instance.opacity,
      'radiusTopLeft': instance.radiusTopLeft,
      'radiusTopRight': instance.radiusTopRight,
      'radiusBottomLeft': instance.radiusBottomLeft,
      'radiusBottomRight': instance.radiusBottomRight,
      'paddingHorizontal': instance.paddingHorizontal,
      'paddingVertical': instance.paddingVertical,
    };

_ChatTextTheme _$ChatTextThemeFromJson(Map<String, dynamic> json) =>
    _ChatTextTheme(
      fontFamily: json['fontFamily'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      fontWeight: (json['fontWeight'] as num).toInt(),
      senderMessageColor: (json['senderMessageColor'] as num).toInt(),
      receiverMessageColor: (json['receiverMessageColor'] as num).toInt(),
      timestampColor: (json['timestampColor'] as num).toInt(),
      timestampSize: (json['timestampSize'] as num).toDouble(),
      emojiSize: (json['emojiSize'] as num).toDouble(),
    );

Map<String, dynamic> _$ChatTextThemeToJson(_ChatTextTheme instance) =>
    <String, dynamic>{
      'fontFamily': instance.fontFamily,
      'fontSize': instance.fontSize,
      'fontWeight': instance.fontWeight,
      'senderMessageColor': instance.senderMessageColor,
      'receiverMessageColor': instance.receiverMessageColor,
      'timestampColor': instance.timestampColor,
      'timestampSize': instance.timestampSize,
      'emojiSize': instance.emojiSize,
    };

_ChatBackgroundTheme _$ChatBackgroundThemeFromJson(Map<String, dynamic> json) =>
    _ChatBackgroundTheme(
      solidColor: (json['solidColor'] as num).toInt(),
      gradientColors: (json['gradientColors'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      wallpaperUrl: json['wallpaperUrl'] as String?,
      blur: (json['blur'] as num).toDouble(),
      brightness: (json['brightness'] as num).toDouble(),
      opacity: (json['opacity'] as num).toDouble(),
    );

Map<String, dynamic> _$ChatBackgroundThemeToJson(
  _ChatBackgroundTheme instance,
) => <String, dynamic>{
  'solidColor': instance.solidColor,
  'gradientColors': instance.gradientColors,
  'wallpaperUrl': instance.wallpaperUrl,
  'blur': instance.blur,
  'brightness': instance.brightness,
  'opacity': instance.opacity,
};

_AppAppearanceTheme _$AppAppearanceThemeFromJson(Map<String, dynamic> json) =>
    _AppAppearanceTheme(
      appBarColor: (json['appBarColor'] as num).toInt(),
      appBarGradientColors: (json['appBarGradientColors'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      appBarTitleColor: (json['appBarTitleColor'] as num).toInt(),
      appBarIconColor: (json['appBarIconColor'] as num).toInt(),
      inputBackgroundColor: (json['inputBackgroundColor'] as num).toInt(),
      inputBorderColor: (json['inputBorderColor'] as num).toInt(),
      inputBorderRadius: (json['inputBorderRadius'] as num).toDouble(),
      inputTextColor: (json['inputTextColor'] as num).toInt(),
      inputHintColor: (json['inputHintColor'] as num).toInt(),
      sendButtonColor: (json['sendButtonColor'] as num).toInt(),
      sendButtonRadius: (json['sendButtonRadius'] as num).toDouble(),
      iconColor: (json['iconColor'] as num).toInt(),
      iconSize: (json['iconSize'] as num).toDouble(),
    );

Map<String, dynamic> _$AppAppearanceThemeToJson(_AppAppearanceTheme instance) =>
    <String, dynamic>{
      'appBarColor': instance.appBarColor,
      'appBarGradientColors': instance.appBarGradientColors,
      'appBarTitleColor': instance.appBarTitleColor,
      'appBarIconColor': instance.appBarIconColor,
      'inputBackgroundColor': instance.inputBackgroundColor,
      'inputBorderColor': instance.inputBorderColor,
      'inputBorderRadius': instance.inputBorderRadius,
      'inputTextColor': instance.inputTextColor,
      'inputHintColor': instance.inputHintColor,
      'sendButtonColor': instance.sendButtonColor,
      'sendButtonRadius': instance.sendButtonRadius,
      'iconColor': instance.iconColor,
      'iconSize': instance.iconSize,
    };
