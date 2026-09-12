import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/core/calculate.dart';
import 'package:hisab_pro/core/copy_message.dart';
import 'package:hisab_pro/core/format.dart';
import 'package:hisab_pro/core/money.dart';
import 'package:hisab_pro/core/validate.dart';
import 'package:hisab_pro/models/result_type.dart';
import 'package:hisab_pro/models/row_data.dart';

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
  test('user example 56000 / 4% / 89.6 / 96 yields LENE 45158', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '56000', bracket: '89.6'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );

    expect(result.totalAmount, Decimal.parse('56000'));
    expect(result.amountDeduction, Decimal.parse('2240'));
    expect(result.netTotalAmount, Decimal.parse('53760'));
    expect(result.totalBracket, Decimal.parse('89.6'));
    expect(result.passing, Decimal.parse('8601.6'));
    expect(result.finalBalance, Decimal.parse('45158'));
    expect(result.displayAmount, Decimal.parse('45158'));
    expect(result.resultType, ResultType.lene);
  });

  test('sample data at 96% passing and 4% deduction yields LENE ₹14,234', () {
    final result = calculateSettlement(
      _exampleRows(),
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );

    expect(result.totalAmount, Decimal.parse('120777'));
    expect(result.amountDeduction, Decimal.parse('4831'));
    expect(result.netTotalAmount, Decimal.parse('115946'));
    expect(result.totalBracket, Decimal.parse('1059.5'));
    expect(result.passing, Decimal.parse('101712'));
    expect(result.finalBalance, Decimal.parse('14234'));
    expect(result.displayAmount, Decimal.parse('14234'));
    expect(result.resultType, ResultType.lene);
  });

  test('amount deduction rounds to nearest rupee', () {
    final deduction = roundMoney(
      percentOf(Decimal.parse('120777'), Decimal.parse('4')),
    );
    expect(deduction, Decimal.parse('4831'));
  });

  test('negative balance yields DENE with absolute display', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '100000', bracket: '1000'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('100'),
      amountDeductionRate: Decimal.parse('10'),
    );

    expect(result.netTotalAmount, Decimal.parse('90000'));
    expect(result.passing, Decimal.parse('100000'));
    expect(result.finalBalance, Decimal.parse('-10000'));
    expect(result.displayAmount, Decimal.parse('10000'));
    expect(result.resultType, ResultType.dene);
  });

  test('zero balance yields HISAB BARABAR', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '105263', bracket: '1000'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('100'),
      amountDeductionRate: Decimal.parse('5'),
    );

    expect(result.netTotalAmount, Decimal.parse('100000'));
    expect(result.passing, Decimal.parse('100000'));
    expect(result.finalBalance, Decimal.zero);
    expect(result.displayAmount, Decimal.zero);
    expect(result.resultType, ResultType.balanced);
  });

  test('amount must be whole number', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '5000.50', bracket: '10'),
    ];
    final result = validateRows(rows, allowedNames: ['Sb.']);
    expect(result.isValid, false);
    expect(result.errorMessage, contains('whole number'));
  });

  test('formatMoney shows no decimals', () {
    expect(
      formatMoney(Decimal.parse('45158'), showCurrency: true),
      '₹45,158',
    );
    expect(formatPassingAmount(Decimal.parse('8601.6')), '8,601.6');
  });

  test('copy message uses compact three-line summary', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '2255', bracket: '88'),
      RowData(id: '2', name: 'Gw.', amount: '2215', bracket: '10'),
      RowData(id: '3', name: 'Db.', amount: '6665', bracket: '5'),
      RowData(id: '4', name: 'Dm.', amount: '200', bracket: '10'),
      RowData(id: '5', name: 'Sg.', amount: '1500', bracket: '12'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildCopyMessage(
      title: 'Calculation',
      rows: rows,
      result: result,
    );

    expect(message, contains('TOTAL 12835 - 513 = 12322'));
    expect(message, contains('PASSING 125 × 96 = 12,000'));
    expect(message, contains('12,322 - 12,000 = 322 lene aaj.'));
  });

  test('copy message includes persistent header when set', () {
    final rows = _exampleRows();
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildCopyMessage(
      title: 'Sample calculation',
      rows: rows,
      result: result,
      persistentHeader: '12 Sep 2026',
    );

    expect(message.startsWith('12 Sep 2026'), isTrue);
    expect(message, contains('Sample calculation'));
  });

  test('copy message includes deduction and passing steps', () {
    final rows = _exampleRows();
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildCopyMessage(
      title: 'Sample calculation',
      rows: rows,
      result: result,
    );

    expect(message, contains('TOTAL 120777 - 4831 = 115946'));
    expect(message, contains('PASSING 1059.5 × 96 = 1,01,712'));
    expect(message, contains('1,15,946 - 1,01,712 = 14,234 lene aaj.'));
  });

  test('different calculations keep their own rates', () {
    final rows = _exampleRows();
    final at96x4 = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final at95x5 = calculateSettlement(
      rows,
      passingRate: Decimal.parse('95'),
      amountDeductionRate: Decimal.parse('5'),
    );

    expect(at96x4.passing, Decimal.parse('101712'));
    expect(at95x5.passing, Decimal.parse('100652.5'));
    expect(at96x4.passingRate, Decimal.parse('96'));
    expect(at95x5.amountDeductionRate, Decimal.parse('5'));
  });
}
