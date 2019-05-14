Pod::Spec.new do |s|

  s.name         = "Mimus"
  s.version      = "1.1.2"
  s.summary      = "Swift Mocking Library"

  s.description  = <<-DESC
                   Mimus is a Swift mocking library, aiming to reduce boilerplate code required for building mocks in Swift.
                   It's been battle tested at AirHelp where we've used it extensively across our test suites.
                   DESC

  s.homepage     = "https://www.airhelp.com"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors = { "Pawel Dudek" => "pawel@dudek.mobi", "Paweł Kozielecki" => "pawel.kozielecki@airhelp.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"

  s.swift_versions = ['4.2', '5.0']

  s.source       = { :git => "https://github.com/airhelp/mimus.git", :tag => "#{s.version}" }
  s.source_files  = "Mimus/Source", "Mimus/Source/**/*.swift"
  s.framework  = "XCTest"
end
