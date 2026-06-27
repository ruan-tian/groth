import 'package:flutter/widgets.dart';

@immutable
class SceneryTheme {
  const SceneryTheme({
    required this.id,
    required this.name,
    required this.landscapeAsset,
    required this.portraitAsset,
  });

  final String id;
  final String name;
  final String landscapeAsset;
  final String portraitAsset;

  String assetForOrientation(Orientation orientation) {
    return orientation == Orientation.landscape
        ? landscapeAsset
        : portraitAsset;
  }

  String assetForSize(Size size) {
    return size.width >= size.height ? landscapeAsset : portraitAsset;
  }
}

class SceneryThemeCatalog {
  SceneryThemeCatalog._();

  static const _root = 'assets/images/focus/themes';

  static const _names = <String>[
    '云岭花谷',
    '暮色海岸',
    '黄昏港湾',
    '花海日落',
    '山顶天池',
    '海边花园',
    '山坡木屋',
    '薰衣草牧场',
    '林间花野',
    '冰原雪境',
    '海崖雏菊',
    '玫瑰花窗',
    '花房庭院',
    '山城晴空',
    '海崖晨光',
    '湖岸公路',
    '雪山蓝湖',
    '城市湖畔',
    '古树夕照',
    '秋千夜城',
    '天空浮城',
    '富士山湖',
    '风暴彩云',
    '草原彩虹',
    '山谷虹桥',
    '海上虹桥',
    '街角彩虹',
    '海船彩虹',
    '田野虹云',
    '云海彩虹',
    '悬崖海光',
    '云上草坡',
    '海景小屋',
    '桂林群峰',
    '森林晨光',
    '椰林海岛',
    '海边石阶',
    '海岸草坡',
    '海边长椅',
    '夕阳花海',
    '日落海滩',
    '月夜海岸',
    '夏日浅滩',
    '棕榈落日',
    '湖心孤岛',
    '湖中林路',
    '湖边夕阳',
    '湖畔小舟',
    '林溪草坡',
    '透明海岛',
    '田边晴云',
    '绵羊草地',
    '竹林雨径',
    '幽竹茶室',
    '粉色海浪',
    '山脚花田',
    '花树天光',
    '荷塘盛夏',
    '孤树花路',
    '麦田小路',
    '雨中陶缸',
    '雨夜公路',
    '雪峰云光',
    '雪山湖湾',
    '云涌街角',
    '云塔城市',
  ];

  static final themes = List<SceneryTheme>.generate(_names.length, (index) {
    final number = (index + 1).toString().padLeft(3, '0');
    return SceneryTheme(
      id: 'scene_$number',
      name: _names[index],
      landscapeAsset: '$_root/scene_${number}_landscape.webp',
      portraitAsset: '$_root/scene_${number}_portrait.webp',
    );
  }, growable: false);

  static SceneryTheme themeAt(int index) {
    if (themes.isEmpty) {
      throw StateError('SceneryThemeCatalog has no themes.');
    }
    return themes[index % themes.length];
  }
}
