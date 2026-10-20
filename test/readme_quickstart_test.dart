import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The README's quick start must be exactly `example/lib/quickstart.dart`,
/// which CI analyzes and tests, so the copy-paste sample can't rot.
void main() {
  test('README quick start matches example/lib/quickstart.dart', () {
    final readme = File('README.md').readAsStringSync();
    final start = readme.indexOf('<!-- quickstart:start -->');
    final end = readme.indexOf('<!-- quickstart:end -->');
    expect(start, isNonNegative, reason: 'quickstart start marker missing');
    expect(end, greaterThan(start), reason: 'quickstart end marker missing');

    final fence = RegExp(r'```dart\n([\s\S]*?)```')
        .firstMatch(readme.substring(start, end));
    expect(fence, isNotNull, reason: 'no dart code block between markers');

    final example = File('example/lib/quickstart.dart').readAsStringSync();
    expect(fence!.group(1)!.trim(), example.trim());
  });
}
