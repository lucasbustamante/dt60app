import 'package:flutter/material.dart';

import '../widgets/ad_carousel.dart';
import '../widgets/app_frame.dart';

class StandbyScreen extends StatelessWidget {
  const StandbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      showSteps: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          final intro = const InstructionPanel(
            title: 'Conheça soluções feitas para você',
            maxWidth: 360,
            messageSpans: [],
            helpText: 'Toque aqui para falar',
            helpSubtitle: 'com nosso atendimento.',
          );

          if (wide) {
            return Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Align(alignment: Alignment.centerLeft, child: intro),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: SizedBox(
                      height: constraints.maxHeight.clamp(280.0, 420.0),
                      child: const AdCarousel(),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                const SizedBox(height: 340, child: AdCarousel()),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
