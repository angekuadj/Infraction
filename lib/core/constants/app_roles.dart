enum AppRole { usager, client, agent, admin }

extension AppRoleX on AppRole {
  String get apiValue {
    switch (this) {
      case AppRole.usager:
        return 'proprietaire';
      case AppRole.client:
        return 'user';
      case AppRole.agent:
        return 'agent';
      case AppRole.admin:
        return 'admin';
    }
  }

  String get label {
    switch (this) {
      case AppRole.usager:
        return 'Propriétaire';
      case AppRole.client:
        return 'Usager';
      case AppRole.agent:
        return 'Agent de Police';
      case AppRole.admin:
        return 'Administrateur';
    }
  }

  String get description {
    switch (this) {
      case AppRole.usager:
        return 'Propriétaire (plaque obligatoire)';
      case AppRole.client:
        return 'Usager (téléphone et CNI)';
      case AppRole.agent:
        return 'Agent de police (numéro matricule)';
      case AppRole.admin:
        return 'Administrateur';
    }
  }

  static AppRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'user':
      case 'utilisateur':
      case 'client':
      case 'clientusager':
      case 'client_usager':
        return AppRole.client;
      case 'proprietaire':
      case 'propriétaire':
      case 'owner':
      case 'usager':
      case 'usagerclient':
      case 'usager_client':
        return AppRole.usager;
      case 'agent':
      case 'agent Police':
      case 'agentpolice':
      case 'agent_quipux':
      case 'agentquipux':
        return AppRole.agent;
      case 'admin':
      case 'administrateur':
        return AppRole.admin;
      default:
        return AppRole.client;
    }
  }
}

class AppRoles {
  static const String usager = 'usager';
  static const String client = 'client';
  static const String agent = 'agent';
  static const String admin = 'admin';
  static const String roleNotAllowed = 'ROLE_NOT_ALLOWED';

  static bool isUsager(AppRole role) => role == AppRole.usager;
  static bool isClient(AppRole role) => role == AppRole.client;
  static bool isAgent(AppRole role) => role == AppRole.agent;
  static bool isAdmin(AppRole role) => role == AppRole.admin;
}
