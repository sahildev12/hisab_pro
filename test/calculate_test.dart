import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/core/calculate.dart';
import 'package:hisab_pro/core/copy_message.dart';
import 'package:hisab_pro/core/format.dart';
import 'package:hisab_pro/models/row_data.dart';
import 'package:hisab_pro/models/settlement_type.dart';

List<RowData> _exampleRows() {
  const data = [
    ('Sb.', '8490', '30'),
    ('Gw.', '5880', '35'),
    ('Db.', '7500', '81'),
    ('Dm.', '7570', '50'),
    ('Sg.', '7337', '211'),
    ('Ag.', '11732', '140'),
    ('Fb.', '16253', '65'),
    ('Al.', '10270', '100'),
    ('Gb.', '11500', '82.5'),
    ('Dw.', '10350', '35'),
    ('Gl.', '15700', '190'),
    ('Ds.', '8195', '40'),
  ];

  return data
      .asMap()
      .entries
      .map(
        (entry) => RowData(
          id: '${entry.key}',
          name: entry.value.$1,
          amount: entry.value.$2,
          bracket: entry.value.$3,
        ),
      )
      .toList();
}

void main() {
  test('calculate matches design spec example totals', () {
    final result = calculate(
      _exampleRows(),
      settlementType: SettlementType.lene,
    );

    expect(result.totalAmount, Decimal.parse('120777'));
    expect(result.totalBracket, Decimal.parse('1059.5'));
    expect(result.passing, Decimal.parse('101712'));
    expect(result.finalAmount, Decimal.parse('19065'));
  });

  test('formatIndianNumber formats currency values', () {
    expect(
      formatIndianNumber(Decimal.parse('19065'), showCurrency: true),
      '₹19,065',
    );
    expect(formatIndianNumber(Decimal.parse('120777')), '1,20,777');
  });

  test('copy message matches design spec format', () {
    final rows = _exampleRows();
    final result = calculate(rows, settlementType: SettlementType.lene);
    final message = buildCopyMessage(
      title: 'Modi bhai 96% 4',
      rows: rows,
      result: result,
    );

    expect(message, contains('Modi bhai 96% 4'));
    expect(message, contains('Sb. 8490 (30)'));
    expect(message, contains('Gb. 11500 (82.5)'));
    expect(message, contains('TOTAL 120777'));
    expect(message, contains('PASSING 1059.5 × 96 = 101712'));
    expect(message, contains('LENE AAJ = 19065'));
  });

  test('copy message uses DENE AAJ when selected', () {
    final rows = _exampleRows();
    final result = calculate(rows, settlementType: SettlementType.dene);
    final message = buildCopyMessage(
      title: 'Modi bhai 96% 4',
      rows: rows,
      result: result,
    );

    expect(message, contains('DENE AAJ = 19065'));
  });
}
