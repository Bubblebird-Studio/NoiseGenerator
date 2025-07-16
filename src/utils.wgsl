const NOISE_TYPE_RANDOM: u32 = 0;
const NOISE_TYPE_PERLIN: u32 = 1;
const NOISE_TYPE_VORONOI: u32 = 2;

const VALUE_TYPE_VALUE: u32 = 0;
const VALUE_TYPE_NORMALX: u32 = 1;
const VALUE_TYPE_NORMALY: u32 = 2;
const VALUE_TYPE_0: u32 = 3;
const VALUE_TYPE_1: u32 = 4;

struct Settings {
  generatorIndex: f32,
  resolutionX: f32,
  resolutionY: f32,
  resolutionZ: f32,
  xTiles: f32,
  yTiles: f32,
  noiseType: f32,
  perlinSize: f32,
  perlinOctaves: f32,
  perlinLacunarity: f32,
  voronoiCellSize: f32,
  voronoiFalloff: f32,
  voronoiWeight1: f32,
  voronoiWeight2: f32,
  voronoiWeight3: f32,
  voronoiWeight4: f32,
  seamless: f32,
  seed: f32,
  channel0generator: f32,
  channel0type: f32,
  channel0invert: f32,
  channel1generator: f32,
  channel1type: f32,
  channel1invert: f32,
  channel2generator: f32,
  channel2type: f32,
  channel2invert: f32,
  channel3generator: f32,
  channel3type: f32,
  channel3invert: f32,
};



fn frac(x: f32) -> f32 {
  return x - floor(x);
}


fn Hash_vec3_i32(p: vec3<i32>) -> u32 {
  var h: u32 = 2166136261u;
  h = (h ^ u32(p.x)) * 16777619u;
  h = (h ^ u32(p.y)) * 16777619u;
  h = (h ^ u32(p.z)) * 16777619u;
  return h;
}

fn Hash_u32(x: u32) -> u32 {
    var h = x;
    h ^= h >> 16;
    h *= 0x85ebca6b;
    h ^= h >> 13;
    h *= 0xc2b2ae35;
    h ^= h >> 16;
    return h;
}

fn RandVector(s: u32) -> vec3<f32> {
  let x = frac(sin(f32(s + 1)) * 43758.5453);
  let y = frac(sin(f32(s + 2)) * 12345.6789);
  let z = frac(sin(f32(s + 3)) * 98765.4321);
  return vec3<f32>(x, y, z);
}

fn Rand01(hash: u32) -> f32 {
    // Mask to keep only the positive 31 bits
    let mixed = Hash_u32(hash);
    let masked: u32 = (mixed & 0x7FFFFFFF);
    // Convert to float and normalize to [0.0, 1.0)
    return f32(masked) / f32(0x7FFFFFFF);
}

fn modulo_i32(v: vec3<i32>, m: vec3<i32>) -> vec3<i32> {
  return ((v % m) + m) % m;
}

fn toroidal_distance(a: vec3<f32>, b: vec3<f32>, tileSize: vec3<f32>) -> f32 {
  let delta = abs(a - b);
  let wrapped = min(delta, tileSize - delta);
  return length(wrapped);
}

fn alphaBlend(fg: vec4<f32>, bg: vec4<f32>) -> vec4<f32> {
    let outAlpha = fg.a + bg.a * (1.0 - fg.a);
    if (outAlpha == 0.0) {
        return vec4<f32>(0.0);
    }

    let outRgb = (fg.rgb * fg.a + bg.rgb * bg.a * (1.0 - fg.a)) / outAlpha;
    return vec4<f32>(outRgb, outAlpha);
}