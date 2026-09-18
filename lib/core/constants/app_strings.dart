class AppStrings {
  static const String appName = 'PrecisionCare Diagnostic Centre';
  static const String appTagline = 'Accurate Diagnostics, Compassionate Care';
  static const String labAccreditation = 'NABL & ICMR Approved Quality Diagnostics';
  static const String helplineNumber = '+91 92709 88595';
  static const String emergencySupport = '24/7 Diagnostics & Home Sample Collection';

  // Pune Centre Branches
  static const String branch1Address = 'Opposite Fakhri Hills Lullanagar, Chowk, Kondhwa, Pune, Maharashtra 411040';
  static const String branch2Address = 'Parmar Pavan, Maharashtra, Fakhri Hills, Kondhwa, Fullnagar, Pune, Maharashtra 411048';
  static const String centreAddress = '$branch1Address\n\nBranch 2: $branch2Address';

  static const List<String> centreBranches = [
    'Opposite Fakhri Hills Lullanagar, Chowk, Kondhwa, Pune, Maharashtra 411040',
    'Parmar Pavan, Maharashtra, Fakhri Hills, Kondhwa, Fullnagar, Pune, Maharashtra 411048',
  ];

  // Auth Strings
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to schedule tests & access your medical reports';
  static const String registerTitle = 'Create Patient Account';
  static const String registerSubtitle = 'Fill in your personal health profile to get started';
  
  // Home Visit Categories
  static const String homeBloodTest = 'Home Visit Blood Test';
  static const String homeXRay = 'Home Visit Digital X-Ray';
  static const String homeECG = 'Home Visit 12-Lead ECG';
  static const String homePhysio = 'Home Visit Physiotherapy';

  // In-House Diagnostic Tests
  static const String inHousePFT = 'In-House PFT Test (Spirometry)';
  static const String inHouseStressTest = 'Cardiac Stress Test (TMT)';
  static const String inHousePhysioSetup = 'Complete Physiotherapy Setup';

  // Common Sections
  static const String popularServices = 'Popular Diagnostics & Home Services';
  static const String whyChooseUs = 'Why PrecisionCare Diagnostic Centre?';
  static const String trackYourSample = 'Track Sample & Visits';
  static const String downloadReports = 'Download & View Diagnostic Reports';
  static const String nextTestReminders = 'Personalized Health & Test Reminders';
}
