dictionary = AnyStyle::Dictionary.create(
  Rails.configuration.anystyle.dictionary
).open

dictionary.freeze
dictionary.db.freeze

AnyStyle::Parser.defaults[:dictionary] = dictionary
