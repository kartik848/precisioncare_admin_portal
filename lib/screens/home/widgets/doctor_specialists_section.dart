import 'package:flutter/material.dart';

class DoctorSpecialistsSection extends StatelessWidget {
  final Function(String category) onSpecialtyTap;

  const DoctorSpecialistsSection({super.key, required this.onSpecialtyTap});

  static final List<Map<String, dynamic>> _doctors = [
    {
      'title': 'Clinical Pathologist',
      'specialty': 'Blood & Lab Tests',
      'badge': 'NABL ACCREDITED',
      'imageAsset': 'assets/images/3d/doc_pathologist.jpg',
      'color': const Color(0xFF0284C7),
      'category': 'Blood Tests',
      'bgGradient': [const Color(0xFFE0F2FE), const Color(0xFFFFFFFF)],
      'borderColor': const Color(0xFFBAE6FD),
    },
    {
      'title': 'Senior Cardiologist',
      'specialty': 'ECG, TMT & Heart',
      'badge': 'INSTANT REPORT',
      'imageAsset': 'assets/images/3d/doc_cardiologist.jpg',
      'color': const Color(0xFFDC2626),
      'category': 'ECG',
      'bgGradient': [const Color(0xFFFEE2E2), const Color(0xFFFFFFFF)],
      'borderColor': const Color(0xFFFECACA),
    },
    {
      'title': 'General Physician',
      'specialty': 'Full Body Prevention',
      'badge': '80+ PARAMETERS',
      'imageAsset': 'assets/images/3d/doctor_mascot.jpg',
      'color': const Color(0xFF0D9488),
      'category': 'Full Body Checkups',
      'bgGradient': [const Color(0xFFCCFBF1), const Color(0xFFFFFFFF)],
      'borderColor': const Color(0xFF99F6E4),
    },
    {
      'title': 'Consultant Radiologist',
      'specialty': 'Digital X-Ray & PFT',
      'badge': 'CHEST & LUNGS',
      'imageAsset': 'assets/images/3d/female_doctor.jpg',
      'color': const Color(0xFF7C3AED),
      'category': 'Digital X-Ray',
      'bgGradient': [const Color(0xFFEDE9FE), const Color(0xFFFFFFFF)],
      'borderColor': const Color(0xFFDDD6FE),
    },
    {
      'title': 'Senior Physiotherapist',
      'specialty': 'Ortho & Rehab Therapy',
      'badge': '1-ON-1 SESSIONS',
      'imageAsset': 'assets/images/3d/call_helpline.jpg',
      'color': const Color(0xFFD97706),
      'category': 'Physiotherapy',
      'bgGradient': [const Color(0xFFFEF3C7), const Color(0xFFFFFFFF)],
      'borderColor': const Color(0xFFFDE68A),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consult Specialists & Lab Doctors',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verified MD Pathologists & Radiologists supervising tests',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _doctors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final doc = _doctors[index];
              return InkWell(
                onTap: () => onSpecialtyTap(doc['category'] as String),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 146,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: doc['bgGradient'] as List<Color>,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: doc['borderColor'] as Color, width: 1.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 3D Cartoon Doctor Avatar
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: (doc['color'] as Color).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            doc['imageAsset'] as String,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            doc['title'] as String,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc['specialty'] as String,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: (doc['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            doc['badge'] as String,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: doc['color'] as Color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
