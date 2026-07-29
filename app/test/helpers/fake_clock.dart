/// A hand-advanced clock. The timer derives every figure from the wall clock,
/// so controlling `now` is enough to test elapsed time deterministically.
class FakeClock {
  FakeClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration amount) => now = now.add(amount);
}
