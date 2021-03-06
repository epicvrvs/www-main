require 'www-library/MIMEType'
require 'www-library/RequestManager'
require 'visual/general'

def plainError(message)
  raise WWWLib::RequestManager::Exception.new([WWWLib::MIMEType::Plain, message])
end

def internalError(message)
  plainError "An internal error has occured: #{message}"
end

def fieldError
  plainError 'Not all required fields have been specified.'
end

def javaScriptError
  ['JavaScript error', visualError('You need to turn on JavaScript in order to use this feature.')]
end

def hashError
  ['Hash error', visualError('Invalid hash.')]
end

def argumentError
  #puts getStackTrace
  plainError 'You have specified invalid arguments.'
end

def permissionError
  ['Permission error', visualError('You do not have permission to perform this action.')]
end

def getStackTrace
  begin
    raise nil
  rescue => exception
    output = exception.backtrace[2..-1]
    return output
  end
end
