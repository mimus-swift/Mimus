import Mimus
import MimusMocks
import Observation
import Testing

@Mockable
private protocol ObservableService: Observable {
  var enabled: Bool { get set }
}

@Test func preservesObservationForComputedStubProperties() {
  let mock = MockObservableService()
  let observation = MockState()
  withObservationTracking {
    _ = mock.enabled
  } onChange: {
    observation.set(true, for: "changed")
  }
  mock.enabled = true
  #expect(observation.value(for: "changed", as: Bool.self) == true)
  #expect(mock.enabled)
}
