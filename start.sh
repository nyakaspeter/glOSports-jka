#!/bin/sh
# Star Wars Jedi Knight: Jedi Academy (OpenJK, single player) on goodluckOS,
# drawn with GLES 1.1 on ARM's Mali driver (glos-gpu). Game files in base/: the
# PC game's assets0.pk3 to assets3.pk3. Saves and settings stay in
# this folder (portable build). Logs to /dev/shm/jka.log.
cd "$(dirname "$0")"
# Xbox-style positions (A = bottom), as in the GTA ports.
export SDL_GAMECONTROLLERCONFIG="1900c621474133362d4d422047616d00,GA36-MB Gamepad,a:b0,b:b1,x:b3,y:b2,back:b8,start:b9,guide:b8,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,leftstick:b11,rightstick:b12,dpup:b13,dpdown:b14,dpleft:b15,dpright:b16,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux"
export JKA_STICK_SCALE=1.5     # GA36-MB sticks reach only ~2/3 of the declared range
export JKA_STICK_DEADZONE=0.12 # radial; the sticks rest up to 9% off centre after scaling
export JKA_LOOK_SPEED=200      # degrees/second at full right-stick deflection
export JKA_LOOK_CURVE=2        # right-stick response exponent
# The pad layout (base/glos-pad.cfg) runs right after the game's default.cfg,
# at startup and on a settings reset; the saved config keeps any changes.
# The game draws to /dev/fb0 through EGL; SDL is for the controller and audio only.
exec ./glos/glos-gpu run mali ./openjk_sp.arm \
	+set fs_basepath "$PWD" +set fs_homepath "$PWD" \
	+set r_texturebits 16 +set r_ignoreGLErrors 1 +set r_flares 0 +set cg_drawFPS 1 \
	"$@" >/dev/shm/jka.log 2>&1
