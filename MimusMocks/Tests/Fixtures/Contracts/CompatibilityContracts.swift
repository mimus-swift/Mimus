import Foundation

public enum Warehouse {
  public enum Nested {
    // mimus: mockable
    public protocol Client: Store {
      func dispatch()
    }
  }
  // mimus: mockable
  public protocol Store: Sendable {
    func ping()
  }

  // mimus: mockable
  // mimus: defaults = "fixtures"
  public protocol Client: Store {
    var store: any Store { get }
    // mimus: forceMock
    var optionalStore: Store? { get }
    // mimus: callControl
    func finish() async
  }
}

public enum Courier {
  // mimus: mockable
  public protocol Store {
    func dispatch()
  }
}

public enum ContractSpace {}
extension ContractSpace {
  // mimus: mockable
  public protocol Service {
    func ping()
  }
}

#if os(macOS)
  // mimus: mockable
  public protocol PlatformService {
    func platform() -> String
  }
#elseif os(Linux)
  // mimus: mockable
  public protocol PlatformService {
    func linuxOnly() -> Int
  }
#else
  // mimus: mockable
  public protocol PlatformService {
    func otherPlatform() -> Bool
  }
#endif

#if false
  // mimus: mockable
  public protocol InactiveService {
    func unavailable(_ value: IntentionallyUnavailableType)
  }
#endif

// mimus: mockable
public protocol OperationStatus: ProgressReporting {
  func ready() -> Bool
}

// mimus: mockable
public protocol DescribedService: NSObjectProtocol {
  // mimus: override
  var description: String { get }
  // sourcery: definedIn = "NSObject"
  func isEqual(_ object: Any?) -> Bool
}

// mimus: mockable
// mimus: stubbing = "argumentMatching"
public protocol CallbackExecutor {
  func perform(_ operation: () throws -> Int) rethrows -> Int
}
