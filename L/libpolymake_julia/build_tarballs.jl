# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms


name = "libpolymake_julia"
version = v"0.5.0"

julia_versions = [v"1.6.0", v"1.7.0", v"1.8.0"]

# Collection of sources required to build libpolymake_julia
sources = [
    ArchiveSource("https://github.com/oscar-system/libpolymake-julia/archive/v$(version).tar.gz",
                  "5af8ccce9928b05c2c30f6adcddc7f07bdbef79d69d7d28aa6671846e742d2fb"),
]

# Bash recipe for building across all platforms
script = raw"""
# remove $libdir from LD_LIBRARY_PATH as this causes issues with perl
if [[ -n "$LD_LIBRARY_PATH" ]]; then
LD_LIBRARY_PATH=$(echo -n $LD_LIBRARY_PATH | sed -e "s|[:^]$libdir\w*|:|g")
fi

cmake libpolymake-j*/ -B build \
   -DJulia_PREFIX="$prefix" \
   -DCMAKE_INSTALL_PREFIX="$prefix" \
   -DCMAKE_FIND_ROOT_PATH="$prefix" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_BUILD_TYPE=Release

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license libpolymake-j*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
]
platforms = expand_cxxstring_abis(platforms)

# expand julia platforms
julia_platforms = []
foreach(platforms) do platform
    foreach(julia_versions) do jv
        p = deepcopy(platform)
        BinaryPlatforms.add_tag!(p.tags, "julia_version", string(jv))
        push!(julia_platforms, p)
    end
end


# The products that we will ensure are always built
products = [
    ExecutableProduct("polymake_run_script", :polymake_run_script),
    LibraryProduct("libpolymake_julia", :libpolymake_julia),
    FileProduct("share/libpolymake_julia/type_translator.jl",:type_translator),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    BuildDependency("GMP_jll"),
    BuildDependency("MPFR_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("FLINT_jll", compat = "~200.800"),
    Dependency("libcxxwrap_julia_jll"),
    Dependency("polymake_jll"; compat = "~400.500.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, julia_platforms, products, dependencies;
    preferred_gcc_version=v"8",
    julia_compat = "1.6")
