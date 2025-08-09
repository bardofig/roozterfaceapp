// lib/data/options_data.dart

const List<String> combTypeOptions = [
  'Simple',
  'Rosa',
  'Triple (Guisante)',
  'Cereza',
  'De Cinco Puntas',
  'Pava',
  'Sierra',
  'Doble (Abosado)',
  'Penacho (Tassel)',
  'Con Barba (Muffed)',
  'Otra',
];

const List<String> plumageColorOptions = [
  'Colorado',
  'Colorado Pecho Negro (Black-breasted red)',
  'Colorado Pinta Negra (Spangled)',
  'Giro',
  'Giro Plateado (Silver-grey)',
  'Giro Limón (Lemon/Clemon)',
  'Giro Miel (Honey-colored)',
  'Negro',
  'Negro con reflejos verdes (Tuzo)',
  'Blanco',
  'Cenizo (Blue)',
  'Cenizo Colorado (Blue-red)',
  'Trigueño (Wheaten)',
  'Pardo Colorado (Brown-red)',
  'Canelo',
  'Cuclillo (Cuckoo)',
  'Dorado (Gold)',
  'Plateado (Silver)',
  'Ala de Pato (Duckwing)',
  'Limonado (Blue Lemon)',
  'Otro',
];

const List<String> legColorOptions = [
  'Amarilla',
  'Blanca',
  'Negra',
  'Verde',
  'Gris',
  'Azul',
  'Rosada',
  'Otra',
];

const List<String> weaponTypeOptions = [
  'Navaja de 1 pulgada',
  'Navaja de 1 pulgada, 2 líneas',
  'Espuela Natural',
  'Espuela de Plástico',
  'Pico y Espuela (sin arma)',
  'Otra',
];

// --- ¡NUEVA LISTA DE DURACIÓN DE PELEA! ---
// Generamos una lista de "1 minuto", "2 minutos", etc., hasta 20.
final List<String> fightDurationOptions = List.generate(
  20,
  (index) => '${index + 1} minuto${index == 0 ? '' : 's'}',
);
