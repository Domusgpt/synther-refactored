Below is a step‐by‐step list of exactly what a coding agent (e.g., your Claude-Code agent) should do to restore the “Pro” features in **CrystalGrimoireBeta2**, using **crystal-grimoire-alpha-v1** as a reference.  There are no Termux or PC command‐line details here—just precise file‐and‐code instructions.

---

## A. Restore the Moon Ritual Planner Screen

1. **Locate the Alpha v1 implementation**

   * In `crystal-grimoire-alpha-v1/lib/screens/`, find the file named something like `moon_ritual_planner.dart` (or `moon_guide.dart`).
   * Open that file and note:

     * The widget class name (e.g. `MoonRitualPlannerScreen`).
     * Any helper classes it imports (e.g. `moon_phase_widget.dart`, `calendar_helper.dart`).
     * Assets it depends on (SVGs, JSON, images).

2. **Copy the Alpha screen into Beta2**

   * In your Beta2 project (`CrystalGrimoireBeta2`), create a new file at:

     ```
     lib/screens/moon_ritual_planner.dart
     ```
   * Paste the entire contents of Alpha’s `moon_ritual_planner.dart` into this new file.
   * Update the top‐of‐file imports to match Beta2 folder structure. For example:

     ```dart
     // In Alpha it might have been:
     // import 'package:crystal_grimoire_alpha/widgets/moon_phase_widget.dart';
     // In Beta2, mirror or relocate those widgets under the same relative path.

     import 'package:crystal_grimoire_beta2/widgets/moon_phase_widget.dart';
     import 'package:crystal_grimoire_beta2/helpers/calendar_helper.dart';
     // …and any other dependencies…
     ```
   * If helper files (e.g. `moon_phase_widget.dart`) do not yet exist in Beta2, bring them over from Alpha (copy into `lib/widgets/` or `lib/helpers/`, preserving subfolders).

3. **Hook the screen into Beta2’s navigation**

   * Open Beta2’s main navigation file—commonly `lib/main.dart` or `lib/routes.dart` (depending on how you’ve organized routing).
   * Locate the list of named routes or the bottom‐navigation bar that defines each tab.
   * Add a new route pointing to your freshly copied `MoonRitualPlannerScreen`. For example:

     ```dart
     // Inside your RouteGenerator or MaterialApp routes map:
     '/moon_ritual': (context) => MoonRitualPlannerScreen(),
     ```
   * If Beta2 uses a BottomNavigationBar or Drawer, add a “Moon Ritual” entry to the appropriate menu. For instance, if there’s a `List<BottomNavigationItem>` in `home_screen.dart`, insert:

     ```dart
     BottomNavigationBarItem(
       icon: Icon(Icons.nights_stay),
       label: 'Moon Ritual',
     ),
     ```

     and map its index to the new route.

4. **Protect Moon Ritual behind “Pro” access**

   * Identify your app’s “access control” logic. In Beta2, look for a method like `StorageService.canUseProFeature(String featureKey)` or `SubscriptionService.isProUser()`.
   * On the UI elements that link to Moon Ritual (e.g. the BottomNavigationBarItem’s onTap or the DrawerItem’s onTap), wrap the navigation in a guard:

     ```dart
     if (await SubscriptionService.instance.isProUser()) {
       Navigator.pushNamed(context, '/moon_ritual');
     } else {
       // Show a “Pro only” dialog or redirect to PurchaseScreen
       showDialog(
         context: context,
         builder: (_) => NeedProDialog(featureName: 'Moon Ritual')
       );
     }
     ```
   * If Beta2 already centralizes “Pro” gating (for example, a `ProGate` widget), wrap the “Moon Ritual” menu tile or button in that.

5. **Verify asset references and null‐safety**

   * Scan through `moon_ritual_planner.dart` for any calls to `rootBundle.loadString('assets/...')` or `Image.asset('images/...')`.
   * Copy any missing assets (JSON calendars, SVGs, images) from Alpha’s `assets/` folder into Beta2’s `assets/` folder.
   * Update `pubspec.yaml` in Beta2 to include new asset paths:

     ```yaml
     flutter:
       assets:
         - assets/moon_calendar.json
         - assets/images/moon_phases/
         - …
     ```
   * Run a quick static analysis or `flutter doctor` (if using Flutter) to ensure no missing assets.

---

## B. Restore the Crystal Energy Healing Screen

1. **Identify Alpha’s Healing screen file**

   * In `crystal-grimoire-alpha-v1/lib/screens/`, locate `crystal_energy_healing.dart` (or similarly named).
   * Note its widget class—e.g. `CrystalHealingScreen`—and any custom widgets (`healing_flow.dart`, `chakra_list.dart`, etc.).

2. **Copy over to Beta2**

   * Create `lib/screens/crystal_healing_screen.dart` in Beta2.
   * Copy/paste Alpha’s entire file into it.
   * Adjust imports at the top so they point to Beta2’s package and folder structure:

     ```dart
     import 'package:crystal_grimoire_beta2/widgets/chakra_list.dart';
     import 'package:crystal_grimoire_beta2/helpers/healing_flow.dart';
     // …etc.
     ```
   * If any of the helper widgets (`chakra_list.dart`, etc.) are missing in Beta2, copy them from Alpha into `lib/widgets/` or `lib/helpers/`.

3. **Add routing/navigation entry**

   * In Beta2’s navigation file (`lib/routes.dart` or similar), add:

     ```dart
     '/crystal_healing': (context) => CrystalHealingScreen(),
     ```
   * Add a corresponding icon/label to your BottomNavigationBar or Drawer (e.g. using a hand‐holding‐gem icon).

4. **Gate access behind Pro subscription**

   * Use the same pattern as Moon Ritual:

     ```dart
     if (await SubscriptionService.instance.isProUser()) {
       Navigator.pushNamed(context, '/crystal_healing');
     } else {
       showDialog(
         context: context,
         builder: (_) => NeedProDialog(featureName: 'Crystal Healing')
       );
     }
     ```
   * If Beta2 already has a centralized gating widget (e.g. `ProGate(child: CrystalHealingScreen(), featureKey: 'healing')`), wrap it accordingly.

5. **Verify UI consistency**

   * In Alpha, healing steps might have custom animations or color palettes. Copy any missing color definitions or theme adjustments from `alpha_v1/lib/theme/` into Beta2’s `lib/theme/`.
   * Confirm that fonts, icons, and images (e.g. chakra icons) are present in Beta2’s `assets/images/healing/`.

---

## C. Fix & Re‐link the Sound Bath Screen

1. **Locate Beta2’s existing Sound Bath placeholder**

   * Beta2 already has a `sound_bath_screen.dart` (found under `lib/screens/`). It currently “logs an error” if files are missing.
   * Open `lib/screens/sound_bath_screen.dart`. You’ll see references to missing audio files and a timer widget—but no actual playback.

2. **Bring over Alpha’s audio assets**

   * From `crystal-grimoire-alpha-v1/assets/sound_bath/` (or similar), copy all `.mp3`/.wav files into Beta2’s `assets/audio/sound_bath/`.
   * In Beta2’s `pubspec.yaml`, under `flutter.assets`, add:

     ```yaml
     assets:
       - assets/audio/sound_bath/crystal_sound_bath_1.mp3
       - assets/audio/sound_bath/crystal_sound_bath_2.mp3
       # …and so on for each track
     ```
   * Run your IDE’s “flutter pub get” (or simply save the file) to ensure the assets are registered.

3. **Merge Alpha’s playback logic**

   * In Alpha, open `alpha_v1/lib/screens/sound_bath_screen.dart`. Copy any AudioPlayer setup, `initState()` logic, and widget tree (buttons, slider, timer).
   * In Beta2’s `sound_bath_screen.dart`, replace the stubs/error‐logging code with the copied AudioPlayer code. For example:

     ```dart
     // ALPHA LOGIC (simplified)
     class SoundBathScreen extends StatefulWidget { … }
     class _SoundBathScreenState extends State<SoundBathScreen> {
       late AudioPlayer _audioPlayer;
       bool _isPlaying = false;
       Duration _duration = Duration.zero;
       Duration _position = Duration.zero;

       @override
       void initState() {
         super.initState();
         _audioPlayer = AudioPlayer();
         _audioPlayer.onDurationChanged.listen((d) {
           setState(() { _duration = d; });
         });
         _audioPlayer.onAudioPositionChanged.listen((p) {
           setState(() { _position = p; });
         });
       }

       void _startPlayback() async {
         _isPlaying = true;
         await _audioPlayer.play('assets/audio/sound_bath/crystal_sound_bath_1.mp3');
         // handle loop or next track if needed
       }

       void _pausePlayback() {
         _isPlaying = false;
         _audioPlayer.pause();
       }

       @override
       Widget build(BuildContext context) {
         return Scaffold(
           appBar: AppBar(title: Text('Sound Bath')),
           body: Column(
             children: [
               Slider(
                 value: _position.inSeconds.toDouble(),
                 max: _duration.inSeconds.toDouble(),
                 onChanged: (val) {
                   final position = Duration(seconds: val.toInt());
                   _audioPlayer.seek(position);
                 },
               ),
               IconButton(
                 icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                 onPressed: () {
                   _isPlaying ? _pausePlayback() : _startPlayback();
                 },
               ),
               Text('${_position.toString().split('.').first} / ${_duration.toString().split('.').first}'),
               // …any other controls (volume, track list, etc.)
             ],
           ),
         );
       }
     }
     ```
   * Adjust any path strings (`'assets/audio/…'`) to match exactly the Beta2 asset paths.
   * Remove any debug `print` or log statements that Alpha used; keep only the relevant playback logic.

4. **Re‐link Sound Bath into navigation**

   * In Beta2’s `home_screen.dart` (or wherever the Metaphysical tab is), find the placeholder for “Sound Bath”. Replace it with a direct call to `SoundBathScreen()` wrapped in your Pro‐gate logic:

     ```dart
     ProGate(
       featureKey: 'sound_bath',
       child: SoundBathScreen(),
       onDenied: () => showDialog(
         context: context,
         builder: (_) => NeedProDialog(featureName: 'Sound Bath'),
       ),
     )
     ```

5. **Test playback in Beta2**

   * Launch the app on your PC (e.g., via an emulator or debug session).
   * Navigate to “Sound Bath” (as a Pro user). Confirm the audio plays, slider moves, and pause/resume works.

---

## D. Enable “Journal” as a Paid (Pro) Feature, Backed by Collection

1. **Identify Beta2’s Journal screen and its data calls**

   * In `lib/screens/journal_screen.dart`, locate where journal entries are created, edited, and listed.
   * In Beta2, the Journal may currently be free or disabled; find any gating logic:

     ```dart
     // Example stub in Beta2:
     if (!StorageService.canUseJournal()) {
       return Center(child: Text('Upgrade to Premium to use Journal'));
     }
     ```
   * If missing, insert a check at the top of `build()`:

     ```dart
     if (!await SubscriptionService.instance.isProUser()) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Text('Journal is a Pro feature'),
             ElevatedButton(
               onPressed: () => Navigator.pushNamed(context, '/purchase'),
               child: Text('Upgrade Now'),
             ),
           ],
         ),
       );
     }
     ```

2. **Switch Journal’s data store to “Collection” as a database**

   * In Alpha, journal entries may have been stored in a local SQLite or JSON file. In Beta2, “Collection” acts as the persisted store for user data.
   * Locate `lib/services/collection_service.dart` (or `storage_service.dart`). You’ll see methods like `addItem()`, `getItems()`, `updateItem()`, etc., which persist objects.
   * Create a new Collection “type” for Journal. For example:

     ```dart
     // In collection_service.dart:
     static const String journalCollection = 'user_journal_entries';

     Future<void> saveJournalEntry(JournalEntry entry) async {
       final json = entry.toJson();
       await _database.insert(journalCollection, json);
     }

     Future<List<JournalEntry>> loadJournalEntries() async {
       final rows = await _database.query(journalCollection, orderBy: 'date DESC');
       return rows.map((r) => JournalEntry.fromJson(r)).toList();
     }

     Future<void> deleteJournalEntry(String id) async {
       await _database.delete(journalCollection, where: 'id = ?', whereArgs: [id]);
     }
     ```
   * If `collection_service.dart` does not already have methods for these actions, add them.
   * In `lib/models/`, create or update `journal_entry.dart`:

     ```dart
     class JournalEntry {
       final String id;
       final String title;
       final String content;
       final DateTime date;
       // …any other fields…

       JournalEntry({
         required this.id,
         required this.title,
         required this.content,
         required this.date,
       });

       Map<String, dynamic> toJson() => {
         'id': id,
         'title': title,
         'content': content,
         'date': date.toIso8601String(),
       };

       factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
         id: json['id'] as String,
         title: json['title'] as String,
         content: json['content'] as String,
         date: DateTime.parse(json['date'] as String),
       );
     }
     ```
   * In `journal_screen.dart`, replace any local storage calls with calls to `CollectionService.instance.saveJournalEntry(...)` and `loadJournalEntries()`. For example:

     ```dart
     // Before (stubbed):
     // List<Entry> entries = LocalJournalStorage.getAll();
     // After:
     List<JournalEntry> entries = await CollectionService.instance.loadJournalEntries();
     ```

3. **Mark Journal data as “Pro‐only”**

   * Because Journal is now a Pro feature, wrap any “Add Entry” buttons in a ProGate:

     ```dart
     ProGate(
       featureKey: 'journal',
       child: FloatingActionButton(
         onPressed: () { /* open “New Entry” screen */ },
         child: Icon(Icons.add),
       ),
       onDenied: () => showDialog(
         context: context,
         builder: (_) => NeedProDialog(featureName: 'Journal'),
       ),
     )
     ```
   * For listing existing entries, it’s fine to show read‐only to non‐Pro users if you wish, but block creation/edit. If you prefer to fully hide Journal for non‐Pro, wrap the entire `Scaffold` in:

     ```dart
     if (!await SubscriptionService.instance.isProUser()) {
       return Center(child: /* “Upgrade to Pro” UI */);
     }
     ```

4. **Ensure Collection schema supports “stones” and “journal entries”**

   * In `CollectionService`, verify there’s a separate table or JSON bucket for “user\_stones” (i.e., crystals the user has collected). If not, create it:

     ```dart
     static const String stonesCollection = 'user_stones';
     Future<void> addStone(UserStone stone) async { … }
     Future<List<UserStone>> loadStones() async { … }
     ```
   * Confirm that your Journal entries know which stones to reference. For example, if a journal entry can associate a “stone\_id”, add `stoneId` to `JournalEntry`.

---

## E. Re‐enable Pro Features (Moon & Healing & Sound) to Write/Read from Collection

1. **Crystal Healing: read user’s stones from Collection**

   * In `crystal_healing_screen.dart`, find where Alpha displayed recommended crystals. Replace any hard‐coded lists with a dynamic query:

     ```dart
     List<UserStone> myStones = await CollectionService.instance.loadStones();
     // Then filter or sort by chakra or energy type:
     final healingStones = myStones.where((s) => s.energy == 'healing').toList();
     ```
   * If Alpha used a local JSON of crystals, you can merge that with the user’s Collection: show “My Stones” separately from “Available Crystals in Shop.”

2. **Moon Ritual: reference user’s saved stones or journal**

   * In `moon_ritual_planner.dart`, if you want to “suggest crystals” based on current moon phase, query the Collection:

     ```dart
     final phase = MoonHelper.currentPhase();
     final recommended = await CrystalRecommendationService.getForPhase(phase);
     // Or fetch from local dataset that tags crystals by moon phase,
     // then highlight ones the user already owns:
     final myStones = await CollectionService.instance.loadStones();
     final ownedRecommended = recommended.where((r) => myStones.any((s) => s.id == r.id)).toList();
     ```
   * This step ensures the UI “knows” which stones to highlight, so your guidance can say “Use one of your Amethyst or Selenite.”

3. **Metaphysical Guidance: allow LLM prompts to include user’s Collection context**

   * Locate `metaphysical_guidance_service.dart` or wherever LLM calls are built:

     ```dart
     Future<String> getGuidance({required String query}) async {
       final stones = await CollectionService.instance.loadStones();
       final stoneNames = stones.map((s) => s.name).join(', ');
       final prompt = '''
       The user has the following stones: $stoneNames.
       They are asking: $query
       Based on their stones, what would you recommend?
       ''';
       return _sendPromptToLLM(prompt);
     }
     ```
   * Replace the existing “bare prompt” with this enriched prompt.
   * In `guidance_screen.dart`, when user taps “Ask for guidance,” pass along the enriched prompt.

---

## F. Final Integration & Testing Checklist

1. **Navigation & Menu Validation**

   * Confirm every “Pro” feature—Moon Ritual, Crystal Healing, Sound Bath, Journal—is listed in the app’s main menu or tab bar only for Pro users.
   * Confirm tapping those icons as a non-Pro user pops a “NeedProDialog” (with correct feature name).

2. **Database Migrations (if needed)**

   * If Beta2’s database schema has changed since alpha, you may need to add new tables/collections. In `CollectionService`, add logic to create `journal_entries` and `user_stones` tables during initialization:

     ```dart
     Future<void> _initDb() async {
       // existing tables…
       await db.execute('''
         CREATE TABLE IF NOT EXISTS journal_entries (
           id TEXT PRIMARY KEY,
           title TEXT,
           content TEXT,
           date TEXT
         );
       ''');

       await db.execute('''
         CREATE TABLE IF NOT EXISTS user_stones (
           id TEXT PRIMARY KEY,
           name TEXT,
           energy TEXT,
           color TEXT
         );
       ''');
       // …any other migrations…
     }
     ```

3. **Asset & Dependency Validation**

   * Verify that all assets required by Moon Ritual, Healing, Sound Bath, and any helper widgets exist under `beta2/assets/`.
   * Check `pubspec.yaml` to ensure they are declared.
   * Confirm the `pub get` or `flutter pub get` (if using Flutter) runs without errors.

4. **UI/UX Smoke Test**

   * Launch the app (in your PC emulator or physical device if you prefer).
   * Log in as a Pro test user (or set your local `SubscriptionService` to “true” for isProUser()).
   * Navigate in order to:

     1. Moon Ritual → confirm calendar loads, phases display, “recommend stones” shows items from your Collection.
     2. Crystal Healing → confirm chakra list loads, healing steps animate, stones from Collection appear as owned.
     3. Sound Bath → play/pause works, slider moves, audio continues even if you switch tabs.
     4. Journal → create a new entry, see it saved in your Collection (inspect via a debug print of `loadJournalEntries()`).
   * Log out or switch to non-Pro → confirm tapping any of those features immediately shows “Upgrade to Pro” and does not proceed deeper.

5. **Edge Cases & Fallbacks**

   * If the LLM service is unreachable, ensure you have a local “fallback” in `MetaphysicalGuidanceService`—for instance, return a canned message:

     ```dart
     try {
       return await _sendPromptToLLM(enrichedPrompt);
     } catch (e) {
       return 'Apologies—our guidance service is temporarily offline. Try again later or consult your stones directly.';
     }
     ```
   * If the user has zero stones in Collection, show:

     ```dart
     if (stones.isEmpty) {
       return Center(child: Text('Add at least one crystal to your Collection first.'));
     }
     ```
   * In the Journal screen, if the database migration fails, catch errors and display “Unable to load entries. Please try again.”

---

### Summary of What the Coding Agent Should Do

1. **Copy over Alpha’s `moon_ritual_planner.dart` and all dependent widgets/assets into Beta2, adjust imports, add routes, and gate behind Pro.**
2. **Copy over Alpha’s `crystal_energy_healing.dart` and dependent widgets/assets into Beta2, adjust imports, add routes, and gate behind Pro.**
3. **In Beta2’s `sound_bath_screen.dart`, replace the stub with Alpha’s full AudioPlayer logic, copy all `assets/audio/sound_bath/*` files, update `pubspec.yaml`, and gate behind Pro.**
4. **Modify `journal_screen.dart` (or equivalent) so that:**

   * It checks `SubscriptionService.isProUser()` at build time and shows an “Upgrade to Pro” UI if false.
   * It persists journal entries to `CollectionService` instead of any local JSON. Create `JournalEntry` model, add the table in `CollectionService`, and wire up save/load/delete.
5. **Update `CollectionService` (or `storage_service.dart`) to include methods for:**

   * `loadStones()` and `saveStone()` (if not already present).
   * `loadJournalEntries()` and `saveJournalEntry()`.
   * Adding any missing collections/tables in `_initDb()`.
6. **In Metaphysical Guidance code (`metaphysical_guidance_service.dart` or similar), prepend the user’s stones (fetched via `loadStones()`) to the LLM prompt so that suggestions honor the user’s Collection.**
7. **Add Pro gating UI everywhere relevant (Moon, Healing, Sound Bath, Journal), using the existing `SubscriptionService` or `ProGate` widget.**
8. **Verify assets in `pubspec.yaml`, run a full UI/UX test for Pro vs. non‐Pro flows, and implement fallback text if resources/LLM calls fail.**

Once each of these steps is performed, Beta2 will have its original “Pro” features (Moon Ritual, Crystal Healing, Sound Bath, Paid Journal) fully restored, integrated with the Collection database, and gated behind a paid subscription.
