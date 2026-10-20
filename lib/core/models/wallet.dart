class Wallet {
  final String? id;
  final String? userId;
  final double solde;
  final double amount;
  final double balance;
  final List<WalletOperation> operations;
  final DateTime? updatedAt;

  const Wallet({
    this.id,
    this.userId,
    this.solde = 0,
    this.amount = 0,
    this.balance = 0,
    this.operations = const [],
    this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final solde = _d(json['solde'] ?? json['balance'] ?? json['amount']) ?? 0;
    return Wallet(
      id: (json['id'] ?? json['_id'])?.toString(),
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      solde: solde,
      amount: _d(json['amount'] ?? json['solde']) ?? solde,
      balance: _d(json['balance'] ?? json['solde']) ?? solde,
      operations: json['operations'] is List
          ? (json['operations'] as List)
              .whereType<Map<String, dynamic>>()
              .map(WalletOperation.fromJson)
              .toList()
          : json['history'] is List
              ? (json['history'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map(WalletOperation.fromJson)
                  .toList()
              : const [],
      updatedAt: _dt(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (userId != null) 'userId': userId,
        'solde': solde,
        'amount': amount,
        'balance': balance,
        'operations': operations.map((e) => e.toJson()).toList(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  double get soldeDisponible => solde;
  double get montantDu => solde < 0 ? -solde : 0;

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}

class WalletOperation {
  final String? id;
  final String? type;
  final double amount;
  final String? description;
  final String? label;
  final DateTime? date;
  final DateTime? createdAt;

  const WalletOperation({
    this.id,
    this.type,
    this.amount = 0,
    this.description,
    this.label,
    this.date,
    this.createdAt,
  });

  factory WalletOperation.fromJson(Map<String, dynamic> json) {
    return WalletOperation(
      id: (json['id'] ?? json['_id'])?.toString(),
      type: (json['type'] ?? json['operation'])?.toString(),
      amount: _d(json['amount'] ?? json['montant']) ?? 0,
      description: (json['description'] ?? json['label'])?.toString(),
      label: (json['label'] ?? json['description'])?.toString(),
      date: _dt(json['date'] ?? json['createdAt'] ?? json['created_at']),
      createdAt: _dt(json['createdAt'] ?? json['created_at'] ?? json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (type != null) 'type': type,
        'amount': amount,
        if (description != null) 'description': description,
        if (label != null) 'label': label,
        if (date != null) 'date': date!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
