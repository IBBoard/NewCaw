/* Picture.vala
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

public class Backend.Mastodon.Picture : Backend.Picture, Backend.Mastodon.Media  {

  /**
   * Creates an Picture object from a given Json.Object.
   *
   * @param json A Json.Object containing the data.
   */
  public Picture.from_json (Json.Object json) {
    // Set base properties
    base.from_json (json);
  }

  /**
   * Loads the media for display.
   */
  public async Gdk.Texture? load_media () {
    // Load from storage if already loaded
    if (media != null) {
      return media;
    }
    // TODO: Implement the downloader
    return null;
  }

  /**
   * The downloaded media in storage.
   */
  private Gdk.Texture? media;

}