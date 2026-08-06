import 'dart:io';

const outputRoot = 'assets/svg';

void main() {
  final assets = <String, String>{
    'pieces/peanut.svg': piece('peanut', '#D98B45', 'P', shell: true),
    'pieces/egg.svg': piece('egg', '#FFD75E', 'E', oval: true),
    'pieces/sugar_crystal.svg': crystal('#71D7EC'),
    'pieces/caramel_ribbon.svg': ribbon('#EF7A3D'),
    'pieces/coconut_cream.svg': piece('coconut', '#FFF7DF', 'C'),
    'pieces/cocoa_crumb.svg': crumb('#74442E'),
    'specials/sugar_beam_horizontal.svg': special('#64D6ED', '↔'),
    'specials/sugar_beam_vertical.svg': special('#64D6ED', '↕'),
    'specials/golden_recipe_spark.svg': special('#FFC83D', '★'),
    'specials/oven_burst.svg': special('#F06445', '✦'),
    'specials/peanut_spinner.svg': special('#D99048', '↻'),
    'blockers/sugar_frosting.svg': blocker('#FFF4E4', 'F'),
    'blockers/peanut_crate.svg': blocker('#A86532', '╳'),
    'blockers/sticky_caramel.svg': blocker('#E36F32', 'S'),
    'blockers/chocolate_crumbs.svg': blocker('#5D3427', '••'),
    'blockers/oven_stone.svg': blocker('#8D8275', 'O'),
    'blockers/bakers_twine.svg': blocker('#D5B26E', '#'),
    'boosters/sugar_beam.svg': badge('#5CCDE5', '↔'),
    'boosters/oven_burst.svg': badge('#F06445', '✦'),
    'boosters/peanut_spinner.svg': badge('#D99048', '↻'),
    'ui/button_primary.svg': button(),
    'ui/star_empty.svg': star('#E6D6B5'),
    'ui/star_filled.svg': star('#FFC83D'),
    'goals/target_score.svg': badge('#FFC83D', '★'),
    'goals/collect_pieces.svg': badge('#D99048', 'P'),
    'goals/clear_frosting.svg': badge('#FFF4E4', 'F'),
    'goals/break_crates.svg': badge('#A86532', '╳'),
    'goals/drop_baskets.svg': badge('#E89C3F', '↓'),
    'goals/spread_cream.svg': badge('#FFF7DF', 'C'),
    'goals/light_ovens.svg': badge('#F06445', 'O'),
    'backgrounds/sunrise_glow.svg': sunrise(),
    'backgrounds/map_path.svg': mapPath(),
    'characters/peanut_baker.svg': peanutBaker(),
  };

  for (final entry in assets.entries) {
    final file = File('$outputRoot/${entry.key}');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
  }
  stdout.writeln('Generated ${assets.length} original SVG assets.');
}

String frame(String body, {String viewBox = '0 0 128 128'}) =>
    '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox">
  <defs>
    <filter id="shadow" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="7" stdDeviation="5" flood-color="#3B2418" flood-opacity=".28"/></filter>
    <linearGradient id="shine" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#FFFFFF" stop-opacity=".8"/><stop offset=".45" stop-color="#FFFFFF" stop-opacity=".08"/><stop offset="1" stop-color="#4A2314" stop-opacity=".2"/></linearGradient>
  </defs>
  $body
</svg>''';

String piece(
  String id,
  String color,
  String label, {
  bool shell = false,
  bool oval = false,
}) {
  final shape = oval
      ? '<ellipse cx="64" cy="66" rx="38" ry="48" fill="$color"/>'
      : '<path d="M64 18C91 18 109 39 106 67c-3 27-20 44-42 44S25 94 22 67C19 39 37 18 64 18Z" fill="$color"/>';
  final texture = shell
      ? '<path d="M45 31c14 18 24 45 29 70M75 27C64 49 56 73 53 101" fill="none" stroke="#8B4C27" stroke-width="4" stroke-linecap="round" opacity=".65"/>'
      : '';
  return frame(
    '''<g filter="url(#shadow)">$shape<path d="M40 34c15-13 38-12 51 1" fill="none" stroke="#FFF" stroke-width="9" stroke-linecap="round" opacity=".55"/>$texture<ellipse cx="64" cy="66" rx="39" ry="47" fill="url(#shine)" opacity=".45"/><text x="64" y="79" text-anchor="middle" font-family="Arial Rounded MT Bold,Arial" font-size="36" font-weight="900" fill="#5A3825">$label</text></g><!-- $id -->''',
  );
}

String crystal(String color) => frame(
  '''<g filter="url(#shadow)"><path d="M64 12 106 47 91 105 37 112 18 53Z" fill="$color"/><path d="m64 12 8 55-35 45M64 12 18 53l54 14 34-20M72 67l19 38" fill="none" stroke="#DFFFFF" stroke-width="5" opacity=".8"/><path d="M34 48 58 27" stroke="#FFF" stroke-width="9" stroke-linecap="round" opacity=".65"/></g>''',
);

String ribbon(String color) => frame(
  '''<g filter="url(#shadow)"><path d="M23 38c26-25 70-20 79 5 9 26-24 29-45 35-18 5-18 18 10 28" fill="none" stroke="$color" stroke-width="28" stroke-linecap="round"/><path d="M28 34c20-14 48-13 62 1" fill="none" stroke="#FFD0A8" stroke-width="7" stroke-linecap="round" opacity=".65"/></g>''',
);

String crumb(String color) => frame(
  '''<g filter="url(#shadow)" fill="$color"><circle cx="64" cy="65" r="43"/><circle cx="35" cy="31" r="13"/><circle cx="94" cy="39" r="11"/><circle cx="91" cy="94" r="14"/><g fill="#B87754" opacity=".65"><circle cx="48" cy="59" r="6"/><circle cx="77" cy="45" r="7"/><circle cx="76" cy="82" r="5"/></g><path d="M39 42c13-12 30-15 43-8" fill="none" stroke="#FFF" stroke-width="7" stroke-linecap="round" opacity=".35"/></g>''',
);

String special(String color, String symbol) => frame(
  '''<g filter="url(#shadow)"><circle cx="64" cy="65" r="49" fill="$color"/><circle cx="64" cy="65" r="39" fill="none" stroke="#FFF3B5" stroke-width="8"/><path d="M37 35c14-12 34-13 49-4" fill="none" stroke="#FFF" stroke-width="7" stroke-linecap="round" opacity=".6"/><text x="64" y="82" text-anchor="middle" font-family="Arial" font-size="48" font-weight="900" fill="#5A3825">$symbol</text></g>''',
);

String blocker(String color, String symbol) => frame(
  '''<g filter="url(#shadow)"><rect x="16" y="16" width="96" height="96" rx="25" fill="$color"/><rect x="24" y="24" width="80" height="80" rx="19" fill="url(#shine)" opacity=".55"/><path d="M31 34h66" stroke="#FFF" stroke-width="8" stroke-linecap="round" opacity=".45"/><text x="64" y="82" text-anchor="middle" font-family="Arial" font-size="42" font-weight="900" fill="#FFF">$symbol</text></g>''',
);

String badge(String color, String symbol) => frame(
  '''<g filter="url(#shadow)"><path d="M64 10 79 24l21-1 4 21 14 15-14 16-4 21-21-1-15 15-15-15-21 1-4-21L10 59l14-15 4-21 21 1Z" fill="$color"/><circle cx="64" cy="60" r="34" fill="#FFF" opacity=".22"/><text x="64" y="78" text-anchor="middle" font-family="Arial" font-size="46" font-weight="900" fill="#5A3825">$symbol</text></g>''',
);

String star(String color) => frame(
  '''<path filter="url(#shadow)" d="m64 10 16 33 37 5-27 26 7 37-33-18-33 18 7-37-27-26 37-5Z" fill="$color" stroke="#C98223" stroke-width="5"/><path d="m50 38 10-14" stroke="#FFF" stroke-width="7" stroke-linecap="round" opacity=".65"/>''',
);

String button() => frame(
  '''<g filter="url(#shadow)"><rect x="8" y="22" width="112" height="80" rx="30" fill="#F4B942"/><rect x="15" y="28" width="98" height="61" rx="24" fill="url(#shine)" opacity=".7"/><path d="M31 42h55" stroke="#FFF" stroke-width="8" stroke-linecap="round" opacity=".55"/></g>''',
);

String sunrise() =>
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 1200"><defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#7EDAF0"/><stop offset=".46" stop-color="#FFE9B5"/><stop offset="1" stop-color="#FFF7DF"/></linearGradient></defs><rect width="800" height="1200" fill="url(#sky)"/><circle cx="620" cy="270" r="120" fill="#FFF4B8" opacity=".8"/><path d="M0 830Q190 690 390 845T800 790V1200H0Z" fill="#4A9B76"/><path d="M0 920Q220 810 430 930T800 880V1200H0Z" fill="#D99048" opacity=".7"/></svg>''';

String mapPath() =>
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 1200"><path d="M90 1150C330 1020 55 900 280 760S75 500 300 360 150 160 245 40" fill="none" stroke="#FFF7DF" stroke-width="38" stroke-linecap="round" stroke-dasharray="18 28"/><path d="M90 1150C330 1020 55 900 280 760S75 500 300 360 150 160 245 40" fill="none" stroke="#D99048" stroke-width="7" stroke-linecap="round" stroke-dasharray="18 28" opacity=".55"/></svg>''';

String peanutBaker() => frame(
  '''<g filter="url(#shadow)"><path d="M39 37C26 48 27 89 44 106c10 10 30 10 40 0 17-17 18-58 5-69-13-12-37-12-50 0Z" fill="#D99048"/><path d="M34 38c-13-9-5-25 8-22 5-14 20-13 25-2 10-10 28-2 24 12 15 0 17 18 4 24Z" fill="#FFF7DF"/><circle cx="50" cy="65" r="6" fill="#3A2118"/><circle cx="77" cy="65" r="6" fill="#3A2118"/><path d="M52 82q12 11 24 0" fill="none" stroke="#5A3825" stroke-width="5" stroke-linecap="round"/><path d="M43 40c8 18 15 42 18 65M77 39c-7 18-12 42-13 67" fill="none" stroke="#8B4C27" stroke-width="3" opacity=".6"/></g>''',
);
