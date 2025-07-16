
@group(0) @binding(0) var<uniform> settings: Settings;
@group(0) @binding(1) var<storage, read_write> noiseBuffer: array<f32>;
@group(0) @binding(2) var<storage, read_write> outputBuffer: array<f32>;

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
  let generatorIndex = u32(settings.generatorIndex);
  let resolutionX = u32(settings.resolutionX);
  let resolutionY = u32(settings.resolutionY);
  let resolutionZ = u32(settings.resolutionZ);
  let xTiles = u32(settings.xTiles);
  let yTiles = u32(settings.yTiles);
  let channel0generator = u32(settings.channel0generator);
  let channel0type = u32(settings.channel0type);
  let channel0invert = u32(settings.channel0invert) != 0u;
  let channel1generator = u32(settings.channel1generator);
  let channel1type = u32(settings.channel1type);
  let channel1invert = u32(settings.channel1invert) != 0u;
  let channel2generator = u32(settings.channel2generator);
  let channel2type = u32(settings.channel2type);
  let channel2invert = u32(settings.channel2invert) != 0u;
  let channel3generator = u32(settings.channel3generator);
  let channel3type = u32(settings.channel3type);
  let channel3invert = u32(settings.channel3invert) != 0u;
  let normalScale = 1.0;

  let fragX = u32(fragCoord.x);
  let fragY = u32(fragCoord.y);
  let tileX = fragX / resolutionX;
  let tileY = fragY / resolutionY;
  let x = fragX % resolutionX;
  let y = fragY % resolutionY;
  let z = tileX + xTiles * tileY;

  let outputIndex = fragX + (resolutionX * xTiles) * fragY;
  let index = x + resolutionX * y + resolutionX * resolutionY * z;
  let indexL = ((x + 1) % resolutionX) + resolutionX * y + resolutionX * resolutionY * z;
  let indexB = x + resolutionX * ((y + 1) % resolutionY) + resolutionX * resolutionY * z;

  var values: array<array<f32, 5>, 4>;

  for (var i = 0u; i < 4; i++) {
    let g =  noiseBuffer[index  * 4 + i];
    let gl = noiseBuffer[indexL * 4 + i];
    let gb = noiseBuffer[indexB * 4 + i];
    let gdx = (g - gl) * f32(resolutionX) * normalScale * 0.1;
    let gdy = (g - gb) * f32(resolutionY) * normalScale * 0.1;
    let glength = sqrt(gdx * gdx + gdy * gdy + 1.0);
    let gdxn = (-gdx / glength * 0.5) + 0.5;
    let gdyn = (-gdy / glength * 0.5) + 0.5;
    values[i][0] = g;
    values[i][1] = gdxn;
    values[i][2] = gdyn;
    values[i][3] = 0.0;
    values[i][4] = 1.0;
  }
  

  var outputR = values[channel0generator][channel0type];
  var outputG = values[channel1generator][channel1type];
  var outputB = values[channel2generator][channel2type];
  var outputA = values[channel3generator][channel3type];

  if (channel0invert) { outputR = 1.0 - outputR; };
  if (channel1invert) { outputG = 1.0 - outputG; };
  if (channel2invert) { outputG = 1.0 - outputB; };
  if (channel3invert) { outputA = 1.0 - outputA; };

  let output = vec4<f32>(outputR, outputG, outputB, outputA);

  outputBuffer[outputIndex * 4 + 0] = output.r;
  outputBuffer[outputIndex * 4 + 1] = output.g;
  outputBuffer[outputIndex * 4 + 2] = output.b;
  outputBuffer[outputIndex * 4 + 3] = output.a;

  let checkerColor = (floor(f32(fragX) * 0.1) + floor(f32(fragY) * 0.1)) % 2.0 * 0.2 + 0.2;
  let background = vec4<f32>(checkerColor, checkerColor, checkerColor, checkerColor);

  return alphaBlend(output, background);
}