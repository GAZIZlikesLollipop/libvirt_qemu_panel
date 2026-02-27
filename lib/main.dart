import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

sealed class ApiState {}

class Initial extends ApiState {}

class Loading extends ApiState {}

class Error extends ApiState {
  final String message;
  Error({required this.message});
}

class MachineState {
  final int state;
  final int maxRam;
  final int ram;
  final int coreCount;
  final int cpuTime;
  const MachineState({
    required this.state,
    required this.maxRam,
    required this.ram,
    required this.coreCount,
    required this.cpuTime,
  });
  factory MachineState.fromJson(Map<String, dynamic> json) {
    return switch(json) {
      {'state': int state,'max_ram': int maxRam,'ram': int ram,'core_count': int coreCount,'cpu_time': int cpuTime} => MachineState(
          state: state,
          maxRam: maxRam, 
          ram: ram, 
          coreCount: coreCount, 
          cpuTime: cpuTime
        ),
      _ => throw const FormatException('Ошибка преобразования MachineState')
    };
  }
}

class Success extends ApiState {}

class LibVirtApiModel extends ChangeNotifier {
  MachineState? _machineState;
  MachineState? get machineState => _machineState;
  ApiState _apiState = Initial();
  ApiState get apiState => _apiState;
  final baseURL = String.fromEnvironment('SERVER_URL',defaultValue: "http://localhost:8080");
  void startVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("$baseURL/start"));
    if(response.statusCode == 200) {
      _apiState = Success();
    } else {
      _apiState = Error(message: response.body);
    }
    notifyListeners();
  }
  void getMachineState() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("$baseURL/state"));
    if(response.statusCode == 200) {
      _apiState = Success();
      _machineState = MachineState.fromJson(jsonDecode(response.body) as Map<String,dynamic>);
    } else {
      _apiState = Error(message: response.body);
    }
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LibVirtApiModel(),
      child: MainApp(),
    )
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      title: 'Libvirt panel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback callback;
  const ActionButton({
    super.key,
    required this.callback,
    required this.text,
    required this.icon
  });
  @override
  Widget build(BuildContext ctx){
    return Material(
      child: InkWell(
        onTap: () => callback(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Theme.of(ctx).colorScheme.primary,
              size: 25,
            ),
            SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(ctx).colorScheme.onSurface,
                fontWeight: FontWeight.w100
              )
            )
          ],
        )
      )
    );
  }
}

class MachineInfo extends StatelessWidget {
  final String title;
  final String info; 
  const MachineInfo({
    super.key,
    required this.title,
    required this.info
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface
          )
        ),
        SizedBox(width: 8),
        Text(
          info
        )
      ],
    ); 
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 10,
        ),
        child: Column(
          children: [
            Row(
              children: [
                ActionButton(
                  icon: Icons.play_circle_outline,
                  callback: () {},
                  text: 'Start'
                ),
                SizedBox(width: 8),
                ActionButton(
                  icon: Icons.restart_alt,
                  callback: () {},
                  text: 'Reboot'
                ),
                SizedBox(width: 8),
                ActionButton(
                  icon: Icons.power_settings_new_outlined,
                  callback: () {},
                  text: 'Shutdown'
                )
              ],
            ),
            Divider(
              thickness: 1,
              color: Colors.grey,
              indent: 0,
              endIndent: 0
            )
          ],
        )
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
