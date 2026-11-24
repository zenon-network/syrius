// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'p2p_swap.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
P2pSwap _$P2pSwapFromJson(
  Map<String, dynamic> json
) {
    return HtlcSwap.fromJson(
      json
    );
}

/// @nodoc
mixin _$P2pSwap {

 String get hashLock; String get initialHtlcId; int get initialHtlcExpirationTime; int get hashType; String get id; int get chainId; P2pSwapType get type; P2pSwapDirection get direction; String get selfAddress; String get counterpartyAddress; BigInt get fromAmount; Token get fromToken; P2pSwapChain get fromChain; P2pSwapChain get toChain; int get startTime; P2pSwapState get state; P2pSwapMode get mode; BigInt? get toAmount; Token? get toToken; String? get counterHtlcId; int? get counterHtlcExpirationTime; String? get preimage;
/// Create a copy of P2pSwap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$P2pSwapCopyWith<P2pSwap> get copyWith => _$P2pSwapCopyWithImpl<P2pSwap>(this as P2pSwap, _$identity);

  /// Serializes this P2pSwap to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is P2pSwap&&(identical(other.hashLock, hashLock) || other.hashLock == hashLock)&&(identical(other.initialHtlcId, initialHtlcId) || other.initialHtlcId == initialHtlcId)&&(identical(other.initialHtlcExpirationTime, initialHtlcExpirationTime) || other.initialHtlcExpirationTime == initialHtlcExpirationTime)&&(identical(other.hashType, hashType) || other.hashType == hashType)&&(identical(other.id, id) || other.id == id)&&(identical(other.chainId, chainId) || other.chainId == chainId)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.selfAddress, selfAddress) || other.selfAddress == selfAddress)&&(identical(other.counterpartyAddress, counterpartyAddress) || other.counterpartyAddress == counterpartyAddress)&&(identical(other.fromAmount, fromAmount) || other.fromAmount == fromAmount)&&(identical(other.fromToken, fromToken) || other.fromToken == fromToken)&&(identical(other.fromChain, fromChain) || other.fromChain == fromChain)&&(identical(other.toChain, toChain) || other.toChain == toChain)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.state, state) || other.state == state)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.toAmount, toAmount) || other.toAmount == toAmount)&&(identical(other.toToken, toToken) || other.toToken == toToken)&&(identical(other.counterHtlcId, counterHtlcId) || other.counterHtlcId == counterHtlcId)&&(identical(other.counterHtlcExpirationTime, counterHtlcExpirationTime) || other.counterHtlcExpirationTime == counterHtlcExpirationTime)&&(identical(other.preimage, preimage) || other.preimage == preimage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,hashLock,initialHtlcId,initialHtlcExpirationTime,hashType,id,chainId,type,direction,selfAddress,counterpartyAddress,fromAmount,fromToken,fromChain,toChain,startTime,state,mode,toAmount,toToken,counterHtlcId,counterHtlcExpirationTime,preimage]);

@override
String toString() {
  return 'P2pSwap(hashLock: $hashLock, initialHtlcId: $initialHtlcId, initialHtlcExpirationTime: $initialHtlcExpirationTime, hashType: $hashType, id: $id, chainId: $chainId, type: $type, direction: $direction, selfAddress: $selfAddress, counterpartyAddress: $counterpartyAddress, fromAmount: $fromAmount, fromToken: $fromToken, fromChain: $fromChain, toChain: $toChain, startTime: $startTime, state: $state, mode: $mode, toAmount: $toAmount, toToken: $toToken, counterHtlcId: $counterHtlcId, counterHtlcExpirationTime: $counterHtlcExpirationTime, preimage: $preimage)';
}


}

/// @nodoc
abstract mixin class $P2pSwapCopyWith<$Res>  {
  factory $P2pSwapCopyWith(P2pSwap value, $Res Function(P2pSwap) _then) = _$P2pSwapCopyWithImpl;
@useResult
$Res call({
 String hashLock, String initialHtlcId, int initialHtlcExpirationTime, int hashType, String id, int chainId, P2pSwapType type, P2pSwapDirection direction, String selfAddress, String counterpartyAddress, BigInt fromAmount, Token fromToken, P2pSwapChain fromChain, P2pSwapChain toChain, int startTime, P2pSwapState state, P2pSwapMode mode, BigInt? toAmount, Token? toToken, String? counterHtlcId, int? counterHtlcExpirationTime, String? preimage
});




}
/// @nodoc
class _$P2pSwapCopyWithImpl<$Res>
    implements $P2pSwapCopyWith<$Res> {
  _$P2pSwapCopyWithImpl(this._self, this._then);

  final P2pSwap _self;
  final $Res Function(P2pSwap) _then;

/// Create a copy of P2pSwap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hashLock = null,Object? initialHtlcId = null,Object? initialHtlcExpirationTime = null,Object? hashType = null,Object? id = null,Object? chainId = null,Object? type = null,Object? direction = null,Object? selfAddress = null,Object? counterpartyAddress = null,Object? fromAmount = null,Object? fromToken = null,Object? fromChain = null,Object? toChain = null,Object? startTime = null,Object? state = null,Object? mode = null,Object? toAmount = freezed,Object? toToken = freezed,Object? counterHtlcId = freezed,Object? counterHtlcExpirationTime = freezed,Object? preimage = freezed,}) {
  return _then(_self.copyWith(
hashLock: null == hashLock ? _self.hashLock : hashLock // ignore: cast_nullable_to_non_nullable
as String,initialHtlcId: null == initialHtlcId ? _self.initialHtlcId : initialHtlcId // ignore: cast_nullable_to_non_nullable
as String,initialHtlcExpirationTime: null == initialHtlcExpirationTime ? _self.initialHtlcExpirationTime : initialHtlcExpirationTime // ignore: cast_nullable_to_non_nullable
as int,hashType: null == hashType ? _self.hashType : hashType // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,chainId: null == chainId ? _self.chainId : chainId // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as P2pSwapType,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as P2pSwapDirection,selfAddress: null == selfAddress ? _self.selfAddress : selfAddress // ignore: cast_nullable_to_non_nullable
as String,counterpartyAddress: null == counterpartyAddress ? _self.counterpartyAddress : counterpartyAddress // ignore: cast_nullable_to_non_nullable
as String,fromAmount: null == fromAmount ? _self.fromAmount : fromAmount // ignore: cast_nullable_to_non_nullable
as BigInt,fromToken: null == fromToken ? _self.fromToken : fromToken // ignore: cast_nullable_to_non_nullable
as Token,fromChain: null == fromChain ? _self.fromChain : fromChain // ignore: cast_nullable_to_non_nullable
as P2pSwapChain,toChain: null == toChain ? _self.toChain : toChain // ignore: cast_nullable_to_non_nullable
as P2pSwapChain,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as P2pSwapState,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as P2pSwapMode,toAmount: freezed == toAmount ? _self.toAmount : toAmount // ignore: cast_nullable_to_non_nullable
as BigInt?,toToken: freezed == toToken ? _self.toToken : toToken // ignore: cast_nullable_to_non_nullable
as Token?,counterHtlcId: freezed == counterHtlcId ? _self.counterHtlcId : counterHtlcId // ignore: cast_nullable_to_non_nullable
as String?,counterHtlcExpirationTime: freezed == counterHtlcExpirationTime ? _self.counterHtlcExpirationTime : counterHtlcExpirationTime // ignore: cast_nullable_to_non_nullable
as int?,preimage: freezed == preimage ? _self.preimage : preimage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [P2pSwap].
extension P2pSwapPatterns on P2pSwap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HtlcSwap value)?  htlc,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HtlcSwap() when htlc != null:
return htlc(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HtlcSwap value)  htlc,}){
final _that = this;
switch (_that) {
case HtlcSwap():
return htlc(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HtlcSwap value)?  htlc,}){
final _that = this;
switch (_that) {
case HtlcSwap() when htlc != null:
return htlc(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String hashLock,  String initialHtlcId,  int initialHtlcExpirationTime,  int hashType,  String id,  int chainId,  P2pSwapType type,  P2pSwapDirection direction,  String selfAddress,  String counterpartyAddress,  BigInt fromAmount,  Token fromToken,  P2pSwapChain fromChain,  P2pSwapChain toChain,  int startTime,  P2pSwapState state,  P2pSwapMode mode,  BigInt? toAmount,  Token? toToken,  String? counterHtlcId,  int? counterHtlcExpirationTime,  String? preimage)?  htlc,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HtlcSwap() when htlc != null:
return htlc(_that.hashLock,_that.initialHtlcId,_that.initialHtlcExpirationTime,_that.hashType,_that.id,_that.chainId,_that.type,_that.direction,_that.selfAddress,_that.counterpartyAddress,_that.fromAmount,_that.fromToken,_that.fromChain,_that.toChain,_that.startTime,_that.state,_that.mode,_that.toAmount,_that.toToken,_that.counterHtlcId,_that.counterHtlcExpirationTime,_that.preimage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String hashLock,  String initialHtlcId,  int initialHtlcExpirationTime,  int hashType,  String id,  int chainId,  P2pSwapType type,  P2pSwapDirection direction,  String selfAddress,  String counterpartyAddress,  BigInt fromAmount,  Token fromToken,  P2pSwapChain fromChain,  P2pSwapChain toChain,  int startTime,  P2pSwapState state,  P2pSwapMode mode,  BigInt? toAmount,  Token? toToken,  String? counterHtlcId,  int? counterHtlcExpirationTime,  String? preimage)  htlc,}) {final _that = this;
switch (_that) {
case HtlcSwap():
return htlc(_that.hashLock,_that.initialHtlcId,_that.initialHtlcExpirationTime,_that.hashType,_that.id,_that.chainId,_that.type,_that.direction,_that.selfAddress,_that.counterpartyAddress,_that.fromAmount,_that.fromToken,_that.fromChain,_that.toChain,_that.startTime,_that.state,_that.mode,_that.toAmount,_that.toToken,_that.counterHtlcId,_that.counterHtlcExpirationTime,_that.preimage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String hashLock,  String initialHtlcId,  int initialHtlcExpirationTime,  int hashType,  String id,  int chainId,  P2pSwapType type,  P2pSwapDirection direction,  String selfAddress,  String counterpartyAddress,  BigInt fromAmount,  Token fromToken,  P2pSwapChain fromChain,  P2pSwapChain toChain,  int startTime,  P2pSwapState state,  P2pSwapMode mode,  BigInt? toAmount,  Token? toToken,  String? counterHtlcId,  int? counterHtlcExpirationTime,  String? preimage)?  htlc,}) {final _that = this;
switch (_that) {
case HtlcSwap() when htlc != null:
return htlc(_that.hashLock,_that.initialHtlcId,_that.initialHtlcExpirationTime,_that.hashType,_that.id,_that.chainId,_that.type,_that.direction,_that.selfAddress,_that.counterpartyAddress,_that.fromAmount,_that.fromToken,_that.fromChain,_that.toChain,_that.startTime,_that.state,_that.mode,_that.toAmount,_that.toToken,_that.counterHtlcId,_that.counterHtlcExpirationTime,_that.preimage);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class HtlcSwap extends P2pSwap {
  const HtlcSwap({required this.hashLock, required this.initialHtlcId, required this.initialHtlcExpirationTime, required this.hashType, required this.id, required this.chainId, required this.type, required this.direction, required this.selfAddress, required this.counterpartyAddress, required this.fromAmount, required this.fromToken, required this.fromChain, required this.toChain, required this.startTime, required this.state, this.mode = P2pSwapMode.htlc, this.toAmount, this.toToken, this.counterHtlcId, this.counterHtlcExpirationTime, this.preimage}): super._();
  factory HtlcSwap.fromJson(Map<String, dynamic> json) => _$HtlcSwapFromJson(json);

@override final  String hashLock;
@override final  String initialHtlcId;
@override final  int initialHtlcExpirationTime;
@override final  int hashType;
@override final  String id;
@override final  int chainId;
@override final  P2pSwapType type;
@override final  P2pSwapDirection direction;
@override final  String selfAddress;
@override final  String counterpartyAddress;
@override final  BigInt fromAmount;
@override final  Token fromToken;
@override final  P2pSwapChain fromChain;
@override final  P2pSwapChain toChain;
@override final  int startTime;
@override final  P2pSwapState state;
@override@JsonKey() final  P2pSwapMode mode;
@override final  BigInt? toAmount;
@override final  Token? toToken;
@override final  String? counterHtlcId;
@override final  int? counterHtlcExpirationTime;
@override final  String? preimage;

/// Create a copy of P2pSwap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HtlcSwapCopyWith<HtlcSwap> get copyWith => _$HtlcSwapCopyWithImpl<HtlcSwap>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HtlcSwapToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HtlcSwap&&(identical(other.hashLock, hashLock) || other.hashLock == hashLock)&&(identical(other.initialHtlcId, initialHtlcId) || other.initialHtlcId == initialHtlcId)&&(identical(other.initialHtlcExpirationTime, initialHtlcExpirationTime) || other.initialHtlcExpirationTime == initialHtlcExpirationTime)&&(identical(other.hashType, hashType) || other.hashType == hashType)&&(identical(other.id, id) || other.id == id)&&(identical(other.chainId, chainId) || other.chainId == chainId)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.selfAddress, selfAddress) || other.selfAddress == selfAddress)&&(identical(other.counterpartyAddress, counterpartyAddress) || other.counterpartyAddress == counterpartyAddress)&&(identical(other.fromAmount, fromAmount) || other.fromAmount == fromAmount)&&(identical(other.fromToken, fromToken) || other.fromToken == fromToken)&&(identical(other.fromChain, fromChain) || other.fromChain == fromChain)&&(identical(other.toChain, toChain) || other.toChain == toChain)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.state, state) || other.state == state)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.toAmount, toAmount) || other.toAmount == toAmount)&&(identical(other.toToken, toToken) || other.toToken == toToken)&&(identical(other.counterHtlcId, counterHtlcId) || other.counterHtlcId == counterHtlcId)&&(identical(other.counterHtlcExpirationTime, counterHtlcExpirationTime) || other.counterHtlcExpirationTime == counterHtlcExpirationTime)&&(identical(other.preimage, preimage) || other.preimage == preimage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,hashLock,initialHtlcId,initialHtlcExpirationTime,hashType,id,chainId,type,direction,selfAddress,counterpartyAddress,fromAmount,fromToken,fromChain,toChain,startTime,state,mode,toAmount,toToken,counterHtlcId,counterHtlcExpirationTime,preimage]);

@override
String toString() {
  return 'P2pSwap.htlc(hashLock: $hashLock, initialHtlcId: $initialHtlcId, initialHtlcExpirationTime: $initialHtlcExpirationTime, hashType: $hashType, id: $id, chainId: $chainId, type: $type, direction: $direction, selfAddress: $selfAddress, counterpartyAddress: $counterpartyAddress, fromAmount: $fromAmount, fromToken: $fromToken, fromChain: $fromChain, toChain: $toChain, startTime: $startTime, state: $state, mode: $mode, toAmount: $toAmount, toToken: $toToken, counterHtlcId: $counterHtlcId, counterHtlcExpirationTime: $counterHtlcExpirationTime, preimage: $preimage)';
}


}

/// @nodoc
abstract mixin class $HtlcSwapCopyWith<$Res> implements $P2pSwapCopyWith<$Res> {
  factory $HtlcSwapCopyWith(HtlcSwap value, $Res Function(HtlcSwap) _then) = _$HtlcSwapCopyWithImpl;
@override @useResult
$Res call({
 String hashLock, String initialHtlcId, int initialHtlcExpirationTime, int hashType, String id, int chainId, P2pSwapType type, P2pSwapDirection direction, String selfAddress, String counterpartyAddress, BigInt fromAmount, Token fromToken, P2pSwapChain fromChain, P2pSwapChain toChain, int startTime, P2pSwapState state, P2pSwapMode mode, BigInt? toAmount, Token? toToken, String? counterHtlcId, int? counterHtlcExpirationTime, String? preimage
});




}
/// @nodoc
class _$HtlcSwapCopyWithImpl<$Res>
    implements $HtlcSwapCopyWith<$Res> {
  _$HtlcSwapCopyWithImpl(this._self, this._then);

  final HtlcSwap _self;
  final $Res Function(HtlcSwap) _then;

/// Create a copy of P2pSwap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hashLock = null,Object? initialHtlcId = null,Object? initialHtlcExpirationTime = null,Object? hashType = null,Object? id = null,Object? chainId = null,Object? type = null,Object? direction = null,Object? selfAddress = null,Object? counterpartyAddress = null,Object? fromAmount = null,Object? fromToken = null,Object? fromChain = null,Object? toChain = null,Object? startTime = null,Object? state = null,Object? mode = null,Object? toAmount = freezed,Object? toToken = freezed,Object? counterHtlcId = freezed,Object? counterHtlcExpirationTime = freezed,Object? preimage = freezed,}) {
  return _then(HtlcSwap(
hashLock: null == hashLock ? _self.hashLock : hashLock // ignore: cast_nullable_to_non_nullable
as String,initialHtlcId: null == initialHtlcId ? _self.initialHtlcId : initialHtlcId // ignore: cast_nullable_to_non_nullable
as String,initialHtlcExpirationTime: null == initialHtlcExpirationTime ? _self.initialHtlcExpirationTime : initialHtlcExpirationTime // ignore: cast_nullable_to_non_nullable
as int,hashType: null == hashType ? _self.hashType : hashType // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,chainId: null == chainId ? _self.chainId : chainId // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as P2pSwapType,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as P2pSwapDirection,selfAddress: null == selfAddress ? _self.selfAddress : selfAddress // ignore: cast_nullable_to_non_nullable
as String,counterpartyAddress: null == counterpartyAddress ? _self.counterpartyAddress : counterpartyAddress // ignore: cast_nullable_to_non_nullable
as String,fromAmount: null == fromAmount ? _self.fromAmount : fromAmount // ignore: cast_nullable_to_non_nullable
as BigInt,fromToken: null == fromToken ? _self.fromToken : fromToken // ignore: cast_nullable_to_non_nullable
as Token,fromChain: null == fromChain ? _self.fromChain : fromChain // ignore: cast_nullable_to_non_nullable
as P2pSwapChain,toChain: null == toChain ? _self.toChain : toChain // ignore: cast_nullable_to_non_nullable
as P2pSwapChain,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as P2pSwapState,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as P2pSwapMode,toAmount: freezed == toAmount ? _self.toAmount : toAmount // ignore: cast_nullable_to_non_nullable
as BigInt?,toToken: freezed == toToken ? _self.toToken : toToken // ignore: cast_nullable_to_non_nullable
as Token?,counterHtlcId: freezed == counterHtlcId ? _self.counterHtlcId : counterHtlcId // ignore: cast_nullable_to_non_nullable
as String?,counterHtlcExpirationTime: freezed == counterHtlcExpirationTime ? _self.counterHtlcExpirationTime : counterHtlcExpirationTime // ignore: cast_nullable_to_non_nullable
as int?,preimage: freezed == preimage ? _self.preimage : preimage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
