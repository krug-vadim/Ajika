require 'lib/Ajika'

Ajika do
  db do
    path "#{date.year}-#{date.month}/#{date.day}#{date.time.hour}#{date.time.minute}#{date.time.second}"
end

from '' do
  secret key
  db_save_to path
  post_to path
  render haml
  save_attachemnts true

  page index do
    haml index
  end

  page archive do
  end

  page post do
  end
end

post do
end