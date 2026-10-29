import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  // Datos simulados para Aprobaciones
  final List<Map<String, dynamic>> _aprobaciones = [
    {
      'id': 'A01',
      'bodega': 'Minimarket Don Pedro',
      'pedido': 1200.00,
      'exceso': 450.00,
    },
    {
      'id': 'A02',
      'bodega': 'Comercial Bella',
      'pedido': 2100.00,
      'exceso': 600.00,
    },
  ];

  // Datos simulados para Avance de Preventistas
  final List<Map<String, dynamic>> _preventistas = [
    {'nombre': 'Carlos Ruiz', 'meta': 3000.0, 'vendido': 2450.0},
    {'nombre': 'Ana Castillo', 'meta': 4000.0, 'vendido': 4100.0},
    {'nombre': 'Luis Mendoza', 'meta': 2500.0, 'vendido': 1900.0},
  ];

  void _gestionarAprobacion(String id, bool aprobar, String bodega) {
    setState(() {
      _aprobaciones.removeWhere((item) => item['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(aprobar
            ? 'Excepción aprobada para $bodega.'
            : 'Pedido rechazado para $bodega.'),
        backgroundColor: aprobar ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Supervisión Comercial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('usuario_rol');
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: KPIs
            const Text('Métricas del Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildKpiCard('Total Facturado', 'S/ 8,450.00', Icons.attach_money, Colors.green),
                const SizedBox(width: 12),
                _buildKpiCard('Cuota', '72%', Icons.trending_up, Colors.blue),
                const SizedBox(width: 12),
                _buildKpiCard('Pedidos', '14', Icons.shopping_cart, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Sección: Aprobaciones Pendientes
            Row(
              children: [
                const Text('Aprobaciones Crediticias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (_aprobaciones.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${_aprobaciones.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_aprobaciones.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No hay solicitudes pendientes de aprobación.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _aprobaciones.length,
                itemBuilder: (context, index) {
                  final item = _aprobaciones[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['bodega'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Pedido: S/ ${item['pedido'].toStringAsFixed(2)} | Exceso: S/ ${item['exceso'].toStringAsFixed(2)}'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _gestionarAprobacion(item['id'], false, item['bodega']),
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _gestionarAprobacion(item['id'], true, item['bodega']),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                icon: const Icon(Icons.check),
                                label: const Text('Aprobar Excepción'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Sección: Avance por Preventista
            const Text('Avance por Preventista', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _preventistas.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final prev = _preventistas[index];
                  final double avance = prev['vendido'] / prev['meta'];
                  final bool metaCumplida = avance >= 1.0;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(prev['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('S/ ${prev['vendido'].toStringAsFixed(2)} / S/ ${prev['meta'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: avance > 1.0 ? 1.0 : avance,
                          backgroundColor: Colors.grey.shade200,
                          color: metaCumplida ? Colors.green : const Color(0xFF0D47A1),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
