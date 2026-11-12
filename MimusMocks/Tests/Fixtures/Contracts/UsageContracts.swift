public enum InventoryError: Error, Equatable {
  case unavailable
}

// mimus: mockable
// mimus: excluding = "canReserve"
public protocol InventoryService: Sendable {
  func quantity(of itemID: String) async throws -> Int
  func canReserve(itemID: String, count: Int) async throws -> Bool
}

extension InventoryService {
  public func canReserve(itemID: String, count: Int) async throws -> Bool {
    try await quantity(of: itemID) >= count
  }
}

// sourcery: automockable
public protocol ParcelDispatcher {
  func dispatch(_ parcelID: String, completion: @escaping (Result<Int, any Error>) -> Void)
}

// mimus: mockable
public protocol MeasurementFeed: Sendable {
  func samples() -> AsyncThrowingStream<Int, any Error>
}
