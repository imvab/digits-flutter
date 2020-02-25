import 'package:flutter/material.dart';
import 'constants.dart';
import 'paint.dart';
import 'detector.dart';

class RecognizerScreen extends StatefulWidget {
  RecognizerScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _RecognizerScreen createState() => _RecognizerScreen();
}

class _RecognizerScreen extends State<RecognizerScreen> {
  List<Offset> points = List();
  List preds = List();
  Detector brain = Detector();

  void _cleanDrawing() {
    setState(() {
      points = List();
    });
  }

  @override
  void initState() {
    super.initState();
    brain.loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("DIGITS")),
        //backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 30),
            ),
            Row(
              children: <Widget>[
                Container(
                  decoration: new BoxDecoration(
                    border: new Border.all(
                      width: 3.0,
                      color: Colors.blue,
                    ),
                  ),
                  child: Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            RenderBox renderBox = context.findRenderObject();
                            points.add(renderBox
                                .globalToLocal(details.globalPosition));
                          });
                        },
                        onPanStart: (details) {
                          setState(() {
                            RenderBox renderBox = context.findRenderObject();
                            points.add(renderBox
                                .globalToLocal(details.globalPosition));
                          });
                        },
                        onPanEnd: (details) async {
                          points.add(null);
                          preds = await brain.processPoints(points);
                          print(preds[0]["confidence"]);
                          setState(() {});
                        },
                        child: ClipRect(
                          child: CustomPaint(
                            size: Size(kCanvasSize, kCanvasSize),
                            painter: DrawingPainter(
                              offsetPoints: points,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 150),
            ),
            Center(child: 
              Text("The Number is " + preds.toString(), style: TextStyle(fontSize: 40),)
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _cleanDrawing();
        },
        tooltip: 'Clean',
        child: Icon(Icons.delete),
      ),
    );
  }
}
