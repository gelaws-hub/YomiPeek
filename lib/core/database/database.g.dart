// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DictionariesTable extends Dictionaries
    with TableInfo<$DictionariesTable, Dictionary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionariesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<String> revision = GeneratedColumn<String>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _entriesMeta = const VerificationMeta(
    'entries',
  );
  @override
  late final GeneratedColumn<int> entries = GeneratedColumn<int>(
    'entries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    revision,
    metadata,
    enabled,
    priority,
    entries,
    bytes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Dictionary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    } else if (isInserting) {
      context.missing(_metadataMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('entries')) {
      context.handle(
        _entriesMeta,
        entries.isAcceptableOrUnknown(data['entries']!, _entriesMeta),
      );
    } else if (isInserting) {
      context.missing(_entriesMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dictionary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dictionary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      entries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entries'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $DictionariesTable createAlias(String alias) {
    return $DictionariesTable(attachedDatabase, alias);
  }
}

class Dictionary extends DataClass implements Insertable<Dictionary> {
  final int id;
  final String title;
  final String revision;
  final String metadata;
  final bool enabled;
  final int priority;
  final int entries;
  final int bytes;
  const Dictionary({
    required this.id,
    required this.title,
    required this.revision,
    required this.metadata,
    required this.enabled,
    required this.priority,
    required this.entries,
    required this.bytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['revision'] = Variable<String>(revision);
    map['metadata'] = Variable<String>(metadata);
    map['enabled'] = Variable<bool>(enabled);
    map['priority'] = Variable<int>(priority);
    map['entries'] = Variable<int>(entries);
    map['bytes'] = Variable<int>(bytes);
    return map;
  }

  DictionariesCompanion toCompanion(bool nullToAbsent) {
    return DictionariesCompanion(
      id: Value(id),
      title: Value(title),
      revision: Value(revision),
      metadata: Value(metadata),
      enabled: Value(enabled),
      priority: Value(priority),
      entries: Value(entries),
      bytes: Value(bytes),
    );
  }

  factory Dictionary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dictionary(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      revision: serializer.fromJson<String>(json['revision']),
      metadata: serializer.fromJson<String>(json['metadata']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      priority: serializer.fromJson<int>(json['priority']),
      entries: serializer.fromJson<int>(json['entries']),
      bytes: serializer.fromJson<int>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'revision': serializer.toJson<String>(revision),
      'metadata': serializer.toJson<String>(metadata),
      'enabled': serializer.toJson<bool>(enabled),
      'priority': serializer.toJson<int>(priority),
      'entries': serializer.toJson<int>(entries),
      'bytes': serializer.toJson<int>(bytes),
    };
  }

  Dictionary copyWith({
    int? id,
    String? title,
    String? revision,
    String? metadata,
    bool? enabled,
    int? priority,
    int? entries,
    int? bytes,
  }) => Dictionary(
    id: id ?? this.id,
    title: title ?? this.title,
    revision: revision ?? this.revision,
    metadata: metadata ?? this.metadata,
    enabled: enabled ?? this.enabled,
    priority: priority ?? this.priority,
    entries: entries ?? this.entries,
    bytes: bytes ?? this.bytes,
  );
  Dictionary copyWithCompanion(DictionariesCompanion data) {
    return Dictionary(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      revision: data.revision.present ? data.revision.value : this.revision,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      priority: data.priority.present ? data.priority.value : this.priority,
      entries: data.entries.present ? data.entries.value : this.entries,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dictionary(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('revision: $revision, ')
          ..write('metadata: $metadata, ')
          ..write('enabled: $enabled, ')
          ..write('priority: $priority, ')
          ..write('entries: $entries, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    revision,
    metadata,
    enabled,
    priority,
    entries,
    bytes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dictionary &&
          other.id == this.id &&
          other.title == this.title &&
          other.revision == this.revision &&
          other.metadata == this.metadata &&
          other.enabled == this.enabled &&
          other.priority == this.priority &&
          other.entries == this.entries &&
          other.bytes == this.bytes);
}

class DictionariesCompanion extends UpdateCompanion<Dictionary> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> revision;
  final Value<String> metadata;
  final Value<bool> enabled;
  final Value<int> priority;
  final Value<int> entries;
  final Value<int> bytes;
  const DictionariesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.revision = const Value.absent(),
    this.metadata = const Value.absent(),
    this.enabled = const Value.absent(),
    this.priority = const Value.absent(),
    this.entries = const Value.absent(),
    this.bytes = const Value.absent(),
  });
  DictionariesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String revision,
    required String metadata,
    this.enabled = const Value.absent(),
    this.priority = const Value.absent(),
    required int entries,
    required int bytes,
  }) : title = Value(title),
       revision = Value(revision),
       metadata = Value(metadata),
       entries = Value(entries),
       bytes = Value(bytes);
  static Insertable<Dictionary> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? revision,
    Expression<String>? metadata,
    Expression<bool>? enabled,
    Expression<int>? priority,
    Expression<int>? entries,
    Expression<int>? bytes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (revision != null) 'revision': revision,
      if (metadata != null) 'metadata': metadata,
      if (enabled != null) 'enabled': enabled,
      if (priority != null) 'priority': priority,
      if (entries != null) 'entries': entries,
      if (bytes != null) 'bytes': bytes,
    });
  }

  DictionariesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? revision,
    Value<String>? metadata,
    Value<bool>? enabled,
    Value<int>? priority,
    Value<int>? entries,
    Value<int>? bytes,
  }) {
    return DictionariesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      revision: revision ?? this.revision,
      metadata: metadata ?? this.metadata,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      entries: entries ?? this.entries,
      bytes: bytes ?? this.bytes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (revision.present) {
      map['revision'] = Variable<String>(revision.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (entries.present) {
      map['entries'] = Variable<int>(entries.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionariesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('revision: $revision, ')
          ..write('metadata: $metadata, ')
          ..write('enabled: $enabled, ')
          ..write('priority: $priority, ')
          ..write('entries: $entries, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }
}

class $TermsTable extends Terms with TableInfo<$TermsTable, Term> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TermsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<int> dictionaryId = GeneratedColumn<int>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dictionaries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _expressionMeta = const VerificationMeta(
    'expression',
  );
  @override
  late final GeneratedColumn<String> expression = GeneratedColumn<String>(
    'expression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedMeta = const VerificationMeta(
    'normalized',
  );
  @override
  late final GeneratedColumn<String> normalized = GeneratedColumn<String>(
    'normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedReadingMeta = const VerificationMeta(
    'normalizedReading',
  );
  @override
  late final GeneratedColumn<String> normalizedReading =
      GeneratedColumn<String>(
        'normalized_reading',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _definitionsMeta = const VerificationMeta(
    'definitions',
  );
  @override
  late final GeneratedColumn<String> definitions = GeneratedColumn<String>(
    'definitions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rulesMeta = const VerificationMeta('rules');
  @override
  late final GeneratedColumn<String> rules = GeneratedColumn<String>(
    'rules',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictionaryId,
    expression,
    reading,
    normalized,
    normalizedReading,
    definitions,
    tags,
    rules,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'terms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Term> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('expression')) {
      context.handle(
        _expressionMeta,
        expression.isAcceptableOrUnknown(data['expression']!, _expressionMeta),
      );
    } else if (isInserting) {
      context.missing(_expressionMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('normalized')) {
      context.handle(
        _normalizedMeta,
        normalized.isAcceptableOrUnknown(data['normalized']!, _normalizedMeta),
      );
    } else if (isInserting) {
      context.missing(_normalizedMeta);
    }
    if (data.containsKey('normalized_reading')) {
      context.handle(
        _normalizedReadingMeta,
        normalizedReading.isAcceptableOrUnknown(
          data['normalized_reading']!,
          _normalizedReadingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedReadingMeta);
    }
    if (data.containsKey('definitions')) {
      context.handle(
        _definitionsMeta,
        definitions.isAcceptableOrUnknown(
          data['definitions']!,
          _definitionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionsMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('rules')) {
      context.handle(
        _rulesMeta,
        rules.isAcceptableOrUnknown(data['rules']!, _rulesMeta),
      );
    } else if (isInserting) {
      context.missing(_rulesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Term map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Term(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dictionary_id'],
      )!,
      expression: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expression'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      normalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized'],
      )!,
      normalizedReading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_reading'],
      )!,
      definitions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definitions'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      rules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rules'],
      )!,
    );
  }

  @override
  $TermsTable createAlias(String alias) {
    return $TermsTable(attachedDatabase, alias);
  }
}

class Term extends DataClass implements Insertable<Term> {
  final int id;
  final int dictionaryId;
  final String expression;
  final String reading;
  final String normalized;
  final String normalizedReading;
  final String definitions;
  final String tags;
  final String rules;
  const Term({
    required this.id,
    required this.dictionaryId,
    required this.expression,
    required this.reading,
    required this.normalized,
    required this.normalizedReading,
    required this.definitions,
    required this.tags,
    required this.rules,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dictionary_id'] = Variable<int>(dictionaryId);
    map['expression'] = Variable<String>(expression);
    map['reading'] = Variable<String>(reading);
    map['normalized'] = Variable<String>(normalized);
    map['normalized_reading'] = Variable<String>(normalizedReading);
    map['definitions'] = Variable<String>(definitions);
    map['tags'] = Variable<String>(tags);
    map['rules'] = Variable<String>(rules);
    return map;
  }

  TermsCompanion toCompanion(bool nullToAbsent) {
    return TermsCompanion(
      id: Value(id),
      dictionaryId: Value(dictionaryId),
      expression: Value(expression),
      reading: Value(reading),
      normalized: Value(normalized),
      normalizedReading: Value(normalizedReading),
      definitions: Value(definitions),
      tags: Value(tags),
      rules: Value(rules),
    );
  }

  factory Term.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Term(
      id: serializer.fromJson<int>(json['id']),
      dictionaryId: serializer.fromJson<int>(json['dictionaryId']),
      expression: serializer.fromJson<String>(json['expression']),
      reading: serializer.fromJson<String>(json['reading']),
      normalized: serializer.fromJson<String>(json['normalized']),
      normalizedReading: serializer.fromJson<String>(json['normalizedReading']),
      definitions: serializer.fromJson<String>(json['definitions']),
      tags: serializer.fromJson<String>(json['tags']),
      rules: serializer.fromJson<String>(json['rules']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictionaryId': serializer.toJson<int>(dictionaryId),
      'expression': serializer.toJson<String>(expression),
      'reading': serializer.toJson<String>(reading),
      'normalized': serializer.toJson<String>(normalized),
      'normalizedReading': serializer.toJson<String>(normalizedReading),
      'definitions': serializer.toJson<String>(definitions),
      'tags': serializer.toJson<String>(tags),
      'rules': serializer.toJson<String>(rules),
    };
  }

  Term copyWith({
    int? id,
    int? dictionaryId,
    String? expression,
    String? reading,
    String? normalized,
    String? normalizedReading,
    String? definitions,
    String? tags,
    String? rules,
  }) => Term(
    id: id ?? this.id,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    expression: expression ?? this.expression,
    reading: reading ?? this.reading,
    normalized: normalized ?? this.normalized,
    normalizedReading: normalizedReading ?? this.normalizedReading,
    definitions: definitions ?? this.definitions,
    tags: tags ?? this.tags,
    rules: rules ?? this.rules,
  );
  Term copyWithCompanion(TermsCompanion data) {
    return Term(
      id: data.id.present ? data.id.value : this.id,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      expression: data.expression.present
          ? data.expression.value
          : this.expression,
      reading: data.reading.present ? data.reading.value : this.reading,
      normalized: data.normalized.present
          ? data.normalized.value
          : this.normalized,
      normalizedReading: data.normalizedReading.present
          ? data.normalizedReading.value
          : this.normalizedReading,
      definitions: data.definitions.present
          ? data.definitions.value
          : this.definitions,
      tags: data.tags.present ? data.tags.value : this.tags,
      rules: data.rules.present ? data.rules.value : this.rules,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Term(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('expression: $expression, ')
          ..write('reading: $reading, ')
          ..write('normalized: $normalized, ')
          ..write('normalizedReading: $normalizedReading, ')
          ..write('definitions: $definitions, ')
          ..write('tags: $tags, ')
          ..write('rules: $rules')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dictionaryId,
    expression,
    reading,
    normalized,
    normalizedReading,
    definitions,
    tags,
    rules,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Term &&
          other.id == this.id &&
          other.dictionaryId == this.dictionaryId &&
          other.expression == this.expression &&
          other.reading == this.reading &&
          other.normalized == this.normalized &&
          other.normalizedReading == this.normalizedReading &&
          other.definitions == this.definitions &&
          other.tags == this.tags &&
          other.rules == this.rules);
}

class TermsCompanion extends UpdateCompanion<Term> {
  final Value<int> id;
  final Value<int> dictionaryId;
  final Value<String> expression;
  final Value<String> reading;
  final Value<String> normalized;
  final Value<String> normalizedReading;
  final Value<String> definitions;
  final Value<String> tags;
  final Value<String> rules;
  const TermsCompanion({
    this.id = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.expression = const Value.absent(),
    this.reading = const Value.absent(),
    this.normalized = const Value.absent(),
    this.normalizedReading = const Value.absent(),
    this.definitions = const Value.absent(),
    this.tags = const Value.absent(),
    this.rules = const Value.absent(),
  });
  TermsCompanion.insert({
    this.id = const Value.absent(),
    required int dictionaryId,
    required String expression,
    required String reading,
    required String normalized,
    required String normalizedReading,
    required String definitions,
    required String tags,
    required String rules,
  }) : dictionaryId = Value(dictionaryId),
       expression = Value(expression),
       reading = Value(reading),
       normalized = Value(normalized),
       normalizedReading = Value(normalizedReading),
       definitions = Value(definitions),
       tags = Value(tags),
       rules = Value(rules);
  static Insertable<Term> custom({
    Expression<int>? id,
    Expression<int>? dictionaryId,
    Expression<String>? expression,
    Expression<String>? reading,
    Expression<String>? normalized,
    Expression<String>? normalizedReading,
    Expression<String>? definitions,
    Expression<String>? tags,
    Expression<String>? rules,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (expression != null) 'expression': expression,
      if (reading != null) 'reading': reading,
      if (normalized != null) 'normalized': normalized,
      if (normalizedReading != null) 'normalized_reading': normalizedReading,
      if (definitions != null) 'definitions': definitions,
      if (tags != null) 'tags': tags,
      if (rules != null) 'rules': rules,
    });
  }

  TermsCompanion copyWith({
    Value<int>? id,
    Value<int>? dictionaryId,
    Value<String>? expression,
    Value<String>? reading,
    Value<String>? normalized,
    Value<String>? normalizedReading,
    Value<String>? definitions,
    Value<String>? tags,
    Value<String>? rules,
  }) {
    return TermsCompanion(
      id: id ?? this.id,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      expression: expression ?? this.expression,
      reading: reading ?? this.reading,
      normalized: normalized ?? this.normalized,
      normalizedReading: normalizedReading ?? this.normalizedReading,
      definitions: definitions ?? this.definitions,
      tags: tags ?? this.tags,
      rules: rules ?? this.rules,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<int>(dictionaryId.value);
    }
    if (expression.present) {
      map['expression'] = Variable<String>(expression.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (normalized.present) {
      map['normalized'] = Variable<String>(normalized.value);
    }
    if (normalizedReading.present) {
      map['normalized_reading'] = Variable<String>(normalizedReading.value);
    }
    if (definitions.present) {
      map['definitions'] = Variable<String>(definitions.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (rules.present) {
      map['rules'] = Variable<String>(rules.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TermsCompanion(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('expression: $expression, ')
          ..write('reading: $reading, ')
          ..write('normalized: $normalized, ')
          ..write('normalizedReading: $normalizedReading, ')
          ..write('definitions: $definitions, ')
          ..write('tags: $tags, ')
          ..write('rules: $rules')
          ..write(')'))
        .toString();
  }
}

abstract class _$DictionaryDb extends GeneratedDatabase {
  _$DictionaryDb(QueryExecutor e) : super(e);
  $DictionaryDbManager get managers => $DictionaryDbManager(this);
  late final $DictionariesTable dictionaries = $DictionariesTable(this);
  late final $TermsTable terms = $TermsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [dictionaries, terms];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dictionaries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('terms', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DictionariesTableCreateCompanionBuilder =
    DictionariesCompanion Function({
      Value<int> id,
      required String title,
      required String revision,
      required String metadata,
      Value<bool> enabled,
      Value<int> priority,
      required int entries,
      required int bytes,
    });
typedef $$DictionariesTableUpdateCompanionBuilder =
    DictionariesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> revision,
      Value<String> metadata,
      Value<bool> enabled,
      Value<int> priority,
      Value<int> entries,
      Value<int> bytes,
    });

final class $$DictionariesTableReferences
    extends BaseReferences<_$DictionaryDb, $DictionariesTable, Dictionary> {
  $$DictionariesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TermsTable, List<Term>> _termsRefsTable(
    _$DictionaryDb db,
  ) => MultiTypedResultKey.fromTable(
    db.terms,
    aliasName: 'dictionaries__id__terms__dictionary_id',
  );

  $$TermsTableProcessedTableManager get termsRefs {
    final manager = $$TermsTableTableManager(
      $_db,
      $_db.terms,
    ).filter((f) => f.dictionaryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_termsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DictionariesTableFilterComposer
    extends Composer<_$DictionaryDb, $DictionariesTable> {
  $$DictionariesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entries => $composableBuilder(
    column: $table.entries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> termsRefs(
    Expression<bool> Function($$TermsTableFilterComposer f) f,
  ) {
    final $$TermsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.terms,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TermsTableFilterComposer(
            $db: $db,
            $table: $db.terms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DictionariesTableOrderingComposer
    extends Composer<_$DictionaryDb, $DictionariesTable> {
  $$DictionariesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entries => $composableBuilder(
    column: $table.entries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionariesTableAnnotationComposer
    extends Composer<_$DictionaryDb, $DictionariesTable> {
  $$DictionariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get entries =>
      $composableBuilder(column: $table.entries, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  Expression<T> termsRefs<T extends Object>(
    Expression<T> Function($$TermsTableAnnotationComposer a) f,
  ) {
    final $$TermsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.terms,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TermsTableAnnotationComposer(
            $db: $db,
            $table: $db.terms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DictionariesTableTableManager
    extends
        RootTableManager<
          _$DictionaryDb,
          $DictionariesTable,
          Dictionary,
          $$DictionariesTableFilterComposer,
          $$DictionariesTableOrderingComposer,
          $$DictionariesTableAnnotationComposer,
          $$DictionariesTableCreateCompanionBuilder,
          $$DictionariesTableUpdateCompanionBuilder,
          (Dictionary, $$DictionariesTableReferences),
          Dictionary,
          PrefetchHooks Function({bool termsRefs})
        > {
  $$DictionariesTableTableManager(_$DictionaryDb db, $DictionariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> revision = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> entries = const Value.absent(),
                Value<int> bytes = const Value.absent(),
              }) => DictionariesCompanion(
                id: id,
                title: title,
                revision: revision,
                metadata: metadata,
                enabled: enabled,
                priority: priority,
                entries: entries,
                bytes: bytes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String revision,
                required String metadata,
                Value<bool> enabled = const Value.absent(),
                Value<int> priority = const Value.absent(),
                required int entries,
                required int bytes,
              }) => DictionariesCompanion.insert(
                id: id,
                title: title,
                revision: revision,
                metadata: metadata,
                enabled: enabled,
                priority: priority,
                entries: entries,
                bytes: bytes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DictionariesTable, Dictionary>(table),
                  $$DictionariesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({termsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (termsRefs) db.terms],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (termsRefs)
                    await $_getPrefetchedDataByColumns<
                      Dictionary,
                      $DictionariesTable,
                      Term,
                      $TermsTable
                    >(
                      currentTable: table,
                      referencedTable: $$DictionariesTableReferences
                          ._termsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DictionariesTableReferences(
                            db,
                            table,
                            p0,
                          ).termsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'dictionary_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DictionariesTableProcessedTableManager =
    ProcessedTableManager<
      _$DictionaryDb,
      $DictionariesTable,
      Dictionary,
      $$DictionariesTableFilterComposer,
      $$DictionariesTableOrderingComposer,
      $$DictionariesTableAnnotationComposer,
      $$DictionariesTableCreateCompanionBuilder,
      $$DictionariesTableUpdateCompanionBuilder,
      (Dictionary, $$DictionariesTableReferences),
      Dictionary,
      PrefetchHooks Function({bool termsRefs})
    >;
typedef $$TermsTableCreateCompanionBuilder = TermsCompanion Function({
  Value<int> id,
  required int dictionaryId,
  required String expression,
  required String reading,
  required String normalized,
  required String normalizedReading,
  required String definitions,
  required String tags,
  required String rules,
});
typedef $$TermsTableUpdateCompanionBuilder = TermsCompanion Function({
  Value<int> id,
  Value<int> dictionaryId,
  Value<String> expression,
  Value<String> reading,
  Value<String> normalized,
  Value<String> normalizedReading,
  Value<String> definitions,
  Value<String> tags,
  Value<String> rules,
});

final class $$TermsTableReferences
    extends BaseReferences<_$DictionaryDb, $TermsTable, Term> {
  $$TermsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DictionariesTable _dictionaryIdTable(_$DictionaryDb db) =>
      db.dictionaries.createAlias('terms__dictionary_id__dictionaries__id');

  $$DictionariesTableProcessedTableManager get dictionaryId {
    final $_column = $_itemColumn<int>('dictionary_id')!;

    final manager = $$DictionariesTableTableManager(
      $_db,
      $_db.dictionaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dictionaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TermsTableFilterComposer extends Composer<_$DictionaryDb, $TermsTable> {
  $$TermsTableFilterComposer({
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

  ColumnFilters<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedReading => $composableBuilder(
    column: $table.normalizedReading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rules => $composableBuilder(
    column: $table.rules,
    builder: (column) => ColumnFilters(column),
  );

  $$DictionariesTableFilterComposer get dictionaryId {
    final $$DictionariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermsTableOrderingComposer
    extends Composer<_$DictionaryDb, $TermsTable> {
  $$TermsTableOrderingComposer({
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

  ColumnOrderings<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedReading => $composableBuilder(
    column: $table.normalizedReading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rules => $composableBuilder(
    column: $table.rules,
    builder: (column) => ColumnOrderings(column),
  );

  $$DictionariesTableOrderingComposer get dictionaryId {
    final $$DictionariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableOrderingComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermsTableAnnotationComposer
    extends Composer<_$DictionaryDb, $TermsTable> {
  $$TermsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedReading => $composableBuilder(
    column: $table.normalizedReading,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get rules =>
      $composableBuilder(column: $table.rules, builder: (column) => column);

  $$DictionariesTableAnnotationComposer get dictionaryId {
    final $$DictionariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermsTableTableManager
    extends
        RootTableManager<
          _$DictionaryDb,
          $TermsTable,
          Term,
          $$TermsTableFilterComposer,
          $$TermsTableOrderingComposer,
          $$TermsTableAnnotationComposer,
          $$TermsTableCreateCompanionBuilder,
          $$TermsTableUpdateCompanionBuilder,
          (Term, $$TermsTableReferences),
          Term,
          PrefetchHooks Function({bool dictionaryId})
        > {
  $$TermsTableTableManager(_$DictionaryDb db, $TermsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TermsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TermsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TermsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictionaryId = const Value.absent(),
                Value<String> expression = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> normalized = const Value.absent(),
                Value<String> normalizedReading = const Value.absent(),
                Value<String> definitions = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> rules = const Value.absent(),
              }) => TermsCompanion(
                id: id,
                dictionaryId: dictionaryId,
                expression: expression,
                reading: reading,
                normalized: normalized,
                normalizedReading: normalizedReading,
                definitions: definitions,
                tags: tags,
                rules: rules,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictionaryId,
                required String expression,
                required String reading,
                required String normalized,
                required String normalizedReading,
                required String definitions,
                required String tags,
                required String rules,
              }) => TermsCompanion.insert(
                id: id,
                dictionaryId: dictionaryId,
                expression: expression,
                reading: reading,
                normalized: normalized,
                normalizedReading: normalizedReading,
                definitions: definitions,
                tags: tags,
                rules: rules,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TermsTable, Term>(table),
                  $$TermsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dictionaryId = false}) {
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
                    if (dictionaryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.dictionaryId,
                        referencedTable: $$TermsTableReferences
                            ._dictionaryIdTable(db),
                        referencedColumn: $$TermsTableReferences
                            ._dictionaryIdTable(db)
                            .id,
                      ) as T;
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

typedef $$TermsTableProcessedTableManager =
    ProcessedTableManager<
      _$DictionaryDb,
      $TermsTable,
      Term,
      $$TermsTableFilterComposer,
      $$TermsTableOrderingComposer,
      $$TermsTableAnnotationComposer,
      $$TermsTableCreateCompanionBuilder,
      $$TermsTableUpdateCompanionBuilder,
      (Term, $$TermsTableReferences),
      Term,
      PrefetchHooks Function({bool dictionaryId})
    >;

class $DictionaryDbManager {
  final _$DictionaryDb _db;
  $DictionaryDbManager(this._db);
  $$DictionariesTableTableManager get dictionaries =>
      $$DictionariesTableTableManager(_db, _db.dictionaries);
  $$TermsTableTableManager get terms =>
      $$TermsTableTableManager(_db, _db.terms);
}

class $SavedWordsTable extends SavedWords
    with TableInfo<$SavedWordsTable, SavedWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedWordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _expressionMeta = const VerificationMeta(
    'expression',
  );
  @override
  late final GeneratedColumn<String> expression = GeneratedColumn<String>(
    'expression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionsMeta = const VerificationMeta(
    'definitions',
  );
  @override
  late final GeneratedColumn<String> definitions = GeneratedColumn<String>(
    'definitions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expression,
    reading,
    definitions,
    source,
    created,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('expression')) {
      context.handle(
        _expressionMeta,
        expression.isAcceptableOrUnknown(data['expression']!, _expressionMeta),
      );
    } else if (isInserting) {
      context.missing(_expressionMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('definitions')) {
      context.handle(
        _definitionsMeta,
        definitions.isAcceptableOrUnknown(
          data['definitions']!,
          _definitionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionsMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {expression, reading, definitions},
  ];
  @override
  SavedWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      expression: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expression'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      definitions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definitions'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
    );
  }

  @override
  $SavedWordsTable createAlias(String alias) {
    return $SavedWordsTable(attachedDatabase, alias);
  }
}

class SavedWord extends DataClass implements Insertable<SavedWord> {
  final int id;
  final String expression;
  final String reading;
  final String definitions;
  final String source;
  final DateTime created;
  const SavedWord({
    required this.id,
    required this.expression,
    required this.reading,
    required this.definitions,
    required this.source,
    required this.created,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['expression'] = Variable<String>(expression);
    map['reading'] = Variable<String>(reading);
    map['definitions'] = Variable<String>(definitions);
    map['source'] = Variable<String>(source);
    map['created'] = Variable<DateTime>(created);
    return map;
  }

  SavedWordsCompanion toCompanion(bool nullToAbsent) {
    return SavedWordsCompanion(
      id: Value(id),
      expression: Value(expression),
      reading: Value(reading),
      definitions: Value(definitions),
      source: Value(source),
      created: Value(created),
    );
  }

  factory SavedWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedWord(
      id: serializer.fromJson<int>(json['id']),
      expression: serializer.fromJson<String>(json['expression']),
      reading: serializer.fromJson<String>(json['reading']),
      definitions: serializer.fromJson<String>(json['definitions']),
      source: serializer.fromJson<String>(json['source']),
      created: serializer.fromJson<DateTime>(json['created']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'expression': serializer.toJson<String>(expression),
      'reading': serializer.toJson<String>(reading),
      'definitions': serializer.toJson<String>(definitions),
      'source': serializer.toJson<String>(source),
      'created': serializer.toJson<DateTime>(created),
    };
  }

  SavedWord copyWith({
    int? id,
    String? expression,
    String? reading,
    String? definitions,
    String? source,
    DateTime? created,
  }) => SavedWord(
    id: id ?? this.id,
    expression: expression ?? this.expression,
    reading: reading ?? this.reading,
    definitions: definitions ?? this.definitions,
    source: source ?? this.source,
    created: created ?? this.created,
  );
  SavedWord copyWithCompanion(SavedWordsCompanion data) {
    return SavedWord(
      id: data.id.present ? data.id.value : this.id,
      expression: data.expression.present
          ? data.expression.value
          : this.expression,
      reading: data.reading.present ? data.reading.value : this.reading,
      definitions: data.definitions.present
          ? data.definitions.value
          : this.definitions,
      source: data.source.present ? data.source.value : this.source,
      created: data.created.present ? data.created.value : this.created,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedWord(')
          ..write('id: $id, ')
          ..write('expression: $expression, ')
          ..write('reading: $reading, ')
          ..write('definitions: $definitions, ')
          ..write('source: $source, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, expression, reading, definitions, source, created);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedWord &&
          other.id == this.id &&
          other.expression == this.expression &&
          other.reading == this.reading &&
          other.definitions == this.definitions &&
          other.source == this.source &&
          other.created == this.created);
}

class SavedWordsCompanion extends UpdateCompanion<SavedWord> {
  final Value<int> id;
  final Value<String> expression;
  final Value<String> reading;
  final Value<String> definitions;
  final Value<String> source;
  final Value<DateTime> created;
  const SavedWordsCompanion({
    this.id = const Value.absent(),
    this.expression = const Value.absent(),
    this.reading = const Value.absent(),
    this.definitions = const Value.absent(),
    this.source = const Value.absent(),
    this.created = const Value.absent(),
  });
  SavedWordsCompanion.insert({
    this.id = const Value.absent(),
    required String expression,
    required String reading,
    required String definitions,
    required String source,
    this.created = const Value.absent(),
  }) : expression = Value(expression),
       reading = Value(reading),
       definitions = Value(definitions),
       source = Value(source);
  static Insertable<SavedWord> custom({
    Expression<int>? id,
    Expression<String>? expression,
    Expression<String>? reading,
    Expression<String>? definitions,
    Expression<String>? source,
    Expression<DateTime>? created,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expression != null) 'expression': expression,
      if (reading != null) 'reading': reading,
      if (definitions != null) 'definitions': definitions,
      if (source != null) 'source': source,
      if (created != null) 'created': created,
    });
  }

  SavedWordsCompanion copyWith({
    Value<int>? id,
    Value<String>? expression,
    Value<String>? reading,
    Value<String>? definitions,
    Value<String>? source,
    Value<DateTime>? created,
  }) {
    return SavedWordsCompanion(
      id: id ?? this.id,
      expression: expression ?? this.expression,
      reading: reading ?? this.reading,
      definitions: definitions ?? this.definitions,
      source: source ?? this.source,
      created: created ?? this.created,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (expression.present) {
      map['expression'] = Variable<String>(expression.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (definitions.present) {
      map['definitions'] = Variable<String>(definitions.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedWordsCompanion(')
          ..write('id: $id, ')
          ..write('expression: $expression, ')
          ..write('reading: $reading, ')
          ..write('definitions: $definitions, ')
          ..write('source: $source, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }
}

class $HistoryTable extends History with TableInfo<$HistoryTable, HistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchedMeta = const VerificationMeta(
    'searched',
  );
  @override
  late final GeneratedColumn<DateTime> searched = GeneratedColumn<DateTime>(
    'searched',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [query, searched];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('searched')) {
      context.handle(
        _searchedMeta,
        searched.isAcceptableOrUnknown(data['searched']!, _searchedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  HistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryData(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      searched: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}searched'],
      )!,
    );
  }

  @override
  $HistoryTable createAlias(String alias) {
    return $HistoryTable(attachedDatabase, alias);
  }
}

class HistoryData extends DataClass implements Insertable<HistoryData> {
  final String query;
  final DateTime searched;
  const HistoryData({required this.query, required this.searched});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['searched'] = Variable<DateTime>(searched);
    return map;
  }

  HistoryCompanion toCompanion(bool nullToAbsent) {
    return HistoryCompanion(query: Value(query), searched: Value(searched));
  }

  factory HistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryData(
      query: serializer.fromJson<String>(json['query']),
      searched: serializer.fromJson<DateTime>(json['searched']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'searched': serializer.toJson<DateTime>(searched),
    };
  }

  HistoryData copyWith({String? query, DateTime? searched}) => HistoryData(
    query: query ?? this.query,
    searched: searched ?? this.searched,
  );
  HistoryData copyWithCompanion(HistoryCompanion data) {
    return HistoryData(
      query: data.query.present ? data.query.value : this.query,
      searched: data.searched.present ? data.searched.value : this.searched,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryData(')
          ..write('query: $query, ')
          ..write('searched: $searched')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, searched);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryData &&
          other.query == this.query &&
          other.searched == this.searched);
}

class HistoryCompanion extends UpdateCompanion<HistoryData> {
  final Value<String> query;
  final Value<DateTime> searched;
  final Value<int> rowid;
  const HistoryCompanion({
    this.query = const Value.absent(),
    this.searched = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryCompanion.insert({
    required String query,
    this.searched = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : query = Value(query);
  static Insertable<HistoryData> custom({
    Expression<String>? query,
    Expression<DateTime>? searched,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (searched != null) 'searched': searched,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryCompanion copyWith({
    Value<String>? query,
    Value<DateTime>? searched,
    Value<int>? rowid,
  }) {
    return HistoryCompanion(
      query: query ?? this.query,
      searched: searched ?? this.searched,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (searched.present) {
      map['searched'] = Variable<DateTime>(searched.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryCompanion(')
          ..write('query: $query, ')
          ..write('searched: $searched, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDb extends GeneratedDatabase {
  _$UserDb(QueryExecutor e) : super(e);
  $UserDbManager get managers => $UserDbManager(this);
  late final $SavedWordsTable savedWords = $SavedWordsTable(this);
  late final $HistoryTable history = $HistoryTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    savedWords,
    history,
    preferences,
  ];
}

typedef $$SavedWordsTableCreateCompanionBuilder = SavedWordsCompanion Function({
  Value<int> id,
  required String expression,
  required String reading,
  required String definitions,
  required String source,
  Value<DateTime> created,
});
typedef $$SavedWordsTableUpdateCompanionBuilder = SavedWordsCompanion Function({
  Value<int> id,
  Value<String> expression,
  Value<String> reading,
  Value<String> definitions,
  Value<String> source,
  Value<DateTime> created,
});

class $$SavedWordsTableFilterComposer
    extends Composer<_$UserDb, $SavedWordsTable> {
  $$SavedWordsTableFilterComposer({
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

  ColumnFilters<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedWordsTableOrderingComposer
    extends Composer<_$UserDb, $SavedWordsTable> {
  $$SavedWordsTableOrderingComposer({
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

  ColumnOrderings<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedWordsTableAnnotationComposer
    extends Composer<_$UserDb, $SavedWordsTable> {
  $$SavedWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);
}

class $$SavedWordsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $SavedWordsTable,
          SavedWord,
          $$SavedWordsTableFilterComposer,
          $$SavedWordsTableOrderingComposer,
          $$SavedWordsTableAnnotationComposer,
          $$SavedWordsTableCreateCompanionBuilder,
          $$SavedWordsTableUpdateCompanionBuilder,
          (SavedWord, BaseReferences<_$UserDb, $SavedWordsTable, SavedWord>),
          SavedWord,
          PrefetchHooks Function()
        > {
  $$SavedWordsTableTableManager(_$UserDb db, $SavedWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> expression = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> definitions = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
              }) => SavedWordsCompanion(
                id: id,
                expression: expression,
                reading: reading,
                definitions: definitions,
                source: source,
                created: created,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String expression,
                required String reading,
                required String definitions,
                required String source,
                Value<DateTime> created = const Value.absent(),
              }) => SavedWordsCompanion.insert(
                id: id,
                expression: expression,
                reading: reading,
                definitions: definitions,
                source: source,
                created: created,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedWordsTable, SavedWord>(table),
                  BaseReferences<_$UserDb, $SavedWordsTable, SavedWord>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $SavedWordsTable,
      SavedWord,
      $$SavedWordsTableFilterComposer,
      $$SavedWordsTableOrderingComposer,
      $$SavedWordsTableAnnotationComposer,
      $$SavedWordsTableCreateCompanionBuilder,
      $$SavedWordsTableUpdateCompanionBuilder,
      (SavedWord, BaseReferences<_$UserDb, $SavedWordsTable, SavedWord>),
      SavedWord,
      PrefetchHooks Function()
    >;
typedef $$HistoryTableCreateCompanionBuilder = HistoryCompanion Function({
  required String query,
  Value<DateTime> searched,
  Value<int> rowid,
});
typedef $$HistoryTableUpdateCompanionBuilder = HistoryCompanion Function({
  Value<String> query,
  Value<DateTime> searched,
  Value<int> rowid,
});

class $$HistoryTableFilterComposer extends Composer<_$UserDb, $HistoryTable> {
  $$HistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get searched => $composableBuilder(
    column: $table.searched,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryTableOrderingComposer extends Composer<_$UserDb, $HistoryTable> {
  $$HistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get searched => $composableBuilder(
    column: $table.searched,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryTableAnnotationComposer
    extends Composer<_$UserDb, $HistoryTable> {
  $$HistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get searched =>
      $composableBuilder(column: $table.searched, builder: (column) => column);
}

class $$HistoryTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $HistoryTable,
          HistoryData,
          $$HistoryTableFilterComposer,
          $$HistoryTableOrderingComposer,
          $$HistoryTableAnnotationComposer,
          $$HistoryTableCreateCompanionBuilder,
          $$HistoryTableUpdateCompanionBuilder,
          (HistoryData, BaseReferences<_$UserDb, $HistoryTable, HistoryData>),
          HistoryData,
          PrefetchHooks Function()
        > {
  $$HistoryTableTableManager(_$UserDb db, $HistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> query = const Value.absent(),
                Value<DateTime> searched = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryCompanion(
                query: query,
                searched: searched,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String query,
                Value<DateTime> searched = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryCompanion.insert(
                query: query,
                searched: searched,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryTable, HistoryData>(table),
                  BaseReferences<_$UserDb, $HistoryTable, HistoryData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $HistoryTable,
      HistoryData,
      $$HistoryTableFilterComposer,
      $$HistoryTableOrderingComposer,
      $$HistoryTableAnnotationComposer,
      $$HistoryTableCreateCompanionBuilder,
      $$HistoryTableUpdateCompanionBuilder,
      (HistoryData, BaseReferences<_$UserDb, $HistoryTable, HistoryData>),
      HistoryData,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$UserDb, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$UserDb, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$UserDb, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (Preference, BaseReferences<_$UserDb, $PreferencesTable, Preference>),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$UserDb db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, Preference>(table),
                  BaseReferences<_$UserDb, $PreferencesTable, Preference>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (Preference, BaseReferences<_$UserDb, $PreferencesTable, Preference>),
      Preference,
      PrefetchHooks Function()
    >;

class $UserDbManager {
  final _$UserDb _db;
  $UserDbManager(this._db);
  $$SavedWordsTableTableManager get savedWords =>
      $$SavedWordsTableTableManager(_db, _db.savedWords);
  $$HistoryTableTableManager get history =>
      $$HistoryTableTableManager(_db, _db.history);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
}
