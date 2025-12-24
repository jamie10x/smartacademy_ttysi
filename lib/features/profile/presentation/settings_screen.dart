import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // In dark mode, Use null (default surface) or specific color
    final bgColor = isDark ? null : Colors.grey[50];
    final appBarColor = isDark ? null : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Sozlamalar",
          style: GoogleFonts.inter(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appBarColor,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _SettingsSection(
            title: "Ko'rinish",
            children: [
              ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
                title: Text(
                  "Tungi rejim",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: "Akkaunt",
            children: [
              _SettingsTile(
                icon: Icons.logout,
                title: "Chiqish",
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  // Router triggers redirect automatically
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: isDark
                ? Border.all(color: Colors.white12)
                : Border.symmetric(
                    horizontal: BorderSide(color: Colors.grey.shade200),
                  ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: textColor),
      ),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
