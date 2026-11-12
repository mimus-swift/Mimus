import Combine

public protocol TelemetryEvents {
  // mimus: publisher = "passthrough"
  var events: AnyPublisher<String, Never> { get }
}

// mimus: mockable
// mimus: defaults = "fixtures"
public protocol TelemetryChannel: TelemetryEvents {
  // mimus: publisherInitial = "10"
  var readings: AnyPublisher<Int, Never> { get }

  // mimus: publisherInitial = "nil"
  var label: AnyPublisher<String?, Never> { get }
}
