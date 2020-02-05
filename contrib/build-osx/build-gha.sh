#!/bin/bash
set -ev

WRKDIR=$PWD

BUILD_REPO_URL=https://github.com/komodoplatform/electrum-komodo

#git clone --branch dev $BUILD_REPO_URL electrum-komodo

cp libusb-1.0.dylib $WRKDIR/contrib

cd $WRKDIR

export PY36BINDIR=/Library/Frameworks/Python.framework/Versions/3.6/bin/
export PATH=$PATH:$PY36BINDIR
source ./contrib/zcash/travis/electrum_zcash_version_env.sh;
echo build version is $ELECTRUM_ZCASH_VERSION

sudo pip3 install --upgrade pip
sudo pip3 install -r contrib/deterministic-build/requirements.txt
sudo pip3 install \
    pycryptodomex==3.6.0 \
    btchip-python==0.1.28 \
    keepkey==4.0.2 \
    trezor==0.9.1

pyrcc5 icons.qrc -o gui/qt/icons_rc.py

export PATH="/usr/local/opt/gettext/bin:$PATH"
./contrib/make_locale
find . -name '*.po' -delete
find . -name '*.pot' -delete

cd $WRKDIR/contrib/build-osx

cp pyi_runtimehook.py ../

pyinstaller \
    -y \
    --name electrum-zcash-$ELECTRUM_ZCASH_VERSION.bin \
    osx.spec

sudo hdiutil create -fs HFS+ -volname "Electrum-Komodo" \
    -srcfolder dist/Electrum-Komodo.app \
    dist/electrum-komodo-$ELECTRUM_ZCASH_VERSION-macosx.dmg
