require 'spec_helper'

describe Curly::ComponentCompiler do
  describe ".compile_conditional" do
    let(:presenter_class) do
      Class.new do
        def monday?
          true
        end

        def tuesday?
          false
        end

        def day?(name)
          name == "monday"
        end

        def season?(name:)
          name == "summer"
        end

        def hello
          "hello"
        end

        def self.component_available?(name)
          true
        end
      end
    end

    it "compiles simple components" do
      evaluate("monday?").should == true
      evaluate("tuesday?").should == false
    end

    it "compiles components with an identifier" do
      evaluate("day.monday?").should == true
      evaluate("day.tuesday?").should == false
    end

    it "compiles components with attributes" do
      evaluate("season? name=summer").should == true
      evaluate("season? name=winter").should == false
    end

    it "fails if the component is missing a question mark" do
      expect { evaluate("hello") }.to raise_exception(Curly::Error)
    end

    def evaluate(component, &block)
      method, argument, attributes = Curly::ComponentParser.parse(component)
      code = Curly::ComponentCompiler.compile_conditional(presenter_class, method, argument, attributes)
      presenter = presenter_class.new
      context = double("context", presenter: presenter)

      context.instance_eval(<<-RUBY)
        def self.render
          #{code}
        end
      RUBY

      context.render(&block)
    end
  end

  describe ".compile_component" do
    let(:presenter_class) do
      Class.new do
        def title
          "Welcome!"
        end

        def i18n(key, fallback: nil)
          case key
          when "home.welcome" then "Welcome to our lovely place!"
          else fallback
          end
        end

        def summary(length = "long")
          case length
          when "long" then "This is a long summary"
          when "short" then "This is a short summary"
          end
        end

        def invalid(x, y)
        end

        def widget(size:, color: nil)
          s = "Widget (#{size})"
          s << " - #{color}" if color
          s
        end

        def self.component_available?(name)
          true
        end
      end
    end

    it "compiles components with identifiers" do
      evaluate("i18n.home.welcome").should == "Welcome to our lovely place!"
    end

    it "compiles components with optional identifiers" do
      evaluate("summary").should == "This is a long summary"
      evaluate("summary.short").should == "This is a short summary"
    end

    it "compiles components with attributes" do
      evaluate("widget size=100px").should == "Widget (100px)"
    end

    it "compiles components with optional attributes" do
      evaluate("widget color=blue size=50px").should == "Widget (50px) - blue"
    end

    it "allows both identifier and attributes" do
      evaluate("i18n.hello fallback=yolo").should == "yolo"
    end

    it "fails when an invalid attribute is used" do
      expect { evaluate("i18n.foo extreme=true") }.to raise_exception(Curly::Error)
    end

    it "fails when a component is missing a required identifier" do
      expect { evaluate("i18n") }.to raise_exception(Curly::Error)
    end

    it "fails when a component is missing a required attribute" do
      expect { evaluate("widget") }.to raise_exception(Curly::Error)
    end

    it "fails when an identifier is specified for a component that doesn't support one" do
      expect { evaluate("title.rugby") }.to raise_exception(Curly::Error)
    end

    it "fails when the method takes more than one argument" do
      expect { evaluate("invalid") }.to raise_exception(Curly::Error)
    end

    def evaluate(component, &block)
      method, argument, attributes = Curly::ComponentParser.parse(component)
      code = Curly::ComponentCompiler.compile_component(presenter_class, method, argument, attributes)
      presenter = presenter_class.new
      context = double("context", presenter: presenter)

      context.instance_eval(<<-RUBY)
        def self.render
          #{code}
        end
      RUBY

      context.render(&block)
    end
  end
end
