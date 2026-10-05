import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showmyname/features/display/widgets/effect_sign.dart';
import 'package:showmyname/models/sign_config.dart';
import 'package:showmyname/models/sign_mode.dart';

void main() {
  Widget marqueeSign(double fontScale) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 300,
        height: 180,
        child: EffectSign(
          config: SignConfig(
            message: 'LIVE TONIGHT VIP',
            usageMode: SignUsageMode.concert,
            signType: SignType.textMotion,
            concertTextEffect: ConcertTextEffect.marquee,
            fontScale: fontScale,
          ),
        ),
      ),
    );
  }

  testWidgets('Concert text size scales marquee text', (tester) async {
    await tester.pumpWidget(marqueeSign(0.7));
    await tester.pump();
    final smaller =
        tester.widget<Text>(find.byType(Text).first).style!.fontSize!;

    await tester.pumpWidget(marqueeSign(5.0));
    await tester.pump();
    final larger =
        tester.widget<Text>(find.byType(Text).first).style!.fontSize!;

    expect(larger, greaterThan(smaller));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
