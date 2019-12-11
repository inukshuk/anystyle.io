module AnystyleHelper
  def repo_url(
    host: 'https://github.com',
    user: 'inukshuk',
    project: 'anystyle',
    path: nil
  )
    [host, user, project, path].compact.join('/')
  end

  def gem_url
    'http://rubygems.org/gems/anystyle'
  end

  def doc_url
    'http://rubydoc.info/gems/anystyle'
  end

  def translated_labels
    AnyStyleIo
      .translated_labels
      .sort_by { |_, t| t.parameterize }
  end
end
