import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatefulWidget {
  final String registrationId;
  final Map<String, dynamic> data;

  const DetailScreen({super.key, required this.registrationId, required this.data});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _status;
  bool _isUpdating = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'label': 'Menunggu verifikasi',
      'icon': Icons.hourglass_top_rounded,
      'color': Color(0xFFD97706),
      'desc': 'Berkas pendaftaran sedang dalam antrean verifikasi.',
    },
    {
      'label': 'Lulus verifikasi',
      'icon': Icons.verified_rounded,
      'color': Color(0xFF15803D),
      'desc': 'Semua dokumen dan data valid, siswa dinyatakan lulus seleksi.',
    },
    {
      'label': 'Berkas tidak lengkap',
      'icon': Icons.assignment_late_rounded,
      'color': Color(0xFFEA580C),
      'desc': 'Ada lampiran dokumen yang belum lengkap atau buram.',
    },
    {
      'label': 'Berkas dikembalikan',
      'icon': Icons.assignment_return_rounded,
      'color': Color(0xFFEA580C),
      'desc': 'Calon siswa diminta mengunggah ulang perbaikan dokumen.',
    },
    {
      'label': 'Tidak lulus verifikasi',
      'icon': Icons.cancel_rounded,
      'color': Color(0xFFDC2626),
      'desc': 'Data atau syarat administrasi tidak memenuhi kriteria penerimaan.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.data['status'] ?? 'Menunggu verifikasi';
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
                  "Ubah Status Pendaftaran",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Status baru akan langsung disinkronkan ke portal peserta.",
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _statusOptions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _statusOptions[index];
                      final isSelected = item['label'] == _status;
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _updateStatus(item['label'] as String);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.lightBlue : AppTheme.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (item['color'] as Color).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['label'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppTheme.primaryBlue : AppTheme.dark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['desc'] as String,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateStatus(String newStatus) async {
    if (newStatus == _status) return;

    setState(() => _isUpdating = true);

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      batch.update(db.collection('registrations').doc(widget.registrationId), {'status': newStatus});
      batch.update(db.collection('registration_status').doc(widget.registrationId), {'status': newStatus});

      await batch.commit();

      setState(() => _status = newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text("Status berhasil diubah menjadi: $newStatus")),
              ],
            ),
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
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _confirmDeleteStudent(BuildContext context, String name, String regNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 10),
            Text(
              "Hapus Pendaftar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Apakah Anda yakin ingin menghapus data calon siswa ini secara permanen?",
              style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.dark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "No. Registrasi: $regNumber",
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Peringatan: Data pendaftaran dan status publik calon siswa ini akan langsung dihapus dari sistem PPDB.",
              style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600, height: 1.3),
            ),
          ],
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
              _deleteStudent(context, name);
            },
            child: const Text("Ya, Hapus Data"),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(BuildContext context, String name) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      ),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      final regRef = FirebaseFirestore.instance.collection('registrations').doc(widget.registrationId);
      final statusRef = FirebaseFirestore.instance.collection('registration_status').doc(widget.registrationId);

      batch.delete(regRef);
      batch.delete(statusRef);
      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Tutup loading indicator
        Navigator.pop(context); // Kembali ke Dashboard

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text("Data pendaftar $name berhasil dihapus.")),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus data: $e"),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final name = d['name'] ?? 'Tanpa Nama';
    final regNumber = d['registration_number'] ?? widget.registrationId;
    final rawPhoto = d['photo_url'] ?? d['pas_foto'] ?? d['foto_url'] ?? d['photo'];
    final photoUrl = rawPhoto is String ? rawPhoto.trim() : null;
    final hasValidPhoto = photoUrl != null && photoUrl.isNotEmpty && photoUrl.startsWith('http');
    final statusColor = AppTheme.getStatusColor(_status);
    final statusBgColor = AppTheme.getStatusBgColor(_status);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Detail Calon Siswa"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: "Hapus Pendaftar",
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            onPressed: () => _confirmDeleteStudent(context, name, regNumber),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Student Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: AppTheme.dark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.brightBlue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.skyBlue, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasValidPhoto
                          ? Image.network(
                              photoUrl,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Text(
                                  name.isNotEmpty
                                      ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                name.isNotEmpty
                                    ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      regNumber,
                      style: const TextStyle(
                        color: AppTheme.skyBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
                children: [
                  // Action Card for Changing Status
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                "Tindakan Verifikasi",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.dark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isUpdating ? null : _showStatusPicker,
                              icon: _isUpdating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.edit_note_rounded, size: 20),
                              label: Text(_isUpdating ? "Memperbarui..." : "Ubah Status Kelulusan"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.dark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Section 1: Data Diri
                  _buildSectionCard(
                    title: "Data Calon Siswa",
                    icon: Icons.person_rounded,
                    items: [
                      {"label": "Nama Lengkap", "value": d['name']},
                      {"label": "NISN", "value": d['nisn']},
                      {"label": "Tanggal Lahir", "value": d['birth_date']},
                      {"label": "Pilihan Jurusan", "value": d['major']},
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Section 2: Kontak & Orang Tua
                  _buildSectionCard(
                    title: "Kontak & Orang Tua",
                    icon: Icons.contact_phone_rounded,
                    items: [
                      {"label": "No. Handphone Siswa", "value": d['phone']},
                      {"label": "Nama Orang Tua / Wali", "value": d['parent_name']},
                      {"label": "No. Handphone Orang Tua", "value": d['parent_phone']},
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Section 3: Berkas Dokumen & Tanggal
                  _buildSectionCard(
                    title: "Informasi Pendaftaran",
                    icon: Icons.info_outline_rounded,
                    items: [
                      {"label": "Nomor Registrasi", "value": regNumber},
                      {"label": "Waktu Pendaftaran", "value": d['created_at']},
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Danger Action: Hapus Pendaftar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        backgroundColor: const Color(0xFFFEF2F2),
                        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _confirmDeleteStudent(context, name, regNumber),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text(
                        "Hapus Data Pendaftar Ini",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
  }) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 10),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          item['label'] ?? '',
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
                          item['value']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
