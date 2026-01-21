#!/bin/sh

# To be removed
# Workaround a bug where the initial /etc/dnf/dnf.conf file contains
# just the "tsflags=nodocs" line
printf '[main]\ngpgcheck=True\ninstallonly_limit=3\nclean_requirements_on_remove=True\nbest=False\nskip_if_unavailable=True\ntsflags=nodocs' > /etc/dnf/dnf.conf

dnf install -y --nogpgcheck \
  mingw64-dlfcn \
  mingw64-exiv2 \
  mingw64-fcgi \
  ccache \
  mingw64-gcc-c++ \
  mingw64-gdal \
  mingw64-gdb \
  mingw64-GeographicLib \
  mingw64-geos \
  mingw64-gsl \
  mingw64-libgomp \
  mingw64-libzip \
  mingw64-postgresql \
  mingw64-proj \
  mingw64-python3 \
  mingw64-python3-affine \
  mingw64-python3-chardet \
  mingw64-python3-dateutil \
  mingw64-python3-flask \
  mingw64-python3-gdal \
  mingw64-python3-GeographicLib \
  mingw64-python3-homography \
  mingw64-python3-idna \
  mingw64-python3-lxml \
  mingw64-python3-markupsafe \
  mingw64-python3-numpy \
  mingw64-python3-opencv \
  mingw64-python3-OWSLib \
  mingw64-python3-pillow \
  mingw64-python3-psycopg2 \
  mingw64-python3-PyQt-builder \
  mingw64-python3-pytz \
  mingw64-python3-pyyaml \
  mingw64-python3-qscintilla-qt5 \
  mingw64-python3-qt5 \
  mingw64-python3-requests \
  mingw64-python3-shapely \
  mingw64-python3-urllib3 \
  mingw64-qca-qt5 \
  mingw64-qscintilla-qt5 \
  mingw64-qt5-qmake \
  mingw64-qt5-qtactiveqt \
  mingw64-qt5-qtbase \
  mingw64-qt5-qtimageformats \
  mingw64-qt5-qtlocation \
  mingw64-qt5-qtmultimedia \
  mingw64-qt5-qtscript \
  mingw64-qt5-qtserialport \
  mingw64-qt5-qtsvg \
  mingw64-qt5-qttools \
  mingw64-qt5-qttools-tools \
  mingw64-qt5-qttranslations \
  mingw64-qt5-qtwebkit \
  mingw64-qt5-qtxmlpatterns \
  mingw64-qtkeychain-qt5 \
  mingw64-quazip-qt5 \
  mingw64-qwt-qt5 \
  mingw64-sip \
  mingw64-spatialindex \
  mingw64-sqlite \
  mingw64-svg2svgt \
  mingw64-zstd \
  bison \
  cmake \
  findutils \
  flex \
  gcc-c++ \
  gdal-devel \
  git \
  make \
  proj-devel \
  python-devel \
  python3-networkx \
  python-qt5 \
  python3-qscintilla-qt5 \
  qt5-linguist \
  qt5-qtbase-devel \
  sqlite-devel \
  wget \
  xorg-x11-server-Xvfb \
  zip

# networkx is not available as a mingw64-python3-* Fedora package.
# Install the host package and copy it into the MinGW sysroot so it gets
# bundled by ms-windows/mingw/build.sh.
pyver=$(mingw64-python3 -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')")

# Fedora installs python3-networkx under /usr/lib/... but the default python3
# inside containers may be /usr/local/... (e.g. if layered by other images).
# Find the real install location via rpm.
host_purelib=$(rpm -ql python3-networkx | awk '/\/networkx\/__init__\.py$/ { sub(/\/networkx\/__init__\.py$/, ""); print; exit }')
if [ -z "$host_purelib" ]; then
  host_purelib=$(python3 -c "import os, networkx; print(os.path.dirname(os.path.dirname(networkx.__file__)))")
fi

dest="/usr/x86_64-w64-mingw32/sys-root/mingw/lib/python${pyver}/site-packages"
mkdir -p "$dest"
cp -a "$host_purelib/networkx" "$dest/"
for d in "$host_purelib"/networkx-*.dist-info; do
  [ -e "$d" ] && cp -a "$d" "$dest/"
done
