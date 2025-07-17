alias int = i32;
alias int2 = vec2<i32>;
alias int3 = vec3<i32>;
alias int4 = vec4<i32>;

alias uint = u32;
alias uint2 = vec2<u32>;
alias uint3 = vec3<u32>;
alias uint4 = vec4<u32>;

alias float = f32;
alias float2 = vec2<f32>;
alias float3 = vec3<f32>;
alias float4 = vec4<f32>;

const NOISE_TYPE_RANDOM = 0;
const NOISE_TYPE_PERLIN = 1;
const NOISE_TYPE_VORONOI = 2;

const VALUE_TYPE_VALUE = 0;
const VALUE_TYPE_NORMALX = 1;
const VALUE_TYPE_NORMALY = 2;
const VALUE_TYPE_0 = 3;
const VALUE_TYPE_1 = 4;

const F3 = 0.3333333;   // 1/3
const G3 = 0.1666667;   // 1/6

struct Settings {
  generatorIndex: float,
  resolutionX: float,
  resolutionY: float,
  resolutionZ: float,
  xTiles: float,
  yTiles: float,
  noiseType: float,
  perlinSize: float,
  perlinOctaves: float,
  perlinLacunarity: float,
  voronoiCellSize: float,
  voronoiFalloff: float,
  voronoiWeight1: float,
  voronoiWeight2: float,
  voronoiWeight3: float,
  voronoiWeight4: float,
  seamless: float,
  seed: float,
  channel0generator: float,
  channel0type: float,
  channel0invert: float,
  channel1generator: float,
  channel1type: float,
  channel1invert: float,
  channel2generator: float,
  channel2type: float,
  channel2invert: float,
  channel3generator: float,
  channel3type: float,
  channel3invert: float,
};



fn frac(x: float) -> float {
  return x - floor(x);
}


fn frac4(x: float4) -> float4 {
  return x - floor(x);
}


fn hash_int3(p: int3) -> uint {
  var h = 2166136261u;
  h = (h ^ uint(p.x)) * 16777619u;
  h = (h ^ uint(p.y)) * 16777619u;
  h = (h ^ uint(p.z)) * 16777619u;
  return h;
}


fn hash_uint(x: uint) -> uint {
    var h = x;
    h ^= h >> 16;
    h *= 0x85ebca6b;
    h ^= h >> 13;
    h *= 0xc2b2ae35;
    h ^= h >> 16;
    return h;
}


fn rand_vector(s: uint) -> float3 {
  let x = frac(sin(float(s + 1)) * 43758.5453);
  let y = frac(sin(float(s + 2)) * 12345.6789);
  let z = frac(sin(float(s + 3)) * 98765.4321);
  return float3(x, y, z);
}


fn rand01(hash: uint) -> float {
    // Mask to keep only the positive 31 bits
    let mixed = hash_uint(hash);
    let masked: uint = (mixed & 0x7FFFFFFF);
    // Convert to float and normalize to [0.0, 1.0)
    return float(masked) / float(0x7FFFFFFF);
}


fn alpha_blend(fg: float4, bg: float4) -> float4 {
    let outAlpha = fg.a + bg.a * (1.0 - fg.a);
    if (outAlpha == 0.0) {
        return float4(0.0);
    }

    let outRgb = (fg.rgb * fg.a + bg.rgb * bg.a * (1.0 - fg.a)) / outAlpha;
    return float4(outRgb, outAlpha);
}


fn mod289(x: float3) -> float3 {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}


fn permute(x: float, period: float) -> float {
    return ((34.0 * x + 1.0) * x) % float(period);
}


fn grad(hash: float) -> float3 {
    let h = int(hash) & 15;
    let grad = float3(
        select(1.0, -1.0, (h & 1) == 0),
        select(1.0, -1.0, (h & 2) == 0),
        select(1.0, -1.0, (h & 4) == 0)
    );
    return normalize(grad);
}