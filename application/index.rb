require 'PathMap'
require 'visual/index'

def getIndex(request)
	return $generator.get(PathMap.getDescription(:Index), request, visualIndex)
end
