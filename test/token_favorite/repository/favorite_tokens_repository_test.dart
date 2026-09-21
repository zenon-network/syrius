import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  group('HiveFavoriteTokensRepository', () {
    late MockBox favoriteTokensBox;
    late HiveFavoriteTokensRepository repository;

    setUp(() {
      favoriteTokensBox = MockBox();
      when(() => favoriteTokensBox.values).thenReturn(<dynamic>[]);
      repository = HiveFavoriteTokensRepository(
        favoriteTokensBox: favoriteTokensBox,
      );
    });

    test('adds a token standard', () async {
      when(
        () => favoriteTokensBox.add(znnZts.toString()),
      ).thenAnswer((_) async => 0);

      await repository.add(znnZts);

      verify(() => favoriteTokensBox.add(znnZts.toString())).called(1);
    });

    test('does not add a duplicate token standard', () async {
      when(
        () => favoriteTokensBox.values,
      ).thenReturn(<dynamic>[znnZts.toString()]);

      await repository.add(znnZts);

      verifyNever(() => favoriteTokensBox.add(any()));
    });

    test('wraps an add failure', () async {
      final Exception cause = Exception('add failed');
      when(
        () => favoriteTokensBox.add(znnZts.toString()),
      ).thenThrow(cause);

      await expectLater(
        repository.add(znnZts),
        throwsA(
          isA<AddingToFavoriteTokensException>().having(
            (AddingToFavoriteTokensException exception) => exception.cause,
            'cause',
            same(cause),
          ),
        ),
      );
    });

    test('removes a token standard', () async {
      when(
        () => favoriteTokensBox.values,
      ).thenReturn(<dynamic>[znnZts.toString()]);
      when(() => favoriteTokensBox.deleteAt(0)).thenAnswer((_) async {});

      await repository.remove(znnZts);

      verify(() => favoriteTokensBox.deleteAt(0)).called(1);
    });

    test('does not remove a missing token standard', () async {
      await repository.remove(znnZts);

      verifyNever(() => favoriteTokensBox.deleteAt(any()));
    });

    test('wraps a remove failure', () async {
      final Exception cause = Exception('remove failed');
      when(
        () => favoriteTokensBox.values,
      ).thenReturn(<dynamic>[znnZts.toString()]);
      when(() => favoriteTokensBox.deleteAt(0)).thenThrow(cause);

      await expectLater(
        repository.remove(znnZts),
        throwsA(
          isA<RemovingFromFavoriteTokensException>().having(
            (RemovingFromFavoriteTokensException exception) => exception.cause,
            'cause',
            same(cause),
          ),
        ),
      );
    });
  });
}
