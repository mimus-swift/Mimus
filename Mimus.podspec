Pod::Spec.new do |s|

  s.name         = "Mimus"
  s.version      = "2.0.1"
  s.summary      = "Swift Mocking Library"

  s.description  = <<-DESC
                   Mimus is a Swift mocking library, aiming to reduce boilerplate code required for building mocks in Swift.
                   DESC

  s.homepage     = "https://github.com/mimus-swift/Mimus"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors = { "Pawel Dudek" => "pawel@dudek.mobi", "Paweł Kozielecki" => "pawel.kozielecki@airhelp.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"

  s.swift_versions = ['4.2', '5.0']

  s.source       = { :git => "https://github.com/mimus-swift/mimus.git", :tag => "#{s.version}" }
  s.preserve_path = 'SourceryStencils/AutoMockable.stencil'
  s.source_files  = "Sources/Mimus", "Sources/Mimus/**/*.swift"
  s.framework  = "XCTest"
end
