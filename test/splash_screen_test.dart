import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/screens/splash_screen.dart';

void main() {
  testWidgets('splash shows the full-screen splash image', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      SplashScreen.splashImageAsset,
    );
    expect(image.fit, BoxFit.cover);

    // Unmount so the navigation timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
