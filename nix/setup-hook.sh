#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

log2compdbEchoExec() {
	echoCmd "log2compdb" "$@"
	"$@"
}

# Sensible defaults.
log2compdbDefaultCompilers=(cc c++ gcc g++ clang clang++)

# If log2compdbCompilers is unspecified, then use the defaults.
if ! [[ -v "log2compdbCompilers" ]]; then
	log2compdbCompilers=("${log2compdbDefaultCompilers[@]}")
fi

# Use log2compdbExtraCompilers to specify more compilers including the defaults.
if [[ -v "log2compdbExtraCompilers" ]]; then
	log2compdbCompilers+=("${log2compdbExtraCompilers[@]}")
fi

# Set in log2compdbPreBuild(), and used in log2compdbMake().
log2compdbOrigMake=

log2compdbMake() {
	#log2compdbEchoExec "$log2compdbOrigMake" "$@" V=1 VERBOSE=1 2>&1 | tee /dev/stderr > log2compdb_build.log
	echo "log2compdb:" "$log2compdbOrigMake" '"$@" V=1 VERBOSE=1 2>&1 | tee /dev/stderr >> log2compdb_build.log'
	ls -l --color=always --group-directories-first
	"$log2compdbOrigMake" "$@" V=1 VERBOSE=1 2>&1 | tee /dev/stderr > log2compdb_build.log
}

# TODO: add a preConfigure hook to check for things like CMake and Meson.

log2compdbPreBuild() {
	echo "log2compdbPreBuild"

	# Same Makefile detection code as used in NixOS/nixpkgs/pkgs/stdenv/generic/setup.sh.
	if [[ -z "${makeFlags-}" && -z "${makefile:-}" && ! ( -e Makefile || -e makefile || -e GNUmakefile ) ]]; then
		echo "log2compdbPreBuild: no Makefile"
		# TODO: check for other things
	else
		log2compdbOrigMake="$(command -v make)"

		# Override the normal make command.
		function make() {
			# shellcheck disable=2317
			log2compdbMake "$@"
		}
	fi
}

log2compdbPostBuild() {
	echo "log2compdbPostInstall"

	local compilerArgs=()
	for compiler in "${log2compdbCompilers[@]}"; do
		compilerArgs+=("-c" "$compiler")
	done

	if [[ -e ./log2compdb_build.log ]]; then
		log2compdbEchoExec log2compdb "${compilerArgs[@]}" -i log2compdb_build.log -o log2compdb_compile_commands.json
	fi
}

log2compdbPreInstall() {
	echo "log2compdbPostInstall"
	unset -f make
}

log2compdbPostInstall() {
	echo "log2compdbPostInstall"

	# $out exists, shellcheck, because Nix says so.
	# shellcheck disable=2154
	mkdir -vp "$out/share/log2compdb"
	cp -v ./log2compdb_build.log "$out/share/log2compdb/build.log"
	cp -v ./log2compdb_compile_commands.json "$out/share/log2compdb/compile_commands.json"
}

if [[ -z "${dontLog2compdbPreBuild-}" ]] && [[ -z "${configurePhase-}" ]]; then
	preBuildHooks+=('log2compdbPreBuild')
	postBuildHooks+=('log2compdbPostBuild')
	preInstallHooks+=('log2compdbPreInstall')
	postInstallHooks+=('log2compdbPostInstall')
fi
