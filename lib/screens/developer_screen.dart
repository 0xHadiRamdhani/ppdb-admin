import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Informasi Pengembang"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Dev Hero Section (Hitam Slate & Biru Elektrik)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.skyBlue, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/developer.jpeg',
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: AppTheme.primaryBlue,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Hadi Ramdhani",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Lead Developer • BaniMaHub Tech",
                    style: TextStyle(
                      color: AppTheme.skyBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.code_rounded,
                          color: Color(0xFF38BDF8),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Mobile & Full-Stack Developer",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF38BDF8),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "NexoraLabStudio Founder",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Ringkasan Proyek
                  _buildSectionTitle("TENTANG PROYEK"),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PPDB SMK Bani Masum Admin Mobile",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Aplikasi manajemen penerimaan peserta didik baru (PPDB) yang terintegrasi langsung secara real-time dengan portal web resmi SMK Bani Masum. Dirancang untuk memudahkan panitia dalam memverifikasi berkas dan mengubah status calon siswa langsung dari perangkat mobile.",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textMuted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppTheme.border),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMiniBadge(
                                "Next.js 16 Ecosystem",
                                AppTheme.dark,
                              ),
                              const SizedBox(width: 8),
                              _buildMiniBadge(
                                "Flutter Material 3",
                                AppTheme.primaryBlue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Tech Stack & Arsitektur
                  _buildSectionTitle("TEKNOLOGI & ARSITEKTUR"),
                  Card(
                    child: Column(
                      children: [
                        _buildTechTile(
                          icon: Icons.flutter_dash,
                          title: "Flutter 3.x & Dart",
                          description: "Framework cross-platform performa tinggi dengan Impeller Engine.",
                          tag: "Frontend",
                        ),
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: AppTheme.border,
                        ),
                        _buildTechTile(
                          icon: Icons.alt_route_rounded,
                          title: "Provider State Management",
                          description: "Manajemen state reaktif untuk sesi autentikasi & antarmuka admin.",
                          tag: "State",
                        ),
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: AppTheme.border,
                        ),
                        _buildTechTile(
                          icon: Icons.local_fire_department_rounded,
                          title: "Firebase Auth & Firestore",
                          description: "Sinkronisasi data real-time, security rules, dan batch commit atomik.",
                          tag: "Cloud DB",
                        ),
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: AppTheme.border,
                        ),
                        _buildTechTile(
                          icon: Icons.palette_outlined,
                          title: "Tema Hitam, Biru & Putih",
                          description: "Palet visual khas institusi pendidikan formal & modern.",
                          tag: "Design",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Informasi Lingkungan Rilis
                  _buildSectionTitle("INFORMASI BUILD & ENVIRONMENT"),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow("Nama Paket", "com.banimasum.ppdbsmk"),
                          const SizedBox(height: 10),
                          _buildInfoRow("Versi Rilis", "v2.0.0 (Build 2026.10)"),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            "Target Platform",
                            "iOS 17+ • Android 14+",
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            "Project Repository",
                            "0xHadiRamdhani/BaniMaHub-PPDB",
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            "Status Rilis",
                            "Produksi Siap Pakai (Stable)",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 4: Kontak & Media Pengembang
                  _buildSectionTitle("HUBUNGI PENGEMBANG"),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: _buildIconBox(Icons.language_rounded),
                          title: const Text(
                            "Website Portofolio",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.dark,
                            ),
                          ),
                          subtitle: const Text(
                            "https://hadiramdhani.site",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppTheme.primaryBlue,
                          ),
                          onTap: () => _launchExternalUrl(
                            context,
                            "https://hadiramdhani.site",
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: AppTheme.border,
                        ),
                        ListTile(
                          leading: _buildIconBox(Icons.code_rounded),
                          title: const Text(
                            "GitHub Repository",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.dark,
                            ),
                          ),
                          subtitle: const Text(
                            "github.com/0xHadiRamdhani",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          onTap: () => _launchExternalUrl(
                            context,
                            "https://github.com/0xHadiRamdhani",
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: AppTheme.border,
                        ),
                        ListTile(
                          leading: _buildIconBox(Icons.email_outlined),
                          title: const Text(
                            "Email Pengembang",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.dark,
                            ),
                          ),
                          subtitle: const Text(
                            "hadsxdev@icloud.com",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          onTap: () => _launchExternalUrl(
                            context,
                            "mailto:hadsxdev@icloud.com",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Technical Engineering Signature & Build Info
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.terminal_rounded, size: 14, color: AppTheme.primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                "ENGINEERED BY BANIMAHUB ARCHITECTURE",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.dark,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "SMK BANI MASUM • PRODUCTION RELEASE CHANNEL",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "BaniMaHub Engine v2.0.0 (Darwin/ARM64) • All Rights Reserved",
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
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

  static Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
    );
  }

  static Widget _buildMiniBadge(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  static Widget _buildTechTile({
    required IconData icon,
    required String title,
    required String description,
    required String tag,
  }) {
    return ListTile(
      leading: _buildIconBox(icon),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.dark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          description,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppTheme.textMuted,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.dark,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: urlString));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Membuka aplikasi/browser gagal. Tautan disalin: $urlString"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.dark,
          ),
        );
      }
    }
  }
}
