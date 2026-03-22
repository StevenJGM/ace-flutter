import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'models/registro.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RegistroPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final List<Registro> registros = [];

  final ticketCtrl = TextEditingController(); // <-- Nuevo campo Ticket
  final lugarTrabajoCtrl = TextEditingController();
  final ciudadCtrl = TextEditingController();
  final detalleCtrl = TextEditingController();

  final List<String> clientes = ['BG', 'BP', 'AGLAR'];
  String clienteSeleccionado = 'BG';

  final List<String> diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];
  String diaSeleccionado = 'Lunes';

  int desdeHora = 8;
  String desdeMinuto = ":30";
  int hastaHora = 17;
  String hastaMinuto = ":30";

  final List<int> horas = List.generate(24, (i) => i);
  final List<String> minutos = List.generate(
      60, (i) => ":${i.toString().padLeft(2, '0')}"); // <-- Todos los minutos

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  // -------------------- PERSISTENCIA JSON --------------------
  Future<String> get _localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/registros.json');
  }

  Future<void> guardarRegistros() async {
    final file = await _localFile;
    List<Map<String, dynamic>> jsonList =
        registros.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<void> cargarRegistros() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return;
      final jsonString = await file.readAsString();
      final List jsonList = jsonDecode(jsonString);
      setState(() {
        registros
            .addAll(jsonList.map((item) => Registro.fromJson(item)).toList());
      });
    } catch (e) {
      // Error al cargar registros
    }
  }
  // -------------------------------------------------------------

  Map<String, double> calcularHoras(
      String dia, DateTime desde, DateTime hasta) {
    double horas50 = 0;
    double horas100 = 0;
    const inicioNormal = 8;
    const inicioMin = 30;
    const finNormal = 17;
    const finMin = 30;

    DateTime inicio =
        DateTime(desde.year, desde.month, desde.day, inicioNormal, inicioMin);
    DateTime fin =
        DateTime(hasta.year, hasta.month, hasta.day, finNormal, finMin);

    double totalHoras = hasta.difference(desde).inMinutes / 60.0;

    if (dia == 'Sábado' || dia == 'Domingo') {
      horas100 = totalHoras;
    } else {
      if (desde.isBefore(inicio)) {
        horas50 += inicio.difference(desde).inMinutes / 60.0;
      }
      if (hasta.isAfter(fin)) {
        horas50 += hasta.difference(fin).inMinutes / 60.0;
      }
    }
    return {'50': horas50, '100': horas100};
  }

  void agregarRegistro() async {
    if (ticketCtrl.text.isEmpty ||
        lugarTrabajoCtrl.text.isEmpty ||
        ciudadCtrl.text.isEmpty ||
        detalleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    // Validar que Ticket solo tenga números
    if (!RegExp(r'^\d+$').hasMatch(ticketCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket solo puede contener números')),
      );
      return;
    }

    final now = DateTime.now();
    final desde = DateTime(now.year, now.month, now.day, desdeHora,
        int.parse(desdeMinuto.substring(1)));
    final hasta = DateTime(now.year, now.month, now.day, hastaHora,
        int.parse(hastaMinuto.substring(1)));

    final totalHoras = hasta.difference(desde).inMinutes / 60.0;
    final horasMap = calcularHoras(diaSeleccionado, desde, hasta);

    final registro = Registro(
      dia: diaSeleccionado,
      fecha: now,
      ticket: ticketCtrl.text, // <-- Guardamos Ticket
      lugarTrabajo: lugarTrabajoCtrl.text,
      ciudad: ciudadCtrl.text,
      cliente: clienteSeleccionado,
      detalle: detalleCtrl.text,
      desde: "${desdeHora.toString().padLeft(2, '0')}${desdeMinuto}",
      hasta: "${hastaHora.toString().padLeft(2, '0')}${hastaMinuto}",
      totalHoras: totalHoras,
      horasExtras: 0,
      horas50: horasMap['50']!,
      horas100: horasMap['100']!,
    );

    setState(() {
      registros.add(registro);
      ticketCtrl.clear();
      lugarTrabajoCtrl.clear();
      ciudadCtrl.clear();
      detalleCtrl.clear();
      diaSeleccionado = 'Lunes';
      clienteSeleccionado = 'BG';
      desdeHora = 8;
      desdeMinuto = ":30";
      hastaHora = 17;
      hastaMinuto = ":30";
    });

    await guardarRegistros();
  }

  // -------------------- Generar Excel --------------------
  Future<void> generarExcel() async {
    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para generar Excel')),
      );
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel['Registros'];

    // Columnas: Ticket primero, luego resto
    sheet.appendRow([
      TextCellValue('Ticket'),
      TextCellValue('Día'),
      TextCellValue('Fecha'),
      TextCellValue('Lugar de trabajo'),
      TextCellValue('Ciudad'),
      TextCellValue('Cliente'),
      TextCellValue('Detalle'),
      TextCellValue('Desde'),
      TextCellValue('Hasta'),
      TextCellValue('Horas 50%'),
      TextCellValue('Horas 100%'),
      TextCellValue('Total de Horas'),
    ]);

    for (var r in registros) {
      sheet.appendRow([
        TextCellValue(r.ticket),
        TextCellValue(r.dia),
        TextCellValue("${r.fecha.day}/${r.fecha.month}/${r.fecha.year}"),
        TextCellValue(r.lugarTrabajo),
        TextCellValue(r.ciudad),
        TextCellValue(r.cliente),
        TextCellValue(r.detalle),
        TextCellValue(r.desde),
        TextCellValue(r.hasta),
        DoubleCellValue(r.horas50),
        DoubleCellValue(r.horas100),
        DoubleCellValue(r.totalHoras),
      ]);
    }

    Directory docDir = Directory("/storage/emulated/0/Documents");
    if (!await docDir.exists()) await docDir.create(recursive: true);

    final filePath = "${docDir.path}/registro.xlsx";
    final file = File(filePath);

    final bytes = excel.encode();
    if (bytes == null) return;

    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archivo Excel guardado en: $filePath')),
    );
  }

  Future<void> borrarRegistros() async {
    final file = await _localFile;

    setState(() {
      registros.clear();
    });

    if (await file.exists()) await file.writeAsString('[]');

    Directory docDir = Directory("/storage/emulated/0/Documents");
    final filePath = "${docDir.path}/registro.xlsx";
    final excelFile = File(filePath);
    if (await excelFile.exists()) await excelFile.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todos los registros han sido borrados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Diario")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ticketCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Ticket"),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Día: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: diaSeleccionado,
                  items: diasSemana
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => diaSeleccionado = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lugarTrabajoCtrl,
              decoration: const InputDecoration(labelText: "Lugar de trabajo"),
            ),
            TextField(
              controller: ciudadCtrl,
              decoration: const InputDecoration(labelText: "Ciudad"),
            ),
            Row(
              children: [
                const Text('Cliente: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: clienteSeleccionado,
                  items: clientes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => clienteSeleccionado = v);
                  },
                ),
              ],
            ),
            TextField(
              controller: detalleCtrl,
              decoration: const InputDecoration(labelText: "Detalle"),
            ),
            const SizedBox(height: 10),
            // ---------------- Selector de Horas ----------------
            Row(
              children: [
                const Text("Desde: "),
                DropdownButton<int>(
                  value: desdeHora,
                  items: horas
                      .map((h) => DropdownMenuItem(
                          value: h, child: Text(h.toString().padLeft(2, '0'))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => desdeHora = v);
                  },
                ),
                DropdownButton<String>(
                  value: desdeMinuto,
                  items: minutos
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => desdeMinuto = v);
                  },
                ),
                const SizedBox(width: 20),
                const Text("Hasta: "),
                DropdownButton<int>(
                  value: hastaHora,
                  items: horas
                      .map((h) => DropdownMenuItem(
                          value: h, child: Text(h.toString().padLeft(2, '0'))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => hastaHora = v);
                  },
                ),
                DropdownButton<String>(
                  value: hastaMinuto,
                  items: minutos
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => hastaMinuto = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: agregarRegistro,
              child: const Text("Agregar"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: generarExcel,
              child: const Text("Generar Excel"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: borrarRegistros,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Borrar registros"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: registros.length,
                itemBuilder: (context, index) {
                  final r = registros[index];
                  return ListTile(
                    title: Text(
                        "Ticket: ${r.ticket} - ${r.lugarTrabajo} - ${r.cliente} - Total: ${r.totalHoras}h"),
                    subtitle: Text(
                        "Ticket: ${r.ticket} | ${r.dia} | ${r.fecha.day}/${r.fecha.month}/${r.fecha.year} | ${r.ciudad} | ${r.detalle} | Desde: ${r.desde} | Hasta: ${r.hasta} | Horas 50%: ${r.horas50} | Horas 100%: ${r.horas100}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
