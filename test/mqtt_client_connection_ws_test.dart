/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'mqtt_client_mockbroker.dart';

/// Don't run some tests on Travis, easier to do this than find out why they
/// run locally on both windows and linux but not on Travis
bool skipIfTravis() {
  bool ret = false;
  final Map<String, String> envVars = Platform.environment;
  if (envVars['TRAVIS'] == 'true') {
    // Skip
    ret = true;
  }
  return ret;
}

void main() {
  // Test wide variables
  final MockBrokerWs brokerWs = new MockBrokerWs();
  final String mockBrokerAddressWs = "ws://localhost/ws";
  final String mockBrokerAddressWsNoScheme = "localhost.com";
  final String mockBrokerAddressWsBad = "://localhost.com";
  final int mockBrokerPortWs = 8080;
  final String testClientId = "syncMqttTests";

  group("Connection parameters", () {
    test("Invalid URL", () async {
      try {
        final SynchronousMqttConnectionHandler ch =
        new SynchronousMqttConnectionHandler();
        ch.useWebSocket = true;
        await ch.connect(mockBrokerAddressWsBad, mockBrokerPortWs,
            new MqttConnectMessage().withClientIdentifier(testClientId));
      } catch (e) {
        expect(e is NoConnectionException, true);
        expect(
            e.toString(),
            "mqtt-client::NoConnectionException: "
                "MqttWsConnection::The URI supplied for the WS connection is not valid - ://localhost.com");
      }
    });

    test("Invalid URL - bad scheme", () async {
      try {
        final SynchronousMqttConnectionHandler ch =
        new SynchronousMqttConnectionHandler();
        ch.useWebSocket = true;
        await ch.connect(mockBrokerAddressWsNoScheme, mockBrokerPortWs,
            new MqttConnectMessage().withClientIdentifier(testClientId));
      } catch (e) {
        expect(e is NoConnectionException, true);
        expect(
            e.toString(),
            "mqtt-client::NoConnectionException: "
                "MqttWsConnection::The URI supplied for the WS has an incorrect scheme - $mockBrokerAddressWsNoScheme");
      }
    });
  }, skip: false);

  group("Connection Keep Alive - Mock broker WS", () {
    test("Successful response WS", () async {
      int expectRequest = 0;

      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final MqttConnectAckMessage ack = new MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        brokerWs.sendMessage(ack);
      }

      void messageHandlerPingRequest(typed.Uint8Buffer messageArrived) {
        final MqttByteBuffer headerStream = new MqttByteBuffer(messageArrived);
        final MqttHeader header = new MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
              "WS Connection Keep Alive - Successful response - Ping Request received $expectRequest");
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      await brokerWs.start();
      final SynchronousMqttConnectionHandler ch =
      new SynchronousMqttConnectionHandler();
      ch.useWebSocket = true;
      brokerWs.setMessageHandler(messageHandlerConnect);
      await ch.connect(mockBrokerAddressWs, mockBrokerPortWs,
          new MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionState, ConnectionState.connected);
      brokerWs.setMessageHandler(messageHandlerPingRequest);
      final MqttConnectionKeepAlive ka = new MqttConnectionKeepAlive(ch, 2);
      print(
          "WS Connection Keep Alive - Successful response - keepealive ms is ${ka
              .keepAlivePeriod}");
      print(
          "WS Connection Keep Alive - Successful response - ping timer active is ${ka
              .pingTimer.isActive.toString()}");
      final Stopwatch stopwatch = new Stopwatch()
        ..start();
      await MqttUtilities.asyncSleep(10);
      print("WS Connection Keep Alive - Successful response - Elapsed time "
          "is ${stopwatch.elapsedMilliseconds / 1000} seconds");
      ka.stop();
      ch.close();
    });
  }, skip: skipIfTravis());
}
