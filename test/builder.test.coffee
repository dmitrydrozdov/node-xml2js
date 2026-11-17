# use zap to run tests, it also detects CoffeeScript files
xml2js = require '../lib/xml2js'
assert = require 'assert'
fs = require 'fs'
path = require 'path'
diff = require 'diff'

# fileName = path.join __dirname, '/fixtures/sample.xml'

# shortcut, because it is quite verbose
equ = assert.equal

# equality test with diff output
diffeq = (expected, actual) ->
  diffless = "Index: test\n===================================================================\n--- test\texpected\n+++ test\tactual\n"
  patch = diff.createPatch('test', expected.trim(), actual.trim(), 'expected', 'actual')
  throw patch unless patch is diffless

# default XML declaration, for compact expected strings
xmldec = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'

# build without pretty printing, so expected output fits on one line
buildCompact = (opts, obj) ->
  opts.renderOpts = pretty: false
  new xml2js.Builder(opts).buildObject obj

module.exports =
  'test building basic XML structure': (test) ->
    expected = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><xml><Label/><MsgId>5850440872586764820</MsgId></xml>'
    obj = {"xml":{"Label":[""],"MsgId":["5850440872586764820"]}}
    builder = new xml2js.Builder renderOpts: pretty: false
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test setting XML declaration': (test) ->
    expected = '<?xml version="1.2" encoding="WTF-8" standalone="no"?><root/>'
    opts =
      renderOpts: pretty: false
      xmldec: 'version': '1.2', 'encoding': 'WTF-8', 'standalone': false
    builder = new xml2js.Builder opts
    actual = builder.buildObject {}
    diffeq expected, actual
    test.finish()

  'test pretty by default': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId>5850440872586764820</MsgId>
      </xml>

    """
    builder = new xml2js.Builder()
    obj = {"xml":{"MsgId":["5850440872586764820"]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test setting indentation': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
          <MsgId>5850440872586764820</MsgId>
      </xml>

    """
    opts = renderOpts: pretty: true, indent: '    '
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":["5850440872586764820"]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test headless option': (test) ->
    expected = """
      <xml>
          <MsgId>5850440872586764820</MsgId>
      </xml>

    """
    opts =
      renderOpts: pretty: true, indent: '    '
      headless: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":["5850440872586764820"]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test allowSurrogateChars option': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
          <MsgId>\uD83D\uDC33</MsgId>
      </xml>

    """
    opts =
      renderOpts: pretty: true, indent: '    '
      allowSurrogateChars: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":["\uD83D\uDC33"]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test explicit rootName is always used: 1. when there is only one element': (test) ->
    expected = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><FOO><MsgId>5850440872586764820</MsgId></FOO>'
    opts = renderOpts: {pretty: false}, rootName: 'FOO'
    builder = new xml2js.Builder opts
    obj = {"MsgId":["5850440872586764820"]}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test explicit rootName is always used: 2. when there are multiple elements': (test) ->
    expected = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><FOO><MsgId>5850440872586764820</MsgId></FOO>'
    opts = renderOpts: {pretty: false}, rootName: 'FOO'
    builder = new xml2js.Builder opts
    obj = {"MsgId":["5850440872586764820"]}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test default rootName is used when there is more than one element in the hash': (test) ->
    expected = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><root><MsgId>5850440872586764820</MsgId><foo>bar</foo></root>'
    opts = renderOpts: pretty: false
    builder = new xml2js.Builder opts
    obj = {"MsgId":["5850440872586764820"],"foo":"bar"}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test when there is only one first-level element in the hash, that is used as root': (test) ->
    expected = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><first><MsgId>5850440872586764820</MsgId><foo>bar</foo></first>'
    opts = renderOpts: pretty: false
    builder = new xml2js.Builder opts
    obj = {"first":{"MsgId":["5850440872586764820"],"foo":"bar"}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test parser -> builder roundtrip': (test) ->
    fileName = path.join __dirname, '/fixtures/build_sample.xml'
    fs.readFile fileName, (err, xmlData) ->
      xmlExpected = xmlData.toString()
      xml2js.parseString xmlData, {'trim': true}, (err, obj) ->
        equ err, null
        builder = new xml2js.Builder({})
        xmlActual = builder.buildObject obj
        diffeq xmlExpected, xmlActual
        test.finish()

  'test building obj with undefined value' : (test) ->
    obj = { node: 'string', anothernode: undefined }
    builder = new xml2js.Builder renderOpts: { pretty: false }
    actual = builder.buildObject(obj);
    expected = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><root><node>string</node><anothernode/></root>'
    equ actual, expected
    test.finish();

  'test building obj with null value' : (test) ->
    obj = { node: 'string', anothernode: null }
    builder = new xml2js.Builder renderOpts: { pretty: false }
    actual = builder.buildObject(obj);
    expected = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><root><node>string</node><anothernode/></root>'
    equ actual, expected
    test.finish();

  'test escapes escaped characters': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId>&amp;amp;&amp;lt;&amp;gt;</MsgId>
      </xml>

    """
    builder = new xml2js.Builder
    obj = {"xml":{"MsgId":["&amp;&lt;&gt;"]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test cdata text nodes': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId><![CDATA[& <<]]></MsgId>
      </xml>

    """
    opts = cdata: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":["& <<"]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test cdata text nodes with escaped end sequence': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId><![CDATA[& <<]]]]><![CDATA[>]]></MsgId>
      </xml>

    """
    opts = cdata: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":["& <<]]>"]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test cdata text nodes with multiple escaped end sequences': (test) ->
    text = "a[i[1]]>0 AND b[j[2]]>0"
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId><![CDATA[a[i[1]]]]><![CDATA[>0 AND b[j[2]]]]><![CDATA[>0]]></MsgId>
      </xml>

    """
    opts = cdata: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":[text]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    xml2js.parseString actual, (err, parsed) ->
      equ err, null
      equ parsed.xml.MsgId[0], text
      test.finish()

  'test uses cdata only for chars &, <, >': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId><![CDATA[& <<]]></MsgId>
        <Message>Hello</Message>
      </xml>

    """
    opts = cdata: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":["& <<"],"Message":["Hello"]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test uses cdata for string values of objects': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId><![CDATA[& <<]]></MsgId>
      </xml>

    """
    opts = cdata: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":"& <<"}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test does not error on non string values when checking for cdata': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId>10</MsgId>
      </xml>

    """
    opts = cdata: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":10}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test does not error on array values when checking for cdata': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <xml>
        <MsgId>10</MsgId>
        <MsgId>12</MsgId>
      </xml>

    """
    opts = cdata: true
    builder = new xml2js.Builder opts
    obj = {"xml":{"MsgId":[10, 12]}}
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  'test building obj with array': (test) ->
    expected = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <root>
        <MsgId>10</MsgId>
        <MsgId2>12</MsgId2>
      </root>

    """
    opts = cdata: true
    builder = new xml2js.Builder opts
    obj = [{"MsgId": 10}, {"MsgId2": 12}]
    actual = builder.buildObject obj
    diffeq expected, actual
    test.finish()

  # cdataElements: per-element wrapping

  'test cdataElements wraps a multi-line ST body inline': (test) ->
    body = "\nh1Extend:=FALSE;\nh2Extend:=FALSE;\nvextend:=FALSE;\nh1Retract:=FALSE;\nh2Retract:=FALSE;\nturn_vacuum_on:=FALSE;\nturn_vacuum_off:=FALSE;"
    expected = xmldec + '\n' +
      '<Algorithm Name="INIT" Comment="Initialization algorithm">\n' +
      '  <ST><![CDATA[\nh1Extend:=FALSE;\nh2Extend:=FALSE;\nvextend:=FALSE;\nh1Retract:=FALSE;\nh2Retract:=FALSE;\nturn_vacuum_on:=FALSE;\nturn_vacuum_off:=FALSE;]]></ST>\n' +
      '</Algorithm>'
    builder = new xml2js.Builder cdataElements: ['ST']
    obj = {Algorithm: {$: {Name: "INIT", Comment: "Initialization algorithm"}, ST: [body]}}
    actual = builder.buildObject obj
    equ actual, expected
    test.finish()

  'test cdataElements wraps regardless of the cdata option': (test) ->
    actual = buildCompact {cdata: false, cdataElements: ['ST']}, {FB: {ST: ["x:=1;"], Comment: ["x:=1;"]}}
    equ actual, xmldec + '<FB><ST><![CDATA[x:=1;]]></ST><Comment>x:=1;</Comment></FB>'
    test.finish()

  'test cdataElements wraps special characters exactly once under cdata': (test) ->
    actual = buildCompact {cdata: true, cdataElements: ['ST']}, {FB: {ST: ["IF a < b THEN x := 1; END_IF;"]}}
    equ actual, xmldec + '<FB><ST><![CDATA[IF a < b THEN x := 1; END_IF;]]></ST></FB>'
    test.finish()

  'test cdataElements with several element names': (test) ->
    actual = buildCompact {cdataElements: ['ST', 'Code']}, {FB: {ST: ["a:=1;"], Code: ["b"], Other: ["c"]}}
    equ actual, xmldec + '<FB><ST><![CDATA[a:=1;]]></ST><Code><![CDATA[b]]></Code><Other>c</Other></FB>'
    test.finish()

  'test cdataElements round trip through the parser keeps the text': (test) ->
    text = "\nx:=1;\ny:=2;"
    builder = new xml2js.Builder cdataElements: ['ST']
    xml = builder.buildObject {FB: {ST: [text]}}
    xml2js.parseString xml, (err, parsed) ->
      equ err, null
      equ parsed.FB.ST[0], text
      test.finish()

  # cdataElements: value shapes

  'test cdataElements wraps a string property value': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, {FB: {ST: "x:=1;"}}
    equ actual, xmldec + '<FB><ST><![CDATA[x:=1;]]></ST></FB>'
    test.finish()

  'test cdataElements wraps each string in an array': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, {FB: {ST: ["x:=1;", "y:=2;"]}}
    equ actual, xmldec + '<FB><ST><![CDATA[x:=1;]]></ST><ST><![CDATA[y:=2;]]></ST></FB>'
    test.finish()

  'test cdataElements wraps the char key alongside attributes': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, {FB: {ST: {$: {Lang: "st"}, _: "x:=1;"}}}
    equ actual, xmldec + '<FB><ST Lang="st"><![CDATA[x:=1;]]></ST></FB>'
    test.finish()

  'test cdataElements wraps non-string scalars': (test) ->
    actual = buildCompact {cdataElements: ['Value']}, {FB: {Value: 10}}
    equ actual, xmldec + '<FB><Value><![CDATA[10]]></Value></FB>'
    actual = buildCompact {cdataElements: ['Flag']}, {FB: {Flag: false}}
    equ actual, xmldec + '<FB><Flag><![CDATA[false]]></Flag></FB>'
    test.finish()

  'test cdataElements wraps root element text': (test) ->
    actual = buildCompact {rootName: 'ST', cdataElements: ['ST']}, "x:=1;"
    equ actual, xmldec + '<ST><![CDATA[x:=1;]]></ST>'
    test.finish()

  'test cdataElements wraps arrays of single-key objects': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, [{ST: "x:=1;"}, {Other: "y"}]
    equ actual, xmldec + '<root><ST><![CDATA[x:=1;]]></ST><Other>y</Other></root>'
    test.finish()

  # cdataElements: empty and absent text

  'test cdataElements writes an empty string as an empty CDATA section': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, {FB: {ST: [""]}}
    equ actual, xmldec + '<FB><ST><![CDATA[]]></ST></FB>'
    test.finish()

  'test cdataElements leaves attribute-only elements without CDATA': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, {FB: {ST: [{$: {Text: "x:=1;"}}]}}
    equ actual, xmldec + '<FB><ST Text="x:=1;"/></FB>'
    test.finish()

  'test cdataElements leaves null and undefined values unchanged': (test) ->
    obj = {FB: {ST: null, Code: undefined}}
    without = buildCompact {cdataElements: []}, obj
    actual = buildCompact {cdataElements: ['ST', 'Code']}, obj
    equ actual, without
    equ actual.indexOf('CDATA'), -1
    test.finish()

  # cdataElements: element name matching

  'test cdataElements matches names case-sensitively': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, {FB: {st: ["x:=1;"]}}
    equ actual, xmldec + '<FB><st>x:=1;</st></FB>'
    test.finish()

  'test cdataElements matches nested elements': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, {FBType: {BasicFB: [{Algorithm: [{$: {Name: "INIT"}, ST: ["x:=1;"]}]}]}}
    equ actual, xmldec + '<FBType><BasicFB><Algorithm Name="INIT"><ST><![CDATA[x:=1;]]></ST></Algorithm></BasicFB></FBType>'
    test.finish()

  'test cdataElements does not wrap descendants of a listed element': (test) ->
    actual = buildCompact {cdataElements: ['Algorithm']}, {FB: {Algorithm: [{ST: ["x:=1;"]}]}}
    equ actual, xmldec + '<FB><Algorithm><ST>x:=1;</ST></Algorithm></FB>'
    test.finish()

  'test cdataElements does not match prototype property names': (test) ->
    actual = buildCompact {cdataElements: ['ST']}, {FB: {"constructor": ["a"], "toString": ["b"]}}
    equ actual, xmldec + '<FB><constructor>a</constructor><toString>b</toString></FB>'
    test.finish()

  'test empty cdataElements leaves output unchanged': (test) ->
    # covers every text path: string array entries (incl. "" and cdata
    # content), string/number/boolean/undefined/null properties, char key with
    # attributes, attribute-only objects, #119 arrays and root text
    obj = {xml: {a: ["x", "", "& <"], b: "str", c: 10, d: true, e: undefined, f: null, g: "", h: {_: "t & u", $: {k: "v"}}, i: {$: {k: "v"}}, j: [{_: "q"}, 5, ""]}}
    for base in [{}, {cdata: true}]
      for input in [obj, [{MsgId: 10}, {MsgId2: "a<b"}, {Z: ""}]]
        withDefault = new xml2js.Builder(base).buildObject input
        withEmpty = new xml2js.Builder(Object.assign {cdataElements: []}, base).buildObject input
        equ withEmpty, withDefault
      rootOpts = Object.assign {rootName: 'R'}, base
      withDefault = new xml2js.Builder(rootOpts).buildObject "a & b"
      withEmpty = new xml2js.Builder(Object.assign {cdataElements: []}, rootOpts).buildObject "a & b"
      equ withEmpty, withDefault
    test.finish()

  # cdataElements: end-sequence escaping

  'test cdataElements splits multiple end sequences': (test) ->
    text = "IF a[i[1]]>0 AND b[j[2]]>0 THEN"
    actual = buildCompact {cdataElements: ['ST']}, {FB: {ST: [text]}}
    equ actual, xmldec + '<FB><ST><![CDATA[IF a[i[1]]]]><![CDATA[>0 AND b[j[2]]]]><![CDATA[>0 THEN]]></ST></FB>'
    xml2js.parseString actual, (err, parsed) ->
      equ err, null
      equ parsed.FB.ST[0], text
      test.finish()
