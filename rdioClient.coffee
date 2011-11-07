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

Rdio = require './lib/rdio'

RdioException = (msg) ->
  @name = "RdioException"
  Error.call this, msg
  Error.captureStackTrace this, arguments.callee

class RdioClient
  constructor: (@consumerKey, @consumerSecret) ->

  loginHandler: (req, res) =>
    callbackURL = 'http://localhost:8000/callback'
    @rdio = new Rdio [@consumerKey, @consumerSecret]
    @rdio.beginAuthentication callbackURL, (err, authURL) =>
      throw new RdioException err if err?
      [req.session.requestToken, req.session.requestTokenSecret] = @rdio.token
      res.redirect authURL

  callbackHandler: (req, res) =>
   verifier = req.query.oauth_verifier
   requestToken = req.session.requestToken
   requestTokenSecret = req.session.requestTokenSecret
   res.redirect '/logout' if not verifier? or not requestToken? or not requestTokenSecret?

   @rdio = new Rdio [@consumerKey, @consumerSecret], [requestToken, requestTokenSecret]
   @rdio.completeAuthentication verifier, (err) =>
     throw new RdioException err if err?

     [req.session.accessToken, req.session.accessTokenSecret] = @rdio.token

     delete req.session.requestToken
     delete req.session.requestTokenSecret

     res.redirect '/'

  logoutHandler: (req, res) =>
    delete req.session.accessToken
    delete req.session.accessTokenSecret
    res.redirect '/'

  authenticate: (session) ->
    @rdio = new Rdio [@consumerKey, @consumerSecret],
                     [session.accessToken, session.accessTokenSecret]

  loggedIn: () ->
    return @rdio?

  createPlaylist: (name, description, tracks, callback) ->
    params =
      name: name
      description: description
      tracks: tracks.join ', '

    @rdio.call 'createPlaylist', params, (err, data) =>
      throw new RdioException err if err?
      callback data.result

module.exports = RdioClient
