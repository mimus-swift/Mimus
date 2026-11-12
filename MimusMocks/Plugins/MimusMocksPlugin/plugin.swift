import Foundation
import PackagePlugin

private struct Configuration: Decodable {
  struct Settings: Decodable {
    let modules: [String]
    let includeInternal: Bool?
  }
  let targets: [String: Settings]
}

private struct InputManifest: Encodable {
  struct Input: Encodable {
    let module: String
    let path: String
  }
  let modules: [String]
  let inputs: [Input]
  let includeInternal: Bool
}

@main
struct MimusMocksPlugin: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    let excluded: Set<String> = ["Mimus", "MimusMocks", "MockableMacro"]
    func sourceTargets(_ dependencies: [TargetDependency]) -> [SourceModuleTarget] {
      dependencies.flatMap { dependency -> [SourceModuleTarget] in
        switch dependency {
        case .target(let target): return (target as? SourceModuleTarget).map { [$0] } ?? []
        case .product(let product): return product.targets.compactMap { $0 as? SourceModuleTarget }
        @unknown default: return []
        }
      }.filter { !excluded.contains($0.name) }
    }
    let configURL = context.package.directoryURL.appendingPathComponent(".mimus-mocks.json")
    let configData = try? Data(contentsOf: configURL)
    let settings = try configData.map { try JSONDecoder().decode(Configuration.self, from: $0) }
      .flatMap { $0.targets[target.name] }
    let selected = sourceTargets(target.dependencies).filter {
      settings?.modules.contains($0.name) ?? true
    }
    if let settings {
      let missing = Set(settings.modules).subtracting(selected.map(\.name))
      guard missing.isEmpty else {
        Diagnostics.error(
          "Configured mock modules are not source dependencies of \(target.name): \(missing.sorted().joined(separator: ", "))"
        )
        return []
      }
    }
    guard !selected.isEmpty else {
      Diagnostics.error(
        "MimusMocksPlugin needs a dependency on the production source target to mock")
      return []
    }
    var visited = Set<String>()
    var modules = [SourceModuleTarget]()
    func collect(_ source: SourceModuleTarget) {
      guard visited.insert(source.id).inserted else { return }
      modules.append(source)
      sourceTargets(source.dependencies).forEach(collect)
    }
    selected.forEach(collect)
    // Mocks-target source can declare overlays for SDK/binary-only protocols.
    if let source = target as? SourceModuleTarget { modules.append(source) }
    let output = context.pluginWorkDirectoryURL.appendingPathComponent("Mocks.generated.swift")
    let manifestURL = context.pluginWorkDirectoryURL.appendingPathComponent("Inputs.json")
    var files = [URL]()
    var inputs = [InputManifest.Input]()
    if configData != nil { files.append(configURL) }
    for module in modules.sorted(by: { $0.name < $1.name }) {
      for file in module.sourceFiles(withSuffix: ".swift").sorted(by: { $0.url.path < $1.url.path })
      {
        files.append(file.url)
        inputs.append(.init(module: module.name, path: file.url.path))
      }
    }
    let manifest = InputManifest(
      modules: selected.map(\.name).sorted(), inputs: inputs,
      includeInternal: settings?.includeInternal ?? target.name.hasSuffix("Tests")
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(manifest)
    try FileManager.default.createDirectory(
      at: context.pluginWorkDirectoryURL, withIntermediateDirectories: true)
    if (try? Data(contentsOf: manifestURL)) != data {
      try data.write(to: manifestURL, options: .atomic)
    }
    return [
      .buildCommand(
        displayName: "Preparing Mimus macro declarations for \(target.name)",
        executable: try context.tool(named: "MimusMockDeclarations").url,
        arguments: ["--manifest", manifestURL.path, "--output", output.path],
        inputFiles: files + [manifestURL],
        outputFiles: [output]
      )
    ]
  }
}
