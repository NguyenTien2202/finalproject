import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ChartConfig {
  final String title;
  final List<ChartLine> lines;

  ChartConfig({
    required this.title,
    required this.lines,
  });

  @override
  String toString() => 'ChartConfig(title: $title, lines: $lines)';
}

class ChartLine {
  // Item name, i.e 'Electricity'
  final String name;
  // Color decoration
  final Color color;
  // Badge icon
  final Widget icon;
  // Value for chart percentage. i.e: 10.0
  final double value;
  // Display value, i.e '10%'
  final String valueDisplay;

  ChartLine(
      {required this.icon,
      required this.value,
      required this.name,
      required this.valueDisplay,
      required this.color});

  @override
  String toString() {
    return 'ChartLine(icon: $icon, value: $value, title: $name, color: $color)';
  }
}

class PieChartScreen extends StatelessWidget {
  final ChartConfig config;

  const PieChartScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFdcecca),
        ),
        body: Center(
          child: Column(
            children: [
              const Gap(72),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  config.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(child: PieChartContent(config: config)),
            ],
          ),
        ));
  }
}

class PieChartContent extends StatefulWidget {
  const PieChartContent({super.key, required this.config});

  final ChartConfig config;

  @override
  State<PieChartContent> createState() => _PieChartContentState();
}

class _PieChartContentState extends State<PieChartContent> {
  int touchedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.black;
    const inactiveColor = Colors.black38;
    final lines = widget.config.lines;
    return AspectRatio(
      aspectRatio: 1.3,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: showingSections(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  lines.length,
                  (index) => Indicator(
                        color: lines[index].color,
                        text: lines[index].name,
                        isSquare: false,
                        size: touchedIndex == index ? 18 : 16,
                        textColor:
                            touchedIndex == index ? activeColor : inactiveColor,
                      )),
            ),
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final lines = widget.config.lines;
    return List.generate(lines.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final entry = lines[i];
      return PieChartSectionData(
        color: entry.color,
        value: entry.value,
        title: entry.valueDisplay,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
          shadows: shadows,
        ),
        badgeWidget: _Badge(
          entry.icon,
          size: widgetSize,
          borderColor: Colors.black,
        ),
        badgePositionPercentageOffset: .98,
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.icon, {
    required this.size,
    required this.borderColor,
  });
  final Widget icon;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: icon,
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
        )
      ],
    );
  }
}

// Return percentage display given list of values
List<String> convertPercentage(List<double> numbers) {
  final out = <String>[];
  double total = numbers.fold(0, (acc, value) => acc + value);
  double sumBeforeLast = 0;
  for (int i = 0; i < numbers.length - 1; i++) {
    double percentage = numbers[i] * 100;
    sumBeforeLast += percentage;
    out.add(percentage.toStringAsFixed(2));
  }
  return out..add((total - sumBeforeLast).toStringAsFixed(2));
}
