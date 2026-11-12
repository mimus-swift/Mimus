import Foundation

/// Conditions evaluate against the original typed argument, including explicit nil.
public struct StubArgument<Value> {
  private let predicate: (Value) -> Bool
  public init(matching predicate: @escaping (Value) -> Bool) { self.predicate = predicate }
  public static var any: Self { Self { _ in true } }
  public static func any(_ type: Value.Type) -> Self { .any }
  public static func value(_ value: Value) -> Self where Value: Equatable { Self { $0 == value } }
  public static func matching(_ predicate: @escaping (Value) -> Bool) -> Self {
    Self(matching: predicate)
  }
  public func matches(_ value: Value) -> Bool { predicate(value) }
}

/// Concurrent mocks require safe captures in predicates, just as in their handlers.
public struct SendableStubArgument<Value>: Sendable {
  private let predicate: @Sendable (Value) -> Bool
  public init(matching predicate: @escaping @Sendable (Value) -> Bool) {
    self.predicate = predicate
  }
  public static var any: Self { Self { _ in true } }
  public static func any(_ type: Value.Type) -> Self { .any }
  public static func value(_ value: Value) -> Self where Value: Equatable & Sendable {
    Self { $0 == value }
  }
  public static func matching(_ predicate: @escaping @Sendable (Value) -> Bool) -> Self {
    Self(matching: predicate)
  }
  public func matches(_ value: Value) -> Bool { predicate(value) }
}

/// A non-escaping closure can be forwarded to an answer, but never stored in a matcher.
public enum NonEscapingStubArgument: Sendable { case any }

public struct StubMethodKey: Hashable, Sendable {
  private let signature: String
  private let specialization: ObjectIdentifier?
  public init(_ signature: String, specialization: Any.Type? = nil) {
    self.signature = signature
    self.specialization = specialization.map(ObjectIdentifier.init)
  }
}

public struct StubLocation: Sendable, CustomStringConvertible {
  public let file: StaticString
  public let line: UInt
  public init(file: StaticString, line: UInt) {
    self.file = file
    self.line = line
  }
  public var description: String { "\(file):\(line)" }
}

/// Type erasure stays behind the generated, signature-specific builders.
public enum StubAction {
  case value(Any)
  case failure(any Error)
  case answer(Any)

  public func returned<Value>(as type: Value.Type) -> Value {
    guard case .value(let value) = self, let result = value as? Value else {
      preconditionFailure("Invalid return type in a generated stub")
    }
    return result
  }
  public func error<Failure: Error>(as type: Failure.Type) -> Failure {
    guard case .failure(let error) = self, let result = error as? Failure else {
      preconditionFailure("Invalid error type in a generated stub")
    }
    return result
  }
  public func handler<Handler>(as type: Handler.Type) -> Handler {
    guard case .answer(let handler) = self, let result = handler as? Handler else {
      preconditionFailure("Invalid answer signature in a generated stub")
    }
    return result
  }
}

/// A matched nil return is distinct from an unmatched invocation.
public enum StubResolution {
  case unmatched
  case matched(StubAction)
}

/// The table and response cursors are synchronized. Predicates and answers run
/// on the invoking method's executor, outside the lock. This type intentionally
/// makes no Sendable claim about callbacks or returned objects; generated
/// concurrent mocks enforce Sendable predicate and answer signatures.
public final class StubRules {
  private final class Entry {
    let id: UInt64
    let matches: ([Any]) -> Bool
    let location: StubLocation
    var actions: [StubAction]
    var next = 0
    init(
      id: UInt64, matches: @escaping ([Any]) -> Bool, actions: [StubAction], location: StubLocation
    ) {
      self.id = id
      self.matches = matches
      self.actions = actions
      self.location = location
    }
  }
  private let lock = NSLock()
  private var entries: [StubMethodKey: [Entry]] = [:]
  private var nextID: UInt64 = 0
  private var generation: UInt64 = 0

  public init() {}

  public func register(
    method: StubMethodKey, matches: @escaping ([Any]) -> Bool,
    actions: [StubAction], location: StubLocation
  ) -> StubRuleHandle {
    precondition(!actions.isEmpty, "A stub must have at least one response (\(location))")
    lock.lock()
    defer { lock.unlock() }
    let id = nextID
    nextID &+= 1
    entries[method, default: []].append(
      Entry(id: id, matches: matches, actions: actions, location: location))
    return StubRuleHandle(
      rules: self, method: method, id: id, generation: generation, location: location)
  }

  public func resolve(method: StubMethodKey, arguments: [Any]) -> StubResolution {
    lock.lock()
    let candidates = entries[method] ?? []
    let observedGeneration = generation
    lock.unlock()
    for entry in candidates.reversed() where entry.matches(arguments) {
      lock.lock()
      guard observedGeneration == generation else {
        lock.unlock()
        return .unmatched
      }
      let action = entry.actions[min(entry.next, entry.actions.count - 1)]
      entry.next = min(entry.next + 1, entry.actions.count)
      lock.unlock()
      return .matched(action)
    }
    return .unmatched
  }

  fileprivate func append(_ action: StubAction, to handle: StubRuleHandle) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    guard handle.generation == generation,
      let entry = entries[handle.method]?.first(where: { $0.id == handle.id })
    else { return false }
    entry.actions.append(action)
    return true
  }

  public func reset() {
    lock.lock()
    let retired = entries
    entries = [:]
    generation &+= 1
    lock.unlock()
    // Release captured user objects outside the registry lock as well.
    withExtendedLifetime(retired) {}
  }
}

public struct StubRuleHandle {
  fileprivate let rules: StubRules
  fileprivate let method: StubMethodKey
  fileprivate let id: UInt64
  fileprivate let generation: UInt64
  fileprivate let location: StubLocation
  fileprivate func append(_ action: StubAction) {
    precondition(
      rules.append(action, to: self),
      "This stub was cleared by reset. Register a new rule (originally \(location)).")
  }
}

private struct StubSelection {
  let rules: StubRules
  let method: StubMethodKey
  let matches: ([Any]) -> Bool
  func register(_ actions: [StubAction], file: StaticString, line: UInt) -> StubRuleHandle {
    rules.register(
      method: method, matches: matches, actions: actions,
      location: StubLocation(file: file, line: line))
  }
}

public struct Stub<Output, Handler> {
  private let selection: StubSelection
  public init(rules: StubRules, method: StubMethodKey, matches: @escaping ([Any]) -> Bool) {
    selection = StubSelection(rules: rules, method: method, matches: matches)
  }
  public func returning(_ type: Output.Type) -> Self { self }
  @discardableResult
  public func returns(
    _ first: Output, _ rest: Output..., file: StaticString = #filePath, line: UInt = #line
  ) -> StubSequence<Output, Handler> {
    let values = [first] + rest
    return StubSequence(
      handle: selection.register(values.map { .value($0 as Any) }, file: file, line: line))
  }
  @discardableResult
  public func answers(file: StaticString = #filePath, line: UInt = #line, _ handler: Handler)
    -> StubSequence<Output, Handler>
  {
    StubSequence(handle: selection.register([.answer(handler)], file: file, line: line))
  }
}

extension Stub where Output == Void {
  @discardableResult
  public func doesNothing(file: StaticString = #filePath, line: UInt = #line) -> StubSequence<
    Output, Handler
  > {
    returns((), file: file, line: line)
  }
}

public struct ThrowingStub<Output, Failure: Error, Handler> {
  private let selection: StubSelection
  public init(rules: StubRules, method: StubMethodKey, matches: @escaping ([Any]) -> Bool) {
    selection = StubSelection(rules: rules, method: method, matches: matches)
  }
  public func returning(_ type: Output.Type) -> Self { self }
  @discardableResult
  public func returns(
    _ first: Output, _ rest: Output..., file: StaticString = #filePath, line: UInt = #line
  ) -> ThrowingStubSequence<Output, Failure, Handler> {
    let values = [first] + rest
    return ThrowingStubSequence(
      handle: selection.register(values.map { .value($0 as Any) }, file: file, line: line))
  }
  @discardableResult
  public func `throws`(_ error: Failure, file: StaticString = #filePath, line: UInt = #line)
    -> ThrowingStubSequence<Output, Failure, Handler>
  {
    ThrowingStubSequence(handle: selection.register([.failure(error)], file: file, line: line))
  }
  @discardableResult
  public func answers(file: StaticString = #filePath, line: UInt = #line, _ handler: Handler)
    -> ThrowingStubSequence<Output, Failure, Handler>
  {
    ThrowingStubSequence(handle: selection.register([.answer(handler)], file: file, line: line))
  }
}

extension ThrowingStub where Output == Void {
  @discardableResult
  public func doesNothing(file: StaticString = #filePath, line: UInt = #line)
    -> ThrowingStubSequence<Output, Failure, Handler>
  {
    returns((), file: file, line: line)
  }
}

public struct StubSequence<Output, Handler> {
  fileprivate let handle: StubRuleHandle
  @discardableResult public func thenReturn(_ value: Output) -> Self {
    handle.append(.value(value as Any))
    return self
  }
  @discardableResult public func thenAnswer(_ handler: Handler) -> Self {
    handle.append(.answer(handler))
    return self
  }
}

public struct ThrowingStubSequence<Output, Failure: Error, Handler> {
  fileprivate let handle: StubRuleHandle
  @discardableResult public func thenReturn(_ value: Output) -> Self {
    handle.append(.value(value as Any))
    return self
  }
  @discardableResult public func thenThrow(_ error: Failure) -> Self {
    handle.append(.failure(error))
    return self
  }
  @discardableResult public func thenAnswer(_ handler: Handler) -> Self {
    handle.append(.answer(handler))
    return self
  }
}
