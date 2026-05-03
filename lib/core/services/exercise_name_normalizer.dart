/// Normalise le nom d'un exercice pour la comparaison fonctionnelle.
///
/// Règles :
/// - met en minuscules ;
/// - retire les accents ;
/// - réduit les espaces multiples à un seul ;
/// - trim les espaces de début/fin.
class ExerciseNameNormalizer {
  static const Map<String, String> _accentMap = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ñ': 'n', 'ç': 'c',
    'œ': 'oe', 'æ': 'ae',
  };

  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      buffer.write(_accentMap[ch] ?? ch);
    }
    s = buffer.toString();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }
}
