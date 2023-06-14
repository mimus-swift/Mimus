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
    private let recordedCallsQueue = DispatchQueue(label: "recorded-calls", attributes: .concurrent)
    private var _recordedCalls: [RecordedCall]
    var recordedCalls: [RecordedCall] {
        recordedCallsQueue.sync {
            _recordedCalls
        }
    }
    private let recordedReturnValueEntriesQueue = DispatchQueue(label: "recorded_return_value-entries", attributes: .concurrent)
    private var _recordedReturnValueEntries: [RecordedReturnEntry]
    var recordedReturnValueEntries: [RecordedReturnEntry] {
        recordedReturnValueEntriesQueue.sync {
            _recordedReturnValueEntries
        }
    }

    public init() {
        _recordedCalls = []
        _recordedReturnValueEntries = []
    }

    func record(call: RecordedCall) {
        recordedCallsQueue.sync(flags: .barrier) {
            _recordedCalls.append(call)
        }
    }

    func record(entry: RecordedReturnEntry) {
        recordedReturnValueEntriesQueue.sync(flags: .barrier) {
            _recordedReturnValueEntries.append(entry)
        }

    }

    /// Resets all recorded calls. Use to return given mock to initial state.
    public func reset() {
        recordedCallsQueue.sync(flags: .barrier) {
            _recordedCalls = []
        }
        recordedReturnValueEntriesQueue.sync(flags: .barrier) {
            _recordedReturnValueEntries = []
        }
    }

    /// Removes recorded calls at given indexes.
    /// 
    /// - Parameter indexes: a list of recorded call indexes to be removed. 
    func remove(callsAtIndexes indexes: [Int]) {
        for index in indexes.reversed() {
            _ = recordedCallsQueue.sync(flags: .barrier) {
                _recordedCalls.remove(at: index)
            }
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
