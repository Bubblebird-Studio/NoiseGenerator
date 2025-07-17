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

const VORONOI_DISTANCE_TYPE_EUCLIDEAN = 0;
const VORONOI_DISTANCE_TYPE_SQUARED = 1;
const VORONOI_DISTANCE_TYPE_MANHATTAN = 2;
const VORONOI_DISTANCE_TYPE_CHEBYSHEV = 3;

const VALUE_TYPE_VALUE = 0;
const VALUE_TYPE_NORMALX = 1;
const VALUE_TYPE_NORMALY = 2;
const VALUE_TYPE_0 = 3;
const VALUE_TYPE_1 = 4;


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
  voronoiWeight1: float,
  voronoiWeight2: float,
  voronoiWeight3: float,
  voronoiWeight4: float,
  voronoiDistanceType: float,
  seamless: float,
  seed: float,
  channel0display: float,
  channel0generator: float,
  channel0type: float,
  channel0invert: float,
  channel0gain: float,
  channel0gamma: float,
  channel0offset: float,
  channel1display: float,
  channel1generator: float,
  channel1type: float,
  channel1invert: float,
  channel1gain: float,
  channel1gamma: float,
  channel1offset: float,
  channel2display: float,
  channel2generator: float,
  channel2type: float,
  channel2invert: float,
  channel2gain: float,
  channel2gamma: float,
  channel2offset: float,
  channel3display: float,
  channel3generator: float,
  channel3type: float,
  channel3invert: float,
  channel3gain: float,
  channel3gamma: float,
  channel3offset: float,
};


fn hash_int3(v: int3) -> uint {
    var x: u32 = bitcast<u32>(v.x);
    var y: u32 = bitcast<u32>(v.y);
    var z: u32 = bitcast<u32>(v.z);

    var h: u32 = 0xdeadbeefu;
    h ^= x + 0x9e3779b9u + (h << 6) + (h >> 2);
    h ^= y + 0x9e3779b9u + (h << 6) + (h >> 2);
    h ^= z + 0x9e3779b9u + (h << 6) + (h >> 2);

    h ^= h >> 16;
    h *= 0x85ebca6bu;
    h ^= h >> 13;
    h *= 0xc2b2ae35u;
    h ^= h >> 16;

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


fn rand_vector(hash: uint) -> float3 {
  let x = hash_uint(hash ^ 0xA53C9A1F);
  let y = hash_uint(hash ^ 0xC2B2AE35);
  let z = hash_uint(hash ^ 0x27D4EB2F);
  
  return float3(f32(x) / 4294967296.0, f32(y) / 4294967296.0, f32(z) / 4294967296.0);
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


fn fade(t: float3) -> float3 {
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}


fn grad(hash: uint, p: float3) -> float {
  let h = hash & 15;
  return dot(rand_vector(h) * 2.0 - 1.0, p);
}