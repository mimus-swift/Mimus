//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest

extension String: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherString = argument as? String {
            return self == otherString
        }
        if let otherStaticString = argument as? StaticString {
            return self == otherStaticString.toString()
        }
        return false
    }
}

extension StaticString: Matcher {
    public func matches(argument: Any?) -> Bool {
        let selfString = self.toString()
        if let otherString = argument as? String {
            return selfString == otherString
        }
        if let otherStaticString = argument as? StaticString {
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

extension Int: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherInt = argument as? Int {
            return self == otherInt
        }
        return false
    }
}

extension UInt: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherInt = argument as? UInt {
            return self == otherInt
        }
        return false
    }
}

extension Float: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherFloat = argument as? Float {
            return self == otherFloat
        }
        return false
    }
}

extension Double: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherDouble = argument as? Double {
            return self == otherDouble
        }
        return false
    }
}

extension Bool: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherBool = argument as? Bool {
            return self == otherBool
        }
        return false
    }
}

extension URL: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherUrl = argument as? URL {
            return self == otherUrl
        }
        return false
    }
}

extension Array: Matcher {
    public func matches(argument: Any?) -> Bool {
        guard let actualArray = argument as? [Any?] else {
            return false
        }
        // Small hack to go around type system
        let selfAny = self as Any?
        guard let expectedArray = selfAny as? [Matcher?] else {
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

            equal = expected.matches(argument: actual) && equal
        }
        return equal
    }

    private func areNullEquivalents(item: Matcher?, other: Any?) -> Bool {
        if item == nil || item is NSNull {
            return other == nil || other is NSNull
        }
        return false
    }
}

extension Dictionary: Matcher {
    public func matches(argument: Any?) -> Bool {
        guard let actual = argument as? [AnyHashable: Any] else {
            return false
        }
        guard let expected = self as? [AnyHashable: Matcher] else {
            let location = TestLocation.currentTestLocation()
            XCTFail("Attempted to compare unsupported dictionary types. Values should conform to \(Matcher.self)",
                file: location.file,
                line: location.line)
            return false
        }

        guard keys.count == actual.keys.count else {
            return false
        }

        var equal = true

        for (key, expectedValue) in expected {
            guard let actualValue = actual[key] else {
                return false
            }

            equal = expectedValue.matches(argument: actualValue) && equal
        }

        return equal
    }
}

extension IndexPath: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherIndexPath = argument as? IndexPath {
            return self == otherIndexPath
        }
        return false
    }
}
