internal struct MatchResult {

    struct MismatchedComparison {

        let argumentIndex: Int
        
        let expected: MockEquatable?

        let actual: Any?
    }

    let matching: Bool

    let mismatchedComparisons: [MismatchedComparison]

    init(matching: Bool) {
        self.matching = matching
        self.mismatchedComparisons = []
    }

    init(matching: Bool, mismatchedComparisons: [MismatchedComparison]) {
        self.matching = matching
        self.mismatchedComparisons = mismatchedComparisons
    }
}

internal class Matcher {

    func match(expected: Arguments, actual: [Any?]?) -> MatchResult {
        switch expected {
        case .any:
            return MatchResult(matching: true)
        case .none:
            return MatchResult(matching: actual == nil)
        case let .actual(arguments):
            return match(expected: arguments, actual: actual)
        }
    }

    private func match(expected: [MockEquatable?], actual: [Any?]?) -> MatchResult {
        guard let actualArguments = actual else {
            return MatchResult(matching: false)
        }

        if expected.count != actualArguments.count {
            return MatchResult(matching: false)
        }

        return match(expectedArguments: expected, actualArguments: actualArguments)
    }

    private func match(expectedArguments: [MockEquatable?], actualArguments: [Any?]) -> MatchResult {
        // At this point we're sure both arrays have the same count

        var equal = true

        var mismatchedComparisons: [MatchResult.MismatchedComparison] = []

        for (index, item) in expectedArguments.enumerated() {
            let internalEqual: Bool

            let other = actualArguments[index]
            if let unwrappedItem = item {
                internalEqual = (unwrappedItem.equalTo(other: other))
            } else {
                internalEqual = other == nil
            }

            if !internalEqual {
                mismatchedComparisons.append(MatchResult.MismatchedComparison(argumentIndex: index, expected: item, actual: other))
            }

            equal = internalEqual && equal
        }

        return MatchResult(matching: equal, mismatchedComparisons: mismatchedComparisons)
    }
}
