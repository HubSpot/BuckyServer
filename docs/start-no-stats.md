If you don't already have a stats platform, this is a great opportunity
for you to start learning more about what is going on in your system.

A graphing tool allows you to identify both long-term bottlenecks and
short-term issues in your software, at very little hands-on cost.

There are two major graphing and storage platforms in the OS world
right now: [Graphite](http://graphite.wikidot.com/) (often with
[statsd](https://github.com/etsy/statsd/)) and [OpenTSDB](http://opentsdb.net/).

Choosing a Platform
-------------------

### Graphite Advantages
 
- It's more popular and has been around longer
- It has a larger collection of functions
- It doesn't require setting up HBase

### OpenTSDB Advantages

- It can handle more data
- It stores every datapoint, not aggregations

Graphite Install
----------------

There are install instructions on the [Graphite Wiki](http://graphite.wikidot.com/installation).

Next, you'll want to install [statsd](https://github.com/etsy/statsd/) to support aggregation of metrics.

It's a good idea to take a peek at the
[Graphite config](https://github.com/etsy/statsd/blob/master/docs/graphite.md)

Put the hostname/port of your statsd install in the
[Bucky config](https://github.com/HubSpot/BuckyServer/blob/master/config/default.yaml).

OpenTSDB Install
----------------

You can find OpenTSDB instructions [here](http://opentsdb.net/getting-started.html).

Plug the hostname/port of your install in the
[Bucky config](https://github.com/HubSpot/BuckyServer/blob/master/config/default.yaml).
