import 'focus_assets.dart';

class FocusPresetOption {
  const FocusPresetOption({
    required this.type,
    required this.label,
    required this.minutes,
    required this.asset,
    required this.tint,
  });

  final String type;
  final String label;
  final int minutes;
  final String asset;
  final int tint;
}

class FocusSoundOption {
  const FocusSoundOption({
    required this.value,
    required this.label,
    required this.asset,
  });

  final String value;
  final String label;
  final String asset;
}

const focusPresetOptions = <FocusPresetOption>[
  FocusPresetOption(
    type: 'pomodoro',
    label: '番茄',
    minutes: 25,
    asset: FocusAssets.iconPomodoro,
    tint: 0xFF4FB7AA,
  ),
  FocusPresetOption(
    type: 'deep',
    label: '深度',
    minutes: 45,
    asset: FocusAssets.iconDeep,
    tint: 0xFF74BCE8,
  ),
  FocusPresetOption(
    type: 'ultra',
    label: '超深度',
    minutes: 90,
    asset: FocusAssets.iconUltra,
    tint: 0xFFC7A0DB,
  ),
  FocusPresetOption(
    type: 'custom',
    label: '自定义',
    minutes: 0,
    asset: FocusAssets.iconCustom,
    tint: 0xFFF1B84E,
  ),
];

const focusSoundOptions = <FocusSoundOption>[
  FocusSoundOption(
    value: 'rain',
    label: '雨声',
    asset: FocusAssets.soundRain,
  ),
  FocusSoundOption(
    value: 'ocean',
    label: '海浪',
    asset: FocusAssets.soundOcean,
  ),
  FocusSoundOption(
    value: 'forest',
    label: '森林',
    asset: FocusAssets.soundForest,
  ),
  FocusSoundOption(
    value: 'cafe',
    label: '咖啡馆',
    asset: FocusAssets.soundCafe,
  ),
  FocusSoundOption(
    value: 'white_noise',
    label: '白噪声',
    asset: FocusAssets.soundWhiteNoise,
  ),
  FocusSoundOption(
    value: 'none',
    label: '无',
    asset: FocusAssets.soundNone,
  ),
];

String focusTypeLabel(String type) {
  switch (type) {
    case 'pomodoro':
      return '番茄';
    case 'deep':
      return '深度';
    case 'ultra':
      return '超深度';
    case 'custom':
      return '自定义';
    default:
      return '专注';
  }
}

String focusSoundLabel(String? soundType) {
  if (soundType == null || soundType == 'none') return '无';
  for (final option in focusSoundOptions) {
    if (option.value == soundType) return option.label;
  }
  return soundType;
}
