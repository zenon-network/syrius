import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

class _MockPillarApi extends Mock implements PillarApi {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

Address _address(int seed) => Address.fromPublicKey(List<int>.filled(32, seed));

PillarInfo _pillar(String name, Address owner, Address producer) =>
    PillarInfo.fromJson(<String, dynamic>{
      'name': name,
      'rank': 1,
      'type': PillarInfo.regularPillarType,
      'ownerAddress': owner.toString(),
      'producerAddress': producer.toString(),
      'withdrawAddress': owner.toString(),
      'giveMomentumRewardPercentage': 0,
      'giveDelegateRewardPercentage': 100,
      'isRevocable': false,
      'revokeCooldown': 0,
      'revokeTimestamp': 0,
      'currentStats': const <String, dynamic>{
        'producedMomentums': 0,
        'expectedMomentums': 0,
      },
      'weight': '0',
    });

PillarVote _pillarVote(Hash id, String name, AcceleratorProjectVote vote) =>
    PillarVote.fromJson(<String, dynamic>{
      'id': id.toString(),
      'name': name,
      'vote': vote.index,
    });

void main() {
  final Hash targetId = Hash.digest(List<int>.filled(32, 9));
  final Address owner = _address(1);
  final Address producer = _address(2);
  final Address stranger = _address(3);

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyAddress);
    registerFallbackValue(targetId);
  });

  group('VoteProjectBloc', () {
    late _MockZenon zenon;
    late _MockEmbeddedApi embedded;
    late _MockAcceleratorApi acceleratorApi;
    late _MockPillarApi pillarApi;
    late _MockAccountBlockUtils accountBlockUtils;
    late _MockAccountBlockTemplate txTemplate;
    late _MockAccountBlockTemplate signedBlock;

    setUp(() {
      zenon = _MockZenon();
      embedded = _MockEmbeddedApi();
      acceleratorApi = _MockAcceleratorApi();
      pillarApi = _MockPillarApi();
      accountBlockUtils = _MockAccountBlockUtils();
      txTemplate = _MockAccountBlockTemplate();
      signedBlock = _MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.accelerator).thenReturn(acceleratorApi);
      when(() => embedded.pillar).thenReturn(pillarApi);
    });

    test('initial state is VoteProjectInitial', () async {
      final VoteProjectBloc bloc = VoteProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
      );
      expect(bloc.state, const VoteProjectInitial());
      await bloc.close();
    });

    blocTest<VoteProjectBloc, VoteProjectState>(
      'owner address dispatches voteByName, pins signing address, and waits '
      'for on-chain vote confirmation',
      setUp: () {
        when(() => pillarApi.getByOwner(owner)).thenAnswer(
          (_) async => <PillarInfo>[_pillar('alpha', owner, producer)],
        );
        when(
          () => acceleratorApi.voteByName(
            targetId,
            'alpha',
            AcceleratorProjectVote.yes.index,
          ),
        ).thenReturn(txTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            txTemplate,
            'vote for project',
            address: owner,
          ),
        ).thenAnswer((_) async => signedBlock);
        when(
          () => acceleratorApi.getPillarVotes('alpha', <String>[
            targetId.toString(),
          ]),
        ).thenAnswer(
          (_) async => <PillarVote?>[
            _pillarVote(targetId, 'alpha', AcceleratorProjectVote.yes),
          ],
        );
      },
      build: () => VoteProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        pollInterval: const Duration(milliseconds: 5),
        confirmationTimeout: const Duration(milliseconds: 200),
      ),
      act: (VoteProjectBloc bloc) => bloc.add(
        VoteProjectRequested(
          address: owner,
          id: targetId,
          vote: AcceleratorProjectVote.yes,
        ),
      ),
      expect: () => <VoteProjectState>[
        const VoteProjectLoading(),
        VoteProjectDone(accountBlock: signedBlock),
      ],
      verify: (_) {
        verify(
          () => acceleratorApi.voteByName(
            targetId,
            'alpha',
            AcceleratorProjectVote.yes.index,
          ),
        ).called(1);
        verifyNever(() => acceleratorApi.voteByProdAddress(any(), any()));
        verify(
          () => accountBlockUtils.createAccountBlock(
            txTemplate,
            'vote for project',
            address: owner,
          ),
        ).called(1);
        verify(
          () => acceleratorApi.getPillarVotes('alpha', <String>[
            targetId.toString(),
          ]),
        ).called(1);
      },
    );

    blocTest<VoteProjectBloc, VoteProjectState>(
      'producer address falls back to pillar.getAll, dispatches '
      'voteByProdAddress, and polls until confirmation',
      setUp: () {
        final PillarInfo alpha = _pillar('alpha', owner, producer);
        when(
          () => pillarApi.getByOwner(producer),
        ).thenAnswer((_) async => <PillarInfo>[]);
        when(() => pillarApi.getAll(pageSize: 10)).thenAnswer(
          (_) async => PillarInfoList.fromJson(<String, dynamic>{
            'count': 1,
            'list': <Map<String, dynamic>>[alpha.toJson()],
          }),
        );
        when(
          () => acceleratorApi.voteByProdAddress(
            targetId,
            AcceleratorProjectVote.no.index,
          ),
        ).thenReturn(txTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            txTemplate,
            'vote for project',
            address: producer,
          ),
        ).thenAnswer((_) async => signedBlock);

        int pollCount = 0;
        when(
          () => acceleratorApi.getPillarVotes('alpha', <String>[
            targetId.toString(),
          ]),
        ).thenAnswer((_) async {
          pollCount++;
          if (pollCount == 1) {
            return const <PillarVote?>[null];
          }
          if (pollCount == 2) {
            return <PillarVote?>[
              _pillarVote(targetId, 'alpha', AcceleratorProjectVote.yes),
            ];
          }
          return <PillarVote?>[
            _pillarVote(targetId, 'alpha', AcceleratorProjectVote.no),
          ];
        });
      },
      build: () => VoteProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        pageSize: 10,
        pollInterval: const Duration(milliseconds: 5),
        confirmationTimeout: const Duration(milliseconds: 300),
      ),
      act: (VoteProjectBloc bloc) => bloc.add(
        VoteProjectRequested(
          address: producer,
          id: targetId,
          vote: AcceleratorProjectVote.no,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => <VoteProjectState>[
        const VoteProjectLoading(),
        VoteProjectDone(accountBlock: signedBlock),
      ],
      verify: (_) {
        verify(
          () => acceleratorApi.voteByProdAddress(
            targetId,
            AcceleratorProjectVote.no.index,
          ),
        ).called(1);
        verifyNever(() => acceleratorApi.voteByName(any(), any(), any()));
        verify(
          () => accountBlockUtils.createAccountBlock(
            txTemplate,
            'vote for project',
            address: producer,
          ),
        ).called(1);
        verify(
          () => acceleratorApi.getPillarVotes('alpha', <String>[
            targetId.toString(),
          ]),
        ).called(3);
      },
    );

    blocTest<VoteProjectBloc, VoteProjectState>(
      'tolerates transient RPC errors while polling and emits VoteProjectDone '
      'once confirmed',
      setUp: () {
        when(() => pillarApi.getByOwner(owner)).thenAnswer(
          (_) async => <PillarInfo>[_pillar('alpha', owner, producer)],
        );
        when(
          () => acceleratorApi.voteByName(
            targetId,
            'alpha',
            AcceleratorProjectVote.abstain.index,
          ),
        ).thenReturn(txTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            txTemplate,
            'vote for project',
            address: owner,
          ),
        ).thenAnswer((_) async => signedBlock);

        int attempt = 0;
        when(
          () => acceleratorApi.getPillarVotes('alpha', <String>[
            targetId.toString(),
          ]),
        ).thenAnswer((_) async {
          attempt++;
          if (attempt == 1) {
            throw Exception('transient RPC hiccup');
          }
          return <PillarVote?>[
            _pillarVote(targetId, 'alpha', AcceleratorProjectVote.abstain),
          ];
        });
      },
      build: () => VoteProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        pollInterval: const Duration(milliseconds: 5),
        confirmationTimeout: const Duration(milliseconds: 300),
      ),
      act: (VoteProjectBloc bloc) => bloc.add(
        VoteProjectRequested(
          address: owner,
          id: targetId,
          vote: AcceleratorProjectVote.abstain,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => <VoteProjectState>[
        const VoteProjectLoading(),
        VoteProjectDone(accountBlock: signedBlock),
      ],
      verify: (_) {
        verify(
          () => acceleratorApi.getPillarVotes('alpha', <String>[
            targetId.toString(),
          ]),
        ).called(2);
      },
    );

    blocTest<VoteProjectBloc, VoteProjectState>(
      'falls back to emitting VoteProjectDone when confirmation polling times '
      'out',
      setUp: () {
        when(() => pillarApi.getByOwner(owner)).thenAnswer(
          (_) async => <PillarInfo>[_pillar('alpha', owner, producer)],
        );
        when(
          () => acceleratorApi.voteByName(
            targetId,
            'alpha',
            AcceleratorProjectVote.yes.index,
          ),
        ).thenReturn(txTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            txTemplate,
            'vote for project',
            address: owner,
          ),
        ).thenAnswer((_) async => signedBlock);
        when(
          () => acceleratorApi.getPillarVotes('alpha', <String>[
            targetId.toString(),
          ]),
        ).thenAnswer((_) async => const <PillarVote?>[null]);
      },
      build: () => VoteProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        pollInterval: const Duration(milliseconds: 5),
        confirmationTimeout: const Duration(milliseconds: 25),
      ),
      act: (VoteProjectBloc bloc) => bloc.add(
        VoteProjectRequested(
          address: owner,
          id: targetId,
          vote: AcceleratorProjectVote.yes,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => <VoteProjectState>[
        const VoteProjectLoading(),
        VoteProjectDone(accountBlock: signedBlock),
      ],
    );

    test(
      'stops polling cleanly when closed while waiting for confirmation',
      () async {
      final Completer<List<PillarVote?>> firstPollStarted =
          Completer<List<PillarVote?>>();
      when(() => pillarApi.getByOwner(owner)).thenAnswer(
        (_) async => <PillarInfo>[_pillar('alpha', owner, producer)],
      );
      when(
        () => acceleratorApi.voteByName(
          targetId,
          'alpha',
          AcceleratorProjectVote.yes.index,
        ),
      ).thenReturn(txTemplate);
      when(
        () => accountBlockUtils.createAccountBlock(
          txTemplate,
          'vote for project',
          address: owner,
        ),
      ).thenAnswer((_) async => signedBlock);
      when(
        () => acceleratorApi.getPillarVotes('alpha', <String>[
          targetId.toString(),
        ]),
      ).thenAnswer((_) => firstPollStarted.future);

      final VoteProjectBloc bloc = VoteProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        pollInterval: const Duration(milliseconds: 5),
        confirmationTimeout: const Duration(seconds: 5),
      );
      final List<VoteProjectState> emitted = <VoteProjectState>[];
      final StreamSubscription<VoteProjectState> sub = bloc.stream.listen(
        emitted.add,
      );
      addTearDown(sub.cancel);

      bloc.add(
        VoteProjectRequested(
          address: owner,
          id: targetId,
          vote: AcceleratorProjectVote.yes,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(emitted, equals(<VoteProjectState>[const VoteProjectLoading()]));

      final Future<void> closeFuture = bloc.close();
      firstPollStarted.complete(const <PillarVote?>[null]);
      await closeFuture;

      expect(emitted, equals(<VoteProjectState>[const VoteProjectLoading()]));
    });

    blocTest<VoteProjectBloc, VoteProjectState>(
      'emits graceful NoPillarForAddressException when address has no pillar '
      'role',
      setUp: () {
        final PillarInfo alpha = _pillar('alpha', owner, producer);
        when(
          () => pillarApi.getByOwner(stranger),
        ).thenAnswer((_) async => <PillarInfo>[]);
        when(() => pillarApi.getAll(pageSize: 10)).thenAnswer(
          (_) async => PillarInfoList.fromJson(<String, dynamic>{
            'count': 1,
            'list': <Map<String, dynamic>>[alpha.toJson()],
          }),
        );
      },
      build: () => VoteProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        pageSize: 10,
      ),
      act: (VoteProjectBloc bloc) => bloc.add(
        VoteProjectRequested(
          address: stranger,
          id: targetId,
          vote: AcceleratorProjectVote.abstain,
        ),
      ),
      expect: () => <VoteProjectState>[
        const VoteProjectLoading(),
        VoteProjectFailure(exception: NoPillarForAddressException()),
      ],
      verify: (_) {
        verifyNever(
          () => accountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
          ),
        );
      },
    );

    blocTest<VoteProjectBloc, VoteProjectState>(
      'emits failure when signing fails without polling',
      setUp: () {
        when(() => pillarApi.getByOwner(owner)).thenAnswer(
          (_) async => <PillarInfo>[_pillar('alpha', owner, producer)],
        );
        when(
          () => acceleratorApi.voteByName(
            targetId,
            'alpha',
            AcceleratorProjectVote.yes.index,
          ),
        ).thenReturn(txTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
          ),
        ).thenThrow(Exception('wallet closed'));
      },
      build: () =>
          VoteProjectBloc(accountBlockUtils: accountBlockUtils, zenon: zenon),
      act: (VoteProjectBloc bloc) => bloc.add(
        VoteProjectRequested(
          address: owner,
          id: targetId,
          vote: AcceleratorProjectVote.yes,
        ),
      ),
      expect: () => <Matcher>[
        isA<VoteProjectLoading>(),
        isA<VoteProjectFailure>().having(
          (VoteProjectFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => acceleratorApi.getPillarVotes(any(), any()));
      },
    );
  });
}
