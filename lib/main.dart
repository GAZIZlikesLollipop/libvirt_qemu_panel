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
  LibVirtApiModel() {
    getMachineState();
  }
  MachineState? _machineState;
  MachineState? get machineState => _machineState;
  ApiState _apiState = Initial();
  ApiState get apiState => _apiState;
  static const baseURL = String.fromEnvironment('SERVER_URL',defaultValue: "http://localhost:8080");
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
  void startVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("$baseURL/start"));
    if(response.statusCode == 200) {
      getMachineState();
    } else {
      _apiState = Error(message: response.body);
    }
    notifyListeners();
  }
  void stopVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("$baseURL/stop"));
    if(response.statusCode == 200) {
      getMachineState();
    } else {
      _apiState = Error(message: response.body);
    }
    notifyListeners();
  }
  void forceStopVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("$baseURL/forcestop"));
    if(response.statusCode == 200) {
      getMachineState();
    } else {
      _apiState = Error(message: response.body);
    }
    notifyListeners();
  }
  void rebootVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("$baseURL/reboot"));
    if(response.statusCode == 200) {
      getMachineState();
    } else {
      _apiState = Error(message: response.body);
    }
    notifyListeners();
  }
  void suspendVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("$baseURL/suspend"));
    if(response.statusCode == 200) {
      getMachineState();
    } else {
      _apiState = Error(message: response.body);
    }
    notifyListeners();
  }
  void resumeVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("$baseURL/resume"));
    if(response.statusCode == 200) {
      getMachineState();
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
  final bool enabled;
  const ActionButton({
    super.key,
    required this.callback,
    required this.text,
    required this.icon,
    this.enabled = true
  });
  @override
  Widget build(BuildContext ctx){
    return Row(
      children: [
        Material(
          child: InkWell(
            onTap: enabled ? () => callback() : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: enabled ? Theme.of(ctx).colorScheme.primary : Colors.grey.withAlpha(178),
                  size: 25,
                ),
                SizedBox(width: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 24,
                    color: enabled ? Theme.of(ctx).colorScheme.onSurface : Colors.grey.withAlpha(178),
                    fontWeight: FontWeight.w100
                  ),
                )
              ],
            )
          )
        ),
        SizedBox(width: 20)
      ]
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
            color: Theme.of(context).colorScheme.onSurface.withAlpha(190),
            fontSize: 24,
            fontWeight: FontWeight.w100
          )
        ),
        SizedBox(width: 6),
        Text(
          info,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w100
          )
        )
      ],
    ); 
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibVirtApiModel>();
    final isRunning = viewModel.machineState?.state == 1 || viewModel.machineState?.state == 2;
    final isClickable = viewModel.machineState?.state != 0 && viewModel.machineState?.state != 4;
    final isSleep = viewModel.machineState?.state != 3 || viewModel.machineState?.state != 7;
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
                  icon: Icons.power_settings_new_outlined,
                  callback: !isRunning ? () => viewModel.startVM() : () => viewModel.stopVM(),
                  text: !isRunning ? 'Start' : 'Stop',
                  enabled: isClickable && isSleep
                ),
                ActionButton(
                  icon: Icons.restart_alt,
                  callback: () => viewModel.rebootVM(),
                  text: 'Reboot',
                  enabled: isClickable && isRunning
                ),
                ActionButton(
                  icon: Icons.power_off_outlined,
                  callback: () => viewModel.forceStopVM(),
                  text: 'Force stop',
                  enabled: isClickable && isRunning || viewModel.machineState?.state == 3 || viewModel.machineState?.state == 7
                ),
                ActionButton(
                  icon: viewModel.machineState?.state == 3 ? Icons.play_circle_outlined : Icons.pause_circle_outlined,
                  callback: viewModel.machineState?.state == 3 ? () => viewModel.resumeVM() : () => viewModel.suspendVM(),
                  text: viewModel.machineState?.state == 3 ? 'Resume' : 'Suspend',
                  enabled: viewModel.machineState?.state == 1 || viewModel.machineState?.state == 3,
                ),
              ],
            ),
            Divider(
              thickness: 1,
              color: Colors.grey,
              indent: 0,
              endIndent: 0
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: 
                InkWell(
                  onTap: (){},
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh_outlined,
                        color: Colors.blueGrey
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Refrush',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey
                        ),
                      )
                    ],
                  ),
                ),
            ),
            SizedBox(height: 8),
            Column(
              children: [
                MachineInfo(
                  title: 'State',
                   info: '${viewModel.machineState?.state}'
                )
              ],
            )
          ],
        )
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
