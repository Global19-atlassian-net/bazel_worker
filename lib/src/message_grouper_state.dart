// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

/// State held by the [MessageGrouper] while waiting for additional data to
/// arrive.
class MessageGrouperState {
  /// `true` means we are waiting to receive bytes of base-128 encoded length.
  /// Some bytes of length may have been received already.
  ///
  /// `false` means we are waiting to receive more bytes of message data.  Some
  /// bytes of message data may have been received already.
  bool waitingForLength = true;

  /// If [waitingForLength] is `true`, the decoded value of the length bytes
  /// received so far (if any).  If [waitingForLength] is `false`, the decoded
  /// length that was most recently received.
  int length = 0;

  /// If [waitingForLength] is `true`, the amount by which the next received
  /// length byte must be left-shifted; otherwise undefined.
  int lengthShift = 0;

  /// If [waitingForLength] is `false`, a [Uint8List] which is ready to receive
  /// message data.  Otherwise null.
  Uint8List message;

  /// If [waitingForLength] is `false`, the number of message bytes that have
  /// been received so far.  Otherwise zero.
  int numMessageBytesReceived;

  MessageGrouperState() {
    reset();
  }

  /// Handle one byte at a time.
  ///
  /// Returns a [List<int>] of message bytes if [byte] was the last byte in a
  /// message, otherwise returns [null].
  List<int> handleInput(int byte) {
    if (waitingForLength) {
      length |= (byte & 0x7f) << lengthShift;
      if ((byte & 0x80) == 0) {
        waitingForLength = false;
        message = new Uint8List(length);
        if (length == 0) {
          // There is no message data to wait for, so just go ahead and deliver the
          // empty message.
          var messageToReturn = message;
          reset();
          return messageToReturn;
        }
      } else {
        lengthShift += 7;
      }
    } else {
      message[numMessageBytesReceived] = byte;
      numMessageBytesReceived++;
      if (numMessageBytesReceived == length) {
        var messageToReturn = message;
        reset();
        return messageToReturn;
      }
    }
    return null;
  }

  /// Reset the state so that we are ready to receive the next base-128 encoded
  /// length.
  void reset() {
    waitingForLength = true;
    length = 0;
    lengthShift = 0;
    message = null;
    numMessageBytesReceived = 0;
  }
}
