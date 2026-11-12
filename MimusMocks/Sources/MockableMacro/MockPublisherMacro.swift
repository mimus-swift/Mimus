import MockGenerationSupport
import SwiftSyntax
import SwiftSyntaxMacros

/// Marker consumed by @Mockable; no subject is added to the source protocol.
public struct MockPublisherMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(VariableDeclSyntax.self),
      context.lexicalContext.contains(where: { $0.is(ProtocolDeclSyntax.self) })
    else { throw FixtureDiagnostic("@MockPublisher applies to a protocol property") }
    return []
  }
}
