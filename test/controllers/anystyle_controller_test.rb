require 'test_helper'

class AnystyleControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def with_protection
    original_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield if block_given?
  ensure
    ActionController::Base.allow_forgery_protection = original_protection
  end

  test 'index should return default layout' do
    get root_url
    assert_response :success
    assert_select 'body[ng-app]', 1
  end

  test 'parse should fail without valid token' do
    with_protection do
      token = accounts(:sylvester).access_token

      post parse_url, xhr: true
      assert_response :unauthorized

      post parse_url, xhr: true
      assert_response :unauthorized

      post parse_url, xhr: true, params: { input: [''] }
      assert_response :unauthorized

      post parse_url, xhr: true, params: { access_token: token }
      assert_response :bad_request

      post parse_url, xhr: true, params: { access_token: token, input: [''] }
      assert_response :success
    end
  end

  test 'parse should respond to json' do
    post parse_url(format: 'json'), params: { input: ['test'] }
    assert_response :success
    assert_equal 'application/json', @response.media_type
    assert_match(/\[\[\["\w+","test"\]\]\]/, @response.body)
  end

  test 'parse should respond to csl' do
    post parse_url, params: { format: 'csl', input: ['test'] }
    assert_response :success
    assert_equal 'application/vnd.citationstyles.csl+json', @response.media_type
    assert_includes JSON.parse(@response.body)[0].values, 'test'
  end

  test 'parse should respond to bibtex' do
    post parse_url, params: { format: 'bibtex', input: ['test'] }
    assert_response :success
    assert_equal 'application/x-bibtex', @response.media_type
    assert_match(/^@\w+\{[\w-]+,\s+\w+ = \{test\}/, @response.body)
  end

  test 'parse should respond to xml' do
    post parse_url, params: { format: 'xml', input: ['test'] }
    assert_response :success
    assert_equal 'application/xml', @response.media_type
    assert_match(
      %r{<dataset><sequence><\w+>test</\w+></sequence></dataset>},
      @response.body
    )
  end

  test 'parse should support single reference' do
    post parse_url(format: 'json'), params: { input: 'A B' }
    assert_response :success
    assert_equal 'application/json', @response.media_type
    assert_match(/\[\[\["\w+","A"\],\["\w+","B"\]\]\]/, @response.body)
  end

  test 'format should support csl' do
    post format_url, params: {
      format: 'csl',
      dataset: '[{"tokens":[{"value":"test","label":"note"}]}]'
    }

    assert_response :success
    assert_equal 'application/vnd.citationstyles.csl+json', @response.media_type
    assert_equal 'test', JSON.parse(@response.body)[0]['note']
  end

  test 'format should support xml' do
    post format_url, params: {
      format: 'xml',
      dataset: '[{"tokens":[{"value":"test","label":"note"}]}]'
    }

    assert_response :success
    assert_equal 'application/xml', @response.media_type
    assert_match(
      %r{<dataset><sequence><note>test</note></sequence></dataset>},
      @response.body
    )
  end

  test 'format should support bib' do
    post format_url, params: {
      format: 'bibtex',
      dataset: '[{"tokens":[{"value":"test","label":"note"}]}]'
    }

    assert_response :success
    assert_equal 'application/x-bibtex', @response.media_type
    assert_match(/^@\w+\{[\w-]+,\s+\w+ = \{test\}/, @response.body)
  end

  test 'format should save reviewed references for training' do
    seq_count = Sequence.count

    assert_enqueued_with(job: TrainModelJob) do
      post format_url, params: {
        format: 'csl',
        reviewed: true,
        dataset: '[{"pertinent":true,"tokens":[{"value":"test","label":"note"}]}]'
      }

      assert_response :success
      assert_equal seq_count + 1, Sequence.count
    end
  end

  test 'format should not save pertinent unreviewed references for training' do
    seq_count = Sequence.count

    post format_url, params: {
      format: 'csl',
      dataset: '[{"pertinent":true,"tokens":[{"value":"test","label":"note"}]}]'
    }

    assert_response :success
    assert_equal seq_count, Sequence.count
  end
end
