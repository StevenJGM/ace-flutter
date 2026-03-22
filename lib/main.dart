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

  final lugarTrabajoCtrl = TextEditingController();
  final ciudadCtrl = TextEditingController();
  final detalleCtrl = TextEditingController();

  // Horas Extras
  List<bool> seleccionHoras = List.generate(9, (_) => false);
  int horasExtrasSeleccionada = 1;

  // Cliente
  final List<String> clientes = ['BG', 'BP', 'AGLAR'];
  String clienteSeleccionado = 'BG';

  // Días de la semana
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

  // Horario Desde/Hasta
  int desdeHora = 8;
  String desdeMinuto = ":00";
  int hastaHora = 17;
  String hastaMinuto = ":00";

  final List<int> horas = List.generate(24, (i) => i);
  final List<String> minutos = [":00", ":30"];

  @override
  void initState() {
    super.initState();
    cargarRegistros();
    seleccionHoras[0] = true; // Inicializar la primera hora extra seleccionada
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
      // Error al cargar registros, no hacer nada
    }
  }
  // -------------------------------------------------------------

  double calcularTotalHoras() {
    final desdeDate =
        DateTime(0, 0, 0, desdeHora, int.parse(desdeMinuto.substring(1)));
    final hastaDate =
        DateTime(0, 0, 0, hastaHora, int.parse(hastaMinuto.substring(1)));
    final diff = hastaDate.difference(desdeDate).inMinutes;
    return diff / 60.0;
  }

  void agregarRegistro() {
    if (lugarTrabajoCtrl.text.isEmpty ||
        ciudadCtrl.text.isEmpty ||
        detalleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final totalHoras = calcularTotalHoras();

    final registro = Registro(
      dia: diaSeleccionado,
      fecha: DateTime.now(),
      lugarTrabajo: lugarTrabajoCtrl.text,
      ciudad: ciudadCtrl.text,
      cliente: clienteSeleccionado,
      detalle: detalleCtrl.text,
      desde: "${desdeHora.toString().padLeft(2, '0')}${desdeMinuto}",
      hasta: "${hastaHora.toString().padLeft(2, '0')}${hastaMinuto}",
      totalHoras: totalHoras,
      horasExtras: horasExtrasSeleccionada,
    );

    setState(() {
      registros.add(registro);
      lugarTrabajoCtrl.clear();
      ciudadCtrl.clear();
      detalleCtrl.clear();
      seleccionHoras = List.generate(9, (_) => false);
      horasExtrasSeleccionada = 1;
      seleccionHoras[0] = true;
      clienteSeleccionado = 'BG';
      diaSeleccionado = 'Lunes';
      desdeHora = 8;
      desdeMinuto = ":00";
      hastaHora = 17;
      hastaMinuto = ":00";
    });

    guardarRegistros(); // Guardar automáticamente
  }

  Future<void> generarExcel() async {
    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para generar Excel')),
      );
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel['Registros'];

    // Encabezado reordenado
    sheet.appendRow([
      TextCellValue('Día'),
      TextCellValue('Fecha'),
      TextCellValue('Lugar de trabajo'),
      TextCellValue('Ciudad'),
      TextCellValue('Cliente'),
      TextCellValue('Detalle'),
      TextCellValue('Desde'),
      TextCellValue('Hasta'),
      TextCellValue('Total de Horas'),
      TextCellValue('Horas Extras'),
    ]);

    for (var r in registros) {
      sheet.appendRow([
        TextCellValue(r.dia),
        TextCellValue("${r.fecha.day}/${r.fecha.month}/${r.fecha.year}"),
        TextCellValue(r.lugarTrabajo),
        TextCellValue(r.ciudad),
        TextCellValue(r.cliente),
        TextCellValue(r.detalle),
        TextCellValue(r.desde),
        TextCellValue(r.hasta),
        DoubleCellValue(r.totalHoras),
        IntCellValue(r.horasExtras),
      ]);
    }

    Directory? baseDir = await getExternalStorageDirectory();
    if (baseDir == null) return;

    String docPath = baseDir.path.split('Android')[0] + 'Documents';
    final docDir = Directory(docPath);
    if (!await docDir.exists()) await docDir.create(recursive: true);

    final filePath = "${docDir.path}/registros.xlsx";
    final file = File(filePath);

    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archivo guardado en: $filePath')),
    );
  }

  // -------------------- NUEVA FUNCION: BORRAR REGISTROS --------------------
  Future<void> borrarRegistros() async {
    final file = await _localFile;

    setState(() {
      registros.clear();
    });

    if (await file.exists()) {
      await file.writeAsString('[]');
    }

    // Eliminar Excel si existe
    Directory? baseDir = await getExternalStorageDirectory();
    if (baseDir != null) {
      String docPath = baseDir.path.split('Android')[0] + 'Documents';
      final filePath = "$docPath/registros.xlsx";
      final excelFile = File(filePath);
      if (await excelFile.exists()) {
        await excelFile.delete();
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todos los registros han sido borrados')),
    );
  }
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Diario")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            const SizedBox(height: 10),
            const Text('Horas Extras',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ToggleButtons(
              children: List.generate(
                  9,
                  (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${i + 1}'),
                      )),
              isSelected: seleccionHoras,
              onPressed: (i) {
                setState(() {
                  for (int j = 0; j < seleccionHoras.length; j++) {
                    seleccionHoras[j] = j == i;
                  }
                  horasExtrasSeleccionada = i + 1;
                });
              },
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
                        "${r.lugarTrabajo} - ${r.cliente} - Total: ${r.totalHoras}h"),
                    subtitle: Text(
                        "${r.dia} | ${r.fecha.day}/${r.fecha.month}/${r.fecha.year} | ${r.ciudad} | ${r.detalle} | Desde: ${r.desde} | Hasta: ${r.hasta} | Horas Extras: ${r.horasExtras}"),
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
