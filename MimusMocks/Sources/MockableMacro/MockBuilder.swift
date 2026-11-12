import Foundation
import MockGenerationSupport
import SwiftSyntax
import SwiftSyntaxBuilder

struct MockBuilder {
  let declaration: ProtocolDeclSyntax
  let baseClassName: String?
  let access: String
  let isActor: Bool
  let isSendable: Bool
  let isObservable: Bool
  let methods: [FunctionDeclSyntax]
  let associatedTypes: [AssociatedTypeDeclSyntax]
  let fixtureDefaults: Bool

  init(
    _ declaration: ProtocolDeclSyntax, baseClassName: String?, excluding: Set<String> = [],
    publicMock: Bool = false, inheritedRequirementsAreDeclared: Bool = false,
    fixtureDefaults: Bool = false
  ) throws {
    self.declaration = declaration
    self.baseClassName = baseClassName
    self.fixtureDefaults = fixtureDefaults
    access =
      publicMock || declaration.modifiers.contains { $0.name.text == "public" } ? "public " : ""
    let inherited =
      declaration.inheritanceClause?.inheritedTypes.map {
        $0.type.trimmedDescription.replacingOccurrences(of: "Swift.", with: "")
          .replacingOccurrences(of: "Observation.", with: "")
      } ?? []
    isActor = inherited.contains("Actor")
    isSendable = isActor || inherited.contains("Sendable")
    isObservable = inherited.contains("Observable")
    let allowed: Set<String> = ["AnyObject", "Sendable", "Actor", "Observable"]
    for name in inherited where !allowed.contains(name) {
      if inheritedRequirementsAreDeclared { continue }
      if name == "NSObjectProtocol", baseClassName == "NSObject" { continue }
      throw MockableDiagnostic(
        "@Mockable cannot inspect inherited requirements of '\(name)'. Flatten the protocol into a mocks target before applying the macro."
      )
    }
    let declaredMethods = declaration.memberBlock.members.compactMap {
      $0.decl.as(FunctionDeclSyntax.self)
    }
    for excluded in excluding where !declaredMethods.contains(where: { $0.name.text == excluded }) {
      throw MockableDiagnostic("No method named '\(excluded)' exists in this protocol")
    }
    for method in declaredMethods
    where !method.name.text.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) {
      throw MockableDiagnostic("Operator requirements need a custom mock implementation")
    }
    methods =
      declaredMethods
      .filter { !excluding.contains($0.name.text) }
    associatedTypes = declaration.memberBlock.members.compactMap {
      $0.decl.as(AssociatedTypeDeclSyntax.self)
    }
    for member in declaration.memberBlock.members {
      if !member.decl.is(VariableDeclSyntax.self),
        let attributed = member.decl.asProtocol(WithAttributesSyntax.self),
        try PublisherSyntax.configuration(
          attributes: attributed.attributes, trivia: member.decl.leadingTrivia) != nil
      {
        throw MockableDiagnostic("@MockPublisher applies to a protocol property")
      }
      guard
        member.decl.is(FunctionDeclSyntax.self) || member.decl.is(VariableDeclSyntax.self)
          || member.decl.is(AssociatedTypeDeclSyntax.self)
          || member.decl.is(SubscriptDeclSyntax.self)
          || member.decl.is(InitializerDeclSyntax.self) || member.decl.is(TypeAliasDeclSyntax.self)
      else {
        throw MockableDiagnostic("Unsupported protocol member: \(member.decl.trimmedDescription)")
      }
    }
  }

  func build() throws -> DeclSyntax {
    let name = "Mock" + declaration.name.text
    let genericTypes = associatedTypes.filter { $0.initializer == nil }
    let genericClause =
      genericTypes.isEmpty
      ? ""
      : "<"
        + genericTypes.map {
          "_" + $0.name.text
            + ($0.inheritanceClause.map { ": " + $0.inheritedTypes.trimmedDescription } ?? "")
        }.joined(separator: ", ") + ">"
    let hasStatics =
      methods.contains(where: isStatic)
      || declaration.memberBlock.members.contains {
        $0.decl.as(VariableDeclSyntax.self)?.modifiers.contains { $0.name.text == "static" } == true
      }
    if !genericTypes.isEmpty && hasStatics {
      throw MockableDiagnostic(
        "Static requirements combined with generic associated types need a concrete flattened protocol"
      )
    }
    let aliases = associatedTypes.map {
      "\(access)typealias \($0.name.text) = \($0.initializer?.value.trimmedDescription ?? "_" + $0.name.text)"
    }.joined(separator: "\n")
    let globalAttributes = declaration.attributes.filter {
      guard let attribute = $0.as(AttributeSyntax.self) else { return false }
      return FixtureSyntax.attributeName(attribute) != "Mockable"
    }.map(\.trimmedDescription).joined(separator: "\n")
    let visibility =
      access.isEmpty && declaration.modifiers.contains { $0.name.text == "private" }
      ? "private " : access
    let superclass = baseClassName.map { $0 + ", " } ?? ""
    let isolation = isActor ? "nonisolated " : ""
    var members = [String]()
    var instanceVerifications = [String]()
    var staticVerifications = [String]()
    for method in methods {
      let overloaded = methods.filter { selector($0) == selector(method) }.count > 1
      let generated = try generate(method, overloaded: overloaded)
      members.append(generated.members)
      if isStatic(method) {
        staticVerifications.append(generated.verification)
      } else {
        instanceVerifications.append(generated.verification)
      }
    }
    for member in declaration.memberBlock.members {
      if let variable = member.decl.as(VariableDeclSyntax.self) {
        members.append(try property(variable))
      }
      if let subscriptDecl = member.decl.as(SubscriptDeclSyntax.self) {
        members.append(try subscriptMember(subscriptDecl))
      }
      if let alias = member.decl.as(TypeAliasDeclSyntax.self) {
        members.append(access + alias.trimmedDescription)
      }
      if let initializer = member.decl.as(InitializerDeclSyntax.self) {
        var witness = initializer
        witness.modifiers = DeclModifierListSyntax([
          DeclModifierSyntax(name: .keyword(access.isEmpty ? .internal : .public))
        ])
        let args = initializer.signature.parameterClause.parameters.map { capture($0) }.joined(
          separator: ", ")
        witness.body = CodeBlockSyntax(
          stringLiteral:
            "{ recordCall(withIdentifier: \(quoted(initializer.trimmedDescription)), arguments: [\(args)]) }"
        )
        members.append(witness.formatted().trimmedDescription)
      }
    }
    let hasDefaultInit = declaration.memberBlock.members.contains {
      $0.decl.as(InitializerDeclSyntax.self)?.signature.parameterClause.parameters.isEmpty == true
    }
    let initializer: String
    if hasDefaultInit {
      initializer = ""
    } else if baseClassName == "UIViewController" {
      initializer =
        "\(access)init() { super.init(nibName: nil, bundle: nil) }\nrequired init?(coder: NSCoder) { fatalError(\"Use init()\") }"
    } else {
      initializer = "\(access)\(baseClassName == nil ? "" : "override ")init() {}"
    }
    let constraints =
      ([declaration.genericWhereClause].compactMap { $0 }
      + associatedTypes.compactMap { $0.genericWhereClause })
      .flatMap { $0.requirements.map { $0.requirement.trimmedDescription } }
    var whereClause = constraints.isEmpty ? "" : "where " + constraints.joined(separator: ", ")
    for type in genericTypes {
      whereClause = whereClause.replacingOccurrences(
        of: "Self." + type.name.text, with: "_" + type.name.text)
      whereClause = whereClause.replacingOccurrences(
        of: "(?<![.\\w])\(type.name.text)\\b", with: "_" + type.name.text,
        options: .regularExpression)
    }
    let source = """
      \(globalAttributes)
      \(visibility)\(isActor ? "actor" : "final class") \(name)\(genericClause): \(superclass)\(declaration.name), Mimus.Mock \(whereClause) {
          \(aliases)
          \(access)let storage = Mimus.Storage()
          private let _mimusState = MimusMocks.MockState()
          \(isObservable ? "private let _mimusRegistrar = Observation.ObservationRegistrar()" : "")
          \(hasStatics ? """
            private static var _mimusStaticState: MimusMocks.MockState { StaticState.state }
            private enum StaticState {
                static let state = MimusMocks.MockState()
                static let recorder = StaticRecorder()
            }
            private final class StaticRecorder: Mimus.Mock, Sendable {
                let storage = Mimus.Storage()
            }
            \(access)static func resetMock() { StaticState.recorder.storage.reset(); StaticState.state.reset() }
            """ : "")
          \(initializer)
          \(access)\(isolation)func resetMock() { storage.reset(); _mimusState.reset() }
          \(members.joined(separator: "\n"))
          \(access)\(isolation)func verify(mode: Mimus.VerificationMode = .times(1), file: StaticString = #filePath,
              fileId: StaticString = #fileID, line: UInt = #line, column: UInt = #column) -> Verifier {
              Verifier(mock: self, mode: mode, file: file, fileId: fileId, line: line, column: column)
          }
          \(access)struct Verifier {
              let mock: any Mimus.Mock
              let mode: Mimus.VerificationMode
              let file: StaticString
              let fileId: StaticString
              let line: UInt
              let column: UInt
              \(instanceVerifications.joined(separator: "\n"))
          }
          \(staticVerifications.isEmpty ? "" : """
            \(access)static func verify(mode: Mimus.VerificationMode = .times(1), file: StaticString = #filePath,
                fileId: StaticString = #fileID, line: UInt = #line, column: UInt = #column) -> StaticVerifier {
                StaticVerifier(mock: StaticState.recorder, mode: mode, file: file, fileId: fileId, line: line, column: column)
            }
            \(access)struct StaticVerifier {
                let mock: any Mimus.Mock
                let mode: Mimus.VerificationMode
                let file: StaticString
                let fileId: StaticString
                let line: UInt
                let column: UInt
                \(staticVerifications.joined(separator: "\n"))
            }
            """)
      }
      """
    return DeclSyntax(stringLiteral: source)
  }

  private func generate(
    _ originalMethod: FunctionDeclSyntax, overloaded: Bool, defaultExpression: ExprSyntax? = nil
  ) throws -> (
    members: String, verification: String
  ) {
    var method = originalMethod
    method.signature.parameterClause.parameters = FunctionParameterListSyntax(
      method.signature.parameterClause.parameters.enumerated().map { index, parameter in
        var result = parameter
        if parameter.firstName.text == "_", parameter.secondName == nil {
          result.secondName = .identifier("_argument\(index)")
        }
        return result
      }
    )
    let parameters = Array(method.signature.parameterClause.parameters)
    let returnType = method.signature.returnClause?.type.trimmedDescription ?? "Void"
    let returnsVoid = returnType == "Void" || returnType == "Swift.Void" || returnType == "()"
    let generics = method.genericParameterClause?.parameters.map { $0.name.text } ?? []
    let isGeneric = !generics.isEmpty
    let explicitDefault = try FixtureSyntax.explicitDefault(
      attributes: method.attributes, trivia: method.leadingTrivia,
      type: method.signature.returnClause?.type ?? TypeSyntax(stringLiteral: "Void"))
    if returnsVoid && explicitDefault != nil {
      throw MockableDiagnostic("Void requirements do not accept a mock default")
    }
    if isGeneric && explicitDefault != nil {
      throw MockableDiagnostic("Generic methods require explicit stubs instead of @MockDefault")
    }
    let fallback =
      try defaultExpression ?? explicitDefault
      ?? (!returnsVoid && !isGeneric && fixtureDefaults
        ? FixtureSyntax.fixtureDefault(for: method.signature.returnClause!.type) : nil)
    let staticPrefix = isStatic(method) ? "static " : ""
    let isolation = isActor ? "nonisolated " : ""
    let state = isStatic(method) ? "Self._mimusStaticState" : "_mimusState"
    let identifier =
      method.name.text + method.signature.trimmedDescription
      + (method.genericParameterClause?.trimmedDescription ?? "")
      + (method.genericWhereClause?.trimmedDescription ?? "")
    let id = quoted(identifier)
    let key =
      isGeneric
      ? id + generics.map { " + \"|\($0):\" + String(reflecting: \($0).self)" }.joined() : id
    let stem =
      upper(method.name.text)
      + parameters.map { $0.firstName.text == "_" ? "" : upper($0.firstName.text) }.joined()
      + (overloaded
        ? parameters.map { typeIdentifier(valueType($0)) }.joined() + "Returning"
          + typeIdentifier(returnType) : "")
    let throwsClause = method.signature.effectSpecifiers?.throwsClause
    let rethrowsMethod = throwsClause?.throwsSpecifier.text == "rethrows"
    let throwing = throwsClause != nil && !rethrowsMethod
    let errorType = throwsClause?.type?.trimmedDescription ?? "any Error"
    let asyncMethod = method.signature.effectSpecifiers?.asyncSpecifier != nil
    let typedThrows = throwing && throwsClause?.type != nil
    let handlerEffect = (asyncMethod ? " async" : "") + (throwing && !typedThrows ? " throws" : "")
    let handlerResult = typedThrows ? "Result<\(returnType), \(errorType)>" : returnType
    let handlerType =
      "\(isSendable ? "@Sendable " : "")(\(parameters.map(handlerParameterType).joined(separator: ", ")))\(handlerEffect) -> \(handlerResult)"
    var stubs = [String]()
    if !isGeneric {
      stubs.append(
        """
        \(access)\(isolation)\(staticPrefix)var simulated\(stem)Handler: (\(handlerType))? {
            get { \(state).value(for: \(id) + ".handler") }
            set { \(state).setOptional(newValue, for: \(id) + ".handler") }
        }
        """)
      if !returnsVoid {
        stubs.append(
          stubProperty(
            "simulated" + stem, type: returnType, key: id, state: state,
            prefix: isolation + staticPrefix, defaultExpression: fallback))
      }
      if throwing {
        stubs.append(
          stubProperty(
            "simulated" + stem + "Error", type: "(" + errorType + ")?", key: id + " + \".error\"",
            state: state, prefix: isolation + staticPrefix))
      }
    } else if !returnsVoid {
      let typeParameters = generics.map { "for type\($0): \($0).Type = \($0).self" }.joined(
        separator: ", ")
      stubs.append(
        """
        \(access)\(isolation)\(staticPrefix)func stub\(stem)\(method.genericParameterClause!.trimmedDescription)(_ value: \(returnType), \(typeParameters)) \(method.genericWhereClause?.trimmedDescription ?? "") {
            \(state).set(value, for: \(key))
        }
        """)
    }
    let capturePrelude = parameters.filter(isAutoclosure).map {
      "let _captured_\(local($0)) = \(local($0))()"
    }.joined(separator: "\n")
    let arguments = parameters.map(capture).joined(separator: ", ")
    let record = isStatic(method) ? "StaticState.recorder.recordCall" : "recordCall"
    let handlerArguments = parameters.map {
      isAutoclosure($0)
        ? "_captured_" + local($0)
        : ($0.type.is(SomeOrAnyTypeSyntax.self) ? local($0) : (isInout($0) ? "&" : "") + local($0))
    }.joined(separator: ", ")
    let handlerCall =
      "\(throwing && !typedThrows ? "try " : "")\(asyncMethod ? "await " : "")handler(\(handlerArguments))"
    let handlerBody =
      typedThrows
      ? "switch \(handlerCall) { case .success(let value): return value; case .failure(let error): throw error }"
      : "\(returnsVoid ? "" : "return ")\(handlerCall)\(returnsVoid ? "; return" : "")"
    let useHandler = isGeneric ? "" : "if let handler = simulated\(stem)Handler { \(handlerBody) }"
    let useError =
      throwing
      ? "if let error: \(errorType) = \(state).value(for: \(key) + \".error\") { throw error }" : ""
    let result =
      returnsVoid
      ? ""
      : fallback.map {
        "return \(state).value(for: \(key), as: (\(returnType)).self, default: { \($0.trimmedDescription) })"
      }
        ?? "return \(state).\(isOptional(returnType) ? "value" : "require")(for: \(key), as: (\(returnType)).self)\(isOptional(returnType) ? " ?? nil" : "")"
    var witness = method
    witness.attributes = method.attributes.filter {
      guard let attribute = $0.as(AttributeSyntax.self) else { return true }
      return !["Mockable", "MockDefault"].contains(FixtureSyntax.attributeName(attribute))
    }
    witness.modifiers = method.modifiers.filter {
      !["mutating", "nonmutating", "optional"].contains($0.name.text)
    }
    if !access.isEmpty {
      witness.modifiers.insert(
        DeclModifierSyntax(name: .keyword(.public)), at: witness.modifiers.startIndex)
    }
    if rethrowsMethod { witness.signature.effectSpecifiers?.throwsClause = nil }
    witness.body = CodeBlockSyntax(
      stringLiteral:
        "{\n\(capturePrelude)\n\(record)(withIdentifier: \(id), arguments: [\(arguments)])\n\(useHandler)\n\(useError)\n\(result)\n}"
    )
    let typed = overloaded || isGeneric
    var verifierParameters = parameters.map { parameter -> String in
      let label = parameter.firstName.trimmedDescription
      let name = local(parameter)
      let labelAndName = label == name ? name : label + " " + name
      return labelAndName + ": "
        + (typed ? "MimusMocks.Argument<\(valueType(parameter))>" : "(any Mimus.Matcher)?")
    }
    let usedGenericTypes = parameters.map(valueType).joined(separator: " ")
    if isGeneric && generics.contains(where: { !usedGenericTypes.contains($0) })
      || (overloaded
        && methods.filter {
          selector($0) == selector(method) && parameterTypes($0) == parameterTypes(method)
        }.count > 1)
    {
      verifierParameters.append("returning: (\(returnType)).Type")
    }
    let matcherArguments = parameters.map {
      typed ? "Mimus.ClosureMatcher<\(valueType($0))> { \(local($0)).matches($0) }" : local($0)
    }.joined(separator: ", ")
    let verification = """
      \(access)func \(method.name)\(method.genericParameterClause?.trimmedDescription ?? "")(\(verifierParameters.joined(separator: ", "))) \(method.genericWhereClause?.trimmedDescription ?? "") {
          mock.verifyCall(withIdentifier: \(id), arguments: [\(matcherArguments)], mode: mode, file: file, fileId: fileId, line: line, column: column)
      }
      """
    return (
      (stubs + [witness.formatted().trimmedDescription]).joined(separator: "\n"), verification
    )
  }

  private func property(_ variable: VariableDeclSyntax) throws -> String {
    if let publisher = try PublisherSyntax.configuration(
      attributes: variable.attributes, trivia: variable.leadingTrivia)
    {
      return try publisherProperty(variable, configuration: publisher)
    }
    let prefix = variable.modifiers.contains { $0.name.text == "static" } ? "static " : ""
    let state = prefix.isEmpty ? "_mimusState" : "Self._mimusStaticState"
    var result = [String]()
    for binding in variable.bindings {
      guard
        let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmedDescription,
        let type = binding.typeAnnotation?.type.trimmedDescription
      else {
        throw MockableDiagnostic("Mocked properties require a name and an explicit type")
      }
      let key = quoted("property:" + name)
      let fixture = try requirementDefault(
        type: binding.typeAnnotation!.type, attributes: variable.attributes,
        trivia: variable.leadingTrivia)
      var accessors: [AccessorDeclSyntax] = []
      if case .accessors(let items) = binding.accessorBlock?.accessors { accessors = Array(items) }
      let getter = accessors.first { $0.accessorSpecifier.text == "get" }
      let effects = getter?.effectSpecifiers?.trimmedDescription ?? ""
      if !effects.isEmpty {
        let fake = try FunctionDeclSyntax(
          "\(raw: prefix)func _get\(raw: upper(name))() \(raw: effects) -> \(raw: type)")
        let generated = try generate(fake, overloaded: false, defaultExpression: fixture)
        result.append(generated.members)
        result.append(
          "\(access)\(prefix)var \(name): \(type) { get \(effects) { return \(effects.contains("throws") ? "try " : "")\(effects.contains("async") ? "await " : "")_get\(upper(name))() } }"
        )
      } else {
        let fallback =
          fixture.map {
            "value(for: \(key), as: (\(type)).self, default: { \($0.trimmedDescription) })"
          }
          ?? defaultValue(type).map { "value(for: \(key), as: (\(type)).self) ?? \($0)" }
          ?? "require(for: \(key), as: (\(type)).self)"
        result.append(
          """
          \(access)\(isActor ? "nonisolated " : "")\(prefix)var \(name): \(type) {
              get {
                  \(isObservable && prefix.isEmpty ? "_mimusRegistrar.access(self, keyPath: \\." + name + ")" : "")
                  return \(state).\(fallback)
              }
              set {
                  \(isObservable && prefix.isEmpty ? "_mimusRegistrar.withMutation(of: self, keyPath: \\." + name + ") {" : "")
                  \(state).set(newValue, for: \(key))
                  \(isObservable && prefix.isEmpty ? "}" : "")
              }
          }
          """)
      }
    }
    return result.joined(separator: "\n")
  }

  private func publisherProperty(
    _ variable: VariableDeclSyntax, configuration: PublisherConfiguration
  ) throws -> String {
    try PublisherSyntax.validate(variable)
    let binding = variable.bindings.first!
    let name = binding.pattern.as(IdentifierPatternSyntax.self)!.identifier.trimmedDescription
    let subjectName = name.replacingOccurrences(of: "`", with: "") + "Subject"
    let conflicts = declaration.memberBlock.members.contains { member in
      if let property = member.decl.as(VariableDeclSyntax.self) {
        return property.bindings.contains {
          $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            .replacingOccurrences(of: "`", with: "") == subjectName
        }
      }
      return member.decl.as(FunctionDeclSyntax.self)?.name.text == subjectName
    }
    guard !conflicts else {
      throw MockableDiagnostic(
        "Generated subject '\(subjectName)' conflicts with another requirement")
    }
    let type = binding.typeAnnotation!.type
    let types = try PublisherSyntax.types(for: type)
    let subject: String
    let initializer: String
    switch configuration {
    case .passthrough:
      subject = "Combine.PassthroughSubject<\(types.output), \(types.failure)>"
      initializer = "\(subject)()"
    case .currentValue(let value):
      subject = "Combine.CurrentValueSubject<\(types.output), \(types.failure)>"
      initializer = "\(subject)(\(value.trimmedDescription))"
    }
    let prefix = variable.modifiers.contains { $0.name.text == "static" } ? "static " : ""
    let isolation =
      variable.modifiers.contains { $0.name.text == "nonisolated" } ? "nonisolated " : ""
    let state = prefix.isEmpty ? "_mimusState" : "Self._mimusStaticState"
    let subjectKey = quoted("publisher:" + name)
    let propertyKey = quoted("property:" + name)
    let attributes = variable.attributes.filter {
      $0.as(AttributeSyntax.self).map {
        !["MockPublisher", "MockDefault"].contains(FixtureSyntax.attributeName($0))
      } ?? true
    }.trimmedDescription
    return """
      \(attributes)
      \(access)\(isolation)\(prefix)var \(subjectName): \(subject) {
          \(state).value(for: \(subjectKey), as: (\(subject)).self, default: { \(initializer) })
      }
      \(attributes)
      \(access)\(isolation)\(prefix)var \(name): \(type) {
          get {
              \(isObservable && prefix.isEmpty ? "_mimusRegistrar.access(self, keyPath: \\." + name + ")" : "")
              return \(state).value(for: \(propertyKey), as: (\(type)).self, default: { \(subjectName).eraseToAnyPublisher() })
          }
          set {
              \(isObservable && prefix.isEmpty ? "_mimusRegistrar.withMutation(of: self, keyPath: \\." + name + ") {" : "")
              \(state).set(newValue, for: \(propertyKey))
              \(isObservable && prefix.isEmpty ? "}" : "")
          }
      }
      """
  }

  private func subscriptMember(_ subscriptDecl: SubscriptDeclSyntax) throws -> String {
    let parameters = subscriptDecl.parameterClause.parameters
    let arguments = parameters.map { parameter -> String in
      let label = parameter.firstName.text
      return (label == "_" ? "" : label + ": ") + local(parameter)
    }.joined(separator: ", ")
    var accessors: [AccessorDeclSyntax] = []
    if case .accessors(let items) = subscriptDecl.accessorBlock?.accessors {
      accessors = Array(items)
    }
    let getter = accessors.first { $0.accessorSpecifier.text == "get" }
    let effects = getter?.effectSpecifiers?.trimmedDescription ?? ""
    let stem = "subscript" + parameters.map { typeIdentifier(valueType($0)) }.joined()
    let fake = try FunctionDeclSyntax(
      "func \(raw: stem)\(raw: subscriptDecl.parameterClause.trimmedDescription) \(raw: effects) \(raw: subscriptDecl.returnClause.trimmedDescription)"
    )
    let fixture = try requirementDefault(
      type: subscriptDecl.returnClause.type, attributes: subscriptDecl.attributes,
      trivia: subscriptDecl.leadingTrivia)
    let generated = try generate(fake, overloaded: false, defaultExpression: fixture)
    var signature = subscriptDecl
    signature.accessorBlock = nil
    signature.attributes = signature.attributes.filter {
      $0.as(AttributeSyntax.self).map { FixtureSyntax.attributeName($0) != "MockDefault" } ?? true
    }
    signature.modifiers = access.isEmpty ? [] : [DeclModifierSyntax(name: .keyword(.public))]
    let setter =
      accessors.contains { $0.accessorSpecifier.text == "set" }
      ? "set { _mimusState.set(newValue, for: \(quoted(fake.name.text + fake.signature.trimmedDescription))) }"
      : ""
    return generated.members + "\n" + signature.trimmedDescription
      + " { get \(effects) { return \(effects.contains("throws") ? "try " : "")\(effects.contains("async") ? "await " : "")\(stem)(\(arguments)) } \(setter) }"
  }

  private func stubProperty(
    _ name: String, type: String, key: String, state: String, prefix: String,
    defaultExpression: ExprSyntax? = nil
  ) -> String {
    let optional = isOptional(type)
    return """
      \(access)\(prefix)var \(name): \(optional ? type : "(\(type))!") {
          get { \(defaultExpression.map { "\(state).value(for: \(key), as: (\(type)).self, default: { \($0.trimmedDescription) })" } ?? "\(state).value(for: \(key))\(optional ? " ?? nil" : "")") }
          set { \(state).\(optional ? "set" : "setOptional")(newValue, for: \(key)) }
      }
      """
  }

  private func requirementDefault(
    type: TypeSyntax, attributes: AttributeListSyntax, trivia: Trivia
  ) throws -> ExprSyntax? {
    try FixtureSyntax.explicitDefault(attributes: attributes, trivia: trivia, type: type)
      ?? (fixtureDefaults ? FixtureSyntax.fixtureDefault(for: type) : nil)
  }

  private func selector(_ method: FunctionDeclSyntax) -> String {
    method.name.text
      + method.signature.parameterClause.parameters.map { $0.firstName.text + ":" }.joined()
  }
  private func parameterTypes(_ method: FunctionDeclSyntax) -> String {
    method.signature.parameterClause.parameters.map(valueType).joined(separator: ",")
  }
  private func isStatic(_ method: FunctionDeclSyntax) -> Bool {
    method.modifiers.contains { $0.name.text == "static" || $0.name.text == "class" }
  }
  private func local(_ parameter: FunctionParameterSyntax) -> String {
    (parameter.secondName ?? parameter.firstName).trimmedDescription
  }
  private func isInout(_ parameter: FunctionParameterSyntax) -> Bool {
    parameter.type.trimmedDescription.hasPrefix("inout ")
  }
  private func attributes(_ parameter: FunctionParameterSyntax) -> [String] {
    parameter.type.as(AttributedTypeSyntax.self)?.attributes.compactMap {
      $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription
    } ?? []
  }
  private func unwrapped(_ type: TypeSyntax) -> TypeSyntax {
    if let attributed = type.as(AttributedTypeSyntax.self) { return unwrapped(attributed.baseType) }
    if let tuple = type.as(TupleTypeSyntax.self), tuple.elements.count == 1,
      let element = tuple.elements.first, element.firstName == nil
    {
      return unwrapped(element.type)
    }
    return type
  }
  private func isAutoclosure(_ parameter: FunctionParameterSyntax) -> Bool {
    attributes(parameter).contains("autoclosure")
  }
  private func isNonEscaping(_ parameter: FunctionParameterSyntax) -> Bool {
    unwrapped(parameter.type).is(FunctionTypeSyntax.self)
      && !attributes(parameter).contains("escaping") && !isAutoclosure(parameter)
  }
  private func valueType(_ parameter: FunctionParameterSyntax) -> String {
    var type = parameter.type
    if var attributed = type.as(AttributedTypeSyntax.self) {
      attributed.specifiers = []
      attributed.attributes = attributed.attributes.filter {
        guard let attribute = $0.as(AttributeSyntax.self) else { return true }
        return !["escaping", "autoclosure"].contains(attribute.attributeName.trimmedDescription)
      }
      type = attributed.attributes.isEmpty ? attributed.baseType : TypeSyntax(attributed)
    }
    if isAutoclosure(parameter), let function = unwrapped(type).as(FunctionTypeSyntax.self) {
      type = function.returnClause.type
    }
    let value = type.trimmedDescription
    return parameter.ellipsis == nil ? value : "[\(value)]"
  }
  private func handlerParameterType(_ parameter: FunctionParameterSyntax) -> String {
    (isInout(parameter) ? "inout " : "") + valueType(parameter)
  }
  private func capture(_ parameter: FunctionParameterSyntax) -> String {
    if isAutoclosure(parameter) { return "_captured_" + local(parameter) }
    if isNonEscaping(parameter) { return "MimusMocks.NonEscapingArgument()" }
    return local(parameter)
  }
  private func isOptional(_ type: String) -> Bool {
    type.hasSuffix("?") || type.hasPrefix("Optional<")
  }
  private func defaultValue(_ type: String) -> String? {
    if isOptional(type) { return "nil" }
    if type.hasPrefix("[") { return type.contains(":") ? "[:]" : "[]" }
    if type == "Bool" { return "false" }
    if type == "String" { return "\"\"" }
    if ["Int", "UInt", "Double", "Float", "Int32", "Int64", "UInt32", "UInt64"].contains(type) {
      return "0"
    }
    return nil
  }
  private func typeIdentifier(_ type: String) -> String {
    if type.hasSuffix("?") { return "Optional" + typeIdentifier(String(type.dropLast())) }
    return type.split { !$0.isLetter && !$0.isNumber }.map { upper(String($0)) }.joined()
  }
  private func upper(_ value: String) -> String { value.prefix(1).uppercased() + value.dropFirst() }
  private func quoted(_ value: String) -> String { String(reflecting: value) }
  private func hash(_ value: String) -> String {
    let hash = value.utf8.reduce(UInt32(2_166_136_261)) { ($0 ^ UInt32($1)) &* 16_777_619 }
    return String(hash, radix: 16)
  }
}
