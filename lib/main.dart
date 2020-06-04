import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'CircleProgress.dart';

void main() async {
  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin{

  PageController _pageController;
  int _page = 0;

  double _progress = 100;
  AnimationController progressController;
  Animation<double> animation;

  // Brokker configurations

//  String titleBar = 'MQTT';
  String broker = 'm16.cloudmqtt.com';
  int port = 10397;
  String username = 'zeydwrgb';
  String passwd = 'S-8dPLb9DgID';
  String clientIdentifier = 'vinicius';

//  String broker = 'tailor.cloudmqtt.com';
//  int port = 12027;
//  String username = 'tajuanfa';
//  String passwd = '9CpBKnFY-_5o';
//  String clientIdentifier = 'vinicius';

  mqtt.MqttClient client;
  mqtt.MqttConnectionState connectionState;

  final _formKey = GlobalKey<FormState>();

  StreamSubscription subscription;

  String topic = 'cmd'; // topic for comands
  Set<String> topics = Set<String>();
  String _fluxReading = '';

  @override
  void initState() {
    _connect();
    _pageController = PageController();
    super.initState();
    progressController = AnimationController(vsync: this, duration: Duration(milliseconds: 5000));
    animation = Tween<double>(begin: 0, end: _progress).animate(progressController)..addListener((){
      setState(() {

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    void navigationTapped(int page) {
      _pageController.animateToPage(page,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }

    void onPageChanged(int page) {
      setState(() {
        this._page = page;
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Water Flux",
          style: TextStyle(
              fontSize: 20, fontStyle: FontStyle.normal, color: Colors.white),
        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: navigationTapped,
        currentIndex: _page,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            title: Text('Consumos'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.power_settings_new),
            title: Text('Bomba'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            title: Text('Leituras'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: <Widget>[
          _buildConsumptionPage(),
          _buildPumpPage(),
          //_buildMessagesPage(),
        ],
      ),
    );
  }

  Column _buildConsumptionPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CustomPaint(
          foregroundPainter: CircleProgress(animation.value),
          child: Container(
            width: 200,
            height: 200,
            child: GestureDetector(
              onTap: (){
                if(animation.value == _progress){
                  progressController.reverse();
                }else{
                  progressController.forward();
                }
              },
              child: Center(
                child: Text(
                    "${animation.value.toInt()}%",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Column _buildPumpPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 250),
                child: RaisedButton(
                  child: Text(
                    "ON",
                    style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  color: Colors.green,
                  onPressed: () {
                    _sendMessage("ON");
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 250),
                child: RaisedButton(
                  child: Text(
                    "OFF",
                    style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  color: Colors.red,
                  onPressed: () {
                    _sendMessage("OFF");
                  },
                ),
              ),
            ],
          )
        ),

      ],
    );
  }

  void _connect() async {
    /// First create a client, the client is constructed with a broker name, client identifier
    /// and port if needed. The client identifier (short ClientId) is an identifier of each MQTT
    /// client connecting to a MQTT broker. As the word identifier already suggests, it should be unique per broker.
    /// The broker uses it for identifying the client and the current state of the client. If you don’t need a state
    /// to be hold by the broker, in MQTT 3.1.1 you can set an empty ClientId, which results in a connection without any state.
    /// A condition is that clean session connect flag is true, otherwise the connection will be rejected.
    /// The client identifier can be a maximum length of 23 characters. If a port is not specified the standard port
    /// of 1883 is used.
    /// If you want to use websockets rather than TCP see below.
    ///
    client = mqtt.MqttClient(broker, '');
    client.port = port;

    /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
    /// for details.
    /// To use websockets add the following lines -:
    /// client.useWebSocket = true;
    /// client.port = 80;  ( or whatever your WS port is)
    /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.
    /// Set logging on if needed, defaults to off
    client.logging(on: true);

    /// If you intend to use a keep alive value in your connect message that is not the default(60s)
    /// you must set it here
    client.keepAlivePeriod = 20;

    /// Add the unsolicited disconnection callback
    client.onDisconnected = _onDisconnected;

    /// Add successful conection callback
    client.onConnected = _onConeccted;

    client.onSubscribed = _subscribeToTopic;

    client.pongCallback = pong;

    /// Create a connection message to use or use the default one. The default one sets the
    /// client identifier, any supplied username/password, the default keepalive interval(60s)
    /// and clean session, an example of a specific one below.
    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        // Must agree with the keep alive set above or not set
        .startClean() // Non persistent session for testing
        .keepAliveFor(20)
        // If you set this you must set a will message
        .withWillTopic('test/test')
        .withWillMessage('lamhx message test')
        .withWillQos(mqtt.MqttQos.atLeastOnce);
    print('MQTT client connecting....');
    client.connectionMessage = connMess;

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.

    try {
      await client.connect(username, passwd);
    } catch (e) {
      print(e);
      client.disconnect();
    }

    /// Check if we are connected
    if (client.connectionStatus.state == mqtt.MqttConnectionState.connected) {
      print('MQTT client connected');
      setState(() {
        connectionState = client.connectionStatus.state;
        print('Conectado!!!');
        _subscribeToTopic("consumo");
      });
    } else {
      print('ERROR: MQTT client connection failed - '
          'disconnecting, state is ${client.connectionStatus.state}');
      client.disconnect();
    }

    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    subscription = client.updates.listen(_onMessage);
  }

  void _onConeccted() {
    print('Status: $client.connectionStatus.state');
  }

  void pong() {
    print('EXAMPLE::Ping response client callback invoked');
  }

  void _disconnect() {
    client.disconnect();
  }

  void _onDisconnected() {
    setState(() {
      connectionState = client.connectionStatus.state;
      client = null;
      subscription.cancel();
      subscription = null;
    });
    print('MQTT client disconnected');
  }

  void _onMessage(List<mqtt.MqttReceivedMessage> event) {
    print(event.length);
    final mqtt.MqttPublishMessage recMess =
        event[0].payload as mqtt.MqttPublishMessage;
    final String message =
        mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic
    print('MQTT message: topic is <${event[0].topic}>, '
        'payload is <-- ${message} -->');
    print(client.connectionStatus.state);
    setState(() {
      print('Mensagem => $message');
      _fluxReading = message;
    });
  }

  void _subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      setState(() {
        if (topics.add(topic.trim())) {
          print('Subscribing to ${topic.trim()}');
          client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
        }
      });
    }
  }

  void _unsubscribeFromTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      setState(() {
        if (topics.remove(topic.trim())) {
          print('Unsubscribing from ${topic.trim()}');
          client.unsubscribe(topic);
        }
      });
    }
  }

  void _sendMessage(String comand) {
    final mqtt.MqttClientPayloadBuilder builder =
        mqtt.MqttClientPayloadBuilder();

    builder.addString(comand);
    client.publishMessage(
      topic,
      mqtt.MqttQos.exactlyOnce,
      builder.payload,
      retain: false,
    );
  }
}
