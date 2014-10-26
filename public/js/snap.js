$(function() {

  var socket = io();

  $('#joinButton').click(function() {
    console.log("ADDUSER");

    var username = $('#playerName').val();
    socket.emit('new player', username);

  });

  $('#wordButton').click(function() {
    console.log("WORDBUTTON");

    var word = $('#newWord').val();
    socket.emit('new word', word);

  });


});
