//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest

extension String: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        if let otherString = other as? String {
            return self == otherString
        }
        if let otherStaticString = other as? StaticString {
            return self == otherStaticString.toString()
        }
        return false
    }
}

extension StaticString: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        let selfString = self.toString()
        if let otherString = other as? String {
            return selfString == otherString
        }
        if let otherStaticString = other as? StaticString {
            return selfString == otherStaticString.toString()
        }
        return false
    }

    fileprivate func toString() -> String {
        if hasPointerRepresentation {
            return String(cString: utf8Start)
        }
        return String(self.unicodeScalar)
    }
}

extension Int: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        if let otherInt = other as? Int {
            return self == otherInt
        }
        return false
    }
}

extension Float: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        if let otherFloat = other as? Float {
            return self == otherFloat
        }
        return false
    }
}

extension Double: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        if let otherDouble = other as? Double {
            return self == otherDouble
        }
        return false
    }
}

extension Bool: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        if let otherBool = other as? Bool {
            return self == otherBool
        }
        return false
    }
}

extension URL: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        if let otherUrl = other as? URL {
            return self == otherUrl
        }
        return false
    }
}

extension Array: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        // Small hack to go around type system
        let selfAny = self as Any?
        guard let expectedArray = selfAny as? [MockEquatable?],
              let actualArray = other as? [Any?] else {
            let expectedMirror = Mirror(reflecting: self as Any)
            let location = TestLocation.currentTestLocation()
            XCTFail("Attempted to compare unsupported array types. Expected type \(expectedMirror.subjectType)",
                    file: location.file,
                    line: location.line)
            return false
        }

        if expectedArray.count != actualArray.count {
            return false
        }

        var equal = true

        for (index, item) in expectedArray.enumerated() {
            let otherItem = actualArray[index]

            if areNullEquivalents(item: item, other: otherItem) {
                continue
            }

            guard let expected = item, let actual = otherItem else {
                return false
            }

            equal = expected.equalTo(other: actual) && equal
        }
        return equal
    }

    private func areNullEquivalents(item: MockEquatable?, other: Any?) -> Bool {
        if item == nil || item is NSNull {
            return other == nil || other is NSNull
        }
        return false
    }
}

extension Dictionary: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        // Small hack to go around type system
        let anySelf: [AnyHashable: Any] = self

        guard let expected = anySelf as? [AnyHashable: MockEquatable],
              let actual = other as? [AnyHashable: Any] else {
            let location = TestLocation.currentTestLocation()
            XCTFail("Attempted to compare unsupported dictionary types. Values should conform to \(MockEquatable.self)",
                    file: location.file,
                    line: location.line)
            return false
        }

        var equal = true

        for (key, expectedValue) in expected {
            guard let actualValue = actual[key] else {
                return false
            }

            equal = expectedValue.equalTo(other: actualValue) && equal
        }

        return equal
    }
}

extension IndexPath: MockEquatable {

    public func equalTo(other: Any?) -> Bool {
        if let otherIndexPath = other as? IndexPath {
            return self == otherIndexPath
        }
        return false
    }
}
