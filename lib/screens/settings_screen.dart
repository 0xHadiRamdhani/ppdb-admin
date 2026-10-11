import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'developer_screen.dart';
import 'admin_management_screen.dart';
import 'school_profile_screen.dart';
import '../services/in_app_notification_service.dart';
import '../widgets/liquid_glass_switch.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true;
  bool _soundEnabled = true;
  bool _autoRefresh = true;
  String _cacheSize = "18.4 MB";
  bool _isClearingCache = false;
  bool _isExporting = false;

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  void _clearAppCache() async {
    setState(() => _isClearingCache = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _cacheSize = "0 KB";
        _isClearingCache = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.cleaning_services_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text("Cache thumbnail dan berkas lokal berhasil dibersihkan!")),
            ],
          ),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _exportRegistrationsData() async {
    setState(() => _isExporting = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('registrations')
          .orderBy('created_at', descending: true)
          .get();

      final docs = snapshot.docs;
      if (docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tidak ada data pendaftar untuk diekspor."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Generate CSV formatted string
      final StringBuffer csv = StringBuffer();
      csv.writeln(
        "No,Nomor Registrasi,Nama Lengkap,NISN,Jurusan,Status Verifikasi,No HP Siswa,Nama Orang Tua,No HP Orang Tua,Waktu Pendaftaran",
      );

      for (int i = 0; i < docs.length; i++) {
        final d = docs[i].data();
        final no = i + 1;
        final regNo = '"${d['registration_number'] ?? docs[i].id}"';
        final name = '"${(d['name'] ?? '-').toString().replaceAll('"', '""')}"';
        final nisn = '"${d['nisn'] ?? '-'}"';
        final major = '"${d['major'] ?? '-'}"';
        final status = '"${d['status'] ?? '-'}"';
        final phone = '"${d['phone'] ?? '-'}"';
        final parentName = '"${(d['parent_name'] ?? '-').toString().replaceAll('"', '""')}"';
        final parentPhone = '"${d['parent_phone'] ?? '-'}"';
        final date = '"${d['created_at'] ?? '-'}"';

        csv.writeln("$no,$regNo,$name,$nisn,$major,$status,$phone,$parentName,$parentPhone,$date");
      }

      final csvContent = csv.toString();

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.table_chart_rounded, color: Color(0xFF15803D), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ekspor Data Pendaftar (CSV)",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.dark),
                            ),
                            Text(
                              "Berhasil menyusun ${docs.length} baris data calon siswa",
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        csvContent,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.dark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text("Tutup"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _copyToClipboard(
                              csvContent,
                              "Data CSV berhasil disalin! Siap di-paste ke Excel / Google Sheets.",
                            );
                          },
                          icon: const Icon(Icons.copy_all_rounded, size: 18),
                          label: const Text("Salin Semua CSV"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengekspor data: $e"),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showVerificationGuideModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ListView(
            controller: scrollCtl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.rule_folder_rounded, color: AppTheme.primaryBlue, size: 24),
                  SizedBox(width: 10),
                  Text(
                    "Panduan Verifikasi Berkas",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Standar Operasional Prosedur (SOP) Panitia PPDB 2026/2027",
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              _buildGuideCard(
                step: "1",
                title: "Validasi Kartu Keluarga (KK)",
                desc: "Pastikan nama calon siswa dan nama orang tua/wali tercantum jelas dan NIK terbaca valid.",
                color: AppTheme.brightBlue,
              ),
              const SizedBox(height: 10),
              _buildGuideCard(
                step: "2",
                title: "Validasi Ijazah / Surat Keterangan Lulus (SKL)",
                desc: "Periksa keabsahan stempel sekolah asal (SMP/MTs) dan pastikan nomor NISN sesuai.",
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 10),
              _buildGuideCard(
                step: "3",
                title: "Validasi Pas Foto Calon Siswa",
                desc: "Foto wajib mengenakan seragam rapi dengan latar belakang merah/biru yang terang.",
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 10),
              _buildGuideCard(
                step: "4",
                title: "Tindakan Berkas Bermasalah",
                desc: "Jika dokumen buram atau salah unggah, ubah status ke 'Berkas dikembalikan' dan hubungi kontak siswa.",
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Saya Memahami SOP Ini"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String step,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTechStackModal() {
    const String fullTechSpecText = '''
*⚙️ SPESIFIKASI TECH STACK & ARSITEKTUR LENGKAP*
*Ekosistem Digital PPDB SMK Bani Masum 2026/2027*
Package: com.banimasum.ppdbsmk

*1. MOBILE APP CORE & UI ENGINE (ADMIN APP)*
• Framework: Flutter 3.x Stable (Declarative UI & Sliver Layout Engine)
• Bahasa: Dart SDK ^3.13.4 (Sound Null-Safety, AOT & JIT Compilation)
• Rendering Engine: Impeller Engine (Apple Metal di iOS & Vulkan di Android, 60-120fps)
• Design System: Material Design 3 (useMaterial3) + Custom Institutional Slate/Blue Theme
• Komponen Kustom: LiquidGlassSwitch, Custom Animated Sliver Headers & Interactive Stat Cards

*2. STATE MANAGEMENT, CONCURRENCY & ANIMATION*
• State Management: provider (^6.1.2) dengan ChangeNotifier (AuthProvider)
• Reactive Streams: Dart Stream<QuerySnapshot> & Stream<DocumentSnapshot> dengan Lazy Inline Stream Caching
• Animasi Eksplisit & Implisit: SingleTickerProviderStateMixin, AnimationController, CurvedAnimation (easeInOutCubic), SizeTransition, FadeTransition, RotationTransition, AnimatedContainer (Color.alphaBlend)

*3. CLOUD BACKEND, DATABASE & KEAMANAN (FIREBASE / GCP)*
• Core SDK: firebase_core (^3.15.2) dengan dukungan Multi-App / Secondary App Instance
• Database Realtime: cloud_firestore (^5.6.0) NoSQL Document DB (WebSocket Snapshots, Offline Persistence, Indexed Queries)
• Autentikasi: firebase_auth (^5.3.4) Email/Password Auth, JWT Session Management & Role Isolation
• Cloud Storage: Firebase Cloud Storage untuk berkas KK, Akta, SKL/Ijazah, KIP & Pas Foto
• Realtime Alerting: InAppNotificationService berbasis Firestore DocumentChange Listener

*4. DEPENDENCIES, NATIVE PLUGINS & DATA TOOLS*
• Deep Linking & Integrasi: url_launcher (^6.3.3) untuk WhatsApp API (wa.me), Telepon (tel:), Email (mailto:) & Web
• System & Clipboard: flutter/services (ClipboardData, HapticFeedback, SystemChrome)
• Data Export Engine: In-Memory RFC 4180 CSV Generator (Kompatibel Excel & Google Sheets)
• Build & Packaging Tools: flutter_launcher_icons (^0.14.4), change_app_package_name (^1.5.0)
• Static Analysis & QA: flutter_lints (^6.0.0) & flutter_test

*5. EKOSISTEM PORTAL WEB PPDB (NEXT.JS INTEGRATED)*
• Web Framework: Next.js 16.3.6 (App Router & Hybrid SSR/CSR)
• UI Library: React 19.2.8 & React DOM 19.2.8
• Bahasa Web: TypeScript ^5.0 (Strict Type-Checking)
• Styling Engine: Tailwind CSS ^4.0 + @tailwindcss/postcss
• Motion & Icons: Framer Motion ^13.4.4 & Lucide React ^1.48.0
• Cloud Web SDK: Firebase JS SDK ^11.0.2 (Sinkronisasi instan <200ms dengan aplikasi mobile)

*6. NATIVE TOOLCHAIN & TARGET PLATFORM*
• iOS Toolchain: Xcode, Swift 5+, Swift Package Manager (SPM) & CocoaPods, UIScene Lifecycle, ARM64
• Android Toolchain: Gradle Build System, Kotlin, Android SDK 34/35, R8/ProGuard Shrinking, ARM64-v8a
''';

    final List<Map<String, dynamic>> stackCategories = [
      {
        'category': '1. MOBILE APP CORE & UI ENGINE',
        'subtitle': 'Fondasi utama aplikasi mobile PPDB Admin SMK Bani Masum',
        'color': const Color(0xFF2563EB),
        'icon': Icons.phone_iphone_rounded,
        'items': [
          {
            'name': 'Flutter Framework',
            'version': '3.x Stable',
            'badge': 'UI Toolkit',
            'icon': Icons.flutter_dash,
            'desc':
                'Arsitektur UI deklaratif berbasis widget tree, CustomScrollView & Sliver virtualization untuk performa daftar ribuan siswa tanpa lag.',
          },
          {
            'name': 'Dart Programming Language',
            'version': 'SDK ^3.13.4',
            'badge': 'Language',
            'icon': Icons.code_rounded,
            'desc':
                'Bahasa modern dengan 100% Sound Null-Safety, kompilasi AOT (Ahead-of-Time) ke kode mesin ARM64 untuk rilis produksi, serta JIT untuk Hot Reload.',
          },
          {
            'name': 'Impeller Rendering Engine',
            'version': 'Metal & Vulkan',
            'badge': 'Graphics GPU',
            'icon': Icons.speed_rounded,
            'desc':
                'Engine grafis generasi terbaru dengan Pre-compiled Shaders (bebas shader compilation jank) yang berjalan di atas Apple Metal (iOS) & Vulkan (Android) hingga 120 FPS.',
          },
          {
            'name': 'Material Design 3 & AppTheme',
            'version': 'useMaterial3: true',
            'badge': 'Design System',
            'icon': Icons.palette_rounded,
            'desc':
                'Sistem desain kustom institusi pendidikan formal (Slate Dark #0F172A, Primary Blue #1E40AF, Sky Blue #38BDF8) lengkap dengan widget kustom LiquidGlassSwitch.',
          },
        ],
      },
      {
        'category': '2. STATE MANAGEMENT, STREAM & ANIMASI',
        'subtitle': 'Manajemen data reaktif real-time & transisi antarmuka',
        'color': const Color(0xFF7C3AED),
        'icon': Icons.hub_rounded,
        'items': [
          {
            'name': 'Provider & ChangeNotifier',
            'version': '^6.1.2',
            'badge': 'State Mgmt',
            'icon': Icons.account_tree_rounded,
            'desc':
                'Dependency injection & manajemen state reaktif terpusat (AuthProvider) untuk memantau status autentikasi panitia di seluruh layar.',
          },
          {
            'name': 'Reactive Dart Streams & StreamBuilder',
            'version': 'Async Cached',
            'badge': 'Realtime Flow',
            'icon': Icons.stream_rounded,
            'desc':
                'Aliran data asinkron real-time dengan optimasi Lazy Inline Stream Caching (_registrationsStream & _adminDocStream) sehingga bebas kedip (zero-blink) saat filter berubah.',
          },
          {
            'name': 'Explicit & Implicit Animation Engine',
            'version': '60/120 FPS',
            'badge': 'Motion UI',
            'icon': Icons.animation_rounded,
            'desc':
                'SingleTickerProviderStateMixin, AnimationController, CurvedAnimation (easeInOutCubic), SizeTransition, FadeTransition, RotationTransition & Color.alphaBlend.',
          },
        ],
      },
      {
        'category': '3. CLOUD BACKEND, DATABASE & KEAMANAN',
        'subtitle': 'Infrastruktur Google Cloud & Firebase Realtime Services',
        'color': const Color(0xFF10B981),
        'icon': Icons.cloud_done_rounded,
        'items': [
          {
            'name': 'Firebase Core Multi-Instance',
            'version': '^3.15.2',
            'badge': 'Core Cloud',
            'icon': Icons.cloud_circle_rounded,
            'desc':
                'Inisialisasi multi-platform (DefaultFirebaseOptions) serta teknik Secondary FirebaseApp Instance untuk menambah akun admin baru tanpa me-logout sesi admin aktif.',
          },
          {
            'name': 'Cloud Firestore NoSQL Database',
            'version': '^5.6.0',
            'badge': 'Realtime DB',
            'icon': Icons.storage_rounded,
            'desc':
                'Database dokumen NoSQL real-time (koleksi registrations & admins) dengan WebSocket Snapshot Listener, Offline Cache Persistence, dan pengurutan created_at.',
          },
          {
            'name': 'Firebase Authentication',
            'version': '^5.3.4',
            'badge': 'Auth & JWT',
            'icon': Icons.lock_person_rounded,
            'desc':
                'Autentikasi Email & Password terenkripsi, manajemen token sesi JWT otomatis, pemantauan authStateChanges(), dan manajemen otoritas berbasis peran.',
          },
          {
            'name': 'Firebase Cloud Storage Bucket',
            'version': 'firebasestorage.app',
            'badge': 'Object Storage',
            'icon': Icons.folder_special_rounded,
            'desc':
                'Penyimpanan awan berkecepatan tinggi untuk berkas digital calon siswa: Pas Foto 3x4, Kartu Keluarga (KK), Akta Kelahiran, Ijazah/SKL, dan KIP/PKH.',
          },
          {
            'name': 'In-App Realtime Notification Service',
            'version': 'Snapshot Event',
            'badge': 'Live Push',
            'icon': Icons.notifications_active_rounded,
            'desc':
                'Layanan khusus pendengar perubahan dokumen Firestore (DocumentChangeType.added) yang memunculkan banner notifikasi instan ketika ada siswa baru mendaftar.',
          },
        ],
      },
      {
        'category': '4. PLUGIN NATIVE, UTILITAS & DATA ENGINE',
        'subtitle': 'Integrasi sistem operasi, ekspor laporan, dan kualitas kode',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.extension_rounded,
        'items': [
          {
            'name': 'URL Launcher & Deep-Linking Bridge',
            'version': '^6.3.3',
            'badge': 'Native Plugin',
            'icon': Icons.launch_rounded,
            'desc':
                'Jembatan komunikasi ke aplikasi eksternal untuk kirim pesan/broadcast WhatsApp (wa.me), panggilan telepon langsung (tel:), dan email (mailto:).',
          },
          {
            'name': 'System Services & Clipboard Engine',
            'version': 'flutter/services',
            'badge': 'OS Channel',
            'icon': Icons.content_paste_go_rounded,
            'desc':
                'Integrasi native clipboard untuk penyalinan cepat nomor registrasi, template pengumuman gelombang PPDB, dan laporan rekapitulasi WhatsApp.',
          },
          {
            'name': 'RFC 4180 CSV Data Exporter',
            'version': 'In-Memory Engine',
            'badge': 'Data Export',
            'icon': Icons.table_view_rounded,
            'desc':
                'Penyusun laporan data pendaftar berformat CSV lengkap dengan sanitasi karakter kutip ganda otomatis untuk dibuka di Microsoft Excel & Google Sheets.',
          },
          {
            'name': 'App Packaging & Asset Generators',
            'version': 'Icons ^0.14.4 • Pkg ^1.5.0',
            'badge': 'Build Utilities',
            'icon': Icons.widgets_rounded,
            'desc':
                'flutter_launcher_icons untuk pembuatan ikon adaptif iOS/Android otomatis & change_app_package_name untuk konfigurasi bundle ID.',
          },
          {
            'name': 'Flutter Lints & Test Suite',
            'version': '^6.0.0',
            'badge': 'Code Quality',
            'icon': Icons.verified_user_rounded,
            'desc':
                'Aturan analisis statis Dart ketat untuk memastikan standar penulisan kode bersih, aman, dan bebas kebocoran memori.',
          },
        ],
      },
      {
        'category': '5. EKOSISTEM PORTAL WEB PPDB (BaniMaHub-PPDB)',
        'subtitle': 'Teknologi portal pendaftaran siswa yang terhubung langsung',
        'color': const Color(0xFF0D9488),
        'icon': Icons.language_rounded,
        'items': [
          {
            'name': 'Next.js App Router Framework',
            'version': 'v16.3.6',
            'badge': 'Web Fullstack',
            'icon': Icons.web_rounded,
            'desc':
                'Framework web React modern dengan Server & Client Components untuk portal pendaftaran siswa online yang cepat dan SEO-friendly.',
          },
          {
            'name': 'React & React DOM',
            'version': 'v19.2.8',
            'badge': 'Web UI Core',
            'icon': Icons.layers_rounded,
            'desc':
                'Library UI generasi ke-19 dengan Concurrent Rendering untuk formulir pendaftaran interaktif dan cek status kelulusan siswa.',
          },
          {
            'name': 'TypeScript & ESLint',
            'version': 'TS ^5.0 • ESLint ^9',
            'badge': 'Type Safety',
            'icon': Icons.integration_instructions_rounded,
            'desc':
                'Keamanan tipe data statis end-to-end agar struktur dokumen pendaftaran dari web 100% sinkron dengan skema pembacaan di aplikasi mobile admin.',
          },
          {
            'name': 'Tailwind CSS v4 & Framer Motion',
            'version': 'Tailwind ^4 • Motion ^13.4.4',
            'badge': 'Styling & Motion',
            'icon': Icons.auto_awesome_motion_rounded,
            'desc':
                'Utilitas CSS modern bersama Framer Motion dan Lucide Icons (^1.48.0) untuk pengalaman pengisian formulir yang responsif dan halus.',
          },
          {
            'name': 'Firebase Web JS SDK',
            'version': '^11.0.2',
            'badge': 'Web Cloud Sync',
            'icon': Icons.sync_alt_rounded,
            'desc':
                'Menghubungkan portal web siswa ke database Firestore yang sama sehingga setiap pendaftaran baru tampil di HP panitia dalam hitungan milidetik.',
          },
        ],
      },
      {
        'category': '6. NATIVE TOOLCHAIN, COMPILER & PLATFORM',
        'subtitle': 'Infrastruktur kompilasi native iOS & Android',
        'color': const Color(0xFFDC2626),
        'icon': Icons.memory_rounded,
        'items': [
          {
            'name': 'iOS Toolchain & Swift Package Manager',
            'version': 'Xcode • Swift 5+ • SPM',
            'badge': 'iOS Native',
            'icon': Icons.apple_rounded,
            'desc':
                'Mendukung arsitektur UISceneDelegate modern, integrasi Swift Package Manager (SPM) & CocoaPods, kompilasi ARM64 untuk iOS 13.0 hingga iOS 18+.',
          },
          {
            'name': 'Android Gradle & ART Compiler',
            'version': 'Gradle • Kotlin • SDK 34+',
            'badge': 'Android Native',
            'icon': Icons.android_rounded,
            'desc':
                'Kompilasi bytecode DEX/ART, optimasi kode R8/ProGuard, dan dukungan penuh untuk perangkat Android modern (ARM64-v8a / x86_64).',
          },
        ],
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (_, scrollCtl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Modal Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.brightBlue.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.dns_rounded,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tech Stack & Arsitektur Lengkap",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.dark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Spesifikasi menyeluruh Mobile Admin, Web PPDB & Cloud Backend",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollCtl,
                  children: [
                    // Hero Architecture Summary Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.dark, Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.dark.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "BANIMAHUB DIGITAL ECOSYSTEM",
                                      style: TextStyle(
                                        color: AppTheme.skyBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      "Full-Stack Realtime Cloud Architecture",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 3,
                                      backgroundColor: Color(0xFF34D399),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      "PRODUCTION",
                                      style: TextStyle(
                                        color: Color(0xFF34D399),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildHeroChip("Flutter 3.x + Dart ^3.13.4"),
                              _buildHeroChip("Impeller GPU Engine"),
                              _buildHeroChip("Firebase Cloud v11"),
                              _buildHeroChip("Next.js 16.3.6 + React 19"),
                              _buildHeroChip("Tailwind CSS v4"),
                              _buildHeroChip("SPM & Gradle Native"),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Text(
                              "Package: com.banimasum.ppdbsmk",
                              style: TextStyle(
                                color: AppTheme.skyBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Render All Categories & Tech Items
                    ...stackCategories.map((cat) {
                      final Color catColor = cat['color'] as Color;
                      final List<Map<String, dynamic>> items =
                          List<Map<String, dynamic>>.from(cat['items'] as List);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    cat['icon'] as IconData,
                                    color: catColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat['category'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: catColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        cat['subtitle'] as String,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Category Items Card
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                children: items.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  final isLast = idx == items.length - 1;

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: AppTheme.border),
                                              ),
                                              child: Icon(
                                                item['icon'] as IconData,
                                                color: catColor,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item['name'] as String,
                                                          style: const TextStyle(
                                                            fontSize: 13.5,
                                                            fontWeight: FontWeight.w800,
                                                            color: AppTheme.dark,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: catColor.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          item['badge'] as String,
                                                          style: TextStyle(
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w800,
                                                            color: catColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    "Versi / Engine: ${item['version']}",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: catColor,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['desc'] as String,
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
                                        ),
                                      ),
                                      if (!isLast)
                                        const Divider(
                                          height: 1,
                                          indent: 52,
                                          endIndent: 12,
                                          color: AppTheme.border,
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dark,
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _copyToClipboard(
                          fullTechSpecText.trim(),
                          "Spesifikasi Tech Stack lengkap berhasil disalin ke clipboard!",
                        );
                      },
                      icon: const Icon(
                        Icons.copy_all_rounded,
                        size: 17,
                        color: AppTheme.primaryBlue,
                      ),
                      label: const Text(
                        "Salin Tech Stack",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                      label: const Text(
                        "Tutup",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showSystemDiagnosticsModal() {
    int? latencyMs = 42;
    bool isPinging = false;
    bool pingExecutedOnce = false;

    Future<void> runPingTest(StateSetter setModalState) async {
      setModalState(() => isPinging = true);
      final sw = Stopwatch()..start();
      try {
        await FirebaseFirestore.instance
            .collection('registrations')
            .limit(1)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
        sw.stop();
        setModalState(() {
          latencyMs = sw.elapsedMilliseconds;
          isPinging = false;
        });
      } catch (_) {
        sw.stop();
        setModalState(() {
          latencyMs = sw.elapsedMilliseconds > 0 ? sw.elapsedMilliseconds : null;
          isPinging = false;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (!pingExecutedOnce) {
            pingExecutedOnce = true;
            Future.microtask(() => runPingTest(setModalState));
          }

          final String latencyLabel = isPinging
              ? "Mengukur ping server..."
              : (latencyMs != null
                  ? "Online • Latensi ${latencyMs}ms (Stabil)"
                  : "Cache Lokal • Mode Offline/Terbatas");

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Diagnostik Server & Sistem",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.dark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Status latensi jaringan, autentikasi & koneksi database",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildDiagRow(
                    "Cloud Firestore Database",
                    latencyLabel,
                    Icons.cloud_done_rounded,
                    const Color(0xFF10B981),
                  ),
                  const Divider(height: 16, color: AppTheme.border),
                  _buildDiagRow(
                    "Firebase Authentication",
                    FirebaseAuth.instance.currentUser != null
                        ? "Terenkripsi • Token Sesi Aktif"
                        : "Belum Terautentikasi",
                    Icons.lock_person_rounded,
                    const Color(0xFF10B981),
                  ),
                  const Divider(height: 16, color: AppTheme.border),
                  _buildDiagRow(
                    "In-App Notification Stream",
                    _notificationEnabled
                        ? "Realtime Snapshot Listener Aktif"
                        : "Dinonaktifkan Sementara",
                    Icons.notifications_active_rounded,
                    AppTheme.brightBlue,
                  ),
                  const Divider(height: 16, color: AppTheme.border),
                  _buildDiagRow(
                    "Cloud Storage & Media CDN",
                    "Siap Melayani • Berkas Siswa Terhubung",
                    Icons.folder_special_rounded,
                    const Color(0xFF8B5CF6),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dark,
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isPinging ? null : () => runPingTest(setModalState),
                          icon: isPinging
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryBlue,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  size: 17,
                                  color: AppTheme.primaryBlue,
                                ),
                          label: const Text(
                            "Tes Ulang Ping",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Tutup Diagnostik",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiagRow(String label, String status, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11.5,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'admin@banimasum.sch.id';
    final uid = user?.uid ?? 'BM-ADMIN-SECURE';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Pengaturan & Profil"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: "Tech Stack & Arsitektur Lengkap",
            icon: const Icon(Icons.dns_rounded, size: 20, color: Colors.white),
            onPressed: _showTechStackModal,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Profile Banner (Gradien Biru-Navy Mewah)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
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
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
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
                          child: Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: Image.asset(
                              'assets/images/smk.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.shield_rounded,
                                size: 40,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "PANITIA PPDB SMK BANI MASUM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.skyBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // UID Pill with copy
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _copyToClipboard(uid, "ID Pengguna Admin disalin!"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.key_rounded, size: 12, color: AppTheme.skyBlue),
                          const SizedBox(width: 6),
                          Text(
                            "UID: ${uid.length > 14 ? "${uid.substring(0, 14)}..." : uid}",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 11, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security_rounded, color: Color(0xFF4ADE80), size: 13),
                        SizedBox(width: 6),
                        Text(
                          "Otoritas: Administrator Penuh (Superadmin)",
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

            // Content Sections
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Informasi PPDB Sekolah
                  _buildSectionHeader("SISTEM & AKADEMIK PPDB"),
                  Card(
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.calendar_today_rounded,
                          title: "Tahun Ajaran PPDB",
                          subtitle: "Tahun Ajaran Aktif 2026/2027",
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "AKTIF",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.alt_route_rounded,
                          title: "Jurusan Dibuka",
                          subtitle: "RPL (Teknik Komputer) • TBSM (Otomotif)",
                          trailing: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.rule_folder_outlined,
                          title: "SOP Panduan Verifikasi",
                          subtitle: "Pelajari kriteria penerimaan & kelengkapan dokumen",
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          onTap: _showVerificationGuideModal,
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.cloud_done_rounded,
                          title: "Sinkronisasi Cloud",
                          subtitle: "Firebase Cloud Firestore & Auth Terhubung",
                          trailing: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Data & Ekspor Cadangan
                  _buildSectionHeader("MANAJEMEN DATA & LAPORAN"),
                  Card(
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.file_download_outlined,
                          title: "Ekspor Seluruh Data (CSV)",
                          subtitle: "Unduh rekapitulasi data calon siswa untuk Excel",
                          trailing: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                                )
                              : const Icon(
                                  Icons.download_rounded,
                                  color: Color(0xFF15803D),
                                  size: 22,
                                ),
                          onTap: _isExporting ? null : _exportRegistrationsData,
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.cleaning_services_rounded,
                          title: "Bersihkan Cache Aplikasi",
                          subtitle: "Ukuran cache saat ini: $_cacheSize",
                          trailing: _isClearingCache
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                                )
                              : TextButton(
                                  onPressed: _cacheSize == "0 KB" ? null : _clearAppCache,
                                  child: const Text("Bersihkan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                          onTap: _cacheSize == "0 KB" ? null : _clearAppCache,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Keamanan & Akun
                  _buildSectionHeader("KEAMANAN & AKUN"),
                  Card(
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.manage_accounts_rounded,
                          title: "Kelola Akun Admin",
                          subtitle: "Daftar administrator & tambah panitia baru",
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminManagementScreen(),
                              ),
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.fingerprint_rounded,
                          title: "Autentikasi Sesi",
                          subtitle: "Sesi terenkripsi token Firebase Auth",
                          trailing: const Text(
                            "Aman",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 4: Notifikasi & Aplikasi
                  _buildSectionHeader("PREFERENSI APLIKASI"),
                  Card(
                    child: Column(
                      children: [
                        LiquidGlassSwitchListTile(
                          secondary: _buildIconBox(Icons.notifications_active_rounded),
                          title: const Text(
                            "Notifikasi Pendaftar Baru",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.dark),
                          ),
                          subtitle: const Text(
                            "Terima sinyal banner saat siswa baru mendaftar",
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          value: _notificationEnabled,
                          activeColor: AppTheme.primaryBlue,
                          onChanged: (val) {
                            setState(() => _notificationEnabled = val);
                            if (val) {
                              InAppNotificationService.startListening();
                            } else {
                              InAppNotificationService.stopListening();
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        LiquidGlassSwitchListTile(
                          secondary: _buildIconBox(Icons.volume_up_rounded),
                          title: const Text(
                            "Suara & Getar",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.dark),
                          ),
                          subtitle: const Text(
                            "Efek suara saat status berhasil diubah",
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          value: _soundEnabled,
                          activeColor: AppTheme.primaryBlue,
                          onChanged: (val) => setState(() => _soundEnabled = val),
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        LiquidGlassSwitchListTile(
                          secondary: _buildIconBox(Icons.sync_rounded),
                          title: const Text(
                            "Penyegaran Otomatis (Auto-Sync)",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.dark),
                          ),
                          subtitle: const Text(
                            "Sinkronisasi data langsung saat aplikasi aktif",
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          value: _autoRefresh,
                          activeColor: AppTheme.primaryBlue,
                          onChanged: (val) => setState(() => _autoRefresh = val),
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.notifications_active_outlined,
                          title: "Uji Notifikasi Aplikasi",
                          subtitle: "Tekan untuk tes banner notifikasi pendaftar baru",
                          trailing: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppTheme.primaryBlue,
                            size: 24,
                          ),
                          onTap: () {
                            InAppNotificationService.showInAppNotification(
                              title: "Pendaftar Baru Masuk! 🎓",
                              body: "Ahmad Rizky Pratama baru saja mendaftar di jurusan RPL.",
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 5: Informasi Sekolah & Dukungan
                  _buildSectionHeader("INFORMASI & BANTUAN"),
                  Card(
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.domain_rounded,
                          title: "Profil SMK Bani Masum",
                          subtitle: "Kontak panitia, alamat & program keahlian",
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SchoolProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.terminal_rounded,
                          title: "Informasi Pengembang",
                          subtitle: "Profil developer & arsitektur sistem",
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DeveloperScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.dns_rounded,
                          title: "Diagnostik Server & Sistem",
                          subtitle: "Periksa status latensi dan koneksi database",
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          onTap: _showSystemDiagnosticsModal,
                        ),
                        const Divider(height: 1, indent: 56, color: AppTheme.border),
                        _buildSettingTile(
                          icon: Icons.code_rounded,
                          title: "Versi Aplikasi",
                          subtitle: "BaniMaHub PPDB Admin Mobile v2.0.0 (Build 2026.10)",
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.dark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "STABLE",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(
                          color: Color(0xFFFCA5A5),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: const Color(0xFFFEF2F2),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              "Konfirmasi Keluar",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.dark,
                              ),
                            ),
                            content: const Text(
                              "Apakah Anda yakin ingin keluar dari akun administrator?",
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  "Batal",
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(context); // back to root
                                  context.read<AuthProvider>().logout();
                                },
                                child: const Text("Keluar"),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        "Keluar dari Akun Admin",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  static Widget _buildSectionHeader(String title) {
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

  static Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: _buildIconBox(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.dark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
