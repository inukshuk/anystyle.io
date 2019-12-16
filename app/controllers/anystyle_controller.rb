class AnystyleController < ApplicationController
  def index
  end

  def parse
    input = params.require(:input).taint

    if input.length > 1000
      bad_request 'Excessive use'
    else
      dataset = parser.parse(input, format: 'wapiti')

      respond_to do |format|
        format.json {
          render json: dataset.map { |s| s.map { |t| [t.label, t.value] } }
        }
      end
    end
  ensure
    response.headers['X-AnyStyle-Last-Modified'] = model_time
  end

  def format
    input = JSON.parse(params.require(:dataset))
    training_data = []

    dataset = Wapiti::Dataset.new(input.map { |s|
      seq = Wapiti::Sequence.new(s['tokens'].map { |t|
        Wapiti::Token.new t['value'], label: t['label']
      })

      training_data << Sequence.new(xml: seq.to_xml) if s['pertinent']

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
    training_data.each(&:save) if reviewed?
  end

  private

  def parser
    AnyStyle.parser
  end

  def reviewed?
    !!params[:reviewed]
  end

  def model_time
    view_context.time_ago_in_words parser.mtime, include_seconds: true
  end
end
