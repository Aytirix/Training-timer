/// Stratégie de calcul des temps de repos selon le nombre de reps.
class RestStrategy {
  final int smallSetRestSeconds; // reps 1–3
  final int mediumSetRestSeconds; // reps 4–6
  final int largeSetRestSeconds; // reps 7–9
  final int peakSetRestSeconds; // reps 10+

  const RestStrategy({
    this.smallSetRestSeconds = 45,
    this.mediumSetRestSeconds = 60,
    this.largeSetRestSeconds = 90,
    this.peakSetRestSeconds = 120,
  });

  int restForReps(int reps) {
    if (reps <= 3) return smallSetRestSeconds;
    if (reps <= 6) return mediumSetRestSeconds;
    if (reps <= 9) return largeSetRestSeconds;
    return peakSetRestSeconds;
  }

  RestStrategy copyWith({
    int? smallSetRestSeconds,
    int? mediumSetRestSeconds,
    int? largeSetRestSeconds,
    int? peakSetRestSeconds,
  }) {
    return RestStrategy(
      smallSetRestSeconds: smallSetRestSeconds ?? this.smallSetRestSeconds,
      mediumSetRestSeconds: mediumSetRestSeconds ?? this.mediumSetRestSeconds,
      largeSetRestSeconds: largeSetRestSeconds ?? this.largeSetRestSeconds,
      peakSetRestSeconds: peakSetRestSeconds ?? this.peakSetRestSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'smallSetRestSeconds': smallSetRestSeconds,
        'mediumSetRestSeconds': mediumSetRestSeconds,
        'largeSetRestSeconds': largeSetRestSeconds,
        'peakSetRestSeconds': peakSetRestSeconds,
      };

  factory RestStrategy.fromJson(Map<String, dynamic> json) => RestStrategy(
        smallSetRestSeconds: json['smallSetRestSeconds'] as int? ?? 45,
        mediumSetRestSeconds: json['mediumSetRestSeconds'] as int? ?? 60,
        largeSetRestSeconds: json['largeSetRestSeconds'] as int? ?? 90,
        peakSetRestSeconds: json['peakSetRestSeconds'] as int? ?? 120,
      );

  @override
  bool operator ==(Object other) =>
      other is RestStrategy &&
      smallSetRestSeconds == other.smallSetRestSeconds &&
      mediumSetRestSeconds == other.mediumSetRestSeconds &&
      largeSetRestSeconds == other.largeSetRestSeconds &&
      peakSetRestSeconds == other.peakSetRestSeconds;

  @override
  int get hashCode => Object.hash(
      smallSetRestSeconds, mediumSetRestSeconds, largeSetRestSeconds, peakSetRestSeconds);
}
