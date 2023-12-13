import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voice_call/chat_screen.dart';

const appId = "66baa546d0b849b5800ada2307c91c93";
const tokenId =
    "007eJxTYOC+evPGvreJbJ+7msTSTvAvMFy2tDyiYFrirVuzMm64SKsoMJiZJSUmmpqYpRgkWZhYJplaGBgkpiQaGRuYJ1saJlsar6ytTG0IZGSYYP2AkZEBAkF8FoaS1OISBgYAldsgPA==";
const channel = "test";

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  int? _remoteUid;

  bool _localUserJoined = false;

  late RtcEngine _engine;

  bool _isLocalAudioMuted = false;
  bool _isSpeakerphoneEnabled = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();

    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
      debugPrint("local user ${connection.localUid} joined");
      setState(() {
        _localUserJoined = true;
      });
    }, onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
      debugPrint("remote user $remoteUid joined");
      setState(() {
        _remoteUid = remoteUid;
      });
    }, onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
      debugPrint("remote user $remoteUid left channel");
      setState(() {
        _remoteUid = null;
        _dispose();
      });
    }, onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
      debugPrint(
          '[on token privilege will expire] connection ${connection.toJson()}, token $token');
    }));

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    //await _engine.enableVideo();
    //await _engine.enableAudio();
    //await _engine.startPreview();

    await _engine.joinChannel(
        token: tokenId,
        channelId: channel,
        uid: 0,
        options: const ChannelMediaOptions());
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    try {
      if (_localUserJoined) {
        await _engine.leaveChannel();
        setState(() {
          _localUserJoined = false;
        });
      }
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }

    try {
      await _engine.release();
    } catch (e) {
      debugPrint('Error releasing engine: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            // remote user widget call
            child: _remoteUser(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      _dispose();
                      Get.offAll(() => const ChatScreen());
                    },
                    icon: const Icon(
                      Icons.call_end_sharp,
                      color: Colors.red,
                      size: 30.0,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      setState(() {
                        _isLocalAudioMuted = !_isLocalAudioMuted;
                        // Toggle local audio mute status
                        // Mute or unmute local audio based on the status
                        _engine.muteLocalAudioStream(_isLocalAudioMuted);
                      });
                    },
                    icon: Icon(
                      !_isLocalAudioMuted ? Icons.mic : Icons.mic_off,
                      size: 30.0,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      setState(() {
                        // Toggle speakerphone status
                        _isSpeakerphoneEnabled = !_isSpeakerphoneEnabled;
                        // Enable or disable speakerphone based on the status
                        _engine.setEnableSpeakerphone(_isSpeakerphoneEnabled);
                      });
                    },
                    icon: Icon(
                      _isSpeakerphoneEnabled
                          ? Icons.volume_up
                          : Icons.volume_down,
                      size: 30.0,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _remoteUser() {
    if (_localUserJoined) {
      if (_remoteUid != null) {
        return Center(
          child: Text(
            "Connected with remote user $_remoteUid",
          ),
        );
      } else {
        return const Center(
          child: Text("Waiting for remote user to join..."),
        );
      }
    } else {
      return const Center(
        child: Text("Local user is not connected to the channel."),
      );
    }
  }
}
