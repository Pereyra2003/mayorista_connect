import 'package:flutter/material.dart';
import 'domain/bodega_model.dart';
import 'presentation/pedido_screen.dart';
import 'presentation/login_screen.dart';
import 'presentation/historial_screen.dart';
import 'data/pedido_repository.dart';
import 'data/bodega_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool('tema_oscuro') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MayoristaConnectApp());
}

class MayoristaConnectApp extends StatelessWidget {
  const MayoristaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'MayoristaConnect Piura',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              primary: const Color(0xFF0D47A1),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              primary: const Color(0xFF0D47A1),
              brightness: Brightness.dark,
            ),
          ),
          themeMode: currentMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}

class DashboardPreventaScreen extends StatefulWidget {
  const DashboardPreventaScreen({super.key});

  @override
  State<DashboardPreventaScreen> createState() => _DashboardPreventaScreenState();
}

class _DashboardPreventaScreenState extends State<DashboardPreventaScreen> {
  int _pendientes = 0;
  bool _isOnline = false;
  List<Bodega> _bodegasRuta = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final pendientes = await PedidoRepository.instance.obtenerCantidadPendientes();
    final bodegas = await BodegaRepository.instance.obtenerBodegas();
    if (mounted) {
      setState(() {
        _pendientes = pendientes;
        _bodegasRuta = bodegas;
      });
    }
  }

  Future<void> _sincronizar() async {
    if (_pendientes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay pedidos pendientes de sincronizar.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizando con Firestore (Simulación)...')),
    );

    await PedidoRepository.instance.sincronizarPedidosPendientes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronización completada exitosamente.'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MayoristaConnect Piura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Ruta Preventa: Mercado Modelo / Piura Centro', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(themeNotifier.value == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'Alternar Tema',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final isDark = themeNotifier.value == ThemeMode.dark;
              await prefs.setBool('tema_oscuro', !isDark);
              themeNotifier.value = !isDark ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          IconButton(
            icon: Icon(_isOnline ? Icons.cloud_done : Icons.cloud_off),
            tooltip: 'Alternar Conexión',
            onPressed: () {
              setState(() {
                _isOnline = !_isOnline;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar ahora',
            onPressed: _sincronizar,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long),
                tooltip: 'Historial de Pedidos',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistorialScreen()),
                  );
                  _cargarDatos();
                },
              ),
              if (_pendientes > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_pendientes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green.shade100 : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isOnline ? Colors.green.shade700 : Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.wifi : Icons.wifi_off,
                    color: _isOnline ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isOnline
                          ? 'Modo Online Activo: Conectado al Servidor Central.'
                          : 'Modo Offline Activo: Los pedidos se guardarán localmente.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Cartera de Bodegas en Ruta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _bodegasRuta.length,
                itemBuilder: (context, index) {
                  final bodega = _bodegasRuta[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PedidoScreen(bodega: bodega)),
                        );
                        _cargarDatos();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${bodega.nombre} (${bodega.ruc})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: bodega.tieneCreditoCritico ? Colors.red.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: bodega.tieneCreditoCritico ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  child: Text(
                                    bodega.tieneCreditoCritico ? 'Crédito Crítico' : 'Al día',
                                    style: TextStyle(
                                      color: bodega.tieneCreditoCritico ? Colors.red.shade800 : Colors.green.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(bodega.direccion, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Línea: S/ ${bodega.limiteCredito.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                Text(
                                  'Disponible: S/ ${bodega.creditoDisponible.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bodegasRuta.isEmpty ? null : _mostrarSelectorBodegas,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Tomar Pedido'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _mostrarSelectorBodegas() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Seleccione una Bodega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _bodegasRuta.length,
                itemBuilder: (ctx, i) {
                  final bodega = _bodegasRuta[i];
                  return ListTile(
                    leading: const Icon(Icons.storefront, color: Color(0xFF0D47A1)),
                    title: Text(bodega.nombre),
                    subtitle: Text(bodega.ruc),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PedidoScreen(bodega: bodega)),
                      );
                      _cargarDatos();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
