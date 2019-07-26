//
//  Copyright © 2019 AirHelp. All rights reserved.
//

import Foundation

class MismatchMessageCreator {
    
    func message(for mismatchedResults: [MatchResult]) -> String {
        guard !mismatchedResults.isEmpty else {
            return ""
        }
        let mismatchedCallsCountInfo = "Found \(mismatchedResults.count) call(s) with expected identifier, but not matching arguments:"
        return mismatchedResults
            .enumerated()
            .map {[unowned self] (index, result) -> String in
                let comparisons = result.mismatchedComparisons
                let callIndex = index + 1
                return "\nMismatched call #\(callIndex):\(self.comparisonDetails(for: comparisons))"
            }
            .reduce(mismatchedCallsCountInfo, +)
    }
    
    private func comparisonDetails(for comparisons: [MatchResult.MismatchedComparison]) -> String {
        guard !comparisons.isEmpty else {
            return "\nUnexpected behavior, no arguments comparison to present"
        }
        return comparisons
            .map({[unowned self] (comparison) -> String in
                return "\nMismatch in argument #\(comparison.argumentIndex) - expected \(self.displayText(for: comparison.expected)), but was \(self.displayText(for: comparison.actual))."})
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
