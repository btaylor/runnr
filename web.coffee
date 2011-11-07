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
MemoryStore = require('express').session.MemoryStore

cred = require './credentials'
RdioClient = require './rdioClient'
EchoNestClient = require './echoNestClient'

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

rdio = new RdioClient cred.RDIO_CONSUMER_KEY, cred.RDIO_CONSUMER_SECRET
echoNestClient = new EchoNestClient cred.ECHONEST_API_KEY

app.get '/login', rdio.loginHandler
app.get '/callback', rdio.callbackHandler
app.get '/logout', rdio.logoutHandler

app.get '/', (req, res) ->
  if not rdio.loggedIn()
    res.send '<a href="/login">Login to rdio to continue.</a>'
    return

  params =
    style: "80s"
    min_tempo: 150
    max_tempo: 180
    type: "artist-description"
    results: 25
    bucket: "id:rdio-us-streaming"
    limit: true

  echoNestClient.staticPlaylist params, (err, json) ->
    throw new EchoNestException err if err?

    playlistSongs = (s.foreign_ids[0].foreign_id.split(':')[2] for s in json.response.songs)

    rdio.authenticate req.session
    rdio.createPlaylist "80s High Tempo Mix", "A runnr generated playlist", playlistSongs, (playlist) ->
      console.log "Created playlist #{playlist.name}!"

  res.send ""


app.listen 8000
console.log 'Now listening on http://localhost:8000'
