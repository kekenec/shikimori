using 'DynamicElements'
class DynamicElements.Comment extends ShikiEditable
  _type: -> 'comment'
  _type_label: -> 'Комментарий'

  initialize: ->
    # data attribute is set in Comments.Tracker
    @model = @$root.data 'model'
    @user_id = @$root.data('user_id')

    if SHIKI_USER.ignored_users.includes(@user_id)
      @$root.remove()
      return

    @$body = @$('.body')

    @_activate_appear_marker() if @model && !@model.is_viewed

    if @$inner.hasClass('check_height')
      $images = @$body.find('img')
      if $images.exists()
        # картинки могут быть уменьшены image_normalizer'ом, поэтому делаем с задержкой
        $images.imagesLoaded => @_check_height.delay(10)
      else
        @_check_height()

    # ответ на комментарий
    @$('.item-reply').on 'click', (e) =>
      comment_id = @root.id
      nickname = @$root.data 'user_nickname'
      reply = "[#{@_type()}=#{comment_id}]#{nickname}[/#{@_type()}], "

      @$root.trigger 'comment:reply', [reply, @_is_offtopic()]

    # edit message
    @$('.main-controls .item-edit')
      .on 'ajax:before', @_shade
      .on 'ajax:complete', @_unshade
      .on 'ajax:success', (e, html, status, xhr) =>
        $editor = $(html)
        new ShikiEditor($editor).edit_comment(@$root)

    # moderation
    @$('.main-controls .item-moderation').on 'click', =>
      @$('.main-controls').hide()
      @$('.moderation-controls').show()

    @$('.item-spoiler, .item-abuse').on 'ajax:before', (e) ->
      reason = prompt $(@).data('reason-prompt')

      if reason == null
        false
      else
        $(@).data form:
          reason: reason

    # пометка комментария обзором/оффтопиком
    @$('.item-summary,.item-offtopic,.item-spoiler,.item-abuse,.b-offtopic_marker,.b-summary_marker').on 'ajax:success', (e, data, satus, xhr) =>
      if 'affected_ids' of data && data.affected_ids.length
        data.affected_ids.each (id) ->
          $(".b-comment##{id}").view().mark(data.kind, data.value)
        $.notice marker_message(data)
      else
        $.notice 'Ваш запрос будет рассмотрен. Домо аригато.'

      @$('.item-moderation-cancel').trigger('click')

    # cancel moderation
    @$('.moderation-controls .item-moderation-cancel').on 'click', =>
      #@$('.main-controls').show()
      #@$('.moderation-controls').hide()
      @_close_aside()

    # кнопка бана или предупреждения
    @$('.item-ban').on 'ajax:success', (e, html) =>
      @$('.moderation-ban').html(html).show()
      @_close_aside()

    # закрытие формы бана
    @$('.moderation-ban').on 'click', '.cancel', =>
      @$('.moderation-ban').hide()

    # сабмит формы бана
    @$('.moderation-ban').on 'ajax:success', 'form', (e, response) =>
      @_replace response.html

    # изменение ответов
    @on 'faye:comment:set_replies', (e, data) =>
      @$('.b-replies').remove()
      $(data.replies_html).appendTo(@$body).process()

    # хештег со ссылкой на комментарий
    @$('.hash').one 'mouseover', ->
      $node = $(@)
      $node
        .attr(href: $node.data('url'))
        .change_tag('a')

  # пометка комментария маркером (оффтопик/отзыв)
  mark: (kind, value) ->
    @$(".item-#{kind}").toggleClass('selected', value)
    @$(".b-#{kind}_marker").toggle(value)

  # оффтопиковый ли данный комментарий
  _is_offtopic: ->
    @$('.b-offtopic_marker').css('display') != 'none'

# текст сообщения, отображаемый при изменении маркера
marker_message = (data) ->
  if data.value
    if data.kind == 'offtopic'
      if data.affected_ids.length > 1
        $.notice 'Комментарии помечены оффтопиком'
      else
        $.notice 'Комментарий помечен оффтопиком'
    else
      $.notice 'Комментарий помечен отзывом'

  else
    if data.kind == 'offtopic'
      $.notice 'Метка оффтопика снята'
    else
      $.notice 'Метка отзыва снята'