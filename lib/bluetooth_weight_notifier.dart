import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothWeightNotifier extends ChangeNotifier {
  BluetoothConnection? _connection;
  double _weight = 0.0;
  BluetoothDevice? _connectedDevice;
  String? _connectedDeviceName;
  String? _connectedDeviceAddress;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  BluetoothConnection? get connection => _connection;
  double get weight => _weight;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  bool get isConnected => _connection != null && _connection!.isConnected;
  List<double> weightHistory = [];

  final StreamController<double> _weightStreamController = StreamController<double>.broadcast();
  Stream<double> get weightStream => _weightStreamController.stream;

  Future<List<BluetoothDevice>> scanForDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (ex) {
      //print('Error al escanear dispositivos Bluetooth: $ex');
      return [];
    }
  }

String _buffer = "";

void _datareceives(Uint8List data) {
  _buffer += String.fromCharCodes(data);
  
  final lines = _buffer.split("\n");
  
  for (var line in lines) {
    final regExp = RegExp(r'([0-9]+.[0-9]+)kg');
    final match = regExp.firstMatch(line);

    if (match != null) {
      final weightValue = match.group(1);
      final newWeight = double.tryParse(weightValue!);

      if (newWeight != null) {
        updateWeight(newWeight);
      }
    }
  }

  // Mantener cualquier fragmento de línea incompleta en el buffer
  if (lines.isNotEmpty) {
    _buffer = lines.last;
  } else {
    _buffer = "";
  }
}

  void startReadingData() {
    if (_connection != null && _connection!.isConnected) {
      _connection!.input!.listen(_datareceives).onDone(() { });
    }
  }

  void connectToDevice(String address) async {
    if (_connection != null && _connection!.isConnected) {
      _connection!.dispose();
    }

    BluetoothDevice device = BluetoothDevice(
      address: address,
      type: BluetoothDeviceType.unknown,
      isConnected: false,
      bondState: BluetoothBondState.unknown,
    );

    try {
      _isConnecting = true;
      notifyListeners();

      _connection = await BluetoothConnection.toAddress(address);
      _connectedDevice = device;
      _connectedDeviceName = device.name;
      _connectedDeviceAddress = device.address;
      //print('Conectado a ${device.name}');

      startReadingData();
      _isConnecting = false;
      notifyListeners();
    } catch (ex) {
      _isConnecting = false;
      notifyListeners();
      //print('No se pudo conectar al dispositivo: $ex');
    }
  }

  void disconnectDevice() {
    if (_connection != null && _connection!.isConnected) {
      _connection!.dispose();
      _connection = null;
      _connectedDevice = null;
      _connectedDeviceName = null;
      _connectedDeviceAddress = null;
      //print('Dispositivo desconectado');
      notifyListeners();
    }
  }

  void updateWeight(double newWeight) {
    final formattedWeight = newWeight.toStringAsFixed(2);
    final formattedWeightWithZero = formattedWeight.endsWith(".00")
      ? formattedWeight
      : "${formattedWeight}0";
    _weight = double.parse(formattedWeightWithZero);
    _weight = newWeight;
    _weightStreamController.sink.add(newWeight);
    notifyListeners();
    //print('Nuevo Peso: $newWeight');
  }

  void captureWeight(double weight) {
    weightHistory.add(weight);
    notifyListeners();
  }

  @override
  void dispose() {
    if (_connection != null) {
      _connection!.dispose();
    }
    _weightStreamController.close(); // Cerrar el StreamController.
    super.dispose();
  }
}
