import 'package:flutter_test/flutter_test.dart';

import 'package:circulation/core/models/incivi_type.dart';
import 'package:circulation/core/plate/cote_ivoire_plate.dart';
import 'package:circulation/core/services/plate_detection_service.dart';

void main() {
  test('Les types d\'incivisme par défaut sont disponibles', () {
    expect(InciviTypeDefaults.all.isNotEmpty, isTrue);
    expect(
      InciviTypeDefaults.all.any((t) => t['id'] == 'mauvais_stationnement'),
      isTrue,
    );
  });

  test('La plaque ivoirienne se normalise et se valide', () {
    expect(CoteIvoirePlate.normalize('ab-1234'), 'AB1234');
    expect(CoteIvoirePlate.isValid('AB1234'), isTrue);
    expect(CoteIvoirePlate.isValid('AB'), isFalse);
  });

  test('L\'OCR corrige les confusions lettres/chiffres', () {
    expect(CoteIvoirePlate.correctOcr('AB12O4'), 'AB1204');
    expect(CoteIvoirePlate.correctOcr('OB1234'), 'OB1234');
    expect(CoteIvoirePlate.correctOcr('0B1234'), 'OB1234');
  });

  test('Les candidats OCR génèrent une plaque valide', () {
    expect(CoteIvoirePlate.candidates('AB1234'), contains('AB1234'));
    expect(CoteIvoirePlate.candidates('AB12O4'), contains('AB1204'));
    expect(CoteIvoirePlate.candidates('XY'), isEmpty);
  });

  test('L\'extraction de plaque score et nettoie le texte OCR', () {
    final service = PlateDetectionService();
    final plates = service.extractPlates(
      'Voiture immat AB-1234-CD\n'
      'Circulation\n'
      'plaque AB 5678 ZW stationnée',
    );
    expect(plates, contains('AB1234CD'));
    expect(plates.first, 'AB1234CD');
  });
}
