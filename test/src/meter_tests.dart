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

library metrics.meter_test;

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:metrics/metrics.dart';

import 'meter_tests.mocks.dart';

@GenerateMocks([Clock])
main() async {
  group('meter', () {
    test('starts out with no rates or count', () {
      final clock = new MockClock();
      when(clock.tick).thenReturn(0);
      final meter = new Meter(clock);

      when(clock.tick).thenReturn(const Duration(seconds: 10).inMicroseconds);

      expect(meter.count, equals(0));
      expect(meter.meanRate, closeTo(0, 0.001));
      expect(meter.oneMinuteRate, closeTo(0, 0.001));
      expect(meter.fiveMinuteRate, closeTo(0, 0.001));
      expect(meter.fifteenMinuteRate, closeTo(0, 0.001));
    });

    test('marks events and updates rates and count', () {
      final clock = new MockClock();
      when(clock.tick).thenReturn(0);
      final meter = new Meter(clock);
      meter.mark();

      when(clock.tick).thenReturn(const Duration(seconds: 10).inMicroseconds);
      meter.mark(2);

      expect(meter.meanRate, closeTo(0.3, 0.001));
      expect(meter.oneMinuteRate, closeTo(0.1840, 0.001));
      expect(meter.fiveMinuteRate, closeTo(0.1966, 0.001));
      expect(meter.fifteenMinuteRate, closeTo(0.1988, 0.001));
    });
  });
}
