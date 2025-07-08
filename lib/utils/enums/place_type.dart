enum PlaceType {
  general('general'),
  academy("academy"),
  bar("bar"),
  cafe("cafe"),
  culturalCenter("culturalCenter"),
  forum("forum"),
  manager("manager"),
  privateSpace("privateSpace"),
  publicSpace("publicSpace"),
  restaurant("restaurant"),
  other('other');

  final String value;
  const PlaceType(this.value);
}
