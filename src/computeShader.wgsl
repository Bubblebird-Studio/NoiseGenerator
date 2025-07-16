

struct Settings {
  width: f32,
  height: f32,
  depth: f32,
  xTiles: f32,
  yTiles: f32,
  seamless: f32,
  seed: f32,
  scale: f32,
};

@group(0) @binding(0) var<uniform> settings: Settings;
@group(0) @binding(1) var<storage, read_write> noiseBuffer: array<f32>;


fn frac(x: f32) -> f32 {
  return x - floor(x);
}

fn RandVector(s: u32) -> vec3<f32> {
  let x = frac(sin(f32(s + 1)) * 43758.5453);
  let y = frac(sin(f32(s + 2)) * 12345.6789);
  let z = frac(sin(f32(s + 3)) * 98765.4321);
  return vec3<f32>(x, y, z);
}

fn HashInt3(p: vec3<i32>) -> u32 {
  var h: u32 = 2166136261u;
  h = (h ^ u32(p.x)) * 16777619u;
  h = (h ^ u32(p.y)) * 16777619u;
  h = (h ^ u32(p.z)) * 16777619u;
  return h;
}

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
fn main(@builtin(global_invocation_id) id: vec3<u32>) {
  let x = id.x;
  let y = id.y;
  let z = id.z;
  let width = u32(settings.width);
  let height = u32(settings.height);
  let depth = u32(settings.depth);
  let seed = u32(settings.seed);
  let index = x + width * y + width * height * z;

  //if (x >= settings.width || y >= settings.height || z >= settings.depth) return;


  let position = vec3<f32>(f32(x), f32(y), f32(z)) / 20.0;

  let cell = vec3<i32>(position);
  //let weights = vec4<f32>(0.588, -0.76, -1.175, -0.788);
  let weights = vec4<f32>(1.0, 0.0, 0, 0);
  var minDistances = vec4<f32>(99999.0, 99999.0, 99999.0, 99999.0);
  var minDist = f32(9999999.0);

  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dz = -1; dz <= 1; dz++) {
        let neighbor_cell = cell + vec3<i32>(dx, dy, dz);
        let feature_point = vec3<f32>(neighbor_cell) + RandVector(HashInt3(neighbor_cell) + seed);
        let delta = feature_point - position;
        let dist = length(delta);
        if (dist < minDist) {
          minDist = dist;
        }
        minDistances = insert_sorted(minDistances, dist);
      }
    }
  }

  let d = dot(minDistances, weights);

  let test = HashInt3(cell);

  noiseBuffer[index] = d;


  // TEMP: fill with placeholder noise (random seed-based)
  let fx = f32(x); // / settings.scale;
  let fy = f32(y); // / settings.scale;
  let fz = f32(z); // / settings.scale;
  //noiseBuffer[index] = fract(sin(dot(vec3<f32>(fx, fy, fz), vec3<f32>(12.9898, 78.233, 45.164))) * 43758.5453);
  //noiseBuffer[index] = f32(x) / f32(settings.width);
}