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

    /// Removes recorded calls at given indexes.
    /// 
    /// - Parameter indexes: a list of recorded call indexes to be removed. 
    func remove(callsAtIndexes indexes: [Int]) {
        for index in indexes.reversed() {
            recordedCalls.remove(at: index)
        }
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
