import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loja_virtual/helpers/firebase_errors.dart';
import 'package:loja_virtual/models/user.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

class UserManager extends ChangeNotifier {
  UserManager() {
    _loadCurrentUser();
  }

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ignore: deprecated_member_use
  UserModel user;
  bool _loading = false;
  bool get isLoggedIn => user != null;

  bool get loading => _loading;
  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> signIn(
      {UserModel user, Function onFail, Function onSuccess}) async {
    loading = true;
    try {
      final UserCredential result = await auth.signInWithEmailAndPassword(
          email: user.email, password: user.password);
      await _loadCurrentUser(firebaseUser: result.user);
      onSuccess();
      loading = false;
    } on PlatformException catch (e) {
      loading = false;
      onFail(getErrorString(e.message));
    } catch (err) {
      loading = false;
      onFail(getErrorString(err.message));
    }
  }

  bool _loadingFace = false;
  bool get loadingFace => _loadingFace;
  set loadingFace(bool value) {
    _loadingFace = value;
    notifyListeners();
  }

  Future<void> facebookLogin({Function onFail, Function onSuccess}) async {
    loadingFace = true;

    final result = await FacebookLogin().logIn(['email', 'public_profile']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        final credential =
            FacebookAuthProvider.credential(result.accessToken.token);

        final authResult = await auth.signInWithCredential(credential);

        if (authResult.user != null) {
          final firebaseUser = authResult.user;

          user = UserModel(
              id: firebaseUser.uid,
              name: firebaseUser.displayName,
              email: firebaseUser.email);

          await user.saveData();
          user.saveToken();

          onSuccess();
        }
        break;
      case FacebookLoginStatus.cancelledByUser:
        break;
      case FacebookLoginStatus.error:
        onFail(result.errorMessage);
        break;
    }

    loadingFace = false;
  }

  Future<void> signUp(
      {UserModel user, Function onFail, Function onSuccess}) async {
    loading = true;
    try {
      final UserCredential result = await auth
          .createUserWithEmailAndPassword(
              email: user.email, password: user.password)
          // ignore: missing_return
          .then((value) async {
        await firestore.collection('users').doc(value.user.uid).set({
          'name': user.name,
          'email': user.email,
        });
        user.id = value.user.uid;
      });
      this.user = result?.user as UserModel;
      await user.saveData();
      await user.saveToken();
      _loadCurrentUser();
      onSuccess();
      loading = false;
    } on PlatformException catch (e) {
      print(e.toString());
      onFail(getErrorString(e.code));

      loading = false;
    } catch (err) {
      print(err.toString());
      loading = false;
      onFail(getErrorString(err.toString()));
    }
  }

  void signOut() {
    auth.signOut();
    user = null;
    notifyListeners();
  }

  Future<void> _loadCurrentUser({User firebaseUser}) async {
    final User currentUser = firebaseUser ?? auth.currentUser;
    if (currentUser != null) {
      final DocumentSnapshot docUser =
          await firestore.collection('users').doc(currentUser.uid).get();
      user = UserModel.fromDocument(docUser);
      user.saveToken();
      final docAdmin = await firestore.collection('admins').doc(user.id).get();
      if (docAdmin.exists) {
        user.admin = true;
      }
      notifyListeners();
    }
  }

  bool get adminEnabled => user != null && user.admin;
}
