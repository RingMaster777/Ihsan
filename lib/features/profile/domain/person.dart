import 'package:flutter/material.dart';

/// Stable identifiers. The `name` of each value is also the storage key, so
/// do not rename them (it would break existing backups).
enum PersonId {
  faisal,
  aaraf,
  kakon;

  static PersonId? tryParse(Object? value) {
    if (value is! String) return null;
    for (final id in PersonId.values) {
      if (id.name == value) return id;
    }
    return null;
  }
}

@immutable
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarAsset,
    required this.accent,
    required this.accentSoft,
  });

  final PersonId id;
  final String name;
  final String role;
  final String avatarAsset;

  /// Strong accent (names, icons) and a soft tint (borders, rings).
  final Color accent;
  final Color accentSoft;

  static const Map<PersonId, Person> all = {
    PersonId.faisal: Person(
      id: PersonId.faisal,
      name: 'Faisal',
      role: 'Father',
      avatarAsset: 'assets/images/faisal.jpg',
      accent: Color(0xFF186888),
      accentSoft: Color(0xFF88C8E0),
    ),
    PersonId.aaraf: Person(
      id: PersonId.aaraf,
      name: "A'araf",
      role: 'Son',
      avatarAsset: 'assets/images/aaraf.jpg',
      accent: Color(0xFF187848),
      accentSoft: Color(0xFF88D8A8),
    ),
    PersonId.kakon: Person(
      id: PersonId.kakon,
      name: 'Kakon',
      role: 'Mother',
      avatarAsset: 'assets/images/kakon.jpg',
      accent: Color(0xFF983858),
      accentSoft: Color(0xFFF0A8C0),
    ),
  };

  static Person of(PersonId id) => all[id]!;
  static List<Person> get list => PersonId.values.map(of).toList();
}
