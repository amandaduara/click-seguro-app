import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/activities_fixtures.dart';

void main() {
  ModuleDetailEntity parse(Map<String, dynamic> json) =>
      ModuleDetailModel.fromJson(json).toEntity();

  test('JSON do serviço → módulo com as lições e alternativas', () {
    final module = parse(moduleDetailJson(answered: {'l1'}));

    expect(module.title, 'Golpes Digitais');
    expect([for (final l in module.lessons) l.id], ['l1', 'l2', 'l3']);
    final first = module.lessons.first;
    expect(
      first.question,
      'Promessa de dinheiro em dobro pelo PIX. O que fazer?',
    );
    expect(first.imageUrl, 'https://img.test/l1.png');
    expect(first.isCompleted, isTrue);
    expect(module.lessons[1].isCompleted, isFalse);
    expect(
      [for (final o in first.options) o.text],
      ['Ignorar e denunciar', 'Enviar', 'Pedir prova', 'Repassar'],
    );
    expect(first.options.first.id, 'l1-o1');
  });

  test('ordena as lições por order', () {
    final module = parse(
      moduleDetailJson(
        lessons: [
          lessonJson(id: 'l3', order: 3),
          lessonJson(),
          lessonJson(id: 'l2', order: 2),
        ],
      ),
    );

    expect([for (final l in module.lessons) l.id], ['l1', 'l2', 'l3']);
  });

  test('lição com menos de 2 alternativas é descartada (CB-012)', () {
    final module = parse(
      moduleDetailJson(
        lessons: [
          lessonJson(options: const ['Só uma']),
          lessonJson(id: 'l2', order: 2),
        ],
      ),
    );

    expect([for (final l in module.lessons) l.id], ['l2']);
  });

  test('alternativa sem id ou texto não conta', () {
    final Map<String, dynamic> lesson = lessonJson();
    (lesson['options'] as List)
      ..[1] = {'id': 'l1-o2'}
      ..[2] = {'text': 'Sem id'};

    final module = parse(moduleDetailJson(lessons: [lesson]));

    expect(module.lessons, isEmpty);
  });

  test('lição sem id ou enunciado é descartada', () {
    final module = parse(
      moduleDetailJson(
        lessons: [
          lessonJson()..remove('id'),
          lessonJson(id: 'l2', order: 2)..remove('question'),
          lessonJson(id: 'l3', order: 3),
        ],
      ),
    );

    expect([for (final l in module.lessons) l.id], ['l3']);
  });

  test('imagem vazia ou ausente → null; isCompleted ausente → false', () {
    final module = parse(
      moduleDetailJson(
        lessons: [
          lessonJson(imageUrl: ''),
          lessonJson(id: 'l2', order: 2, imageUrl: null),
        ],
      ),
    );
    final Map<String, dynamic> raw = moduleDetailJson();
    (raw['lessons'] as List<Map<String, dynamic>>).first.remove('isCompleted');

    expect(module.lessons[0].imageUrl, isNull);
    expect(module.lessons[1].imageUrl, isNull);
    expect(parse(raw).lessons.first.isCompleted, isFalse);
  });
}
