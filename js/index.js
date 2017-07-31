

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
    document.getElementById('chatInput').focus();
  });
  
  router.get('/console', function(req) {
    tabTo('console');
    document.getElementById('consoleInput').focus();
  });

  router.get('/status', function(req) {
    tabTo('about');
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

function appendLine(txt) {
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



var commandInProgress = false;

function runCommand(cmd, cb) {

  var xhr = new XMLHttpRequest();
  
  if(commandInProgress) return cb(new Error("Command already in progress"));

  commandInProgress = true;

  xhr.open('POST', '/console');
  xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');

  xhr.onload = function() {
    commandInProgress = false;
    if(xhr.status !== 200) {
      return cb(new Error("POST failed: " + xhr.status));
    }
    console.log("GOT:", xhr.responseText);

    cb(null, xhr.responseText);
  };
};

function initDevConsole() {

  function devAppendLine(parent, txt) {
   
    var div = document.createElement('DIV');
    div.innerHTML = entityEncode(txt);
    parent.appendChild(div);

    return div;
  }

  document.getElementById('consoleForm').addEventListener('submit', function(e) {
    e.preventDefault();

    var cmd = document.getElementById('consoleInput').value;
    runCommand(cmd, function(err, res) {
      if(err) return console.error(err);

      var parent = document.getElementById('consoleOutput');

      var lines = res.trim().split(/\r\n/);
      for(i=0; i < lines.length; i++) {
        devAppendLine(parent, lines);
      }

    });
  });
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

