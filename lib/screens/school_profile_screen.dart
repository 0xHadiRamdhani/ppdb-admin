import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SchoolProfileScreen extends StatelessWidget {
  const SchoolProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Profil SMK Bani Masum"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header Section (Hitam & Biru)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.dark, Color(0xFF1E3A8A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.skyBlue, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.asset(
                          'assets/images/smk.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.school_rounded,
                                size: 40,
                                color: AppTheme.primaryBlue,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "SMK BANI MASUM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Mencetak Generasi Unggul, Berkarakter & Siap Kerja",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.skyBlue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPillTag(
                        Icons.verified_rounded,
                        "Terakreditasi",
                        const Color(0xFF4ADE80),
                      ),
                      const SizedBox(width: 8),
                      _buildPillTag(
                        Icons.domain_rounded,
                        "SMK Pusat Kejuruan",
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Sections
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Program Keahlian / Jurusan
                  _buildSectionTitle("PROGRAM KEAHLIAN UNGGULAN"),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildMajorTile(
                            icon: Icons.computer_rounded,
                            code: "RPL",
                            title: "Rekayasa Perangkat Lunak",
                            desc: "Fokus keahlian pengembangan aplikasi web, mobile app, cloud, dan arsitektur basis data modern.",
                            color: AppTheme.brightBlue,
                          ),
                          const Divider(height: 24, color: AppTheme.border),
                          _buildMajorTile(
                            icon: Icons.two_wheeler_rounded,
                            code: "TBSM",
                            title: "Teknik & Bisnis Sepeda Motor",
                            desc: "Fokus kompetensi mekanikal otomotif roda dua standar industri, kelistrikan kendaraan, dan wirausaha bengkel.",
                            color: const Color(0xFFEA580C),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Visi & Misi
                  _buildSectionTitle("VISI & NILAI PENDIDIKAN"),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Visi Utama",
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.dark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Menjadi lembaga pendidikan kejuruan yang unggul, religius, berwawasan global, dan menghasilkan lulusan berkompetensi tinggi yang siap bersaing di dunia industri.",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Informasi Kontak & Layanan
                  _buildSectionTitle("KONTAK & LAYANAN PPDB"),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildContactRow(
                            icon: Icons.badge_rounded,
                            title: "NPSN Sekolah",
                            value: "69888774",
                          ),
                          const Divider(
                            height: 18,
                            indent: 44,
                            color: AppTheme.border,
                          ),
                          _buildContactRow(
                            icon: Icons.location_on_rounded,
                            title: "Alamat Sekolah",
                            value: "Raya Cimanggu No. 87, Desa Cimanggu, Kecamatan Cisalak, Kabupaten Subang, Jawa Barat",
                          ),
                          const Divider(
                            height: 18,
                            indent: 44,
                            color: AppTheme.border,
                          ),
                          _buildContactRow(
                            icon: Icons.email_rounded,
                            title: "Email Panitia PPDB",
                            value: "smk.banimasum@yahoo.co.id",
                          ),
                          const Divider(
                            height: 18,
                            indent: 44,
                            color: AppTheme.border,
                          ),
                          _buildContactRow(
                            icon: Icons.phone_in_talk_rounded,
                            title: "Telepon Panitia",
                            value: "+62 838-2200-1667",
                          ),
                          const Divider(
                            height: 18,
                            indent: 44,
                            color: AppTheme.border,
                          ),
                          _buildContactRow(
                            icon: Icons.language_rounded,
                            title: "Portal Web Resmi",
                            value: "ppdb-smk-bm.vercel.app",
                          ),
                          const Divider(
                            height: 18,
                            indent: 44,
                            color: AppTheme.border,
                          ),
                          _buildContactRow(
                            icon: Icons.access_time_rounded,
                            title: "Jam Operasional Verifikasi",
                            value: "Senin - Sabtu (08.00 - 15.00 WIB)",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 4: Sarana & Fasilitas
                  _buildSectionTitle("SARANA & PRASARANA SEKOLAH"),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFacilityChip("Lab Komputer Berkipas"),
                          _buildFacilityChip("Bengkel TBSM Standar Industri"),
                          _buildFacilityChip("Jaringan Internet Fiber"),
                          _buildFacilityChip("Perpustakaan Digital"),
                          _buildFacilityChip("Lapangan Olahraga"),
                          _buildFacilityChip("Masjid & Sarana Ibadah"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPillTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static Widget _buildMajorTile({
    required IconData icon,
    required String code,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.dark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildFacilityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.dark,
        ),
      ),
    );
  }
}
