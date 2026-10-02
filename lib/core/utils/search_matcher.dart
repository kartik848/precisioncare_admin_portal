/// Forgiving search used across the app (catalog, booking picker, reports, admin).
///
/// - every word of the query must appear somewhere ("thyroid test" finds "Thyroid Profile Test")
/// - punctuation and spacing are ignored ("xray" finds "X-Ray", "t3 t4" finds "T3, T4 & TSH")
/// - common short forms are expanded ("cbc", "sugar", "usg", …)
class SearchMatcher {
  SearchMatcher._();

  static const Map<String, List<String>> _synonyms = {
    'sugar': ['glucose', 'diabetes', 'hba1c'],
    'diabetes': ['glucose', 'hba1c', 'sugar'],
    'cbc': ['complete blood count', 'hemogram'],
    'blood count': ['cbc'],
    'thyroid': ['tsh', 't3', 't4'],
    'tsh': ['thyroid'],
    'cholesterol': ['lipid'],
    'lipid': ['cholesterol'],
    'liver': ['lft', 'sgpt', 'sgot'],
    'lft': ['liver'],
    'kidney': ['kft', 'rft', 'creatinine', 'renal'],
    'kft': ['kidney', 'renal'],
    'xray': ['radiograph'],
    'usg': ['ultrasound', 'sonography'],
    'ultrasound': ['usg', 'sonography'],
    'ecg': ['ekg', 'cardiac', 'heart'],
    'heart': ['cardiac', 'ecg', 'cardio'],
    'lung': ['pft', 'spirometry'],
    'pft': ['lung', 'spirometry'],
    'vitamin d': ['vit d', '25 oh'],
    'vit d': ['vitamin d'],
    'vitamin b12': ['vit b12', 'b12'],
    'b12': ['vitamin b12'],
    'full body': ['fullbody', 'comprehensive', 'master checkup'],
    'physio': ['physiotherapy'],
  };

  /// Generic words that shouldn't have to appear ("thyroid test" should still find "Thyroid Profile").
  static const _stopWords = {'test', 'tests', 'testing', 'checkup', 'check', 'up', 'package', 'packages', 'lab', 'the', 'for', 'of', 'and', 'a', 'my'};

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9₹]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _squash(String s) => s.replaceAll(' ', '');

  static List<String> tokens(String query) => _normalize(query).split(' ').where((t) => t.isNotEmpty).toList();

  /// True when every query word is found in [fields]. An empty query matches everything.
  static bool matches(String query, Iterable<String?> fields) => score(query, fields) > 0;

  /// 0 = no match. Higher is better: exact/prefix hits on the first field (the title) rank first.
  static int score(String query, Iterable<String?> fields) {
    final q = _normalize(query);
    if (q.isEmpty) return 1;
    final list = fields.whereType<String>().map(_normalize).where((f) => f.isNotEmpty).toList();
    if (list.isEmpty) return 0;

    final haystack = list.join(' | ');
    final squashed = _squash(haystack);

    bool found(String token) {
      if (haystack.contains(token) || squashed.contains(_squash(token))) return true;
      for (final alt in _synonyms[token] ?? const <String>[]) {
        if (haystack.contains(alt) || squashed.contains(_squash(alt))) return true;
      }
      return false;
    }

    // Whole phrase first (handles multi-word synonyms like "full body"), then word by word.
    final phraseHit = found(q);
    final all = tokens(q);
    final core = all.where((t) => !_stopWords.contains(t)).toList();
    final required = core.isEmpty ? all : core;
    if (!phraseHit && !required.every(found)) return 0;

    final title = list.first;
    var s = 10;
    if (title == q) {
      s += 100;
    } else if (title.startsWith(q)) {
      s += 60;
    } else if (title.contains(q) || _squash(title).contains(_squash(q))) {
      s += 40;
    } else if (required.every((t) => title.contains(t))) {
      s += 25;
    }
    if (phraseHit) s += 5;
    return s;
  }

  /// Filters [items] by [query] and sorts best matches first (stable for equal scores).
  static List<T> rank<T>(List<T> items, String query, Iterable<String?> Function(T) fieldsOf) {
    if (_normalize(query).isEmpty) return items;
    final scored = <(int, int, T)>[];
    for (var i = 0; i < items.length; i++) {
      final s = score(query, fieldsOf(items[i]));
      if (s > 0) scored.add((s, i, items[i]));
    }
    scored.sort((a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2.compareTo(b.$2));
    return scored.map((e) => e.$3).toList();
  }
}
