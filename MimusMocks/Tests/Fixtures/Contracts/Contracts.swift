public protocol ParentService {
  func ping(value: Int)
}

// mimus: mockable
public protocol ChildService: ParentService, Sendable {
  var name: String { get }
  func fetch() async throws -> String
  func parent() -> (any ParentService)?
}

// sourcery: automockable
public protocol SelectionStore {
  var selection: String? { get }
}
