import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/core/calculate.dart';
import 'package:hisab_pro/core/smart_text_parser.dart';
import 'package:hisab_pro/core/validate.dart';
import 'package:hisab_pro/models/row_data.dart';

const _sampleText = '''
Modi bhai 96%4

Sb.       6995    ( 30 )
Gw.       8322      ( 70 )
Db.       8230     ( 100 )
Dm.       6140     ( 55 )
Sg.       6684    ( 72 )
Ag.       4850     ( 35 )
Fb.       11600     ( 105 )
Al.       8550     ( 115 )
Gb.       16292     ( 67 )
Dw.        6300     ( 35 )
Gl.       15732     ( 90 )
''';

void main() {
  test('parses Modi bhai sample with rates and 11 entries', () {
    const names = [
      'Sb.', 'Gw.', 'Db.', 'Dm.', 'Sg.', 'Ag.', 'Fb.', 'Al.', 'Gb.', 'Dw.', 'Gl.',
    ];
    final output = SmartTextParser.parse(_sampleText, allowedEntryNames: names);

    expect(output.errors, isEmpty);
    expect(output.result, isNotNull);
    expect(output.result!.title.toLowerCase(), contains('modi bhai'));
    expect(output.result!.passingRate, Decimal.fromInt(96));
    expect(output.result!.amountDeductionRate, Decimal.fromInt(4));
    expect(output.result!.rows.length, 11);

    expect(output.result!.rows.first.name, 'Sb.');
    expect(output.result!.rows.first.amount, '6995');
    expect(output.result!.rows.first.bracket, '30');
  });

  test('smart and manual calculator produce identical results', () {
    const names = ['Sb.', 'Gw.'];
    final manualRows = [
      RowData(id: '1', name: 'Sb.', amount: '6995', bracket: '30'),
      RowData(id: '2', name: 'Gw.', amount: '8322', bracket: '70'),
    ];
    final manual = calculateSettlement(
      manualRows,
      passingRate: Decimal.fromInt(96),
      amountDeductionRate: Decimal.fromInt(4),
    );

    final output = SmartTextParser.parse(
      'Test 96%4\nSb. 6995 (30)\nGw. 8322 (70)',
      allowedEntryNames: names,
    );
    expect(output.errors, isEmpty);

    final validation = validateRows(output.result!.rows, allowedNames: names);
    expect(validation.isValid, isTrue);

    final smart = calculateSettlement(
      output.result!.rows,
      passingRate: Decimal.fromInt(96),
      amountDeductionRate: Decimal.fromInt(4),
    );

    expect(smart.displayAmount, manual.displayAmount);
    expect(smart.resultType, manual.resultType);
    expect(smart.totalAmount, manual.totalAmount);
    expect(smart.passing, manual.passing);
  });

  test('reports error for invalid entry line', () {
    final output = SmartTextParser.parse(
      'Test 96%4\nSb. abc (30)',
      allowedEntryNames: ['Sb.'],
    );
    expect(output.result, isNull);
    expect(output.errors, isNotEmpty);
  });
}
