require 'anystyle'

module AnyStyleIo
  # Subtle: assuming model does not change!
  LABELS = AnyStyle.parser.model.labels.map { |label|
    label.force_encoding('UTF-8')
  }.sort

  module_function

  def translated_labels
    Hash[LABELS.map { |label|
      [label, I18n.t("parser.labels.#{label}", default: label.capitalize)]
    }]
  end
end
