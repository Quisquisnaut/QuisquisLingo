# Build 265 change summary

Build 265 is **Word Lookup**: a learner taps a word of the language they
are learning and sees its translation from the Course's own GuideBook
vocabulary, offline. The owner's decisions of 5 October 2026 are in
`docs/265_WORD_LOOKUP_PLAN.md`; the files, steps and the owner's answers of
6 October (Q1–Q4) in `docs/265_WORD_LOOKUP_IMPLEMENTATION.md`. The owner
gave the go on 6 October 2026, after Build 264 was merged.

Revisions (plan):

- Revision 0: one reader for GuideBook vocabulary lines, read as target =
  source; QQL Demo: English from Italian's entries turned; the lookup rules
  (pure Dart) with their tests. No screen changes.
- Revision 1: the lookup card on the learner's text, never in Test Rounds or
  the Duel; the hand cursor on desktop; the one-time notice per learner and
  Course; the Word Lookup switch in Lesson Options; the texts in seven
  languages; Help EN/IT/ES.
- Revision 2: keyboard and screen-reader access; the Laboratory renamed
  QQL Demo: Italian Exercise Lab.
- Revision 3: the Lab's vocabulary (approved on 6 October), mass nouns
  without "the", and the third rule limited to articles.
- Revision 4: the distractor and Match limits become recommendations
  (another session's change of the same evening, completed and taken in
  by the owner's decision of 6 October), and three Word Lookup fixes from
  the review of Build 265. Word Lookup stays available before answering
  (no Word Lookup revision follows).
- Revisions 5–8 (owner's brief of 7 October 2026): the image library's
  tags, a redrawn picture and ten new pictures; one revision at a time,
  the next after the owner's review. Revision 5: the specific fixes, the
  new pictures and group 1 of the tags; Revisions 6 and 7: groups 2 and 3;
  Revision 8: group 4 and the five-tag minimum as a rule.

## Revision 11 (2.0.65+265011, 7 October 2026): plural pictures

The owner's decision of 7 October 2026 (Revision 6 discussion: look A of
the mock-up, stacked copies, with a switch on each picture; "as a separate
revision"), started after Revision 10 was committed (`6fe9638`).

### What changed

- **Course format**: `plural` (boolean) on an `image` element, or on the
  `text` element with role `icon` that names a QQL picture answer (QQL
  pictures on answers are stored as icon keys, Course pictures as image
  elements); on any other element a format error. Absent means one.
  `PromptElement.plural`/`isPlural`/`withPlural`,
  `ExerciseItem.pictureIsPlural`, `ExerciseFeatures.illustrationPlural`.
- **Minimum build**: `PluralPictures.withMinimumAppBuild` raises a Course
  that marks a picture to `minimumAppBuild` 265011 on confirmation, as
  Pages and picture-answer looks do; an earlier build refuses it with a
  clear reason rather than showing one picture for several.
- **Forms**: the mark travels as `ExerciseDraftValues.pluralPictures`, the
  set of marked assets or icon keys, applied to whatever a recipe builds
  (`PluralPictures.withMarks`, after the picture look) and read back by
  `PresetRecipes.decompose` (`markedIn`). No preset recipe had to change,
  and a marked exercise is still represented by its preset. The
  canonical editor's element rows keep the mark while the element stays a
  picture (it listed the attributes it keeps and would have dropped it).
- **Editor**: a **Plural** chip on `ExerciseImageField`: under the
  exercise picture (`exercise-image-plural`; not a Story cover) and under
  each answer picture (`answer-picture-plural-<i>`); the field's preview
  shows the plural look; replacing a picture keeps its mark.
- **Learner**: `PluralPicture` draws the picture three times in its own
  box: two copies at 68% and 45% opacity at the top left and right, the
  picture in front at 74%, bottom centre. Round: the exercise picture,
  picture answers (square and earlier tiles, QQL and Course pictures),
  picture options in a list, Match rows with pictures; the Duel: the
  question's picture, picture answers and the correct-answer picture.
  Match grading counts the mark (a plural picture and the same picture
  alone are different rows). A Story cover, Pages and Recognize
  characters' specimens are drawn as before.
- **Tools**: `docs/capabilities_v12.json` regenerated (`plural`,
  `textRoles: [icon]`); `tools/qql_capabilities.py` reads `text_roles`;
  `tools/validate_courses.py` refuses `plural` on a text element that is
  not an icon.
- Help EN/IT/ES (answer pictures), the exercise picture's field Help,
  `docs/COURSE_JSON_FORMAT.md`, `docs/EXERCISE_ARCHITECTURE_V12.md`.
- Not done: drawn plural pictures for the few words where stacked copies
  read badly (Grapes, Peas), suggested alongside look A; they would be
  ordinary new pictures.

### Also in Revision 11 (owner, while testing, 7 October 2026)

- **Spelling needs two blocks**: the owner found that Spell the word in
  the picture accepted one block. The three spelling presets (base recipe
  `image_word`) now refuse a Published save with fewer than two blocks
  (`ExerciseDraftErrorCode.blocksTooFew`, field Blocks of the word); a
  draft may keep one; the fields' hints say "At least two blocks". Their
  Help already said so.
- **Extra blocks** (owner decision, replacing the no-distractor rule of 29
  September 2026): the three spelling forms have an optional Extra blocks
  field (`extraWords`) below the word's blocks; the builder appends them
  to the blocks, `PresetRecipes.decompose` reads back the blocks outside
  the order, so the preset still represents the exercise; while the field
  holds something the form shows a note (`spelling-extra-blocks-note`):
  "Extra blocks are distractors: only the blocks of the word are
  recommended. Use them deliberately, fewer in a Lesson's first Rounds;
  Course Audit lists them as Info." The Audit's Info now covers Spell the
  word and Spell what you hear as well. Field Help
  (`ExerciseAuthoringField.extraSpellingBlocks`) and the blocks' Help
  (EN/IT/ES) say where distractors go.
- `PluralPicture.wrap` leaves a picture that is not plural untouched (the
  Laboratory presentation baseline records the widget tree of each
  answer).
- **Family scenes** (owner decisions: small scenes, the person ringed in
  yellow): Father (a man holding a small child), Mother (a woman holding
  a small child), Son, Daughter and Child (in front of their parents),
  Brother and Sister (beside a sibling), Uncle and Aunt (beside the
  child's parent and the child), drawn with the pronoun pictures' parts
  (`draw11.py`); 6 got the grey ring (their yellow ring makes a light
  edge). The family-tree pictures keep their files and tags and are named
  "<Who> (family tree)"; the plain names go to the scenes, as Grandfather
  and Grandmother were.
- **Man 2, Man 3, Woman 2, Woman 3** (owner: numbered): Man and Woman in
  other skin, hair and clothes colours, with Man's and Woman's tags.
- **Friends (women)**: three women friends (`relationships_friends_women`).
- 4,334 pictures (`bundledImageCount` 4334). Tags that equal another
  picture's name are general words the named picture keeps (Parent, Boy,
  Girl, Child, Siblings), as on the family-tree pictures.

## Revision 10 (2.0.65+265010, 7 October 2026): historical figures and landmarks from more places

The owner's decisions of 7 October 2026, started after Revision 9 was
committed (`a68a2da`).

### What changed

- **Forty new figures** in `historical_figures`, each with its country,
  at least five tags and one attribute that names it (Lincoln's top hat,
  Nightingale's lamp, Sax's saxophone, Hokusai's wave, Sejong's Hangul
  scroll): Simón Bolívar (Venezuela), Diego Velázquez (Spain), Gabriela Mistral
  (Chile), Luís de Camões, Fernando Pessoa (Portugal), Alberto
  Santos-Dumont (Brazil), Rembrandt, Vincent van Gogh, Erasmus
  (Netherlands), Johannes Gutenberg, Bach, Clara Schumann (Germany), Louis
  XIV, Victor Hugo, Louis Pasteur (France), Abraham Lincoln, Jackson
  Pollock, Benjamin Franklin (United States), Queen Victoria, Florence
  Nightingale, Jane Austen (England), James Watt (Scotland), Tutankhamun
  (Egypt), Catherine the Great, Leo Tolstoy (Russia), Hokusai, Murasaki
  Shikibu (Japan), Ibn Battuta (Morocco), Mansa Musa (Mali), Genghis Khan
  (Mongolia), King Sejong (Korea), Al-Khwarizmi (Iraq, Uzbekistan),
  Nicolaus Copernicus (Poland), Hans Christian Andersen (Denmark), Leif
  Erikson (Iceland, Norway), Adolphe Sax (Belgium), Queen Nzinga (Angola),
  Benito Juárez (Mexico), Zheng He (China), the Trưng Sisters (Vietnam). Drawn as SVG in the flat style of the
  existing figures by `draw10.py` (outside the repository), rendered with
  headless Chrome, 256 × 256 lossless WebP of 8–17 KB; Al-Khwarizmi, Bach,
  Jane Austen, Leo Tolstoy, Tutankhamun and Victor Hugo got the grey ring
  (`tools/outline_light_edges.py`). The Trưng Sisters share one picture.
- **Columbus is removed** (record and file); nothing else used it.
- **Country tags** on the figures already there: Julius Caesar, Dante,
  Petrarch, Marco Polo "Italy"; Cleopatra "Egypt"; Plato, Socrates,
  Aristotle "Greece"; Confucius "China"; Charlemagne "France" and
  "Germany". Alexander the Great keeps "Ancient Greece" and "Macedonian"
  only. A country tag is the same word as that country's flag; the flag
  keeps the word through its name.
- **Tags avoid bare words another picture answers better**: "Dutch
  painter", not "painter"; "creator of Hangul", not "hangul"; "inventor
  of the saxophone", not "saxophone"; "The Lady with the Lamp", not
  "lamp".
- **Left out**: Einstein (an earlier owner decision), Picasso, Frida
  Kahlo and Martin Luther King (name and likeness still licensed), and
  the sensitive Anne Frank, Sitting Bull, Moctezuma, Martin Luther and
  Columbus; `test/figures_and_landmarks_265_test.dart` checks that none of
  them is in the catalogue.
- **Twenty-two landmarks**, the owner's approved list (the owner asked
  for "more missing places"; Landmarks held eight): Big Ben, Tower Bridge, Stonehenge (United
  Kingdom), Arc de Triomphe (France), Brandenburg Gate, Neuschwanstein
  Castle (Germany), Amsterdam canal houses (Netherlands), Alhambra (Spain),
  Belém Tower (Portugal), Rialto Bridge (Italy), Parthenon (Greece),
  Kremlin (Russia), Mount Fuji (Japan), Forbidden City (China),
  Gyeongbokgung Palace (South Korea), Machu Picchu (Peru), Chichén Itzá
  (Mexico), Sugarloaf Mountain (Brazil), Golden Gate Bridge (United
  States), Niagara Falls (Canada, United States), Petra (Jordan), Mount
  Kilimanjaro (Tanzania).
  Drawn by `draw10_places.py` in the style of the eight before them:
  buildings on a soft shadow, landscapes (Stonehenge, Mount Fuji, Machu
  Picchu, Sugarloaf Mountain, Niagara Falls, Petra, Mount Kilimanjaro) in
  a rounded tile with their sky. Each has "landmark", its country and city;
  bare words another picture answers better are phrases ("suspension
  bridge", "fairy-tale castle", "Japanese volcano", "city gate"). The
  Kremlin's tower has a plain gold point, not the star.
- Accent-free spellings as tags, for authors typing without accents:
  "Simon Bolivar", "Diego Velazquez", "Luis de Camoes", "Benito Juarez",
  "Trung Sisters", "Chichen Itza", "Belem Tower", "Champs-Elysees".
- **Landmarks left out**: modern designs still protected or restricted
  (Atomium, the Little Mermaid, Christ the Redeemer, the Louvre Pyramid,
  Burj Khalifa), places sacred to their peoples (the Moai, Uluru), and
  religious buildings (Sagrada Família, St Basil's, Hagia Sophia, Angkor
  Wat: not on the owner's list).
- 4,320 pictures (`bundledImageCount` 4320); 66 historical figures, 30
  landmarks. The test is `test/figures_and_landmarks_265_test.dart`.

## Revision 9 (2.0.65+265009, 7 October 2026): category groups

The owner's decisions of 7 October 2026 ("Agreed": groups as Revision 9,
plurals as Revision 10), started after Revision 8 was committed
(`90a174d`).

### What changed

- `lib/models/image_categories.dart`: `imageCategoryGroups` (11 groups),
  `imageCategoryGroupLabels`, `isImageCategoryGroup`, `imageCategoryGroupOf`,
  `imageCategoriesOfGroup`, `imageSubcategoryLabel`; `imageCategoryLabel`
  names a group, and a grouped category after its group ("free time › art
  cinema"), as it did for the characters. Groups: people (people & family, jobs, relationships, life stages, appearance,
  personality, emotions), food & drink (food & drinks, food descriptions,
  restaurant), body & health, home & things, places & travel, numbers &
  time, language & grammar, society & culture, history & stories, free time,
  nature & animals.
  Alone: flags, Lesson icons, actions, movement, clothing and accessories,
  school and work, concepts, symbols, colours, Other.
- `FlatImageLibraryScreen`: the top row has one chip per group (21 category
  chips instead of 73); choosing a group shows every picture of its categories and
  opens a second row, `exercise-image-group-categories` ("all <group>" and
  the categories present), the characters keeping their own key. Choosing a
  category, or opening it from a picture's card, keeps its group selected.
- A group shows what its categories show, so a picture tagged "restaurant"
  is in Food & drink; the rule of a tag and the category of the same name
  stays with the categories (a tag "people" adds nothing to People).
- `matchesImageSearch`: a group's whole name, "&" or "and", finds its
  pictures. The decision is recorded as "a group's name is searchable";
  single words of a group name were left out because "time" would bring up
  every number, unit and shape, and "home" every tool.
- The category menus (Edit metadata, an Image Bank's new categories) show
  the grouped names, so a group's categories stand together.
- Help EN/IT/ES: Image Library Help ("Finding a picture") and the Editor
  Help answer `findPicture`; `docs/COURSE_EDITOR.md`.
- Tests: `test/image_category_groups_265_test.dart` (every group's
  categories exist, none twice, group keys are not categories, the
  standalone list; lookups and labels; search by whole name; the library's
  group chip, second row, counts and the namesake rule; the characters'
  row unchanged). `image_library_categories_264_test`,
  `image_library_namesake_264_test` and `import_archives_tranche4_test`
  choose the group first or read the grouped name.

Nothing stored changes: no picture, Course file, device record or learner
data.

## Revision 8 (2.0.65+265008, 7 October 2026): group 4 tags; five tags become a rule

The owner's brief of 7 October 2026 (Revision 8: group 4 and the rule),
started after Revision 7 was committed (`9978ccd`).

### What changed

- **Group 4**: 515 records, none below five tags. The categories the brief
  did not name (jobs and professions, units, clock times) had five tags
  already. **No record outside the character categories has fewer than
  five tags.** Words left out because another picture answers them better:
  type (What kind?), what time (the picture "What time?"), lines
  (Wrinkles). Every added tag: `docs/265_REVISION8_TAGS.md`.
- **Tennis** loses "racket", which names the redrawn Tennis racket (it
  wins the word through its name in any case).
- **Point 10, the rule**: `tools/validate_images.py` 2.9.0 refuses a
  bundled record outside the character categories with fewer than 5 tags,
  and any bundled record with more than 32 tags or a tag over 80
  characters; the Revision 5 tag report is gone (it became this check).
  `test/image_catalog_rules_264_test.dart` ("every picture outside the
  characters has 5 to 32 tags") checks the same. Image Banks an Admin
  imports are not checked by this tool and keep their rule (at least one
  tag); nothing in the app changed.
- The catalogue now has at most 15 tags on a record and no tag longer than
  52 characters.

### Records completed, by category (515)

- **personality** (17): Intelligent; Silly; Shy; Outgoing; Introverted; Extravagant; Kind; Generous; Selfish; Brave; Lazy; Hard-working; Patient; Impatient; Curious; Proud; Modest.
- **politics** (12): Politician; Election; Voting; Democracy; Parliament; Government; Protest; Trade Union; Strike; Picket Line; Negotiation; Agreement.
- **pronouns_be_have** (2): It is; It has.
- **quantity_pointing** (15): This; That; These; Those; Here; There; None; Few; Some; Many; All; Both; Each; Enough; Too much.
- **question_words** (11): Who?; Where?; When?; What?; Which?; Why?; Whose?; How long?; How often?; How far?; Where to?.
- **relationships** (19): Hugging; Holding Hands; Giving Flowers; Proposing Marriage; Wedding; Partner; Husband; Wife; Marriage; Bride; Groom; Anniversary; Separation; Divorce; Widow; Widower; Adoption; Stepparent; Half-sibling.
- **religious_figures** (3): Bishop; Pope; Monk (Christian).
- **restaurant** (22): Menu; Tablecloth; Napkin; Saucer; Teaspoon; Tray; Bottle; Jug; Salt Shaker; Pepper Mill; Bread Basket; Bill; Reservation; Order; Starter; Main Course; Side Dish; Dessert; Takeaway; Tip; Straw (drinking straw); Wine glass.
- **school_work** (42): Book; Pencil; Scissors; Ruler; Calculator; Pen; Eraser; Notebook; Stapler; Globe; Blackboard; Pencil Sharpener; Pupil; Coloured pencils; Timetable (school); Homework; Exam (test); PE (physical education); Notice board; Page; Textbook; Lecture hall; Kindergarten; Test tube; Microscope; School trip; Locker; Bookmark; Diary; Clipboard; Crayon; Dictionary; Envelope; Folder; Glue stick; Highlighter; Magazine; Newspaper; Paper clip; Pencil case; Sticky note; Whiteboard.
- **services** (27): Library; Post office; Police station; Fire station; Town hall; Recycling centre; Waste collection; Hotel; Supermarket; Bakery; Pharmacy; Hairdresser; Vet; Laundrette; Electrician; Bookshop; Clothes shop; Toy shop; Florist's (shop); Beauty salon; Department store; Electronics shop; Fishmonger's; Greengrocer's; Hardware store; Pet shop; Travel agency.
- **shapes_patterns** (20): Circle; Square; Triangle; Rectangle; Oval; Heart; Diamond; Hexagon; Cube; Sphere; Cylinder; Cone; Striped; Polka Dot; Checkered; Zigzag; Wavy; Plaid; Vertical; Horizontal.
- **shopping** (30): Shopping Trolley; Shopping Basket; Shopping Bag; Buying Groceries; Trying on Shoes; Weighing Fruit; Gift Wrapping; Shopping Online; Paying with Cash; Cash; Coins; Banknotes; Payment Card; Parcel; Opening a Parcel; Packing a Parcel; Cheap; Expensive; Discounted; Free; Price tag; Changing room; Shop window; Open sign; Closed sign; Sell; Shopping list; Barcode; Label; Vending machine.
- **sizes_dimensions** (13): Big; Small; Tall; Short; Long; Wide; Narrow; Full; Empty; Heavy; Light; Half; Medium (size).
- **sports** (76): Football; Basketball; Volleyball; Tennis; Table Tennis; Badminton; Cricket; Golf; Ice Hockey; Swimming; Diving; Scuba Diving; Surfing; Windsurfing; Kayaking; Cycling; Boxing; Fencing; Archery; Horse Riding; Climbing; Skiing; Snowboarding; Ice Skating; Roller Skating; Skateboarding; Bowling; Billiards; Parachuting; Weight Training; Player; Referee; Goalkeeper; Football pitch; Sport; Athletics; Rugby; Baseball; Rowing; Karate; Gymnastics; Yoga; Race; Podium; Goggles (swimming); Olympic Games; Football boots; Stopwatch; Judo; Marathon; Penalty; High jump; Long jump; Relay race; Push-up; Sit-up; Treadmill; Wrestling; Yellow card; Red card; Silver medal; Bronze medal; Stretching; Sports hall; Ski slope; Running track; Hurdles; Javelin; Mountain biking; Motor racing; Horse racing; Goal; Golf club; Tennis racket; Sledge; Swimming pool.
- **street_signs** (11): Stop sign; No entry; No parking; Speed limit; Pedestrian crossing sign; Roadworks; One-way street; No left turn; No U-turn; Parking; Wheelchair access.
- **symbols** (5): Prohibition sign; Power symbol; Play symbol; Pause symbol; Stop symbol.
- **technology** (37): Laptop; Camera; Smartphone; Headphones; Television; Desktop Computer; Keyboard; Computer Mouse; Printer; Microphone; USB Flash Drive; Battery; Satellite Dish; Robot; Tablet (computer); Selfie; App; Projector; Video camera; Scanner; Drone; Smartwatch; Password; QR code; Power bank; CD; Download; Upload; Webcam; E-reader; Headset; Charger; Earphones; Radio; Router; Screen; Hard drive.
- **time_calendar** (38): Hourglass; Calendar; January; February; March; April; May; June; July; August; September; October; November; December; Spring; Summer; Autumn; Winter; Seasons; Morning; Noon; Afternoon; Evening; Night; Midnight; Yesterday; Today; Tomorrow; Week; Weekday; Weekend; Month; Year; Hour; Minute; Second; Day (daytime); Timer.
- **tools** (20): Hammer; Screwdriver; Spanner; Pliers; Saw; Drill; Ladder; Screw; Nail; Toolbox; Paintbrush; Paint Roller; Lawnmower; Hard hat; Axe; Hose; Rake; Shovel; Tape measure; Torch.
- **transport** (47): Car; Train; Airplane; Bus; Bicycle; Sailboat; Truck; Motorcycle; Cruise Ship; Camper Van; Ambulance; Fire Engine; Rocket; Passenger; School bus; Ticket (travel); Van; Rowing boat; Hot-air balloon; Cable car; Driving licence; Departure board; Life jacket; Car accident (crash); Kick scooter; Yacht; Engine; Car key; Number plate; Ticket machine; Electric scooter; Double-decker bus; Sports car; Caravan; Carriage (horse-drawn); Speedboat; Fishing boat; Steam train; High-speed train; Flat tyre; Electric car; Ferry; Helicopter; Tram; Seat belt; Steering wheel; Tyre.
- **travel** (39): Suitcase; Map; Compass; Packing; Taking Photographs; Hiking; Reading a Map; Passport; Campsite; Boarding pass; Holiday; Guidebook; Postcard; Check-in (airport); Sightseeing; Tourist information; Delay; Border; Passport control; Hand luggage; Beach umbrella; Sunbed; Sandcastle; Bucket and spade; Hotel room; Hostel; Ski resort; Ski lift; Visa; Backpacker; Luggage trolley; Deckchair; Key card; Single room; Double room; Breakfast buffet; Tour bus; Inflatable ring; ID card.
- **utilities** (9): Water supply; Heating; Air conditioning; Water meter; Electricity meter; Solar panel; Wind turbine; Power line; Drain.

## Revision 7 (2.0.65+265007, 7 October 2026): group 3 tags

The owner's brief of 7 October 2026 (Revision 7: group 3), started after
the owner's go of 11:00 (Revision 6 committed `49865fb`, its follow-up
Friend (woman) with two women `cb73c6a`), and the owner's request for two
tags on each "you" picture.

### What changed

- **Group 3**: 546 records, none below five tags. The tags were drafted
  while the follow-up's complete suite ran and applied after its commit.
  Descriptive tags were checked against the drawings, and those that did
  not fit were replaced before applying: two-seater (not three-seater),
  single bed (not double), plain chair (not wooden), glass window (not
  open), pedestal sink (not kitchen sink), shower spray (no cubicle),
  chef's knife (not table knife), ceramic vase (not glass), glowing bulb
  (not LED), stovetop kettle (not electric), snare drum (not bass drum),
  flower petal (not rose petal), comic panels (not superhero comic), card
  trick (not rabbit in a hat), grey concrete (not concrete wall). Words
  left out because another picture answers them better: comforter (Duvet),
  school lunch (School canteen), nursery (Kindergarten), far away (Far),
  sun lounger (Sunbed), delayed (Delay), schoolgirl (Pupil). The Lesson
  icons are tagged in `metadata_v2.json` (owner decision of Revision 6).
  Every added tag: `docs/265_REVISION7_TAGS.md`.
- **Owner's tags**: "You, your, yourself": you singular, singular you; "You
  all, your, yourselves": you plural, plural you.
- **Corrections**: "hoover" moves from Vacuuming (Revision 5) to Vacuum
  cleaner, which it names; Vacuuming takes "vacuum the carpet". Hot
  (Revision 6) shows a steaming drink: "hot food" becomes "hot drink".
  The other Revision 6 pictures with descriptive tags were checked: no
  other change.

### Records completed, by category (546)

- **historical_figures** (1): Cleopatra.
- **hobbies_leisure** (71): Pottery; Filmmaking; Origami; Sewing; Knitting; Crochet; Embroidery; Woodworking; Playing the Piano; Playing the Violin; Playing the Drums; Playing the Flute; Playing the Trumpet; DJing; Karaoke; Chess; Card Games; Dominoes; Jigsaw Puzzle; Video Games; Darts; Table Football; Camping; Fishing; Birdwatching; Gardening; Picnicking; Stargazing; Flying a Kite; Sunbathing; Cake Decorating; Making Pizza; Making Pasta; Collecting Stamps; Collecting Coins; Collecting Records; Going to the Cinema; Visiting Art Galleries; Shopping; Chatting; Kissing; Smoking; Guitar; Drum; Accordion; Concert; Saxophone; Orchestra; Comic (comic book); Circus; Puppet (puppet show); Magic trick; Roller coaster; Carousel (merry-go-round); Ferris wheel; Band; Harp; Cello; Choir; Poem; Opera; Photo album; Tambourine; Xylophone; Recorder (instrument); Disco; Clarinet; Trombone; Bumper cars; Waterslide; Sleeping bag.
- **home_household** (113): House; Chair; Bed; Table; Lamp; Door; Window; Sofa; Toilet; Sink; Bathtub; Shower; Refrigerator; Oven; Frying pan; Pot; Knife; Fork; Spoon; Broom; Trash can; Vacuum cleaner; Key; Alarm Clock; Light Bulb; Plate; Bowl; Saucepan; Kettle; Cutting Board; Armchair; Remote Control; Bookshelf; Cushion; Rug; Curtains; Pillow; Blanket; Wardrobe; Hanger; Mirror; Bedside Table; Toothbrush; Toothpaste; Soap; Towel; Toilet Paper; Hairdryer; Dustpan; Mop; Bucket; Sponge; Washing Machine; Iron; Ironing Board; Laundry Basket; Lock; Light Switch; Socket; Teddy Bear; Pram; Baby Bottle; Dummy; Nappy; Washing Line; Clothes Peg; Jar; Barrel; Watering Can; Wheelbarrow; Button; Zip; Safety Pin; Kitchen (room); Bedroom; Bathroom; Living room; Dining room; Desk; Chest of drawers; Cupboard; Flowerpot; Ceiling; Mattress; Stool; Bathroom scales; Greenhouse; Flower bed; Vegetable garden; Birdhouse; Blender; Can opener; Chopsticks; Coffee maker; Dishwasher; Freezer; Ladle; Lunchbox; Microwave; Oven glove; Rolling pin; Sieve; Thermos; Toaster; Cot; Doorbell; Extension lead; Heater; Highchair; Letterbox; Picture frame; Smoke alarm; Vase.
- **ideas_opinions** (16): Idea; Thinking; Opinion; Agreeing; Disagreeing; Doubt; Belief; Debate; Advice; Feminism; Socialism; Capitalism; Communism; Anarchism; Conservatism; Liberalism.
- **landmarks** (8): Eiffel Tower; Colosseum; Leaning Tower of Pisa; Statue of Liberty; Pyramids of Giza; Great Wall of China; Taj Mahal; Sydney Opera House.
- **languages** (40): Italian; Japanese; Korean; Greek; Polish; Turkish; Dutch; Swedish; Norwegian; Danish; Finnish; Hungarian; Czech; Slovak; Slovene; Croatian; Serbian; Bulgarian; Romanian; Russian; Ukrainian; Lithuanian; Latvian; Estonian; Icelandic; Albanian; Armenian; Georgian; Hebrew; Persian; Hindi; Bengali; Thai; Vietnamese; Indonesian; Malay; Filipino; Urdu; Maltese; Irish.
- **lesson_icons** (17): Home; Food; Café / Coffee; Shopping; Directions / Map; Train; Hotel; Work; School; Time / Calendar; Leisure; Animals; Clothing; Sports; Music; Emotions; City.
- **life_stages** (9): Pregnancy; Birth; Newborn; Toddler; Teenager; Growing up; Aging; Life; Generations.
- **literary_characters** (1): Robinson Crusoe.
- **maps_navigation** (26): World map; Street map; Map pin; Route; North; South; East; West; Straight ahead; You are here; Africa (map); Asia (map); Europe (map); North America (map); South America (map); Oceania (map); Antarctica (map); Turn left; Turn right; Compass rose; Equator; Atlantic Ocean (map); Pacific Ocean (map); Mediterranean Sea (map); North Pole; South Pole.
- **materials_commodities** (10): Coffee beans; Coal; Sand; Wooden; Cardboard; Leather; Silk; Steel; Concrete; Pearl.
- **movement** (6): Fast; Spin; Bounce; Fall; Grow; Shrink.
- **mythology** (26): Poseidon; Medusa; Thor; Ra; Anubis; Isis; Minotaur; Centaur; Pegasus; Phoenix; Mermaid; Unicorn; Cyclops; Griffin; Wizard; Witch; Fairy; Magic wand; Ghost; Dragon; Elf; Potion; Cauldron; Crystal ball; Broomstick; Alien.
- **nature** (92): Tree; Mountain; Sun; Flower; Moon; Star; Rain; Beach; Island; Waterfall; Forest; Cave; Flowers; Nest; Feather; Paw Print; Spiderweb; Seashell; Planet; Grass; Rose; Sunflower; Tulip; Cactus; Fern; Bamboo; Palm Tree; Willow; Water Lily; Leaf; Roots; Tree Stump; Pine Cone; Acorn; Seedling; Mountain Range; Valley; Canyon; Cliff; Volcano; River; Lake; Iceberg; Coral Reef; Fire; Ice; Snow; Rock; Pebbles; Mud; Lava; Crystal; Cloud; Snowfall; Lightning; Rainbow; Wind; Tornado; Rainy; Snowy; Foggy; Thunder; Hail; Weather forecast; Branch; Bush; Shadow; Snowman; Frost; Meadow; Oak tree; Tide; Horizon; Earthquake; Flood; Drought; Avalanche; Wildfire; Hurricane; Heatwave; Comet; Galaxy; Eclipse; Full moon; Petal; Lily; Daffodil; Poppy; Lavender; Vineyard; Orchard; Olive tree.
- **numbers** (19): 100; 1 000; 1 000 000; I; II; III; IV; V; VI; VII; VIII; IX; X; −5; 2.5; ½; ⅓; ¼; 50%.
- **opposites** (54): Good; Bad; Wet; Dry; Early; Late; Easy; Difficult; Ugly; Near; Far; Thick; Thin; Sharp; Blunt; Rotten; Outside; Hungry; Thirsty; Safe; True; False; Possible; Impossible; Deep; Young; Old; Weak; Cute; Shallow; Straight; Crowded; Alive; Dead; Awake; Blind; Rough; Sticky; Shiny; Tight; Loose; Modern; Ancient; Scary; Comfortable; Wild; Steep; Bent; Torn; Rusty; Deserted; Poisonous; Old-fashioned; Transparent.
- **people_family** (37): Man; Woman; Boy; Girl; Baby; Grandfather; Grandmother; Family; Parent; Mother; Father; Child; Son; Daughter; Brother; Sister; Siblings; Grandmother (family tree); Grandfather (family tree); Grandparents; Grandchild; Aunt; Uncle; Cousin; Nephew; Niece; Twins; Ancestor; Descendant; King; Queen; Knight; People; Neighbour; Crowd; Prince; Princess.

## Revision 6 (2.0.65+265006, 7 October 2026): group 2 tags, personal pronouns, friends, kids, greetings

The owner's brief of 7 October 2026 (Revision 6: group 2) and the owner's
answers of the same morning, after Revision 5 was committed (`ea159c2`):

- one picture per person for the personal pronouns, names like "I, me, my,
  myself", "me" and "myself" moved from "I am";
- Friend (man) / Friend (woman): the owner asked why not "(male)/(female)";
  decision: keep one rule by what the picture shows, adults "(man)/(woman)"
  (as the 158 existing names since Build 264), children "(boy)/(girl)",
  animals "(male)/(female)"; the tags carry male and female;
- Kid (boy) / Kid (girl), in other colours than Boy and Girl;
- Hello, Bye, Goodbye "with text if necessary": the word in a speech
  bubble, like the 35 other greetings (without it Bye and Goodbye cannot be
  told apart);
- flags tagged in `metadata_v2.json` (option a: nothing builds flag tags
  from the World Flags manifest, which has none; the same holds for the
  Lesson icons of Revision 7);
- Vest, Mango and Jump fixed;
- plurals: a "Plural" switch on a picture in an exercise, drawn as stacked
  copies (option A of the mock-up), as its own Revision 9 after the tags,
  because it changes the Course format; not started.

### What changed

- **Pictures** (`D:\QQL_plus\nuove_immagini\serie7_265\draw6.py`, the
  pipeline of `draw.py`, sources in `svg/`): 15 WebP, lossless, 12–20 KB,
  margins 15 px; five with a light edge (the yellow halos, the girl's skin)
  got the grey edge from `tools/outline_light_edges.py`, as the library's
  own "I am" and "We are" did in Build 264.
  - Pronouns (`pronouns_be_have`): the speaker in blue (as in "I am") points;
    the person or people meant are ringed in yellow; a wordless "…" bubble
    marks the speaker; the listener (orange, as in "You are") stands in
    front, the people spoken about behind, smaller. I: the speaker rings
    himself; you: the listener; he, she: a man or a woman behind; it: a
    ball; we: the speaker and a friend in one ring; you all: three
    listeners; they: two people behind.
  - Friend (man) / (woman) (`relationships`): the speaker high-fives the
    friend, who is ringed in yellow; no heart, unlike Partner. Follow-up
    after the owner's review (7 October, 11:00): Friend (woman) shows two
    women (a woman in blue in the speaker's place); Friend (man) shows two
    men.
  - Kid (boy) / (girl) (`people_family`): about six years old, full length,
    waving and holding a ball; dark skin and a green T-shirt / light skin,
    red bunches and a purple T-shirt (Boy is light-skinned in blue, Girl
    medium brown in yellow).
  - Hello!, Bye!, Goodbye! (`greetings_expressions`): the word in a speech
    bubble; Hello! waves; Bye! waves with a backpack, walking off; Goodbye!
    leaves with a suitcase. Hello!'s file is `hello_greeting.webp`:
    `assets/exercise_images/hello.webp` is a retired path that
    `unified_learner_layout_regression_test` keeps unused (the first
    complete run caught it).
- **Vest and Mango** re-rendered from their Build 264 sources with the
  taller-window fix in `serie1_rifatte/redo.py` (the previous files are
  kept there as `*_before_265.webp`); Football goal was not cut and stays.
- **Jump**: "Saltare" → "Jump"; "jump" leaves the tags, "jump up" joins.
- **Drink** gives "glass of water" to Water (the importer would have chosen
  Drink) and takes "have a drink".
- **Group 2**: 539 records, none below five tags. Words left out because
  another picture answers them better: vitamin C (Vitamins), packed lunch
  (Lunchbox), olive branch (Pacifism), dartboard and bullseye (Darts),
  glass ball (Crystal ball), banknotes and coins (Cash), shake (Milkshake),
  drape (Curtains), row (Rowing), stick (Ice hockey), over the top
  (Extravagant), hey (Calling out), small child (Toddler). Every added tag:
  `docs/265_REVISION6_TAGS.md`.

### Records completed, by category (539)

- **construction_farming** (10): Brick; Crane; Excavator; Cement Mixer; Tractor; Scarecrow; Hay Bale; Bulldozer; Barn; Pitchfork.
- **crime_law** (8): Thief; Shoplifting; Vandalism; Handcuffs; Arresting Someone; Prisoner; Prison Cell; Police Car.
- **culture_traditions** (36): Russian Nesting Dolls; Folding Fan; Chinese Lantern; Piñata; Boomerang; Bagpipes; Maracas; Gondola; Venetian Mask; Kimono; Kilt; Sari; Sombrero; Poncho; Clogs; Cowboy Hat; Cowboy Boots; Dragon Dance; Flamenco; Halloween; Easter Eggs; Bonsai; Duel; Sword; Shield; Throne; Treasure chest; Pirate; Spear; Catapult; Goblet; Feast; Dagger; Cannon; Treasure map; Pirate ship.
- **death_remembrance** (13): Death; Dying; Funeral; Coffin; Grave; Cemetery; Cremation; Mourning; Remembrance; Heir; Inheritance; Will; Inheriting.
- **directions_positions** (15): Up; Down; Left; Right; On; Under; Above; Inside; Next To; Between; In Front Of; Behind; Upside down; Upstairs; Downstairs.
- **economy_finance** (49): Business; Trade; Import; Export; Economic Growth; Recession; Inflation; Profit; Loss; Taxes; Salary; Rich; Poor; Contract; Invoice; Currency; Euro; Dollar; Pound Sterling; Yen; Currency Exchange; Exchange Rate; Savings; Debt; Budget; Bank; Bank Account; Account balance; Deposit; Withdrawal; Bank Transfer; Loan; Mortgage; Interest; Credit Card; Debit Card; Safe; Trading; Stock Market; Shares; Investment; Dividend; Rising Price; Falling Price; Fluctuating Price; Line Chart; Bar Chart; Pie Chart; Candlestick Chart.
- **emotions** (35): Happy; Sad; Angry; Surprised; Laugh; Scared; Bored; Crying; Pointing; Shrugging; Winking; Yawning; Whispering; Arguing; Smile; Excited; Worried; Nervous; Embarrassed; Jealous; Stressed; Disappointed; Shocked; Disgusted; In love; Annoyed; Scream; Grateful; Ashamed; Guilty; Homesick; Frustrated; Panic; Frown; Blush.
- **everyday_objects** (25): Fire Extinguisher; Lifebuoy; Rope; Chain; Match; Matchbox; Lighter; Cork; Corkscrew; Magnet; Spring; Funnel; Tape; Paint; Glue; Rubber band; Tarpaulin; Fishing net; Anchor; Bell; Whistle; Water bottle; Magnifying glass; Fire alarm; Ribbon.
- **flags** (23): Antarctica; Bouvet Island; Corsican; French Guiana; Friulian; Guadeloupe; Heard Island and McDonald Islands; Ligurian; Lombard; Martinique; Mayotte; Mirandese; Northern Ireland; Occitan; Roma; Réunion; Saint Barthélemy; Saint Martin (French part); Saint Pierre and Miquelon; Sardinian; Svalbard and Jan Mayen; United States Minor Outlying Islands; Venetian.
- **food_descriptions** (19): Hot; Cold; Sweet; Salty; Sour; Bitter; Spicy; Fresh; Ripe; Raw; Cooked; Crispy; Soft; Tender; Creamy; Delicious; Disgusting; Burnt; Unhealthy.
- **food_drinks** (145): Bread; Apple; Water; Coffee; Orange; Bananas; Strawberry; Carrot; Tomato; Broccoli; Potato; Cheese; Egg; Burger; Pizza; Rice; Soup; Salad; Milk; Juice; Tea; Ice cream; Chocolate; Cake; Croissant; Watermelon; Grapes; Lemon; Cherries; Pear; Pasta; Flour; Butter; Cream; Yogurt; Meat; Beef; Pork; Chicken; Shrimp; Mussels; Seafood; Vegetables; Onions; Garlic; Lettuce; Peas; Beans; Lentils; Fruit; Olives; Olive Oil; Vinegar; Salt; Pepper; Sugar; Honey; Basil; Parsley; Rosemary; Sandwich; Omelette; Steak; Roast Chicken; Grilled Fish; Mashed Potatoes; Fries; Biscuits; Sparkling Water; Lemonade; Beer; Wine; Bruschetta; Spaghetti; Tagliatelle; Lasagne; Tortellini; Gnocchi; Mozzarella; Prosciutto; Salame; Gelato; Espresso; Cappuccino; Sushi; Taco; Nachos; Hot Dog; Fish and Chips; Paella; Fondue; Baguette; Waffle; Pancakes; Doughnut; Churros; Fortune Cookie; Gingerbread Man; Dinner; Tin (can); Avocado; Bell pepper; Salmon; Noodles; Fried egg; Ketchup; Cereal (breakfast); Lime; Apricot; Blueberries; Raspberries; Grapefruit; Coconut; Cauliflower; Spinach; Muffin; Lollipop; Porridge; Sauce; Mayonnaise; Mustard; Cola; Milkshake; Curry; Kebab; Celery; Asparagus; Sweet potato; Scrambled eggs; Cocktail; Chewing gum; Peanut butter; Meatballs; Risotto; Aubergine; Bacon; Cabbage; Courgette; Cucumber; Kiwi; Mango; Melon; Peach; Pineapple; Plum.
- **games** (55): Dice; Hearts; Diamonds; Clubs; Spades; Ace; Joker; Deck of cards; Hand of cards; Draughts piece; Playing piece; Poker chip; Board game; Puzzle piece; Dart; Spinner; Tile; Marble; Trophy; Medal; Scoreboard; Winner; Winning; Turn; Draw; Checkmate; Strategy; Cheating; Doll; Toy car; Toy train; Building blocks; Dollhouse; Skipping rope; Sandpit; Beach ball; Bubbles (soap bubbles); Yo-yo; Rocking horse; Water pistol; Frisbee; Spinning top; Colouring book; Stickers; Snowball; Tricycle; Trampoline; Hula hoop; Rubber duck; Crossword; Hopscotch; Paper plane; Tug of war; Rock, paper, scissors; Noughts and crosses.
- **grammar** (15): Noun; Pronoun; Verb; Adjective; Adverb; Preposition; Conjunction; Singular; Plural; Infinitive; Negation; Subject; Object; Sentence; Exclamation.
- **grammar_time** (2): Present; Imperative.
- **greetings_expressions** (23): Good morning!; Good night!; Welcome!; Maybe; Please; Thank you; You're welcome; Excuse me; Take care!; Forbidden; No problem!; Wait!; Hurry up!; Let's go!; Good luck!; See you soon!; Stop!; Really?; Never mind; After you; Bless you!; Oh no!; Phew!.
- **health_care** (30): Plaster; Bandage; Thermometer; Crutches; Wheelchair; Stethoscope; Syringe; Pills; Tissues; X-ray; Stretcher; Waiting room; Inhaler; Blood test; Blood pressure; Prescription; Hospital bed; Vitamins; Eye test; Shower gel; Face mask; First aid kit; Hand sanitizer; Hearing aid; Walking stick; Contact lens; Cotton bud; Shampoo; Deodorant; Sunscreen.
- **health_illness** (36): Sick; Fever; Coughing; Sneezing; Headache; Toothache; Stomach ache; Vomiting; Injury; Bleeding; Broken arm; Allergy; Medicine; Capsule; Cough syrup; Eye drops; Ointment; Injection; Vaccination; Bandaging; Surgery; Treatment; Recovery; First aid; Earache; Sore throat; Healthy; Sunburn; Bruise; Burn; Rash; Itch; Scar; Blister; Nosebleed; Dizzy.

## Revision 5 (2.0.65+265005, 7 October 2026): image library tags, a redrawn picture, ten new pictures

The owner's brief of 7 October 2026. Better tags and a few new pictures
make the image library easier to search, for Course authors and for
Courses imported from other tools. Committed locally at the owner's word
(7 October 2026), not pushed.

**Rules followed for every tag** (all four revisions): English; never the
picture's name (the validator refuses it); what a Course author would
search for: the everyday synonyms, the more specific or more general word,
the usual phrase, the verb or adjective shown; no padding with generic
words (picture, image, thing, object, icon) or with words that fit many
pictures of a category equally; existing tags kept in their order, new ones
appended; at most 32 tags per record, 1–80 characters each, unique
(capitals and spaces ignored); at least five outside the character
categories.

**Never a tag that describes another picture better.** Every new tag was
checked against the whole catalogue (a scratchpad script lists, for each
new tag, the other pictures with that word as name or tag). Two cases:

- the word is another picture's *name* (dog: puppy, bed: bedroom, as in the
  brief's own examples): kept when it is the more general, more specific or
  related word, because a name always ranks first (the library search
  shows both, and a word-to-picture match ranks a name above a tag);
- the word is only a *tag* of another, closer picture: dropped, because two
  tag matches tie and the importer then takes the picture with fewer name
  words, then the lower ID, which can be the wrong one. Words dropped this
  way include gift (Present), letter (Envelope), postbox (Post box),
  chopping board (Cutting board), itchy (Itch), scales (Bathroom scales),
  underground (Metro), seaside (Beach), shellfish (Seafood), pollen
  (Allergy), fawn (Beige), playful (Silly), North America (the continent
  map), palm (Palm tree), shrug (Shrugging), kiss (Kissing), pulse (Beans,
  Lentils), rainy day (Rainy), boxers (Boxing), aeroplane (Airplane), take
  away (Takeaway), close (Near), agree (Agreeing), advert (Billboard
  advert), fairy tale, spooky, office desk; and the category-wide "farm
  animal" on three more farm animals.

### What changed

- Point 1, the owner's tags: Waving (hi, wave hand), Wrong (not), Eye (see,
  look, sight), Tourist (travel), Dry (dried), Angry (angry face), I am
  (myself, me).
- Point 2: "friend" removed from Man and Woman, in the catalogue and in
  `TAG_OVERRIDES` of `tools/generate_exercise_image_metadata.py` (a stale
  tool: it reads the 111-entry manifest that no longer exists and must not
  be run); the picture Friends carries it.
- Point 3: `assets/exercise_images/tennis_racket.webp` redrawn: one blue
  racket standing on its own, strings, open throat, white grip, no ball and
  no court, so it reads as the object next to Tennis (a red racket with a
  ball). ID, name, category, tags and path unchanged. No media hash list or
  test pinned the old file (`tools/media_asset_hashes.json` holds audio
  only).
- Point 4, ten new pictures (records appended to `metadata_v2.json`),
  drawn for QQL in the library's flat style, rendered from SVG with
  headless Chrome at 4x and fitted to a 220-pixel longest side
  (`D:\QQL_plus\nuove_immagini\serie7_265\draw.py`, sources in `svg/`,
  outside the repository, like the earlier series). Each 256 × 256 WebP,
  lossless, 10–26 KB, transparent with a 15–17-pixel transparent margin;
  none needs the grey edge (light edge 0–13%, the tool starts at 25%).
  Headless Chrome paints about 100 pixels less than its window's height,
  so `draw.py` renders into a taller window and crops the square (the
  Build 264 redraws Vest and Mango, made with the shorter window, lost the
  bottom of their shadows; flagged separately, not changed here).
  - `food_drinks_artichoke` Artichoke: vegetable, thistle, globe artichoke,
    artichoke heart, green vegetable, italian food.
  - `food_drinks_fig` Fig (a whole fig and a cut half): fruit, figs, fig
    tree, fresh fig, dried fig, sweet fruit.
  - `food_drinks_macaroni` Macaroni (a heap of elbows): pasta, elbow pasta,
    short pasta, italian food, dry pasta.
  - `food_drinks_provolone` Provolone (hanging, tied with string, and a
    slice): cheese, italian cheese, dairy, cheese wheel, aged cheese, deli.
  - `food_drinks_orange_soda` Orange soda (a can and a fizzy glass):
    orangeade, soft drink, fizzy drink, orange drink, soda, can of soda.
  - `nature_asteroid` Asteroid (a cratered rock on a starry circle, like
    Comet and Galaxy): space rock, meteor, meteorite, comet, outer space.
    ID by the catalogue's convention (`<category>_<name>`): `time_space` is
    no category (it maps to Other) and the space pictures are in nature.
  - `nature_dry_soil` Dry soil (a block of soil, cracked pale top, cracks
    running down; no sun, so it differs from Drought): dry ground, drought,
    cracked earth, dried, arid, desert ground.
  - `jobs_professions_tennis_player_man` Tennis Player (man) and
    `jobs_professions_tennis_player_woman` Tennis Player (woman), a pair
    framed like the other jobs (head and shoulders, teal polo, sweatband,
    the racket and a ball in the lower-right corner): tennis player,
    tennis, athlete, man/woman, male/female, sport, job. Labels in Title
    Case like the other two-word jobs. Through the tag "sport" they also
    show in the category Sports (Build 264 Revision 10's rule); no other
    new tag names a category.
  - `relationships_friends` Friends (three friends, arms over shoulders):
    friend, friendship, group of friends, best friends, mates, together.
- Point 5: `tools/validate_images.py` 2.8.0 prints a tag report after the
  issues: the records outside the character categories with fewer than
  five tags, per category (not refused). After this revision: 1,600.
- Point 6, group 1 complete: 546 records, none below five tags now. Every
  added tag, record by record: `docs/265_REVISION5_TAGS.md`.

### Records completed, by category (546)

- **actions** (102): Walk; Run; Saltare; Sit; Stand; Write; Brush teeth; Sleep; Eat; Drink; Cook; Read; Watch TV; Wash the Dishes; Sweep; Iron Clothes; Do the Laundry; Wash Hands; Comb Hair; Clean; Bake; Boil; Fry; Grill; Roast; Chop; Slice; Peel; Grate; Stir; Mix; Pour; Season; Taste; Serve; Order; Pay; Shaving; Showering; Vacuuming; Cutting; Clapping; Swinging; Sliding; Playing on a Seesaw; Crawling; Throwing; Climbing Stairs; Give; Take; Bring; Look for; Find; Lose; Want; Need; Make; Begin; Finish; Learn; Teach; Speak; Know; Live; Push; Pull; Lie down; Wake up; Get dressed; Carry; Catch; Send; Remember; Forget; Build; Break; Fix; Fill; Hide; Meet; Arrive; Have a bath; Hit; Enter; Visit; Knock; Chew; Pick fruit; Dream; Snore; Fold; Switch on (turn on); Switch off (turn off); Juggle; Kneel; Bend; Chase; Splash; Float; Melt; Slip; Scratch.
- **animals** (139): Cat; Dog; Rabbit; Bird; Fish; Horse; Cow; Pig; Sheep; Duck; Butterfly; Ladybug; Snail; Donkey; Goat; Mouse; Hedgehog; Squirrel; Bat; Fox; Polar Bear; Panda; Deer; Moose; Giraffe; Zebra; Elephant; Rhinoceros; Hippopotamus; Lion; Tiger; Kangaroo; Koala; Camel; Sloth; Hen; Rooster; Swan; Owl; Parrot; Toucan; Flamingo; Peacock; Penguin; Ostrich; Woodpecker; Snake; Crocodile; Tortoise; Sea Turtle; Chameleon; Frog; Earthworm; Dragonfly; Grasshopper; Spider; Scorpion; Shark; Dolphin; Whale; Walrus; Octopus; Jellyfish; Starfish; Seahorse; Crab; Lobster; Rook; Puppy; Kitten; Black cat; Ginger cat; Labrador; German shepherd; Poodle; Dachshund; Beagle; Bulldog; Chihuahua; Golden retriever; Border collie; Dalmatian; Husky; Bee; Fly (insect); Wolf; Turkey; Lamb; Hamster; Guinea pig; Rat; Goldfish; Pony; Bull; Chick; Goose; Eagle; Pigeon; Seagull; Wasp; Beetle; Caterpillar; Dinosaur; Leopard; Gorilla; Brown bear; Seal; Cage; Calf; Duckling; Sparrow; Robin; Slug; Toad; Cheetah; Chimpanzee; Tail; Beak; Kennel; Mole; Buffalo; Otter; Beaver; Badger; Raccoon; Llama; Hummingbird; Cockroach; Moth; Reindeer; Piglet; Tadpole; Beehive; Stable; Lead (dog lead); Guide dog; Ant; Monkey; Mosquito.
- **appearance** (20): Comb; Hairbrush; Razor; Long-haired; Short-haired; Curly-haired; Straight-haired; Bearded; Moustache; Freckled; Slim; Muscular; Handsome; Beautiful; Wrinkles; Ponytail; Hairy; Fashionable; Nail clippers; Tweezers.
- **architecture** (16): Skyscraper; Cottage; Mosque; Tower; Arch; Dome; Column; Staircase; Balcony; Roof; Chimney; Fence; Gate; Drawbridge; Moat; Dungeon.
- **art_cinema** (17): Portrait; Landscape Painting; Sculpture; Abstract Art; Mosaic; Palette; Easel; Clapperboard; Film Reel; Popcorn; Science Fiction; Fantasy; Western; Horror; Black and White; Cartoon; Graffiti.
- **body_parts** (43): Ear; Eye; Nose; Mouth; Hand; Foot; Tongue; Tooth; Knee; Elbow; Body; Chest; Back; Stomach; Shoulder; Hip; Neck; Skin; Bone; Skeleton; Nail; Heart (organ); Brain; Lungs; Face; Arm; Leg; Head; Lips; Chin; Cheek; Forehead; Eyebrow; Eyelashes; Wrist; Bottom; Ankle; Heel; Waist; Fist; Thigh; Belly button; Thumb.
- **business_work** (13): Factory; Office; Business meeting; Shipping container; Construction site; Counting money; Cash register; Job interview; Briefcase; Photocopier; CV (résumé); Business card; Coffee break.
- **celebrations** (19): Birthday Cake; Candle; Present; Balloon; Christmas Tree; New Year's Eve; Fireworks; Greeting card (birthday card); Santa Claus; Blow out candles; Decorations; Festival; Wedding cake; Party hat; Wreath; Christmas stocking; Christmas lights; Easter bunny; Wrapping paper.
- **city_places** (54): Shop; Hospital; School; Traffic Light; Restaurant; Café; Bar; Pizzeria; Trattoria; Airport; Railway Station; Harbour; Castle; Apartment Building; Playground; Petrol Station; Lighthouse; Bridge; Windmill; Fountain; Street; Pavement; Crossroads; Roundabout; Pedestrian crossing; Square; Park; Car park; Bus stop; Cycle lane; Streetlight; Bench; Village; Lift (elevator); Stadium; Zoo; Aquarium; Shopping centre (mall); Bus station; Motorway; City centre; Emergency exit; Escalator; Sports centre; Monument; Nightclub; Concert hall; Ruins; Old town; Parking meter; Petrol pump; Phone box; Post box; Tunnel.
- **clothing_accessories** (64): T-shirt; Pants; Dress; Jacket; Shoes; Hat; Glasses; Backpack; Umbrella; Scarf; Gloves; Shorts; Socks; Watch; Ring; Necklace; Wallet; Tie; Sunglasses; Coat; Boots; Handbag; Cap; Belt; Helmet; Slippers; Sweater; Shirt; Skirt; Blouse; Suit; Flip-flops; High heels; Woolly hat; Swimming trunks; Bikini; Cardigan; Leggings; Tights; Nightdress; Dressing gown (bathrobe); Bra; Pocket; Tracksuit; Sleeve; Shoelace; Headscarf; Nail polish; Lipstick; Make-up; Perfume; Bracelet; Earrings; Apron; Hoodie; Jeans; Pyjamas; Raincoat; Sandals; Swimsuit; Trainers; Underwear; Uniform; Vest.
- **colors** (17): Red; Orange; Yellow; Green; Blue; Purple; Pink; Brown; Black; Gray; White; Gold; Silver; Light; Dark; Colorful; Light blue.
- **communication** (20): Asking; Answering; Calling out; Looking at someone; Listening; Explaining; Inviting; Refusing; Accepting; Helping; Comforting; Promising; Forgiving; Shouting; Poster; Email; Video call; Emoji; Social media; Sign language.
- **concepts** (22): Love; Calm; Confusion; Energy; Question; Correct; Wrong; Same; Different; More; Less; Together; Alone; Balance; Broken; Fragile; Open; Closed; Clean; Dirty; Centre; List.

### Not changed

The picture `actions_jump` is named "Saltare", an Italian word in the
English catalogue; names are outside this brief, so it stays (its tags
jump, jumping, leap now have hop and jump for joy). Pictures of other
categories, Course files, scoring, progression and learner data are
unchanged.

## Revision 4 (2.0.65+265004, 6 October 2026): distractor and Match limits become recommendations; Word Lookup fixes

**Why.** Another session, working on Courses imported from other tools
(where one word can be paired with two meanings, and an exercise often has
more than two distractors), turned four Audit errors into Info for every Course.
The owner made it Revision 4 and decided on 6 October: the number of
distractors has a didactic reason but is no technical problem, so it is the
author's choice; a repeated Match value may be deliberate and the notices
must say so; Spell the word with extra blocks is Info too; the Help and the
tooltips recommend few distractors.

**What changed.**

- Audit (`audit_code_registry.dart`, `course_audit_service.dart`): Info
  instead of Error for `WORD_BLOCK_DISTRACTOR_COUNT`,
  `WORD_BLOCK_LANGUAGE_MISMATCH`, `MATCH_LEFT_DUPLICATE`,
  `MATCH_RIGHT_DUPLICATE`, `AUDIO_MATCH_ANSWER_DUPLICATE`,
  `AUDIO_MATCH_SOUND_DUPLICATE`, `AUDIO_MATCH_TEXT_DUPLICATE` (registry: 66
  Errors, 14 Info). The language of a block is recognized only from a
  small list of common words per language (`_languageHint`), so that rule
  catches obvious cases only.
- Spell the word with extra blocks: one `WORD_BLOCK_DISTRACTOR_COUNT` Info
  ("only the blocks needed for the word are recommended"), whatever their
  number. Before: a `PRESET_CANONICAL_MISMATCH` Warning with one or two
  extra blocks, an Error from three. The other session's draft had left
  the Warning for one or two and only Info from three; checking Spell the
  word first fixes it.
- Notices: a repeated value "may be deliberate (one word, two meanings):
  any matching that reads the same is accepted"; distractor counts "Few
  distractors work best: 0, 1 or 2 are recommended; more are allowed when
  deliberate".
- Runtime: `RoundScreen._matchingReadsAsExpected`, shared by Match and
  Listen and match (the latter compared IDs before). The learner's pairs
  are counted as left-right readings and compared with the expected ones;
  each side as the learner sees it (a row by text and picture, a Listen and
  match sound by its text, an answer by its text, an item with neither by
  its ID). Two identical rows or sounds are interchangeable; giving both
  the same answer is wrong; a Match without repeated values grades as
  before.
- Help: the field Help (`exercise_field_help.dart` and the EN/IT/ES
  `exerciseHelp.field.*` bodies), the preset descriptions and the Editor
  Help answer `distractors` (EN/IT/ES) recommend few distractors (0, 1 or
  2, fewer in a Lesson's first Rounds; more make the exercise slower to
  read; QQL allows them); `docs/COURSE_EDITOR.md`.
- AGENTS.md: the content rule is a recommendation; the grading exception
  to "IDs identify answers" for identical Match items.
- Word Lookup fixes from the review of Build 265 (owner: "fix them now"):
  - `_LookupTextState._card` wraps the card in a
    `NotificationListener<ScrollNotification>` that stops its notifications:
    the scope closes the card on any `ScrollUpdateNotification`, and the
    card's own `SingleChildScrollView` sent one, so a card longer than 360
    pixels closed when scrolled (proven by a widget test before the fix);
  - `WordLookupAnalysis._bare`: the key of a word ending with an apostrophe
    that no word follows, without it. Occurrences and rule 3 try the key as
    written first; a match through the bare key is `loose` and loses to an
    exact match of the same length (`di'` = say before `di` = of), and its
    closing quote mark is not highlighted or underlined. The tokenizer is
    unchanged: a leading apostrophe is not always a quote (Neapolitan
    *'o sole*, English *'em*), so quotes are not tracked there;
  - the pieces of an apostrophe word use rule 3 (`_insideExpressions`,
    shared with single words): `acqua` in `d'acqua` shows `l'acqua`.

**Unchanged.** Scoring rules, progression, the Course format, learner data.
Word Lookup before answering (owner decision: a Course is a lesson, not an
interrogation; an author can turn it off in Lesson Options).

## Revision 3 (2.0.65+265003, 6 October 2026): the Lab's vocabulary; articles in Word Lookup

**Why.** The owner approved the proposed Lab vocabulary on 6 October,
remarking that English uses mass nouns generically without "the" (bread,
milk, water), so `il pane = the bread` misleads; and, on the "word inside
an expression" rule, that an expression should show only when the text
uses it, choosing a middle way: articles may stand beside the word.

**What changed.**

- `tools/generate_exercise_laboratory_254.py`: `VOCABULARY`, 98 entries in
  eight Lessons (15, 15, 14, 12, 10, 12, 10, 10), appended to each
  Lesson's GuideBook after the overview (`<prefix>_vocab_NN`). The bundled
  Course, the future fixture and the v11 fixture (`course_v11()` with the
  generator's checksum recipe) are regenerated. The Lab's Review shows
  vocabulary cards and its Round Wizard can plan from every Lesson.
- Mass nouns without "the": the Lab's `il pane = bread`,
  `il latte = milk`, `l'acqua = water`, `il riso = rice`,
  `il caffè = coffee` (Lesson 1) and `= espresso` (Lesson 8);
  `tools/generate_english_from_italian_260.py`: `bread = il pane`,
  `water = l'acqua`, `milk = il latte`, `coffee = il caffè`,
  `tea = il tè`. Countable nouns keep "the".
- `lib/services/word_lookup/word_lookup_articles.dart`:
  `WordLookupArticles.forLanguage(tag)`, the articles of English, Italian,
  Spanish, French, German, Portuguese and Dutch.
  `WordLookupIndex.build(articles:)`; rule 3 shows an expression the text
  does not contain only when its other words are articles or common words
  (more than three distinct entries), and a tapped article or common word
  finds nothing. `WordLookupSources.indexFor` passes the Course learning
  language's articles.
- Help EN/IT/ES (Editor Help's Word Lookup answer) and
  `docs/265_WORD_LOOKUP_PLAN.md` describe the rule.
- A light dotted underline (owner request of 6 October): `LookupText`
  draws `_WordMarksPainter` (key `word-lookup-marks`, a `CustomPaint`
  foreground over the plain `Text`, so its `data` and keys are unchanged)
  under `tappableRanges` (now computed once per analysis), in the theme's
  primary colour at 60%, 2-pixel dashes. The notice reads "Tap a word with
  a dotted underline to see a translation from this Course's GuideBook.
  Only some exercise types have them. It is a hint, one possible
  translation: it does not always match the answer to the exercise." in
  the seven languages; App Info and Editor Help say so.
- `WordLookupCard(currentLessonIndex:)`: the Lesson line
  (`word-lookup-lesson-<i>`) only for an entry from another Lesson (owner
  decision of 6 October). A card with several entries says "Some possible
  translations from this Course's GuideBook." (`WordLookupScope.notePlural`,
  learner panel `wordLookup.notes`, seven languages).
- Gapped texts: `RoundScreen`'s `_missingWordDisplay` text (Complete the
  text, Missing letters, Type the missing word) and the text runs around
  inline gaps (Arrange, Select, Assign) are `LookupText` (gaps are never
  looked up).
- The Lab: narrower hints on `complete_text` and
  `complete_text_alternatives` (the presentation baseline's four hint
  lines follow), and the Page line "Careful: at the bar, *un caffè* is
  never a large mug of coffee.".

## Revision 2 (2.0.65+265002, 6 October 2026): keyboard, screen readers, the Lab's name

**What changed.**

- `LookupText` (when its text has entries) is a `Focus` stop: Tab reaches
  it; Enter, numpad Enter or Space open the card with every entry the text
  finds (`allEntries`, in text order, identical ones once) beside the whole
  text, with no word highlighted; pressed again, or Escape, they close it.
  A 2-pixel outline marks the focused text only while the keyboard is in
  use (`FocusHighlightMode.traditional`). Texts with nothing to look up
  take no focus, so Tab order elsewhere is unchanged.
- Screen readers: the text and its action "Vocabulary in this text"
  (`wordLookup.action`, seven languages) are one node (`MergeSemantics`,
  `CustomSemanticsAction`); the action opens the same card.
- QQL Demo: Exercise Laboratory is renamed **QQL Demo: Italian Exercise
  Lab**: `tools/generate_exercise_laboratory_254.py` (title and the
  printed-character specimens' credit title), the bundled JSON and the
  future fixture regenerated, the v11 fixture rewritten from `course_v11()`
  with the generator's checksum recipe (the writer reproduced the old
  fixture byte for byte before the change), the credits page, Help EN/IT/ES
  (Fill with an example), two tests and code comments. Course ID, file
  names and code names stay, so learners keep their progress.
- Not in this revision: the Lab's GuideBook vocabulary (proposed to the
  owner on 6 October; it follows as Revision 3 once approved).

## Revision 1 (2.0.65+265001, 6 October 2026): Word Lookup on the learner's screen

**What changed.**

- `lib/widgets/word_lookup_view.dart`:
  - `WordLookupScope`: the Round screen puts it around its page when the
    Course's Use GuideBook and Word Lookup are on and the Round is not a
    Test Round. It holds the Course's index (built once per Course object;
    the Preview reads Draft GuideBooks too), the Round's Lesson, the
    Lessons' names as the learner's path shows them, and the card's line in
    the learner panel's language. One card is open at a time; Escape closes
    it, and so does any scrolling inside the page.
  - `LookupText`: the text a learner can look words up in. Without a
    scope, on text stated in the learner's own language, or when no word of
    it has an entry, it is exactly the plain `Text` it replaces (same key,
    same `data`), so the Duel and every earlier test see no difference.
    Otherwise a tap is mapped to the character under it through the
    paragraph's own layout; a word with entries is highlighted and its card
    opens beside it (below, or above near the bottom edge, at most 320
    pixels wide). On a computer the pointer becomes a hand over words that
    have entries only. A label before or after the text ("Correct answer:
    ", a speaker's name) is never looked up.
  - `WordLookupCard`: each entry's learning-language side in bold, its
    meaning, its Lesson, then "One possible translation from this Course's
    GuideBook.".
  - `WordLookupNotice`: the one-time notice, once per learner and Course
    (`word_lookup_<Course ID>` in the learner's one-time notices, so Show
    one-time notices again brings it back); not in the Preview (there is no
    learner) nor in a Timed Round (its clock would run behind the dialog).
- `RoundScreen`: the page is built by `_buildPage` and wrapped in the scope.
  Looked up: the question, the text to translate (only when it is not in
  the learner's language), a dialogue line by its speaker's language (the
  current one once its text shows, and the ones kept in a scrolling
  Story's log), a cover's title line, the correct-answer line, the correct
  translations and the ranked translations. Not looked up: the Instruction
  or context, the Before you start note, options, blocks, links, gapped
  sentences, a scrolling Story's past exercise cards.
- `ExercisePromptPanels`: the context, the dialogue turns (not the speaker
  names) and the passage or situation, each by its own language; the Duel,
  which shares these panels, provides no scope.
- `PageCardView`: text blocks and list items through `LookupText.runs`, so
  bold and italic marks stay; headings too; links and pictures unchanged.
- `ExerciseFeatures.textLanguageOf(role)`: the language a role's text
  states.
- `Course.wordLookup` (default on, stored only when off, strict boolean),
  copied by Fork, Copy as New Course and the transfer copy; a Merge keeps
  the left Course's value. Lesson Options' **Word Lookup** switch
  (`course-word-lookup`) sits under Use GuideBook and is hidden while it is
  off. `tools/validate_courses.py` checks the field is a boolean.
- Texts: `wordLookup.note` and `wordLookup.notice` in the seven learner
  panel catalogs; Help EN/IT/ES (App Info, Editor Help, GuideBook and
  Lesson Options answers); `docs/239_RESET_STORAGE_INVENTORY.md` names the
  notice key.

**Unchanged.** Scoring, progression, Review, the Course format (an earlier
build ignores `wordLookup`) and learner data.

## Revision 0 (2.0.65+265000, 6 October 2026): one vocabulary reader, the lookup rules

**Why.** Word Lookup needs to know which side of a GuideBook entry is the
learning language. The GuideBook editor says "One target/source pair per
line. Example: casa = house" and the Round Wizard reads the left side as
the target, but QQL Demo: English from Italian wrote its entries Italian
first (`ciao = hello, hi`), so the Wizard took its Italian words for
English. The owner chose the convention target = source and the correction
of the demo. The line was also read by two copies of the same parser.

**What changed.**

- `lib/services/guidebook_vocabulary.dart`: `GuidebookVocabulary.parse`
  returns a `GuidebookVocabularyPair` (target, source). It is the old
  algorithm, unchanged: separators ` = `, ` → `, ` - `, `:` tried in that
  order, text needed on both sides. `VocabularyReviewService` and
  `GuidebookRoundGenerator` use it; their private copies are deleted. Each
  caller still decides which entries it reads (Review: Published only; the
  Wizard: the GuideBook it is given).
- `tools/generate_english_from_italian_260.py`: the 36 entries are written
  English first (`hello, hi = ciao`, `the water = l'acqua`, …); the bundled
  Course is regenerated. Its GuideBook and Review vocabulary show English
  first; the Round Wizard plans "Foundations: hello, hi"; that demo's Review
  vocabulary memory starts again, because each entry's fingerprint
  (prompt, answer) changed. Nothing else of a learner's data changes.
- `lib/services/word_lookup/` (pure Dart, not yet used by any screen):
  - `word_lookup_text.dart`, `WordLookupText.tokenize`: the words of a text
    with their offsets. Small letters, punctuation dropped, accents kept
    (NFC, so a composed and a decomposed è are one), `’` read as `'`. An
    apostrophe after a letter stays with its word and ends it (`l'acqua` is
    `l'` + `acqua`); a hyphen between letters joins (`self-service` is one
    word); a word holding `_` is a gap. Han, Hiragana, Katakana, Thai, Lao,
    Khmer, Myanmar and Tibetan characters (Unicode `Script_Extensions`, so
    the Katakana long-vowel mark counts) are one word each, by grapheme
    cluster (a Thai letter keeps its vowel and tone marks).
  - `word_lookup.dart`, `WordLookupIndex`: built from a flat list of
    entries in Course order (so Build 266's GuideBook modules change only
    the source adapter). Only the target side is searched. For a tapped
    word: the longest entry found in the text that covers it, counted in
    words (characters in the scripts above); otherwise an entry of two or
    more words that contains it, unless the word is in more than three
    distinct entries (il, la, the); at the length reached, the current
    Lesson's entries if it has any, else every Lesson's in Course order,
    identical entries once. An apostrophe word is looked up whole first;
    when no entry covers it whole, each piece is looked up with the first
    rule only and the results are shown together (`l'` and `acqua`), so
    *Tom's* never borrows *it's ten o'clock*. Gaps are never looked up and
    an expression never spans one. `tappableRanges` (where a tap finds
    something), `allEntries` (every entry found in a text) and a small
    cache per text and Lesson.
  - `word_lookup_sources.dart`, `WordLookupSources.forCourse`: the
    vocabulary of the whole Course, locked Lessons included, from Published
    Lessons and Published GuideBook entries; with `includeDrafts` (the
    Course Editor Preview) Drafts too; nothing while Use GuideBook is off.
- Version `2.0.65+265000`, Beta expiry `2026-11-05 23:59:59` local time.

**Unchanged.** Every screen, scoring, progression, the Course format and
learner data (except the English from Italian Review vocabulary memory
above).

**Files.** The implementation plan put the parser under
`lib/services/word_lookup/` and the index and the rules in two files; the
parser sits in `lib/services/` because Review and the Round Wizard use it
too, and the index and the rules share one file (`word_lookup.dart`)
because the rules read the index's private tables.
