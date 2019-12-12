angular.
  module('anystyle', [
    'ng'
    'ngResource'
    'ui.bootstrap.pagination'
  ]).

  config([
    '$httpProvider', (http) ->
      token = $('meta[name="csrf-token"]').attr('content')
      http.defaults.headers.common['X-CSRF-TOKEN'] = token if token?
  ]).

  config([
    'paginationConfig', (config) ->
      config.previousText = '«'
      config.nextText = '»'
  ]).

  filter('startFrom', ->
    (items, start) ->
      return items unless angular.isArray items
      items.slice parseInt(start, 10) || 0
  ).

  factory('Reference', [
    '$resource'
    'MarkedTokens'

    (resource, MarkedTokens) ->
      Reference = resource '/parse.:format', {},
        parse:
          method: 'POST'
          isArray: true
          params:
            format: 'raw'
          transformResponse: (data, headers) ->
            try
              if (/json/).test headers('content-type')
                (Reference.convert(tokens) for tokens in JSON.parse(data))
              else
                data
            catch
              data

        train:
          method: 'PUT'
          isArray: true
          params:
            format: 'json'

      Reference.convert = (tokens) ->
        tokens: ({ value: token[1], label: token[0]} for token in tokens)

      Reference::initialize = ->
        @marked = new MarkedTokens
        this

      Reference::mark = (token) ->
        @marked.push token
        this

      Reference::unmark = (token) ->
        @marked.remove token
        this

      Reference
  ]).

  factory('ParserInput', [
    ->
      class ParserInput
        constructor: ->
          @lines = []

        update: (source = '') ->
          @clear()
          @push line for line in source.split /\r?\n/ when (/\S/).test line
          this

        clear: ->
          @lines.length = 0
          this

        push: (line) ->
          @lines.push line.replace /^\s+|\s+$/, ''
          this
  ]).

  factory('LabelHistory', [
    ->
      class LabelHistory
        constructor: (@depth = 5) ->
          @labels = []

        remember: (label) ->
          try
            @forget label.name
            @labels.unshift label
            this
          finally
            @labels.length = @depth if @labels.length > @depth

        forget: (name) ->
          @labels = (label for label in @labels when label.name isnt name)
          this
  ]).

  factory('MarkedTokens', [
    ->
      class MarkedTokens
        constructor: ->
          @tokens = []

        toggle: (token) ->
          if token.marked then @remove token else @push token

        remove: (token) ->
          delete token.marked
          idx = @tokens.indexOf token
          @tokens.splice idx, 1 if idx?
          this

        push: (token) ->
          token.marked = true
          @tokens.push token
          this

        clear: (keep) ->
          if keep
            drop = (token for token in @tokens when token not in keep)
            @remove token for token in drop
          else
            delete token.marked for token in @tokens
            @tokens.length = 0

          this

      MarkedTokens
  ]).

  directive('anystyleParser', [
    '$document'
    '$rootScope'
    '$http'
    'ParserInput'
    'Reference'
    'LabelHistory'

    (document, root, http, ParserInput, Reference, LabelHistory) ->
      restrict: 'EA'
      replace: true
      templateUrl: 'anystyle/parser'
      scope: true,

      link: (scope, element) ->
        [form, body, skip] = [element.find('#export form:first'), $('body')]

        scope.history = new LabelHistory 12
        scope.input = new ParserInput

        scope.parse = ->
          scope.output = Reference.parse
            input: scope.input.lines

            (output, headers) ->
              delete output.processing
              output.mtime = headers 'x-anystyle-last-modified'

              reference.initialize() for reference in output
              focus '#editor'
              scope.error = false

            (reason) ->
              delete scope.output.processing
              focus '#source'
              scope.error = true

          scope.output.processing = true

        scope.open = ->
          try
            body.addClass 'modal-open'
            scope.selector = true
          finally
            skip = true

        scope.close = ->
          try
            body.removeClass 'modal-open'
            scope.selector = false
          finally
            skip = true


        scope.save = (format) ->
          form.attr 'action', [scope.save.path, format].join('.')
          $('[name="references"]', form).val angular.toJson(scope.output)
          form.submit()
          true

        scope.save.path = form.attr 'action'

        scope.tag = (label) ->
          try
            for reference in scope.output
              for token in reference.marked.tokens when token.label isnt label.name
                token.label = label.name
                reference.pertinent = scope.output.edited = true

          finally
            scope.history.remember label
            skip = true


        scope.mark = (reference, token, event) ->
          span = $(event.target)

          # Return early if the click was outside the token,
          # i.e., on the label pseudo-element!
          return unless inside span, event

          try
            if !token.marked
              switch
                when event.shiftKey && scope.anchor?
                  append = true
                  select reference, span, scope.anchor

                when event.ctrlKey || event.metaKey
                  append = true
                  reference.mark token

                else
                  clear()
                  reference.mark token

              scope.anchor = span
              drag reference, append

            else
              reference.unmark token
              delete scope.anchor unless marked()


          finally
            skip = true

          return token

        scope.pick = (reference, token, event) ->
          span = $(event.target)
          return unless inside span, event

          scope.anchor = span

          span
            .siblings ".label-#{token.label}"
            .addBack()
            .each ->
              reference.mark $(this).scope().token

          null



        # Returns whether or not the event occurred
        # inside the node.
        inside = (node, event) ->
          offset = node.offset()

          return false if event.pageX < offset.left
          return false if event.pageX > offset.left + node.outerWidth()

          true

        # Handle drag-selection by registering mouse-enter
        # event handlers for all tokens of the passed-in
        # reference until the next mouse-up event.
        drag = (reference, append = false) ->
          return unless scope.anchor?

          tokens = scope.anchor.siblings().addBack()

          if append
            keep = (token for token in reference.marked.tokens)

          tokens.on 'mouseenter', ->
            reference.marked.clear(keep)
            select reference, $(this), scope.anchor

          document.one 'mouseup.anystyle', ->
            tokens.off 'mouseenter'

          null


        # Returns an [a, b] or [b, a] depending on the
        # order of the two nodes in the DOM; or [a] if
        # the two nodes are not siblings.
        order = (a, b) ->
          return [a] unless a[0] isnt b[0]

          parent = a.parent()
          return [a] unless b and b.parent()[0] is parent[0]

          context = parent.children()

          if context.index(a) > context.index(b) then [b, a] else [a, b]


        # Mark all tokens of the reference between a and b.
        # Marks only token a if the two tokens are not part
        # of the same reference.
        select = (reference, a, b) ->
          try
            [from, to] = order a, b

            reference.mark from.scope().token

            unless !to?
              to.prevUntil(from).addBack().each ->
                reference.mark $(this).scope().token
          finally
            scope.$digest() unless root.$$phase


        # Focus the selector by setting the document's
        # scroll offset accordingly.
        focus = (selector, padding = 0) ->
          document.scrollTop element.find(selector).offset().top - padding

        # Whether or not there are currently marked tokens
        marked = ->
          for reference in scope.output
            return true if reference.marked.tokens.length
          false

        # Clears the current selection unless the skip
        # variable is currently set.
        clear = ->
          try
            digest = null

            unless skip? || !scope.output?
              for reference in scope.output
                if reference.marked.tokens.length
                  reference.marked.clear()
                  digest = true

              scope.anchor = null

          finally
            skip = null
            scope.$digest() unless !digest? || root.$$phase

        document.on 'mouseup.anystyle', clear


        scope.$watch 'source', (source) ->
          scope.input.update source

        scope.$watch 'input.lines.length', (lines) ->
          scope.excessive = lines && lines > 300

        # Pagination
        scope.ipp = 5

        scope.$watch 'page', (page) ->
          scope.offset = ((page || 1) - 1) * scope.ipp
          focus '#tokens', 40 if page?


        scope.$on '$destroy', ->
          body = form = null
          document.off 'mouseup.anystyle'

        # Mock Input
        # scope.source =
          """
          Lamm, C., Zucconi, A., & Silani, G. (2013). Carl Rogers Meets the Neurosciences: Insights from Social Neuroscience for Client-Centered Therapy. In J. H. D. Cornelius-White, R. Motschnig-Pitrik & M. Lux (Hrsg.), Interdisciplinary Handbook of the Person-Centered Approach (63–78). New York: Springer.
          Fisher, L. (2013). How Can I Trust You? Encounters with Carl Rogers and Game Theory. In J. H. D. Cornelius-White, R. Motschnig-Pitrik & M. Lux (Hrsg.), Interdisciplinary Handbook of the Person-Centered Approach (299–317). New York: Springer.
          Rachlin, H., Sommerbeck, L., & Frankel, M. (2010). Rogers’ concept of the actualizing tendency in relation to Darwinian theory. (M. Cooper, J. C. Watson & W. B. Stiles, Eds.) Person-Centered & Experiential Psychotherapies, 9(1), 69-80.
          Mason, M. J. (2009). Rogers Redux: Relevance and Outcomes of Motivational Interviewing Across Behavioral Problems. Journal of Counseling and Development, 87(3), 357–362.
          """

        # Parse Mock Input
        # setTimeout(->
        #   scope.parse()
        # 200)

  ]).

  directive('affix', [
    '$window'

    (window) ->
      restrict: 'EA'
      scope: true
      link: (scope, element, attr) ->

        container = element.closest '.affix-container'

        offset =
          top: parseInt(attr.offsetTop, 10) || 0
          bottom: parseInt(attr.offsetBottom, 10) || 0

        check = ->
          return unless element.is ':visible'

          height = element.outerHeight()
          scroll = $(window).scrollTop()

          bounds = container.offset()
          bounds.delta = container.height()
          bounds.bottom = bounds.top + bounds.delta

          bounds.top -= offset.top
          bounds.bottom -= (height + offset.bottom)

          mode = switch
            when scroll < bounds.top then 'affix-top'
            when height >= bounds.delta then 'affix-top'
            when scroll >= bounds.bottom then 'affix-bottom'
            else 'affix'

          element
            .removeClass 'affix affix-top affix-bottom'
            .addClass mode


        delayed_check = -> setTimeout check, 30

        $(window)
          .on 'scroll', check
          .on 'mouseup', delayed_check

        scope.$on '$destroy', ->
          $(window)
            .off 'scroll', check
            .off 'mouseup', delayed_check

          container = null
  ]).

  factory('$spinner', [
    ->
      extend = angular.extend

      defaults =
        lines: 8             # The number of lines to draw
        length: 6            # The length of each line
        width: 16            # The line thickness
        radius: 2            # The radius of the inner circle
        corners: 1           # Corner roundness (0..1)
        rotate: 0            # The rotation offset
        color: '#f2584e'     # #rgb or #rrggbb
        speed: 1.4           # Rounds per second
        trail: 60            # Afterglow percentage
        shadow: false        # Whether to render a shadow
        hwaccel: true        # Whether to use hardware acceleration
        className: 'spinner' # The CSS class to assign to the spinner
        zIndex: 2e9          # The z-index (defaults to 2000000000)
        top: 'auto'          # Top position relative to parent in px
        left: 'auto'         # Left position relative to parent in px

      $spinner = (options) ->
        new Spinner extend({}, defaults, options)
  ]).

  directive('spinner', [
    '$spinner'
    '$timeout'

    ($spinner, $timeout) ->
      restrict: 'A'
      link: (scope, element, attributes) ->
        spinner = $spinner()
        delay = null

        stop = -> spinner && spinner.stop()

        scope.$watch attributes.spinner, (condition) ->
          $timeout.cancel delay

          if condition
            delay = $timeout ->
                spinner.spin element[0]
              900
          else
            stop()

        scope.$on '$destroy', ->
          $timeout.cancel delay
          stop()
          spinner = null
  ])
