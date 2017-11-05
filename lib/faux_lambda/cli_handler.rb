require 'optparse'

class FauxLambda::CliHandler
  attr_reader :options

  def initialize
    @functions = {
      default: {
        invocation_type: nil,
        replies: []
      }
    }
    @options = {}
  end

  def parse_options(argv)
    current_function = :default
    parser = OptionParser.new do |opts|
      opts.banner = "AWS Lambda debugging endpoint, version #{FauxLambda::VERSION}."
      opts.separator('')
      opts.separator('Usage: faux-lambda --reply "Hello world!"')
      opts.separator('Query specifiers:')
      opts.on('--function name', '-f name', 'Name of function to expect, optionally with :<qualifier>') do |function_name|
        current_function = function_name
        @functions[current_function] = {replies: []}
      end
      opts.separator('Reply specifiers:')
      opts.on('--reply payload', '-r payload', 'Data to respond with') do |payload|
        @functions[current_function][:replies] << lambda {|_| payload }
      end
      opts.on('--handler script.rb', '-h script.rb', 'Ruby script is eval:ed to produce reply') do |script|
        @functions[current_function][:replies] << make_handler(script)
      end
      opts.on('--fail', 'AWS Lambda framework gives 400') do
        @functions[current_function][:replies] << lambda {|_| :fail }
      end
      opts.separator('Control options')
      opts.on('--port port', 'TCP port to bind, 9123 by default') do |port|
        @options[:port] = port
      end
      opts.on('--bind address', 'Interface to bind to, localhost by default') do |bindaddress|
        @options[:bind] = bindaddress
      end
    end
    parser.parse!(argv)
  end

  def handler(call)
    data = function_data(call)
    reply_from(data[:replies], call)
  end

  private

  def make_handler(script)
    code = File.read(script)
    lambda do |call|
      eval(code, binding(), script)
    end
  end

  def reply_from(replies, call)
    if replies.size > 1
      replies.shift.call(call)
    elsif replies.size == 1
      replies.last.call(call)
    else
      nil
    end
  end

  def function_data(call)
    qualified_function_name = if call.qualifier
      "#{call.function_name}:#{call.qualifier}"
    end
    @functions[qualified_function_name] || @functions[call.function_name] || @functions[:default]
  end
end
