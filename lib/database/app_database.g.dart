// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryAvatarUrlMeta = const VerificationMeta(
    'primaryAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> primaryAvatarUrl = GeneratedColumn<String>(
    'primary_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isStubMeta = const VerificationMeta('isStub');
  @override
  late final GeneratedColumn<bool> isStub = GeneratedColumn<bool>(
    'is_stub',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stub" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    primaryAvatarUrl,
    kind,
    isStub,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('primary_avatar_url')) {
      context.handle(
        _primaryAvatarUrlMeta,
        primaryAvatarUrl.isAcceptableOrUnknown(
          data['primary_avatar_url']!,
          _primaryAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('is_stub')) {
      context.handle(
        _isStubMeta,
        isStub.isAcceptableOrUnknown(data['is_stub']!, _isStubMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      primaryAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_avatar_url'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      isStub: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stub'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final int id;
  final String displayName;

  /// URL to the primary avatar image, if known.
  final String? primaryAvatarUrl;

  /// Rough entity kind: 'person', 'team', 'system'.
  final String? kind;

  /// True until at least one enrichment pass has been completed.
  final bool isStub;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Contact({
    required this.id,
    required this.displayName,
    this.primaryAvatarUrl,
    this.kind,
    required this.isStub,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || primaryAvatarUrl != null) {
      map['primary_avatar_url'] = Variable<String>(primaryAvatarUrl);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    map['is_stub'] = Variable<bool>(isStub);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      primaryAvatarUrl: primaryAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryAvatarUrl),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      isStub: Value(isStub),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      primaryAvatarUrl: serializer.fromJson<String?>(json['primaryAvatarUrl']),
      kind: serializer.fromJson<String?>(json['kind']),
      isStub: serializer.fromJson<bool>(json['isStub']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'primaryAvatarUrl': serializer.toJson<String?>(primaryAvatarUrl),
      'kind': serializer.toJson<String?>(kind),
      'isStub': serializer.toJson<bool>(isStub),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Contact copyWith({
    int? id,
    String? displayName,
    Value<String?> primaryAvatarUrl = const Value.absent(),
    Value<String?> kind = const Value.absent(),
    bool? isStub,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Contact(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    primaryAvatarUrl: primaryAvatarUrl.present
        ? primaryAvatarUrl.value
        : this.primaryAvatarUrl,
    kind: kind.present ? kind.value : this.kind,
    isStub: isStub ?? this.isStub,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      primaryAvatarUrl: data.primaryAvatarUrl.present
          ? data.primaryAvatarUrl.value
          : this.primaryAvatarUrl,
      kind: data.kind.present ? data.kind.value : this.kind,
      isStub: data.isStub.present ? data.isStub.value : this.isStub,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('primaryAvatarUrl: $primaryAvatarUrl, ')
          ..write('kind: $kind, ')
          ..write('isStub: $isStub, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    primaryAvatarUrl,
    kind,
    isStub,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.primaryAvatarUrl == this.primaryAvatarUrl &&
          other.kind == this.kind &&
          other.isStub == this.isStub &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String?> primaryAvatarUrl;
  final Value<String?> kind;
  final Value<bool> isStub;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.primaryAvatarUrl = const Value.absent(),
    this.kind = const Value.absent(),
    this.isStub = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    this.primaryAvatarUrl = const Value.absent(),
    this.kind = const Value.absent(),
    this.isStub = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : displayName = Value(displayName);
  static Insertable<Contact> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? primaryAvatarUrl,
    Expression<String>? kind,
    Expression<bool>? isStub,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (primaryAvatarUrl != null) 'primary_avatar_url': primaryAvatarUrl,
      if (kind != null) 'kind': kind,
      if (isStub != null) 'is_stub': isStub,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ContactsCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String?>? primaryAvatarUrl,
    Value<String?>? kind,
    Value<bool>? isStub,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      primaryAvatarUrl: primaryAvatarUrl ?? this.primaryAvatarUrl,
      kind: kind ?? this.kind,
      isStub: isStub ?? this.isStub,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (primaryAvatarUrl.present) {
      map['primary_avatar_url'] = Variable<String>(primaryAvatarUrl.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (isStub.present) {
      map['is_stub'] = Variable<bool>(isStub.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('primaryAvatarUrl: $primaryAvatarUrl, ')
          ..write('kind: $kind, ')
          ..write('isStub: $isStub, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ContactIdentitiesTable extends ContactIdentities
    with TableInfo<$ContactIdentitiesTable, ContactIdentity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactIdentitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contacts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameSnapshotMeta =
      const VerificationMeta('displayNameSnapshot');
  @override
  late final GeneratedColumn<String> displayNameSnapshot =
      GeneratedColumn<String>(
        'display_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _avatarUrlSnapshotMeta = const VerificationMeta(
    'avatarUrlSnapshot',
  );
  @override
  late final GeneratedColumn<String> avatarUrlSnapshot =
      GeneratedColumn<String>(
        'avatar_url_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rawPayloadJsonMeta = const VerificationMeta(
    'rawPayloadJson',
  );
  @override
  late final GeneratedColumn<String> rawPayloadJson = GeneratedColumn<String>(
    'raw_payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastEnrichedAtMeta = const VerificationMeta(
    'lastEnrichedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastEnrichedAt =
      GeneratedColumn<DateTime>(
        'last_enriched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contactId,
    source,
    externalId,
    displayNameSnapshot,
    avatarUrlSnapshot,
    rawPayloadJson,
    lastSeenAt,
    lastEnrichedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_identities';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactIdentity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('display_name_snapshot')) {
      context.handle(
        _displayNameSnapshotMeta,
        displayNameSnapshot.isAcceptableOrUnknown(
          data['display_name_snapshot']!,
          _displayNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url_snapshot')) {
      context.handle(
        _avatarUrlSnapshotMeta,
        avatarUrlSnapshot.isAcceptableOrUnknown(
          data['avatar_url_snapshot']!,
          _avatarUrlSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('raw_payload_json')) {
      context.handle(
        _rawPayloadJsonMeta,
        rawPayloadJson.isAcceptableOrUnknown(
          data['raw_payload_json']!,
          _rawPayloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('last_enriched_at')) {
      context.handle(
        _lastEnrichedAtMeta,
        lastEnrichedAt.isAcceptableOrUnknown(
          data['last_enriched_at']!,
          _lastEnrichedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {source, externalId},
  ];
  @override
  ContactIdentity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactIdentity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contact_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      displayNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name_snapshot'],
      ),
      avatarUrlSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url_snapshot'],
      ),
      rawPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_payload_json'],
      ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
      lastEnrichedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_enriched_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContactIdentitiesTable createAlias(String alias) {
    return $ContactIdentitiesTable(attachedDatabase, alias);
  }
}

class ContactIdentity extends DataClass implements Insertable<ContactIdentity> {
  final int id;
  final int contactId;

  /// Provider name, e.g. 'smartschool', 'gmail', 'outlook'.
  final String source;

  /// ID of the user as supplied by the remote provider.
  final String externalId;

  /// Display name at the time this identity was last seen.
  final String? displayNameSnapshot;

  /// Avatar URL at the time this identity was last seen.
  final String? avatarUrlSnapshot;

  /// Full raw payload as JSON, for future re-processing.
  final String? rawPayloadJson;
  final DateTime lastSeenAt;
  final DateTime? lastEnrichedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ContactIdentity({
    required this.id,
    required this.contactId,
    required this.source,
    required this.externalId,
    this.displayNameSnapshot,
    this.avatarUrlSnapshot,
    this.rawPayloadJson,
    required this.lastSeenAt,
    this.lastEnrichedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['contact_id'] = Variable<int>(contactId);
    map['source'] = Variable<String>(source);
    map['external_id'] = Variable<String>(externalId);
    if (!nullToAbsent || displayNameSnapshot != null) {
      map['display_name_snapshot'] = Variable<String>(displayNameSnapshot);
    }
    if (!nullToAbsent || avatarUrlSnapshot != null) {
      map['avatar_url_snapshot'] = Variable<String>(avatarUrlSnapshot);
    }
    if (!nullToAbsent || rawPayloadJson != null) {
      map['raw_payload_json'] = Variable<String>(rawPayloadJson);
    }
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    if (!nullToAbsent || lastEnrichedAt != null) {
      map['last_enriched_at'] = Variable<DateTime>(lastEnrichedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContactIdentitiesCompanion toCompanion(bool nullToAbsent) {
    return ContactIdentitiesCompanion(
      id: Value(id),
      contactId: Value(contactId),
      source: Value(source),
      externalId: Value(externalId),
      displayNameSnapshot: displayNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(displayNameSnapshot),
      avatarUrlSnapshot: avatarUrlSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrlSnapshot),
      rawPayloadJson: rawPayloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rawPayloadJson),
      lastSeenAt: Value(lastSeenAt),
      lastEnrichedAt: lastEnrichedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEnrichedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContactIdentity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactIdentity(
      id: serializer.fromJson<int>(json['id']),
      contactId: serializer.fromJson<int>(json['contactId']),
      source: serializer.fromJson<String>(json['source']),
      externalId: serializer.fromJson<String>(json['externalId']),
      displayNameSnapshot: serializer.fromJson<String?>(
        json['displayNameSnapshot'],
      ),
      avatarUrlSnapshot: serializer.fromJson<String?>(
        json['avatarUrlSnapshot'],
      ),
      rawPayloadJson: serializer.fromJson<String?>(json['rawPayloadJson']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      lastEnrichedAt: serializer.fromJson<DateTime?>(json['lastEnrichedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contactId': serializer.toJson<int>(contactId),
      'source': serializer.toJson<String>(source),
      'externalId': serializer.toJson<String>(externalId),
      'displayNameSnapshot': serializer.toJson<String?>(displayNameSnapshot),
      'avatarUrlSnapshot': serializer.toJson<String?>(avatarUrlSnapshot),
      'rawPayloadJson': serializer.toJson<String?>(rawPayloadJson),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'lastEnrichedAt': serializer.toJson<DateTime?>(lastEnrichedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContactIdentity copyWith({
    int? id,
    int? contactId,
    String? source,
    String? externalId,
    Value<String?> displayNameSnapshot = const Value.absent(),
    Value<String?> avatarUrlSnapshot = const Value.absent(),
    Value<String?> rawPayloadJson = const Value.absent(),
    DateTime? lastSeenAt,
    Value<DateTime?> lastEnrichedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ContactIdentity(
    id: id ?? this.id,
    contactId: contactId ?? this.contactId,
    source: source ?? this.source,
    externalId: externalId ?? this.externalId,
    displayNameSnapshot: displayNameSnapshot.present
        ? displayNameSnapshot.value
        : this.displayNameSnapshot,
    avatarUrlSnapshot: avatarUrlSnapshot.present
        ? avatarUrlSnapshot.value
        : this.avatarUrlSnapshot,
    rawPayloadJson: rawPayloadJson.present
        ? rawPayloadJson.value
        : this.rawPayloadJson,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    lastEnrichedAt: lastEnrichedAt.present
        ? lastEnrichedAt.value
        : this.lastEnrichedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContactIdentity copyWithCompanion(ContactIdentitiesCompanion data) {
    return ContactIdentity(
      id: data.id.present ? data.id.value : this.id,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      displayNameSnapshot: data.displayNameSnapshot.present
          ? data.displayNameSnapshot.value
          : this.displayNameSnapshot,
      avatarUrlSnapshot: data.avatarUrlSnapshot.present
          ? data.avatarUrlSnapshot.value
          : this.avatarUrlSnapshot,
      rawPayloadJson: data.rawPayloadJson.present
          ? data.rawPayloadJson.value
          : this.rawPayloadJson,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      lastEnrichedAt: data.lastEnrichedAt.present
          ? data.lastEnrichedAt.value
          : this.lastEnrichedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactIdentity(')
          ..write('id: $id, ')
          ..write('contactId: $contactId, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('displayNameSnapshot: $displayNameSnapshot, ')
          ..write('avatarUrlSnapshot: $avatarUrlSnapshot, ')
          ..write('rawPayloadJson: $rawPayloadJson, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastEnrichedAt: $lastEnrichedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contactId,
    source,
    externalId,
    displayNameSnapshot,
    avatarUrlSnapshot,
    rawPayloadJson,
    lastSeenAt,
    lastEnrichedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactIdentity &&
          other.id == this.id &&
          other.contactId == this.contactId &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.displayNameSnapshot == this.displayNameSnapshot &&
          other.avatarUrlSnapshot == this.avatarUrlSnapshot &&
          other.rawPayloadJson == this.rawPayloadJson &&
          other.lastSeenAt == this.lastSeenAt &&
          other.lastEnrichedAt == this.lastEnrichedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContactIdentitiesCompanion extends UpdateCompanion<ContactIdentity> {
  final Value<int> id;
  final Value<int> contactId;
  final Value<String> source;
  final Value<String> externalId;
  final Value<String?> displayNameSnapshot;
  final Value<String?> avatarUrlSnapshot;
  final Value<String?> rawPayloadJson;
  final Value<DateTime> lastSeenAt;
  final Value<DateTime?> lastEnrichedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ContactIdentitiesCompanion({
    this.id = const Value.absent(),
    this.contactId = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.displayNameSnapshot = const Value.absent(),
    this.avatarUrlSnapshot = const Value.absent(),
    this.rawPayloadJson = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.lastEnrichedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ContactIdentitiesCompanion.insert({
    this.id = const Value.absent(),
    required int contactId,
    required String source,
    required String externalId,
    this.displayNameSnapshot = const Value.absent(),
    this.avatarUrlSnapshot = const Value.absent(),
    this.rawPayloadJson = const Value.absent(),
    required DateTime lastSeenAt,
    this.lastEnrichedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : contactId = Value(contactId),
       source = Value(source),
       externalId = Value(externalId),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<ContactIdentity> custom({
    Expression<int>? id,
    Expression<int>? contactId,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? displayNameSnapshot,
    Expression<String>? avatarUrlSnapshot,
    Expression<String>? rawPayloadJson,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? lastEnrichedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contactId != null) 'contact_id': contactId,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (displayNameSnapshot != null)
        'display_name_snapshot': displayNameSnapshot,
      if (avatarUrlSnapshot != null) 'avatar_url_snapshot': avatarUrlSnapshot,
      if (rawPayloadJson != null) 'raw_payload_json': rawPayloadJson,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (lastEnrichedAt != null) 'last_enriched_at': lastEnrichedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ContactIdentitiesCompanion copyWith({
    Value<int>? id,
    Value<int>? contactId,
    Value<String>? source,
    Value<String>? externalId,
    Value<String?>? displayNameSnapshot,
    Value<String?>? avatarUrlSnapshot,
    Value<String?>? rawPayloadJson,
    Value<DateTime>? lastSeenAt,
    Value<DateTime?>? lastEnrichedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ContactIdentitiesCompanion(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      displayNameSnapshot: displayNameSnapshot ?? this.displayNameSnapshot,
      avatarUrlSnapshot: avatarUrlSnapshot ?? this.avatarUrlSnapshot,
      rawPayloadJson: rawPayloadJson ?? this.rawPayloadJson,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastEnrichedAt: lastEnrichedAt ?? this.lastEnrichedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (displayNameSnapshot.present) {
      map['display_name_snapshot'] = Variable<String>(
        displayNameSnapshot.value,
      );
    }
    if (avatarUrlSnapshot.present) {
      map['avatar_url_snapshot'] = Variable<String>(avatarUrlSnapshot.value);
    }
    if (rawPayloadJson.present) {
      map['raw_payload_json'] = Variable<String>(rawPayloadJson.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (lastEnrichedAt.present) {
      map['last_enriched_at'] = Variable<DateTime>(lastEnrichedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactIdentitiesCompanion(')
          ..write('id: $id, ')
          ..write('contactId: $contactId, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('displayNameSnapshot: $displayNameSnapshot, ')
          ..write('avatarUrlSnapshot: $avatarUrlSnapshot, ')
          ..write('rawPayloadJson: $rawPayloadJson, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastEnrichedAt: $lastEnrichedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mailboxMeta = const VerificationMeta(
    'mailbox',
  );
  @override
  late final GeneratedColumn<String> mailbox = GeneratedColumn<String>(
    'mailbox',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyRawMeta = const VerificationMeta(
    'bodyRaw',
  );
  @override
  late final GeneratedColumn<String> bodyRaw = GeneratedColumn<String>(
    'body_raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyTextMeta = const VerificationMeta(
    'bodyText',
  );
  @override
  late final GeneratedColumn<String> bodyText = GeneratedColumn<String>(
    'body_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyFormatMeta = const VerificationMeta(
    'bodyFormat',
  );
  @override
  late final GeneratedColumn<String> bodyFormat = GeneratedColumn<String>(
    'body_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> remoteUpdatedAt =
      GeneratedColumn<DateTime>(
        'remote_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasAttachmentsMeta = const VerificationMeta(
    'hasAttachments',
  );
  @override
  late final GeneratedColumn<bool> hasAttachments = GeneratedColumn<bool>(
    'has_attachments',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_attachments" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _detailFetchedAtMeta = const VerificationMeta(
    'detailFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detailFetchedAt =
      GeneratedColumn<DateTime>(
        'detail_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _headerFingerprintMeta = const VerificationMeta(
    'headerFingerprint',
  );
  @override
  late final GeneratedColumn<String> headerFingerprint =
      GeneratedColumn<String>(
        'header_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rawHeaderJsonMeta = const VerificationMeta(
    'rawHeaderJson',
  );
  @override
  late final GeneratedColumn<String> rawHeaderJson = GeneratedColumn<String>(
    'raw_header_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawDetailJsonMeta = const VerificationMeta(
    'rawDetailJson',
  );
  @override
  late final GeneratedColumn<String> rawDetailJson = GeneratedColumn<String>(
    'raw_detail_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    externalId,
    mailbox,
    subject,
    bodyRaw,
    bodyText,
    bodyFormat,
    sentAt,
    receivedAt,
    remoteUpdatedAt,
    isRead,
    isArchived,
    isDeleted,
    hasAttachments,
    detailFetchedAt,
    headerFingerprint,
    rawHeaderJson,
    rawDetailJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('mailbox')) {
      context.handle(
        _mailboxMeta,
        mailbox.isAcceptableOrUnknown(data['mailbox']!, _mailboxMeta),
      );
    } else if (isInserting) {
      context.missing(_mailboxMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('body_raw')) {
      context.handle(
        _bodyRawMeta,
        bodyRaw.isAcceptableOrUnknown(data['body_raw']!, _bodyRawMeta),
      );
    }
    if (data.containsKey('body_text')) {
      context.handle(
        _bodyTextMeta,
        bodyText.isAcceptableOrUnknown(data['body_text']!, _bodyTextMeta),
      );
    }
    if (data.containsKey('body_format')) {
      context.handle(
        _bodyFormatMeta,
        bodyFormat.isAcceptableOrUnknown(data['body_format']!, _bodyFormatMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('has_attachments')) {
      context.handle(
        _hasAttachmentsMeta,
        hasAttachments.isAcceptableOrUnknown(
          data['has_attachments']!,
          _hasAttachmentsMeta,
        ),
      );
    }
    if (data.containsKey('detail_fetched_at')) {
      context.handle(
        _detailFetchedAtMeta,
        detailFetchedAt.isAcceptableOrUnknown(
          data['detail_fetched_at']!,
          _detailFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('header_fingerprint')) {
      context.handle(
        _headerFingerprintMeta,
        headerFingerprint.isAcceptableOrUnknown(
          data['header_fingerprint']!,
          _headerFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('raw_header_json')) {
      context.handle(
        _rawHeaderJsonMeta,
        rawHeaderJson.isAcceptableOrUnknown(
          data['raw_header_json']!,
          _rawHeaderJsonMeta,
        ),
      );
    }
    if (data.containsKey('raw_detail_json')) {
      context.handle(
        _rawDetailJsonMeta,
        rawDetailJson.isAcceptableOrUnknown(
          data['raw_detail_json']!,
          _rawDetailJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {source, externalId},
  ];
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      mailbox: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mailbox'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      bodyRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_raw'],
      ),
      bodyText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_text'],
      ),
      bodyFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_format'],
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}remote_updated_at'],
      ),
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      hasAttachments: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_attachments'],
      )!,
      detailFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detail_fetched_at'],
      ),
      headerFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}header_fingerprint'],
      ),
      rawHeaderJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_header_json'],
      ),
      rawDetailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_detail_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;

  /// Provider name, always 'smartschool' for now.
  final String source;

  /// ID of the message as assigned by the remote provider.
  final String externalId;

  /// Mailbox/folder name, e.g. 'inbox', 'sent', 'trash'.
  final String mailbox;
  final String subject;

  /// Original body as received (typically HTML).
  final String? bodyRaw;

  /// Normalized plain-text body for FTS and AI processing.
  final String? bodyText;

  /// Format of [bodyRaw], e.g. 'html' or 'plain'.
  final String? bodyFormat;

  /// When the message was sent (may differ from server receive time).
  final DateTime? sentAt;

  /// When we first received / stored this message.
  final DateTime receivedAt;

  /// Timestamp from the remote provider, used for update detection.
  final DateTime? remoteUpdatedAt;
  final bool isRead;
  final bool isArchived;
  final bool isDeleted;
  final bool hasAttachments;

  /// When the full body detail was last fetched and stored.
  final DateTime? detailFetchedAt;

  /// Hash of header fields used to detect remote updates without deep comparison.
  final String? headerFingerprint;

  /// Raw header JSON snapshot for debugging / re-processing.
  final String? rawHeaderJson;

  /// Raw detail JSON snapshot for debugging / re-processing.
  final String? rawDetailJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Message({
    required this.id,
    required this.source,
    required this.externalId,
    required this.mailbox,
    required this.subject,
    this.bodyRaw,
    this.bodyText,
    this.bodyFormat,
    this.sentAt,
    required this.receivedAt,
    this.remoteUpdatedAt,
    required this.isRead,
    required this.isArchived,
    required this.isDeleted,
    required this.hasAttachments,
    this.detailFetchedAt,
    this.headerFingerprint,
    this.rawHeaderJson,
    this.rawDetailJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source'] = Variable<String>(source);
    map['external_id'] = Variable<String>(externalId);
    map['mailbox'] = Variable<String>(mailbox);
    map['subject'] = Variable<String>(subject);
    if (!nullToAbsent || bodyRaw != null) {
      map['body_raw'] = Variable<String>(bodyRaw);
    }
    if (!nullToAbsent || bodyText != null) {
      map['body_text'] = Variable<String>(bodyText);
    }
    if (!nullToAbsent || bodyFormat != null) {
      map['body_format'] = Variable<String>(bodyFormat);
    }
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    map['received_at'] = Variable<DateTime>(receivedAt);
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt);
    }
    map['is_read'] = Variable<bool>(isRead);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['has_attachments'] = Variable<bool>(hasAttachments);
    if (!nullToAbsent || detailFetchedAt != null) {
      map['detail_fetched_at'] = Variable<DateTime>(detailFetchedAt);
    }
    if (!nullToAbsent || headerFingerprint != null) {
      map['header_fingerprint'] = Variable<String>(headerFingerprint);
    }
    if (!nullToAbsent || rawHeaderJson != null) {
      map['raw_header_json'] = Variable<String>(rawHeaderJson);
    }
    if (!nullToAbsent || rawDetailJson != null) {
      map['raw_detail_json'] = Variable<String>(rawDetailJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      source: Value(source),
      externalId: Value(externalId),
      mailbox: Value(mailbox),
      subject: Value(subject),
      bodyRaw: bodyRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyRaw),
      bodyText: bodyText == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyText),
      bodyFormat: bodyFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFormat),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      receivedAt: Value(receivedAt),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      isRead: Value(isRead),
      isArchived: Value(isArchived),
      isDeleted: Value(isDeleted),
      hasAttachments: Value(hasAttachments),
      detailFetchedAt: detailFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(detailFetchedAt),
      headerFingerprint: headerFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(headerFingerprint),
      rawHeaderJson: rawHeaderJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rawHeaderJson),
      rawDetailJson: rawDetailJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rawDetailJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      externalId: serializer.fromJson<String>(json['externalId']),
      mailbox: serializer.fromJson<String>(json['mailbox']),
      subject: serializer.fromJson<String>(json['subject']),
      bodyRaw: serializer.fromJson<String?>(json['bodyRaw']),
      bodyText: serializer.fromJson<String?>(json['bodyText']),
      bodyFormat: serializer.fromJson<String?>(json['bodyFormat']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      remoteUpdatedAt: serializer.fromJson<DateTime?>(json['remoteUpdatedAt']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      hasAttachments: serializer.fromJson<bool>(json['hasAttachments']),
      detailFetchedAt: serializer.fromJson<DateTime?>(json['detailFetchedAt']),
      headerFingerprint: serializer.fromJson<String?>(
        json['headerFingerprint'],
      ),
      rawHeaderJson: serializer.fromJson<String?>(json['rawHeaderJson']),
      rawDetailJson: serializer.fromJson<String?>(json['rawDetailJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<String>(source),
      'externalId': serializer.toJson<String>(externalId),
      'mailbox': serializer.toJson<String>(mailbox),
      'subject': serializer.toJson<String>(subject),
      'bodyRaw': serializer.toJson<String?>(bodyRaw),
      'bodyText': serializer.toJson<String?>(bodyText),
      'bodyFormat': serializer.toJson<String?>(bodyFormat),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'remoteUpdatedAt': serializer.toJson<DateTime?>(remoteUpdatedAt),
      'isRead': serializer.toJson<bool>(isRead),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'hasAttachments': serializer.toJson<bool>(hasAttachments),
      'detailFetchedAt': serializer.toJson<DateTime?>(detailFetchedAt),
      'headerFingerprint': serializer.toJson<String?>(headerFingerprint),
      'rawHeaderJson': serializer.toJson<String?>(rawHeaderJson),
      'rawDetailJson': serializer.toJson<String?>(rawDetailJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Message copyWith({
    int? id,
    String? source,
    String? externalId,
    String? mailbox,
    String? subject,
    Value<String?> bodyRaw = const Value.absent(),
    Value<String?> bodyText = const Value.absent(),
    Value<String?> bodyFormat = const Value.absent(),
    Value<DateTime?> sentAt = const Value.absent(),
    DateTime? receivedAt,
    Value<DateTime?> remoteUpdatedAt = const Value.absent(),
    bool? isRead,
    bool? isArchived,
    bool? isDeleted,
    bool? hasAttachments,
    Value<DateTime?> detailFetchedAt = const Value.absent(),
    Value<String?> headerFingerprint = const Value.absent(),
    Value<String?> rawHeaderJson = const Value.absent(),
    Value<String?> rawDetailJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Message(
    id: id ?? this.id,
    source: source ?? this.source,
    externalId: externalId ?? this.externalId,
    mailbox: mailbox ?? this.mailbox,
    subject: subject ?? this.subject,
    bodyRaw: bodyRaw.present ? bodyRaw.value : this.bodyRaw,
    bodyText: bodyText.present ? bodyText.value : this.bodyText,
    bodyFormat: bodyFormat.present ? bodyFormat.value : this.bodyFormat,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    receivedAt: receivedAt ?? this.receivedAt,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    isRead: isRead ?? this.isRead,
    isArchived: isArchived ?? this.isArchived,
    isDeleted: isDeleted ?? this.isDeleted,
    hasAttachments: hasAttachments ?? this.hasAttachments,
    detailFetchedAt: detailFetchedAt.present
        ? detailFetchedAt.value
        : this.detailFetchedAt,
    headerFingerprint: headerFingerprint.present
        ? headerFingerprint.value
        : this.headerFingerprint,
    rawHeaderJson: rawHeaderJson.present
        ? rawHeaderJson.value
        : this.rawHeaderJson,
    rawDetailJson: rawDetailJson.present
        ? rawDetailJson.value
        : this.rawDetailJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      mailbox: data.mailbox.present ? data.mailbox.value : this.mailbox,
      subject: data.subject.present ? data.subject.value : this.subject,
      bodyRaw: data.bodyRaw.present ? data.bodyRaw.value : this.bodyRaw,
      bodyText: data.bodyText.present ? data.bodyText.value : this.bodyText,
      bodyFormat: data.bodyFormat.present
          ? data.bodyFormat.value
          : this.bodyFormat,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      hasAttachments: data.hasAttachments.present
          ? data.hasAttachments.value
          : this.hasAttachments,
      detailFetchedAt: data.detailFetchedAt.present
          ? data.detailFetchedAt.value
          : this.detailFetchedAt,
      headerFingerprint: data.headerFingerprint.present
          ? data.headerFingerprint.value
          : this.headerFingerprint,
      rawHeaderJson: data.rawHeaderJson.present
          ? data.rawHeaderJson.value
          : this.rawHeaderJson,
      rawDetailJson: data.rawDetailJson.present
          ? data.rawDetailJson.value
          : this.rawDetailJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('mailbox: $mailbox, ')
          ..write('subject: $subject, ')
          ..write('bodyRaw: $bodyRaw, ')
          ..write('bodyText: $bodyText, ')
          ..write('bodyFormat: $bodyFormat, ')
          ..write('sentAt: $sentAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('isRead: $isRead, ')
          ..write('isArchived: $isArchived, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('detailFetchedAt: $detailFetchedAt, ')
          ..write('headerFingerprint: $headerFingerprint, ')
          ..write('rawHeaderJson: $rawHeaderJson, ')
          ..write('rawDetailJson: $rawDetailJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    source,
    externalId,
    mailbox,
    subject,
    bodyRaw,
    bodyText,
    bodyFormat,
    sentAt,
    receivedAt,
    remoteUpdatedAt,
    isRead,
    isArchived,
    isDeleted,
    hasAttachments,
    detailFetchedAt,
    headerFingerprint,
    rawHeaderJson,
    rawDetailJson,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.mailbox == this.mailbox &&
          other.subject == this.subject &&
          other.bodyRaw == this.bodyRaw &&
          other.bodyText == this.bodyText &&
          other.bodyFormat == this.bodyFormat &&
          other.sentAt == this.sentAt &&
          other.receivedAt == this.receivedAt &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.isRead == this.isRead &&
          other.isArchived == this.isArchived &&
          other.isDeleted == this.isDeleted &&
          other.hasAttachments == this.hasAttachments &&
          other.detailFetchedAt == this.detailFetchedAt &&
          other.headerFingerprint == this.headerFingerprint &&
          other.rawHeaderJson == this.rawHeaderJson &&
          other.rawDetailJson == this.rawDetailJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<String> source;
  final Value<String> externalId;
  final Value<String> mailbox;
  final Value<String> subject;
  final Value<String?> bodyRaw;
  final Value<String?> bodyText;
  final Value<String?> bodyFormat;
  final Value<DateTime?> sentAt;
  final Value<DateTime> receivedAt;
  final Value<DateTime?> remoteUpdatedAt;
  final Value<bool> isRead;
  final Value<bool> isArchived;
  final Value<bool> isDeleted;
  final Value<bool> hasAttachments;
  final Value<DateTime?> detailFetchedAt;
  final Value<String?> headerFingerprint;
  final Value<String?> rawHeaderJson;
  final Value<String?> rawDetailJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.mailbox = const Value.absent(),
    this.subject = const Value.absent(),
    this.bodyRaw = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.bodyFormat = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.detailFetchedAt = const Value.absent(),
    this.headerFingerprint = const Value.absent(),
    this.rawHeaderJson = const Value.absent(),
    this.rawDetailJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required String source,
    required String externalId,
    required String mailbox,
    this.subject = const Value.absent(),
    this.bodyRaw = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.bodyFormat = const Value.absent(),
    this.sentAt = const Value.absent(),
    required DateTime receivedAt,
    this.remoteUpdatedAt = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.detailFetchedAt = const Value.absent(),
    this.headerFingerprint = const Value.absent(),
    this.rawHeaderJson = const Value.absent(),
    this.rawDetailJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : source = Value(source),
       externalId = Value(externalId),
       mailbox = Value(mailbox),
       receivedAt = Value(receivedAt);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? mailbox,
    Expression<String>? subject,
    Expression<String>? bodyRaw,
    Expression<String>? bodyText,
    Expression<String>? bodyFormat,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? remoteUpdatedAt,
    Expression<bool>? isRead,
    Expression<bool>? isArchived,
    Expression<bool>? isDeleted,
    Expression<bool>? hasAttachments,
    Expression<DateTime>? detailFetchedAt,
    Expression<String>? headerFingerprint,
    Expression<String>? rawHeaderJson,
    Expression<String>? rawDetailJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (mailbox != null) 'mailbox': mailbox,
      if (subject != null) 'subject': subject,
      if (bodyRaw != null) 'body_raw': bodyRaw,
      if (bodyText != null) 'body_text': bodyText,
      if (bodyFormat != null) 'body_format': bodyFormat,
      if (sentAt != null) 'sent_at': sentAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (isRead != null) 'is_read': isRead,
      if (isArchived != null) 'is_archived': isArchived,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (hasAttachments != null) 'has_attachments': hasAttachments,
      if (detailFetchedAt != null) 'detail_fetched_at': detailFetchedAt,
      if (headerFingerprint != null) 'header_fingerprint': headerFingerprint,
      if (rawHeaderJson != null) 'raw_header_json': rawHeaderJson,
      if (rawDetailJson != null) 'raw_detail_json': rawDetailJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? source,
    Value<String>? externalId,
    Value<String>? mailbox,
    Value<String>? subject,
    Value<String?>? bodyRaw,
    Value<String?>? bodyText,
    Value<String?>? bodyFormat,
    Value<DateTime?>? sentAt,
    Value<DateTime>? receivedAt,
    Value<DateTime?>? remoteUpdatedAt,
    Value<bool>? isRead,
    Value<bool>? isArchived,
    Value<bool>? isDeleted,
    Value<bool>? hasAttachments,
    Value<DateTime?>? detailFetchedAt,
    Value<String?>? headerFingerprint,
    Value<String?>? rawHeaderJson,
    Value<String?>? rawDetailJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      mailbox: mailbox ?? this.mailbox,
      subject: subject ?? this.subject,
      bodyRaw: bodyRaw ?? this.bodyRaw,
      bodyText: bodyText ?? this.bodyText,
      bodyFormat: bodyFormat ?? this.bodyFormat,
      sentAt: sentAt ?? this.sentAt,
      receivedAt: receivedAt ?? this.receivedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      detailFetchedAt: detailFetchedAt ?? this.detailFetchedAt,
      headerFingerprint: headerFingerprint ?? this.headerFingerprint,
      rawHeaderJson: rawHeaderJson ?? this.rawHeaderJson,
      rawDetailJson: rawDetailJson ?? this.rawDetailJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (mailbox.present) {
      map['mailbox'] = Variable<String>(mailbox.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (bodyRaw.present) {
      map['body_raw'] = Variable<String>(bodyRaw.value);
    }
    if (bodyText.present) {
      map['body_text'] = Variable<String>(bodyText.value);
    }
    if (bodyFormat.present) {
      map['body_format'] = Variable<String>(bodyFormat.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (hasAttachments.present) {
      map['has_attachments'] = Variable<bool>(hasAttachments.value);
    }
    if (detailFetchedAt.present) {
      map['detail_fetched_at'] = Variable<DateTime>(detailFetchedAt.value);
    }
    if (headerFingerprint.present) {
      map['header_fingerprint'] = Variable<String>(headerFingerprint.value);
    }
    if (rawHeaderJson.present) {
      map['raw_header_json'] = Variable<String>(rawHeaderJson.value);
    }
    if (rawDetailJson.present) {
      map['raw_detail_json'] = Variable<String>(rawDetailJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('mailbox: $mailbox, ')
          ..write('subject: $subject, ')
          ..write('bodyRaw: $bodyRaw, ')
          ..write('bodyText: $bodyText, ')
          ..write('bodyFormat: $bodyFormat, ')
          ..write('sentAt: $sentAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('isRead: $isRead, ')
          ..write('isArchived: $isArchived, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('detailFetchedAt: $detailFetchedAt, ')
          ..write('headerFingerprint: $headerFingerprint, ')
          ..write('rawHeaderJson: $rawHeaderJson, ')
          ..write('rawDetailJson: $rawDetailJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MessageParticipantsTable extends MessageParticipants
    with TableInfo<$MessageParticipantsTable, MessageParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES messages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
    'contact_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contacts (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _contactIdentityIdMeta = const VerificationMeta(
    'contactIdentityId',
  );
  @override
  late final GeneratedColumn<int> contactIdentityId = GeneratedColumn<int>(
    'contact_identity_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contact_identities (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _displayNameSnapshotMeta =
      const VerificationMeta('displayNameSnapshot');
  @override
  late final GeneratedColumn<String> displayNameSnapshot =
      GeneratedColumn<String>(
        'display_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _addressSnapshotMeta = const VerificationMeta(
    'addressSnapshot',
  );
  @override
  late final GeneratedColumn<String> addressSnapshot = GeneratedColumn<String>(
    'address_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageId,
    contactId,
    contactIdentityId,
    role,
    position,
    displayNameSnapshot,
    addressSnapshot,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    if (data.containsKey('contact_identity_id')) {
      context.handle(
        _contactIdentityIdMeta,
        contactIdentityId.isAcceptableOrUnknown(
          data['contact_identity_id']!,
          _contactIdentityIdMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('display_name_snapshot')) {
      context.handle(
        _displayNameSnapshotMeta,
        displayNameSnapshot.isAcceptableOrUnknown(
          data['display_name_snapshot']!,
          _displayNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameSnapshotMeta);
    }
    if (data.containsKey('address_snapshot')) {
      context.handle(
        _addressSnapshotMeta,
        addressSnapshot.isAcceptableOrUnknown(
          data['address_snapshot']!,
          _addressSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageParticipant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_id'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contact_id'],
      ),
      contactIdentityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contact_identity_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      displayNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name_snapshot'],
      )!,
      addressSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_snapshot'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessageParticipantsTable createAlias(String alias) {
    return $MessageParticipantsTable(attachedDatabase, alias);
  }
}

class MessageParticipant extends DataClass
    implements Insertable<MessageParticipant> {
  final int id;
  final int messageId;

  /// May be null for stub/unresolved participants.
  final int? contactId;

  /// The specific identity this participant was resolved from.
  final int? contactIdentityId;

  /// Role in this message: 'sender', 'to', 'cc', 'bcc'.
  final String role;

  /// Position within the role group (0-based).
  final int position;

  /// Display name as it appeared when the message was ingested.
  final String displayNameSnapshot;

  /// Email address or other identifier snapshot.
  final String? addressSnapshot;
  final DateTime createdAt;
  const MessageParticipant({
    required this.id,
    required this.messageId,
    this.contactId,
    this.contactIdentityId,
    required this.role,
    required this.position,
    required this.displayNameSnapshot,
    this.addressSnapshot,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<int>(messageId);
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<int>(contactId);
    }
    if (!nullToAbsent || contactIdentityId != null) {
      map['contact_identity_id'] = Variable<int>(contactIdentityId);
    }
    map['role'] = Variable<String>(role);
    map['position'] = Variable<int>(position);
    map['display_name_snapshot'] = Variable<String>(displayNameSnapshot);
    if (!nullToAbsent || addressSnapshot != null) {
      map['address_snapshot'] = Variable<String>(addressSnapshot);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessageParticipantsCompanion toCompanion(bool nullToAbsent) {
    return MessageParticipantsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      contactIdentityId: contactIdentityId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactIdentityId),
      role: Value(role),
      position: Value(position),
      displayNameSnapshot: Value(displayNameSnapshot),
      addressSnapshot: addressSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(addressSnapshot),
      createdAt: Value(createdAt),
    );
  }

  factory MessageParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageParticipant(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<int>(json['messageId']),
      contactId: serializer.fromJson<int?>(json['contactId']),
      contactIdentityId: serializer.fromJson<int?>(json['contactIdentityId']),
      role: serializer.fromJson<String>(json['role']),
      position: serializer.fromJson<int>(json['position']),
      displayNameSnapshot: serializer.fromJson<String>(
        json['displayNameSnapshot'],
      ),
      addressSnapshot: serializer.fromJson<String?>(json['addressSnapshot']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<int>(messageId),
      'contactId': serializer.toJson<int?>(contactId),
      'contactIdentityId': serializer.toJson<int?>(contactIdentityId),
      'role': serializer.toJson<String>(role),
      'position': serializer.toJson<int>(position),
      'displayNameSnapshot': serializer.toJson<String>(displayNameSnapshot),
      'addressSnapshot': serializer.toJson<String?>(addressSnapshot),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessageParticipant copyWith({
    int? id,
    int? messageId,
    Value<int?> contactId = const Value.absent(),
    Value<int?> contactIdentityId = const Value.absent(),
    String? role,
    int? position,
    String? displayNameSnapshot,
    Value<String?> addressSnapshot = const Value.absent(),
    DateTime? createdAt,
  }) => MessageParticipant(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    contactId: contactId.present ? contactId.value : this.contactId,
    contactIdentityId: contactIdentityId.present
        ? contactIdentityId.value
        : this.contactIdentityId,
    role: role ?? this.role,
    position: position ?? this.position,
    displayNameSnapshot: displayNameSnapshot ?? this.displayNameSnapshot,
    addressSnapshot: addressSnapshot.present
        ? addressSnapshot.value
        : this.addressSnapshot,
    createdAt: createdAt ?? this.createdAt,
  );
  MessageParticipant copyWithCompanion(MessageParticipantsCompanion data) {
    return MessageParticipant(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      contactIdentityId: data.contactIdentityId.present
          ? data.contactIdentityId.value
          : this.contactIdentityId,
      role: data.role.present ? data.role.value : this.role,
      position: data.position.present ? data.position.value : this.position,
      displayNameSnapshot: data.displayNameSnapshot.present
          ? data.displayNameSnapshot.value
          : this.displayNameSnapshot,
      addressSnapshot: data.addressSnapshot.present
          ? data.addressSnapshot.value
          : this.addressSnapshot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageParticipant(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('contactId: $contactId, ')
          ..write('contactIdentityId: $contactIdentityId, ')
          ..write('role: $role, ')
          ..write('position: $position, ')
          ..write('displayNameSnapshot: $displayNameSnapshot, ')
          ..write('addressSnapshot: $addressSnapshot, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messageId,
    contactId,
    contactIdentityId,
    role,
    position,
    displayNameSnapshot,
    addressSnapshot,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageParticipant &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.contactId == this.contactId &&
          other.contactIdentityId == this.contactIdentityId &&
          other.role == this.role &&
          other.position == this.position &&
          other.displayNameSnapshot == this.displayNameSnapshot &&
          other.addressSnapshot == this.addressSnapshot &&
          other.createdAt == this.createdAt);
}

class MessageParticipantsCompanion extends UpdateCompanion<MessageParticipant> {
  final Value<int> id;
  final Value<int> messageId;
  final Value<int?> contactId;
  final Value<int?> contactIdentityId;
  final Value<String> role;
  final Value<int> position;
  final Value<String> displayNameSnapshot;
  final Value<String?> addressSnapshot;
  final Value<DateTime> createdAt;
  const MessageParticipantsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.contactIdentityId = const Value.absent(),
    this.role = const Value.absent(),
    this.position = const Value.absent(),
    this.displayNameSnapshot = const Value.absent(),
    this.addressSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MessageParticipantsCompanion.insert({
    this.id = const Value.absent(),
    required int messageId,
    this.contactId = const Value.absent(),
    this.contactIdentityId = const Value.absent(),
    required String role,
    this.position = const Value.absent(),
    required String displayNameSnapshot,
    this.addressSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : messageId = Value(messageId),
       role = Value(role),
       displayNameSnapshot = Value(displayNameSnapshot);
  static Insertable<MessageParticipant> custom({
    Expression<int>? id,
    Expression<int>? messageId,
    Expression<int>? contactId,
    Expression<int>? contactIdentityId,
    Expression<String>? role,
    Expression<int>? position,
    Expression<String>? displayNameSnapshot,
    Expression<String>? addressSnapshot,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (contactId != null) 'contact_id': contactId,
      if (contactIdentityId != null) 'contact_identity_id': contactIdentityId,
      if (role != null) 'role': role,
      if (position != null) 'position': position,
      if (displayNameSnapshot != null)
        'display_name_snapshot': displayNameSnapshot,
      if (addressSnapshot != null) 'address_snapshot': addressSnapshot,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MessageParticipantsCompanion copyWith({
    Value<int>? id,
    Value<int>? messageId,
    Value<int?>? contactId,
    Value<int?>? contactIdentityId,
    Value<String>? role,
    Value<int>? position,
    Value<String>? displayNameSnapshot,
    Value<String?>? addressSnapshot,
    Value<DateTime>? createdAt,
  }) {
    return MessageParticipantsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      contactId: contactId ?? this.contactId,
      contactIdentityId: contactIdentityId ?? this.contactIdentityId,
      role: role ?? this.role,
      position: position ?? this.position,
      displayNameSnapshot: displayNameSnapshot ?? this.displayNameSnapshot,
      addressSnapshot: addressSnapshot ?? this.addressSnapshot,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (contactIdentityId.present) {
      map['contact_identity_id'] = Variable<int>(contactIdentityId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (displayNameSnapshot.present) {
      map['display_name_snapshot'] = Variable<String>(
        displayNameSnapshot.value,
      );
    }
    if (addressSnapshot.present) {
      map['address_snapshot'] = Variable<String>(addressSnapshot.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('contactId: $contactId, ')
          ..write('contactIdentityId: $contactIdentityId, ')
          ..write('role: $role, ')
          ..write('position: $position, ')
          ..write('displayNameSnapshot: $displayNameSnapshot, ')
          ..write('addressSnapshot: $addressSnapshot, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MessageAttachmentsTable extends MessageAttachments
    with TableInfo<$MessageAttachmentsTable, MessageAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES messages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isInlineMeta = const VerificationMeta(
    'isInline',
  );
  @override
  late final GeneratedColumn<bool> isInline = GeneratedColumn<bool>(
    'is_inline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_inline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _downloadStatusMeta = const VerificationMeta(
    'downloadStatus',
  );
  @override
  late final GeneratedColumn<String> downloadStatus = GeneratedColumn<String>(
    'download_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localSha256Meta = const VerificationMeta(
    'localSha256',
  );
  @override
  late final GeneratedColumn<String> localSha256 = GeneratedColumn<String>(
    'local_sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageId,
    source,
    externalId,
    filename,
    mimeType,
    sizeBytes,
    isInline,
    downloadStatus,
    localPath,
    localSha256,
    downloadedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('is_inline')) {
      context.handle(
        _isInlineMeta,
        isInline.isAcceptableOrUnknown(data['is_inline']!, _isInlineMeta),
      );
    }
    if (data.containsKey('download_status')) {
      context.handle(
        _downloadStatusMeta,
        downloadStatus.isAcceptableOrUnknown(
          data['download_status']!,
          _downloadStatusMeta,
        ),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('local_sha256')) {
      context.handle(
        _localSha256Meta,
        localSha256.isAcceptableOrUnknown(
          data['local_sha256']!,
          _localSha256Meta,
        ),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      isInline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_inline'],
      )!,
      downloadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_status'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      localSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_sha256'],
      ),
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MessageAttachmentsTable createAlias(String alias) {
    return $MessageAttachmentsTable(attachedDatabase, alias);
  }
}

class MessageAttachment extends DataClass
    implements Insertable<MessageAttachment> {
  final int id;
  final int messageId;

  /// Provider name, e.g. 'smartschool'.
  final String source;

  /// Provider-assigned attachment identifier, if available.
  final String? externalId;

  /// Original filename as provided by the remote source.
  final String filename;
  final String? mimeType;
  final int? sizeBytes;

  /// True for inline/embedded attachments (e.g. inline images).
  final bool isInline;

  /// Download lifecycle state.
  ///
  /// Values: 'none', 'queued', 'downloading', 'downloaded', 'failed'
  final String downloadStatus;

  /// Absolute path to the locally cached file, if downloaded.
  final String? localPath;

  /// SHA-256 hex digest of the local file, populated after download.
  final String? localSha256;
  final DateTime? downloadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MessageAttachment({
    required this.id,
    required this.messageId,
    required this.source,
    this.externalId,
    required this.filename,
    this.mimeType,
    this.sizeBytes,
    required this.isInline,
    required this.downloadStatus,
    this.localPath,
    this.localSha256,
    this.downloadedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<int>(messageId);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['filename'] = Variable<String>(filename);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['is_inline'] = Variable<bool>(isInline);
    map['download_status'] = Variable<String>(downloadStatus);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || localSha256 != null) {
      map['local_sha256'] = Variable<String>(localSha256);
    }
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MessageAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return MessageAttachmentsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      source: Value(source),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      filename: Value(filename),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      isInline: Value(isInline),
      downloadStatus: Value(downloadStatus),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      localSha256: localSha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(localSha256),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MessageAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageAttachment(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<int>(json['messageId']),
      source: serializer.fromJson<String>(json['source']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      filename: serializer.fromJson<String>(json['filename']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      isInline: serializer.fromJson<bool>(json['isInline']),
      downloadStatus: serializer.fromJson<String>(json['downloadStatus']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      localSha256: serializer.fromJson<String?>(json['localSha256']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<int>(messageId),
      'source': serializer.toJson<String>(source),
      'externalId': serializer.toJson<String?>(externalId),
      'filename': serializer.toJson<String>(filename),
      'mimeType': serializer.toJson<String?>(mimeType),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'isInline': serializer.toJson<bool>(isInline),
      'downloadStatus': serializer.toJson<String>(downloadStatus),
      'localPath': serializer.toJson<String?>(localPath),
      'localSha256': serializer.toJson<String?>(localSha256),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MessageAttachment copyWith({
    int? id,
    int? messageId,
    String? source,
    Value<String?> externalId = const Value.absent(),
    String? filename,
    Value<String?> mimeType = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    bool? isInline,
    String? downloadStatus,
    Value<String?> localPath = const Value.absent(),
    Value<String?> localSha256 = const Value.absent(),
    Value<DateTime?> downloadedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MessageAttachment(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    source: source ?? this.source,
    externalId: externalId.present ? externalId.value : this.externalId,
    filename: filename ?? this.filename,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    isInline: isInline ?? this.isInline,
    downloadStatus: downloadStatus ?? this.downloadStatus,
    localPath: localPath.present ? localPath.value : this.localPath,
    localSha256: localSha256.present ? localSha256.value : this.localSha256,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MessageAttachment copyWithCompanion(MessageAttachmentsCompanion data) {
    return MessageAttachment(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      filename: data.filename.present ? data.filename.value : this.filename,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      isInline: data.isInline.present ? data.isInline.value : this.isInline,
      downloadStatus: data.downloadStatus.present
          ? data.downloadStatus.value
          : this.downloadStatus,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      localSha256: data.localSha256.present
          ? data.localSha256.value
          : this.localSha256,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachment(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isInline: $isInline, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('localPath: $localPath, ')
          ..write('localSha256: $localSha256, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messageId,
    source,
    externalId,
    filename,
    mimeType,
    sizeBytes,
    isInline,
    downloadStatus,
    localPath,
    localSha256,
    downloadedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageAttachment &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.filename == this.filename &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.isInline == this.isInline &&
          other.downloadStatus == this.downloadStatus &&
          other.localPath == this.localPath &&
          other.localSha256 == this.localSha256 &&
          other.downloadedAt == this.downloadedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MessageAttachmentsCompanion extends UpdateCompanion<MessageAttachment> {
  final Value<int> id;
  final Value<int> messageId;
  final Value<String> source;
  final Value<String?> externalId;
  final Value<String> filename;
  final Value<String?> mimeType;
  final Value<int?> sizeBytes;
  final Value<bool> isInline;
  final Value<String> downloadStatus;
  final Value<String?> localPath;
  final Value<String?> localSha256;
  final Value<DateTime?> downloadedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MessageAttachmentsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.filename = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isInline = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.localPath = const Value.absent(),
    this.localSha256 = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MessageAttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required int messageId,
    required String source,
    this.externalId = const Value.absent(),
    required String filename,
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isInline = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.localPath = const Value.absent(),
    this.localSha256 = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : messageId = Value(messageId),
       source = Value(source),
       filename = Value(filename);
  static Insertable<MessageAttachment> custom({
    Expression<int>? id,
    Expression<int>? messageId,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? filename,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<bool>? isInline,
    Expression<String>? downloadStatus,
    Expression<String>? localPath,
    Expression<String>? localSha256,
    Expression<DateTime>? downloadedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (filename != null) 'filename': filename,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (isInline != null) 'is_inline': isInline,
      if (downloadStatus != null) 'download_status': downloadStatus,
      if (localPath != null) 'local_path': localPath,
      if (localSha256 != null) 'local_sha256': localSha256,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MessageAttachmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? messageId,
    Value<String>? source,
    Value<String?>? externalId,
    Value<String>? filename,
    Value<String?>? mimeType,
    Value<int?>? sizeBytes,
    Value<bool>? isInline,
    Value<String>? downloadStatus,
    Value<String?>? localPath,
    Value<String?>? localSha256,
    Value<DateTime?>? downloadedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MessageAttachmentsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isInline: isInline ?? this.isInline,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      localPath: localPath ?? this.localPath,
      localSha256: localSha256 ?? this.localSha256,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (isInline.present) {
      map['is_inline'] = Variable<bool>(isInline.value);
    }
    if (downloadStatus.present) {
      map['download_status'] = Variable<String>(downloadStatus.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (localSha256.present) {
      map['local_sha256'] = Variable<String>(localSha256.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('filename: $filename, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isInline: $isInline, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('localPath: $localPath, ')
          ..write('localSha256: $localSha256, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingOutgoingMessagesTable extends PendingOutgoingMessages
    with TableInfo<$PendingOutgoingMessagesTable, PendingOutgoingMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOutgoingMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payloadJson,
    subject,
    attemptCount,
    lastAttemptAt,
    nextAttemptAt,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_outgoing_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOutgoingMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOutgoingMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOutgoingMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PendingOutgoingMessagesTable createAlias(String alias) {
    return $PendingOutgoingMessagesTable(attachedDatabase, alias);
  }
}

class PendingOutgoingMessage extends DataClass
    implements Insertable<PendingOutgoingMessage> {
  final int id;

  /// Serialized draft payload ready to be reconstructed for retry.
  final String payloadJson;

  /// Convenience copy for debugging / quick inspection.
  final String subject;
  final int attemptCount;
  final DateTime? lastAttemptAt;

  /// Earliest timestamp when this row should be retried again.
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PendingOutgoingMessage({
    required this.id,
    required this.payloadJson,
    required this.subject,
    required this.attemptCount,
    this.lastAttemptAt,
    this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['subject'] = Variable<String>(subject);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PendingOutgoingMessagesCompanion toCompanion(bool nullToAbsent) {
    return PendingOutgoingMessagesCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      subject: Value(subject),
      attemptCount: Value(attemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PendingOutgoingMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOutgoingMessage(
      id: serializer.fromJson<int>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      subject: serializer.fromJson<String>(json['subject']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'subject': serializer.toJson<String>(subject),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PendingOutgoingMessage copyWith({
    int? id,
    String? payloadJson,
    String? subject,
    int? attemptCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PendingOutgoingMessage(
    id: id ?? this.id,
    payloadJson: payloadJson ?? this.payloadJson,
    subject: subject ?? this.subject,
    attemptCount: attemptCount ?? this.attemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PendingOutgoingMessage copyWithCompanion(
    PendingOutgoingMessagesCompanion data,
  ) {
    return PendingOutgoingMessage(
      id: data.id.present ? data.id.value : this.id,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      subject: data.subject.present ? data.subject.value : this.subject,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOutgoingMessage(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('subject: $subject, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    payloadJson,
    subject,
    attemptCount,
    lastAttemptAt,
    nextAttemptAt,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOutgoingMessage &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.subject == this.subject &&
          other.attemptCount == this.attemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PendingOutgoingMessagesCompanion
    extends UpdateCompanion<PendingOutgoingMessage> {
  final Value<int> id;
  final Value<String> payloadJson;
  final Value<String> subject;
  final Value<int> attemptCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PendingOutgoingMessagesCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.subject = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PendingOutgoingMessagesCompanion.insert({
    this.id = const Value.absent(),
    required String payloadJson,
    this.subject = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : payloadJson = Value(payloadJson);
  static Insertable<PendingOutgoingMessage> custom({
    Expression<int>? id,
    Expression<String>? payloadJson,
    Expression<String>? subject,
    Expression<int>? attemptCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (subject != null) 'subject': subject,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PendingOutgoingMessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? payloadJson,
    Value<String>? subject,
    Value<int>? attemptCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PendingOutgoingMessagesCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
      subject: subject ?? this.subject,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOutgoingMessagesCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('subject: $subject, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSuccessAtMeta = const VerificationMeta(
    'lastSuccessAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSuccessAt =
      GeneratedColumn<DateTime>(
        'last_success_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _remoteCursorMeta = const VerificationMeta(
    'remoteCursor',
  );
  @override
  late final GeneratedColumn<String> remoteCursor = GeneratedColumn<String>(
    'remote_cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _highWaterReceivedAtMeta =
      const VerificationMeta('highWaterReceivedAt');
  @override
  late final GeneratedColumn<DateTime> highWaterReceivedAt =
      GeneratedColumn<DateTime>(
        'high_water_received_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _highWaterExternalIdMeta =
      const VerificationMeta('highWaterExternalId');
  @override
  late final GeneratedColumn<String> highWaterExternalId =
      GeneratedColumn<String>(
        'high_water_external_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureCountMeta = const VerificationMeta(
    'failureCount',
  );
  @override
  late final GeneratedColumn<int> failureCount = GeneratedColumn<int>(
    'failure_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    scope,
    lastAttemptAt,
    lastSuccessAt,
    remoteCursor,
    highWaterReceivedAt,
    highWaterExternalId,
    lastError,
    failureCount,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
        _lastSuccessAtMeta,
        lastSuccessAt.isAcceptableOrUnknown(
          data['last_success_at']!,
          _lastSuccessAtMeta,
        ),
      );
    }
    if (data.containsKey('remote_cursor')) {
      context.handle(
        _remoteCursorMeta,
        remoteCursor.isAcceptableOrUnknown(
          data['remote_cursor']!,
          _remoteCursorMeta,
        ),
      );
    }
    if (data.containsKey('high_water_received_at')) {
      context.handle(
        _highWaterReceivedAtMeta,
        highWaterReceivedAt.isAcceptableOrUnknown(
          data['high_water_received_at']!,
          _highWaterReceivedAtMeta,
        ),
      );
    }
    if (data.containsKey('high_water_external_id')) {
      context.handle(
        _highWaterExternalIdMeta,
        highWaterExternalId.isAcceptableOrUnknown(
          data['high_water_external_id']!,
          _highWaterExternalIdMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('failure_count')) {
      context.handle(
        _failureCountMeta,
        failureCount.isAcceptableOrUnknown(
          data['failure_count']!,
          _failureCountMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {source, scope},
  ];
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastSuccessAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_success_at'],
      ),
      remoteCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_cursor'],
      ),
      highWaterReceivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}high_water_received_at'],
      ),
      highWaterExternalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}high_water_external_id'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      failureCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failure_count'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final int id;

  /// Provider name, e.g. 'smartschool'.
  final String source;

  /// Functional scope within the provider, e.g. 'inbox', 'sent'.
  final String scope;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;

  /// Opaque cursor/delta token from the remote provider, if supported.
  final String? remoteCursor;

  /// Timestamp of the highest received_at seen in the last successful sync.
  final DateTime? highWaterReceivedAt;

  /// External ID of the newest message seen in the last successful sync.
  final String? highWaterExternalId;

  /// Serialized error from the last failed attempt.
  final String? lastError;
  final int failureCount;
  final DateTime updatedAt;
  const SyncStateData({
    required this.id,
    required this.source,
    required this.scope,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.remoteCursor,
    this.highWaterReceivedAt,
    this.highWaterExternalId,
    this.lastError,
    required this.failureCount,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source'] = Variable<String>(source);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt);
    }
    if (!nullToAbsent || remoteCursor != null) {
      map['remote_cursor'] = Variable<String>(remoteCursor);
    }
    if (!nullToAbsent || highWaterReceivedAt != null) {
      map['high_water_received_at'] = Variable<DateTime>(highWaterReceivedAt);
    }
    if (!nullToAbsent || highWaterExternalId != null) {
      map['high_water_external_id'] = Variable<String>(highWaterExternalId);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['failure_count'] = Variable<int>(failureCount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      source: Value(source),
      scope: Value(scope),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      remoteCursor: remoteCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteCursor),
      highWaterReceivedAt: highWaterReceivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(highWaterReceivedAt),
      highWaterExternalId: highWaterExternalId == null && nullToAbsent
          ? const Value.absent()
          : Value(highWaterExternalId),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      failureCount: Value(failureCount),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      id: serializer.fromJson<int>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      scope: serializer.fromJson<String>(json['scope']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastSuccessAt: serializer.fromJson<DateTime?>(json['lastSuccessAt']),
      remoteCursor: serializer.fromJson<String?>(json['remoteCursor']),
      highWaterReceivedAt: serializer.fromJson<DateTime?>(
        json['highWaterReceivedAt'],
      ),
      highWaterExternalId: serializer.fromJson<String?>(
        json['highWaterExternalId'],
      ),
      lastError: serializer.fromJson<String?>(json['lastError']),
      failureCount: serializer.fromJson<int>(json['failureCount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<String>(source),
      'scope': serializer.toJson<String>(scope),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastSuccessAt': serializer.toJson<DateTime?>(lastSuccessAt),
      'remoteCursor': serializer.toJson<String?>(remoteCursor),
      'highWaterReceivedAt': serializer.toJson<DateTime?>(highWaterReceivedAt),
      'highWaterExternalId': serializer.toJson<String?>(highWaterExternalId),
      'lastError': serializer.toJson<String?>(lastError),
      'failureCount': serializer.toJson<int>(failureCount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncStateData copyWith({
    int? id,
    String? source,
    String? scope,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> lastSuccessAt = const Value.absent(),
    Value<String?> remoteCursor = const Value.absent(),
    Value<DateTime?> highWaterReceivedAt = const Value.absent(),
    Value<String?> highWaterExternalId = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? failureCount,
    DateTime? updatedAt,
  }) => SyncStateData(
    id: id ?? this.id,
    source: source ?? this.source,
    scope: scope ?? this.scope,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastSuccessAt: lastSuccessAt.present
        ? lastSuccessAt.value
        : this.lastSuccessAt,
    remoteCursor: remoteCursor.present ? remoteCursor.value : this.remoteCursor,
    highWaterReceivedAt: highWaterReceivedAt.present
        ? highWaterReceivedAt.value
        : this.highWaterReceivedAt,
    highWaterExternalId: highWaterExternalId.present
        ? highWaterExternalId.value
        : this.highWaterExternalId,
    lastError: lastError.present ? lastError.value : this.lastError,
    failureCount: failureCount ?? this.failureCount,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      scope: data.scope.present ? data.scope.value : this.scope,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      remoteCursor: data.remoteCursor.present
          ? data.remoteCursor.value
          : this.remoteCursor,
      highWaterReceivedAt: data.highWaterReceivedAt.present
          ? data.highWaterReceivedAt.value
          : this.highWaterReceivedAt,
      highWaterExternalId: data.highWaterExternalId.present
          ? data.highWaterExternalId.value
          : this.highWaterExternalId,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      failureCount: data.failureCount.present
          ? data.failureCount.value
          : this.failureCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('scope: $scope, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('remoteCursor: $remoteCursor, ')
          ..write('highWaterReceivedAt: $highWaterReceivedAt, ')
          ..write('highWaterExternalId: $highWaterExternalId, ')
          ..write('lastError: $lastError, ')
          ..write('failureCount: $failureCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    scope,
    lastAttemptAt,
    lastSuccessAt,
    remoteCursor,
    highWaterReceivedAt,
    highWaterExternalId,
    lastError,
    failureCount,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.id == this.id &&
          other.source == this.source &&
          other.scope == this.scope &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.remoteCursor == this.remoteCursor &&
          other.highWaterReceivedAt == this.highWaterReceivedAt &&
          other.highWaterExternalId == this.highWaterExternalId &&
          other.lastError == this.lastError &&
          other.failureCount == this.failureCount &&
          other.updatedAt == this.updatedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<int> id;
  final Value<String> source;
  final Value<String> scope;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> lastSuccessAt;
  final Value<String?> remoteCursor;
  final Value<DateTime?> highWaterReceivedAt;
  final Value<String?> highWaterExternalId;
  final Value<String?> lastError;
  final Value<int> failureCount;
  final Value<DateTime> updatedAt;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.scope = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.remoteCursor = const Value.absent(),
    this.highWaterReceivedAt = const Value.absent(),
    this.highWaterExternalId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.failureCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    required String source,
    required String scope,
    this.lastAttemptAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.remoteCursor = const Value.absent(),
    this.highWaterReceivedAt = const Value.absent(),
    this.highWaterExternalId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.failureCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : source = Value(source),
       scope = Value(scope);
  static Insertable<SyncStateData> custom({
    Expression<int>? id,
    Expression<String>? source,
    Expression<String>? scope,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? lastSuccessAt,
    Expression<String>? remoteCursor,
    Expression<DateTime>? highWaterReceivedAt,
    Expression<String>? highWaterExternalId,
    Expression<String>? lastError,
    Expression<int>? failureCount,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (scope != null) 'scope': scope,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (remoteCursor != null) 'remote_cursor': remoteCursor,
      if (highWaterReceivedAt != null)
        'high_water_received_at': highWaterReceivedAt,
      if (highWaterExternalId != null)
        'high_water_external_id': highWaterExternalId,
      if (lastError != null) 'last_error': lastError,
      if (failureCount != null) 'failure_count': failureCount,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncStateCompanion copyWith({
    Value<int>? id,
    Value<String>? source,
    Value<String>? scope,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? lastSuccessAt,
    Value<String?>? remoteCursor,
    Value<DateTime?>? highWaterReceivedAt,
    Value<String?>? highWaterExternalId,
    Value<String?>? lastError,
    Value<int>? failureCount,
    Value<DateTime>? updatedAt,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      scope: scope ?? this.scope,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      remoteCursor: remoteCursor ?? this.remoteCursor,
      highWaterReceivedAt: highWaterReceivedAt ?? this.highWaterReceivedAt,
      highWaterExternalId: highWaterExternalId ?? this.highWaterExternalId,
      lastError: lastError ?? this.lastError,
      failureCount: failureCount ?? this.failureCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt.value);
    }
    if (remoteCursor.present) {
      map['remote_cursor'] = Variable<String>(remoteCursor.value);
    }
    if (highWaterReceivedAt.present) {
      map['high_water_received_at'] = Variable<DateTime>(
        highWaterReceivedAt.value,
      );
    }
    if (highWaterExternalId.present) {
      map['high_water_external_id'] = Variable<String>(
        highWaterExternalId.value,
      );
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (failureCount.present) {
      map['failure_count'] = Variable<int>(failureCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('scope: $scope, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('remoteCursor: $remoteCursor, ')
          ..write('highWaterReceivedAt: $highWaterReceivedAt, ')
          ..write('highWaterExternalId: $highWaterExternalId, ')
          ..write('lastError: $lastError, ')
          ..write('failureCount: $failureCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ContactIdentitiesTable contactIdentities =
      $ContactIdentitiesTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageParticipantsTable messageParticipants =
      $MessageParticipantsTable(this);
  late final $MessageAttachmentsTable messageAttachments =
      $MessageAttachmentsTable(this);
  late final $PendingOutgoingMessagesTable pendingOutgoingMessages =
      $PendingOutgoingMessagesTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final ContactsDao contactsDao = ContactsDao(this as AppDatabase);
  late final MessagesDao messagesDao = MessagesDao(this as AppDatabase);
  late final AttachmentsDao attachmentsDao = AttachmentsDao(
    this as AppDatabase,
  );
  late final PendingOutgoingMessagesDao pendingOutgoingMessagesDao =
      PendingOutgoingMessagesDao(this as AppDatabase);
  late final SyncStateDao syncStateDao = SyncStateDao(this as AppDatabase);
  late final SearchDao searchDao = SearchDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contacts,
    contactIdentities,
    messages,
    messageParticipants,
    messageAttachments,
    pendingOutgoingMessages,
    syncState,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contacts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contact_identities', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'messages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('message_participants', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contacts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('message_participants', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contact_identities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('message_participants', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'messages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('message_attachments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      Value<int> id,
      required String displayName,
      Value<String?> primaryAvatarUrl,
      Value<String?> kind,
      Value<bool> isStub,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<String?> primaryAvatarUrl,
      Value<String?> kind,
      Value<bool> isStub,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ContactsTableReferences
    extends BaseReferences<_$AppDatabase, $ContactsTable, Contact> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ContactIdentitiesTable, List<ContactIdentity>>
  _contactIdentitiesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contactIdentities,
        aliasName: $_aliasNameGenerator(
          db.contacts.id,
          db.contactIdentities.contactId,
        ),
      );

  $$ContactIdentitiesTableProcessedTableManager get contactIdentitiesRefs {
    final manager = $$ContactIdentitiesTableTableManager(
      $_db,
      $_db.contactIdentities,
    ).filter((f) => f.contactId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contactIdentitiesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MessageParticipantsTable,
    List<MessageParticipant>
  >
  _messageParticipantsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.messageParticipants,
        aliasName: $_aliasNameGenerator(
          db.contacts.id,
          db.messageParticipants.contactId,
        ),
      );

  $$MessageParticipantsTableProcessedTableManager get messageParticipantsRefs {
    final manager = $$MessageParticipantsTableTableManager(
      $_db,
      $_db.messageParticipants,
    ).filter((f) => f.contactId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _messageParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryAvatarUrl => $composableBuilder(
    column: $table.primaryAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStub => $composableBuilder(
    column: $table.isStub,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contactIdentitiesRefs(
    Expression<bool> Function($$ContactIdentitiesTableFilterComposer f) f,
  ) {
    final $$ContactIdentitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactIdentities,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactIdentitiesTableFilterComposer(
            $db: $db,
            $table: $db.contactIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> messageParticipantsRefs(
    Expression<bool> Function($$MessageParticipantsTableFilterComposer f) f,
  ) {
    final $$MessageParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messageParticipants,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.messageParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryAvatarUrl => $composableBuilder(
    column: $table.primaryAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStub => $composableBuilder(
    column: $table.isStub,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryAvatarUrl => $composableBuilder(
    column: $table.primaryAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get isStub =>
      $composableBuilder(column: $table.isStub, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> contactIdentitiesRefs<T extends Object>(
    Expression<T> Function($$ContactIdentitiesTableAnnotationComposer a) f,
  ) {
    final $$ContactIdentitiesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contactIdentities,
          getReferencedColumn: (t) => t.contactId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContactIdentitiesTableAnnotationComposer(
                $db: $db,
                $table: $db.contactIdentities,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> messageParticipantsRefs<T extends Object>(
    Expression<T> Function($$MessageParticipantsTableAnnotationComposer a) f,
  ) {
    final $$MessageParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.messageParticipants,
          getReferencedColumn: (t) => t.contactId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MessageParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.messageParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, $$ContactsTableReferences),
          Contact,
          PrefetchHooks Function({
            bool contactIdentitiesRefs,
            bool messageParticipantsRefs,
          })
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> primaryAvatarUrl = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<bool> isStub = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                displayName: displayName,
                primaryAvatarUrl: primaryAvatarUrl,
                kind: kind,
                isStub: isStub,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                Value<String?> primaryAvatarUrl = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<bool> isStub = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ContactsCompanion.insert(
                id: id,
                displayName: displayName,
                primaryAvatarUrl: primaryAvatarUrl,
                kind: kind,
                isStub: isStub,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                contactIdentitiesRefs = false,
                messageParticipantsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (contactIdentitiesRefs) db.contactIdentities,
                    if (messageParticipantsRefs) db.messageParticipants,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (contactIdentitiesRefs)
                        await $_getPrefetchedData<
                          Contact,
                          $ContactsTable,
                          ContactIdentity
                        >(
                          currentTable: table,
                          referencedTable: $$ContactsTableReferences
                              ._contactIdentitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContactsTableReferences(
                                db,
                                table,
                                p0,
                              ).contactIdentitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contactId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (messageParticipantsRefs)
                        await $_getPrefetchedData<
                          Contact,
                          $ContactsTable,
                          MessageParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$ContactsTableReferences
                              ._messageParticipantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContactsTableReferences(
                                db,
                                table,
                                p0,
                              ).messageParticipantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contactId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, $$ContactsTableReferences),
      Contact,
      PrefetchHooks Function({
        bool contactIdentitiesRefs,
        bool messageParticipantsRefs,
      })
    >;
typedef $$ContactIdentitiesTableCreateCompanionBuilder =
    ContactIdentitiesCompanion Function({
      Value<int> id,
      required int contactId,
      required String source,
      required String externalId,
      Value<String?> displayNameSnapshot,
      Value<String?> avatarUrlSnapshot,
      Value<String?> rawPayloadJson,
      required DateTime lastSeenAt,
      Value<DateTime?> lastEnrichedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ContactIdentitiesTableUpdateCompanionBuilder =
    ContactIdentitiesCompanion Function({
      Value<int> id,
      Value<int> contactId,
      Value<String> source,
      Value<String> externalId,
      Value<String?> displayNameSnapshot,
      Value<String?> avatarUrlSnapshot,
      Value<String?> rawPayloadJson,
      Value<DateTime> lastSeenAt,
      Value<DateTime?> lastEnrichedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ContactIdentitiesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ContactIdentitiesTable,
          ContactIdentity
        > {
  $$ContactIdentitiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContactsTable _contactIdTable(_$AppDatabase db) =>
      db.contacts.createAlias(
        $_aliasNameGenerator(db.contactIdentities.contactId, db.contacts.id),
      );

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<int>('contact_id')!;

    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $MessageParticipantsTable,
    List<MessageParticipant>
  >
  _messageParticipantsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.messageParticipants,
        aliasName: $_aliasNameGenerator(
          db.contactIdentities.id,
          db.messageParticipants.contactIdentityId,
        ),
      );

  $$MessageParticipantsTableProcessedTableManager get messageParticipantsRefs {
    final manager = $$MessageParticipantsTableTableManager(
      $_db,
      $_db.messageParticipants,
    ).filter((f) => f.contactIdentityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _messageParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactIdentitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ContactIdentitiesTable> {
  $$ContactIdentitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayNameSnapshot => $composableBuilder(
    column: $table.displayNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrlSnapshot => $composableBuilder(
    column: $table.avatarUrlSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawPayloadJson => $composableBuilder(
    column: $table.rawPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastEnrichedAt => $composableBuilder(
    column: $table.lastEnrichedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> messageParticipantsRefs(
    Expression<bool> Function($$MessageParticipantsTableFilterComposer f) f,
  ) {
    final $$MessageParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messageParticipants,
      getReferencedColumn: (t) => t.contactIdentityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.messageParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactIdentitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactIdentitiesTable> {
  $$ContactIdentitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayNameSnapshot => $composableBuilder(
    column: $table.displayNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrlSnapshot => $composableBuilder(
    column: $table.avatarUrlSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawPayloadJson => $composableBuilder(
    column: $table.rawPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastEnrichedAt => $composableBuilder(
    column: $table.lastEnrichedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactIdentitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactIdentitiesTable> {
  $$ContactIdentitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayNameSnapshot => $composableBuilder(
    column: $table.displayNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrlSnapshot => $composableBuilder(
    column: $table.avatarUrlSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawPayloadJson => $composableBuilder(
    column: $table.rawPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastEnrichedAt => $composableBuilder(
    column: $table.lastEnrichedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> messageParticipantsRefs<T extends Object>(
    Expression<T> Function($$MessageParticipantsTableAnnotationComposer a) f,
  ) {
    final $$MessageParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.messageParticipants,
          getReferencedColumn: (t) => t.contactIdentityId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MessageParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.messageParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContactIdentitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactIdentitiesTable,
          ContactIdentity,
          $$ContactIdentitiesTableFilterComposer,
          $$ContactIdentitiesTableOrderingComposer,
          $$ContactIdentitiesTableAnnotationComposer,
          $$ContactIdentitiesTableCreateCompanionBuilder,
          $$ContactIdentitiesTableUpdateCompanionBuilder,
          (ContactIdentity, $$ContactIdentitiesTableReferences),
          ContactIdentity,
          PrefetchHooks Function({bool contactId, bool messageParticipantsRefs})
        > {
  $$ContactIdentitiesTableTableManager(
    _$AppDatabase db,
    $ContactIdentitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactIdentitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactIdentitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactIdentitiesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> contactId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String?> displayNameSnapshot = const Value.absent(),
                Value<String?> avatarUrlSnapshot = const Value.absent(),
                Value<String?> rawPayloadJson = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<DateTime?> lastEnrichedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ContactIdentitiesCompanion(
                id: id,
                contactId: contactId,
                source: source,
                externalId: externalId,
                displayNameSnapshot: displayNameSnapshot,
                avatarUrlSnapshot: avatarUrlSnapshot,
                rawPayloadJson: rawPayloadJson,
                lastSeenAt: lastSeenAt,
                lastEnrichedAt: lastEnrichedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int contactId,
                required String source,
                required String externalId,
                Value<String?> displayNameSnapshot = const Value.absent(),
                Value<String?> avatarUrlSnapshot = const Value.absent(),
                Value<String?> rawPayloadJson = const Value.absent(),
                required DateTime lastSeenAt,
                Value<DateTime?> lastEnrichedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ContactIdentitiesCompanion.insert(
                id: id,
                contactId: contactId,
                source: source,
                externalId: externalId,
                displayNameSnapshot: displayNameSnapshot,
                avatarUrlSnapshot: avatarUrlSnapshot,
                rawPayloadJson: rawPayloadJson,
                lastSeenAt: lastSeenAt,
                lastEnrichedAt: lastEnrichedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContactIdentitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({contactId = false, messageParticipantsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (messageParticipantsRefs) db.messageParticipants,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (contactId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.contactId,
                                    referencedTable:
                                        $$ContactIdentitiesTableReferences
                                            ._contactIdTable(db),
                                    referencedColumn:
                                        $$ContactIdentitiesTableReferences
                                            ._contactIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messageParticipantsRefs)
                        await $_getPrefetchedData<
                          ContactIdentity,
                          $ContactIdentitiesTable,
                          MessageParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$ContactIdentitiesTableReferences
                              ._messageParticipantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContactIdentitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).messageParticipantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contactIdentityId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ContactIdentitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactIdentitiesTable,
      ContactIdentity,
      $$ContactIdentitiesTableFilterComposer,
      $$ContactIdentitiesTableOrderingComposer,
      $$ContactIdentitiesTableAnnotationComposer,
      $$ContactIdentitiesTableCreateCompanionBuilder,
      $$ContactIdentitiesTableUpdateCompanionBuilder,
      (ContactIdentity, $$ContactIdentitiesTableReferences),
      ContactIdentity,
      PrefetchHooks Function({bool contactId, bool messageParticipantsRefs})
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      required String source,
      required String externalId,
      required String mailbox,
      Value<String> subject,
      Value<String?> bodyRaw,
      Value<String?> bodyText,
      Value<String?> bodyFormat,
      Value<DateTime?> sentAt,
      required DateTime receivedAt,
      Value<DateTime?> remoteUpdatedAt,
      Value<bool> isRead,
      Value<bool> isArchived,
      Value<bool> isDeleted,
      Value<bool> hasAttachments,
      Value<DateTime?> detailFetchedAt,
      Value<String?> headerFingerprint,
      Value<String?> rawHeaderJson,
      Value<String?> rawDetailJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<String> source,
      Value<String> externalId,
      Value<String> mailbox,
      Value<String> subject,
      Value<String?> bodyRaw,
      Value<String?> bodyText,
      Value<String?> bodyFormat,
      Value<DateTime?> sentAt,
      Value<DateTime> receivedAt,
      Value<DateTime?> remoteUpdatedAt,
      Value<bool> isRead,
      Value<bool> isArchived,
      Value<bool> isDeleted,
      Value<bool> hasAttachments,
      Value<DateTime?> detailFetchedAt,
      Value<String?> headerFingerprint,
      Value<String?> rawHeaderJson,
      Value<String?> rawDetailJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $MessageParticipantsTable,
    List<MessageParticipant>
  >
  _messageParticipantsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.messageParticipants,
        aliasName: $_aliasNameGenerator(
          db.messages.id,
          db.messageParticipants.messageId,
        ),
      );

  $$MessageParticipantsTableProcessedTableManager get messageParticipantsRefs {
    final manager = $$MessageParticipantsTableTableManager(
      $_db,
      $_db.messageParticipants,
    ).filter((f) => f.messageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _messageParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MessageAttachmentsTable, List<MessageAttachment>>
  _messageAttachmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.messageAttachments,
        aliasName: $_aliasNameGenerator(
          db.messages.id,
          db.messageAttachments.messageId,
        ),
      );

  $$MessageAttachmentsTableProcessedTableManager get messageAttachmentsRefs {
    final manager = $$MessageAttachmentsTableTableManager(
      $_db,
      $_db.messageAttachments,
    ).filter((f) => f.messageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _messageAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mailbox => $composableBuilder(
    column: $table.mailbox,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyRaw => $composableBuilder(
    column: $table.bodyRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyText => $composableBuilder(
    column: $table.bodyText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyFormat => $composableBuilder(
    column: $table.bodyFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headerFingerprint => $composableBuilder(
    column: $table.headerFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawHeaderJson => $composableBuilder(
    column: $table.rawHeaderJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawDetailJson => $composableBuilder(
    column: $table.rawDetailJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> messageParticipantsRefs(
    Expression<bool> Function($$MessageParticipantsTableFilterComposer f) f,
  ) {
    final $$MessageParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messageParticipants,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.messageParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> messageAttachmentsRefs(
    Expression<bool> Function($$MessageAttachmentsTableFilterComposer f) f,
  ) {
    final $$MessageAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messageAttachments,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessageAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.messageAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mailbox => $composableBuilder(
    column: $table.mailbox,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyRaw => $composableBuilder(
    column: $table.bodyRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyText => $composableBuilder(
    column: $table.bodyText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyFormat => $composableBuilder(
    column: $table.bodyFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headerFingerprint => $composableBuilder(
    column: $table.headerFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawHeaderJson => $composableBuilder(
    column: $table.rawHeaderJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawDetailJson => $composableBuilder(
    column: $table.rawDetailJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mailbox =>
      $composableBuilder(column: $table.mailbox, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get bodyRaw =>
      $composableBuilder(column: $table.bodyRaw, builder: (column) => column);

  GeneratedColumn<String> get bodyText =>
      $composableBuilder(column: $table.bodyText, builder: (column) => column);

  GeneratedColumn<String> get bodyFormat => $composableBuilder(
    column: $table.bodyFormat,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headerFingerprint => $composableBuilder(
    column: $table.headerFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawHeaderJson => $composableBuilder(
    column: $table.rawHeaderJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawDetailJson => $composableBuilder(
    column: $table.rawDetailJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> messageParticipantsRefs<T extends Object>(
    Expression<T> Function($$MessageParticipantsTableAnnotationComposer a) f,
  ) {
    final $$MessageParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.messageParticipants,
          getReferencedColumn: (t) => t.messageId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MessageParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.messageParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> messageAttachmentsRefs<T extends Object>(
    Expression<T> Function($$MessageAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$MessageAttachmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.messageAttachments,
          getReferencedColumn: (t) => t.messageId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MessageAttachmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.messageAttachments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, $$MessagesTableReferences),
          Message,
          PrefetchHooks Function({
            bool messageParticipantsRefs,
            bool messageAttachmentsRefs,
          })
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> mailbox = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String?> bodyRaw = const Value.absent(),
                Value<String?> bodyText = const Value.absent(),
                Value<String?> bodyFormat = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime?> remoteUpdatedAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<DateTime?> detailFetchedAt = const Value.absent(),
                Value<String?> headerFingerprint = const Value.absent(),
                Value<String?> rawHeaderJson = const Value.absent(),
                Value<String?> rawDetailJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                source: source,
                externalId: externalId,
                mailbox: mailbox,
                subject: subject,
                bodyRaw: bodyRaw,
                bodyText: bodyText,
                bodyFormat: bodyFormat,
                sentAt: sentAt,
                receivedAt: receivedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                isRead: isRead,
                isArchived: isArchived,
                isDeleted: isDeleted,
                hasAttachments: hasAttachments,
                detailFetchedAt: detailFetchedAt,
                headerFingerprint: headerFingerprint,
                rawHeaderJson: rawHeaderJson,
                rawDetailJson: rawDetailJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String source,
                required String externalId,
                required String mailbox,
                Value<String> subject = const Value.absent(),
                Value<String?> bodyRaw = const Value.absent(),
                Value<String?> bodyText = const Value.absent(),
                Value<String?> bodyFormat = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                required DateTime receivedAt,
                Value<DateTime?> remoteUpdatedAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<DateTime?> detailFetchedAt = const Value.absent(),
                Value<String?> headerFingerprint = const Value.absent(),
                Value<String?> rawHeaderJson = const Value.absent(),
                Value<String?> rawDetailJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                source: source,
                externalId: externalId,
                mailbox: mailbox,
                subject: subject,
                bodyRaw: bodyRaw,
                bodyText: bodyText,
                bodyFormat: bodyFormat,
                sentAt: sentAt,
                receivedAt: receivedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                isRead: isRead,
                isArchived: isArchived,
                isDeleted: isDeleted,
                hasAttachments: hasAttachments,
                detailFetchedAt: detailFetchedAt,
                headerFingerprint: headerFingerprint,
                rawHeaderJson: rawHeaderJson,
                rawDetailJson: rawDetailJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                messageParticipantsRefs = false,
                messageAttachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (messageParticipantsRefs) db.messageParticipants,
                    if (messageAttachmentsRefs) db.messageAttachments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messageParticipantsRefs)
                        await $_getPrefetchedData<
                          Message,
                          $MessagesTable,
                          MessageParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$MessagesTableReferences
                              ._messageParticipantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MessagesTableReferences(
                                db,
                                table,
                                p0,
                              ).messageParticipantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.messageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (messageAttachmentsRefs)
                        await $_getPrefetchedData<
                          Message,
                          $MessagesTable,
                          MessageAttachment
                        >(
                          currentTable: table,
                          referencedTable: $$MessagesTableReferences
                              ._messageAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MessagesTableReferences(
                                db,
                                table,
                                p0,
                              ).messageAttachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.messageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, $$MessagesTableReferences),
      Message,
      PrefetchHooks Function({
        bool messageParticipantsRefs,
        bool messageAttachmentsRefs,
      })
    >;
typedef $$MessageParticipantsTableCreateCompanionBuilder =
    MessageParticipantsCompanion Function({
      Value<int> id,
      required int messageId,
      Value<int?> contactId,
      Value<int?> contactIdentityId,
      required String role,
      Value<int> position,
      required String displayNameSnapshot,
      Value<String?> addressSnapshot,
      Value<DateTime> createdAt,
    });
typedef $$MessageParticipantsTableUpdateCompanionBuilder =
    MessageParticipantsCompanion Function({
      Value<int> id,
      Value<int> messageId,
      Value<int?> contactId,
      Value<int?> contactIdentityId,
      Value<String> role,
      Value<int> position,
      Value<String> displayNameSnapshot,
      Value<String?> addressSnapshot,
      Value<DateTime> createdAt,
    });

final class $$MessageParticipantsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MessageParticipantsTable,
          MessageParticipant
        > {
  $$MessageParticipantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MessagesTable _messageIdTable(_$AppDatabase db) =>
      db.messages.createAlias(
        $_aliasNameGenerator(db.messageParticipants.messageId, db.messages.id),
      );

  $$MessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<int>('message_id')!;

    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContactsTable _contactIdTable(_$AppDatabase db) =>
      db.contacts.createAlias(
        $_aliasNameGenerator(db.messageParticipants.contactId, db.contacts.id),
      );

  $$ContactsTableProcessedTableManager? get contactId {
    final $_column = $_itemColumn<int>('contact_id');
    if ($_column == null) return null;
    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContactIdentitiesTable _contactIdentityIdTable(_$AppDatabase db) =>
      db.contactIdentities.createAlias(
        $_aliasNameGenerator(
          db.messageParticipants.contactIdentityId,
          db.contactIdentities.id,
        ),
      );

  $$ContactIdentitiesTableProcessedTableManager? get contactIdentityId {
    final $_column = $_itemColumn<int>('contact_identity_id');
    if ($_column == null) return null;
    final manager = $$ContactIdentitiesTableTableManager(
      $_db,
      $_db.contactIdentities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdentityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessageParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageParticipantsTable> {
  $$MessageParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayNameSnapshot => $composableBuilder(
    column: $table.displayNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressSnapshot => $composableBuilder(
    column: $table.addressSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactIdentitiesTableFilterComposer get contactIdentityId {
    final $$ContactIdentitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactIdentityId,
      referencedTable: $db.contactIdentities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactIdentitiesTableFilterComposer(
            $db: $db,
            $table: $db.contactIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageParticipantsTable> {
  $$MessageParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayNameSnapshot => $composableBuilder(
    column: $table.displayNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressSnapshot => $composableBuilder(
    column: $table.addressSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableOrderingComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactIdentitiesTableOrderingComposer get contactIdentityId {
    final $$ContactIdentitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactIdentityId,
      referencedTable: $db.contactIdentities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactIdentitiesTableOrderingComposer(
            $db: $db,
            $table: $db.contactIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageParticipantsTable> {
  $$MessageParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get displayNameSnapshot => $composableBuilder(
    column: $table.displayNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addressSnapshot => $composableBuilder(
    column: $table.addressSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactIdentitiesTableAnnotationComposer get contactIdentityId {
    final $$ContactIdentitiesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contactIdentityId,
          referencedTable: $db.contactIdentities,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContactIdentitiesTableAnnotationComposer(
                $db: $db,
                $table: $db.contactIdentities,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$MessageParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageParticipantsTable,
          MessageParticipant,
          $$MessageParticipantsTableFilterComposer,
          $$MessageParticipantsTableOrderingComposer,
          $$MessageParticipantsTableAnnotationComposer,
          $$MessageParticipantsTableCreateCompanionBuilder,
          $$MessageParticipantsTableUpdateCompanionBuilder,
          (MessageParticipant, $$MessageParticipantsTableReferences),
          MessageParticipant,
          PrefetchHooks Function({
            bool messageId,
            bool contactId,
            bool contactIdentityId,
          })
        > {
  $$MessageParticipantsTableTableManager(
    _$AppDatabase db,
    $MessageParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageParticipantsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MessageParticipantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> messageId = const Value.absent(),
                Value<int?> contactId = const Value.absent(),
                Value<int?> contactIdentityId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> displayNameSnapshot = const Value.absent(),
                Value<String?> addressSnapshot = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MessageParticipantsCompanion(
                id: id,
                messageId: messageId,
                contactId: contactId,
                contactIdentityId: contactIdentityId,
                role: role,
                position: position,
                displayNameSnapshot: displayNameSnapshot,
                addressSnapshot: addressSnapshot,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int messageId,
                Value<int?> contactId = const Value.absent(),
                Value<int?> contactIdentityId = const Value.absent(),
                required String role,
                Value<int> position = const Value.absent(),
                required String displayNameSnapshot,
                Value<String?> addressSnapshot = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MessageParticipantsCompanion.insert(
                id: id,
                messageId: messageId,
                contactId: contactId,
                contactIdentityId: contactIdentityId,
                role: role,
                position: position,
                displayNameSnapshot: displayNameSnapshot,
                addressSnapshot: addressSnapshot,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessageParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                messageId = false,
                contactId = false,
                contactIdentityId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (messageId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.messageId,
                                    referencedTable:
                                        $$MessageParticipantsTableReferences
                                            ._messageIdTable(db),
                                    referencedColumn:
                                        $$MessageParticipantsTableReferences
                                            ._messageIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (contactId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.contactId,
                                    referencedTable:
                                        $$MessageParticipantsTableReferences
                                            ._contactIdTable(db),
                                    referencedColumn:
                                        $$MessageParticipantsTableReferences
                                            ._contactIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (contactIdentityId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.contactIdentityId,
                                    referencedTable:
                                        $$MessageParticipantsTableReferences
                                            ._contactIdentityIdTable(db),
                                    referencedColumn:
                                        $$MessageParticipantsTableReferences
                                            ._contactIdentityIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$MessageParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageParticipantsTable,
      MessageParticipant,
      $$MessageParticipantsTableFilterComposer,
      $$MessageParticipantsTableOrderingComposer,
      $$MessageParticipantsTableAnnotationComposer,
      $$MessageParticipantsTableCreateCompanionBuilder,
      $$MessageParticipantsTableUpdateCompanionBuilder,
      (MessageParticipant, $$MessageParticipantsTableReferences),
      MessageParticipant,
      PrefetchHooks Function({
        bool messageId,
        bool contactId,
        bool contactIdentityId,
      })
    >;
typedef $$MessageAttachmentsTableCreateCompanionBuilder =
    MessageAttachmentsCompanion Function({
      Value<int> id,
      required int messageId,
      required String source,
      Value<String?> externalId,
      required String filename,
      Value<String?> mimeType,
      Value<int?> sizeBytes,
      Value<bool> isInline,
      Value<String> downloadStatus,
      Value<String?> localPath,
      Value<String?> localSha256,
      Value<DateTime?> downloadedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$MessageAttachmentsTableUpdateCompanionBuilder =
    MessageAttachmentsCompanion Function({
      Value<int> id,
      Value<int> messageId,
      Value<String> source,
      Value<String?> externalId,
      Value<String> filename,
      Value<String?> mimeType,
      Value<int?> sizeBytes,
      Value<bool> isInline,
      Value<String> downloadStatus,
      Value<String?> localPath,
      Value<String?> localSha256,
      Value<DateTime?> downloadedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$MessageAttachmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MessageAttachmentsTable,
          MessageAttachment
        > {
  $$MessageAttachmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MessagesTable _messageIdTable(_$AppDatabase db) =>
      db.messages.createAlias(
        $_aliasNameGenerator(db.messageAttachments.messageId, db.messages.id),
      );

  $$MessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<int>('message_id')!;

    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessageAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInline => $composableBuilder(
    column: $table.isInline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localSha256 => $composableBuilder(
    column: $table.localSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInline => $composableBuilder(
    column: $table.isInline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localSha256 => $composableBuilder(
    column: $table.localSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableOrderingComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<bool> get isInline =>
      $composableBuilder(column: $table.isInline, builder: (column) => column);

  GeneratedColumn<String> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get localSha256 => $composableBuilder(
    column: $table.localSha256,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessageAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageAttachmentsTable,
          MessageAttachment,
          $$MessageAttachmentsTableFilterComposer,
          $$MessageAttachmentsTableOrderingComposer,
          $$MessageAttachmentsTableAnnotationComposer,
          $$MessageAttachmentsTableCreateCompanionBuilder,
          $$MessageAttachmentsTableUpdateCompanionBuilder,
          (MessageAttachment, $$MessageAttachmentsTableReferences),
          MessageAttachment,
          PrefetchHooks Function({bool messageId})
        > {
  $$MessageAttachmentsTableTableManager(
    _$AppDatabase db,
    $MessageAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> messageId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<bool> isInline = const Value.absent(),
                Value<String> downloadStatus = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> localSha256 = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MessageAttachmentsCompanion(
                id: id,
                messageId: messageId,
                source: source,
                externalId: externalId,
                filename: filename,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                isInline: isInline,
                downloadStatus: downloadStatus,
                localPath: localPath,
                localSha256: localSha256,
                downloadedAt: downloadedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int messageId,
                required String source,
                Value<String?> externalId = const Value.absent(),
                required String filename,
                Value<String?> mimeType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<bool> isInline = const Value.absent(),
                Value<String> downloadStatus = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> localSha256 = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MessageAttachmentsCompanion.insert(
                id: id,
                messageId: messageId,
                source: source,
                externalId: externalId,
                filename: filename,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                isInline: isInline,
                downloadStatus: downloadStatus,
                localPath: localPath,
                localSha256: localSha256,
                downloadedAt: downloadedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessageAttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (messageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.messageId,
                                referencedTable:
                                    $$MessageAttachmentsTableReferences
                                        ._messageIdTable(db),
                                referencedColumn:
                                    $$MessageAttachmentsTableReferences
                                        ._messageIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MessageAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageAttachmentsTable,
      MessageAttachment,
      $$MessageAttachmentsTableFilterComposer,
      $$MessageAttachmentsTableOrderingComposer,
      $$MessageAttachmentsTableAnnotationComposer,
      $$MessageAttachmentsTableCreateCompanionBuilder,
      $$MessageAttachmentsTableUpdateCompanionBuilder,
      (MessageAttachment, $$MessageAttachmentsTableReferences),
      MessageAttachment,
      PrefetchHooks Function({bool messageId})
    >;
typedef $$PendingOutgoingMessagesTableCreateCompanionBuilder =
    PendingOutgoingMessagesCompanion Function({
      Value<int> id,
      required String payloadJson,
      Value<String> subject,
      Value<int> attemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PendingOutgoingMessagesTableUpdateCompanionBuilder =
    PendingOutgoingMessagesCompanion Function({
      Value<int> id,
      Value<String> payloadJson,
      Value<String> subject,
      Value<int> attemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PendingOutgoingMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOutgoingMessagesTable> {
  $$PendingOutgoingMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOutgoingMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOutgoingMessagesTable> {
  $$PendingOutgoingMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOutgoingMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOutgoingMessagesTable> {
  $$PendingOutgoingMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PendingOutgoingMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOutgoingMessagesTable,
          PendingOutgoingMessage,
          $$PendingOutgoingMessagesTableFilterComposer,
          $$PendingOutgoingMessagesTableOrderingComposer,
          $$PendingOutgoingMessagesTableAnnotationComposer,
          $$PendingOutgoingMessagesTableCreateCompanionBuilder,
          $$PendingOutgoingMessagesTableUpdateCompanionBuilder,
          (
            PendingOutgoingMessage,
            BaseReferences<
              _$AppDatabase,
              $PendingOutgoingMessagesTable,
              PendingOutgoingMessage
            >,
          ),
          PendingOutgoingMessage,
          PrefetchHooks Function()
        > {
  $$PendingOutgoingMessagesTableTableManager(
    _$AppDatabase db,
    $PendingOutgoingMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOutgoingMessagesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingOutgoingMessagesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingOutgoingMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PendingOutgoingMessagesCompanion(
                id: id,
                payloadJson: payloadJson,
                subject: subject,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String payloadJson,
                Value<String> subject = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PendingOutgoingMessagesCompanion.insert(
                id: id,
                payloadJson: payloadJson,
                subject: subject,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOutgoingMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOutgoingMessagesTable,
      PendingOutgoingMessage,
      $$PendingOutgoingMessagesTableFilterComposer,
      $$PendingOutgoingMessagesTableOrderingComposer,
      $$PendingOutgoingMessagesTableAnnotationComposer,
      $$PendingOutgoingMessagesTableCreateCompanionBuilder,
      $$PendingOutgoingMessagesTableUpdateCompanionBuilder,
      (
        PendingOutgoingMessage,
        BaseReferences<
          _$AppDatabase,
          $PendingOutgoingMessagesTable,
          PendingOutgoingMessage
        >,
      ),
      PendingOutgoingMessage,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      Value<int> id,
      required String source,
      required String scope,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> lastSuccessAt,
      Value<String?> remoteCursor,
      Value<DateTime?> highWaterReceivedAt,
      Value<String?> highWaterExternalId,
      Value<String?> lastError,
      Value<int> failureCount,
      Value<DateTime> updatedAt,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<int> id,
      Value<String> source,
      Value<String> scope,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> lastSuccessAt,
      Value<String?> remoteCursor,
      Value<DateTime?> highWaterReceivedAt,
      Value<String?> highWaterExternalId,
      Value<String?> lastError,
      Value<int> failureCount,
      Value<DateTime> updatedAt,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteCursor => $composableBuilder(
    column: $table.remoteCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get highWaterReceivedAt => $composableBuilder(
    column: $table.highWaterReceivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get highWaterExternalId => $composableBuilder(
    column: $table.highWaterExternalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteCursor => $composableBuilder(
    column: $table.remoteCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get highWaterReceivedAt => $composableBuilder(
    column: $table.highWaterReceivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get highWaterExternalId => $composableBuilder(
    column: $table.highWaterExternalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteCursor => $composableBuilder(
    column: $table.remoteCursor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get highWaterReceivedAt => $composableBuilder(
    column: $table.highWaterReceivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get highWaterExternalId => $composableBuilder(
    column: $table.highWaterExternalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<String?> remoteCursor = const Value.absent(),
                Value<DateTime?> highWaterReceivedAt = const Value.absent(),
                Value<String?> highWaterExternalId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> failureCount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                source: source,
                scope: scope,
                lastAttemptAt: lastAttemptAt,
                lastSuccessAt: lastSuccessAt,
                remoteCursor: remoteCursor,
                highWaterReceivedAt: highWaterReceivedAt,
                highWaterExternalId: highWaterExternalId,
                lastError: lastError,
                failureCount: failureCount,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String source,
                required String scope,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<String?> remoteCursor = const Value.absent(),
                Value<DateTime?> highWaterReceivedAt = const Value.absent(),
                Value<String?> highWaterExternalId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> failureCount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                source: source,
                scope: scope,
                lastAttemptAt: lastAttemptAt,
                lastSuccessAt: lastSuccessAt,
                remoteCursor: remoteCursor,
                highWaterReceivedAt: highWaterReceivedAt,
                highWaterExternalId: highWaterExternalId,
                lastError: lastError,
                failureCount: failureCount,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ContactIdentitiesTableTableManager get contactIdentities =>
      $$ContactIdentitiesTableTableManager(_db, _db.contactIdentities);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageParticipantsTableTableManager get messageParticipants =>
      $$MessageParticipantsTableTableManager(_db, _db.messageParticipants);
  $$MessageAttachmentsTableTableManager get messageAttachments =>
      $$MessageAttachmentsTableTableManager(_db, _db.messageAttachments);
  $$PendingOutgoingMessagesTableTableManager get pendingOutgoingMessages =>
      $$PendingOutgoingMessagesTableTableManager(
        _db,
        _db.pendingOutgoingMessages,
      );
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
