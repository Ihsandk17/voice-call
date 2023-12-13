import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voice_call/voice_call.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Chat screen")),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Get.to(() => VoiceCallScreen());
              },
              style: const ButtonStyle(),
              child: const Text("Call me"),
            ),
          )
        ],
      ),
    ));
  }
}
