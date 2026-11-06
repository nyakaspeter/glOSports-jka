#!/bin/sh
# Assemble out/ports/jka/ from the build (build/) and glos/, the driver set from
# goodluckOS-mali-driver: copy out/ports/jka/ over /home/player/ports/jka/ (game files
# in base/ stay there) and out/.local/share/applications/jka.puppy next to the
# other launcher entries.
set -eu
cd "$(dirname "$0")"
GLOS=../goodluckOS-mali-driver/glos
[ -d "$GLOS" ] || { echo "package.sh: $GLOS missing (goodluckOS-mali-driver/assemble-glos.sh)" >&2; exit 1; }
out=out/ports/jka
rm -rf out/ports out/.local
mkdir -p $out/OpenJK $out/base $out/lib $out/glos/lib out/.local/share/applications
docker run --rm -v "$PWD":/w -w /w jka-builder:bookworm sh -c "
	cp build/openjk_sp.arm build/code/rd-vanilla/rdsp-vanilla_arm.so $out/ &&
	cp build/code/game/jagamearm.so $out/OpenJK/ &&
	cp -L /usr/lib/arm-linux-gnueabihf/libjpeg.so.62 $out/lib/ &&
	! arm-linux-gnueabihf-nm -DC --undefined-only build/code/rd-vanilla/rdsp-vanilla_arm.so | grep glos_ &&
	arm-linux-gnueabihf-strip $out/openjk_sp.arm $out/rdsp-vanilla_arm.so $out/OpenJK/jagamearm.so &&
	patchelf --force-rpath --set-rpath '\$ORIGIN/lib' $out/rdsp-vanilla_arm.so"
cp start.sh $out/ && { [ ! -f icon.png ] || cp icon.png $out/; } && cp glos-pad.cfg $out/base/ && cp jka.puppy out/.local/share/applications/
echo "Copy the PC game's base/assets0.pk3, assets1.pk3, assets2.pk3 and assets3.pk3 here." > $out/base/place-game-files-here.txt
cp "$GLOS"/glos-gpu "$GLOS"/glos-gpu-switch "$GLOS"/mali.ko "$GLOS"/glos_fbfix.ko $out/glos/ && cp "$GLOS"/lib/* $out/glos/lib/
mkdir -p $out/licenses && cp LICENSE $out/licenses/LICENSE && cp licenses/* $out/licenses/
ls -la $out $out/glos
