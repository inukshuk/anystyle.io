module AnystyleHelper
  def doc_url
    Rails.configuration.anystyle[:doc]
  end

  def gem_url
    Rails.configuration.anystyle[:gem]
  end

  def git_url(*args)
    [Rails.configuration.anystyle[:git], *args].compact.join('/')
  end
end
