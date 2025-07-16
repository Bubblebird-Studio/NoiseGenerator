
@group(0) @binding(0) var<uniform> settings: Settings;
@group(0) @binding(1) var<storage, read_write> noiseBuffer: array<f32>;


fn InsertSorted(distances: vec4<f32>, value: f32) -> vec4<f32> {
    var d = distances;

    if (value < d.x) {
        d.w = d.z;
        d.z = d.y;
        d.y = d.x;
        d.x = value;
    } else if (value < d.y) {
        d.w = d.z;
        d.z = d.y;
        d.y = value;
    } else if (value < d.z) {
        d.w = d.z;
        d.z = value;
    } else if (value < d.w) {
        d.w = value;
    }
    return d;
}


@compute @workgroup_size(4, 4, 4)
fn main(@builtin(global_invocation_id) coord: vec3<u32>) {
  let generatorIndex = u32(settings.generatorIndex);
  let resolutionX = u32(settings.resolutionX);
  let resolutionY = u32(settings.resolutionY);
  let resolutionZ = u32(settings.resolutionZ);
  let xTiles = u32(settings.xTiles);
  let yTiles = u32(settings.yTiles);
  let noiseType = u32(settings.noiseType);
  let perlinSize = f32(settings.perlinSize);
  let perlinOctaves = u32(settings.perlinOctaves);
  let perlinLacunarity = f32(settings.perlinLacunarity);
  let voronoiCellSize = f32(settings.voronoiCellSize);
  let voronoiFalloff = f32(settings.voronoiFalloff);
  let voronoiWeight1 = f32(settings.voronoiWeight1);
  let voronoiWeight2 = f32(settings.voronoiWeight2);
  let voronoiWeight3 = f32(settings.voronoiWeight3);
  let voronoiWeight4 = f32(settings.voronoiWeight4);
  let seamless = u32(settings.seamless) != 0u;
  let seed = u32(settings.seed);

  let x = coord.x;
  let y = coord.y;
  let z = coord.z;
  
  let resolution = vec3<u32>(resolutionX, resolutionY, resolutionZ);
  let index = x + resolutionX * y + resolutionX * resolutionY * z;
  var output = 0.0;

  //if (x >= settings.width || y >= settings.height || z >= settings.depth) return;

  if (noiseType == NOISE_TYPE_RANDOM) {
    let fx = f32(x);
    let fy = f32(y);
    let fz = f32(z);
    output = Rand01(Hash_vec3_i32(vec3<i32>(coord)) + seed);
  }

  if (noiseType == NOISE_TYPE_PERLIN) {
    var v = vec3<f32>(f32(x) / f32(resolutionX), f32(y) / f32(resolutionY), f32(z) / f32(resolutionZ)) * perlinSize;

    // Wrap the input coordinates to enforce tiling
    //v = fmod(v, vec3<f32>(perlinSize));

    // Skew the input space to find simplex cell
    let s: f32 = (v.x + v.y + v.z) * F3;
    let i: vec3<f32> = floor(v + s);
    let t: f32 = (i.x + i.y + i.z) * G3;
    let X0: vec3<f32> = i - t;
    let x0: vec3<f32> = v - X0;

    // Determine simplex corner ordering
    let g: vec3<f32> = step(x0.yzx, x0.xyz);
    let l: vec3<f32> = 1.0 - g;
    let i1: vec3<f32> = min(g.xyz, l.zxy);
    let i2: vec3<f32> = max(g.xyz, l.zxy);

    // Offsets for corners
    let x1: vec3<f32> = x0 - i1 + G3;
    let x2: vec3<f32> = x0 - i2 + 2.0 * G3;
    let x3: vec3<f32> = x0 - 1.0 + 3.0 * G3;

    // Calculate hashed gradients
    let ii: vec4<f32> = mod289_4(float4(i.x, i.x + i1.x, i.x + i2.x, i.x + 1.0));
    let jj: vec4<f32> = mod289_4(float4(i.y, i.y + i1.y, i.y + i2.y, i.y + 1.0));
    let kk: vec4<f32> = mod289_4(float4(i.z, i.z + i1.z, i.z + i2.z, i.z + 1.0));

    let perm: vec4<f32> = permute(permute(permute(ii) + jj) + kk);
    var gx: vec4<f32> = frac4(perm * (1.0 / 41.0)) * 2.0 - 1.0;
    let gy: vec4<f32> = abs(gx) - 0.5;
    let tx: vec4<f32> = floor(gx + 0.5);
    gx = gx - tx;

    var g0 = vec3<f32>(gx.x, gy.x, 1.0 - abs(gx.x) - abs(gy.x));
    var g1 = vec3<f32>(gx.y, gy.y, 1.0 - abs(gx.y) - abs(gy.y));
    var g2 = vec3<f32>(gx.z, gy.z, 1.0 - abs(gx.z) - abs(gy.z));
    var g3 = vec3<f32>(gx.w, gy.w, 1.0 - abs(gx.w) - abs(gy.w));

    // Normalize gradients
    let norm: vec4<f32> = taylorInvSqrt(vec4<f32>(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
    g0 *= norm.x;
    g1 *= norm.y;
    g2 *= norm.z;
    g3 *= norm.w;

    // Calculate noise contributions
    let t0: vec4<f32> = 0.6 - vec4<f32>(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3));
    var n: vec4<f32> = max(t0, vec4<f32>(0.0));
    n = n * n * n * n;
    let dotProd = vec4<f32>(dot(g0,x0), dot(g1,x1), dot(g2,x2), dot(g3,x3));

    output = perlinSize * dot(n, dotProd) * 0.5 + 0.5;
  }

  if (noiseType == NOISE_TYPE_VORONOI) {
    let cellSize = voronoiCellSize * f32(resolutionX);
    let gridResolution = vec3<i32>(max(vec3<f32>(1.0), vec3<f32>(resolution) / cellSize));
    let tileSize = vec3<f32>(gridResolution) * cellSize;

    let position = vec3<f32>(f32(x), f32(y), f32(z)) / vec3<f32>(resolution) * tileSize;
    let cell = vec3<i32>(floor(position / cellSize));

    let weights = vec4<f32>(voronoiWeight1, voronoiWeight2, voronoiWeight3, voronoiWeight4);
    var minDistances = vec4<f32>(999999.0, 999999.0, 999999.0, 999999.0);

    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (var dz = -1; dz <= 1; dz++) {
          var neighbor_cell = cell + vec3<i32>(dx, dy, dz);
          if (seamless) {
            neighbor_cell = modulo_i32(neighbor_cell, gridResolution);
          }

          let feature_point = (vec3<f32>(neighbor_cell) + RandVector(Hash_vec3_i32(neighbor_cell) + seed)) * cellSize;
          var delta = feature_point - position;
          if (seamless) {
            delta = min(abs(delta), tileSize - abs(delta)); // toroidal distance
          }
          let dist = length(delta); // / cellSize;

          minDistances = InsertSorted(minDistances, dist);
        }
      }
    }

    output = pow(dot(minDistances, weights), voronoiFalloff);
  }
  
  noiseBuffer[index * 4 + generatorIndex] = output;
}