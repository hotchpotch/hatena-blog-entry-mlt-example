
require './entry'
require 'time'
require 'nokogiri'

source = ARGV[0]
abort "usage: bundle exec ruby #{$0} hatenablog.export.txt" unless source

entries = File.read(source).scan(/
              TITLE:\s(.*?)\n.*?
              STATUS:\s(.*?)\n.*?
              DATE:\s(.*?)\n.*?
              BODY:\n(.*?)
              ----\n
            /mx)

entries.each do |entry|
  title, status, id, body = *entry
  if status == "Publish"
    Entry.where(id: id.gsub(/\D/, '')).first_or_create(title: title, body: Nokogiri::HTML(body).text)
  end
end
