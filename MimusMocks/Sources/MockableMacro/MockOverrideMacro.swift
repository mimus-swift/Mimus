import MockGenerationSupport
import SwiftSyntax
import SwiftSyntaxMacros

public struct MockOverrideMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      declaration.is(FunctionDeclSyntax.self) || declaration.is(VariableDeclSyntax.self)
        || declaration.is(SubscriptDeclSyntax.self),
      context.lexicalContext.contains(where: { $0.is(ProtocolDeclSyntax.self) })
    else {
      throw FixtureDiagnostic("@MockOverride applies to a protocol method, property, or subscript")
    }
    return []
  }
}
