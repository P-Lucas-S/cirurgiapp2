import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalUser {
  final String uid;
  final String email;
  final List<String> roles;
  final String fullName;
  final String cpf;

  const HospitalUser({
    required this.uid,
    required this.email,
    required this.roles,
    required this.fullName,
    required this.cpf,
  });

  factory HospitalUser.fromMap(Map<String, dynamic> data, String uid) {
    return HospitalUser(
      uid: uid,
      email: data['email'] as String,
      roles: (data['roles'] as List<dynamic>).map((e) => e.toString()).toList(),
      fullName: data['fullName'] as String,
      cpf: data['cpf'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'roles': roles,
        'fullName': fullName,
        'cpf': cpf,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
