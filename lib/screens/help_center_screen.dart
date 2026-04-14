// lib/screens/help_center_screen.dart

import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Ayuda'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildHelpCategory(
              context,
              icon: Icons.home_work_outlined,
              title: 'Gestión de Gallera',
              items: [
                'Cómo registrar un nuevo ejemplar.',
                'Organización por jaulas y áreas.',
                'Configuración de la información pública.',
              ],
            ),
            _buildHelpCategory(
              context,
              icon: Icons.analytics_outlined,
              title: 'Finanzas y Reportes',
              items: [
                'Registro de ingresos y gastos.',
                'Generación de reportes PDF para auditoría.',
                'Seguimiento de rentabilidad por ejemplar.',
              ],
            ),
            _buildHelpCategory(
              context,
              icon: Icons.shield_outlined,
              title: 'Partidos y Competencia',
              items: [
                'Cómo fundar un Partido competitivo.',
                'Invitación de socios y gestión de roles.',
                'Funcionamiento del Leaderboard global.',
              ],
            ),
            _buildHelpCategory(
              context,
              icon: Icons.qr_code_2_rounded,
              title: 'QR y Traceabilidad',
              items: [
                'Uso del código QR para identificación rápida.',
                'Escaneo en derbis para acceso a historial.',
                'Impresión de etiquetas premium.',
              ],
            ),
            _buildHelpCategory(
              context,
              icon: Icons.auto_stories_outlined,
              title: 'Libro de Cría',
              items: [
                'Seguimiento genético (Padre/Madre).',
                'Registro de consanguinidad y linaje.',
                'Estadísticas de descendencia exitosa.',
              ],
            ),
            const SizedBox(height: 40),
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: '¿En qué podemos ayudarte?',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildHelpCategory(BuildContext context, {required IconData icon, required String title, required List<String> items}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: items.map((item) => ListTile(
          title: Text(item, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, size: 16),
          onTap: () {
            // Futuro: Navegar a detalle del tutorial
          },
        )).toList(),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Column(
      children: [
        const Text('¿No encuentras lo que buscas?', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            // Futuro: Abrir WhatsApp o Correo
          },
          icon: const Icon(Icons.support_agent),
          label: const Text('CONTACTAR SOPORTE TÉCNICO'),
        ),
      ],
    );
  }
}
