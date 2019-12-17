class AnystyleController < ApplicationController
  def index
  end

  def parse
    input = params.require(:input).taint

    if input.length <= Rails.configuration.anystyle.parse_limit
      dataset = parser.parse(input, format: 'wapiti')

      respond_to do |format|
        format.json {
          render json: dataset.map { |s| s.map { |t| [t.label, t.value] } }
        }
      end
    else
      bad_request 'Excessive use'
    end
  ensure
    response.headers['X-AnyStyle-Last-Modified'] = model_time
  end

  def format
    input = JSON.parse(params.require(:dataset))
    sequences = []

    dataset = Wapiti::Dataset.new(input.map { |s|
      seq = Wapiti::Sequence.new(s['tokens'].map { |t|
        Wapiti::Token.new t['value'], label: t['label']
      })

      sequences << Sequence.new(xml: seq.to_xml) if s['pertinent']

      seq
    })

    respond_to do |format|
      format.csl {
        render json: parser.format_csl(dataset)
      }
      format.bib {
        send_data parser.format_bibtex(dataset), filename: 'anystyle.bib'
      }
      format.xml {
        render xml: dataset.to_xml
      }
    end
  ensure
    save_training_data sequences if train_model?
  end

  private

  def parser
    AnyStyle.parser
  end

  def train_model?
    !!params[:reviewed]
  end

  def save_training_data(sequences)
    saved_count = sequences.map(&:save).count(true)

    unless saved_count.zero?
      TrainModelJob.perform_later(parser.model.path)
    end
  end

  def model_time
    view_context.time_ago_in_words parser.mtime, include_seconds: true
  end
end
