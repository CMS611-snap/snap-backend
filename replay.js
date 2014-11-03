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

function processEvent(event, cb) {
    var player = event.player;
    if (event.type === 'join') {
        console.info(player + ' joined');
        var socket = io(args['host']);
        players[player] = socket;
        socket.emit('new player', player);
        cb();
        return;
    }
    var socket = players[player];
    if (event.type === 'word') {
        var word = event.word;
        console.info(player + ' submitted ' + word);
        socket.emit('new word', word);
        cb();
        return;
    }
    console.warn('unknown event type: ' + event.type);
    cb();
}

var trace = yaml.load(args['trace']);
var timeMultiplier = trace.config.timeUnitsMillis || 1;

var startTime = Date.now();

// TODO(tchajed): sort events by offset

function scheduleEvent(num) {
    if (num >= trace.events.length) {
        // we're done
        process.exit(0);
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
