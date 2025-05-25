import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


class YearlyLineChart extends StatefulWidget {

  final Map<int,int> monthlyValues;
  final int xTitlesInterval;
  final int yTitlesInterval;
  final String xTitle;
  final String yTitle;


  const YearlyLineChart({required this.monthlyValues,
    this.xTitlesInterval = 5, this.yTitlesInterval = 5,
    this.xTitle = '', this.yTitle = '',
    super.key});


  @override
  State<YearlyLineChart> createState() => _YearlyLineChartState();
}

class _YearlyLineChartState extends State<YearlyLineChart> {
  List<Color> gradientColors = [
    Colors.teal,
    Colors.blue,
  ];

  bool showAvg = false;
  double charMaxY = 10;

  @override
  Widget build(BuildContext context) {
    charMaxY = calculateRoundedMaxY(widget.monthlyValues);

    return Stack(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 44,
              bottom: 12,
            ),
            child: LineChart(
              // swapAnimationDuration: 700.ms,
              // swapAnimationCurve: Curves.easeInBack,
              showAvg ? avgData() : mainData(),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          height: 34,
          child: TextButton(
            onPressed: () {
              setState(() {
                showAvg = !showAvg;
              });
            },
            child: Text(widget.yTitle,
              style: TextStyle(
                fontSize: 12,
                color: showAvg ? Colors.white.withOpacity(0.5) : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget monthsBottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = const Text('Ene', style: style);
        break;
      case 2:
        text = const Text('Feb', style: style);
        break;
      case 3:
        text = const Text('Mar', style: style);
        break;
      case 4:
        text = const Text('Abr', style: style);
        break;
      case 5:
        text = const Text('May', style: style);
        break;
      case 6:
        text = const Text('Jun', style: style);
        break;
      case 7:
        text = const Text('Jul', style: style);
        break;
      case 8:
        text = const Text('Ago', style: style);
        break;
      case 9:
        text = const Text('Sep', style: style);
        break;
      case 10:
        text = const Text('Oct', style: style);
        break;
      case 11:
        text = const Text('Nov', style: style);
        break;
      case 12:
        text = const Text('Dic', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      meta: meta,
      child: text,
    );
  }

  // Eje izquierdo: se muestran los valores en miles (K) usando el maxY calculado.
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    // No mostramos etiqueta para el cero.
    if (value == 0) return Container();

    return Text(formatYAxisLabel(value), style: style, textAlign: TextAlign.left);
  }

  LineChartData mainData() {
    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
      ),
      baselineX: 2,
      baselineY: 2,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.teal,
            strokeWidth: 0,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.pink,
            strokeWidth: 0,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: monthsBottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: charMaxY/widget.yTitlesInterval,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: 12,
      minY: 0,
      maxY: charMaxY,
      lineBarsData: [
        setLineChartBarData(),
        //TODO Add functionality to add more LineChartBarData to compare items stas
      ],
    );
  }

  LineChartBarData setLineChartBarData() {
    // Creamos una lista de FLSpot de manera dinámica:
    List<FlSpot> spots = buildFlSpots();

    return LineChartBarData(
        spots: spots,
        isCurved: true,
        gradient: LinearGradient(
          colors: gradientColors,
        ),
        barWidth: 5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          ),
        ),
      );
  }

  List<FlSpot> buildFlSpots() {
    // Creamos una lista de FLSpot de manera dinámica:
    List<FlSpot> spots = [];

    // Recorrer cada mes del 1 al 12
    for (int month = 1; month <= 12; month++) {
      // Obtenemos el valor para el mes, si no existe se asigna 0.
      double y = widget.monthlyValues[month]?.toDouble() ?? 0.0;
      spots.add(FlSpot(month.toDouble(), y));
    }
    return spots;
  }

  LineChartData avgData() {
    List<FlSpot> spots = buildFlSpots();
    return LineChartData(
      lineTouchData: LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        verticalInterval: 1,
        horizontalInterval: 1,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 0,
          );
        },
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 0,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: monthsBottomTitleWidgets,
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
            interval: 1,
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: false,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: 12,
      minY: 0,
      maxY: calculateMaxY(widget.monthlyValues),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!,
            ],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!.withOpacity(0.1),
                ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double calculateMaxY(Map<int, int> data) {
    if (data.isEmpty) return 10.0; // Valor por defecto si el mapa está vacío.

    // Se obtiene el valor máximo del mapa.
    int maxValue = data.values.reduce((a, b) => a > b ? a : b);

    // Calculamos maxY de modo que maxValue sea el 75% de maxY.
    double maxY = maxValue / 0.75;
    return maxY;
  }


  // double calculateRoundedMaxY(Map<int, int> data) {
  //   double maxY = calculateMaxY(data);
  //   // Redondea al millar cerrado más cercano.
  //   return (maxY / 1000).round() * 1000.0;
  // }

  String formatYAxisLabel(double value) {
    // Si el valor es 1 millón o más:
    if (value >= 1e6) {
      return "${(value / 1e6).toStringAsFixed(0)}M";
    }
    // Si el valor es 1,000 o más:
    else if (value >= 1e3) {
      return "${(value / 1e3).toStringAsFixed(0)}K";
    } else {
      return value.toStringAsFixed(0);
    }
  }

  double niceNumber(double value, bool round) {
    // Obtiene la potencia de 10 menor o igual a value.
    double exponent = pow(10, value.log10().floor()).toDouble();
    double fraction = value / exponent;
    double niceFraction;

    if (round) {
      if (fraction < 1.5) {
        niceFraction = 1;
      } else if (fraction < 3) {
        niceFraction = 2;
      } else if (fraction < 7) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    } else {
      if (fraction <= 1) {
        niceFraction = 1;
      } else if (fraction <= 2) {
        niceFraction = 2;
      } else if (fraction <= 5) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    }

    return niceFraction * exponent;
  }

  // Para obtener un charMaxY redondeado de forma "bonita":
  double calculateRoundedMaxY(Map<int, int> data) {
    double maxY = calculateMaxY(data);
    // Puedes elegir redondear a un "nice number" o a un múltiplo específico.
    return niceNumber(maxY, true);
  }

// Calcula el intervalo "bonito" dividiendo charMaxY en 5 partes.
  double calculateInterval(double maxY, int divisions) {
    double rawInterval = maxY / divisions;
    return niceNumber(rawInterval, true);
  }

}

// Método de extensión para calcular el logaritmo base 10 de un double.
extension Log10 on double {
  double log10() => log(this) / log(10);
}
