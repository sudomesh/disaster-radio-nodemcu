
// TODO this adds 58 kB to bundle.js
// need to find a smaller alternative
var entities = new (require('html-entities').AllHtmlEntities);

var myName;

function error(msg) {
  // TODO show this to the user
  console.error(msg);
}

function hexEncode(msgStr) {
  var msg = '';
  var i;
  for(i=0; i < msgStr.length; i++) {
    msg += msgStr.charCodeAt(i).toString(16);
  }
  return msg;
}

function hexDecode(msg) {
  var str = '';
  var i, cur;
  for(i=0; i < msg.length - 1;  i+=2) {
    cur = msg.substr(i, 2);
    str += String.fromCharCode(parseInt(cur, 16));
  }
  return str;
}

function receiveMessages(cb) {
  var req = new XMLHttpRequest();

  req.addEventListener("error", function(err) {
    return cb(err);
  });

  req.addEventListener("load", function(e) {
    if(req.status !== 200) {
      return cb("Got unexpected status: " + req.status + ' ' + req.statusText)
    }
    
    console.log("Got:" + req.responseText);
    cb(null, req.responseText);
  });
  req.open("POST", "/receive");

  var toSend = 'arg=foo';
  req.send(toSend);
}

function receiveOnce() {
  receiveMessages(function(err, data) {
    if(err) {
      return console.error("Error: ", err);
    }

    data = hexDecode(data);
    appendLine(data, 'remote');
  });
}

function receiveLoop(delay) {
  delay = delay || 1000;
  receiveMessages(function(err, data) {
    if(err) {
      console.error("Error: ", err);
    } else {
      
    }

    setTimeout(receiveLoop, delay);
  });
}

function sendMessage(msg, cb) {

  // convert to hex string
  msg = hexEncode(msg);

  // TODO needs to check byte length rather than character length
  if(msg.length > 512) {
    return cb(new Error("message must be shorter than 256 bytes"));
  }
  if(msg.length <= 0) {
    return cb(new Error("zero length message"));
  }

  var req = new XMLHttpRequest();

  req.addEventListener("error", function(err) {
    return cb(err);
  });

  req.addEventListener("load", function(e) {
    if(req.status !== 200) {
      return cb("Got unexpected status: " + req.status + ' ' + req.statusText)
    }
    
    console.log("Got:" + req.responseText);
    cb();
  });
  req.open("POST", "/transmit");

  var toSend = 'arg=' + msg;
  console.log("SENDING:", toSend)
  req.send(toSend);
}

function appendLine(txt, classes) {
  var view = document.getElementById('chat');

  var span = document.createElement('DIV');

  span.innerHTML = entities.encode(txt);
  span.className = classes || 'unsent';
  view.appendChild(span);

  return span;
}

function initChat() {
  var form = document.getElementById('chatForm');
  var input = document.getElementById('chatInput');

  form.onsubmit = function(e) {
    e.stopPropagation();

    if(!myName) {
      myName = input.value.replace(/\s+/g, '_').replace(/[^\d\w_-]/g, '');
      appendLine("Name set to: <" + myName + ">", 'status');
      input.placeholder = '';
    } else {
      var msg = '<'+myName+'> '+input.value;
      var node = appendLine(msg);
      sendMessage(msg, function(err) {
        if(err) return error(err);
        console.log("message sent");

        node.className = '';
      });
    }

    input.value = '';

    return false;
  };

  document.getElementById("receiveButton").onclick = function(e) {
    receiveOnce();
  };

//  receiveLoop();
}




function initDevConsole() {
  try {

    var te = document.getElementById('terminal-container');

    if(te) {

//      var Terminal = require('xterm');
      if(Terminal) console.log("LOADED TERM");

      var term = new Terminal();

      term.open(te);

      var promptLine = '';

      term.prompt = function () {
        term.write('\r\n' + promptLine);
      };

      
      var commandInProgress = false;

      function runCommand(cmd, cb) {

        var xhr = new XMLHttpRequest();
        
        xhr.open('POST', '/console');
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onload = function() {
          var commandInProgress = false;
          if(xhr.status !== 200) {
            return cb("POST failed: " + xhr.status);
          }
          console.log("GOT:", xhr.responseText);
          cb(null, xhr.responseText);
        };

// TODO
// we should URI encode but the nodemcu webserver doesn't care
// and can't uridecode anyway
//        var toSend = encodeURI('arg=' + cmd)
        var toSend = 'arg=' + cmd;
        console.log("SENDING:", toSend)
        xhr.send(toSend);
      }

      var cmd = '';

      term.on('key', function(key, ev) {
        // TODO this is a terrible test for whether something is printable
        var printable = (
          !ev.altKey && !ev.altGraphKey && !ev.ctrlKey && !ev.metaKey
        );
        
        if(ev.keyCode == 13) {
          if(commandInProgress) return;
          if(!cmd.length) cmd = "\n";
          var commandInProgress = true;
          runCommand(cmd, function(err, res) {
            var commandInProgress = false;
            if(err) return console.error(err);
            
            term.write(res);
          });

          cmd = '';
          term.prompt();

        } else if(ev.keyCode == 8) {
          // Do not delete the prompt
          if(term.x > promptLine.length) {
            term.write('\b \b');
            cmd = cmd.slice(0, -1);
          }
        } else if(printable) {
          cmd += key;
          term.write(key);
        }
      });

      term.prompt();
    }

  } catch(e) {
    // ignore error 
    // since xterm is only installed
    // as a developer dependency
  }

}



function pageInit() {

  initChat();

  initDevConsole();
}

document.addEventListener("DOMContentLoaded", pageInit);

