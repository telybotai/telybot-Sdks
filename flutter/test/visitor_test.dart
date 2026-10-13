import 'package:flutter_test/flutter_test.dart';
import 'package:telybot/src/chat_page.dart';
import 'package:telybot/src/visitor.dart';

/// `setVisitor`'s cleaning, which must drop exactly what the chat page drops.
void main() {
  // Built from code points: a lone half cannot be written in a source file.
  final String loneHalf = String.fromCharCode(0xD83D);
  final String grin = String.fromCharCodes(<int>[0x1F600]);
  final String joiner = String.fromCharCode(0x200D);
  final String softHyphen = String.fromCharCode(0x00AD);

  test('keeps well-formed details', () {
    final TelyBotVisitor? v =
        TelyBotVisitor.of(name: '  Asha \n Rao ', phone: '+91 98765 43210', email: 'asha@example.com');
    expect(v?.name, 'Asha Rao');
    expect(v?.phone, '+91 98765 43210');
    expect(v?.email, 'asha@example.com');
    expect(v?.fragmentItems(), <String>['name=Asha%20Rao', 'phone=%2B91%2098765%2043210', 'email=asha%40example.com']);
  });

  test('drops what does not look like what it claims, whole', () {
    expect(TelyBotVisitor.of(name: 'a' * 81, phone: 'call me', email: 'x@y'), isNull);
    expect(TelyBotVisitor.of(), isNull);
    expect(TelyBotVisitor.of(name: ' \t\n '), isNull);
    expect(TelyBotVisitor.of(phone: '12', email: 'a@b.co')?.phone, '');
  });

  test('name: 1 to 80 characters on one line, nothing else taken out', () {
    expect(TelyBotVisitor.cleanName('a' * 80), 'a' * 80);
    expect(TelyBotVisitor.cleanName('a' * 81), '', reason: 'dropped, not cut');
    expect(TelyBotVisitor.cleanName(grin * 80), grin * 80, reason: 'counted in characters');
    expect(TelyBotVisitor.cleanName('Asha${String.fromCharCodes(<int>[0, 1, 9])}Rao'), 'Asha Rao');
    expect(TelyBotVisitor.cleanName('Asha${String.fromCharCode(0x7F)}Rao'), 'Asha Rao');
    expect(TelyBotVisitor.cleanName('Asha$loneHalf Rao'), 'Asha Rao');
    expect(TelyBotVisitor.cleanName('A${joiner}B${softHyphen}C'), 'A${joiner}B${softHyphen}C');
  });

  test('phone: 8 to 15 digits, and no "+0"', () {
    expect(TelyBotVisitor.cleanPhone(' 9876 5432 '), '9876 5432');
    expect(TelyBotVisitor.cleanPhone('987 6543'), '', reason: '7 digits');
    expect(TelyBotVisitor.cleanPhone('+1 (234) 567-8901.234'), '+1 (234) 567-8901.234');
    expect(TelyBotVisitor.cleanPhone('1234567890123456'), '', reason: '16 digits');
    expect(TelyBotVisitor.cleanPhone('+0 98765 43210'), '');
    expect(TelyBotVisitor.cleanPhone('98765 43210 ext 2'), '');
    expect(TelyBotVisitor.cleanPhone('9' * 8 + ' ' * 25), '9' * 8, reason: 'trimmed first');
    expect(TelyBotVisitor.cleanPhone('9  ' * 12), '', reason: '12 digits, but 34 characters');
  });

  test('email: a real-looking address up to 254 characters', () {
    expect(TelyBotVisitor.cleanEmail(' asha@example.co.in '), 'asha@example.co.in');
    expect(TelyBotVisitor.cleanEmail('asha@example.c'), '', reason: 'a one-letter ending');
    expect(TelyBotVisitor.cleanEmail('asha..rao@example.com'), '');
    expect(TelyBotVisitor.cleanEmail('asha@example..com'), '');
    expect(TelyBotVisitor.cleanEmail('asha rao@example.com'), '');
    expect(TelyBotVisitor.cleanEmail('${'a' * 242}@example.com'), '${'a' * 242}@example.com');
    expect(TelyBotVisitor.cleanEmail('${'a' * 243}@example.com'), '', reason: '255 characters');
  });

  test('the start question: no lone halves, cut at 500 whole characters', () {
    expect(cleanQuestion('  Is it in stock?$loneHalf '), 'Is it in stock?');
    final String q = cleanQuestion('${'a' * 499}$grin${'b' * 10}');
    expect(q.runes.length, 500);
    expect(q.endsWith(grin), isTrue);
    expect(Uri.encodeComponent(cleanQuestion('a${loneHalf}b')), 'ab');
  });
}
