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

library metrics.sliding_time_window_reservoir_test;

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:metrics/metrics.dart';

import 'meter_tests.mocks.dart';

@GenerateMocks([Clock])
main() {
  group('sliding time window reservoir', () {

    late MockClock clock;
    late SlidingTimeWindowReservoir reservoir;

    setUp(() {
      clock = new MockClock();
      reservoir = new SlidingTimeWindowReservoir(const Duration(microseconds: 10), clock);
    });

    test('stores measurements with duplicate ticks', () {
      when(clock.tick).thenReturn(20);

      reservoir.update(1);
      reservoir.update(2);

      expect(reservoir.size, equals(2));
      expect(reservoir.snapshot.values, unorderedEquals([1, 2]));
    });

    test('bounds measurements to a time window', () {
      when(clock.tick).thenReturn(0);
      reservoir.update(1);

      when(clock.tick).thenReturn(5);
      reservoir.update(2);

      when(clock.tick).thenReturn(10);
      reservoir.update(3);

      when(clock.tick).thenReturn(15);
      reservoir.update(4);

      when(clock.tick).thenReturn(20);
      reservoir.update(5);

      expect(reservoir.size, equals(2));
      expect(reservoir.snapshot.values, unorderedEquals([4, 5]));
    });

  });
}
