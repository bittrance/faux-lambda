# Faux Lambda server for testing

Lambda service mock implementation for testing and exploration. It starts a simple web server (default is http://localhost:9123) and processes Lambda invocation requests. It can be used both programmatically and as a command line tool.

## As a command line tool

In its simplest form:
```
gem install faux-lambda
faux-lambda --reply='{}' &
aws --endpoint http://localhost:9123 lambda invoke --function-name whatever /dev/stdout
```

The CLI can also simulate specific scenarios:
```
$ faux-lambda --function=foo --reply='{}' --function=bar --reply='{}' --reply='{}' --fail &
$ aws --endpoint http://localhost:12345 lambda invoke --function-name foo /dev/stdout
Called foo with ...
{}
```
Here, each call to function `foo` gets reply `{}`, first call to function `bar` gets `{}`, second gets `{}` and third will fail.

You can pass a script to process the call:
```
cat > ./echo-service.rb <<EOF
"You called #{call.function_name} with #{call.payload}"
EOF
faux-lambda --handler=./echo-service.rb
```
The handler script is a piece of ruby code that is `eval`:ed in the context of the handler function (see below). The value of the last line becomes the reply. `--handler` behaves much like `--reply` so you can use query specifiers to limit when the handler is executed.

You can also pipe in replies from `stdin`, one reply per object (may contain newlines):
```
faux-lambda --function=foo <<<EOF
{}
{}
EOF
```
In this mode, the CLI will accept only one function, but may prove useful where there are numerous or large replies.

```
Usage: faux-lambda [options]
Query specifiers:
  --function-name=regex
  --async             Require invocation to be async
  --sync              Require invocation to be sync
Reply specifiers:
  --reply=json        Send this reply
  --handler=script.rb Ruby script is eval:ed to produce reply
  --fail              Imitate AWS Lambda failure
Various:
  --quiet             Don't log sent and received messages
  --version
```

## faux-lambda as a Docker container

You can use `faux-lambda` through Docker, like so:
```
docker -t bittrance/faux-lambda:latest --function=foo --reply='{}'
```

When combined with handler scripts and Docker Compose, you can add proper mocks to your project that behaves as the true functions. Add something like this to your `docker-compose.yml`:
```
version: '2'
services:
  lambda_mocks:
    image: bittrance/faux-lambda:latest
    command: --handler=/mock-lambdas.rb
    ports:
      - "127.0.0.1:9123:9123"
    volumes:
      - ./mock-lambdas.rb:/mock-lambdas.rb
```
This will start a container running faux-lambda with your local handler function.

## faux-lambda as a library

You can use `faux-lambda` programmatically too, like so:
```
require `faux-lambda`
lambda = FauxLambda.new(port: 12345).handle do |call|
  return if call.async
  if call.function_name == 'foo'
    '{}'
  end
end

Aws::Lambda.new(endpoint: lambda.endpoint).invoke(...)
```

If your handler function returns nil, faux-lambda will reply that the function is unknown (404). All other replies will be passed on to the
caller, including if your lambda function fails.

## faux-lambda in your specs

TBD.
