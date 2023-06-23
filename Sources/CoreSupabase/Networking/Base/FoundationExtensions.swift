import Foundation

extension Data {
  /// Returns a pretty representation of the Data.
  var pretty: String {
    String(decoding: self, as: UTF8.self)
  }

  /// Returns a prefix of a pretty representation of the Data.
  var prettyPrefix: String {
    prefix(256).pretty
  }
}
