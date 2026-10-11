import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final Stream<QuerySnapshot> _registrationsStream = FirebaseFirestore
      .instance
      .collection('registrations')
      .orderBy('created_at', descending: true)
      .snapshots();
  late final AnimationController _quotaAnimController;
  late final Animation<double> _quotaExpandAnimation;
  late final Animation<double> _quotaRotateAnimation;

  String _searchQuery = '';
  String _selectedStatusFilter = 'Semua';
  String _selectedMajorFilter = 'Semua';
  String _sortBy = 'newest'; // newest, oldest, name_asc, name_desc
  bool _showBackToTop = false;
  bool _isStatsExpanded = true;

  // Target kuota penerimaan siswa baru
  final int _targetQuota = 200;

  final List<String> _statusFilters = [
    'Semua',
    'Menunggu verifikasi',
    'Lulus verifikasi',
    'Berkas bermasalah',
  ];

  final List<String> _majorFilters = [
    'Semua',
    'RPL',
    'TBSM',
  ];

  @override
  void initState() {
    super.initState();
    _quotaAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _quotaExpandAnimation = CurvedAnimation(
      parent: _quotaAnimController,
      curve: Curves.easeInOutCubic,
    );
    _quotaRotateAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _quotaAnimController,
        curve: Curves.easeInOutCubic,
      ),
    );
    if (_isStatsExpanded) {
      _quotaAnimController.value = 1.0;
    }

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController.offset <= 300 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _quotaAnimController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleQuotaExpanded() {
    _isStatsExpanded = !_isStatsExpanded;
    if (_isStatsExpanded) {
      _quotaAnimController.forward();
    } else {
      _quotaAnimController.reverse();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStatusFilter = 'Semua';
      _selectedMajorFilter = 'Semua';
      _sortBy = 'newest';
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _adminDocStream;
  String? _adminStreamUid;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _getAdminDocStream(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    if (_adminStreamUid != uid || _adminDocStream == null) {
      _adminStreamUid = uid;
      _adminDocStream = FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .snapshots();
    }
    return _adminDocStream;
  }

  String _formatEmailPrefix(String? email) {
    if (email == null || email.trim().isEmpty) return 'Admin';
    final prefix = email.split('@').first.trim();
    if (prefix.isEmpty) return 'Admin';
    final words = prefix
        .split(RegExp(r'[._\-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .toList();
    return words.isEmpty ? 'Admin' : words.join(' ');
  }

  String _resolveAdminName({
    required String? firestoreName,
    required String? displayName,
    required String? email,
  }) {
    final cleanFirestore = firestoreName?.trim() ?? '';
    if (cleanFirestore.isNotEmpty &&
        cleanFirestore != 'Administrator Utama' &&
        cleanFirestore != 'Panitia PPDB') {
      return cleanFirestore;
    }
    final cleanDisplay = displayName?.trim() ?? '';
    if (cleanDisplay.isNotEmpty) {
      return cleanDisplay;
    }
    final emailName = _formatEmailPrefix(email);
    if (emailName.toLowerCase() != 'admin') {
      return emailName;
    }
    if (cleanFirestore.isNotEmpty) {
      return cleanFirestore;
    }
    return emailName;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '-';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year • $hour:$minute';
    } catch (_) {
      return dateVal.toString();
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.dark, size: 22),
            SizedBox(width: 8),
            Text(
              "Konfirmasi Keluar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari portal admin PPDB?",
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
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

  void _copyWhatsAppReport({
    required int total,
    required int pending,
    required int approved,
    required int problematic,
    required int rplTotal,
    required int rplApproved,
    required int tbsmTotal,
    required int tbsmApproved,
    required int pendingDocs,
  }) {
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    final passRate = total > 0 ? ((approved / total) * 100).toStringAsFixed(1) : '0';
    final quotaPercent = ((approved / _targetQuota) * 100).toStringAsFixed(1);

    final report = '''
*📊 LAPORAN REKAPITULASI PPDB SMK BANI MASUM*
*Tahun Ajaran 2026/2027*
Per Tanggal: $dateStr

*📈 Ringkasan Pendaftaran:*
• Total Pendaftar: $total Calon Siswa
• Menunggu Verifikasi: $pending
• Lulus Verifikasi: $approved ($passRate%)
• Berkas Bermasalah: $problematic
• Kuota Terisi: $approved / $_targetQuota ($quotaPercent%)

*🎓 Distribusi Per Jurusan:*
• *RPL (Teknik Komputer):*
  - Total: $rplTotal siswa
  - Lulus: $rplApproved siswa
• *TBSM (Teknik Otomotif):*
  - Total: $tbsmTotal siswa
  - Lulus: $tbsmApproved siswa

*📁 Status Kelengkapan Dokumen:*
• Berkas Lengkap: ${total - pendingDocs}
• Dokumen Belum Lengkap: $pendingDocs

_Laporan otomatis dibuat melalui Aplikasi PPDB Admin SMK Bani Masum._
'''.trim();

    _copyToClipboard(report, "Rekapitulasi disalin! Siap dibagikan ke WhatsApp Panitia.");
  }

  Future<void> _shareToWhatsApp(String text) async {
    final url = "https://wa.me/?text=${Uri.encodeComponent(text)}";
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _copyToClipboard(text, "Gagal membuka WhatsApp. Format telah disalin ke clipboard!");
      }
    } catch (e) {
      if (mounted) {
        _copyToClipboard(text, "Format disalin ke clipboard!");
      }
    }
  }

  void _showScheduleAndWavesModal({
    required int approvedCount,
    required int targetQuota,
  }) {
    const wave1Target = 120;
    final wave1Filled = approvedCount.clamp(0, wave1Target);
    final wave1Percent = ((wave1Filled / wave1Target) * 100).toStringAsFixed(1);

    final scheduleText = '''
*📅 JADWAL & AGENDA PPDB SMK BANI MASUM 2026/2027*
_NPSN: 69888774 • Terakreditasi_

*🟢 GELOMBANG 1 (Reguler & Prestasi):*
1. Pendaftaran Online: 1 Mei – 30 Juli 2026
2. Verifikasi Berkas: Setiap Hari Kerja (08.00–14.00 WIB)
3. Tes Minat Bakat (RPL/TBSM): 1 – 3 Agustus 2026
4. Pengumuman Kelulusan: 5 Agustus 2026
5. Daftar Ulang & Seragam: 6 – 12 Agustus 2026

*⏳ GELOMBANG 2 (Pemenuhan Kuota):*
• Periode: 1 – 25 Agustus 2026
• Alokasi: 80 Siswa

*🚩 AWAL TAHUN AJARAN:*
• Pra-MPLS & MPLS: 15 – 17 Agustus 2026
• Hari Pertama Masuk: 18 Agustus 2026

Sekretariat PPDB SMK Bani Masum
Hotline: 0812-3456-7890
Website: https://hadiramdhani.site
'''.trim();

    final timelineItems = [
      {
        'title': 'Pendaftaran Online & Berkas',
        'date': '1 Mei – 30 Juli 2026',
        'desc': 'Pengisian formulir dan unggah dokumen persyaratan calon siswa.',
        'status': 'Aktif',
        'color': const Color(0xFF10B981),
        'icon': Icons.app_registration_rounded,
      },
      {
        'title': 'Verifikasi Berkas Administrasi',
        'date': 'Setiap Hari Kerja (08.00–14.00)',
        'desc': 'Pengecekan keabsahan ijazah, rapor, KK, dan pas foto oleh panitia.',
        'status': 'Aktif',
        'color': const Color(0xFF2563EB),
        'icon': Icons.fact_check_rounded,
      },
      {
        'title': 'Tes Minat Bakat & Wawancara',
        'date': '1 – 3 Agustus 2026',
        'desc': 'Uji kompetensi dasar peminatan jurusan RPL dan TBSM di kampus sekolah.',
        'status': 'Mendatang',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.psychology_rounded,
      },
      {
        'title': 'Rapat Pleno & Pengumuman Hasil',
        'date': '5 Agustus 2026',
        'desc': 'Penetapan kelulusan resmi dan publikasi hasil seleksi di portal PPDB.',
        'status': 'Mendatang',
        'color': const Color(0xFF7C3AED),
        'icon': Icons.campaign_rounded,
      },
      {
        'title': 'Daftar Ulang & Ukur Seragam',
        'date': '6 – 12 Agustus 2026',
        'desc': 'Penyerahan berkas fisik, pengukuran seragam sekolah, dan administrasi.',
        'status': 'Mendatang',
        'color': const Color(0xFF0D9488),
        'icon': Icons.checkroom_rounded,
      },
      {
        'title': 'Masa Pengenalan Lingkungan Sekolah',
        'date': '15 – 17 Agustus 2026',
        'desc': 'Pengenalan budaya sekolah, guru pengajar, bengkel dan laboratorium.',
        'status': 'Mendatang',
        'color': const Color(0xFFDC2626),
        'icon': Icons.school_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtl) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppTheme.primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Jadwal & Gelombang PPDB",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.dark,
                              ),
                            ),
                            Text(
                              "Timeline resmi penerimaan siswa baru SMK Bani Masum",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Active Wave Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.dark, AppTheme.darkSecondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.dark.withValues(alpha: 0.2),
                          blurRadius: 10,
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
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "GELOMBANG 1",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                "SEDANG AKTIF",
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Jalur Reguler & Prestasi Akademik/Non-Akademik",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Countdown Box inside Wave Card
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.alarm_on_rounded, color: Color(0xFFFBBF24), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Batas Penutupan Gelombang 1",
                                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5),
                                    ),
                                    Text(
                                      "30 Juli 2026 (Sisa 14 Hari Lagi)",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (wave1Filled / wave1Target).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Terisi $wave1Filled dari $wave1Target Siswa",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                            Text(
                              "$wave1Percent%",
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section Title: Alur & Tahapan PPDB
                  const Text(
                    "Alur & Tahapan PPDB 2026/2027",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Timeline Items
                  ...timelineItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isLast = idx == timelineItems.length - 1;
                    final color = item['color'] as Color;
                    final status = item['status'] as String;
                    final isActive = status == 'Aktif';

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Timeline indicator
                          Column(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color, width: 1.5),
                                ),
                                child: Icon(item['icon'] as IconData, size: 15, color: color),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppTheme.border,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Right Content
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isActive ? color.withValues(alpha: 0.05) : AppTheme.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive ? color.withValues(alpha: 0.3) : AppTheme.border,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] as String,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.dark,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 11, color: color),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['date'] as String,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['desc'] as String,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Gelombang 2 Preview Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Icon(Icons.next_plan_rounded, color: AppTheme.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Gelombang 2 (Pemenuhan Kuota)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.dark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Periode: 1 – 25 Agustus 2026 • Kuota: 80 Siswa",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: Salin Agenda & Bagikan WA
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
                            _copyToClipboard(scheduleText, "Agenda jadwal PPDB berhasil disalin!");
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primaryBlue),
                          label: const Text(
                            "Salin Agenda",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _shareToWhatsApp(scheduleText);
                          },
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text(
                            "Kirim ke WhatsApp",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBroadcastTemplatesModal({
    required int total,
    required int pending,
    required int approved,
    required int problematic,
    required int rplTotal,
    required int tbsmTotal,
    required int quota,
  }) {
    final remainingQuota = quota > approved ? quota - approved : 0;

    final templates = [
      {
        'title': '📢 Info Kuota & Gelombang',
        'tag': 'GELOMBANG 1',
        'tagColor': const Color(0xFF2563EB),
        'desc': 'Update keterisian kuota & pendaftar untuk grup calon siswa',
        'text': '''
*📢 PENGUMUMAN PPDB SMK BANI MASUM 2026/2027*
_NPSN: 69888774 • Terakreditasi_

Halo Calon Peserta Didik Baru & Bapak/Ibu Wali Murid!
Berikut update terkini pendaftaran PPDB SMK Bani Masum:

📊 *STATUS PENDAFTARAN:*
• Total Pendaftar: *$total Siswa*
• Lulus Verifikasi: *$approved Siswa*
• Sisa Kuota Penerimaan: *$remainingQuota Kursi* (dari target $quota)

💻 *Peminatan Jurusan:*
- RPL (Rekayasa Perangkat Lunak): $rplTotal Siswa
- TBSM (Teknik Sepeda Motor): $tbsmTotal Siswa

Pendaftaran Gelombang 1 masih dibuka! Segera lengkapi berkas dan verifikasi data Anda melalui aplikasi pendaftaran.

🏫 *SMK BANI MASUM*
NPSN: 69888774
Layanan Panitia PPDB: 0812-3456-7890
Website: https://hadiramdhani.site
'''.trim(),
      },
      {
        'title': '⚠️ Pengingat Berkas Belum Lengkap',
        'tag': 'PENTING',
        'tagColor': const Color(0xFFEA580C),
        'desc': 'Pemberitahuan kepada pendaftar yang belum mengunggah berkas lengkap',
        'text': '''
*⚠️ PENGINGAT KELENGKAPAN BERKAS PPDB*
*SMK BANI MASUM (NPSN: 69888774)*

Yth. Calon Siswa & Orang Tua/Wali,
Berdasarkan hasil verifikasi panitia, saat ini terdapat berkas pendaftaran yang *belum lengkap* atau *perlu perbaikan*.

📌 *DOKUMEN WAJIB YANG HARUS DILENGKAPI:*
1. Pas Foto Berwarna Terbaru (3x4)
2. Scan / Foto Ijazah / Surat Keterangan Lulus (SKL)
3. Scan Kartu Keluarga (KK) & Akta Kelahiran
4. Nomor Induk Siswa Nasional (NISN) Valid

Silakan login kembali ke aplikasi pendaftaran untuk mengunggah berkas sebelum batas waktu berakhir.

Bantuan Teknis & Informasi:
📞 Panitia PPDB: 0812-3456-7890
'''.trim(),
      },
      {
        'title': '🎯 Undangan Tes Minat & Wawancara',
        'tag': 'SELEKSI',
        'tagColor': const Color(0xFF7C3AED),
        'desc': 'Jadwal tes seleksi & wawancara peminatan RPL & TBSM',
        'text': '''
*🎯 UNDANGAN TES SELEKSI & WAWANCARA PPDB*
*SMK BANI MASUM TAHUN AJARAN 2026/2027*

Yth. Calon Peserta Didik Baru,
Panitia PPDB mengundang Anda untuk mengikuti Tes Minat Bakat & Wawancara Penjurusan (RPL & TBSM):

🗓️ *Hari/Tanggal:* Sabtu, 15 Juli 2026
⏰ *Waktu:* 08.00 WIB - Selesai
📍 *Lokasi:* Kampus SMK Bani Masum
👕 *Pakaian:* Seragam SMP/MTs Asal & Bersepatu

*Kelengkapan yang dibawa:*
- Bukti Nomor Registrasi PPDB
- Kartu Pelajar / Identitas
- Alat Tulis Lengkap

Konfirmasi kehadiran dan info:
WA Panitia: 0812-3456-7890
'''.trim(),
      },
      {
        'title': '🎉 Pengumuman Hasil Kelulusan',
        'tag': 'HASIL SELEKSI',
        'tagColor': const Color(0xFF15803D),
        'desc': 'Format ucapan selamat kelulusan seleksi PPDB',
        'text': '''
*🎉 PENGUMUMAN KELULUSAN SELEKSI PPDB*
*SMK BANI MASUM TAHUN AJARAN 2026/2027*
_NPSN: 69888774_

Selamat! Bagi calon siswa yang telah dinyatakan *LULUS VERIFIKASI SELEKSI PPDB*. 

Selamat bergabung menjadi bagian dari Keluarga Besar SMK Bani Masum! 🎓

Tahap selanjutnya adalah *Daftar Ulang dan Pengambilan Seragam*. Informasi detail mengenai jadwal dan berkas fisik dapat dilihat di aplikasi PPDB atau langsung datang ke sekretariat PPDB.

Salam Hangat,
Panitia PPDB SMK Bani Masum
'''.trim(),
      },
      {
        'title': '💳 Panduan Daftar Ulang & Seragam',
        'tag': 'DAFTAR ULANG',
        'tagColor': const Color(0xFF0D9488),
        'desc': 'Instruksi alur daftar ulang dan pengukuran seragam',
        'text': '''
*💳 PANDUAN DAFTAR ULANG & SERAGAM SISWA BARU*
*SMK BANI MASUM 2026/2027*

Bagi siswa yang telah lulus verifikasi, berikut langkah daftar ulang:

1. Hadir ke Sekretariat PPDB SMK Bani Masum
2. Menyerahkan berkas fisik (Fotokopi KK, Akta, SKL/Ijazah, Pas Foto 3x4 3 lembar)
3. Melakukan pengukuran seragam sekolah & praktik bengkel/lab
4. Penyelesaian administrasi pendaftaran

Pelayanan dibuka setiap hari kerja pukul 08.00 - 14.00 WIB.

Sekretariat PPDB SMK Bani Masum:
NPSN: 69888774
Hotline: 0812-3456-7890
'''.trim(),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int selectedIdx = 0;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentTpl = templates[selectedIdx];
            final currentText = currentTpl['text'] as String;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtl) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                      const SizedBox(height: 14),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Color(0xFF16A34A),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pusat Siaran & Template WA",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.dark,
                                  ),
                                ),
                                Text(
                                  "Format pengumuman resmi siap broadcast ke grup/wali murid",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Template Chips selector
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: templates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final isSelected = selectedIdx == idx;
                            final tpl = templates[idx];
                            return ChoiceChip(
                              label: Text(
                                tpl['title'] as String,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppTheme.dark,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.dark,
                              backgroundColor: AppTheme.background,
                              side: BorderSide(
                                color: isSelected ? AppTheme.dark : AppTheme.border,
                              ),
                              showCheckmark: false,
                              onSelected: (_) => setModalState(() => selectedIdx = idx),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Template Description Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (currentTpl['tagColor'] as Color).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (currentTpl['tagColor'] as Color).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: currentTpl['tagColor'] as Color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentTpl['tag'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentTpl['desc'] as String,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.dark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // WhatsApp Preview Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.chat_bubble_rounded, size: 14, color: Color(0xFF16A34A)),
                                    SizedBox(width: 6),
                                    Text(
                                      "Pratinjau Pesan WhatsApp",
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "Format WA",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SelectableText(
                              currentText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.dark,
                                fontFamily: 'monospace',
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions: Salin Format & Buka WhatsApp
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
                                _copyToClipboard(currentText, "Format pesan berhasil disalin!");
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF16A34A)),
                              label: const Text(
                                "Salin Format",
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _shareToWhatsApp(currentText);
                              },
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: const Text(
                                "Buka WhatsApp",
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                const Text(
                  "Urutkan Daftar Pendaftar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 14),
                _buildSortOption(
                  ctx,
                  title: "Pendaftaran Terbaru (Default)",
                  subtitle: "Berdasarkan waktu pendaftaran terbaru",
                  icon: Icons.access_time_filled_rounded,
                  value: 'newest',
                ),
                _buildSortOption(
                  ctx,
                  title: "Pendaftaran Terlama",
                  subtitle: "Berdasarkan pendaftar yang masuk lebih awal",
                  icon: Icons.history_rounded,
                  value: 'oldest',
                ),
                _buildSortOption(
                  ctx,
                  title: "Nama Siswa (A - Z)",
                  subtitle: "Urutkan sesuai alfabet nama siswa",
                  icon: Icons.sort_by_alpha_rounded,
                  value: 'name_asc',
                ),
                _buildSortOption(
                  ctx,
                  title: "Nama Siswa (Z - A)",
                  subtitle: "Urutan terbalik dari Z ke A",
                  icon: Icons.sort_by_alpha_rounded,
                  value: 'name_desc',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _sortBy == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.brightBlue : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.dark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }

  void _showQuickStatusModal(
    String regId,
    String currentStatus,
    String studentName,
  ) {
    final statusList = [
      {
        'label': 'Menunggu verifikasi',
        'icon': Icons.hourglass_top_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'label': 'Lulus verifikasi',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFF15803D),
      },
      {
        'label': 'Berkas tidak lengkap',
        'icon': Icons.assignment_late_rounded,
        'color': const Color(0xFFEA580C),
      },
      {
        'label': 'Berkas dikembalikan',
        'icon': Icons.assignment_return_rounded,
        'color': const Color(0xFFEA580C),
      },
      {
        'label': 'Tidak lulus verifikasi',
        'icon': Icons.cancel_rounded,
        'color': const Color(0xFFDC2626),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                        color: AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ubah Status Cepat",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.dark,
                            ),
                          ),
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...statusList.map((item) {
                  final label = item['label'] as String;
                  final color = item['color'] as Color;
                  final icon = item['icon'] as IconData;
                  final isSelected = currentStatus == label;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : AppTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Icon(icon, color: color, size: 20),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                          color: isSelected ? color : AppTheme.dark,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: color, size: 18)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        if (isSelected) return;

                        try {
                          final db = FirebaseFirestore.instance;
                          final batch = db.batch();
                          batch.update(db.collection('registrations').doc(regId), {'status': label});
                          batch.update(db.collection('registration_status').doc(regId), {'status': label});
                          await batch.commit();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Status $studentName berhasil diubah ke: $label"),
                                backgroundColor: const Color(0xFF15803D),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Gagal memperbarui status: $e"),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuickContactModal(
    String studentName,
    String? phone,
    String? parentName,
    String? parentPhone,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                Text(
                  "Kontak Pendaftar: $studentName",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildContactTile(
                  title: "No. Handphone Siswa",
                  value: phone ?? '-',
                  icon: Icons.phone_android_rounded,
                  onCopy: phone != null && phone.isNotEmpty && phone != '-'
                      ? () {
                          Navigator.pop(ctx);
                          _copyToClipboard(phone, "Nomor HP Siswa disalin ke clipboard!");
                        }
                      : null,
                ),
                const SizedBox(height: 10),
                _buildContactTile(
                  title: "Orang Tua / Wali (${parentName ?? 'Wali'})",
                  value: parentPhone ?? '-',
                  icon: Icons.phone_in_talk_rounded,
                  onCopy: parentPhone != null && parentPhone.isNotEmpty && parentPhone != '-'
                      ? () {
                          Navigator.pop(ctx);
                          _copyToClipboard(parentPhone, "Nomor HP Orang Tua disalin ke clipboard!");
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactTile({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dark,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: "Salin Nomor",
              icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryBlue, size: 18),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  void _showAnalyticsModal({
    required int total,
    required int pending,
    required int approved,
    required int problematic,
    required int rplTotal,
    required int rplApproved,
    required int tbsmTotal,
    required int tbsmApproved,
    required int pendingDocs,
  }) {
    final passRate = total > 0 ? ((approved / total) * 100).toStringAsFixed(1) : '0';
    final quotaPercent = ((approved / _targetQuota) * 100).toStringAsFixed(1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtl) {
            return Padding(
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
                      Icon(Icons.analytics_rounded, color: AppTheme.primaryBlue, size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Analisis Data PPDB",
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
                    "Statistik lengkap pendaftaran PPDB SMK Bani Masum",
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Quota Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.dark, AppTheme.darkSecondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Keterisian Kuota PPDB",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.brightBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "$quotaPercent%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _targetQuota > 0 ? (approved / _targetQuota).clamp(0.0, 1.0) : 0,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$approved Lulus Terverifikasi",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            Text(
                              "Target: $_targetQuota Siswa",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Jurusan Comparison
                  const Text(
                    "Distribusi Peminatan Jurusan",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMajorStatCard(
                          title: "RPL - Komputer",
                          total: rplTotal,
                          approved: rplApproved,
                          icon: Icons.computer_rounded,
                          color: AppTheme.brightBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMajorStatCard(
                          title: "TBSM - Otomotif",
                          total: tbsmTotal,
                          approved: tbsmApproved,
                          icon: Icons.two_wheeler_rounded,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Document Status Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.folder_shared_rounded, size: 18, color: AppTheme.dark),
                                SizedBox(width: 8),
                                Text(
                                  "Status Kelengkapan Dokumen",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.dark,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "$pendingDocs Menunggu",
                              style: const TextStyle(
                                color: Color(0xFFEA580C),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Dokumen Lengkap", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${total - pendingDocs}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Menunggu Upload", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$pendingDocs",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons: Salin Rekap Singkat & Pusat Siaran WA
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
                            Navigator.pop(ctx);
                            _copyWhatsAppReport(
                              total: total,
                              pending: pending,
                              approved: approved,
                              problematic: problematic,
                              rplTotal: rplTotal,
                              rplApproved: rplApproved,
                              tbsmTotal: tbsmTotal,
                              tbsmApproved: tbsmApproved,
                              pendingDocs: pendingDocs,
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF15803D)),
                          label: const Text(
                            "Salin Rekap",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showBroadcastTemplatesModal(
                              total: total,
                              pending: pending,
                              approved: approved,
                              problematic: problematic,
                              rplTotal: rplTotal,
                              tbsmTotal: tbsmTotal,
                              quota: _targetQuota,
                            );
                          },
                          icon: const Icon(Icons.campaign_rounded, size: 16, color: AppTheme.skyBlue),
                          label: const Text(
                            "Pusat Siaran WA",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMajorStatCard({
    required String title,
    required int total,
    required int approved,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$total Siswa",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$approved telah lulus",
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Image.asset(
                    'assets/images/smk.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SMK BANI MASUM",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "PANITIA PPDB 2026/2027",
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.skyBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Pengaturan & Akun",
            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: "Keluar Akun",
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _registrationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      "Gagal Memuat Data:\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dark,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Compute Statistics
          final totalCount = allDocs.length;
          final pendingCount = allDocs.where((d) => (d.data() as Map)['status'] == 'Menunggu verifikasi').length;
          final approvedCount = allDocs.where((d) => (d.data() as Map)['status'] == 'Lulus verifikasi').length;
          final problematicCount = allDocs.where((d) {
            final st = (d.data() as Map)['status'];
            return st == 'Berkas tidak lengkap' ||
                st == 'Berkas dikembalikan' ||
                st == 'Tidak lulus verifikasi';
          }).length;

          // Department & Document Statistics
          final rplDocs = allDocs.where((d) => ((d.data() as Map)['major'] ?? '').toString().contains('RPL')).toList();
          final rplTotal = rplDocs.length;
          final rplApproved = rplDocs.where((d) => (d.data() as Map)['status'] == 'Lulus verifikasi').length;

          final tbsmDocs = allDocs.where((d) => ((d.data() as Map)['major'] ?? '').toString().contains('TBSM')).toList();
          final tbsmTotal = tbsmDocs.length;
          final tbsmApproved = tbsmDocs.where((d) => (d.data() as Map)['status'] == 'Lulus verifikasi').length;

          final pendingDocsCount = allDocs.where((d) => (d.data() as Map)['documents_pending'] == true).length;

          // Filter by search, status, and major
          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final number = (data['registration_number'] ?? '').toString().toLowerCase();
            final nisn = (data['nisn'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? '').toString().toLowerCase();
            final parentName = (data['parent_name'] ?? '').toString().toLowerCase();
            final parentPhone = (data['parent_phone'] ?? '').toString().toLowerCase();
            final major = (data['major'] ?? '').toString();
            final status = (data['status'] ?? '').toString();

            // Search multi-fields
            final q = _searchQuery.toLowerCase();
            final matchesSearch = q.isEmpty ||
                name.contains(q) ||
                number.contains(q) ||
                nisn.contains(q) ||
                phone.contains(q) ||
                parentName.contains(q) ||
                parentPhone.contains(q) ||
                major.toLowerCase().contains(q);

            if (!matchesSearch) return false;

            // Status filter
            if (_selectedStatusFilter == 'Menunggu verifikasi' && status != 'Menunggu verifikasi') {
              return false;
            }
            if (_selectedStatusFilter == 'Lulus verifikasi' && status != 'Lulus verifikasi') {
              return false;
            }
            if (_selectedStatusFilter == 'Berkas bermasalah') {
              final isProblem = status == 'Berkas tidak lengkap' ||
                  status == 'Berkas dikembalikan' ||
                  status == 'Tidak lulus verifikasi';
              if (!isProblem) return false;
            }

            // Major filter
            if (_selectedMajorFilter == 'RPL' && !major.contains('RPL')) {
              return false;
            }
            if (_selectedMajorFilter == 'TBSM' && !major.contains('TBSM')) {
              return false;
            }

            return true;
          }).toList();

          // Sorting logic
          filteredDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            if (_sortBy == 'oldest') {
              final aCreated = aData['created_at'] ?? '';
              final bCreated = bData['created_at'] ?? '';
              return aCreated.toString().compareTo(bCreated.toString());
            } else if (_sortBy == 'name_asc') {
              final aName = (aData['name'] ?? '').toString().toLowerCase();
              final bName = (bData['name'] ?? '').toString().toLowerCase();
              return aName.compareTo(bName);
            } else if (_sortBy == 'name_desc') {
              final aName = (aData['name'] ?? '').toString().toLowerCase();
              final bName = (bData['name'] ?? '').toString().toLowerCase();
              return bName.compareTo(aName);
            } else {
              // newest (default)
              final aCreated = aData['created_at'] ?? '';
              final bCreated = bData['created_at'] ?? '';
              return bCreated.toString().compareTo(aCreated.toString());
            }
          });

          final hasActiveFilters = _searchQuery.isNotEmpty ||
              _selectedStatusFilter != 'Semua' ||
              _selectedMajorFilter != 'Semua' ||
              _sortBy != 'newest';

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Top Stats & Greeting Banner
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: const BoxDecoration(
                      color: AppTheme.dark,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(26),
                        bottomRight: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final currentUser = context.watch<AuthProvider>().user;
                                  final adminStream = _getAdminDocStream(currentUser?.uid);
                                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                    stream: adminStream,
                                    builder: (context, adminSnapshot) {
                                      final firestoreName = adminSnapshot.data?.data()?['name']?.toString();
                                      final adminName = _resolveAdminName(
                                        firestoreName: firestoreName,
                                        displayName: currentUser?.displayName,
                                        email: currentUser?.email,
                                      );
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${_getGreeting()}, $adminName 👋",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            "Portal Administrasi PPDB SMK Bani Masum",
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 3,
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Live Sync",
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Interactive 4 Stat Cards Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildInteractiveStatCard(
                                title: "Total",
                                count: totalCount.toString(),
                                icon: Icons.people_alt_rounded,
                                color: AppTheme.brightBlue,
                                filterKey: 'Semua',
                                isSelected: _selectedStatusFilter == 'Semua',
                                onTap: () => setState(() => _selectedStatusFilter = 'Semua'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInteractiveStatCard(
                                title: "Menunggu",
                                count: pendingCount.toString(),
                                icon: Icons.hourglass_top_rounded,
                                color: const Color(0xFFF59E0B),
                                filterKey: 'Menunggu verifikasi',
                                isSelected: _selectedStatusFilter == 'Menunggu verifikasi',
                                onTap: () => setState(() {
                                  _selectedStatusFilter = _selectedStatusFilter == 'Menunggu verifikasi'
                                      ? 'Semua'
                                      : 'Menunggu verifikasi';
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInteractiveStatCard(
                                title: "Lulus",
                                count: approvedCount.toString(),
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFF10B981),
                                filterKey: 'Lulus verifikasi',
                                isSelected: _selectedStatusFilter == 'Lulus verifikasi',
                                onTap: () => setState(() {
                                  _selectedStatusFilter = _selectedStatusFilter == 'Lulus verifikasi'
                                      ? 'Semua'
                                      : 'Lulus verifikasi';
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInteractiveStatCard(
                                title: "Masalah",
                                count: problematicCount.toString(),
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFEF4444),
                                filterKey: 'Berkas bermasalah',
                                isSelected: _selectedStatusFilter == 'Berkas bermasalah',
                                onTap: () => setState(() {
                                  _selectedStatusFilter = _selectedStatusFilter == 'Berkas bermasalah'
                                      ? 'Semua'
                                      : 'Berkas bermasalah';
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Quota & Major Distribution Card (Expandable)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _toggleQuotaExpanded,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.pie_chart_rounded,
                                            size: 15,
                                            color: AppTheme.skyBlue,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Target Kuota Penerimaan ($approvedCount/$_targetQuota)",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      RotationTransition(
                                        turns: _quotaRotateAnimation,
                                        child: const Icon(
                                          Icons.keyboard_arrow_up_rounded,
                                          color: AppTheme.skyBlue,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizeTransition(
                                sizeFactor: _quotaExpandAnimation,
                                axisAlignment: -1.0,
                                child: FadeTransition(
                                  opacity: _quotaExpandAnimation,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),
                                      // Quota Progress Bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: _targetQuota > 0 ? (approvedCount / _targetQuota).clamp(0.0, 1.0) : 0,
                                          minHeight: 6,
                                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildMiniDepartmentPill(
                                              name: "💻 RPL",
                                              total: rplTotal,
                                              approved: rplApproved,
                                              color: AppTheme.brightBlue,
                                              isActive: _selectedMajorFilter == 'RPL',
                                              onTap: () {
                                                setState(() {
                                                  _selectedMajorFilter = _selectedMajorFilter == 'RPL' ? 'Semua' : 'RPL';
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildMiniDepartmentPill(
                                              name: "🏍️ TBSM",
                                              total: tbsmTotal,
                                              approved: tbsmApproved,
                                              color: const Color(0xFFF97316),
                                              isActive: _selectedMajorFilter == 'TBSM',
                                              onTap: () {
                                                setState(() {
                                                  _selectedMajorFilter = _selectedMajorFilter == 'TBSM' ? 'Semua' : 'TBSM';
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Action Bar: Jadwal & Gelombang & Analisis Lengkap
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _showScheduleAndWavesModal(
                                  approvedCount: approvedCount,
                                  targetQuota: _targetQuota,
                                ),
                                icon: const Icon(
                                  Icons.event_note_rounded,
                                  size: 15,
                                  color: AppTheme.skyBlue,
                                ),
                                label: const Text(
                                  "Jadwal & Gelombang",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  _showAnalyticsModal(
                                    total: totalCount,
                                    pending: pendingCount,
                                    approved: approvedCount,
                                    problematic: problematicCount,
                                    rplTotal: rplTotal,
                                    rplApproved: rplApproved,
                                    tbsmTotal: tbsmTotal,
                                    tbsmApproved: tbsmApproved,
                                    pendingDocs: pendingDocsCount,
                                  );
                                },
                                icon: const Icon(Icons.bar_chart_rounded, size: 14),
                                label: const Text(
                                  "Analisis Detail",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Box & Sorting Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      children: [
                        // Search TextField
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: "Cari nama, no. reg, NISN, atau no HP...",
                            hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filters & Sort Controls Row
                        Row(
                          children: [
                            // Sort Button
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _showSortModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _sortBy != 'newest' ? AppTheme.primaryBlue : AppTheme.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.swap_vert_rounded,
                                      size: 16,
                                      color: _sortBy != 'newest' ? AppTheme.primaryBlue : AppTheme.dark,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _sortBy == 'newest'
                                          ? "Terbaru"
                                          : _sortBy == 'oldest'
                                              ? "Terlama"
                                              : _sortBy == 'name_asc'
                                                  ? "Nama A-Z"
                                                  : "Nama Z-A",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _sortBy != 'newest' ? AppTheme.primaryBlue : AppTheme.dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Major Filter Chips
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _majorFilters.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                                  itemBuilder: (context, index) {
                                    final m = _majorFilters[index];
                                    final isSelected = _selectedMajorFilter == m;
                                    return ChoiceChip(
                                      label: Text(
                                        m == 'Semua' ? 'Semua Jurusan' : m,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : AppTheme.dark,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppTheme.dark,
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: isSelected ? AppTheme.dark : AppTheme.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      showCheckmark: false,
                                      onSelected: (_) => setState(() => _selectedMajorFilter = m),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Status Filter Chips
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _statusFilters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final cat = _statusFilters[index];
                              final isSelected = _selectedStatusFilter == cat;
                              return ChoiceChip(
                                label: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppTheme.dark,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryBlue,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                showCheckmark: false,
                                onSelected: (_) => setState(() => _selectedStatusFilter = cat),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Result count & Reset filter row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Menampilkan ${filteredDocs.length} dari $totalCount pendaftar",
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (hasActiveFilters)
                              InkWell(
                                onTap: _resetAllFilters,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.restart_alt_rounded, size: 14, color: Color(0xFFDC2626)),
                                      SizedBox(width: 2),
                                      Text(
                                        "Reset Filter",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Registrations List
                filteredDocs.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  "Tidak ada pendaftar ditemukan",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.dark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Sesuaikan kata kunci pencarian atau reset filter yang sedang aktif.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                if (hasActiveFilters) ...[
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.dark,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: _resetAllFilters,
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text("Tampilkan Semua Data"),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildStudentCard(context, doc.id, data);
                            },
                            childCount: filteredDocs.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              backgroundColor: AppTheme.dark,
              foregroundColor: Colors.white,
              tooltip: "Kembali ke Atas",
              onPressed: _scrollToTop,
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
            )
          : null,
    );
  }

  Widget _buildInteractiveStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required String filterKey,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected
        ? Color.alphaBlend(color.withValues(alpha: 0.22), AppTheme.darkSecondary)
        : AppTheme.darkSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 13, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniDepartmentPill({
    required String name,
    required int total,
    required int approved,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final bgColor = isActive
        ? Color.alphaBlend(color.withValues(alpha: 0.2), AppTheme.darkSecondary)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.06), AppTheme.darkSecondary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
            ),
            Text(
              "$total ($approved✓)",
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Tanpa Nama';
    final number = data['registration_number'] ?? docId;
    final status = data['status'] ?? 'Menunggu verifikasi';
    final major = data['major'] ?? 'RPL';
    final rawPhoto = data['photo_url'] ?? data['pas_foto'] ?? data['foto_url'] ?? data['photo'];
    final photoUrl = rawPhoto is String ? rawPhoto.trim() : null;
    final hasValidPhoto = photoUrl != null && photoUrl.isNotEmpty && photoUrl.startsWith('http');
    final statusColor = AppTheme.getStatusColor(status);
    final statusBgColor = AppTheme.getStatusBgColor(status);
    final isDocsPending = data['documents_pending'] == true;
    final createdAt = data['created_at'];

    final phone = data['phone']?.toString();
    final parentName = data['parent_name']?.toString();
    final parentPhone = data['parent_phone']?.toString();

    // Initial avatar text
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : 'S';

    final isRpl = major.toString().contains('RPL');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(
                  registrationId: docId,
                  data: data,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar + Name + Reg Number + Quick Action Popup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.brightBlue.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: hasValidPhoto
                            ? Image.network(
                                photoUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Main info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.dark,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                number,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyToClipboard(number, "Nomor pendaftaran disalin!"),
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick More Action Popup Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textMuted),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'detail') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                registrationId: docId,
                                data: data,
                              ),
                            ),
                          );
                        } else if (val == 'status') {
                          _showQuickStatusModal(docId, status, name);
                        } else if (val == 'contact') {
                          _showQuickContactModal(name, phone, parentName, parentPhone);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'detail',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_rounded, size: 18, color: AppTheme.primaryBlue),
                              SizedBox(width: 10),
                              Text("Lihat Detail Siswa"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF10B981)),
                              SizedBox(width: 10),
                              Text("Ubah Status Cepat"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'contact',
                          child: Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 18, color: Color(0xFFF59E0B)),
                              SizedBox(width: 10),
                              Text("Kontak & Orang Tua"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Middle Badges: Major & Document Status
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Major Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRpl ? AppTheme.lightBlue : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isRpl
                              ? AppTheme.brightBlue.withValues(alpha: 0.3)
                              : const Color(0xFFF97316).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRpl ? Icons.computer_rounded : Icons.two_wheeler_rounded,
                            size: 13,
                            color: isRpl ? AppTheme.primaryBlue : const Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            major.toString().split(' - ').first,
                            style: TextStyle(
                              color: isRpl ? AppTheme.primaryBlue : const Color(0xFFEA580C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Document indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDocsPending ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDocsPending
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                              : const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDocsPending ? Icons.pending_actions_rounded : Icons.task_alt_rounded,
                            size: 13,
                            color: isDocsPending ? const Color(0xFFD97706) : const Color(0xFF15803D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDocsPending ? "Menunggu Berkas" : "Berkas Lengkap",
                            style: TextStyle(
                              color: isDocsPending ? const Color(0xFFD97706) : const Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom Row: Status Badge & Date + Quick Status Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showQuickStatusModal(docId, status, name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_rounded, size: 10, color: statusColor),
                          ],
                        ),
                      ),
                    ),

                    // Registration Date
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


