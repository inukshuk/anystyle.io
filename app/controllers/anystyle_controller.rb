class AnystyleController < ApplicationController
  def index
  end

  def parse
    respond_to do |format|
      format.json do
        render json: tokenize(parser.parse(input, format: 'wapiti'))
      end
    end
  ensure
    set_last_modified
  end

  def format
    respond_to do |format|
      format.csl do
        render json: parser.format_csl(dataset)
      end
      format.bib do
        send_data parser.format_bibtex(dataset), filename: 'anystyle.bib'
      end
      format.xml do
        render xml: dataset.to_xml
      end
    end
  ensure
    # save_training_data
  end

  private

  def input
    params.require(:input).taint
  end

  def dataset
    Wapiti::Dataset.new(JSON.parse(params.require(:dataset)).map { |s|
      Wapiti::Sequence.new(s['tokens'].map { |t|
        Wapiti::Token.new t['value'], label: t['label']
      })
    })
  end

  def parser
    AnyStyle.parser
  end

  def tokenize(ds)
    ds.map { |s| s.map { |t| [t.label, t.value] } }
  end

  def set_last_modified
    response.headers['X-AnyStyle-Last-Modified'] = mtime(AnyStyle.parser.model)
  end

  def mtime(model)
    view_context.time_ago_in_words File.mtime(model.path), include_seconds: true
  end
end
