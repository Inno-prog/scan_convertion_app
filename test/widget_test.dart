import 'package:flutter_test/flutter_test.dart';
import 'package:file_converter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FileConverterApp());
    expect(find.byType(FileConverterApp), findsOneWidget);
  });
}
