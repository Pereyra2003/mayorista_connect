import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class PedidoRepository {
  static final PedidoRepository instance = PedidoRepository._init();
  PedidoRepository._init();

  // Fallback en memoria si falla SQLite (ej. en Web)
  final List<Map<String, dynamic>> _memoryCache = [];

  Future<void> insertarPedido(Map<String, dynamic> pedido) async {
    try {
      if (kIsWeb) {
        // En Web, SQLite no es compatible nativamente con sqflite, usamos la memoria.
        _memoryCache.insert(0, {...pedido, 'id': DateTime.now().millisecondsSinceEpoch});
        return;
      }
      await DatabaseHelper.instance.insertarPedido(pedido);
    } catch (e) {
      debugPrint('Error al guardar en SQLite, usando fallback en memoria: $e');
      _memoryCache.insert(0, {...pedido, 'id': DateTime.now().millisecondsSinceEpoch});
    }
  }

  Future<void> actualizarPedido(int id, double nuevoTotal) async {
    try {
      if (kIsWeb) {
        final index = _memoryCache.indexWhere((p) => p['id'] == id);
        if (index != -1) {
          _memoryCache[index]['total'] = nuevoTotal;
        }
        return;
      }
      await DatabaseHelper.instance.actualizarPedido(id, nuevoTotal);
    } catch (e) {
      debugPrint('Error al actualizar en SQLite, usando fallback en memoria: $e');
      final index = _memoryCache.indexWhere((p) => p['id'] == id);
      if (index != -1) {
        _memoryCache[index]['total'] = nuevoTotal;
      }
    }
  }

  Future<void> eliminarPedido(int id) async {
    try {
      if (kIsWeb) {
        _memoryCache.removeWhere((p) => p['id'] == id);
        return;
      }
      await DatabaseHelper.instance.eliminarPedido(id);
    } catch (e) {
      debugPrint('Error al eliminar en SQLite, usando fallback en memoria: $e');
      _memoryCache.removeWhere((p) => p['id'] == id);
    }
  }

  Future<List<Map<String, dynamic>>> obtenerPedidos() async {
    try {
      if (kIsWeb) {
        return _memoryCache;
      }
      return await DatabaseHelper.instance.obtenerPedidos();
    } catch (e) {
      debugPrint('Error al leer de SQLite, usando fallback en memoria: $e');
      return _memoryCache;
    }
  }

  Future<int> obtenerCantidadPendientes() async {
    final pedidos = await obtenerPedidos();
    return pedidos.where((p) => p['sincronizado'] == 0).length;
  }

  Future<void> sincronizarPedidosPendientes() async {
    try {
      // Simula el tiempo de red para subir a Firestore/Cloud Functions
      await Future.delayed(const Duration(seconds: 2));

      if (kIsWeb) {
        for (var i = 0; i < _memoryCache.length; i++) {
          if (_memoryCache[i]['sincronizado'] == 0) {
            _memoryCache[i]['sincronizado'] = 1;
          }
        }
        return;
      }
      
      await DatabaseHelper.instance.marcarComoSincronizados();
    } catch (e) {
      debugPrint('Error al sincronizar con SQLite: $e');
      // Fallback: actualizamos la memoria local
      for (var i = 0; i < _memoryCache.length; i++) {
        if (_memoryCache[i]['sincronizado'] == 0) {
          _memoryCache[i]['sincronizado'] = 1;
        }
      }
    }
  }
}
