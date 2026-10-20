class InciviType {
  final String id;
  final String nom;
  final String? description;
  final String? category;
  final int? ordre;
  final bool actif;

  const InciviType({
    required this.id,
    required this.nom,
    this.description,
    this.category,
    this.ordre,
    this.actif = true,
  });

  factory InciviType.fromId(String id) => InciviType(
        id: id,
        nom: id.replaceAll('_', ' '),
      );

  factory InciviType.fromJson(Map<String, dynamic> json) {
    return InciviType(
      id: (json['id'] ?? json['_id'] ?? json['code'] ?? '').toString(),
      nom: (json['nom'] ?? json['name'] ?? json['title'] ?? '').toString(),
      description: json['description'] as String?,
      category: (json['category'] ?? json['categorie']) as String?,
      ordre: json['ordre'] as int? ?? json['order'] as int?,
      actif: json['actif'] as bool? ?? json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (ordre != null) 'ordre': ordre,
        'actif': actif,
      };

  InciviType copyWith({
    String? id,
    String? nom,
    String? description,
    String? category,
    int? ordre,
    bool? actif,
  }) {
    return InciviType(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      category: category ?? this.category,
      ordre: ordre ?? this.ordre,
      actif: actif ?? this.actif,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InciviType && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InciviType($id, $nom)';
}

class InciviTypeDefaults {
  static const List<Map<String, String>> all = [
    {
      'id': 'mauvais_stationnement',
      'nom': 'Mauvais stationnement',
      'description':
          'Stationnement devant une sortie, en double file, sur trottoir ou stationnement gênant.',
    },
    {
      'id': 'non_respect_code_route',
      'nom': 'Non-respect du code de la route',
      'description': 'Feux rouges, sens interdits, circulation à contresens.',
    },
    {
      'id': 'non_respect_arrets',
      'nom': 'Non-respect des arrêts',
      'description': 'Arrêts et priorités non respectés.',
    },
    {
      'id': 'conduite_dangereuse',
      'nom': 'Conduite dangereuse',
      'description':
          'Dépassement dangereux, excès de vitesse, conduite sans permis ou sans assurance.',
    },
    {
      'id': 'non_respect vie_commune',
      'nom': 'Non-respect des règles de vie commune',
      'description': 'Tapage, désordre.',
    },
    {
      'id': 'hausse_tarifs',
      'nom': 'Hausse illégale des tarifs',
      'description': 'Refus de payer les impôts, fraude fiscale.',
    },
    {
      'id': 'activites_non_declarees',
      'nom': 'Activités économiques non déclarées',
      'description': 'Activités économiques non déclarées.',
    },
    {
      'id': 'corruption',
      'nom': 'Corruption et pots-de-vin',
      'description': 'Corruption et pots-de-vin.',
    },
    {
      'id': 'pollution',
      'nom': 'Pollution',
      'description':
          'Jets de sachets plastiques, eaux usées, pollution environnementale.',
    },
    {
      'id': 'documents',
      'nom': 'Non-respect des procédures',
      'description':
          'Non-respect des procédures administratives, corruption, falsification de documents.',
    },
  ];
}
