/* Post.vala
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
 * Represents one posted status message.
 */
public class Backend.TwitterLegacy.Post : Object, Backend.Post {

  /**
   * The unique identifier of this post.
   */
  public string id { get; }

  /**
   * The time this post was posted.
   */
  public DateTime date { get; }

  /**
   * The message of this post.
   */
  public string text {
    owned get {
      return Backend.TextUtils.format_text (text_modules);
    }
  }

  /**
   * The source application who created this Post.
   */
  public string source { get; }

  /**
   * How often the post was liked.
   */
  public int64 liked_count { get; }

  /**
   * How often the post was replied to.
   */
  public int64 replied_count { get; }

  /**
   * How often this post was reposted or quoted.
   */
  public int64 reposted_count { get; }

  /**
   * Parses an given Json.Object and creates an Post object.
   *
   * @param json A Json.Object retrieved from the API.
   */
  public Post.from_json (Json.Object json) {
    // Get basic data
    _id   = json.get_string_member ("id_str");
    _date = TextUtils.parse_time (json.get_string_member ("created_at"));

    // Parse source
    try {
      string application  = json.get_string_member ("source");
      var    source_regex = new Regex ("<a.*?>(.*?)</a>");
      _source = source_regex.replace (
        application,
        application.length,
        0,
        "\\1"
      );
    } catch (RegexError e) {
      error (@"Error while parsing source: $(e.message)");
    }

    // Get metrics
    _liked_count    = json.get_int_member ("favorite_count");
    // TODO: Add `replied_count` by counting actual replies
    _reposted_count = json.get_int_member ("retweet_count");

    // Parse the text into modules
    Json.Object? entities   = null;
    string       raw_text   = "";
    uint         text_start = 0;

    if (json.has_member ("display_text_range")) {
      Json.Array text_range = json.get_array_member ("display_text_range");
      text_start = (uint) text_range.get_int_element (0);
    }

    if (json.has_member ("full_text")) {
      raw_text = json.get_string_member ("full_text") [text_start:];
    } else {
      raw_text = json.get_string_member ("text") [text_start:];
    }

    if (json.has_member ("entities")) {
      entities = json.get_object_member ("entities");
    }

    text_modules = TextUtils.parse_text (raw_text, entities);
  }

#if DEBUG
  /**
   * Returns the text modules.
   *
   * Only used in test cases and therefore only available in debug builds.
   */
  public TextModule[] get_text_modules () {
    return text_modules;
  }
#endif

  /**
   * The text split into modules for formatting.
   */
  private TextModule[] text_modules;

}
