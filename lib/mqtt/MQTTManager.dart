import 'package:flutter/cupertino.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:waterflux/mqtt/state/MQTTAppState.dart';

class MQTTManager{

  /// Private instance of client
  MQTTAppState _currentState;
  MqttClient _client;
  String _identifier;
  String _host;
  String _topic;

  // Constructor
  MQTTManager({
    @required String host,
    @required String topic,
    @required String identifier,
    @required MQTTAppState state
  }): _identifier = identifier, _host = host, _topic = topic, _currentState = state;

  void initializeMQTTClient(){

    _client = MqttClient(_host, _identifier);
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = onDisconnected;
    //_client.autoReconnect = true;
    _client.logging(on: true);

    // Add the successful connection callback
    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;

    final MqttConnectMessage connectMessage = MqttConnectMessage()
      .withClientIdentifier(_identifier)
      .withWillTopic('test') // if you set this you must set a will message
      .withWillMessage("lamhx message test")
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
    print('Client Connecting.....');
    _client.connectionMessage = connectMessage;

  }

  /// Connect to the host
  void connect() async{

    // TODO Assert if client is not null
    assert( _client != null );

    try{

      print('Start client connecting......');
      _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    }on Exception catch (e){

      print('Client exception - $e' );
      disconnect();
    }
  }

  void disconnect(){

    print('Disconected');
    _client.disconnect();
  }

  void publish(String message){

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload);
  }

  /// The subscribed callback
  void onSubscribed(String topic){

    print('Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected(){

    print('OnDisconnected client callback - Client disconnection');

    if(_client.connectionStatus.returnCode == MqttConnectReturnCode.solicited){
      print('OnDisconnected callback is solicited, this is correct');
    }
  }

  /// The successful connect callback
  void onConnected(){
    _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    print('Client connected.....');
    _client.subscribe(_topic, MqttQos.atLeastOnce);
    try {
      _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c){

        final MqttPublishMessage recMess = c[0].payload;
        final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        _currentState.setReceivedText(pt);

        /// The above may seem a little convoluted for users only interested in the
        /// payload, some users however may be interested in the received publish message,
        /// lets not constrain ourselves yet until the package has been in the wild
        /// for a while.
        /// The payload is a byte buffer, this will be specific to the topic

        print('Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
        print('');
      });
      print('OnConnected client callback - Client connection was successful');
    } catch (e, s) {
      print(s);
    }
  }

}