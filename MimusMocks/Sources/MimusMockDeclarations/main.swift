import Foundation
import MockGenerationSupport
import SwiftParser
import SwiftSyntax

struct GenerationError: Error, CustomStringConvertible {
  let description: String
  init(_ description: String) { self.description = description }
}

func annotation(_ text: String, named name: String) -> String? {
  FixtureSyntax.annotation(text, named: name)
}

func isMarked(_ text: String) -> Bool {
  text.range(of: "(?:sourcery:\\s*automockable|mimus:\\s*mockable)", options: .regularExpression)
    != nil
}

let markers: Set<String> = ["AnyObject", "Sendable", "Actor", "Observable", "NSObjectProtocol"]
func canonical(_ type: String) -> String {
  type.replacingOccurrences(of: "Swift.", with: "").replacingOccurrences(
    of: "Observation.", with: "")
}

func memberKey(_ member: MemberBlockItemSyntax) -> String {
  if let method = member.decl.as(FunctionDeclSyntax.self) {
    return "method:" + method.name.text + method.signature.trimmedDescription
      + (method.genericParameterClause?.trimmedDescription ?? "")
  }
  if let variable = member.decl.as(VariableDeclSyntax.self) {
    return "property:"
      + variable.bindings.map { $0.pattern.trimmedDescription }.joined(separator: ",")
  }
  if let type = member.decl.as(AssociatedTypeDeclSyntax.self) {
    return "associated:" + type.name.text
  }
  if let alias = member.decl.as(TypeAliasDeclSyntax.self) { return "alias:" + alias.name.text }
  return member.decl.trimmedDescription
}

struct MemberSource {
  let module: String
  let namespace: [String]
  let syntax: MemberBlockItemSyntax
}

struct Flattened {
  var members: [MemberSource] = []
  var traits: Set<String> = []
  var baseClass: String?
}

func flattened(_ entry: ProtocolEntry, entries: [ProtocolEntry], visiting: Set<String> = []) throws
  -> Flattened
{
  guard !visiting.contains(entry.key) else {
    throw GenerationError("Protocol inheritance cycle at " + entry.key)
  }
  var result = Flattened()
  result.baseClass = annotation(entry.annotations, named: "mockBaseClass")
  for inherited in entry.declaration.inheritanceClause?.inheritedTypes ?? [] {
    let name = canonical(inherited.type.trimmedDescription)
    if markers.contains(name) {
      result.traits.insert(name)
      if name == "NSObjectProtocol", result.baseClass == nil { result.baseClass = "NSObject" }
      continue
    }
    if name == result.baseClass { continue }
    let candidates = entries.filter {
      !$0.isExclusive(with: entry)
        && ($0.key == name || $0.path == name || $0.name == name || $0.requirementsFor == name
          || $0.requirementsFor?.split(separator: ".").last.map(String.init) == name)
    }
    var scoped = [ProtocolEntry]()
    for depth in stride(from: entry.namespace.count, through: 0, by: -1) {
      scoped = candidates.filter {
        $0.module == entry.module && $0.namespace == Array(entry.namespace.prefix(depth))
      }
      if !scoped.isEmpty { break }
    }
    let local = scoped.isEmpty ? candidates.filter { $0.module == entry.module } : scoped
    let available = local.isEmpty ? candidates : local
    let matching = available.filter { parent in
      parent.conditions.allSatisfy { context in
        entry.conditions.contains { $0.prefix == context.prefix }
      }
    }
    let parents = matching.isEmpty ? available : matching
    guard parents.count == 1, let parent = parents.first else {
      throw GenerationError(
        "Cannot resolve inherited protocol '\(name)' for \(entry.key). Include its source module or supply a requirementsFor overlay; conditional parents must resolve unambiguously."
      )
    }
    let inherited = try flattened(parent, entries: entries, visiting: visiting.union([entry.key]))
    result.members += inherited.members
    result.traits.formUnion(inherited.traits)
    if result.baseClass == nil { result.baseClass = inherited.baseClass }
  }
  for member in entry.declaration.memberBlock.members {
    result.members.removeAll { memberKey($0.syntax) == memberKey(member) }
    result.members.append(
      MemberSource(module: entry.module, namespace: entry.namespace, syntax: member))
  }
  return result
}

func run() throws {
  struct Manifest: Decodable {
    struct Input: Decodable {
      let module: String
      let path: String
    }
    let modules: [String]
    let inputs: [Input]
    let includeInternal: Bool
  }
  var arguments = Array(CommandLine.arguments.dropFirst())
  var inputs = [(module: String, path: String)]()
  var selected = Set<String>()
  var output: String?
  var includeInternal = false
  while !arguments.isEmpty {
    let flag = arguments.removeFirst()
    if flag == "--include-internal" {
      includeInternal = true
      continue
    }
    guard !arguments.isEmpty else { throw GenerationError("Missing value for " + flag) }
    let value = arguments.removeFirst()
    switch flag {
    case "--manifest":
      let data = try Data(contentsOf: URL(fileURLWithPath: value))
      let manifest = try JSONDecoder().decode(Manifest.self, from: data)
      selected.formUnion(manifest.modules)
      inputs += manifest.inputs.map { ($0.module, $0.path) }
      includeInternal = manifest.includeInternal
    case "--input":
      guard let separator = value.firstIndex(of: "=") else {
        throw GenerationError("--input expects Module=/path/File.swift")
      }
      inputs.append((String(value[..<separator]), String(value[value.index(after: separator)...])))
    case "--module": selected.insert(value)
    case "--output": output = value
    default: throw GenerationError("Unknown option: " + flag)
    }
  }
  guard let output, !selected.isEmpty else {
    throw GenerationError(
      "Usage: mimus-mock-declarations --module Module --input Module=/path/File.swift --output /path/Mocks.generated.swift"
    )
  }
  var entries = [ProtocolEntry]()
  var imports = Set<String>()
  for input in inputs {
    let tree = Parser.parse(source: try String(contentsOfFile: input.path, encoding: .utf8))
    guard !tree.hasError else { throw GenerationError("Cannot parse " + input.path) }
    let index = DeclarationIndex(module: input.module, file: input.path)
    index.walk(tree)
    if let message = index.message { throw GenerationError(message) }
    entries += index.entries
    if selected.contains(input.module)
      || index.entries.contains(where: { $0.requirementsFor != nil })
    {
      imports.formUnion(index.imports)
    }
  }
  let eligible = entries.filter {
    selected.contains($0.module) && $0.accessible && ($0.isPublic || includeInternal)
      && $0.requirementsFor == nil
      && isMarked($0.annotations)
  }
  var rendered = [String]()
  var names = [String: [ProtocolEntry]]()
  let mockProtocols = Dictionary(
    eligible.map { ($0.key, "Mock" + $0.proxyName) }, uniquingKeysWith: { first, _ in first })
  for entry in eligible.sorted(by: { $0.key < $1.key }) {
    guard (names[entry.proxyName] ?? []).allSatisfy({ $0.isExclusive(with: entry) }) else {
      throw GenerationError(
        "Duplicate protocol name '\(entry.name)'. Use separate mocks targets for its modules.")
    }
    names[entry.proxyName, default: []].append(entry)
    let flat = try flattened(entry, entries: entries)
    let defaults = annotation(entry.annotations, named: "defaults")
    let stubbing = annotation(entry.annotations, named: "stubbing")
    guard stubbing == nil || stubbing == "simple" || stubbing == "argumentMatching" else {
      throw GenerationError("Mock stubbing must be 'simple' or 'argumentMatching' for " + entry.key)
    }
    guard defaults == nil || defaults == "none" || defaults == "fixtures" else {
      throw GenerationError("Mock defaults must be 'none' or 'fixtures' for " + entry.key)
    }
    let boundNames = Set(
      flat.members.compactMap { $0.syntax.decl.as(AssociatedTypeDeclSyntax.self)?.name.text })
    let members = try flat.members.map { member in
      let generics =
        member.syntax.decl.as(FunctionDeclSyntax.self)?.genericParameterClause?.parameters.map {
          $0.name.text
        } ?? []
      let rewriter = QualifyProtocols(
        module: member.module, namespace: member.namespace, entries: entries,
        boundNames: boundNames.union(generics))
      let rewritten = rewriter.rewrite(member.syntax)
      guard let item = rewritten.as(MemberBlockItemSyntax.self) else {
        throw GenerationError("Cannot prepare protocol member for " + entry.key)
      }
      if !item.decl.is(FunctionDeclSyntax.self),
        let attributed = item.decl.asProtocol(WithAttributesSyntax.self),
        try CallControlSyntax.isEnabled(
          attributes: attributed.attributes, trivia: item.decl.leadingTrivia)
      {
        throw GenerationError("Call control applies only to protocol methods")
      }
      if !item.decl.is(VariableDeclSyntax.self),
        let attributed = item.decl.asProtocol(WithAttributesSyntax.self),
        try PublisherSyntax.configuration(
          attributes: attributed.attributes, trivia: item.decl.leadingTrivia) != nil
      {
        throw GenerationError("Publisher helpers apply only to protocol properties")
      }
      func withDefault<D: DeclSyntaxProtocol & WithAttributesSyntax>(
        _ declaration: D, type: TypeSyntax, isGeneric: Bool = false
      ) throws -> String {
        var declaration = declaration
        let explicit = try FixtureSyntax.explicitDefault(
          attributes: declaration.attributes, trivia: declaration.leadingTrivia, type: type,
          mockProtocols: mockProtocols)
        let value =
          try explicit
          ?? (defaults == "fixtures" && !isGeneric
            ? FixtureSyntax.fixtureDefault(for: type, mockProtocols: mockProtocols) : nil)
        if let value,
          !declaration.attributes.contains(where: {
            $0.as(AttributeSyntax.self).map { FixtureSyntax.attributeName($0) == "MockDefault" }
              ?? false
          })
        {
          // Macro arguments are type-checked before generated peers are visible.
          // Keep the prepared expression in trivia until @Mockable emits its body.
          declaration.leadingTrivia =
            .lineComment(
              "// mimus: default = " + String(reflecting: value.trimmedDescription))
            + .newline + declaration.leadingTrivia
        }
        return declaration.description.trimmingCharacters(in: .whitespacesAndNewlines)
      }
      if let method = item.decl.as(FunctionDeclSyntax.self),
        let type = method.signature.returnClause?.type
      {
        return try withDefault(method, type: type, isGeneric: method.genericParameterClause != nil)
      }
      if let variable = item.decl.as(VariableDeclSyntax.self) {
        if try PublisherSyntax.configuration(
          attributes: variable.attributes, trivia: variable.leadingTrivia) != nil
        {
          try PublisherSyntax.validate(variable)
          return variable.description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if variable.bindings.count == 1, let type = variable.bindings.first?.typeAnnotation?.type {
          return try withDefault(variable, type: type)
        }
      }
      if let subscriptDecl = item.decl.as(SubscriptDeclSyntax.self) {
        return try withDefault(subscriptDecl, type: subscriptDecl.returnClause.type)
      }
      return item.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }.joined(separator: "\n")
    var options = [String]()
    if let base = flat.baseClass {
      options.append("baseClassName: " + String(reflecting: base))
    }
    if defaults == "fixtures" { options.append("defaults: .fixtures") }
    if stubbing == "argumentMatching" { options.append("stubbing: .argumentMatching") }
    if let excluded = annotation(entry.annotations, named: "excluding") {
      options.append(
        "excluding: ["
          + excluded.split(separator: ",").map {
            String(reflecting: $0.trimmingCharacters(in: .whitespaces))
          }.joined(separator: ", ") + "]")
    }
    options.append(contentsOf: [
      "publicMock: \(entry.isPublic)", "inheritedRequirementsAreDeclared: true",
    ])
    let attributes = entry.declaration.attributes.filter {
      $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription != "Mockable"
    }.trimmedDescription
    let traits = flat.traits.sorted().map { ", " + $0 }.joined()
    rendered.append(
      guarded(
        """
        \(attributes)
        @Mockable(\(options.joined(separator: ", ")))
        fileprivate protocol \(entry.proxyName): \(entry.key)\(traits) \(entry.declaration.genericWhereClause?.trimmedDescription ?? "") {
            \(members)
        }
        """, by: entry.conditions))
  }
  for module in selected {
    imports.insert((includeInternal ? "@testable " : "") + "import " + module)
  }
  imports.formUnion(["import Mimus", "import MimusMocks"])
  let source =
    "// Generated mock declarations; do not edit. Implementations are expanded by @Mockable.\n"
    + imports.sorted().joined(separator: "\n") + "\n\n" + rendered.joined(separator: "\n\n") + "\n"
  let url = URL(fileURLWithPath: output)
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  if (try? String(contentsOf: url, encoding: .utf8)) != source {
    try source.write(to: url, atomically: true, encoding: .utf8)
  }
  print("Prepared \(eligible.count) protocol declarations for Swift macro expansion")
}

do { try run() } catch {
  FileHandle.standardError.write(Data("error: \(error)\n".utf8))
  exit(1)
}
