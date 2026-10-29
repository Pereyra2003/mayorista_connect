import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/bodega_model.dart';
import '../data/pedido_repository.dart';
import '../data/bodega_repository.dart';

class PedidoScreen extends StatefulWidget {
  final Bodega bodega;

  const PedidoScreen({super.key, required this.bodega});

  @override
  State<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> with WidgetsBindingObserver {
  // Catálogo inicial de prueba para preventistas
  final List<Map<String, dynamic>> _catalogo = [
    {'sku': 'ARR-01', 'nombre': 'Arroz Costeño Saco 50kg', 'precio': 165.0, 'cant': 0},
    {'sku': 'AZU-02', 'nombre': 'Azúcar Cartavio Saco 50kg', 'precio': 142.0, 'cant': 0},
    {'sku': 'ACE-03', 'nombre': 'Aceite Primor Caja 12x1L', 'precio': 89.5, 'cant': 0},
    {'sku': 'LECH-04', 'nombre': 'Leche Gloria Caja 48 latas', 'precio': 178.0, 'cant': 0},
  ];

  double get _totalPedido {
    double total = 0.0;
    for (var item in _catalogo) {
      total += (item['precio'] as double) * (item['cant'] as int);
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarBorrador();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _guardarBorrador();
    } else if (state == AppLifecycleState.resumed) {
      _cargarBorrador();
    }
  }

  Future<void> _guardarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    final draftData = _catalogo.map((item) => {
      'sku': item['sku'],
      'cant': item['cant'],
    }).toList();
    await prefs.setString('borrador_pedido_${widget.bodega.id}', jsonEncode(draftData));
  }

  Future<void> _cargarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    final draftString = prefs.getString('borrador_pedido_${widget.bodega.id}');
    if (draftString != null) {
      try {
        final List<dynamic> draftData = jsonDecode(draftString);
        setState(() {
          for (var draftItem in draftData) {
            final index = _catalogo.indexWhere((item) => item['sku'] == draftItem['sku']);
            if (index != -1) {
              _catalogo[index]['cant'] = draftItem['cant'];
            }
          }
        });
      } catch (e) {
        debugPrint('Error al cargar borrador: $e');
      }
    }
  }

  Future<void> _confirmarPedido() async {
    final double disponible = widget.bodega.creditoDisponible;
    final double total = _totalPedido;

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue al menos un producto al pedido.')),
      );
      return;
    }

    // Regla de Negocio CP-01: Bloqueo si supera la línea de crédito
    if (total > disponible) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Línea de Crédito Excedida'),
            ],
          ),
          content: Text(
            'El total del pedido (S/ ${total.toStringAsFixed(2)}) supera el crédito disponible de la bodega (S/ ${disponible.toStringAsFixed(2)}).\n\nRequiere autorización de gerencia.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
              return;
    }

    try {
      // Regla de Negocio: Guardar en caché local o fallback en memoria
      final String fecha = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      
      await PedidoRepository.instance.insertarPedido({
        'bodega_nombre': widget.bodega.nombre,
        'bodega_ruc': widget.bodega.ruc,
        'total': total,
        'fecha': fecha,
        'sincronizado': 0, // 0 = pendiente, 1 = sincronizado
      });

      // Actualizar el saldo deudor de la bodega
      await BodegaRepository.instance.actualizarSaldo(widget.bodega.id, total);

      if (!mounted) return;

      // Limpiamos el formulario (reset de cantidades)
      setState(() {
        for (var item in _catalogo) {
          item['cant'] = 0;
        }
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('borrador_pedido_${widget.bodega.id}');

      final double subtotal = total / 1.18;
      final double igv = total - subtotal;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Pedido Registrado'),
            ],
          ),
          content: Text(
            'Pedido guardado exitosamente (Modo Offline).\n\n'
            'Subtotal: S/ ${subtotal.toStringAsFixed(2)}\n'
            'IGV (18%): S/ ${igv.toStringAsFixed(2)}\n'
            'Total: S/ ${total.toStringAsFixed(2)}\n\n'
            'Estado: Pendiente de sincronización.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) {
                  Navigator.pop(context); // Retorna a la cartera
                }
              },
              child: const Text('Volver al Dashboard'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error en _confirmarPedido: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error al guardar el pedido: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = _totalPedido / 1.18;
    final double igv = _totalPedido - subtotal;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido: ${widget.bodega.nombre}'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Resumen de crédito de la bodega
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RUC: ${widget.bodega.ruc}', style: const TextStyle(fontSize: 12)),
                    Text(
                      'Crédito Disponible: S/ ${widget.bodega.creditoDisponible.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.bodega.tieneCreditoCritico ? Colors.red : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    widget.bodega.tieneCreditoCritico ? 'Riesgo' : 'Normal',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: widget.bodega.tieneCreditoCritico ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),
          // Listado interactivo de productos
          Expanded(
            child: ListView.separated(
              itemCount: _catalogo.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final prod = _catalogo[index];
                return ListTile(
                  title: Text(prod['nombre'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('${prod['sku']} - S/ ${(prod['precio'] as double).toStringAsFixed(2)} c/u'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          if (prod['cant'] > 0) {
                            setState(() => prod['cant']--);
                          }
                        },
                      ),
                      Text('${prod['cant']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => setState(() => prod['cant']++),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Panel de Totales y Liquidación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Base Imponible:'),
                    Text('S/ ${subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('IGV (18%):'),
                    Text('S/ ${igv.toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total a Facturar:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'S/ ${_totalPedido.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Confirmar Pre-Venta'),
                    onPressed: _confirmarPedido,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}