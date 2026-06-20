/// 天气卡片全部资源路径统一管理
///
/// 所有组件只能引用这个类的常量，不允许散写字符串路径。
class WeatherAssets {
  WeatherAssets._();

  static const _cats = 'assets/images/weather/cats';
  static const _bg = 'assets/images/weather/backgrounds';
  static const _fg = 'assets/images/weather/foregrounds';
  static const _lights = 'assets/images/weather/lights';
  static const _particles = 'assets/images/weather/particles';

  // ── Cats ──
  static const catSunny = '$_cats/cat_sunny.webp';
  static const catCloudy = '$_cats/cat_cloudy.webp';
  static const catRainy = '$_cats/cat_rainy.webp';
  static const catHeavyRain = '$_cats/cat_heavy_rain.webp';
  static const catSnowy = '$_cats/cat_snowy.webp';
  static const catWindy = '$_cats/cat_windy.webp';
  static const catHot = '$_cats/cat_hot.webp';
  static const catNight = '$_cats/cat_night.webp';

  // ── Backgrounds ──
  static const bgSunny = '$_bg/bg_sunny.webp';
  static const bgCloudy = '$_bg/bg_cloudy.webp';
  static const bgRainy = '$_bg/bg_rainy.webp';
  static const bgHeavyRain = '$_bg/bg_heavy_rain.webp';
  static const bgSnowy = '$_bg/bg_snowy.webp';
  static const bgWindy = '$_bg/bg_windy.webp';
  static const bgHot = '$_bg/bg_hot.webp';
  static const bgNight = '$_bg/bg_night.webp';

  // ── Foregrounds ──
  static const fgSunnyFlower = '$_fg/fg_sunny_flower.webp';
  static const fgCloudyGrass = '$_fg/fg_cloudy_grass.webp';
  static const fgRainyPuddle = '$_fg/fg_rainy_puddle.webp';
  static const fgHeavyRainWindow = '$_fg/fg_heavy_rain_window.webp';
  static const fgSnowySnowbank = '$_fg/fg_snowy_snowbank.webp';
  static const fgWindyLeafground = '$_fg/fg_windy_leafground.webp';
  static const fgHotGround = '$_fg/fg_hot_ground.webp';
  static const fgNightWindow = '$_fg/fg_night_window.webp';

  // ── Lights ──
  static const sunGlow = '$_lights/sun_glow.webp';
  static const lightCloudSoft = '$_lights/light_cloud_soft.webp';
  static const lightRainGlow = '$_lights/light_rain_glow.webp';
  static const lightStormGlow = '$_lights/light_storm_glow.webp';
  static const lightSnowGlow = '$_lights/light_snow_glow.webp';
  static const lightWindyGlow = '$_lights/light_windy_glow.webp';
  static const sunGlowHot = '$_lights/sun_glow_hot.webp';
  static const lightMoonGlow = '$_lights/light_moon_glow.webp';

  // ── Particles ──
  static const particleSparkle1 = '$_particles/particle_sparkle_1.webp';
  static const particleSparkle2 = '$_particles/particle_sparkle_2.webp';
  static const particleCloud1 = '$_particles/particle_cloud_1.webp';
  static const particleCloud2 = '$_particles/particle_cloud_2.webp';
  static const particleRaindrop1 = '$_particles/particle_raindrop_1.webp';
  static const particleRaindrop2 = '$_particles/particle_raindrop_2.webp';
  static const particleRaindrop3 = '$_particles/particle_raindrop_3.webp';
  static const particleRainHeavy1 = '$_particles/particle_rain_heavy_1.webp';
  static const particleRainHeavy2 = '$_particles/particle_rain_heavy_2.webp';
  static const particleSnowflake1 = '$_particles/particle_snowflake_1.webp';
  static const particleSnowflake2 = '$_particles/particle_snowflake_2.webp';
  static const particleSnowflake3 = '$_particles/particle_snowflake_3.webp';
  static const particleWindLine1 = '$_particles/particle_wind_line_1.webp';
  static const particleWindLine2 = '$_particles/particle_wind_line_2.webp';
  static const particleLeaf = '$_particles/particle_leaf.webp';
  static const particleHeat1 = '$_particles/particle_heat_1.webp';
  static const particleHeat2 = '$_particles/particle_heat_2.webp';
  static const particleStar1 = '$_particles/particle_star_1.webp';
  static const particleStar2 = '$_particles/particle_star_2.webp';
  static const particleMoonDust = '$_particles/particle_moon_dust.webp';

  // ── Common Overlays ──
  static const highlightOverlay =
      'assets/images/weather/common/highlight_overlay.webp';
}
