import Foundation

/// An error thrown by a client performing an OpenAPI operation.
///
/// Use a `ClientError` to inspect details about the request and response that resulted in an error.
///
/// You don't create or throw instances of `ClientError` yourself; they are created and thrown on
/// your behalf by the runtime library when a client operation fails.
public struct ClientError: Error {
  /// The HTTP request created during the operation.
  ///
  /// Will be nil if the error resulted before the request was generated,
  /// for example if generating the request from the Input failed.
  public var request: Request?

  /// The base URL for HTTP requests.
  ///
  /// Will be nil if the error resulted before the request was generated,
  /// for example if generating the request from the Input failed.
  public var baseURL: URL?

  /// The HTTP response received during the operation.
  ///
  /// Will be `nil` if the error resulted before the `Response` was received.
  public var response: Response?

  /// The underlying error that caused the operation to fail.
  public var underlyingError: Error

  /// Creates a new error.
  /// - Parameters:
  ///   - request: The HTTP request created during the operation.
  ///   - baseURL: The base URL for HTTP requests.
  ///   - response: The HTTP response received during the operation.
  ///   - underlyingError: The underlying error that caused the operation to fail.
  public init(
    request: Request? = nil,
    baseURL: URL? = nil,
    response: Response? = nil,
    underlyingError: Error
  ) {
    self.request = request
    self.baseURL = baseURL
    self.response = response
    self.underlyingError = underlyingError
  }

  // MARK: Private

  fileprivate var underlyingErrorDescription: String {
    guard let prettyError = underlyingError as? PrettyStringConvertible else {
      return underlyingError.localizedDescription
    }
    return prettyError.prettyDescription
  }
}

extension ClientError: CustomStringConvertible {
  public var description: String {
    "Client error - request: \(request?.description ?? "<nil>"), baseURL: \(baseURL?.absoluteString ?? "<nil>"), response: \(response?.description ?? "<nil>"), underlying error: \(underlyingErrorDescription)"
  }
}

extension ClientError: LocalizedError {
  public var errorDescription: String? {
    description
  }
}
