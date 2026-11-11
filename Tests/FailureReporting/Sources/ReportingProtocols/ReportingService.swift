// sourcery: automockable
@MainActor
public protocol ReportingService {
    func ping()
    func send(value: Int)
    static func refresh()
}
