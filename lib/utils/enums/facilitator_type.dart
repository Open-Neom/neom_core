enum FacilityType {
  general('general'),
  producer('producer'),
  publisher('publisher'),
  printing('printing'),
  teacher('teacher'),
  store('store'),
  podcaster('podcaster'),
  radio('radio'),
  recordStudio('recordStudio'),
  soundRental('soundRental'),
  rehearsalRoom('rehearsalRoom'),
  other('other');

  final String value;
  const FacilityType(this.value);
}
