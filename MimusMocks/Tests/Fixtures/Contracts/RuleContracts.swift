public enum CatalogFailure: Error, Equatable {
  case unavailable
}

public protocol CatalogParent {
  // mimus: default = "\"unnamed\""
  func name(id: Int) -> String
}

// mimus: mockable
// mimus: defaults = "fixtures"
// mimus: stubbing = "argumentMatching"
// mimus: excluding = "hasStock"
public protocol ProductCatalog: CatalogParent, Sendable {
  func product(id: Int) async throws(CatalogFailure) -> FixtureProduct
  func hasStock(id: Int) async throws -> Bool
}

extension ProductCatalog {
  public func hasStock(id: Int) async throws -> Bool {
    try await product(id: id).code != "empty"
  }
}
