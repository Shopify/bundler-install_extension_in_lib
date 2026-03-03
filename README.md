# bundler-install_extension_in_lib

A Bundler plugin that copies compiled native extensions (`.so`/`.bundle`/`.dll`) into a gem's `lib/` directory after installation. This is useful for old or unmaintained gems that expect their compiled extensions to live in `lib/` rather than in Bundler's extension directory.

## Installation

```
gem install bundler-install_extension_in_lib
```

## Usage

Add the following to your `Gemfile`:

```ruby
plugin "bundler-install_extension_in_lib"
if Bundler::Plugin.installed?("bundler-install_extension_in_lib")
  Bundler::Plugin.send(:load_plugin, "bundler-install_extension_in_lib")
elsif respond_to?(:gem)
  raise "Run `bundle install` first to install the bundler-install_extension_in_lib plugin"
end

source "https://rubygems.org"

gem "sassc", install_extension_in_lib: true
```

The `install_extension_in_lib: true` option on a `gem` declaration tells the plugin to copy that gem's compiled extensions into its `lib/` directory after installation.

You must run `bundle install` before any other Bundler command (`bundle exec`, `bundle check`, etc.). The first `bundle install` installs the plugin and registers it. Subsequent commands use the `load_plugin` call to load it before the `gem` declarations are evaluated. Without it, Bundler would reject `install_extension_in_lib:` as an unknown keyword.

### Why is `load_plugin` needed?

Bundler doesn't eagerly load already-installed plugins before evaluating the Gemfile. The `load_plugin` call forces the plugin to load early, which prepends our DSL extension onto `Bundler::Dsl` before any `gem` declarations are evaluated.

This is a known limitation of the Bundler plugin system: https://github.com/ruby/rubygems/pull/6961

## How it works

The plugin hooks into `Bundler::Plugin::Events::GEM_AFTER_INSTALL`. When a gem marked with `install_extension_in_lib: true` is freshly installed, the plugin copies all compiled extension files from the gem's extension directory into its `lib/` directory.

Files that are skipped: `gem.build_complete`, `mkmf.log`.

## License

MIT
