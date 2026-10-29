import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ChoferScreen extends StatefulWidget {
  const ChoferScreen({super.key});

  @override
  State<ChoferScreen> createState() => _ChoferScreenState();
}

class _ChoferScreenState extends State<ChoferScreen> {
  // Datos simulados para Hoja de Ruta
  final List<Map<String, dynamic>> _entregas = [
    {
      'id': 'E01',
      'bodega': 'Bodega San Martín',
      'monto': 660.00,
      'metodo': 'Cobro contra entrega en Efectivo',
      'liquidado': false,
    },
    {
      'id': 'E02',
      'bodega': 'Comercializadora El Sol',
      'monto': 268.50,
      'metodo': 'Pagado con Transferencia',
      'liquidado': false,
    },
    {
      'id': 'E03',
      'bodega': 'Minimarket Don Pedro',
      'monto': 1485.00,
      'metodo': 'Contra entrega',
      'liquidado': false,
    },
  ];

  Future<void> _liquidarEntrega(Map<String, dynamic> entrega) async {
    if (entrega['liquidado']) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liquidar Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bodega: ${entrega['bodega']}'),
            Text('Monto a recaudar: S/ ${entrega['monto'].toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('¿Confirmar recepción de mercadería y pago?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Confirmar y Escanear Guía'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        entrega['liquidado'] = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entrega a ${entrega['bodega']} liquidada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoja de Ruta y Despacho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          // Banner de Estado
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.amber.shade100,
            child: const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unidad Fuso #P1U-842', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Capacidad: 85% ocupada', style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de Entregas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _entregas.length,
              itemBuilder: (context, index) {
                final entrega = _entregas[index];
                final bool liquidado = entrega['liquidado'];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entrega['bodega'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            if (liquidado)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Text(
                                  'Entregado / Liquidado',
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Monto: S/ ${entrega['monto'].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text('Método: ${entrega['metodo']}', style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: liquidado ? null : () => _liquidarEntrega(entrega),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                            ),
                            icon: Icon(liquidado ? Icons.check_circle : Icons.inventory),
                            label: Text(liquidado ? 'Liquidado' : 'Liquidar Entrega'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
