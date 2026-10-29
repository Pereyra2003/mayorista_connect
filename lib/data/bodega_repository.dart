import '../domain/bodega_model.dart';

class BodegaRepository {
  static final BodegaRepository instance = BodegaRepository._init();
  BodegaRepository._init();

  final List<Bodega> _bodegas = [
    Bodega(
      id: 'B01',
      nombre: 'Bodega San Martín',
      ruc: '10458796321',
      direccion: 'Av. Sánchez Cerro #412',
      limiteCredito: 2500.0,
      saldoDeudor: 350.0,
    ),
    Bodega(
      id: 'B02',
      nombre: 'Minimarket Don Pedro',
      ruc: '20601234567',
      direccion: 'Calle Tacna #820 - Piura Centro',
      limiteCredito: 5000.0,
      saldoDeudor: 4800.0,
    ),
    Bodega(
      id: 'B03',
      nombre: 'Comercializadora El Sol',
      ruc: '10784512369',
      direccion: 'Jr. Huánuco #105',
      limiteCredito: 1800.0,
      saldoDeudor: 0.0,
    ),
  ];

  Future<List<Bodega>> obtenerBodegas() async {
    return _bodegas;
  }

  Future<void> actualizarSaldo(String bodegaId, double montoPedido) async {
    final index = _bodegas.indexWhere((b) => b.id == bodegaId);
    if (index != -1) {
      final bodegaAnterior = _bodegas[index];
      // Actualizamos el saldo deudor sumando el monto del pedido
      final nuevoSaldo = bodegaAnterior.saldoDeudor + montoPedido;
      
      _bodegas[index] = Bodega(
        id: bodegaAnterior.id,
        nombre: bodegaAnterior.nombre,
        ruc: bodegaAnterior.ruc,
        direccion: bodegaAnterior.direccion,
        limiteCredito: bodegaAnterior.limiteCredito,
        saldoDeudor: nuevoSaldo,
      );
    }
  }
}