$(function() {

  var socket = io();
  
  $('#setTopicButton').click(function() {
    var topic = $('#topic').val();
    console.log("Set Topic To: " + topic);
    socket.emit('set topic', topic);
  });  

  $('#startGameButton').click(function() {
    console.log("Starting Game...");
    socket.emit('start game');
  });

  $('#stopGameButton').click(function() {
    console.log("Stopping Game...");
    socket.emit('stop game');
  });


  $('#joinButton').click(function() {
    var username = $('#playerName').val();
    console.log("ADDUSER: " + username);
    socket.emit('new player', username);
  });

  $('#wordButton').click(function() {
    var word = $('#newWord').val();
    console.log("WORDBUTTON: " + word);
    socket.emit('new word', word);
  });
  socket.on('new topic', function(topic){
    console.log('new topic: ' + topic);
    $('#info').append('TOPIC is : ' + JSON.stringify(topic) + '<br>');
  });

  socket.on('game started', function(info) {
    console.log('game started');
    $('#info').append('<br>' + 'GAME STARTED!! ');
    if (info.gameId) {
      var url = '/admin/games/' + info.gameId;
      $('#info').append('<a href="' + url + '">(word cloud)</a>');
    }
    $('#info').append('<br>');
  });

  socket.on('snap', function(data) {
    console.log('snap ' + data);
    $('#info').append(JSON.stringify(data) + '<br>');
  });

  socket.on('game over', function(data) {
    console.log('game over ' + data);
    winnerNames = data.winners.map(function(p) {
        return p.name;
    });
    $('#info').append("GAME OVER: winners: " + winnerNames.join(", ") + '<br>');
    var scores = [];
    for (var i = 0; i < data.scores.length; i++) {
        var score = data.scores[i];
        scores.push(score.player.name + ": " + score.score);
    }
    $('#info').append("scores: " + scores.join(", ") + '<br>');
  });

  socket.on('disconnect', function() {
    $('#info').empty();
  })

  var words = [];

  var updateWordCloud = function(data) {
    var words = data.words;
    var wordsListed = '';
    for (var i = 0; i < words.length; i++) {
      wordsListed += words[i].text + ': ' + words[i].score + '<br/>'
    }
    $('#wordlist').html(wordsListed);

    d3.select("#graph").select("svg").remove();

    wordcloud.words(words);
    wordcloud.start();
  }

  socket.on('wordcloud', function(data) {
    console.log('wordcloud ' + JSON.stringify(data));
    updateWordCloud(data);
  });

  $.get("/rpc/wordcloud", function(data) {
      console.log('wordcloud ' + JSON.stringify(data));
      updateWordCloud(data);
  });

  $.get('/rpc/setup/endConfig', function(data) {
      function isPresent(val) {
          return (val && val != 0 && !isNaN(val));
      }
      if (isPresent(data.maxSeconds)) {
          $("#endTime").val(data.maxSeconds);
      }
      if (isPresent(data.maxScore)) {
          $("#endScore").val(data.maxScore);
      }
      if (isPresent(data.maxWords)) {
          $("#endWords").val(data.maxWords);
      }
  });

  $.get('/rpc/setup/metadata', function(data) {
      var metadata = data.metadata;
      $("#facilitator").val(metadata.facilitator || "");
      $("#event").val(metadata.event || "");
      if (metadata.numPlayers && metadata.numPlayers !== 0) {
          $("#numPlayers").val(metadata.numPlayers.toString());
      }
      if (data.topic) {
          $("#topic").val(data.topic);
      }
  });

  (function() {
      $.notify.defaults({
          autoHideDelay: 3000
      });
      function parseNumber(selector) {
          var number = parseInt($(selector).val());
          if (isNaN(number)) {
              return 0;
          }
          return number;
      }

      $("#endForm").submit(function() {
          $.post("/rpc/setup/endConfig", {
              "maxSeconds": parseNumber("#endTime"),
              "maxScore": parseNumber("#endScore"),
              "maxWords": parseNumber("#endWords")
          }, function() {
              $.notify('Set end conditions', 'success');
          });
          return false;
      });

      $("#metadataForm").submit(function() {
          $.post("/rpc/setup/metadata", {
              "facilitator": $("#facilitator").val(),
              "event": $("#event").val(),
              "numPlayers": parseNumber("#numPlayers")
          }, function() {
              $.notify('Set game info', 'success');
          });
          return false;
      });
  })()


  var fill = d3.scale.category20();

  var wordcloud = d3.layout.cloud()
      .size([300, 300])
      .words(words)
      .padding(5)
      .rotate(function() { return 0; })//~~(Math.random() * 2) * 90; })
      .font("Impact")
      .fontSize(function(d) { return d.size; })
      .on("end", draw)
      .start();


  function draw(words) {
    d3.select("#graph").append("svg")
        .attr("width", 300)
        .attr("height", 300)
      .append("g")
        .attr("transform", "translate(150,150)")
      .selectAll("text")
        .data(words)
      .enter().append("text")
        .style("font-size", function(d) { return d.size + "px"; })
        .style("font-family", "Impact")
        .style("fill", function(d, i) { return fill(i); })
        .attr("text-anchor", "middle")
        .attr("transform", function(d) {
          return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")";
        })
        .text(function(d) { return d.text; });
  }
});
