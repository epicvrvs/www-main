require 'User'
require 'PastebinHandler'
require 'PastebinUnit'
require 'error'
require 'string'

require 'www-library/HTMLWriter'
require 'www-library/SymbolTransfer'

class PastebinPost < SymbolTransfer
	AnonymousAuthor = 'Anonymous'
	NoDescription = 'No description'
	
	attr_reader :id, :userId, :user, :units, :name, :isAnonymous, :author, :bodyAuthor, :noDescription, :description, :bodyDescription, :pasteType, :creation, :contentSize, :ip, :activeUnit
	
	attr_accessor :pasteTypes
	
	def initialize
		@bodyAuthor = ''
		@bodyDescription = ''
	end
	
	def simpleInitialisation(id, database)
		@id = id
		posts = database[:pastebin_post]
		postData = posts.where(id: id).select(:user_id, :ip, :description)
		argumentError if postData.empty?
		transferSymbols postData.first
		initialiseMembers false
		return nil
	end
	
	def deletePostQueryInitialisation(id, database)
		simpleInitialisation(id, database)
		return nil
	end
	
	def unitInitialisation(unitId, database, fields, fullUnitInitialisation = true)
		units = database[:pastebin_unit]
		unitData = units.where(id: unitId).select(*fields)
		argumentError if unitData.empty?
		@activeUnit = PastebinUnit.new(unitData.first, fullUnitInitialisation)
		@activeUnit.id = unitId
		postId = @activeUnit.postId
		simpleInitialisation(postId, database)
		return postId
	end
	
	def deleteUnitQueryInitialisation(unitId, database)
		return unitInitialisation(unitId, [:post_id, :description, :paste_type])
	end
	
	def editUnitQueryInitialisation(unitId, database)
		return unitInitialisation(unitId, [:post_id, :description, :content, :paste_type])
	end
	
	def editPermissionQueryInitialisation(unitId, database)
		return unitInitialisation(unitId, [:post_id], false)
	end
	
	def showPostQueryInitialisation(target, handler, request, database)
		dataset = database[:pastebin_post]
		
		if target.class == String
			postData = dataset.where(anonymous_string: target)
		else
			postData = dataset.where(id: target, anonymous_string: nil)
		end
		
		handler.pastebinError('You have specified an invalid post identifier.', request) if postData.empty?
		
		postData = postData.first
		transferSymbols postData
		
		if @userId != nil
			dataset = database[:site_user]
			userData = dataset.where(id: @userId)
			internalError 'Unable to retrieve the user associated with this post.' if userData.empty?
			@user = User.new(userData.first)
		end
		
		initialiseMembers
		
		dataset = database[:pastebin_unit]
		unitData = dataset.where(post_id: @id)
		internalError 'No units are associated with this post.' if unitData.empty?
		#unit ID will be transferred from the select * query
		unitData.each { |unit| @units << PastebinUnit.new(unit) }
		
		return nil
	end
	
	def initialiseMembers(fullMode = true)
		if fullMode
			if @userId == nil
				@user = nil
			end
			
			@pasteTypes = []
			
			if @author == nil
				if @user != nil
					@author = @user.name
				elsif @name != nil
					#name from the post listing joins
					@author = @name
				end
			end
			@isAnonymous = @author.empty?
			processDescription(@isAnonymous, @author, @bodyAuthor, AnonymousAuthor)
		end
		
		@noDescription = @description.empty?
		processDescription(@noDescription, @description, @bodyDescription, NoDescription)
		
		@units = []
		
		return nil
	end
end

