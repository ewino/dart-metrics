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

library metrics.derivative_gauge_test;

import 'package:test/test.dart';
import 'package:metrics/metrics.dart';

main() {
  group('derivative gauge', () {
    test('returns a transformed value', () {
      final gauge1 = new Gauge<String>(() => 'woo');
      final gauge2 = new DerivativeGauge<String, int>(
          gauge1, (String s) => s.length);

      expect(gauge2.value, equals(3));
    });
  });
}
