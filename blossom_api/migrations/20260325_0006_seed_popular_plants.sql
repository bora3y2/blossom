-- Seed: 20 most popular plants with full catalog data
-- All plants are admin-reviewed and active.
-- image_path can be updated via the admin dashboard.

insert into public.plants (
  common_name, scientific_name, short_description,
  image_path, water_requirements, light_requirements,
  temperature, pet_safe, location_type, caring_difficulty,
  source, reviewed_by_admin, is_active
) values

-- 1. Monstera
(
  'Monstera',
  'Monstera deliciosa',
  'A striking tropical plant with large, split leaves that''s become a must-have for modern interiors. Fast-growing and dramatic.',
  null,
  'Water every 1–2 weeks, allowing the top half of soil to dry out between waterings. Reduce frequency in winter.',
  'Bright indirect light. Tolerates medium light but grows slower. Avoid harsh direct sun.',
  'Thrives between 18–29 °C (65–85 °F). Protect from cold drafts and temperatures below 10 °C.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 2. Peace Lily
(
  'Peace Lily',
  'Spathiphyllum wallisii',
  'A graceful flowering plant that purifies the air and thrives in low light. Its white blooms bring calm elegance to any room.',
  null,
  'Water once a week; keep soil consistently moist but never soggy. Will droop slightly when thirsty — a clear watering cue.',
  'Low to medium indirect light. One of the best plants for dim spaces. Avoid direct sun.',
  'Prefers 18–30 °C (65–85 °F). Sensitive to cold; keep away from drafts.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 3. Snake Plant
(
  'Snake Plant',
  'Dracaena trifasciata',
  'One of the most forgiving plants you can own. Sculptural, upright leaves and exceptional tolerance of neglect make it perfect for beginners.',
  null,
  'Every 2–6 weeks depending on season. Let soil dry completely between waterings. Overwatering is its main enemy.',
  'Adapts to low light but grows faster in bright indirect light. Avoid harsh direct sun.',
  'Best between 15–27 °C (60–80 °F). Survives brief cool spells but dislikes frost.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 4. Golden Pothos
(
  'Golden Pothos',
  'Epipremnum aureum',
  'A trailing vine with heart-shaped golden-green leaves. Nearly impossible to kill, it cascades beautifully from shelves or climbs a moss pole.',
  null,
  'Every 1–2 weeks; let the top 2–5 cm of soil dry out before watering again. Yellow leaves mean overwatering.',
  'Highly adaptable — tolerates low light but shows best colour in bright indirect light.',
  'Comfortable in 18–29 °C (65–85 °F). Keep away from cold windows in winter.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 5. Spider Plant
(
  'Spider Plant',
  'Chlorophytum comosum',
  'A cheerful, arching plant that produces baby plantlets on long runners. Non-toxic to pets and NASA-listed as an excellent air purifier.',
  null,
  'Once a week during the growing season; allow soil to partially dry between waterings. Reduce in winter.',
  'Bright to medium indirect light. Avoid direct summer sun which can scorch the leaves.',
  'Happy between 15–27 °C (60–80 °F). Tolerates cool rooms but not frost.',
  true, 'Indoor', 'low', 'admin', true, true
),

-- 6. ZZ Plant
(
  'ZZ Plant',
  'Zamioculcas zamiifolia',
  'Glossy, dark-green leaves on graceful arching stems. Stores water in its thick roots, making it extraordinarily drought-tolerant.',
  null,
  'Every 2–3 weeks. One of the most drought-tolerant houseplants — allow soil to dry out completely between waterings.',
  'Thrives in low to bright indirect light. Avoid direct sun which can bleach the foliage.',
  'Best at 15–24 °C (60–75 °F). Not cold-hardy; keep above 8 °C.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 7. Fiddle Leaf Fig
(
  'Fiddle Leaf Fig',
  'Ficus lyrata',
  'A statement indoor tree with large, violin-shaped leaves. A design icon that rewards stable conditions and consistent care.',
  null,
  'Every 7–10 days; water thoroughly then let the top 2–3 cm dry out. Sensitive to both over- and under-watering.',
  'Bright indirect to filtered direct light for at least 6 hours. Rotate monthly for even growth.',
  'Prefers a steady 18–29 °C (65–85 °F). Hates cold drafts, air conditioning vents, and being moved.',
  false, 'Indoor', 'high', 'admin', true, true
),

-- 8. Rubber Plant
(
  'Rubber Plant',
  'Ficus elastica',
  'A bold indoor tree with large, glossy leaves in deep green or burgundy. Easier than a fiddle leaf fig and grows rapidly in good light.',
  null,
  'Every 1–2 weeks; let the top centimetre of soil dry before watering. Wipe dust from leaves to keep them shiny.',
  'Bright indirect light is ideal. Tolerates lower light but growth slows and leaves lose vibrancy.',
  'Comfortable at 18–27 °C (65–80 °F). Avoid temperature swings and cold windows.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 9. Aloe Vera
(
  'Aloe Vera',
  'Aloe barbadensis miller',
  'A succulent with thick, fleshy leaves filled with soothing gel. A natural first-aid plant that is as useful as it is attractive.',
  null,
  'Every 3 weeks; allow soil to dry out completely. Water sparingly in winter. Extremely susceptible to root rot from overwatering.',
  'Bright direct to indirect light; prefers 6+ hours of sun. Can live outdoors in warm climates.',
  'Thrives in 15–27 °C (60–80 °F). Frost-tender; bring indoors when temperatures drop below 5 °C.',
  false, 'Both', 'low', 'admin', true, true
),

-- 10. Chinese Evergreen
(
  'Chinese Evergreen',
  'Aglaonema commutatum',
  'A colourful, low-maintenance plant with strikingly patterned leaves in shades of green, silver, red, and pink.',
  null,
  'Once a week; keep soil lightly moist. Allow the top 2–3 cm to dry between waterings. Very forgiving of missed waterings.',
  'Low to bright indirect light. Darker varieties tolerate lower light; colourful varieties prefer brighter spots.',
  'Prefers 18–27 °C (65–80 °F). Sensitive to cold and drafts; keep above 15 °C.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 11. Boston Fern
(
  'Boston Fern',
  'Nephrolepis exaltata',
  'Full, arching fronds of lush, bright-green foliage. A classic houseplant and one of the best natural humidifiers.',
  null,
  'Water 2–3 times a week; keep soil consistently moist. Never let it dry out completely. Mist fronds regularly.',
  'Indirect light or partial shade. Avoid direct sun which causes frond scorch.',
  'Prefers 15–24 °C (60–75 °F) and high humidity above 50 %. Dislikes heat vents.',
  true, 'Indoor', 'high', 'admin', true, true
),

-- 12. Jade Plant
(
  'Jade Plant',
  'Crassula ovata',
  'A long-lived succulent with thick, oval leaves on woody stems. Said to bring good luck and can become a treasured bonsai-like specimen.',
  null,
  'Every 2–3 weeks; let soil dry out completely between waterings. Reduce to monthly in winter.',
  'Bright indirect to direct light; needs at least 4 hours of sun daily. A sunny windowsill is ideal.',
  'Comfortable at 18–24 °C (65–75 °F). Tolerates cooler winters down to 10 °C which can encourage flowering.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 13. Bird of Paradise
(
  'Bird of Paradise',
  'Strelitzia reginae',
  'A majestic plant with large, paddle-shaped leaves and vivid orange flowers resembling a tropical bird in flight.',
  null,
  'Every 1–2 weeks during the growing season; reduce in winter. Allow the top 5 cm of soil to dry before watering.',
  'Bright direct light; needs at least 4–6 hours of direct sun daily to flower. Excellent for south-facing windows.',
  'Best at 18–29 °C (65–85 °F). Can handle brief dips to 5 °C but prefers warmth.',
  false, 'Both', 'low', 'admin', true, true
),

-- 14. Lavender
(
  'Lavender',
  'Lavandula angustifolia',
  'A fragrant Mediterranean shrub beloved for its calming scent, silvery foliage, and purple flower spikes. A favourite of pollinators.',
  null,
  'Once a week until established; then drought-tolerant. Water deeply but infrequently. Avoid wet feet.',
  'Full sun — needs 6–8 hours of direct sunlight daily. Poor in shade.',
  'Hardy to −10 °C (14 °F); thrives in 15–27 °C (60–80 °F). Excellent drought and heat tolerance.',
  false, 'Outdoor', 'low', 'admin', true, true
),

-- 15. Rosemary
(
  'Rosemary',
  'Salvia rosmarinus',
  'A fragrant culinary herb with needle-like leaves and blue flowers. Hardy, drought-tolerant, and a magnet for bees.',
  null,
  'Every 1–2 weeks; drought-tolerant once established. Allow soil to dry between waterings. Overwatering is the main risk.',
  'Full sun — at least 6 hours of direct sunlight daily. Essential for strong growth and flavour.',
  'Hardy to −12 °C (10 °F); thrives in 13–27 °C (55–80 °F). Excellent heat tolerance.',
  false, 'Both', 'low', 'admin', true, true
),

-- 16. Basil
(
  'Basil',
  'Ocimum basilicum',
  'The quintessential culinary herb with aromatic leaves perfect for cooking. Fast-growing and rewarding with the right conditions.',
  null,
  'Every 2–3 days; keep soil consistently moist. Water at the base to avoid leaf disease. Wilts quickly when thirsty.',
  'Full sun — 6–8 hours of direct light daily. A south-facing windowsill or outdoor plot works best.',
  'Needs warmth: 18–29 °C (65–85 °F). Frost-tender; dies below 10 °C. Do not put outdoors until nights stay above 12 °C.',
  true, 'Both', 'low', 'admin', true, true
),

-- 17. Moth Orchid
(
  'Moth Orchid',
  'Phalaenopsis amabilis',
  'The most popular flowering houseplant in the world, with elegant blooms lasting weeks. Easier to care for than its glamorous looks suggest.',
  null,
  'Every 1–2 weeks; water at the base or soak the pot briefly, then let roots dry. Never let roots sit in standing water.',
  'Bright indirect light; avoid direct sun which burns leaves. An east-facing window is ideal.',
  'Comfortable at 18–27 °C (65–80 °F) by day; benefits from a slight night temperature drop to encourage re-flowering.',
  true, 'Indoor', 'low', 'admin', true, true
),

-- 18. Heartleaf Philodendron
(
  'Heartleaf Philodendron',
  'Philodendron hederaceum',
  'A vining plant with glossy, heart-shaped leaves that looks stunning trailing from shelves or trained up a pole. Extremely forgiving.',
  null,
  'Every 1–2 weeks; let the top half of soil dry out between waterings. Very forgiving — bounces back from occasional drought.',
  'Low to bright indirect light. One of the most adaptable houseplants for varying light conditions.',
  'Prefers 18–27 °C (65–80 °F). Sensitive to temperatures below 13 °C and cold drafts.',
  false, 'Indoor', 'low', 'admin', true, true
),

-- 19. Barrel Cactus
(
  'Barrel Cactus',
  'Ferocactus wislizeni',
  'A classic desert cactus with a round, ribbed barrel shape and bright spines. Near-indestructible and fascinating as a sculptural accent.',
  null,
  'Every 2–3 weeks in summer; once a month in winter. Less is more — drought is far safer than overwatering.',
  'Full sun — 6+ hours of direct sunlight daily. Ideal near the brightest window or outdoors in warm months.',
  'Thrives in 10–27 °C (50–80 °F). Tolerates brief frosts to −7 °C. Excellent heat tolerance.',
  false, 'Both', 'low', 'admin', true, true
),

-- 20. String of Pearls
(
  'String of Pearls',
  'Curio rowleyanus',
  'A trailing succulent with bead-like leaves that cascade elegantly from hanging baskets. A real conversation piece for bright spots.',
  null,
  'Every 2 weeks; allow soil to dry completely between waterings. Very sensitive to overwatering — when in doubt, wait.',
  'Bright indirect to some direct light; 4–6 hours. Insufficient light causes the strands to become sparse.',
  'Prefers 21–27 °C (70–80 °F). Bring indoors if temperatures drop below 7 °C.',
  false, 'Indoor', 'high', 'admin', true, true
)

on conflict do nothing;
