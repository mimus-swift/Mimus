import Foundation

public enum CallCoordinationError: Error, Equatable {
  case reset
}

/// Observes method entry without blocking synchronous methods.
public struct CallObserver: Sendable {
  let state: CallCoordinationState
  public var callCount: Int { state.callCount }
  public func waitForCall(count: Int = 1) async throws { try await state.waitForCall(count: count) }
  public func recordCall() { state.recordCall() }
}

/// Pausing affects future entries. Calls are recorded before their response runs.
public struct AsyncCallControl: Sendable {
  let state: CallCoordinationState
  public var callCount: Int { state.callCount }
  public var pendingCallCount: Int { state.pendingCallCount }
  public func waitForCall(count: Int = 1) async throws { try await state.waitForCall(count: count) }
  public func pause() { state.pause() }
  public func resume() { state.resume() }
  @discardableResult public func resumeNext() -> Bool { state.resumeNext() }
  public func enter() async { await state.enter() }
}

/// All state is protected by lock. Only counts and Void continuations cross
/// executors; no arguments, responses, or user callbacks are stored here.
/// NSLock supports the package's deployment minimum, unlike Mutex. Replace it
/// when that minimum supports Mutex. Continuations are resumed after unlocking.
final class CallCoordinationState: @unchecked Sendable {
  private struct Observer {
    let count: Int
    let signal: CoordinationSignal
  }
  private struct Gate {
    let id: UUID
    let signal: CoordinationSignal
  }
  private let lock = NSLock()
  private var count = 0
  private var paused = false
  private var observers: [UUID: Observer] = [:]
  private var gates: [Gate] = []

  var callCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return count
  }

  var pendingCallCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return gates.count
  }

  func waitForCall(count target: Int) async throws {
    precondition(target > 0, "waitForCall(count:) requires a positive count")
    try Task.checkCancellation()
    let id = UUID()
    let signal = CoordinationSignal()
    registerObserver(id: id, count: target, signal: signal)
    try await withTaskCancellationHandler {
      try await signal.wait()
    } onCancel: {
      self.cancelObserver(id: id, signal: signal)
    }
  }

  func registerObserver(id: UUID, count target: Int, signal: CoordinationSignal) {
    lock.lock()
    let reached = count >= target
    if !reached { observers[id] = Observer(count: target, signal: signal) }
    lock.unlock()
    if reached { signal.finish(.success(())) }
  }

  private func cancelObserver(id: UUID, signal: CoordinationSignal) {
    lock.lock()
    observers.removeValue(forKey: id)
    lock.unlock()
    signal.finish(.failure(CancellationError()))
  }

  func recordCall() { _ = record(suspending: false) }

  func enter() async {
    guard let gate = record(suspending: true) else { return }
    await withTaskCancellationHandler {
      // Cancellation releases the gate. The original method keeps its declared
      // error contract and continues through its normal handler/stub path.
      try? await gate.signal.wait()
    } onCancel: {
      self.cancelGate(id: gate.id, signal: gate.signal)
    }
  }

  private func record(suspending: Bool) -> Gate? {
    lock.lock()
    count += 1
    let gate = paused && suspending ? Gate(id: UUID(), signal: CoordinationSignal()) : nil
    if let gate { gates.append(gate) }
    let reached = observers.filter { $0.value.count <= count }
    for id in reached.keys { observers.removeValue(forKey: id) }
    lock.unlock()
    // Publish entry after its gate exists, so a waiter can immediately release it.
    for observer in reached.values { observer.signal.finish(.success(())) }
    return gate
  }

  private func cancelGate(id: UUID, signal: CoordinationSignal) {
    lock.lock()
    gates.removeAll { $0.id == id }
    lock.unlock()
    signal.finish(.success(()))
  }

  func pause() {
    lock.lock()
    paused = true
    lock.unlock()
  }

  func resume() {
    lock.lock()
    paused = false
    let released = gates
    gates = []
    lock.unlock()
    for gate in released { gate.signal.finish(.success(())) }
  }

  func resumeNext() -> Bool {
    lock.lock()
    let gate = gates.isEmpty ? nil : gates.removeFirst()
    lock.unlock()
    gate?.signal.finish(.success(()))
    return gate != nil
  }

  func reset() {
    lock.lock()
    count = 0
    paused = false
    let waiting = observers
    observers = [:]
    let released = gates
    gates = []
    lock.unlock()
    for observer in waiting.values { observer.signal.finish(.failure(CallCoordinationError.reset)) }
    for gate in released { gate.signal.finish(.success(())) }
  }
}

/// A one-shot completion remembers release/reset/cancellation even if it arrives
/// before continuation installation. Its result and continuations are exclusively
/// lock-protected and Sendable. Replace NSLock with Mutex when deployment permits.
final class CoordinationSignal: @unchecked Sendable {
  private let lock = NSLock()
  private var result: Result<Void, any Error>?
  private var continuations: [CheckedContinuation<Void, any Error>] = []

  func wait() async throws {
    try await withCheckedThrowingContinuation { install($0) }
  }

  private func install(_ continuation: CheckedContinuation<Void, any Error>) {
    lock.lock()
    let completed = result
    if completed == nil { continuations.append(continuation) }
    lock.unlock()
    if let completed { continuation.resume(with: completed) }
  }

  func finish(_ result: Result<Void, any Error>) {
    lock.lock()
    guard self.result == nil else {
      lock.unlock()
      return
    }
    self.result = result
    let waiting = continuations
    continuations = []
    lock.unlock()
    for continuation in waiting { continuation.resume(with: result) }
  }
}
