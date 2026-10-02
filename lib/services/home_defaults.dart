import '../models/diagnostic_service.dart';
import '../models/home_collection.dart';
import '../models/lab_section.dart';

/// Ready-made home content built from the live catalog by keyword.
///
/// Shown to patients until the admin creates their own sections, and used as the
/// "Create starter …" seed in the admin panel so the admin starts from a filled home.
class HomeDefaults {
  HomeDefaults._();

  static String _plain(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static List<String> _ids(List<DiagnosticService> catalog, List<String> keywords) {
    final ids = <String>[];
    for (final k in keywords) {
      for (final s in catalog) {
        if (ids.contains(s.id)) continue;
        // Literal match on names only (no synonyms) so sections stay on-topic.
        final hay = _plain([s.title, ...s.includedTests].join(' '));
        if (hay.contains(_plain(k))) ids.add(s.id);
      }
    }
    return ids;
  }

  static LabSubcategory _group(List<DiagnosticService> catalog, String id, String name, List<String> keywords,
      {int? minAge, int? maxAge}) {
    return LabSubcategory(id: id, name: name, minAge: minAge, maxAge: maxAge, testIds: _ids(catalog, keywords));
  }

  static List<LabAudience> audiences(List<DiagnosticService> catalog) {
    LabSubcategory g(String id, String name, List<String> k, {int? min, int? max}) =>
        _group(catalog, id, name, k, minAge: min, maxAge: max);
    return [
      LabAudience(id: 'aud_women', name: 'For Women', gender: 'Female', minAge: 15, sortOrder: 0, subcategories: [
        g('sub_women_adult', 'Adult Women', ['thyroid', 'cbc', 'hba1c', 'full body'], min: 15, max: 45),
        g('sub_women_senior', 'Senior Women', ['full body', 'lipid', 'hba1c', 'thyroid', 'knee'], min: 46),
        g('sub_women_fitness', 'Fitness', ['cbc', 'lipid', 'thyroid']),
      ]),
      LabAudience(id: 'aud_men', name: 'For Men', gender: 'Male', minAge: 15, sortOrder: 1, subcategories: [
        g('sub_men_adult', 'Adult Men', ['full body', 'lipid', 'hba1c', 'cbc'], min: 15, max: 45),
        g('sub_men_senior', 'Senior Men', ['full body', 'ecg', 'lipid', 'hba1c', 'stress'], min: 46),
        g('sub_men_fitness', 'Fitness', ['cbc', 'lipid', 'ecg']),
      ]),
      LabAudience(id: 'aud_children', name: 'For Children', maxAge: 14, sortOrder: 2, subcategories: [
        g('sub_kids_fullbody', 'Full Body Checkup', ['cbc', 'full body']),
        g('sub_kids_growth', 'Growth & Nutrition', ['cbc', 'thyroid']),
        g('sub_kids_allergy', 'Allergy & Infection', ['cbc', 'chest x-ray']),
      ]),
      LabAudience(id: 'aud_seniors', name: 'For Seniors', minAge: 60, sortOrder: 3, subcategories: [
        g('sub_senior_heart', 'Heart Health', ['ecg', 'lipid', 'echocardiography', 'stress']),
        g('sub_senior_diabetes', 'Diabetes Care', ['hba1c', 'glucose']),
        g('sub_senior_bone', 'Bone & Joint', ['knee', 'spine', 'hip']),
      ]),
    ];
  }

  static List<HomeCollection> collections(List<DiagnosticService> catalog) {
    LabSubcategory g(String id, String name, List<String> k) => _group(catalog, id, name, k);
    return [
      HomeCollection(id: 'col_fever', title: 'Checkups & Vaccination for Fever', sortOrder: 0, groups: [
        g('grp_fever', 'Fever', ['fever', 'dengue', 'malaria', 'typhoid', 'widal', 'cbc', 'full body']),
      ]),
      HomeCollection(id: 'col_specialised', title: 'Specialised tests tailored to your health profile',
          subtitle: 'Explore targeted checkups built for individual health concerns',
          layout: HomeCollection.layoutTiles, sortOrder: 1, groups: [
            g('grp_heart', 'Heart Health', ['lipid', 'ecg', 'echocardiography', 'stress']),
            g('grp_diabetes', 'Diabetes', ['hba1c', 'glucose']),
            g('grp_thyroid', 'Thyroid & Hairfall', ['thyroid', 'cbc']),
            g('grp_bone', 'Bone & Joint', ['knee', 'spine', 'hip']),
            g('grp_lung', 'Lung Health', ['pft', 'chest x-ray']),
            g('grp_women', "Women's Health", ['thyroid', 'cbc', 'hba1c']),
          ]),
      HomeCollection(id: 'col_lifestyle', title: 'Packages for lifestyle concerns', sortOrder: 2, groups: [
        g('grp_lifestyle', 'Lifestyle', ['full body', 'lipid', 'hba1c', 'thyroid']),
      ]),
      HomeCollection(id: 'col_athlete', title: 'Athlete health empowerment', sortOrder: 3, groups: [
        g('grp_endurance', 'Endurance tests', ['cbc', 'lipid', 'ecg', 'stress']),
        g('grp_fatigue', 'Fatigue monitoring tests', ['thyroid', 'cbc', 'hba1c', 'vitamin']),
      ]),
      HomeCollection(id: 'col_children', title: "Introducing Children's Health Checkup Range",
          subtitle: 'Packages for growth, nutrition, allergies and more',
          layout: HomeCollection.layoutTiles, sortOrder: 4, groups: [
            g('grp_kids_full', 'Full Body Checkup', ['cbc', 'full body']),
            g('grp_kids_growth', 'Growth & Nutrition', ['cbc', 'thyroid']),
            g('grp_kids_allergy', 'Allergy & Infection', ['cbc', 'chest x-ray']),
          ]),
    ];
  }
}
