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
      home: HomePage()
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(

    );
  }
}
