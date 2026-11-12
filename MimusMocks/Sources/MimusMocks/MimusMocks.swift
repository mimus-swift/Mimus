import Foundation

/// Opt in to the consumer's .mock() factories for unstubbed values.
public enum MockDefaults: Sendable {
  case none
  case fixtures
}

public enum MockStubbing: Sendable {
  /// Configure simulated values, errors, and handlers directly.
  case simple
  /// Add typed stub() builders with argument matchers, answers, and response sequences.
  case argumentMatching
}

/// A per-requirement factory choice, evaluated in the generated mock.
public enum MockDefaultSource: Sendable {
  case fixture
  case nestedMock
}

/// Generates a Mimus mock beside a protocol declared in a test or mocks target.
@attached(peer, names: prefixed(Mock))
public macro Mockable(
  baseClassName: String? = nil,
  defaults: MockDefaults = .none,
  stubbing: MockStubbing = .simple,
  excluding: [String] = [],
  publicMock: Bool = false,
  inheritedRequirementsAreDeclared: Bool = false
) =
  #externalMacro(
    module: "MockableMacro", type: "MockableMacro"
  )

/// Supplies a lazy default for a generated property or return value.
/// A configured simulated value or handler takes precedence.
@attached(peer)
public macro MockDefault<Value>(_ value: Value) =
  #externalMacro(module: "MockableMacro", type: "MockDefaultMacro")

@attached(peer)
public macro MockDefault(_ source: MockDefaultSource) =
  #externalMacro(module: "MockableMacro", type: "MockDefaultMacro")

/// Opts a publisher property into a generated PassthroughSubject helper.
@attached(peer)
public macro MockPublisher() =
  #externalMacro(module: "MockableMacro", type: "MockPublisherMacro")

/// Opts a publisher property into a generated CurrentValueSubject helper.
/// The emitted subject initializer type-checks the value against its Output.
@attached(peer)
public macro MockPublisher(initial: Any?) =
  #externalMacro(module: "MockableMacro", type: "MockPublisherMacro")

/// Adds a method-entry observer and, for async methods, optional suspension control.
@attached(peer)
public macro MockCallControl() =
  #externalMacro(module: "MockableMacro", type: "MockCallControlMacro")

/// Marks a requirement whose generated witness overrides the mock's base class.
@attached(peer)
public macro MockOverride() =
  #externalMacro(module: "MockableMacro", type: "MockOverrideMacro")

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

/// Explicit stubs and factory cells are registered under a lock. Each cell
/// serializes its lazy initialization separately. Handlers are copied while
/// locked and invoked after unlocking, allowing reentrant mocks.
/// Sendable mocks require @Sendable handlers; referenced return values retain
/// their own concurrency contracts. This invariant permits unchecked conformance
/// until the deployment minimum supports a standard-library Mutex everywhere.
public final class MockState: @unchecked Sendable {
  private let lock = NSLock()
  private var values: [String: Any] = [:]
  private var defaults: [String: Any] = [:]
  private var rules: StubRules?
  private var callControls: [String: CallCoordinationState] = [:]

  public init() {}

  /// A rule table is allocated only for mocks that use rule stubbing.
  public func stubRules() -> StubRules {
    lock.lock()
    defer { lock.unlock() }
    if let rules { return rules }
    let rules = StubRules()
    self.rules = rules
    return rules
  }

  private func callControl(for key: String) -> CallCoordinationState {
    lock.lock()
    defer { lock.unlock() }
    if let state = callControls[key] { return state }
    let state = CallCoordinationState()
    callControls[key] = state
    return state
  }

  public func callObserver(for key: String) -> CallObserver {
    CallObserver(state: callControl(for: key))
  }

  public func asyncCallControl(for key: String) -> AsyncCallControl {
    AsyncCallControl(state: callControl(for: key))
  }

  public func value<Value>(for key: String, as type: Value.Type = Value.self) -> Value? {
    lock.lock()
    defer { lock.unlock() }
    guard let stored = values[key] else { return nil }
    return stored as? Value
  }

  /// Select a per-key initialization cell while locked, then run the consumer's
  /// factory outside the state lock. Concurrent first reads share the same cell.
  public func value<Value>(
    for key: String, as type: Value.Type = Value.self, default makeValue: () -> Value
  ) -> Value {
    lock.lock()
    if let stored = values[key], let configured = stored as? Value {
      lock.unlock()
      return configured
    }
    let cell = defaults[key] as? DefaultValue<Value> ?? DefaultValue<Value>()
    defaults[key] = cell
    lock.unlock()
    let fallback = cell.value(makeValue)
    lock.lock()
    defer { lock.unlock() }
    if let stored = values[key], let configured = stored as? Value { return configured }
    return fallback
  }

  public func set<Value>(_ value: Value, for key: String) {
    lock.lock()
    defer { lock.unlock() }
    values[key] = value as Any
  }

  public func setOptional<Value>(_ value: Value?, for key: String) {
    lock.lock()
    defer { lock.unlock() }
    if let value {
      values[key] = value
    } else {
      values.removeValue(forKey: key)
      defaults.removeValue(forKey: key)
    }
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
    values.removeAll()
    defaults.removeAll()
    let rules = rules
    let controls = Array(callControls.values)
    lock.unlock()
    rules?.reset()
    for control in controls { control.reset() }
  }
}

private final class DefaultValue<Value> {
  private let lock = NSRecursiveLock()
  private var cached: Value?
  private var initializing = false

  func value(_ makeValue: () -> Value) -> Value {
    lock.lock()
    defer { lock.unlock() }
    if let cached { return cached }
    precondition(
      !initializing, "A mock default recursively depends on itself. Configure an explicit value.")
    initializing = true
    defer { initializing = false }
    let value = makeValue()
    cached = .some(value)
    return value
  }
}
