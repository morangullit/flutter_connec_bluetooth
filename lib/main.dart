import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bluetooth_weight_notifier.dart';
import 'home_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Weight Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BluetoothProvider(
        child: HomePage(),
      ),
    );
  }
}

class BluetoothProvider extends StatefulWidget {
  final Widget child;

  BluetoothProvider({required this.child});

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
