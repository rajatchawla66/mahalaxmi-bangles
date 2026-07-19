import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mahalaxmi_shared/providers/auth_provider.dart';

const _kMaroon = Color(0xFF800020);
const _kCream = Color(0xFFFFF8F0);
const _kDark = Color(0xFF1A1A2E);
const _kMuted = Color(0xFF9E9E9E);

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _adminPasswordController = TextEditingController();
  final _labourPasswordController = TextEditingController();
  bool _adminLoading = false;
  bool _labourLoading = false;
  String? _adminError;
  String? _labourError;

  @override
  void dispose() {
    _adminPasswordController.dispose();
    _labourPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    setState(() {
      _adminLoading = true;
      _adminError = null;
    });

    final auth = ref.read(authControllerProvider);
    final result = await auth.loginAdmin('admin', _adminPasswordController.text);

    if (!mounted) return;
    setState(() {
      _adminLoading = false;
      if (result is InvalidCredentials) {
        _adminError = 'Incorrect password';
      } else if (result is NetworkError) {
        _adminError = result.message;
      }
    });
  }

  Future<void> _loginLabour() async {
    setState(() {
      _labourLoading = true;
      _labourError = null;
    });

    final auth = ref.read(authControllerProvider);
    final result = await auth.loginLabour('labour', _labourPasswordController.text);

    if (!mounted) return;
    setState(() {
      _labourLoading = false;
      if (result is InvalidCredentials) {
        _labourError = 'Incorrect password';
      } else if (result is NetworkError) {
        _labourError = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: _kMaroon,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mahalaxmi Admin',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _kDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sign in to manage orders & catalogue',
                  style: TextStyle(fontSize: 13, color: _kMuted),
                ),
                const SizedBox(height: 40),

                // --- Admin Card ---
                _LoginCard(
                  title: 'Admin',
                  subtitle: 'Full access — orders, catalogue, settings',
                  icon: Icons.shield_outlined,
                  error: _adminError,
                  loading: _adminLoading,
                  controller: _adminPasswordController,
                  obscureText: true,
                  onLogin: _loginAdmin,
                ),

                const SizedBox(height: 20),

                // --- Labour Card ---
                _LoginCard(
                  title: 'Labour',
                  subtitle: 'Production checklist — no pricing',
                  icon: Icons.construction_outlined,
                  error: _labourError,
                  loading: _labourLoading,
                  controller: _labourPasswordController,
                  obscureText: true,
                  onLogin: _loginLabour,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? error;
  final bool loading;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.error,
    required this.loading,
    required this.controller,
    required this.obscureText,
    required this.onLogin,
  });

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: _kMaroon, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kDark)),
                    Text(widget.subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.controller,
              obscureText: _obscured,
              decoration: InputDecoration(
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => widget.onLogin(),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 8),
              Text(widget.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: widget.loading ? null : widget.onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: widget.loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Sign in as ${widget.title}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
