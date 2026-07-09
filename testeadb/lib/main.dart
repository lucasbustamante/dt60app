import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TerminalControlTabletApp());
}

class TerminalControlTabletApp extends StatelessWidget {
  const TerminalControlTabletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terminal Control Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6200)),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(150, 56),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      home: const ControlHomePage(),
    );
  }
}

enum ConnectionStateKind { disconnected, connecting, connected, error }

class RaspberryConnection {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final ValueNotifier<ConnectionStateKind> state = ValueNotifier(ConnectionStateKind.disconnected);
  final ValueNotifier<String> lastMessage = ValueNotifier('Aguardando conexão.');

  String ip = '192.168.1.50';
  String port = '8787';
  String token = '';

  Uri get wsUri => Uri.parse('ws://$ip:$port/ws');

  Future<void> connect() async {
    await disconnect(silent: true);
    state.value = ConnectionStateKind.connecting;
    lastMessage.value = 'Conectando em $wsUri ...';

    try {
      final channel = WebSocketChannel.connect(wsUri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 5));
      state.value = ConnectionStateKind.connected;
      lastMessage.value = 'Conectado em $wsUri';

      _subscription = channel.stream.listen(
        (message) {
          lastMessage.value = message.toString();
        },
        onError: (Object error) {
          state.value = ConnectionStateKind.error;
          lastMessage.value = 'Erro no WebSocket: $error';
        },
        onDone: () {
          if (state.value != ConnectionStateKind.disconnected) {
            state.value = ConnectionStateKind.disconnected;
            lastMessage.value = 'Conexão encerrada pelo Raspberry.';
          }
        },
        cancelOnError: false,
      );
    } catch (error) {
      await disconnect(silent: true);
      state.value = ConnectionStateKind.error;
      lastMessage.value = 'Não conectou: $error';
    }
  }

  Future<void> disconnect({bool silent = false}) async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    if (!silent) {
      state.value = ConnectionStateKind.disconnected;
      lastMessage.value = 'Desconectado.';
    }
  }

  void sendCommand(String command) {
    if (_channel == null || state.value != ConnectionStateKind.connected) {
      lastMessage.value = 'Não está conectado. Toque em Conectar primeiro.';
      return;
    }

    final payload = <String, dynamic>{'command': command};
    if (token.trim().isNotEmpty) {
      payload['token'] = token.trim();
    }

    final jsonText = jsonEncode(payload);
    _channel!.sink.add(jsonText);
    lastMessage.value = 'Enviado: $jsonText';
  }

  void dispose() {
    unawaited(disconnect(silent: true));
    state.dispose();
    lastMessage.dispose();
  }
}

class ControlHomePage extends StatefulWidget {
  const ControlHomePage({super.key});

  @override
  State<ControlHomePage> createState() => _ControlHomePageState();
}

class _ControlHomePageState extends State<ControlHomePage> {
  final RaspberryConnection connection = RaspberryConnection();
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadConfig());
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    connection.ip = prefs.getString('raspberry_ip') ?? connection.ip;
    connection.port = prefs.getString('raspberry_port') ?? connection.port;
    connection.token = prefs.getString('raspberry_token') ?? '';
    ipController.text = connection.ip;
    portController.text = connection.port;
    tokenController.text = connection.token;
    setState(() {});
  }

  Future<void> _saveConfig() async {
    connection.ip = ipController.text.trim();
    connection.port = portController.text.trim().isEmpty ? '8787' : portController.text.trim();
    connection.token = tokenController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('raspberry_ip', connection.ip);
    await prefs.setString('raspberry_port', connection.port);
    await prefs.setString('raspberry_token', connection.token);
  }

  Future<void> _connect() async {
    await _saveConfig();
    await connection.connect();
  }

  @override
  void dispose() {
    ipController.dispose();
    portController.dispose();
    tokenController.dispose();
    connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConnectionPanel(
                connection: connection,
                ipController: ipController,
                portController: portController,
                tokenController: tokenController,
                onConnect: _connect,
              ),
              const Divider(height: 1),
              _CommandPanel(connection: connection),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({required this.connection, required this.ipController, required this.portController, required this.tokenController, required this.onConnect});

  final RaspberryConnection connection;
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController tokenController;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Terminal Control', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const Text('Controle do Raspberry PinPad Bridge', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 18),
          TextField(controller: ipController, decoration: const InputDecoration(labelText: 'IP do Raspberry', border: OutlineInputBorder(), hintText: '192.168.1.50')),
          const SizedBox(height: 10),
          TextField(controller: portController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Porta', border: OutlineInputBorder(), hintText: '8787')),
          const SizedBox(height: 10),
          TextField(controller: tokenController, decoration: const InputDecoration(labelText: 'Token opcional', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          ValueListenableBuilder<ConnectionStateKind>(
            valueListenable: connection.state,
            builder: (context, state, _) {
              final connected = state == ConnectionStateKind.connected;
              final connecting = state == ConnectionStateKind.connecting;
              return Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: connecting ? null : onConnect,
                      icon: Icon(connected ? Icons.refresh : Icons.wifi),
                      label: Text(connected ? 'Reconectar' : connecting ? 'Conectando...' : 'Conectar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () => connection.disconnect(),
                    icon: const Icon(Icons.link_off),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<ConnectionStateKind>(
            valueListenable: connection.state,
            builder: (context, state, _) {
              return _StatusChip(state: state);
            },
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 130),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
              child: SingleChildScrollView(
                child: ValueListenableBuilder<String>(
                  valueListenable: connection.lastMessage,
                  builder: (context, message, _) => Text(message, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('WebSocket: ws://${ipController.text.isEmpty ? 'IP' : ipController.text}:${portController.text.isEmpty ? '8787' : portController.text}/ws', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state});
  final ConnectionStateKind state;

  @override
  Widget build(BuildContext context) {
    final text = switch (state) {
      ConnectionStateKind.connected => 'Conectado',
      ConnectionStateKind.connecting => 'Conectando',
      ConnectionStateKind.error => 'Erro',
      ConnectionStateKind.disconnected => 'Desconectado',
    };
    final icon = switch (state) {
      ConnectionStateKind.connected => Icons.check_circle,
      ConnectionStateKind.connecting => Icons.sync,
      ConnectionStateKind.error => Icons.error,
      ConnectionStateKind.disconnected => Icons.radio_button_unchecked,
    };
    return Chip(avatar: Icon(icon, size: 18), label: Text(text), padding: const EdgeInsets.all(8));
  }
}

class _CommandPanel extends StatelessWidget {
  const _CommandPanel({required this.connection});
  final RaspberryConnection connection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comandos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          _CommandSection(title: 'Jornadas', commands: const [
            CommandButton('Seguro Pet', 'seguro_pet'),
            CommandButton('Bolsa Protegida', 'bolsa_protegida'),
            CommandButton('Seguro Saúde', 'seguro_saude'),
            CommandButton('Proteção Cartão', 'protecao_cartao'),
            CommandButton('Assist. Residencial', 'assistencia_residencial'),
            CommandButton('Seguro Celular', 'seguro_celular'),
            CommandButton('Abertura de Conta', 'abertura_conta'),
            CommandButton('Crédito Consignado', 'credito_consignado'),
          ], connection: connection),
          _CommandSection(title: 'Telas principais', commands: const [
            CommandButton('Standby', 'standby'),
            CommandButton('Aproximação', 'aproximar'),
            CommandButton('Inserir Cartão', 'inserir_cartao'),
            CommandButton('Tarja Magnética', 'cartao'),
            CommandButton('Senha', 'senha'),
            CommandButton('Biometria Facial', 'biometria_facial'),
            CommandButton('Biometria Digital', 'biometria_digital'),
            CommandButton('Sucesso', 'sucesso'),
            CommandButton('Erro', 'erro'),
            CommandButton('Docinho', 'docinho'),
          ], connection: connection),
          _CommandSection(title: 'LEDs', commands: const [
            CommandButton('Teste LED', 'led'),
            CommandButton('Vermelho', 'led_red'),
            CommandButton('Verde', 'led_green'),
            CommandButton('Azul', 'led_blue'),
            CommandButton('Amarelo', 'led_yellow'),
            CommandButton('Roxo', 'led_purple'),
            CommandButton('Branco', 'led_white'),
            CommandButton('Loading', 'led_loading'),
            CommandButton('Desligar', 'led_off'),
          ], connection: connection),
        ],
      ),
    );
  }
}

class CommandButton {
  const CommandButton(this.label, this.command);
  final String label;
  final String command;
}

class _CommandSection extends StatelessWidget {
  const _CommandSection({required this.title, required this.commands, required this.connection});
  final String title;
  final List<CommandButton> commands;
  final RaspberryConnection connection;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Colors.black12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isVeryNarrow = constraints.maxWidth < 360;
                final buttonWidth = isVeryNarrow ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in commands)
                      SizedBox(
                        width: buttonWidth,
                        child: FilledButton(
                          onPressed: () => connection.sendCommand(item.command),
                          child: Text(item.label, textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
