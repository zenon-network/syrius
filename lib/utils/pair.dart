import 'package:equatable/equatable.dart';

class Pair<T1, T2> extends Equatable{
  /// Creates a [Pair] instance
  Pair(this.first, this.second);

  /// Constructor to specify deserialization methods for generic types
  factory Pair.fromJson(
      Map<String, dynamic> json,
      T1 Function(Object? json) fromJsonT1,
      T2 Function(Object? json) fromJsonT2,
      ) =>
      Pair(
        fromJsonT1(json['first']),
        fromJsonT2(json['second']),
      );

  final T1 first;
  final T2 second;

  @override
  List<Object?> get props => [first, second];

  /// A function to serialize generic types
  Map<String, dynamic> toJson(
      Object? Function(T1 value) toJsonT1,
      Object? Function(T2 value) toJsonT2,
      ) =>
      <String, dynamic>{
        'first': toJsonT1(first),
        'second': toJsonT2(second),
      };
}
