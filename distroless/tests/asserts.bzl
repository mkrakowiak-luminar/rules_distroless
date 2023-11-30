"Make shorter assertions"

load("@aspect_bazel_lib//lib:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

# buildifier: disable=function-docstring
def assert_tar_listing(name, actual, expected):
    actual_listing = "_{}_listing".format(name)
    expected_listing = "_{}_expected".format(name)

    native.genrule(
        name = actual_listing,
        srcs = [actual],
        outs = ["_{}.listing".format(name)],
        cmd = "cat $(execpath {}) | $(BSDTAR_BIN) -cf $@ --format=mtree --options 'cksum,sha1' @-".format(actual),
        toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
    )

    write_file(
        name = expected_listing,
        out = "_{}.expected".format(name),
        content = [expected],
        newline = "unix",
    )

    diff_test(
        name = name,
        file1 = actual_listing,
        file2 = expected_listing,
        timeout = "short",
    )

# buildifier: disable=function-docstring
def assert_jks_listing(name, actual, expected):
    actual_listing = "_{}_listing".format(name)

    native.genrule(
        name = actual_listing,
        srcs = [
            actual,
            "@rules_java//toolchains:current_java_runtime",
        ],
        outs = ["_{}.listing".format(name)],
        cmd = """
BINS=($(locations @rules_java//toolchains:current_java_runtime))
KEYTOOL=$$(dirname $${BINS[1]})/keytool
TZ="UTC" $$KEYTOOL -list -keystore $(location %s) -storepass changeit > $@
""" % actual,
    )

    diff_test(
        name = name,
        file1 = actual_listing,
        file2 = expected,
        timeout = "short",
    )