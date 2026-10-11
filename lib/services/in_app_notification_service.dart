import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class InAppNotificationService {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static StreamSubscription<QuerySnapshot>? _subscription;
  static bool _isListening = false;

  /// Memulai pemantauan pendaftar baru dari Firestore secara real-time
  static void startListening() {
    if (_isListening) return;
    _isListening = true;

    bool isInitialLoad = true;

    _subscription = FirebaseFirestore.instance
        .collection('registrations')
        .snapshots()
        .listen(
      (snapshot) {
        // Lewati kumpulan data awal saat aplikasi baru saja dibuka
        if (isInitialLoad) {
          isInitialLoad = false;
          return;
        }

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              final name = data['name'] ?? 'Calon Siswa';
              final major = data['major'] ?? 'RPL';
              showInAppNotification(
                title: "Pendaftar Baru Masuk! 🎓",
                body: "$name baru saja mendaftar di jurusan $major.",
              );
            }
          }
        }
      },
      onError: (e) {
        debugPrint("InAppNotification listener error: $e");
      },
    );
  }

  /// Menghentikan pemantauan jika diperlukan
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  /// Menampilkan banner notifikasi lokal di dalam aplikasi (Floating Banner)
  static void showInAppNotification({
    required String title,
    required String body,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE2E8F0),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 4),
        elevation: 8,
      ),
    );
  }
}
