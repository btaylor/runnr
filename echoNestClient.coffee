#
# Copyright (C) 2011 by Brad Taylor <brad@getoded.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

request = require 'request'
querystring = require 'querystring'

EchoNestException = (msg) ->
  @name = "EchoNestException"
  Error.call this, msg
  Error.captureStackTrace this, arguments.callee

ECHONEST_API_HOST = 'http://developer.echonest.com/api/v4'

class EchoNestClient
  constructor: (@apiKey) ->

  request: (type, method, params, callback) ->
    params['api_key'] = @apiKey

    uri = "#{ECHONEST_API_HOST}/#{type}/#{method}?#{querystring.stringify(params)}"
    request uri, (err, res, body) ->
      json = JSON.parse body
      callback err, json

  staticPlaylist: (params, callback) ->
    @request 'playlist', 'static', params, callback

module.exports = EchoNestClient
