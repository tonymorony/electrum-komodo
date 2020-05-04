#!/bin/bash

NAME_ROOT=electrum-komodo
PYTHON_VERSION=3.5.4

# These settings probably don't need any change
export WINEPREFIX=/opt/wine64
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=22

PYHOME=c:/python$PYTHON_VERSION
PYTHON="wine $PYHOME/python.exe -OO -B"


# Let's begin!
cd `dirname $0`
set -e

mkdir -p tmp
cd tmp
if [ ! -z "$2" ]
    then
        URL=https://github.com/$2.git
    else
        URL=https://github.com/komodoplatform/electrum-komodo.git
    fi

if [ -d electrum-komodo ]; then
    cd electrum-komodo
    git pull
    if [ ! -z "$1" ]
        then
            git checkout $1
        else
            git checkout master
        fi
    cd ..
    else
    echo $URL
    if [ $1 ]
        then
            git clone $URL electrum-komodo
	    cd electrum-komodo
	    git checkout --force $1
	    cd ..
        else
            git clone $URL electrum-komodo
	    cd electrum-komodo
	    git checkout master
	    cd ..
        fi
    fi

for repo in electrum-locale electrum-icons; do
    if [ -d $repo ]; then
	cd $repo
	git pull
	git checkout master
	cd ..
    else
	URL=https://github.com/komodoplatform/$repo.git
	git clone -b master $URL $repo
    fi
done

pushd electrum-locale
for i in ./locale/*; do
    dir=$i/LC_MESSAGES
    mkdir -p $dir
    msgfmt --output-file=$dir/electrum.mo $i/electrum.po || true
done
popd

pushd electrum-komodo
if [ ! -z "$1" ]; then
    git checkout $1
fi

VERSION=`git describe --tags`
echo "Last commit: $VERSION"
find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

rm -rf $WINEPREFIX/drive_c/electrum
cp -r electrum-komodo $WINEPREFIX/drive_c/electrum
cp -r electrum-komodo/icons $WINEPREFIX/drive_c/electrum/icons
cp electrum-komodo/LICENCE .
cp -r electrum-locale/locale $WINEPREFIX/drive_c/electrum/lib/
cp electrum-icons/icons_rc.py $WINEPREFIX/drive_c/electrum/gui/qt/

# Install frozen dependencies
$PYTHON -m pip install -r ../../deterministic-build/requirements.txt
$PYTHON -m pip install pypiwin32

$PYTHON -m pip install -r ../../deterministic-build/requirements-hw.txt

pushd $WINEPREFIX/drive_c/electrum
$PYTHON setup.py install
popd

cd ..

rm -rf dist/

# build standalone and portable versions
wine "C:/python$PYTHON_VERSION/scripts/pyinstaller.exe" --noconfirm --ascii --name $NAME_ROOT-$VERSION -w deterministic.spec

# set timestamps in dist, in order to make the installer reproducible
pushd dist
find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

# build NSIS installer
# $VERSION could be passed to the electrum.nsi script, but this would require some rewriting in the script iself.
wine "$WINEPREFIX/drive_c/Program Files (x86)/NSIS/makensis.exe" /DPRODUCT_VERSION=$VERSION electrum.nsi

cd dist
mv electrum-komodo-setup.exe $NAME_ROOT-$VERSION-setup.exe
cd ..

echo "Done."
md5sum dist/electrum*exe
