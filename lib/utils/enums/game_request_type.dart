/// Types of games available for multiplayer requests
enum GameRequestType {
  literaryChess,
  wordChain,
  quoteQuest,
  verseScramble,
  // Future games...
}

extension GameRequestTypeExtension on GameRequestType {
  String get displayName {
    switch (this) {
      case GameRequestType.literaryChess:
        return 'Ajedrez Literario';
      case GameRequestType.wordChain:
        return 'Cadena de Palabras';
      case GameRequestType.quoteQuest:
        return 'Quote Quest';
      case GameRequestType.verseScramble:
        return 'Verse Scramble';
    }
  }

  String get roomPrefix => name;
}
