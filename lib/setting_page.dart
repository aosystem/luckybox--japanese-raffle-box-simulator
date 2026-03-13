import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:luckybox/l10n/app_localizations.dart';
import 'package:luckybox/model.dart';
import 'package:luckybox/text_to_speech.dart';
import 'package:luckybox/theme_color.dart';
import 'package:luckybox/ad_manager.dart';
import 'package:luckybox/ad_banner_widget.dart';
import 'package:luckybox/ad_ump_status.dart';


class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late AdManager _adManager;
  final TextEditingController _controllerPrizeText = TextEditingController();
  bool _prizeInitialFlag = false;
  int _countdownTime = 0;
  double _soundReadyVolume = 0.5;
  double _soundStartVolume = 0.5;
  late List<TtsOption> _ttsVoices;
  bool _ttsEnabled = true;
  String _ttsVoiceId = '';
  double _ttsVolume = 1.0;
  late ThemeColor _themeColor;
  int _themeNumber = 0;
  String _languageCode = '';
  final _inAppReview = InAppReview.instance;
  bool _isReady = false;
  bool _isFirst = true;
  late final UmpConsentController _adUmp;
  AdUmpState _adUmpState = AdUmpState.initial;


  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void dispose() {
    _adManager.dispose();
    _controllerPrizeText.dispose();
    super.dispose();
  }

  void _initState() async {
    _adManager = AdManager();
    _controllerPrizeText.text = Model.prizeText;
    _countdownTime = Model.countdownTime;
    _soundReadyVolume = Model.soundReadyVolume;
    _soundStartVolume = Model.soundStartVolume;
    _ttsEnabled = Model.ttsEnabled;
    _ttsVoiceId = Model.ttsVoiceId;
    _ttsVolume = Model.ttsVolume;
    _themeNumber = Model.themeNumber;
    _languageCode = Model.languageCode;
    //speech
    await TextToSpeech.getInstance();
    _ttsVoices = TextToSpeech.ttsVoices;
    TextToSpeech.setVolume(_ttsVolume);
    TextToSpeech.setTtsVoiceId(_ttsVoiceId);
    //
    _adUmp = UmpConsentController();
    _refreshConsentInfo();
    //
    setState(() {
      _isReady = true;
    });
  }

  Future<void> _refreshConsentInfo() async {
    _adUmpState = await _adUmp.updateConsentInfo(current: _adUmpState);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onTapPrivacyOptions() async {
    final err = await _adUmp.showPrivacyOptions();
    await _refreshConsentInfo();
    if (err != null && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.cmpErrorOpeningSettings} ${err.message}')),
      );
    }
  }

  void _apply() async {
    FocusScope.of(context).unfocus();
    if (_prizeInitialFlag) {
      await Model.setPrizeTextDefault();
    } else {
      await Model.setPrizeText(_controllerPrizeText.text);
    }
    await Model.setCountdownTime(_countdownTime);
    await Model.setSoundReadyVolume(_soundReadyVolume);
    await Model.setSoundStartVolume(_soundStartVolume);
    await Model.setTtsEnabled(_ttsEnabled);
    await Model.setTtsVoiceId(_ttsVoiceId);
    await Model.setTtsVolume(_ttsVolume);
    await Model.setThemeNumber(_themeNumber);
    await Model.setLanguageCode(_languageCode);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return _buildLoadingView();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: _themeNumber, context: context);
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _themeColor.backColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(foregroundColor: _themeColor.appBarForegroundColor),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.check),
              onPressed: _apply,
              style: IconButton.styleFrom(foregroundColor: _themeColor.appBarForegroundColor),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 100),
                    child: Column(
                      children: [
                        _buildPrize(l),
                        _buildCountdown(l),
                        _buildSoundVolume(l),
                        _buildSpeechSettings(l),
                        _buildTheme(l),
                        _buildLanguage(l),
                        _buildReview(l),
                        _buildCmpSection(l),
                        _buildUsage(l),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.yellow[700],
      child: Center(
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          backgroundColor: Colors.yellow[300],
        ),
      ),
    );
  }

  Widget _buildPrize(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 4, top: 4, right: 4, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(l.prize),
                ),
                Text(l.initial),
                Switch(
                  value: _prizeInitialFlag,
                  onChanged: (bool value) {
                    setState(() {
                      _prizeInitialFlag = value;
                    });
                  },
                  activeThumbColor: Colors.red,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 1,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: TextField(
              controller: _controllerPrizeText,
              maxLines: null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
        ],
      )
    );
  }

  Widget _buildCountdown(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 4, top: 12, right: 4, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Row(
              children: [
                Text(l.countdownTime),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_countdownTime.toString()),
                Expanded(
                  child: Slider(
                    value: _countdownTime.toDouble(),
                    min: 0,
                    max: 9,
                    divisions: 9,
                    label: _countdownTime.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _countdownTime = value.toInt();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildSoundVolume(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 4, top: 12, right: 4, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Row(
              children: [
                Text(l.soundReadyVolume),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_soundReadyVolume.toString()),
                Expanded(
                  child: Slider(
                    value: _soundReadyVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: _soundReadyVolume.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _soundReadyVolume = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: [
                Text(l.soundStartVolume),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_soundStartVolume.toString()),
                Expanded(
                  child: Slider(
                    value: _soundStartVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: _soundStartVolume.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _soundStartVolume = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildSpeechSettings(AppLocalizations l) {
    if (_ttsVoices.isEmpty) {
      return SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.only(left: 4, top: 12, right: 4, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(l.ttsEnabled),
                ),
                Switch(
                  value: _ttsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _ttsEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: [
                Text(l.ttsVolume),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: <Widget>[
                Text(_ttsVolume.toStringAsFixed(1)),
                Expanded(
                  child: Slider(
                    value: _ttsVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: _ttsVolume.toStringAsFixed(1),
                    onChanged: _ttsEnabled
                      ? (double value) {
                        setState(() {
                          _ttsVolume = double.parse(value.toStringAsFixed(1));
                        });
                      }
                      : null,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: [
                Text(l.ttsVoiceId),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: DropdownButtonFormField<String>(
              dropdownColor: _themeColor.dropdownColor,
              initialValue: () {
                if (_ttsVoiceId.isNotEmpty && _ttsVoices.any((o) => o.id == _ttsVoiceId)) {
                  return _ttsVoiceId;
                }
                return _ttsVoices.first.id;
              }(),
              items: _ttsVoices
                .map((o) => DropdownMenuItem<String>(value: o.id, child: Text(o.label)))
                .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _ttsVoiceId = v);
              },
            ),
          ),
        ],
      )
    );
  }

  Widget _buildTheme(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 4, top: 12, right: 4, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(l.theme,style: Theme.of(context).textTheme.bodyMedium),
              contentPadding: EdgeInsets.zero,
              trailing: DropdownButton<int>(
                value: _themeNumber,
                items: [
                  DropdownMenuItem(value: 0, child: Text(l.systemSetting)),
                  DropdownMenuItem(value: 1, child: Text(l.lightTheme)),
                  DropdownMenuItem(value: 2, child: Text(l.darkTheme)),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _themeNumber = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguage(AppLocalizations l) {
    final Map<String,String> languageNames = {
      'af': 'af: Afrikaans',
      'ar': 'ar: العربية',
      'bg': 'bg: Български',
      'bn': 'bn: বাংলা',
      'bs': 'bs: Bosanski',
      'ca': 'ca: Català',
      'cs': 'cs: Čeština',
      'da': 'da: Dansk',
      'de': 'de: Deutsch',
      'el': 'el: Ελληνικά',
      'en': 'en: English',
      'es': 'es: Español',
      'et': 'et: Eesti',
      'fa': 'fa: فارسی',
      'fi': 'fi: Suomi',
      'fil': 'fil: Filipino',
      'fr': 'fr: Français',
      'gu': 'gu: ગુજરાતી',
      'he': 'he: עברית',
      'hi': 'hi: हिन्दी',
      'hr': 'hr: Hrvatski',
      'hu': 'hu: Magyar',
      'id': 'id: Bahasa Indonesia',
      'it': 'it: Italiano',
      'ja': 'ja: 日本語',
      'km': 'km: ខ្មែរ',
      'kn': 'kn: ಕನ್ನಡ',
      'ko': 'ko: 한국어',
      'lt': 'lt: Lietuvių',
      'lv': 'lv: Latviešu',
      'ml': 'ml: മലയാളം',
      'mr': 'mr: मराठी',
      'ms': 'ms: Bahasa Melayu',
      'my': 'my: မြန်မာ',
      'ne': 'ne: नेपाली',
      'nl': 'nl: Nederlands',
      'or': 'or: ଓଡ଼ିଆ',
      'pa': 'pa: ਪੰਜਾਬੀ',
      'pl': 'pl: Polski',
      'pt': 'pt: Português',
      'ro': 'ro: Română',
      'ru': 'ru: Русский',
      'si': 'si: සිංහල',
      'sk': 'sk: Slovenčina',
      'sr': 'sr: Српски',
      'sv': 'sv: Svenska',
      'sw': 'sw: Kiswahili',
      'ta': 'ta: தமிழ்',
      'te': 'te: తెలుగు',
      'th': 'th: ไทย',
      'tl': 'tl: Tagalog',
      'tr': 'tr: Türkçe',
      'uk': 'uk: Українська',
      'ur': 'ur: اردو',
      'uz': 'uz: Oʻzbekcha',
      'vi': 'vi: Tiếng Việt',
      'zh': 'zh: 中文',
      'zu': 'zu: isiZulu',
    };
    return Card(
      margin: const EdgeInsets.only(left: 4, top: 12, right: 4, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(l.language,style: Theme.of(context).textTheme.bodyMedium),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              trailing: DropdownButton<String?>(
                value: _languageCode.isEmpty ? null : _languageCode,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: const Text('Default'),
                  ),
                  ...languageNames.entries.map(
                        (entry) => DropdownMenuItem<String?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _languageCode = value ?? '';
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.reviewApp, style: t.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: Text(l.reviewStore, style: t.bodySmall),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await _inAppReview.openStoreListing(
                      appStoreId: 'YOUR_APP_STORE_ID',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCmpSection(AppLocalizations l) {
    String statusLabel;
    IconData statusIcon;
    final showButton = _adUmpState.privacyStatus == PrivacyOptionsRequirementStatus.required;
    statusLabel = l.cmpCheckingRegion;
    statusIcon = Icons.help_outline;
    switch (_adUmpState.privacyStatus) {
      case PrivacyOptionsRequirementStatus.required:
        statusLabel = l.cmpRegionRequiresSettings;
        statusIcon = Icons.privacy_tip;
        break;
      case PrivacyOptionsRequirementStatus.notRequired:
        statusLabel = l.cmpRegionNoSettingsRequired;
        statusIcon = Icons.check_circle_outline;
        break;
      case PrivacyOptionsRequirementStatus.unknown:
        statusLabel = l.cmpRegionCheckFailed;
        statusIcon = Icons.error_outline;
        break;
    }
    return Card(
      margin: const EdgeInsets.only(left: 4, top: 12, right: 4, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.cmpSettingsTitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(l.cmpConsentDescription, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Chip(
                    avatar: Icon(statusIcon, size: 18),
                    label: Text(statusLabel),
                    side: BorderSide.none,
                  ),
                  const SizedBox(height: 4),
                  Text('${l.cmpConsentStatusLabel} ${_adUmpState.consentStatus.localized(context)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (showButton)
                    Column(
                        children: [
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _adUmpState.isChecking ? null : _onTapPrivacyOptions,
                            icon: const Icon(Icons.settings),
                            label: Text(_adUmpState.isChecking ? l.cmpConsentStatusChecking : l.cmpOpenConsentSettings),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              side: BorderSide(
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _adUmpState.isChecking ? null : _refreshConsentInfo,
                            icon: const Icon(Icons.refresh),
                            label: Text(l.cmpRefreshStatus),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await ConsentInformation.instance.reset();
                              await _refreshConsentInfo();
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(l.cmpResetStatusDone)));
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(l.cmpResetStatus),
                          ),
                        ]
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsage(AppLocalizations l) {
    return SizedBox(
        width: double.infinity,
        child: Card(
            margin: const EdgeInsets.only(left: 4, top: 12, right: 4, bottom: 0),
            color: _themeColor.cardColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.usage1),
                  const SizedBox(height: 15),
                  Text(l.usage2),
                  const SizedBox(height: 15),
                  Text(l.usage3),
                  const SizedBox(height: 15),
                  Text(l.usage4),
                ],
              ),
            )
        )
    );
  }

}

