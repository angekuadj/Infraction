class InfractionReport {
  final String? id;
  final String? localId;
  final String? serverId;
  final String? typeId;
  final String? inciviTypeId;
  final String? plaqueImmatriculation;
  final String? numeroImmatriculation;
  final String? description;
  final String? commentaire;
  final String? lieu;
  final double? latitude;
  final double? longitude;
  final String? status;
  final String? statut;
  final String? priority;
  final String? videoPath;
  final String? photoPath;
  final String? plateImagePath;
  final String? thumbnailPath;
  final String? videoUrl;
  final String? imageUrl;
  final String? clientId;
  final String? clientName;
  final String? userId;
  final String? userName;
  final String? agentName;
  final String? agentPolice;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reportedAt;
  final DateTime? sentAt;
  final int? retryCount;
  final bool isPending;
  final bool isQueued;
  final bool isUploading;
  final bool isAnalyzed;
  final String? trimStart;
  final String? trimEnd;
  final double? score;
  final String? panneStart;
  final String? panneEnd;
  final bool enPanne;
  final Map<String, dynamic>? extra;

  const InfractionReport({
    this.id,
    this.localId,
    this.serverId,
    this.typeId,
    this.inciviTypeId,
    this.plaqueImmatriculation,
    this.numeroImmatriculation,
    this.description,
    this.commentaire,
    this.lieu,
    this.latitude,
    this.longitude,
    this.status,
    this.statut,
    this.priority,
    this.videoPath,
    this.photoPath,
    this.plateImagePath,
    this.thumbnailPath,
    this.videoUrl,
    this.imageUrl,
    this.clientId,
    this.clientName,
    this.userId,
    this.userName,
    this.agentName,
    this.agentPolice,
    this.createdAt,
    this.updatedAt,
    this.reportedAt,
    this.sentAt,
    this.retryCount,
    this.isPending = false,
    this.isQueued = false,
    this.isUploading = false,
    this.isAnalyzed = false,
    this.trimStart,
    this.trimEnd,
    this.score,
    this.panneStart,
    this.panneEnd,
    this.enPanne = false,
    this.extra,
  });

  factory InfractionReport.fromJson(Map<String, dynamic> json) {
    return InfractionReport(
      id: _s(json['id'] ?? json['_id']),
      localId: _s(json['localId'] ?? json['local_id']),
      serverId: _s(json['serverId'] ?? json['server_id']),
      typeId: _s(json['typeId'] ?? json['type_id'] ?? json['type']),
      inciviTypeId:
          _s(json['inciviTypeId'] ?? json['incivi_type_id'] ?? json['incivisme']),
      plaqueImmatriculation: _s(json['plaqueImmatriculation'] ??
          json['plaque_immatriculation'] ??
          json['plaque']),
      numeroImmatriculation: _s(
          json['numeroImmatriculation'] ?? json['numero_immatriculation']),
      description: _s(json['description']),
      commentaire: _s(json['commentaire'] ?? json['comment']),
      lieu: _s(json['lieu'] ?? json['address'] ?? json['adresse']),
      latitude: _d(json['latitude']),
      longitude: _d(json['longitude']),
      status: _s(json['status'] ?? json['statut']),
      statut: _s(json['statut'] ?? json['status']),
      priority: _s(json['priority'] ?? json['priorite']),
      videoPath: _s(json['videoPath'] ?? json['video_path']),
      photoPath: _s(json['photoPath'] ?? json['photo_path']),
      plateImagePath:
          _s(json['plateImagePath'] ?? json['plate_image_path']),
      thumbnailPath:
          _s(json['thumbnailPath'] ?? json['thumbnail_path'] ?? json['thumbnail']),
      videoUrl: _s(json['videoUrl'] ?? json['video_url'] ?? json['video']),
      imageUrl: _s(json['imageUrl'] ?? json['image_url'] ?? json['image']),
      clientId: _s(json['clientId'] ?? json['client_id']),
      clientName: _s(json['clientName'] ?? json['client_name']),
      userId: _s(json['userId'] ?? json['user_id']),
      userName: _s(json['userName'] ?? json['user_name']),
      agentName: _s(json['agentName'] ?? json['agent_name']),
      agentPolice: _s(json['agentPolice'] ?? json['agent_police']),
      createdAt: _dt(json['createdAt'] ?? json['created_at'] ?? json['date']),
      updatedAt: _dt(json['updatedAt'] ?? json['updated_at']),
      reportedAt: _dt(json['reportedAt'] ?? json['reported_at']),
      sentAt: _dt(json['sentAt'] ?? json['sent_at']),
      retryCount: _i(json['retryCount'] ?? json['retry_count']),
      isPending: json['isPending'] as bool? ?? false,
      isQueued: json['isQueued'] as bool? ?? false,
      isUploading: json['isUploading'] as bool? ?? false,
      isAnalyzed: json['isAnalyzed'] as bool? ?? false,
      trimStart: _s(json['trimStart'] ?? json['trim_start']),
      trimEnd: _s(json['trimEnd'] ?? json['trim_end']),
      score: _d(json['score'] ?? json['confidence']),
      panneStart: _s(json['panneStart'] ?? json['panne_start']),
      panneEnd: _s(json['panneEnd'] ?? json['panne_end']),
      enPanne: json['enPanne'] as bool? ?? json['en_panne'] as bool? ?? false,
      extra: json['extra'] is Map<String, dynamic>
          ? json['extra'] as Map<String, dynamic>
          : null,
    );
  }

  factory InfractionReport.fromApiJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return InfractionReport.fromJson(data);
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (localId != null) 'localId': localId,
        if (serverId != null) 'serverId': serverId,
        if (typeId != null) 'typeId': typeId,
        if (inciviTypeId != null) 'inciviTypeId': inciviTypeId,
        if (plaqueImmatriculation != null)
          'plaqueImmatriculation': plaqueImmatriculation,
        if (numeroImmatriculation != null)
          'numeroImmatriculation': numeroImmatriculation,
        if (description != null) 'description': description,
        if (commentaire != null) 'commentaire': commentaire,
        if (lieu != null) 'lieu': lieu,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (status != null) 'status': status,
        if (statut != null) 'statut': statut,
        if (priority != null) 'priority': priority,
        if (videoPath != null) 'videoPath': videoPath,
        if (photoPath != null) 'photoPath': photoPath,
        if (plateImagePath != null) 'plateImagePath': plateImagePath,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (clientId != null) 'clientId': clientId,
        if (clientName != null) 'clientName': clientName,
        if (userId != null) 'userId': userId,
        if (userName != null) 'userName': userName,
        if (agentName != null) 'agentName': agentName,
        if (agentPolice != null) 'agentPolice': agentPolice,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (reportedAt != null) 'reportedAt': reportedAt!.toIso8601String(),
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
        if (retryCount != null) 'retryCount': retryCount,
        'isPending': isPending,
        'isQueued': isQueued,
        'isUploading': isUploading,
        'isAnalyzed': isAnalyzed,
        if (trimStart != null) 'trimStart': trimStart,
        if (trimEnd != null) 'trimEnd': trimEnd,
        if (score != null) 'score': score,
        if (panneStart != null) 'panneStart': panneStart,
        if (panneEnd != null) 'panneEnd': panneEnd,
        'enPanne': enPanne,
        if (extra != null) 'extra': extra,
      };

  InfractionReport copyWith({
    String? id,
    String? localId,
    String? serverId,
    String? typeId,
    String? inciviTypeId,
    String? plaqueImmatriculation,
    String? numeroImmatriculation,
    String? description,
    String? commentaire,
    String? lieu,
    double? latitude,
    double? longitude,
    String? status,
    String? statut,
    String? priority,
    String? videoPath,
    String? photoPath,
    String? plateImagePath,
    String? thumbnailPath,
    String? videoUrl,
    String? imageUrl,
    String? clientId,
    String? clientName,
    String? userId,
    String? userName,
    String? agentName,
    String? agentPolice,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reportedAt,
    DateTime? sentAt,
    int? retryCount,
    bool? isPending,
    bool? isQueued,
    bool? isUploading,
    bool? isAnalyzed,
    String? trimStart,
    String? trimEnd,
    double? score,
    String? panneStart,
    String? panneEnd,
    bool? enPanne,
    Map<String, dynamic>? extra,
  }) {
    return InfractionReport(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      typeId: typeId ?? this.typeId,
      inciviTypeId: inciviTypeId ?? this.inciviTypeId,
      plaqueImmatriculation:
          plaqueImmatriculation ?? this.plaqueImmatriculation,
      numeroImmatriculation: numeroImmatriculation ?? this.numeroImmatriculation,
      description: description ?? this.description,
      commentaire: commentaire ?? this.commentaire,
      lieu: lieu ?? this.lieu,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      statut: statut ?? this.statut,
      priority: priority ?? this.priority,
      videoPath: videoPath ?? this.videoPath,
      photoPath: photoPath ?? this.photoPath,
      plateImagePath: plateImagePath ?? this.plateImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      agentName: agentName ?? this.agentName,
      agentPolice: agentPolice ?? this.agentPolice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reportedAt: reportedAt ?? this.reportedAt,
      sentAt: sentAt ?? this.sentAt,
      retryCount: retryCount ?? this.retryCount,
      isPending: isPending ?? this.isPending,
      isQueued: isQueued ?? this.isQueued,
      isUploading: isUploading ?? this.isUploading,
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      score: score ?? this.score,
      panneStart: panneStart ?? this.panneStart,
      panneEnd: panneEnd ?? this.panneEnd,
      enPanne: enPanne ?? this.enPanne,
      extra: extra ?? this.extra,
    );
  }

  bool get isEnAttente =>
      (status ?? statut)?.toLowerCase() == 'pending' ||
      (status ?? statut)?.toLowerCase() == 'en_attente' ||
      isPending;
  bool get isTraitee =>
      (status ?? statut)?.toLowerCase() == 'processed' ||
      (status ?? statut)?.toLowerCase() == 'traitee' ||
      (status ?? statut)?.toLowerCase() == 'traitée';
  bool get isRejetee =>
      (status ?? statut)?.toLowerCase() == 'rejected' ||
      (status ?? statut)?.toLowerCase() == 'rejetee';
  bool get isAcceptee =>
      (status ?? statut)?.toLowerCase() == 'accepted' ||
      (status ?? statut)?.toLowerCase() == 'acceptee';

  static String? _s(dynamic v) => v?.toString();
  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
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
