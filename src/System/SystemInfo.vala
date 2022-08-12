/* SystemInfo.vala
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
 * Provides system information for debug and troubleshooting.
 */
namespace SystemInfo {

  /**
   * Returns all information for display.
   *
   * @return A string containing all system information.
   */
  public string display_info () {
    string info_string = "";

    // Add the information
    info_string += get_application_info () + "\n";
    info_string += get_backends_info () + "\n";
    info_string += get_client_info () + "\n";
    info_string += get_library_info () + "\n";
    info_string += get_system_info () + "\n";

    return info_string;
  }

  /**
   * Adds information about the application.
   */
  private string get_application_info () {
    string info_string = "";

    info_string += "Application:\n";
    info_string += @"- ID: $(Config.APPLICATION_ID)\n";
    info_string += @"- Version: $(Config.PROJECT_VERSION)\n";

    return info_string;
  }

  /**
   * Adds information about the backends.
   */
  private string get_backends_info () {
    string info_string = "";

    info_string += "Backends:\n";
#if SUPPORT_MASTODON
    info_string += "- Mastodon: enabled\n";
#else
    info_string += "- Mastodon: disabled\n";
#endif
#if SUPPORT_TWITTER
    info_string += "- Twitter: enabled\n";
#else
    info_string += "- Twitter: disabled\n";
#endif

    return info_string;
  }

  /**
   * Adds information about the backend client.
   */
  private string get_client_info () {
    string info_string = "";

    string redirect_uri = Backend.Client.instance.redirect_uri != null
                            ? Backend.Client.instance.redirect_uri
                            : "(none)";

    info_string += "Backend Client:\n";
    info_string += @"- Name: $(Backend.Client.instance.name)\n";
    info_string += @"- Website: $(Backend.Client.instance.website)\n";
    info_string += @"- Redirect-URI: $(redirect_uri)\n";

    return info_string;
  }

  /**
   * Adds information about the used libraries.
   */
  private string get_library_info () {
    string info_string = "";

    string glib_version = @"$(GLib.Version.major).$(GLib.Version.minor).$(GLib.Version.micro)";
    string gtk_version  = @"$(Gtk.get_major_version ()).$(Gtk.get_minor_version ()).$(Gtk.get_micro_version ())";
    string adw_version  = @"$(Adw.get_major_version ()).$(Adw.get_minor_version ()).$(Adw.get_micro_version ())";
    string soup_version = @"$(Soup.get_major_version ()).$(Soup.get_minor_version ()).$(Soup.get_micro_version ())";

    info_string += "Running against:\n";
    info_string += @"- GLib: Version $(glib_version)\n";
    info_string += @"- GTK: Version $(gtk_version)\n";
    info_string += @"- Adwaita: Version $(adw_version)\n";
    info_string += @"- Soup: Version $(soup_version)\n";

    return info_string;
  }

  /**
   * Adds information about the used libraries.
   */
  private string get_system_info () {
    string info_string = "";

    string os_name    = Environment.get_os_info ("NAME");
    string os_version = Environment.get_os_info ("VERSION");

    info_string += "System:\n";
    info_string += @"- Name: $(os_name)\n";
    info_string += @"- Version: $(os_version)\n";

    return info_string;
  }

}
