// models/registro.dart
class Registro {
  final String dia;
  final DateTime fecha;
  final String lugarTrabajo;
  final String ciudad;
  final String cliente;
  final String detalle;
  final String desde;
  final String hasta;
  final double totalHoras;
  final int horasExtras;

  Registro({
    required this.dia,
    required this.fecha,
    required this.lugarTrabajo,
    required this.ciudad,
    required this.cliente,
    required this.detalle,
    required this.desde,
    required this.hasta,
    required this.totalHoras,
    required this.horasExtras,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
        "dia": dia,
        "fecha": fecha.toIso8601String(),
        "lugarTrabajo": lugarTrabajo,
        "ciudad": ciudad,
        "cliente": cliente,
        "detalle": detalle,
        "desde": desde,
        "hasta": hasta,
        "totalHoras": totalHoras,
        "horasExtras": horasExtras,
      };

  // Crear objeto desde JSON
  factory Registro.fromJson(Map<String, dynamic> json) => Registro(
        dia: json["dia"],
        fecha: DateTime.parse(json["fecha"]),
        lugarTrabajo: json["lugarTrabajo"],
        ciudad: json["ciudad"],
        cliente: json["cliente"],
        detalle: json["detalle"],
        desde: json["desde"],
        hasta: json["hasta"],
        totalHoras: json["totalHoras"].toDouble(),
        horasExtras: json["horasExtras"],
      );
}
