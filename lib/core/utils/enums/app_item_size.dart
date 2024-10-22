enum AppItemSize {
  halfLetter('14x21.6cm'),      // 1/2 carta
  sixByNine('15.24x22.86cm'),   // 6x9 pulgadas
  letter('21.6x27.9cm'),        // Carta (Letter)
  quarterLetter('10.8x14cm');   // 1/4 de carta
  // other('other');                // Para tamaños no especificados

  final String value;
  const AppItemSize(this.value);
}

enum ItemQuality {
  mid(0),
  standard(1),
  premium(2);

  final int value;
  const ItemQuality(this.value);
}

enum PaperType {
  bond75('Bond 75g'),
  uncoated90('Cultural 90g'),
  couche130('Couché 130g');


  final String value;
  const PaperType(this.value);
}

enum CoverLamination {
  gloss('gloss'),        // Carta (Letter)
  matte('matte');


  final String value;
  const CoverLamination(this.value);
}
