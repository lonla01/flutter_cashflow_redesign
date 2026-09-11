// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _montantMeta =
      const VerificationMeta('montant');
  @override
  late final GeneratedColumn<double> montant = GeneratedColumn<double>(
      'montant', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fraisMeta = const VerificationMeta('frais');
  @override
  late final GeneratedColumn<double> frais = GeneratedColumn<double>(
      'frais', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _montantNetMeta =
      const VerificationMeta('montantNet');
  @override
  late final GeneratedColumn<double> montantNet = GeneratedColumn<double>(
      'montant_net', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _soldeApresMeta =
      const VerificationMeta('soldeApres');
  @override
  late final GeneratedColumn<double> soldeApres = GeneratedColumn<double>(
      'solde_apres', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _contactNomMeta =
      const VerificationMeta('contactNom');
  @override
  late final GeneratedColumn<String> contactNom = GeneratedColumn<String>(
      'contact_nom', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contactNumeroMeta =
      const VerificationMeta('contactNumero');
  @override
  late final GeneratedColumn<String> contactNumero = GeneratedColumn<String>(
      'contact_numero', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categorieMeta =
      const VerificationMeta('categorie');
  @override
  late final GeneratedColumn<String> categorie = GeneratedColumn<String>(
      'categorie', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Autre'));
  static const VerificationMeta _dateTransactionMeta =
      const VerificationMeta('dateTransaction');
  @override
  late final GeneratedColumn<DateTime> dateTransaction =
      GeneratedColumn<DateTime>('date_transaction', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _idTransactionOperateurMeta =
      const VerificationMeta('idTransactionOperateur');
  @override
  late final GeneratedColumn<String> idTransactionOperateur =
      GeneratedColumn<String>('id_transaction_operateur', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _smsBrutMeta =
      const VerificationMeta('smsBrut');
  @override
  late final GeneratedColumn<String> smsBrut = GeneratedColumn<String>(
      'sms_brut', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _statutEditionMeta =
      const VerificationMeta('statutEdition');
  @override
  late final GeneratedColumn<String> statutEdition = GeneratedColumn<String>(
      'statut_edition', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('auto'));
  static const VerificationMeta _derniereModificationMeta =
      const VerificationMeta('derniereModification');
  @override
  late final GeneratedColumn<DateTime> derniereModification =
      GeneratedColumn<DateTime>('derniere_modification', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        source,
        type,
        montant,
        frais,
        montantNet,
        soldeApres,
        contactNom,
        contactNumero,
        categorie,
        dateTransaction,
        idTransactionOperateur,
        smsBrut,
        notes,
        statutEdition,
        derniereModification
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('montant')) {
      context.handle(_montantMeta,
          montant.isAcceptableOrUnknown(data['montant']!, _montantMeta));
    } else if (isInserting) {
      context.missing(_montantMeta);
    }
    if (data.containsKey('frais')) {
      context.handle(
          _fraisMeta, frais.isAcceptableOrUnknown(data['frais']!, _fraisMeta));
    }
    if (data.containsKey('montant_net')) {
      context.handle(
          _montantNetMeta,
          montantNet.isAcceptableOrUnknown(
              data['montant_net']!, _montantNetMeta));
    } else if (isInserting) {
      context.missing(_montantNetMeta);
    }
    if (data.containsKey('solde_apres')) {
      context.handle(
          _soldeApresMeta,
          soldeApres.isAcceptableOrUnknown(
              data['solde_apres']!, _soldeApresMeta));
    }
    if (data.containsKey('contact_nom')) {
      context.handle(
          _contactNomMeta,
          contactNom.isAcceptableOrUnknown(
              data['contact_nom']!, _contactNomMeta));
    }
    if (data.containsKey('contact_numero')) {
      context.handle(
          _contactNumeroMeta,
          contactNumero.isAcceptableOrUnknown(
              data['contact_numero']!, _contactNumeroMeta));
    }
    if (data.containsKey('categorie')) {
      context.handle(_categorieMeta,
          categorie.isAcceptableOrUnknown(data['categorie']!, _categorieMeta));
    }
    if (data.containsKey('date_transaction')) {
      context.handle(
          _dateTransactionMeta,
          dateTransaction.isAcceptableOrUnknown(
              data['date_transaction']!, _dateTransactionMeta));
    } else if (isInserting) {
      context.missing(_dateTransactionMeta);
    }
    if (data.containsKey('id_transaction_operateur')) {
      context.handle(
          _idTransactionOperateurMeta,
          idTransactionOperateur.isAcceptableOrUnknown(
              data['id_transaction_operateur']!, _idTransactionOperateurMeta));
    }
    if (data.containsKey('sms_brut')) {
      context.handle(_smsBrutMeta,
          smsBrut.isAcceptableOrUnknown(data['sms_brut']!, _smsBrutMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('statut_edition')) {
      context.handle(
          _statutEditionMeta,
          statutEdition.isAcceptableOrUnknown(
              data['statut_edition']!, _statutEditionMeta));
    }
    if (data.containsKey('derniere_modification')) {
      context.handle(
          _derniereModificationMeta,
          derniereModification.isAcceptableOrUnknown(
              data['derniere_modification']!, _derniereModificationMeta));
    } else if (isInserting) {
      context.missing(_derniereModificationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      montant: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}montant'])!,
      frais: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}frais'])!,
      montantNet: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}montant_net'])!,
      soldeApres: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}solde_apres']),
      contactNom: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_nom']),
      contactNumero: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_numero']),
      categorie: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categorie'])!,
      dateTransaction: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_transaction'])!,
      idTransactionOperateur: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}id_transaction_operateur']),
      smsBrut: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sms_brut']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      statutEdition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}statut_edition'])!,
      derniereModification: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}derniere_modification'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String source;
  final String type;
  final double montant;
  final double frais;
  final double montantNet;
  final double? soldeApres;
  final String? contactNom;
  final String? contactNumero;
  final String categorie;
  final DateTime dateTransaction;
  final String? idTransactionOperateur;
  final String? smsBrut;
  final String notes;
  final String statutEdition;
  final DateTime derniereModification;
  const TransactionRow(
      {required this.id,
      required this.source,
      required this.type,
      required this.montant,
      required this.frais,
      required this.montantNet,
      this.soldeApres,
      this.contactNom,
      this.contactNumero,
      required this.categorie,
      required this.dateTransaction,
      this.idTransactionOperateur,
      this.smsBrut,
      required this.notes,
      required this.statutEdition,
      required this.derniereModification});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    map['type'] = Variable<String>(type);
    map['montant'] = Variable<double>(montant);
    map['frais'] = Variable<double>(frais);
    map['montant_net'] = Variable<double>(montantNet);
    if (!nullToAbsent || soldeApres != null) {
      map['solde_apres'] = Variable<double>(soldeApres);
    }
    if (!nullToAbsent || contactNom != null) {
      map['contact_nom'] = Variable<String>(contactNom);
    }
    if (!nullToAbsent || contactNumero != null) {
      map['contact_numero'] = Variable<String>(contactNumero);
    }
    map['categorie'] = Variable<String>(categorie);
    map['date_transaction'] = Variable<DateTime>(dateTransaction);
    if (!nullToAbsent || idTransactionOperateur != null) {
      map['id_transaction_operateur'] =
          Variable<String>(idTransactionOperateur);
    }
    if (!nullToAbsent || smsBrut != null) {
      map['sms_brut'] = Variable<String>(smsBrut);
    }
    map['notes'] = Variable<String>(notes);
    map['statut_edition'] = Variable<String>(statutEdition);
    map['derniere_modification'] = Variable<DateTime>(derniereModification);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      source: Value(source),
      type: Value(type),
      montant: Value(montant),
      frais: Value(frais),
      montantNet: Value(montantNet),
      soldeApres: soldeApres == null && nullToAbsent
          ? const Value.absent()
          : Value(soldeApres),
      contactNom: contactNom == null && nullToAbsent
          ? const Value.absent()
          : Value(contactNom),
      contactNumero: contactNumero == null && nullToAbsent
          ? const Value.absent()
          : Value(contactNumero),
      categorie: Value(categorie),
      dateTransaction: Value(dateTransaction),
      idTransactionOperateur: idTransactionOperateur == null && nullToAbsent
          ? const Value.absent()
          : Value(idTransactionOperateur),
      smsBrut: smsBrut == null && nullToAbsent
          ? const Value.absent()
          : Value(smsBrut),
      notes: Value(notes),
      statutEdition: Value(statutEdition),
      derniereModification: Value(derniereModification),
    );
  }

  factory TransactionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      type: serializer.fromJson<String>(json['type']),
      montant: serializer.fromJson<double>(json['montant']),
      frais: serializer.fromJson<double>(json['frais']),
      montantNet: serializer.fromJson<double>(json['montantNet']),
      soldeApres: serializer.fromJson<double?>(json['soldeApres']),
      contactNom: serializer.fromJson<String?>(json['contactNom']),
      contactNumero: serializer.fromJson<String?>(json['contactNumero']),
      categorie: serializer.fromJson<String>(json['categorie']),
      dateTransaction: serializer.fromJson<DateTime>(json['dateTransaction']),
      idTransactionOperateur:
          serializer.fromJson<String?>(json['idTransactionOperateur']),
      smsBrut: serializer.fromJson<String?>(json['smsBrut']),
      notes: serializer.fromJson<String>(json['notes']),
      statutEdition: serializer.fromJson<String>(json['statutEdition']),
      derniereModification:
          serializer.fromJson<DateTime>(json['derniereModification']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'type': serializer.toJson<String>(type),
      'montant': serializer.toJson<double>(montant),
      'frais': serializer.toJson<double>(frais),
      'montantNet': serializer.toJson<double>(montantNet),
      'soldeApres': serializer.toJson<double?>(soldeApres),
      'contactNom': serializer.toJson<String?>(contactNom),
      'contactNumero': serializer.toJson<String?>(contactNumero),
      'categorie': serializer.toJson<String>(categorie),
      'dateTransaction': serializer.toJson<DateTime>(dateTransaction),
      'idTransactionOperateur':
          serializer.toJson<String?>(idTransactionOperateur),
      'smsBrut': serializer.toJson<String?>(smsBrut),
      'notes': serializer.toJson<String>(notes),
      'statutEdition': serializer.toJson<String>(statutEdition),
      'derniereModification': serializer.toJson<DateTime>(derniereModification),
    };
  }

  TransactionRow copyWith(
          {String? id,
          String? source,
          String? type,
          double? montant,
          double? frais,
          double? montantNet,
          Value<double?> soldeApres = const Value.absent(),
          Value<String?> contactNom = const Value.absent(),
          Value<String?> contactNumero = const Value.absent(),
          String? categorie,
          DateTime? dateTransaction,
          Value<String?> idTransactionOperateur = const Value.absent(),
          Value<String?> smsBrut = const Value.absent(),
          String? notes,
          String? statutEdition,
          DateTime? derniereModification}) =>
      TransactionRow(
        id: id ?? this.id,
        source: source ?? this.source,
        type: type ?? this.type,
        montant: montant ?? this.montant,
        frais: frais ?? this.frais,
        montantNet: montantNet ?? this.montantNet,
        soldeApres: soldeApres.present ? soldeApres.value : this.soldeApres,
        contactNom: contactNom.present ? contactNom.value : this.contactNom,
        contactNumero:
            contactNumero.present ? contactNumero.value : this.contactNumero,
        categorie: categorie ?? this.categorie,
        dateTransaction: dateTransaction ?? this.dateTransaction,
        idTransactionOperateur: idTransactionOperateur.present
            ? idTransactionOperateur.value
            : this.idTransactionOperateur,
        smsBrut: smsBrut.present ? smsBrut.value : this.smsBrut,
        notes: notes ?? this.notes,
        statutEdition: statutEdition ?? this.statutEdition,
        derniereModification: derniereModification ?? this.derniereModification,
      );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      type: data.type.present ? data.type.value : this.type,
      montant: data.montant.present ? data.montant.value : this.montant,
      frais: data.frais.present ? data.frais.value : this.frais,
      montantNet:
          data.montantNet.present ? data.montantNet.value : this.montantNet,
      soldeApres:
          data.soldeApres.present ? data.soldeApres.value : this.soldeApres,
      contactNom:
          data.contactNom.present ? data.contactNom.value : this.contactNom,
      contactNumero: data.contactNumero.present
          ? data.contactNumero.value
          : this.contactNumero,
      categorie: data.categorie.present ? data.categorie.value : this.categorie,
      dateTransaction: data.dateTransaction.present
          ? data.dateTransaction.value
          : this.dateTransaction,
      idTransactionOperateur: data.idTransactionOperateur.present
          ? data.idTransactionOperateur.value
          : this.idTransactionOperateur,
      smsBrut: data.smsBrut.present ? data.smsBrut.value : this.smsBrut,
      notes: data.notes.present ? data.notes.value : this.notes,
      statutEdition: data.statutEdition.present
          ? data.statutEdition.value
          : this.statutEdition,
      derniereModification: data.derniereModification.present
          ? data.derniereModification.value
          : this.derniereModification,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('type: $type, ')
          ..write('montant: $montant, ')
          ..write('frais: $frais, ')
          ..write('montantNet: $montantNet, ')
          ..write('soldeApres: $soldeApres, ')
          ..write('contactNom: $contactNom, ')
          ..write('contactNumero: $contactNumero, ')
          ..write('categorie: $categorie, ')
          ..write('dateTransaction: $dateTransaction, ')
          ..write('idTransactionOperateur: $idTransactionOperateur, ')
          ..write('smsBrut: $smsBrut, ')
          ..write('notes: $notes, ')
          ..write('statutEdition: $statutEdition, ')
          ..write('derniereModification: $derniereModification')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      source,
      type,
      montant,
      frais,
      montantNet,
      soldeApres,
      contactNom,
      contactNumero,
      categorie,
      dateTransaction,
      idTransactionOperateur,
      smsBrut,
      notes,
      statutEdition,
      derniereModification);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.type == this.type &&
          other.montant == this.montant &&
          other.frais == this.frais &&
          other.montantNet == this.montantNet &&
          other.soldeApres == this.soldeApres &&
          other.contactNom == this.contactNom &&
          other.contactNumero == this.contactNumero &&
          other.categorie == this.categorie &&
          other.dateTransaction == this.dateTransaction &&
          other.idTransactionOperateur == this.idTransactionOperateur &&
          other.smsBrut == this.smsBrut &&
          other.notes == this.notes &&
          other.statutEdition == this.statutEdition &&
          other.derniereModification == this.derniereModification);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> source;
  final Value<String> type;
  final Value<double> montant;
  final Value<double> frais;
  final Value<double> montantNet;
  final Value<double?> soldeApres;
  final Value<String?> contactNom;
  final Value<String?> contactNumero;
  final Value<String> categorie;
  final Value<DateTime> dateTransaction;
  final Value<String?> idTransactionOperateur;
  final Value<String?> smsBrut;
  final Value<String> notes;
  final Value<String> statutEdition;
  final Value<DateTime> derniereModification;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.type = const Value.absent(),
    this.montant = const Value.absent(),
    this.frais = const Value.absent(),
    this.montantNet = const Value.absent(),
    this.soldeApres = const Value.absent(),
    this.contactNom = const Value.absent(),
    this.contactNumero = const Value.absent(),
    this.categorie = const Value.absent(),
    this.dateTransaction = const Value.absent(),
    this.idTransactionOperateur = const Value.absent(),
    this.smsBrut = const Value.absent(),
    this.notes = const Value.absent(),
    this.statutEdition = const Value.absent(),
    this.derniereModification = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String source,
    required String type,
    required double montant,
    this.frais = const Value.absent(),
    required double montantNet,
    this.soldeApres = const Value.absent(),
    this.contactNom = const Value.absent(),
    this.contactNumero = const Value.absent(),
    this.categorie = const Value.absent(),
    required DateTime dateTransaction,
    this.idTransactionOperateur = const Value.absent(),
    this.smsBrut = const Value.absent(),
    this.notes = const Value.absent(),
    this.statutEdition = const Value.absent(),
    required DateTime derniereModification,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        source = Value(source),
        type = Value(type),
        montant = Value(montant),
        montantNet = Value(montantNet),
        dateTransaction = Value(dateTransaction),
        derniereModification = Value(derniereModification);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? type,
    Expression<double>? montant,
    Expression<double>? frais,
    Expression<double>? montantNet,
    Expression<double>? soldeApres,
    Expression<String>? contactNom,
    Expression<String>? contactNumero,
    Expression<String>? categorie,
    Expression<DateTime>? dateTransaction,
    Expression<String>? idTransactionOperateur,
    Expression<String>? smsBrut,
    Expression<String>? notes,
    Expression<String>? statutEdition,
    Expression<DateTime>? derniereModification,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (type != null) 'type': type,
      if (montant != null) 'montant': montant,
      if (frais != null) 'frais': frais,
      if (montantNet != null) 'montant_net': montantNet,
      if (soldeApres != null) 'solde_apres': soldeApres,
      if (contactNom != null) 'contact_nom': contactNom,
      if (contactNumero != null) 'contact_numero': contactNumero,
      if (categorie != null) 'categorie': categorie,
      if (dateTransaction != null) 'date_transaction': dateTransaction,
      if (idTransactionOperateur != null)
        'id_transaction_operateur': idTransactionOperateur,
      if (smsBrut != null) 'sms_brut': smsBrut,
      if (notes != null) 'notes': notes,
      if (statutEdition != null) 'statut_edition': statutEdition,
      if (derniereModification != null)
        'derniere_modification': derniereModification,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? source,
      Value<String>? type,
      Value<double>? montant,
      Value<double>? frais,
      Value<double>? montantNet,
      Value<double?>? soldeApres,
      Value<String?>? contactNom,
      Value<String?>? contactNumero,
      Value<String>? categorie,
      Value<DateTime>? dateTransaction,
      Value<String?>? idTransactionOperateur,
      Value<String?>? smsBrut,
      Value<String>? notes,
      Value<String>? statutEdition,
      Value<DateTime>? derniereModification,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      type: type ?? this.type,
      montant: montant ?? this.montant,
      frais: frais ?? this.frais,
      montantNet: montantNet ?? this.montantNet,
      soldeApres: soldeApres ?? this.soldeApres,
      contactNom: contactNom ?? this.contactNom,
      contactNumero: contactNumero ?? this.contactNumero,
      categorie: categorie ?? this.categorie,
      dateTransaction: dateTransaction ?? this.dateTransaction,
      idTransactionOperateur:
          idTransactionOperateur ?? this.idTransactionOperateur,
      smsBrut: smsBrut ?? this.smsBrut,
      notes: notes ?? this.notes,
      statutEdition: statutEdition ?? this.statutEdition,
      derniereModification: derniereModification ?? this.derniereModification,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (montant.present) {
      map['montant'] = Variable<double>(montant.value);
    }
    if (frais.present) {
      map['frais'] = Variable<double>(frais.value);
    }
    if (montantNet.present) {
      map['montant_net'] = Variable<double>(montantNet.value);
    }
    if (soldeApres.present) {
      map['solde_apres'] = Variable<double>(soldeApres.value);
    }
    if (contactNom.present) {
      map['contact_nom'] = Variable<String>(contactNom.value);
    }
    if (contactNumero.present) {
      map['contact_numero'] = Variable<String>(contactNumero.value);
    }
    if (categorie.present) {
      map['categorie'] = Variable<String>(categorie.value);
    }
    if (dateTransaction.present) {
      map['date_transaction'] = Variable<DateTime>(dateTransaction.value);
    }
    if (idTransactionOperateur.present) {
      map['id_transaction_operateur'] =
          Variable<String>(idTransactionOperateur.value);
    }
    if (smsBrut.present) {
      map['sms_brut'] = Variable<String>(smsBrut.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (statutEdition.present) {
      map['statut_edition'] = Variable<String>(statutEdition.value);
    }
    if (derniereModification.present) {
      map['derniere_modification'] =
          Variable<DateTime>(derniereModification.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('type: $type, ')
          ..write('montant: $montant, ')
          ..write('frais: $frais, ')
          ..write('montantNet: $montantNet, ')
          ..write('soldeApres: $soldeApres, ')
          ..write('contactNom: $contactNom, ')
          ..write('contactNumero: $contactNumero, ')
          ..write('categorie: $categorie, ')
          ..write('dateTransaction: $dateTransaction, ')
          ..write('idTransactionOperateur: $idTransactionOperateur, ')
          ..write('smsBrut: $smsBrut, ')
          ..write('notes: $notes, ')
          ..write('statutEdition: $statutEdition, ')
          ..write('derniereModification: $derniereModification, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryRulesTable extends CategoryRules
    with TableInfo<$CategoryRulesTable, CategoryRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _matchTypeMeta =
      const VerificationMeta('matchType');
  @override
  late final GeneratedColumn<String> matchType = GeneratedColumn<String>(
      'match_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matchValueMeta =
      const VerificationMeta('matchValue');
  @override
  late final GeneratedColumn<String> matchValue = GeneratedColumn<String>(
      'match_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categorieMeta =
      const VerificationMeta('categorie');
  @override
  late final GeneratedColumn<String> categorie = GeneratedColumn<String>(
      'categorie', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, matchType, matchValue, categorie];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_rules';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRuleRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('match_type')) {
      context.handle(_matchTypeMeta,
          matchType.isAcceptableOrUnknown(data['match_type']!, _matchTypeMeta));
    } else if (isInserting) {
      context.missing(_matchTypeMeta);
    }
    if (data.containsKey('match_value')) {
      context.handle(
          _matchValueMeta,
          matchValue.isAcceptableOrUnknown(
              data['match_value']!, _matchValueMeta));
    } else if (isInserting) {
      context.missing(_matchValueMeta);
    }
    if (data.containsKey('categorie')) {
      context.handle(_categorieMeta,
          categorie.isAcceptableOrUnknown(data['categorie']!, _categorieMeta));
    } else if (isInserting) {
      context.missing(_categorieMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRuleRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      matchType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_type'])!,
      matchValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_value'])!,
      categorie: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categorie'])!,
    );
  }

  @override
  $CategoryRulesTable createAlias(String alias) {
    return $CategoryRulesTable(attachedDatabase, alias);
  }
}

class CategoryRuleRow extends DataClass implements Insertable<CategoryRuleRow> {
  final int id;
  final String matchType;
  final String matchValue;
  final String categorie;
  const CategoryRuleRow(
      {required this.id,
      required this.matchType,
      required this.matchValue,
      required this.categorie});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['match_type'] = Variable<String>(matchType);
    map['match_value'] = Variable<String>(matchValue);
    map['categorie'] = Variable<String>(categorie);
    return map;
  }

  CategoryRulesCompanion toCompanion(bool nullToAbsent) {
    return CategoryRulesCompanion(
      id: Value(id),
      matchType: Value(matchType),
      matchValue: Value(matchValue),
      categorie: Value(categorie),
    );
  }

  factory CategoryRuleRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRuleRow(
      id: serializer.fromJson<int>(json['id']),
      matchType: serializer.fromJson<String>(json['matchType']),
      matchValue: serializer.fromJson<String>(json['matchValue']),
      categorie: serializer.fromJson<String>(json['categorie']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matchType': serializer.toJson<String>(matchType),
      'matchValue': serializer.toJson<String>(matchValue),
      'categorie': serializer.toJson<String>(categorie),
    };
  }

  CategoryRuleRow copyWith(
          {int? id,
          String? matchType,
          String? matchValue,
          String? categorie}) =>
      CategoryRuleRow(
        id: id ?? this.id,
        matchType: matchType ?? this.matchType,
        matchValue: matchValue ?? this.matchValue,
        categorie: categorie ?? this.categorie,
      );
  CategoryRuleRow copyWithCompanion(CategoryRulesCompanion data) {
    return CategoryRuleRow(
      id: data.id.present ? data.id.value : this.id,
      matchType: data.matchType.present ? data.matchType.value : this.matchType,
      matchValue:
          data.matchValue.present ? data.matchValue.value : this.matchValue,
      categorie: data.categorie.present ? data.categorie.value : this.categorie,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRuleRow(')
          ..write('id: $id, ')
          ..write('matchType: $matchType, ')
          ..write('matchValue: $matchValue, ')
          ..write('categorie: $categorie')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, matchType, matchValue, categorie);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRuleRow &&
          other.id == this.id &&
          other.matchType == this.matchType &&
          other.matchValue == this.matchValue &&
          other.categorie == this.categorie);
}

class CategoryRulesCompanion extends UpdateCompanion<CategoryRuleRow> {
  final Value<int> id;
  final Value<String> matchType;
  final Value<String> matchValue;
  final Value<String> categorie;
  const CategoryRulesCompanion({
    this.id = const Value.absent(),
    this.matchType = const Value.absent(),
    this.matchValue = const Value.absent(),
    this.categorie = const Value.absent(),
  });
  CategoryRulesCompanion.insert({
    this.id = const Value.absent(),
    required String matchType,
    required String matchValue,
    required String categorie,
  })  : matchType = Value(matchType),
        matchValue = Value(matchValue),
        categorie = Value(categorie);
  static Insertable<CategoryRuleRow> custom({
    Expression<int>? id,
    Expression<String>? matchType,
    Expression<String>? matchValue,
    Expression<String>? categorie,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchType != null) 'match_type': matchType,
      if (matchValue != null) 'match_value': matchValue,
      if (categorie != null) 'categorie': categorie,
    });
  }

  CategoryRulesCompanion copyWith(
      {Value<int>? id,
      Value<String>? matchType,
      Value<String>? matchValue,
      Value<String>? categorie}) {
    return CategoryRulesCompanion(
      id: id ?? this.id,
      matchType: matchType ?? this.matchType,
      matchValue: matchValue ?? this.matchValue,
      categorie: categorie ?? this.categorie,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matchType.present) {
      map['match_type'] = Variable<String>(matchType.value);
    }
    if (matchValue.present) {
      map['match_value'] = Variable<String>(matchValue.value);
    }
    if (categorie.present) {
      map['categorie'] = Variable<String>(categorie.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRulesCompanion(')
          ..write('id: $id, ')
          ..write('matchType: $matchType, ')
          ..write('matchValue: $matchValue, ')
          ..write('categorie: $categorie')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueEntriesTable extends SyncQueueEntries
    with TableInfo<$SyncQueueEntriesTable, SyncQueueEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('upsert'));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('en_attente'));
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityId,
        operation,
        payload,
        createdAt,
        updatedAt,
        status,
        attemptCount,
        lastError,
        nextAttemptAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at']),
    );
  }

  @override
  $SyncQueueEntriesTable createAlias(String alias) {
    return $SyncQueueEntriesTable(attachedDatabase, alias);
  }
}

class SyncQueueEntryRow extends DataClass
    implements Insertable<SyncQueueEntryRow> {
  final int id;
  final String entityId;
  final String operation;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final int attemptCount;
  final String? lastError;
  final DateTime? nextAttemptAt;
  const SyncQueueEntryRow(
      {required this.id,
      required this.entityId,
      required this.operation,
      required this.payload,
      required this.createdAt,
      required this.updatedAt,
      required this.status,
      required this.attemptCount,
      this.lastError,
      this.nextAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    return map;
  }

  SyncQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueEntriesCompanion(
      id: Value(id),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
    );
  }

  factory SyncQueueEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntryRow(
      id: serializer.fromJson<int>(json['id']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
    };
  }

  SyncQueueEntryRow copyWith(
          {int? id,
          String? entityId,
          String? operation,
          String? payload,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? status,
          int? attemptCount,
          Value<String?> lastError = const Value.absent(),
          Value<DateTime?> nextAttemptAt = const Value.absent()}) =>
      SyncQueueEntryRow(
        id: id ?? this.id,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        lastError: lastError.present ? lastError.value : this.lastError,
        nextAttemptAt:
            nextAttemptAt.present ? nextAttemptAt.value : this.nextAttemptAt,
      );
  SyncQueueEntryRow copyWithCompanion(SyncQueueEntriesCompanion data) {
    return SyncQueueEntryRow(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntryRow(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityId, operation, payload, createdAt,
      updatedAt, status, attemptCount, lastError, nextAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntryRow &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class SyncQueueEntriesCompanion extends UpdateCompanion<SyncQueueEntryRow> {
  final Value<int> id;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  const SyncQueueEntriesCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
  });
  SyncQueueEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String entityId,
    this.operation = const Value.absent(),
    required String payload,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
  })  : entityId = Value(entityId),
        payload = Value(payload),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SyncQueueEntryRow> custom({
    Expression<int>? id,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
    });
  }

  SyncQueueEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? status,
      Value<int>? attemptCount,
      Value<String?>? lastError,
      Value<DateTime?>? nextAttemptAt}) {
    return SyncQueueEntriesCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }
}

class $ConflictHistoryEntriesTable extends ConflictHistoryEntries
    with TableInfo<$ConflictHistoryEntriesTable, ConflictHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localVersionJsonMeta =
      const VerificationMeta('localVersionJson');
  @override
  late final GeneratedColumn<String> localVersionJson = GeneratedColumn<String>(
      'local_version_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteVersionJsonMeta =
      const VerificationMeta('remoteVersionJson');
  @override
  late final GeneratedColumn<String> remoteVersionJson =
      GeneratedColumn<String>('remote_version_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detectedAtMeta =
      const VerificationMeta('detectedAt');
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
      'detected_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, transactionId, localVersionJson, remoteVersionJson, detectedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflict_history_entries';
  @override
  VerificationContext validateIntegrity(Insertable<ConflictHistoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('local_version_json')) {
      context.handle(
          _localVersionJsonMeta,
          localVersionJson.isAcceptableOrUnknown(
              data['local_version_json']!, _localVersionJsonMeta));
    } else if (isInserting) {
      context.missing(_localVersionJsonMeta);
    }
    if (data.containsKey('remote_version_json')) {
      context.handle(
          _remoteVersionJsonMeta,
          remoteVersionJson.isAcceptableOrUnknown(
              data['remote_version_json']!, _remoteVersionJsonMeta));
    } else if (isInserting) {
      context.missing(_remoteVersionJsonMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
          _detectedAtMeta,
          detectedAt.isAcceptableOrUnknown(
              data['detected_at']!, _detectedAtMeta));
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConflictHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictHistoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      localVersionJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_version_json'])!,
      remoteVersionJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}remote_version_json'])!,
      detectedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}detected_at'])!,
    );
  }

  @override
  $ConflictHistoryEntriesTable createAlias(String alias) {
    return $ConflictHistoryEntriesTable(attachedDatabase, alias);
  }
}

class ConflictHistoryRow extends DataClass
    implements Insertable<ConflictHistoryRow> {
  final int id;
  final String transactionId;
  final String localVersionJson;
  final String remoteVersionJson;
  final DateTime detectedAt;
  const ConflictHistoryRow(
      {required this.id,
      required this.transactionId,
      required this.localVersionJson,
      required this.remoteVersionJson,
      required this.detectedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['local_version_json'] = Variable<String>(localVersionJson);
    map['remote_version_json'] = Variable<String>(remoteVersionJson);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    return map;
  }

  ConflictHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return ConflictHistoryEntriesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      localVersionJson: Value(localVersionJson),
      remoteVersionJson: Value(remoteVersionJson),
      detectedAt: Value(detectedAt),
    );
  }

  factory ConflictHistoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      localVersionJson: serializer.fromJson<String>(json['localVersionJson']),
      remoteVersionJson: serializer.fromJson<String>(json['remoteVersionJson']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'localVersionJson': serializer.toJson<String>(localVersionJson),
      'remoteVersionJson': serializer.toJson<String>(remoteVersionJson),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
    };
  }

  ConflictHistoryRow copyWith(
          {int? id,
          String? transactionId,
          String? localVersionJson,
          String? remoteVersionJson,
          DateTime? detectedAt}) =>
      ConflictHistoryRow(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        localVersionJson: localVersionJson ?? this.localVersionJson,
        remoteVersionJson: remoteVersionJson ?? this.remoteVersionJson,
        detectedAt: detectedAt ?? this.detectedAt,
      );
  ConflictHistoryRow copyWithCompanion(ConflictHistoryEntriesCompanion data) {
    return ConflictHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      localVersionJson: data.localVersionJson.present
          ? data.localVersionJson.value
          : this.localVersionJson,
      remoteVersionJson: data.remoteVersionJson.present
          ? data.remoteVersionJson.value
          : this.remoteVersionJson,
      detectedAt:
          data.detectedAt.present ? data.detectedAt.value : this.detectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictHistoryRow(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('localVersionJson: $localVersionJson, ')
          ..write('remoteVersionJson: $remoteVersionJson, ')
          ..write('detectedAt: $detectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, transactionId, localVersionJson, remoteVersionJson, detectedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictHistoryRow &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.localVersionJson == this.localVersionJson &&
          other.remoteVersionJson == this.remoteVersionJson &&
          other.detectedAt == this.detectedAt);
}

class ConflictHistoryEntriesCompanion
    extends UpdateCompanion<ConflictHistoryRow> {
  final Value<int> id;
  final Value<String> transactionId;
  final Value<String> localVersionJson;
  final Value<String> remoteVersionJson;
  final Value<DateTime> detectedAt;
  const ConflictHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.localVersionJson = const Value.absent(),
    this.remoteVersionJson = const Value.absent(),
    this.detectedAt = const Value.absent(),
  });
  ConflictHistoryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String transactionId,
    required String localVersionJson,
    required String remoteVersionJson,
    required DateTime detectedAt,
  })  : transactionId = Value(transactionId),
        localVersionJson = Value(localVersionJson),
        remoteVersionJson = Value(remoteVersionJson),
        detectedAt = Value(detectedAt);
  static Insertable<ConflictHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? transactionId,
    Expression<String>? localVersionJson,
    Expression<String>? remoteVersionJson,
    Expression<DateTime>? detectedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (localVersionJson != null) 'local_version_json': localVersionJson,
      if (remoteVersionJson != null) 'remote_version_json': remoteVersionJson,
      if (detectedAt != null) 'detected_at': detectedAt,
    });
  }

  ConflictHistoryEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? transactionId,
      Value<String>? localVersionJson,
      Value<String>? remoteVersionJson,
      Value<DateTime>? detectedAt}) {
    return ConflictHistoryEntriesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      localVersionJson: localVersionJson ?? this.localVersionJson,
      remoteVersionJson: remoteVersionJson ?? this.remoteVersionJson,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (localVersionJson.present) {
      map['local_version_json'] = Variable<String>(localVersionJson.value);
    }
    if (remoteVersionJson.present) {
      map['remote_version_json'] = Variable<String>(remoteVersionJson.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('localVersionJson: $localVersionJson, ')
          ..write('remoteVersionJson: $remoteVersionJson, ')
          ..write('detectedAt: $detectedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTableTable extends SyncMetaTable
    with TableInfo<$SyncMetaTableTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastPulledAtMeta =
      const VerificationMeta('lastPulledAt');
  @override
  late final GeneratedColumn<DateTime> lastPulledAt = GeneratedColumn<DateTime>(
      'last_pulled_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, lastPulledAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_pulled_at')) {
      context.handle(
          _lastPulledAtMeta,
          lastPulledAt.isAcceptableOrUnknown(
              data['last_pulled_at']!, _lastPulledAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lastPulledAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_pulled_at']),
    );
  }

  @override
  $SyncMetaTableTable createAlias(String alias) {
    return $SyncMetaTableTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final int id;
  final DateTime? lastPulledAt;
  const SyncMetaRow({required this.id, this.lastPulledAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lastPulledAt != null) {
      map['last_pulled_at'] = Variable<DateTime>(lastPulledAt);
    }
    return map;
  }

  SyncMetaTableCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaTableCompanion(
      id: Value(id),
      lastPulledAt: lastPulledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPulledAt),
    );
  }

  factory SyncMetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
      id: serializer.fromJson<int>(json['id']),
      lastPulledAt: serializer.fromJson<DateTime?>(json['lastPulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastPulledAt': serializer.toJson<DateTime?>(lastPulledAt),
    };
  }

  SyncMetaRow copyWith(
          {int? id, Value<DateTime?> lastPulledAt = const Value.absent()}) =>
      SyncMetaRow(
        id: id ?? this.id,
        lastPulledAt:
            lastPulledAt.present ? lastPulledAt.value : this.lastPulledAt,
      );
  SyncMetaRow copyWithCompanion(SyncMetaTableCompanion data) {
    return SyncMetaRow(
      id: data.id.present ? data.id.value : this.id,
      lastPulledAt: data.lastPulledAt.present
          ? data.lastPulledAt.value
          : this.lastPulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
          ..write('id: $id, ')
          ..write('lastPulledAt: $lastPulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastPulledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaRow &&
          other.id == this.id &&
          other.lastPulledAt == this.lastPulledAt);
}

class SyncMetaTableCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<int> id;
  final Value<DateTime?> lastPulledAt;
  const SyncMetaTableCompanion({
    this.id = const Value.absent(),
    this.lastPulledAt = const Value.absent(),
  });
  SyncMetaTableCompanion.insert({
    this.id = const Value.absent(),
    this.lastPulledAt = const Value.absent(),
  });
  static Insertable<SyncMetaRow> custom({
    Expression<int>? id,
    Expression<DateTime>? lastPulledAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastPulledAt != null) 'last_pulled_at': lastPulledAt,
    });
  }

  SyncMetaTableCompanion copyWith(
      {Value<int>? id, Value<DateTime?>? lastPulledAt}) {
    return SyncMetaTableCompanion(
      id: id ?? this.id,
      lastPulledAt: lastPulledAt ?? this.lastPulledAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastPulledAt.present) {
      map['last_pulled_at'] = Variable<DateTime>(lastPulledAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaTableCompanion(')
          ..write('id: $id, ')
          ..write('lastPulledAt: $lastPulledAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabaseDrift extends GeneratedDatabase {
  _$AppDatabaseDrift(QueryExecutor e) : super(e);
  $AppDatabaseDriftManager get managers => $AppDatabaseDriftManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $CategoryRulesTable categoryRules = $CategoryRulesTable(this);
  late final $SyncQueueEntriesTable syncQueueEntries =
      $SyncQueueEntriesTable(this);
  late final $ConflictHistoryEntriesTable conflictHistoryEntries =
      $ConflictHistoryEntriesTable(this);
  late final $SyncMetaTableTable syncMetaTable = $SyncMetaTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        transactions,
        categoryRules,
        syncQueueEntries,
        conflictHistoryEntries,
        syncMetaTable
      ];
}

typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String id,
  required String source,
  required String type,
  required double montant,
  Value<double> frais,
  required double montantNet,
  Value<double?> soldeApres,
  Value<String?> contactNom,
  Value<String?> contactNumero,
  Value<String> categorie,
  required DateTime dateTransaction,
  Value<String?> idTransactionOperateur,
  Value<String?> smsBrut,
  Value<String> notes,
  Value<String> statutEdition,
  required DateTime derniereModification,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> source,
  Value<String> type,
  Value<double> montant,
  Value<double> frais,
  Value<double> montantNet,
  Value<double?> soldeApres,
  Value<String?> contactNom,
  Value<String?> contactNumero,
  Value<String> categorie,
  Value<DateTime> dateTransaction,
  Value<String?> idTransactionOperateur,
  Value<String?> smsBrut,
  Value<String> notes,
  Value<String> statutEdition,
  Value<DateTime> derniereModification,
  Value<int> rowid,
});

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabaseDrift, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get montant => $composableBuilder(
      column: $table.montant, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get frais => $composableBuilder(
      column: $table.frais, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get montantNet => $composableBuilder(
      column: $table.montantNet, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get soldeApres => $composableBuilder(
      column: $table.soldeApres, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactNom => $composableBuilder(
      column: $table.contactNom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactNumero => $composableBuilder(
      column: $table.contactNumero, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categorie => $composableBuilder(
      column: $table.categorie, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateTransaction => $composableBuilder(
      column: $table.dateTransaction,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idTransactionOperateur => $composableBuilder(
      column: $table.idTransactionOperateur,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get smsBrut => $composableBuilder(
      column: $table.smsBrut, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statutEdition => $composableBuilder(
      column: $table.statutEdition, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get derniereModification => $composableBuilder(
      column: $table.derniereModification,
      builder: (column) => ColumnFilters(column));
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabaseDrift, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get montant => $composableBuilder(
      column: $table.montant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get frais => $composableBuilder(
      column: $table.frais, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get montantNet => $composableBuilder(
      column: $table.montantNet, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get soldeApres => $composableBuilder(
      column: $table.soldeApres, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactNom => $composableBuilder(
      column: $table.contactNom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactNumero => $composableBuilder(
      column: $table.contactNumero,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categorie => $composableBuilder(
      column: $table.categorie, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateTransaction => $composableBuilder(
      column: $table.dateTransaction,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idTransactionOperateur => $composableBuilder(
      column: $table.idTransactionOperateur,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get smsBrut => $composableBuilder(
      column: $table.smsBrut, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statutEdition => $composableBuilder(
      column: $table.statutEdition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get derniereModification => $composableBuilder(
      column: $table.derniereModification,
      builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabaseDrift, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get montant =>
      $composableBuilder(column: $table.montant, builder: (column) => column);

  GeneratedColumn<double> get frais =>
      $composableBuilder(column: $table.frais, builder: (column) => column);

  GeneratedColumn<double> get montantNet => $composableBuilder(
      column: $table.montantNet, builder: (column) => column);

  GeneratedColumn<double> get soldeApres => $composableBuilder(
      column: $table.soldeApres, builder: (column) => column);

  GeneratedColumn<String> get contactNom => $composableBuilder(
      column: $table.contactNom, builder: (column) => column);

  GeneratedColumn<String> get contactNumero => $composableBuilder(
      column: $table.contactNumero, builder: (column) => column);

  GeneratedColumn<String> get categorie =>
      $composableBuilder(column: $table.categorie, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTransaction => $composableBuilder(
      column: $table.dateTransaction, builder: (column) => column);

  GeneratedColumn<String> get idTransactionOperateur => $composableBuilder(
      column: $table.idTransactionOperateur, builder: (column) => column);

  GeneratedColumn<String> get smsBrut =>
      $composableBuilder(column: $table.smsBrut, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get statutEdition => $composableBuilder(
      column: $table.statutEdition, builder: (column) => column);

  GeneratedColumn<DateTime> get derniereModification => $composableBuilder(
      column: $table.derniereModification, builder: (column) => column);
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabaseDrift,
    $TransactionsTable,
    TransactionRow,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      TransactionRow,
      BaseReferences<_$AppDatabaseDrift, $TransactionsTable, TransactionRow>
    ),
    TransactionRow,
    PrefetchHooks Function()> {
  $$TransactionsTableTableManager(
      _$AppDatabaseDrift db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> montant = const Value.absent(),
            Value<double> frais = const Value.absent(),
            Value<double> montantNet = const Value.absent(),
            Value<double?> soldeApres = const Value.absent(),
            Value<String?> contactNom = const Value.absent(),
            Value<String?> contactNumero = const Value.absent(),
            Value<String> categorie = const Value.absent(),
            Value<DateTime> dateTransaction = const Value.absent(),
            Value<String?> idTransactionOperateur = const Value.absent(),
            Value<String?> smsBrut = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> statutEdition = const Value.absent(),
            Value<DateTime> derniereModification = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            source: source,
            type: type,
            montant: montant,
            frais: frais,
            montantNet: montantNet,
            soldeApres: soldeApres,
            contactNom: contactNom,
            contactNumero: contactNumero,
            categorie: categorie,
            dateTransaction: dateTransaction,
            idTransactionOperateur: idTransactionOperateur,
            smsBrut: smsBrut,
            notes: notes,
            statutEdition: statutEdition,
            derniereModification: derniereModification,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String source,
            required String type,
            required double montant,
            Value<double> frais = const Value.absent(),
            required double montantNet,
            Value<double?> soldeApres = const Value.absent(),
            Value<String?> contactNom = const Value.absent(),
            Value<String?> contactNumero = const Value.absent(),
            Value<String> categorie = const Value.absent(),
            required DateTime dateTransaction,
            Value<String?> idTransactionOperateur = const Value.absent(),
            Value<String?> smsBrut = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> statutEdition = const Value.absent(),
            required DateTime derniereModification,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            source: source,
            type: type,
            montant: montant,
            frais: frais,
            montantNet: montantNet,
            soldeApres: soldeApres,
            contactNom: contactNom,
            contactNumero: contactNumero,
            categorie: categorie,
            dateTransaction: dateTransaction,
            idTransactionOperateur: idTransactionOperateur,
            smsBrut: smsBrut,
            notes: notes,
            statutEdition: statutEdition,
            derniereModification: derniereModification,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TransactionsTable, TransactionRow>(table),
                    BaseReferences<_$AppDatabaseDrift, $TransactionsTable,
                        TransactionRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabaseDrift,
    $TransactionsTable,
    TransactionRow,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      TransactionRow,
      BaseReferences<_$AppDatabaseDrift, $TransactionsTable, TransactionRow>
    ),
    TransactionRow,
    PrefetchHooks Function()>;
typedef $$CategoryRulesTableCreateCompanionBuilder = CategoryRulesCompanion
    Function({
  Value<int> id,
  required String matchType,
  required String matchValue,
  required String categorie,
});
typedef $$CategoryRulesTableUpdateCompanionBuilder = CategoryRulesCompanion
    Function({
  Value<int> id,
  Value<String> matchType,
  Value<String> matchValue,
  Value<String> categorie,
});

class $$CategoryRulesTableFilterComposer
    extends Composer<_$AppDatabaseDrift, $CategoryRulesTable> {
  $$CategoryRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchType => $composableBuilder(
      column: $table.matchType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchValue => $composableBuilder(
      column: $table.matchValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categorie => $composableBuilder(
      column: $table.categorie, builder: (column) => ColumnFilters(column));
}

class $$CategoryRulesTableOrderingComposer
    extends Composer<_$AppDatabaseDrift, $CategoryRulesTable> {
  $$CategoryRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchType => $composableBuilder(
      column: $table.matchType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchValue => $composableBuilder(
      column: $table.matchValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categorie => $composableBuilder(
      column: $table.categorie, builder: (column) => ColumnOrderings(column));
}

class $$CategoryRulesTableAnnotationComposer
    extends Composer<_$AppDatabaseDrift, $CategoryRulesTable> {
  $$CategoryRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get matchType =>
      $composableBuilder(column: $table.matchType, builder: (column) => column);

  GeneratedColumn<String> get matchValue => $composableBuilder(
      column: $table.matchValue, builder: (column) => column);

  GeneratedColumn<String> get categorie =>
      $composableBuilder(column: $table.categorie, builder: (column) => column);
}

class $$CategoryRulesTableTableManager extends RootTableManager<
    _$AppDatabaseDrift,
    $CategoryRulesTable,
    CategoryRuleRow,
    $$CategoryRulesTableFilterComposer,
    $$CategoryRulesTableOrderingComposer,
    $$CategoryRulesTableAnnotationComposer,
    $$CategoryRulesTableCreateCompanionBuilder,
    $$CategoryRulesTableUpdateCompanionBuilder,
    (
      CategoryRuleRow,
      BaseReferences<_$AppDatabaseDrift, $CategoryRulesTable, CategoryRuleRow>
    ),
    CategoryRuleRow,
    PrefetchHooks Function()> {
  $$CategoryRulesTableTableManager(
      _$AppDatabaseDrift db, $CategoryRulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> matchType = const Value.absent(),
            Value<String> matchValue = const Value.absent(),
            Value<String> categorie = const Value.absent(),
          }) =>
              CategoryRulesCompanion(
            id: id,
            matchType: matchType,
            matchValue: matchValue,
            categorie: categorie,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String matchType,
            required String matchValue,
            required String categorie,
          }) =>
              CategoryRulesCompanion.insert(
            id: id,
            matchType: matchType,
            matchValue: matchValue,
            categorie: categorie,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CategoryRulesTable, CategoryRuleRow>(table),
                    BaseReferences<_$AppDatabaseDrift, $CategoryRulesTable,
                        CategoryRuleRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryRulesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabaseDrift,
    $CategoryRulesTable,
    CategoryRuleRow,
    $$CategoryRulesTableFilterComposer,
    $$CategoryRulesTableOrderingComposer,
    $$CategoryRulesTableAnnotationComposer,
    $$CategoryRulesTableCreateCompanionBuilder,
    $$CategoryRulesTableUpdateCompanionBuilder,
    (
      CategoryRuleRow,
      BaseReferences<_$AppDatabaseDrift, $CategoryRulesTable, CategoryRuleRow>
    ),
    CategoryRuleRow,
    PrefetchHooks Function()>;
typedef $$SyncQueueEntriesTableCreateCompanionBuilder
    = SyncQueueEntriesCompanion Function({
  Value<int> id,
  required String entityId,
  Value<String> operation,
  required String payload,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> status,
  Value<int> attemptCount,
  Value<String?> lastError,
  Value<DateTime?> nextAttemptAt,
});
typedef $$SyncQueueEntriesTableUpdateCompanionBuilder
    = SyncQueueEntriesCompanion Function({
  Value<int> id,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> status,
  Value<int> attemptCount,
  Value<String?> lastError,
  Value<DateTime?> nextAttemptAt,
});

class $$SyncQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabaseDrift, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabaseDrift, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabaseDrift, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);
}

class $$SyncQueueEntriesTableTableManager extends RootTableManager<
    _$AppDatabaseDrift,
    $SyncQueueEntriesTable,
    SyncQueueEntryRow,
    $$SyncQueueEntriesTableFilterComposer,
    $$SyncQueueEntriesTableOrderingComposer,
    $$SyncQueueEntriesTableAnnotationComposer,
    $$SyncQueueEntriesTableCreateCompanionBuilder,
    $$SyncQueueEntriesTableUpdateCompanionBuilder,
    (
      SyncQueueEntryRow,
      BaseReferences<_$AppDatabaseDrift, $SyncQueueEntriesTable,
          SyncQueueEntryRow>
    ),
    SyncQueueEntryRow,
    PrefetchHooks Function()> {
  $$SyncQueueEntriesTableTableManager(
      _$AppDatabaseDrift db, $SyncQueueEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
          }) =>
              SyncQueueEntriesCompanion(
            id: id,
            entityId: entityId,
            operation: operation,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
            attemptCount: attemptCount,
            lastError: lastError,
            nextAttemptAt: nextAttemptAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityId,
            Value<String> operation = const Value.absent(),
            required String payload,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
          }) =>
              SyncQueueEntriesCompanion.insert(
            id: id,
            entityId: entityId,
            operation: operation,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
            attemptCount: attemptCount,
            lastError: lastError,
            nextAttemptAt: nextAttemptAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncQueueEntriesTable, SyncQueueEntryRow>(
                        table),
                    BaseReferences<_$AppDatabaseDrift, $SyncQueueEntriesTable,
                        SyncQueueEntryRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabaseDrift,
    $SyncQueueEntriesTable,
    SyncQueueEntryRow,
    $$SyncQueueEntriesTableFilterComposer,
    $$SyncQueueEntriesTableOrderingComposer,
    $$SyncQueueEntriesTableAnnotationComposer,
    $$SyncQueueEntriesTableCreateCompanionBuilder,
    $$SyncQueueEntriesTableUpdateCompanionBuilder,
    (
      SyncQueueEntryRow,
      BaseReferences<_$AppDatabaseDrift, $SyncQueueEntriesTable,
          SyncQueueEntryRow>
    ),
    SyncQueueEntryRow,
    PrefetchHooks Function()>;
typedef $$ConflictHistoryEntriesTableCreateCompanionBuilder
    = ConflictHistoryEntriesCompanion Function({
  Value<int> id,
  required String transactionId,
  required String localVersionJson,
  required String remoteVersionJson,
  required DateTime detectedAt,
});
typedef $$ConflictHistoryEntriesTableUpdateCompanionBuilder
    = ConflictHistoryEntriesCompanion Function({
  Value<int> id,
  Value<String> transactionId,
  Value<String> localVersionJson,
  Value<String> remoteVersionJson,
  Value<DateTime> detectedAt,
});

class $$ConflictHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabaseDrift, $ConflictHistoryEntriesTable> {
  $$ConflictHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localVersionJson => $composableBuilder(
      column: $table.localVersionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteVersionJson => $composableBuilder(
      column: $table.remoteVersionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => ColumnFilters(column));
}

class $$ConflictHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabaseDrift, $ConflictHistoryEntriesTable> {
  $$ConflictHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localVersionJson => $composableBuilder(
      column: $table.localVersionJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteVersionJson => $composableBuilder(
      column: $table.remoteVersionJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => ColumnOrderings(column));
}

class $$ConflictHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabaseDrift, $ConflictHistoryEntriesTable> {
  $$ConflictHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  GeneratedColumn<String> get localVersionJson => $composableBuilder(
      column: $table.localVersionJson, builder: (column) => column);

  GeneratedColumn<String> get remoteVersionJson => $composableBuilder(
      column: $table.remoteVersionJson, builder: (column) => column);

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
      column: $table.detectedAt, builder: (column) => column);
}

class $$ConflictHistoryEntriesTableTableManager extends RootTableManager<
    _$AppDatabaseDrift,
    $ConflictHistoryEntriesTable,
    ConflictHistoryRow,
    $$ConflictHistoryEntriesTableFilterComposer,
    $$ConflictHistoryEntriesTableOrderingComposer,
    $$ConflictHistoryEntriesTableAnnotationComposer,
    $$ConflictHistoryEntriesTableCreateCompanionBuilder,
    $$ConflictHistoryEntriesTableUpdateCompanionBuilder,
    (
      ConflictHistoryRow,
      BaseReferences<_$AppDatabaseDrift, $ConflictHistoryEntriesTable,
          ConflictHistoryRow>
    ),
    ConflictHistoryRow,
    PrefetchHooks Function()> {
  $$ConflictHistoryEntriesTableTableManager(
      _$AppDatabaseDrift db, $ConflictHistoryEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictHistoryEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictHistoryEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictHistoryEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> transactionId = const Value.absent(),
            Value<String> localVersionJson = const Value.absent(),
            Value<String> remoteVersionJson = const Value.absent(),
            Value<DateTime> detectedAt = const Value.absent(),
          }) =>
              ConflictHistoryEntriesCompanion(
            id: id,
            transactionId: transactionId,
            localVersionJson: localVersionJson,
            remoteVersionJson: remoteVersionJson,
            detectedAt: detectedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String transactionId,
            required String localVersionJson,
            required String remoteVersionJson,
            required DateTime detectedAt,
          }) =>
              ConflictHistoryEntriesCompanion.insert(
            id: id,
            transactionId: transactionId,
            localVersionJson: localVersionJson,
            remoteVersionJson: remoteVersionJson,
            detectedAt: detectedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ConflictHistoryEntriesTable,
                        ConflictHistoryRow>(table),
                    BaseReferences<
                        _$AppDatabaseDrift,
                        $ConflictHistoryEntriesTable,
                        ConflictHistoryRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConflictHistoryEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabaseDrift,
        $ConflictHistoryEntriesTable,
        ConflictHistoryRow,
        $$ConflictHistoryEntriesTableFilterComposer,
        $$ConflictHistoryEntriesTableOrderingComposer,
        $$ConflictHistoryEntriesTableAnnotationComposer,
        $$ConflictHistoryEntriesTableCreateCompanionBuilder,
        $$ConflictHistoryEntriesTableUpdateCompanionBuilder,
        (
          ConflictHistoryRow,
          BaseReferences<_$AppDatabaseDrift, $ConflictHistoryEntriesTable,
              ConflictHistoryRow>
        ),
        ConflictHistoryRow,
        PrefetchHooks Function()>;
typedef $$SyncMetaTableTableCreateCompanionBuilder = SyncMetaTableCompanion
    Function({
  Value<int> id,
  Value<DateTime?> lastPulledAt,
});
typedef $$SyncMetaTableTableUpdateCompanionBuilder = SyncMetaTableCompanion
    Function({
  Value<int> id,
  Value<DateTime?> lastPulledAt,
});

class $$SyncMetaTableTableFilterComposer
    extends Composer<_$AppDatabaseDrift, $SyncMetaTableTable> {
  $$SyncMetaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPulledAt => $composableBuilder(
      column: $table.lastPulledAt, builder: (column) => ColumnFilters(column));
}

class $$SyncMetaTableTableOrderingComposer
    extends Composer<_$AppDatabaseDrift, $SyncMetaTableTable> {
  $$SyncMetaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPulledAt => $composableBuilder(
      column: $table.lastPulledAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncMetaTableTableAnnotationComposer
    extends Composer<_$AppDatabaseDrift, $SyncMetaTableTable> {
  $$SyncMetaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPulledAt => $composableBuilder(
      column: $table.lastPulledAt, builder: (column) => column);
}

class $$SyncMetaTableTableTableManager extends RootTableManager<
    _$AppDatabaseDrift,
    $SyncMetaTableTable,
    SyncMetaRow,
    $$SyncMetaTableTableFilterComposer,
    $$SyncMetaTableTableOrderingComposer,
    $$SyncMetaTableTableAnnotationComposer,
    $$SyncMetaTableTableCreateCompanionBuilder,
    $$SyncMetaTableTableUpdateCompanionBuilder,
    (
      SyncMetaRow,
      BaseReferences<_$AppDatabaseDrift, $SyncMetaTableTable, SyncMetaRow>
    ),
    SyncMetaRow,
    PrefetchHooks Function()> {
  $$SyncMetaTableTableTableManager(
      _$AppDatabaseDrift db, $SyncMetaTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> lastPulledAt = const Value.absent(),
          }) =>
              SyncMetaTableCompanion(
            id: id,
            lastPulledAt: lastPulledAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> lastPulledAt = const Value.absent(),
          }) =>
              SyncMetaTableCompanion.insert(
            id: id,
            lastPulledAt: lastPulledAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncMetaTableTable, SyncMetaRow>(table),
                    BaseReferences<_$AppDatabaseDrift, $SyncMetaTableTable,
                        SyncMetaRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetaTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabaseDrift,
    $SyncMetaTableTable,
    SyncMetaRow,
    $$SyncMetaTableTableFilterComposer,
    $$SyncMetaTableTableOrderingComposer,
    $$SyncMetaTableTableAnnotationComposer,
    $$SyncMetaTableTableCreateCompanionBuilder,
    $$SyncMetaTableTableUpdateCompanionBuilder,
    (
      SyncMetaRow,
      BaseReferences<_$AppDatabaseDrift, $SyncMetaTableTable, SyncMetaRow>
    ),
    SyncMetaRow,
    PrefetchHooks Function()>;

class $AppDatabaseDriftManager {
  final _$AppDatabaseDrift _db;
  $AppDatabaseDriftManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$CategoryRulesTableTableManager get categoryRules =>
      $$CategoryRulesTableTableManager(_db, _db.categoryRules);
  $$SyncQueueEntriesTableTableManager get syncQueueEntries =>
      $$SyncQueueEntriesTableTableManager(_db, _db.syncQueueEntries);
  $$ConflictHistoryEntriesTableTableManager get conflictHistoryEntries =>
      $$ConflictHistoryEntriesTableTableManager(
          _db, _db.conflictHistoryEntries);
  $$SyncMetaTableTableTableManager get syncMetaTable =>
      $$SyncMetaTableTableTableManager(_db, _db.syncMetaTable);
}
