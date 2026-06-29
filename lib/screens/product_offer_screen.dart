import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bank_product.dart';
import '../services/card_reader_service.dart';
import '../services/pinpad_keys.dart';
import '../theme/app_theme.dart';
import '../widgets/app_frame.dart';

class ProductOfferScreen extends StatefulWidget {
  const ProductOfferScreen({super.key, required this.product});

  final BankProduct product;

  @override
  State<ProductOfferScreen> createState() => _ProductOfferScreenState();
}

class _ProductOfferScreenState extends State<ProductOfferScreen> {
  final FocusNode _focusNode = FocusNode();
  late final StreamSubscription<CardReaderEvent> _pinpadSubscription;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _pinpadSubscription = CardReaderService.instance.events.listen((event) {
      if (_leaving) return;
      switch (event.type) {
        case CardReaderEventType.pinpadEnter:
          _hire();
          break;
        case CardReaderEventType.pinpadCancel:
          _cancel();
          break;
        default:
          break;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocus());
  }

  @override
  void dispose() {
    unawaited(_pinpadSubscription.cancel());
    _focusNode.dispose();
    super.dispose();
  }

  void _ensureFocus() {
    if (!mounted || _leaving) return;
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _hire() {
    if (_leaving) return;
    _leaving = true;
    final session = ProductJourneySession(product: widget.product);
    final route = switch (math.Random().nextInt(3)) {
      0 => '/inserir-cartao',
      1 => '/cartao',
      _ => '/aproximar',
    };

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(route, (_) => false, arguments: session);
  }

  void _cancel() {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pushNamedAndRemoveUntil('/erro', (_) => false);
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || _leaving) return;

    final key = event.logicalKey;
    if (PinpadKeys.isEnter(key)) {
      _hire();
      return;
    }

    if (PinpadKeys.isCancel(key)) {
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
                final media = MediaQuery.sizeOf(context);
                final compactHeight =
                    media.height <= 460 || constraints.maxHeight <= 360;
                final wide = constraints.maxWidth >= 680;
                final contentPadding = compactHeight ? 12.0 : 18.0;

                final content = wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: _ProductSummary(
                              product: widget.product,
                              compact: compactHeight,
                            ),
                          ),
                          SizedBox(width: compactHeight ? 12 : 18),
                          Expanded(
                            flex: 7,
                            child: _OfferDetails(
                              product: widget.product,
                              compact: compactHeight,
                              onHire: _hire,
                              onCancel: _cancel,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProductSummary(
                            product: widget.product,
                            compact: compactHeight,
                          ),
                          const SizedBox(height: 14),
                          _OfferDetails(
                            product: widget.product,
                            compact: compactHeight,
                            onHire: _hire,
                            onCancel: _cancel,
                          ),
                        ],
                      );

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(contentPadding),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0,
                            constraints.maxHeight - contentPadding * 2,
                          ),
                        ),
                        child: content,
                      ),
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

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.product, required this.compact});

  final BankProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 46 : 64,
            height: compact ? 46 : 64,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              product.icon,
              color: AppColors.orange,
              size: compact ? 26 : 34,
            ),
          ),
          SizedBox(height: compact ? 10 : 18),
          Text(
            product.title,
            style: TextStyle(
              color: AppColors.text,
              fontSize: compact ? 26 : 40,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: compact ? 8 : 14),
          Container(
            width: compact ? 54 : 72,
            height: compact ? 4 : 6,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(height: compact ? 10 : 18),
          Text(
            product.description,
            style: TextStyle(
              color: AppColors.text,
              fontSize: compact ? 14 : 18,
              height: 1.32,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferDetails extends StatelessWidget {
  const _OfferDetails({
    required this.product,
    required this.compact,
    required this.onHire,
    required this.onCancel,
  });

  final BankProduct product;
  final bool compact;
  final VoidCallback onHire;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Valor estimado',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.estimatedValue,
            style: TextStyle(
              color: AppColors.orange,
              fontSize: compact ? 24 : 32,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: compact ? 14 : 22),
          const Text(
            'Principais benefícios',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          for (final benefit in product.benefits) ...[
            _BenefitLine(text: benefit, compact: compact),
            SizedBox(height: compact ? 6 : 9),
          ],
          SizedBox(height: compact ? 12 : 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.3),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 16,
                      vertical: compact ? 12 : 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onHire,
                  icon: const Icon(Icons.check),
                  label: const Text('Contratar'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 16,
                      vertical: compact ? 12 : 16,
                    ),
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

class _BenefitLine extends StatelessWidget {
  const _BenefitLine({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: compact ? 17 : 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.text,
              fontSize: compact ? 12.5 : 14.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
