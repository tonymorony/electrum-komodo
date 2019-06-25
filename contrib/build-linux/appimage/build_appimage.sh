#!/bin/bash

set -e

PROJECT_ROOT="$(dirname "$(readlink -e "$0")")/../../.."
CONTRIB="$PROJECT_ROOT/contrib"
CONTRIB_APPIMAGE="$CONTRIB/build-linux/appimage"
DISTDIR="$PROJECT_ROOT/dist"
BUILDDIR="$CONTRIB_APPIMAGE/build/appimage"
APPDIR="$BUILDDIR/electrum-komodo.AppDir"
CACHEDIR="$CONTRIB_APPIMAGE/.cache/appimage"

# pinned versions
PYTHON_VERSION=3.6.8
PKG2APPIMAGE_COMMIT="eb8f3acdd9f11ab19b78f5cb15daa772367daf15"
LIBSECP_VERSION="b408c6a8b287003d1ade5709e6f7bc3c7f1d5be7"
SQUASHFSKIT_COMMIT="ae0d656efa2d0df2fcac795b6823b44462f19386"


VERSION=`git describe --tags --dirty --always`
APPIMAGE="$DISTDIR/electrum-komodo-$VERSION-x86_64.AppImage"

rm -rf "$BUILDDIR"
mkdir -p "$APPDIR" "$CACHEDIR" "$DISTDIR"


. "$CONTRIB"/build_tools_util.sh

info "creating the AppImage."
(
    cd "$BUILDDIR"
    chmod +x "$CACHEDIR/appimagetool"
    "$CACHEDIR/appimagetool" --appimage-extract
    # We build a small wrapper for mksquashfs that removes the -mkfs-fixed-time option
    # that mksquashfs from squashfskit does not support. It is not needed for squashfskit.
    cat > ./squashfs-root/usr/lib/appimagekit/mksquashfs << EOF
#!/bin/sh
args=\$(echo "\$@" | sed -e 's/-mkfs-fixed-time 0//')
"$MKSQUASHFS" \$args
EOF
    env VERSION="$VERSION" ARCH=x86_64 SOURCE_DATE_EPOCH=1530212462 ./squashfs-root/AppRun --no-appstream --verbose "$APPDIR" "$APPIMAGE"
)

info "done."
ls -la "$DISTDIR"
sha256sum "$DISTDIR"/*
