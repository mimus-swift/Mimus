#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
fixture_dir="$repo_dir/Tests/FailureReporting"
generated_dir="$fixture_dir/Tests/FailureReportingTests/Generated"
sourcery_executable="${SOURCERY:-sourcery}"

mkdir -p "$generated_dir"
"$sourcery_executable" \
    --sources "$fixture_dir/Sources/ReportingProtocols" \
    --templates "$repo_dir/SourceryStencil/AutoMockable.stencil" \
    --output "$generated_dir/Mocks.generated.swift" \
    --args module=ReportingProtocols \
    --disableCache

swift test --package-path "$fixture_dir" "$@"
