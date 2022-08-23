/* MainWindow.vala
 *
 * Copyright 2021-2022 Frederick Schenk
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

/**
 * The main window of the application, also responsible for new windows.
 */
[GtkTemplate (ui="/uk/co/ibboard/Cawbird/ui/Windows/MainWindow.ui")]
public class MainWindow : Adw.ApplicationWindow {

  // UI-Elements of MainWindow
  [GtkChild]
  private unowned Gtk.Stack window_stack;
  [GtkChild]
  private unowned AuthView auth_view;
  [GtkChild]
  private unowned Adw.Leaflet main_view;

  /**
   * The account currently displayed in this window.
   */
  public Backend.Account account {
    get {
      return displayed_account;
    }
    construct set {
      // Set the new account
      displayed_account = value;

      if (displayed_account != null) {
        // Display set account
        var main_page = new MainPage ();
        main_view.append (main_page);
        main_view.set_visible_child (main_page);
        main_page.account = displayed_account;
        this.window_stack.set_visible_child (main_view);
        this.title = @"$(Config.PROJECT_NAME) - @$(displayed_account.username)";
      } else {
        // Or open AuthView on non-existence
        this.window_stack.set_visible_child (auth_view);
        this.title = @"$(Config.PROJECT_NAME) - Authentication";
      }
    }
  }

  /**
   * Initializes a MainWindow.
   *
   * @param app The Gtk.Application for this window.
   * @param account The account to be assigned to this window, or null for an AuthView.
   */
  public MainWindow (Gtk.Application app, Backend.Account? account = null) {
    // Initializes the Object
    Object (
      application: app,
      account:     account
    );
  }

  /**
   * Run at the construction of an window.
   */
  construct {
    // Handle input when authentication is closed
    auth_view.close_auth.connect (() => {
      if (auth_view.account == null) {
        // Close the window if no account was added
        this.close ();
      } else {
        // Otherwise set the new account
        this.account      = auth_view.account;
        auth_view.account = null;
      }
    });
#if DEBUG
    // Add development style in debug
    this.add_css_class ("devel");
#endif
  }

  /**
   * Run at initialization of the class.
   */
  class construct {
    // Set up back button action
    install_action ("main.move-back", null, (widget, action) => {
      var window = widget as MainWindow;
      if (window != null) {
        window.main_view.navigate (BACK);
      }
    });
  }

  /**
   * Display a user in a new UserPage.
   *
   * @param user The user to be displayed.
   */
  public void display_user (Backend.User user) {
    // Check if a UserPage is active
    var current_page = main_view.visible_child as UserPage;
    if (current_page != null) {
      // Check if the user is already displayed
      if (current_page.user == user) {
        return;
      }
    }

    // Create the new page and make it visible
    var user_page = new UserPage ();
    main_view.append (user_page);
    user_page.user = user;
    main_view.set_visible_child (user_page);
  }

  /**
   * Removes the page the user has left.
   */
  [GtkCallback]
  private void on_transition () {
    // Do nothing while a transition is running
    if (main_view.child_transition_running) {
      return;
    }

    // Get the page the user left and removes it
    Gtk.Widget? left_page = main_view.get_adjacent_child (FORWARD);
    if (left_page != null) {
      main_view.remove (left_page);
    }
  }

  /**
   * Holds the displayed account.
   */
  private Backend.Account displayed_account;

}
