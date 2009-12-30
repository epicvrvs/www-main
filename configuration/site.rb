class SiteConfiguration
	SitePrefix = '/main/'
	StaticPath = SitePrefix + 'static/'
	
	StylesheetDirectory = 'style'
	ImageDirectory = 'image'
	ScriptDirectory = 'script'
	
	GeneralStringLengthMaximum = 128
	
	UserNameLengthMaximum = GeneralStringLengthMaximum
	PasswordLengthMaximum = GeneralStringLengthMaximum
	
	SessionStringLength = 128
	SessionDurationInDays = 30
end
