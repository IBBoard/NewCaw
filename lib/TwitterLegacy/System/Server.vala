/* Server.vala
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
 * Stores the information to connect to the Twitter server.
 *
 * As there is only one server this backend can connect to,
 * this server is created as an singleton.
 */
[SingleInstance]
public class Backend.TwitterLegacy.Server : Backend.Server {

  /**
   * The "Out-of-Band" redirect uri for Twitter.
   *
   * This uri is used when the Client does not specify an redirect url
   * to identify the API to display an authentication code
   * the user needs to manually input to authenticate the client.
   */
  internal const string OOB_REDIRECT = "oob";

  /**
   * The global instance of this server.
   */
  public static Server? instance {
    get {
      if (_instance == null) {
        critical ("This server was not initialized!");
      }
      return _instance;
    }
  }

  /**
   * Creates an connection with established client authentication.
   *
   * This constructor requires existing and valid client
   * keys and secrets to build the connection.
   *
   * If you do not have a key to provide, you need to generate
   * them on Twitter's Developer Portal to use here.
   *
   * @param client_key The key to authenticate the client.
   * @param client_secret The secret to authenticate the client.
   */
  public Server (string client_key, string client_secret) {
    // Create the Server instance
    Object (
      domain:        "https://api.twitter.com",
      client_key:    client_key,
      client_secret: client_secret
    );

    // Set the global instance
    _instance = this;
  }

  /**
   * Checks an finished Rest.ProxyCall for occurred errors.
   *
   * @param call The call as run by call.
   *
   * @throws CallError Possible detected errors.
   */
  protected override void check_call (Rest.ProxyCall call) throws CallError {
  }

  /**
   * Stores the global instance of this Server.
   */
  private static Server? _instance = null;

}