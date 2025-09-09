import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.blueAccent,
        body: Center(
          child: RevealCardGrid(),
        ),
      ),
    );
  }
}

class RevealCardGrid extends StatefulWidget {
  const RevealCardGrid({super.key});

  @override
  State<RevealCardGrid> createState() => _RevealCardGridState();
}

class _RevealCardGridState extends State<RevealCardGrid> {
  late List<String> values;
  late List<bool> revealed;
  late List<bool> matched;
  List<int> selectedIndices = [];

  @override
  void initState() {
    super.initState();
    values = [
      'assets/images/1.png', 'assets/images/1.png',
      'assets/images/2.png', 'assets/images/2.png',
      'assets/images/3.png', 'assets/images/3.png',
      'assets/images/4.png', 'assets/images/4.png',
      'assets/images/5.png', 'assets/images/5.png',
      '6', '6', '7', '7', '8', '8', '9', '9', '10', '10',
      '11', '11', '12', '12', '13', '13', '14', '14', '15', '15'
    ];
    values.shuffle();
    revealed = List.generate(values.length, (_) => false);
    matched = List.generate(values.length, (_) => false);
  }

  void onCardTap(int index) async {
    if (revealed[index] || matched[index] || selectedIndices.length == 2) return;
    setState(() {
      revealed[index] = true;
      selectedIndices.add(index);
    });
    if (selectedIndices.length == 2) {
      int first = selectedIndices[0];
      int second = selectedIndices[1];
      if (values[first] == values[second]) {
        setState(() {
          matched[first] = true;
          matched[second] = true;
          selectedIndices.clear();
        });
      } else {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          revealed[first] = false;
          revealed[second] = false;
          selectedIndices.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 700, // Increased height to fit all 30 cards
      child: GridView.count(
        crossAxisCount: 6,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(values.length, (index) {
          return RevealCard(
            value: values[index],
            revealed: revealed[index] || matched[index],
            matched: matched[index],
            onTap: () => onCardTap(index),
          );
        }),
      ),
    );
  }
}

class RevealCard extends StatelessWidget {
  final String value;
  final bool revealed;
  final bool matched;
  final VoidCallback onTap;
  const RevealCard({super.key, required this.value, required this.revealed, required this.matched, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              return Transform(
                transform: Matrix4.rotationY(tilt),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        layoutBuilder: (widget, list) => Stack(children: [widget!, ...list]),
        child: revealed
            ? Opacity(
                opacity: matched ? 0.6 : 1.0,
                child: Container(
                  key: const ValueKey(true),
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    child: SizedBox(
                      width: 120,
                      height: 80,
                      child: Center(
                        child: value.endsWith('.png')
                            ? Image.asset(
                                value,
                                fit: BoxFit.contain,
                                width: 60,
                                height: 60,
                              )
                            : Text(
                                value,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.blueAccent,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                key: const ValueKey(false),
                child: Card(
                  color: Colors.white,
                  elevation: 8,
                  child: SizedBox(
                    width: 120,
                    height: 80,
                    child: Center(
                      child: const Text(
                        '?',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
