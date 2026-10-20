/// Règles et format des plaques d'immatriculation de Côte d'Ivoire.
///
/// Formats courants :
/// - Ancien : 1 lettre + 3-4 chiffres (ex: A1234, AB123)
/// - Nouveau : 2-3 lettres + 3-4 chiffres + 1-2 lettres (ex: AB123CD, ABC1234D)
/// - Diplomates / services spéciaux possibles
class CoteIvoirePlate {
  static final RegExp plateRegex = RegExp(
    r'^[A-Z]{1,3}[-\s]?[0-9]{3,4}[-\s]?[A-Z]{0,2}$',
    caseSensitive: false,
  );

  static final RegExp plateStrictRegex = RegExp(
    r'^[A-Z]{1,3}[0-9]{3,4}[A-Z]{0,2}$',
    caseSensitive: false,
  );

  static final RegExp alphanumericOnly = RegExp(r'[^A-Z0-9]', caseSensitive: false);

  /// Nettoie une plaque : majuscules, supprime espaces/tirets.
  static String normalize(String raw) {
    return raw.toUpperCase().replaceAll(alphanumericOnly, '');
  }

  /// Valide le format d'une plaque ivoirienne.
  static bool isValid(String raw) {
    final cleaned = normalize(raw);
    if (cleaned.length < 5 || cleaned.length > 9) return false;
    return plateStrictRegex.hasMatch(cleaned);
  }

  /// Valide avec une longueur minimale (ex: "Plaque trop courte").
  static String? validate(String raw) {
    final cleaned = normalize(raw);
    if (cleaned.isEmpty) return 'La plaque est requise';
    if (cleaned.length < 5) return 'Plaque trop courte';
    if (!plateStrictRegex.hasMatch(cleaned)) {
      return 'Format de plaque invalide';
    }
    return null;
  }

  /// Formate pour l'affichage : AAAA-1234 si possible.
  static String format(String raw) {
    final cleaned = normalize(raw);
    final match = RegExp(r'^([A-Z]{1,3})([0-9]{3,4})([A-Z]{0,2})$')
        .firstMatch(cleaned);
    if (match == null) return cleaned;
    final letters1 = match.group(1)!;
    final digits = match.group(2)!;
    final letters2 = match.group(3) ?? '';
    if (letters2.isEmpty) return '$letters1-$digits';
    return '$letters1-$digits-$letters2';
  }

  /// Extrait les lettres et chiffres séparément.
  static ({String letters, String digits}) split(String raw) {
    final cleaned = normalize(raw);
    final letters = RegExp(r'[A-Z]+').allMatches(cleaned).map((m) => m.group(0)).join();
    final digits = RegExp(r'[0-9]+').allMatches(cleaned).map((m) => m.group(0)).join();
    return (letters: letters, digits: digits);
  }

  /// Confusions OCR fréquentes entre lettres et chiffres selon leur position.
  static const Map<String, String> _toDigit = {
    'O': '0', 'Q': '0', 'D': '0',
    'I': '1', 'L': '1', 'T': '7',
    'Z': '2', 'S': '5', 'B': '8', 'G': '6',
  };
  static const Map<String, String> _toLetter = {
    '0': 'O', '1': 'I', '2': 'Z', '5': 'S',
    '8': 'B', '6': 'G', '4': 'A', '7': 'T',
  };

  /// Corrige une chaîne pour qu'elle respecte le motif
  /// lettres (1-3) + chiffres (3-4) + lettres (0-2).
  /// Ex: "A81234" -> "AB1234", "0O1234" -> "0011234"->... ->plaque.
  static String correctOcr(String raw) {
    final cleaned = normalize(raw);
    if (cleaned.isEmpty) return cleaned;
    final chars = cleaned.split('');

    // Repère la plus longue suite de chiffres (la partie numérique).
    var bestStart = -1;
    var bestLen = 0;
    var runStart = -1;
    for (var i = 0; i <= chars.length; i++) {
      final isDigit = i < chars.length &&
          RegExp(r'[0-9]').hasMatch(chars[i]);
      if (isDigit) {
        if (runStart < 0) runStart = i;
      } else if (runStart >= 0) {
        final len = i - runStart;
        if (len > bestLen) {
          bestLen = len;
          bestStart = runStart;
        }
        runStart = -1;
      }
    }

    if (bestStart < 0) {
      // Aucune suite de chiffres : tout convertir en chiffres.
      return chars.map((c) => _toDigit[c] ?? c).join();
    }

    final digitEnd = bestStart + bestLen - 1;
    for (var i = 0; i < chars.length; i++) {
      final isDigitPos = i >= bestStart && i <= digitEnd;
      chars[i] = isDigitPos
          ? (_toDigit[chars[i]] ?? chars[i])
          : (_toLetter[chars[i]] ?? chars[i]);
    }
    return chars.join();
  }

  /// Génère des candidats valides à partir d'un mot OCR brut, en testant
  /// d'abord la chaîne brute puis une version corrigée.
  static List<String> candidates(String raw) {
    final results = <String>[];
    void add(String value) {
      final normalized = normalize(value);
      if (isValid(normalized) && !results.contains(normalized)) {
        results.add(normalized);
      }
    }

    add(raw);
    final cleaned = normalize(raw);
    add(correctOcr(cleaned));
    // Variantes : suppression d'un caractère parasite en tête/queue.
    if (cleaned.length > 6) {
      add(cleaned.substring(1));
      add(cleaned.substring(0, cleaned.length - 1));
    }
    return results;
  }
}
