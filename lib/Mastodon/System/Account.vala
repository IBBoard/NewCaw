/* Account.vala
 *
 * Copyright 2022 Frederick Schenk
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using GLib;

/**
 * Represents an Profile that uses this library.
 *
 * Account extends Profile to add the
 * properties and methods to allow it to
 * interact with the API provided by the platform.
 */
public class Backend.Mastodon.Account : Backend.Account {

  /**
   * Creates an unauthenticated Account for a server.
   *
   * After construction, it is required to either authenticate the account,
   * using the methods init_authentication and authenticate,
   * or to login with the method login.
   *
   * @param server The server to connect to with the account.
   */
  public Account (Server server) {
    // Construct the object with server information
    Object (
      // Set server and non-authenticated
      server:        server,
      authenticated: false
    );

    // Get Client instance and determine used redirect uri
    Client application    = Client.instance;
    string used_redirects = application.redirect_uri != null
                              ? application.redirect_uri
                              : Server.OOB_REDIRECT;

    // Create proxy
    proxy = new Rest.OAuth2Proxy (@"$(server.domain)/oauth/authorize",
                                  @"$(server.domain)/oauth/token",
                                   used_redirects,
                                   server.client_key,
                                   server.client_secret,
                                  @"$(server.domain)/api/v1/");
  }

  /**
   * Prepares the link to launch the authentication of a new Account.
   *
   * @return The link with the site to authenticate the user.
   *
   * @throws Error Any error occurring while requesting the token.
   */
  public override async string init_authentication () throws Error {
    // Check if authentication is necessary
    if (authenticated) {
      error ("Already authenticated!");
    }

    // Create code challenge
    auth_challenge = new Rest.PkceCodeChallenge.random ();

    // Build authorization url
    return proxy.build_authorization_url (auth_challenge.get_challenge (),
                                          "read write follow push",
                                          null);
  }

  /**
   * Authenticates the account with an code.
   *
   * This method should be run after init_authentication and use
   * the code retrieved from the site where the user authenticated himself.
   *
   * After completion, you should save the access token retrieved
   * from the platform so you can use the login method on following runs.
   *
   * @param auth_code The authentication code for the user.
   *
   * @throws Error Any error occurring while requesting the token.
   */
  public override async void authenticate (string auth_code) throws Error {
    // Check if authentication is necessary
    if (authenticated) {
      error ("Already authenticated!");
    }

    // Check if init_authenticate was run beforehand
    if (auth_challenge == null) {
      critical ("No code challenge available!");
    }

    // Get the access token using the proxy
    yield proxy.fetch_access_token_async (auth_code, auth_challenge.get_verifier (), null);

    // Check if we retrieved a valid access token
    if (proxy.access_token == null || proxy.access_token == "") {
      error ("Could not retrieve access token!");
    } else {
      // Store the access token in the property
      access_token = proxy.access_token;
    }

    // Retrieve the account profile data
    var auth_call = create_call ();
    auth_call.set_method ("GET");
    auth_call.set_function ("accounts/verify_credentials");

    Json.Object data;
    try {
      data = yield server.call (auth_call);
    } catch (Error e) {
      throw e;
    }

    // Populate data with retrieved json
    set_profile_data (data);
    authenticated = true;
  }

  /**
   * Creates an Account with existing access token.
   *
   * @param token The access token for the account.
   *
   * @throws Error Any error occurring while requesting the token.
   */
  public override async void login (string token) throws Error {
    // Check if authentication is necessary
    if (authenticated) {
      error ("Already authenticated!");
    }

    // Check if init_authenticate was run beforehand
    if (auth_challenge != null) {
      error ("Authentication in progress!");
    }

    // Set the access token on the proxy
    access_token       = token;
    proxy.access_token = access_token;

    // Retrieve the account profile data
    var auth_call = create_call ();
    auth_call.set_method ("GET");
    auth_call.set_function ("accounts/verify_credentials");

    Json.Object data;
    try {
      data = yield server.call (auth_call);
    } catch (Error e) {
      throw e;
    }

    // Populate data with retrieved json
    set_profile_data (data);
    authenticated = true;
  }

  /**
   * Sets the Profile data for this Account.
   *
   * @param json A Json.Object retrieved from the API.
   */
  private void set_profile_data (Json.Object json) {
    // Get the url for avatar and header
    string avatar_url = json.get_string_member ("avatar_static");
    string header_url = json.get_string_member ("header_static");

    // Get url and domain to this account
    string account_url = json.get_string_member ("url");
    string account_domain = Utils.ParseUtils.strip_domain (account_url);

    // Set the id of the account
    id = json.get_string_member ("id");

    // Set the creation date for the account
    creation_date = new DateTime.from_iso8601 (
                      json.get_string_member ("created_at"),
                      new TimeZone.utc ()
                    );

    // Set the names of the account
    display_name = json.get_string_member ("display_name");
    username     = json.get_string_member ("acct");

    // Set the url and domain
    url    = account_url;
    domain = account_domain;

    // Set metrics
    followers_count = (int) json.get_int_member ("followers_count");
    following_count = (int) json.get_int_member ("following_count");
    posts_count     = (int) json.get_int_member ("statuses_count");

    // Set the images
    avatar = new Media (PICTURE, avatar_url);
    header = new Media (PICTURE, header_url);

    // Parse the description into modules and create a formatted version
    description_modules = Utils.TextUtils.parse_text (json.get_string_member ("note"));
    description = Backend.Utils.TextUtils.format_text (description_modules);

    // Parses all fields
    data_fields = Utils.ParseUtils.parse_data_fields (json.get_array_member ("fields"));

    // Get possible flags for this user
    if (json.get_boolean_member ("locked")) {
      flags = flags | MODERATED;
    }
    if (json.get_boolean_member ("bot")) {
      flags = flags | BOT;
    }
  }

  /**
   * A CodeChallenge used to verify the authentication process.
   */
  private Rest.PkceCodeChallenge? auth_challenge = null;

  /**
   * Creates a Rest.ProxyCall to perform an API call.
   */
  internal override Rest.ProxyCall create_call () {
    assert (proxy != null);
    return proxy.new_call ();
  }

  /**
   * The proxy used to authorize the API calls.
   */
  private Rest.OAuth2Proxy? proxy = null;

}
