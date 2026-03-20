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
  gloss('gloss'),
  matte('matte');

  final String value;
  const CoverLamination(this.value);
}

enum CoverType {
  softcover('softcover'),
  hardcover('hardcover'),
  dustJacket('dustJacket');   // Con camisa

  final String value;
  const CoverType(this.value);
}

enum BindingType {
  hotmelt('hotmelt'),         // Pegado caliente (económico, estándar)
  sewn('sewn'),               // Cosido (premium, mayor durabilidad)
  spiralPlastic('spiralPlastic'), // Gusano de plástico
  wireO('wireO'),             // Wire-o (espiral metálico)
  stapled('stapled');         // Engrapado

  final String value;
  const BindingType(this.value);
}

enum PrintType {
  blackAndWhite('blackAndWhite'),
  color('color'),
  mixed('mixed');

  final String value;
  const PrintType(this.value);
}

enum ProjectType {
  independentAuthor('independentAuthor'),
  school('school'),
  company('company'),
  publisher('publisher'),
  designPhoto('designPhoto'),
  other('other');

  final String value;
  const ProjectType(this.value);
}

enum ProjectStage {
  filesReady('filesReady'),
  isbnCopyright('isbnCopyright'),
  finalCorrections('finalCorrections'),
  needsDesign('needsDesign'),
  planning('planning');

  final String value;
  const ProjectStage(this.value);
}

enum ProductionPriority {
  normal('normal'),       // 21 días hábiles
  priority('priority'),   // 14 días hábiles
  urgent('urgent');       // 7 días hábiles

  final String value;
  const ProductionPriority(this.value);
}
