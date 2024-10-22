enum ProfileType {
  commonTarget('commonTarget'), ///COMMON TARGET PROFILE TYPE WITH REGULAR PRIVILEGES
  artist('artist'), ///ARTIST PROFILE
  facilitator('facilitator'), ///FACILITATOR OF SERVICES FOR ARTISTS
  host('host'), ///HOST OF EVENTS OR OWNER OF VENUES
  band('band'), ///BAND OR COLLECTIVE FOR ARTISTS
  broadcaster('broadcaster'), ///PROFILE FOR AUDIO CONTENT CREATORS
  researcher("researcher"); ///RESEARCHER TO PUBLISH PDFs

  final String value;
  const ProfileType(this.value);

}
