import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({super.key});

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = "Panitia PPDB";
  final List<String> _roles = ["Panitia PPDB", "Verifikator Berkas", "Administrator"];

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      // Menggunakan secondary FirebaseApp agar akun admin yang sedang aktif tidak ter-logout
      final secondaryApp = await Firebase.initializeApp(
        name: 'AddAdminSecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (name.isNotEmpty) {
        await userCredential.user?.updateDisplayName(name);
      }

      final newUid = userCredential.user?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();
      await secondaryApp.delete();

      // Simpan data admin ke koleksi Firestore 'admins'
      await FirebaseFirestore.instance.collection('admins').doc(newUid).set({
        'uid': newUid,
        'email': email,
        'name': name.isNotEmpty ? name : 'Panitia PPDB',
        'role': _selectedRole,
        'status': 'Aktif',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text("Admin ($email) berhasil ditambahkan!")),
            ],
          ),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context); // Kembali ke list admin
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String msg = "Gagal mendaftarkan admin: ${e.message}";
      if (e.code == 'email-already-in-use') {
        msg = "Email tersebut sudah terdaftar di sistem.";
      } else if (e.code == 'weak-password') {
        msg = "Kata sandi terlalu lemah (minimal 6 karakter).";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Tambah Admin Baru"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: AppTheme.dark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded, color: AppTheme.skyBlue, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pendaftaran Administrator",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Akun yang didaftarkan akan memiliki akses login ke aplikasi PPDB ini.",
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Body Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Lengkap
                        const Text(
                          "Nama Panitia / Petugas",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.dark),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: "Contoh: Budi Santoso",
                            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primaryBlue, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Nama petugas wajib diisi";
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Email
                        const Text(
                          "Email Akun Admin",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.dark),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: "panitia@banimasum.sch.id",
                            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryBlue, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Email wajib diisi";
                            if (!v.contains('@')) return "Format email tidak valid";
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Kata Sandi
                        const Text(
                          "Kata Sandi Akun",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.dark),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Minimal 6 karakter",
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryBlue, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Kata sandi wajib diisi";
                            if (v.length < 6) return "Kata sandi minimal 6 karakter";
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Peran / Role
                        const Text(
                          "Peran / Jabatan",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.dark),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primaryBlue, size: 20),
                          ),
                          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRole = val);
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        "Simpan & Daftarkan Admin",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
