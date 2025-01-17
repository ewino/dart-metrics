// Copyright (c) 2014, Alexandre Ardhuin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of metrics_graphite;

/// A reporter which publishes metric values to a Graphite server.
class GraphiteReporter extends ScheduledReporter {
  static final _log = new Logger('GraphiteReporter');

  final Clock _clock;
  final String? _prefix;
  final GraphiteSender _graphite;

  factory GraphiteReporter(MetricRegistry registry, GraphiteSender graphite, {String? prefix, Clock? clock, TimeUnit? rateUnit, TimeUnit? durationUnit, MetricFilter? where})
      => new GraphiteReporter._(registry,
          graphite,
          prefix,
          clock ?? Clock.defaultClock,
          rateUnit ?? TimeUnit.SECONDS,
          durationUnit ?? TimeUnit.MILLISECONDS,
          where: where);

  GraphiteReporter._(MetricRegistry registry, this._graphite, this._prefix, this._clock, TimeUnit rateUnit, TimeUnit durationUnit, {MetricFilter? where})
      : super(registry, rateUnit, durationUnit, where: where);

  @override
  void reportMetrics({Map<String, Gauge>? gauges,
                      Map<String, Counter>? counters,
                      Map<String, Histogram>? histograms,
                      Map<String, Meter>? meters,
                      Map<String, Timer>? timers}) {
    final timeInSeconds = _clock.time ~/ 1000;

    try {
      if (!_graphite.isConnected) {
        _graphite.connect();
      }

      if (gauges != null) {
        gauges.forEach((name, gauge) {
          reportGauge(timeInSeconds, name, gauge);
        });
      }

      if (counters != null) {
        counters.forEach((name, counter) {
          reportCounter(timeInSeconds, name, counter);
        });
      }

      if (histograms != null) {
        histograms.forEach((name, histogram) {
          reportHistogram(timeInSeconds, name, histogram);
        });
      }

      if (meters != null) {
        meters.forEach((name, meter) {
          reportMeter(timeInSeconds, name, meter);
        });
      }

      if (timers != null) {
        timers.forEach((name, timer) {
          reportTimer(timeInSeconds, name, timer);
        });
      }

      _graphite.flush();
    } on IOException catch (e) {
      _log.warning("Unable to report to Graphite", e);
      try {
        _graphite.close();
      } on IOException catch (e1) {
        _log.warning("Error closing Graphite", e1);
      }
    }
  }

  @override
  void stop() {
    try {
      super.stop();
    } finally {
      try {
        _graphite.close();
      } on IOException catch (e) {
        _log.fine("Error disconnecting from Graphite", e);
      }
    }
  }

  void reportGauge(int timeInSeconds, String name, Gauge gauge) {
    _report(timeInSeconds, name, {'value': gauge.value});
  }

  void reportCounter(int timeInSeconds, String name, Counter counter) {
    _report(timeInSeconds, name, {'count': counter.count});
  }

  void reportHistogram(int timeInSeconds, String name, Histogram histogram) {
    final snapshot = histogram.snapshot;
    _report(timeInSeconds, name, {
      'count': histogram.count,
      'max': snapshot.max,
      'mean': snapshot.mean,
      'min': snapshot.min,
      'stddev': snapshot.stdDev,
      'p50': snapshot.median,
      'p75': snapshot.get75thPercentile(),
      'p95': snapshot.get95thPercentile(),
      'p98': snapshot.get98thPercentile(),
      'p99': snapshot.get99thPercentile(),
      'p999': snapshot.get999thPercentile(),
    });
  }

  void reportMeter(int timeInSeconds, String name, Meter meter) {
    _report(timeInSeconds, name, {
      'count': meter.count,
      'mean_rate': convertRate(meter.meanRate),
      'm1_rate': convertRate(meter.oneMinuteRate),
      'm5_rate': convertRate(meter.fiveMinuteRate),
      'm15_rate': convertRate(meter.fifteenMinuteRate),
      'rate_unit': 'events/${rateUnit.name}',
    });
  }

  void reportTimer(int timeInSeconds, String name, Timer timer) {
    final snapshot = timer.snapshot;
    _report(timeInSeconds, name, {
      'count': timer.count,
      'max': convertDuration(snapshot.max),
      'mean': convertDuration(snapshot.mean),
      'min': convertDuration(snapshot.min),
      'stddev': convertDuration(snapshot.stdDev),
      'p50': convertDuration(snapshot.median),
      'p75': convertDuration(snapshot.get75thPercentile()),
      'p95': convertDuration(snapshot.get95thPercentile()),
      'p98': convertDuration(snapshot.get98thPercentile()),
      'p99': convertDuration(snapshot.get99thPercentile()),
      'p999': convertDuration(snapshot.get999thPercentile()),
      'mean_rate': convertRate(timer.meanRate),
      'm1_rate': convertRate(timer.oneMinuteRate),
      'm5_rate': convertRate(timer.fiveMinuteRate),
      'm15_rate': convertRate(timer.fifteenMinuteRate),
      'rate_unit': 'calls/${rateUnit.name}',
      'duration_unit': '${durationUnit.name}s',
    });
  }

  void _report(int timeInSeconds, String name, Map<String, dynamic> datas) {
    datas.forEach((k, v) {
      _graphite.send(MetricRegistry.name([_prefix, name, k]), v.toString(), timeInSeconds);
    });
  }
}
