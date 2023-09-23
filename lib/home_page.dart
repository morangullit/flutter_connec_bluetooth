import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'bluetooth_weight_notifier.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Weight Reader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Consumer<BluetoothWeightNotifier>(
              builder: (context, bluetoothNotifier, child) {
                return Column(
                  children: <Widget>[
                    if (bluetoothNotifier.isConnected)
                      Text('Conectado a: ${bluetoothNotifier.connectedDeviceName ?? "Dispositivo desconocido"}'),
                      if (bluetoothNotifier.isConnecting)
                      const Text('Conectando al dispositivo...'),
                    Text('Dirección MAC: ${bluetoothNotifier.connectedDeviceAddress ?? "Desconocida"}'),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const WeightDisplay(),
            const SizedBox(height: 200),
            const Expanded(
              child: WeightHistoryList(), // Permitir hacer scroll en el historial de pesos.
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<BluetoothWeightNotifier>(
        builder: (context, bluetoothNotifier, child) {
          return FloatingActionButton(
            onPressed: () async {
              if (!bluetoothNotifier.isConnected) {
                List<BluetoothDevice> devices = await bluetoothNotifier.scanForDevices();
                if (devices.isNotEmpty) {
                  _showDeviceSelectionDialog(context, devices, bluetoothNotifier);
                } else {
                  print('No se encontraron dispositivos Bluetooth disponibles.');
                }
              } else {
                _showDisconnectDialog(context, bluetoothNotifier);
              }
            },
            child: Icon(bluetoothNotifier.isConnected ? Icons.bluetooth_disabled : Icons.bluetooth),
          );
        },
      ),
    );
  }

  Future<void> _showDeviceSelectionDialog(BuildContext context, List<BluetoothDevice> devices, BluetoothWeightNotifier bluetoothNotifier) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un dispositivo Bluetooth'),
          content: SingleChildScrollView(
            child: ListBody(
              children: devices.map((device) {
                return ListTile(
                  title: Text(device.name ?? 'Dispositivo desconocido'),
                  subtitle: Text(device.address),
                  onTap: () {
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

  Future<void> _showDisconnectDialog(BuildContext context, BluetoothWeightNotifier bluetoothNotifier) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desconectar dispositivo'),
          content: ListTile(
            title: Text('Conectado a: ${bluetoothNotifier.connectedDeviceName ?? "Dispositivo desconocido"}'),
            subtitle: Text('Dirección MAC: ${bluetoothNotifier.connectedDeviceAddress ?? "Desconocida"}'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo sin desconectar.
              },
            ),
            TextButton(
              child: const Text('Desconectar'),
              onPressed: () {
                bluetoothNotifier.disconnectDevice();
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
  const WeightDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothWeightNotifier>(
      builder: (context, bluetoothNotifier, child) {
        double weight = bluetoothNotifier.weight;
        return ElevatedButton(
          onPressed: () {
            // Capturar el peso y agregarlo a la lista
            bluetoothNotifier.captureWeight(weight);
          },
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Text('Peso: $weight'),
          ),
        );
      },
    );
  }
}

class WeightHistoryList extends StatelessWidget {
  const WeightHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothWeightNotifier>(
      builder: (context, bluetoothNotifier, child) {
        List<double> weightHistory = bluetoothNotifier.weightHistory.reversed.toList();
        return Card(
          elevation: 4.0,
          child: Column(
            children: <Widget>[
              const ListTile(
                title: Text('Historial de Pesos'),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  reverse: false, 
                  itemCount: weightHistory.length,
                  itemBuilder: (context, index) {
                    final weight = weightHistory[index];
                    String weightText;
                    if(weight < 1){
                      weightText = 'Peso: ${weight.toStringAsFixed(2)} gr';
                    } else {
                      weightText = 'Peso: ${weight.toStringAsFixed(2)} kg';
                    }
                    return ListTile(
                      title: Text(weightText),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}




