import * as THREE from 'three';
import { OrbitControls } from './vendor/OrbitControls.js';
import { TransformControls } from './vendor/TransformControls.js';

// ---------------------------------------------------------------------------
// Data model
// Course order and member names follow GameBehaviour.ls (setupGame / setupCourse).
// ---------------------------------------------------------------------------
const COURSE_NAMES = {
  1: 'Track 1 · Sky 1', 2: 'Track 2 · Sky 1', 3: 'Track 3 · Sky 1',
  4: 'Track 1 · Sky 2', 5: 'Track 2 · Sky 2', 6: 'Track 3 · Sky 2',
  7: 'Track 1 · Sky 3', 8: 'Track 2 · Sky 3', 9: 'Track 3 · Sky 3',
};
const LAYERS = [
  { key: 'checkpoints', label: 'Checkpoints', color: 0x8b5cf6, shape: 'octa', lift: 200 },
  { key: 'slalom', label: 'Slalom gates', color: 0xf59e0b, shape: 'pole', lift: 375 },
  { key: 'photos', label: 'Photo spots', color: 0x38bdf8, shape: 'box', lift: 375 },
  { key: 'weapons', label: 'Weapons', color: 0xef4444, shape: 'ball', lift: 375 },
  { key: 'weaponsx', label: 'Weapons (battle only)', color: 0xec4899, shape: 'ball', lift: 375 },
];
const LAYER = Object.fromEntries(LAYERS.map(l => [l.key, l]));
const HIDDEN_NODES = /^(Track\d|Sky\d|NullRes)/;
const RIBBON_DROP = 300;            // checkpoints sit above the riding surface
const STORE_KEY = 'sewerrun-editor-v1';

const state = {
  original: null,                  // courses.json as shipped
  nodes: null,                     // scenery nodes per course
  data: {},                        // working copy, per course
  course: 1,
  visible: Object.fromEntries(LAYERS.map(l => [l.key, true])),
  selected: null,                  // { layer, index }
  undo: {}, redo: {},
  markerSize: 1,                   // on-screen size multiplier
  trackWidth: 5000,
};

const clone = o => JSON.parse(JSON.stringify(o));
const cur = () => state.data[state.course];

// ---------------------------------------------------------------------------
// Three.js scene
// ---------------------------------------------------------------------------
const viewport = document.getElementById('viewport');
const renderer = new THREE.WebGLRenderer({ antialias: true, logarithmicDepthBuffer: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
viewport.prepend(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0a0b0f);
const camera = new THREE.PerspectiveCamera(50, 1, 10, 3e6);
scene.add(new THREE.HemisphereLight(0xdfe3ff, 0x22232b, 1.6));
const sun = new THREE.DirectionalLight(0xffffff, 1.4);
sun.position.set(0.4, 1, 0.3);
scene.add(sun);

const orbit = new OrbitControls(camera, renderer.domElement);
orbit.enableDamping = true;
orbit.screenSpacePanning = true;

const gizmo = new TransformControls(camera, renderer.domElement);
gizmo.setSize(0.9);
scene.add(gizmo.getHelper());

const trackGroup = new THREE.Group();
const markerGroup = new THREE.Group();
const sceneryGroup = new THREE.Group();
scene.add(trackGroup, markerGroup, sceneryGroup);
let grid = null;
let ribbonMesh = null;

const geoms = {
  octa: new THREE.OctahedronGeometry(1),
  pole: new THREE.CylinderGeometry(0.35, 0.35, 3, 12).translate(0, 1.5, 0),
  box: new THREE.BoxGeometry(1.4, 1.4, 1.4),
  ball: new THREE.SphereGeometry(0.9, 20, 14),
  scenery: new THREE.BoxGeometry(1, 1, 1),
};
const mats = Object.fromEntries(LAYERS.map(l => [l.key, new THREE.MeshStandardMaterial({ color: l.color, roughness: .45, metalness: .1, emissive: l.color, emissiveIntensity: .25 })]));
const selMat = new THREE.MeshStandardMaterial({ color: 0xffffff, emissive: 0xffffff, emissiveIntensity: .6 });
const sceneryMats = {};
function sceneryMat(res) {
  if (!sceneryMats[res]) {
    const hue = [...res].reduce((h, c) => (h * 31 + c.charCodeAt(0)) % 360, 7);
    sceneryMats[res] = new THREE.MeshStandardMaterial({ color: new THREE.Color(`hsl(${hue}, 18%, 52%)`), roughness: .8, transparent: true, opacity: .75 });
  }
  return sceneryMats[res];
}

// ---------------------------------------------------------------------------
// Persistence & undo
// ---------------------------------------------------------------------------
function save() {
  const edited = {};
  for (const c of Object.keys(state.data)) {
    if (JSON.stringify(state.data[c]) !== JSON.stringify(state.original[c])) edited[c] = state.data[c];
  }
  localStorage.setItem(STORE_KEY, JSON.stringify(edited));
}
function pushUndo() {
  const c = state.course;
  (state.undo[c] ||= []).push(JSON.stringify(cur()));
  if (state.undo[c].length > 200) state.undo[c].shift();
  state.redo[c] = [];
  updateUndoButtons();
}
function stepHistory(from, to) {
  const c = state.course;
  const stack = state[from][c];
  if (!stack?.length) return;
  (state[to][c] ||= []).push(JSON.stringify(cur()));
  state.data[c] = JSON.parse(stack.pop());
  const s = state.selected;
  if (s && s.index >= cur()[s.layer].length) state.selected = null;
  commit({ refit: false });
}
function updateUndoButtons() {
  document.getElementById('undo').disabled = !state.undo[state.course]?.length;
  document.getElementById('redo').disabled = !state.redo[state.course]?.length;
}
// call after any data change
function commit({ refit = false } = {}) {
  save();
  buildTrack();
  buildMarkers();
  renderLayerList();
  renderSelection();
  updateUndoButtons();
  if (refit) fitView();
}

// ---------------------------------------------------------------------------
// Track ribbon (built from checkpoint path)
// ---------------------------------------------------------------------------
function buildTrack() {
  trackGroup.clear();
  ribbonMesh = null;
  const cps = cur().checkpoints.map(c => new THREE.Vector3(...c.pos).add(new THREE.Vector3(0, -RIBBON_DROP, 0)));
  if (cps.length < 2) return;
  const curve = new THREE.CatmullRomCurve3(cps, false, 'centripetal');
  const n = cps.length * 24;
  const pts = curve.getSpacedPoints(n);
  const up = new THREE.Vector3(0, 1, 0);
  const pos = [], idx = [];
  const half = state.trackWidth / 2;
  const left = [], right = [];
  for (let i = 0; i <= n; i++) {
    const t = curve.getTangentAt(i / n);
    const side = new THREE.Vector3().crossVectors(t, up).normalize().multiplyScalar(half);
    const p = pts[i];
    const l = p.clone().add(side), r = p.clone().sub(side);
    // low banks either side, like the drain profile
    const lw = l.clone().addScaledVector(side, .25).add(new THREE.Vector3(0, half * .35, 0));
    const rw = r.clone().addScaledVector(side, -.25).add(new THREE.Vector3(0, half * .35, 0));
    pos.push(...lw.toArray(), ...l.toArray(), ...r.toArray(), ...rw.toArray());
    left.push(lw); right.push(rw);
    if (i < n) {
      const a = i * 4, b = (i + 1) * 4;
      for (let k = 0; k < 3; k++) idx.push(a + k, b + k, a + k + 1, a + k + 1, b + k, b + k + 1);
    }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setIndex(idx);
  g.computeVertexNormals();
  ribbonMesh = new THREE.Mesh(g, new THREE.MeshStandardMaterial({ color: 0x6b7080, roughness: .95, side: THREE.DoubleSide, transparent: true, opacity: .85 }));
  trackGroup.add(ribbonMesh);

  const lineMat = new THREE.LineBasicMaterial({ color: 0x8b5cf6, transparent: true, opacity: .8 });
  trackGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), lineMat));
  const edgeMat = new THREE.LineBasicMaterial({ color: 0x3b3f4d });
  trackGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(left), edgeMat));
  trackGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(right), edgeMat));
}

// ---------------------------------------------------------------------------
// Markers (editable) and scenery (read-only)
// ---------------------------------------------------------------------------
function buildMarkers() {
  const keepSel = state.selected;
  gizmo.detach();
  markerGroup.clear();
  for (const layer of LAYERS) {
    if (!state.visible[layer.key]) continue;
    cur()[layer.key].forEach((item, index) => {
      const isSel = keepSel && keepSel.layer === layer.key && keepSel.index === index;
      const m = new THREE.Mesh(geoms[layer.shape], isSel ? selMat : mats[layer.key]);
      m.position.set(...item.pos);
      m.userData = { layer: layer.key, index };
      if (layer.key === 'checkpoints') {
        const dir = new THREE.Vector3(...item.axis).negate();
        if (dir.lengthSq() > 1e-9) {
          const arrow = new THREE.ArrowHelper(dir.normalize(), new THREE.Vector3(), 6, layer.color, 1.6, 1);
          arrow.line.material.depthTest = false;
          m.add(arrow);
        }
      }
      markerGroup.add(m);
      if (isSel) gizmo.attach(m);
    });
  }
}

function buildScenery() {
  sceneryGroup.clear();
  const m4 = new THREE.Matrix4(), p = new THREE.Vector3(), q = new THREE.Quaternion(), sc = new THREE.Vector3();
  for (const node of state.nodes[state.course] || []) {
    if (HIDDEN_NODES.test(node.resource)) continue;
    m4.fromArray(node.matrix).decompose(p, q, sc);
    const mesh = new THREE.Mesh(geoms.scenery, sceneryMat(node.resource));
    mesh.position.copy(p);
    mesh.quaternion.copy(q);
    mesh.userData = { scenery: node };
    sceneryGroup.add(mesh);
  }
}

// ---------------------------------------------------------------------------
// Camera helpers
// ---------------------------------------------------------------------------
function courseBounds() {
  const box = new THREE.Box3();
  for (const l of LAYERS) for (const it of cur()[l.key]) box.expandByPoint(new THREE.Vector3(...it.pos));
  if (box.isEmpty()) box.setFromCenterAndSize(new THREE.Vector3(), new THREE.Vector3(10000, 10000, 10000));
  return box;
}
function fitView() {
  const box = courseBounds();
  const c = box.getCenter(new THREE.Vector3());
  const r = box.getSize(new THREE.Vector3()).length() / 2;
  orbit.target.copy(c);
  camera.position.copy(c).add(new THREE.Vector3(r * .9, r * .7, r * .9));
  camera.lookAt(c);
  orbit.update();
  placeGrid(box);
}
function topView() {
  const box = courseBounds();
  const c = box.getCenter(new THREE.Vector3());
  const r = box.getSize(new THREE.Vector3()).length() / 2;
  orbit.target.copy(c);
  camera.position.set(c.x, c.y + r * 1.9, c.z + 1);
  orbit.update();
}
function focusSelected() {
  const m = selectedMesh();
  if (!m) return;
  const off = camera.position.clone().sub(orbit.target).setLength(30000);
  orbit.target.copy(m.position);
  camera.position.copy(m.position).add(off);
  orbit.update();
}
function placeGrid(box) {
  if (grid) scene.remove(grid);
  const size = Math.max(box.max.x - box.min.x, box.max.z - box.min.z) * 1.4;
  grid = new THREE.GridHelper(size, 40, 0x2a2c38, 0x1a1b23);
  const c = box.getCenter(new THREE.Vector3());
  grid.position.set(c.x, box.min.y - 2000, c.z);
  scene.add(grid);
}

// ---------------------------------------------------------------------------
// Selection & editing
// ---------------------------------------------------------------------------
function selectedMesh() {
  const s = state.selected;
  return s && markerGroup.children.find(m => m.userData.layer === s.layer && m.userData.index === s.index);
}
function select(sel) {
  state.selected = sel;
  if (sel && !state.visible[sel.layer]) state.visible[sel.layer] = true;
  buildMarkers();
  renderSelection();
  renderLayerList();
}
function renderSelection() {
  const panel = document.getElementById('selPanel');
  const s = state.selected;
  if (!s) { panel.classList.add('hidden'); return; }
  const item = cur()[s.layer][s.index];
  panel.classList.remove('hidden');
  document.getElementById('selTitle').textContent = `${LAYER[s.layer].label} #${s.index + 1}`;
  document.getElementById('axisBlock').classList.toggle('hidden', s.layer !== 'checkpoints');
  for (const input of panel.querySelectorAll('input[data-k]')) {
    const v = item[input.dataset.k]?.[+input.dataset.i];
    if (document.activeElement !== input && v !== undefined) input.value = +v.toFixed(4);
  }
}
function moveSelection(step) {
  const s = state.selected;
  if (!s) return;
  const n = cur()[s.layer].length;
  if (!n) return;
  select({ layer: s.layer, index: (s.index + step + n) % n });
  focusSelected();
}
function deleteSelected() {
  const s = state.selected;
  if (!s) return;
  if (s.layer === 'checkpoints' && cur().checkpoints.length <= 2) return flash('A course needs at least 2 checkpoints');
  pushUndo();
  cur()[s.layer].splice(s.index, 1);
  const n = cur()[s.layer].length;
  state.selected = n ? { layer: s.layer, index: Math.min(s.index, n - 1) } : null;
  commit();
}
function alignCheckpoint(i) {
  const cps = cur().checkpoints;
  const a = new THREE.Vector3(...cps[i].pos);
  const b = i + 1 < cps.length ? new THREE.Vector3(...cps[i + 1].pos) : a.clone().multiplyScalar(2).sub(new THREE.Vector3(...cps[i - 1].pos));
  const axis = a.sub(b).normalize();          // game stores the reverse of travel direction
  cps[i].axis = axis.toArray().map(v => +v.toFixed(4));
}
function nearestSegment(p) {
  const cps = cur().checkpoints.map(c => new THREE.Vector3(...c.pos));
  let best = cps.length, bestD = Infinity;
  const seg = new THREE.Line3(), q = new THREE.Vector3();
  for (let i = 0; i < cps.length - 1; i++) {
    seg.set(cps[i], cps[i + 1]);
    const d = seg.closestPointToPoint(p, true, q).distanceToSquared(p);
    if (d < bestD) { bestD = d; best = i + 1; }
  }
  return best;
}
function addPoint(layerKey, at) {
  pushUndo();
  const list = cur()[layerKey];
  const lift = LAYER[layerKey].lift;
  let pos, index;
  if (at) {
    pos = at.clone().add(new THREE.Vector3(0, RIBBON_DROP + lift - 200, 0));
    index = layerKey === 'checkpoints' ? nearestSegment(pos) : list.length;
  } else {
    // insert after the selected item of the same layer, or at the end
    const s = state.selected;
    const i = s && s.layer === layerKey ? s.index : list.length - 1;
    const a = list[i] ? new THREE.Vector3(...list[i].pos) : orbit.target.clone();
    const b = list[i + 1] ? new THREE.Vector3(...list[i + 1].pos) : a.clone().add(new THREE.Vector3(0, 0, -8000));
    pos = a.clone().lerp(b, .5);
    index = i + 1;
  }
  const item = { pos: pos.toArray().map(v => +v.toFixed(4)) };
  if (layerKey === 'checkpoints') item.axis = [0, 0, 1];
  list.splice(index, 0, item);
  if (layerKey === 'checkpoints') alignCheckpoint(index);
  state.selected = { layer: layerKey, index };
  state.visible[layerKey] = true;
  commit();
}
function snapSelected() {
  const s = state.selected;
  if (!s || !ribbonMesh) return;
  const item = cur()[s.layer][s.index];
  const ray = new THREE.Raycaster(new THREE.Vector3(item.pos[0], item.pos[1] + 1e5, item.pos[2]), new THREE.Vector3(0, -1, 0));
  const hit = ray.intersectObject(ribbonMesh)[0];
  if (!hit) return flash('No track surface below this point');
  pushUndo();
  item.pos[1] = +(hit.point.y + RIBBON_DROP + LAYER[s.layer].lift - 200).toFixed(4);
  commit();
}

let dragStart = null;
gizmo.addEventListener('dragging-changed', e => { orbit.enabled = !e.value; });
gizmo.addEventListener('mouseDown', () => { dragStart = JSON.stringify(cur()); });
gizmo.addEventListener('objectChange', () => {
  const m = gizmo.object;
  if (!m) return;
  const { layer, index } = m.userData;
  cur()[layer][index].pos = m.position.toArray().map(v => +v.toFixed(4));
  if (layer === 'checkpoints') buildTrack();
  renderSelection();
});
gizmo.addEventListener('mouseUp', () => {
  if (dragStart && dragStart !== JSON.stringify(cur())) {
    const c = state.course;
    (state.undo[c] ||= []).push(dragStart);
    state.redo[c] = [];
    save();
    renderLayerList();
    updateUndoButtons();
  }
  dragStart = null;
});

// ---------------------------------------------------------------------------
// Picking
// ---------------------------------------------------------------------------
const raycaster = new THREE.Raycaster();
const ndc = new THREE.Vector2();
function pick(ev, objects) {
  const r = renderer.domElement.getBoundingClientRect();
  ndc.set(((ev.clientX - r.left) / r.width) * 2 - 1, -((ev.clientY - r.top) / r.height) * 2 + 1);
  raycaster.setFromCamera(ndc, camera);
  return raycaster.intersectObjects(objects, false)[0];
}
let downAt = null;
renderer.domElement.addEventListener('pointerdown', e => { downAt = [e.clientX, e.clientY]; });
renderer.domElement.addEventListener('pointerup', e => {
  if (!downAt || gizmo.dragging) return;
  const moved = Math.hypot(e.clientX - downAt[0], e.clientY - downAt[1]);
  downAt = null;
  if (moved > 4 || e.button !== 0) return;
  if (e.shiftKey) {
    const hit = pick(e, ribbonMesh ? [ribbonMesh, ...sceneryGroup.children] : sceneryGroup.children);
    if (hit) addPoint(document.getElementById('addLayer').value, hit.point);
    else flash('Shift+click on the track to add a point');
    return;
  }
  const hit = pick(e, markerGroup.children);
  if (hit) select({ layer: hit.object.userData.layer, index: hit.object.userData.index });
  else if (!gizmo.axis) select(null);
});

const tip = document.getElementById('tip');
let hoverQueued = false, lastMove = null;
renderer.domElement.addEventListener('pointermove', e => {
  lastMove = e;
  if (hoverQueued) return;
  hoverQueued = true;
  requestAnimationFrame(() => {
    hoverQueued = false;
    if (!document.getElementById('showLabels').checked || gizmo.dragging) return tip.classList.add('hidden');
    const hit = pick(lastMove, [...markerGroup.children, ...(sceneryGroup.visible ? sceneryGroup.children : [])]);
    if (!hit) return tip.classList.add('hidden');
    const u = hit.object.userData;
    tip.textContent = u.scenery ? `${u.scenery.name}  (scenery)` : `${LAYER[u.layer].label} #${u.index + 1}`;
    const r = viewport.getBoundingClientRect();
    tip.style.left = `${lastMove.clientX - r.left}px`;
    tip.style.top = `${lastMove.clientY - r.top}px`;
    tip.classList.remove('hidden');
  });
});

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------
const $ = id => document.getElementById(id);
function renderLayerList() {
  const el = $('layers');
  el.innerHTML = '';
  for (const l of LAYERS) {
    const dirty = JSON.stringify(cur()[l.key]) !== JSON.stringify(state.original[state.course][l.key]);
    const row = document.createElement('label');
    row.className = 'layer';
    row.innerHTML = `<input type="checkbox" ${state.visible[l.key] ? 'checked' : ''}>
      <span class="swatch" style="background:#${l.color.toString(16).padStart(6, '0')}"></span>
      <span class="name">${l.label}</span>${dirty ? '<span class="dirty">edited</span>' : ''}
      <span class="count">${cur()[l.key].length}</span>`;
    row.querySelector('input').addEventListener('change', ev => {
      state.visible[l.key] = ev.target.checked;
      if (!ev.target.checked && state.selected?.layer === l.key) state.selected = null;
      buildMarkers(); renderSelection();
    });
    el.append(row);
  }
  const edited = Object.keys(state.data).filter(c => JSON.stringify(state.data[c]) !== JSON.stringify(state.original[c]));
  $('status').textContent = edited.length ? `Edited courses: ${edited.join(', ')} · saved in this browser` : 'No edits yet';
  for (const opt of $('course').options) opt.textContent = `${opt.value}. ${COURSE_NAMES[opt.value]}${edited.includes(opt.value) ? ' •' : ''}`;
}
let flashTimer;
function flash(msg) {
  const s = $('status');
  s.textContent = msg;
  s.style.color = '#fecdd3';
  clearTimeout(flashTimer);
  flashTimer = setTimeout(() => { s.style.color = ''; renderLayerList(); }, 2200);
}

function loadCourse(c) {
  state.course = +c;
  state.selected = null;
  buildScenery();
  commit({ refit: true });
}

function wireUI() {
  const courseSel = $('course');
  for (const c of Object.keys(COURSE_NAMES)) courseSel.add(new Option(`${c}. ${COURSE_NAMES[c]}`, c));
  courseSel.addEventListener('change', () => loadCourse(courseSel.value));
  for (const l of LAYERS) $('addLayer').add(new Option(l.label, l.key));

  $('undo').onclick = () => stepHistory('undo', 'redo');
  $('redo').onclick = () => stepHistory('redo', 'undo');
  $('topView').onclick = topView;
  $('fitView').onclick = fitView;
  $('addBtn').onclick = () => addPoint($('addLayer').value);
  $('delBtn').onclick = deleteSelected;
  $('prevBtn').onclick = () => moveSelection(-1);
  $('nextBtn').onclick = () => moveSelection(1);
  $('dropBtn').onclick = snapSelected;
  $('alignBtn').onclick = () => { pushUndo(); alignCheckpoint(state.selected.index); commit(); };
  $('alignAllBtn').onclick = () => { pushUndo(); cur().checkpoints.forEach((_, i) => alignCheckpoint(i)); commit(); };
  $('resetCourse').onclick = () => {
    if (!confirm(`Discard all edits to course ${state.course}? You can undo this.`)) return;
    pushUndo();
    state.data[state.course] = clone(state.original[state.course]);
    state.selected = null;
    commit();
  };

  for (const input of document.querySelectorAll('#selPanel input[data-k]')) {
    input.addEventListener('change', () => {
      const s = state.selected;
      const v = parseFloat(input.value);
      if (!s || !Number.isFinite(v)) return renderSelection();
      pushUndo();
      cur()[s.layer][s.index][input.dataset.k][+input.dataset.i] = v;
      commit();
    });
  }

  $('markerSize').addEventListener('input', e => { state.markerSize = +e.target.value / 100; });
  $('trackWidth').addEventListener('input', e => { state.trackWidth = +e.target.value; buildTrack(); });
  $('showScenery').addEventListener('change', e => { sceneryGroup.visible = e.target.checked; });

  window.addEventListener('keydown', e => {
    if (e.target.matches('input, select, textarea')) return;
    const mod = e.metaKey || e.ctrlKey;
    if (mod && e.key.toLowerCase() === 'z') { e.preventDefault(); stepHistory(e.shiftKey ? 'redo' : 'undo', e.shiftKey ? 'undo' : 'redo'); }
    else if (mod && e.key.toLowerCase() === 'y') { e.preventDefault(); stepHistory('redo', 'undo'); }
    else if (e.key === 'Delete' || e.key === 'Backspace') { e.preventDefault(); deleteSelected(); }
    else if (e.key === 'Escape') select(null);
    else if (e.key === 'f') focusSelected();
    else if (e.key === 'h') fitView();
    else if (e.key === 't') topView();
    else if (e.key === '[') moveSelection(-1);
    else if (e.key === ']') moveSelection(1);
  });

  wireExport();
}

// ---------------------------------------------------------------------------
// Export / import
// ---------------------------------------------------------------------------
// Lingo's value() reads plain decimals and e-notation, as used in the original members.
const num = v => String(+(+v).toFixed(4));
const vec = p => `vector( ${num(p[0])}, ${num(p[1])}, ${num(p[2])} )`;
function memberText(course, key) {
  const items = state.data[course][key];
  const lines = key === 'checkpoints' ? items.flatMap(c => [vec(c.pos), vec(c.axis)]) : items.map(i => vec(i.pos));
  return lines.join('\n');
}
function download(name, text, type = 'text/plain') {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([text], { type }));
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
function wireExport() {
  const modal = $('exportModal');
  let tab = 'checkpoints';
  const show = () => {
    $('exportCourse').textContent = `course ${state.course} (${COURSE_NAMES[state.course]})`;
    $('exportTabs').innerHTML = '';
    for (const l of LAYERS) {
      const b = document.createElement('button');
      b.textContent = `${l.key}${state.course}`;
      b.className = l.key === tab ? 'active' : '';
      b.onclick = () => { tab = l.key; show(); };
      $('exportTabs').append(b);
    }
    $('exportText').value = memberText(state.course, tab);
  };
  $('exportBtn').onclick = () => { show(); modal.classList.remove('hidden'); };
  $('exportClose').onclick = () => modal.classList.add('hidden');
  modal.addEventListener('click', e => { if (e.target === modal) modal.classList.add('hidden'); });
  $('copyBtn').onclick = async () => {
    await navigator.clipboard.writeText($('exportText').value);
    $('copyBtn').textContent = 'Copied';
    setTimeout(() => { $('copyBtn').textContent = 'Copy'; }, 1200);
  };
  $('dlTxtBtn').onclick = () => download(`${tab}${state.course}.txt`, $('exportText').value);
  $('dlAllBtn').onclick = () => download('sewerrun-courses.json', JSON.stringify({ format: 'sewerrun-courses', version: 1, courses: state.data }, null, 1), 'application/json');
  $('importFile').addEventListener('change', async e => {
    const file = e.target.files[0];
    e.target.value = '';
    if (!file) return;
    try {
      const json = JSON.parse(await file.text());
      const courses = validateImport(json);
      for (const c of Object.keys(courses)) { (state.undo[c] ||= []).push(JSON.stringify(state.data[c])); state.redo[c] = []; }
      Object.assign(state.data, courses);
      modal.classList.add('hidden');
      state.selected = null;
      commit({ refit: true });
      flash(`Imported ${Object.keys(courses).length} course(s)`);
    } catch (err) {
      alert(`Import failed: ${err.message}`);
    }
  });
}
function validateImport(json) {
  if (json?.format !== 'sewerrun-courses' || typeof json.courses !== 'object') throw new Error('not a Sewer Run course file');
  const isVec = v => Array.isArray(v) && v.length === 3 && v.every(Number.isFinite);
  const out = {};
  for (const [c, data] of Object.entries(json.courses)) {
    if (!COURSE_NAMES[c]) throw new Error(`unknown course ${c}`);
    for (const l of LAYERS) {
      if (!Array.isArray(data[l.key])) throw new Error(`course ${c}: missing ${l.key}`);
      for (const it of data[l.key]) {
        if (!isVec(it.pos) || (l.key === 'checkpoints' && !isVec(it.axis))) throw new Error(`course ${c}: bad ${l.key} entry`);
      }
    }
    out[c] = clone(data);
  }
  return out;
}

// keep markers a constant size on screen, whatever the zoom
const _wp = new THREE.Vector3();
function scaleToScreen() {
  const k = Math.tan(THREE.MathUtils.degToRad(camera.fov / 2)) * 0.012 * state.markerSize;
  for (const m of markerGroup.children) m.scale.setScalar(m.getWorldPosition(_wp).distanceTo(camera.position) * k);
  for (const m of sceneryGroup.children) {
    const d = m.getWorldPosition(_wp).distanceTo(camera.position) * k;
    m.scale.set(d * 1.6, d * .8, d * 1.6);
  }
}

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------
function resize() {
  const r = viewport.getBoundingClientRect();
  renderer.setSize(r.width, r.height);
  camera.aspect = r.width / r.height;
  camera.updateProjectionMatrix();
}
new ResizeObserver(resize).observe(viewport);

async function boot() {
  const [courses, nodes] = await Promise.all(['data/courses.json', 'data/nodes.json'].map(u => fetch(u).then(r => {
    if (!r.ok) throw new Error(`${u}: ${r.status}`);
    return r.json();
  })));
  state.original = courses;
  state.nodes = nodes;
  for (const c of Object.keys(COURSE_NAMES)) {
    for (const l of LAYERS) courses[c][l.key] ||= [];
    state.data[c] = clone(courses[c]);
  }
  try {
    const saved = JSON.parse(localStorage.getItem(STORE_KEY) || '{}');
    Object.assign(state.data, validateImport({ format: 'sewerrun-courses', courses: saved }));
  } catch (err) {
    console.warn('Ignoring saved edits:', err);
  }
  wireUI();
  resize();
  loadCourse(1);
  renderer.setAnimationLoop(() => {
    orbit.update();
    scaleToScreen();
    renderer.render(scene, camera);
  });
}
// small hook for automated checks
window.__editor = { state, select, addPoint, deleteSelected, stepHistory, memberText, alignCheckpoint, loadCourse, focusSelected };

boot().catch(err => {
  $('status').textContent = `Failed to load course data: ${err.message}. Serve this folder over http (not file://).`;
  $('status').style.color = '#fecdd3';
});
