enum ProfileType {
  general('general'), ///COMMON TARGET PROFILE TYPE WITH REGULAR PRIVILEGES
  artist('artist'), ///ARTIST PROFILE
  facilitator('facilitator'), ///FACILITATOR OF SERVICES FOR ARTISTS
  host('host'), ///HOST OF EVENTS OR OWNER OF VENUES
  band('band'), ///BAND OR COLLECTIVE FOR ARTISTS
  researcher("researcher"), ///RESEARCHER TO PUBLISH PDFs
  broadcaster('broadcaster'); ///PROFILE FOR AUDIO CONTENT CREATORS


  final String value;
  const ProfileType(this.value);

}
