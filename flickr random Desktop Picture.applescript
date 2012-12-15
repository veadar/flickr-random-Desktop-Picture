property msg1 : "Input flickr API Key"
property defaultAnswer1 : "http://www.flickr.com/services/apps/create/"

property msg2 : "Input flickr Tag"
property defaultAnswer2 : "cat"

property needSetup : true

property flickrAPI : missing value

property saveFolder_Unix : missing value

on run
	
	set modKey to my getModifierKeys()
	if modKey contains "shift" then
		set needSetup to true
	end if
	
	if needSetup then
		if flickrAPI is missing value then
			set flickrAPI to dda(msg1, defaultAnswer1)
		end if
		
		set flickrTag to dda(msg2, defaultAnswer2)
		
		set baseFolder to choose folder with prompt "Choose save folder"
		
		set tempPath to baseFolder's POSIX path & "flickr random Desktop Picture/"
		
		try
			do shell script "mkdir " & quoted form of tempPath
		end try
		
		
		set saveFolder_Unix to tempPath & flickrTag & "/"
		
		try
			do shell script "mkdir " & quoted form of saveFolder_Unix
		end try
		
		set needSetup to false
		
	end if
	
	
	set rubyText to "require 'open-uri'
require 'rexml/document'
require 'cgi'

FLICKR_API_KEY = '" & flickrAPI & "'

def flickr_call(method_name, arg_map={}.freeze)
  args = arg_map.collect {|k,v| CGI.escape(k) << '=' << CGI.escape(v)}.join('&')
  url = Ä"http://www.flickr.com/services/rest/?api_key=%s&method=%s&%sÄ" %
    [FLICKR_API_KEY, method_name, args]
  doc = REXML::Document.new(open(url).read)
end

def check_post_number(tag)
	doc = flickr_call('flickr.photos.search','tags' => tag, 'license' => '4','per_page' => '1','privacy_filter' => '1','media' => 'photos')
	total_number = doc.elements['rsp/photos/'].attributes['pages'].to_i

  if total_number > 4000 then
	 random_number = rand(4000) + 1
  else
    random_number = rand(total_number) + 1
  end

	return random_number.to_s
end

def pick_a_photo(tag, random_number)
 doc = flickr_call('flickr.photos.search', 'tags' => tag, 'license' => '4','per_page' => '1','page' => random_number,'privacy_filter' => '1','media' => 'photos')
 photo = REXML::XPath.first(doc, '//photo')
 return photo.attribute('id')
end

def get_a_photo(flickr_id)
  doc = flickr_call('flickr.photos.getSizes', 'photo_id' => flickr_id)
  doc.elements.each('rsp/sizes/') do |element|
  last_number = element.elements.size
  end

  flickr_source = 1

  doc.elements.each('rsp/sizes/size') do |element|
    flickr_source = element.attribute('source').to_s
  end

  flickr_url = 1

  doc.elements.each('rsp/sizes/size') do |element|
    flickr_url = element.attribute('url').to_s
  end

  puts flickr_source
  puts flickr_url
end

flickr_tag = '" & flickrTag & "'
random_number = check_post_number(flickr_tag)

flickr_id = pick_a_photo(flickr_tag,random_number)

get_a_photo(flickr_id.to_s)"
	
	try
		set two_url to do shell script "/usr/bin/ruby -e " & quoted form of rubyText
		
		set flickr_source to paragraph 1 of two_url
		set flickr_url to paragraph 2 of two_url
		
		do shell script "cd " & quoted form of saveFolder_Unix & ";curl -O -L -f --retry 5 " & flickr_source
		set fileName to end of makeList(flickr_source, "/")
		
		set filePath to saveFolder_Unix & fileName
		
		set filePath to POSIX file filePath as alias
		
		tell application "Finder"
			set comment of filePath to flickr_url
			set desktop picture to filePath
		end tell
		
	on error
		set needSetup to true
		set flickrAPI to missing value
	end try
end run

on dda(msg, defaultAnswer)
	display dialog msg default answer defaultAnswer buttons {"OK"} default button 1
	return text returned of result
end dda

on makeList(theText, theDelimiter) --ÉeÉLÉXÉgÇéwíËåÍãÂÇ≈ãÊêÿÇËîzóÒÇ…äiî[Ç∑ÇÈ
	set tmp to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theList to every text item of theText
	set AppleScript's text item delimiters to tmp
	return theList
end makeList

on getModifierKeys()
	set theRubyScript to "require 'osx/cocoa';
event=OSX::CGEventCreate(nil);
mods=OSX::CGEventGetFlags(event);
print mods,' ';
print 'shift ' if (mods&0x00020000)!=0;
print 'control ' if(mods&0x00040000)!=0;
print 'option ' if(mods & 0x00080000)!=0;
print 'command ' if(mods & 0x00100000)!=0;
"
	return do shell script "/usr/bin/ruby -e " & quoted form of theRubyScript
end getModifierKeys