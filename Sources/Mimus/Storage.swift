//
// Copyright (©) 2019 AirHelp. All rights reserved.
//

import Foundation

/// Structure used to hold recorded invocations
struct RecordedCall {
    let identifier: String
    let arguments: [Any?]?
}

struct RecordedReturnEntry {
    let returnValue: Any?
    let recordedCall: RecordedCall
    let thrownError: Error?
}

/// Class responsible for storing recorded calls.
public class Storage {
    var recordedCalls: [RecordedCall]
    var recordedReturnValueEntries: [RecordedReturnEntry]

    public init() {
        recordedCalls = []
        recordedReturnValueEntries = []
    }

    func record(call: RecordedCall) {
        recordedCalls.append(call)
    }

    func record(entry: RecordedReturnEntry) {
        recordedReturnValueEntries.append(entry)
    }

    /// Resets all recorded calls. Use to return given mock to initial state.
    public func reset() {
        recordedCalls = []
        recordedReturnValueEntries = []
    }

    /// Removes all calls at a given identifier.
    func remove(callsWithIdentifier identifier: String) {
        recordedCalls.removeAll(where: { $0.identifier == identifier })
    }
}

extension Storage {
    func recordedReturnEntry(matchingIdentifier identifier: String, arguments: Arguments) -> RecordedReturnEntry? {
        let callCandidates = recordedReturnValueEntries.filter {
            $0.recordedCall.identifier == identifier
        }

        let mockMatcher = MimusComparator()
        return callCandidates.filter({
            let result = mockMatcher.match(expected: arguments, actual: $0.recordedCall.arguments)
            return result.matching
        }).last
    }
}
