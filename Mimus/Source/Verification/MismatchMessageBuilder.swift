//
//  Copyright © 2019 AirHelp. All rights reserved.
//

import Foundation

class MismatchMessageBuilder {

    func message(for mismatchedResults: [MatchResult]) -> String {
        guard !mismatchedResults.isEmpty else {
            return ""
        }
        let messages = buildRecordedCallsMessages(for: mismatchedResults)
        return joined(messages, newlineSeparator: "\n\n")
    }

    private func buildRecordedCallsMessages(for matchResults: [MatchResult]) -> [String] {
        let hasMultipleMismatches = matchResults.count > 1
        if hasMultipleMismatches {
            return matchResults.enumerated().map(indexedMessageForMismatchedCall)
        } else {
            return matchResults.map(messageForMismatchedCall)
        }
    }

    private func indexedMessageForMismatchedCall(index: Int, matchResult: MatchResult) -> String {
        let callIndex = index + 1
        return "Mismatched call #\(callIndex):\n\(messageForMismatchedCall(for: matchResult))"
    }

    private func messageForMismatchedCall(for matchResult: MatchResult) -> String {
        let comparisons = matchResult.mismatchedComparisons
        guard !comparisons.isEmpty else {
            return "Unexpected behavior, no arguments comparison to present"
        }
        let messages = comparisons.map { comparison -> String in
            let details = "expected \(comparison.expected.mimusDescription()), but was \(comparison.actual.mimusDescription())."
            return "Mismatch in argument #\(comparison.argumentIndex) - \(details)"
        }
        return joined(messages)
    }

    private func joined(_ messages: [String], newlineSeparator: String = "\n") -> String {
        return messages
            .enumerated()
            .reduce("", { (result, element) in
                let (index, message) = element
                let isLastMessage = messages.count == index + 1
                return isLastMessage ? "\(result)\(message)" : "\(result)\(message)\(newlineSeparator)"
            })

    }
}
