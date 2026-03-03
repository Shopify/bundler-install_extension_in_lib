# frozen_string_literal: true

require "bundler"
require "rubygems/indexer"
require "fileutils"
require "tmpdir"
require "open3"
require "rbconfig"

class BundlerPluginTestCase < Megatest::Test
  PLUGIN_ROOT = File.expand_path("..", __dir__)
  FIXTURES_DIR = File.join(__dir__, "fixtures")
  DLEXT = RbConfig::CONFIG["DLEXT"]

  def setup
    super
    @workdir = Dir.mktmpdir("bundler_plugin_test", PLUGIN_ROOT + "/tmp")
    @home = File.join(@workdir, "home")
    @bundle_path = File.join(@workdir, "bundle")
    FileUtils.mkdir_p(@home)

    # Create a gemrc that disables install_extension_in_lib globally,
    # so we can test that only the plugin enables it for specific gems.
    @gemrc = File.join(@workdir, "gemrc")
    File.write(@gemrc, ":install_extension_in_lib: false\n")
  end

  def teardown
    FileUtils.rm_rf(@workdir) if @workdir
    super
  end

  def write_gemfile(content)
    File.write(File.join(@workdir, "Gemfile"), content)
  end

  def bundle_env
    {
      "HOME" => @home,
      "BUNDLE_PATH" => @bundle_path,
      "BUNDLE_GEMFILE" => File.join(@workdir, "Gemfile"),
      "BUNDLE_USER_CONFIG" => File.join(@home, ".bundle", "config"),
      "BUNDLE_USER_CACHE" => File.join(@home, ".bundle", "cache"),
      "BUNDLE_USER_PLUGIN" => File.join(@home, ".bundle", "plugin"),
      # Force install_extension_in_lib to false so the plugin is the only
      # thing that can copy extensions to lib/.
      "GEMRC" => @gemrc,
    }
  end

  def bundle_install
    Bundler.with_unbundled_env do
      stdout, stderr, status = Open3.capture3(bundle_env, "bundle install", chdir: @workdir)
      [status.success?, stdout, stderr]
    end
  end

  def bundle_exec(ruby_code)
    Bundler.with_unbundled_env do
      stdout, stderr, status = Open3.capture3(
        bundle_env,
        "bundle exec ruby -e #{ruby_code.shellescape}",
        chdir: @workdir,
      )
      [status.success?, stdout, stderr]
    end
  end

  # Build .gem files and create a local gem repo with index.
  # Returns the file:// URI for the repo.
  def build_gem_repo(*gem_names)
    repo_path = File.join(@workdir, "repo")
    FileUtils.mkdir_p(File.join(repo_path, "gems"))

    gem_names.each do |gem_name|
      fixture_dir = File.join(FIXTURES_DIR, gem_name)
      # Build the .gem in a temp copy to avoid polluting fixtures
      build_dir = File.join(@workdir, "build", gem_name)
      FileUtils.mkdir_p(File.dirname(build_dir))
      FileUtils.cp_r(fixture_dir, build_dir)

      _stdout, stderr, status = Open3.capture3(
        "gem build #{gem_name}.gemspec",
        chdir: build_dir,
      )
      raise "gem build #{gem_name} failed: #{stderr}" unless status.success?

      gem_file = Dir.glob(File.join(build_dir, "*.gem")).first
      FileUtils.mv(gem_file, File.join(repo_path, "gems"))
    end

    capture_io { Gem::Indexer.new(repo_path).generate_index }

    "file://#{repo_path}"
  end

  # Find the installed gem's lib directory in the bundle path.
  def installed_gem_lib(gem_name)
    pattern = File.join(@bundle_path, "**", "gems", "#{gem_name}-*", "lib")
    dirs = Dir.glob(pattern)
    raise "No installed gem found for #{gem_name} in #{@bundle_path}" if dirs.empty?
    dirs.first
  end

  # Check if a shared library exists in the given directory.
  def shared_lib_in?(dir)
    Dir.glob(File.join(dir, "**", "*.#{DLEXT}")).any?
  end
end
