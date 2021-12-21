import 'dart:developer' as d;
import 'dart:math';

import 'package:app/floating_chat.dart';
import 'package:flutter/material.dart';

class FloatingChatView extends StatefulWidget {
  /// constructor
  const FloatingChatView({
    Key? key,
    required this.globalKey,
    required this.chatRooms,
    required this.centerChatBubble,
    required this.maxHeight,
    required this.maxWidth,
    this.surroundingColor,
  }) : super(key: key);

  /// variables
  final GlobalKey globalKey;
  final List<FloatingChat> chatRooms; // chat rooms to be placed
  final LinearGradient?
      surroundingColor; // when new chat arrives, the color will be surrounded
  final FloatingChat centerChatBubble; // main user's bubble
  // final double centerChatBubbleRadius; // main user's radius
  final double maxHeight;
  final double maxWidth;

  @override
  _FloatingChatViewState createState() => _FloatingChatViewState();
}

class _FloatingChatViewState extends State<FloatingChatView> {
  /// check whether chat room is inside the screen
  bool _isInsideScreen(double dist, double maxWidth, double maxHeight) =>
      dist <= min(maxWidth, maxHeight);

  /// find out if the two circles meet together
  bool _hasCollided(double r1, double r2, double d) =>
      !(r1 + r2 < d) ||
      ((max(r1, r2) - min(r1, r2) < d) && (d < r1 + r2)) ||
      (max(r1, r2) - min(r1, r2) == d) ||
      (max(r1, r2) - min(r1, r2) > d);

  /// place chat rooms
  List<FloatingChat> setPositions() {
    d.log("chatRooms length : ${widget.chatRooms.length}");
    d.log("the window size : ${widget.maxWidth} * ${widget.maxHeight}");
    List<FloatingChat> result = [];

    /// set mid
    double midWidth = widget.maxWidth / 2;
    double midHeight = widget.maxHeight / 2;

    /// 1) sort by distance
    for (FloatingChat c in widget.chatRooms) {
      result.add(c);
    }
    result.sort((c1, c2) => c1.distance.compareTo(c2.distance));

    List<int> haveTried = [];

    /// 2) place the closest chat room first and try N-times
    for (int i = 0; i < result.length; ++i) {
      bool hasPlaced = false;
      FloatingChat fChat = result[i];
      int tried = 0; // try 360 / 5 = 72 times
      /// check the distance first
      if (!_isInsideScreen(fChat.distance, widget.maxWidth, widget.maxHeight)) {
        continue;
      }

      int radian = 0;
      while (tried < 72) {
        // bool isNotDuplicated = false;

        /// try different radian
        radian = Random().nextInt(360) ~/ 10 * 10;
        // do {
        //   if (!haveTried.contains(radian)) {
        //     isNotDuplicated = true;
        //     break;
        //   }

        // } while (haveTried.isNotEmpty);

        // if (isNotDuplicated) {
        //   haveTried.add(radian);
        // }

        /// calculate top(Y) and left(X), also distance from center
        double newTop = midHeight + fChat.distance * sin(radian);
        double newLeft = midWidth + fChat.distance * cos(radian);
        double distancefromCenter =
            sqrt(pow(newTop - midHeight, 2) + pow(newLeft - midWidth, 2));

        /// check if newCircle collides with center circle
        /// if it collides then update the distance a bit longer
        // while (_hasCollided(
        //     fChat.radius, widget.centerChatBubble.radius, distancefromCenter)) {
        //   fChat.updateDistance = fChat.distance * 1.15;
        // }

        /// check if new Circle collides with other circles
        bool hasCollidedWithOthers = false;
        for (FloatingChat pChat in result) {
          /// check only different circles
          if (fChat.hashCode != pChat.hashCode) {
            if (pChat.top != null && pChat.left != null) {
              double distanceFromPlacedCircle = sqrt(
                  pow(pChat.top! - newTop, 2) + pow(pChat.left! - newLeft, 2));
              if (_hasCollided(
                  pChat.radius, fChat.radius, distanceFromPlacedCircle)) {
                /// has collided with other placed circle, need to re-try
                hasCollidedWithOthers = true;
                break;
              }
            } // if

            /// others not set yet
            break;
          } // if
        } // for
        d.log("fChat has collided : ${fChat.name}");
        if (!hasCollidedWithOthers) {
          /// set results, save it
          fChat.top = newTop;
          fChat.left = newLeft;
          hasPlaced = true;
          break;
        }

        /// count up and try different radius
        tried += 1;
      } //while

      if (!hasPlaced) {
        /// the circle has not been set yet
        /// let's try different radius again
        fChat.updateDistance = fChat.distance * 1.15;
        i -= 1;
      } else {
        d.log("set circle : ${fChat.name}");
      }
    }

    return result;
  }

  late final List<FloatingChat> setChatRooms;

  @override
  void initState() {
    setChatRooms = setPositions();

    super.initState();
  }

  /// rendered view
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: InteractiveViewer(
            minScale: 0.1,
            child: Stack(
              children: [
                /// other chat rooms
                Stack(
                  children: setChatRooms
                      .map(
                        (item) => Positioned(
                          top: item.top,
                          left: item.left,
                          child: InkWell(
                              onTap: () {
                                /// in default, show chatting room
                                showBottomSheet(
                                    context: context,
                                    builder: (_) {
                                      return Container(
                                        child: Center(
                                          child: Text(item.name),
                                        ),
                                      );
                                    });
                              },
                              child: item.getFloatingCircle),
                        ),
                      )
                      .toList(),
                ),

                /// center user
                Align(
                  alignment: Alignment.center,
                  child: widget.centerChatBubble.getFloatingCircle,
                )
              ],
            )),
      ),
    );
  }
}
