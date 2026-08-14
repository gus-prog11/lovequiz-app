import 'dart:io';

import 'package:LoveQuiz/features/game_engine/data/question_bank_v1.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_chapter.dart';
import 'package:flutter_test/flutter_test.dart';

final _nonWord = RegExp(r'[^\p{L}\p{N} ]+', unicode: true);
String norm(String s) => s.toLowerCase().replaceAll(_nonWord, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

Set<String> bigrams(String s) {
  final words = s.split(' ');
  final out = <String>{};
  for (var i = 0; i + 1 < words.length; i++) {
    out.add('${words[i]} ${words[i + 1]}');
  }
  return out;
}

double sim(String a, String b) {
  final sa = bigrams(a);
  final sb = bigrams(b);
  if (sa.isEmpty || sb.isEmpty) return 0;
  return sa.intersection(sb).length / sa.union(sb).length;
}

void main() {
  test('analisis', () async {
    final sb = StringBuffer();
    final qs = bancoV1Questions;

    final ids = <String, int>{};
    for (final q in qs) {
      ids[q.id] = (ids[q.id] ?? 0) + 1;
    }
    for (final e in ids.entries.where((e) => e.value > 1)) {
      sb.writeln('ID_DUP\t${e.key}\tx${e.value}');
    }

    final seen = <String, String>{};
    final dupTexts = <String>[];
    for (final q in qs) {
      final n = norm(q.text);
      if (n.isEmpty) continue;
      if (seen.containsKey(n)) {
        dupTexts.add('${seen[n]} <> ${q.id}: ${q.text}');
      } else {
        seen[n] = q.id;
      }
    }
    for (final d in dupTexts) {
      sb.writeln('TEXT_DUP\t$d');
    }

    final flagged = <String>[];
    for (var i = 0; i < qs.length; i++) {
      for (var j = i + 1; j < qs.length; j++) {
        if (qs[i].text == qs[j].text) continue;
        final s = sim(norm(qs[i].text), norm(qs[j].text));
        if (s >= 0.5) {
          flagged.add('${qs[i].id} | ${qs[i].text} ||| ${qs[j].id} | ${qs[j].text} | sim=${s.toStringAsFixed(2)}');
        }
      }
    }
    for (final f in flagged) {
      sb.writeln('NEAR_DUP\t$f');
    }

    sb.writeln('COUNTS\ttotal=${qs.length}\tidDups=${ids.entries.where((e) => e.value > 1).length}\ttextDups=${dupTexts.length}\tnearPairs=${flagged.length}');

    final ruleIssues = <String>[];
    for (final q in qs) {
      final ch = GameChapter.forChapter(q.chapter);
      final emoOk = ch.emotions.contains(q.emotion);
      final intMin = ch.minIntensity;
      final intMax = ch.maxIntensity;
      final i = q.intensity;
      final intOk = i.index >= intMin.index && i.index <= intMax.index;
      if (!emoOk || !intOk) {
        ruleIssues.add('${q.id}\t${q.chapter.name}\t${q.emotion.name}\t${q.intensity.name}\temoOk=$emoOk\tintOk=$intOk');
      }
    }
    for (final r in ruleIssues) {
      sb.writeln('RULE\t$r');
    }

    File(r'C:\Users\migue\AppData\Local\Temp\opencode\bank_analysis_low.tsv').writeAsStringSync(sb.toString());
  });
}
