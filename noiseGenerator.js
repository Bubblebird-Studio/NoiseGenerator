/**
  This Noise Generator is licensed under the MIT License

  MIT License

  Copyright (c) 2025 BUBBLEBIRD STUDIO S.a.r.l.-S

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
 */

const canvas = document.getElementById("noiseCanvas");
const resSlider = document.getElementById("resSlider");
const seedInput = document.getElementById("seedInput");
const resLabel = document.getElementById("resLabel");
const noiseType = document.getElementById("noiseType");
const perlinScaleSlider = document.getElementById("perlinScaleSlider");
const perlinScaleLabel = document.getElementById("perlinScaleLabel");
const perlinFractalsSlider = document.getElementById("perlinFractalsSlider");
const perlinFractalsLabel = document.getElementById("perlinFractalsLabel");
const perlinLacunaritySlider = document.getElementById("perlinLacunaritySlider");
const perlinLacunarityLabel = document.getElementById("perlinLacunarityLabel");
const voronoiCellSizeSlider = document.getElementById("voronoiCellSizeSlider");
const voronoiCellSizeLabel = document.getElementById("voronoiCellSizeLabel");
const blueNoiseRadiusSlider = document.getElementById("blueNoiseRadiusSlider");
const blueNoiseRadiusLabel = document.getElementById("blueNoiseRadiusLabel");
const seamlessCheckbox = document.getElementById("seamlessCheckbox");
const dimension = document.getElementById("dimension");
const channelSelector = document.getElementById("channelSelector");
const imageInfos = document.getElementById("imageInfos");
const displayChannelR = document.getElementById("displayChannelR");
const displayChannelG = document.getElementById("displayChannelG");
const displayChannelB = document.getElementById("displayChannelB");
const displayChannelA = document.getElementById("displayChannelA");
const generatingPlanel = document.getElementById("generatingPlanel");
const dimensionWarning = document.getElementById("dimensionWarning");
const tilesLayoutGroup = document.getElementById("tilesLayoutGroup");
const tilesLayout = document.getElementById("tilesLayout");

noiseType.addEventListener("input", () => ShowSettings(noiseType.value));
resSlider.addEventListener("input", () => ResizeCanvas());
dimension.addEventListener("input", () => ResizeCanvas());
tilesLayout.addEventListener("input", () => ResizeCanvas());
perlinScaleSlider.addEventListener("input", () => perlinScaleLabel.textContent = perlinScaleSlider.value);
perlinFractalsSlider.addEventListener("input", () => perlinFractalsLabel.textContent = perlinFractalsSlider.value);
perlinLacunaritySlider.addEventListener("input", () => perlinLacunarityLabel.textContent = perlinLacunaritySlider.value);
voronoiCellSizeSlider.addEventListener("input", () => voronoiCellSizeLabel.textContent = voronoiCellSizeSlider.value);
blueNoiseRadiusSlider.addEventListener("input", () => blueNoiseRadiusLabel.textContent = blueNoiseRadiusSlider.value);
displayChannelR.addEventListener("input", Draw);
displayChannelG.addEventListener("input", Draw);
displayChannelB.addEventListener("input", Draw);
displayChannelA.addEventListener("input", Draw);

const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))

let channelR = [];
let channelG = [];
let channelB = [];
let channelA = [];

function is3d() {
  return dimension.value === "3d" && resSlider.value < 9;
}

function xTiles() {
  const resolution = 1 << resSlider.value;
  const sqr = Math.sqrt(resolution);
  if (!is3d()) return 1;
  if (tilesLayout.value === "auto") return Number.isInteger(sqr) ? Math.ceil(sqr) : 1;
  if (tilesLayout.value === "square") return Math.ceil(sqr);
  if (tilesLayout.value === "horizontal") return resolution;
  if (tilesLayout.value === "vertical") return 1;
}

function yTiles() {
  const resolution = 1 << resSlider.value;
  const sqr = Math.sqrt(resolution);
  if (!is3d()) return 1;
  if (tilesLayout.value === "auto") return Number.isInteger(sqr) ? Math.ceil(sqr) : resolution;
  if (tilesLayout.value === "square") return Math.ceil(sqr);
  if (tilesLayout.value === "horizontal") return 1;
  if (tilesLayout.value === "vertical") return resolution;
}

function fade(t) {
  return t * t * t * (t * (t * 6 - 15) + 10);
}

function lerp(a, b, t) {
  return a + t * (b - a);
}

function grad(hash, x, y, z) {
  const h = hash & 15;
  const u = h < 8 ? x : y;
  const v = h < 4 ? y : (h === 12 || h === 14 ? x : z);
  return ((h & 1) ? -u : u) + ((h & 2) ? -v : v);
}

function splitmix32(a) {
  return function() {
    a |= 0;
    a = a + 0x9e3779b9 | 0;
    let t = a ^ a >>> 16;
    t = Math.imul(t, 0x21f0aaad);
    t = t ^ t >>> 15;
    t = Math.imul(t, 0x735a2d97);
    return ((t = t ^ t >>> 15) >>> 0) / 4294967296;
  }
}

function generateBlack(seed, width, height, depth, seamless) {
  const imgData = []
  for (let z = 0; z < depth; z++) {
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const index = x + width * y + width * height * z;
        imgData[index] = 0;
      }
    }
  }
  return imgData;
}

function generateGradientCube(seed, width, height, depth, seamless) {
  const imgData = []
  for (let z = 0; z < depth; z++) {
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const index = x + width * y + width * height * z;
        imgData[index] = x / width;
      }
    }
  }
  return imgData;
}

function generateRandomNoise(seed, width, height, depth, seamless) {
  const prng = splitmix32(seed);
  const imgData = []
  for (let z = 0; z < depth; z++) {
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const index = x + width * y + width * height * z;
        imgData[index] = prng();
      }
    }
  }
  return imgData;
}

function generateSimplexNoise(seed, width, height, depth, seamless, scale, fractals, lacunarity) {
  const prng = splitmix32(seed);
  const perm = [...Array(256).keys()];
  const imgData = []

  for (let f = 0; f < fractals; f++) {
    for (let i = 255; i > 0; i--) {
      const j = Math.floor(prng() * (i + 1));
      [perm[i], perm[j]] = [perm[j], perm[i]];
    }
    const p = perm.concat(perm); // duplication to avoid wrapping logic
    for (let z = 0; z < depth; z++) {
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const attenuation = 1.0 / Math.pow(lacunarity, f)
          const s = scale * attenuation;
          const xScaled = x / s;
          const yScaled = y / s;
          const zScaled = z / s;
          const repeatX = width / s;
          const repeatY = height / s;
          const repeatZ = depth / s;

          const xi = Math.floor(xScaled);
          const yi = Math.floor(yScaled);
          const zi = Math.floor(zScaled);

          const xf = xScaled - xi;
          const yf = yScaled - yi;
          const zf = zScaled - zi;

          const u = fade(xf);
          const v = fade(yf);
          const w = fade(zf);

          // Wrap coordinates if tileable
          const X = seamless ? xi % repeatX & 255 : xi & 255;
          const Y = seamless ? yi % repeatY & 255 : yi & 255;
          const Z = seamless ? zi % repeatZ & 255 : zi & 255;

          const X1 = seamless ? (X + 1) % repeatX & 255 : (X + 1) & 255;
          const Y1 = seamless ? (Y + 1) % repeatY & 255 : (Y + 1) & 255;
          const Z1 = seamless ? (Z + 1) % repeatZ & 255 : (Z + 1) & 255;

          const aaa = p[p[p[X] + Y] + Z];
          const aba = p[p[p[X] + Y1] + Z];
          const aab = p[p[p[X] + Y] + Z1];
          const abb = p[p[p[X] + Y1] + Z1];
          const baa = p[p[p[X1] + Y] + Z];
          const bba = p[p[p[X1] + Y1] + Z];
          const bab = p[p[p[X1] + Y] + Z1];
          const bbb = p[p[p[X1] + Y1] + Z1];

          const x1 = lerp(grad(aaa, xf, yf, zf), grad(baa, xf - 1, yf, zf), u);
          const x2 = lerp(grad(aba, xf, yf - 1, zf), grad(bba, xf - 1, yf - 1, zf), u);
          const y1 = lerp(x1, x2, v);

          const x3 = lerp(grad(aab, xf, yf, zf - 1), grad(bab, xf - 1, yf, zf - 1), u);
          const x4 = lerp(grad(abb, xf, yf - 1, zf - 1), grad(bbb, xf - 1, yf - 1, zf - 1), u);
          const y2 = lerp(x3, x4, v);

          const index = x + width * y + width * height * z;
          const prevVal = imgData[index] || 0;
          const val = lerp(y1, y2, w) * attenuation;
          imgData[index] = prevVal + val;
        }
      }
    }
  }

  for (let i = 0; i < imgData.length; i++) imgData[i] = imgData[i] * 0.5 + 0.5
  return imgData;
}

function generateVoronoiNoise(seed, width, height, depth, seamless, gridSize) {
  const prng = splitmix32(seed);
  const imgData = []
  const points = []
  const gridWidth = Math.floor(Math.max(1, width / gridSize));
  const gridHeight = Math.floor(Math.max(1, height / gridSize));
  const gridDepth = Math.floor(Math.max(1, depth / gridSize));
  
  for (let z = 0; z < gridDepth; z++) {
    for (let y = 0; y < gridHeight; y++) {
      for (let x = 0; x < gridWidth; x++) {
        points.push({ x: x + prng(), y: y + prng(), z: z + prng() })
      }
    }
  }

  for (let z = 0; z < depth; z++) {
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const cellX = Math.floor(x / width * gridWidth);
        const cellY = Math.floor(y / height * gridHeight);
        const cellZ = Math.floor(z / depth * gridDepth);

        let minDist = Infinity;

        for (let k = -1; k <= 1; k++) {
          for (let j = -1; j <= 1; j++) {
            for (let i = -1; i <= 1; i++) {
              const neighborX = (gridWidth + cellX + i) % gridWidth;
              const neighborY = (gridHeight + cellY + j) % gridHeight;
              const neighborZ = (gridDepth + cellZ + k) % gridDepth;
              const cellIndex = neighborX + gridWidth * neighborY + gridWidth * gridHeight * neighborZ;
              const pointPosition = points[cellIndex];
              let dx = x - pointPosition.x / gridWidth * width;
              let dy = y - pointPosition.y / gridHeight * height;
              let dz = z - pointPosition.z / gridDepth * depth;
              if (seamless) {
                dx = Math.min(Math.abs(dx), width - Math.abs(dx));
                dy = Math.min(Math.abs(dy), height - Math.abs(dy));
                dz = Math.min(Math.abs(dz), depth - Math.abs(dz));
              }
              const dist = dx * dx + dy * dy + dz * dz;
              if (dist < minDist) minDist = dist;
            }
          }
        }
        const index = x + width * y + width * height * z;
        imgData[index] = Math.sqrt(minDist) / gridSize;
      }
    }
  }
  return imgData;
}

function generateBlueNoise(seed, width, height, depth, seamless, radius) {
  const prng = splitmix32(seed);
  const samples = width * height * depth * 32;
  const sqrRadius = radius * radius;
  const points = [];
  const imgData = [];

  function isFarEnough(x, y, z) {
    for (const p of points) {
      const dx = x - p.x;
      const dy = y - p.y;
      const dz = z - p.z;
      if (dx * dx + dy * dy + dz * dz < sqrRadius) return false;
    }
    return true;
  }

  for (let i = 0; i < samples && points.length < samples / 4; i++) {
    const x = prng() * width;
    const y = prng() * height;
    const z = prng() * depth;
    const X = Math.floor(x);
    const Y = Math.floor(y);
    const Z = Math.floor(z);
    const index = X + width * Y + width * height * Z;
    if (isFarEnough(x, y, z)) {
      points.push({ x, y, z });
      const dx = x - X;
      const dy = y - Y;
      const dz = z - Z;
      const prevVal = imgData[index] || 0;
      const gridDist = dx * dx + dy * dy + dz * dz;
      imgData[index] = prevVal + (radius / gridDist);
    }
  }
  return imgData;
}

function ResizeCanvas() {
  const resolution = 1 << resSlider.value;
  const tileResolutionX = resolution;
  const tileResolutionY = resolution;
  const canvasWidth = tileResolutionX * xTiles();
  const canvasHeight = tileResolutionY * yTiles();

  canvas.width = canvasWidth;
  canvas.height = canvasHeight;
  channelR = [];
  channelG = [];
  channelB = [];
  channelA = [];
  resLabel.textContent = 1 << resSlider.value;
  imageInfos.innerHTML = `${canvasWidth}x${canvasHeight} pixels`;
  dimensionWarning.classList.add("hidden");
  tilesLayoutGroup.classList.add("hidden");
  if (resSlider.value > 8 && dimension.value === "3d") dimensionWarning.classList.remove("hidden")
  if (is3d()) {
    tilesLayoutGroup.classList.remove("hidden");
    imageInfos.innerHTML += ` - ${xTiles()} columns, ${yTiles()} rows (${xTiles() * yTiles()} tiles)`
  }
}

async function generateNoise(R = true, G = true, B = true, A = true) {
  const resolution = 1 << resSlider.value;
  const type = noiseType.value;
  const perlinScale = perlinScaleSlider.value * resolution;
  const perlinFractals = perlinFractalsSlider.value;
  const perlinLacunarity = perlinLacunaritySlider.value;
  const voronoiCellSize = voronoiCellSizeSlider.value * resolution;
  const blueNoiseRadius = blueNoiseRadiusSlider.value;
  const seamless = seamlessCheckbox.checked;
  const tileResolutionX = resolution;
  const tileResolutionY = resolution;
  const depthResolution = is3d() ? resolution : 1;
  const seed = seedInput.value;

  generatingPlanel.classList.remove("hidden");

  await delay(1);

  let noise;
  if (type === "black") noise = generateBlack(seed, tileResolutionX, tileResolutionY, depthResolution, seamless);
  if (type === "gradientCube") noise = generateGradientCube(seed, tileResolutionX, tileResolutionY, depthResolution, seamless);
  if (type === "random") noise = generateRandomNoise(seed, tileResolutionX, tileResolutionY, depthResolution, seamless);
  if (type === "perlin") noise = generateSimplexNoise(seed, tileResolutionX, tileResolutionY, depthResolution, seamless, perlinScale, perlinFractals, perlinLacunarity);
  if (type === "voronoi") noise = generateVoronoiNoise(seed, tileResolutionX, tileResolutionY, depthResolution, seamless, voronoiCellSize);
  if (type === "blueNoise") noise = generateBlueNoise(seed, tileResolutionX, tileResolutionY, depthResolution, seamless, blueNoiseRadius);

  for (let z = 0; z < depthResolution; z++) {
    for (let y = 0; y < tileResolutionY; y++) {
      for (let x = 0; x < tileResolutionX; x++) {
        const noiseIndex = x + tileResolutionX * y + tileResolutionX * tileResolutionY * z;
        const noiseVal =  noise[noiseIndex];
        if (R) channelR[noiseIndex] = noiseVal;
        if (G) channelG[noiseIndex] = noiseVal;
        if (B) channelB[noiseIndex] = noiseVal;
        if (A) channelA[noiseIndex] = noiseVal;
      }
    }
  }

  Draw();

  await delay(1);
  generatingPlanel.classList.add("hidden");
}

function Draw() {
  const ctx = canvas.getContext("2d");
  const resolution = 1 << resSlider.value;
  const tileResolutionX = resolution;
  const tileResolutionY = resolution;
  const depthResolution = is3d() ? resolution : 1;
  const imgData = ctx.createImageData(tileResolutionX, tileResolutionY);
  console.log(imgData.pixelFormat)

  for (let z = 0; z < depthResolution; z++) {
    const posX = (z % xTiles()) * tileResolutionX;
    const posY = Math.floor((z / xTiles())) * tileResolutionY;
    for (let y = 0; y < tileResolutionY; y++) {
      for (let x = 0; x < tileResolutionX; x++) {
        const dataIndex = x + tileResolutionX * y;
        const noiseIndex = x + tileResolutionX * y + tileResolutionX * tileResolutionY * z;
        if (displayChannelR.checked) imgData.data[dataIndex * 4 + 0] = channelR[noiseIndex] * 255;
        if (displayChannelG.checked) imgData.data[dataIndex * 4 + 1] = channelG[noiseIndex] * 255;
        if (displayChannelB.checked) imgData.data[dataIndex * 4 + 2] = channelB[noiseIndex] * 255;
        if (displayChannelA.checked) imgData.data[dataIndex * 4 + 3] = channelA[noiseIndex] * 255;
        else imgData.data[dataIndex * 4 + 3] = 255;
      }
    }
    ctx.putImageData(imgData, posX, posY);
  }
}

function ShuffleSeed() {
  return seedInput.value = Math.floor(Math.random() * 1000000);
}

function ShowSettings(id)
{
  for(let elm of document.getElementsByClassName("settings")) elm.classList.add("hidden");
  document.getElementById(id + "Settings")?.classList.remove("hidden");
}

function saveImage() {
  const link = document.createElement("a");
  link.download = dimension.value === "3d" ? "noise_volume.png" : "noise_map.png";
  link.href = canvas.toDataURL("image/png");
  link.click();
}

function delay(time) {
  return new Promise(res => {
    setTimeout(res,time)
  })
}

async function copyImageToClipboard() {
  try {
    const blob = await new Promise(resolve => canvas.toBlob(resolve));
    const item = new ClipboardItem({ 'image/png': blob });
    await navigator.clipboard.write([item]);
    alert("Image copied to clipboard!");
  } catch (err) {
    alert("Failed to copy: " + err);
  }
}