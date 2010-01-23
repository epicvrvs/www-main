require 'PathMap'
require 'PastebinForm'
require 'error'
require 'processForm'
require 'SyntaxHighlighting'
require 'PastebinPost'
require 'SiteContainer'

require 'configuration/pastebin'

require 'visual/general'
require 'visual/pastebin'

require 'site/RequestManager'
require 'site/random'
require 'site/input'
require 'site/HTTPReply'
require 'site/input'

class PastebinHandler < SiteContainer
	SubmitNewPost = 'submitNewPost'
	View = 'view'
	List = 'list'
	
	def installHandlers
		@localPrefix = 'pastebin'
		
		installMenuHandler('Pastebin', [], :newPastebinPost)
		installHandler(SubmitNewPost, :submitNewPastebinPost)
		installHandler(View, :viewPastebinPost, 1)
		installHandler(List, :listPastebinPosts, 1)
	end
	
	def pastebinError(content, request)
		data = ['Pastebin error', content]
		raise RequestManager::Exception.new(@pastebinGenerator.get(data, request))
	end

	def newPastebinPost(request)
		@pastebinGenerator.get([PathMap.getDescription(:Pastebin), visualPastebinForm(request)], request)
	end

	def floodCheck(request)
		query = "select count(*) from flood_protection where ip = '#{request.address}' and paste_time + interval '#{PastebinConfiguration::PasteInterval} seconds' >= now()"
		count = @database.fetch(query).first.values.first
		return count > PastebinConfiguration::PastesPerInterval
	end

	def createAnonymousString(length)
		dataset = @database[:pastebin_post]
		while true
			string = RandomString.get length
			break if dataset.where(anonymous_string: sessionString).count == 0
		end
	end

	def submitNewPastebinPost(request)

		if PastebinForm::DebugMode
			actualData = serialiseFields(getFieldValues(request, PastebinForm::PostFields))
			debugData = request.getPost(PastebinForm::Debug)
			
			if debugData == actualData
				puts 'Data matches'
				#pastebinError('Data matches.', request)
			else
				puts 'Data does not match!'
				puts "Actual data:\n#{actualData}"
				puts "Debug data:\n#{debugData}"
				
				data = ''
				writer = HTMLWriter.new data
				writer.p { 'Data does not match:' }
				textAreaArguments = {cols: '50', rows: '30'}
				writer.textArea('Actual data', 'test1', actualData, textAreaArguments)
				writer.textArea('Debug data', 'test2', debugData, textAreaArguments)
				#pastebinError(data, request)
			end
		end

		author,
			
		postDescription,
		
		highlightingGroup,
		
		commonHighlighting,
		advancedHighlighting,
		expertHighlighting,
		
		privatePost,
		expiration,
		
		unitDescription,
		
		content = processFormFields(request, PastebinForm::PostFields)
		
		stringLengthChecks =
		[
			[author, 'name', PastebinConfiguration::AuthorLengthMaximum],
			[postDescription, 'post description', PastebinConfiguration::PostDescriptionLengthMaximum],
			[unitDescription, 'unit description', PastebinConfiguration::UnitDescriptionLengthMaximum],
			[content, 'content', PastebinConfiguration::UnitSizeLimit],
			[expertHighlighting, 'vim script name', PastebinConfiguration::VimScriptLengthMaximum],
		]
		
		errors = []
		
		privatePost = privatePost.to_i
		expiration = expiration.to_i
		
		validValues =
		[
			[highlightingGroup, 'highlighting group', PastebinForm::HighlightingGroupIdentifiers],
			[privatePost, 'privacy option', [0, 1]],
			[expiration, 'expiration option', (0..(PastebinConfiguration::ExpirationOptions.size - 1))],
		]
		
		syntaxHighlightingFields =
		[
			commonHighlighting,
			advancedHighlighting,
			expertHighlighting,
		]
		
		@database.transaction do
			isSpammer = floodCheck request
			if isSpammer
				errors << 'You have triggered the pastebin flood protection by posting too frequently so your request could not be processed.'
			end
			
			errors << 'You have not specified any content for your post.' if content.empty?
			
			stringLengthChecks.each do |field, name, limit|
				next if field.size <= limit
				errors << "The #{name} you have specified is too long - the limit is #{limit}."
			end
			
			validValues.each do |field, name, values|
				next if values.include?(field)
				errors << "The #{name} you have specified is invalid."
			end
			
			useSyntaxHighlighting =
				PastebinForm::HighlightingGroupIdentifiers.include?(highlightingGroup) &&
				highlightingGroup != PastebinForm::NoHighlighting
				
			highlightingSelectionMode = nil
			lastSelection = nil
				
			if useSyntaxHighlighting
				highlightingSelectionMode = PastebinForm::HighlightingGroupIdentifiers.index highlightingGroup
				syntaxHighlighting = syntaxHighlightingFields[highlightingSelectionMode - 1]
				if SyntaxHighlighting::isValidScript syntaxHighlighting
					lastSelection = syntaxHighlighting
				else
					errors << 'The vim syntax highlighting script you have specified does not exist.'
				end
			end
			
			if !errors.empty?
				errorContent = visualPastebinForm(request, errors, postDescription, unitDescription, content, highlightingSelectionMode, lastSelection)
				pastebinError(errorContent, request)
			end

			isLoggedIn = request.sessionUser != nil
			
			postUser = isLoggedIn ? request.sessionUser.id : nil
			postAuthor = !isLoggedIn ? author : nil
			postExpiration = expiration == 0 ? nil : (:NOW.sql_function + "#{PastebinConfiguration::ExpirationOptions[expiration][1]} second")
			anonymousString = privatePost == 1 ? createAnonymousString(PastebinConfiguration::AnonymousStringLength) : nil
			postReply = nil

			newPost =
			{
				user_id: postUser,
				
				author: postAuthor,
				ip: request.address,
				
				description: postDescription,
				
				expiration: postExpiration,
				
				anonymous_string: anonymousString,
				
				reply_to: postReply
			}

			dataset = @database[:pastebin_post]
			postId = dataset.insert newPost
			
			isPlain = highlightingGroup == PastebinForm::NoHighlighting
			if isPlain
				highlightedContent = nil
				pasteType = nil
			else
				highlightedContent = SyntaxHighlighting::highlight(syntaxHighlighting, content)
				pasteType = syntaxHighlighting
			end
			
			newUnit =
			{
				post_id: postId,
				
				description: unitDescription,
				content: content,
				
				highlighted_content: highlightedContent,
				
				paste_type: pasteType
			}
			
			dataset = @database[:pastebin_unit]
			dataset.insert newUnit
			
			postPath = "#{PathMap::PastebinView}/#{postId}"
			return HTTPReply.localRefer(request, postPath)
		end
	end

	def getPostId(request)
		arguments = request.arguments
		argumentError if arguments.empty?
		postId = readId arguments[0]
		argumentError if postId == nil
		return postId
	end

	def viewPastebinPost(request)
		postId = getPostId request
		post = @database.transaction { PastebinPost.new(postId, request) }
		return visualShowPastebinPost(request, post)
	end

	def listPastebinPosts(request)
		arguments = request.arguments
		argumentError if arguments.size > 1
		if arguments.empty?
			page = 0
		else
			page = readId(arguments[0]) - 1
		end
		
		@database.transaction do
			dataset = @database[:pastebin_post]
			postsPerPage = PastebinConfiguration::PostsPerPage
			posts = dataset.where(anonymous_string: nil, reply_to: nil)
			count = posts.count
			pageCount = count == 0 ? 1 : (Float(count) / postsPerPage).ceil
			pastebinError('Invalid page specified.', request) if page >= pageCount
			offset = [count - (page + 1) * postsPerPage, 0].max
			
			posts = posts.left_outer_join(:site_user, :id => :user_id)
			posts = posts.filter(pastebin_post__anonymous_string: nil, pastebin_post__reply_to: nil)
			
			posts = posts.select(
				:pastebin_post__id.as(:pastebin_post_id), :pastebin_post__user_id, :pastebin_post__author, :pastebin_post__description, :pastebin_post__creation,
				:site_user__name,
			)
			
			posts = posts.limit(postsPerPage, offset)

			posts = posts.from_self(alias: :user_post)
			posts = posts.left_outer_join(:pastebin_unit, :post_id => :user_post__pastebin_post_id)
			
			posts = posts.select(
				:user_post__pastebin_post_id, :user_post__user_id, :user_post__author, :user_post__description, :user_post__creation,
				:user_post__name,
				:pastebin_unit__paste_type
			)
			
			puts posts.sql
			posts = posts.all
			put posts.inspect
			output = visualListPastebinPosts(request, posts)
			return @pastebinGenerator.get(output, request)
		end
	end
end
