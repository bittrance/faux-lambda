require 'rack'
require 'webrick'

class FauxLambda
  Call = Struct.new(
    :function_name,
    :qualifier,
    :payload
  )

  def initialize(options)
    @bind = options[:bind]
    @port = options[:port]
  end

  def handle(&block)
    Rack::Handler::WEBrick.run(
      lambda do |env|
        _, version, _, function_name, _ = env['REQUEST_PATH'].split('/')
        raise "Unknown version #{version}" unless version == '2015-03-31'
        qs = Rack::Utils.parse_nested_query(env["QUERY_STRING"])
        qualifier = qs["Qualifier"]
        payload = env['rack.input'].read

        call = Call.new(function_name, qualifier, payload)
        begin
          reply = block.call(call)
          if reply.nil?
            status_code = '404'
            reply = 'Not found'
          elsif reply == :fail
            status_code = '400'
            reply = 'Failed'
          else
            status_code = '200'
          end
          log(function_name, qualifier, payload, status_code, reply)
        rescue => e
          reply = ''
          log(function_name, qualifier, payload, '200', e)
        end

        headers = {'Content-Type' => 'application/octet-stream'}
        [status_code, headers, [reply]]
      end,
      Host: @bind,
      Port: @port,
      Logger: WEBrick::Log.new($stderr, WEBrick::Log::ERROR),
      AccessLog: [['/dev/null', WEBrick::AccessLog::COMMON_LOG_FORMAT]]
    )
  end

  private

  def log(function_name, qualifier, payload, status_code, reply)
    qualifier ||= "$LATEST"
    puts "#{function_name}:#{qualifier} called with #{payload}, replying #{status_code}: #{reply}"
  end
end
