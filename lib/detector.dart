import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' hide Image;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as im;
import 'package:tflite/tflite.dart';
import 'constants.dart';

class Detector {
  Future loadModel() async {
      Tflite.close();
      await Tflite.loadModel(
          model: "assets/converted_mnist_model.tflite",
          labels: "assets/labels.txt");
  }

  Future<List> processPoints(List<Offset> points) async {
    final recorder = PictureRecorder();
    final canvasSize = kCanvasSize;// + (2 * kCanvasInnerOffset);
    final canvas = Canvas(recorder,
        Rect.fromPoints(Offset(0, 0), Offset(canvasSize, canvasSize)));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize, canvasSize), kBackgroundPaint);

    void paint(Canvas canvas, Size size) {
      for (int i = 0; i < points.length - 1; i++) {
        if (points[i] != null && points[i + 1] != null) {
          canvas.drawLine(points[i], points[i + 1], kWhitePaint);
        }
      }
    }

    paint(canvas, Size(200, 200));

    final picture = recorder.endRecording();
    final img = await picture.toImage(

      canvasSize.toInt(),
      canvasSize.toInt(),
    );
    final imgBytes = await img.toByteData(format: ImageByteFormat.png);
    Uint8List pngUint8List = imgBytes.buffer.asUint8List();

    // There's quite a funny game at this point. The image class we are using doesn't allow resizing.
    // In order to achieve that, we need to convert it to another image class that we are importing
    // as 'im' from package:image/image.dart
    im.Image imImage = im.decodeImage(pngUint8List);
    im.Image resizedImage = im.copyResize(
      imImage,
      width: kModelInputSize,
      height: kModelInputSize,
    );

    // Finally, we can return our the prediction we will perform over that
    // resized image
    return predictImage(resizedImage);
  }

  Future<List> predictImage(im.Image image) async {
    return await Tflite.runModelOnBinary(
      binary: imageToByteListFloat32(image, kModelInputSize),
    );
  }

  Uint8List imageToByteListFloat32(im.Image image, int inputSize) {
    var convertedBytes = Float32List(inputSize * inputSize);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] =
            (im.getRed(pixel) + im.getGreen(pixel) + im.getBlue(pixel)) /
                3 /
                255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  double convertPixel(int color) {
    return (255 -
            (((color >> 16) & 0xFF) * 0.299 +
                ((color >> 8) & 0xFF) * 0.587 +
                (color & 0xFF) * 0.114)) /
        255.0;
  }
}
