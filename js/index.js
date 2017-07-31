

// hmm, this module is 11 kB... i feel like that's a lot for what it does
// but other similar modules like ent, entities and html-entities are a lot bigger
var entityEncode = require('stringify-entities');
var Grapnel = require('grapnel');

$ = function(q) {
  return document.querySelectorAll(q);
}

function notFound() {
  return '<h3>404 not found</h3>';
}


function initRouting() {
  
  var router = new Grapnel({pushState: true});
  
  function appsRoute(req) {
    tabTo('apps');
  };
    
  router.get('', appsRoute);
  router.get('/', appsRoute);
  router.get('/apps', appsRoute);
  
  router.get('/chat', function(req) {
    tabTo('chat');
  });
  
  router.get('/console', function(req) {
    tabTo('console');
  });

  router.get('/status', function(req) {
    tabTo('status');
  });
  
  router.get('/about', function(req) {
    tabTo('about');
  });

  document.addEventListener('click', function(e) {
    if(e.target.tagName === 'A' && e.target.href && e.target.href !== '#') {
      e.preventDefault();
      router.navigate(e.target.href);
    }
  });
}

function tabTo(tabID) {
  var tabs = $('.tab');
  tabs.forEach(function(tab) {
    // on mouse enter
    tab.classList.remove('active-tab');
  });

  $('#'+tabID)[0].classList.add('active-tab');
}


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

  span.innerHTML = entityEncode(txt);
  span.className = classes || 'unsent';
  view.appendChild(span);

  return span;
}





var myName;

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


function initMenu() {

  // menu show/hide on click
  $('#menu .icon')[0].addEventListener('click', function(e) {
    e.stopPropagation();

    if(getComputedStyle($('#menu ul')[0])['display'] === 'none') {
      $('#menu ul')[0].style.display = 'block';
    } else {
      $('#menu ul')[0].style.display = 'none';
    }
  });
  $('#menu')[0].addEventListener('mousedown', function(e) {
    e.stopPropagation();    
  });

  function unHighlight() {
    // menu mouse-over highlighting
    var els = $('#menu ul li');
    els.forEach(function(el) {
      // on mouse enter
      el.classList.remove('highlight');
    });
  }  

  function setCurrent(el) {
    // menu mouse-over highlighting
    var els = $('#menu ul li');
    els.forEach(function(cur) {
      if(cur === el) return;
      // on mouse enter
      cur.classList.remove('current');
    });
    el.classList.add('current');
  }

  // menu mouse-over highlighting
  var els = $('#menu ul li');
  els.forEach(function(el) {
    el.addEventListener('mouseover', function(e) {
      unHighlight();
      el.classList.add('highlight');
    });

    el.addEventListener('mouseout', function(e) {
      unHighlight();
      $('#menu ul li.current')[0].classList.add('highlight');
    });

    el.addEventListener('click', function(e) {
      setCurrent(el);
      $('#menu ul')[0].style.display = 'none';
    });
  });

  // menu disappears when clicking elsewhere
  document.body.addEventListener('mousedown', function(e) {
    $('#menu ul')[0].style.display = 'none';
  });


}


function pageInit() {


  initMenu();

  initRouting();

  initChat();

  initDevConsole();
}

document.addEventListener("DOMContentLoaded", pageInit);

