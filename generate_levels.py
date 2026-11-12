import json
import random
import urllib.request
import os
from collections import Counter

URL = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt"
CACHE_FILE = "words_cache.txt"

def get_wordlist():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r") as f:
            return f.read().splitlines()
    print("Downloading word list...")
    response = urllib.request.urlopen(URL)
    words = response.read().decode('utf-8').splitlines()
    with open(CACHE_FILE, "w") as f:
        f.write("\n".join(words))
    return words

print("Loading words...")
raw_words = get_wordlist()

# Curate
valid_words = []
for w in raw_words:
    w = w.upper().strip()
    if len(w) >= 3 and len(w) <= 9 and w.isalpha():
        valid_words.append(w)

# Eliminate plurals heavily, or just keep unique. The 10k list is already sorted by frequency.
# Keep the most frequent 4000 words
curated_words = list(dict.fromkeys(valid_words))[:4000]

print(f"Total curated unique words: {len(curated_words)}")

# Helper to check if word can be formed
def can_form(word, letters):
    w_count = Counter(word)
    l_count = Counter(letters)
    for char, count in w_count.items():
        if l_count[char] < count:
            return False
    return True

# Build source word candidates (5-8 letters, must have enough anagrams)
print("Evaluating source words...")
source_candidates = []
word_pool_map = {}

# We pre-calculate valid combinations to speed up
for src in curated_words:
    if 5 <= len(src) <= 8:
        pool = [w for w in curated_words if can_form(w, src)]
        if len(pool) >= 5: # Minimum 5 derived words for Easy
            source_candidates.append(src)
            word_pool_map[src] = pool

print(f"Valid source words found: {len(source_candidates)}")

# Categorize source words by difficulty (derived word count)
easy_sources = [s for s in source_candidates if 5 <= len(word_pool_map[s]) <= 9]
medium_sources = [s for s in source_candidates if 10 <= len(word_pool_map[s]) <= 14]
hard_sources = [s for s in source_candidates if len(word_pool_map[s]) >= 15]

print(f"Easy: {len(easy_sources)}, Medium: {len(medium_sources)}, Hard: {len(hard_sources)}")

levels = []
themes = ["Spring", "Forest", "Mountain", "Ocean", "Autumn", "Snow", "Sunset", "Night", "Desert", "Mystical"]

def create_level(level_id):
    if level_id <= 30:
        req_count = random.randint(3, 5)
        if level_id > 10: req_count = random.randint(4, 7)
        difficulty = 1
        src_pool = easy_sources if easy_sources else medium_sources
    elif level_id <= 150:
        req_count = random.randint(5, 8)
        if level_id > 75: req_count = random.randint(6, 9)
        difficulty = 2
        src_pool = medium_sources if medium_sources else hard_sources
    else:
        req_count = random.randint(7, 10)
        if level_id > 225: req_count = random.randint(8, 10)
        difficulty = 3
        src_pool = hard_sources

    # pick a source
    # to avoid repetition, pick randomly
    source_word = random.choice(src_pool)
    pool = word_pool_map[source_word].copy()
    
    # Sort pool so we prioritize slightly longer words, but keep it mixed
    pool.sort(key=len)
    
    # Identify hard/coin word (typically the longest/source word)
    hard_word = None
    if source_word in pool and req_count > 0:
        if random.random() < 0.3: # 30% chance for a hard coin word
            hard_word = source_word
            pool.remove(source_word)
        
    random.shuffle(pool)
    
    required = pool[:req_count]
    if source_word not in required and hard_word is None and source_word in word_pool_map[source_word]:
        # ensure source word is in required if it wasn't made a hard word
        if req_count > 0:
            required[0] = source_word
            
    bonus = pool[req_count:]
    
    required.sort(key=len)
    
    layout = random.randint(1, 8) # Extended layout patterns
    theme = themes[(level_id - 1) // 30 % len(themes)]
    reward = 10 + (difficulty * 5) + len(required) * 2
    
    letters = "".join(random.sample(source_word, len(source_word)))
    
    return {
        "id": level_id,
        "theme": theme,
        "letters": letters,
        "requiredWords": required,
        "bonusWords": bonus,
        "hardWord": hard_word,
        "difficulty": difficulty,
        "reward": reward,
        "layoutPattern": layout
    }

print("Generating 300 main levels...")
random.seed(42) # Deterministic
for i in range(1, 301):
    levels.append(create_level(i))

# Generate Riddles (100 riddles)
print("Generating riddles...")
riddles = []
riddle_clues = [
    ("Twinkles in the sky", "STARS"), ("Man's best friend", "DOG"), ("Meows", "CAT"),
    ("Red fruit", "APPLE"), ("Yellow fruit", "BANANA"), ("Hot drink", "COFFEE"),
    ("Cold season", "WINTER"), ("Hot season", "SUMMER"), ("Has leaves", "TREE"),
    ("Flows to sea", "RIVER"), ("Big body of water", "OCEAN"), ("Reads books", "READER"),
    ("Writes books", "AUTHOR"), ("Plays music", "MUSICIAN"), ("Bakes bread", "BAKER"),
    ("Time piece", "CLOCK"), ("Opens doors", "KEY"), ("Flies in sky", "BIRD")
] 
for i in range(1, 101):
    clue, ans = riddle_clues[i % len(riddle_clues)]
    riddles.append({
        "id": i,
        "clue": f"{clue} {i}",
        "answer": ans,
        "letters": "".join(random.sample(ans + "ABCDEFGHIJ"[:10-len(ans)], 10)),
        "reward": 50 + (i * 2)
    })

# Generate Word Wheel
print("Generating Word Wheel levels...")
word_wheels = []
for i in range(1, 51):
    # Need a 7 letter word with at least 10 derived words
    candidates = [w for w in hard_sources if len(w) == 7 and len(word_pool_map[w]) > 10]
    if not candidates:
        candidates = [w for w in medium_sources if len(w) == 7 and len(word_pool_map[w]) > 5]
    src = random.choice(candidates) if candidates else "PLANETS"
    center = src[0]
    outer = "".join(random.sample(src[1:], 6))
    pool = word_pool_map.get(src, [])
    valid = [w for w in pool if center in w and len(w) >= 4]
    
    word_wheels.append({
        "id": i,
        "centerLetter": center,
        "outerLetters": outer,
        "validWords": valid,
        "reward": 100 + (i * 5)
    })

# Generate Word Search (Placeholder arrays for now)
print("Generating Word Search levels...")
word_searches = []
for i in range(1, 51):
    grid_size = 4 if i <= 10 else (5 if i <= 30 else 6)
    pool = random.sample([w for w in curated_words if 3 <= len(w) <= grid_size], 4 + (i // 10))
    # Note: A real generator would pack the grid. We mock a simple grid string for now.
    grid_str = "".join(random.choices("ABCDEFGHIJKLMNOPQRSTUVWXYZ", k=grid_size*grid_size))
    word_searches.append({
        "id": i,
        "gridSize": grid_size,
        "gridLetters": grid_str,
        "hiddenWords": pool,
        "reward": 50 + (i * 3)
    })

# Generate Mini Crossword (Placeholder structure for architecture)
print("Generating Mini Crosswords...")
crosswords = []
for i in range(1, 51):
    size = 3 if i <= 20 else 5
    crosswords.append({
        "id": i,
        "size": size,
        "clues": [{"id": 1, "direction": "across", "x": 0, "y": 0, "clue": "Test across", "answer": "CAT"},
                  {"id": 2, "direction": "down", "x": 0, "y": 0, "clue": "Test down", "answer": "CAR"}],
        "reward": 75 + (i * 5)
    })


# Write Dart Code
dart_code = """// GENERATED CODE - DO NOT MODIFY BY HAND
import '../models/level.dart';
import '../models/puzzle_models.dart';

class LevelService {
  static final List<String> allVocabulary = """ + json.dumps(curated_words) + """;

  static final List<Level> levels = [
"""

for lvl in levels:
    hw = f'"{lvl["hardWord"]}"' if lvl["hardWord"] else 'null'
    dart_code += f'''    Level(
      id: {lvl["id"]},
      theme: "{lvl["theme"]}",
      letters: "{lvl["letters"]}",
      requiredWords: {json.dumps(lvl["requiredWords"])},
      bonusWords: {json.dumps(lvl["bonusWords"])},
      hardWord: {hw},
      difficulty: {lvl["difficulty"]},
      reward: {lvl["reward"]},
      layoutPattern: {lvl["layoutPattern"]},
    ),
'''

dart_code += """  ];
  
  static final List<RiddlePuzzle> riddles = [
"""
for r in riddles:
    dart_code += f'''    RiddlePuzzle(id: {r["id"]}, clue: "{r["clue"]}", answer: "{r["answer"]}", letters: "{r["letters"]}", reward: {r["reward"]}),
'''

dart_code += """  ];
  
  static final List<WordWheelPuzzle> wordWheels = [
"""
for w in word_wheels:
    dart_code += f'''    WordWheelPuzzle(id: {w["id"]}, centerLetter: "{w["centerLetter"]}", outerLetters: "{w["outerLetters"]}", validWords: {json.dumps(w["validWords"])}, reward: {w["reward"]}),
'''

dart_code += """  ];
  
  static final List<WordSearchPuzzle> wordSearches = [
"""
for s in word_searches:
    dart_code += f'''    WordSearchPuzzle(id: {s["id"]}, gridSize: {s["gridSize"]}, gridLetters: "{s["gridLetters"]}", hiddenWords: {json.dumps(s["hiddenWords"])}, reward: {s["reward"]}),
'''

dart_code += """  ];
  
  static final List<CrosswordPuzzle> crosswords = [
"""
for c in crosswords:
    dart_code += f'''    CrosswordPuzzle(id: {c["id"]}, size: {c["size"]}, reward: {c["reward"]}, clues: []),
'''

dart_code += """  ];
  
  static Level getLevel(int id) {
    if (id < 1) return levels.first;
    if (id > levels.length) return levels.last;
    return levels[id - 1];
  }
}
"""

with open("lib/services/level_service.dart", "w") as f:
    f.write(dart_code)

print(f"Generated level_service.dart with {len(levels)} levels, {len(riddles)} riddles, {len(word_wheels)} wheels, {len(word_searches)} searches, {len(crosswords)} crosswords, and {len(curated_words)} vocabulary words.")
