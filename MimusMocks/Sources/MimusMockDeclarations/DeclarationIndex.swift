import Foundation
import MockGenerationSupport
import SwiftSyntax
import SwiftSyntaxBuilder

struct ConditionalContext {
  let group: String
  let branch: Int
  let prefix: String
}

func conditionalContexts(of node: some SyntaxProtocol, file: String) -> [ConditionalContext] {
  var result = [ConditionalContext]()
  var ancestor = node.parent
  while let current = ancestor {
    if let clause = current.as(IfConfigClauseSyntax.self),
      let group = current.parent?.parent?.as(IfConfigDeclSyntax.self),
      let index = Array(group.clauses).firstIndex(where: { $0.id == clause.id })
    {
      let prefix = group.clauses.prefix(index + 1).map {
        $0.poundKeyword.text + ($0.condition.map { " " + $0.trimmedDescription } ?? "")
      }.joined(separator: "\n")
      result.append(
        ConditionalContext(
          group: file + ":" + String(group.position.utf8Offset), branch: index, prefix: prefix))
    }
    ancestor = current.parent
  }
  return result.reversed()
}

func guarded(_ source: String, by contexts: [ConditionalContext]) -> String {
  contexts.reversed().reduce(source) { body, context in context.prefix + "\n" + body + "\n#endif" }
}

struct ProtocolEntry {
  let module: String
  let declaration: ProtocolDeclSyntax
  var namespace: [String] = []
  var conditions: [ConditionalContext] = []
  var enclosingPublic = true
  var accessible = true
  var name: String { declaration.name.text }
  var path: String { (namespace + [declaration.name.trimmedDescription]).joined(separator: ".") }
  var key: String { module + "." + path }
  var proxyName: String {
    (namespace + [name]).map { $0.replacingOccurrences(of: "`", with: "") }.joined(separator: "_")
  }
  var annotations: String { declaration.leadingTrivia.description }
  var requirementsFor: String? { annotation(annotations, named: "requirementsFor") }
  var isPublic: Bool {
    enclosingPublic && declaration.modifiers.contains { $0.name.text == "public" }
  }
  func isExclusive(with other: Self) -> Bool {
    conditions.contains { context in
      other.conditions.contains { $0.group == context.group && $0.branch != context.branch }
    }
  }
}

final class DeclarationIndex: SyntaxVisitor {
  let module: String
  let file: String
  var entries = [ProtocolEntry]()
  var imports = Set<String>()
  var message: String?

  init(module: String, file: String) {
    self.module = module
    self.file = file
    super.init(viewMode: .sourceAccurate)
  }

  override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
    imports.insert(guarded(node.trimmedDescription, by: conditionalContexts(of: node, file: file)))
    return .skipChildren
  }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    var entry = ProtocolEntry(module: module, declaration: node)
    entry.conditions = conditionalContexts(of: node, file: file)
    var ancestor = node.parent
    while let current = ancestor {
      func enclose(_ name: TokenSyntax, modifiers: DeclModifierListSyntax, generic: Bool) {
        entry.namespace.insert(name.trimmedDescription, at: 0)
        entry.enclosingPublic =
          entry.enclosingPublic && modifiers.contains { ["public", "open"].contains($0.name.text) }
        entry.accessible =
          entry.accessible
          && !modifiers.contains { ["private", "fileprivate"].contains($0.name.text) }
        if generic && isMarked(entry.annotations) {
          message =
            "A mockable protocol inside a generic namespace needs a concrete adapter: " + entry.key
        }
      }
      if let type = current.as(EnumDeclSyntax.self) {
        enclose(type.name, modifiers: type.modifiers, generic: type.genericParameterClause != nil)
      } else if let type = current.as(StructDeclSyntax.self) {
        enclose(type.name, modifiers: type.modifiers, generic: type.genericParameterClause != nil)
      } else if let type = current.as(ClassDeclSyntax.self) {
        enclose(type.name, modifiers: type.modifiers, generic: type.genericParameterClause != nil)
      } else if let type = current.as(ActorDeclSyntax.self) {
        enclose(type.name, modifiers: type.modifiers, generic: type.genericParameterClause != nil)
      } else if let ext = current.as(ExtensionDeclSyntax.self) {
        entry.namespace.insert(
          contentsOf: ext.extendedType.trimmedDescription.split(separator: ".").map(String.init),
          at: 0)
        if ext.genericWhereClause != nil && isMarked(entry.annotations) {
          message =
            "A mockable protocol inside a constrained extension needs a concrete adapter: "
            + entry.key
        }
      }
      ancestor = current.parent
    }
    entry.accessible =
      entry.accessible
      && !node.modifiers.contains { ["private", "fileprivate"].contains($0.name.text) }
    entries.append(entry)
    return .skipChildren
  }
}

final class QualifyProtocols: SyntaxRewriter {
  let module: String
  let namespace: [String]
  let entries: [ProtocolEntry]
  let boundNames: Set<String>
  init(module: String, namespace: [String], entries: [ProtocolEntry], boundNames: Set<String>) {
    self.module = module
    self.namespace = namespace
    self.entries = entries.filter { $0.requirementsFor == nil }
    self.boundNames = boundNames
    super.init(viewMode: .sourceAccurate)
  }

  override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    guard !boundNames.contains(node.name.text) else { return super.visit(node) }
    let candidates = entries.filter { $0.name == node.name.text }
    for depth in stride(from: namespace.count, through: 0, by: -1) {
      if let entry = candidates.first(where: {
        $0.module == module && $0.namespace == Array(namespace.prefix(depth))
      }) {
        return TypeSyntax(
          stringLiteral: entry.key + (node.genericArgumentClause?.trimmedDescription ?? ""))
      }
    }
    let keys = Set(candidates.map(\.key))
    if keys.count == 1, let entry = candidates.first {
      return TypeSyntax(
        stringLiteral: entry.key + (node.genericArgumentClause?.trimmedDescription ?? ""))
    }
    return super.visit(node)
  }

  override func visit(_ node: MemberTypeSyntax) -> TypeSyntax {
    let path = node.baseType.trimmedDescription + "." + node.name.text
    if let entry = entries.first(where: { $0.module == module && $0.path == path }) {
      return TypeSyntax(
        stringLiteral: entry.key + (node.genericArgumentClause?.trimmedDescription ?? ""))
    }
    return super.visit(node)
  }
}
