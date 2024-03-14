#!/usr/bin/bash
die () {
	printf "$@" >&2
	cleanup
	exit 1
}
cleanup(){
	rm -rf upstream
}

pkgname=mingw-w64-clang

old_pkgver="$(sed -ne 's/pkgver=\([.0-9]*\).*/\1/p' -e 's/_version=\([.0-9]*\).*/\1/p' < PKGBUILD)"
old_pkgrel="$(sed -ne 's/pkgrel=\([0-9]*\).*/\1/p' < PKGBUILD)"

test -n "$old_pkgver" ||
	die "$0: could not determine current pkgver\n"

test -n "$old_pkgrel" ||
	die "$0: could not determine current pkgrel\n"

git clone --sparse --depth 1 --filter=blob:none https://github.com/msys2/MINGW-packages upstream
git -C upstream sparse-checkout add $pkgname

new_pkgver="$(sed -ne 's/pkgver=\([.0-9]*\).*/\1/p' -e 's/_version=\([.0-9]*\).*/\1/p' < upstream/$pkgname/PKGBUILD)"
new_pkgrel="$(sed -ne 's/pkgrel=\([0-9]*\).*/\1/p' < upstream/$pkgname/PKGBUILD)"
rc="$(sed -ne 's/_rc="\(*\)".*/\1/p' < upstream/$pkgname/PKGBUILD)"

test -n "$new_pkgver" ||
	die "$0: could not determine new pkgver\n"
	
test -n "$new_pkgrel" ||
	die "$0: could not determine new pkgrel\n"
	
test -z "$rc" ||
    die "$0: MSYS2 is currently on an RC version. This script is not able to handle RC versions."

test "$new_pkgver" = "$old_pkgver" &&
    new_pkgrel="$old_pkgrel"
    
new_pkgrel=$(("$new_pkgrel"+1))

rm -f *.patch &&
mv upstream/$pkgname/*.patch ./ &&
rm -f PKGBUILD &&
mv upstream/$pkgname/PKGBUILD ./ &&
rm -f README-patches.md &&
mv upstream/$pkgname/README-patches.md ./ || die "$0: failed to replace existing files with upstream files"

sed -e "s/pkgrel=[.0-9]\+\(.*\)/pkgrel=$new_pkgrel\1/" \
    -e 's/-DCMAKE_BUILD_TYPE=Release/-DCMAKE_BUILD_TYPE=MinSizeRel/' \
    -e 's/-DLLVM_TARGETS_TO_BUILD=[^)]*/-DLLVM_TARGETS_TO_BUILD=Native/' \
    -e 's/-DLLVM_ENABLE_SPHINX=ON/-DLLVM_ENABLE_SPHINX=OFF/'\
    -e '/^check()/,/^}/d' \
	-i PKGBUILD

cleanup
