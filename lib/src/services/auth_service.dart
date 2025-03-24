import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class AuthService {
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? lastError;

  Stream<HospitalUser?> get userStream => _auth.userChanges().asyncMap((user) {
        if (user == null) return null;
        return _getUserWithRetry(user.uid);
      });

  Future<HospitalUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(const Duration(seconds: 15));

      _logger.i('Auth OK, buscando dados no Firestore...');
      return await _getUserWithRetry(userCredential.user!.uid);
    } on TimeoutException {
      lastError = 'Tempo excedido na autenticação';
      _logger.e('Timeout no login');
      return null;
    } on FirebaseAuthException catch (e) {
      lastError = _parseAuthError(e.code);
      _logger.e('Erro Auth: ${e.code}');
      return null;
    }
  }

  Future<HospitalUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required List<String> roles,
    required String fullName,
    required String cpf,
  }) async {
    UserCredential? userCredential;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _logger.i('Usuário Auth criado: ${userCredential.user!.uid}');

      final userData = {
        'fullName': fullName.trim(),
        'cpf': _sanitizeCpf(cpf),
        'email': email.trim(),
        'roles': roles,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      _logger.i('Tentando salvar no Firestore: $userData');

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData)
          .timeout(const Duration(seconds: 5));

      _logger.i('Firestore atualizado com sucesso');

      return HospitalUser(
        uid: userCredential.user!.uid,
        email: email.trim(),
        roles: roles,
        fullName: fullName.trim(),
        cpf: cpf,
      );
    } catch (e) {
      _logger.e('Erro durante cadastro: $e');
      await _deleteUserIfOrphaned(userCredential?.user);
      return null;
    }
  }

  Future<void> _deleteUserIfOrphaned(User? user) async {
    try {
      if (user != null) await user.delete();
    } catch (e) {
      _logger.e('Error deleting orphaned user: $e');
    }
  }

  String _sanitizeCpf(String cpf) => cpf.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> signOut() async => await _auth.signOut();

  Future<HospitalUser?> _getUserWithRetry(String uid, {int retries = 5}) async {
    for (var i = 0; i < retries; i++) {
      try {
        _logger.i('Tentativa ${i + 1}/$retries para buscar usuário $uid');

        final doc = await _firestore.collection('users').doc(uid).get();

        if (doc.exists) {
          return _parseUserDocument(doc);
        }

        await Future.delayed(Duration(seconds: i + 1));
      } on FirebaseException catch (e) {
        _logger.e('Erro Firestore (tentativa ${i + 1}): ${e.code}');
        if (i == retries - 1) {
          _logger.w('Falha final após $retries tentativas');
          throw Exception('Falha ao buscar usuário');
        }
      }
    }
    return null;
  }

  HospitalUser _parseUserDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return HospitalUser(
      uid: doc.id,
      email: data['email'] as String,
      roles: List<String>.from(data['roles']),
      fullName: data['fullName'] as String,
      cpf: data['cpf'] as String,
    );
  }

  String _parseAuthError(String code) {
    const errors = {
      'invalid-email': 'E-mail inválido',
      'user-disabled': 'Conta desativada',
      'user-not-found': 'Usuário não encontrado',
      'wrong-password': 'Senha incorreta',
      'email-already-in-use': 'E-mail já cadastrado',
      'operation-not-allowed': 'Operação não permitida',
      'weak-password': 'Senha fraca (mínimo 6 caracteres)',
      'network-request-failed': 'Falha de conexão com a internet',
    };
    return errors[code] ?? 'Erro desconhecido ($code)';
  }

  Future<void> debugCheckUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      _logger.i('Dados do usuário no Firestore: ${doc.data()}');
      _logger.i('Existe? ${doc.exists}');
    } catch (e) {
      _logger.e('Erro na verificação: $e');
    }
  }

  Future<bool> isLoggedIn() async => _auth.currentUser != null;
}
