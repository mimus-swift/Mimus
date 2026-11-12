import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MimusMocksPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    MockableMacro.self, MockDefaultMacro.self, MockPublisherMacro.self, MockCallControlMacro.self,
    MockOverrideMacro.self,
  ]
}
