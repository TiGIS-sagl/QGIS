FROM fedora:38

# Fedora-based MinGW cross-build environment for QGIS.
#
# Build:
#   docker build -t qgis-deps-mingw:fedora -f ms-windows/mingw/Dockerfile.fedora .
#
# Run (from QGIS repo root):
#   docker run --rm -w /QGIS -v "$(pwd):/QGIS" qgis-deps-mingw:fedora /QGIS/ms-windows/mingw/build.sh x86_64

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# The dependency list lives in the repo and is Fedora/dnf specific.
COPY ms-windows/mingw/mingwdeps.sh /tmp/mingwdeps.sh

# Install dependencies. Add a few wrappers/tools which are used by build.sh
# but may not be pulled in as transitive deps on all Fedora releases.
RUN sh /tmp/mingwdeps.sh;

# QGIS build generates qgsversion.h by running git commands in /QGIS.
# When /QGIS is a bind-mounted working tree with a different uid/gid than the
# container user (often root), git may refuse to operate unless the directory
# is marked as safe.
RUN git config --system --add safe.directory /QGIS

WORKDIR /QGIS
