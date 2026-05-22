// Tests for `Menu3DotsModel` — trivial value class.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/menu_three_dots.dart';

void main() {
  group('Menu3DotsModel', () {
    test('constructor positional', () {
      final m = Menu3DotsModel('Editar', 'Modificar item', Icons.edit, 'edit');
      expect(m.title, 'Editar');
      expect(m.subtitle, 'Modificar item');
      expect(m.icons, Icons.edit);
      expect(m.action, 'edit');
    });

    test('campos son mutables', () {
      final m = Menu3DotsModel('A', 'B', Icons.add, 'a');
      m.title = 'C';
      expect(m.title, 'C');
    });
  });
}
