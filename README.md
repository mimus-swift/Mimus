<p align="center">
  <img src="https://github.com/mimus-swift/Mimus/raw/master/Design/mimus%403x.png" width="250" height="250"/>
</p>

# Mimus

[![Swift 5.0+](https://img.shields.io/badge/Swift-5.0+-orange.svg?style=flat)](https://swift.org/)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg?style=flat)]()
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-compatible-4BC51D.svg?style=flat)](https://github.com/CocoaPods/CocoaPods)
[![License MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)]()
[![Public Yes](https://img.shields.io/badge/Public-yes-green.svg?style=flat)]()
[![CI](https://github.com/mimus-swift/Mimus/actions/workflows/default.yml/badge.svg)](https://github.com/mimus-swift/Mimus/actions/workflows/default.yml)

> Mimus is a bird genus in the family Mimidae. It contains the typical mockingbirds.

Mimus is a Swift mocking library, aiming to reduce boilerplate code required for building mocks in Swift. It's been battle tested at [AirHelp](http://airhelp.com) and [Toptal](https://www.toptal.com) where it's being used extensively across test suites.

# Main features

* Pure Swift
* Protocol-oriented implementation
* Integrated with XCTest and Swift Test
* Support for verification of basic types and collections (including optionals)
* Support for writing custom matchers
* Detailed failure reporting
* Unit-tested

# Usage

A Mimus mock can be created by declaring a class that conforms to your custom protocol and Mimus `Mock` type:

```swift
class FakeAuthenticationManager: AuthenticationManager, Mock {

    var storage = Mimus.Storage()

    func beginAuthentication(with email: String, password: String) {
        recordCall(withIdentifier: "BeginAuthentication", arguments: [email, password])
    }
}
```

Afterwards you can verify whether specific call was received:

```swift
let fakeLoginAuthenticationManager = FakeAuthenticationManager()

(...)

fakeLoginAuthenticationManager.verifyCall(withIdentifier: "BeginAuthentication",
        arguments: [mEqual("Fixture Email"), mEqual("Fixture Password")])
```

You can find more on the basic usage [here](https://github.com/mimus-swift/Mimus/blob/master/Documentation/Basics.md).

For detailed usage refer to [documentation folder](https://github.com/mimus-swift/Mimus/tree/master/Documentation).

## Installation

### Swift Package Manager

Mimus is available through [Swift Package Manager](https://swift.org/package-manager/).

#### When added as a package dependency

``` swift
dependencies: [
        .package(
            url: "https://github.com/mimus-swift/Mimus.git",
            from: "2.3.0"
        )
    ]
```

#### When added as an Application dependency:

To add a package dependency to your Xcode project, select File > Swift Packages > Add Package Dependency and enter its repository URL.

You can also navigate to your target’s General pane, and in the “Frameworks, Libraries, and Embedded Content” section, click the + button.
In the “Choose frameworks and libraries to add” dialog, select Add Other, and choose Add Package Dependency.

### Carthage

You can also use [Carthage](https://github.com/Carthage/Carthage) for installing Mimus.
Simply add it to your Cartfile:

``` ruby
github "mimus-swift/Mimus"
```

and then link it with your test target.

### Cocoapods - 🚨 DEPRECATED 🚨

Mimus is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile against your test target:

```ruby
pod "Mimus"
```

Note that starting with 2.1.0 Mimus will not be distributed via Cocoapods - we're moving to Swift Package Manager and we recommend everyone to do the same. You can still use Cocoapods with latest versions by pinning to a specific tag.

## Authors

Mimus is an AirHelp open source project, designed and implemented by

* Pawel Dudek, [@eldudi](http://twitter.com/eldudi), pawel@dudek.mobi
* Pawel Kozielecki, [@pawelkozielecki](https://twitter.com/pawelkozielecki), pawel.kozielecki@airhelp.com

Logo Design by Arkadiusz Lipiarz [@arek_lipiarz](https://twitter.com/arek_lipiarz), arkadiusz.lipiarz@airhelp.com

## License

*Mimus* is available under the MIT license. See the LICENSE file for more info.
