//
//  Copyright © 2019 AirHelp. All rights reserved.
//

import Foundation

class MismatchMessageBuilder {
    
    func message(for mismatchedResults: [MatchResult]) -> String {
        guard !mismatchedResults.isEmpty else {
            return ""
        }
        let mismatchedCallsCountInfo = "Found \(mismatchedResults.count) call(s) with expected identifier, but not matching arguments:"
        return mismatchedResults
            .enumerated()
            .map {(index, result) -> String in
                let comparisons = result.mismatchedComparisons
                let callIndex = index + 1
                return "\nMismatched call #\(callIndex):\(comparisonDetails(for: comparisons))"
            }
            .reduce(mismatchedCallsCountInfo, +)
    }
    
    private func comparisonDetails(for comparisons: [MatchResult.MismatchedComparison]) -> String {
        guard !comparisons.isEmpty else {
            return "\nUnexpected behavior, no arguments comparison to present"
        }
        return comparisons
            .map({(comparison) -> String in
                return "\nMismatch in argument #\(comparison.argumentIndex) - expected \(displayText(for: comparison.expected)), but was \(displayText(for: comparison.actual))."})
            .reduce("", +)
    }
    
    private func displayText(for value: Any?) -> String {
        if let value = value {
            return "<(\(String(describing: value)))>"
        } else {
            return "<(nil)>"
        }
    }
    
}
