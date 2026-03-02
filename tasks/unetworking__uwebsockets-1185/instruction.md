The pub/sub TopicTree publish behavior is missing support for excluding the publishing subscriber (“sender”) from receiving its own published message. This causes incorrect delivery semantics when applications publish a message on a topic while also being subscribed to that same topic.

When calling `uWS::TopicTree::publish(topic, dataChannels, sender)`, delivery should work as follows:

- If `sender` is `nullptr`, all subscribers to `topic` must receive the published message.
- If `sender` is a non-null `uWS::Subscriber*`, every subscriber to `topic` except `sender` must receive the published message. The `sender` must not receive its own message.

This exclusion must apply consistently even when multiple subscribers are present and even when the sender is subscribed to the topic.

In addition, when delivering a message to a subscriber via the TopicTree callback mechanism, the callback may use `topicTree->getSenderFor(subscriber)` to obtain the sender associated with that delivery. For correct behavior, `getSenderFor(s)` must reflect the sender passed to `publish` for deliveries produced by that `publish` call (and be `nullptr` when `publish` was called with a null sender).

A concrete scenario that must behave correctly:

1) Publish to a topic with no subscribers: nobody receives anything.
2) Subscribe `s1` to a topic, then publish to that topic with `sender == s1`: `s1` must not receive the message.
3) Subscribe `s2` to the same topic, then publish with `sender == nullptr`: both `s1` and `s2` must receive the message.
4) Publish with `sender == s2`: `s1` receives it and `s2` does not.
5) Publish with `sender == s1`: `s2` receives it and `s1` does not.

The implementation must ensure that message segmentation/iteration over intersections still terminates correctly (i.e., the per-subscriber delivery iterator provides a final segment where `fin == true`, and no additional data is delivered after that final segment).