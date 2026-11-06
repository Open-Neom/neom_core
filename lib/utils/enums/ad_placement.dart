/// Supported advertising and internal house-ad surfaces across Open Neom apps.
enum AdPlacement {
  /// Single native/banner/video/house card interleaved inside `neom_timeline`.
  feedInline,

  /// Horizontal 3-card menu feature discovery carousel inside `neom_timeline`.
  feedFeatureCarousel,

  /// Right sidebar ad/house-ad unit on Web (`300x250` / compact card).
  feedSidebarWeb,

  /// Non-intrusive collapsible strip outside the book reader canvas.
  readerBanner,

  /// Page-milestone modal break (video/image/house ad) inside `neom_books`.
  readerPageBreak,

  /// Rewarded video/interactive ad unlocking extra reading trial time/pages.
  readerRewarded,

  /// Audio + companion card break between narrated Read-Aloud pages.
  narrationAudioBreak,

  /// Compact banner inside `neom_audio_player` for non-subscribers.
  playerBanner,

  /// Pre-roll audio/video ad before starting playback every N sessions.
  playerAudioPreRoll,

  /// Mid-roll / between-track audio + companion video/image ad every K tracks.
  playerAudioMidRoll,

  /// Rewarded ad unlocking extra listening quota when daily trial expires.
  playerRewarded,
}
