{exec} = require 'child_process'
path = require 'path'
fusker = require 'fusker'

module.exports =
  start: (port, username, password) ->
    username ?= 'admin'
    password ?= 'password'
    fusker.config.dir = path.join __dirname, '../public'
    fusker.config.silent = true
    server = fusker.http.createServer port, username, password
    io = fusker.socket.listen server
    io.sockets.on 'connection', (socket) ->
      socket.cwd ?= process.cwd()
      socket.emit 'cwd', socket.cwd
      
      socket.on 'command', (msg) ->
        exec msg, {cwd: socket.cwd}, (err, stdout, stderr) ->
          if !err and !stderr and msg.indexOf('cd ') is 0
            socket.cwd = path.join socket.cwd, msg.replace 'cd ', ''
          socket.emit 'cwd', socket.cwd
          socket.emit 'stdout', stdout if stdout? and stdout isnt ""
          socket.emit 'stderr', stderr if stderr? and stderr isnt ""
          socket.emit 'error', err.message if err? and !stderr
