import MockGenerationSupport
import SwiftSyntax
import SwiftSyntaxMacros

public struct MockCallControlMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(FunctionDeclSyntax.self),
      context.lexicalContext.contains(where: { $0.is(ProtocolDeclSyntax.self) })
    else { throw FixtureDiagnostic("@MockCallControl applies to a protocol method") }
    return []
  }
}
