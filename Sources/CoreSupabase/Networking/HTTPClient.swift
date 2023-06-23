import Foundation

public struct HTTPClient: Sendable {

  /// The URL of the server, used as the base URL for requests made by the
  /// client.
  public let serverURL: URL

  /// Type capable of sending HTTP requests and receiving HTTP responses.
  public var transport: ClientTransport

  /// Middlewares to be invoked before `transport`.
  public var middlewares: [ClientMiddleware]

  /// Creates a new client.
  public init(
    serverURL: URL,
    transport: ClientTransport,
    middlewares: [ClientMiddleware] = []
  ) {
    self.serverURL = serverURL
    self.transport = transport
    self.middlewares = middlewares
  }

  /// Performs the HTTP operation.
  ///
  /// An operation consists of three steps:
  /// 1. Convert Input into an HTTP request.
  /// 2. Invoke the `ClientTransport` to perform the HTTP call, wrapped by middlewares.
  /// 3. Convert the HTTP response into Output.
  ///
  /// It wraps any thrown errors and attaches appropriate context.
  ///
  /// - Parameters:
  ///   - request: The request to send.
  /// - Returns: The Output value produced by `deserializer`.
  public func send(_ request: Request) async throws -> Response {
    func wrappingErrors<R>(
      work: () async throws -> R,
      mapError: (Error) -> Error
    ) async throws -> R {
      do {
        return try await work()
      } catch {
        throw mapError(error)
      }
    }
    let baseURL = serverURL
    func makeError(
      request: Request? = nil,
      baseURL: URL? = nil,
      response: Response? = nil,
      error: Error
    ) -> Error {
      ClientError(
        request: request,
        baseURL: baseURL,
        response: response,
        underlyingError: error
      )
    }
    let response: Response = try await wrappingErrors {
      var next: (Request, URL) async throws -> Response = { (_request, _url) in
        try await wrappingErrors {
          try await transport.send(_request, baseURL: _url)
        } mapError: { error in
          RuntimeError.transportFailed(error)
        }
      }
      for middleware in middlewares.reversed() {
        let tmp = next
        next = {
          try await middleware.intercept($0, baseURL: $1, next: tmp)
        }
      }
      return try await next(request, baseURL)
    } mapError: { error in
      makeError(request: request, baseURL: baseURL, error: error)
    }

    return response
  }
}
