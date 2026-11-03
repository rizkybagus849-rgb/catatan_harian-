import 'package:catatan_harian/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Tampil kosong lalu bisa menambah catatan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CatatanHarianApp());
    await tester.pumpAndSettle();

    expect(find.text('Catatan Harian'), findsOneWidget);
    expect(find.textContaining('Belum ada catatan'), findsOneWidget);

    await tester.tap(find.text('Catatan Baru'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Hari ini');
    await tester.enterText(find.byType(TextField).at(1), 'Belajar Flutter');
    await tester.tap(find.text('Simpan').last);
    await tester.pumpAndSettle();

    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Belajar Flutter'), findsOneWidget);
  });

  testWidgets('Bisa menghapus catatan dari daftar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CatatanHarianApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catatan Baru'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Judul yang akan dihapus');
    await tester.enterText(find.byType(TextField).at(1), 'Isi catatan');
    await tester.tap(find.text('Simpan').last);
    await tester.pumpAndSettle();

    expect(find.text('Judul yang akan dihapus'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Judul yang akan dihapus'), findsNothing);
    expect(find.textContaining('Belum ada catatan'), findsOneWidget);
  });
}
