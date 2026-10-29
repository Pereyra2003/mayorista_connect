class Bodega {
  final String id;
  final String nombre;
  final String ruc;
  final String direccion;
  final double limiteCredito;
  final double saldoDeudor;

  const Bodega({
    required this.id,
    required this.nombre,
    required this.ruc,
    required this.direccion,
    required this.limiteCredito,
    required this.saldoDeudor,
  });

  double get creditoDisponible => limiteCredito - saldoDeudor;
  bool get tieneCreditoCritico => creditoDisponible <= (limiteCredito * 0.10);
}