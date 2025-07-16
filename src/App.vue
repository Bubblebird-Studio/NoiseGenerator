<template>
  <div class="container text-center" :style="{'max-width': '1000px'}">
    <div class="row m-5">
      <div class="position-relative">
        <h1 class="display-3">Noise Generator</h1><span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-info">New version</span>
      </div>
      <p><small>A simple random noise generator by Bubblebird Studio. <a href="https://bubblebirdstudio.com/" target="_blank">Buy our games</a> to support this tool!</small></p>
    </div>

    <div v-if="error != ''" class="alert alert-danger" role="alert">
      <p>{{ error }}</p>
      <p>Open an issue on <a href="https://github.com/Bubblebird-Studio/NoiseGenerator">Github</a> to let us know what went wrong.</p>
    </div>

    <div class="row">
      <div class="col-md-auto">
        <div class="viewer overflow-auto">
          <div v-if="generating" id="generatingPlanel">
            <div class="spinner-border" role="status">
              <span class="visually-hidden">Generating...</span>
            </div>
          </div>
          <canvas width="256" height="256" ref="canvas"></canvas>
        </div>

        <p class="text-info">
          <span class="m-3">{{ settings.name }}.png</span>
          <span class="m-3">{{ canvasWidth }} x {{ canvasHeight }} pixels</span>
          <span class="m-3" v-if="is3d">{{ xTiles }} x {{ yTiles }} tiles</span>
        </p>

        <div class="btn-group" role="group">
          <button class="btn btn-primary mt-3" type="button" @click="exportImage()"><i class="bi bi-download"></i> Export PNG</button>
          <button class="btn btn-secondary mt-3" type="button" @click="copyImageToClipboard()"><i class="bi bi-copy"></i> Copy</button>
          <button class="btn btn-secondary mt-3" type="button" data-bs-toggle="modal" data-bs-target="#loadBackdrop"><i class="bi bi-floppy"></i> Load...</button>
          <button class="btn btn-secondary mt-3" type="button" data-bs-toggle="modal" data-bs-target="#saveBackdrop"><i class="bi bi-floppy"></i> Save...</button>
        </div>
      </div>

      <div class="col">

        <div class="input-group mb-3">
          <label class="input-group-text" for="resolution">Resolution</label>
          <div class="input-group-text">
            <input type="range" class="form-range" min="3" max="12" id="resolution" :value="Math.log2(settings.resolution)" @input="event => settings.resolution = 1 << event.target.value">
          </div>
          <label class="input-group-text" for="resolution">{{ settings.resolution }}</label>
        </div>

        <div class="input-group mb-3">
          <label class="input-group-text" for="dimension">Dimension</label>
          <select class="form-select" id="dimension" v-model="settings.dimension">
            <option value="2d">2D</option>
            <option value="3d">3D</option>
          </select>
          <span v-if="settings.dimension == '3d' && settings.resolution > 256" class="input-group-text text-danger" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Resolution is too high for 3d. Generating an image will fall back to 2d.">
            <i class="bi bi-exclamation-triangle-fill"></i>
          </span>
        </div>

        <div v-if="settings.dimension == '3d'" class="input-group mb-3">
          <label class="input-group-text" for="layout">3D tiles layout</label>
          <select class="form-select" id="layout" v-model="settings.layout">
            <option value="auto">Auto</option>
            <option value="square">Square</option>
            <option value="horizontal">Horizontal</option>
            <option value="vertical">Vertical</option>
          </select>
          <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Lets you choose how to arrange the tiles (the slices of your volume texture) in 2D.">
            <i class="bi bi-question"></i>
          </span>
        </div>

        <!-- ################  GENERATORS  ################ -->
        <ul class="nav nav-tabs">
          <li class="nav-item">
            <a class="nav-link disabled" aria-disabled="true">Generators</a>
          </li>
          <li class="nav-item">
            <a class="nav-link channel-nav" :class="{'active': settings.activeGenerator == 0}" role="button" data-channel=0 @click="settings.activeGenerator = 0">0</a>
          </li>
          <li class="nav-item">
            <a class="nav-link channel-nav" :class="{'active': settings.activeGenerator == 1}" role="button" data-channel=1 @click="settings.activeGenerator = 1">1</a>
          </li>
          <li class="nav-item">
            <a class="nav-link channel-nav" :class="{'active': settings.activeGenerator == 2}" role="button" data-channel=2 @click="settings.activeGenerator = 2">2</a>
          </li>
          <li class="nav-item">
            <a class="nav-link channel-nav" :class="{'active': settings.activeGenerator == 3}" role="button" data-channel=3 @click="settings.activeGenerator = 3">3</a>
          </li>
        </ul>

        <div class="col border-start border-end border-bottom p-3 mb-3">
          <div class="input-group mb-3">
            <label class="input-group-text" for="type">Type</label>
            <select class="form-select" id="type" v-model="activeGenerator.type">
              <option v-for="(noiseType, i) in noiseTypes" :value="i">{{ noiseType }}</option>
            </select>
          </div>

          <div v-if="activeGenerator.type == noiseTypes.indexOf('Perlin')" class="settings m-3">
            <div class="input-group mb-1">
              <label class="input-group-text" for="perlinSize">Size</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="0.1" max="100.0" step="0.1" id="perlinSize" v-model="activeGenerator.perlinSize">
              </div>
              <label class="input-group-text" for="perlinSize">{{ activeGenerator.perlinSize }}</label>
            </div>
            <div class="input-group mb-1">
              <label class="input-group-text" for="perlinOctaves">Octaves</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="1" max="10" step="1" id="perlinOctaves" v-model="activeGenerator.perlinOctaves">
              </div>
              <label class="input-group-text" for="perlinOctaves">{{ activeGenerator.perlinOctaves }}</label>
              <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Sets the number of noise layers combined to create fractal detail.">
                <i class="bi bi-question"></i>
              </span>
            </div>
            <div class="input-group mb-1">
              <label class="input-group-text" for="perlinLacunarity">Lacunarity</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="1.0" max="10.0" step="0.01" id="perlinLacunarity" v-model="activeGenerator.perlinLacunarity" @dblclick="activeGenerator.perlinLacunarity = defaultSettings.generators[0].perlinLacunarity">
              </div>
              <label class="input-group-text" for="perlinLacunarity">{{ activeGenerator.perlinLacunarity }}</label>
              <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Controls how quickly frequency increases with each octave, affecting texture detail.">
                <i class="bi bi-question"></i>
              </span>
            </div>
          </div>

          <div v-if="activeGenerator.type == noiseTypes.indexOf('Voronoi')" class="settings m-3">
            <div class="input-group mb-1">
              <label class="input-group-text" for="voronoiCellSize">Cell size</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="0.01" max="0.3" step="0.01" id="voronoiCellSize" v-model="activeGenerator.voronoiCellSize">
              </div>
              <label class="input-group-text" for="voronoiCellSize">{{ activeGenerator.voronoiCellSize }}</label>
            </div>
            <div class="input-group mb-1">
              <label class="input-group-text" for="voronoiWeight1">Weight feature 1</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="-2.0" max="2.0" step="0.01" id="voronoiWeight1" v-model="activeGenerator.voronoiWeight1">
              </div>
              <label class="input-group-text" for="voronoiWeight1">{{ activeGenerator.voronoiWeight1 }}</label>
            </div>
            <div class="input-group mb-1">
              <label class="input-group-text" for="voronoiWeight2">Weight feature 2</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="-2.0" max="2.0" step="0.01" id="voronoiWeight2" v-model="activeGenerator.voronoiWeight2">
              </div>
              <label class="input-group-text" for="voronoiWeight2">{{ activeGenerator.voronoiWeight2 }}</label>
            </div>
            <div class="input-group mb-1">
              <label class="input-group-text" for="voronoiWeight3">Weight feature 3</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="-2.0" max="2.0" step="0.01" id="voronoiWeight3" v-model="activeGenerator.voronoiWeight3">
              </div>
              <label class="input-group-text" for="voronoiWeight3">{{ activeGenerator.voronoiWeight3 }}</label>
            </div>
            <div class="input-group mb-1">
              <label class="input-group-text" for="voronoiWeight4">Weight feature 4</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="-2.0" max="2.0" step="0.01" id="voronoiWeight4" v-model="activeGenerator.voronoiWeight4">
              </div>
              <label class="input-group-text" for="voronoiWeight4">{{ activeGenerator.voronoiWeight4 }}</label>
            </div>
            <div class="input-group mb-1">
              <label class="input-group-text" for="voronoiFalloff">Falloff</label>
              <div class="input-group-text">
                <input type="range" class="form-range" min="0.01" max="3.0" step="0.01" id="voronoiFalloff" v-model="activeGenerator.voronoiFalloff" @dblclick="activeGenerator.voronoiFalloff = defaultSettings.generators[0].voronoiFalloff">
              </div>
              <label class="input-group-text" for="voronoiFalloff">{{ activeGenerator.voronoiFalloff }}</label>
              <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Controls the curve of the gradient. For a linear gradient, use 1.0.">
                <i class="bi bi-question"></i>
              </span>
            </div>
          </div>

          <div class="input-group mb-3">
            <label class="input-group-text" for="seamless">Seamless</label>
            <div class="input-group-text">
              <input class="form-check-input mt-0" type="checkbox" id="seamless" v-model="activeGenerator.seamless">
            </div>
            <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Makes the image tileable.">
              <i class="bi bi-question"></i>
            </span>
          </div>

          <div class="input-group">
            <label class="input-group-text" for="seed">Seed</label>
            <input type="number" class="form-control" v-model="activeGenerator.seed" id="seed">
            <button class="btn btn-outline-secondary" type="button" @click="activeGenerator.seed = getRandomSeed()"><i class="bi bi-arrow-clockwise"></i></button>
            <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Defines the starting point for random number generation, producing different noise patterns.">
              <i class="bi bi-question"></i>
            </span>
          </div>
        </div>

        <!-- ################  SWIZZLE  ################ -->
        <ul class="nav nav-tabs">
          <li class="nav-item">
            <a class="nav-link disabled" aria-disabled="true">Swizzle</a>
          </li>
          <li class="nav-item dropdown">
            <button class="nav-link dropdown-toggle" data-toggle="dropdown" data-bs-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="true">Presets</button>
            <ul class="dropdown-menu">
              <li><span class="dropdown-item disabled" href="#">Choose a preset</span></li>
              <li><hr class="dropdown-divider"></li>
              <li><a v-for="(channelPreset, i) in channelsPresets" class="dropdown-item" role="button" @click="onPresetSelection(i)">{{ i }}</a></li>
            </ul>
          </li>
          <li class="nav-item">
            <a class="nav-link channel-nav" :class="{'active': settings.activeChannel == 0}" role="button" data-channel=0 @click="settings.activeChannel = 0">R</a>
          </li>
          <li class="nav-item">
            <a class="nav-link channel-nav" :class="{'active': settings.activeChannel == 1}" role="button" data-channel=1 @click="settings.activeChannel = 1">G</a>
          </li>
          <li class="nav-item">
            <a class="nav-link channel-nav" :class="{'active': settings.activeChannel == 2}" role="button" data-channel=2 @click="settings.activeChannel = 2">B</a>
          </li>
          <li class="nav-item">
            <a class="nav-link channel-nav" :class="{'active': settings.activeChannel == 3}" role="button" data-channel=3 @click="settings.activeChannel = 3">A</a>
          </li>
        </ul>

        <div class="col border-start border-end border-bottom p-3 mb-3">
          <div class="input-group mb-3">
            <label class="input-group-text" for="sourceGenerator">Source generator</label>
            <select class="form-select" v-model="activeChannel.generator" id="sourceGenerator">
              <option v-for="(n, i) in 4" :value="i">{{ i }}</option>
            </select>
            <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Choose the source for this channel of the image">
              <i class="bi bi-question"></i>
            </span>
          </div>

          <div class="input-group mb-3">
            <label class="input-group-text" for="sourceType">Value type</label>
            <select class="form-select" v-model="activeChannel.type" id="sourceType">
              <option v-for="(sourceType, i) in sourceTypes" :value="i">{{ sourceType }}</option>
            </select>
            <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Choose the type of value to use for this channel">
              <i class="bi bi-question"></i>
            </span>
          </div>

          <!-- <div v-else class="input-group mb-3">
            <label class="input-group-text" for="normalScale">Normal scale</label>
            <div class="input-group-text">
              <input type="range" class="form-range" min="0.0" max="2.0" step="0.01" v-model="settings.normalScale" @dblclick="settings.normalScale = defaultSettings.normalScale">
            </div>
            <label class="input-group-text" for="normalScale">{{ settings.normalScale }}</label>
            <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Controls the strength of the normal map.">
              <i class="bi bi-question"></i>
            </span>
          </div> -->

          <div class="input-group mb-3">
            <label class="input-group-text" for="invert">Invert</label>
            <div class="input-group-text">
              <input class="form-check-input mt-0" type="checkbox" id="invert" v-model="activeChannel.invert">
            </div>
            <span class="input-group-text" data-bs-toggle="tooltip" data-bs-placement="right" data-bs-title="Inverts the range of the values (1.0 - x).">
              <i class="bi bi-question"></i>
            </span>
          </div>
        </div>
      </div>
      <div class="row m-5">
        <p class="text-secondary"><a href="mailto:contact@bubblebirdstudio.com">Contact us</a> for feature request or bug report. Visit the <a href="https://github.com/Bubblebird-Studio/NoiseGenerator">Github project page</a>.</p>
      </div>
    </div>
  </div>

  <!-- save as modal -->
  <div class="modal fade" id="saveBackdrop" data-bs-keyboard="false" tabindex="-1" aria-labelledby="saveBackdropLabel" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h1 class="modal-title fs-5" id="saveBackdropLabel"><i class="bi bi-floppy"></i> Save your settings</h1>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
            <label for="recipient-name" class="col-form-label">Choose a name for these settings:</label>
            <input type="text" class="form-control mb-2" v-model="settings.name">
            <p class="text-warning">
              <i class="bi bi-info-circle"></i> Settings are saved in your browser only (localStorage). 
              If you clear the cache or data for this domain, you will lose them.
            </p>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
          <button type="button" class="btn btn-primary" data-bs-dismiss="modal" @click="saveSettings()">Save</button>
        </div>
      </div>
    </div>
  </div>

  <!-- load modal -->
  <div class="modal fade" id="loadBackdrop" data-bs-keyboard="false" tabindex="-1" aria-labelledby="loadBackdropLabel" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h1 class="modal-title fs-5" id="loadBackdropLabel"><i class="bi bi-floppy"></i> Load settings</h1>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
            <label for="recipient-name" class="col-form-label">Choose a setting to load:</label>
            <div class="list-group">
              <div v-for="setting in settingsCollection">
                <button type="button" class="list-group-item list-group-item-action position-relative" @click.stop="loadSetting(setting)">
                  {{ setting.name }}
                </button>
                <button type="button" class="btn position-absolute top-50 end-0 translate-middle" @click.stop="removeSetting(setting)">
                  <i class="bi bi-trash3"></i>
                </button>
              </div>
              <div v-if="Object.keys(settingsCollection).length == 0"><p class="text-info"><i class="bi bi-info-circle"></i> No settings saved on this browser.</p></div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, useTemplateRef, reactive , onMounted, watch } from "vue";
import { getRandomSeed, createBuffer, createPipeline } from "./utils.ts";
//import { Tooltip, Dropdown } from "bootstrap";
import utilsShader from "./utils.wgsl?raw" with { type: "text" };
import computeShader from "./computeShader.wgsl?raw" with { type: "text" };
import compositingShader from "./compositingShader.wgsl?raw" with { type: "text" };

let initialized = false;
let device: any;
let context: any;
let format: any;
let computeModule: any;
let compositingModule: any;
let uniformBuffer: any;
let noiseBuffer: any;
let outputBuffer: any;
let computePipeline: any;
let compositingPipeline: any;

const noiseTypes = ["Random", "Perlin", "Voronoi"];
const sourceTypes = ["Value", "Normal X", "Normal Y", "0", "1"];
const channelsData = [];
const generating = ref(false);
const error = ref("");
const canvas = useTemplateRef("canvas");
const initialSeed = getRandomSeed();

const defaultGeneratorSettings = {
  type: 1, // set to 0
  seamless: true,
  seed: initialSeed,
  perlinSize: 10.0,
  perlinOctaves: 1,
  perlinLacunarity: 2.0,
  voronoiCellSize: 0.2,
  voronoiFalloff: 1.0,
  voronoiWeight1: 1.0,
  voronoiWeight2: 0.0,
  voronoiWeight3: 0.0,
  voronoiWeight4: 0.0,
  blueNoiseRadius: 1.5
}

const channelsPresets = {
    "Default": [
      { generator: 0, type: 0, invert: false },
      { generator: 0, type: 0, invert: false },
      { generator: 0, type: 0, invert: false },
      { generator: 0, type: 4, invert: false },
    ],
    "Each generator its channel": [
      { generator: 0, type: 0, invert: false },
      { generator: 0, type: 3, invert: false },
      { generator: 0, type: 3, invert: false },
      { generator: 0, type: 4, invert: false },
    ],
    "Generator 0 to Normal map (OpenGL)": [
      { generator: 0, type: 1, invert: false },
      { generator: 0, type: 2, invert: false },
      { generator: 0, type: 4, invert: false },
      { generator: 0, type: 4, invert: false },
    ],
    "Generator 0 to Normal map (DirectX)": [
      { generator: 0, type: 1, invert: false },
      { generator: 0, type: 2, invert: true },
      { generator: 0, type: 4, invert: false },
      { generator: 0, type: 4, invert: false },
    ],
    "Generator 0 to red channel": [
      { generator: 0, type: 0, invert: false },
      { generator: 0, type: 3, invert: false },
      { generator: 0, type: 3, invert: false },
      { generator: 0, type: 4, invert: false },
    ],
    "Generator 1 to green channel": [
      { generator: 0, type: 3, invert: false },
      { generator: 1, type: 0, invert: false },
      { generator: 0, type: 3, invert: false },
      { generator: 0, type: 4, invert: false },
    ],
    "Generator 2 to blue channel": [
      { generator: 0, type: 3, invert: false },
      { generator: 0, type: 3, invert: false },
      { generator: 2, type: 0, invert: false },
      { generator: 0, type: 4, invert: false },
    ],
}

const defaultSettings = {
  name: "Noise",
  resolution: 256,
  dimension: "2d",
  layout: "auto",
  activeGenerator: 0,
  generators: [defaultGeneratorSettings, defaultGeneratorSettings, defaultGeneratorSettings, defaultGeneratorSettings],
  activeChannel: 0,
  channels: channelsPresets["Default"],
  normalScale: 1.0,
}

const settings = reactive(JSON.parse(JSON.stringify(defaultSettings)));
const settingsCollection = reactive(JSON.parse(localStorage.getItem("settingsCollection") || "{}"));
const is3d = computed(() => settings.dimension === "3d" && settings.resolution < 512)
const activeGenerator = computed(() => settings.generators[settings.activeGenerator])
const activeChannel = computed(() => settings.channels[settings.activeChannel])
const canvasWidth = computed(() => settings.resolution * xTiles.value)
const canvasHeight = computed(() => settings.resolution * yTiles.value)

const xTiles = computed(() => {
  const sqr = Math.sqrt(settings.resolution);
  if (!is3d.value) return 1;
  if (settings.layout === "auto") return Number.isInteger(sqr) ? Math.ceil(sqr) : 1;
  if (settings.layout === "square") return Math.ceil(sqr);
  if (settings.layout === "horizontal") return settings.resolution;
  if (settings.layout === "vertical") return 1;
  return 1;
})

const yTiles = computed(() => {
  const sqr = Math.sqrt(settings.resolution);
  if (!is3d.value) return 1;
  if (settings.layout === "auto") return Number.isInteger(sqr) ? Math.ceil(sqr) : settings.resolution;
  if (settings.layout === "square") return Math.ceil(sqr);
  if (settings.layout === "horizontal") return 1;
  if (settings.layout === "vertical") return settings.resolution;
  return 1;
})

watch(() => settings.dimension, (newValue, oldValue) => {
  setupRenderPipeline();
})

watch(() => settings.layout, (newValue, oldValue) => {
  setupRenderPipeline();
})

watch(() => settings.resolution, (newValue, oldValue) => {
  setupRenderPipeline();
})

watch(settings, (newValue, oldValue) => {
  generateNoise(true);
})

onMounted(async () => {
  [...document.querySelectorAll('[data-bs-toggle="tooltip"]')].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl)); // doesn't work on hidden panels
  try {
    const adapter = await navigator.gpu.requestAdapter();
    device = await adapter.requestDevice({
      requiredLimits: {
        maxBufferSize: 2147483644,
        maxStorageBufferBindingSize: 2147483644,
        maxTextureDimension2D: 16384
      }
    });
    context = canvas.value?.getContext("webgpu");
    if (!context) throw new Error("Can't get the webgpu context");
    format = navigator.gpu.getPreferredCanvasFormat();
    computeModule = device.createShaderModule({ code: utilsShader + computeShader }),
    compositingModule = device.createShaderModule({ code: utilsShader + compositingShader });
    context.configure({ device, format, alphaMode: "opaque" });
    initialized = true;
    setupRenderPipeline();
    await generateNoise(true);
  } catch(e) {
    error.value = `Your browser doesn't support webGPU! error: ${e.message}`;
    console.error(e);
    initialized = false;
  }
})


function GetUniformData(generator: number) {
  return new Float32Array([
    generator,
    settings.resolution,
    settings.resolution,
    is3d.value ? settings.resolution : 1,
    xTiles.value,
    yTiles.value,
    settings.generators[generator].type,
    settings.generators[generator].perlinSize,
    settings.generators[generator].perlinOctaves,
    settings.generators[generator].perlinLacunarity,
    settings.generators[generator].voronoiCellSize,
    settings.generators[generator].voronoiFalloff,
    settings.generators[generator].voronoiWeight1,
    settings.generators[generator].voronoiWeight2,
    settings.generators[generator].voronoiWeight3,
    settings.generators[generator].voronoiWeight4,
    settings.generators[generator].seamless ? 1 : 0,
    settings.generators[generator].seed,
    settings.channels[0].generator,
    settings.channels[0].type,
    settings.channels[0].invert ? 1 : 0,
    settings.channels[1].generator,
    settings.channels[1].type,
    settings.channels[1].invert ? 1 : 0,
    settings.channels[2].generator,
    settings.channels[2].type,
    settings.channels[2].invert ? 1 : 0,
    settings.channels[3].generator,
    settings.channels[3].type,
    settings.channels[3].invert ? 1 : 0,
  ]);
}


function setupRenderPipeline() {
  if (initialized == false) return;
  const resolutionX = settings.resolution;
  const resolutionY = settings.resolution;
  const resolutionZ = is3d.value ? settings.resolution : 1;

  canvas.value.width = canvasWidth.value;
  canvas.value.height = canvasHeight.value;

  uniformBuffer = device.createBuffer({
    size: GetUniformData(0).byteLength,
    usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
  });

  noiseBuffer = device.createBuffer({
    size: resolutionX * resolutionY * resolutionZ * 4 * 4,
    usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST,
  });

  outputBuffer = device.createBuffer({
    size: canvasWidth.value * canvasHeight.value * 4 * 4,
    usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST,
  });

  const bindGroupLayout = device.createBindGroupLayout({
    entries: [
      { binding: 0, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.VERTEX | GPUShaderStage.FRAGMENT, buffer: { type: 'uniform' }, },
      { binding: 1, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.FRAGMENT, buffer: { type: 'storage' }, },
      { binding: 2, visibility: GPUShaderStage.COMPUTE | GPUShaderStage.FRAGMENT, buffer: { type: 'storage' }, },
    ],
  });
  const pipelineLayout = device.createPipelineLayout({
    bindGroupLayouts: [bindGroupLayout]
  });

  computePipeline = device.createComputePipeline({
    label: 'ComputePipeline',
    layout: pipelineLayout,
    compute: {
      module: computeModule,
      entryPoint: 'main'
    }
  });

  compositingPipeline = device.createRenderPipeline({
    label: 'CompositingPipeline',
    layout: pipelineLayout,
    vertex: {
      module: compositingModule,
      entryPoint: "vertex"
    },
    fragment: {
      module: compositingModule,
      entryPoint: "fragment",
      targets: [{ format }]
    },
    primitive: {
      topology: 'triangle-list'
    }
  });
}


function generateNoise(allChannels: boolean) {
  if (initialized == false) return;
  const resolutionX = settings.resolution;
  const resolutionY = settings.resolution;
  const resolutionZ = is3d.value ? settings.resolution : 1;
  const dispatchX = Math.ceil(resolutionX  / 4);
  const dispatchY = Math.ceil(resolutionY / 4);
  const dispatchZ = Math.ceil(resolutionZ  / 4);

  const computeBindGroup = device.createBindGroup({
    layout: computePipeline.getBindGroupLayout(0),
    entries: [
      { binding: 0, resource: { buffer: uniformBuffer } },
      { binding: 1, resource: { buffer: noiseBuffer } },
      { binding: 2, resource: { buffer: outputBuffer } },
    ]
  });

  const compositingBindGroup = device.createBindGroup({
    layout: compositingPipeline.getBindGroupLayout(0),
    entries: [
      { binding: 0, resource: { buffer: uniformBuffer } },
      { binding: 1, resource: { buffer: noiseBuffer } },
      { binding: 2, resource: { buffer: outputBuffer } },
    ]
  });


  for (let c = 0; c < 4; c++) {
    device.queue.writeBuffer(uniformBuffer, 0, GetUniformData(c));
    const commandEncoder = device.createCommandEncoder();
    const computePass = commandEncoder.beginComputePass();
    computePass.setPipeline(computePipeline);
    computePass.setBindGroup(0, computeBindGroup);
    computePass.dispatchWorkgroups(dispatchX, dispatchY, dispatchZ);
    computePass.end();
    device.queue.submit([commandEncoder.finish()]);
  }

  const commandEncoder = device.createCommandEncoder();
  const compositingPass = commandEncoder.beginRenderPass({
    colorAttachments: [{
      view: context.getCurrentTexture().createView(),
      clearValue: { r: 0, g: 0, b: 0, a: 1 },
      loadOp: 'load',
      storeOp: 'store',
    }]
  });
  compositingPass.setPipeline(compositingPipeline);
  compositingPass.setBindGroup(0, compositingBindGroup);
  compositingPass.draw(6);
  compositingPass.end();

  device.queue.submit([commandEncoder.finish()]);
}


function onPresetSelection(channelPresetName) {
  settings.channels = structuredClone(channelsPresets[channelPresetName]);
}


async function getImageData() {
  const resultBuffer = device.createBuffer({
    size: canvasWidth.value * canvasHeight.value * 4 * 4,
    usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ,
  });
  const encoder = device.createCommandEncoder();
  encoder.copyBufferToBuffer(outputBuffer, 0, resultBuffer, 0, canvasWidth.value * canvasHeight.value * 4 * 4);
  device.queue.submit([encoder.finish()]);

  await resultBuffer.mapAsync(GPUMapMode.READ);
  const floatArray = new Float32Array(resultBuffer.getMappedRange().slice());
  resultBuffer.unmap();
  resultBuffer.destroy();

  const clampedArray = new Uint8ClampedArray(canvasWidth.value * canvasHeight.value * 4);

  for (let i = 0; i < clampedArray.length; i++) {
    const val = floatArray[i];
    clampedArray[i] = Math.max(0, Math.min(255, val <= 1 ? val * 255 : val));
  }

  return new ImageData(clampedArray, canvasWidth.value, canvasHeight.value);
}


async function exportImage() {
  generating.value = true;
  try {
    const imageData = await getImageData();
    const canvas = document.createElement("canvas");
    canvas.width = canvasWidth.value;
    canvas.height = canvasHeight.value;
    canvas.getContext("2d").putImageData(imageData, 0, 0);

    const link = document.createElement("a");
    link.download = `${settings.name}.png`;
    link.href = canvas.toDataURL("image/png") || "";
    link.click();

    link.remove();
    canvas.remove();
  } catch (err) {
    alert("Failed to export image: " + err);
  }
  generating.value = false;
}

async function copyImageToClipboard() {
  generating.value = true;
  try {
    const imageData = await getImageData();
    const canvas = document.createElement("canvas");
    canvas.width = canvasWidth.value;
    canvas.height = canvasHeight.value;
    canvas.getContext("2d").putImageData(imageData, 0, 0);

    const blob = await new Promise(resolve => canvas.toBlob(resolve));
    const item = new ClipboardItem({ 'image/png': blob as Blob });
    await navigator.clipboard.write([item]);
    alert("Image copied to clipboard!");
  } catch (err) {
    alert("Failed to copy: " + err);
  }
  generating.value = false;
}


async function loadSetting(loadedSettings: any) {
  Object.assign(settings, loadedSettings);
  setupRenderPipeline();
  //loadModal.hide();
}


function removeSetting(setting: any) {
  if (confirm(`Really delete setting ${setting.name}`)) {
    delete settingsCollection[setting.name];
    localStorage.setItem("settingsCollection", JSON.stringify(settingsCollection));
  }
}


function saveSettings() {
  try {
    const settingsCollection = JSON.parse(localStorage.getItem("settingsCollection") || "{}");
    settingsCollection[settings.name] = settings
    localStorage.setItem("settingsCollection", JSON.stringify(settingsCollection));
  } catch(e) {
    fixSettingsCollection();
  }
}


function fixSettingsCollection() {
  alert("Your settings collection was corrupted. They were cleared to fix the issue.")
  localStorage.setItem("settingsCollection", "{}");
}
</script>

<style lang="scss">
@use "../node_modules/bootstrap/dist/css/bootstrap.min.css";
@use "../node_modules/bootstrap-icons/font/bootstrap-icons.css";
@use './style.css';
</style>
