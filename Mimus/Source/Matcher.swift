internal struct MatchResult {

    struct MismatchedComparison {

        let expected: MockEquatable?

        let actual: MockEquatable?
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

    func match(expected: [MockEquatable?]?, actual: [MockEquatable?]?) -> MatchResult {
        if expected == nil && actual == nil {
            return MatchResult(matching: true)
        }

        guard let expectedArguments = expected, let actualArguments = actual else {
            return MatchResult(matching: false)
        }

        if expectedArguments.count != actualArguments.count {
            return MatchResult(matching: false)
        }

        return match(expectedArguments: expectedArguments, actualArguments: actualArguments)
    }

    func match(expectedArguments: [MockEquatable?], actualArguments: [MockEquatable?]) -> MatchResult {
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
                mismatchedComparisons.append(MatchResult.MismatchedComparison(expected: item, actual: other))
            }

            equal = internalEqual && equal
        }

        return MatchResult(matching: equal, mismatchedComparisons: mismatchedComparisons)
    }
}
