class MimusComparator {
    struct ComparisonResult {
        struct MismatchedComparison {
            let argumentIndex: Int             
            let expected: Matcher?
            let actual: Any?
        }

        let matching: Bool
        let mismatchedComparisons: [MismatchedComparison]
    }

    func match(expected: Arguments, actual: [Any?]?) -> ComparisonResult {
        switch expected {
        case .any:
            return ComparisonResult(matching: true, mismatchedComparisons: [])
        case .none:
            return ComparisonResult(matching: actual == nil, mismatchedComparisons: [])
        case let .actual(arguments):
            return match(expected: arguments, actual: actual)
        }
    }

    private func match(expected: [Matcher?], actual: [Any?]?) -> ComparisonResult {
        guard let actualArguments = actual else {
            return ComparisonResult(matching: false, mismatchedComparisons: [])
        }

        if expected.count != actualArguments.count {
            return ComparisonResult(matching: false, mismatchedComparisons: [])
        }

        return match(expectedArguments: expected, actualArguments: actualArguments)
    }

    private func match(expectedArguments: [Matcher?], actualArguments: [Any?]) -> ComparisonResult {
        // At this point we're sure both arrays have the same count

        var equal = true

        var mismatchedComparisons: [ComparisonResult.MismatchedComparison] = []

        for (index, item) in expectedArguments.enumerated() {
            let internalEqual: Bool

            let other = actualArguments[index]
            if let unwrappedItem = item {
                internalEqual = unwrappedItem.matches(argument: other)
            } else {
                internalEqual = other == nil
            }

            if !internalEqual {
                mismatchedComparisons.append(ComparisonResult.MismatchedComparison(argumentIndex: index, expected: item, actual: other))
            }

            equal = internalEqual && equal
        }

        return ComparisonResult(matching: equal, mismatchedComparisons: mismatchedComparisons)
    }
}
