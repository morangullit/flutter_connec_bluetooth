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

  BluetoothConnection? get connection => _connection;
  double get weight => _weight;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  bool get isConnected => _connection != null && _connection!.isConnected;

  final StreamController<double> _weightStreamController = StreamController<double>.broadcast();
  Stream<double> get weightStream => _weightStreamController.stream;

  Future<List<BluetoothDevice>> scanForDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (ex) {
      print('Error al escanear dispositivos Bluetooth: $ex');
      return [];
    }
  }

  void _datareceives (Uint8List data){
    List<int> buffer = [];
     for (int byte in data) {
          if (byte == 8 || byte == 127) {
            if (buffer.isNotEmpty) {
              buffer.removeLast();
            }
          } else {
            buffer.add(byte);
          }
        }

        final regExp = RegExp(r'([0-9]+.[0-9]+)kg');
        String dataString = String.fromCharCodes(buffer);

        final match = regExp.firstMatch(dataString);

        if (match != null) {
          final weightValue = match.group(1);
          final newWeight = double.tryParse(weightValue!);

          if (newWeight != null) {
            updateWeight(newWeight);
            
          }
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
      _connection = await BluetoothConnection.toAddress(address);
      _connectedDevice = device;
      _connectedDeviceName = device.name;
      _connectedDeviceAddress = device.address;
      print('Conectado a ${device.name}');

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
    final formattedWeight = newWeight.toStringAsFixed(2);
    final formattedWeightWithZero = formattedWeight.endsWith(".00")
      ? formattedWeight
      : "${formattedWeight}0";
    _weight = double.parse(formattedWeightWithZero);
    _weight = newWeight;
    _weightStreamController.sink.add(newWeight);
    notifyListeners();
    print('Nuevo Peso: $newWeight');
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
