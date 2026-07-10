import 'package:flutter/material.dart';

/// A single care guide shown in the Guides tab. Each guide renders through
/// the existing InfoScreen (title + heading/paragraph section pairs), so no
/// new rendering code is needed.
///
/// Content here is deliberately general, widely-accepted houseplant guidance
/// — kept static and offline so the Guides tab costs nothing to serve. It can
/// later be swapped for richer, per-species AI-generated guides.
class Guide {
  final String title;
  final IconData icon;
  final String summary;
  final List<(String, String)> sections;

  const Guide({
    required this.title,
    required this.icon,
    required this.summary,
    required this.sections,
  });
}

const List<Guide> guides = [
  Guide(
    title: 'Watering basics',
    icon: Icons.water_drop_outlined,
    summary: 'How much, how often, and how to tell when a plant is thirsty.',
    sections: [
      (
        'Check the soil, not the calendar',
        'The single most useful habit is to feel the soil before watering. Push a '
            'finger an inch or two into the top of the pot: if it comes out dry, most '
            'houseplants are ready for water; if it still feels damp, wait. Fixed '
            'weekly schedules are a starting point, but light, warmth, humidity and '
            'pot size all change how fast a plant dries out.',
      ),
      (
        'Water thoroughly, then let it drain',
        'When you do water, add enough that it runs out of the drainage holes. This '
            'wets the whole root ball and flushes out built-up salts. Empty the saucer '
            'afterwards — leaving a pot sitting in water is the fastest way to rot '
            'roots. Pots without drainage need extra care: add less water, more slowly.',
      ),
      (
        'Overwatering vs. underwatering',
        'Both can look similar — droopy, yellowing leaves — which is why people often '
            'water a struggling plant that is actually already too wet. Soft, mushy '
            'stems and consistently soggy soil point to overwatering. Crispy, curling '
            'leaves and soil pulling away from the pot point to underwatering. When in '
            'doubt, err on the drier side; most houseplants recover from thirst far '
            'more easily than from rot.',
      ),
    ],
  ),
  Guide(
    title: 'Light & placement',
    icon: Icons.wb_sunny_outlined,
    summary: 'Reading the light in your home and matching plants to it.',
    sections: [
      (
        'Know your light levels',
        'Bright direct light means several hours of sun hitting the leaves — a south- '
            'or west-facing window. Bright indirect light is a spot that feels bright '
            'but where the sun does not land directly on the plant, such as near an '
            'east window or just back from a sunny one. Low light is a room with '
            'windows but no direct sun. Most popular houseplants prefer bright '
            'indirect light.',
      ),
      (
        'Watch the plant, adjust the spot',
        'Leggy, stretched growth reaching toward a window usually means too little '
            'light. Pale, scorched, or bleached patches mean too much direct sun. Rotate '
            'pots a quarter-turn every week or two so plants grow evenly rather than '
            'leaning.',
      ),
      (
        'Light changes with the seasons',
        'A windowsill that is perfect in summer can become dim in winter as the sun '
            'sits lower and days shorten. It is normal to move plants closer to windows '
            'in the darker months, and a little further back when summer sun gets '
            'intense.',
      ),
    ],
  ),
  Guide(
    title: 'Repotting 101',
    icon: Icons.yard_outlined,
    summary: 'When to size up, and how to do it without shocking the plant.',
    sections: [
      (
        'When to repot',
        'Signs a plant has outgrown its pot: roots circling the surface or growing out '
            'of the drainage holes, water running straight through without soaking in, '
            'or growth that has stalled despite good care. Most houseplants need '
            'repotting every one to two years. Early spring, as growth picks up, is the '
            'kindest time.',
      ),
      (
        'Size up gently',
        'Choose a pot just one size larger — about 2–5 cm (1–2 inches) wider. A pot '
            'that is far too big holds excess wet soil around the roots and invites '
            'rot. Always use a pot with drainage.',
      ),
      (
        'The repotting steps',
        'Water the plant a day before so the root ball holds together. Ease it out, '
            'loosen any tightly circled roots, and set it in fresh potting mix at the '
            'same depth it grew before. Firm the soil gently, water it in, and keep it '
            'out of harsh direct sun for a week while it settles. Some drooping right '
            'after repotting is normal.',
      ),
    ],
  ),
  Guide(
    title: 'Humidity & temperature',
    icon: Icons.thermostat_outlined,
    summary: 'Keeping tropical plants comfortable indoors.',
    sections: [
      (
        'Most houseplants like it steady',
        'The majority of common houseplants are happiest between about 18–27°C '
            '(65–80°F) and dislike sudden swings. Keep them away from cold drafts, '
            'frosty windows in winter, and the hot, dry blast of heating vents, '
            'radiators, and air conditioners.',
      ),
      (
        'Raising humidity',
        'Tropical plants such as calatheas, ferns, and many aroids appreciate humidity '
            'higher than a typical heated room. Grouping plants together, using a pebble '
            'tray with water beneath the pot, or running a small humidifier all help. '
            'Misting gives only a brief lift and is not a reliable substitute.',
      ),
      (
        'Reading the signs',
        'Crispy brown leaf edges and tips are a classic sign of air that is too dry '
            '(or inconsistent watering). Sudden leaf drop often follows a cold draft or '
            'a big temperature change rather than anything you did wrong at the roots.',
      ),
    ],
  ),
  Guide(
    title: 'Feeding & seasons',
    icon: Icons.eco_outlined,
    summary: 'Fertilizing lightly and adjusting care through the year.',
    sections: [
      (
        'Feed during active growth',
        'Most houseplants grow from spring through summer and rest in autumn and '
            'winter. Feed only during the growing season, using a balanced houseplant '
            'fertilizer at the strength on the label — or slightly weaker. More is not '
            'better; excess fertilizer burns roots and builds up as salts in the soil.',
      ),
      (
        'Ease off in winter',
        'As light fades and growth slows, plants need less of everything: less water, '
            'and little or no feeding until spring. Watering on the same summer schedule '
            'through a dark winter is a common cause of rot.',
      ),
      (
        'Let plants rest',
        'Slower growth and the odd dropped leaf in winter are normal, not a problem to '
            'fix with extra feeding or water. Keep conditions stable and pick feeding '
            'back up when you see fresh growth return.',
      ),
    ],
  ),
  Guide(
    title: 'Pest & disease basics',
    icon: Icons.pest_control_outlined,
    summary:
        'The fundamentals of spotting and treating common houseplant pests.',
    sections: [
      (
        'Inspect regularly',
        'Catching pests early makes them far easier to beat. Every week or two, check '
            'the undersides of leaves and the joints where leaves meet stems — the '
            'places pests hide. Look for tiny webbing, cottony white specks, small '
            'brown bumps, or clusters of tiny insects.',
      ),
      (
        'Common culprits',
        'Spider mites: fine webbing and stippled, dusty-looking leaves, thriving in '
            'dry air. Mealybugs: cottony white blobs in leaf joints. Scale: small, '
            'immobile brown bumps along stems. Fungus gnats: small flies around '
            'consistently damp soil.',
      ),
      (
        'Treating an outbreak',
        'Isolate the affected plant so pests do not spread. Wipe leaves and joints '
            'with insecticidal soap or diluted neem oil, repeating every few days until '
            'they are gone. For fungus gnats, let the top of the soil dry out more '
            'between waterings to break their cycle. Persistence matters more than any '
            'single treatment.',
      ),
    ],
  ),
];
