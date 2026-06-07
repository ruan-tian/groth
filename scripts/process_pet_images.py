import os
from pathlib import Path

def log(msg):
    print(f"[PetProcessor] {msg}", flush=True)

SRC_DIR = Path(r"F:\opencode\GROS\picture")
DST_BASE = Path(r"F:\opencode\GROS\growth_os\assets\pet")
TARGET_SIZE = 512
COLOR_DIST = 30

DIR_MAP = {
    "study_": "study",
    "fitness_": "fitness",
    "journal_": "journal",
    "diet_": "diet",
    "sleep_": "sleep",
    "common_": "common",
    "ai_": "ai",
    "empty_": "empty",
    "event_": "events",
}

SPECIAL_MAP = {
    "可爱": "life", "开心wink": "life", "大哭": "life", "好困": "life",
    "尴尬": "life", "惊讶": "life", "疑惑": "life", "打招呼": "life",
    "吃薯片": "life", "吃西瓜": "life", "吃饱了": "life", "喝个茶": "life",
    "喝可乐": "life", "听音乐": "life", "弹吉他唱歌": "life", "敲键盘": "life",
    "跳舞": "life", "荡秋千": "life", "玩毛球": "life", "抓蝴蝶": "life",
    "下雨打伞": "life", "举铁好重": "life", "夏天晒太阳": "life", "冬天堆雪人": "life",
    "春天菜花": "life", "秋天捡落叶": "life", "英语考试": "life",
    "和朋友一起吃饭png": "social", "和朋友一起打游戏": "social", "和朋友一起游泳": "social",
    "和朋友一起看海": "social", "和朋友一起羽毛球": "social", "和朋友一起购物": "social",
    "和朋友一起钓鱼": "social", "和朋友一起骑车": "social",
    "去中国故宫旅游": "travel", "去埃菲尔铁塔旅游被别人拍照": "travel",
    "去新西兰草原旅游": "travel", "去格陵兰岛冰川旅游": "travel",
    "去美国的纽约时代广场": "travel", "去非洲草原拍狮子": "travel",
    "日本东京富士山下看樱花": "travel",
    "参加ChrisJames演唱会": "concerts", "参加Imagine Dragons音乐会和其合影": "concerts",
    "参加OneRepublic音乐会": "concerts", "参加The Chainsmokers演唱会": "concerts",
    "参加邓紫棋演唱会": "concerts", "看周杰伦演唱": "concerts",
    "看贾斯汀比伯演唱会": "concerts", "没抢到K-pop 的演唱会门票伤心": "life",
    "可爱": "emotions", "开心wink": "emotions", "大哭": "emotions", "好困": "emotions",
    "尴尬": "emotions", "惊讶": "emotions", "疑惑": "emotions", "打招呼": "emotions",
}

def get_target_dir(filename):
    name = filename.replace(".png", "")
    for prefix, dir_name in DIR_MAP.items():
        if name.startswith(prefix):
            return dir_name
    return SPECIAL_MAP.get(name, "life")

def color_distance(c1, c2):
    return ((c1[0]-c2[0])**2 + (c1[1]-c2[1])**2 + (c1[2]-c2[2])**2) ** 0.5

def get_background_color(img):
    w, h = img.size
    corners = [
        img.getpixel((0, 0)),
        img.getpixel((w-1, 0)),
        img.getpixel((0, h-1)),
        img.getpixel((w-1, h-1)),
    ]
    avg_r = sum(c[0] for c in corners) // 4
    avg_g = sum(c[1] for c in corners) // 4
    avg_b = sum(c[2] for c in corners) // 4
    return (avg_r, avg_g, avg_b)

def process_image(src_path, dst_path):
    try:
        from PIL import Image
        img = Image.open(src_path).convert("RGBA")
        bg_color = get_background_color(img)
        
        pixels = img.load()
        w, h = img.size
        
        for y in range(h):
            for x in range(w):
                r, g, b, a = pixels[x, y]
                dist = color_distance((r, g, b), bg_color)
                if dist < COLOR_DIST:
                    pixels[x, y] = (r, g, b, 0)
                else:
                    pixels[x, y] = (r, g, b, 255)
        
        img = img.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
        img.save(dst_path, "PNG")
        
        size_kb = os.path.getsize(dst_path) // 1024
        return True, size_kb
    except Exception as e:
        return False, str(e)

def main():
    log("开始处理甜甜萌宠图片...")
    
    all_dirs = set(DIR_MAP.values()) | set(SPECIAL_MAP.values()) | {"life", "emotions", "social", "travel", "concerts"}
    for d in all_dirs:
        (DST_BASE / d).mkdir(parents=True, exist_ok=True)
    
    png_files = sorted([f for f in SRC_DIR.iterdir() if f.suffix == ".png"])
    log(f"找到 {len(png_files)} 张图片")
    
    success = skip = error = 0
    
    for i, src_file in enumerate(png_files, 1):
        filename = src_file.name
        target_dir = get_target_dir(filename)
        dst_path = DST_BASE / target_dir / filename
        
        if dst_path.exists() and dst_path.stat().st_size > 10000:
            skip += 1
            continue
        
        log(f"[{i}/{len(png_files)}] {filename} -> {target_dir}/")
        ok, result = process_image(str(src_file), str(dst_path))
        if ok:
            log(f"  完成: {result}KB")
            success += 1
        else:
            log(f"  失败: {result}")
            error += 1
    
    log(f"\n完成! 成功:{success} 跳过:{skip} 失败:{error} 总计:{len(png_files)}")

if __name__ == "__main__":
    main()
