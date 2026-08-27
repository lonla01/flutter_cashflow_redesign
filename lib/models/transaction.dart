import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Opérateur source de la transaction.
enum TransactionSource { orangeMoney, mtnMomo }

/// Type de transaction reconnu par le moteur de parsing.
enum TransactionType {
  transfertEnvoye,
  depotRecu,
  retrait,
  paiementMarchand,
  reception,
  paiementService,
}

/// Statut d'édition d'une transaction : générée automatiquement par le
/// parsing, ou corrigée manuellement par l'utilisateur.
enum EditStatus { auto, editeManuellement }

String sourceToString(TransactionSource s) => switch (s) {
      TransactionSource.orangeMoney => 'orange_money',
      TransactionSource.mtnMomo => 'mtn_momo',
    };

TransactionSource sourceFromString(String s) => switch (s) {
      'orange_money' => TransactionSource.orangeMoney,
      'mtn_momo' => TransactionSource.mtnMomo,
      _ => throw ArgumentError('source inconnue: $s'),
    };

String typeToString(TransactionType t) => switch (t) {
      TransactionType.transfertEnvoye => 'transfert_envoye',
      TransactionType.depotRecu => 'depot_recu',
      TransactionType.retrait => 'retrait',
      TransactionType.paiementMarchand => 'paiement_marchand',
      TransactionType.reception => 'reception',
      TransactionType.paiementService => 'paiement_service',
    };

TransactionType typeFromString(String t) => switch (t) {
      'transfert_envoye' => TransactionType.transfertEnvoye,
      'depot_recu' => TransactionType.depotRecu,
      'retrait' => TransactionType.retrait,
      'paiement_marchand' => TransactionType.paiementMarchand,
      'reception' => TransactionType.reception,
      'paiement_service' => TransactionType.paiementService,
      _ => throw ArgumentError('type inconnu: $t'),
    };

/// Une transaction financière, qu'elle vienne du parsing automatique d'un
/// SMS ou d'une saisie manuelle.
class MoneyTransaction {
  final String id;
  final TransactionSource source;
  final TransactionType type;
  final double montant;
  final double frais;
  final double montantNet;
  final double? soldeApres;
  String? contactNom;
  String? contactNumero;
  String categorie;
  final DateTime dateTransaction;
  final String? idTransactionOperateur;
  final String? smsBrut;
  String notes;
  EditStatus statutEdition;
  DateTime derniereModification;

  MoneyTransaction({
    String? id,
    required this.source,
    required this.type,
    required this.montant,
    this.frais = 0,
    double? montantNet,
    this.soldeApres,
    this.contactNom,
    this.contactNumero,
    this.categorie = 'Autre',
    required this.dateTransaction,
    this.idTransactionOperateur,
    this.smsBrut,
    this.notes = '',
    this.statutEdition = EditStatus.auto,
    DateTime? derniereModification,
  })  : id = id ?? _uuid.v4(),
        montantNet = montantNet ?? (montant + frais),
        derniereModification = derniereModification ?? DateTime.now();

  /// Le signe du montant pour les agrégats : positif si argent reçu,
  /// négatif si argent dépensé/envoyé.
  double get montantSigne {
    switch (type) {
      case TransactionType.depotRecu:
      case TransactionType.reception:
        return montant;
      case TransactionType.transfertEnvoye:
      case TransactionType.retrait:
      case TransactionType.paiementMarchand:
      case TransactionType.paiementService:
        return -montantNet;
    }
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'source': sourceToString(source),
        'type': typeToString(type),
        'montant': montant,
        'frais': frais,
        'montant_net': montantNet,
        'solde_apres': soldeApres,
        'contact_nom': contactNom,
        'contact_numero': contactNumero,
        'categorie': categorie,
        'date_transaction': dateTransaction.toIso8601String(),
        'id_transaction_operateur': idTransactionOperateur,
        'sms_brut': smsBrut,
        'notes': notes,
        'statut_edition': statutEdition == EditStatus.auto ? 'auto' : 'edite_manuellement',
        'derniere_modification': derniereModification.toIso8601String(),
      };

  factory MoneyTransaction.fromMap(Map<String, Object?> map) => MoneyTransaction(
        id: map['id'] as String,
        source: sourceFromString(map['source'] as String),
        type: typeFromString(map['type'] as String),
        montant: (map['montant'] as num).toDouble(),
        frais: (map['frais'] as num?)?.toDouble() ?? 0,
        montantNet: (map['montant_net'] as num?)?.toDouble(),
        soldeApres: (map['solde_apres'] as num?)?.toDouble(),
        contactNom: map['contact_nom'] as String?,
        contactNumero: map['contact_numero'] as String?,
        categorie: map['categorie'] as String? ?? 'Autre',
        dateTransaction: DateTime.parse(map['date_transaction'] as String),
        idTransactionOperateur: map['id_transaction_operateur'] as String?,
        smsBrut: map['sms_brut'] as String?,
        notes: map['notes'] as String? ?? '',
        statutEdition: (map['statut_edition'] as String?) == 'edite_manuellement'
            ? EditStatus.editeManuellement
            : EditStatus.auto,
        derniereModification: DateTime.parse(map['derniere_modification'] as String),
      );
}
