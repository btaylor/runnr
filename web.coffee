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

express = require 'express'
request = require 'request'
querystring = require 'querystring'
MemoryStore = require('express').session.MemoryStore

Rdio = require './lib/rdio'
cred = require './credentials'

app = express.createServer()
app.configure 'development', () ->
  app.use express.logger()
  app.use express.errorHandler
    dumpExceptions: true,
    showStack: true

  app.use express.cookieParser()
  app.use express.session
    secret: 'sekrit'
    store: new MemoryStore
      reapInterval: 6000 * 10


RdioException = (msg) ->
  @name = "RdioException"
  Error.call this, msg
  Error.captureStackTrace this, arguments.callee

EchoNestException = (msg) ->
  @name = "EchoNestException"
  Error.call this, msg
  Error.captureStackTrace this, arguments.callee


app.get '/', (req, res) ->
  accessToken = req.session.accessToken
  accessTokenSecret = req.session.accessTokenSecret
  if not accessToken? or not accessTokenSecret?
    res.send '<a href="/login">Login to rdio to continue.</a>'
    return

  # Get playlist from echonest
  # http://developer.echonest.com/api/v4/playlist/static?api_key=N6E4NIOVYMTHNDM8J&style=80s&style=powerpop&min_tempo=150&max_tempo=180&type=artist-description&results=5&bucket=id:rdio-us-streaming&limit=true
  ECHONEST_API_HOST = 'http://developer.echonest.com/api/v4'

  queryParams =
    api_key: cred.ECHONEST_API_KEY
    style: "80s"
    min_tempo: 150
    max_tempo: 180
    type: "artist-description"
    results: 25
    bucket: "id:rdio-us-streaming"
    limit: true

  uri = "#{ECHONEST_API_HOST}/playlist/static?" + querystring.stringify(queryParams)
  console.log uri
  request uri, (err, res, body) ->
    #throw new EchoNestException err if err?
    json = JSON.parse body
    console.log(json.response.songs)

    playlistSongs = (s.foreign_ids[0].foreign_id.split(':')[2] for s in json.response.songs)
    console.log playlistSongs

    rdio = new Rdio [cred.RDIO_CONSUMER_KEY, cred.RDIO_CONSUMER_SECRET],
                    [accessToken, accessTokenSecret]
    params =
      name: "80s High Tempo Mix"
      description: "A runnr generated playlist"
      tracks: playlistSongs.join ', '

    rdio.call 'createPlaylist', params, (err, data) ->
      throw new RdioException err if err?

      playlist = data.result
      res.send "Created playlist #{playlist.name}!"

app.get '/login', (req, res) ->
  callbackURL = 'http://localhost:8000/callback'
  rdio = new Rdio [cred.RDIO_CONSUMER_KEY, cred.RDIO_CONSUMER_SECRET]
  rdio.beginAuthentication callbackURL, (err, authURL) ->
      throw new RdioException err if err?
      [req.session.requestToken, req.session.requestTokenSecret] = rdio.token
      res.redirect authURL

app.get '/callback', (req, res) ->
  verifier = req.query.oauth_verifier
  requestToken = req.session.requestToken
  requestTokenSecret = req.session.requestTokenSecret
  console.log "verifier = #{verifier}, requestToken = #{requestToken}, requestTokenSecret = #{requestTokenSecret}"
  res.redirect '/logout' if not verifier? or not requestToken? or not requestTokenSecret?

  rdio = new Rdio [cred.RDIO_CONSUMER_KEY, cred.RDIO_CONSUMER_SECRET],
                  [requestToken, requestTokenSecret]
  rdio.completeAuthentication verifier, (err) ->
    throw new RdioException err if err?

    [req.session.accessToken, req.session.accessTokenSecret] = rdio.token

    delete req.session.requestToken
    delete req.session.requestTokenSecret

    res.redirect '/'

app.get '/logout', (req, res) ->
  delete req.session.accessToken
  delete req.session.accessTokenSecret
  res.redirect '/'


app.listen 8000
console.log 'Now listening on http://localhost:8000'
