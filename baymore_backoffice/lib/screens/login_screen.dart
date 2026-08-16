import 'package:flutter/material.dart';
import '../services/staff_auth_service.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      print('🔑 Tentative de login: ${_email.text}');
      final name = await StaffAuthService().login(_email.text.trim(), _password.text);
      print('👤 Nom retourné: $name');

      if (name != null && mounted) {
        print('✅ Login réussi, redirection vers le dashboard');
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (mounted) {
        print('❌ Login échoué: nom null');
        setState(() => _error = "Ce compte n'est pas autorisé sur le back-office Baymore.");
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() => _error = 'Identifiants incorrects.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('B', style: TextStyle(fontFamily: 'Fraunces', fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
                const SizedBox(height: 18),
                const Text('Baymore Back-office', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Réservé à l\'équipe boutique et aux livreurs', style: TextStyle(color: Color(0xFFC9BFA8), fontSize: 12)),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    TextField(controller: _email, decoration: const InputDecoration(labelText: 'E-mail'), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    TextField(controller: _password, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Se connecter'),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}