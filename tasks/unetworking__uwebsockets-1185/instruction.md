The pub/sub topic functionality should support publishing a message to all subscribers of a topic except the publishing sender, and this behavior must be consistent across normal publishes and wildcard/intersection topic matching.

Currently, when publishing with a non-null sender, the sender may still receive its own published message (or sender-exclusion is not correctly applied in all publish paths). This breaks the expected semantics that a publisher can broadcast to a topic while excluding itself.

Update the topic publish API so that when calling `uWS::TopicTree::publish(topic, data, sender)` with `sender != nullptr`, the message is delivered to every subscriber of `topic` except `sender`. When `sender == nullptr`, the message must be delivered to all subscribers.

This sender-exclusion must hold in these scenarios:

- Publishing to a topic with no current subscribers should deliver to nobody and must not affect later subscriptions (subscribers added after a publish must not receive old messages).
- If a subscriber is subscribed to a topic and then calls publish with itself as sender, it must not receive that message.
- If multiple subscribers are subscribed to the same topic, publishing with one subscriber as sender must deliver the message to all other subscribers but not the sender.
- Publishing multiple messages in sequence should preserve message ordering per subscriber, and the concatenated payload received by each subscriber must match exactly what was published to them.
- Sender exclusion must also work when delivery is performed via intersection logic: when iterating delivery using `uWS::Intersection::forSubscriber(...)` and `topicTree->getSenderFor(subscriber)` as the sender context, the delivery callback must not be invoked for the sender itself, while still invoking for other subscribers.

Example of expected behavior with two subscribers `s1` and `s2` subscribed to the same topic:

- `publish("topic", {"A","B"}, nullptr)` => both `s1` and `s2` receive `"A"` on the first channel and `"B"` on the second channel.
- `publish("topic", {"X","Y"}, s1)` => only `s2` receives `"X"`/`"Y"`; `s1` receives nothing from this publish.
- `publish("topic", {"M","N"}, s2)` => only `s1` receives `"M"`/`"N"`.

The delivery mechanism also exposes a `fin` flag when streaming/segmenting payload. For any given publish stream to a subscriber, `fin == true` must only occur on the last segment, and no additional bytes may arrive for that subscriber after `fin` has been observed for that publish stream.