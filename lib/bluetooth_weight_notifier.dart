import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothWeightNotifier extends ChangeNotifier {
  BluetoothConnection? _connection;
  double _weight = 0.0;
  BluetoothDevice? _connectedDevice;
  String? _connectedDeviceName;
  String? _connectedDeviceAddress;

  BluetoothConnection? get connection => _connection;
  double get weight => _weight;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  bool get isConnected => _connection != null && _connection!.isConnected;

  Future<List<BluetoothDevice>> scanForDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (ex) {
      print('Error al escanear dispositivos Bluetooth: $ex');
      return [];
    }
  }

  void startReadingData() {
    if (_connection != null && _connection!.isConnected) {
      List<int> buffer = [];
      _connection!.input!.listen((Uint8List data) {
        for (int byte in data) {
          if (byte == 8 || byte == 127) {
            // Manejo de retrocesos (backspaces)
            if (buffer.isNotEmpty) {
              buffer.removeLast();
            }
          } else {
            buffer.add(byte);
          }
        }

        String dataString = String.fromCharCodes(buffer);

        // Utiliza una expresión regular para extraer el valor del peso
        final regExp = RegExp(r'([0-9]+.[0-9]+)');
        final match = regExp.firstMatch(dataString);

        if (match != null) {
          final weightValue = match.group(0);
          final newWeight = double.tryParse(weightValue!);

          if (newWeight != null) {
            updateWeight(newWeight);
          }
        }
      });
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
      _connection = await BluetoothConnection.toAddress(address);
      _connectedDevice = device;
      _connectedDeviceName = device.name;
      _connectedDeviceAddress = device.address;
      print('Conectado a ${device.name}');

      // Inicia la lectura de datos desde el dispositivo Bluetooth después de conectarse.
      startReadingData();

      notifyListeners();
    } catch (ex) {
      print('No se pudo conectar al dispositivo: $ex');
    }
  }

  void disconnectDevice() {
    if (_connection != null && _connection!.isConnected) {
      _connection!.dispose();
      _connection = null;
      _connectedDevice = null;
      _connectedDeviceName = null;
      _connectedDeviceAddress = null;
      print('Dispositivo desconectado');
      notifyListeners();
    }
  }

  void updateWeight(double newWeight) {
    _weight = newWeight;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_connection != null) {
      _connection!.dispose();
    }
    super.dispose();
  }
}
