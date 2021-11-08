/* UserAvatar.vala
 *
 * Copyright 2021 Frederick Schenk
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
 * A small widget displaying an avatar of an user.
 */
[GtkTemplate (ui="/uk/co/ibboard/Cawbird/ui/Content/UserAvatar.ui")]
public class UserAvatar : Gtk.Widget {

  // UI-Elements of UserAvatar
  [GtkChild]
  private unowned Adw.Avatar avatar_holder;

  /**
   * The size of this widget.
   */
  public int size { get; set; default = 48; }

  /**
   * Deconstructs UserAvatar and it's childrens.
   */
  public override void dispose () {
    // Destructs children of UserAvatar
    avatar_holder.unparent ();
  }

}
