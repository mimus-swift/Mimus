import MockGenerationSupport
import SwiftSyntax
import SwiftSyntaxMacros

/// Marker consumed by @Mockable; it emits no members into the source protocol.
public struct MockDefaultMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      declaration.is(VariableDeclSyntax.self) || declaration.is(FunctionDeclSyntax.self)
        || declaration.is(SubscriptDeclSyntax.self)
    else { throw FixtureDiagnostic("@MockDefault applies to a property, method, or subscript") }
    guard context.lexicalContext.contains(where: { $0.is(ProtocolDeclSyntax.self) }) else {
      throw FixtureDiagnostic("@MockDefault must be used on a protocol requirement")
    }
    return []
  }
}
