import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bank_product.dart';
import '../services/journey_flow.dart';
import '../services/pinpad_keys.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class CreditConsignedScreen extends StatefulWidget {
  const CreditConsignedScreen({super.key});

  @override
  State<CreditConsignedScreen> createState() => _CreditConsignedScreenState();
}

class _CreditConsignedScreenState extends State<CreditConsignedScreen> {
  final FocusNode _focusNode = FocusNode();
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _ensureFocus() {
    if (!mounted || _leaving) return;
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
  }

  void _hire() {
    if (_leaving) return;
    _leaving = true;

    final session = ProductJourneySession(
      product: BankProductCatalog.byKind(BankProductKind.payrollLoan),
    );

    Navigator.of(context).pushNamedAndRemoveUntil(
      JourneyFlow.nfcRoute,
      (_) => false,
      arguments: session,
    );
  }

  void _cancel() {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      JourneyFlow.errorRoute,
      (_) => false,
      arguments: const OperationFailure(
        title: 'Contratação cancelada',
        message: 'A proposta de crédito consignado foi cancelada com segurança.',
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || _leaving) return;
    final key = event.logicalKey;
    if (PinpadKeys.isEnter(key)) {
      _hire();
    } else if (PinpadKeys.isCancel(key)) {
      _cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _ensureFocus,
          child: AppFrame(
            showSteps: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = MediaQuery.sizeOf(context).height <= 460 ||
                    constraints.maxHeight <= 360;
                final wide = constraints.maxWidth >= 760;
                final content = wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ClientInfo(compact: compact)),
                          SizedBox(width: compact ? 12 : 18),
                          Expanded(child: _CreditDetails(compact: compact, onHire: _hire, onCancel: _cancel)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ClientInfo(compact: compact),
                          const SizedBox(height: 14),
                          _CreditDetails(compact: compact, onHire: _hire, onCancel: _cancel),
                        ],
                      );

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(compact ? 12 : 18),
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientInfo extends StatelessWidget {
  const _ClientInfo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 48 : 64,
          height: compact ? 48 : 64,
          decoration: BoxDecoration(
            color: AppColors.orangeSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.account_balance_wallet_outlined, color: AppColors.orange, size: compact ? 28 : 36),
        ),
        SizedBox(height: compact ? 10 : 18),
        Text(
          'Crédito consignado',
          style: TextStyle(
            color: AppColors.text,
            fontSize: compact ? 28 : 40,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          'Olá, Lucas',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: compact ? 22 : 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Confira a simulação disponível para contratação. A validação será feita por aproximação do cartão e biometria facial.',
          style: TextStyle(
            color: AppColors.text,
            fontSize: compact ? 14 : 18,
            height: 1.32,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
      ],
    );
  }
}

class _CreditDetails extends StatelessWidget {
  const _CreditDetails({
    required this.compact,
    required this.onHire,
    required this.onCancel,
  });

  final bool compact;
  final VoidCallback onHire;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo da proposta',
            style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: compact ? 12 : 16),
          _AmountLine(label: 'Valor contratado', value: 'R\$ 500.000,00', highlight: true, compact: compact),
          _AmountLine(label: 'Quantidade de parcelas', value: '96x', compact: compact),
          _AmountLine(label: 'Valor da parcela', value: 'R\$ 7.245,90', compact: compact),
          _AmountLine(label: 'Taxa mensal', value: '1,49% a.m.', compact: compact),
          _AmountLine(label: 'CET aproximado', value: '1,72% a.m.', compact: compact),
          _AmountLine(label: 'Primeiro vencimento', value: '10/08/2026', compact: compact),
          _AmountLine(label: 'Forma de desconto', value: 'Débito em folha', compact: compact),
          SizedBox(height: compact ? 12 : 18),
          Text(
            'Os valores são uma simulação para demonstração no terminal.',
            style: TextStyle(color: AppColors.muted, fontSize: compact ? 12 : 14, height: 1.3),
          ),
          SizedBox(height: compact ? 12 : 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onHire,
                  icon: const Icon(Icons.check),
                  label: const Text('Contratar'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: compact ? 12 : 16, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.3),
                    padding: EdgeInsets.symmetric(vertical: compact ? 12 : 16, horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    required this.compact,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool compact;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? AppColors.orange : AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.muted, fontSize: compact ? 12 : 14, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.orange : AppColors.text,
              fontSize: highlight ? (compact ? 20 : 26) : (compact ? 15 : 18),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowLine extends StatelessWidget {
  const _FlowLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.orange, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.text, fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.text, fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
