import Foundation

// mimus: requirementsFor = "Foundation.ProgressReporting"
private protocol ProgressRequirements: NSObjectProtocol {
  var progress: Progress { get }
}
