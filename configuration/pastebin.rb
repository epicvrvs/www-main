require 'configuration/loader'
requireConfiguration 'site'

class PastebinConfiguration
  PostsPerPage = 100
  Prefix = 'pastebin'

  PrivateStringLength = 16

  AuthorLengthMaximum = SiteConfiguration::GeneralStringLengthMaximum
  PostDescriptionLengthMaximum = SiteConfiguration::GeneralStringLengthMaximum
  UnitDescriptionLengthMaximum = SiteConfiguration::GeneralStringLengthMaximum
  VimScriptLengthMaximum = 16

  #limit in bytes
  UnitSizeLimit = 10 * 1024 * 1024

  #interval in seconds
  PasteInterval = 10 * 60
  PastesPerInterval = 10

  HourSeconds = 60 * 60
  DayHours = 24
  WeekDays = 7

  ListDescriptionLengthMaximum = 64
  ListAuthorLengthMaximum = 32

  ExpirationOptions =
    [
     ['No expiration', 0],
     ['One hour', HourSeconds],
     ['One day', DayHours * HourSeconds],
     ['One week', WeekDays * DayHours * HourSeconds]
    ]
end
