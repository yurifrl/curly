Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.name              = 'curly-templates'
  s.version           = '2.0.0'
  s.date              = '2014-07-01'

  s.summary     = "Free your views!"
  s.description = "A view layer for your Rails apps that separates structure and logic."
  s.license     = "apache2"

  s.authors  = ["Daniel Schierbeck"]
  s.email    = 'daniel.schierbeck@gmail.com'
  s.homepage = 'https://github.com/zendesk/curly'

  s.require_paths = %w[lib]

  s.rdoc_options = ["--charset=UTF-8"]

  s.add_dependency("actionpack", [">= 3.1", "< 4.1"])

  s.add_development_dependency("railties", [">= 3.1", "< 4.1"])
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec", "~> 2.12")
  s.add_development_dependency("genspec")

  # = MANIFEST =
  s.files = %w[
    CHANGELOG.md
    CONTRIBUTING.md
    Gemfile
    README.md
    Rakefile
    curly-templates.gemspec
    lib/curly-templates.rb
    lib/curly.rb
    lib/curly/attribute_parser.rb
    lib/curly/compiler.rb
    lib/curly/component_compiler.rb
    lib/curly/component_parser.rb
    lib/curly/dependency_tracker.rb
    lib/curly/error.rb
    lib/curly/incomplete_block_error.rb
    lib/curly/incorrect_ending_error.rb
    lib/curly/invalid_component.rb
    lib/curly/presenter.rb
    lib/curly/presenter_not_found.rb
    lib/curly/railtie.rb
    lib/curly/scanner.rb
    lib/curly/syntax_error.rb
    lib/curly/template_handler.rb
    lib/generators/curly/controller/controller_generator.rb
    lib/generators/curly/controller/templates/presenter.rb.erb
    lib/generators/curly/controller/templates/view.html.curly.erb
    lib/rails/projections.json
    spec/attribute_parser_spec.rb
    spec/compiler/collections_spec.rb
    spec/compiler_spec.rb
    spec/component_compiler_spec.rb
    spec/generators/controller_generator_spec.rb
    spec/incorrect_ending_error_spec.rb
    spec/integration/collection_blocks_spec.rb
    spec/integration/components_spec.rb
    spec/integration/conditional_blocks_spec.rb
    spec/presenter_spec.rb
    spec/scanner_spec.rb
    spec/spec_helper.rb
    spec/syntax_error_spec.rb
    spec/template_handler_spec.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^spec\/.*_spec\.rb/ }
end
