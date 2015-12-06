#!/usr/bin/ruby

# сонный после спортзала шиза
# 2015-11-27 00:45

require 'haml'
require 'mail'
require 'yaml'
require 'fileutils'

def collect_multipart(part)
  if part.multipart?
    part.parts.map { |p| collect_multipart(p) }.join
  else
    part.body if part.content_type.start_with?('text/plain')
  end
end

$config = YAML.load( File.open('config.yml') )

mail = Mail.new(STDIN.read)

puts mail['from']
puts mail.methods.sort.inspect
mail.header_fields.each do |header| puts "#{header.name} == #{header.value}" end
raise
puts mail.from
puts mail.to
puts mail.subject

puts "Parts: #{mail.parts.count}"
puts "Attach: #{mail.parts.attachments.count}"

puts "Text: <#{collect_multipart(mail)}>"

path_prefix = mail.date.strftime("%Y-%m/%d%H%M%S")
db_path = "#{__dir__}/#{path_prefix}"
attachments_path = "#{__dir__}/#{path_prefix}"
puts db_path

begin
  FileUtils.mkpath(db_path)
  FileUtils.mkpath(attachments_path)
  File.open("#{db_path}/post", "w+b", 0644) {|f| f.write collect_multipart(mail)}
rescue => e
  puts "Unable to save data for #{attachments_path} because #{e.message}"
end


mail.attachments.each do | attachment |
  if (attachment.content_type.start_with?('image/'))
    filename = "#{attachments_path}/#{attachment.filename}"
    begin
      File.open("#{filename}", "w+b", 0644) {|f| f.write attachment.body.decoded}
    rescue => e
      puts "Unable to save data for #{filename} because #{e.message}"
    end
  end
end