import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? firebaseUser;
  UserModel? userModel;

  bool isLoading = true;
  String? errorMessage;

  UserAuthProvider() {
    _listenToAuthState();
  }

  // ---------------------------------------------------------
  // LISTEN TO LOGIN / LOGOUT EVENTS
  // ---------------------------------------------------------
  void _listenToAuthState() {
    _authService.authStateChanges().listen((user) async {
      firebaseUser = user;

      if (user == null) {
        // User logged out
        userModel = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      // User logged in → load Firestore model
      await _loadUserModel();
    });
  }

  // ---------------------------------------------------------
  // LOAD USER MODEL FROM FIRESTORE
  // ---------------------------------------------------------
  Future<void> _loadUserModel() async {
    userModel = await _authService.fetchUserModel();
    isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------
  // EMAIL REGISTER
  // ---------------------------------------------------------
  Future<String?> register(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      final user = await _authService.registerWithEmail(email, password);
      if (user != null) {
        await _authService.createUserDocumentIfMissing(user);
        await _loadUserModel();
      }

      return null;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return errorMessage;
    }
  }

  // ---------------------------------------------------------
  // EMAIL LOGIN
  // ---------------------------------------------------------
  Future<String?> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      final user = await _authService.loginWithEmail(email, password);

      if (user != null) {
        await _authService.createUserDocumentIfMissing(user);
        await _loadUserModel();
      }

      return null;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return errorMessage;
    }
  }

  // ---------------------------------------------------------
  // GOOGLE LOGIN
  // ---------------------------------------------------------
  Future<String?> loginWithGoogle() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithGoogle();

      if (user != null) {
        await _authService.createUserDocumentIfMissing(user);
        await _loadUserModel();
      }

      return null;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return errorMessage;
    }
  }

  // ---------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------
  Future<void> logout() async {
    await _authService.signOut();
    firebaseUser = null;
    userModel = null;
    notifyListeners();
  }

  // ---------------------------------------------------------
  // UPDATE USER DATA (onboarding + setup)
  // ---------------------------------------------------------
  Future<void> updateUserData(Map<String, dynamic> data) async {
    await _authService.updateUserData(data);
    await _loadUserModel();
  }
}
