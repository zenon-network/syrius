import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_addresses/settings_addresses.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class MockSettingsAddressesRepository extends Mock
    implements SettingsAddressesRepository {}

void main() {
  group('SettingsAddressesBloc', () {
    const String addr1 = 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
    const String addr2 = 'z1qxemdeddedxt0kenxxxxxxxxxxxxxxxxh9amk0';

    late MockSettingsAddressesRepository repository;
    late List<String> addresses;
    late Map<String, String> labels;

    setUp(() {
      repository = MockSettingsAddressesRepository();
      addresses = <String>[addr1, addr2];
      labels = <String, String>{addr1: 'Address 1', addr2: 'Address 2'};

      when(() => repository.getAddresses()).thenAnswer((_) => addresses);
      when(() => repository.getSelectedAddress()).thenReturn(addr1);
      when(
        () => repository.getAddressLabels(),
      ).thenAnswer((_) => Map<String, String>.of(labels));
      when(() => repository.saveDefaultAddress(any())).thenAnswer((_) async {});
      when(() => repository.generateNewAddresses(any())).thenAnswer((_) async {
        addresses = <String>[...addresses, 'z1new'];
        labels['z1new'] = 'Address 3';
      });
      when(
        () => repository.updateAddressLabel(
          address: any(named: 'address'),
          label: any(named: 'label'),
        ),
      ).thenAnswer((Invocation invocation) async {
        final String address = invocation.namedArguments[#address] as String;
        final String label = invocation.namedArguments[#label] as String;
        labels[address] = label;
      });
    });

    test('initial state loads addresses, selection, and labels', () {
      final SettingsAddressesBloc bloc = SettingsAddressesBloc(
        repository: repository,
      );
      addTearDown(bloc.close);

      expect(bloc.state.addresses, <String>[addr1, addr2]);
      expect(bloc.state.selectedAddress, addr1);
      expect(bloc.state.addressLabels[addr1], 'Address 1');
    });

    blocTest<SettingsAddressesBloc, SettingsAddressesState>(
      'changes default address, resets count to 1, and increments nonce',
      build: () => SettingsAddressesBloc(repository: repository),
      act: (SettingsAddressesBloc bloc) {
        bloc
          ..add(const SettingsAddressesCountChanged(count: 4))
          ..add(const SettingsAddressesDefaultChanged(address: addr2));
      },
      verify: (_) {
        verify(() => repository.saveDefaultAddress(addr2)).called(1);
      },
      expect: () => <Matcher>[
        isA<SettingsAddressesState>().having(
          (SettingsAddressesState s) => s.numberOfAddressesToAdd,
          'count',
          4,
        ),
        isA<SettingsAddressesState>()
            .having(
              (SettingsAddressesState s) => s.status,
              'status',
              SettingsAddressesStatus.loading,
            )
            .having(
              (SettingsAddressesState s) => s.numberOfAddressesToAdd,
              'count reset',
              1,
            ),
        isA<SettingsAddressesState>()
            .having(
              (SettingsAddressesState s) => s.status,
              'status',
              SettingsAddressesStatus.ready,
            )
            .having(
              (SettingsAddressesState s) => s.selectedAddress,
              'selectedAddress',
              addr2,
            )
            .having(
              (SettingsAddressesState s) => s.defaultAddressChangeNonce,
              'nonce',
              1,
            ),
      ],
    );

    blocTest<SettingsAddressesBloc, SettingsAddressesState>(
      'generates new addresses and increments scrollToEndNonce',
      build: () => SettingsAddressesBloc(repository: repository),
      act: (SettingsAddressesBloc bloc) =>
          bloc.add(const SettingsAddressesGenerateRequested(count: 2)),
      verify: (_) {
        verify(() => repository.generateNewAddresses(2)).called(1);
      },
      expect: () => <Matcher>[
        isA<SettingsAddressesState>().having(
          (SettingsAddressesState s) => s.status,
          'status',
          SettingsAddressesStatus.loading,
        ),
        isA<SettingsAddressesState>()
            .having(
              (SettingsAddressesState s) => s.addresses,
              'addresses',
              contains('z1new'),
            )
            .having(
              (SettingsAddressesState s) => s.scrollToEndNonce,
              'scrollToEndNonce',
              1,
            ),
      ],
    );

    blocTest<SettingsAddressesBloc, SettingsAddressesState>(
      'recovers to ready state and exposes generateError when generation '
      'throws',
      setUp: () {
        when(
          () => repository.generateNewAddresses(any()),
        ).thenThrow(StateError('ledger rejected'));
      },
      build: () => SettingsAddressesBloc(repository: repository),
      act: (SettingsAddressesBloc bloc) =>
          bloc.add(const SettingsAddressesGenerateRequested(count: 1)),
      expect: () => <Matcher>[
        isA<SettingsAddressesState>().having(
          (SettingsAddressesState s) => s.status,
          'status',
          SettingsAddressesStatus.loading,
        ),
        isA<SettingsAddressesState>()
            .having(
              (SettingsAddressesState s) => s.status,
              'status',
              SettingsAddressesStatus.ready,
            )
            .having(
              (SettingsAddressesState s) => s.generateErrorNonce,
              'generateErrorNonce',
              1,
            )
            .having(
              (SettingsAddressesState s) => s.generateError,
              'generateError',
              isA<StateError>(),
            ),
      ],
      errors: () => <Matcher>[isA<StateError>()],
    );

    blocTest<SettingsAddressesBloc, SettingsAddressesState>(
      'validates empty, too-long, and duplicate address labels',
      build: () => SettingsAddressesBloc(repository: repository),
      act: (SettingsAddressesBloc bloc) {
        bloc
          ..add(const SettingsAddressesLabelUpdated(address: addr1, label: ''))
          ..add(
            SettingsAddressesLabelUpdated(
              address: addr1,
              label: 'a' * (kAddressLabelMaxLength + 1),
            ),
          )
          ..add(
            const SettingsAddressesLabelUpdated(
              address: addr1,
              label: 'Address 2',
            ),
          );
      },
      verify: (_) {
        verifyNever(
          () => repository.updateAddressLabel(
            address: any(named: 'address'),
            label: any(named: 'label'),
          ),
        );
      },
      expect: () => <Matcher>[
        isA<SettingsAddressesState>().having(
          (SettingsAddressesState s) => s.labelError,
          'empty error',
          SettingsAddressLabelError.empty,
        ),
        isA<SettingsAddressesState>().having(
          (SettingsAddressesState s) => s.labelError,
          'tooLong error',
          SettingsAddressLabelError.tooLong,
        ),
        isA<SettingsAddressesState>().having(
          (SettingsAddressesState s) => s.labelError,
          'duplicate error',
          SettingsAddressLabelError.alreadyExists,
        ),
      ],
    );

    blocTest<SettingsAddressesBloc, SettingsAddressesState>(
      'persists valid address label update',
      build: () => SettingsAddressesBloc(repository: repository),
      act: (SettingsAddressesBloc bloc) => bloc.add(
        const SettingsAddressesLabelUpdated(address: addr1, label: 'Savings'),
      ),
      expect: () => <Matcher>[
        isA<SettingsAddressesState>().having(
          (SettingsAddressesState s) => s.updatingLabelAddress,
          'updatingLabelAddress',
          addr1,
        ),
        isA<SettingsAddressesState>()
            .having(
              (SettingsAddressesState s) => s.addressLabels[addr1],
              'updated label',
              'Savings',
            )
            .having(
              (SettingsAddressesState s) => s.updatingLabelAddress,
              'cleared updating',
              isNull,
            )
            .having(
              (SettingsAddressesState s) => s.labelError,
              'no error',
              isNull,
            ),
      ],
    );

    test(
      'serializes label updates so concurrent duplicate labels are rejected',
      () async {
        final Completer<void> firstWrite = Completer<void>();
        when(
          () => repository.updateAddressLabel(
            address: any(named: 'address'),
            label: any(named: 'label'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final String address = invocation.namedArguments[#address] as String;
          final String label = invocation.namedArguments[#label] as String;
          if (address == addr1) {
            await firstWrite.future;
          }
          labels[address] = label;
        });

        final SettingsAddressesBloc bloc = SettingsAddressesBloc(
          repository: repository,
        );
        addTearDown(bloc.close);

        bloc
          ..add(
            const SettingsAddressesLabelUpdated(
              address: addr1,
              label: 'Shared',
            ),
          )
          ..add(
            const SettingsAddressesLabelUpdated(
              address: addr2,
              label: 'Shared',
            ),
          );
        await Future<void>.delayed(Duration.zero);

        firstWrite.complete();
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SettingsAddressesState>().having(
              (SettingsAddressesState s) => s.labelError,
              'duplicate rejected',
              SettingsAddressLabelError.alreadyExists,
            ),
          ),
        );

        expect(labels[addr1], 'Shared');
        expect(labels[addr2], 'Address 2');
        verify(
          () => repository.updateAddressLabel(address: addr1, label: 'Shared'),
        ).called(1);
        verifyNever(
          () => repository.updateAddressLabel(address: addr2, label: 'Shared'),
        );
      },
    );
  });
}
