// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advanced_theme_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdvancedThemeModel {

 String get id; String get name; String get description; String get category; BubbleTheme get senderBubble; BubbleTheme get receiverBubble; ChatTextTheme get textTheme; ChatBackgroundTheme get backgroundTheme; AppAppearanceTheme get appAppearance;
/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdvancedThemeModelCopyWith<AdvancedThemeModel> get copyWith => _$AdvancedThemeModelCopyWithImpl<AdvancedThemeModel>(this as AdvancedThemeModel, _$identity);

  /// Serializes this AdvancedThemeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdvancedThemeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.senderBubble, senderBubble) || other.senderBubble == senderBubble)&&(identical(other.receiverBubble, receiverBubble) || other.receiverBubble == receiverBubble)&&(identical(other.textTheme, textTheme) || other.textTheme == textTheme)&&(identical(other.backgroundTheme, backgroundTheme) || other.backgroundTheme == backgroundTheme)&&(identical(other.appAppearance, appAppearance) || other.appAppearance == appAppearance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,category,senderBubble,receiverBubble,textTheme,backgroundTheme,appAppearance);

@override
String toString() {
  return 'AdvancedThemeModel(id: $id, name: $name, description: $description, category: $category, senderBubble: $senderBubble, receiverBubble: $receiverBubble, textTheme: $textTheme, backgroundTheme: $backgroundTheme, appAppearance: $appAppearance)';
}


}

/// @nodoc
abstract mixin class $AdvancedThemeModelCopyWith<$Res>  {
  factory $AdvancedThemeModelCopyWith(AdvancedThemeModel value, $Res Function(AdvancedThemeModel) _then) = _$AdvancedThemeModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String category, BubbleTheme senderBubble, BubbleTheme receiverBubble, ChatTextTheme textTheme, ChatBackgroundTheme backgroundTheme, AppAppearanceTheme appAppearance
});


$BubbleThemeCopyWith<$Res> get senderBubble;$BubbleThemeCopyWith<$Res> get receiverBubble;$ChatTextThemeCopyWith<$Res> get textTheme;$ChatBackgroundThemeCopyWith<$Res> get backgroundTheme;$AppAppearanceThemeCopyWith<$Res> get appAppearance;

}
/// @nodoc
class _$AdvancedThemeModelCopyWithImpl<$Res>
    implements $AdvancedThemeModelCopyWith<$Res> {
  _$AdvancedThemeModelCopyWithImpl(this._self, this._then);

  final AdvancedThemeModel _self;
  final $Res Function(AdvancedThemeModel) _then;

/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? category = null,Object? senderBubble = null,Object? receiverBubble = null,Object? textTheme = null,Object? backgroundTheme = null,Object? appAppearance = null,}) {
  return _then(AdvancedThemeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,senderBubble: null == senderBubble ? _self.senderBubble : senderBubble // ignore: cast_nullable_to_non_nullable
as BubbleTheme,receiverBubble: null == receiverBubble ? _self.receiverBubble : receiverBubble // ignore: cast_nullable_to_non_nullable
as BubbleTheme,textTheme: null == textTheme ? _self.textTheme : textTheme // ignore: cast_nullable_to_non_nullable
as ChatTextTheme,backgroundTheme: null == backgroundTheme ? _self.backgroundTheme : backgroundTheme // ignore: cast_nullable_to_non_nullable
as ChatBackgroundTheme,appAppearance: null == appAppearance ? _self.appAppearance : appAppearance // ignore: cast_nullable_to_non_nullable
as AppAppearanceTheme,
  ));
}
/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BubbleThemeCopyWith<$Res> get senderBubble {
  
  return $BubbleThemeCopyWith<$Res>(_self.senderBubble, (value) {
    return _then(_self.copyWith(senderBubble: value));
  });
}/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BubbleThemeCopyWith<$Res> get receiverBubble {
  
  return $BubbleThemeCopyWith<$Res>(_self.receiverBubble, (value) {
    return _then(_self.copyWith(receiverBubble: value));
  });
}/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextThemeCopyWith<$Res> get textTheme {
  
  return $ChatTextThemeCopyWith<$Res>(_self.textTheme, (value) {
    return _then(_self.copyWith(textTheme: value));
  });
}/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatBackgroundThemeCopyWith<$Res> get backgroundTheme {
  
  return $ChatBackgroundThemeCopyWith<$Res>(_self.backgroundTheme, (value) {
    return _then(_self.copyWith(backgroundTheme: value));
  });
}/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppAppearanceThemeCopyWith<$Res> get appAppearance {
  
  return $AppAppearanceThemeCopyWith<$Res>(_self.appAppearance, (value) {
    return _then(_self.copyWith(appAppearance: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdvancedThemeModel].
extension AdvancedThemeModelPatterns on AdvancedThemeModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdvancedThemeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdvancedThemeModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdvancedThemeModel value)  $default,){
final _that = this;
switch (_that) {
case _AdvancedThemeModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdvancedThemeModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdvancedThemeModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String category,  BubbleTheme senderBubble,  BubbleTheme receiverBubble,  ChatTextTheme textTheme,  ChatBackgroundTheme backgroundTheme,  AppAppearanceTheme appAppearance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdvancedThemeModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.category,_that.senderBubble,_that.receiverBubble,_that.textTheme,_that.backgroundTheme,_that.appAppearance);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String category,  BubbleTheme senderBubble,  BubbleTheme receiverBubble,  ChatTextTheme textTheme,  ChatBackgroundTheme backgroundTheme,  AppAppearanceTheme appAppearance)  $default,) {final _that = this;
switch (_that) {
case _AdvancedThemeModel():
return $default(_that.id,_that.name,_that.description,_that.category,_that.senderBubble,_that.receiverBubble,_that.textTheme,_that.backgroundTheme,_that.appAppearance);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  String category,  BubbleTheme senderBubble,  BubbleTheme receiverBubble,  ChatTextTheme textTheme,  ChatBackgroundTheme backgroundTheme,  AppAppearanceTheme appAppearance)?  $default,) {final _that = this;
switch (_that) {
case _AdvancedThemeModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.category,_that.senderBubble,_that.receiverBubble,_that.textTheme,_that.backgroundTheme,_that.appAppearance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdvancedThemeModel extends AdvancedThemeModel {
  const _AdvancedThemeModel({required this.id, required this.name, this.description = '', this.category = 'Modern', required this.senderBubble, required this.receiverBubble, required this.textTheme, required this.backgroundTheme, required this.appAppearance}): super._();
  factory _AdvancedThemeModel.fromJson(Map<String, dynamic> json) => _$AdvancedThemeModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String category;
@override final  BubbleTheme senderBubble;
@override final  BubbleTheme receiverBubble;
@override final  ChatTextTheme textTheme;
@override final  ChatBackgroundTheme backgroundTheme;
@override final  AppAppearanceTheme appAppearance;

/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdvancedThemeModelCopyWith<_AdvancedThemeModel> get copyWith => __$AdvancedThemeModelCopyWithImpl<_AdvancedThemeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdvancedThemeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdvancedThemeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.senderBubble, senderBubble) || other.senderBubble == senderBubble)&&(identical(other.receiverBubble, receiverBubble) || other.receiverBubble == receiverBubble)&&(identical(other.textTheme, textTheme) || other.textTheme == textTheme)&&(identical(other.backgroundTheme, backgroundTheme) || other.backgroundTheme == backgroundTheme)&&(identical(other.appAppearance, appAppearance) || other.appAppearance == appAppearance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,category,senderBubble,receiverBubble,textTheme,backgroundTheme,appAppearance);

@override
String toString() {
  return 'AdvancedThemeModel(id: $id, name: $name, description: $description, category: $category, senderBubble: $senderBubble, receiverBubble: $receiverBubble, textTheme: $textTheme, backgroundTheme: $backgroundTheme, appAppearance: $appAppearance)';
}


}

/// @nodoc
abstract mixin class _$AdvancedThemeModelCopyWith<$Res> implements $AdvancedThemeModelCopyWith<$Res> {
  factory _$AdvancedThemeModelCopyWith(_AdvancedThemeModel value, $Res Function(_AdvancedThemeModel) _then) = __$AdvancedThemeModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String category, BubbleTheme senderBubble, BubbleTheme receiverBubble, ChatTextTheme textTheme, ChatBackgroundTheme backgroundTheme, AppAppearanceTheme appAppearance
});


@override $BubbleThemeCopyWith<$Res> get senderBubble;@override $BubbleThemeCopyWith<$Res> get receiverBubble;@override $ChatTextThemeCopyWith<$Res> get textTheme;@override $ChatBackgroundThemeCopyWith<$Res> get backgroundTheme;@override $AppAppearanceThemeCopyWith<$Res> get appAppearance;

}
/// @nodoc
class __$AdvancedThemeModelCopyWithImpl<$Res>
    implements _$AdvancedThemeModelCopyWith<$Res> {
  __$AdvancedThemeModelCopyWithImpl(this._self, this._then);

  final _AdvancedThemeModel _self;
  final $Res Function(_AdvancedThemeModel) _then;

/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? category = null,Object? senderBubble = null,Object? receiverBubble = null,Object? textTheme = null,Object? backgroundTheme = null,Object? appAppearance = null,}) {
  return _then(_AdvancedThemeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,senderBubble: null == senderBubble ? _self.senderBubble : senderBubble // ignore: cast_nullable_to_non_nullable
as BubbleTheme,receiverBubble: null == receiverBubble ? _self.receiverBubble : receiverBubble // ignore: cast_nullable_to_non_nullable
as BubbleTheme,textTheme: null == textTheme ? _self.textTheme : textTheme // ignore: cast_nullable_to_non_nullable
as ChatTextTheme,backgroundTheme: null == backgroundTheme ? _self.backgroundTheme : backgroundTheme // ignore: cast_nullable_to_non_nullable
as ChatBackgroundTheme,appAppearance: null == appAppearance ? _self.appAppearance : appAppearance // ignore: cast_nullable_to_non_nullable
as AppAppearanceTheme,
  ));
}

/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BubbleThemeCopyWith<$Res> get senderBubble {
  
  return $BubbleThemeCopyWith<$Res>(_self.senderBubble, (value) {
    return _then(_self.copyWith(senderBubble: value));
  });
}/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BubbleThemeCopyWith<$Res> get receiverBubble {
  
  return $BubbleThemeCopyWith<$Res>(_self.receiverBubble, (value) {
    return _then(_self.copyWith(receiverBubble: value));
  });
}/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatTextThemeCopyWith<$Res> get textTheme {
  
  return $ChatTextThemeCopyWith<$Res>(_self.textTheme, (value) {
    return _then(_self.copyWith(textTheme: value));
  });
}/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatBackgroundThemeCopyWith<$Res> get backgroundTheme {
  
  return $ChatBackgroundThemeCopyWith<$Res>(_self.backgroundTheme, (value) {
    return _then(_self.copyWith(backgroundTheme: value));
  });
}/// Create a copy of AdvancedThemeModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppAppearanceThemeCopyWith<$Res> get appAppearance {
  
  return $AppAppearanceThemeCopyWith<$Res>(_self.appAppearance, (value) {
    return _then(_self.copyWith(appAppearance: value));
  });
}
}


/// @nodoc
mixin _$BubbleTheme {

 int get backgroundColor; List<int> get gradientColors; int get borderColor; double get borderWidth; double get shadowOpacity; double get opacity; double get radiusTopLeft; double get radiusTopRight; double get radiusBottomLeft; double get radiusBottomRight; double get paddingHorizontal; double get paddingVertical;
/// Create a copy of BubbleTheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BubbleThemeCopyWith<BubbleTheme> get copyWith => _$BubbleThemeCopyWithImpl<BubbleTheme>(this as BubbleTheme, _$identity);

  /// Serializes this BubbleTheme to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BubbleTheme&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&const DeepCollectionEquality().equals(other.gradientColors, gradientColors)&&(identical(other.borderColor, borderColor) || other.borderColor == borderColor)&&(identical(other.borderWidth, borderWidth) || other.borderWidth == borderWidth)&&(identical(other.shadowOpacity, shadowOpacity) || other.shadowOpacity == shadowOpacity)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.radiusTopLeft, radiusTopLeft) || other.radiusTopLeft == radiusTopLeft)&&(identical(other.radiusTopRight, radiusTopRight) || other.radiusTopRight == radiusTopRight)&&(identical(other.radiusBottomLeft, radiusBottomLeft) || other.radiusBottomLeft == radiusBottomLeft)&&(identical(other.radiusBottomRight, radiusBottomRight) || other.radiusBottomRight == radiusBottomRight)&&(identical(other.paddingHorizontal, paddingHorizontal) || other.paddingHorizontal == paddingHorizontal)&&(identical(other.paddingVertical, paddingVertical) || other.paddingVertical == paddingVertical));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,backgroundColor,const DeepCollectionEquality().hash(gradientColors),borderColor,borderWidth,shadowOpacity,opacity,radiusTopLeft,radiusTopRight,radiusBottomLeft,radiusBottomRight,paddingHorizontal,paddingVertical);

@override
String toString() {
  return 'BubbleTheme(backgroundColor: $backgroundColor, gradientColors: $gradientColors, borderColor: $borderColor, borderWidth: $borderWidth, shadowOpacity: $shadowOpacity, opacity: $opacity, radiusTopLeft: $radiusTopLeft, radiusTopRight: $radiusTopRight, radiusBottomLeft: $radiusBottomLeft, radiusBottomRight: $radiusBottomRight, paddingHorizontal: $paddingHorizontal, paddingVertical: $paddingVertical)';
}


}

/// @nodoc
abstract mixin class $BubbleThemeCopyWith<$Res>  {
  factory $BubbleThemeCopyWith(BubbleTheme value, $Res Function(BubbleTheme) _then) = _$BubbleThemeCopyWithImpl;
@useResult
$Res call({
 int backgroundColor, List<int> gradientColors, int borderColor, double borderWidth, double shadowOpacity, double opacity, double radiusTopLeft, double radiusTopRight, double radiusBottomLeft, double radiusBottomRight, double paddingHorizontal, double paddingVertical
});




}
/// @nodoc
class _$BubbleThemeCopyWithImpl<$Res>
    implements $BubbleThemeCopyWith<$Res> {
  _$BubbleThemeCopyWithImpl(this._self, this._then);

  final BubbleTheme _self;
  final $Res Function(BubbleTheme) _then;

/// Create a copy of BubbleTheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backgroundColor = null,Object? gradientColors = null,Object? borderColor = null,Object? borderWidth = null,Object? shadowOpacity = null,Object? opacity = null,Object? radiusTopLeft = null,Object? radiusTopRight = null,Object? radiusBottomLeft = null,Object? radiusBottomRight = null,Object? paddingHorizontal = null,Object? paddingVertical = null,}) {
  return _then(BubbleTheme(
backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as int,gradientColors: null == gradientColors ? _self.gradientColors : gradientColors // ignore: cast_nullable_to_non_nullable
as List<int>,borderColor: null == borderColor ? _self.borderColor : borderColor // ignore: cast_nullable_to_non_nullable
as int,borderWidth: null == borderWidth ? _self.borderWidth : borderWidth // ignore: cast_nullable_to_non_nullable
as double,shadowOpacity: null == shadowOpacity ? _self.shadowOpacity : shadowOpacity // ignore: cast_nullable_to_non_nullable
as double,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,radiusTopLeft: null == radiusTopLeft ? _self.radiusTopLeft : radiusTopLeft // ignore: cast_nullable_to_non_nullable
as double,radiusTopRight: null == radiusTopRight ? _self.radiusTopRight : radiusTopRight // ignore: cast_nullable_to_non_nullable
as double,radiusBottomLeft: null == radiusBottomLeft ? _self.radiusBottomLeft : radiusBottomLeft // ignore: cast_nullable_to_non_nullable
as double,radiusBottomRight: null == radiusBottomRight ? _self.radiusBottomRight : radiusBottomRight // ignore: cast_nullable_to_non_nullable
as double,paddingHorizontal: null == paddingHorizontal ? _self.paddingHorizontal : paddingHorizontal // ignore: cast_nullable_to_non_nullable
as double,paddingVertical: null == paddingVertical ? _self.paddingVertical : paddingVertical // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BubbleTheme].
extension BubbleThemePatterns on BubbleTheme {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BubbleTheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BubbleTheme() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BubbleTheme value)  $default,){
final _that = this;
switch (_that) {
case _BubbleTheme():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BubbleTheme value)?  $default,){
final _that = this;
switch (_that) {
case _BubbleTheme() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int backgroundColor,  List<int> gradientColors,  int borderColor,  double borderWidth,  double shadowOpacity,  double opacity,  double radiusTopLeft,  double radiusTopRight,  double radiusBottomLeft,  double radiusBottomRight,  double paddingHorizontal,  double paddingVertical)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BubbleTheme() when $default != null:
return $default(_that.backgroundColor,_that.gradientColors,_that.borderColor,_that.borderWidth,_that.shadowOpacity,_that.opacity,_that.radiusTopLeft,_that.radiusTopRight,_that.radiusBottomLeft,_that.radiusBottomRight,_that.paddingHorizontal,_that.paddingVertical);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int backgroundColor,  List<int> gradientColors,  int borderColor,  double borderWidth,  double shadowOpacity,  double opacity,  double radiusTopLeft,  double radiusTopRight,  double radiusBottomLeft,  double radiusBottomRight,  double paddingHorizontal,  double paddingVertical)  $default,) {final _that = this;
switch (_that) {
case _BubbleTheme():
return $default(_that.backgroundColor,_that.gradientColors,_that.borderColor,_that.borderWidth,_that.shadowOpacity,_that.opacity,_that.radiusTopLeft,_that.radiusTopRight,_that.radiusBottomLeft,_that.radiusBottomRight,_that.paddingHorizontal,_that.paddingVertical);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int backgroundColor,  List<int> gradientColors,  int borderColor,  double borderWidth,  double shadowOpacity,  double opacity,  double radiusTopLeft,  double radiusTopRight,  double radiusBottomLeft,  double radiusBottomRight,  double paddingHorizontal,  double paddingVertical)?  $default,) {final _that = this;
switch (_that) {
case _BubbleTheme() when $default != null:
return $default(_that.backgroundColor,_that.gradientColors,_that.borderColor,_that.borderWidth,_that.shadowOpacity,_that.opacity,_that.radiusTopLeft,_that.radiusTopRight,_that.radiusBottomLeft,_that.radiusBottomRight,_that.paddingHorizontal,_that.paddingVertical);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BubbleTheme extends BubbleTheme {
  const _BubbleTheme({required this.backgroundColor, required  List<int> gradientColors, required this.borderColor, required this.borderWidth, required this.shadowOpacity, required this.opacity, required this.radiusTopLeft, required this.radiusTopRight, required this.radiusBottomLeft, required this.radiusBottomRight, required this.paddingHorizontal, required this.paddingVertical}): _gradientColors = gradientColors,super._();
  factory _BubbleTheme.fromJson(Map<String, dynamic> json) => _$BubbleThemeFromJson(json);

@override final  int backgroundColor;
 final  List<int> _gradientColors;
@override List<int> get gradientColors {
  if (_gradientColors is EqualUnmodifiableListView) return _gradientColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gradientColors);
}

@override final  int borderColor;
@override final  double borderWidth;
@override final  double shadowOpacity;
@override final  double opacity;
@override final  double radiusTopLeft;
@override final  double radiusTopRight;
@override final  double radiusBottomLeft;
@override final  double radiusBottomRight;
@override final  double paddingHorizontal;
@override final  double paddingVertical;

/// Create a copy of BubbleTheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BubbleThemeCopyWith<_BubbleTheme> get copyWith => __$BubbleThemeCopyWithImpl<_BubbleTheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BubbleThemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BubbleTheme&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&const DeepCollectionEquality().equals(other._gradientColors, _gradientColors)&&(identical(other.borderColor, borderColor) || other.borderColor == borderColor)&&(identical(other.borderWidth, borderWidth) || other.borderWidth == borderWidth)&&(identical(other.shadowOpacity, shadowOpacity) || other.shadowOpacity == shadowOpacity)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.radiusTopLeft, radiusTopLeft) || other.radiusTopLeft == radiusTopLeft)&&(identical(other.radiusTopRight, radiusTopRight) || other.radiusTopRight == radiusTopRight)&&(identical(other.radiusBottomLeft, radiusBottomLeft) || other.radiusBottomLeft == radiusBottomLeft)&&(identical(other.radiusBottomRight, radiusBottomRight) || other.radiusBottomRight == radiusBottomRight)&&(identical(other.paddingHorizontal, paddingHorizontal) || other.paddingHorizontal == paddingHorizontal)&&(identical(other.paddingVertical, paddingVertical) || other.paddingVertical == paddingVertical));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,backgroundColor,const DeepCollectionEquality().hash(_gradientColors),borderColor,borderWidth,shadowOpacity,opacity,radiusTopLeft,radiusTopRight,radiusBottomLeft,radiusBottomRight,paddingHorizontal,paddingVertical);

@override
String toString() {
  return 'BubbleTheme(backgroundColor: $backgroundColor, gradientColors: $gradientColors, borderColor: $borderColor, borderWidth: $borderWidth, shadowOpacity: $shadowOpacity, opacity: $opacity, radiusTopLeft: $radiusTopLeft, radiusTopRight: $radiusTopRight, radiusBottomLeft: $radiusBottomLeft, radiusBottomRight: $radiusBottomRight, paddingHorizontal: $paddingHorizontal, paddingVertical: $paddingVertical)';
}


}

/// @nodoc
abstract mixin class _$BubbleThemeCopyWith<$Res> implements $BubbleThemeCopyWith<$Res> {
  factory _$BubbleThemeCopyWith(_BubbleTheme value, $Res Function(_BubbleTheme) _then) = __$BubbleThemeCopyWithImpl;
@override @useResult
$Res call({
 int backgroundColor, List<int> gradientColors, int borderColor, double borderWidth, double shadowOpacity, double opacity, double radiusTopLeft, double radiusTopRight, double radiusBottomLeft, double radiusBottomRight, double paddingHorizontal, double paddingVertical
});




}
/// @nodoc
class __$BubbleThemeCopyWithImpl<$Res>
    implements _$BubbleThemeCopyWith<$Res> {
  __$BubbleThemeCopyWithImpl(this._self, this._then);

  final _BubbleTheme _self;
  final $Res Function(_BubbleTheme) _then;

/// Create a copy of BubbleTheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? backgroundColor = null,Object? gradientColors = null,Object? borderColor = null,Object? borderWidth = null,Object? shadowOpacity = null,Object? opacity = null,Object? radiusTopLeft = null,Object? radiusTopRight = null,Object? radiusBottomLeft = null,Object? radiusBottomRight = null,Object? paddingHorizontal = null,Object? paddingVertical = null,}) {
  return _then(_BubbleTheme(
backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as int,gradientColors: null == gradientColors ? _self._gradientColors : gradientColors // ignore: cast_nullable_to_non_nullable
as List<int>,borderColor: null == borderColor ? _self.borderColor : borderColor // ignore: cast_nullable_to_non_nullable
as int,borderWidth: null == borderWidth ? _self.borderWidth : borderWidth // ignore: cast_nullable_to_non_nullable
as double,shadowOpacity: null == shadowOpacity ? _self.shadowOpacity : shadowOpacity // ignore: cast_nullable_to_non_nullable
as double,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,radiusTopLeft: null == radiusTopLeft ? _self.radiusTopLeft : radiusTopLeft // ignore: cast_nullable_to_non_nullable
as double,radiusTopRight: null == radiusTopRight ? _self.radiusTopRight : radiusTopRight // ignore: cast_nullable_to_non_nullable
as double,radiusBottomLeft: null == radiusBottomLeft ? _self.radiusBottomLeft : radiusBottomLeft // ignore: cast_nullable_to_non_nullable
as double,radiusBottomRight: null == radiusBottomRight ? _self.radiusBottomRight : radiusBottomRight // ignore: cast_nullable_to_non_nullable
as double,paddingHorizontal: null == paddingHorizontal ? _self.paddingHorizontal : paddingHorizontal // ignore: cast_nullable_to_non_nullable
as double,paddingVertical: null == paddingVertical ? _self.paddingVertical : paddingVertical // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ChatTextTheme {

 String get fontFamily; double get fontSize; int get fontWeight; int get senderMessageColor; int get receiverMessageColor; int get timestampColor; double get timestampSize; double get emojiSize;
/// Create a copy of ChatTextTheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTextThemeCopyWith<ChatTextTheme> get copyWith => _$ChatTextThemeCopyWithImpl<ChatTextTheme>(this as ChatTextTheme, _$identity);

  /// Serializes this ChatTextTheme to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTextTheme&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.fontWeight, fontWeight) || other.fontWeight == fontWeight)&&(identical(other.senderMessageColor, senderMessageColor) || other.senderMessageColor == senderMessageColor)&&(identical(other.receiverMessageColor, receiverMessageColor) || other.receiverMessageColor == receiverMessageColor)&&(identical(other.timestampColor, timestampColor) || other.timestampColor == timestampColor)&&(identical(other.timestampSize, timestampSize) || other.timestampSize == timestampSize)&&(identical(other.emojiSize, emojiSize) || other.emojiSize == emojiSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fontFamily,fontSize,fontWeight,senderMessageColor,receiverMessageColor,timestampColor,timestampSize,emojiSize);

@override
String toString() {
  return 'ChatTextTheme(fontFamily: $fontFamily, fontSize: $fontSize, fontWeight: $fontWeight, senderMessageColor: $senderMessageColor, receiverMessageColor: $receiverMessageColor, timestampColor: $timestampColor, timestampSize: $timestampSize, emojiSize: $emojiSize)';
}


}

/// @nodoc
abstract mixin class $ChatTextThemeCopyWith<$Res>  {
  factory $ChatTextThemeCopyWith(ChatTextTheme value, $Res Function(ChatTextTheme) _then) = _$ChatTextThemeCopyWithImpl;
@useResult
$Res call({
 String fontFamily, double fontSize, int fontWeight, int senderMessageColor, int receiverMessageColor, int timestampColor, double timestampSize, double emojiSize
});




}
/// @nodoc
class _$ChatTextThemeCopyWithImpl<$Res>
    implements $ChatTextThemeCopyWith<$Res> {
  _$ChatTextThemeCopyWithImpl(this._self, this._then);

  final ChatTextTheme _self;
  final $Res Function(ChatTextTheme) _then;

/// Create a copy of ChatTextTheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fontFamily = null,Object? fontSize = null,Object? fontWeight = null,Object? senderMessageColor = null,Object? receiverMessageColor = null,Object? timestampColor = null,Object? timestampSize = null,Object? emojiSize = null,}) {
  return _then(ChatTextTheme(
fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,fontWeight: null == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as int,senderMessageColor: null == senderMessageColor ? _self.senderMessageColor : senderMessageColor // ignore: cast_nullable_to_non_nullable
as int,receiverMessageColor: null == receiverMessageColor ? _self.receiverMessageColor : receiverMessageColor // ignore: cast_nullable_to_non_nullable
as int,timestampColor: null == timestampColor ? _self.timestampColor : timestampColor // ignore: cast_nullable_to_non_nullable
as int,timestampSize: null == timestampSize ? _self.timestampSize : timestampSize // ignore: cast_nullable_to_non_nullable
as double,emojiSize: null == emojiSize ? _self.emojiSize : emojiSize // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatTextTheme].
extension ChatTextThemePatterns on ChatTextTheme {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatTextTheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatTextTheme() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatTextTheme value)  $default,){
final _that = this;
switch (_that) {
case _ChatTextTheme():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatTextTheme value)?  $default,){
final _that = this;
switch (_that) {
case _ChatTextTheme() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fontFamily,  double fontSize,  int fontWeight,  int senderMessageColor,  int receiverMessageColor,  int timestampColor,  double timestampSize,  double emojiSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatTextTheme() when $default != null:
return $default(_that.fontFamily,_that.fontSize,_that.fontWeight,_that.senderMessageColor,_that.receiverMessageColor,_that.timestampColor,_that.timestampSize,_that.emojiSize);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fontFamily,  double fontSize,  int fontWeight,  int senderMessageColor,  int receiverMessageColor,  int timestampColor,  double timestampSize,  double emojiSize)  $default,) {final _that = this;
switch (_that) {
case _ChatTextTheme():
return $default(_that.fontFamily,_that.fontSize,_that.fontWeight,_that.senderMessageColor,_that.receiverMessageColor,_that.timestampColor,_that.timestampSize,_that.emojiSize);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fontFamily,  double fontSize,  int fontWeight,  int senderMessageColor,  int receiverMessageColor,  int timestampColor,  double timestampSize,  double emojiSize)?  $default,) {final _that = this;
switch (_that) {
case _ChatTextTheme() when $default != null:
return $default(_that.fontFamily,_that.fontSize,_that.fontWeight,_that.senderMessageColor,_that.receiverMessageColor,_that.timestampColor,_that.timestampSize,_that.emojiSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatTextTheme extends ChatTextTheme {
  const _ChatTextTheme({required this.fontFamily, required this.fontSize, required this.fontWeight, required this.senderMessageColor, required this.receiverMessageColor, required this.timestampColor, required this.timestampSize, required this.emojiSize}): super._();
  factory _ChatTextTheme.fromJson(Map<String, dynamic> json) => _$ChatTextThemeFromJson(json);

@override final  String fontFamily;
@override final  double fontSize;
@override final  int fontWeight;
@override final  int senderMessageColor;
@override final  int receiverMessageColor;
@override final  int timestampColor;
@override final  double timestampSize;
@override final  double emojiSize;

/// Create a copy of ChatTextTheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatTextThemeCopyWith<_ChatTextTheme> get copyWith => __$ChatTextThemeCopyWithImpl<_ChatTextTheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatTextThemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatTextTheme&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.fontWeight, fontWeight) || other.fontWeight == fontWeight)&&(identical(other.senderMessageColor, senderMessageColor) || other.senderMessageColor == senderMessageColor)&&(identical(other.receiverMessageColor, receiverMessageColor) || other.receiverMessageColor == receiverMessageColor)&&(identical(other.timestampColor, timestampColor) || other.timestampColor == timestampColor)&&(identical(other.timestampSize, timestampSize) || other.timestampSize == timestampSize)&&(identical(other.emojiSize, emojiSize) || other.emojiSize == emojiSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fontFamily,fontSize,fontWeight,senderMessageColor,receiverMessageColor,timestampColor,timestampSize,emojiSize);

@override
String toString() {
  return 'ChatTextTheme(fontFamily: $fontFamily, fontSize: $fontSize, fontWeight: $fontWeight, senderMessageColor: $senderMessageColor, receiverMessageColor: $receiverMessageColor, timestampColor: $timestampColor, timestampSize: $timestampSize, emojiSize: $emojiSize)';
}


}

/// @nodoc
abstract mixin class _$ChatTextThemeCopyWith<$Res> implements $ChatTextThemeCopyWith<$Res> {
  factory _$ChatTextThemeCopyWith(_ChatTextTheme value, $Res Function(_ChatTextTheme) _then) = __$ChatTextThemeCopyWithImpl;
@override @useResult
$Res call({
 String fontFamily, double fontSize, int fontWeight, int senderMessageColor, int receiverMessageColor, int timestampColor, double timestampSize, double emojiSize
});




}
/// @nodoc
class __$ChatTextThemeCopyWithImpl<$Res>
    implements _$ChatTextThemeCopyWith<$Res> {
  __$ChatTextThemeCopyWithImpl(this._self, this._then);

  final _ChatTextTheme _self;
  final $Res Function(_ChatTextTheme) _then;

/// Create a copy of ChatTextTheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fontFamily = null,Object? fontSize = null,Object? fontWeight = null,Object? senderMessageColor = null,Object? receiverMessageColor = null,Object? timestampColor = null,Object? timestampSize = null,Object? emojiSize = null,}) {
  return _then(_ChatTextTheme(
fontFamily: null == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,fontWeight: null == fontWeight ? _self.fontWeight : fontWeight // ignore: cast_nullable_to_non_nullable
as int,senderMessageColor: null == senderMessageColor ? _self.senderMessageColor : senderMessageColor // ignore: cast_nullable_to_non_nullable
as int,receiverMessageColor: null == receiverMessageColor ? _self.receiverMessageColor : receiverMessageColor // ignore: cast_nullable_to_non_nullable
as int,timestampColor: null == timestampColor ? _self.timestampColor : timestampColor // ignore: cast_nullable_to_non_nullable
as int,timestampSize: null == timestampSize ? _self.timestampSize : timestampSize // ignore: cast_nullable_to_non_nullable
as double,emojiSize: null == emojiSize ? _self.emojiSize : emojiSize // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ChatBackgroundTheme {

 int get solidColor; List<int> get gradientColors; String? get wallpaperUrl; double get blur; double get brightness; double get opacity;
/// Create a copy of ChatBackgroundTheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatBackgroundThemeCopyWith<ChatBackgroundTheme> get copyWith => _$ChatBackgroundThemeCopyWithImpl<ChatBackgroundTheme>(this as ChatBackgroundTheme, _$identity);

  /// Serializes this ChatBackgroundTheme to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatBackgroundTheme&&(identical(other.solidColor, solidColor) || other.solidColor == solidColor)&&const DeepCollectionEquality().equals(other.gradientColors, gradientColors)&&(identical(other.wallpaperUrl, wallpaperUrl) || other.wallpaperUrl == wallpaperUrl)&&(identical(other.blur, blur) || other.blur == blur)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.opacity, opacity) || other.opacity == opacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,solidColor,const DeepCollectionEquality().hash(gradientColors),wallpaperUrl,blur,brightness,opacity);

@override
String toString() {
  return 'ChatBackgroundTheme(solidColor: $solidColor, gradientColors: $gradientColors, wallpaperUrl: $wallpaperUrl, blur: $blur, brightness: $brightness, opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class $ChatBackgroundThemeCopyWith<$Res>  {
  factory $ChatBackgroundThemeCopyWith(ChatBackgroundTheme value, $Res Function(ChatBackgroundTheme) _then) = _$ChatBackgroundThemeCopyWithImpl;
@useResult
$Res call({
 int solidColor, List<int> gradientColors, String? wallpaperUrl, double blur, double brightness, double opacity
});




}
/// @nodoc
class _$ChatBackgroundThemeCopyWithImpl<$Res>
    implements $ChatBackgroundThemeCopyWith<$Res> {
  _$ChatBackgroundThemeCopyWithImpl(this._self, this._then);

  final ChatBackgroundTheme _self;
  final $Res Function(ChatBackgroundTheme) _then;

/// Create a copy of ChatBackgroundTheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? solidColor = null,Object? gradientColors = null,Object? wallpaperUrl = freezed,Object? blur = null,Object? brightness = null,Object? opacity = null,}) {
  return _then(ChatBackgroundTheme(
solidColor: null == solidColor ? _self.solidColor : solidColor // ignore: cast_nullable_to_non_nullable
as int,gradientColors: null == gradientColors ? _self.gradientColors : gradientColors // ignore: cast_nullable_to_non_nullable
as List<int>,wallpaperUrl: freezed == wallpaperUrl ? _self.wallpaperUrl : wallpaperUrl // ignore: cast_nullable_to_non_nullable
as String?,blur: null == blur ? _self.blur : blur // ignore: cast_nullable_to_non_nullable
as double,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatBackgroundTheme].
extension ChatBackgroundThemePatterns on ChatBackgroundTheme {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatBackgroundTheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatBackgroundTheme() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatBackgroundTheme value)  $default,){
final _that = this;
switch (_that) {
case _ChatBackgroundTheme():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatBackgroundTheme value)?  $default,){
final _that = this;
switch (_that) {
case _ChatBackgroundTheme() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int solidColor,  List<int> gradientColors,  String? wallpaperUrl,  double blur,  double brightness,  double opacity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatBackgroundTheme() when $default != null:
return $default(_that.solidColor,_that.gradientColors,_that.wallpaperUrl,_that.blur,_that.brightness,_that.opacity);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int solidColor,  List<int> gradientColors,  String? wallpaperUrl,  double blur,  double brightness,  double opacity)  $default,) {final _that = this;
switch (_that) {
case _ChatBackgroundTheme():
return $default(_that.solidColor,_that.gradientColors,_that.wallpaperUrl,_that.blur,_that.brightness,_that.opacity);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int solidColor,  List<int> gradientColors,  String? wallpaperUrl,  double blur,  double brightness,  double opacity)?  $default,) {final _that = this;
switch (_that) {
case _ChatBackgroundTheme() when $default != null:
return $default(_that.solidColor,_that.gradientColors,_that.wallpaperUrl,_that.blur,_that.brightness,_that.opacity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatBackgroundTheme extends ChatBackgroundTheme {
  const _ChatBackgroundTheme({required this.solidColor, required  List<int> gradientColors, required this.wallpaperUrl, required this.blur, required this.brightness, required this.opacity}): _gradientColors = gradientColors,super._();
  factory _ChatBackgroundTheme.fromJson(Map<String, dynamic> json) => _$ChatBackgroundThemeFromJson(json);

@override final  int solidColor;
 final  List<int> _gradientColors;
@override List<int> get gradientColors {
  if (_gradientColors is EqualUnmodifiableListView) return _gradientColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gradientColors);
}

@override final  String? wallpaperUrl;
@override final  double blur;
@override final  double brightness;
@override final  double opacity;

/// Create a copy of ChatBackgroundTheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatBackgroundThemeCopyWith<_ChatBackgroundTheme> get copyWith => __$ChatBackgroundThemeCopyWithImpl<_ChatBackgroundTheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatBackgroundThemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatBackgroundTheme&&(identical(other.solidColor, solidColor) || other.solidColor == solidColor)&&const DeepCollectionEquality().equals(other._gradientColors, _gradientColors)&&(identical(other.wallpaperUrl, wallpaperUrl) || other.wallpaperUrl == wallpaperUrl)&&(identical(other.blur, blur) || other.blur == blur)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.opacity, opacity) || other.opacity == opacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,solidColor,const DeepCollectionEquality().hash(_gradientColors),wallpaperUrl,blur,brightness,opacity);

@override
String toString() {
  return 'ChatBackgroundTheme(solidColor: $solidColor, gradientColors: $gradientColors, wallpaperUrl: $wallpaperUrl, blur: $blur, brightness: $brightness, opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class _$ChatBackgroundThemeCopyWith<$Res> implements $ChatBackgroundThemeCopyWith<$Res> {
  factory _$ChatBackgroundThemeCopyWith(_ChatBackgroundTheme value, $Res Function(_ChatBackgroundTheme) _then) = __$ChatBackgroundThemeCopyWithImpl;
@override @useResult
$Res call({
 int solidColor, List<int> gradientColors, String? wallpaperUrl, double blur, double brightness, double opacity
});




}
/// @nodoc
class __$ChatBackgroundThemeCopyWithImpl<$Res>
    implements _$ChatBackgroundThemeCopyWith<$Res> {
  __$ChatBackgroundThemeCopyWithImpl(this._self, this._then);

  final _ChatBackgroundTheme _self;
  final $Res Function(_ChatBackgroundTheme) _then;

/// Create a copy of ChatBackgroundTheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? solidColor = null,Object? gradientColors = null,Object? wallpaperUrl = freezed,Object? blur = null,Object? brightness = null,Object? opacity = null,}) {
  return _then(_ChatBackgroundTheme(
solidColor: null == solidColor ? _self.solidColor : solidColor // ignore: cast_nullable_to_non_nullable
as int,gradientColors: null == gradientColors ? _self._gradientColors : gradientColors // ignore: cast_nullable_to_non_nullable
as List<int>,wallpaperUrl: freezed == wallpaperUrl ? _self.wallpaperUrl : wallpaperUrl // ignore: cast_nullable_to_non_nullable
as String?,blur: null == blur ? _self.blur : blur // ignore: cast_nullable_to_non_nullable
as double,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$AppAppearanceTheme {

 int get appBarColor; List<int> get appBarGradientColors; int get appBarTitleColor; int get appBarIconColor; int get inputBackgroundColor; int get inputBorderColor; double get inputBorderRadius; int get inputTextColor; int get inputHintColor; int get sendButtonColor; double get sendButtonRadius; int get iconColor; double get iconSize;
/// Create a copy of AppAppearanceTheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppAppearanceThemeCopyWith<AppAppearanceTheme> get copyWith => _$AppAppearanceThemeCopyWithImpl<AppAppearanceTheme>(this as AppAppearanceTheme, _$identity);

  /// Serializes this AppAppearanceTheme to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppAppearanceTheme&&(identical(other.appBarColor, appBarColor) || other.appBarColor == appBarColor)&&const DeepCollectionEquality().equals(other.appBarGradientColors, appBarGradientColors)&&(identical(other.appBarTitleColor, appBarTitleColor) || other.appBarTitleColor == appBarTitleColor)&&(identical(other.appBarIconColor, appBarIconColor) || other.appBarIconColor == appBarIconColor)&&(identical(other.inputBackgroundColor, inputBackgroundColor) || other.inputBackgroundColor == inputBackgroundColor)&&(identical(other.inputBorderColor, inputBorderColor) || other.inputBorderColor == inputBorderColor)&&(identical(other.inputBorderRadius, inputBorderRadius) || other.inputBorderRadius == inputBorderRadius)&&(identical(other.inputTextColor, inputTextColor) || other.inputTextColor == inputTextColor)&&(identical(other.inputHintColor, inputHintColor) || other.inputHintColor == inputHintColor)&&(identical(other.sendButtonColor, sendButtonColor) || other.sendButtonColor == sendButtonColor)&&(identical(other.sendButtonRadius, sendButtonRadius) || other.sendButtonRadius == sendButtonRadius)&&(identical(other.iconColor, iconColor) || other.iconColor == iconColor)&&(identical(other.iconSize, iconSize) || other.iconSize == iconSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appBarColor,const DeepCollectionEquality().hash(appBarGradientColors),appBarTitleColor,appBarIconColor,inputBackgroundColor,inputBorderColor,inputBorderRadius,inputTextColor,inputHintColor,sendButtonColor,sendButtonRadius,iconColor,iconSize);

@override
String toString() {
  return 'AppAppearanceTheme(appBarColor: $appBarColor, appBarGradientColors: $appBarGradientColors, appBarTitleColor: $appBarTitleColor, appBarIconColor: $appBarIconColor, inputBackgroundColor: $inputBackgroundColor, inputBorderColor: $inputBorderColor, inputBorderRadius: $inputBorderRadius, inputTextColor: $inputTextColor, inputHintColor: $inputHintColor, sendButtonColor: $sendButtonColor, sendButtonRadius: $sendButtonRadius, iconColor: $iconColor, iconSize: $iconSize)';
}


}

/// @nodoc
abstract mixin class $AppAppearanceThemeCopyWith<$Res>  {
  factory $AppAppearanceThemeCopyWith(AppAppearanceTheme value, $Res Function(AppAppearanceTheme) _then) = _$AppAppearanceThemeCopyWithImpl;
@useResult
$Res call({
 int appBarColor, List<int> appBarGradientColors, int appBarTitleColor, int appBarIconColor, int inputBackgroundColor, int inputBorderColor, double inputBorderRadius, int inputTextColor, int inputHintColor, int sendButtonColor, double sendButtonRadius, int iconColor, double iconSize
});




}
/// @nodoc
class _$AppAppearanceThemeCopyWithImpl<$Res>
    implements $AppAppearanceThemeCopyWith<$Res> {
  _$AppAppearanceThemeCopyWithImpl(this._self, this._then);

  final AppAppearanceTheme _self;
  final $Res Function(AppAppearanceTheme) _then;

/// Create a copy of AppAppearanceTheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appBarColor = null,Object? appBarGradientColors = null,Object? appBarTitleColor = null,Object? appBarIconColor = null,Object? inputBackgroundColor = null,Object? inputBorderColor = null,Object? inputBorderRadius = null,Object? inputTextColor = null,Object? inputHintColor = null,Object? sendButtonColor = null,Object? sendButtonRadius = null,Object? iconColor = null,Object? iconSize = null,}) {
  return _then(AppAppearanceTheme(
appBarColor: null == appBarColor ? _self.appBarColor : appBarColor // ignore: cast_nullable_to_non_nullable
as int,appBarGradientColors: null == appBarGradientColors ? _self.appBarGradientColors : appBarGradientColors // ignore: cast_nullable_to_non_nullable
as List<int>,appBarTitleColor: null == appBarTitleColor ? _self.appBarTitleColor : appBarTitleColor // ignore: cast_nullable_to_non_nullable
as int,appBarIconColor: null == appBarIconColor ? _self.appBarIconColor : appBarIconColor // ignore: cast_nullable_to_non_nullable
as int,inputBackgroundColor: null == inputBackgroundColor ? _self.inputBackgroundColor : inputBackgroundColor // ignore: cast_nullable_to_non_nullable
as int,inputBorderColor: null == inputBorderColor ? _self.inputBorderColor : inputBorderColor // ignore: cast_nullable_to_non_nullable
as int,inputBorderRadius: null == inputBorderRadius ? _self.inputBorderRadius : inputBorderRadius // ignore: cast_nullable_to_non_nullable
as double,inputTextColor: null == inputTextColor ? _self.inputTextColor : inputTextColor // ignore: cast_nullable_to_non_nullable
as int,inputHintColor: null == inputHintColor ? _self.inputHintColor : inputHintColor // ignore: cast_nullable_to_non_nullable
as int,sendButtonColor: null == sendButtonColor ? _self.sendButtonColor : sendButtonColor // ignore: cast_nullable_to_non_nullable
as int,sendButtonRadius: null == sendButtonRadius ? _self.sendButtonRadius : sendButtonRadius // ignore: cast_nullable_to_non_nullable
as double,iconColor: null == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as int,iconSize: null == iconSize ? _self.iconSize : iconSize // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AppAppearanceTheme].
extension AppAppearanceThemePatterns on AppAppearanceTheme {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppAppearanceTheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppAppearanceTheme() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppAppearanceTheme value)  $default,){
final _that = this;
switch (_that) {
case _AppAppearanceTheme():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppAppearanceTheme value)?  $default,){
final _that = this;
switch (_that) {
case _AppAppearanceTheme() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int appBarColor,  List<int> appBarGradientColors,  int appBarTitleColor,  int appBarIconColor,  int inputBackgroundColor,  int inputBorderColor,  double inputBorderRadius,  int inputTextColor,  int inputHintColor,  int sendButtonColor,  double sendButtonRadius,  int iconColor,  double iconSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppAppearanceTheme() when $default != null:
return $default(_that.appBarColor,_that.appBarGradientColors,_that.appBarTitleColor,_that.appBarIconColor,_that.inputBackgroundColor,_that.inputBorderColor,_that.inputBorderRadius,_that.inputTextColor,_that.inputHintColor,_that.sendButtonColor,_that.sendButtonRadius,_that.iconColor,_that.iconSize);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int appBarColor,  List<int> appBarGradientColors,  int appBarTitleColor,  int appBarIconColor,  int inputBackgroundColor,  int inputBorderColor,  double inputBorderRadius,  int inputTextColor,  int inputHintColor,  int sendButtonColor,  double sendButtonRadius,  int iconColor,  double iconSize)  $default,) {final _that = this;
switch (_that) {
case _AppAppearanceTheme():
return $default(_that.appBarColor,_that.appBarGradientColors,_that.appBarTitleColor,_that.appBarIconColor,_that.inputBackgroundColor,_that.inputBorderColor,_that.inputBorderRadius,_that.inputTextColor,_that.inputHintColor,_that.sendButtonColor,_that.sendButtonRadius,_that.iconColor,_that.iconSize);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int appBarColor,  List<int> appBarGradientColors,  int appBarTitleColor,  int appBarIconColor,  int inputBackgroundColor,  int inputBorderColor,  double inputBorderRadius,  int inputTextColor,  int inputHintColor,  int sendButtonColor,  double sendButtonRadius,  int iconColor,  double iconSize)?  $default,) {final _that = this;
switch (_that) {
case _AppAppearanceTheme() when $default != null:
return $default(_that.appBarColor,_that.appBarGradientColors,_that.appBarTitleColor,_that.appBarIconColor,_that.inputBackgroundColor,_that.inputBorderColor,_that.inputBorderRadius,_that.inputTextColor,_that.inputHintColor,_that.sendButtonColor,_that.sendButtonRadius,_that.iconColor,_that.iconSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppAppearanceTheme extends AppAppearanceTheme {
  const _AppAppearanceTheme({required this.appBarColor, required  List<int> appBarGradientColors, required this.appBarTitleColor, required this.appBarIconColor, required this.inputBackgroundColor, required this.inputBorderColor, required this.inputBorderRadius, required this.inputTextColor, required this.inputHintColor, required this.sendButtonColor, required this.sendButtonRadius, required this.iconColor, required this.iconSize}): _appBarGradientColors = appBarGradientColors,super._();
  factory _AppAppearanceTheme.fromJson(Map<String, dynamic> json) => _$AppAppearanceThemeFromJson(json);

@override final  int appBarColor;
 final  List<int> _appBarGradientColors;
@override List<int> get appBarGradientColors {
  if (_appBarGradientColors is EqualUnmodifiableListView) return _appBarGradientColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appBarGradientColors);
}

@override final  int appBarTitleColor;
@override final  int appBarIconColor;
@override final  int inputBackgroundColor;
@override final  int inputBorderColor;
@override final  double inputBorderRadius;
@override final  int inputTextColor;
@override final  int inputHintColor;
@override final  int sendButtonColor;
@override final  double sendButtonRadius;
@override final  int iconColor;
@override final  double iconSize;

/// Create a copy of AppAppearanceTheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppAppearanceThemeCopyWith<_AppAppearanceTheme> get copyWith => __$AppAppearanceThemeCopyWithImpl<_AppAppearanceTheme>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppAppearanceThemeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppAppearanceTheme&&(identical(other.appBarColor, appBarColor) || other.appBarColor == appBarColor)&&const DeepCollectionEquality().equals(other._appBarGradientColors, _appBarGradientColors)&&(identical(other.appBarTitleColor, appBarTitleColor) || other.appBarTitleColor == appBarTitleColor)&&(identical(other.appBarIconColor, appBarIconColor) || other.appBarIconColor == appBarIconColor)&&(identical(other.inputBackgroundColor, inputBackgroundColor) || other.inputBackgroundColor == inputBackgroundColor)&&(identical(other.inputBorderColor, inputBorderColor) || other.inputBorderColor == inputBorderColor)&&(identical(other.inputBorderRadius, inputBorderRadius) || other.inputBorderRadius == inputBorderRadius)&&(identical(other.inputTextColor, inputTextColor) || other.inputTextColor == inputTextColor)&&(identical(other.inputHintColor, inputHintColor) || other.inputHintColor == inputHintColor)&&(identical(other.sendButtonColor, sendButtonColor) || other.sendButtonColor == sendButtonColor)&&(identical(other.sendButtonRadius, sendButtonRadius) || other.sendButtonRadius == sendButtonRadius)&&(identical(other.iconColor, iconColor) || other.iconColor == iconColor)&&(identical(other.iconSize, iconSize) || other.iconSize == iconSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appBarColor,const DeepCollectionEquality().hash(_appBarGradientColors),appBarTitleColor,appBarIconColor,inputBackgroundColor,inputBorderColor,inputBorderRadius,inputTextColor,inputHintColor,sendButtonColor,sendButtonRadius,iconColor,iconSize);

@override
String toString() {
  return 'AppAppearanceTheme(appBarColor: $appBarColor, appBarGradientColors: $appBarGradientColors, appBarTitleColor: $appBarTitleColor, appBarIconColor: $appBarIconColor, inputBackgroundColor: $inputBackgroundColor, inputBorderColor: $inputBorderColor, inputBorderRadius: $inputBorderRadius, inputTextColor: $inputTextColor, inputHintColor: $inputHintColor, sendButtonColor: $sendButtonColor, sendButtonRadius: $sendButtonRadius, iconColor: $iconColor, iconSize: $iconSize)';
}


}

/// @nodoc
abstract mixin class _$AppAppearanceThemeCopyWith<$Res> implements $AppAppearanceThemeCopyWith<$Res> {
  factory _$AppAppearanceThemeCopyWith(_AppAppearanceTheme value, $Res Function(_AppAppearanceTheme) _then) = __$AppAppearanceThemeCopyWithImpl;
@override @useResult
$Res call({
 int appBarColor, List<int> appBarGradientColors, int appBarTitleColor, int appBarIconColor, int inputBackgroundColor, int inputBorderColor, double inputBorderRadius, int inputTextColor, int inputHintColor, int sendButtonColor, double sendButtonRadius, int iconColor, double iconSize
});




}
/// @nodoc
class __$AppAppearanceThemeCopyWithImpl<$Res>
    implements _$AppAppearanceThemeCopyWith<$Res> {
  __$AppAppearanceThemeCopyWithImpl(this._self, this._then);

  final _AppAppearanceTheme _self;
  final $Res Function(_AppAppearanceTheme) _then;

/// Create a copy of AppAppearanceTheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appBarColor = null,Object? appBarGradientColors = null,Object? appBarTitleColor = null,Object? appBarIconColor = null,Object? inputBackgroundColor = null,Object? inputBorderColor = null,Object? inputBorderRadius = null,Object? inputTextColor = null,Object? inputHintColor = null,Object? sendButtonColor = null,Object? sendButtonRadius = null,Object? iconColor = null,Object? iconSize = null,}) {
  return _then(_AppAppearanceTheme(
appBarColor: null == appBarColor ? _self.appBarColor : appBarColor // ignore: cast_nullable_to_non_nullable
as int,appBarGradientColors: null == appBarGradientColors ? _self._appBarGradientColors : appBarGradientColors // ignore: cast_nullable_to_non_nullable
as List<int>,appBarTitleColor: null == appBarTitleColor ? _self.appBarTitleColor : appBarTitleColor // ignore: cast_nullable_to_non_nullable
as int,appBarIconColor: null == appBarIconColor ? _self.appBarIconColor : appBarIconColor // ignore: cast_nullable_to_non_nullable
as int,inputBackgroundColor: null == inputBackgroundColor ? _self.inputBackgroundColor : inputBackgroundColor // ignore: cast_nullable_to_non_nullable
as int,inputBorderColor: null == inputBorderColor ? _self.inputBorderColor : inputBorderColor // ignore: cast_nullable_to_non_nullable
as int,inputBorderRadius: null == inputBorderRadius ? _self.inputBorderRadius : inputBorderRadius // ignore: cast_nullable_to_non_nullable
as double,inputTextColor: null == inputTextColor ? _self.inputTextColor : inputTextColor // ignore: cast_nullable_to_non_nullable
as int,inputHintColor: null == inputHintColor ? _self.inputHintColor : inputHintColor // ignore: cast_nullable_to_non_nullable
as int,sendButtonColor: null == sendButtonColor ? _self.sendButtonColor : sendButtonColor // ignore: cast_nullable_to_non_nullable
as int,sendButtonRadius: null == sendButtonRadius ? _self.sendButtonRadius : sendButtonRadius // ignore: cast_nullable_to_non_nullable
as double,iconColor: null == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as int,iconSize: null == iconSize ? _self.iconSize : iconSize // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
