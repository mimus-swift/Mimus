//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest

extension String: MockEquatable {

    public func equalTo(other: MockEquatable?) -> Bool {
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

    public func equalTo(other: MockEquatable?) -> Bool {
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

    public func equalTo(other: MockEquatable?) -> Bool {
        if let otherInt = other as? Int {
            return self == otherInt
        }
        return false
    }
}

extension Double: MockEquatable {

    public func equalTo(other: MockEquatable?) -> Bool {
        if let otherDouble = other as? Double {
            return self == otherDouble
        }
        return false
    }
}

extension Bool: MockEquatable {

    public func equalTo(other: MockEquatable?) -> Bool {
        if let otherBool = other as? Bool {
            return self == otherBool
        }
        return false
    }
}

extension Array: MockEquatable {

    public func equalTo(other: MockEquatable?) -> Bool {
        // Small hack to go around type system
        let anyArray = self as Any
        guard let selfArray = anyArray as? [MockEquatable?],
              let otherArray = other as? [MockEquatable?],
              selfArray.count == otherArray.count else {
            let expectedMirror = Mirror(reflecting: self as Any)
            let location = TestLocation.currentTestLocation()
            XCTFail("Attempted to compare unsupported array types. Expected type \(expectedMirror.subjectType)",
                    file: location.file,
                    line: location.line)
            return false
        }

        var equal = true

        for (index, item) in selfArray.enumerated() {
            let otherItem = otherArray[index]
            guard let expected = item, let actual = otherItem else {
                return false
            }

            equal = expected.equalTo(other: actual) && equal
        }
        return equal
    }
}

extension Dictionary: MockEquatable {

    public func equalTo(other: MockEquatable?) -> Bool {
        // Small hack to go around type system
        let anySelf: [AnyHashable: Any] = self

        guard let expected = anySelf as? [AnyHashable: MockEquatable],
              let actual = other as? [AnyHashable: MockEquatable] else {
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

    public func equalTo(other: MockEquatable?) -> Bool {
        if let otherIndexPath = other as? IndexPath {
            return self == otherIndexPath
        }
        return false
    }
}
