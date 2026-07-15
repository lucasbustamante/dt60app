import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TerminalControlApp());
}

class TerminalControlApp extends StatelessWidget {
  const TerminalControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    const itauOrange = Color(0xFFFF6200);
    const itauBlue = Color(0xFF003399);
    const background = Color(0xFFF4F5F8);

    return MaterialApp(
      title: 'Terminal Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: itauOrange,
          primary: itauOrange,
          secondary: itauBlue,
          tertiary: const Color(0xFFFFD6B7),
          surface: Colors.white,
          background: background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF171717),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: itauOrange, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(140, 54),
            backgroundColor: itauOrange,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      home: const ControlHomePage(),
    );
  }
}

class AppPalette {
  static const orange = Color(0xFFFF6200);
  static const orangeDark = Color(0xFFE65100);
  static const blue = Color(0xFF003399);
  static const ink = Color(0xFF1F1F1F);
  static const muted = Color(0xFF6D6D6D);
  static const line = Color(0xFFE7E7E7);
  static const background = Color(0xFFF4F5F8);
  static const success = Color(0xFF0B8F53);
  static const danger = Color(0xFFD32F2F);
}

enum ConnectionStateKind { disconnected, connecting, connected, error }

class TerminalConnection {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final ValueNotifier<ConnectionStateKind> state = ValueNotifier(ConnectionStateKind.disconnected);
  final ValueNotifier<String> lastMessage = ValueNotifier('Informe o IP e a porta para conectar.');

  String ip = '192.168.1.50';
  String port = '8790';
  static const int fixedTimeoutSeconds = 5;
  int timeoutSeconds = fixedTimeoutSeconds;

  Uri get wsUri => Uri.parse('ws://$ip:$port/ws');

  Future<void> connect() async {
    await disconnect(silent: true);
    state.value = ConnectionStateKind.connecting;
    lastMessage.value = 'Conectando em $wsUri...';

    try {
      final socket = await WebSocket.connect(wsUri.toString()).timeout(const Duration(seconds: fixedTimeoutSeconds));
      final channel = IOWebSocketChannel(socket);
      _channel = channel;

      state.value = ConnectionStateKind.connected;
      lastMessage.value = 'Conectado em $wsUri';

      _subscription = channel.stream.listen(
        (message) => lastMessage.value = message.toString(),
        onError: (Object error) {
          state.value = ConnectionStateKind.error;
          lastMessage.value = 'Erro no WebSocket: $error';
        },
        onDone: () {
          if (state.value != ConnectionStateKind.disconnected) {
            state.value = ConnectionStateKind.disconnected;
            lastMessage.value = 'Conexão encerrada.';
          }
        },
      );
    } on TimeoutException {
      await disconnect(silent: true);
      state.value = ConnectionStateKind.error;
      lastMessage.value = 'Tempo esgotado: não conectou em ${fixedTimeoutSeconds}s.';
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
      lastMessage.value = 'Não está conectado.';
      return;
    }

    final payload = jsonEncode(<String, dynamic>{'command': command});
    _channel!.sink.add(payload);
    lastMessage.value = 'Enviado: $payload';
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
  static const _itPassword = '123456';

  final TerminalConnection connection = TerminalConnection();
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController timeoutController = TextEditingController();
  bool itAreaEnabled = false;

  @override
  void initState() {
    super.initState();
    connection.state.addListener(_refresh);
    unawaited(_loadConfig());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    connection.ip = prefs.getString('terminal_ip') ?? connection.ip;
    connection.port = prefs.getString('terminal_port') ?? connection.port;
    connection.timeoutSeconds = TerminalConnection.fixedTimeoutSeconds;
    itAreaEnabled = prefs.getBool('it_area_enabled') ?? false;

    ipController.text = connection.ip;
    portController.text = connection.port;
    timeoutController.text = TerminalConnection.fixedTimeoutSeconds.toString();
    if (mounted) setState(() {});
  }

  Future<void> _saveConfig() async {
    connection.ip = ipController.text.trim().isEmpty ? connection.ip : ipController.text.trim();
    connection.port = portController.text.trim().isEmpty ? '8790' : portController.text.trim();
    connection.timeoutSeconds = TerminalConnection.fixedTimeoutSeconds;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('terminal_ip', connection.ip);
    await prefs.setString('terminal_port', connection.port);

    ipController.text = connection.ip;
    portController.text = connection.port;
    timeoutController.text = TerminalConnection.fixedTimeoutSeconds.toString();
  }

  Future<void> _connect() async {
    await _saveConfig();
    await connection.connect();
  }

  Future<void> _disconnect() async {
    await connection.disconnect();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _setItArea(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('it_area_enabled', enabled);
    setState(() => itAreaEnabled = enabled);
  }

  Future<bool> _askItPassword() async {
    final passController = TextEditingController();
    String? errorText;

    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Habilitar área de TI'),
          content: TextField(
            controller: passController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Senha',
              counterText: '',
              errorText: errorText,
            ),
            onChanged: (_) {
              if (errorText != null) setDialogState(() => errorText = null);
            },
            onSubmitted: (_) {
              if (passController.text == _itPassword) {
                Navigator.of(dialogContext, rootNavigator: true).pop(true);
              } else {
                setDialogState(() => errorText = 'Senha inválida.');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (passController.text == _itPassword) {
                  Navigator.of(dialogContext, rootNavigator: true).pop(true);
                } else {
                  setDialogState(() => errorText = 'Senha inválida.');
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
    passController.dispose();

    if (ok == true && mounted) {
      await _setItArea(true);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    connection.state.removeListener(_refresh);
    ipController.dispose();
    portController.dispose();
    timeoutController.dispose();
    connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = connection.state.value == ConnectionStateKind.connected;

    return Scaffold(
      appBar: AppBar(
        title: const _BrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.menu_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 900 ? 48.0 : 16.0;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: connected
                        ? _ConnectedContent(
                            key: const ValueKey('connected'),
                            connection: connection,
                            itAreaEnabled: itAreaEnabled,
                          )
                        : _DisconnectedContent(
                            key: const ValueKey('disconnected'),
                            connection: connection,
                            ipController: ipController,
                            portController: portController,
                            timeoutController: timeoutController,
                            onConnect: _connect,
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsSheet(
        connection: connection,
        ipController: ipController,
        portController: portController,
        timeoutController: timeoutController,
        itAreaEnabled: itAreaEnabled,
        onConnect: _connect,
        onDisconnect: _disconnect,
        onEnableIt: _askItPassword,
        onDisableIt: () async {
          await _setItArea(false);
          if (mounted) Navigator.of(context).maybePop();
        },
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppPalette.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.terminal_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Text('Terminal Control', style: TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _DisconnectedContent extends StatelessWidget {
  const _DisconnectedContent({
    super.key,
    required this.connection,
    required this.ipController,
    required this.portController,
    required this.timeoutController,
    required this.onConnect,
  });

  final TerminalConnection connection;
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController timeoutController;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    final connecting = connection.state.value == ConnectionStateKind.connecting;

    return _ShellCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Conectar ao terminal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppPalette.ink)),
          const SizedBox(height: 6),
          const Text('Informe o IP e a porta do Terminal Control Bridge para liberar as jornadas.', style: TextStyle(color: AppPalette.muted)),
          const SizedBox(height: 22),
          _ConnectionFields(
            ipController: ipController,
            portController: portController,
            timeoutController: timeoutController,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: connecting ? null : onConnect,
            icon: connecting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_rounded),
            label: Text(connecting ? 'Conectando...' : 'Conectar'),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<ConnectionStateKind>(
            valueListenable: connection.state,
            builder: (context, state, _) => _StatusLine(state: state, messageListenable: connection.lastMessage),
          ),
        ],
      ),
    );
  }
}

class _ConnectedContent extends StatelessWidget {
  const _ConnectedContent({super.key, required this.connection, required this.itAreaEnabled});

  final TerminalConnection connection;
  final bool itAreaEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConnectionBanner(connection: connection),
        const SizedBox(height: 16),
        _CommandSection(title: 'Jornadas', icon: Icons.route_rounded, commands: CommandCatalog.journeys, connection: connection),
        if (itAreaEnabled) ...[
          _CommandSection(title: 'Telas principais', icon: Icons.dashboard_customize_rounded, commands: CommandCatalog.mainScreens, connection: connection),
          _CommandSection(title: 'LEDs', icon: Icons.lightbulb_rounded, commands: CommandCatalog.leds, connection: connection),
        ],
      ],
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.connection});

  final TerminalConnection connection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppPalette.orange, AppPalette.orangeDark]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: connection.lastMessage,
              builder: (context, message, _) => Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({
    required this.connection,
    required this.ipController,
    required this.portController,
    required this.timeoutController,
    required this.itAreaEnabled,
    required this.onConnect,
    required this.onDisconnect,
    required this.onEnableIt,
    required this.onDisableIt,
  });

  final TerminalConnection connection;
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController timeoutController;
  final bool itAreaEnabled;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;
  final Future<bool> Function() onEnableIt;
  final Future<void> Function() onDisableIt;

  @override
  Widget build(BuildContext context) {
    final connected = connection.state.value == ConnectionStateKind.connected;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: 40, bottom: bottom),
      decoration: const BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Configurações', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                _ShellCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Conexão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 14),
                      _ConnectionFields(
                        ipController: ipController,
                        portController: portController,
                        timeoutController: timeoutController,
                      ),
                      const SizedBox(height: 14),
                      if (connected)
                        OutlinedButton.icon(
                          onPressed: onDisconnect,
                          icon: const Icon(Icons.link_off_rounded),
                          label: const Text('Desconectar'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: onConnect,
                          icon: const Icon(Icons.wifi_rounded),
                          label: const Text('Conectar'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ShellCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Área de TI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(
                        itAreaEnabled
                            ? 'As telas principais e os comandos de LED estão habilitados na tela inicial.'
                            : 'Habilite para mostrar telas principais e comandos de LED na tela inicial.',
                        style: const TextStyle(color: AppPalette.muted),
                      ),
                      const SizedBox(height: 14),
                      if (itAreaEnabled)
                        OutlinedButton.icon(
                          onPressed: onDisableIt,
                          icon: const Icon(Icons.visibility_off_rounded),
                          label: const Text('Desabilitar área de TI'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () async {
                            final enabled = await onEnableIt();
                            if (enabled && context.mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.lock_open_rounded),
                          label: const Text('Habilitar área de TI'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionFields extends StatelessWidget {
  const _ConnectionFields({required this.ipController, required this.portController, required this.timeoutController});

  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController timeoutController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final fields = [
          TextField(
            controller: ipController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'IP', hintText: '192.168.1.50', prefixIcon: Icon(Icons.router_rounded)),
          ),
          TextField(
            controller: portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Porta', hintText: '8790', prefixIcon: Icon(Icons.settings_ethernet_rounded)),
          ),
        ];

        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                fields[i],
                if (i != fields.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: fields[0]),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: fields[1]),
          ],
        );
      },
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state, required this.messageListenable});

  final ConnectionStateKind state;
  final ValueNotifier<String> messageListenable;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      ConnectionStateKind.connected => AppPalette.success,
      ConnectionStateKind.connecting => AppPalette.blue,
      ConnectionStateKind.error => AppPalette.danger,
      ConnectionStateKind.disconnected => AppPalette.muted,
    };
    final icon = switch (state) {
      ConnectionStateKind.connected => Icons.check_circle_rounded,
      ConnectionStateKind.connecting => Icons.sync_rounded,
      ConnectionStateKind.error => Icons.error_rounded,
      ConnectionStateKind.disconnected => Icons.radio_button_unchecked_rounded,
    };

    return ValueListenableBuilder<String>(
      valueListenable: messageListenable,
      builder: (context, message, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }
}

class _ShellCard extends StatelessWidget {
  const _ShellCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class CommandButton {
  const CommandButton(this.label, this.command, this.icon, {this.technologies});
  final String label;
  final String command;
  final IconData icon;
  final String? technologies;
}

class CommandCatalog {
  static const journeys = [
    CommandButton('Seguro Pet', 'seguro_pet', Icons.pets_rounded, technologies: 'Aproximação • Biometria facial'),
    CommandButton('Bolsa Protegida', 'bolsa_protegida', Icons.shopping_bag_rounded, technologies: 'Tarja magnética • Senha'),
    CommandButton('Seguro Saúde', 'seguro_saude', Icons.health_and_safety_rounded, technologies: 'Inserção chip • Biometria digital'),
    CommandButton('Proteção Cartão', 'protecao_cartao', Icons.credit_card_rounded, technologies: 'Aproximação • Senha'),
    CommandButton('Assist. Residencial', 'assistencia_residencial', Icons.home_repair_service_rounded, technologies: 'Inserção chip • Biometria facial'),
    CommandButton('Seguro Celular', 'seguro_celular', Icons.phone_android_rounded, technologies: 'Tarja magnética • Biometria digital'),
    CommandButton('Abertura de Conta', 'abertura_conta', Icons.account_balance_rounded, technologies: 'Biometria • Senha • Bio. facial • QR Code'),
    CommandButton('Crédito Consignado', 'credito_consignado', Icons.payments_rounded, technologies: 'Aproximação • Biometria facial'),
  ];

  static const mainScreens = [
    CommandButton('Standby', 'standby', Icons.desktop_windows_rounded),
    CommandButton('Aproximação', 'aproximar', Icons.contactless_rounded),
    CommandButton('Inserir Cartão', 'inserir_cartao', Icons.input_rounded),
    CommandButton('Tarja Magnética', 'cartao', Icons.swipe_rounded),
    CommandButton('Senha', 'senha', Icons.pin_rounded),
    CommandButton('Biometria Facial', 'biometria_facial', Icons.face_rounded),
    CommandButton('Biometria Digital', 'biometria_digital', Icons.fingerprint_rounded),
    CommandButton('Sucesso', 'sucesso', Icons.check_circle_rounded),
    CommandButton('Erro', 'erro', Icons.error_rounded),
    CommandButton('Docinho', 'docinho', Icons.cake_rounded),
  ];

  static const leds = [
    CommandButton('Teste LED', 'led', Icons.light_mode_rounded),
    CommandButton('Vermelho', 'led_red', Icons.circle_rounded),
    CommandButton('Verde', 'led_green', Icons.circle_rounded),
    CommandButton('Azul', 'led_blue', Icons.circle_rounded),
    CommandButton('Amarelo', 'led_yellow', Icons.circle_rounded),
    CommandButton('Roxo', 'led_purple', Icons.circle_rounded),
    CommandButton('Branco', 'led_white', Icons.circle_rounded),
    CommandButton('Loading', 'led_loading', Icons.autorenew_rounded),
    CommandButton('Desligar', 'led_off', Icons.power_settings_new_rounded),
  ];
}

class _CommandSection extends StatelessWidget {
  const _CommandSection({required this.title, required this.icon, required this.commands, required this.connection});

  final String title;
  final IconData icon;
  final List<CommandButton> commands;
  final TerminalConnection connection;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppPalette.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: AppPalette.orange),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 950 ? 4 : width >= 650 ? 3 : width >= 430 ? 2 : 1;
                final itemWidth = (width - (columns - 1) * 10) / columns;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in commands)
                      SizedBox(
                        width: itemWidth,
                        child: _CommandTile(
                          item: item,
                          onTap: () => connection.sendCommand(item.command),
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

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.item, required this.onTap});

  final CommandButton item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.blue,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    if (item.technologies != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.technologies!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.86), fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
