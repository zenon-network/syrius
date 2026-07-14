import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/fetch_bloc/fetch_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class FakeAddress extends Fake implements Address {}

@immutable
class TestData {
  const TestData({required this.value});

  factory TestData.fromJson(Map<String, dynamic> json) =>
      TestData(value: json['value'] as String);

  final String value;

  Map<String, dynamic> toJson() => <String, dynamic>{'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TestData && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class TestFetchBloc extends FetchBloc<TestData> {
  TestFetchBloc({
    required super.zenon,
    required this.getDataCallback,
  }) : super(
         fromJsonT: TestData.fromJson,
         toJsonT: (TestData data) => data.toJson(),
       );

  final Future<TestData> Function(Address address) getDataCallback;

  @override
  Future<TestData> getData({required Address address}) =>
      getDataCallback(address);
}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('FetchBloc', () {
    late MockZenon mockZenon;
    late TestData testData;
    late SyriusException syriusException;

    setUp(() {
      mockZenon = MockZenon();
      testData = const TestData(value: 'ok');
      syriusException = FailureException();
    });

    test('initial state is FetchInitial', () {
      final TestFetchBloc bloc = TestFetchBloc(
        zenon: mockZenon,
        getDataCallback: (Address address) async => testData,
      );
      expect(bloc.state, const FetchInitial<TestData>());
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        final TestFetchBloc bloc = TestFetchBloc(
          zenon: mockZenon,
          getDataCallback: (Address address) async => testData,
        );

        const FetchInitial<TestData> initialState = FetchInitial<TestData>();
        final Map<String, dynamic>? serialized = bloc.toJson(initialState);
        final FetchState<TestData> deserialized = bloc.fromJson(serialized!);
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize populated state', () {
        final TestFetchBloc bloc = TestFetchBloc(
          zenon: mockZenon,
          getDataCallback: (Address address) async => testData,
        );

        final FetchPopulated<TestData> successState = FetchPopulated<TestData>(
          data: testData,
        );
        final Map<String, dynamic>? serialized = bloc.toJson(successState);
        final FetchState<TestData> deserialized = bloc.fromJson(serialized!);
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final TestFetchBloc bloc = TestFetchBloc(
          zenon: mockZenon,
          getDataCallback: (Address address) async => testData,
        );

        final FetchFailure<TestData> failureState = FetchFailure<TestData>(
          exception: syriusException,
        );
        final Map<String, dynamic>? serialized = bloc.toJson(failureState);
        final FetchState<TestData> deserialized = bloc.fromJson(serialized!);
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<TestFetchBloc, FetchState<TestData>>(
      'emits FetchPopulated when getData succeeds',
      build: () => TestFetchBloc(
        zenon: mockZenon,
        getDataCallback: (Address address) async => testData,
      ),
      act: (TestFetchBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<TestData>>[
        FetchPopulated<TestData>(data: testData),
      ],
    );

    blocTest<TestFetchBloc, FetchState<TestData>>(
      'emits FetchFailure with same SyriusException when getData throws it',
      build: () => TestFetchBloc(
        zenon: mockZenon,
        getDataCallback: (Address address) async => throw syriusException,
      ),
      act: (TestFetchBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<TestData>>[
        FetchFailure<TestData>(exception: syriusException),
      ],
    );

    blocTest<TestFetchBloc, FetchState<TestData>>(
      'emits FetchFailure(FailureException) when getData throws Exception',
      build: () => TestFetchBloc(
        zenon: mockZenon,
        getDataCallback: (Address address) async => throw Exception('boom'),
      ),
      act: (TestFetchBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<FetchFailure<TestData>>().having(
          (FetchFailure<TestData> state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
