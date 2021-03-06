/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Entity that captures data related to an individual subscription
class Subscription extends Object with Observable {
  /// The message identifier assigned to the subscription
  int messageIdentifier;

  /// The time the subscription was created.
  DateTime createdTime;

  /// The Topic that is subscribed to.
  SubscriptionTopic topic;

  /// The QOS level of the topics subscription
  MqttQos qos;

  /// The observable that receives messages from the broker.
  ChangeNotifier<MqttReceivedMessage> observable;
}
