import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mahalaxmi_shared/providers/customer_auth_provider.dart';

import '../../../app/theme.dart';
import '../../../constants/business_info.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final reason = ref.read(forcedLogoutReasonProvider);
    if (reason == 'disabled') {
      _error =
          'Your account has been disabled. Please contact Mahalaxmi Bangles.';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(forcedLogoutReasonProvider.notifier).state = null;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_pin.length != 8) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final controller = ref.read(customerAuthControllerProvider);
    final result = await controller.loginWithPin(_pin);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result == null) {
      if (context.mounted) context.go('/dashboard');
    } else {
      setState(() {
        if (result is InvalidPin) {
          _error = 'Invalid PIN. Please try again.';
        } else if (result is BlockedCustomer) {
          _error = 'This account has been blocked. Contact support.';
        } else if (result is CustomerNetworkError) {
          _error = 'Connection error. Please try again.';
        } else {
          _error = 'Login failed. Please try again.';
        }
        _pin = '';
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_pin.length < 8) {
      setState(() => _pin += digit);
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _onClearPressed() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = '');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link. Please try again.')),
      );
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit app?'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You can close this browser tab.')),
                );
              } else {
                SystemNavigator.pop();
              }
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 28),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Image.asset('assets/watermark.png'),
                ),
                const SizedBox(height: 10),
                const Text(
                  kBusinessName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    color: kDark,
                  ),
                ),
                const Text(
                  kTagline,
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 1, color: kGold.withValues(alpha: 0.3)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('✦', style: TextStyle(color: kGold, fontSize: 14)),
                    ),
                    Expanded(
                      child: Container(height: 1, color: kGold.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kGold.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'GST: $kGst',
                    style: const TextStyle(fontSize: 13, color: kDark),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Enter Customer PIN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(8, (i) {
                    final filled = i < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? kDark : kDark.withValues(alpha: 0.12),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_pin.length}/8 digits',
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: kMaroon.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: kMaroon, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _buildKeypad(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _pin.length == 8 && !_isLoading ? _handleLogin : null,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: kMuted),
                    const SizedBox(width: 6),
                    const Text(
                      'Secure & Trusted',
                      style: TextStyle(fontSize: 12, color: kMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  kAddressLine1,
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
                const Text(
                  kAddressLine2,
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Connect With Us',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.camera_alt_outlined,
                        label: 'Instagram',
                        subtitle: 'Follow us',
                        onTap: () => _launchUrl(kInstagramUrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.chat_bubble_outline,
                        label: 'WhatsApp',
                        subtitle: 'Get support',
                        onTap: () => _launchUrl(kWhatsappUrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.location_on_outlined,
                        label: 'Maps',
                        subtitle: 'Visit us',
                        onTap: () => _launchUrl(kMapsUrl),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kGold.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    kHeritageText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kDark,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final disabled = _isLoading;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _KeypadButton(text: '1', onPressed: () => _onDigitPressed('1'), disabled: disabled)),
            const SizedBox(width: 10),
            Expanded(child: _KeypadButton(text: '2', onPressed: () => _onDigitPressed('2'), disabled: disabled)),
            const SizedBox(width: 10),
            Expanded(child: _KeypadButton(text: '3', onPressed: () => _onDigitPressed('3'), disabled: disabled)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _KeypadButton(text: '4', onPressed: () => _onDigitPressed('4'), disabled: disabled)),
            const SizedBox(width: 10),
            Expanded(child: _KeypadButton(text: '5', onPressed: () => _onDigitPressed('5'), disabled: disabled)),
            const SizedBox(width: 10),
            Expanded(child: _KeypadButton(text: '6', onPressed: () => _onDigitPressed('6'), disabled: disabled)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _KeypadButton(text: '7', onPressed: () => _onDigitPressed('7'), disabled: disabled)),
            const SizedBox(width: 10),
            Expanded(child: _KeypadButton(text: '8', onPressed: () => _onDigitPressed('8'), disabled: disabled)),
            const SizedBox(width: 10),
            Expanded(child: _KeypadButton(text: '9', onPressed: () => _onDigitPressed('9'), disabled: disabled)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KeypadButton(
                text: 'C',
                onPressed: _pin.isNotEmpty ? _onClearPressed : null,
                disabled: disabled,
                secondary: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _KeypadButton(text: '0', onPressed: () => _onDigitPressed('0'), disabled: disabled)),
            const SizedBox(width: 10),
            Expanded(
              child: _KeypadButton(
                text: '⌫',
                onPressed: _pin.isNotEmpty ? _onBackspacePressed : null,
                disabled: disabled,
                secondary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool disabled;
  final bool secondary;

  const _KeypadButton({
    required this.text,
    this.onPressed,
    this.disabled = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = secondary ? Colors.white : kCream;
    final fgColor = secondary ? kMaroon : kDark;
    final borderColor = secondary ? kMaroon.withValues(alpha: 0.2) : kGold.withValues(alpha: 0.35);
    final disabledBg = Colors.grey.shade200;
    final disabledFg = Colors.grey.shade400;

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: disabledBg,
          disabledForegroundColor: disabledFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: secondary ? 18 : 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 26, color: kMaroon),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kDark,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
