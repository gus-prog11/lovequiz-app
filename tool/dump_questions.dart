import 'dart:io';

import 'package:LoveQuiz/features/game_engine/data/question_bank_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dump', () async {
    final sb = StringBuffer();
    for (final q in bancoV1Questions) {
      sb.writeln('${q.id}\t${q.chapter.name}\t${q.emotion.name}\t${q.intensity.name}\t${q.type.name}\t${q.category.name}\t${q.source.name}\t${q.status.name}\t${q.text}');
    }
    File(r'C:\Users\migue\AppData\Local\Temp\opencode\bank_dump.tsv').writeAsStringSync(sb.toString());
  });
}
