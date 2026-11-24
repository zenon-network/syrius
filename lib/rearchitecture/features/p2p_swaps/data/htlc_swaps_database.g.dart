// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'htlc_swaps_database.dart';

// ignore_for_file: type=lint
class $HtlcSwapEntriesTable extends HtlcSwapEntries
    with TableInfo<$HtlcSwapEntriesTable, HtlcSwapEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HtlcSwapEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chainIdMeta = const VerificationMeta(
    'chainId',
  );
  @override
  late final GeneratedColumn<int> chainId = GeneratedColumn<int>(
    'chain_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashLockMeta = const VerificationMeta(
    'hashLock',
  );
  @override
  late final GeneratedColumn<String> hashLock = GeneratedColumn<String>(
    'hash_lock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialHtlcIdMeta = const VerificationMeta(
    'initialHtlcId',
  );
  @override
  late final GeneratedColumn<String> initialHtlcId = GeneratedColumn<String>(
    'initial_htlc_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterHtlcIdMeta = const VerificationMeta(
    'counterHtlcId',
  );
  @override
  late final GeneratedColumn<String> counterHtlcId = GeneratedColumn<String>(
    'counter_htlc_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chainId,
    state,
    direction,
    hashLock,
    initialHtlcId,
    counterHtlcId,
    startTime,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'htlc_swaps';
  @override
  VerificationContext validateIntegrity(
    Insertable<HtlcSwapEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chain_id')) {
      context.handle(
        _chainIdMeta,
        chainId.isAcceptableOrUnknown(data['chain_id']!, _chainIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chainIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('hash_lock')) {
      context.handle(
        _hashLockMeta,
        hashLock.isAcceptableOrUnknown(data['hash_lock']!, _hashLockMeta),
      );
    } else if (isInserting) {
      context.missing(_hashLockMeta);
    }
    if (data.containsKey('initial_htlc_id')) {
      context.handle(
        _initialHtlcIdMeta,
        initialHtlcId.isAcceptableOrUnknown(
          data['initial_htlc_id']!,
          _initialHtlcIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialHtlcIdMeta);
    }
    if (data.containsKey('counter_htlc_id')) {
      context.handle(
        _counterHtlcIdMeta,
        counterHtlcId.isAcceptableOrUnknown(
          data['counter_htlc_id']!,
          _counterHtlcIdMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HtlcSwapEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HtlcSwapEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chainId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chain_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      hashLock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_lock'],
      )!,
      initialHtlcId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initial_htlc_id'],
      )!,
      counterHtlcId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_htlc_id'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $HtlcSwapEntriesTable createAlias(String alias) {
    return $HtlcSwapEntriesTable(attachedDatabase, alias);
  }
}

class HtlcSwapEntry extends DataClass implements Insertable<HtlcSwapEntry> {
  /// The unique swap identifier.
  final String id;

  /// The identifier of the chain containing the swap.
  final int chainId;

  /// The serialized swap lifecycle state.
  final String state;

  /// The serialized swap direction.
  final String direction;

  /// The swap's hash lock.
  final String hashLock;

  /// The identifier of the initial HTLC.
  final String initialHtlcId;

  /// The identifier of the counterparty HTLC, when available.
  final String? counterHtlcId;

  /// The swap start time.
  final int startTime;

  /// The complete serialized swap payload.
  final String payloadJson;
  const HtlcSwapEntry({
    required this.id,
    required this.chainId,
    required this.state,
    required this.direction,
    required this.hashLock,
    required this.initialHtlcId,
    this.counterHtlcId,
    required this.startTime,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chain_id'] = Variable<int>(chainId);
    map['state'] = Variable<String>(state);
    map['direction'] = Variable<String>(direction);
    map['hash_lock'] = Variable<String>(hashLock);
    map['initial_htlc_id'] = Variable<String>(initialHtlcId);
    if (!nullToAbsent || counterHtlcId != null) {
      map['counter_htlc_id'] = Variable<String>(counterHtlcId);
    }
    map['start_time'] = Variable<int>(startTime);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  HtlcSwapEntriesCompanion toCompanion(bool nullToAbsent) {
    return HtlcSwapEntriesCompanion(
      id: Value(id),
      chainId: Value(chainId),
      state: Value(state),
      direction: Value(direction),
      hashLock: Value(hashLock),
      initialHtlcId: Value(initialHtlcId),
      counterHtlcId: counterHtlcId == null && nullToAbsent
          ? const Value.absent()
          : Value(counterHtlcId),
      startTime: Value(startTime),
      payloadJson: Value(payloadJson),
    );
  }

  factory HtlcSwapEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HtlcSwapEntry(
      id: serializer.fromJson<String>(json['id']),
      chainId: serializer.fromJson<int>(json['chainId']),
      state: serializer.fromJson<String>(json['state']),
      direction: serializer.fromJson<String>(json['direction']),
      hashLock: serializer.fromJson<String>(json['hashLock']),
      initialHtlcId: serializer.fromJson<String>(json['initialHtlcId']),
      counterHtlcId: serializer.fromJson<String?>(json['counterHtlcId']),
      startTime: serializer.fromJson<int>(json['startTime']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chainId': serializer.toJson<int>(chainId),
      'state': serializer.toJson<String>(state),
      'direction': serializer.toJson<String>(direction),
      'hashLock': serializer.toJson<String>(hashLock),
      'initialHtlcId': serializer.toJson<String>(initialHtlcId),
      'counterHtlcId': serializer.toJson<String?>(counterHtlcId),
      'startTime': serializer.toJson<int>(startTime),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  HtlcSwapEntry copyWith({
    String? id,
    int? chainId,
    String? state,
    String? direction,
    String? hashLock,
    String? initialHtlcId,
    Value<String?> counterHtlcId = const Value.absent(),
    int? startTime,
    String? payloadJson,
  }) => HtlcSwapEntry(
    id: id ?? this.id,
    chainId: chainId ?? this.chainId,
    state: state ?? this.state,
    direction: direction ?? this.direction,
    hashLock: hashLock ?? this.hashLock,
    initialHtlcId: initialHtlcId ?? this.initialHtlcId,
    counterHtlcId: counterHtlcId.present
        ? counterHtlcId.value
        : this.counterHtlcId,
    startTime: startTime ?? this.startTime,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  HtlcSwapEntry copyWithCompanion(HtlcSwapEntriesCompanion data) {
    return HtlcSwapEntry(
      id: data.id.present ? data.id.value : this.id,
      chainId: data.chainId.present ? data.chainId.value : this.chainId,
      state: data.state.present ? data.state.value : this.state,
      direction: data.direction.present ? data.direction.value : this.direction,
      hashLock: data.hashLock.present ? data.hashLock.value : this.hashLock,
      initialHtlcId: data.initialHtlcId.present
          ? data.initialHtlcId.value
          : this.initialHtlcId,
      counterHtlcId: data.counterHtlcId.present
          ? data.counterHtlcId.value
          : this.counterHtlcId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HtlcSwapEntry(')
          ..write('id: $id, ')
          ..write('chainId: $chainId, ')
          ..write('state: $state, ')
          ..write('direction: $direction, ')
          ..write('hashLock: $hashLock, ')
          ..write('initialHtlcId: $initialHtlcId, ')
          ..write('counterHtlcId: $counterHtlcId, ')
          ..write('startTime: $startTime, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chainId,
    state,
    direction,
    hashLock,
    initialHtlcId,
    counterHtlcId,
    startTime,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HtlcSwapEntry &&
          other.id == this.id &&
          other.chainId == this.chainId &&
          other.state == this.state &&
          other.direction == this.direction &&
          other.hashLock == this.hashLock &&
          other.initialHtlcId == this.initialHtlcId &&
          other.counterHtlcId == this.counterHtlcId &&
          other.startTime == this.startTime &&
          other.payloadJson == this.payloadJson);
}

class HtlcSwapEntriesCompanion extends UpdateCompanion<HtlcSwapEntry> {
  final Value<String> id;
  final Value<int> chainId;
  final Value<String> state;
  final Value<String> direction;
  final Value<String> hashLock;
  final Value<String> initialHtlcId;
  final Value<String?> counterHtlcId;
  final Value<int> startTime;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const HtlcSwapEntriesCompanion({
    this.id = const Value.absent(),
    this.chainId = const Value.absent(),
    this.state = const Value.absent(),
    this.direction = const Value.absent(),
    this.hashLock = const Value.absent(),
    this.initialHtlcId = const Value.absent(),
    this.counterHtlcId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HtlcSwapEntriesCompanion.insert({
    required String id,
    required int chainId,
    required String state,
    required String direction,
    required String hashLock,
    required String initialHtlcId,
    this.counterHtlcId = const Value.absent(),
    required int startTime,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chainId = Value(chainId),
       state = Value(state),
       direction = Value(direction),
       hashLock = Value(hashLock),
       initialHtlcId = Value(initialHtlcId),
       startTime = Value(startTime),
       payloadJson = Value(payloadJson);
  static Insertable<HtlcSwapEntry> custom({
    Expression<String>? id,
    Expression<int>? chainId,
    Expression<String>? state,
    Expression<String>? direction,
    Expression<String>? hashLock,
    Expression<String>? initialHtlcId,
    Expression<String>? counterHtlcId,
    Expression<int>? startTime,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chainId != null) 'chain_id': chainId,
      if (state != null) 'state': state,
      if (direction != null) 'direction': direction,
      if (hashLock != null) 'hash_lock': hashLock,
      if (initialHtlcId != null) 'initial_htlc_id': initialHtlcId,
      if (counterHtlcId != null) 'counter_htlc_id': counterHtlcId,
      if (startTime != null) 'start_time': startTime,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HtlcSwapEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? chainId,
    Value<String>? state,
    Value<String>? direction,
    Value<String>? hashLock,
    Value<String>? initialHtlcId,
    Value<String?>? counterHtlcId,
    Value<int>? startTime,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return HtlcSwapEntriesCompanion(
      id: id ?? this.id,
      chainId: chainId ?? this.chainId,
      state: state ?? this.state,
      direction: direction ?? this.direction,
      hashLock: hashLock ?? this.hashLock,
      initialHtlcId: initialHtlcId ?? this.initialHtlcId,
      counterHtlcId: counterHtlcId ?? this.counterHtlcId,
      startTime: startTime ?? this.startTime,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chainId.present) {
      map['chain_id'] = Variable<int>(chainId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (hashLock.present) {
      map['hash_lock'] = Variable<String>(hashLock.value);
    }
    if (initialHtlcId.present) {
      map['initial_htlc_id'] = Variable<String>(initialHtlcId.value);
    }
    if (counterHtlcId.present) {
      map['counter_htlc_id'] = Variable<String>(counterHtlcId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HtlcSwapEntriesCompanion(')
          ..write('id: $id, ')
          ..write('chainId: $chainId, ')
          ..write('state: $state, ')
          ..write('direction: $direction, ')
          ..write('hashLock: $hashLock, ')
          ..write('initialHtlcId: $initialHtlcId, ')
          ..write('counterHtlcId: $counterHtlcId, ')
          ..write('startTime: $startTime, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HtlcScanCheckpointsTable extends HtlcScanCheckpoints
    with TableInfo<$HtlcScanCheckpointsTable, HtlcScanCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HtlcScanCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chainIdMeta = const VerificationMeta(
    'chainId',
  );
  @override
  late final GeneratedColumn<int> chainId = GeneratedColumn<int>(
    'chain_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckedHeightMeta = const VerificationMeta(
    'lastCheckedHeight',
  );
  @override
  late final GeneratedColumn<int> lastCheckedHeight = GeneratedColumn<int>(
    'last_checked_height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [chainId, lastCheckedHeight];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'htlc_scan_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<HtlcScanCheckpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chain_id')) {
      context.handle(
        _chainIdMeta,
        chainId.isAcceptableOrUnknown(data['chain_id']!, _chainIdMeta),
      );
    }
    if (data.containsKey('last_checked_height')) {
      context.handle(
        _lastCheckedHeightMeta,
        lastCheckedHeight.isAcceptableOrUnknown(
          data['last_checked_height']!,
          _lastCheckedHeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastCheckedHeightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chainId};
  @override
  HtlcScanCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HtlcScanCheckpoint(
      chainId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chain_id'],
      )!,
      lastCheckedHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_checked_height'],
      )!,
    );
  }

  @override
  $HtlcScanCheckpointsTable createAlias(String alias) {
    return $HtlcScanCheckpointsTable(attachedDatabase, alias);
  }
}

class HtlcScanCheckpoint extends DataClass
    implements Insertable<HtlcScanCheckpoint> {
  /// The identifier of the scanned chain.
  final int chainId;

  /// The last block height checked for HTLC updates.
  final int lastCheckedHeight;
  const HtlcScanCheckpoint({
    required this.chainId,
    required this.lastCheckedHeight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chain_id'] = Variable<int>(chainId);
    map['last_checked_height'] = Variable<int>(lastCheckedHeight);
    return map;
  }

  HtlcScanCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return HtlcScanCheckpointsCompanion(
      chainId: Value(chainId),
      lastCheckedHeight: Value(lastCheckedHeight),
    );
  }

  factory HtlcScanCheckpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HtlcScanCheckpoint(
      chainId: serializer.fromJson<int>(json['chainId']),
      lastCheckedHeight: serializer.fromJson<int>(json['lastCheckedHeight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chainId': serializer.toJson<int>(chainId),
      'lastCheckedHeight': serializer.toJson<int>(lastCheckedHeight),
    };
  }

  HtlcScanCheckpoint copyWith({int? chainId, int? lastCheckedHeight}) =>
      HtlcScanCheckpoint(
        chainId: chainId ?? this.chainId,
        lastCheckedHeight: lastCheckedHeight ?? this.lastCheckedHeight,
      );
  HtlcScanCheckpoint copyWithCompanion(HtlcScanCheckpointsCompanion data) {
    return HtlcScanCheckpoint(
      chainId: data.chainId.present ? data.chainId.value : this.chainId,
      lastCheckedHeight: data.lastCheckedHeight.present
          ? data.lastCheckedHeight.value
          : this.lastCheckedHeight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HtlcScanCheckpoint(')
          ..write('chainId: $chainId, ')
          ..write('lastCheckedHeight: $lastCheckedHeight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chainId, lastCheckedHeight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HtlcScanCheckpoint &&
          other.chainId == this.chainId &&
          other.lastCheckedHeight == this.lastCheckedHeight);
}

class HtlcScanCheckpointsCompanion extends UpdateCompanion<HtlcScanCheckpoint> {
  final Value<int> chainId;
  final Value<int> lastCheckedHeight;
  const HtlcScanCheckpointsCompanion({
    this.chainId = const Value.absent(),
    this.lastCheckedHeight = const Value.absent(),
  });
  HtlcScanCheckpointsCompanion.insert({
    this.chainId = const Value.absent(),
    required int lastCheckedHeight,
  }) : lastCheckedHeight = Value(lastCheckedHeight);
  static Insertable<HtlcScanCheckpoint> custom({
    Expression<int>? chainId,
    Expression<int>? lastCheckedHeight,
  }) {
    return RawValuesInsertable({
      if (chainId != null) 'chain_id': chainId,
      if (lastCheckedHeight != null) 'last_checked_height': lastCheckedHeight,
    });
  }

  HtlcScanCheckpointsCompanion copyWith({
    Value<int>? chainId,
    Value<int>? lastCheckedHeight,
  }) {
    return HtlcScanCheckpointsCompanion(
      chainId: chainId ?? this.chainId,
      lastCheckedHeight: lastCheckedHeight ?? this.lastCheckedHeight,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chainId.present) {
      map['chain_id'] = Variable<int>(chainId.value);
    }
    if (lastCheckedHeight.present) {
      map['last_checked_height'] = Variable<int>(lastCheckedHeight.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HtlcScanCheckpointsCompanion(')
          ..write('chainId: $chainId, ')
          ..write('lastCheckedHeight: $lastCheckedHeight')
          ..write(')'))
        .toString();
  }
}

abstract class _$HtlcSwapsDatabase extends GeneratedDatabase {
  _$HtlcSwapsDatabase(QueryExecutor e) : super(e);
  $HtlcSwapsDatabaseManager get managers => $HtlcSwapsDatabaseManager(this);
  late final $HtlcSwapEntriesTable htlcSwapEntries = $HtlcSwapEntriesTable(
    this,
  );
  late final $HtlcScanCheckpointsTable htlcScanCheckpoints =
      $HtlcScanCheckpointsTable(this);
  late final Index htlcSwapsChainState = Index(
    'htlc_swaps_chain_state',
    'CREATE INDEX htlc_swaps_chain_state ON htlc_swaps (chain_id, state)',
  );
  late final Index htlcSwapsHashLock = Index(
    'htlc_swaps_hash_lock',
    'CREATE INDEX htlc_swaps_hash_lock ON htlc_swaps (hash_lock)',
  );
  late final Index htlcSwapsInitialHtlcId = Index(
    'htlc_swaps_initial_htlc_id',
    'CREATE INDEX htlc_swaps_initial_htlc_id ON htlc_swaps (initial_htlc_id)',
  );
  late final Index htlcSwapsCounterHtlcId = Index(
    'htlc_swaps_counter_htlc_id',
    'CREATE INDEX htlc_swaps_counter_htlc_id ON htlc_swaps (counter_htlc_id)',
  );
  late final Index htlcSwapsChainStartTime = Index(
    'htlc_swaps_chain_start_time',
    'CREATE INDEX htlc_swaps_chain_start_time ON htlc_swaps (chain_id, start_time)',
  );
  late final HtlcSwapsDao htlcSwapsDao = HtlcSwapsDao(
    this as HtlcSwapsDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    htlcSwapEntries,
    htlcScanCheckpoints,
    htlcSwapsChainState,
    htlcSwapsHashLock,
    htlcSwapsInitialHtlcId,
    htlcSwapsCounterHtlcId,
    htlcSwapsChainStartTime,
  ];
}

typedef $$HtlcSwapEntriesTableCreateCompanionBuilder =
    HtlcSwapEntriesCompanion Function({
      required String id,
      required int chainId,
      required String state,
      required String direction,
      required String hashLock,
      required String initialHtlcId,
      Value<String?> counterHtlcId,
      required int startTime,
      required String payloadJson,
      Value<int> rowid,
    });
typedef $$HtlcSwapEntriesTableUpdateCompanionBuilder =
    HtlcSwapEntriesCompanion Function({
      Value<String> id,
      Value<int> chainId,
      Value<String> state,
      Value<String> direction,
      Value<String> hashLock,
      Value<String> initialHtlcId,
      Value<String?> counterHtlcId,
      Value<int> startTime,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$HtlcSwapEntriesTableFilterComposer
    extends Composer<_$HtlcSwapsDatabase, $HtlcSwapEntriesTable> {
  $$HtlcSwapEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chainId => $composableBuilder(
    column: $table.chainId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashLock => $composableBuilder(
    column: $table.hashLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initialHtlcId => $composableBuilder(
    column: $table.initialHtlcId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterHtlcId => $composableBuilder(
    column: $table.counterHtlcId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HtlcSwapEntriesTableOrderingComposer
    extends Composer<_$HtlcSwapsDatabase, $HtlcSwapEntriesTable> {
  $$HtlcSwapEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chainId => $composableBuilder(
    column: $table.chainId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashLock => $composableBuilder(
    column: $table.hashLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initialHtlcId => $composableBuilder(
    column: $table.initialHtlcId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterHtlcId => $composableBuilder(
    column: $table.counterHtlcId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HtlcSwapEntriesTableAnnotationComposer
    extends Composer<_$HtlcSwapsDatabase, $HtlcSwapEntriesTable> {
  $$HtlcSwapEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chainId =>
      $composableBuilder(column: $table.chainId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get hashLock =>
      $composableBuilder(column: $table.hashLock, builder: (column) => column);

  GeneratedColumn<String> get initialHtlcId => $composableBuilder(
    column: $table.initialHtlcId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterHtlcId => $composableBuilder(
    column: $table.counterHtlcId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$HtlcSwapEntriesTableTableManager
    extends
        RootTableManager<
          _$HtlcSwapsDatabase,
          $HtlcSwapEntriesTable,
          HtlcSwapEntry,
          $$HtlcSwapEntriesTableFilterComposer,
          $$HtlcSwapEntriesTableOrderingComposer,
          $$HtlcSwapEntriesTableAnnotationComposer,
          $$HtlcSwapEntriesTableCreateCompanionBuilder,
          $$HtlcSwapEntriesTableUpdateCompanionBuilder,
          (
            HtlcSwapEntry,
            BaseReferences<
              _$HtlcSwapsDatabase,
              $HtlcSwapEntriesTable,
              HtlcSwapEntry
            >,
          ),
          HtlcSwapEntry,
          PrefetchHooks Function()
        > {
  $$HtlcSwapEntriesTableTableManager(
    _$HtlcSwapsDatabase db,
    $HtlcSwapEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HtlcSwapEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HtlcSwapEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HtlcSwapEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> chainId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> hashLock = const Value.absent(),
                Value<String> initialHtlcId = const Value.absent(),
                Value<String?> counterHtlcId = const Value.absent(),
                Value<int> startTime = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HtlcSwapEntriesCompanion(
                id: id,
                chainId: chainId,
                state: state,
                direction: direction,
                hashLock: hashLock,
                initialHtlcId: initialHtlcId,
                counterHtlcId: counterHtlcId,
                startTime: startTime,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int chainId,
                required String state,
                required String direction,
                required String hashLock,
                required String initialHtlcId,
                Value<String?> counterHtlcId = const Value.absent(),
                required int startTime,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => HtlcSwapEntriesCompanion.insert(
                id: id,
                chainId: chainId,
                state: state,
                direction: direction,
                hashLock: hashLock,
                initialHtlcId: initialHtlcId,
                counterHtlcId: counterHtlcId,
                startTime: startTime,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HtlcSwapEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$HtlcSwapsDatabase,
      $HtlcSwapEntriesTable,
      HtlcSwapEntry,
      $$HtlcSwapEntriesTableFilterComposer,
      $$HtlcSwapEntriesTableOrderingComposer,
      $$HtlcSwapEntriesTableAnnotationComposer,
      $$HtlcSwapEntriesTableCreateCompanionBuilder,
      $$HtlcSwapEntriesTableUpdateCompanionBuilder,
      (
        HtlcSwapEntry,
        BaseReferences<
          _$HtlcSwapsDatabase,
          $HtlcSwapEntriesTable,
          HtlcSwapEntry
        >,
      ),
      HtlcSwapEntry,
      PrefetchHooks Function()
    >;
typedef $$HtlcScanCheckpointsTableCreateCompanionBuilder =
    HtlcScanCheckpointsCompanion Function({
      Value<int> chainId,
      required int lastCheckedHeight,
    });
typedef $$HtlcScanCheckpointsTableUpdateCompanionBuilder =
    HtlcScanCheckpointsCompanion Function({
      Value<int> chainId,
      Value<int> lastCheckedHeight,
    });

class $$HtlcScanCheckpointsTableFilterComposer
    extends Composer<_$HtlcSwapsDatabase, $HtlcScanCheckpointsTable> {
  $$HtlcScanCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get chainId => $composableBuilder(
    column: $table.chainId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCheckedHeight => $composableBuilder(
    column: $table.lastCheckedHeight,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HtlcScanCheckpointsTableOrderingComposer
    extends Composer<_$HtlcSwapsDatabase, $HtlcScanCheckpointsTable> {
  $$HtlcScanCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get chainId => $composableBuilder(
    column: $table.chainId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCheckedHeight => $composableBuilder(
    column: $table.lastCheckedHeight,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HtlcScanCheckpointsTableAnnotationComposer
    extends Composer<_$HtlcSwapsDatabase, $HtlcScanCheckpointsTable> {
  $$HtlcScanCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get chainId =>
      $composableBuilder(column: $table.chainId, builder: (column) => column);

  GeneratedColumn<int> get lastCheckedHeight => $composableBuilder(
    column: $table.lastCheckedHeight,
    builder: (column) => column,
  );
}

class $$HtlcScanCheckpointsTableTableManager
    extends
        RootTableManager<
          _$HtlcSwapsDatabase,
          $HtlcScanCheckpointsTable,
          HtlcScanCheckpoint,
          $$HtlcScanCheckpointsTableFilterComposer,
          $$HtlcScanCheckpointsTableOrderingComposer,
          $$HtlcScanCheckpointsTableAnnotationComposer,
          $$HtlcScanCheckpointsTableCreateCompanionBuilder,
          $$HtlcScanCheckpointsTableUpdateCompanionBuilder,
          (
            HtlcScanCheckpoint,
            BaseReferences<
              _$HtlcSwapsDatabase,
              $HtlcScanCheckpointsTable,
              HtlcScanCheckpoint
            >,
          ),
          HtlcScanCheckpoint,
          PrefetchHooks Function()
        > {
  $$HtlcScanCheckpointsTableTableManager(
    _$HtlcSwapsDatabase db,
    $HtlcScanCheckpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HtlcScanCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HtlcScanCheckpointsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$HtlcScanCheckpointsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> chainId = const Value.absent(),
                Value<int> lastCheckedHeight = const Value.absent(),
              }) => HtlcScanCheckpointsCompanion(
                chainId: chainId,
                lastCheckedHeight: lastCheckedHeight,
              ),
          createCompanionCallback:
              ({
                Value<int> chainId = const Value.absent(),
                required int lastCheckedHeight,
              }) => HtlcScanCheckpointsCompanion.insert(
                chainId: chainId,
                lastCheckedHeight: lastCheckedHeight,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HtlcScanCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$HtlcSwapsDatabase,
      $HtlcScanCheckpointsTable,
      HtlcScanCheckpoint,
      $$HtlcScanCheckpointsTableFilterComposer,
      $$HtlcScanCheckpointsTableOrderingComposer,
      $$HtlcScanCheckpointsTableAnnotationComposer,
      $$HtlcScanCheckpointsTableCreateCompanionBuilder,
      $$HtlcScanCheckpointsTableUpdateCompanionBuilder,
      (
        HtlcScanCheckpoint,
        BaseReferences<
          _$HtlcSwapsDatabase,
          $HtlcScanCheckpointsTable,
          HtlcScanCheckpoint
        >,
      ),
      HtlcScanCheckpoint,
      PrefetchHooks Function()
    >;

class $HtlcSwapsDatabaseManager {
  final _$HtlcSwapsDatabase _db;
  $HtlcSwapsDatabaseManager(this._db);
  $$HtlcSwapEntriesTableTableManager get htlcSwapEntries =>
      $$HtlcSwapEntriesTableTableManager(_db, _db.htlcSwapEntries);
  $$HtlcScanCheckpointsTableTableManager get htlcScanCheckpoints =>
      $$HtlcScanCheckpointsTableTableManager(_db, _db.htlcScanCheckpoints);
}
