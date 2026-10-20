import 'package:circulation/core/services/plate_recognizer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlateRecognizer trie les résultats par score', () {
    final results = PlateRecognizerService.parseResults('''
      {
        "results": [
          {"plate": "ab123cd", "score": 0.4, "region": {"code": "ci"}},
          {"plate": "XY987ZW", "score": 0.9, "region": {"code": "ci"}},
          {"plate": "", "score": 0.99}
        ]
      }
    ''');

    expect(results, hasLength(2));
    expect(results.first.plate, 'XY987ZW');
    expect(results.first.score, 0.9);
    expect(results.first.region, 'ci');
  });

  test('PlateRecognizer ignore un corps JSON sans résultats', () {
    expect(PlateRecognizerService.parseResults('{}'), isEmpty);
    expect(PlateRecognizerService.parseResults('{"results": "oops"}'), isEmpty);
    expect(
      () => PlateRecognizerService.parseResults('not-json'),
      throwsA(isA<FormatException>()),
    );
  });
}
