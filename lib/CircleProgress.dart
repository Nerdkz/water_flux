import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CircleProgress extends CustomPainter{

  double currentProgress;

  CircleProgress(this.currentProgress);

  @override
  void paint(Canvas canvas, Size size) {

    //this is base circle
    Paint outerCircle = Paint()
      ..strokeWidth = 15
      ..color = Colors.blueGrey
      ..style = PaintingStyle.stroke;
    Paint completeArc = Paint()
      ..strokeWidth = 15
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2 ) - 15;

    canvas.drawCircle(center, radius, outerCircle); // this draw main outer circle

    double angle = 2 * pi * (currentProgress/15000);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi/2, angle, false, completeArc);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }

}