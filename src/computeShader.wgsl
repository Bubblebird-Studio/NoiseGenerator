
@group(0) @binding(0) var<uniform> settings: Settings;
@group(0) @binding(1) var<storage, read_write> noiseBuffer: array<float>;


fn InsertSorted(distances: float4, value: float) -> float4 {
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


fn simplex_noise3D(p: float3, period: int) -> float {
  // Skew
  let s = f32(p.x + p.y + p.z) * F3;
  let i = floor(p + s);
  let t = (i.x + i.y + i.z) * G3;
  let x0 = p - (i - t);

  // Simplex corners
  let g = step(x0.yzx, x0.xyz);
  let l = 1.0 - g;
  let i1 = min(g.xyz, l.zxy);
  let i2 = max(g.xyz, l.zxy);

  // Cell coordinates
  let x1 = x0 - i1 + G3;
  let x2 = x0 - i2 + 2.0 * G3;
  let x3 = x0 - 1.0 + 3.0 * G3;

  // Permutation indices (tiled)
  let ii = int3(i) % period;
  let i1_ = ii + int3(i1);
  let i2_ = ii + int3(i2);
  let i3_ = ii + 1;

  // Hash gradients (fully tiled)
  let period_float = float(period);
  let h0 = permute(permute(permute(float(ii.x), period_float) + float(ii.y), period_float) + float(ii.z), period_float);
  let h1 = permute(permute(permute(float(i1_.x), period_float) + float(i1_.y), period_float) + float(i1_.z), period_float);
  let h2 = permute(permute(permute(float(i2_.x), period_float) + float(i2_.y), period_float) + float(i2_.z), period_float);
  let h3 = permute(permute(permute(float(i3_.x), period_float) + float(i3_.y), period_float) + float(i3_.z), period_float);

  let g0 = grad(h0);
  let g1 = grad(h1);
  let g2 = grad(h2);
  let g3 = grad(h3);

  let t0 = 0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3));
  var n = max(t0, float4(0.0));
  n = n * n;
  n = n * n;

  let d = float4(dot(g0, x0), dot(g1, x1), dot(g2, x2), dot(g3, x3));

  return dot(n, d) * 32.0;  // Scale to [-1,1]
}


@compute @workgroup_size(4, 4, 4)
fn main(@builtin(global_invocation_id) coord: uint3) {
  let generatorIndex = uint(settings.generatorIndex);
  let resolutionX = uint(settings.resolutionX);
  let resolutionY = uint(settings.resolutionY);
  let resolutionZ = uint(settings.resolutionZ);
  let xTiles = uint(settings.xTiles);
  let yTiles = uint(settings.yTiles);
  let noiseType = uint(settings.noiseType);
  let perlinSize = float(settings.perlinSize);
  let perlinOctaves = uint(settings.perlinOctaves);
  let perlinLacunarity = float(settings.perlinLacunarity);
  let voronoiCellSize = float(settings.voronoiCellSize);
  let voronoiFalloff = float(settings.voronoiFalloff);
  let voronoiWeight1 = float(settings.voronoiWeight1);
  let voronoiWeight2 = float(settings.voronoiWeight2);
  let voronoiWeight3 = float(settings.voronoiWeight3);
  let voronoiWeight4 = float(settings.voronoiWeight4);
  let seamless = uint(settings.seamless) != 0u;
  let seed = uint(settings.seed);

  let x = coord.x;
  let y = coord.y;
  let z = coord.z;
  
  let resolution = uint3(resolutionX, resolutionY, resolutionZ);
  let index = x + resolutionX * y + resolutionX * resolutionY * z;
  var output = 0.0;

  //if (x >= settings.width || y >= settings.height || z >= settings.depth) return;

  if (noiseType == NOISE_TYPE_RANDOM) {
    output = rand01(hash_int3(int3(coord)) + seed);
  }

  if (noiseType == NOISE_TYPE_PERLIN) {
    let period = 32;
    let pos = float3(coord) / float3(resolution) * float3(float(period)) / float3(perlinSize);
    let amplitude = 1.0;
    var frequency = 1.0;
    var sum = 0.0;
    var maxAmplitude = 0.0;

    for (var i = 0u; i < perlinOctaves; i++)
    {
        sum += simplex_noise3D(pos * frequency, period) * amplitude;
        maxAmplitude += amplitude;

        frequency *= perlinLacunarity;
        //amplitude *= gain;
    }

    output = sum / maxAmplitude;
  }

  if (noiseType == NOISE_TYPE_VORONOI) {
    let cellSize = voronoiCellSize * float(resolutionX);
    let gridResolution = int3(max(float3(1.0), float3(resolution) / cellSize));
    let tileSize = float3(gridResolution) * cellSize;

    let position = float3(float(x), float(y), float(z)) / float3(resolution) * tileSize;
    let cell = int3(floor(position / cellSize));

    let weights = float4(voronoiWeight1, voronoiWeight2, voronoiWeight3, voronoiWeight4);
    var minDistances = float4(999999.0, 999999.0, 999999.0, 999999.0);

    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (var dz = -1; dz <= 1; dz++) {
          var neighbor_cell = cell + int3(dx, dy, dz);
          if (seamless) {
            neighbor_cell = neighbor_cell % gridResolution;
          }

          let feature_point = (float3(neighbor_cell) + rand_vector(hash_int3(neighbor_cell) + seed)) * cellSize;
          var delta = feature_point - position;
          if (seamless) {
            delta = min(abs(delta), tileSize - abs(delta)); // toroidal distance
          }
          let dist = length(delta) / cellSize;

          minDistances = InsertSorted(minDistances, dist);
        }
      }
    }

    output = pow(dot(minDistances, weights), voronoiFalloff);
  }
  
  noiseBuffer[index * 4 + generatorIndex] = output;
}