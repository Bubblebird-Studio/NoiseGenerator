
@group(0) @binding(0) var<uniform> settings: Settings;
@group(0) @binding(1) var<storage, read_write> noiseBuffer: array<f32>;


fn insert_sorted(distances: vec4<f32>, value: f32) -> vec4<f32> {
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
  let width = u32(settings.width);
  let height = u32(settings.height);
  let depth = u32(settings.depth);
  let xTiles = u32(settings.xTiles);
  let yTiles = u32(settings.yTiles);
  let noiseType = u32(settings.noiseType);
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

  let tileResolutionX = width / xTiles;
  let tileResolutionY = height / yTiles;

  let x = coord.x;
  let y = coord.y;
  let z = coord.z;
  
  let index = x + width * y + width * height * z;
  var output = 0.0;

  //if (x >= settings.width || y >= settings.height || z >= settings.depth) return;

  if (noiseType == NOISE_TYPE_RANDOM) {
    let fx = f32(x);
    let fy = f32(y);
    let fz = f32(z);
    output = Rand01(Hash_vec3_i32(vec3<i32>(coord)) + seed);
  }

  if (noiseType == NOISE_TYPE_PERLIN) {
    output = 0;
  }

  if (noiseType == NOISE_TYPE_VORONOI) {
    let position = vec3<f32>(f32(x), f32(y), f32(z)) * voronoiCellSize;
    let cell = vec3<i32>(position);
    let weights = vec4<f32>(voronoiWeight1, voronoiWeight2, voronoiWeight3, voronoiWeight4); //vec4<f32>(0.588, -0.76, -1.175, -0.788);
    var minDistances = vec4<f32>(999999.0, 999999.0, 999999.0, 999999.0);

    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (var dz = -1; dz <= 1; dz++) {
          let neighbor_cell = cell + vec3<i32>(dx, dy, dz);
          let feature_point = vec3<f32>(neighbor_cell) + RandVector(Hash_vec3_i32(neighbor_cell) + seed);
          let delta = feature_point - position;
          let dist = length(delta);
          minDistances = insert_sorted(minDistances, dist);
        }
      }
    }

    output = pow(dot(minDistances, weights), voronoiFalloff);
  }
  

  noiseBuffer[index] = output;
}