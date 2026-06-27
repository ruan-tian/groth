/// 首页卡片装饰图标资源
///
/// 用于首页"你的成长由你掌控"卡片右上角的装饰图标轮换。
/// 所有图标均经过 rembg 去背景 + webp 化处理。
class DashboardDecoAssets {
  DashboardDecoAssets._();

  static const _root = 'assets/images/dashboard/deco';

  // ── 花卉系列 ──
  static const clover = '$_root/clover.webp';
  static const smilingFlower = '$_root/smiling_flower.webp';
  static const pinkRose = '$_root/pink_rose.webp';
  static const lavender = '$_root/lavender.webp';

  // ── 水果系列 ──
  static const strawberry = '$_root/strawberry.webp';
  static const apple = '$_root/apple.webp';
  static const peach = '$_root/peach.webp';
  static const orange = '$_root/orange.webp';
  static const banana = '$_root/banana.webp';
  static const grape = '$_root/grape.webp';

  // ── 学习系列 ──
  static const cuteBookmark = '$_root/cute_bookmark.webp';
  static const cuteNotebook = '$_root/cute_notebook.webp';
  static const cutePencil = '$_root/cute_pencil.webp';
  static const cuteEraser = '$_root/cute_eraser.webp';
  static const cuteRuler = '$_root/cute_ruler.webp';
  static const books = '$_root/books.webp';

  // ── 生活系列 ──
  static const pinkAlarm = '$_root/pink_alarm.webp';
  static const candle = '$_root/candle.webp';
  static const deskLamp = '$_root/desk_lamp.webp';
  static const kettle = '$_root/kettle.webp';
  static const waterCup = '$_root/water_cup.webp';
  static const mintLeaf = '$_root/mint_leaf.webp';
  static const lemonSlice = '$_root/lemon_slice.webp';

  // ── 可爱系列 ──
  static const heart = '$_root/heart.webp';
  static const moon = '$_root/moon.webp';
  static const star = '$_root/star.webp';
  static const nightLamp = '$_root/night_lamp.webp';
  static const cutePillow = '$_root/cute_pillow.webp';
  static const heartPillow = '$_root/heart_pillow.webp';
  static const bunnyDoll = '$_root/bunny_doll.webp';

  /// 所有装饰图标列表（用于轮换，共 30 个）
  static const List<String> all = [
    clover,
    smilingFlower,
    pinkRose,
    lavender,
    strawberry,
    apple,
    peach,
    orange,
    banana,
    grape,
    cuteBookmark,
    cuteNotebook,
    cutePencil,
    cuteEraser,
    cuteRuler,
    books,
    pinkAlarm,
    candle,
    deskLamp,
    kettle,
    waterCup,
    mintLeaf,
    lemonSlice,
    heart,
    moon,
    star,
    nightLamp,
    cutePillow,
    heartPillow,
    bunnyDoll,
  ];

  /// 装饰图标对应的鼓励/提醒消息（图标与消息关联）
  static const List<List<String>> barrageMessages = [
    // 水果系列 → 健康饮食
    [strawberry, '记得多吃水果呀'],
    [apple, '一天一苹果，医生远离我'],
    [orange, '补充维C哦'],
    [banana, '香蕉能让你心情变好'],
    [grape, '葡萄虽甜，也要适量哦'],
    [peach, '你和桃子一样甜'],
    // 生活系列 → 健康习惯
    [waterCup, '多喝水呀'],
    [kettle, '记得喝杯温水'],
    [mintLeaf, '深呼吸，放轻松'],
    [lemonSlice, '来杯柠檬水提提神'],
    [candle, '给自己点一盏灯'],
    [nightLamp, '记得早睡哦'],
    // 学习系列 → 鼓励学习
    [cuteNotebook, '今天也要加油学习'],
    [cutePencil, '每天进步一点点'],
    [books, '知识是最好的投资'],
    [cuteBookmark, '别忘了你的小目标'],
    // 可爱系列 → 情感鼓励
    [heart, '你值得被温柔以待'],
    [heartPillow, '累了就抱抱自己'],
    [bunnyDoll, '你和小兔子一样可爱'],
    [cutePillow, '好好休息也很重要'],
    [moon, '晚安，好梦'],
    [star, '你就是自己的星星'],
    // 花卉系列 → 积极心态
    [smilingFlower, '像花儿一样微笑吧'],
    [pinkRose, '送你一朵小玫瑰'],
    [clover, '好运正在路上'],
    [lavender, '闻闻花香，放松一下'],
  ];
}
