# Failure reporting integration tests

From the repository root, run:

```sh
SOURCERY=/path/to/sourcery bash Scripts/test-failure-reporting.sh
```

CI uses Sourcery 2.4.1. The script generates mocks from `ReportingProtocols` using
the repository's template, then runs this Swift 6 test package against the local
Mimus library. Generated files are ignored by Git. SwiftPM options can be passed
to the script, for example `--filter generatedStaticVerifierPreservesLocation`.

The XCTest test requires exactly one recorded failure. Swift Testing tests accept
intentional failures only when their source locations match the expected file
path, file ID, line, and column. They cover instance methods, argument matchers,
static methods, and default source-location arguments.
