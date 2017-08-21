internal class Matcher {

    func match(expected: [MockEquatable?]?, actual: [MockEquatable?]?) -> Bool {
        if expected == nil && actual == nil {
            return true
        }

        guard let expectedArguments = expected, let actualArguments = actual else {
            return false
        }

        if expectedArguments.count != actualArguments.count {
            return false
        }

        return match(expectedArguments: expectedArguments, actualArguments: actualArguments)
    }

    func match(expectedArguments: [MockEquatable?], actualArguments: [MockEquatable?]) -> Bool {
        // At this point we're sure both arrays have the same count

        var equal = true

        for (index, item) in expectedArguments.enumerated() {
            let other = actualArguments[index]
            if let unwrappedItem = item {
                equal = (unwrappedItem.equalTo(other: other)) && equal
            } else {
                equal = other == nil
            }
        }

        return equal
    }
}
