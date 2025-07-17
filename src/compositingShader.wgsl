
@group(0) @binding(0) var<uniform> settings: Settings;
@group(0) @binding(1) var<storage, read_write> noiseBuffer: array<float>;
@group(0) @binding(2) var<storage, read_write> outputBuffer: array<float>;

@vertex
fn vertex(@builtin(vertex_index) i: uint) -> @builtin(position) float4 {
  var pos = array<float2, 6>(
    float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0),
    float2(-1.0, 1.0), float2(1.0, -1.0), float2(1.0, 1.0)
  );
  return float4(pos[i], 0.0, 1.0);
}

@fragment
fn fragment(@builtin(position) fragCoord: float4) -> @location(0) float4 {
  let generatorIndex = uint(settings.generatorIndex);
  let resolutionX = uint(settings.resolutionX);
  let resolutionY = uint(settings.resolutionY);
  let resolutionZ = uint(settings.resolutionZ);
  let xTiles = uint(settings.xTiles);
  let yTiles = uint(settings.yTiles);
  let channel0generator = uint(settings.channel0generator);
  let channel0type = uint(settings.channel0type);
  let channel0invert = uint(settings.channel0invert) != 0u;
  let channel1generator = uint(settings.channel1generator);
  let channel1type = uint(settings.channel1type);
  let channel1invert = uint(settings.channel1invert) != 0u;
  let channel2generator = uint(settings.channel2generator);
  let channel2type = uint(settings.channel2type);
  let channel2invert = uint(settings.channel2invert) != 0u;
  let channel3generator = uint(settings.channel3generator);
  let channel3type = uint(settings.channel3type);
  let channel3invert = uint(settings.channel3invert) != 0u;
  let normalScale = 1.0;

  let fragX = uint(fragCoord.x);
  let fragY = uint(fragCoord.y);
  let tileX = fragX / resolutionX;
  let tileY = fragY / resolutionY;
  let x = fragX % resolutionX;
  let y = fragY % resolutionY;
  let z = tileX + xTiles * tileY;

  let outputIndex = fragX + (resolutionX * xTiles) * fragY;
  let index = x + resolutionX * y + resolutionX * resolutionY * z;
  let indexL = ((x + 1) % resolutionX) + resolutionX * y + resolutionX * resolutionY * z;
  let indexB = x + resolutionX * ((y + 1) % resolutionY) + resolutionX * resolutionY * z;

  var values: array<array<float, 5>, 4>;

  for (var i = 0u; i < 4; i++) {
    let g =  noiseBuffer[index  * 4 + i];
    let gl = noiseBuffer[indexL * 4 + i];
    let gb = noiseBuffer[indexB * 4 + i];
    let gdx = (g - gl) * float(resolutionX) * normalScale * 0.1;
    let gdy = (g - gb) * float(resolutionY) * normalScale * 0.1;
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

  let output = float4(outputR, outputG, outputB, outputA);

  outputBuffer[outputIndex * 4 + 0] = output.r;
  outputBuffer[outputIndex * 4 + 1] = output.g;
  outputBuffer[outputIndex * 4 + 2] = output.b;
  outputBuffer[outputIndex * 4 + 3] = output.a;

  let checkerColor = (floor(float(fragX) * 0.1) + floor(float(fragY) * 0.1)) % 2.0 * 0.2 + 0.2;
  let background = float4(checkerColor, checkerColor, checkerColor, checkerColor);

  return alpha_blend(output, background);
}