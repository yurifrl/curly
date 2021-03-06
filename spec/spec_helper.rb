require 'active_support/all'

if ENV['CI']
  begin
    require 'coveralls'
    Coveralls.wear!
  rescue LoadError
    STDERR.puts "Failed to load Coveralls"
  end
end

require 'curly'

module RenderingSupport
  def presenter(&block)
    @presenter = block
  end

  def render(source)
    stub_const("TestPresenter", Class.new(Curly::Presenter, &@presenter))
    identifier = "test"
    handler = Curly::TemplateHandler
    details = { virtual_path: 'test' }
    template = ActionView::Template.new(source, identifier, handler, details)
    locals = {}
    view = ActionView::Base.new

    template.render(view, locals)
  end
end

module CompilationSupport
  def evaluate(template, options = {}, &block)
    code = Curly::Compiler.compile(template, presenter_class)
    context = double("context")

    context.instance_eval(<<-RUBY)
      def self.render(presenter, options)
        #{code}
      end
    RUBY

    context.render(presenter, options, &block)
  end
end
