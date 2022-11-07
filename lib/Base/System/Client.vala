/* Client.vala
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
 * The client for utilizing this backend.
 *
 * This class provides information about the client to other methods of the
 * backend and provides methods to initialize and shutdown the backend during
 * an application run.
 *
 * Before using anything else from the backend, Client must be initialized.
 */
[SingleInstance]
public partial class Backend.Client : Initable {

  /**
   * The global instance of the client.
   */
  public static Client? instance {
    get {
      if (global_instance == null) {
        critical ("Client must be initialized first!");
      }
      return global_instance;
    }
  }

  /**
   * The id of the client.
   *
   * Is expected to be a reverse domain and to be the
   * same as the application id utilizing the backend.
   */
  public string id { get; construct; }

  /**
   * The name of the client.
   */
  public string name { get; construct; }

  /**
   * A website for more information on a client.
   *
   * Used by backends that create OAuth applications on the
   * fly (e.g. Mastodon) to provide a link for the user while
   * authorizing a new session.
   */
  public string website { get; construct; }

  /**
   * An optional redirect uri used during authentication.
   *
   * Can be provided to the authenticating server to automatically redirect
   * the user from the webpage back to the client after he has authorized
   * it on the OAuth page.
   *
   * If set to null, the out-of-band uri for a specific platform is used instead.
   */
  public string? redirect_uri { get; construct; }

  /**
   * Constructs the client instance.
   *
   * @param id The identifier for the client.
   * @param name The name of the client.
   * @param website The website for the client.
   * @param redirect_uri An optional redirect uri.
   */
  public Client (string id, string name, string website, string? redirect_uri = null) {
    // Construct the class
    Object (
      id: id,
      name: name,
      website: website,
      redirect_uri: redirect_uri
    );

    // Set the global instance
    global_instance = this;
  }

  /**
   * Initializes the object after constructions.
   *
   * For more information view the docs for Initable.
   *
   * @param cancellable Allows the initialization of the class to be cancelled.
   *
   * @return If the object was successfully initialized.
   *
   * @throws Error Errors that happened while loading the account.
   */
  public bool init (Cancellable? cancellable = null) throws Error {
    // Initialize the arrays
    active_servers = new GenericArray <Server> ();
    active_sessions = new GenericArray <Session> ();

    return true;
  }

  /**
   * Adds a server to be managed by ClientState.
   *
   * @param server The server to be added.
   */
  public void add_server (Server server) {
#if SUPPORT_TWITTER
    // Avoid adding Twitter servers to the ClientState
    if (server is Twitter.Server) {
      error ("Twitter servers should not be added to ClientState!");
    }
#endif

    // Add the server if not already in array
    if (! active_servers.find (server)) {
      active_servers.add (server);
    }
  }

  /**
   * Adds a session to be managed by ClientState.
   *
   * @param session The session to be added.
   */
  public void add_session (Session session) {
    // Add the session if not already in array
    if (! active_sessions.find (session)) {
      active_sessions.add (session);
    }
  }

  /**
   * Checks if an server with a given id exists.
   *
   * @param id The id to check for.
   *
   * @returns A server if one exists with the id, else null;
   */
  public Server? find_server_by_id (string id) {
    foreach (Server server in active_servers) {
      if (server.identifier == id) {
        return server;
      }
    }
    return null;
  }

  /**
   * Checks if an server for a given domain exists.
   *
   * @param domain The domain to check for.
   *
   * @returns A server if one exists for the domain, else null;
   */
  public Server? find_server_by_domain (string domain) {
    foreach (Server server in active_servers) {
      if (server.domain == domain) {
        return server;
      }
    }
    return null;
  }

  /**
   * Removes a server from ClientState and
   * it's access token from the KeyStorage.
   *
   * @param server The server to be removed.
   *
   * @throws Error Errors when removing the access token.
   */
  public void remove_server (Server server) throws Error {
    // Remove the server the server list
    if (active_servers.find (server)) {
      active_servers.remove (server);
    }

    // Remove the access token of the session
    try {
      KeyStorage.remove_access (@"ck_$(server.identifier)");
      KeyStorage.remove_access (@"cs_$(server.identifier)");
    } catch (Error e) {
      throw e;
    }
  }

  /**
   * Removes a session from ClientState and
   * it's access token from the KeyStorage.
   *
   * @param session The session to be removed.
   *
   * @throws Error Errors when removing the access token.
   */
  public void remove_session (Session session) throws Error {
    // Remove the session from the session list
    if (active_sessions.find (session)) {
      active_sessions.remove (session);
    }

    // Remove the access token of the session
    try {
      KeyStorage.remove_access (session.identifier);
    } catch (Error e) {
      throw e;
    }
  }

  /**
   * Cleans up backend-related stuff when the client is exited.
   */
  public void shutdown () {
    MediaLoader.instance.shutdown ();
  }

  /**
   * Stores the global instance of Client.
   */
  private static Client? global_instance = null;

  /**
   * Stores all sessions managed by ClientState.
   */
  private GenericArray <Server> active_servers;

  /**
   * Stores all sessions managed by ClientState.
   */
  private GenericArray <Session> active_sessions;

}
