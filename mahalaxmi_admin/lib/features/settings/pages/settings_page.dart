import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuItem(
            icon: Icons.category_outlined,
            title: 'Manage Categories',
            subtitle: 'Edit names, cover images, active status',
            onTap: () => context.push('/settings/categories'),
          ),
          _MenuItem(
            icon: Icons.trending_flat_outlined,
            title: 'Default Margin',
            subtitle: 'Set default profit margin',
            onTap: () => context.push('/settings/margin'),
          ),
          _MenuItem(
            icon: Icons.science_outlined,
            title: 'Material Master',
            subtitle: 'Manage materials list',
            onTap: () => context.push('/settings/materials'),
          ),
          _MenuItem(
            icon: Icons.label_outline,
            title: 'Tag Master',
            subtitle: 'Rename or remove tags',
            onTap: () => context.push('/settings/tags'),
          ),
          _MenuItem(
            icon: Icons.colorize_outlined,
            title: 'Chuda Customisation',
            subtitle: 'Manage patti, color & box options',
            onTap: () => context.push('/settings/chuda-customization'),
          ),
          _MenuItem(
            icon: Icons.people_outline,
            title: 'Manage Customers',
            subtitle: 'View, add, edit or block customers',
            onTap: () => context.push('/customers'),
          ),
          _MenuItem(
            icon: Icons.checklist,
            title: 'Cutmail / Stock Check',
            subtitle: 'View & manage stock check reports',
            onTap: () => context.push('/cutmail'),
          ),
          _MenuItem(
            icon: Icons.archive_outlined,
            title: 'Archive Orders',
            subtitle: 'View completed & cancelled orders',
            onTap: () => context.push('/settings/archive'),
          ),
          const SizedBox(height: 20),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authControllerProvider).logout();
            },
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1565C0)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
