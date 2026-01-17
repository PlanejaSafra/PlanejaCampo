import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:planejacampo/l10n/l10n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // Para alternar entre login e registro

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  void _validateInputs() {
    setState(() {});
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // O usuário cancelou o login
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      Navigator.pushReplacementNamed(context, '/welcome');
    } catch (e) {
      _showErrorDialog(_handleFirebaseAuthError(e));
    }
  }

  Future<void> _loginWithEmailPassword() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog(S.of(context).msg_error_preencher_email_senha);
      return;
    }
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      Navigator.pushReplacementNamed(context, '/welcome');
    } catch (e) {
      _showErrorDialog(_handleFirebaseAuthError(e));
    }
  }

  String _handleFirebaseAuthError(dynamic e) {
    String errorMessage;
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = S.of(context).error_account_exists_different_credential;
          break;
        case 'invalid-credential':
          errorMessage = S.of(context).error_invalid_credential;
          break;
        case 'operation-not-allowed':
          errorMessage = S.of(context).error_operation_not_allowed;
          break;
        case 'user-disabled':
          errorMessage = S.of(context).error_user_disabled;
          break;
        case 'user-not-found':
          errorMessage = S.of(context).error_user_not_found;
          break;
        case 'wrong-password':
          errorMessage = S.of(context).error_wrong_password;
          break;
        case 'invalid-verification-code':
          errorMessage = S.of(context).error_invalid_verification_code;
          break;
        case 'invalid-verification-id':
          errorMessage = S.of(context).error_invalid_verification_id;
          break;
        default:
          errorMessage = '${S.of(context).error_unknown}: ${e.message}';
          break;
      }
    } else {
      errorMessage = S.of(context).error_generic;
    }
    return '$errorMessage\n\n${S.of(context).error_original}: ${e.toString()}';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e2a26), // Tom de verde escuro
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2a26), // Tom de verde escuro
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo3.png', // Certifique-se de que o logo esteja no caminho correto
                height: 150,
              ),
              const SizedBox(height: 20),
              Text(
                S.of(context).app_title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40), // Mais espaço entre o texto e os campos de email e senha
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: S.of(context).email,
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1e2a26), // Fundo verde escuro
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: S.of(context).password,
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1e2a26), // Fundo verde escuro
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loginWithEmailPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Botão verde
                  foregroundColor: Colors.black, // Cor do texto
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_isLogin ? S.of(context).continuar_email_senha : S.of(context).registrar_email_senha),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? S.of(context).register_prompt : S.of(context).login_prompt,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loginWithGoogle,
                icon: Image.asset('assets/android_neutral_rd_na@4x.png', height: 24), // Ícone do Google
                label: Text(S.of(context).continue_with_google),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Botão branco
                  foregroundColor: Colors.black, // Cor do texto
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24), // Pílula
                    side: const BorderSide(color: Color(0xFF8E918F), width: 1), // Traço
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}