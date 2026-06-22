from __future__ import annotations

import re
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
MODEL_FILE = REPO / "lib" / "features" / "health" / "models" / "drink_recommendation.dart"
ASSET_DIR = REPO / "assets" / "images" / "drinks"


CATEGORIES = ["健康区", "咖啡", "新茶饮", "即饮茶", "气泡", "果汁", "乳饮", "功能", "凉茶"]
NEW_TEA_BRANDS = {
    "CoCo 都可",
    "一点点",
    "书亦烧仙草",
    "古茗",
    "喜茶",
    "奈雪的茶",
    "沪上阿姨",
    "甜啦啦",
    "益禾堂",
    "茶百道",
    "茶颜悦色",
    "蜜雪冰城",
    "霸王茶姬",
    "柠季",
}
COFFEE_BRANDS = {
    "瑞幸咖啡",
    "库迪咖啡",
    "幸运咖",
    "星巴克",
    "雀巢咖啡",
    "星巴克星选",
    "农夫山泉炭仌",
    "三得利",
}
INLINE_BRAND_PREFIXES = [
    "农夫山泉炭仌",
    "可口可乐旗下",
    "认养一头牛",
    "光明致优娟姗",
    "光明优倍",
    "光明莫斯利安",
    "伊利安慕希",
    "君乐宝悦鲜活",
    "君乐宝简醇",
    "蒙牛每日鲜语",
    "统一阿萨姆",
    "宝矿力水特",
    "星巴克星选",
    "六个核桃",
    "三元",
    "三得利",
    "元气森林",
    "兰芳园",
    "康师傅",
    "味全",
    "伊利",
    "佳得乐",
    "乐虎",
    "外星人",
    "娃哈哈",
    "旺仔",
    "椰树",
    "汇源",
    "露露",
    "银鹭",
    "蒙牛",
    "雀巢",
    "OATLY",
    "红牛",
    "七喜",
    "芬达",
    "美年达",
]
DESCRIPTION_BY_CATEGORY = {
    "健康区": "轻负担和补水感更明确，适合今天想喝得清爽一点。",
    "咖啡": "咖啡香更直接，适合学习、工作或想让状态清醒一点的时候。",
    "新茶饮": "茶香、果香和奶感都更活泼，适合给今天加一点小开心。",
    "即饮茶": "方便顺手、味道稳定，适合通勤、配餐或路上来一瓶。",
    "气泡": "气泡感会让心情更轻一点，适合想要一口冰爽的时候。",
    "果汁": "果味更明亮，适合早餐、加餐或想喝点清甜风味的时候。",
    "乳饮": "奶香和顺滑感会更明显，适合当作轻早餐或安抚型小奖励。",
    "功能": "补给感和提神感更强，适合运动后、出门久了或需要打起精神的时候。",
    "凉茶": "草本感更明显，适合重口味之后或者想让口腔清一清的时候。",
}
PRIMARY_TAG_BY_CATEGORY = {
    "健康区": "轻负担",
    "咖啡": "咖啡系",
    "新茶饮": "现制茶饮",
    "即饮茶": "瓶装茶",
    "气泡": "气泡饮",
    "果汁": "果汁系",
    "乳饮": "乳饮系",
    "功能": "功能饮",
    "凉茶": "凉茶系",
}
FALLBACK_TAG_BY_CATEGORY = {
    "健康区": "清爽",
    "咖啡": "提神",
    "新茶饮": "快乐水替代",
    "即饮茶": "通勤搭子",
    "气泡": "冰爽",
    "果汁": "清甜",
    "乳饮": "顺滑",
    "功能": "补给",
    "凉茶": "清口",
}
KEYWORD_TAGS = {
    "无糖": "轻负担",
    "矿泉水": "补水",
    "白开水": "补水",
    "苏打水": "气泡感",
    "拿铁": "拿铁",
    "美式": "美式",
    "冷萃": "冷萃",
    "奶茶": "奶茶",
    "乌龙": "乌龙",
    "茉莉": "茉莉",
    "柠檬": "柠檬",
    "葡萄": "葡萄",
    "草莓": "草莓",
    "杨枝甘露": "芒果",
    "西瓜": "西瓜",
    "百香": "百香果",
    "桃": "蜜桃",
    "椰": "椰香",
    "咖啡": "咖啡香",
    "气泡": "气泡",
    "果汁": "果味",
    "酸奶": "酸奶",
    "牛奶": "奶香",
    "豆奶": "豆香",
    "凉茶": "草本",
}


def dart_quote(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def contains_any(text: str, needles: list[str]) -> bool:
    return any(needle in text for needle in needles)


def clean_label(value: str) -> str:
    return (
        value.replace("png", "")
        .replace("  ", " ")
        .replace("（5.9 元起）", "")
        .strip()
    )


def pretty_brand(brand: str) -> str:
    brand = brand.strip()
    if brand == "瑞幸":
        return "瑞幸咖啡"
    if brand == "库迪":
        return "库迪咖啡"
    return brand


def parse_new_drink(raw_name: str) -> tuple[str, str]:
    clean = clean_label(raw_name)
    colon_index = clean.find("：") if "：" in clean else clean.find(":")
    if colon_index != -1:
        return pretty_brand(clean[:colon_index].strip()), clean_label(clean[colon_index + 1 :].strip())

    for prefix in INLINE_BRAND_PREFIXES:
        if clean.startswith(prefix) and len(clean) > len(prefix):
            return pretty_brand(prefix), clean_label(clean[len(prefix) :])

    if clean == "白开水多喝":
        return "轻补水", clean
    if clean == "矿泉水":
        return "轻补水", clean
    if clean == "无糖可乐":
        return "轻负担", clean
    return pretty_brand(clean), clean


def parse_stem(stem: str) -> tuple[str, str]:
    if "__" not in stem:
        clean = clean_label(stem)
        return pretty_brand(clean), clean

    parts = stem.split("__")
    raw_brand = pretty_brand(parts[0])
    raw_name = clean_label("__".join(parts[1:]))
    if raw_brand == "新饮品":
        return parse_new_drink(raw_name)
    return raw_brand, raw_name


def infer_category(brand: str, name: str) -> str:
    text = f"{brand} {name}"
    if contains_any(name, ["白开水", "矿泉水", "苏打水", "无糖可乐"]):
        return "健康区"
    if contains_any(text, ["王老吉", "凉茶"]):
        return "凉茶"
    if contains_any(text, ["东鹏", "尖叫", "脉动", "佳得乐", "宝矿力", "外星人", "红牛", "乐虎", "健力宝"]):
        return "功能"
    if contains_any(name, ["七喜", "雪碧", "芬达", "美年达", "可乐", "气泡"]):
        return "健康区" if name == "无糖可乐" else "气泡"
    if brand in NEW_TEA_BRANDS:
        return "新茶饮"
    if brand in COFFEE_BRANDS or contains_any(text, ["咖啡", "拿铁", "美式", "冷萃", "澳瑞白", "卡布奇诺", "摩卡", "馥芮白", "星冰乐"]):
        return "咖啡"
    if contains_any(
        text,
        ["豆奶", "牛奶", "酸奶", "乳", "椰汁", "燕麦奶", "花生牛奶", "杏仁露", "安慕希", "莫斯利安", "纯甄", "鲜语", "悦鲜活", "简醇", "营养快线", "优酸乳", "核桃乳"],
    ):
        return "乳饮"
    if contains_any(text, ["乌龙", "绿茶", "红茶", "清茶", "奶茶", "乳茶", "柠檬茶", "鸳鸯", "阿萨姆", "东方树叶", "茶 π", "煎茶"]):
        return "即饮茶"
    if contains_any(text, ["NFC", "果汁", "鲜果汁", "山楂", "C100"]):
        return "果汁"
    if contains_any(name, ["杨枝甘露", "葡萄", "草莓", "西瓜", "百香", "柠檬", "芒", "橙", "柚", "荔枝", "桃", "芭乐", "青提", "凤梨"]):
        return "果汁" if brand == "新饮品" else "新茶饮"
    return "新茶饮"


def tags_for(category: str, brand: str, name: str) -> list[str]:
    tags: list[str] = []

    def add(tag: str) -> None:
        if tag and tag not in tags:
            tags.append(tag)

    add(PRIMARY_TAG_BY_CATEGORY[category])
    if brand not in {"轻补水", "轻负担", "新饮品"}:
        add(brand)
    for key, value in KEYWORD_TAGS.items():
        if key in name:
            add(value)
    add(FALLBACK_TAG_BY_CATEGORY[category])
    return tags[:3]


def parse_curated_block(source: str) -> str:
    match = re.search(r"static const drinks = \[(?P<body>.*?)\n  \];", source, re.S)
    if not match:
        match = re.search(r"static const List<DrinkRecommendation> _curatedDrinks = \[(?P<body>.*?)\n  \];", source, re.S)
    if not match:
        raise RuntimeError("Failed to parse curated drinks block")
    return match.group("body").rstrip("\n")


def build_file(curated_body: str, stems: list[str]) -> str:
    curated_stems = set(re.findall(r"imagePath: '\$_root/(.*?)\.webp'", curated_body))
    generated_stems = [stem for stem in stems if stem not in curated_stems]

    lines: list[str] = []
    add = lines.append

    add("class DrinkRecommendation {")
    add("  const DrinkRecommendation({")
    add("    required this.id,")
    add("    required this.brand,")
    add("    required this.name,")
    add("    required this.category,")
    add("    required this.description,")
    add("    required this.imagePath,")
    add("    required this.tags,")
    add("  });")
    add("")
    add("  final String id;")
    add("  final String brand;")
    add("  final String name;")
    add("  final String category;")
    add("  final String description;")
    add("  final String imagePath;")
    add("  final List<String> tags;")
    add("}")
    add("")
    add("class DrinkCatalog {")
    add("  DrinkCatalog._();")
    add("")
    add("  static const String _root = 'assets/images/drinks';")
    add("")
    add("  static const categories = [")
    for category in CATEGORIES:
        add(f"    {dart_quote(category)},")
    add("  ];")
    add("")
    add("  static final List<DrinkRecommendation> drinks = [")
    add("    ..._curatedDrinks,")
    add("    ..._generatedDrinks,")
    add("  ];")
    add("")
    add("  static const List<DrinkRecommendation> _curatedDrinks = [")
    lines.extend(curated_body.splitlines())
    add("  ];")
    add("")
    add("  static final List<DrinkRecommendation> _generatedDrinks = [")
    for stem in generated_stems:
        brand, name = parse_stem(stem)
        category = infer_category(brand, name)
        description = DESCRIPTION_BY_CATEGORY[category]
        tags = tags_for(category, brand, name)
        drink_id = "drink_" + "_".join(format(rune, "x") for rune in stem.encode("utf-32-le")[::4])
        add("    DrinkRecommendation(")
        add(f"      id: {dart_quote(drink_id)},")
        add(f"      brand: {dart_quote(brand)},")
        add(f"      name: {dart_quote(name)},")
        add(f"      category: {dart_quote(category)},")
        add(f"      description: {dart_quote(description)},")
        add(f"      imagePath: '$_root/{stem}.webp',")
        add(f"      tags: [{', '.join(dart_quote(tag) for tag in tags)}],")
        add("    ),")
    add("  ];")
    add("")
    add("  static List<DrinkRecommendation> byCategory(String? category) {")
    add("    if (category == null || category == '全部') return drinks;")
    add("    return drinks.where((drink) => drink.category == category).toList();")
    add("  }")
    add("")
    add("  static DrinkRecommendation todayRecommendation([DateTime? now]) {")
    add("    final date = now ?? DateTime.now();")
    add("    final day = DateTime(")
    add("      date.year,")
    add("      date.month,")
    add("      date.day,")
    add("    ).difference(DateTime(2026)).inDays;")
    add("    return drinks[day.abs() % drinks.length];")
    add("  }")
    add("}")

    return "\n".join(lines) + "\n"


def main() -> None:
    source = MODEL_FILE.read_text(encoding="utf-8")
    curated_body = parse_curated_block(source)
    stems = sorted(path.stem for path in ASSET_DIR.glob("*.webp"))
    MODEL_FILE.write_text(build_file(curated_body, stems), encoding="utf-8")
    print(f"Rebuilt drink catalog with {len(stems)} asset-backed entries.")


if __name__ == "__main__":
    main()
