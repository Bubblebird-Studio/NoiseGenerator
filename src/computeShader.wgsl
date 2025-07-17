
@group(0) @binding(0) var<uniform> settings: Settings;
@group(0) @binding(1) var<storage, read_write> noiseBuffer: array<float>;


fn insert_sorted(distances: float4, value: float) -> float4 {
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

  if (x >= resolutionX || y >= resolutionY || z >= resolutionZ) {
    return;
  };

  if (noiseType == NOISE_TYPE_RANDOM) {
    output = rand01(hash_int3(int3(coord)) + seed);
  }

  if (noiseType == NOISE_TYPE_PERLIN) {
    let grid_resolution = int(floor(1.0 / perlinSize));
    let position = float3(coord) / float3(resolution) * float(grid_resolution);
    var sum = 0.0;

    for (var i = 0u; i < perlinOctaves; i++)
    {
      let s = seed + i;
      let attenuation = floor(pow(perlinLacunarity, float(i)));
      let p = position * attenuation;
      let pi = int3(floor(p));
      let pf = fract(p);
      let f = fade(pf);

      let period = select(int3(100000000), int3(grid_resolution * int(attenuation)), seamless);

      let n000 = grad(hash_int3((pi + int3(0, 0, 0)) % period) + s, pf - float3(0, 0, 0));
      let n001 = grad(hash_int3((pi + int3(0, 0, 1)) % period) + s, pf - float3(0, 0, 1));
      let n010 = grad(hash_int3((pi + int3(0, 1, 0)) % period) + s, pf - float3(0, 1, 0));
      let n011 = grad(hash_int3((pi + int3(0, 1, 1)) % period) + s, pf - float3(0, 1, 1));
      let n100 = grad(hash_int3((pi + int3(1, 0, 0)) % period) + s, pf - float3(1, 0, 0));
      let n101 = grad(hash_int3((pi + int3(1, 0, 1)) % period) + s, pf - float3(1, 0, 1));
      let n110 = grad(hash_int3((pi + int3(1, 1, 0)) % period) + s, pf - float3(1, 1, 0));
      let n111 = grad(hash_int3((pi + int3(1, 1, 1)) % period) + s, pf - float3(1, 1, 1));

      let x00 = mix(n000, n100, f.x);
      let x01 = mix(n001, n101, f.x);
      let x10 = mix(n010, n110, f.x);
      let x11 = mix(n011, n111, f.x);

      let y0 = mix(x00, x10, f.y);
      let y1 = mix(x01, x11, f.y);

      sum += mix(y0, y1, f.z) / attenuation;
    }

    output = sum * 0.5 + 0.5;
  }

  if (noiseType == NOISE_TYPE_VORONOI) {
    let grid_resolution = int(floor(1.0 / voronoiCellSize));
    let position = float3(coord) / float3(resolution);
    let cellSize = 1.0 / float(grid_resolution);
    let cell = int3(floor(position * float(grid_resolution)));

    let weights = float4(voronoiWeight1, voronoiWeight2, voronoiWeight3, voronoiWeight4);
    var minDistances = float4(999999.0, 999999.0, 999999.0, 999999.0);

    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (var dz = -1; dz <= 1; dz++) {
          var neighbor_cell = cell + int3(dx, dy, dz);
          if (seamless) {
            neighbor_cell = (neighbor_cell + grid_resolution) % grid_resolution;
          }

          let feature_point = (float3(neighbor_cell) + rand_vector(hash_int3(neighbor_cell) + seed)) * cellSize;
          var delta = feature_point - position;
          if (seamless) {
            delta = min(abs(delta), 1.0 - abs(delta)); // toroidal distance
          }
          let dist = length(delta) / cellSize;

          // insert sorted
          if (dist < minDistances.x) {
            minDistances.w = minDistances.z;
            minDistances.z = minDistances.y;
            minDistances.y = minDistances.x;
            minDistances.x = dist;
          } else if (dist < minDistances.y) {
            minDistances.w = minDistances.z;
            minDistances.z = minDistances.y;
            minDistances.y = dist;
          } else if (dist < minDistances.z) {
            minDistances.w = minDistances.z;
            minDistances.z = dist;
          } else if (dist < minDistances.w) {
            minDistances.w = dist;
          }
        }
      }
    }

    output = dot(minDistances, weights);
  }
  
  noiseBuffer[index * 4 + generatorIndex] = output;
}