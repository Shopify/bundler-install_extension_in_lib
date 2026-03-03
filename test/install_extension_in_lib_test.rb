# frozen_string_literal: true

require_relative "test_helper"
require "shellwords"

class InstallExtensionInLibTest < BundlerPluginTestCase
  def test_copies_extension_to_lib_when_flagged
    source_uri = build_gem_repo("needs_ext_in_lib")

    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib", path: #{PLUGIN_ROOT.shellescape.inspect}
      if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
        Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
      elsif respond_to?(:gem)
        raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
      end
      source #{source_uri.inspect}
      gem "needs_ext_in_lib", install_extension_in_lib: true
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "bundle install failed: #{stderr}"

    lib_dir = installed_gem_lib("needs_ext_in_lib")
    assert shared_lib_in?(lib_dir), "Expected shared library in #{lib_dir} but none found"
  end

  def test_does_not_copy_extension_without_flag
    source_uri = build_gem_repo("no_ext_in_lib")

    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib", path: #{PLUGIN_ROOT.shellescape.inspect}
      if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
        Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
      elsif respond_to?(:gem)
        raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
      end
      source #{source_uri.inspect}
      gem "no_ext_in_lib"
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "bundle install failed: #{stderr}"

    lib_dir = installed_gem_lib("no_ext_in_lib")
    refute shared_lib_in?(lib_dir), "Expected NO shared library in #{lib_dir} but found one"
  end

  def test_unflagged_gem_with_ext_not_in_lib_requires_successfully
    source_uri = build_gem_repo("no_ext_in_lib")

    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib", path: #{PLUGIN_ROOT.shellescape.inspect}
      if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
        Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
      elsif respond_to?(:gem)
        raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
      end
      source #{source_uri.inspect}
      gem "no_ext_in_lib"
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "bundle install failed: #{stderr}"

    success, _stdout, stderr = bundle_exec("require 'no_ext_in_lib'; puts NoExtInLib.name")
    assert success, "require no_ext_in_lib failed: #{stderr}"
  end

  def test_flagged_gem_with_ext_in_lib_requires_successfully
    source_uri = build_gem_repo("needs_ext_in_lib")

    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib", path: #{PLUGIN_ROOT.shellescape.inspect}
      if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
        Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
      elsif respond_to?(:gem)
        raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
      end
      source #{source_uri.inspect}
      gem "needs_ext_in_lib", install_extension_in_lib: true
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "bundle install failed: #{stderr}"

    success, _stdout, stderr = bundle_exec("require 'needs_ext_in_lib'; puts NeedsExtInLib.name")
    assert success, "require needs_ext_in_lib failed: #{stderr}"
  end

  def test_flagged_gem_copies_extension_and_breaks_no_ext_in_lib
    source_uri = build_gem_repo("no_ext_in_lib")

    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib", path: #{PLUGIN_ROOT.shellescape.inspect}
      if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
        Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
      elsif respond_to?(:gem)
        raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
      end
      source #{source_uri.inspect}
      gem "no_ext_in_lib", install_extension_in_lib: true
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "bundle install failed: #{stderr}"

    lib_dir = installed_gem_lib("no_ext_in_lib")
    assert shared_lib_in?(lib_dir), "Expected shared library in #{lib_dir} (was flagged)"

    success, _stdout, _stderr = bundle_exec("require 'no_ext_in_lib'")
    refute success, "require should have failed (no_ext_in_lib rejects extensions in lib/)"
  end
end

# Tests using the load_plugin hack for already-installed plugins (non-path).
# This mirrors real-world usage where the plugin is installed as a gem,
# not loaded via path:.
class LoadPluginHackTest < BundlerPluginTestCase
  # Install the plugin into the isolated env so it's in the plugin index,
  # then we can test Gemfiles that reference it without path:.
  def install_plugin
    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib", path: #{PLUGIN_ROOT.shellescape.inspect}
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "plugin install failed: #{stderr}"

    FileUtils.rm_f(File.join(@workdir, "Gemfile.lock"))
  end

  # Override to also include the plugin gem in the repo, so that
  # `plugin "bundler-install_extension_in_lib"` (without path:) can resolve.
  def build_gem_repo(*gem_names)
    source_uri = super

    repo_path = source_uri.sub("file://", "")

    _stdout, stderr, status = Open3.capture3(
      "gem build bundler-install_extension_in_lib.gemspec",
      chdir: PLUGIN_ROOT,
    )
    raise "gem build plugin failed: #{stderr}" unless status.success?

    gem_file = Dir.glob(File.join(PLUGIN_ROOT, "*.gem")).first
    FileUtils.mv(gem_file, File.join(repo_path, "gems"))
    capture_io { Gem::Indexer.new(repo_path).generate_index }

    source_uri
  end

  def test_copies_extension_to_lib_when_flagged
    source_uri = build_gem_repo("needs_ext_in_lib")
    install_plugin

    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib"
      if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
        Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
      elsif respond_to?(:gem)
        raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
      end
      source #{source_uri.inspect}
      gem "needs_ext_in_lib", install_extension_in_lib: true
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "bundle install failed: #{stderr}"

    lib_dir = installed_gem_lib("needs_ext_in_lib")
    assert shared_lib_in?(lib_dir), "Expected shared library in #{lib_dir} but none found"
  end

  def test_does_not_copy_extension_without_flag
    source_uri = build_gem_repo("no_ext_in_lib")
    install_plugin

    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib"
      if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
        Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
      elsif respond_to?(:gem)
        raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
      end
      source #{source_uri.inspect}
      gem "no_ext_in_lib"
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "bundle install failed: #{stderr}"

    lib_dir = installed_gem_lib("no_ext_in_lib")
    refute shared_lib_in?(lib_dir), "Expected NO shared library in #{lib_dir} but found one"
  end

  def test_flagged_gem_requires_successfully
    source_uri = build_gem_repo("needs_ext_in_lib")
    install_plugin

    write_gemfile(<<~GEMFILE)
      plugin "bundler-install_extension_in_lib"
      if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
        Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
      elsif respond_to?(:gem)
        raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
      end
      source #{source_uri.inspect}
      gem "needs_ext_in_lib", install_extension_in_lib: true
    GEMFILE

    success, _stdout, stderr = bundle_install
    assert success, "bundle install failed: #{stderr}"

    success, _stdout, stderr = bundle_exec("require 'needs_ext_in_lib'; puts NeedsExtInLib.name")
    assert success, "require needs_ext_in_lib failed: #{stderr}"
  end
end
