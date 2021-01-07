import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'address.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserModel {
  UserModel({this.email, this.password, this.name, this.id});
  UserModel.fromDocument(DocumentSnapshot document) {
    id = document.id;
    Map response = document.data();
    name = response['name'] as String;
    email = response['email'] as String;

    cpf = response['cpf'] as String;
    if (document.data().containsKey('address')) {
      address =
          Address.fromMap(document.data()['address'] as Map<String, dynamic>);
    }
  }
  Address address;

  bool admin = false;
  String email;
  String id;
  String cpf;
  String name;
  String password;
  String confirmPassword;

  CollectionReference get tokensReference => firestoreRef.collection('tokens');
  CollectionReference get cartReference => firestoreRef.collection('cart');
  DocumentReference get firestoreRef =>
      FirebaseFirestore.instance.doc('users/$id');

  Future<void> saveData() async {
    await firestoreRef.set(toMap());
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      if (address != null) 'address': address.toMap(),
      if (cpf != null) 'cpf': cpf
    };
  }

  void setAddress(Address address) {
    this.address = address;
    saveData();
  }

  void setCpf(String cpf) {
    this.cpf = cpf;
    saveData();
  }

  Future<void> saveToken() async {
    final token = await FirebaseMessaging().getToken();
    await tokensReference.doc(token).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
    });
  }
}
