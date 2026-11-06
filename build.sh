#!/bin/sh
# Cross-build Jedi Academy SP (OpenJK at the commit below in upstream/, fetched
# and patched with patches/ on the first run) for
# goodluckOS in the jka-builder Docker image (docker/Dockerfile.builder), into
# build/. package.sh then assembles out/ports/jka/.
# Optimisation (defaults: LTO=1 PGO=use, the training profile committed in pgo/):
#   LTO=0           no link-time optimisation
#   PGO=generate    instrumented build: play it, quit from the menu, the profile
#                   lands in /dev/shm/jkapgo on the console (tools/pgo.sh)
#   PGO=off         ignore the profile
set -eu
cd "$(dirname "$0")"
OPENJK=260c59c2907187af555a676fe0cc798893bf7757
if [ ! -d upstream ]; then
	git init -q upstream
	git -C upstream fetch -q --depth 1 https://github.com/JACoders/OpenJK "$OPENJK"
	git -C upstream checkout -q FETCH_HEAD
	git -C upstream apply "$PWD"/patches/*.patch
fi
LTO=${LTO:-1}
PGO=${PGO:-use}
[ "$PGO" = use ] && ! ls pgo/*.gcda >/dev/null 2>&1 && { echo "build.sh: no profile in pgo/, building without (PGO=off)"; PGO=off; }
docker image inspect jka-builder:bookworm >/dev/null 2>&1 ||
	docker buildx build -q -f docker/Dockerfile.builder -t jka-builder:bookworm --load docker
docker run --rm -v "$PWD":/w -w /w -e LTO="$LTO" -e PGO="$PGO" jka-builder:bookworm sh -c '
set -e
flags=""
[ "$LTO" = 1 ] && flags="$flags -flto=auto -fuse-linker-plugin -ffat-lto-objects"
case "$PGO" in
generate) flags="$flags -fprofile-generate=/dev/shm/jkapgo -fprofile-update=atomic"; link="-latomic" ;;
use) flags="$flags -fprofile-use=/w/pgo -fprofile-partial-training -Wno-missing-profile -Wno-coverage-mismatch"; link="" ;;
*) link="" ;;
esac
echo "optimisation flags:$flags"
cmake -S upstream -B build -DCMAKE_TOOLCHAIN_FILE=/w/toolchain-armhf.cmake -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_FLAGS="$flags" -DCMAKE_CXX_FLAGS="$flags" \
	-DCMAKE_EXE_LINKER_FLAGS="$flags $link -Wl,--export-dynamic-symbol=ioctl" -DCMAKE_SHARED_LINKER_FLAGS="$flags $link" \
	-DCMAKE_AR=/usr/bin/arm-linux-gnueabihf-gcc-ar -DCMAKE_RANLIB=/usr/bin/arm-linux-gnueabihf-gcc-ranlib \
	-DGlosGLES1=ON -DBuildPortableVersion=ON \
	-DBuildMPEngine=OFF -DBuildMPRdVanilla=OFF -DBuildMPDed=OFF -DBuildMPGame=OFF -DBuildMPCGame=OFF -DBuildMPUI=OFF -DBuildMPRend2=OFF \
	-DBuildSPEngine=ON -DBuildSPGame=ON -DBuildSPRdVanilla=ON \
	-DBuildJK2SPEngine=OFF -DBuildJK2SPGame=OFF -DBuildJK2SPRdVanilla=OFF >/dev/null
cmake --build build --clean-first -j$(nproc) 2>&1 | grep -E "error|Built target" | sort -u
'
