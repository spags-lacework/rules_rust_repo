###############################################################################
# @generated
# DO NOT MODIFY: This file is auto-generated by a crate_universe tool. To
# regenerate this file, run the following:
#
#     bazel run @@//basic/ppp:crates_vendor
###############################################################################
"""
# `crates_repository` API

- [aliases](#aliases)
- [crate_deps](#crate_deps)
- [all_crate_deps](#all_crate_deps)
- [crate_repositories](#crate_repositories)

"""

load("@bazel_skylib//lib:selects.bzl", "selects")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

###############################################################################
# MACROS API
###############################################################################

# An identifier that represent common dependencies (unconditional).
_COMMON_CONDITION = ""

def _flatten_dependency_maps(all_dependency_maps):
    """Flatten a list of dependency maps into one dictionary.

    Dependency maps have the following structure:

    ```python
    DEPENDENCIES_MAP = {
        # The first key in the map is a Bazel package
        # name of the workspace this file is defined in.
        "workspace_member_package": {

            # Not all dependencies are supported for all platforms.
            # the condition key is the condition required to be true
            # on the host platform.
            "condition": {

                # An alias to a crate target.     # The label of the crate target the
                # Aliases are only crate names.   # package name refers to.
                "package_name":                   "@full//:label",
            }
        }
    }
    ```

    Args:
        all_dependency_maps (list): A list of dicts as described above

    Returns:
        dict: A dictionary as described above
    """
    dependencies = {}

    for workspace_deps_map in all_dependency_maps:
        for pkg_name, conditional_deps_map in workspace_deps_map.items():
            if pkg_name not in dependencies:
                non_frozen_map = dict()
                for key, values in conditional_deps_map.items():
                    non_frozen_map.update({key: dict(values.items())})
                dependencies.setdefault(pkg_name, non_frozen_map)
                continue

            for condition, deps_map in conditional_deps_map.items():
                # If the condition has not been recorded, do so and continue
                if condition not in dependencies[pkg_name]:
                    dependencies[pkg_name].setdefault(condition, dict(deps_map.items()))
                    continue

                # Alert on any miss-matched dependencies
                inconsistent_entries = []
                for crate_name, crate_label in deps_map.items():
                    existing = dependencies[pkg_name][condition].get(crate_name)
                    if existing and existing != crate_label:
                        inconsistent_entries.append((crate_name, existing, crate_label))
                    dependencies[pkg_name][condition].update({crate_name: crate_label})

    return dependencies

def crate_deps(deps, package_name = None):
    """Finds the fully qualified label of the requested crates for the package where this macro is called.

    Args:
        deps (list): The desired list of crate targets.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()`.

    Returns:
        list: A list of labels to generated rust targets (str)
    """

    if not deps:
        return []

    if package_name == None:
        package_name = native.package_name()

    # Join both sets of dependencies
    dependencies = _flatten_dependency_maps([
        _NORMAL_DEPENDENCIES,
        _NORMAL_DEV_DEPENDENCIES,
        _PROC_MACRO_DEPENDENCIES,
        _PROC_MACRO_DEV_DEPENDENCIES,
        _BUILD_DEPENDENCIES,
        _BUILD_PROC_MACRO_DEPENDENCIES,
    ]).pop(package_name, {})

    # Combine all conditional packages so we can easily index over a flat list
    # TODO: Perhaps this should actually return select statements and maintain
    # the conditionals of the dependencies
    flat_deps = {}
    for deps_set in dependencies.values():
        for crate_name, crate_label in deps_set.items():
            flat_deps.update({crate_name: crate_label})

    missing_crates = []
    crate_targets = []
    for crate_target in deps:
        if crate_target not in flat_deps:
            missing_crates.append(crate_target)
        else:
            crate_targets.append(flat_deps[crate_target])

    if missing_crates:
        fail("Could not find crates `{}` among dependencies of `{}`. Available dependencies were `{}`".format(
            missing_crates,
            package_name,
            dependencies,
        ))

    return crate_targets

def all_crate_deps(
        normal = False,
        normal_dev = False,
        proc_macro = False,
        proc_macro_dev = False,
        build = False,
        build_proc_macro = False,
        package_name = None):
    """Finds the fully qualified label of all requested direct crate dependencies \
    for the package where this macro is called.

    If no parameters are set, all normal dependencies are returned. Setting any one flag will
    otherwise impact the contents of the returned list.

    Args:
        normal (bool, optional): If True, normal dependencies are included in the
            output list.
        normal_dev (bool, optional): If True, normal dev dependencies will be
            included in the output list..
        proc_macro (bool, optional): If True, proc_macro dependencies are included
            in the output list.
        proc_macro_dev (bool, optional): If True, dev proc_macro dependencies are
            included in the output list.
        build (bool, optional): If True, build dependencies are included
            in the output list.
        build_proc_macro (bool, optional): If True, build proc_macro dependencies are
            included in the output list.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()` when unset.

    Returns:
        list: A list of labels to generated rust targets (str)
    """

    if package_name == None:
        package_name = native.package_name()

    # Determine the relevant maps to use
    all_dependency_maps = []
    if normal:
        all_dependency_maps.append(_NORMAL_DEPENDENCIES)
    if normal_dev:
        all_dependency_maps.append(_NORMAL_DEV_DEPENDENCIES)
    if proc_macro:
        all_dependency_maps.append(_PROC_MACRO_DEPENDENCIES)
    if proc_macro_dev:
        all_dependency_maps.append(_PROC_MACRO_DEV_DEPENDENCIES)
    if build:
        all_dependency_maps.append(_BUILD_DEPENDENCIES)
    if build_proc_macro:
        all_dependency_maps.append(_BUILD_PROC_MACRO_DEPENDENCIES)

    # Default to always using normal dependencies
    if not all_dependency_maps:
        all_dependency_maps.append(_NORMAL_DEPENDENCIES)

    dependencies = _flatten_dependency_maps(all_dependency_maps).pop(package_name, None)

    if not dependencies:
        if dependencies == None:
            fail("Tried to get all_crate_deps for package " + package_name + " but that package had no Cargo.toml file")
        else:
            return []

    crate_deps = list(dependencies.pop(_COMMON_CONDITION, {}).values())
    for condition, deps in dependencies.items():
        crate_deps += selects.with_or({
            tuple(_CONDITIONS[condition]): deps.values(),
            "//conditions:default": [],
        })

    return crate_deps

def aliases(
        normal = False,
        normal_dev = False,
        proc_macro = False,
        proc_macro_dev = False,
        build = False,
        build_proc_macro = False,
        package_name = None):
    """Produces a map of Crate alias names to their original label

    If no dependency kinds are specified, `normal` and `proc_macro` are used by default.
    Setting any one flag will otherwise determine the contents of the returned dict.

    Args:
        normal (bool, optional): If True, normal dependencies are included in the
            output list.
        normal_dev (bool, optional): If True, normal dev dependencies will be
            included in the output list..
        proc_macro (bool, optional): If True, proc_macro dependencies are included
            in the output list.
        proc_macro_dev (bool, optional): If True, dev proc_macro dependencies are
            included in the output list.
        build (bool, optional): If True, build dependencies are included
            in the output list.
        build_proc_macro (bool, optional): If True, build proc_macro dependencies are
            included in the output list.
        package_name (str, optional): The package name of the set of dependencies to look up.
            Defaults to `native.package_name()` when unset.

    Returns:
        dict: The aliases of all associated packages
    """
    if package_name == None:
        package_name = native.package_name()

    # Determine the relevant maps to use
    all_aliases_maps = []
    if normal:
        all_aliases_maps.append(_NORMAL_ALIASES)
    if normal_dev:
        all_aliases_maps.append(_NORMAL_DEV_ALIASES)
    if proc_macro:
        all_aliases_maps.append(_PROC_MACRO_ALIASES)
    if proc_macro_dev:
        all_aliases_maps.append(_PROC_MACRO_DEV_ALIASES)
    if build:
        all_aliases_maps.append(_BUILD_ALIASES)
    if build_proc_macro:
        all_aliases_maps.append(_BUILD_PROC_MACRO_ALIASES)

    # Default to always using normal aliases
    if not all_aliases_maps:
        all_aliases_maps.append(_NORMAL_ALIASES)
        all_aliases_maps.append(_PROC_MACRO_ALIASES)

    aliases = _flatten_dependency_maps(all_aliases_maps).pop(package_name, None)

    if not aliases:
        return dict()

    common_items = aliases.pop(_COMMON_CONDITION, {}).items()

    # If there are only common items in the dictionary, immediately return them
    if not len(aliases.keys()) == 1:
        return dict(common_items)

    # Build a single select statement where each conditional has accounted for the
    # common set of aliases.
    crate_aliases = {"//conditions:default": dict(common_items)}
    for condition, deps in aliases.items():
        condition_triples = _CONDITIONS[condition]
        for triple in condition_triples:
            if triple in crate_aliases:
                crate_aliases[triple].update(deps)
            else:
                crate_aliases.update({triple: dict(deps.items() + common_items)})

    return select(crate_aliases)

###############################################################################
# WORKSPACE MEMBER DEPS AND ALIASES
###############################################################################

_NORMAL_DEPENDENCIES = {
    "": {
        _COMMON_CONDITION: {
            "rdkafka": Label("@basic__rdkafka-0.34.0//:rdkafka"),
        },
    },
}

_NORMAL_ALIASES = {
    "": {
        _COMMON_CONDITION: {
        },
    },
}

_NORMAL_DEV_DEPENDENCIES = {
    "": {
    },
}

_NORMAL_DEV_ALIASES = {
    "": {
    },
}

_PROC_MACRO_DEPENDENCIES = {
    "": {
    },
}

_PROC_MACRO_ALIASES = {
    "": {
    },
}

_PROC_MACRO_DEV_DEPENDENCIES = {
    "": {
    },
}

_PROC_MACRO_DEV_ALIASES = {
    "": {
    },
}

_BUILD_DEPENDENCIES = {
    "": {
    },
}

_BUILD_ALIASES = {
    "": {
    },
}

_BUILD_PROC_MACRO_DEPENDENCIES = {
    "": {
    },
}

_BUILD_PROC_MACRO_ALIASES = {
    "": {
    },
}

_CONDITIONS = {
    "aarch64-apple-darwin": ["@rules_rust//rust/platform:aarch64-apple-darwin"],
    "aarch64-apple-ios": ["@rules_rust//rust/platform:aarch64-apple-ios"],
    "aarch64-apple-ios-sim": ["@rules_rust//rust/platform:aarch64-apple-ios-sim"],
    "aarch64-fuchsia": ["@rules_rust//rust/platform:aarch64-fuchsia"],
    "aarch64-linux-android": ["@rules_rust//rust/platform:aarch64-linux-android"],
    "aarch64-pc-windows-gnullvm": [],
    "aarch64-pc-windows-msvc": ["@rules_rust//rust/platform:aarch64-pc-windows-msvc"],
    "aarch64-unknown-linux-gnu": ["@rules_rust//rust/platform:aarch64-unknown-linux-gnu"],
    "aarch64-unknown-nixos-gnu": ["@rules_rust//rust/platform:aarch64-unknown-nixos-gnu"],
    "aarch64-unknown-nto-qnx710": ["@rules_rust//rust/platform:aarch64-unknown-nto-qnx710"],
    "arm-unknown-linux-gnueabi": ["@rules_rust//rust/platform:arm-unknown-linux-gnueabi"],
    "armv7-linux-androideabi": ["@rules_rust//rust/platform:armv7-linux-androideabi"],
    "armv7-unknown-linux-gnueabi": ["@rules_rust//rust/platform:armv7-unknown-linux-gnueabi"],
    "cfg(all(any(target_arch = \"x86_64\", target_arch = \"arm64ec\"), target_env = \"msvc\", not(windows_raw_dylib)))": ["@rules_rust//rust/platform:x86_64-pc-windows-msvc"],
    "cfg(all(target_arch = \"aarch64\", target_env = \"msvc\", not(windows_raw_dylib)))": ["@rules_rust//rust/platform:aarch64-pc-windows-msvc"],
    "cfg(all(target_arch = \"x86\", target_env = \"gnu\", not(target_abi = \"llvm\"), not(windows_raw_dylib)))": ["@rules_rust//rust/platform:i686-unknown-linux-gnu"],
    "cfg(all(target_arch = \"x86\", target_env = \"msvc\", not(windows_raw_dylib)))": ["@rules_rust//rust/platform:i686-pc-windows-msvc"],
    "cfg(all(target_arch = \"x86_64\", target_env = \"gnu\", not(target_abi = \"llvm\"), not(windows_raw_dylib)))": ["@rules_rust//rust/platform:x86_64-unknown-linux-gnu", "@rules_rust//rust/platform:x86_64-unknown-nixos-gnu"],
    "cfg(not(all(windows, target_env = \"msvc\", not(target_vendor = \"uwp\"))))": ["@rules_rust//rust/platform:aarch64-apple-darwin", "@rules_rust//rust/platform:aarch64-apple-ios", "@rules_rust//rust/platform:aarch64-apple-ios-sim", "@rules_rust//rust/platform:aarch64-fuchsia", "@rules_rust//rust/platform:aarch64-linux-android", "@rules_rust//rust/platform:aarch64-unknown-linux-gnu", "@rules_rust//rust/platform:aarch64-unknown-nixos-gnu", "@rules_rust//rust/platform:aarch64-unknown-nto-qnx710", "@rules_rust//rust/platform:arm-unknown-linux-gnueabi", "@rules_rust//rust/platform:armv7-linux-androideabi", "@rules_rust//rust/platform:armv7-unknown-linux-gnueabi", "@rules_rust//rust/platform:i686-apple-darwin", "@rules_rust//rust/platform:i686-linux-android", "@rules_rust//rust/platform:i686-unknown-freebsd", "@rules_rust//rust/platform:i686-unknown-linux-gnu", "@rules_rust//rust/platform:powerpc-unknown-linux-gnu", "@rules_rust//rust/platform:riscv32imc-unknown-none-elf", "@rules_rust//rust/platform:riscv64gc-unknown-none-elf", "@rules_rust//rust/platform:s390x-unknown-linux-gnu", "@rules_rust//rust/platform:thumbv7em-none-eabi", "@rules_rust//rust/platform:thumbv8m.main-none-eabi", "@rules_rust//rust/platform:wasm32-unknown-unknown", "@rules_rust//rust/platform:wasm32-wasi", "@rules_rust//rust/platform:x86_64-apple-darwin", "@rules_rust//rust/platform:x86_64-apple-ios", "@rules_rust//rust/platform:x86_64-fuchsia", "@rules_rust//rust/platform:x86_64-linux-android", "@rules_rust//rust/platform:x86_64-unknown-freebsd", "@rules_rust//rust/platform:x86_64-unknown-linux-gnu", "@rules_rust//rust/platform:x86_64-unknown-nixos-gnu", "@rules_rust//rust/platform:x86_64-unknown-none"],
    "cfg(tokio_taskdump)": [],
    "cfg(windows)": ["@rules_rust//rust/platform:aarch64-pc-windows-msvc", "@rules_rust//rust/platform:i686-pc-windows-msvc", "@rules_rust//rust/platform:x86_64-pc-windows-msvc"],
    "i686-apple-darwin": ["@rules_rust//rust/platform:i686-apple-darwin"],
    "i686-linux-android": ["@rules_rust//rust/platform:i686-linux-android"],
    "i686-pc-windows-gnullvm": [],
    "i686-pc-windows-msvc": ["@rules_rust//rust/platform:i686-pc-windows-msvc"],
    "i686-unknown-freebsd": ["@rules_rust//rust/platform:i686-unknown-freebsd"],
    "i686-unknown-linux-gnu": ["@rules_rust//rust/platform:i686-unknown-linux-gnu"],
    "powerpc-unknown-linux-gnu": ["@rules_rust//rust/platform:powerpc-unknown-linux-gnu"],
    "riscv32imc-unknown-none-elf": ["@rules_rust//rust/platform:riscv32imc-unknown-none-elf"],
    "riscv64gc-unknown-none-elf": ["@rules_rust//rust/platform:riscv64gc-unknown-none-elf"],
    "s390x-unknown-linux-gnu": ["@rules_rust//rust/platform:s390x-unknown-linux-gnu"],
    "thumbv7em-none-eabi": ["@rules_rust//rust/platform:thumbv7em-none-eabi"],
    "thumbv8m.main-none-eabi": ["@rules_rust//rust/platform:thumbv8m.main-none-eabi"],
    "wasm32-unknown-unknown": ["@rules_rust//rust/platform:wasm32-unknown-unknown"],
    "wasm32-wasi": ["@rules_rust//rust/platform:wasm32-wasi"],
    "x86_64-apple-darwin": ["@rules_rust//rust/platform:x86_64-apple-darwin"],
    "x86_64-apple-ios": ["@rules_rust//rust/platform:x86_64-apple-ios"],
    "x86_64-fuchsia": ["@rules_rust//rust/platform:x86_64-fuchsia"],
    "x86_64-linux-android": ["@rules_rust//rust/platform:x86_64-linux-android"],
    "x86_64-pc-windows-gnullvm": [],
    "x86_64-pc-windows-msvc": ["@rules_rust//rust/platform:x86_64-pc-windows-msvc"],
    "x86_64-unknown-freebsd": ["@rules_rust//rust/platform:x86_64-unknown-freebsd"],
    "x86_64-unknown-linux-gnu": ["@rules_rust//rust/platform:x86_64-unknown-linux-gnu"],
    "x86_64-unknown-nixos-gnu": ["@rules_rust//rust/platform:x86_64-unknown-nixos-gnu"],
    "x86_64-unknown-none": ["@rules_rust//rust/platform:x86_64-unknown-none"],
}

###############################################################################

def crate_repositories():
    """A macro for defining repositories for all generated crates.

    Returns:
      A list of repos visible to the module through the module extension.
    """
    maybe(
        http_archive,
        name = "basic__addr2line-0.24.2",
        sha256 = "dfbe277e56a376000877090da837660b4427aad530e3028d44e0bffe4f89a1c1",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/addr2line/0.24.2/download"],
        strip_prefix = "addr2line-0.24.2",
        build_file = Label("//basic/ppp/crates:BUILD.addr2line-0.24.2.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__adler2-2.0.0",
        sha256 = "512761e0bb2578dd7380c6baaa0f4ce03e84f95e960231d1dec8bf4d7d6e2627",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/adler2/2.0.0/download"],
        strip_prefix = "adler2-2.0.0",
        build_file = Label("//basic/ppp/crates:BUILD.adler2-2.0.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__autocfg-1.4.0",
        sha256 = "ace50bade8e6234aa140d9a2f552bbee1db4d353f69b8217bc503490fc1a9f26",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/autocfg/1.4.0/download"],
        strip_prefix = "autocfg-1.4.0",
        build_file = Label("//basic/ppp/crates:BUILD.autocfg-1.4.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__backtrace-0.3.74",
        sha256 = "8d82cb332cdfaed17ae235a638438ac4d4839913cc2af585c3c6746e8f8bee1a",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/backtrace/0.3.74/download"],
        strip_prefix = "backtrace-0.3.74",
        build_file = Label("//basic/ppp/crates:BUILD.backtrace-0.3.74.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__cc-1.2.3",
        sha256 = "27f657647bcff5394bf56c7317665bbf790a137a50eaaa5c6bfbb9e27a518f2d",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/cc/1.2.3/download"],
        strip_prefix = "cc-1.2.3",
        build_file = Label("//basic/ppp/crates:BUILD.cc-1.2.3.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__cfg-if-1.0.0",
        sha256 = "baf1de4339761588bc0619e3cbc0120ee582ebb74b53b4efbf79117bd2da40fd",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/cfg-if/1.0.0/download"],
        strip_prefix = "cfg-if-1.0.0",
        build_file = Label("//basic/ppp/crates:BUILD.cfg-if-1.0.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__cmake-0.1.52",
        sha256 = "c682c223677e0e5b6b7f63a64b9351844c3f1b1678a68b7ee617e30fb082620e",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/cmake/0.1.52/download"],
        strip_prefix = "cmake-0.1.52",
        build_file = Label("//basic/ppp/crates:BUILD.cmake-0.1.52.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__equivalent-1.0.1",
        sha256 = "5443807d6dff69373d433ab9ef5378ad8df50ca6298caf15de6e52e24aaf54d5",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/equivalent/1.0.1/download"],
        strip_prefix = "equivalent-1.0.1",
        build_file = Label("//basic/ppp/crates:BUILD.equivalent-1.0.1.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__futures-channel-0.3.31",
        sha256 = "2dff15bf788c671c1934e366d07e30c1814a8ef514e1af724a602e8a2fbe1b10",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/futures-channel/0.3.31/download"],
        strip_prefix = "futures-channel-0.3.31",
        build_file = Label("//basic/ppp/crates:BUILD.futures-channel-0.3.31.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__futures-core-0.3.31",
        sha256 = "05f29059c0c2090612e8d742178b0580d2dc940c837851ad723096f87af6663e",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/futures-core/0.3.31/download"],
        strip_prefix = "futures-core-0.3.31",
        build_file = Label("//basic/ppp/crates:BUILD.futures-core-0.3.31.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__futures-task-0.3.31",
        sha256 = "f90f7dce0722e95104fcb095585910c0977252f286e354b5e3bd38902cd99988",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/futures-task/0.3.31/download"],
        strip_prefix = "futures-task-0.3.31",
        build_file = Label("//basic/ppp/crates:BUILD.futures-task-0.3.31.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__futures-util-0.3.31",
        sha256 = "9fa08315bb612088cc391249efdc3bc77536f16c91f6cf495e6fbe85b20a4a81",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/futures-util/0.3.31/download"],
        strip_prefix = "futures-util-0.3.31",
        build_file = Label("//basic/ppp/crates:BUILD.futures-util-0.3.31.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__gimli-0.31.1",
        sha256 = "07e28edb80900c19c28f1072f2e8aeca7fa06b23cd4169cefe1af5aa3260783f",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/gimli/0.31.1/download"],
        strip_prefix = "gimli-0.31.1",
        build_file = Label("//basic/ppp/crates:BUILD.gimli-0.31.1.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__hashbrown-0.15.2",
        sha256 = "bf151400ff0baff5465007dd2f3e717f3fe502074ca563069ce3a6629d07b289",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/hashbrown/0.15.2/download"],
        strip_prefix = "hashbrown-0.15.2",
        build_file = Label("//basic/ppp/crates:BUILD.hashbrown-0.15.2.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__indexmap-2.7.0",
        sha256 = "62f822373a4fe84d4bb149bf54e584a7f4abec90e072ed49cda0edea5b95471f",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/indexmap/2.7.0/download"],
        strip_prefix = "indexmap-2.7.0",
        build_file = Label("//basic/ppp/crates:BUILD.indexmap-2.7.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__itoa-1.0.14",
        sha256 = "d75a2a4b1b190afb6f5425f10f6a8f959d2ea0b9c2b1d79553551850539e4674",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/itoa/1.0.14/download"],
        strip_prefix = "itoa-1.0.14",
        build_file = Label("//basic/ppp/crates:BUILD.itoa-1.0.14.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__libc-0.2.168",
        sha256 = "5aaeb2981e0606ca11d79718f8bb01164f1d6ed75080182d3abf017e6d244b6d",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/libc/0.2.168/download"],
        strip_prefix = "libc-0.2.168",
        build_file = Label("//basic/ppp/crates:BUILD.libc-0.2.168.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__libz-sys-1.1.20",
        sha256 = "d2d16453e800a8cf6dd2fc3eb4bc99b786a9b90c663b8559a5b1a041bf89e472",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/libz-sys/1.1.20/download"],
        strip_prefix = "libz-sys-1.1.20",
        build_file = Label("//basic/ppp/crates:BUILD.libz-sys-1.1.20.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__log-0.4.22",
        sha256 = "a7a70ba024b9dc04c27ea2f0c0548feb474ec5c54bba33a7f72f873a39d07b24",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/log/0.4.22/download"],
        strip_prefix = "log-0.4.22",
        build_file = Label("//basic/ppp/crates:BUILD.log-0.4.22.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__memchr-2.7.4",
        sha256 = "78ca9ab1a0babb1e7d5695e3530886289c18cf2f87ec19a575a0abdce112e3a3",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/memchr/2.7.4/download"],
        strip_prefix = "memchr-2.7.4",
        build_file = Label("//basic/ppp/crates:BUILD.memchr-2.7.4.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__miniz_oxide-0.8.0",
        sha256 = "e2d80299ef12ff69b16a84bb182e3b9df68b5a91574d3d4fa6e41b65deec4df1",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/miniz_oxide/0.8.0/download"],
        strip_prefix = "miniz_oxide-0.8.0",
        build_file = Label("//basic/ppp/crates:BUILD.miniz_oxide-0.8.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__num_enum-0.7.3",
        sha256 = "4e613fc340b2220f734a8595782c551f1250e969d87d3be1ae0579e8d4065179",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/num_enum/0.7.3/download"],
        strip_prefix = "num_enum-0.7.3",
        build_file = Label("//basic/ppp/crates:BUILD.num_enum-0.7.3.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__num_enum_derive-0.7.3",
        sha256 = "af1844ef2428cc3e1cb900be36181049ef3d3193c63e43026cfe202983b27a56",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/num_enum_derive/0.7.3/download"],
        strip_prefix = "num_enum_derive-0.7.3",
        build_file = Label("//basic/ppp/crates:BUILD.num_enum_derive-0.7.3.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__object-0.36.5",
        sha256 = "aedf0a2d09c573ed1d8d85b30c119153926a2b36dce0ab28322c09a117a4683e",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/object/0.36.5/download"],
        strip_prefix = "object-0.36.5",
        build_file = Label("//basic/ppp/crates:BUILD.object-0.36.5.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__pin-project-lite-0.2.15",
        sha256 = "915a1e146535de9163f3987b8944ed8cf49a18bb0056bcebcdcece385cece4ff",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/pin-project-lite/0.2.15/download"],
        strip_prefix = "pin-project-lite-0.2.15",
        build_file = Label("//basic/ppp/crates:BUILD.pin-project-lite-0.2.15.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__pin-utils-0.1.0",
        sha256 = "8b870d8c151b6f2fb93e84a13146138f05d02ed11c7e7c54f8826aaaf7c9f184",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/pin-utils/0.1.0/download"],
        strip_prefix = "pin-utils-0.1.0",
        build_file = Label("//basic/ppp/crates:BUILD.pin-utils-0.1.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__pkg-config-0.3.31",
        sha256 = "953ec861398dccce10c670dfeaf3ec4911ca479e9c02154b3a215178c5f566f2",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/pkg-config/0.3.31/download"],
        strip_prefix = "pkg-config-0.3.31",
        build_file = Label("//basic/ppp/crates:BUILD.pkg-config-0.3.31.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__proc-macro-crate-3.2.0",
        sha256 = "8ecf48c7ca261d60b74ab1a7b20da18bede46776b2e55535cb958eb595c5fa7b",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/proc-macro-crate/3.2.0/download"],
        strip_prefix = "proc-macro-crate-3.2.0",
        build_file = Label("//basic/ppp/crates:BUILD.proc-macro-crate-3.2.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__proc-macro2-1.0.92",
        sha256 = "37d3544b3f2748c54e147655edb5025752e2303145b5aefb3c3ea2c78b973bb0",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/proc-macro2/1.0.92/download"],
        strip_prefix = "proc-macro2-1.0.92",
        build_file = Label("//basic/ppp/crates:BUILD.proc-macro2-1.0.92.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__quote-1.0.37",
        sha256 = "b5b9d34b8991d19d98081b46eacdd8eb58c6f2b201139f7c5f643cc155a633af",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/quote/1.0.37/download"],
        strip_prefix = "quote-1.0.37",
        build_file = Label("//basic/ppp/crates:BUILD.quote-1.0.37.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__rdkafka-0.34.0",
        sha256 = "053adfa02fab06e86c01d586cc68aa47ee0ff4489a59469081dc12cbcde578bf",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/rdkafka/0.34.0/download"],
        strip_prefix = "rdkafka-0.34.0",
        build_file = Label("//basic/ppp/crates:BUILD.rdkafka-0.34.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__rdkafka-sys-4.8.0-2.3.0",
        sha256 = "ced38182dc436b3d9df0c77976f37a67134df26b050df1f0006688e46fc4c8be",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/rdkafka-sys/4.8.0+2.3.0/download"],
        strip_prefix = "rdkafka-sys-4.8.0+2.3.0",
        build_file = Label("//basic/ppp/crates:BUILD.rdkafka-sys-4.8.0+2.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__rustc-demangle-0.1.24",
        sha256 = "719b953e2095829ee67db738b3bfa9fa368c94900df327b3f07fe6e794d2fe1f",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/rustc-demangle/0.1.24/download"],
        strip_prefix = "rustc-demangle-0.1.24",
        build_file = Label("//basic/ppp/crates:BUILD.rustc-demangle-0.1.24.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__ryu-1.0.18",
        sha256 = "f3cb5ba0dc43242ce17de99c180e96db90b235b8a9fdc9543c96d2209116bd9f",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/ryu/1.0.18/download"],
        strip_prefix = "ryu-1.0.18",
        build_file = Label("//basic/ppp/crates:BUILD.ryu-1.0.18.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__serde-1.0.216",
        sha256 = "0b9781016e935a97e8beecf0c933758c97a5520d32930e460142b4cd80c6338e",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/serde/1.0.216/download"],
        strip_prefix = "serde-1.0.216",
        build_file = Label("//basic/ppp/crates:BUILD.serde-1.0.216.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__serde_derive-1.0.216",
        sha256 = "46f859dbbf73865c6627ed570e78961cd3ac92407a2d117204c49232485da55e",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/serde_derive/1.0.216/download"],
        strip_prefix = "serde_derive-1.0.216",
        build_file = Label("//basic/ppp/crates:BUILD.serde_derive-1.0.216.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__serde_json-1.0.133",
        sha256 = "c7fceb2473b9166b2294ef05efcb65a3db80803f0b03ef86a5fc88a2b85ee377",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/serde_json/1.0.133/download"],
        strip_prefix = "serde_json-1.0.133",
        build_file = Label("//basic/ppp/crates:BUILD.serde_json-1.0.133.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__shlex-1.3.0",
        sha256 = "0fda2ff0d084019ba4d7c6f371c95d8fd75ce3524c3cb8fb653a3023f6323e64",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/shlex/1.3.0/download"],
        strip_prefix = "shlex-1.3.0",
        build_file = Label("//basic/ppp/crates:BUILD.shlex-1.3.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__slab-0.4.9",
        sha256 = "8f92a496fb766b417c996b9c5e57daf2f7ad3b0bebe1ccfca4856390e3d3bb67",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/slab/0.4.9/download"],
        strip_prefix = "slab-0.4.9",
        build_file = Label("//basic/ppp/crates:BUILD.slab-0.4.9.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__syn-2.0.90",
        sha256 = "919d3b74a5dd0ccd15aeb8f93e7006bd9e14c295087c9896a110f490752bcf31",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/syn/2.0.90/download"],
        strip_prefix = "syn-2.0.90",
        build_file = Label("//basic/ppp/crates:BUILD.syn-2.0.90.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__tokio-1.42.0",
        sha256 = "5cec9b21b0450273377fc97bd4c33a8acffc8c996c987a7c5b319a0083707551",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/tokio/1.42.0/download"],
        strip_prefix = "tokio-1.42.0",
        build_file = Label("//basic/ppp/crates:BUILD.tokio-1.42.0.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__toml_datetime-0.6.8",
        sha256 = "0dd7358ecb8fc2f8d014bf86f6f638ce72ba252a2c3a2572f2a795f1d23efb41",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/toml_datetime/0.6.8/download"],
        strip_prefix = "toml_datetime-0.6.8",
        build_file = Label("//basic/ppp/crates:BUILD.toml_datetime-0.6.8.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__toml_edit-0.22.22",
        sha256 = "4ae48d6208a266e853d946088ed816055e556cc6028c5e8e2b84d9fa5dd7c7f5",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/toml_edit/0.22.22/download"],
        strip_prefix = "toml_edit-0.22.22",
        build_file = Label("//basic/ppp/crates:BUILD.toml_edit-0.22.22.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__unicode-ident-1.0.14",
        sha256 = "adb9e6ca4f869e1180728b7950e35922a7fc6397f7b641499e8f3ef06e50dc83",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/unicode-ident/1.0.14/download"],
        strip_prefix = "unicode-ident-1.0.14",
        build_file = Label("//basic/ppp/crates:BUILD.unicode-ident-1.0.14.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__vcpkg-0.2.15",
        sha256 = "accd4ea62f7bb7a82fe23066fb0957d48ef677f6eeb8215f372f52e48bb32426",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/vcpkg/0.2.15/download"],
        strip_prefix = "vcpkg-0.2.15",
        build_file = Label("//basic/ppp/crates:BUILD.vcpkg-0.2.15.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows-targets-0.52.6",
        sha256 = "9b724f72796e036ab90c1021d4780d4d3d648aca59e491e6b98e725b84e99973",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows-targets/0.52.6/download"],
        strip_prefix = "windows-targets-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows-targets-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows_aarch64_gnullvm-0.52.6",
        sha256 = "32a4622180e7a0ec044bb555404c800bc9fd9ec262ec147edd5989ccd0c02cd3",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows_aarch64_gnullvm/0.52.6/download"],
        strip_prefix = "windows_aarch64_gnullvm-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows_aarch64_gnullvm-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows_aarch64_msvc-0.52.6",
        sha256 = "09ec2a7bb152e2252b53fa7803150007879548bc709c039df7627cabbd05d469",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows_aarch64_msvc/0.52.6/download"],
        strip_prefix = "windows_aarch64_msvc-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows_aarch64_msvc-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows_i686_gnu-0.52.6",
        sha256 = "8e9b5ad5ab802e97eb8e295ac6720e509ee4c243f69d781394014ebfe8bbfa0b",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows_i686_gnu/0.52.6/download"],
        strip_prefix = "windows_i686_gnu-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows_i686_gnu-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows_i686_gnullvm-0.52.6",
        sha256 = "0eee52d38c090b3caa76c563b86c3a4bd71ef1a819287c19d586d7334ae8ed66",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows_i686_gnullvm/0.52.6/download"],
        strip_prefix = "windows_i686_gnullvm-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows_i686_gnullvm-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows_i686_msvc-0.52.6",
        sha256 = "240948bc05c5e7c6dabba28bf89d89ffce3e303022809e73deaefe4f6ec56c66",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows_i686_msvc/0.52.6/download"],
        strip_prefix = "windows_i686_msvc-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows_i686_msvc-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows_x86_64_gnu-0.52.6",
        sha256 = "147a5c80aabfbf0c7d901cb5895d1de30ef2907eb21fbbab29ca94c5b08b1a78",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows_x86_64_gnu/0.52.6/download"],
        strip_prefix = "windows_x86_64_gnu-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows_x86_64_gnu-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows_x86_64_gnullvm-0.52.6",
        sha256 = "24d5b23dc417412679681396f2b49f3de8c1473deb516bd34410872eff51ed0d",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows_x86_64_gnullvm/0.52.6/download"],
        strip_prefix = "windows_x86_64_gnullvm-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows_x86_64_gnullvm-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__windows_x86_64_msvc-0.52.6",
        sha256 = "589f6da84c646204747d1270a2a5661ea66ed1cced2631d546fdfb155959f9ec",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/windows_x86_64_msvc/0.52.6/download"],
        strip_prefix = "windows_x86_64_msvc-0.52.6",
        build_file = Label("//basic/ppp/crates:BUILD.windows_x86_64_msvc-0.52.6.bazel"),
    )

    maybe(
        http_archive,
        name = "basic__winnow-0.6.20",
        sha256 = "36c1fec1a2bb5866f07c25f68c26e565c4c200aebb96d7e55710c19d3e8ac49b",
        type = "tar.gz",
        urls = ["https://static.crates.io/crates/winnow/0.6.20/download"],
        strip_prefix = "winnow-0.6.20",
        build_file = Label("//basic/ppp/crates:BUILD.winnow-0.6.20.bazel"),
    )

    return [
        struct(repo = "basic__rdkafka-0.34.0", is_dev_dep = False),
    ]
