import Foundation

/// Generates a Mimus mock beside a protocol declared in a test or mocks target.
@attached(peer, names: prefixed(Mock))
public macro Mockable(
  baseClassName: String? = nil,
  excluding: [String] = [],
  publicMock: Bool = false,
  inheritedRequirementsAreDeclared: Bool = false
) =
  #externalMacro(
    module: "MockableMacro", type: "MockableMacro"
  )

/// Keeps argument types in overloaded verifier signatures.
public struct Argument<Value> {
  private let predicate: (Value?) -> Bool

  public init(matching predicate: @escaping (Value?) -> Bool) {
    self.predicate = predicate
  }

  public static var any: Self { Self { _ in true } }

  public static func value(_ value: Value) -> Self where Value: Equatable {
    Self { $0 == value }
  }

  public func matches(_ value: Value?) -> Bool { predicate(value) }
}

/// A marker replaces a non-escaping closure in call history; the closure is
/// forwarded to the handler without extending its lifetime.
public struct NonEscapingArgument: CustomStringConvertible {
  public init() {}
  public var description: String { "<non-escaping closure>" }
}

/// All mutable generated stub state is accessed under this lock. Handlers are
/// copied while locked and invoked after unlocking, allowing reentrant mocks.
/// Sendable mocks require @Sendable handlers; referenced return values retain
/// their own concurrency contracts. This invariant permits unchecked conformance
/// until the deployment minimum supports a standard-library Mutex everywhere.
public final class MockState: @unchecked Sendable {
  private let lock = NSLock()
  private var values: [String: Any] = [:]

  public init() {}

  public func value<Value>(for key: String, as type: Value.Type = Value.self) -> Value? {
    lock.lock()
    defer { lock.unlock() }
    return values[key] as? Value
  }

  public func set<Value>(_ value: Value, for key: String) {
    lock.lock()
    defer { lock.unlock() }
    values[key] = value as Any
  }

  public func setOptional<Value>(_ value: Value?, for key: String) {
    lock.lock()
    defer { lock.unlock() }
    if let value { values[key] = value } else { values.removeValue(forKey: key) }
  }

  public func require<Value>(for key: String, as type: Value.Type = Value.self) -> Value {
    guard let value: Value = value(for: key) else {
      preconditionFailure(
        "No stub configured for \(key). Set its simulated value or handler before calling it.")
    }
    return value
  }

  public func reset() {
    lock.lock()
    defer { lock.unlock() }
    values.removeAll()
  }
}
