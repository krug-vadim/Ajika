#!/usr/bin/ruby

require 'haml'
require 'fileutils'
require 'redcarpet'
require 'yaml'

require_relative 'lib/Ajika'

DB_PREFIX  = "#{__dir__}"
DB_PATH    = "#{DB_PREFIX}/db.yaml"
WWW_PREFIX = "#{__dir__}/www"
WWW_ROOT_INDEX = "#{WWW_PREFIX}/index.html"

category 'blog' do
	#if_from    ['from@you.to']
	#if_to      ['post@post.io']
	if_subject  //, '', nil
	#if_key     'key'
	#if_signed? true
	#if_verify  do |v| v.signatures.map{|sig|sig.from =~ /alice/ }.inject(false) {|d,x| d |= x } end

	action 'post' do |mail, text, attachments|
		post_suffix = mail[:date].strftime("%Y-%m/%d%H%M%S")
		post_path = "#{DB_PREFIX}/#{post_suffix}"

		begin
			FileUtils.mkpath(post_path)

			File.open("#{post_path}/post", "w+b", 0644) {|f| f.write text}

			attachments.each do |name, data|
				filename = "#{post_path}/#{name}"
				File.open("#{filename}", "w+b", 0644) {|f| f.write data}
			end

		rescue => e
			puts "Unable to save data for #{post_path} because #{e.message}"
		end
	end

	action 'page' do |mail, text, attachments|
		page_suffix = mail[:date].strftime("%Y-%m/%d%H%M%S")
		page_path = "#{WWW_PREFIX}/#{page_suffix}"

		html = Haml::Engine.new(File.read('blog_page.haml')).render(Object.new, mail) do
			Redcarpet::Markdown.new(Redcarpet::Render::HTML.new).render(text)
		end

		db = File.exist?(DB_PATH) ? YAML.load_file(DB_PATH) : []

		begin
			FileUtils.mkpath(page_path)
			File.open("#{page_path}/index.html", "w+b", 0644) {|f| f.write html}

			attachments.each do |name, data|
				filename = "#{page_path}/#{name}"
				File.open("#{filename}", "w+b", 0644) {|f| f.write data}
			end

			db << {'date' => mail[:date].iso8601, 'subj' => mail[:subj], 'path' => page_path}
			File.open(DB_PATH, "w", 0644) {|f| f.write db.to_yaml}

		rescue => e
			puts "Unable to save data for #{page_path} because #{e.message}"
		end
	end

	action 'index' do
		index_file = WWW_ROOT_INDEX

		db = File.exist?(DB_PATH) ? YAML.load_file(DB_PATH) : []

		html = Haml::Engine.new(File.read('index.haml')).render(Object.new, entries: db)
		File.open("#{index_file}", "w+b", 0644) {|f| f.write html}
	end
end

category 'blog_reply' do
	if_subject /^(RE|re)(\[\S+\])?\:(.+)$/
end
