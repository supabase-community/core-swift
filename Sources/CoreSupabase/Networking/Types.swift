import Foundation

/// A header field used in an HTTP request or response.
public struct HeaderField: Equatable, Hashable, Sendable {
  /// The name of the HTTP header field.
  public var name: String

  /// The value of the HTTP header field.
  public var value: String

  /// Creates a new HTTP header field.
  /// - Parameters:
  ///   - name: A name of the HTTP header field.
  ///   - value: A value of the HTTP header field.
  public init(name: String, value: String) {
    self.name = name.lowercased()
    self.value = value
  }
}

extension HeaderField {
  /// Names of the header fields whose values should be redacted.
  ///
  /// All header field names are lowercased when added to the set.
  ///
  /// The values of header fields with the provided names will are replaced
  /// with "<redacted>" when using `HeaderField.description`.
  ///
  /// Use this to avoid leaking sensitive tokens into application logs.
  public static var redactedHeaderFields: Set<String> {
    set {
      _lock_redactedHeaderFields.lock()
      defer {
        _lock_redactedHeaderFields.unlock()
      }
      // Save lowercased versions of the header field names to make
      // membership checking O(1).
      _locked_redactedHeaderFields = Set(newValue.map { $0.lowercased() })
    }
    get {
      _lock_redactedHeaderFields.lock()
      defer {
        _lock_redactedHeaderFields.unlock()
      }
      return _locked_redactedHeaderFields
    }
  }

  /// The default header field names whose values are redacted.
  public static let defaultRedactedHeaderFields: Set<String> = [
    "authorization",
    "cookie",
    "set-cookie",
  ]

  /// The lock used for protecting access to `_locked_redactedHeaderFields`.
  private static let _lock_redactedHeaderFields: NSLock = {
    let lock = NSLock()
    lock.name = "com.supabase.core-swift.lock.redactedHeaderFields"
    return lock
  }()

  /// The underlying storage of ``HeaderField/redactedHeaderFields``,
  /// protected by a lock.
  private static var _locked_redactedHeaderFields: Set<String> = defaultRedactedHeaderFields
}

public struct QueryItem: Equatable, Hashable, Sendable {
  /// The name of the query item.
  public var name: String
  /// The value of the query item.
  public var value: String?

  public init(name: String, value: String?) {
    self.name = name
    self.value = value
  }
}

/// Describes the HTTP method used in an OpenAPI operation.
public struct HTTPMethod: RawRepresentable, Equatable, Hashable, Sendable {

  /// Describes an HTTP method explicitly supported by OpenAPI.
  private enum _HTTPMethod: String, Equatable, Hashable, Sendable {
    case GET
    case PUT
    case POST
    case DELETE
    case OPTIONS
    case HEAD
    case PATCH
    case TRACE
  }

  /// The underlying HTTP method.
  private let value: _HTTPMethod

  /// Creates a new method from the provided known supported HTTP method.
  private init(value: _HTTPMethod) {
    self.value = value
  }

  public init?(rawValue: String) {
    guard let value = _HTTPMethod(rawValue: rawValue) else {
      return nil
    }
    self.value = value
  }

  public var rawValue: String {
    value.rawValue
  }

  /// The name of the HTTP method.
  public var name: String {
    rawValue
  }

  /// Returns an HTTP GET method.
  public static var get: Self {
    .init(value: .GET)
  }

  /// Returns an HTTP PUT method.
  public static var put: Self {
    .init(value: .PUT)
  }

  /// Returns an HTTP POST method.
  public static var post: Self {
    .init(value: .POST)
  }

  /// Returns an HTTP DELETE method.
  public static var delete: Self {
    .init(value: .DELETE)
  }

  /// Returns an HTTP OPTIONS method.
  public static var options: Self {
    .init(value: .OPTIONS)
  }

  /// Returns an HTTP HEAD method.
  public static var head: Self {
    .init(value: .HEAD)
  }

  /// Returns an HTTP PATCH method.
  public static var patch: Self {
    .init(value: .PATCH)
  }

  /// Returns an HTTP TRACE method.
  public static var trace: Self {
    .init(value: .TRACE)
  }
}

/// An HTTP request, sent by the client to the server.
public struct Request: Equatable, Hashable, Sendable {

  /// The path of the URL for the HTTP request.
  public var path: String

  /// The query of the URL for the HTTP request.
  public var query: [QueryItem]

  /// The method of the HTTP request.
  public var method: HTTPMethod

  /// The header fields of the HTTP request.
  public var headerFields: [HeaderField]

  /// The body data of the HTTP request.
  public var body: Data?

  /// Creates a new HTTP request.
  /// - Parameters:
  ///   - path: The path of the URL for the request. This must not include
  ///   the base URL of the server.
  ///   - query: The query string of the URL for the request. This should not
  ///   include the separator question mark (`?`) and the names and values
  ///   should be percent-encoded. See ``query`` for more information.
  ///   - method: The method of the HTTP request.
  ///   - headerFields: The header fields of the HTTP request.
  ///   - body: The body data of the HTTP request.
  ///
  /// An example of a request:
  /// ```
  /// let request = Request(
  ///   path: "/users",
  ///   query: "name=Maria%20Ruiz&email=mruiz2%40icloud.com",
  ///   method: .GET,
  ///   headerFields: [
  ///       .init(name: "Accept", value: "application/json"
  ///   ],
  ///   body: nil
  /// )
  /// ```
  public init(
    path: String,
    query: [QueryItem] = [],
    method: HTTPMethod,
    headerFields: [HeaderField] = [],
    body: Data? = nil
  ) {
    self.path = path
    self.query = query
    self.method = method
    self.headerFields = headerFields
    self.body = body
  }
}

/// An HTTP response, returned by the server to the client.
public struct Response: Equatable, Hashable, Sendable {

  /// The status code of the HTTP response, for example `200`.
  public var statusCode: Int

  /// The header fields of the HTTP response.
  public var headerFields: [HeaderField]

  /// The body data of the HTTP response.
  public var body: Data

  /// Creates a new HTTP response.
  /// - Parameters:
  ///   - statusCode: The status code of the HTTP response, for example `200`.
  ///   - headerFields: The header fields of the HTTP response.
  ///   - body: The body data of the HTTP response.
  public init(
    statusCode: Int,
    headerFields: [HeaderField] = [],
    body: Data = .init()
  ) {
    self.statusCode = statusCode
    self.headerFields = headerFields
    self.body = body
  }
}

extension HeaderField: CustomStringConvertible {
  public var description: String {
    let value: String
    if HeaderField.redactedHeaderFields.contains(name.lowercased()) {
      value = "<redacted>"
    } else {
      value = self.value
    }
    return "\(name): \(value)"
  }
}

extension Request: CustomStringConvertible {
  public var description: String {
    "path: \(path), query: \(query), method: \(method), header fields: \(headerFields.description), body (prefix): \(body?.prettyPrefix ?? "<nil>")"
  }
}

extension Response: CustomStringConvertible {
  public var description: String {
    "status: \(statusCode), header fields: \(headerFields.description), body: \(body.prettyPrefix)"
  }
}
