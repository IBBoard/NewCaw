/* Profile.vala
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

public class Backend.TwitterLegacy.Profile : Backend.TwitterLegacy.User, Backend.Profile {

  /**
   * When this Profile was created on the platform.
   */
  public DateTime creation_date { get; construct; }

  /**
   * A formatted description set for the Profile.
   */
  public string description {
    owned get {
      return Backend.TextUtils.format_text (description_modules);
    }
  }

  /**
   * The header image for the detail page of this user.
   */
  public Backend.Picture header { get; construct; }

  /**
   * How many people are following this Profile.
   */
  public int followers_count { get; construct; }

  /**
   * How many people this Profile follows.
   */
  public int following_count { get; construct; }

  /**
   * How many posts this Profile wrote.
   */
  public int posts_count { get; construct; }

  /**
   * The website where this post originates from.
   *
   * Mostly important for the Mastodon backend, where a post
   * can come from multiple site thanks to the federation.
   */
  public string domain { get; construct; }

  /**
   * The url to visit this post on the original website.
   */
  public string url { get; construct; }

  /**
   * Parses an given Json.Object and creates an Profile object.
   *
   * @param json A Json.Object retrieved from the API.
   */
  public Profile.from_json (Json.Object json) {
    // Parse the url for avatar and header
    string avatar_url         = json.get_string_member ("profile_image_url_https");
    string header_preview_url = json.has_member ("profile_banner_url") ?
                                  json.get_string_member ("profile_banner_url")
                                  : null;
    string header_media_url = "";
    try {
      var image_regex = new Regex ("(https://pbs.twimg.com/.*?)_normal(\\..*)");
      avatar_url = image_regex.replace (
        avatar_url,
        avatar_url.length,
        0,
        "\\1_bigger\\2"
      );
      if (header_preview_url != null) {
        header_media_url = image_regex.replace (
          header_preview_url,
          header_preview_url.length,
          0,
          "\\1\\2"
        );
      }
    } catch (RegexError e) {
      error (@"Error while parsing source: $(e.message)");
    }

    // Construct the object with properties
    Object (
      // Set the id of the profile
      id: json.get_string_member ("id_str"),

      // Set the creation data
      creation_date: TextUtils.parse_time (json.get_string_member ("created_at")),

      // Set the names of the profile
      display_name: json.get_string_member ("name"),
      username:     json.get_string_member ("screen_name"),

      // Set metrics
      followers_count: (int) json.get_int_member ("followers_count"),
      following_count: (int) json.get_int_member ("friends_count"),
      posts_count:     (int) json.get_int_member ("statuses_count"),

      // Set the ImageLoader for the avatar
      avatar: new Picture (avatar_url),
      header: header_preview_url != null
                ? new Picture (header_media_url, header_preview_url)
                : null
    );

    // Parse the text into modules
    Json.Object? description_entities = null;
    Json.Object? weblink_entity       = null;
    string       raw_text             = json.get_string_member ("description");

    // Parse entities
    if (json.has_member ("entities")) {
      Json.Object profile_entities = json.get_object_member ("entities");
      // Parse entities for the description
      if (profile_entities.has_member ("description")) {
        description_entities = profile_entities.get_object_member ("description");
      }
      // Parse entity for the linked url
      if (profile_entities.has_member ("url")) {
        Json.Object profile_urls = profile_entities.get_object_member ("url");
        Json.Array  urls_array   = profile_urls.get_array_member ("urls");
        // It should only have one element, so assuming this to avoid an loop
        Json.Node url_node = urls_array.get_element (0);
        if (url_node.get_node_type () == OBJECT) {
          weblink_entity = url_node.get_object ();
        }
      }
    }

    description_modules = TextUtils.parse_text (raw_text, description_entities);

    // Store additional information in data fields
    UserDataField[] additional_fields = {};
    if (json.has_member ("location")) {
      if (json.get_string_member ("location") != "") {
        var new_field      = UserDataField ();
        new_field.type     = LOCATION;
        new_field.name     = "Location";
        new_field.display  = json.get_string_member ("location");
        new_field.target   = null;
        additional_fields += new_field;
      }
    }
    if (weblink_entity != null) {
      var new_field      = UserDataField ();
      new_field.type     = WEBLINK;
      new_field.name     = "Weblink";
      new_field.display  = weblink_entity.get_string_member ("display_url");
      new_field.target   = weblink_entity.get_string_member ("expanded_url");
      additional_fields += new_field;
    }
    data_fields = additional_fields;

    // Get possible flags for this profile
    if (json.get_boolean_member ("protected")) {
      flags = flags | MODERATED | PROTECTED;
    }
    if (json.get_boolean_member ("verified")) {
      flags = flags | VERIFIED;
    }
  }

  /**
   * Run at object construction.
   *
   * Used to manually construct the url and domain properties,
   * as these are not provided by the Twitter API.
   */
  construct {
    // Set domain and url
    domain =  "Twitter.com";
    url    = @"https://$(domain)/$(username)";
  }

  /**
   * Retrieves the UserDataFields for this Profile.
   */
  public UserDataField[] get_data_fields () {
    return data_fields;
  }

#if DEBUG
  /**
   * Returns the text modules from the description.
   *
   * Only used in test cases and therefore only available in debug builds.
   */
  public TextModule[] get_description_modules () {
    return description_modules;
  }
#endif

  /**
   * All data fields attached to this post.
   */
  public UserDataField[] data_fields;

  /**
   * The description split into modules for formatting.
   */
  private TextModule[] description_modules;

}