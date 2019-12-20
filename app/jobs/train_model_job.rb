require 'rexml/document'

class TrainModelJob < ApplicationJob
  queue_as :default

  after_perform :check_memory_consumption!

  class << self
    def pending?
      Delayed::Job
        .where(attempts: 0, locked_at: nil)
        .any? { |job| job.handler =~ /TrainModelJob/ }
    end
  end

  def perform(path)
    return unless Sequence.table_exists?

    parser = AnyStyle::Parser.new
    parser.train core | training_data, truncate: true

    lock.synchronize do
      parser.model.save path.untaint
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

  def training_data(limit = 300)
    Wapiti::Dataset.parse(
      REXML::Document.new(
        "<dataset>#{sequences(limit).join('')}</dataset>"
      )
    )
  end

  # Kills the worker process if it consumes excessive memory
  # to guard against potential leaks in the native module.
  def check_memory_consumption!
    `kill -15 #{Process.pid}` if memory_consumption > 512.megabytes
  end

  def memory_consumption
    `ps -o rss= -p #{Process.pid}`.to_i.kilobytes
  end
end
