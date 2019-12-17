require 'rexml/document'

class TrainModelJob < ApplicationJob
  queue_as :default

  def perform(path)
    return unless Sequence.table_exists?

    parser = AnyStyle::Parser.new
    parser.train core | training_data, truncate: true

    lock.synchronize do
      parser.model.save path
    end
  end

  private

  def lock
    @lock ||= Mutex.new
  end

  def core
    Wapiti::Dataset.open(AnyStyle::Parser.defaults[:training_data])
  end

  def sequences(limit)
    Sequence
      .order(created_at: :desc)
      .limit(limit)
      .pluck(:xml)
  end

  def training_data(limit = 500)
    Wapiti::Dataset.parse(
      REXML::Document.new(
        "<dataset>#{sequences(limit).join('')}</dataset>"
      )
    )
  end
end
