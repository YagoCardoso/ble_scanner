import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() {
  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'BLE Scanner Plus', home: const BleScanScreen());
  }
}

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({Key? key}) : super(key: key);

  @override
  _BleScanScreenState createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? scanSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    // Aguarda 2 segundos para garantir que o Bluetooth esteja pronto
    await Future.delayed(const Duration(seconds: 2));
    _startScan();
  }

  Future<void> _requestPermissions() async {
    var statusLocation = await Permission.location.request();
    print("Location permission: $statusLocation");

    var statusBluetoothScan = await Permission.bluetoothScan.request();
    print("BluetoothScan permission: $statusBluetoothScan");

    var statusBluetoothConnect = await Permission.bluetoothConnect.request();
    print("BluetoothConnect permission: $statusBluetoothConnect");
  }

  // Função para converter o RSSI em uma estimativa de distância (em metros)
  double calculateDistance({
    required int rssi,
    int txPower = -59,
    double n = 2.0,
  }) {
    if (rssi == 0) return -1.0; // Indeterminado
    return pow(10, ((txPower - rssi) / (10 * n))).toDouble();
  }

  Future<void> _startScan() async {
    // Verifica o estado do Bluetooth (utilizando BluetoothAdapterState)
    final isOn = await FlutterBluePlus.state.firstWhere(
      (state) => state == BluetoothAdapterState.on,
      orElse: () => BluetoothAdapterState.off,
    );

    if (isOn != BluetoothAdapterState.on) {
      print("Bluetooth não está ligado: $isOn");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bluetooth não está ligado")),
      );
      return;
    }

    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      print("Erro ao iniciar scan: $e");
    }

    // Assina o stream de resultados
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      print("Dispositivos encontrados: ${results.length}");
      setState(() {
        scanResults = results;
      });
    });

    setState(() {
      isScanning = false;
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Scanner Plus"),
        actions: [
          isScanning
              ? IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () {
                  FlutterBluePlus.stopScan();
                  setState(() {
                    isScanning = false;
                  });
                },
              )
              : IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _startScan,
              ),
        ],
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(8.0), child: StatusRow()),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                final deviceName =
                    result.device.name.isNotEmpty
                        ? result.device.name
                        : 'Dispositivo sem nome';
                // Calcula a distância estimada a partir do RSSI
                double distance = calculateDistance(rssi: result.rssi);
                String distanceText =
                    (distance >= 0)
                        ? "${distance.toStringAsFixed(2)} mts"
                        : "N/A";
                return ListTile(
                  title: Text(deviceName),
                  subtitle: Text(result.device.id.toString()),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${result.rssi} dBm'),
                      Text("Dist: $distanceText"),
                    ],
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

class StatusRow extends StatefulWidget {
  const StatusRow({Key? key}) : super(key: key);

  @override
  _StatusRowState createState() => _StatusRowState();
}

class _StatusRowState extends State<StatusRow> {
  bool locationServiceEnabled = false;
  bool bluetoothScanGranted = false;
  bool bluetoothConnectGranted = false;

  @override
  void initState() {
    super.initState();
    _checkStatuses();
  }

  Future<void> _checkStatuses() async {
    var locStatus = await Permission.location.serviceStatus;
    var scanStatus = await Permission.bluetoothScan.status;
    var connectStatus = await Permission.bluetoothConnect.status;
    setState(() {
      locationServiceEnabled = locStatus == ServiceStatus.enabled;
      bluetoothScanGranted = scanStatus.isGranted;
      bluetoothConnectGranted = connectStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.state,
          initialData: BluetoothAdapterState.unknown,
          builder: (context, snapshot) {
            String bluetoothStatus =
                (snapshot.data == BluetoothAdapterState.on)
                    ? "ligado"
                    : "desligado";
            return Text(
              "Bluetooth: $bluetoothStatus",
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
        Text(
          "GPS: ${locationServiceEnabled ? "ligado" : "desligado"}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          "Permissão proximidade: ${(bluetoothScanGranted && bluetoothConnectGranted) ? "ligado" : "desligado"}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () {
            Phoenix.rebirth(context);
          },
          child: const Text("Reiniciar App"),
        ),
      ],
    );
  }
}
