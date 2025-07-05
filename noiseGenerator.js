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
const ctx = canvas.getContext("2d");
const generatingPlanel = document.getElementById("generatingPlanel");
const tooltipList = [...document.querySelectorAll('[data-bs-toggle="tooltip"]')].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
const loadModal = new bootstrap.Modal('#loadBackdrop');
const initialSeed = GetRandomSeed();
const channelsData = [];

let settings = {
  name: "Noise",
  resolution: 256,
  dimension: "2d",
  layout: "auto",
  channels: [
    { type: "random", seamless: true, seed: initialSeed, perlinSize: 0.1, perlinOctaves: 1, perlinLacunarity: 2.0, voronoiCellSize: 0.1, blueNoiseRadius: 1.5 },
    { type: "random", seamless: true, seed: initialSeed, perlinSize: 0.1, perlinOctaves: 1, perlinLacunarity: 2.0, voronoiCellSize: 0.1, blueNoiseRadius: 1.5 },
    { type: "random", seamless: true, seed: initialSeed, perlinSize: 0.1, perlinOctaves: 1, perlinLacunarity: 2.0, voronoiCellSize: 0.1, blueNoiseRadius: 1.5 },
    { type: "random", seamless: true, seed: initialSeed, perlinSize: 0.1, perlinOctaves: 1, perlinLacunarity: 2.0, voronoiCellSize: 0.1, blueNoiseRadius: 1.5 },
  ],
}
let activeChannel = 0;

document.getElementById("loadBackdrop").addEventListener('shown.bs.modal', onLoadModalShown);
document.getElementById("saveBackdrop").addEventListener('shown.bs.modal', onSaveModalShown);

function init() {
  resizeCanvas();
  refreshUi();
  generateNoise(true);
}

function update(clear = false) {
  const channelSettings = settings.channels[activeChannel];

  settings.resolution = 1 << document.getElementById("resolution").value;
  settings.dimension = document.getElementById("dimension").value;
  settings.layout = document.getElementById("layout").value;

  channelSettings.type = document.getElementById("type").value;
  channelSettings.seamless = document.getElementById("seamless").checked;
  channelSettings.seed = document.getElementById("seed").value;
  channelSettings.perlinSize = document.getElementById("perlinSize").value;
  channelSettings.perlinOctaves = document.getElementById("perlinOctaves").value;
  channelSettings.perlinLacunarity = document.getElementById("perlinLacunarity").value;
  channelSettings.voronoiCellSize = document.getElementById("voronoiCellSize").value;
  channelSettings.blueNoiseRadius = document.getElementById("blueNoiseRadius").value;

  if (clear) resizeCanvas();
  generateNoise(clear);
  refreshUi();
}

function refreshUi() {
  const channelSettings = settings.channels[activeChannel];
  const canvasWidth = settings.resolution * xTiles();
  const canvasHeight = settings.resolution * yTiles();

  for(let elm of document.getElementsByClassName("channel-nav")) elm.getAttribute("data-channel") == activeChannel ? elm.classList.add("active") : elm.classList.remove("active");
  for(let elm of document.getElementsByClassName("settings")) elm.classList.add("hidden");
  document.getElementById(channelSettings.type + "Settings")?.classList.remove("hidden");

  document.getElementById("settingsName").innerHTML = settings.name;
  document.getElementById("resolution").value = Math.log2(settings.resolution);
  document.getElementById("resolutionLabel").textContent = settings.resolution;
  document.getElementById("dimension").value = settings.dimension;
  document.getElementById("layout").value = settings.layout;
  document.getElementById("type").value = channelSettings.type;
  document.getElementById("perlinSize").value = document.getElementById("perlinSizeLabel").textContent = channelSettings.perlinSize;
  document.getElementById("perlinOctaves").value = document.getElementById("perlinOctavesLabel").textContent = channelSettings.perlinOctaves;
  document.getElementById("perlinLacunarity").value = document.getElementById("perlinLacunarityLabel").textContent = channelSettings.perlinLacunarity;
  document.getElementById("voronoiCellSize").value = document.getElementById("voronoiCellSizeLabel").textContent = channelSettings.voronoiCellSize;
  document.getElementById("blueNoiseRadius").value = document.getElementById("blueNoiseRadiusLabel").textContent = channelSettings.blueNoiseRadius;
  document.getElementById("seamless").checked = channelSettings.seamless;
  document.getElementById("seed").value = channelSettings.seed;
  document.getElementById("imageInfos").innerHTML = `${canvasWidth}x${canvasHeight} pixels`;
  document.getElementById("dimensionWarning").classList.add("hidden");
  document.getElementById("layoutGroup").classList.add("hidden");
  if (settings.resolution > 256 && settings.dimension === "3d") document.getElementById("dimensionWarning").classList.remove("hidden")

  if (is3d()) {
    document.getElementById("layoutGroup").classList.remove("hidden");
    document.getElementById("imageInfos").innerHTML += ` - ${xTiles()} columns, ${yTiles()} rows (${xTiles() * yTiles()} tiles)`
  }
}

function switchChannel(channel) {
  activeChannel = channel;
  refreshUi();
}

function shuffleSeed() {
  const channelSettings = settings.channels[activeChannel];
  channelSettings.seed = GetRandomSeed();
  refreshUi();
  generateNoise();
}

function GetRandomSeed() {
  return Math.floor(Math.random() * 100000);
}

function is3d() {
  return settings.dimension === "3d" && settings.resolution < 512;
}

function xTiles() {
  const sqr = Math.sqrt(settings.resolution);
  if (!is3d()) return 1;
  if (settings.layout === "auto") return Number.isInteger(sqr) ? Math.ceil(sqr) : 1;
  if (settings.layout === "square") return Math.ceil(sqr);
  if (settings.layout === "horizontal") return settings.resolution;
  if (settings.layout === "vertical") return 1;
}

function yTiles() {
  const sqr = Math.sqrt(settings.resolution);
  if (!is3d()) return 1;
  if (settings.layout === "auto") return Number.isInteger(sqr) ? Math.ceil(sqr) : settings.resolution;
  if (settings.layout === "square") return Math.ceil(sqr);
  if (settings.layout === "horizontal") return 1;
  if (settings.layout === "vertical") return settings.resolution;
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

function generateNone(seed, width, height, depth, seamless) {
  const imgData = []
  for (let z = 0; z < depth; z++) {
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const index = x + width * y + width * height * z;
        imgData[index] = 1;
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

function resizeCanvas() {
  const canvasWidth = settings.resolution * xTiles();
  const canvasHeight = settings.resolution * yTiles();

  canvas.width = canvasWidth;
  canvas.height = canvasHeight;
  channelsData[0] = [];
  channelsData[1] = [];
  channelsData[2] = [];
  channelsData[3] = [];
}

async function generateNoise(allChannels = false) {
  const width = settings.resolution;
  const height = settings.resolution;
  const depth = is3d() ? settings.resolution : 1;

  generatingPlanel.style.opacity = 1;
  await delay(10);

  for (let c = 0; c < 4; c++) {
    if (c != activeChannel && allChannels == false) continue;
    const channelSettings = settings.channels[c];
    const seed = channelSettings.seed;
    const seamless = channelSettings.seamless;

    if (channelSettings.type === "none")
        channelsData[c] = generateNone(seed, width, height, depth, seamless);
    if (channelSettings.type === "random")
      channelsData[c] = generateRandomNoise(seed, width, height, depth, seamless);
    if (channelSettings.type === "perlin")
      channelsData[c] = generateSimplexNoise(seed, width, height, depth, seamless, channelSettings.perlinSize * settings.resolution, channelSettings.perlinOctaves, channelSettings.perlinLacunarity);
    if (channelSettings.type === "voronoi")
      channelsData[c] = generateVoronoiNoise(seed, width, height, depth, seamless, channelSettings.voronoiCellSize * settings.resolution);
    if (channelSettings.type === "blueNoise")
      channelsData[c] = generateBlueNoise(seed, width, height, depth, seamless, channelSettings.blueNoiseRadius);
  }

  drawCanvas();

  await delay(10);
  generatingPlanel.style.opacity = 0;
}

function drawCanvas() {
  const tileResolutionX = settings.resolution;
  const tileResolutionY = settings.resolution;
  const depthResolution = is3d() ? settings.resolution : 1;
  const imgData = ctx.createImageData(tileResolutionX, tileResolutionY);

  for (let z = 0; z < depthResolution; z++) {
    const posX = (z % xTiles()) * tileResolutionX;
    const posY = Math.floor((z / xTiles())) * tileResolutionY;
    for (let y = 0; y < tileResolutionY; y++) {
      for (let x = 0; x < tileResolutionX; x++) {
        const dataIndex = x + tileResolutionX * y;
        const noiseIndex = x + tileResolutionX * y + tileResolutionX * tileResolutionY * z;
        if (displayChannelR.checked) imgData.data[dataIndex * 4 + 0] = channelsData[0][noiseIndex] * 255;
        if (displayChannelG.checked) imgData.data[dataIndex * 4 + 1] = channelsData[1][noiseIndex] * 255;
        if (displayChannelB.checked) imgData.data[dataIndex * 4 + 2] = channelsData[2][noiseIndex] * 255;
        if (displayChannelA.checked) imgData.data[dataIndex * 4 + 3] = channelsData[3][noiseIndex] * 255;
        else imgData.data[dataIndex * 4 + 3] = 255;
      }
    }
    ctx.putImageData(imgData, posX, posY);
  }
}

function exportImage() {
  const link = document.createElement("a");
  link.download = `${settings.name}.png`;
  link.href = canvas.toDataURL("image/png");
  link.click();
}

function delay(time) {
  return new Promise(res => setTimeout(res,time));
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

function onLoadModalShown() {
  document.getElementById("savedSettingsList").innerHTML = "";
  try {
    const settingsCollection = JSON.parse(localStorage.getItem("settingsCollection") || {});

    if (Object.keys(settingsCollection).length == 0) {
      document.getElementById("savedSettingsList").innerHTML = '<p class="text-info"><i class="bi bi-info-circle"></i> No settings saved on this browser.</p>';
    }

    for (const key in settingsCollection) {
      const listItem = document.createElement("button");
      listItem.className = "list-group-item list-group-item-action position-relative";
      listItem.innerHTML = key;
      listItem.onclick = () => {
        settings = settingsCollection[key];
        resizeCanvas();
        generateNoise(true);
        refreshUi();
        loadModal.hide();
      }
      const deleteButton = document.createElement("button");
      deleteButton.type = "button";
      deleteButton.className = "btn position-absolute top-50 end-0 translate-middle";
      deleteButton.innerHTML = '<i class="bi bi-trash3"></i>';
      deleteButton.onclick = (e) => {
        e.stopPropagation();
        if (confirm(`Really delete setting ${key}`)) {
          delete settingsCollection[key];
          localStorage.setItem("settingsCollection", JSON.stringify(settingsCollection));
          onLoadModalShown();
        }
      }
      listItem.appendChild(deleteButton);
      document.getElementById("savedSettingsList").appendChild(listItem);
    }
  } catch(e) {
    fixSettingsCollection();
  }
}

function onSaveModalShown() {
  document.getElementById("saveName").value = settings.name;
  document.getElementById("saveName").focus();
}

function saveSettings() {
  const name = document.getElementById("saveName").value || settings.name || "untitled noise settings";
  settings.name = name;

  try {
    const settingsCollection = JSON.parse(localStorage.getItem("settingsCollection") || "{}");
    settingsCollection[name] = settings
    localStorage.setItem("settingsCollection", JSON.stringify(settingsCollection));
  } catch(e) {
    fixSettingsCollection();
  }
  
  refreshUi();
}

function fixSettingsCollection() {
  alert("Your settings collection was corrupted. They were cleared to fix the issue.")
  localStorage.setItem("settingsCollection", "{}");
}