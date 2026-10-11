import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/in_app_notification_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = true;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false;
      if (user != null) {
        InAppNotificationService.startListening();
      } else {
        InAppNotificationService.stopListening();
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "Email atau kata sandi yang Anda masukkan salah.";
      }
      return "Terjadi kesalahan saat login: ${e.message}";
    } catch (e) {
      return "Terjadi kesalahan yang tidak diketahui.";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
