class UserModel {
  final String? id;
  final String? userId;
  final String? nom;
  final String? prenom;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? telephone;
  final String? role;
  final String? plaqueImmatriculation;
  final String? numeroImmatriculation;
  final String? matricule;
  final String? agentPolice;
  final String? token;
  final String? accessToken;
  final bool isActive;
  final bool enPanne;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    this.id,
    this.userId,
    this.nom,
    this.prenom,
    this.fullName,
    this.email,
    this.phone,
    this.telephone,
    this.role,
    this.plaqueImmatriculation,
    this.numeroImmatriculation,
    this.matricule,
    this.agentPolice,
    this.token,
    this.accessToken,
    this.isActive = true,
    this.enPanne = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? json['userId'] ?? json['user_id'])
          ?.toString(),
      userId: (json['userId'] ?? json['user_id'] ?? json['id'])?.toString(),
      nom: (json['nom'] ?? json['lastName'] ?? json['last_name'])?.toString(),
      prenom:
          (json['prenom'] ?? json['firstName'] ?? json['first_name'])?.toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'])
          ?.toString(),
      email: json['email']?.toString(),
      phone: (json['phone'] ?? json['telephone'] ?? json['numero'])
          ?.toString(),
      telephone: (json['telephone'] ?? json['phone'])?.toString(),
      role: json['role']?.toString(),
      plaqueImmatriculation: (json['plaqueImmatriculation'] ??
              json['plaque_immatriculation'] ??
              json['plaque'])
          ?.toString(),
      numeroImmatriculation: (json['numeroImmatriculation'] ??
              json['numero_immatriculation'])
          ?.toString(),
      matricule: json['matricule']?.toString(),
      agentPolice:
          (json['agentPolice'] ?? json['agent_police'])?.toString(),
      token: (json['token'] ?? json['accessToken'] ?? json['access_token'])
          ?.toString(),
      accessToken:
          (json['accessToken'] ?? json['access_token'] ?? json['token'])
              ?.toString(),
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? true,
      enPanne: json['enPanne'] as bool? ?? json['en_panne'] as bool? ?? false,
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      updatedAt: _dt(json['updatedAt'] ?? json['updated_at']),
    );
  }

  factory UserModel.fromApiJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final user = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;
    final result = UserModel.fromJson(user);
    final t = (json['token'] ?? data['token'] ?? data['accessToken'])
        ?.toString();
    if (t != null && t.isNotEmpty) {
      return result.copyWith(token: t, accessToken: t);
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (userId != null) 'userId': userId,
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (telephone != null) 'telephone': telephone,
        if (role != null) 'role': role,
        if (plaqueImmatriculation != null)
          'plaqueImmatriculation': plaqueImmatriculation,
        if (numeroImmatriculation != null)
          'numeroImmatriculation': numeroImmatriculation,
        if (matricule != null) 'matricule': matricule,
        if (agentPolice != null) 'agentPolice': agentPolice,
        if (token != null) 'token': token,
        if (accessToken != null) 'accessToken': accessToken,
        'isActive': isActive,
        'enPanne': enPanne,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? userId,
    String? nom,
    String? prenom,
    String? fullName,
    String? email,
    String? phone,
    String? telephone,
    String? role,
    String? plaqueImmatriculation,
    String? numeroImmatriculation,
    String? matricule,
    String? agentPolice,
    String? token,
    String? accessToken,
    bool? isActive,
    bool? enPanne,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      plaqueImmatriculation: plaqueImmatriculation ?? this.plaqueImmatriculation,
      numeroImmatriculation: numeroImmatriculation ?? this.numeroImmatriculation,
      matricule: matricule ?? this.matricule,
      agentPolice: agentPolice ?? this.agentPolice,
      token: token ?? this.token,
      accessToken: accessToken ?? this.accessToken,
      isActive: isActive ?? this.isActive,
      enPanne: enPanne ?? this.enPanne,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final parts = [if (prenom != null) prenom, if (nom != null) nom];
    if (parts.isNotEmpty) return parts.join(' ');
    if (email != null && email!.isNotEmpty) return email!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    return 'Utilisateur';
  }

  bool get hasPlaque =>
      (plaqueImmatriculation?.isNotEmpty ?? false) ||
      (numeroImmatriculation?.isNotEmpty ?? false);

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
