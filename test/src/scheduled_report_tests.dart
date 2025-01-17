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

library metrics.scheduled_report_test;

import 'dart:async' as a;

import 'package:mockito/annotations.dart';
import 'package:test/test.dart';
import 'package:metrics/metrics.dart';

import 'metric_registry_tests.mocks.dart';

class SpyScheduledReporter extends ScheduledReporter {

  int _count = 0;

  SpyScheduledReporter(MetricRegistry registry,
      TimeUnit durationUnit, TimeUnit rateUnit, {MetricFilter? where})
      : super(registry, durationUnit, rateUnit, where: where);

  @override
  void reportMetrics({Map<String, Gauge>? gauges,
                      Map<String, Counter>? counters,
                      Map<String, Histogram>? histograms,
                      Map<String, Meter>? meters,
                      Map<String, Timer>? timers}) {
    _count++;
  }
}

@GenerateMocks([Gauge, Counter, Histogram, Meter, Timer])
main() {
  final gauge = new MockGauge();
  final counter = new MockCounter();
  final histogram = new MockHistogram();
  final meter = new MockMeter();
  final timer = new MockTimer();

  final registry = new MetricRegistry();
  final reporter = new SpyScheduledReporter(
      registry,
      TimeUnit.SECONDS,
      TimeUnit.MILLISECONDS);
  group('scheduled report', () {
    test('polls periodically', () {
      registry.register("gauge", gauge);
      registry.register("counter", counter);
      registry.register("histogram", histogram);
      registry.register("meter", meter);
      registry.register("timer", timer);

      reporter.start(const Duration(milliseconds: 200));

      new a.Future.delayed(const Duration(milliseconds: 500), expectAsync0(() {
        expect(reporter._count, equals(2));
      })).whenComplete(() {
        reporter.stop();
      });
    });
  });
}
