#!/usr/bin/env node

var cluster = require('cluster');

if (process.env.CLUSTER) {
  if (cluster.isMaster) {
    for (var i=0; i < parseInt(process.env.CLUSTER); i++) {
      cluster.fork();
    }
  } else {
    require("coffee-script");
    require("./server.coffee");
  }
} else {
  require("coffee-script");
  require("./server.coffee");
}
