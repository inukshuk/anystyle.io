class AnystyleController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :parse
  before_action :verify_access_token, only: :parse

  rescue_from ActionController::ParameterMissing, with: :bad_request

  def index
  end

  def parse
    input = params.require(:input).taint

    if input.length <= Rails.configuration.anystyle.parse_limit
      render_dataset parser.parse(input, format: 'wapiti')
    else
      bad_request 'status.excessive'
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

    render_dataset dataset
  ensure
    save_training_data sequences if train_model?
  end

  private

  def render_dataset(dataset)
    respond_to do |format|
      format.json {
        render json: dataset.map { |s| s.map { |t| [t.label, t.value] } }
      }
      format.csl {
        render json: parser.format_csl(dataset, date_format: 'citeproc')
      }
      format.bibtex {
        send_data parser.format_bibtex(dataset),
          filename: 'anystyle.bib',
          type: :bibtex
      }
      format.xml {
        render xml: dataset.to_xml
      }
    end
  end

  def parser
    AnyStyle.parser
  ensure
    AnyStyle.parser.reload if AnyStyle.parser.stale?
  end

  def train_model?
    !!params[:reviewed]
  end

  def save_training_data(sequences)
    saved_count = sequences.map(&:save).count(true)

    unless saved_count.zero? || TrainModelJob.pending?
      TrainModelJob.perform_later(parser.model.path)
    end
  end

  def model_time
    view_context.time_ago_in_words parser.mtime, include_seconds: true
  end

  def verify_access_token
    verify_authenticity_or_access_token
  rescue
    not_authorized
  end

  def verify_authenticity_or_access_token
    if params.key? :access_token
      Account.verify params.require(:access_token)
    else
      verify_authenticity_token
    end
  end
end
