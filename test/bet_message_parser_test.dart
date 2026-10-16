import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_pro/core/bet_message_parser.dart';

void main() {
  group('bundle math', () {
    test('jodaEffectiveN cancels pairs', () {
      expect(BetMessageParser.jodaEffectiveN('4574'), 3);
      expect(BetMessageParser.jodaEffectiveN('12345'), 5);
      expect(BetMessageParser.jodaEffectiveN('482'), 3);
    });

    test('crossingN counts all digits', () {
      expect(BetMessageParser.crossingN('4574'), 4);
      expect(BetMessageParser.crossingN('12357890'), 8);
    });

    test('factor n²−n', () {
      expect(BetMessageParser.bundleFactor(8), 56);
      expect(BetMessageParser.bundleFactor(5), 20);
    });
  });

  group('crossing', () {
    test('12357890=3', () {
      final r = BetMessageParser.parseLine('12357890=3')! as BundleBetLine;
      expect(r.kind, BetMessageKind.crossing);
      expect(r.n, 8);
      expect(r.factor, 56);
      expect(r.clientPriceRs, Decimal.fromInt(3));
      expect(r.lineTotalRs, Decimal.fromInt(168));
    });

    test('01234678=2', () {
      final r = BetMessageParser.parseLine('01234678=2')! as BundleBetLine;
      expect(r.lineTotalRs, Decimal.fromInt(112));
    });
  });

  group('joda', () {
    test('12345 joda cut into 15', () {
      final r =
          BetMessageParser.parseLine('12345 joda cut into 15')! as BundleBetLine;
      expect(r.kind, BetMessageKind.joda);
      expect(r.n, 5);
      expect(r.factor, 20);
      expect(r.lineTotalRs, Decimal.fromInt(300));
    });

    test('12345 JK 15', () {
      final r = BetMessageParser.parseLine('12345 JK 15')! as BundleBetLine;
      expect(r.lineTotalRs, Decimal.fromInt(300));
    });

    test('4574 joda 15 uses n=3', () {
      final r = BetMessageParser.parseLine('4574 joda 15')! as BundleBetLine;
      expect(r.n, 3);
      expect(r.factor, 6);
      expect(r.lineTotalRs, Decimal.fromInt(90));
    });

    test('rejects 3-digit joda with repeat', () {
      expect(BetMessageParser.parseLine('464 joda 15'), isNull);
    });
  });

  group('single', () {
    test('11=5', () {
      final r = BetMessageParser.parseLine('11=5')! as SingleBetLine;
      expect(r.tableNumber, 11);
      expect(r.amountRs, Decimal.fromInt(5));
    });

    test('11+10', () {
      final r = BetMessageParser.parseLine('11+10')! as SingleBetLine;
      expect(r.amountRs, Decimal.fromInt(10));
    });

    test('00=5 normalizes to table 100', () {
      final r = BetMessageParser.parseLine('00=5')! as SingleBetLine;
      expect(r.tableNumber, 100);
    });

    test('100=5 normalizes to table 100', () {
      final r = BetMessageParser.parseLine('100=5')! as SingleBetLine;
      expect(r.tableNumber, 100);
    });

    test('11.25 as table 11 price 25', () {
      final r = BetMessageParser.parseLine('11.25')! as SingleBetLine;
      expect(r.tableNumber, 11);
      expect(r.amountRs, Decimal.fromInt(25));
    });
  });

  test('crossing wins over single for long digit string', () {
    final r = BetMessageParser.parseLine('12357890=3');
    expect(r, isA<BundleBetLine>());
    expect((r as BundleBetLine).kind, BetMessageKind.crossing);
  });
}
