import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/main.dart';

void main() {
  testWidgets('QuisquisLingo app exposes the rebranded title', (tester) async {
    await tester.pumpWidget(const QuisquisLingoApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'QuisquisLingo');
  });
}
