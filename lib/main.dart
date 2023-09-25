// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bluetooth_weight_notifier.dart';
import 'home_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Weight Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BluetoothProvider(
        child: HomePage(),
      ),
    );
  }
}

class BluetoothProvider extends StatefulWidget {
  final Widget child;

  const BluetoothProvider({super.key, required this.child});

  @override
  _BluetoothProviderState createState() => _BluetoothProviderState();
}

class _BluetoothProviderState extends State<BluetoothProvider> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BluetoothWeightNotifier?>(
      create: (BuildContext context) => BluetoothWeightNotifier(),
      child: widget.child,
    );
  }
}
