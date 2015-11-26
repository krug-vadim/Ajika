#!/usr/bin/ruby

# сонный после спортзала шиза
# 2015-11-27 00:45

require 'haml'
require 'mail'

mail = Mail.new(STDIN.read)

puts mail.from
puts mail.to
puts mail.subject
puts mail.date.to_s
#puts mail.body.decoded    #=> 'This is the body of the email...

puts mail.multipart?

puts ">>>: #{mail.body.decoded}" if !mail.multipart?

puts "Parts: #{mail.parts.count}"
puts "Attach: #{mail.parts.attachments.count}"

mail.parts.map { |p|
  if p.content_type.start_with?('text/plain')
    puts p.body
  elsif !p.content_type.start_with?('image/')
    if p.multipart?
      puts p.parts.count
      p.parts.map { |p|
        puts p.content_type
        puts p.body
      }
    end
  end
}

puts __dir__

mail.attachments.each do | attachment |
  # Attachments is an AttachmentsList object containing a
  # number of Part objects
  if (attachment.content_type.start_with?('image/'))
    # extracting images for example...
    filename = attachment.filename
    begin
      File.open("#{__dir__}/#{filename}", "w+b", 0644) {|f| f.write attachment.body.decoded}
    rescue => e
      puts "Unable to save data for #{filename} because #{e.message}"
    end
  else
    puts attachment.content_type
  end
end