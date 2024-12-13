# Repo of Rules Rust Issue
rules_rust repo for dangling symbolic links on rdkafka

```
bazel build //basic/ppp/crates:rdkafka
```
with rules_rust 0.54.1 fails with: 

> INFO: Invocation ID: fcefdb36-068d-48a2-b915-623a2620934e
INFO: Analyzed target //basic/ppp/crates:rdkafka (92 packages loaded, 4809 targets configured).
ERROR: /home/coder/.cache/bazel/_bazel_coder/6e203c268c5d4ac64ebb36337b8076c9/external/basic__rdkafka-sys-4.8.0-2.3.0/BUILD.bazel:96:19: error while validating output tree artifact external/basic__rdkafka-sys-4.8.0-2.3.0/_bs.out_dir: child include/librdkafka/rdkafka.h is a dangling symbolic link
ERROR: /home/coder/.cache/bazel/_bazel_coder/6e203c268c5d4ac64ebb36337b8076c9/external/basic__rdkafka-sys-4.8.0-2.3.0/BUILD.bazel:96:19: Running Cargo build script rdkafka-sys failed: not all outputs were created or valid
Target @@basic__rdkafka-0.34.0//:rdkafka failed to build
Use --verbose_failures to see the command lines of failed build steps.
INFO: Elapsed time: 14.213s, Critical Path: 0.39s
INFO: 67 processes: 54 remote cache hit, 13 internal.
ERROR: Build did NOT complete successfully

with rules_rust 0.53.0 successfully builds.
