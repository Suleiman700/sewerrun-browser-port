# Sewer Run — browser port

The original **Sewer Run** (Kinelco, Macromedia Director MX 2004 / Shockwave 3D + Havok + Flash UI)
running unmodified in a modern browser.

This is a *real* port, not a remake: the original `game.dcr` — its Lingo game code, 3D models,
textures, sounds and Flash menus — is loaded as-is by **[dirplayer-rs]**, a Shockwave emulator
written in Rust/WebAssembly, with Flash content rendered by dirplayer's **Ruffle** fork.
A few emulator bugs that broke this game were fixed locally; the patch is in `patches/`.

## Play locally

```sh
cd web
python3 -m http.server 8790 --bind 127.0.0.1
```

Open <http://127.0.0.1:8790> in Chrome. Start-up takes ~4 s.

| Key | Action |
| --- | --- |
| Arrow keys | Steer / lean |
| Z (+ arrow) | Grab |
| X (+ arrow) | Trick |
| Space | Use pick-up (mortar, roller, blaster) |
| R | Reset on track |
| O | Options / pause |

Any static web server works — `web/` is self-contained. Serve it over HTTP(S); opening
`index.html` from disk will not work.

## Repository layout

```
web/                  playable port (deploy this folder)
  index.html          page: loading overlay + <embed src="game.dcr">
  dirplayer-polyfill.js  dirplayer-rs player (patched build, WASM inlined)
  ruffle/             dirplayer's Ruffle fork (Flash renderer)
  game.dcr            original game, unmodified
  landing/            landing page
  editor/             three.js course viewer/editor (three.js r170 vendored in editor/vendor)
patches/
  dirplayer-rs.patch  local fixes on top of dirplayer-rs (see below)
decompiled/
  scripts/            game Lingo decompiled with ProjectorRays (.ls source, .lasm bytecode)
  data/               course data / scene nodes extracted from the W3D models
tools/                Python extractors for W3D / course data
tools/playwright/     browser test & profiling scripts used during the port
```

## Emulator fixes (`patches/dirplayer-rs.patch`)

Base: [dirplayer-rs] PR #244 head, commit `b9b94666`.

| Area | Problem in this game | Fix |
| --- | --- | --- |
| Havok `interpolatingMoveTo` | Air bomb (mortar) spawned ~90,000 units behind the rider, so it seemed not to fire; its smoke trail grew every frame (lag). Cause: a Z-up "stacking" heuristic applied to Sewer Run's Y-up world. | Only use the heuristic in Z-up scenes; otherwise move the body to the target. |
| Sound `play([#member:…, #loopCount:n])` | `#loopCount` was dropped, so music stopped after one 27.6 s pass. | Read `#loopCount` from the property list (0 = forever, absent = once). |
| W3D arithmetic decoder | ~8 s of the load decoding meshes (linear histogram scans). | Fenwick-tree histogram, O(log n). Verified byte-identical decoded meshes on all 15 of the game's W3D models (`realdata_test.rs`); ~5× faster. |
| Flash start-up | Fixed 3 s wait for an ActionScript probe this SWF never answers. | Opt-in `DirPlayer.configureFlash({ asInitWaitMs })`; the page sets 0. |
| Flash frame capture | Readback paced only by the Director tempo. | Also capped at the SWF's own frame rate. |

Load time went from ~13 s to ~4 s.

### Rebuilding the player

```sh
git clone https://github.com/igorlira/dirplayer-rs && cd dirplayer-rs
git fetch origin pull/244/head:pr244 && git checkout b9b94666
git apply /path/to/patches/dirplayer-rs.patch
git submodule update --init ruffle
npm ci
npm run build-vm                 # needs rustup + wasm32-unknown-unknown + wasm-pack
(cd ruffle/web && npm ci && npm run build) && npm run copy-ruffle   # needs wasm-bindgen-cli 0.2.108 + wasm-opt
npm run build-polyfill
cp dist-polyfill/dirplayer-polyfill.js /path/to/web/
cp -R dist-polyfill/ruffle /path/to/web/
```

## Known issues

- Camera distance pulses slightly at constant speed; not yet determined whether this is
  emulator behaviour or the original camera code (`updateCamera` in `GameBehaviour.ls`).
- The Flash HUD is read back from the GPU ~25×/s (~5 ms each); fine on a modern machine,
  may cost frames on slow ones.
- Desktop-only projector commands (window resize/drag/quit) do nothing in the browser.

## Licences and rights

- **Sewer Run** game content (`web/game.dcr`, `decompiled/`): © its rights holders (Kinelco).
  Included by the repository owner, who holds the rights/licence to it. Not covered by the
  licences below.
- **dirplayer-rs** player (`web/dirplayer-polyfill.js`, `patches/`): GPL-3.0 —
  source: [dirplayer-rs] + `patches/dirplayer-rs.patch`.
- **Ruffle** (`web/ruffle/`): MIT / Apache-2.0 (licence files included).
- **three.js** (`web/editor/vendor`): MIT.

[dirplayer-rs]: https://github.com/igorlira/dirplayer-rs
