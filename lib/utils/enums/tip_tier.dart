enum TipTier {
  cafe(5, 'cafe'),
  cuerdas(25, 'cuerdas'),
  amplificador(100, 'amplificador');

  final int coins;
  final String label;

  const TipTier(this.coins, this.label);
}
