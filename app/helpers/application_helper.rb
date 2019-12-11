module ApplicationHelper
  def angular_template(id, options = { partial: id })
    content_tag :script, id: id, type: 'text/ng-template' do
      render options
    end
  end
end
