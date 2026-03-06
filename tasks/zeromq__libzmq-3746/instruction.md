When using an XSUB socket connected to an XPUB socket, subscription commands are encoded as messages whose first byte indicates subscribe (1) or unsubscribe (0), followed by the topic. In multipart sends, the current implementation incorrectly continues to interpret later frames as subscribe/unsubscribe commands even if the first frame of that multipart message is not a subscribe/unsubscribe command. This can cause ordinary multipart application payload frames to be misclassified as subscription control traffic, leading to unexpected subscription state changes and incorrect message delivery.

Change XSUB→XPUB message processing so that subscribe/unsubscribe detection is decided only by the first frame of each multipart message: if the first frame is not a valid subscribe/unsubscribe command, then none of the subsequent frames in that same multipart message may be treated as subscribe/unsubscribe commands (they must be forwarded/handled as normal data frames). Conversely, if the first frame is a valid subscribe/unsubscribe command, subscription handling should proceed consistently for that multipart message as appropriate.

This should work correctly with XPUB in manual mode (ZMQ_XPUB_MANUAL enabled) as well as the normal mode. In manual mode, applications should still be able to receive subscription/unsubscription messages from XSUB exactly when the first frame of a multipart message is a valid subscription command, and should not receive spurious subscription events originating from later frames of a multipart message whose first frame was not a subscription command.

Reproduction example:
- Create an XPUB socket, optionally set ZMQ_XPUB_MANUAL to 1, and bind.
- Create an XSUB socket and connect.
- Send a multipart message from XSUB where the first frame is not a subscription command (does not start with byte 0 or 1 in the subscription-command sense), but a later frame begins with 0 or 1.

Expected behavior: the XPUB side must not treat any frame of that multipart message as a subscribe/unsubscribe command, and the subscriber’s subscription state must not be modified by any later frames in that multipart message.

Actual behavior (current bug): later frames can be misinterpreted as subscribe/unsubscribe commands, producing unexpected subscription events and/or altering which published messages are received.