import std/[
  tables,
  httpclient,
  strformat
]

import common


let lib* = newDict(0)

template addV(name, doc: string, item: Value) =
  addV(lib, name, doc, item)

template addF(name, doc: string, args: ProcArgs, body: untyped) =
  addF(lib, name, doc, args, body)

template addS(name, doc: string, args: ProcArgs, body: string) =
  addS(lib, "http.pg", name, doc, args, body)


var client: HttpClient

proc checkClient() =
  if client == nil:
    raise newPgError("HTTP client has not been initialized")


addF("init", """
'init'
UA R ->
Initializes the HTTP client with the useragent UA and maximum redirects R.
""", @[("UA", tString), ("R", tInteger)]):
  let
    redirects = s.pop().intv
    useragent = s.pop().strv

  client = newHttpClient(useragent, redirects)

addF("req", """
'req'
U B T -> str
Sends a request of a specified type T with a body B to a url U,
then returns its response as a string.
""", @[("U", tString), ("B", tString), ("T", tSymbol)]):
  checkClient()

  let
    typ = s.pop().strv
    body = s.pop().strv
    url = s.pop().strv

  var res = ""

  case typ
  of "HEAD":
    res = client.head(url).body()
  of "GET":
    res = client.getContent(url)
  of "POST":
    res = client.postContent(url, body)
  of "PUT":
    res = client.putContent(url, body)
  of "DELETE":
    res = client.deleteContent(url)
  else:
    raise newPgError(fmt"Invalid HTTP request type '{typ}', expected 'HEAD', 'GET', 'POST', 'PUT', or 'DELETE'")
  
  s.push(newString(res))

addS("get", """
'get'
U -> str
Sends a GET request to a URL U.
""", @[("U", tString)]):
  "() /GET req"

addS("post", """
'post'
U B -> str
Sends a POST request to a URL U with a body B.
""", @[("U", tString)]):
  "/POST req"

addS("put", """
'put'
U B -> str
Sends a PUT request to a URL U with a body B.
""", @[("U", tString)]):
  "/POST req"

addS("delete", """
'delete'
U -> str
Sends a DELETE request to a URL U.
""", @[("U", tString)]):
  "() /DELETE req"
