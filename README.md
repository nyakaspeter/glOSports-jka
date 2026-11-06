# glOSports-jka — Star Wars Jedi Knight: Jedi Academy, native, on the GA36-MB

Jedi Academy's single player through [OpenJK](https://github.com/JACoders/OpenJK)
(GPL-2.0, the game's released source), cross-built for goodluckOS on the
GA36-MB (Allwinner A33, Mali-400 MP2, 640×480). It carries over
`glOSports-jk2`'s patch unchanged in substance: the vanilla renderer's desktop
OpenGL 1.x on **GLES 1.1 on ARM's closed Mali driver** through a small
translation layer (no gl4es), EGL on `/dev/fb0`, the twin-stick pad, NEON
skinning, LTO + PGO. Academy's renderer needed no GL call the layer didn't
already have. The game folder carries its own `glos/` (see `goodluckOS-mali-driver`);
the console stays stock goodluckOS.

## Game files

From the PC game (retail CDs, or a Steam/GOG install), into
`/home/player/ports/jka/base/`:

| File | Where it comes from | Needed |
|---|---|---|
| `assets0.pk3` | CD 1, `GameData/GameData/base/` | yes |
| `assets1.pk3` | CD 2, `GameData/GameData/base/` | yes |
| `assets2.pk3` | CD 2, same folder | yes |
| `assets3.pk3` | CD 2, same folder (the 1.01 patch's `assets3.pk3` is byte-identical: CDs with `SPExtVersion=1.01` in `version.inf` need no patch) | yes |

Nothing else: no `.exe`/`.dll` (OpenJK replaces them). An older CD set would
take `assets3.pk3` from the 1.01 patch (`jkacademy1_01.exe`), which
`glOSports-jk2/tools/jkiiup-extract.py` unpacks without running it (same
installer format as Jedi Outcast's).

## The game folder on the console (`/home/player/ports/jka/`)

| Path | What |
|---|---|
| `start.sh` | sets the pad layout and stick shaping, starts the game through `glos/glos-gpu run mali`; log in `/dev/shm/jka.log` |
| `openjk_sp.arm`, `rdsp-vanilla_arm.so`, `OpenJK/jagamearm.so` | engine, renderer, game code |
| `lib/libjpeg.so.62` | the one library goodluckOS lacks (`$ORIGIN/lib` rpath on the renderer) |
| `glos/` | ARM's driver set from `goodluckOS-mali-driver` |
| `icon.png` | launcher image (192×128) |
| `base/*.pk3` | game files (above) |
| `base/glos-pad.cfg` | pad bindings, run right after the game's `default.cfg` (at every start and on a settings reset) |
| `base/openjk_sp.cfg`, `base/saves/` | the player's settings and saves (portable build: nothing outside the folder) |

Launcher entry: `/home/player/.local/share/applications/jka.puppy`.

## Controls

Positions as on an Xbox pad (A = bottom), like the GTA ports:

| Pad | In game | In menus |
|---|---|---|
| left stick | move (analog) | cursor |
| right stick | aim | cursor |
| R2 / L2 | fire, swing / alternate fire, saber throw | click / back |
| R1 / L1 | use force power / next force power | |
| A (bottom) / B (right) | jump / crouch | click / back |
| X (left) / Y (top) | use / next weapon | |
| d-pad ↑ ↓ ← → | saber style / use item / previous weapon / next item | cursor keys |
| L3 / R3 | walk / first-third person | |
| Select / Start | datapad / menu | — / back |

Rebinding in the Controls menu sticks (saved in `openjk_sp.cfg`); a settings
reset brings the pad layout back. Stick shaping in `start.sh`:
`JKA_STICK_SCALE=1.5` (the sticks reach ~2/3 of their range),
`JKA_STICK_DEADZONE=0.12` (radial; they rest up to 9% off centre after scaling),
`JKA_LOOK_SPEED=200` (degrees/second at full right stick), `JKA_LOOK_CURVE=2`.
`start.sh` also sets `cg_drawFPS 1` (FPS in the top right).

## Repo layout

| Path | What |
|---|---|
| `build.sh` | fetches OpenJK (pinned commit) into `upstream/` and applies `patches/` on the first run, cross-builds in Docker into `build/` (LTO + PGO by default) |
| `package.sh` | assembles `out/ports/jka/` and `out/.local/share/applications/jka.puppy` with `glos/` from `../goodluckOS-mali-driver/glos` |
| `patches/0001-glos-gles1-fbdev-gamepad.patch` | every change to OpenJK (`glOSports-jk2`'s, plus the stick variables' `JKA_` prefix outside Jedi Outcast mode) |
| `docker/Dockerfile.builder` | the build image |
| `pgo/` | the training profile (gcda files) |
| `tools/pgo.sh` | install the instrumented build, collect its profile |
| `start.sh`, `glos-pad.cfg`, `jka.puppy`, `icon.png` | the folder's own files |

## Build, package, deploy

```
./build.sh && ./package.sh
```

Then copy `out/ports/jka/` over `/home/player/ports/jka/` (game files and saves
in `base/` stay) and `out/.local/share/applications/jka.puppy` next to the other
launcher entries. PGO as in `glOSports-jk2`: `PGO=generate ./build.sh &&
./package.sh && tools/pgo.sh install`, play, quit from the menu,
`tools/pgo.sh collect`, `./build.sh`.

### Tear-free flips

ARM's fbdev EGL returns from `eglSwapBuffers` at once and flips
(`FBIOPAN_DISPLAY`, which returns at the vblank) on a thread of its own, so
with two buffers the GPU could draw the next frame into the one still on
screen: tearing, and a flicker between two frames. `GLOS_Swap` now waits
before each flush until the previous frame's flip has landed; the binary
exports `ioctl` (`-Wl,--export-dynamic-symbol=ioctl`, default visibility) so
libMali's flips are counted there. `JKA_FLIP_WAIT=0` turns it off,
`JKA_LOG_FPS=1` logs fps and the wait. Measured in Jedi Outcast (same code), `kejim_post`, standing
still: 47.1 fps (min 41.1) with the wait, 49.7 (min 33.6) without, which
tears. Carried over from glOSports-maxpayne.

## Measurements

Not benched. First start: ~380 MB of memory still free at the main menu.
Plays well by eye.

## Traps

As in `glOSports-jk2` (the mali.ko unload fix, `SDL_QUIT` for the launcher's
stop, pad bindings after `default.cfg`). Extracting the CDs' `GameData/` on a
case-insensitive Mac next to a `gamedata/` folder merges the two: extract
somewhere else first.

## Licence

OpenJK is GPL-2.0, and so are this port's patches to it and the rest of the
repo (`LICENSE`, the GPL-2.0 text from OpenJK). The bundled libjpeg-turbo and
ARM's Mali driver are listed with their licences in `licenses/`, which
`package.sh` copies into the game folder. The game itself is not included.
