
console.log("testing");

function pageInit() {
  try {

    var te = document.getElementById('terminal-container');
    console.log("TERMINAL CONTAINER", te);
    if(te) {

      console.log("GOT HERE");

      var Terminal = require('xterm');
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
        
        xhr.open('POST', '/serial');
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
// we should URI decode but the nodemcu webserver doesn't care
// and can't uridecode anyway
//        var toSend = encodeURI('cmd=' + cmd)
        var toSend = 'cmd=' + cmd;
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

document.addEventListener("DOMContentLoaded", pageInit);

