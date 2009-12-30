require 'PathMap'
require 'PastebinForm'
require 'error'
require 'processForm'
require 'configuration/pastebin'
require 'visual/pastebin'

def newPastebinPost(request)
	$pastebinGenerator.get([PathMap.getDescription(:Pastebin), visualPastebinForm(request)], request)
end

def submitNewPastebinPost(request)
	processFormFields(request, PastebinForm::PostFields)
end
