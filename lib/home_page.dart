import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:luckybox/l10n/app_localizations.dart';
import 'package:luckybox/const_value.dart';
import 'package:luckybox/theme_color.dart';
import 'package:luckybox/setting_page.dart';
import 'package:luckybox/ad_manager.dart';
import 'package:luckybox/ad_banner_widget.dart';
import 'package:luckybox/model.dart';
import 'package:luckybox/audio_play.dart';
import 'package:luckybox/text_to_speech.dart';
import 'package:luckybox/frame_painter.dart';
import 'package:luckybox/theme_mode_number.dart';
import 'package:luckybox/parse_locale_tag.dart';
import 'package:luckybox/main.dart';
import 'package:luckybox/loading_controller.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> with SingleTickerProviderStateMixin {
  late List<ui.Image> _boxDecodedFrames = [];
  late List<ui.Image> _ticketDecodedFrames = [];
  final GlobalKey _aspectRatioKey = GlobalKey();
  late AdManager _adManager;
  final AudioPlay _audioPlay = AudioPlay();
  bool _isBusy = false;
  int _tickNumber = 0;
  String _ticketText = '';
  double _ticketTextSize = 15.0;
  late Timer _timer;
  int _countdownSubtraction = 0;
  String _imageCountdownNumber = ConstValue.imageNumbers[0];
  double _countdownScale = 3;
  double _countdownOpacity = 0;
  int _timerCount = 30;
  final LoadingController _loadingController = LoadingController();
  //
  late ThemeColor _themeColor;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _audioPlay.playZero();
    await TextToSpeech.applyPreferences(Model.ttsVoiceId,Model.ttsVolume);
    _loadingController.start((){ setState((){}); });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _boxDecodedFrames = await boxLoadAllFrames();
      _ticketDecodedFrames = await ticketLoadAllFrames();
      setState(() {
        _loadingController.isReady = true;
      });
    });
  }

  @override
  void dispose() {
    _adManager.dispose();
    TextToSpeech.stop();
    _timer.cancel();
    _loadingController.dispose();
    super.dispose();
  }

  void _speakResult(String text) async {
    if (Model.ttsEnabled && Model.ttsVolume > 0.0) {
      await TextToSpeech.speak(text);
    }
  }

  Future<List<ui.Image>> boxLoadAllFrames() async {
    final List<ui.Image> decodedFrames = [];
    for (int i = 0; i < ConstValue.imageBoxes.length; i++) {
      final path = ConstValue.imageBoxes[i];
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      decodedFrames.add(frame.image);
    }
    return decodedFrames;
  }

  Future<List<ui.Image>> ticketLoadAllFrames() async {
    final List<ui.Image> decodedFrames = [];
    for (int i = 0; i < ConstValue.imageTickets.length; i++) {
      final path = ConstValue.imageTickets[i];
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      decodedFrames.add(frame.image);
    }
    return decodedFrames;
  }

  void _onClickSetting() async {
    final updatedSettings = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingPage(),
      ),
    );
    if (updatedSettings != null) {
      if (mounted) {
        await TextToSpeech.applyPreferences(Model.ttsVoiceId,Model.ttsVolume);
        //
        final mainState = context.findAncestorStateOfType<MainAppState>();
        if (mainState != null) {
          mainState
            ..locale = parseLocaleTag(Model.languageCode)
            ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
            ..setState(() {});
          setState(() {
            _isFirst = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadingController.isReady) {
      return _loadingController.buildLoadingView();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: _decoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: false,
          title: Text(l.appTitle,
            style: TextStyle(color: Colors.white, fontSize: 15.0),
          ),
          actions: <Widget>[
            Opacity(
              opacity: _isBusy ? 0.1 : 1,
              child: IconButton(
                icon: const Icon(Icons.settings,color: Colors.white),
                onPressed: _isBusy ? null : _onClickSetting,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              _onClickStart();
            },
            child: Column(
              children: [
                Expanded(child: LayoutBuilder(builder: (context, c) {
                  final box = min(c.maxWidth, c.maxHeight);
                  final dpr = MediaQuery.of(context).devicePixelRatio;
                  final targetWidthPx = max(1, (box * dpr).round());
                  return Stack(
                    children: [
                      Center(child: _boxFrameImage(_tickNumber, targetWidthPx)),
                      Center(child: _preTextArea()),
                      Center(child: _textArea()),
                      Center(child: _ticketFrameImage(_tickNumber, targetWidthPx)),
                      Center(
                        child: Opacity(
                          opacity: _countdownOpacity,
                          child: Transform.scale(
                            scale: _countdownScale,
                            child: Image.asset(_imageCountdownNumber),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          AppLocalizations.of(context)!.start,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _themeColor.colorNote),
                        ),
                      ),
                    ],
                  );
                })),
              ],
            ),
          )
        ),
        bottomNavigationBar: AdBannerWidget(adManager: _adManager),
      ),
    );
  }

  Decoration _decoration() {
    return BoxDecoration(
      image: DecorationImage(
        image: AssetImage(_themeColor.backImage),
        fit: BoxFit.cover,
      ),
    );
  }

  void _timerStart() {
    _timer = Timer.periodic(const Duration(milliseconds: (1000 ~/ 30)), (
        timer,
        ) {
      setState(() {
        _countdown();
      });
    });
  }

  void _onClickStart() {
    if (_isBusy) {
      return;
    }
    _isBusy = true;
    _countdownSubtraction = Model.countdownTime;
    if (_countdownSubtraction == 0) {
      _tickAction();
    } else {
      _audioPlay.play01();
      _tickNumber = 0;
      _ticketTextSize = 0;
      _timerStart();
    }
  }

  void _tickAction() {
    _audioPlay.play02();
    _tickNumber = 0;
    _ticketText = Model.nextPrizeText();
    _timer = Timer.periodic(const Duration(milliseconds: (1000 ~/ 30)), (
        timer,
        ) {
      setState(() {
        _tickNumber += 1;
        if (_tickNumber < 80) {
          _ticketTextSize = 0;
        } else {
          _ticketTextSize = (_tickNumber - 80) / 2 + 5.0;
        }
        if (_tickNumber >= 119) {
          _timer.cancel();
          _speakResult(_ticketText);
          _isBusy = false;
        }
      });
    });
  }

  void _countdown() {
    if (_countdownSubtraction == 0) {
      return;
    }
    if (_timerCount == 30) {
      _imageCountdownNumber = ConstValue.imageNumbers[_countdownSubtraction];
    }
    _timerCount -= 1;
    if (_timerCount <= 0) {
      _timerCount = 30;
      _countdownSubtraction -= 1;
      if (_countdownSubtraction == 0) {
        _imageCountdownNumber = ConstValue.imageNumbers[0];
        _timer.cancel();
        _tickAction();
      }
    }
    _countdownScale = 1 + (0.1 * (_timerCount / 30));
    if (_timerCount >= 20) {
      _countdownOpacity = (30 - _timerCount) / 10;
    } else if (_timerCount <= 5) {
      _countdownOpacity = _timerCount / 5;
    } else {
      _countdownOpacity = 1;
    }
  }

  Widget _boxFrameImage(int idx, int targetWidthPx) {
    return Center(
      child: SizedBox(
        width: targetWidthPx.toDouble(),
        height: targetWidthPx.toDouble(),
        child: CustomPaint(
          painter: FramePainter(_boxDecodedFrames[idx]),
        ),
      ),
    );
  }

  Widget _ticketFrameImage(int idx, int targetWidthPx) {
    if (idx < 80 || idx >= 90) {
      return SizedBox.shrink();
    }
    return Center(
      child: SizedBox(
        width: targetWidthPx.toDouble(),
        height: targetWidthPx.toDouble(),
        child: CustomPaint(
          painter: FramePainter(_ticketDecodedFrames[idx - 80]),
        ),
      ),
    );
  }

  Widget _preTextArea() {
    return AspectRatio(key: _aspectRatioKey, aspectRatio: 1);
  }

  Widget _textArea() {
    late Size size;
    try {
      RenderBox renderBox =
      _aspectRatioKey.currentContext?.findRenderObject() as RenderBox;
      size = renderBox.size;
    } catch (_) {
      return Container();
    }
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.fromLTRB(
          0,
          size.width * 0.25,
          size.width * 0.19,
          0,
        ),
        child: Text(_ticketText, style: TextStyle(color: Colors.black, fontSize: _ticketTextSize)),
      ),
    );
  }
}
