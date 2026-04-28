import 'package:flutter/material.dart';
import 'package:flutterapp/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/core/routes/routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  final Color _primaryDeep = const Color(0xFF19382F);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Grupo: Apariencia ──
                  _buildGroupLabel('Apariencia'),
                  const SizedBox(height: 10),
                  _buildSettingsCard([
                    _buildToggleTile(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      iconColor: isDark
                          ? Colors.indigo.shade400
                          : Colors.orange.shade500,
                      iconBg: isDark
                          ? Colors.indigo.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      title: 'Tema',
                      subtitle:
                          isDark ? 'Modo oscuro activo' : 'Modo claro activo',
                      value: isDark,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Grupo: Preferencias ──
                  _buildGroupLabel('Preferencias'),
                  const SizedBox(height: 10),
                  _buildSettingsCard([
                    _buildNavTile(
                      icon: Icons.notifications_rounded,
                      iconColor: Colors.red.shade400,
                      iconBg: Colors.red.withValues(alpha: 0.08),
                      title: 'Notificaciones',
                      subtitle: 'Personaliza los avisos',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildNavTile(
                      icon: Icons.language_rounded,
                      iconColor: Colors.blue.shade500,
                      iconBg: Colors.blue.withValues(alpha: 0.08),
                      title: 'Idioma',
                      subtitle: 'Español',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Grupo: Soporte ──
                  _buildGroupLabel('Soporte'),
                  const SizedBox(height: 10),
                  _buildSettingsCard([
                    _buildNavTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.teal.shade500,
                      iconBg: Colors.teal.withValues(alpha: 0.08),
                      title: 'Centro de ayuda',
                      subtitle: 'Preguntas frecuentes',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildNavTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: Colors.purple.shade400,
                      iconBg: Colors.purple.withValues(alpha: 0.08),
                      title: 'Privacidad',
                      subtitle: 'Política de datos',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildNavTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: _primaryDeep,
                      iconBg: _primaryDeep.withValues(alpha: 0.08),
                      title: 'Acerca de',
                      subtitle: 'CanchAPP v1.0.0',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 36),

                  // ── Botón cerrar sesión ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, Routes.logout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      icon: Icon(Icons.logout_rounded,
                          color: Colors.red.shade500, size: 20),
                      label: Text('Cerrar sesión',
                          style: GoogleFonts.sansita(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red.shade600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text('CanchAPP · Made in Loja',
                        style: GoogleFonts.sansita(
                            fontSize: 12,
                            color: _primaryDeep.withValues(alpha: 0.3))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Material(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.arrow_back_rounded,
                            size: 22, color: _primaryDeep),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Configuración',
                      style: GoogleFonts.sansita(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _primaryDeep,
                          letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Personaliza tu experiencia en CanchAPP',
                  style: GoogleFonts.sansita(
                      fontSize: 14,
                      color: _primaryDeep.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _buildGroupLabel(String label) {
    return Text(label,
        style: GoogleFonts.sansita(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _primaryDeep.withValues(alpha: 0.4),
            letterSpacing: 0.5));
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
              color: _primaryDeep.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.sansita(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _primaryDeep)),
          Text(subtitle,
              style: GoogleFonts.sansita(
                  fontSize: 12, color: _primaryDeep.withValues(alpha: 0.45))),
        ])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _primaryDeep,
          activeTrackColor: _primaryDeep.withValues(alpha: 0.25),
        ),
      ]),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: GoogleFonts.sansita(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _primaryDeep)),
                  Text(subtitle,
                      style: GoogleFonts.sansita(
                          fontSize: 12,
                          color: _primaryDeep.withValues(alpha: 0.45))),
                ])),
            Icon(Icons.chevron_right_rounded,
                color: _primaryDeep.withValues(alpha: 0.25), size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1,
        indent: 70,
        endIndent: 16,
        color: _primaryDeep.withValues(alpha: 0.06));
  }
}
