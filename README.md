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
  --async       Require invocation to be async
  --sync        Require invocation to be sync
Reply specifiers:
  --reply=json  Send this reply
  --fail        ...
Various:
  --quiet       Don't log sent and received messages
  --version
```

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
