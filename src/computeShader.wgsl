
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


fn perlin_noise3D(p: float3, seed: uint) -> float {
  let pi = int3(floor(p));
  let pf = fract(p);
  let f = fade(pf);

  let n000 = grad(hash_int3(pi + int3(0, 0, 0)) + seed, pf - float3(0, 0, 0));
  let n001 = grad(hash_int3(pi + int3(0, 0, 1)) + seed, pf - float3(0, 0, 1));
  let n010 = grad(hash_int3(pi + int3(0, 1, 0)) + seed, pf - float3(0, 1, 0));
  let n011 = grad(hash_int3(pi + int3(0, 1, 1)) + seed, pf - float3(0, 1, 1));
  let n100 = grad(hash_int3(pi + int3(1, 0, 0)) + seed, pf - float3(1, 0, 0));
  let n101 = grad(hash_int3(pi + int3(1, 0, 1)) + seed, pf - float3(1, 0, 1));
  let n110 = grad(hash_int3(pi + int3(1, 1, 0)) + seed, pf - float3(1, 1, 0));
  let n111 = grad(hash_int3(pi + int3(1, 1, 1)) + seed, pf - float3(1, 1, 1));

  let x00 = mix(n000, n100, f.x);
  let x01 = mix(n001, n101, f.x);
  let x10 = mix(n010, n110, f.x);
  let x11 = mix(n011, n111, f.x);

  let y0 = mix(x00, x10, f.y);
  let y1 = mix(x01, x11, f.y);

  return mix(y0, y1, f.z);
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
    let pos = float3(coord) / float3(resolution) / float3(perlinSize);
    let amplitude = 1.0;
    var frequency = 1.0;
    var sum = 0.0;
    var maxAmplitude = 0.0;

    for (var i = 0u; i < perlinOctaves; i++)
    {
      sum += perlin_noise3D(pos * frequency, seed) * amplitude;
      maxAmplitude += amplitude;

      frequency *= perlinLacunarity;
      //amplitude *= gain;
    }

    output = sum / maxAmplitude * 0.5 + 0.5;
  }

  if (noiseType == NOISE_TYPE_VORONOI) {
    let cellSize = voronoiCellSize * float(resolutionX);
    let gridResolution = int3(max(float3(1.0), float3(resolution) / cellSize));
    let tileSize = float3(gridResolution) * cellSize;

    let position = float3(coord) / float3(resolution) * tileSize;
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