#!/usr/bin/env node
var io = require('socket.io-client');
var yaml = require('yamljs');
var parseArgs = require('minimist');


var args = parseArgs(process.argv, {
                    default: {
                        'trace': 'trace.yaml',
                        'host': 'http://localhost:8080'
                    }});

var players = {};
players['moderator'] = io(args['host'], {multiplex: false});

function processEvent(event, cb) {
    var uuid = event.player;
    var name = event.name;
    if (event.type === 'join') {
        console.info(name + ' joined (' + uuid + ')');
        var socket = io(args['host'], {multiplex: false});
        players[uuid] = socket;
        socket.emit('new player', name);
        cb();
        return;
    }
    var socket = players[uuid];
    if (event.type === 'word') {
        var word = event.word;
        console.info(uuid + ' submitted ' + word);
        socket.emit('new word', word, function() {});
        cb();
        return;
    }
    if (event.type === 'start') {
      socket.emit('start game');
      cb();
      return;
    }
    if (event.type === 'stop') {
      socket.emit('stop game');
      cb();
      return;
    }
    console.warn('unknown event type: ' + event.type);
    cb();
}

var trace = yaml.load(args['trace']);
var timeMultiplier = trace.config.timeUnitsMillis || 1;
if (timeMultiplier != 1) {
  console.log('scaling times by ' + timeMultiplier);
}

var startTime = Date.now();

// TODO(tchajed): sort events by offset

function scheduleEvent(num) {
    if (num >= trace.events.length) {
        // we're done
        console.log("finished trace");
        setTimeout(function() {
          process.exit(0);
        }, 1000);
        return;
    }
    var event = trace.events[num];
    var time = startTime + event.time * timeMultiplier;
    var now = Date.now();
    setTimeout(function() {
        processEvent(event, function() {
            scheduleEvent(num + 1);
        });
    }, time - now);
}

scheduleEvent(0);
