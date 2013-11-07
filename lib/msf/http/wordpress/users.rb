# -*- coding: binary -*-
module Msf::HTTP::Wordpress::Users

  # Checks if the given user exists
  #
  # @param user [String] Username
  # @return [Boolean] true if the user exists
  def wordpress_user_exists?(user)
    res = send_request_cgi({
        'method' => 'POST',
        'uri' => wordpress_url_login,
        'vars_post' => wordpress_helper_login_post_data(user, Rex::Text.rand_text_alpha(6))
    })

    return true if res and res.code == 200 and
        (res.body.to_s =~ /Incorrect password/ or
            res.body.to_s =~ /document\.getElementById\('user_pass'\)/)

    return false
  end

  # Checks if the given userid exists
  #
  # @param user_id [Integer] user_id
  # @return [String,nil] the Username if it exists, nil otherwise
  def wordpress_userid_exists?(user_id)
    # Wordpress returns all posts from all users on user_id 0
    return nil if user_id < 1

    url = wordpress_url_author(user_id)
    res = send_request_cgi({
        'method' => 'GET',
        'uri' => url
    })

    if res and res.code == 301
      uri = wordpress_helper_parse_location_header(res)
      return nil unless uri
      # try to extract username from location
      if uri.to_s =~ /\/author\/([^\/\b]+)\/?/i
        return $1
      end
      uri = "#{uri.path}?#{uri.query}"
      res = send_request_cgi({
          'method' => 'GET',
          'uri' => uri
      })
    end

    if res.nil?
      print_error("#{peer} - Error getting response.")
      return nil
    elsif res.code == 200 and
        (
          res.body =~ /href="http[s]*:\/\/.*\/\?*author.+title="([[:print:]]+)" /i or
          res.body =~ /<body class="archive author author-(?:[^\s]+) author-(?:\d+)/i or
          res.body =~ /Posts by (\w+) Feed/i or
          res.body =~ /<span class='vcard'><a class='url fn n' href='[^"']+' title='[^"']+' rel='me'>([^<]+)<\/a><\/span>/i or
          res.body =~ /<title>.*(\b\w+\b)<\/title>/i
        )
      return $1
    end
  end

end
