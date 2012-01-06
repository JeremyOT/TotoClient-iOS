TotoClient
==========
Using Toto with iOS is simple. Either copy the source into your project, or build and link to the library and include `TotoService.h`.

Initialize an instance of TotoService with `[TotoService serviceWithURL:(NSURL*)]` (Uses JSON) or `[TotoService serviceWithURL:(NSURL*) BSON:YES]` to use BSON.

_Note: BSON must be enabled on the server in order to use BSON._

TotoService provides methods for account creation and authentication which will automatically store session tokens and associate them with the `NSURL` used to
instantiate the instance. This means that an application can interact with multiple Toto servers independently. Both authentication methods can take an
`NSDictionary` with additional parameters, though they are unused by default.

If an authorized method is called without a valid session ID, either `TOTO_ERROR_NOT_AUTHORIZED` or `TOTO_ERROR_INVALID_SESSION_ID` will be returned. An object
that implements the `TotoServiceAuthenticationDelegate` protocol can be passed to the `authenticationDelegate` property of an instance of `TotoService` in
order to conveniently handle these errors, and optionally call the triggering method again with the original parameters after authentication is complete.

