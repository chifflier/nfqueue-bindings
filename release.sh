#!/bin/sh

GIT_ROOT="git://git.inl.fr/git/nfqueue-bindings"
GIT_TAG="origin"

set -e

VERSION=$(grep "^SET.VERSION" CMakeLists.txt | sed 's/.*"\([^"]\+\)".*/\1/')

cleanup()
{
  :
}


trap cleanup EXIT

TGZ="nfqueue-bindings-$VERSION.tar.gz"

git archive --format=tar --prefix="nfqueue-bindings-$VERSION/" "$GIT_TAG" | gzip -9 - > $TGZ

echo "Release file $TGZ is ok"
echo -n "$TGZ: "
SIZE=$(stat -c "%s" $TGZ)
echo "$SIZE bytes"

echo -n "MD5 : "
SUM=$(md5sum $TGZ | cut -f 1 -d' ')
echo "$SUM"

echo -n "SHA1: "
SUM=$(sha1sum $TGZ | cut -f 1 -d' ')
echo "$SUM"

echo ""
echo "Don't forget to run:"
echo "git tag -s nfqueue-bindings-$VERSION"
echo "git push --tags"

