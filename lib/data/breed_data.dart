// lib/data/breed_data.dart

// Clase que define la estructura de una raza/línea
class BreedProfile {
  final String name;
  final String origin;
  final String fightingStyle;
  final String physicalChars;
  final String plumageColors;
  final String combTypes;
  final String breedingNotes;

  const BreedProfile({
    required this.name,
    required this.origin,
    required this.fightingStyle,
    required this.physicalChars,
    required this.plumageColors,
    required this.combTypes,
    required this.breedingNotes,
  });
}

// Lista COMPLETA que contiene la información de cada raza/línea
const List<BreedProfile> breedProfiles = [
  BreedProfile(
    name: 'Sweater',
    origin:
        'Desarrollada por Carol Nesmith. Origen sugerido de cruces entre Hatch Patas Amarillas y Kelso.',
    fightingStyle:
        'Destaca en agilidad y velocidad. Son audaces y pueden derrotar a oponentes mucho más grandes aprovechando su tamaño. Son "cortadores" por excelencia.',
    physicalChars:
        'Peso típico de 3 a 5 libras. Cuerpos largos pero no altos. Colas de tamaño mediano y ligeramente curvadas.',
    plumageColors: 'Similares a los Hatch, Kelso y Radio.',
    combTypes: 'Varía según el cruce, comúnmente Simple o Pava.',
    breedingNotes:
        'Muy popular. Fácil de cruzar con Hatch, Kelso, Radio, Albany, etc. Tienen una gran prepotencia (transmiten bien sus genes) y se adaptan a diversos climas.',
  ),
  BreedProfile(
    name: 'Kelso',
    origin:
        'Una de las razas más importantes. Vinculada a Walter A. Kelso. Sus líneas de base incluyen Murphy, Albany, McClanahan y Claret.',
    fightingStyle:
        'Famosos por su táctica estratégica de "entrar y salir". Fintan antes de dar un golpe decisivo. Inteligentes y excelentes atacantes.',
    physicalChars:
        'Aves grandes, con un peso de 6 a 8 libras. Cabeza elegante que les da una apariencia inteligente.',
    plumageColors:
        'Plumaje impresionante e iridiscente, con colores vivos. Se encuentran en variaciones rojizas, limón, amarillas y pinto.',
    combTypes: 'Varía, comúnmente Simple o Pava.',
    breedingNotes:
        'Muy exitosos en cruces como Kelso-Hatch, Kelso-Sweater, Kelso-Radio y Kelso-Asil. Biboy Enriquez es conocido por producir Kelsos fuertes.',
  ),
  BreedProfile(
    name: 'Hatch',
    origin:
        'Originada por Sandy Hatch a partir de aves negro-rojas, incorporó líneas como Kearney Whitehackle y Claret. La línea de Patas Amarillas (Yellow Legged Hatch) es muy importante.',
    fightingStyle:
        'Conocidos por su poder, agilidad y reflejos agudos. Son aves de choque muy efectivas.',
    physicalChars:
        'Aves fuertes y bien proporcionadas. Las líneas de Patas Amarillas son una característica distintiva.',
    plumageColors: 'Principalmente colorados, con variaciones según la línea.',
    combTypes: 'Principalmente cresta Simple, a veces Pava.',
    breedingNotes:
        'Clasificada entre las diez mejores líneas. Cruza excelentemente con Sweater, Roundhead, Albany, Giro, Radio y Asil.',
  ),
  BreedProfile(
    name: 'Roundhead',
    origin: 'También conocido como American Gamefowl. Muy versátil.',
    fightingStyle:
        'Extremadamente agresivos y territoriales. Pelean sin descanso hasta la victoria, caracterizados por saltar, volar y actividad constante.',
    physicalChars:
        'Cuerpos largos y capaces. Plumas de hoz largas. Ojos amarillos.',
    plumageColors:
        'Negro, colorado, azul-colorado, pardo-colorado, azul, plata, blanco y oro.',
    combTypes:
        'Cresta roja de cinco puntas. Barbillas y orejillas rojas pequeñas.',
    breedingNotes:
        'Comúnmente usado en cruces, especialmente con líneas Hatch y Kelso. Las gallinas también pueden ser beligerantes.',
  ),
  BreedProfile(
    name: 'Asil',
    origin:
        'Originario de Asia, con una apariencia distintiva, casi prehistórica. Más altos y esbeltos.',
    fightingStyle:
        'Aportan fortaleza, resistencia a la fatiga, inteligencia, poder y una habilidad de corte precisa. Son conocidos por su "casta" y dureza.',
    physicalChars:
        'Musculatura aumentada. Suelen ser más pesados, entre 4 y 5.5 libras para combate con acero.',
    plumageColors: 'Varían ampliamente.',
    combTypes:
        'Cresta de Guisante (Triple) es una característica común de la sangre oriental.',
    breedingNotes:
        'Resistencia natural a enfermedades. Cruces comunes con Sweater, Hatch, Giros, etc., en proporciones 50/50 o 75/25.',
  ),
  BreedProfile(
    name: 'Shamo',
    origin:
        'Japón. El nombre probablemente deriva de "Siam". Cualquier gallo de pelea puro en Japón es llamado "Shamo".',
    fightingStyle:
        'Favorecidos por su resistencia, aguante e instinto de lucha. Los "Tuzos" (una variedad) son considerados de los mejores y más finos, apuntando a la cabeza.',
    physicalChars:
        'Existen variedades grandes como "Ainoku" (5-7 kg) y más pequeños como "Tuzos" (1.5-2.0 kg). Los Tuzos tienen plumaje negro y fuerte, y lengua negra que indica pureza.',
    plumageColors:
        'Comúnmente negro, colorado y ocasionalmente blanco. Ojos perla o amarillo muy claro.',
    combTypes:
        'Varía, pero los Tuzos tienen cabeza más tosca y cresta pequeña.',
    breedingNotes: 'Aportan resistencia y poder en los cruces.',
  ),
  BreedProfile(
    name: 'Claret',
    origin:
        'Linaje inglés puro, descendiente de sangres del Conde de Derby, Genet Pyle y Mahoney.',
    fightingStyle:
        'Son excelentes peleadores, conocidos por su velocidad y corte.',
    physicalChars:
        'Patas blancas es una de sus características más distintivas.',
    plumageColors: 'Plumaje colorado, pecho negro y cola negra sin blanco.',
    combTypes: 'Cresta de Sierra.',
    breedingNotes:
        'Una línea clave en la fundación de los Kelsos. También se usó en líneas Hatch. Se combina bien con Albany para producir los Yankee Clippers.',
  ),
  BreedProfile(
    name: 'Albany',
    origin: 'Originarios de Irlanda.',
    fightingStyle: 'Aportan inteligencia y buen estilo de pelea a los cruces.',
    physicalChars: 'Caracterizados por sus patas amarillas.',
    plumageColors:
        'Plumaje rojizo, a menudo con algunas plumas blancas mezcladas en la gola.',
    combTypes: 'Comúnmente Cresta Pava, a veces de Sierra.',
    breedingNotes:
        'Excelentes para cruzar con Giros, Sweater, Kelso, Brown Red y Butcher. Cruces con Butcher dieron lugar a los famosos Brass Backs.',
  ),
  BreedProfile(
    name: 'Giro (Grey)',
    origin: 'Diversas líneas americanas.',
    fightingStyle: 'Aportan velocidad y buen juego a los cruces.',
    physicalChars: 'Variedades de color.',
    plumageColors:
        'Incluye Clemon (Limón), Regular Grey, Perfection Grey y Madigan. También hay giros plateados o color miel.',
    combTypes: 'Varía según la línea.',
    breedingNotes:
        'Excelente para cruzar con Brown Red, Hatch, Sweater, Kelso, etc., a menudo en proporciones 50/50 o 75/25.',
  ),
  BreedProfile(
    name: 'Brown Red',
    origin: 'Línea de color americana.',
    fightingStyle: 'Aves de pelea sólidas y confiables.',
    physicalChars: 'Patas oscuras características.',
    plumageColors: 'Plumaje oscuro, pardo-rojizo.',
    combTypes: 'Varía según la línea.',
    breedingNotes:
        'Cruzan bien con Hatch, Kelso, Albanys, Radios, Giros y Asil.',
  ),
  BreedProfile(
    name: 'Malayo (Malay)',
    origin:
        'Se cree que existe desde hace al menos 3,000 años. Una de las razas primitivas.',
    fightingStyle:
        'Líder en agresividad y capacidad de pelea. Rápidos, furiosos y letales, pelean con puntería experta para matar y no se detienen.',
    physicalChars:
        'La raza más alta, aprox. 70 cm. Aves potentes, cuello largo, ojos intensos, pico curvo, plumaje firme y cola corta.',
    plumageColors: 'Varían.',
    combTypes: 'Cresta de Cereza.',
    breedingNotes:
        'Su influencia es visible en razas como el Gallo a Navaja del Perú.',
  ),
  BreedProfile(
    name: 'Old English Game',
    origin:
        'Raza tradicional británica. Introducida en Perú a principios del siglo XX.',
    fightingStyle:
        'A pesar de su tamaño más pequeño, son luchadores fuertes con mucha actitud. Aportan velocidad, poder y vehemencia a los cruces.',
    physicalChars:
        'Considerados hermosos, altos, con pecho inflado, cuello largo y plumas brillantes. Patas cortas y robustas.',
    plumageColors:
        'Gran variedad de colores reconocidos, incluyendo rojo-pecho negro, azul-oro, cuclillo, azul-limón, moteado y trigueño (wheaten).',
    combTypes:
        'Varía, puede ser Simple, Rosa, o tener Penacho (Tassel) y Barba (Muffed).',
    breedingNotes: 'De alto mantenimiento y ruidosos, con mucha personalidad.',
  ),
  BreedProfile(
    name: 'Gallo a Navaja del Perú',
    origin:
        'Desarrollado entre los siglos XVIII y XIX en Lima, Perú. Aún no es una raza estandarizada.',
    fightingStyle:
        'Estilo de "sangre caliente", agresivo, provocador y arrogante. No toleran a otro gallo cerca.',
    physicalChars:
        'De tamaño mediano a grande (8.5-10.5 lbs), esbeltos y de postura muy erguida. Cabeza de rapaz, mirada penetrante. Maduran a los 18 meses.',
    plumageColors:
        'Se pueden encontrar en cualquier color. Ojos de amarillo claro a negro. Patas de colores muy variados (amarillo, blanco, verde, gris, azul, negro).',
    combTypes: 'Se reconocen variedades de cresta Simple, Rosa y Triple.',
    breedingNotes:
        'Criarlos se considera una actividad para adinerados por el tiempo y recursos que requiere.',
  ),
  BreedProfile(
    name: 'Combatiente Español',
    origin: 'España. A menudo referido como "Trifino".',
    fightingStyle:
        'Aportan coraje, puntería y habilidad de vuelo a los cruces.',
    physicalChars: 'Varían según la línea (Canaria, Almodovar, etc.).',
    plumageColors: 'Varían.',
    combTypes: 'Varían.',
    breedingNotes:
        'Líneas notables incluyen Canaria, Almodovar y Perez Tabernero.',
  ),
];
