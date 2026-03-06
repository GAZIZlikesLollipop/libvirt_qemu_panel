import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

sealed class ApiState {}

class Initial extends ApiState {}

class Loading extends ApiState {}

class Error extends ApiState {
  final String message;
  Error({required this.message});
}

class MachineState {
  final String event;
  final String detail;
  final String memory;
  final int coreCount;
  final String cpuTime;
  const MachineState({
    required this.event,
    required this.detail,
    required this.memory,
    required this.coreCount,
    required this.cpuTime,
  });
  MachineState copyWith({
    String? event,
    String? detail,
    String? memory,
    String? ram,
    int? coreCount,
    String? cpuTime
  }){
    return MachineState(
      event: event ?? this.event,
      detail: detail ?? this.detail,
      memory: memory ?? this.memory,
      coreCount: coreCount ?? this.coreCount,
      cpuTime: cpuTime ?? this.cpuTime
    );
  }
  factory MachineState.fromJson(Map<String, dynamic> json) {
    return switch(json) {
      {
        'event': String event,
        'detail': String detail,
        'memory': int memory,
        'core_count': int coreCount,
        'cpu_time': int cpuTime
      } => MachineState(
          event: event,
          detail: detail,
          memory: '$memory', 
          coreCount: coreCount, 
          cpuTime: '$cpuTime'
        ),
      _ => throw const FormatException('Ошибка преобразования MachineState')
    };
  }
}

class Success extends ApiState {}

class LibVirtApiModel extends ChangeNotifier {
  LibVirtApiModel() {
    startStateListening();
  }
  MachineState? _machineState;
  MachineState? get machineState => _machineState;
  ApiState _apiState = Initial();
  ApiState get apiState => _apiState;
  static const baseURL = String.fromEnvironment('SERVER_URL',defaultValue: "localhost:8080");
  String fromKB(int bytes) {
    String result = '$bytes KB';
    if(bytes > 1024){
      result = '${bytes/1024} MB';
    }
    return result;
  }
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://$baseURL/state'),
  );
  void startStateListening() async {
    await channel.ready;
    channel.stream.listen((msg){
      _machineState = MachineState.fromJson(jsonDecode(msg) as Map<String,dynamic>);
      var date = DateTime.now().subtract(Duration(microseconds: int.parse(machineState?.cpuTime ?? '0') ~/ 1000)).toUtc();
      _machineState = machineState?.copyWith(
        cpuTime: '${date.day}/${date.month}/${date.year} ${date.hour < 10 ? '0${date.hour}' : date.hour}:${date.minute < 10 ? '0${date.minute}' : date.minute} UTC',
        memory: fromKB(int.parse(machineState?.memory ?? '0')),
      );
      notifyListeners();
    });
  }
  void startVM() async {
    _apiState = Loading();
    if(machineState != null) {
      final response = await http.get(Uri.parse("http://$baseURL/start"));
      if(response.statusCode != 200) {_apiState = Error(message: response.body); }
    } else {
      channel.sink.add('give me data!');
    }
    notifyListeners();
  }
  void stopVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("http://$baseURL/stop"));
    if(response.statusCode != 200) {_apiState = Error(message: response.body); }
    notifyListeners();
  }
  void forceStopVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("http://$baseURL/forcestop"));
    if(response.statusCode != 200) {_apiState = Error(message: response.body); }
    notifyListeners();
  }
  void rebootVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("http://$baseURL/reboot"));
    if(response.statusCode != 200) {_apiState = Error(message: response.body); }
    notifyListeners();
  }
  void suspendVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("http://$baseURL/suspend"));
    if(response.statusCode != 200) {_apiState = Error(message: response.body); }
    notifyListeners();
  }
  void resumeVM() async {
    _apiState = Loading();
    final response = await http.get(Uri.parse("http://$baseURL/resume"));
    if(response.statusCode != 200) {_apiState = Error(message: response.body); }
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
          ':',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
            fontSize: 22,
            fontWeight: FontWeight.w100
          )
        ),
        SizedBox(width: 6),
        SelectableText(
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
    final isRunning = viewModel.machineState?.event == 'Started' || 
                      viewModel.machineState?.event == 'Resumed';
    final isClickable = viewModel.machineState?.event != 'Undefined' && 
                        viewModel.machineState?.event != 'Crashed';
    final isSleep = viewModel.machineState?.event == 'Suspended' || 
        viewModel.machineState?.event == 'Pmsuspended';
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
                  enabled: isClickable || isSleep 
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
                  enabled: isClickable && isRunning || 
                          viewModel.machineState?.event == 'Suspended' || 
                          viewModel.machineState?.event == 'Pmsuspended',
                ),
                ActionButton(
                  icon: viewModel.machineState?.event == 'Suspended' || viewModel.machineState?.event == 'Pmsuspended' 
                      ? Icons.play_circle_outlined 
                      : Icons.pause_circle_outlined,
                  callback: viewModel.machineState?.event == 'Suspended' || viewModel.machineState?.event == 'Pmsuspended' 
                      ? () => viewModel.resumeVM() 
                      : () => viewModel.suspendVM(),
                  text: viewModel.machineState?.event == 'Suspended' || viewModel.machineState?.event == 'Pmsuspended' 
                      ? 'Resume' 
                      : 'Suspend',
                  enabled: isClickable && viewModel.machineState?.event == 'Started' || viewModel.machineState?.event == 'Suspended' || viewModel.machineState?.event == 'Resumed',
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
            Column(
              children: [
                MachineInfo(
                  title: 'State',
                  info: (viewModel.machineState?.detail ?? "Unknown").isNotEmpty ? '${viewModel.machineState?.event} (${viewModel.machineState?.detail})' : '${viewModel.machineState?.event}',
                ),
                MachineInfo(
                  title: 'Memory',
                  info: '${viewModel.machineState?.memory}'
                ),
                MachineInfo(
                  title: 'Core Count',
                  info: '${viewModel.machineState?.coreCount}'
                ),
                MachineInfo(
                  title: 'Start Time',
                  info: '${viewModel.machineState?.cpuTime}'
                ),
              ],
            )
          ],
        )
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
