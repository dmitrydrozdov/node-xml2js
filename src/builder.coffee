"use strict"

builder = require 'xmlbuilder'
defaults = require('./defaults').defaults

requiresCDATA = (entry) ->
  return typeof entry is "string" && (entry.indexOf('&') >= 0 || entry.indexOf('>') >= 0 || entry.indexOf('<') >= 0)

# Note that we do this manually instead of using xmlbuilder's `.dat` method
# since it does not support escaping the CDATA close entity (throws an error if
# it exists, and if it's pre-escaped).
wrapCDATA = (entry) ->
  return "<![CDATA[#{escapeCDATA entry}]]>"

escapeCDATA = (entry) ->
  # Split the CDATA section in two;
  # The first contains the ']]'
  # The second contains the '>'
  # When later parsed, it will be put back together as ']]>'
  return entry.replace /\]\]>/g, ']]]]><![CDATA[>'

class exports.Builder
  constructor: (opts) ->
    # copy this versions default options
    @options = {}
    @options[key] = value for own key, value of defaults["0.2"]
    # overwrite them with the specified options, if any
    @options[key] = value for own key, value of opts
    # accept a missing list or a single element name
    if not @options.cdataElements
      @options.cdataElements = []
    else if typeof @options.cdataElements is 'string'
      @options.cdataElements = [@options.cdataElements]

  buildObject: (rootObj) ->
    attrkey = @options.attrkey
    charkey = @options.charkey

    # If there is a sane-looking first element to use as the root,
    # and the user hasn't specified a non-default rootName,
    if ( Object.keys(rootObj).length is 1 ) and ( @options.rootName == defaults['0.2'].rootName )
      # we'll take the first element as the root element
      rootName = Object.keys(rootObj)[0]
      rootObj = rootObj[rootName]
    else
      # otherwise we'll use whatever they've set, or the default
      rootName = @options.rootName

    # elements listed in cdataElements always get their text as CDATA
    isCDATAElement = (name) => @options.cdataElements.indexOf(name) >= 0

    # The one place that decides how text is written into an element: always
    # CDATA for listed elements, on demand under the `cdata` option, plain
    # text otherwise. A null/undefined value is never wrapped.
    writeText = (element, text) =>
      if text? and isCDATAElement element.name
        element.raw wrapCDATA text.toString()
      else if @options.cdata && requiresCDATA text
        element.raw wrapCDATA text
      else
        element.txt text

    # Appends a child element that holds only text. Anything that may become
    # CDATA goes through writeText; other text keeps the original
    # `ele(key, text)` call so existing output is unchanged.
    appendText = (element, key, text) =>
      if (text? and isCDATAElement key) or (@options.cdata && requiresCDATA text)
        writeText(element.ele(key), text).up()
      else
        if not text?
          text = ''
        element.ele(key, text.toString()).up()

    render = (element, obj) =>
      if typeof obj isnt 'object'
        # single element, just append it as text
        writeText element, obj
      else if Array.isArray obj
        # fix issue #119
        for own index, child of obj
          for key, entry of child
            element = render(element.ele(key), entry).up()
      else
        for own key, child of obj
          # Case #1 Attribute
          if key is attrkey
            if typeof child is "object"
              # Inserts tag attributes
              for attr, value of child
                element = element.att(attr, value)

          # Case #2 Char data (CDATA, etc.)
          else if key is charkey
            element = writeText element, child

          # Case #3 Array data
          else if Array.isArray child
            for own index, entry of child
              if typeof entry is 'string'
                element = appendText element, key, entry
              else
                element = render(element.ele(key), entry).up()

          # Case #4 Objects
          else if typeof child is "object"
            element = render(element.ele(key), child).up()

          # Case #5 String and remaining types
          else
            element = appendText element, key, child

      element

    rootElement = builder.create(rootName, @options.xmldec, @options.doctype,
      headless: @options.headless
      allowSurrogateChars: @options.allowSurrogateChars)

    render(rootElement, rootObj).end(@options.renderOpts)
