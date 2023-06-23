import Foundation

public protocol ClientTransport: Sendable {
  func send(_ request: Request, baseURL: URL) async throws -> Response
}

public protocol ClientMiddleware: Sendable {
  /// Intercepts an outgoing HTTP request and an incoming HTTP response.
  /// - Parameters:
  ///   - request: An HTTP request.
  ///   - baseURL: baseURL: A server base URL.
  ///   - next: A closure that calls the next middleware, or the client.
  /// - Returns: An HTTP response.
  func intercept(
    _ request: Request,
    baseURL: URL,
    next: (Request, URL) async throws -> Response
  ) async throws -> Response
}
