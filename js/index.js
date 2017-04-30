
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

      var promptLine = "$ ";

      term.prompt = function () {
        term.write('\r\n' + promptLine);
      };


      var cmd = '';

      function runCommand(cmd) {
        console.log(cmd);
      }

      term.on('key', function(key, ev) {
        // TODO this is a terrible test for whether something is printable
        var printable = (
          !ev.altKey && !ev.altGraphKey && !ev.ctrlKey && !ev.metaKey
        );
        
        if(ev.keyCode == 13) {
          runCommand(cmd);
          term.prompt();
          cmd = '';
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

