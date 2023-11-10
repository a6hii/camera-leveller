import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

class NewCameraView extends ConsumerStatefulWidget {
  final CameraController a;
  const NewCameraView({
    super.key,
    required this.a,
  });

  @override
  ConsumerState<NewCameraView> createState() => _NewCameraViewState();
}

class _NewCameraViewState extends ConsumerState<NewCameraView> {
  int x = 0;
  int y = 0;
  bool isVertical = false;
  double xDotPosition = 0;
  double yDotPosition = 0;
  double filteredX = 0.0;
  double filteredY = 0.0;
  bool isCorrectLevel = false;
  var badColors = [
    Colors.red,
    Colors.redAccent,
  ];
  int a = 0;
  var correctColors = [
    Colors.green,
    Colors.greenAccent,
  ];
  static const double alpha = 0.8;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        final double scaledV1Position =
            (MediaQuery.of(context).size.height / 2 - 50) /
                MediaQuery.of(context).size.height;
        const double threshold = 0.1; // Set a proper threshold for comparison

        bool isAlignedWithV1 =
            (xDotPosition - scaledV1Position).abs() < threshold;

        x = calculateXValue(event);
        y = calculateYValue(event);
        isCorrectLevel = (x == 0 && x == y);
        filteredX = lowPassFilter(filteredX, event.x);
        filteredY = lowPassFilter(filteredY, event.y);
        isVertical = event.y < 5.5 && event.y > -5;
        xDotPosition = getXDotPosition(filteredX);
        print("objecty:: ${isVertical} ${event.y}  ${event.x}  ${event.z}");
        yDotPosition = getYDotPosition(filteredY);
        // print(((event.y * 10).round()));
      });
    });
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  double getXDotPosition(double xValue) {
    if (isCorrectLevel) {
      return 0;
    }
    return xValue;
  }

  double getYDotPosition(double yValue) {
    if (isCorrectLevel) {
      return 0;
    }
    return yValue;
  }

  // Low-pass filter function
  double lowPassFilter(double output, double input) {
    return alpha * output + (1 - alpha) * input;
  }

  int calculateYValue(AccelerometerEvent event) {
    return (event.y * 10).round();
  }

  int calculateXValue(AccelerometerEvent event) {
    return (event.x * 10 - 2).round();
  }

  @override
  void dispose() {
    widget.a.dispose();
    accelerometerEvents.listen((event) {}).cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(
          widget.a,
        ),
        // RotatedDivider(
        //   color: getVBackgroundColor(),
        //   thickness: 1,
        //   isVertical: isVertical,
        // ),
        isVertical
            ? Center(
                key: const Key("V1"),
                child: VerticalDivider(
                  color: getVBackgroundColor(),
                  thickness: 1,
                  indent: 0,
                  endIndent: (MediaQuery.sizeOf(context).height / 2) + 50,
                ),
              )
            : Center(
                key: const Key("H1"),
                child: Divider(
                  color: getHBackgroundColor(),
                  thickness: 1,
                  indent: 0,
                  endIndent: (MediaQuery.sizeOf(context).width / 2) + 50,
                ),
              ),
        isVertical
            ? Center(
                key: const Key("V2"),
                child: VerticalDivider(
                  color: getVBackgroundColor(),
                  thickness: 1,
                  indent: (MediaQuery.sizeOf(context).height / 2) + 50,
                  endIndent: 0,
                ),
              )
            : Center(
                key: const Key("H2"),
                child: Divider(
                  color: getHBackgroundColor(),
                  thickness: 1,
                  indent: (MediaQuery.sizeOf(context).width / 2) + 50,
                  endIndent: 0,
                ),
              ),

        Center(
          child: CustomPaint(
            size: const Size(200, 200), // Adjust size as needed
            painter: LinePainter(xDotPosition, yDotPosition,
                isVertical ? getVBackgroundColor() : getHBackgroundColor()),
          ),
        ),
        // if (getHBackgroundColor() == Colors.green ||
        //     getVBackgroundColor() == Colors.green)
        if (a == 1)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(onPressed: () {}),
            ),
          ),
      ],
    );
  }

// This method checks if the LinePainter line is aligned with the vertical lines
  bool isLineAlignedWithVerticalLine(double lineX, double verticalX) {
    // Set a threshold for alignment, e.g., 5 units on either side for a match
    return (lineX >= verticalX - 50 && lineX <= verticalX + 50);
  }

  Color getVBackgroundColor() {
    // Get the current X position of the LinePainter line
    double lineX =
        yDotPosition * 100 + (MediaQuery.of(context).size.height / 2);

    // Get the X positions of the vertical lines
    double verticalLineX1 = MediaQuery.of(context).size.height / 2;
    // Check if LinePainter line is aligned with the vertical lines
    bool isAlignedWithV1 = isLineAlignedWithVerticalLine(lineX, verticalLineX1);
    // Change the color of the VerticalDivider widgets when aligned with LinePainter
    if (isAlignedWithV1) {
      print("isAlignedWithV1: $isAlignedWithV1");
      setState(() {
        a = 1;
      });
      return Colors.greenAccent; // Change color for V1
    } else {
      setState(() {
        a = 0;
      });
      // print("bad: $isAlignedWithV1");
      return Colors.white; // Default color
    }
  }

  Color getHBackgroundColor() {
    // Get the current X position of the LinePainter line
    double lineX = xDotPosition * 100 + (MediaQuery.of(context).size.width / 2);

    // Get the X positions of the vertical lines
    double verticalLineX1 = MediaQuery.of(context).size.width / 2;
    // Check if LinePainter line is aligned with the vertical lines
    bool isAlignedWithV1 = isLineAlignedWithVerticalLine(lineX, verticalLineX1);
    // Change the color of the VerticalDivider widgets when aligned with LinePainter
    if (isAlignedWithV1) {
      print("isAlignedWithV1: $isAlignedWithV1");
      setState(() {
        a = 1;
      });
      return Colors.greenAccent; // Change color for V1
    } else {
      // print("bad: $isAlignedWithV1");
      setState(() {
        a = 0;
      });
      return Colors.white; // Default color
    }
  }
}

class LinePainter extends CustomPainter {
  final double xPosition;
  final double yPosition;
  final Color color;

  LinePainter(
    this.xPosition,
    this.yPosition,
    this.color,
  );

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Calculate the center of the screen
    final center = Offset(size.width / 2, size.height / 2);

    // Calculate the start and end points for the line
    final magnitude = sqrt(xPosition * xPosition + yPosition * yPosition);
    final normalizedX = xPosition / magnitude;
    final normalizedY = yPosition / magnitude;

    // Calculate the start and end points for the line
    final lineLength = 50.0; // Set the desired length of the line
    final startX = center.dx - (normalizedX * lineLength);
    final startY = center.dy - (normalizedY * lineLength);
    final endX = center.dx + (normalizedX * lineLength);
    final endY = center.dy + (normalizedY * lineLength);
    Offset start = Offset(startY, startX);
    Offset end = Offset(endY, endX);

    canvas.drawLine(start, end, paint);

    // Draw a vertical line through the center
    canvas.drawLine(
      Offset(center.dx, center.dy - 4.58), // Adjust the length as needed
      Offset(center.dx, center.dy + 4.58), // Adjust the length as needed
      paint..strokeWidth = 0.8,
    );
    // Draw a small circle at the center point
    Paint dotPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class RotatedDivider extends StatelessWidget {
  final Color color;
  final double thickness;
  final bool isVertical;

  RotatedDivider({
    required this.color,
    required this.thickness,
    required this.isVertical,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle:
          isVertical ? 0 : -pi / 2, // Rotate 90 degrees for horizontal dividers
      child: Divider(
        thickness: thickness,
        color: color,
        height: isVertical
            ? MediaQuery.sizeOf(context).width
            : MediaQuery.sizeOf(context).width,
        indent: 0,
        endIndent: 0,
      ),
    );
  }
}
