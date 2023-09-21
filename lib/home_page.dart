import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'bluetooth_weight_notifier.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BluetoothWeightNotifier bluetoothNotifier = Provider.of<BluetoothWeightNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Weight Reader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (bluetoothNotifier.isConnected)
              Text('Conectado a: ${bluetoothNotifier.connectedDeviceName ?? "Dispositivo desconocido"}'),
            Text('Dirección MAC: ${bluetoothNotifier.connectedDeviceAddress ?? "Desconocida"}'),
            SizedBox(height: 20),
            WeightDisplay(bluetoothNotifier: bluetoothNotifier),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!bluetoothNotifier.isConnected) {
            List<BluetoothDevice> devices = await bluetoothNotifier.scanForDevices();
            if (devices.isNotEmpty) {
              // Mostrar el diálogo con la lista de dispositivos disponibles.
              _showDeviceSelectionDialog(context, devices, bluetoothNotifier);
            } else {
              print('No se encontraron dispositivos Bluetooth disponibles.');
            }
          } else {
            // Si ya está conectado, mostrar el diálogo de desconexión.
            _showDisconnectDialog(context, bluetoothNotifier);
          }
        },
        child: Icon(bluetoothNotifier.isConnected ? Icons.bluetooth_disabled : Icons.bluetooth),
      ),
    );
  }

  // Método para mostrar el diálogo de selección de dispositivo.
  Future<void> _showDeviceSelectionDialog(BuildContext context, List<BluetoothDevice> devices, BluetoothWeightNotifier bluetoothNotifier) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecciona un dispositivo Bluetooth'),
          content: SingleChildScrollView(
            child: ListBody(
              children: devices.map((device) {
                return ListTile(
                  title: Text(device.name ?? 'Dispositivo desconocido'),
                  subtitle: Text(device.address),
                  onTap: () {
                    // Cuando se selecciona un dispositivo, lo conectamos.
                    bluetoothNotifier.connectToDevice(device.address);
                    Navigator.of(context).pop(); // Cierra el diálogo.
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Método para mostrar el diálogo de desconexión.
  Future<void> _showDisconnectDialog(BuildContext context, BluetoothWeightNotifier bluetoothNotifier) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Desconectar dispositivo'),
          content: ListTile(
            title: Text('Conectado a: ${bluetoothNotifier.connectedDeviceName ?? "Dispositivo desconocido"}'),
            subtitle: Text('Dirección MAC: ${bluetoothNotifier.connectedDeviceAddress ?? "Desconocida"}'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo sin desconectar.
              },
            ),
            TextButton(
              child: Text('Desconectar'),
              onPressed: () {
                bluetoothNotifier.disconnectDevice(); // Método para desconectar en BluetoothWeightNotifier.
                Navigator.of(context).pop(); // Cierra el diálogo después de desconectar.
              },
            ),
          ],
        );
      },
    );
  }
}

class WeightDisplay extends StatelessWidget {
  final BluetoothWeightNotifier bluetoothNotifier;

  WeightDisplay({required this.bluetoothNotifier});

  @override
  Widget build(BuildContext context) {
    double weight = bluetoothNotifier.weight;
    return Text('Peso: $weight');
  }
}
