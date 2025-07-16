
@group(0) @binding(0) var<uniform> settings: Settings;
@group(0) @binding(1) var<storage, read_write> noiseBuffer: array<f32>;

@vertex
fn vertex(@builtin(vertex_index) i: u32) -> @builtin(position) vec4<f32> {
    var pos = array<vec2<f32>, 6>(
        vec2<f32>(-1.0, -1.0), vec2<f32>(1.0, -1.0), vec2<f32>(-1.0, 1.0),
        vec2<f32>(-1.0, 1.0), vec2<f32>(1.0, -1.0), vec2<f32>(1.0, 1.0)
    );
    return vec4<f32>(pos[i], 0.0, 1.0);
}

@fragment
fn fragment(@builtin(position) fragCoord: vec4<f32>) -> @location(0) vec4<f32> {
    let fragX = u32(fragCoord.x);
    let fragY = u32(fragCoord.y);
    let width = u32(settings.width);
    let height = u32(settings.height);
    let depth = u32(settings.depth);
    let xTiles = u32(settings.xTiles);
    let yTiles = u32(settings.yTiles);
    let tileResolutionX = width / xTiles;
    //let yTileResolution = height / yTiles;

    let tileX = fragX / width;
    let tileY = fragY / height;
    let x = (fragX) % width;
    let y = (fragY) % height;
    let z = tileX + tileResolutionX * tileY;

    let index = x + width * y + width * height * z;

    var p = noiseBuffer[index];
    return vec4<f32>(p, 0.0, 0.0, 1.0);
    //return vec4<f32>(f32(x) / f32(width), f32(y) / f32(height), 0.0, 1.0);
}