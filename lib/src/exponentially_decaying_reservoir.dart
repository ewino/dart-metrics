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

part of metrics;

///
/// An exponentially-decaying random reservoir of [int]s. Uses Cormode et al's
/// forward-decaying priority reservoir sampling method to produce a statistically representative
/// sampling reservoir, exponentially biased towards newer entries.
///
/// See [Cormode et al. Forward Decay: A Practical Time Decay Model for Streaming Systems. ICDE '09:
///      Proceedings of the 2009 IEEE International Conference on Data Engineering (2009)](http://dimacs.rutgers.edu/~graham/pubs/papers/fwddecay.pdf)
class ExponentiallyDecayingReservoir implements Reservoir {
  static const _DEFAULT_SIZE = 1028;
  static const _DEFAULT_ALPHA = 0.015;
  static const _RESCALE_THRESHOLD = Duration.microsecondsPerHour;

  static final _random = new Random();

  final _values = <double, WeightedSample>{};
  final double _alpha;
  final int _size;
  int _count = 0;
  late int _startTime;
  late int _nextScaleTime;
  final Clock _clock;

  /// Creates a new [ExponentiallyDecayingReservoir].
  ///
  /// By default a new [ExponentiallyDecayingReservoir] of 1028 elements, which offers a 99.9%
  /// confidence level with a 5% margin of error assuming a normal distribution, and an alpha
  /// factor of 0.015, which heavily biases the reservoir to the past 5 minutes of measurements.
  ///
  /// [_size] is the number of samples to keep in the sampling reservoir
  /// [_alpha] is the exponential decay factor; the higher this is, the more biased the reservoir will be towards newer values
  /// [clock] is the clock used to timestamp samples and track rescaling
  ExponentiallyDecayingReservoir([this._size = _DEFAULT_SIZE, this._alpha = _DEFAULT_ALPHA, Clock? clock])
      : _clock = clock ?? Clock.defaultClock {
    _startTime = _currentTimeInSeconds;
    _nextScaleTime = _clock.tick + _RESCALE_THRESHOLD;
  }

  @override
  int get size => min(_size, _count);

  @override
  void update(int value, [int? timestamp]) {
    if (timestamp == null) timestamp = _currentTimeInSeconds;
    _rescaleIfNeeded();
    final itemWeight = _weight(timestamp - _startTime);
    final sample = new WeightedSample(value, itemWeight);
    final priority = itemWeight / _random.nextDouble();

    final newCount = ++_count;
    if (newCount <= _size) {
      _values[priority] = sample;
    } else {
      double first = _values.keys.first;
      final WeightedSample? oldValue = _values[priority];
      if (first < priority && oldValue == null) {
        _values[priority] = sample;

        // ensure we always remove an item
        while (_values.remove(first) == null) {
          first = _values.keys.first;
        }
      }
    }
  }

  void _rescaleIfNeeded() {
    final now = _clock.tick;
    final next = _nextScaleTime;
    if (now >= next) {
      _rescale(now, next);
    }
  }

  @override
  Snapshot get snapshot => new WeightedSnapshot(_values.values);

  int get _currentTimeInSeconds => _clock.time ~/ Duration.millisecondsPerSecond;

  double _weight(int t) => exp(_alpha * t);

  /* "A common feature of the above techniques—indeed, the key technique that
   * allows us to track the decayed weights efficiently—is that they maintain
   * counts and other quantities based on g(ti − L), and only scale by g(t − L)
   * at query time. But while g(ti −L)/g(t−L) is guaranteed to lie between zero
   * and one, the intermediate values of g(ti − L) could become very large. For
   * polynomial functions, these values should not grow too large, and should be
   * effectively represented in practice by floating point values without loss of
   * precision. For exponential functions, these values could grow quite large as
   * new values of (ti − L) become large, and potentially exceed the capacity of
   * common floating point types. However, since the values stored by the
   * algorithms are linear combinations of g values (scaled sums), they can be
   * rescaled relative to a new landmark. That is, by the analysis of exponential
   * decay in Section III-A, the choice of L does not affect the final result. We
   * can therefore multiply each value based on L by a factor of exp(−α(L′ − L)),
   * and obtain the correct value as if we had instead computed relative to a new
   * landmark L′ (and then use this new L′ at query time). This can be done with
   * a linear pass over whatever data structure is being used."
   */
  void _rescale(int now, int next) {
    if (_nextScaleTime == next) {
      _nextScaleTime = now + _RESCALE_THRESHOLD;
      final oldStartTime = _startTime;
      _startTime = _currentTimeInSeconds;
      final scalingFactor = exp(-_alpha * (_startTime - oldStartTime));

      final keys = new List<double>.from(_values.keys);
      for (final key in keys) {
        final sample = _values.remove(key)!;
        final newSample = new WeightedSample(sample.value, sample.weight * scalingFactor);
        _values[key * scalingFactor] = newSample;
      }

      // make sure the counter is in sync with the number of stored samples.
      _count = _values.length;
    }
  }
}
