import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckybox/const_value.dart';
import 'package:luckybox/l10n/app_localizations.dart';

class Model {
  Model._();

  static const String _prefPrizeText = 'prizeText';
  static const String _prefCountdownTime = 'countdownTime';
  static const String _prefSoundReadyVolume = 'soundReadyVolume';
  static const String _prefSoundStartVolume = 'soundStartVolume';
  static const String _prefTtsEnabled = 'ttsEnabled';
  static const String _prefTtsVoiceId = 'ttsVoiceId';
  static const String _prefTtsVolume = 'ttsVolume';
  static const String _prefThemeNumber = 'themeNumber';
  static const String _prefLanguageCode = 'languageCode';
  
  static bool _ready = false;
  static String _prizeText = '';
  static List<Map<String, dynamic>> _prizeList = [];
  static int _countdownTime = 0;
  static double _soundReadyVolume = 0.5;
  static double _soundStartVolume = 0.5;
  static bool _ttsEnabled = true;
  static double _ttsVolume = 1.0;
  static String _ttsVoiceId = '';
  static int _themeNumber = 0;
  static String _languageCode = '';

  static String get prizeText => _prizeText;
  static List<Map<String, dynamic>> get prizeList => _prizeList;
  static int get countdownTime => _countdownTime;
  static double get soundReadyVolume => _soundReadyVolume;
  static double get soundStartVolume => _soundStartVolume;
  static bool get ttsEnabled => _ttsEnabled;
  static double get ttsVolume => _ttsVolume;
  static String get ttsVoiceId => _ttsVoiceId;
  static int get themeNumber => _themeNumber;
  static String get languageCode => _languageCode;

  static Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    //
    _prizeText = prefs.getString(_prefPrizeText) ?? '';
    _prizeList = _makePrizeList(_prizeText);
    if (_prizeText == '') {
      await setPrizeText('');
    }
    _countdownTime = (prefs.getInt(_prefCountdownTime) ?? 0).clamp(0, 9);
    _soundReadyVolume = (prefs.getDouble(_prefSoundReadyVolume) ?? 0.5).clamp(0.0, 1.0);
    _soundStartVolume = (prefs.getDouble(_prefSoundStartVolume) ?? 0.5).clamp(0.0, 1.0);
    _ttsEnabled = prefs.getBool(_prefTtsEnabled) ?? true;
    _ttsVolume = (prefs.getDouble(_prefTtsVolume) ?? 1.0).clamp(0.0, 1.0);
    _ttsVoiceId = prefs.getString(_prefTtsVoiceId) ?? '';
    _themeNumber = (prefs.getInt(_prefThemeNumber) ?? 0).clamp(0, 2);
    _languageCode = prefs.getString(_prefLanguageCode) ?? ui.PlatformDispatcher.instance.locale.languageCode;
    _languageCode = _resolveLanguageCode(_languageCode);
    _ready = true;
  }

  static String _resolveLanguageCode(String code) {
    final supported = AppLocalizations.supportedLocales;
    if (supported.any((l) => l.languageCode == code)) {
      return code;
    } else {
      return '';
    }
  }

  static Future<void> setPrizeText(String value) async {
    if (value == '') {
      value = ConstValue.prizeTextDefault;
    }
    _prizeText = _prizeFormat(value);
    _prizeList = _makePrizeList(_prizeText);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPrizeText, _prizeText);
  }

  static Future<void> setPrizeTextDefault() async {
    setPrizeText(ConstValue.prizeTextDefault);
  }

  static List<Map<String, dynamic>> _makePrizeList(String value) {
    List<Map<String, dynamic>> mapList = [];
    if (value == '') {
      return mapList;
    }
    final List<String> lines = value.replaceAll('\r', '').split('\n');
    for (int i = 0; i < lines.length; i++) {
      final List<String> ary = lines[i].split(':');
      final int number = _parseStrToNumber(ary[0]);
      final Map<String, dynamic> mapOne = {'number': number, 'prize': ary[1]};
      mapList.add(mapOne);
    }
    return mapList;
  }

  static String nextPrizeText() {
    final List<int> candidates = [];
    int row = 0;
    for (Map<String, dynamic> prize in _prizeList) {
      for (int i = 0; i < prize['number']; i++) {
        candidates.add(row);
      }
      row += 1;
    }
    if (candidates.isEmpty) {
      return '* END *';
    }
    candidates.shuffle();
    final int choice = candidates.first;
    String result = '';
    for (int i = 0; i < _prizeList.length; i++) {
      if (i == choice) {
        _prizeList[i]['number'] -= 1;
        result = _prizeList[i]['prize'];
        break;
      }
    }
    List<String> prizeStringList = [];
    for (Map<String, dynamic> prize in _prizeList) {
      prizeStringList.add('${prize['number']}:${prize['prize']}');
    }
    setPrizeText(prizeStringList.join('\n'));
    return result;
  }

  static Future<void> setCountdownTime(int value) async {
    _countdownTime = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefCountdownTime, value);
  }

  static Future<void> setSoundReadyVolume(double value) async {
    _soundReadyVolume = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefSoundReadyVolume, value);
  }

  static Future<void> setSoundStartVolume(double value) async {
    _soundStartVolume = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefSoundStartVolume, value);
  }

  static Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTtsEnabled, value);
  }

  static Future<void> setTtsVolume(double value) async {
    _ttsVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefTtsVolume, value);
  }

  static Future<void> setTtsVoiceId(String value) async {
    _ttsVoiceId = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTtsVoiceId, value);
  }

  static Future<void> setThemeNumber(int value) async {
    _themeNumber = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeNumber, value);
  }

  static Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, value);
  }

  static int _parseStrToNumber(String numString) {
    if (_isStringToIntParsable(numString)) {
      return int.parse(numString);
    }
    return 0;
  }

  static bool _isStringToIntParsable(String str) {
    try {
      int.parse(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  static String _prizeFormat(String str) {
    final List<String> lines = str.replaceAll('\r', '').split('\n');
    List<String> prizes = [];
    for (String str in lines) {
      str = str.replaceAll('：', ':');
      if (str.contains(':') == false) {
        continue;
      }
      List<String> ary = str.split(':');
      ary[0] = ary[0].replaceAll('０', '0');
      ary[0] = ary[0].replaceAll('１', '1');
      ary[0] = ary[0].replaceAll('２', '2');
      ary[0] = ary[0].replaceAll('３', '3');
      ary[0] = ary[0].replaceAll('４', '4');
      ary[0] = ary[0].replaceAll('５', '5');
      ary[0] = ary[0].replaceAll('６', '6');
      ary[0] = ary[0].replaceAll('７', '7');
      ary[0] = ary[0].replaceAll('８', '8');
      ary[0] = ary[0].replaceAll('９', '9');
      ary[0] = ary[0].replaceAll('、', ',');
      ary[0] = ary[0].replaceAll('，', ',');
      ary[0] = ary[0].replaceAll('ー', '-');
      ary[0] = ary[0].replaceAll('―', '-');
      ary[0] = ary[0].replaceAll(RegExp(r'[^0-9]'), '');
      prizes.add('${ary[0]}:${ary[1]}');
    }
    return prizes.join('\n');
  }

}
