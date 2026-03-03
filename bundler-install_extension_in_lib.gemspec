# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "bundler-install_extension_in_lib"
  spec.version = "0.1.0"
  spec.author = "Shopify Engineering"
  spec.email = "gems@shopify.com"
  spec.summary = "Bundler plugin to copy compiled extensions into gem lib/ directories"
  spec.description = "Per-gem control over copying native extension shared libraries " \
                      "(.so/.bundle) into the gem's lib/ directory after installation. " \
                      "Useful for old/unmaintained gems that expect extensions in lib/."
  spec.homepage = "https://github.com/Shopify/bundler-install_extension_in_lib"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir["lib/bundler-install_extension_in_lib.rb", "plugins.rb", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = "https://github.com/Shopify/bundler-install_extension_in_lib/tree/v#{spec.version}"
end
