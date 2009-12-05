$:.concat ['..', 'application']

def loadModules
	require 'sequel'
	
	require 'site/RequestManager'
	require 'site/SiteGenerator'

	require 'configuration/database'

	applicationFiles =
	[
		'index',
		'user',
		
		'UserManager',
		'Menu',
		'PathMap',
		'MainSiteGenerator',
		'static'
	]

	applicationFiles.each { |name| require name }
end

def createRequestManager
	handlers =
	[
		[:Index, :getIndex],
		
		[:Login, :loginFormRequest],
		[:SubmitLogin, :performLoginRequest],
		[:Register, :registerFormRequest],
		[:SubmitRegistration, :performRegistrationRequest],
		
		[:Logout, :logoutRequest],
	]

	requestManager = RequestManager.new
	handlers.each { |path, symbol| requestManager.addHandler(PathMap.getPath(path), symbol) }
	return requestManager
end

def getDatabaseObject
	database =
	Sequel.connect(
		adapter: DatabaseConfiguration::Adapter,
		host: DatabaseConfiguration::Host,
		user: DatabaseConfiguration::User,
		password: DatabaseConfiguration::Password,
		database: DatabaseConfiguration::Database
	)
	return database
end

def createMenu
	menu = Menu.new
	
	loggedIn = lambda { |request| $userManager.isLoggedIn? request }
	notLoggedIn = lambda { |request| !loggedIn.(request) }
	
	items =
	[
		[:Index],
		[:Login, notLoggedIn],
		[:Register, notLoggedIn],
		[:Logout, loggedIn]
	]
	
	items.each do |item|
		condition = item.size > 1 ? item[1] : lambda { |request| true }
		item = item[0]
		menu.add(PathMap.getDescription(item), PathMap.getPath(item), condition)
	end
	
	return menu
end

def getSiteGenerator
	output = MainSiteGenerator.new
	output.addStylesheet(getStylesheet 'base')
	output
end

loadModules

$requestManager = createRequestManager
$generator = getSiteGenerator
$database = getDatabaseObject
$userManager = UserManager.new
$menu = createMenu
