dictionary = AnyStyle::Dictionary.create(
  Rails.configuration.anystyle.dictionary
).open

dictionary.freeze
dictionary.db.freeze

AnyStyle::Parser.defaults[:dictionary] = dictionary

original_model = AnyStyle::Parser.defaults[:model]

require 'fileutils'
require 'pathname'

pn = Pathname.new Rails.configuration.anystyle.model
pn.parent.mkpath unless pn.parent.exist?

# Reset model initially or after Gem update!
if !pn.exist? || File.mtime(original_model) > pn.mtime
  FileUtils.cp original_model, pn.to_s
end

AnyStyle::Parser.defaults[:model] =
  Rails.configuration.anystyle.model.dup
