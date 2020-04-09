import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Water Flux",
          style: TextStyle(
            fontSize: 20,
            fontStyle: FontStyle.normal,
            color: Colors.white
          ),

        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16),
          //width: double.infinity,
          /*
          decoration: BoxDecoration(
            border: Border.all(width: 3, color: Colors.amber),
          ),
           */
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Dados do MQTT",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontStyle: FontStyle.normal,
                  color: Colors.blueGrey,
                ),
              ),
              RaisedButton(
                child: Text(
                  "publish",
                  style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                  ),
                ),

                color: Colors.lightBlueAccent,
                onPressed: (){
                  print("Botão Precionado!!");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
