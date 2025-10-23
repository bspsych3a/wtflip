import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'firebase_options.dart'; // <-- added

// <-- for any orientation control if needed


enum Category { psychology, language, geography }
enum Difficulty { easy, medium, hard }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'PressStart2P', // use PressStart2P across the app
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        // ensure all buttons use PressStart2P by default
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 14),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// Top banner with back on left and title where "Card Flip" is cards
class TopBanner extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  const TopBanner({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    // scale factor based on short side
    final scale = (min(width, height) / 600).clamp(0.7, 1.6);
    final bannerHeight = 72.0 * scale;

    return SizedBox(
      height: bannerHeight,
      child: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: bannerHeight, // ensure AppBar uses the computed height
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0 * scale),
            child: Row(
              children: [
                // Back button on left
                if (Navigator.of(context).canPop() || onBack != null)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black, size: 20.0 * scale),
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                  )
                else
                  SizedBox(width: 48.0 * scale),
                // Title center (cards)
                Expanded(
                  child: Center(
                    child: CardTitleRow(
                      letters: 'WTFLIP',
                      // use explicit size derived from bannerHeight so cards fit in the appbar on wide screens
                      overrideSize: bannerHeight * 0.64,
                      overrideFontSize: bannerHeight * 0.36,
                      cardPadding: 6.0 * scale,
                      interactive: true,
                      small: true,
                    ),
                  ),
                ),
                SizedBox(width: 48.0 * scale), // placeholder to balance leading icon
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    // Compute a preferred height based on the current logical window size so the app bar
    // height matches build-time banner height and avoids clipping (works on web/desktop).
    // ignore: deprecated_member_use
    final window = WidgetsBinding.instance.window;
    final logical = window.physicalSize / window.devicePixelRatio;
    final width = logical.width;
    final height = logical.height;
    final scale = (min(width, height) / 600).clamp(0.7, 1.6);
    final bannerHeight = 72.0 * scale;
    return Size.fromHeight(bannerHeight);
  }
}

// Small interactive flip-letter card
class FlipLetterCard extends StatefulWidget {
  final String letter;
  final double size;
  final double fontSize;
  final double padding;
  final bool small;

  const FlipLetterCard({
    super.key,
    required this.letter,
    required this.size,
    required this.fontSize,
    required this.padding,
    this.small = false,
  });

  @override
  State<FlipLetterCard> createState() => _FlipLetterCardState();
}

class _FlipLetterCardState extends State<FlipLetterCard> with SingleTickerProviderStateMixin {
  bool flipped = false;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      flipped = !flipped;
      if (flipped) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final fontSize = widget.fontSize;
    final padding = widget.padding;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final value = _ctrl.value;
          final angle = value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          final isUnder = angle > (pi / 2);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: NotchedCard(
              size: size,
              padding: padding,
              notchFraction: 0.04, // even smaller notch
              fillColor: isUnder ? Colors.black : Colors.white,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(isUnder ? pi : 0),
                child: Text(
                  widget.letter,
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: fontSize,
                    color: isUnder ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Row of letter cards used for banner and home title
class CardTitleRow extends StatelessWidget {
  final String letters;
  final double letterSize;
  final double cardPadding;
  final bool interactive;
  final bool small;
  final double? overrideSize; // NEW: optional explicit card size
  final double? overrideFontSize; // NEW: optional explicit font size
  final int maxRows; // ensure caller can request how many rows this title may occupy
  final double? fixedCardSize; // NEW: force same card size when provided
  final double? fixedFontSize; // NEW: optional forced font size

  const CardTitleRow({
    super.key,
    required this.letters,
    this.letterSize = 36.0,
    required this.cardPadding,
    this.interactive = true,
    this.small = false,
    this.overrideSize,
    this.overrideFontSize,
    this.maxRows = 1, // default to 1 so words stay on a single row
    this.fixedCardSize,
    this.fixedFontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Simpler, robust layout: compute a card size that fits all letters on one row
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width;
      final deviceWidth = MediaQuery.of(context).size.width;
      final scaleHint = (deviceWidth / 400).clamp(0.7, 1.6);

      final lettersList = letters.split('').where((ch) => ch.trim().isNotEmpty).toList();
      final total = lettersList.length;
      final int cols = max(1, total); // aim for single-row display

      // base sizes
      final baseSmall = 28.0;
      final baseLarge = 72.0;
      final desiredSize = (small ? baseSmall : baseLarge) * scaleHint;

      // simple spacing fraction and computation
      const double spacingFrac = 0.14;
      final double computed = availableWidth / (cols + (cols - 1) * spacingFrac);

      double cardSize = min(fixedCardSize ?? overrideSize ?? desiredSize, computed);
      double fontSize = fixedFontSize ??
          overrideFontSize ??
          (letterSize * (cardSize / (small ? baseSmall : baseLarge)));

      final double spacing = cardSize * spacingFrac;

      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < lettersList.length; i++) ...[
              SizedBox(
                width: cardSize,
                height: cardSize,
                child: FlipLetterCard(
                  letter: lettersList[i],
                  size: cardSize,
                  fontSize: fontSize,
                  padding: cardPadding,
                  small: small,
                ),
              ),
              if (i < lettersList.length - 1) SizedBox(width: spacing),
            ],
          ],
        ),
      );
    });
  }
}


// Home screen: shows 8 interactive cards as the title, subtitle "Game", and buttons
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder for responsive sizing
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final shortSide = min(width, height);
      final scale = (shortSide / 600).clamp(0.7, 1.6);

      final verticalSpacing = 16.0 * scale;
      final buttonWidth = (width * 0.45).clamp(140.0, 400.0);

      return Scaffold(
        backgroundColor: Colors.blueAccent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0 * scale, vertical: 24.0 * scale),
              child: SizedBox(
                // make the column occupy a large fraction of the available height so it centers vertically
                height: (height * 0.72).clamp(300.0, height),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: buttonWidth * 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // center vertically
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // The "Card Flip" as 8 interactive cards (constrain so it won't overflow)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: min(520.0, width - 40.0)),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CardTitleRow(
                                letters: 'WHAT',
                                letterSize: 32.0,
                                cardPadding: 6.0 * scale,
                                interactive: true,
                                small: false,
                                maxRows: 1,
                                fixedCardSize: 72.0,
                                fixedFontSize: 32.0,
                              ),
                              SizedBox(height: 6.0 * scale),
                              CardTitleRow(
                                letters: 'THE',
                                letterSize: 32.0,
                                cardPadding: 6.0 * scale,
                                interactive: true,
                                small: false,
                                maxRows: 1,
                                fixedCardSize: 72.0,
                                fixedFontSize: 32.0,
                              ),
                              SizedBox(height: 6.0 * scale),
                              CardTitleRow(
                                letters: 'FLIP',
                                letterSize: 32.0,
                                cardPadding: 6.0 * scale,
                                interactive: true,
                                small: false,
                                maxRows: 1,
                                fixedCardSize: 72.0,
                                fixedFontSize: 32.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing * 2),
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton(
                          style: mainButtonStyle,
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategorySelectionScreen())),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.0 * scale),
                            child: FittedBox(fit: BoxFit.scaleDown, child: Text('Start', style: TextStyle(fontSize: 16.0 * scale, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            foregroundColor: Colors.white,
                            shape: const SquareNotchBorder(notchSize: 6.0),
                            padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                            textStyle: TextStyle(fontFamily: 'PressStart2P', fontSize: 16.0 * scale, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardPage())),
                          child: FittedBox(fit: BoxFit.scaleDown, child: Text('Leaderboard', style: TextStyle(fontSize: 16.0 * scale, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// new screen wrapper so transitions match other pages
class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBanner(onBack: () => Navigator.of(context).pop()),
      backgroundColor: Colors.blueAccent,
      body: SafeArea(
        child: Center(
          child: CategorySelectorPanel(),
        ),
      ),
    );
  }
}

// Category selector panel (keeps logic) — will push Difficulty screen
class CategorySelectorPanel extends StatefulWidget {
  const CategorySelectorPanel({super.key});

  @override
  State<CategorySelectorPanel> createState() => _CategorySelectorPanelState();
}

class _CategorySelectorPanelState extends State<CategorySelectorPanel> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final shortSide = min(constraints.maxWidth, constraints.maxHeight);
      final scale = (shortSide / 600).clamp(0.7, 1.6);
      final btnWidth = (width * 0.6).clamp(140.0, 420.0);

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: btnWidth * 1.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text('Select Category', style: TextStyle(fontFamily: 'PressStart2P', fontSize: 20.0 * scale, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
              SizedBox(height: 20.0 * scale),
              SizedBox(width: btnWidth, child: ElevatedButton(style: mainButtonStyle, onPressed: () => _openDifficulty(context, Category.psychology), child: FittedBox(fit: BoxFit.scaleDown, child: const Text('Psychology')))),
              SizedBox(height: 12.0 * scale),
              SizedBox(width: btnWidth, child: ElevatedButton(style: mainButtonStyle, onPressed: () => _openDifficulty(context, Category.language), child: FittedBox(fit: BoxFit.scaleDown, child: const Text('Language')))),
              SizedBox(height: 12.0 * scale),
              SizedBox(width: btnWidth, child: ElevatedButton(style: mainButtonStyle, onPressed: () => _openDifficulty(context, Category.geography), child: FittedBox(fit: BoxFit.scaleDown, child: const Text('Geography')))),
            ],
          ),
        ),
      );
    });
  }

  void _openDifficulty(BuildContext context, Category category) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DifficultyScreen(category: category)));
  }
}

// Difficulty becomes full page screen with TopBanner
class DifficultyScreen extends StatelessWidget {
  final Category category;
  const DifficultyScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBanner(onBack: () => Navigator.of(context).pop()),
      backgroundColor: Colors.blueAccent,
      body: SafeArea(
        child: Center(
          child: DifficultySelectorPanel(category: category),
        ),
      ),
    );
  }
}

class DifficultySelectorPanel extends StatelessWidget {
  final Category category;
  const DifficultySelectorPanel({super.key, required this.category});

  void _showRules(BuildContext context, Difficulty difficulty) {
    String title;
    String body;

    // build rules text depending on both category and difficulty
    switch (difficulty) {
      case Difficulty.easy:
        title = 'Easy Mode';
        if (category == Category.psychology) {
          body =
              '• Grid: 4x4 (16 cards)\n'
              '• Goal: Match identical image cards.';
        } else if (category == Category.language) {
          body =
              '• Grid: 4x4 (16 cards)\n'
              '• Goal: Match identical image cards';
        } else {
          body =
              '• Grid: 4x4 (16 cards)\n'
              '• Goal: Match identical image cards.';
        }
        break;

      case Difficulty.medium:
        title = 'Medium Mode';
        if (category == Category.psychology) {
          body =
              '• Grid: 4x4 (16 cards)\n'
              '• Goal: Match each concept image with its word. \n'
              '• Order does not matter.\n';
        } else if (category == Category.language) {
          body =
              '• Grid: 4x4 (16 cards)\n'
              '• Goal: Match each image with its word. \n'
              '• Order does not matter.\n';
        } else {
          // geography
          body =
              '• Grid: 4x4 (16 cards)\n'
              '• Goal: Match each flag with its country. \n'
              '• Order does not matter.\n';
        }
        break;

      case Difficulty.hard:
        title = 'Hard Mode';
        if (category == Category.psychology) {
          body =
              '• Grid: 4x6 (24 cards)\n'
              '• Goal: Match each concept image with its word. \n'
              '• Order does not matter.\n';
        } else if (category == Category.language) {
          body =
              '• Grid: 4x6 (24 cards)\n'
              '• Goal: Match each image with its word. \n'
              '• Order does not matter.\n';
        } else {
          body =
              '• Grid: 4x6 (24 cards)\n'
              '• Goal: Match each flag with its country. \n'
              '• Order does not matter.\n';
        }
        break;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: 'PressStart2P', color: Colors.blueAccent)),
        content: Text(body, style: const TextStyle(fontFamily: 'PressStart2P', color: Colors.blueAccent)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final shortSide = min(constraints.maxWidth, constraints.maxHeight);
      final scale = (shortSide / 600).clamp(0.7, 1.6);
      final btnWidth = (width * 0.6).clamp(140.0, 420.0);

      String categoryName;
      switch (category) {
        case Category.psychology:
          categoryName = 'Psychology';
          break;
        case Category.language:
          categoryName = 'Language';
          break;
        case Category.geography:
          categoryName = 'Geography';
          break;
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Select Difficulty',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 22.0 * scale,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6.0 * scale),
          Text(
            categoryName,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 16.0 * scale,
              color: const Color.fromARGB(179, 255, 255, 255),
            ),
          ),
          SizedBox(height: 20.0 * scale),
          // Easy row with rules button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: btnWidth, child: ElevatedButton(style: mainButtonStyle, onPressed: () => _startGame(context, Difficulty.easy), child: const Text('Easy'))),
              SizedBox(width: 8.0 * scale),
              IconButton(
                tooltip: 'Rules',
                icon: Icon(Icons.info_outline, color: Colors.white, size: 20.0 * scale),
                onPressed: () => _showRules(context, Difficulty.easy),
              )
            ],
          ),
          SizedBox(height: 10.0 * scale),
          // Medium row with rules button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: btnWidth, child: ElevatedButton(style: mainButtonStyle, onPressed: () => _startGame(context, Difficulty.medium), child: const Text('Medium'))),
              SizedBox(width: 8.0 * scale),
              IconButton(
                tooltip: 'Rules',
                icon: Icon(Icons.info_outline, color: Colors.white, size: 20.0 * scale),
                onPressed: () => _showRules(context, Difficulty.medium),
              )
            ],
          ),
          SizedBox(height: 10.0 * scale),
          // Hard row with rules button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: btnWidth, child: ElevatedButton(style: mainButtonStyle, onPressed: () => _startGame(context, Difficulty.hard), child: const Text('Hard'))),
              SizedBox(width: 8.0 * scale),
              IconButton(
                tooltip: 'Rules',
                icon: Icon(Icons.info_outline, color: Colors.white, size: 20.0 * scale),
                onPressed: () => _showRules(context, Difficulty.hard),
              )
            ],
          ),
        ],
      );
    });
  }

  void _startGame(BuildContext context, Difficulty difficulty) {
    // Navigate to the GamePage for the current category and chosen difficulty
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GamePage(category: category, difficulty: difficulty),
      ),
    );
  }
}

// GamePage: scaffold that uses TopBanner and contains the RevealCardGame widget
class GamePage extends StatelessWidget {
  final Category category;
  final Difficulty difficulty;
  const GamePage({super.key, required this.category, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    // create a key so we can call retryGame() on the RevealCardGame state when Back is pressed
    final gameKey = GlobalKey<_RevealCardGameState>();

    return Scaffold(
      // If the game is running, reset to pregame (retryGame) and stay on-screen.
      // If already at pregame, pop one route to go back.
      appBar: TopBanner(onBack: () {
        final state = gameKey.currentState;
        if (state != null && state.started) {
          // return to pregame state instead of popping
          state.retryGame();
          return;
        }
        // not started -> pop one route
        Navigator.of(context).maybePop();
      }),
      backgroundColor: Colors.blueAccent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: RevealCardGame(
                key: gameKey,
                category: category,
                difficulty: difficulty,
                onPlayAgain: () {
                  // pop back to difficulty selector
                  Navigator.of(context).pop();
                },
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardData {
  final String matchKey;
  final String displayText;
  CardData(this.matchKey, this.displayText);
}

// RevealCardGame now takes a category
class RevealCardGame extends StatefulWidget {
  final Category category;
  final Difficulty difficulty;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  const RevealCardGame({
    super.key,
    required this.category,
    required this.difficulty,
    required this.onPlayAgain,
    required this.onBack,
  });

  @override
  State<RevealCardGame> createState() => _RevealCardGameState();
}

class _RevealCardGameState extends State<RevealCardGame> {
  bool started = false;
  int seconds = 0;
  int score = 0;
  Timer? timer;
  bool finished = false;

  int correctMatches = 0;
  int totalAttempts = 0;
  int accuracyStreak = 0;

  void startGame() {
    setState(() {
      started = true;
      seconds = 0;
      score = 0;
      finished = false;
      correctMatches = 0;
      totalAttempts = 0;
      accuracyStreak = 0;
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        seconds++;
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  void onGameFinished() {
    stopTimer();
    setState(() {
      finished = true;
    });
    showResultsDialog();
  }

  void showResultsDialog() {
    double accuracyRate = totalAttempts == 0 ? 0 : (correctMatches / totalAttempts) * 100;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
              const SizedBox(height: 12),
              Text(
                'Results',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text('Total Score: $score', style: const TextStyle(fontSize: 18)),
              Text('Time Taken: $formattedTime', style: const TextStyle(fontSize: 18)),
              Text('Accuracy Rate: ${accuracyRate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              // Submit score button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: const SquareNotchBorder(notchSize: 6.0),
                  textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // close results dialog
                  _showSubmitScoreDialog();
                },
                child: const Text('Submit Score', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 12),
              // View leaderboard
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: const SquareNotchBorder(notchSize: 6.0),
                  textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardPage()));
                },
                child: const Text('View Leaderboard', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: const SquareNotchBorder(notchSize: 6.0),
                  textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 18),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitScoreDialog() {
    final nameCtrl = TextEditingController();
    final parentContext = context; // capture parent context so we can navigate after dialog closes
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // TextField text should be black and use PressStart2P
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Name'),
                style: const TextStyle(color: Colors.black, fontFamily: 'PressStart2P'),
                cursorColor: Colors.black,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      Navigator.of(context).pop(); // close dialog
                      // use saveScore helper (writes server timestamp)
                      final success = await saveScore(
                        name,
                        score,
                        widget.category.toString().split('.').last,
                        widget.difficulty.toString().split('.').last,
                        formattedTime,
                      );
                      if (success) {
                        // navigate to leaderboard screen automatically
                        // ignore: use_build_context_synchronously
                        Navigator.of(parentContext).push(MaterialPageRoute(builder: (_) => const LeaderboardPage()));
                      } else {
                        // show failure on the parent scaffold
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Submit failed')));
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  int getBasePoints() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return 10;
      case Difficulty.medium:
        return 15;
      case Difficulty.hard:
        return 20;
    }
  }

  int getTimeBonus() {
    if (seconds <= 20) return 5;
    if (seconds <= 40) return 2;
    return 0;
  }

  void onCorrectMatch({required bool wasAccurate}) {
    int basePoints = getBasePoints();
    int timeBonus = getTimeBonus();
    int accuracyBonus = wasAccurate ? 3 : 0;

    setState(() {
      score += basePoints + timeBonus + accuracyBonus;
      correctMatches++;
      accuracyStreak = wasAccurate ? accuracyStreak + 1 : 0;
      totalAttempts++;
    });
  }

  void onMismatch() {
    setState(() {
      // Don't penalize when score is already zero — never allow negative score.
      if (score > 0) score -= 1;
      accuracyStreak = 0;
      totalAttempts++;
    });
  }

  void retryGame() {
    stopTimer();
    setState(() {
      started = false;
      seconds = 0;
      score = 0;
      finished = false;
      correctMatches = 0;
      totalAttempts = 0;
      accuracyStreak = 0;
    });
  }

  String get formattedTime {
    if (seconds < 60) {
      return '$seconds s';
    } else {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      final sStr = s.toString().padLeft(2, '0');
      return '$m:$sStr';
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive scaling derived from the shortest side
    final mq = MediaQuery.of(context);
    final shortSide = min(mq.size.width, mq.size.height);
    final scale = (shortSide / 600).clamp(0.72, 1.6);

    String categoryName;
    switch (widget.category) {
      case Category.psychology:
        categoryName = 'Psychology';
        break;
      case Category.language:
        categoryName = 'Language';
        break;
      case Category.geography:
        categoryName = 'Geography';
        break;
    }

    final titleSize = 20.0 * scale;
    final subtitleSize = 14.0 * scale;
    final scoreSize = 18.0 * scale;
    final buttonPadding = EdgeInsets.symmetric(vertical: 12.0 * scale, horizontal: 20.0 * scale);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0 * scale, vertical: 6.0 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${widget.difficulty == Difficulty.easy ? 'Easy Mode' : widget.difficulty == Difficulty.medium ? 'Medium Mode' : 'Hard Mode'}: $categoryName',
            style: TextStyle(
              fontSize: titleSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'PressStart2P',
              letterSpacing: 1.5 * scale,
            ),
          ),
          SizedBox(height: 16.0 * scale),
          started
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Score with PressStart2P
                    Text('Score: $score',
                        style: TextStyle(
                          fontSize: scoreSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PressStart2P',
                        )),
                    SizedBox(height: 8.0 * scale),
                    SizedBox(
                      width: mq.size.width * 0.95,
                      child: RevealCardGrid(
                        category: widget.category,
                        difficulty: widget.difficulty,
                        onAllMatched: onGameFinished,
                        onCorrectMatch: () => onCorrectMatch(wasAccurate: accuracyStreak == 0),
                        onMismatch: onMismatch,
                      ),
                    ),
                    SizedBox(height: 12.0 * scale),
                    // Time with PressStart2P
                    Text('Time: $formattedTime',
                        style: TextStyle(
                          fontSize: subtitleSize * 1.1,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PressStart2P',
                        )),
                    SizedBox(height: 12.0 * scale),
                    if (!finished)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                          foregroundColor: const Color.fromRGBO(268, 138, 255, 1),
                          padding: buttonPadding,
                          shape: const SquareNotchBorder(notchSize: 6.0),
                        ),
                        onPressed: retryGame,
                        child: Text('Retry', style: TextStyle(fontSize: subtitleSize)),
                      ),
                    if (finished)
                      Column(
                        children: [
                          SizedBox(height: 12.0 * scale),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                              foregroundColor: const Color.fromRGBO(68, 138, 255, 1),
                              padding: buttonPadding,
                              shape: const SquareNotchBorder(notchSize: 6.0),
                            ),
                            onPressed: widget.onPlayAgain,
                            child: Text('Play Again', style: TextStyle(fontSize: subtitleSize)),
                          ),
                        ],
                      ),
                  ],
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF448AFF), // explicit blue foreground
                    padding: buttonPadding,
                    shape: const SquareNotchBorder(notchSize: 6.0),
                    textStyle: const TextStyle(fontFamily: 'PressStart2P'),
                  ),
                  onPressed: startGame,
                  child: Text('Start', style: TextStyle(fontSize: subtitleSize, color: const Color(0xFF448AFF))),
                ),
          SizedBox(height: 16.0 * scale),
          // removed in-body back button; use TopBanner back button instead
          SizedBox(height: 8.0 * scale),

        ],
      ),
    );
  }
}

// RevealCardGrid now takes a category
class RevealCardGrid extends StatefulWidget {
  final Category category;
  final Difficulty difficulty;
  final VoidCallback? onAllMatched;
  final VoidCallback? onCorrectMatch;
  final VoidCallback? onMismatch;
  const RevealCardGrid({
    super.key,
    required this.category,
    required this.difficulty,
    this.onAllMatched,
    this.onCorrectMatch,
    this.onMismatch,
  });

  @override
  State<RevealCardGrid> createState() => _RevealCardGridState();
}

class _RevealCardGridState extends State<RevealCardGrid> {
  late List<CardData> values;
  late List<bool> revealed;
  late List<bool> matched;
  List<int> selectedIndices = [];

  // number of psychology image assets available
  static const int psychImageCount = 12;

  // language images you uploaded (filenames without .png)
  static const List<String> languageImageNames = [
    'apple',
    'ball',
    'books',
    'car',
    'cat',
    'chair',
    'dog',
    'house',
    'shoes',
    'sun',
    'tree',
    'water',
  ];
  static final int languageImageCount = languageImageNames.length;

  // geography images you uploaded (filenames without .png)
  static const List<String> geographyImageNames = [
    'brazil',
    'canada',
    'china',
    'france',
    'germany',
    'india',
    'italy',
    'japan',
    'philippines',
    'south_korea',
    'united_kingdom',
    'usa',
  ];
  static final int geographyImageCount = geographyImageNames.length;

  // helper: "south_korea" -> "South Korea"
  String _displayNameFromFile(String fname) {
    return fname.split('_').map((s) => s.isEmpty ? s : (s[0].toUpperCase() + (s.length>1 ? s.substring(1) : ''))).join(' ');
  }

  // Card sets for each category
  static final List<CardData> psychologyCards = [
    CardData('conditioning', 'Classical Conditioning'),
    CardData('conditioning', 'Pavlov’s dog'),
    CardData('operant', 'Operant Conditioning'),
    CardData('operant', 'Skinner box'),
    CardData('stm', 'Short-term Memory'),
    CardData('stm', '7±2 items'),
    CardData('wm', 'Working Memory'),
    CardData('wm', 'mental workspace image'),
    CardData('maslow', 'Maslow’s Hierarchy'),
    CardData('maslow', 'pyramid graphic'),
    CardData('piaget', 'Piaget'),
    CardData('piaget', 'stages of development (with visual cues)'),
    CardData('schemas', 'Schemas'),
    CardData('schemas', 'filing cabinet illustration'),
    CardData('attention', 'Selective Attention'),
    CardData('attention', 'cocktail party example'),
  ];

  static final List<CardData> languageCards = [
    CardData('happy', 'Happy'),
    CardData('happy', 'Joyful'),
    CardData('sad', 'Sad'),
    CardData('sad', 'Unhappy'),
    CardData('fast', 'Fast'),
    CardData('fast', 'Quick'),
    CardData('smart', 'Smart'),
    CardData('smart', 'Intelligent'),
    CardData('big', 'Big'),
    CardData('big', 'Large'),
    CardData('small', 'Small'),
    CardData('small', 'Tiny'),
    CardData('angry', 'Angry'),
    CardData('angry', 'Mad'),
    CardData('beautiful', 'Beautiful'),
    CardData('beautiful', 'Pretty'),
    CardData('strong', 'Strong'),
    CardData('strong', 'Powerful'),
    CardData('weak', 'Weak'),
    CardData('weak', 'Fragile'),
    CardData('rich', 'Rich'),
    CardData('rich', 'Wealthy'),
    CardData('poor', 'Poor'),
    CardData('poor', 'Needy'),
  ];

  static final List<CardData> geographyCards = [
    CardData('france', 'France'),
    CardData('france', 'Paris'),
    CardData('germany', 'Germany'),
    CardData('germany', 'Berlin'),
    CardData('italy', 'Italy'),
    CardData('italy', 'Rome'),
    CardData('spain', 'Spain'),
    CardData('spain', 'Madrid'),
    CardData('uk', 'United Kingdom'),
    CardData('uk', 'London'),
    CardData('japan', 'Japan'),
    CardData('japan', 'Tokyo'),
    CardData('canada', 'Canada'),
    CardData('canada', 'Ottawa'),
    CardData('usa', 'United States'),
    CardData('usa', 'Washington D.C.'),
  ];

  List<CardData> getBaseCards(Category category) {
    switch (category) {
      case Category.psychology:
        return psychologyCards;
      case Category.language:
        return languageCards;
      case Category.geography:
        return geographyCards;
    }
  }

  List<CardData> getEasyCards(Category category) {
    // For psychology/easy: use image pairs assets/images/1.png .. up to psychImageCount
    if (category == Category.psychology) {
      final indices = List<int>.generate(psychImageCount, (i) => i + 1);
      indices.shuffle(Random());
      final useCount = min(8, psychImageCount); // 4x4 needs 8 pairs
      final pairs = <CardData>[];
      for (int i = 0; i < useCount; i++) {
        final idx = indices[i];
        final key = 'img$idx';
        final path = 'assets/images/$idx.png';
        pairs.add(CardData(key, path));
        pairs.add(CardData(key, path));
      }
      return pairs;
    }
    // For language/easy: use image pairs (one image shown twice per pair)
    if (category == Category.language) {
      final names = List<String>.from(languageImageNames)..shuffle(Random());
      final useCount = min(8, languageImageCount); // 4x4 needs 8 pairs
      final pairs = <CardData>[];
      for (int i = 0; i < useCount; i++) {
        final name = names[i];
        final key = 'lang_$name';
        final path = 'assets/images/$name.png';
        pairs.add(CardData(key, path));
        pairs.add(CardData(key, path));
      }
      return pairs;
    }
    // For geography/easy: use image pairs (one image shown twice per pair)
    if (category == Category.geography) {
      final names = List<String>.from(geographyImageNames)..shuffle(Random());
      final useCount = min(8, geographyImageCount);
      final pairs = <CardData>[];
      for (int i = 0; i < useCount; i++) {
        final name = names[i];
        final key = 'geo_$name';
        final path = 'assets/images/$name.png';
        pairs.add(CardData(key, path));
        pairs.add(CardData(key, path));
      }
      return pairs;
    }
    // Fallback for other categories: match identical words (duplicate each unique word)
    final base = getBaseCards(category);
    final uniqueWords = base.take(8).toList();
    final pairs = <CardData>[];
    for (final card in uniqueWords) {
      pairs.add(CardData(card.displayText, card.displayText));
      pairs.add(CardData(card.displayText, card.displayText));
    }
    return pairs;
  }

  // NEW: medium mode generator — for psychology returns image+word pairs (picture ↔ corresponding word)
  List<CardData> getMediumCards(Category category) {
    if (category == Category.psychology) {
      // Extended mapping to include images 1..12 (you added 9..12)
      final mapping = <int, Map<String, String>>{
        1: {'key': 'conditioning', 'word': 'Classical Conditioning'},
        2: {'key': 'operant', 'word': 'Operant Conditioning'},
        3: {'key': 'attention', 'word': 'Selective Attention'},
        4: {'key': 'schemas', 'word': 'Schemas'},
        5: {'key': 'piaget', 'word': 'Piaget'},
        6: {'key': 'maslow', 'word': 'Maslow’s Hierarchy'},
        7: {'key': 'stm', 'word': 'Working Memory'},
        8: {'key': 'wm', 'word': 'Short-term Memor'},
        9: {'key': 'stroop', 'word': 'Stroop Effect'},
        10: {'key': 'encoding', 'word': 'Encoding'},
        11: {'key': 'decoding', 'word': 'Decoding'},
        12: {'key': 'problem_solving', 'word': 'Problem Solving'},
      };

      // Choose up to 8 distinct images from available pool so medium remains 16 cards total.
      final available = List<int>.generate(psychImageCount, (i) => i + 1)..shuffle(Random());
      final useCount = min(8, psychImageCount);
      final chosen = available.take(useCount).toList();

      final pairs = <CardData>[];
      for (final i in chosen) {
        final info = mapping[i]!;
        final key = info['key']!;
        final word = info['word']!;
        final imgPath = 'assets/images/$i.png';
        // one card shows the image, the other shows the word — same matchKey
        pairs.add(CardData(key, imgPath));
        pairs.add(CardData(key, word));
      }
      return pairs;
    }
    // Language medium: image <-> word pairs
    if (category == Category.language) {
      // explicit filename -> display word mapping
      final mapping = <String, String>{
        'apple': 'Apple',
        'ball': 'Ball',
        'books': 'Books',
        'car': 'Car',
        'cat': 'Cat',
        'chair': 'Chair',
        'dog': 'Dog',
        'house': 'House',
        'shoes': 'Shoes',
        'sun': 'Sun',
        'tree': 'Tree',
        'water': 'Water',
      };

      final available = List<String>.from(languageImageNames)..shuffle(Random());
      final useCount = min(8, languageImageCount);
      final chosen = available.take(useCount).toList();

      final pairs = <CardData>[];
      for (final name in chosen) {
        // use a stable matchKey so image and word pair correctly
        final key = 'lang_$name';
        final imgPath = 'assets/images/$name.png';
        final word = mapping[name] ?? name;
        pairs.add(CardData(key, imgPath)); // image card
        pairs.add(CardData(key, word)); // matching word card
      }
      return pairs;
    }
    // Geography medium: image <-> country name pairs (word derived from filename)
    if (category == Category.geography) {
      final available = List<String>.from(geographyImageNames)..shuffle(Random());
      final useCount = min(8, geographyImageCount);
      final chosen = available.take(useCount).toList();

      final pairs = <CardData>[];
      for (final name in chosen) {
        final key = 'geo_$name';
        final imgPath = 'assets/images/$name.png';
        final word = _displayNameFromFile(name);
        pairs.add(CardData(key, imgPath));
        pairs.add(CardData(key, word));
      }
      return pairs;
    }
    // Fallback: identical-words pairs like easy (keep previous behavior)
    final base = getBaseCards(category);
    final uniqueWords = base.take(8).toList();
    final pairs = <CardData>[];
    for (final card in uniqueWords) {
      pairs.add(CardData(card.displayText, card.displayText));
      pairs.add(CardData(card.displayText, card.displayText));
    }
    return pairs;
  }

  // NEW: expanded hard-mode generator — use medium rules, then append more items to reach 24 cards
  List<CardData> getHardCards(Category category) {
    // Use the same matching rules as Medium (image↔word pairs for psychology, similar for others).
    final medium = getMediumCards(category);
    final cards = List<CardData>.from(medium);

    // Append complete medium pairs (two entries per concept) until we reach 24 items.
    // medium is organized as [pair0_itemA, pair0_itemB, pair1_itemA, pair1_itemB, ...]
    int pairIndex = 0;
    while (cards.length < 24) {
      final baseIndex = (pairIndex % (medium.length ~/ 2)) * 2;
      // add both elements of the pair to preserve matchKey parity
      cards.add(CardData(medium[baseIndex].matchKey, medium[baseIndex].displayText));
      if (cards.length < 24) {
        cards.add(CardData(medium[baseIndex + 1].matchKey, medium[baseIndex + 1].displayText));
      }
      pairIndex++;
    }

    return cards.sublist(0, 24);
  }

  @override
  void initState() {
    super.initState();
    final baseCards = getBaseCards(widget.category);
    if (widget.difficulty == Difficulty.easy) {
      values = getEasyCards(widget.category);
    } else if (widget.difficulty == Difficulty.medium) {
      // Medium: 4x4 grid, 16 cards.
      // Use getMediumCards for psychology, language and geography (image↔word pairs).
      if (widget.category == Category.psychology || widget.category == Category.language || widget.category == Category.geography) {
        values = getMediumCards(widget.category);
      } else {
        // keep previous behavior for other categories (related pairs)
        values = [];
        while (values.length < 16) {
          values.addAll(baseCards);
        }
        values = values.sublist(0, 16);
      }
    } else {
      // Hard: imitate Medium rules but expand to 24 cards
      values = getHardCards(widget.category);
    }
    values.shuffle();
    revealed = List.generate(values.length, (_) => false);
    matched = List.generate(values.length, (_) => false);
  }

  bool awaiting = false; // prevent double tap

  void onCardTap(int index) async {
    if (revealed[index] || matched[index] || selectedIndices.length == 2 || awaiting) return;
    setState(() {
      revealed[index] = true;
      selectedIndices.add(index);
    });
    if (selectedIndices.length == 2) {
      int first = selectedIndices[0];
      int second = selectedIndices[1];
      awaiting = true;
      if (values[first].matchKey == values[second].matchKey) {
        setState(() {
          matched[first] = true;
          matched[second] = true;
          selectedIndices.clear();
        });
        widget.onCorrectMatch?.call();
        if (matched.every((m) => m)) {
          widget.onAllMatched?.call();
        }
      } else {
        widget.onMismatch?.call();
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          revealed[first] = false;
          revealed[second] = false;
          selectedIndices.clear();
        });
      }
      awaiting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        min(maxWidth, maxHeight);

        // Determine cols/rows based on difficulty
        final int cols = 4;
        final int rows = widget.difficulty == Difficulty.hard ? 6 : 4;

        final double spacing = 1.0; // fixed tiny gap between tiles
        final double padding = 1.0; // ~half the spacing for outer inset

        // compute available area after grid padding
        final double availableWidth = maxWidth - (padding * 2) - (spacing * (cols - 1));
        final double availableHeight = maxHeight - (padding * 2) - (spacing * (rows - 1));

        // each cell should fit into both directions
        double cellSize = min(availableWidth / cols, availableHeight / rows);
        // Slightly reduce cell size for hard difficulty so 4x6 fits more comfortably.
        final double hardScale = widget.difficulty == Difficulty.hard ? 0.85 : 1.0;
        // Lower the maximum allowed size for hard mode to keep tiles a bit smaller.
        final double maxCell = widget.difficulty == Difficulty.hard ? 160.0 : 200.0;
        cellSize = (cellSize * hardScale).clamp(22.0, maxCell);

        final double gridWidth = cellSize * cols + spacing * (cols - 1) + padding * 2;
        final double gridHeight = cellSize * rows + spacing * (rows - 1) + padding * 2;

        final int crossAxisCount = cols;
        final int itemCount = values.length;

        return Center(
          child: SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              padding: EdgeInsets.all(padding),
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(itemCount, (index) {
                return RevealCard(
                  value: values[index].displayText,
                  revealed: revealed[index] || matched[index],
                  matched: matched[index],
                  onTap: () => onCardTap(index),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class RevealCard extends StatelessWidget {
  final String value;
  final bool revealed;
  final bool matched;
  final VoidCallback onTap;
  const RevealCard({super.key, required this.value, required this.revealed, required this.matched, required this.onTap});

  static const Set<String> redTextValues = {
    'Skinner box',
    '7 ± 2 items',
    'Pavlov’s dog',
    'mental workspace image',
    'pyramid graphic',
    'stages of development (with visual cues)',
    'filing cabinet illustration',
    'cocktail party example',
  };

  @override
  Widget build(BuildContext context) {
    final isRedText = redTextValues.contains(value);

    // Make font sizes and layout derive from available size so the game is responsive.
    return LayoutBuilder(builder: (context, constraints) {
      final cardSize = constraints.biggest.shortestSide; // available space for this widget
      final base = cardSize.clamp(40.0, 160.0);

      // split into words/lines
      final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      List<String> lines;
      if (words.isEmpty) {
        lines = [''];
      } else if (words.length == 1) {
        lines = [words[0]];
      } else if (words.length == 3) {
        lines = [words[0], words[1], words[2]];
      } else {
        final mid = (words.length / 2).ceil();
        final line1 = words.take(mid).join(' ');
        final line2 = words.skip(mid).join(' ');
        lines = [line1, line2];
      }

      // heuristics for font sizes based on card size
      double singleFont = (base * 0.42).clamp(14.0, 48.0);
      double lineFont1 = (base * 0.32).clamp(12.0, 40.0);
      double lineFont2 = (base * 0.26).clamp(10.0, 32.0);
      if (lines.length == 1) {
        lineFont1 = singleFont;
      } else if (lines.length == 2) {
        // keep relative differences
        final l1 = lines[0].length;
        final l2 = lines[1].length;
        final longer = max(l1, l2);
        final shorter = min(l1, l2);
        final ratio = (longer / max(shorter, 1)).clamp(1.0, 3.0);
        final baseFont = base * 0.32;
        final shorterF = (baseFont * ratio).clamp(12.0, 48.0);
        final longerF = (baseFont * (1 / ratio) * 1.4).clamp(10.0, shorterF);
        if (l1 <= l2) {
          lineFont1 = shorterF;
          lineFont2 = longerF;
        } else {
          lineFont1 = longerF;
          lineFont2 = shorterF;
        }
      }

      Widget buildFace() {
        // Use NotchedCard so in-game cards match title cards.
        Widget content;
        // render image when value points to an asset image (ends with .png)
        if (value.toLowerCase().endsWith('.png')) {
          // Less padding and use a cover fit to zoom/crop the image so it fills the card.
          final innerPad = max(2.0, base * 0.02);
          content = Padding(
            padding: EdgeInsets.all(innerPad),
            child: ClipRRect(
              // small radius to match card feel (not the notches)
              borderRadius: BorderRadius.circular(max(4.0, base * 0.06)),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Image.asset(
                  value,
                  fit: BoxFit.cover, // cover = zoom / crop to fill
                  alignment: Alignment.center,
                  errorBuilder: (c, e, s) {
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.broken_image, size: base * 0.40, color: Colors.grey),
                      SizedBox(height: 6.0),
                      Text(
                        value.split('/').last,
                        style: TextStyle(fontSize: max(10.0, base * 0.10)),
                      )
                    ]);
                  },
                ),
              ),
            ),
          );
        } else {
           // fallback to text layout
           List<Widget> textLines = [];
           if (lines.length == 1) {
             textLines.add(Text(lines[0],
                 textAlign: TextAlign.center,
                 style: TextStyle(
                     fontFamily: 'PressStart2P',
                     color: isRedText ? Colors.red : Colors.black,
                     fontSize: lineFont1,
                     height: 1.0)));
           } else if (lines.length == 2) {
             textLines.add(Text(lines[0],
                 textAlign: TextAlign.center,
                 style: TextStyle(
                     fontFamily: 'PressStart2P',
                     color: isRedText ? Colors.red : Colors.black,
                     fontSize: lineFont1,
                     height: 1.0)));
             textLines.add(Text(lines[1],
                 textAlign: TextAlign.center,
                 style: TextStyle(
                     fontFamily: 'PressStart2P',
                     color: isRedText ? Colors.red : Colors.black,
                     fontSize: lineFont2,
                     height: 1.0)));
           } else {
             for (final ln in lines) {
               textLines.add(Text(ln,
                   textAlign: TextAlign.center,
                   style: TextStyle(
                       fontFamily: 'PressStart2P',
                       color: Colors.black,
                       fontSize: base * 0.12,
                       height: 1.0)));
             }
           }
           content = FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisSize: MainAxisSize.min, children: textLines));
         }

         return Container(
           // outer shadow to match previous look (the NotchedCard itself draws the notched shape)
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(base * 0.12),
             // subtle shadow same as before
             // ignore: deprecated_member_use
             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), offset: const Offset(0, 2), blurRadius: 4)],
           ),
           child: NotchedCard(
             size: base,
             // reduced internal padding so card content fills more area and edges look tighter
             padding: max(2.0, base * 0.035),
             notchFraction: 0.04, // small notches
             fillColor: Colors.white,
             child: content,
           ),
         );
       }

      Widget buildBack() {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(base * 0.12),
            // ignore: deprecated_member_use
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(0, 2), blurRadius: 4)],
          ),
          child: NotchedCard(
            size: base,
            padding: max(2.0, base * 0.035),
            notchFraction: 0.04,
            fillColor: Colors.white,
            child: Text(
              '?',
              style: TextStyle(fontFamily: 'PressStart2P', color: Colors.blueAccent, fontSize: max(20.0, base * 0.28), height: 1.0),
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: onTap,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final rotate = Tween(begin: pi, end: 0.0).animate(animation);
            return AnimatedBuilder(
              animation: rotate,
              child: child,
              builder: (context, child) {
                final isUnder = (ValueKey(revealed) != child?.key);
                var tilt = (isUnder ? min(rotate.value, pi / 2) : rotate.value);
                return Transform(transform: Matrix4.rotationY(tilt), alignment: Alignment.center, child: child);
              },
            );
          },
          layoutBuilder: (widget, list) => Stack(children: [widget!, ...list]),
          child: revealed
              ? Opacity(opacity: matched ? 0.6 : 1.0, key: const ValueKey(true), child: buildFace())
              : Container(key: const ValueKey(false), child: buildBack()),
        ),
      );
    });
  }
}

// REPLACE the NotchedSquarePainter implementation with one that clears square cutouts (transparent)
// (also adjust default notchFraction to 0.10)
class NotchedSquarePainter extends CustomPainter {
  final Color fillColor;
  final Color backgroundColor;
  final double notchFraction; // fraction of side used for notch (square size)

  NotchedSquarePainter({
    required this.fillColor,
    this.backgroundColor = const Color(0xFF2E2E2E),
    this.notchFraction = 0.04, // even smaller by default
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We'll draw onto a layer so we can "cut out" transparent notches using BlendMode.clear.
    final layerRect = Offset.zero & size;
    canvas.saveLayer(layerRect, Paint());

    // Draw dark background for the entire painter (this will be on the layer).
    final paintBg = Paint()..color = backgroundColor;
    canvas.drawRect(layerRect, paintBg);

    // Use the largest centered square that fits
    final s = min(size.width, size.height);
    final left = (size.width - s) / 2;
    final top = (size.height - s) / 2;
    final r = Rect.fromLTWH(left, top, s, s);

    // notch represents the side length of the square cutout at each corner
    final notch = s * notchFraction;

    // Build a path for the notched rectangle (white card shape).
    final path = Path()
      ..moveTo(r.left + notch, r.top)
      ..lineTo(r.right - notch, r.top)
      ..lineTo(r.right - notch, r.top + notch)
      ..lineTo(r.right, r.top + notch)
      ..lineTo(r.right, r.bottom - notch)
      ..lineTo(r.right - notch, r.bottom - notch)
      ..lineTo(r.right - notch, r.bottom)
      ..lineTo(r.left + notch, r.bottom)
      ..lineTo(r.left + notch, r.bottom - notch)
      ..lineTo(r.left, r.bottom - notch)
      ..lineTo(r.left, r.top + notch)
      ..lineTo(r.left + notch, r.top + notch)
      ..close();

    // Draw fill for the card
    final paintFill = Paint()..color = fillColor;
    canvas.drawPath(path, paintFill);

    // NO stroke: outlines removed

    // Now clear the exact square cutout rects so they become transparent (show underlying app background).
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    // top-left
    canvas.drawRect(Rect.fromLTWH(r.left, r.top, notch, notch), clearPaint);
    // top-right
    canvas.drawRect(Rect.fromLTWH(r.right - notch, r.top, notch, notch), clearPaint);
    // bottom-right
    canvas.drawRect(Rect.fromLTWH(r.right - notch, r.bottom - notch, notch, notch), clearPaint);
    // bottom-left
    canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - notch, notch, notch), clearPaint);

    // restore layer (composite onto main canvas)
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant NotchedSquarePainter old) {
    return old.fillColor != fillColor ||
        old.backgroundColor != backgroundColor ||
        old.notchFraction != notchFraction;
  }
}

// NotchedCard: default notchFraction updated to match smaller size
class NotchedCard extends StatelessWidget {
  final double size;
  final double padding;
  final Widget child;
  final Color fillColor;
  final double notchFraction;

  const NotchedCard({
    super.key,
    required this.size,
    required this.child,
    this.padding = 6.0,
    this.fillColor = Colors.white,
    this.notchFraction = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: NotchedSquarePainter(
          fillColor: fillColor,
          backgroundColor: Colors.grey.shade800,
          notchFraction: notchFraction,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
                    child: Center(child: child),
        ),
      ),
    );
  }
}

// Add a simple Firestore helper (uses server timestamp)
final FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<bool> saveScore(String player, int score, String category, String difficulty, String time) async {
	// writes using same field names the app expects
	try {
		await firestore.collection('leaderboard').add({
			'name': player,
			'score': score,
			'category': category,
			'difficulty': difficulty,
			'time': time,
			'createdAt': FieldValue.serverTimestamp(),
		});
		return true;
	} catch (e) {
		// ignore: avoid_print
		print('saveScore error: $e');
		return false;
	}
}

// Replace HTTP-based Leaderboard classes with Firestore-backed ones:

class LeaderboardEntry {
  final String name;
  final int score;
  final String category;
  final String difficulty;
  final String time;
  final DateTime createdAt;

  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.category,
    required this.difficulty,
    required this.time,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    // Robust parsing for score (int, double or string) and createdAt (Timestamp, int, string, null)
    int parsedScore = 0;
    final rawScore = map['score'];
    if (rawScore is int) {
      parsedScore = rawScore;
    } else if (rawScore is double) {
      parsedScore = rawScore.toInt();
    } else if (rawScore is num) {
      parsedScore = rawScore.toInt();
    } else {
      parsedScore = int.tryParse('${rawScore ?? ''}') ?? 0;
    }

    DateTime parsedCreatedAt = DateTime.now();
    final rawCreated = map['createdAt'];
    try {
      if (rawCreated == null) {
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(0);
      } else if (rawCreated is DateTime) {
        parsedCreatedAt = rawCreated;
      } else if (rawCreated is Timestamp) {
        parsedCreatedAt = (rawCreated).toDate();
      } else if (rawCreated is num) {
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch((rawCreated).toInt());
      } else {
        parsedCreatedAt = DateTime.tryParse(rawCreated.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
    } catch (_) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return LeaderboardEntry(
      name: map['name'] ?? '',
      score: parsedScore,
      category: map['category'] ?? '',
      difficulty: map['difficulty'] ?? '',
      time: map['time'] ?? '',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'score': score,
        'category': category,
        'difficulty': difficulty,
        'time': time,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class LeaderboardService {
  static final CollectionReference _col = FirebaseFirestore.instance.collection('leaderboard');

  // Submit a score to Firestore using server timestamp for createdAt
  static Future<bool> submitScore(LeaderboardEntry entry) async {
    try {
      final data = entry.toMap();
      // Use server timestamp so ordering is consistent and trustworthy
      data['createdAt'] = FieldValue.serverTimestamp();
      await _col.add(data);
      return true;
    } catch (e, st) {
      // ignore: avoid_print
      print('Leaderboard submit error: $e\n$st');
      return false;
    }
  }

  // Fetch top scores ordered by score desc, then client-side by createdAt desc
  static Future<List<LeaderboardEntry>> fetchTop({int limit = 20, String? category, String? difficulty}) async {
    try {
      // If filters are provided (category/difficulty), avoid server-side orderBy('score') to prevent requiring
      // a composite index. Instead, query by equality (fast) and sort/limit client-side.
      bool hasFilter = (category != null && category.isNotEmpty) || (difficulty != null && difficulty.isNotEmpty);
      Query q = _col;
      if (category != null && category.isNotEmpty) q = q.where('category', isEqualTo: category);
      if (difficulty != null && difficulty.isNotEmpty) q = q.where('difficulty', isEqualTo: difficulty);

      if (!hasFilter) {
        // No filters: let server order and limit for efficiency.
        q = q.orderBy('score', descending: true).limit(limit);
       
        final qsnap = await q.get();
        return qsnap.docs.map((d) => LeaderboardEntry.fromMap(d.data() as Map<String, dynamic>)).toList();
      } else {
        // With filters: fetch matching docs, sort by score locally and apply client-side limit.
        final qsnap = await q.get();
        var list = qsnap.docs.map((d) => LeaderboardEntry.fromMap(d.data() as Map<String, dynamic>)).toList();
        list.sort((a, b) {
          final scoreComp = b.score.compareTo(a.score);
          if (scoreComp != 0) return scoreComp;
          return b.createdAt.compareTo(a.createdAt);
        });
        if (list.length > limit) list = list.sublist(0, limit);
        return list;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('Leaderboard fetchTop error: $e\n$st');
      return [];
    }
  }

  // Real-time stream of top scores with optional filters (order by score server-side only)
  static Stream<List<LeaderboardEntry>> streamTop({int limit = 50, String? category, String? difficulty, DateTime? since}) {
    // If filters are provided, avoid server-side orderBy to prevent composite-index requirement.
    bool hasFilter = (category != null && category.isNotEmpty) || (difficulty != null && difficulty.isNotEmpty);
    Query q = _col;
    if (category != null && category.isNotEmpty) q = q.where('category', isEqualTo: category);
    if (difficulty != null && difficulty.isNotEmpty) q = q.where('difficulty', isEqualTo: difficulty);

    // Only use server-side ordering when there are no equality filters.
    if (!hasFilter) {
      q = q.orderBy('score', descending: true).limit(limit);
    }

    return q.snapshots().map((snap) {
      try {
        var list = snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return LeaderboardEntry.fromMap(data);
        }).toList();

        // client-side filter by time window (since) if provided
        if (since != null) {
          final min = since;
          list.retainWhere((e) => e.createdAt.isAfter(min));
        }

        // client-side stable sort: score desc, then createdAt desc
        list.sort((a, b) {
          final scoreComp = b.score.compareTo(a.score);
          if (scoreComp != 0) return scoreComp;
          return b.createdAt.compareTo(a.createdAt);
        });

        // apply client-side limit when we didn't use server-side ordering/limiting
        if (hasFilter && list.length > limit) {
          list = list.sublist(0, limit);
        }

        return list;
      } catch (e, st) {
        // Log and return empty list rather than propagating error to UI
        // ignore: avoid_print
        print('streamTop mapping error: $e\n$st');
        return <LeaderboardEntry>[];
      }
    });
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // No "All" option per request
  final categories = ['psychology', 'language', 'geography'];
  final difficulties = ['easy', 'medium', 'hard'];
  late String selectedCategory = categories.first;
  late String selectedDifficulty = difficulties.first;
  
  // removed null getters - styles/padding are defined in build() for responsiveness

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Widget _rankAvatar(int idx) {
    if (idx == 0) return CircleAvatar(backgroundColor: Colors.amber[700], child: const Icon(Icons.emoji_events, color: Colors.white));
    if (idx == 1) return CircleAvatar(backgroundColor: Colors.grey[400], child: const Icon(Icons.emoji_events, color: Colors.white));
    if (idx == 2) return CircleAvatar(backgroundColor: Colors.brown[400], child: const Icon(Icons.emoji_events, color: Colors.white));
    // idx 3+ : white fill with blue PressStart2P number
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: Text(
        '${idx + 1}',
        style: const TextStyle(fontFamily: 'PressStart2P', color: Colors.blueAccent),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {}); // trigger rebuild / refresh
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    // Responsive layout using LayoutBuilder / MediaQuery
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final shortSide = min(w, h);
      final scale = (shortSide / 600).clamp(0.72, 1.6);

      final edgePadding = 12.0 * scale;
      final gap = 12.0 * scale;
      final chipFont = 10.0 * scale;

      return Scaffold(
        appBar: TopBanner(onBack: () => Navigator.of(context).pop()),
        backgroundColor: Colors.white, // leaderboard background set to white for readability
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: edgePadding, vertical: edgePadding),
          child: Column(
            children: [
              // Dropdown filters row (category + difficulty) — chips removed per request
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: TextStyle(fontFamily: 'PressStart2P', fontSize: 14.0 * scale, color: Colors.black)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.black, fontSize: 12.0 * scale),
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0 * scale, vertical: 8.0 * scale),
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: selectedDifficulty,
                      items: difficulties
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d, style: TextStyle(fontFamily: 'PressStart2P', fontSize: 14.0 * scale, color: Colors.black)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedDifficulty = v!),
                      decoration: InputDecoration(
                        labelText: 'Difficulty',
                        labelStyle: TextStyle(color: Colors.black, fontSize: 12.0 * scale),
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0 * scale, vertical: 8.0 * scale),
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  IconButton(
                    tooltip: 'Clear filters',
                    icon: Icon(Icons.clear, size: 20.0 * scale),
                    onPressed: () => setState(() {
                      selectedCategory = categories.first;
                      selectedDifficulty = difficulties.first;
                    }),
                  )
                ],
              ),

              SizedBox(height: gap),

              // Leaderboard list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: StreamBuilder<List<LeaderboardEntry>>(
                    stream: LeaderboardService.streamTop(
                      limit: 100,
                      category: selectedCategory,
                      difficulty: selectedDifficulty,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0 * scale),
                            child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.0 * scale)),
                          ),
                        );
                      }
 final entries = snapshot.data ?? [];
                      if (entries.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 80.0 * scale),
                            Center(child: Icon(Icons.emoji_events_outlined, size: 64.0 * scale, color: Colors.grey)),
                            SizedBox(height: 12.0 * scale),
                            Center(

                              child: Text(
                                'No scores yet\nBe the first to submit one!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black, fontSize: 14.0 * scale),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(

                        padding: EdgeInsets.symmetric(horizontal: edgePadding, vertical: 8.0 * scale),
                        itemCount: entries.length,
                                               separatorBuilder: (_, __) => SizedBox(height: 8.0 * scale),
                        itemBuilder: (context, idx) {
                          final e = entries[idx];
                          final isTop = idx < 3;
                          final borderSide = isTop
                              ? BorderSide(color: idx == 0 ? Colors.amber[700]! : idx == 1 ? Colors.grey.shade400 : Colors.brown.shade400, width: 2)
                              : BorderSide.none;

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale), side: borderSide),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0 * scale, vertical: 10.0 * scale),
                              child: Row(
                                children: [
                                  _rankAvatar(idx),
                                  SizedBox(width: 12.0 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.name,
                                                                                   style: TextStyle(
                                            fontFamily: 'PressStart2P',
                                            fontSize: 12.0 * scale,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 6.0 * scale),
                                        Wrap(
                                          spacing: 6.0 * scale,
                                          runSpacing: 6.0 * scale,
                                          children: [
                                            Chip(label: Text(e.category, style: TextStyle(fontFamily: 'PressStart2P', fontSize: chipFont, color: Colors.black)), padding: EdgeInsets.symmetric(horizontal: 6.0 * scale)),
                                            Chip(label: Text(e.difficulty, style: TextStyle(fontFamily: 'PressStart2P', fontSize: chipFont, color: Colors.black)), backgroundColor: Colors.blue.shade50, padding: EdgeInsets.symmetric(horizontal: 6.0 * scale)),
                                            Chip(label: Text(e.time, style: TextStyle(fontFamily: 'PressStart2P', fontSize: chipFont, color: Colors.black)), backgroundColor: Colors.grey.shade100, padding: EdgeInsets.symmetric(horizontal: 6.0 * scale)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.0 * scale),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${e.score}', style: TextStyle(fontFamily: 'PressStart2P', fontSize: 16.0 * scale, fontWeight: FontWeight.bold, color: isTop ? Colors.black : Colors.black87)),
                                      SizedBox(height: 6.0 * scale),
                                      Text(_formatDateTime(e.createdAt), style: TextStyle(fontSize: 10.0 * scale, color: Colors.black54)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// Add custom square-notch button shape (chips small square cutouts at corners)
class SquareNotchBorder extends OutlinedBorder {
  final double notchSize;

  const SquareNotchBorder({this.notchSize = 6.0, super.side});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => SquareNotchBorder(notchSize: notchSize * t, side: side);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double n = notchSize.clamp(0.0, min(rect.width, rect.height) / 2);
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;

    return Path()
      ..moveTo(left + n, top)
      ..lineTo(right - n, top)
      ..lineTo(right, top + n)
      ..lineTo(right, bottom - n)
      ..lineTo(right - n, bottom)
      ..lineTo(left + n, bottom)
      ..lineTo(left, bottom - n)
      ..lineTo(left, top + n)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final deflateBy = side.width;
    final innerRect = rect.deflate(deflateBy);
    final double n = notchSize.clamp(0.0, min(innerRect.width, innerRect.height) / 2);
    final left = innerRect.left;
    final top = innerRect.top;
    final right = innerRect.right;
    final bottom = innerRect.bottom;

    return Path()
      ..moveTo(left + n, top)
      ..lineTo(right - n, top)
      ..lineTo(right, top + n)
      ..lineTo(right, bottom - n)
      ..lineTo(right - n, bottom)
      ..lineTo(left + n, bottom)
      ..lineTo(left, bottom - n)
      ..lineTo(left, top + n)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.solid && side.width > 0) {
      final paint = side.toPaint();
      final path = getOuterPath(rect, textDirection: textDirection);
      canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = side.width);
    }
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SquareNotchBorder) {
      final double ns = a.notchSize + (notchSize - a.notchSize) * t;
      final BorderSide s = BorderSide.lerp(a.side, side, t);
      return SquareNotchBorder(notchSize: ns, side: s);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SquareNotchBorder) {
      final double ns = notchSize + (b.notchSize - notchSize) * t;
      final BorderSide s = BorderSide.lerp(side, b.side, t);
      return SquareNotchBorder(notchSize: ns, side: s);
    }
    return super.lerpTo(b, t);
  }

  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return SquareNotchBorder(notchSize: notchSize, side: side ?? this.side);
  }
}

// final shared styles adjusted for chamfered corners
final ButtonStyle mainButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: Colors.blueAccent,
  shape: const SquareNotchBorder(notchSize: 6.0),
  padding: const EdgeInsets.symmetric(vertical: 14),
  textStyle: const TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
);
 
// outlined style for Back buttons retained for any in-body use (visual styling)
final ButtonStyle outlinedBackButtonStyle = OutlinedButton.styleFrom(
  side: const BorderSide(color: Colors.white, width: 2),
  foregroundColor: Colors.white,
  backgroundColor: Colors.transparent,
  shape: const SquareNotchBorder(notchSize: 6.0),
  padding: const EdgeInsets.symmetric(vertical: 14),
  textStyle: const TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
);


