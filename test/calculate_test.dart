import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/core/calculate.dart';
import 'package:hisab_pro/core/commission.dart';
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

List<RowData> _acceptanceRows() => [
      RowData(id: '1', name: 'Sb.', amount: '35498', bracket: '255'),
    ];

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
    expect(result.commissionEarned, Decimal.parse('2240'));
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
    expect(result.commissionEarned, Decimal.parse('4831'));
    expect(result.netTotalAmount, Decimal.parse('115946'));
    expect(result.totalBracket, Decimal.parse('1059.5'));
    expect(result.passing, Decimal.parse('101712'));
    expect(result.finalBalance, Decimal.parse('14234'));
    expect(result.displayAmount, Decimal.parse('14234'));
    expect(result.resultType, ResultType.lene);
  });

  test('amount deduction rounds to nearest rupee', () {
    final deduction = roundMoney(
      percentOf(Decimal.parse('35498'), Decimal.parse('5')),
    );
    expect(deduction, Decimal.parse('1775'));
  });

  test('negative balance yields DENE with absolute display', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '10000', bracket: '200'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('100'),
      amountDeductionRate: Decimal.parse('10'),
    );

    expect(result.resultType, ResultType.dene);
    expect(result.displayAmount, Decimal.parse('11000'));
  });

  test('zero balance yields HISAB BARABAR', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '10000', bracket: '90'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('100'),
      amountDeductionRate: Decimal.parse('10'),
    );

    expect(result.resultType, ResultType.balanced);
    expect(result.displayAmount, Decimal.zero);
  });

  test('amount must be whole number', () {
    expect(isWholeNumberAmount('1770.50'), isFalse);
    expect(isWholeNumberAmount('1770'), isTrue);
  });

  test('formatMoney shows no decimals', () {
    expect(formatMoney(Decimal.parse('1774.90')), '1,775');
  });

  test('copy message uses compact three-line summary', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '56000', bracket: '89.6'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildCopyMessage(
      title: 'Sample',
      rows: rows,
      result: result,
    );

    expect(message, contains('TOTAL'));
    expect(message, contains('PASSING'));
    expect(message, contains('lene aaj'));
  });

  test('copy message includes persistent header when set', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '1000', bracket: '10'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildCopyMessage(
      title: 'Sample',
      rows: rows,
      result: result,
      persistentHeader: '*31-08-2026*',
    );

    expect(message.startsWith('*31-08-2026*'), isTrue);
  });

  test('copy message includes deduction and passing steps', () {
    final result = calculateSettlement(
      _exampleRows(),
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildCopyMessage(
      title: 'Sample',
      rows: _exampleRows(),
      result: result,
    );

    expect(message, contains('TOTAL      120777 - 4831 = 115946'));
    expect(message, contains('PASSING    1059.5 × 96 = 1,01,712'));
    expect(message, contains('1,15,946 - 1,01,712 = 14,234 lene aaj.'));
  });

  test('TEST A — daily commission deducts from total', () {
    final result = calculateSettlement(
      _acceptanceRows(),
      passingRate: Decimal.parse('95'),
      amountDeductionRate: Decimal.parse('5'),
      commissionTracking: false,
    );

    expect(result.commissionEarned, Decimal.parse('1775'));
    expect(result.netTotalAmount, Decimal.parse('33723'));
    expect(result.passing, Decimal.parse('24225'));
    expect(result.displayAmount, Decimal.parse('9498'));
    expect(result.resultType, ResultType.lene);
  });

  test('TEST B — commission tracking keeps full total for settlement', () {
    final result = calculateSettlement(
      _acceptanceRows(),
      passingRate: Decimal.parse('95'),
      amountDeductionRate: Decimal.parse('5'),
      commissionTracking: true,
      storedCommissionBalance: Decimal.zero,
    );

    expect(result.commissionEarned, Decimal.parse('1775'));
    expect(result.netTotalAmount, Decimal.parse('35498'));
    expect(result.passing, Decimal.parse('24225'));
    expect(result.displayAmount, Decimal.parse('11273'));
    expect(result.commissionBalance, Decimal.parse('1775'));
    expect(result.resultType, ResultType.lene);
  });

  test('TEST C — commission balance accumulates', () {
    final result = calculateSettlement(
      _acceptanceRows(),
      passingRate: Decimal.parse('95'),
      amountDeductionRate: Decimal.parse('5'),
      commissionTracking: true,
      storedCommissionBalance: Decimal.parse('5000'),
    );

    expect(result.commissionBalance, Decimal.parse('6775'));
    expect(
      adjustCommissionBalance(
        currentBalance: Decimal.parse('5000'),
        previousEarned: Decimal.zero,
        newEarned: Decimal.parse('1775'),
      ),
      Decimal.parse('6775'),
    );
  });

  test('copy message includes commission when tracking is on', () {
    final result = calculateSettlement(
      _acceptanceRows(),
      passingRate: Decimal.parse('95'),
      amountDeductionRate: Decimal.parse('5'),
      commissionTracking: true,
    );
    final message = buildCopyMessage(
      title: 'Rohit 95%5',
      rows: _acceptanceRows(),
      result: result,
    );

    expect(message, contains('COMMISSION 1,775'));
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
