// ignore_for_file: use_build_context_synchronously

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
                      Text(
                          'Conectado a: ${bluetoothNotifier.connectedDeviceName ?? "Dispositivo desconocido"}'),
                    if (bluetoothNotifier.isConnecting)
                      const Text('Conectando al dispositivo...'),
                    Text(
                        'Dirección MAC: ${bluetoothNotifier.connectedDeviceAddress ?? "Desconocida"}'),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const WeightDisplay(),
            const SizedBox(height: 200),
            const Expanded(
              child:
                  WeightHistoryList(), // Permitir hacer scroll en el historial de pesos.
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<BluetoothWeightNotifier>(
        builder: (context, bluetoothNotifier, child) {
          return FloatingActionButton(
            onPressed: () async {
              final isBluetoothEnabled =
                  await FlutterBluetoothSerial.instance.isEnabled;

              if (!isBluetoothEnabled!) {
                // Bluetooth está desactivado, mostrar diálogo para activarlo.
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Activar Bluetooth'),
                      content: const Text(
                          'Por favor, active el Bluetooth para conectar dispositivos.'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Activar Bluetooth'),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            // Abrir la página de configuración de Bluetooth del dispositivo
                            await FlutterBluetoothSerial.instance
                                .requestEnable();
                          },
                        ),
                      ],
                    );
                  },
                );
              } else if (!bluetoothNotifier.isConnected) {
                List<BluetoothDevice> devices =
                    await bluetoothNotifier.scanForDevices();
                if (devices.isNotEmpty) {
                  _showDeviceSelectionDialog(
                      context, devices, bluetoothNotifier);
                } else {
                  //print('No se encontraron dispositivos Bluetooth disponibles.');
                }
              } else {
                _showDisconnectDialog(context, bluetoothNotifier);
              }
            },
            child: Icon(bluetoothNotifier.isConnected
                ? Icons.bluetooth_disabled
                : Icons.bluetooth),
          );
        },
      ),
    );
  }

  Future<void> _showDeviceSelectionDialog(
      BuildContext context,
      List<BluetoothDevice> devices,
      BluetoothWeightNotifier bluetoothNotifier) async {
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

  Future<void> _showDisconnectDialog(
      BuildContext context, BluetoothWeightNotifier bluetoothNotifier) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desconectar dispositivo'),
          content: ListTile(
            title: Text(
                'Conectado a: ${bluetoothNotifier.connectedDeviceName ?? "Dispositivo desconocido"}'),
            subtitle: Text(
                'Dirección MAC: ${bluetoothNotifier.connectedDeviceAddress ?? "Desconocida"}'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Cierra el diálogo sin desconectar.
              },
            ),
            TextButton(
              child: const Text('Desconectar'),
              onPressed: () {
                bluetoothNotifier.disconnectDevice();
                Navigator.of(context)
                    .pop(); // Cierra el diálogo después de desconectar.
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
            if (bluetoothNotifier.isConnected) {
              if(weight > 0.00){
                bluetoothNotifier.captureWeight(weight);
              }
              else {
                showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Error al capturar peso'),
                    content: const Text('Para capturar el peso, debe contener un peso diferente de cero'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
              }
              // Solo capturar el peso si está conectado al dispositivo Bluetooth
              
            } else {
              // Mostrar un mensaje de error si no está conectado
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Error de conexión'),
                    content: const Text('Para capturar el peso, debe estar conectado al dispositivo Bluetooth.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
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
        List<double> weightHistory =
            bluetoothNotifier.weightHistory.reversed.toList();
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
                    if (weight < 1) {
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
