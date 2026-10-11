import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'add_admin_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  @override
  void initState() {
    super.initState();
    _seedCurrentAdminIfNeeded();
  }

  void _seedCurrentAdminIfNeeded() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null && current.email != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('admins').doc(current.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          final prefix = current.email!.split('@').first.trim();
          final emailName = prefix
              .split(RegExp(r'[._\-]+'))
              .where((p) => p.isNotEmpty)
              .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
              .join(' ');
          final fallbackName = (current.displayName?.trim().isNotEmpty == true)
              ? current.displayName!.trim()
              : (emailName.isNotEmpty ? emailName : 'Admin');
          await docRef.set({
            'uid': current.uid,
            'email': current.email,
            'name': fallbackName,
            'role': 'Super Admin',
            'status': 'Aktif',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {}
    }
  }

  void _confirmDeleteAdmin(BuildContext context, String docId, String email, String currentUid) {
    if (docId == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Anda tidak dapat menghapus akun Anda sendiri."),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Text(
              "Hapus Akun Admin",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dark),
            ),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin mencabut hak akses administrator untuk akun:\n\n$email",
          style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.4),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('admins').doc(docId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Akun admin ($email) berhasil dihapus dari daftar."),
                      backgroundColor: const Color(0xFF15803D),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus admin: $e"),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Kelola Akun Admin"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAdminScreen()),
          );
        },
        backgroundColor: AppTheme.dark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text(
          "Tambah Admin",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admins')
            .orderBy('created_at', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Gagal memuat data admin:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final totalAdmins = docs.length;

          return CustomScrollView(
            slivers: [
              // Top Banner
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                  decoration: const BoxDecoration(
                    color: AppTheme.dark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TIM ADMINISTRATOR PPDB",
                            style: TextStyle(
                              color: AppTheme.skyBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Daftar Petugas Panitia",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$totalAdmins Administrator Terdaftar",
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),

              // Title Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    "SEMUA AKUN TERVERIFIKASI",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              // List Admin Cards
              docs.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          "Belum ada akun admin terdaftar.",
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final email = data['email'] ?? 'Tanpa Email';
                            final name = data['name'] ?? 'Petugas PPDB';
                            final role = data['role'] ?? 'Panitia PPDB';
                            final isMe = doc.id == currentUid;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMe ? AppTheme.primaryBlue : AppTheme.border,
                                  width: isMe ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Avatar Initial
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isMe ? AppTheme.dark : AppTheme.lightBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                          style: TextStyle(
                                            color: isMe ? Colors.white : AppTheme.primaryBlue,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Detail Admin
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppTheme.dark,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.lightBlue,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    "AKUN ANDA",
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppTheme.primaryBlue,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.dark,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  role,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Row(
                                                children: [
                                                  Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Aktif",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF15803D),
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action Delete
                                    if (!isMe)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                        onPressed: () => _confirmDeleteAdmin(context, doc.id, email, currentUid),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: docs.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
