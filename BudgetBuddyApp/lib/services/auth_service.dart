import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------
  // STREAM: Firebase login/logout listener
  // ---------------------------------------------------------
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ---------------------------------------------------------
  // REGISTER WITH EMAIL
  // ---------------------------------------------------------
  Future<User?> registerWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // ---------------------------------------------------------
  // LOGIN WITH EMAIL
  // ---------------------------------------------------------
  Future<User?> loginWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // ---------------------------------------------------------
  // GOOGLE SIGN-IN
  // ---------------------------------------------------------
  Future<User?> signInWithGoogle() async {
    // 1. Trigger Google Sign-In flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    // 2. Obtain auth details
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 3. Create a credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Sign in with Firebase
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }


  // ---------------------------------------------------------
  // RESET PASSWORD
  // ---------------------------------------------------------
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ---------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------
  // CREATE FIRESTORE USER DOC (ONLY IF FIRST LOGIN)
  // ---------------------------------------------------------
  Future<void> createUserDocumentIfMissing(User user) async {
    final doc = _firestore.collection("users").doc(user.uid);

    final snapshot = await doc.get();
    if (snapshot.exists) return;

    await doc.set({
      "email": user.email ?? "",
      "monthlyIncome": 0,
      "needsBudget": 0,
      "wantsBudget": 0,
      "savingsGoal": 0,
      "currency": "USD",
      "budgetType": "Customizable",
      "onboardingComplete": false,
      "setupComplete": false,
    });
  }


  // ---------------------------------------------------------
  // FETCH USER MODEL (READ FROM FIRESTORE)
  // ---------------------------------------------------------
  Future<UserModel?> fetchUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
    await _firestore.collection("users").doc(user.uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(user.uid, doc.data()!);
  }

  // ---------------------------------------------------------
  // UPDATE USER FIELDS IN FIRESTORE
  // ---------------------------------------------------------
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection("users")
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }
}
