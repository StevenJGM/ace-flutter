class Registro {
  String dia;
  DateTime fecha;
  String lugarTrabajo;
  String ciudad;
  String cliente;
  String detalle;
  String ticket; // <-- Agregado
  String desde;
  String hasta;
  double totalHoras;
  double horasExtras;
  double horas50;
  double horas100;

  Registro({
    required this.dia,
    required this.fecha,
    required this.lugarTrabajo,
    required this.ciudad,
    required this.cliente,
    required this.detalle,
    required this.ticket, // <-- Agregado
    required this.desde,
    required this.hasta,
    required this.totalHoras,
    required this.horasExtras,
    required this.horas50,
    required this.horas100,
  });

  // -------------------- Convertir a JSON --------------------
  Map<String, dynamic> toJson() => {
        'dia': dia,
        'fecha': fecha.toIso8601String(),
        'lugarTrabajo': lugarTrabajo,
        'ciudad': ciudad,
        'cliente': cliente,
        'detalle': detalle,
        'ticket': ticket, // <-- Agregado
        'desde': desde,
        'hasta': hasta,
        'totalHoras': totalHoras,
        'horasExtras': horasExtras,
        'horas50': horas50,
        'horas100': horas100,
      };

  // -------------------- Crear desde JSON --------------------
  factory Registro.fromJson(Map<String, dynamic> json) => Registro(
        dia: json['dia'],
        fecha: DateTime.parse(json['fecha']),
        lugarTrabajo: json['lugarTrabajo'],
        ciudad: json['ciudad'],
        cliente: json['cliente'],
        detalle: json['detalle'],
        ticket: json['ticket'], // <-- Agregado
        desde: json['desde'],
        hasta: json['hasta'],
        totalHoras: (json['totalHoras'] as num).toDouble(),
        horasExtras: (json['horasExtras'] as num).toDouble(),
        horas50: (json['horas50'] as num).toDouble(),
        horas100: (json['horas100'] as num).toDouble(),
      );
}
