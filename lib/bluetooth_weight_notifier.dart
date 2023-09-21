import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothWeightNotifier extends ChangeNotifier {
  BluetoothConnection? _connection;
  double _weight = 0.0;
  BluetoothDevice? _connectedDevice;
  String? _connectedDeviceName; // Nueva propiedad para almacenar el nombre del dispositivo
  String? _connectedDeviceAddress; // Nueva propiedad para almacenar la dirección MAC del dispositivo

  BluetoothConnection? get connection => _connection;
  double get weight => _weight;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get connectedDeviceName => _connectedDeviceName; // Propiedad para el nombre del dispositivo
  String? get connectedDeviceAddress => _connectedDeviceAddress; // Propiedad para la dirección MAC del dispositivo
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

  Future<void> connectToDevice(String address) async {
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
      _connectedDeviceName = device.name; // Almacena el nombre del dispositivo
      _connectedDeviceAddress = device.address; // Almacena la dirección MAC del dispositivo
      print('Conectado a ${device.name}');
      notifyListeners();
    } catch (ex) {
      print('No se pudo conectar al dispositivo: $ex');
    }
  }

  // Método para desconectar el dispositivo Bluetooth
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
