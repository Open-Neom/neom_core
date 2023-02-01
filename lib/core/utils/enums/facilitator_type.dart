enum FacilityType {
  producer('producer'),
  publisher('publisher'),
  printing('printing'),
  designer('designer'),
  teacher('teacher'),
  workshop('workshop'),
  store('store'),
  photographer('photographer'),
  podcaster('podcaster'),
  radio('radio'),
  recordStudio('recordStudio'),
  equipmentRental('equipmentRental'),
  rehearsalRoom('rehearsalRoom');

  final String value;
  const FacilityType(this.value);
}
