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

    expect(message, contains('*TOTAL*'));
    expect(message, contains('*PASSING*'));
    expect(message, contains('LENE AAJ KE'));
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
      persistentHeader: '31-08-2026',
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

    expect(message, contains('*TOTAL* 120777-4831=115946'));
    expect(message, contains('*PASSING* 1059.5×96=101712'));
    expect(message, contains('*101712-115946=14234 LENE AAJ KE*'));
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

    expect(message, contains('*COMMISSION* 1775'));
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

  test('rows missing a bracket still contribute their amount', () {
    final result = calculateSettlement(
      [
        RowData(id: '1', name: 'Sb.', amount: '10000', bracket: '50'),
        RowData(id: '2', name: 'Gw.', amount: '5000', bracket: ''),
      ],
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );

    expect(result.totalAmount, Decimal.parse('15000'));
    expect(result.totalBracket, Decimal.parse('50'));
    expect(result.netTotalAmount, Decimal.parse('14400'));
    expect(result.finalBalance, Decimal.parse('9600'));
  });

  test('rows missing an amount still contribute their bracket', () {
    final result = calculateSettlement(
      [
        RowData(id: '1', name: 'Sb.', amount: '10000', bracket: '50'),
        RowData(id: '2', name: 'Gw.', amount: '', bracket: '20'),
      ],
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );

    expect(result.totalAmount, Decimal.parse('10000'));
    expect(result.totalBracket, Decimal.parse('70'));
    expect(result.resultType, ResultType.lene);
  });

  test('all-empty rows calculate to a balanced zero instead of throwing', () {
    final result = calculateSettlement(
      [RowData(id: '1', name: 'Sb.')],
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );

    expect(result.totalAmount, Decimal.zero);
    expect(result.totalBracket, Decimal.zero);
    expect(result.resultType, ResultType.balanced);
  });

  test('copy message lists partial rows so totals still add up', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '10000', bracket: '50'),
      RowData(id: '2', name: 'Gw.', amount: '5000', bracket: ''),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildPasteCopyMessage(
      title: 'Partial',
      rows: rows,
      result: result,
    );

    expect(message, contains('SB      10000'));
    expect(message, contains('GW      5000'));
    expect(message, contains('*TOTAL* 15000-600=14400'));
  });

  test('whatsapp copy message uses bold date, aligned rows, and compact totals', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '56000', bracket: '89.6'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildWhatsAppCopyMessage(
      title: 'MODI BHAI 96%4 (RAVI)',
      rows: rows,
      result: result,
      persistentHeader: '29-09-2026',
    );

    expect(message.startsWith('*29-09-2026*'), isTrue);
    expect(message, contains('*MODI BHAI 96%4 (RAVI)*'));
    expect(message, contains('56000'));
    expect(message, contains('(89.6)'));
    expect(message, isNot(contains('( 89.6)')));
    expect(message, contains('*TOTAL* 56000-2240=53760'));
    expect(message, contains('*PASSING* 89.6×96=8601.6'));
    expect(message, contains('*8601.6-53760=45158 LENE AAJ KE*'));
  });

  test('copy message keeps leading zeros and aligns brackets without inner spaces', () {
    final rows = [
      RowData(id: '1', name: 'Sb.', amount: '06', bracket: '09'),
      RowData(id: '2', name: 'Gw.', amount: '2484', bracket: '979'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildWhatsAppCopyMessage(
      title: 'SANJAY',
      rows: rows,
      result: result,
    );

    expect(message, contains('06'));
    expect(message, contains('(09)'));
    expect(message, contains('2484'));
    expect(message, contains('(979)'));
    expect(message, isNot(contains('( 09)')));
    expect(message, isNot(contains('( 979)')));

    final rowLines = message
        .split('\n')
        .where((line) => line.contains('(') && line.contains(')'))
        .toList();
    final bracketColumns = rowLines.map((line) => line.indexOf('(')).toSet();
    expect(bracketColumns.length, 1, reason: 'All brackets should align');

    final amountStarts = rowLines
        .map((line) => line.indexOf(RegExp(r'\d')))
        .toSet();
    expect(amountStarts.length, 1, reason: 'All amounts should start together');
  });

  test('copy message matches reference spacing for mixed amount widths', () {
    final rows = [
      RowData(id: '1', name: 'Gw.', amount: '4888', bracket: '794'),
      RowData(id: '2', name: 'Dm.', amount: '596', bracket: '49'),
      RowData(id: '3', name: 'Db.', amount: '5997', bracket: '46'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildWhatsAppCopyMessage(
      title: 'MY CALCULATIONS',
      rows: rows,
      result: result,
      persistentHeader: '29-10-2026',
    );

    final rowLines = message
        .split('\n')
        .where((line) => line.contains('(') && line.contains(')'))
        .toList();
    expect(rowLines.length, 3);
    expect(
      rowLines.every((line) => line.startsWith(RegExp(r'[A-Z]{2}\s'))),
      isTrue,
    );

    const figSpace = '\u2007';
    expect(rowLines[0], 'GW      4888${figSpace * 3}(794)');
    expect(rowLines[1], 'DM      596${figSpace * 4}(49)');
    expect(rowLines[2], 'DB      5997${figSpace * 3}(46)');

    final amountStarts = rowLines
        .map((line) => line.indexOf(RegExp(r'\d')))
        .toSet();
    expect(amountStarts.length, 1);
  });

  test('copy message aligns amounts for short and long names', () {
    final rows = [
      RowData(id: '1', name: 'Sp.', amount: '100', bracket: '10'),
      RowData(id: '2', name: 'MODI BHAI', amount: '200', bracket: '20'),
      RowData(id: '3', name: 'A', amount: '300', bracket: '30'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildWhatsAppCopyMessage(
      title: 'TEST',
      rows: rows,
      result: result,
    );

    final rowLines = message
        .split('\n')
        .where((line) => line.contains('(') && line.contains(')'))
        .toList();
    final amountStarts = rowLines
        .map((line) => line.indexOf(RegExp(r'\d')))
        .toSet();
    expect(amountStarts.length, 1);
  });

  test('copy message omits brackets when empty or zero', () {
    final rows = [
      RowData(id: '1', name: 'Db.', amount: '5997', bracket: ''),
      RowData(id: '2', name: 'Sg.', amount: '4694', bracket: '0'),
      RowData(id: '3', name: 'Gw.', amount: '4888', bracket: '794'),
    ];
    final result = calculateSettlement(
      rows,
      passingRate: Decimal.parse('96'),
      amountDeductionRate: Decimal.parse('4'),
    );
    final message = buildWhatsAppCopyMessage(
      title: 'MY CALCULATIONS',
      rows: rows,
      result: result,
    );

    expect(message, contains('DB      5997\n'));
    expect(message, contains('SG      4694\n'));
    expect(message, contains('GW      4888'));
    expect(message, contains('(794)'));
    expect(message, isNot(contains('()')));
    expect(message, isNot(contains('(0)')));
  });
}
