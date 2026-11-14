module Invidious::Frontend::Comments
  extend self

  # Each comment is an article headed by its author. The default level 3
  # puts comments under the "View N comments" h2 on the watch and post pages
  # (added by comments.js, or by the view without JS); replies, fetched
  # separately, use it too.
  def template_youtube(comments, locale, thin_mode, is_replies = false, heading_level = 3)
    heading = "h#{heading_level}"

    String.build do |html|
      root = comments["comments"].as_a
      root.each do |child|
        if child["replies"]?
          replies_count_text = I18n.translate_count(locale,
            "comments_view_x_replies",
            child["replies"]["replyCount"].as_i64 || 0,
            I18n::NumberFormatting::Separator
          )

          # get_youtube_replies (comments.js, community.js) replaces the
          # content of the link's grandparent, the inner div.
          replies_html = <<-END_HTML
            <div class="replies">
              <div>
                <p>
                  <button type="button" class="simulated_a" data-continuation="#{child["replies"]["continuation"]}"
                    data-onclick="get_youtube_replies" data-load-replies>#{replies_count_text}</button>
                </p>
              </div>
            </div>
            END_HTML
        elsif comments["authorId"]? && !comments["singlePost"]?
          # for posts we should display a link to the post
          replies_count_text = I18n.translate_count(locale,
            "comments_view_x_replies",
            child["replyCount"].as_i64 || 0,
            I18n::NumberFormatting::Separator
          )

          replies_html = <<-END_HTML
            <div class="replies">
              <div>
                <p>
                  <a href="/post/#{child["commentId"]}?ucid=#{comments["authorId"]}">#{replies_count_text}</a>
                </p>
              </div>
            </div>
            END_HTML
        end

        if !thin_mode
          if child_author_thumbnail = child["authorThumbnail"]?.try &.as_s
            author_thumbnail = "/ggpht#{URI.parse(child_author_thumbnail).request_target}"
          else
            author_thumbnail = "/ggpht#{URI.parse(child["authorThumbnails"][-1]["url"].as_s).request_target}"
          end
        else
          author_thumbnail = ""
        end

        author_name = HTML.escape(child["author"].as_s)
        sponsor_icon = ""
        if child["verified"]?.try &.as_bool && child["authorIsChannelOwner"]?.try &.as_bool
          author_name += "&nbsp;<i class=\"icon ion ion-md-checkmark-circle\"></i>"
        elsif child["verified"]?.try &.as_bool
          author_name += "&nbsp;<i class=\"icon ion ion-md-checkmark\"></i>"
        end

        if child["isSponsor"]?.try &.as_bool
          sponsor_icon = String.build do |str|
            str << %(<img alt="" )
            str << %(src="/ggpht) << URI.parse(child["sponsorIconUrl"].as_s).request_target << "\" "
            str << %(title=") << I18n.translate(locale, "Channel Sponsor") << "\" "
            str << %(width="16" height="16" />)
          end
        end
        html << <<-END_HTML
          <article class="comment">
            <div class="channel-profile comment-avatar">
              <img loading="lazy" src="#{author_thumbnail}" alt="" />
            </div>
            <div class="comment-body">
              <header>
                <#{heading} class="comment-author">
                  <a class="#{child["authorIsChannelOwner"] == true ? "channel-owner" : ""}" href="#{child["authorUrl"]}">#{author_name}</a>
                  #{sponsor_icon}
                </#{heading}>
              </header>
              <p class="comment-content">#{child["contentHtml"]}</p>
          END_HTML

        if child["attachment"]?
          attachment = child["attachment"]

          case attachment["type"]
          when "image"
            attachment = attachment["imageThumbnails"][1]

            html << <<-END_HTML
              <div class="comment-image">
                <img loading="lazy" src="/ggpht#{URI.parse(attachment["url"].as_s).request_target}" alt="" />
              </div>
              END_HTML
          when "video"
            if attachment["error"]?
              html << <<-END_HTML
                <div class="video-iframe-wrapper">
                  <p>#{attachment["error"]}</p>
                </div>
                END_HTML
            else
              html << <<-END_HTML
                <div class="video-iframe-wrapper">
                  <iframe class="video-iframe" src='/embed/#{attachment["videoId"]?}?autoplay=0'></iframe>
                </div>
                END_HTML
            end
          when "multiImage"
            html << <<-END_HTML
              <div class="carousel">
              <a class="skip-link" href="#skip-#{child["commentId"]}">#{I18n.translate(locale, "carousel_skip")}</a>
              <div class="slides">
              END_HTML
            image_array = attachment["images"].as_a

            image_array.each_index do |i|
              html << <<-END_HTML
                  <div class="slides-item slide-#{i + 1}" id="#{child["commentId"]}-slide-#{i + 1}" aria-label="#{I18n.translate(locale, "carousel_slide", {"current" => (i + 1).to_s, "total" => image_array.size.to_s})}" tabindex="0">
                    <img loading="lazy" src="/ggpht#{URI.parse(image_array[i][1]["url"].as_s).request_target}" alt="" />
                  </div>
                END_HTML
            end

            html << <<-END_HTML
              </div>
              <div class="carousel__nav">
              END_HTML
            attachment["images"].as_a.each_index do |i|
              html << <<-END_HTML
                  <a class="slider-nav" href="##{child["commentId"]}-slide-#{i + 1}" aria-label="#{I18n.translate(locale, "carousel_go_to", (i + 1).to_s)}" tabindex="-1" aria-hidden="true">#{i + 1}</a>
                END_HTML
            end
            html << <<-END_HTML
                </div>
                <div id="skip-#{child["commentId"]}"></div>
              </div>
              END_HTML
          end
        end

        published = Time.unix(child["published"].as_i64)
        html << <<-END_HTML
          <footer>
          <p>
            <time datetime="#{published.to_rfc3339}" title="#{published.to_s(I18n.translate(locale, "%A %B %-d, %Y"))}">#{I18n.translate(locale, "`x` ago", recode_date(published, locale))}</time> #{child["isEdited"] == true ? I18n.translate(locale, "(edited)") : ""}
            |
          END_HTML

        if comments["videoId"]?
          html << <<-END_HTML
            <a rel="noreferrer noopener" href="https://www.youtube.com/watch?v=#{comments["videoId"]}&lc=#{child["commentId"]}" title="#{I18n.translate(locale, "YouTube comment permalink")}">[YT]</a>
            |
            END_HTML
        elsif comments["authorId"]?
          html << <<-END_HTML
            <a rel="noreferrer noopener" href="https://www.youtube.com/channel/#{comments["authorId"]}/community?lb=#{child["commentId"]}" title="#{I18n.translate(locale, "YouTube comment permalink")}">[YT]</a>
            |
            END_HTML
        end

        html << <<-END_HTML
          <i class="icon ion-ios-thumbs-up"></i> #{number_with_separator(child["likeCount"])}
          END_HTML

        if child["creatorHeart"]?
          if !thin_mode
            creator_thumbnail = "/ggpht#{URI.parse(child["creatorHeart"]["creatorThumbnail"].as_s).request_target}"
          else
            creator_thumbnail = ""
          end

          html << <<-END_HTML
            &nbsp;
            <span class="creator-heart-container" title="#{I18n.translate(locale, "`x` marked it with a ❤", child["creatorHeart"]["creatorName"].as_s)}">
                <span class="creator-heart">
                    <img loading="lazy" class="creator-heart-background-hearted" src="#{creator_thumbnail}" alt="" />
                    <span class="creator-heart-small-hearted">
                        <span class="icon ion-ios-heart creator-heart-small-container"></span>
                    </span>
                </span>
            </span>
            END_HTML
        end

        html << <<-END_HTML
              </p>
              </footer>
              #{replies_html}
            </div>
          </article>
          END_HTML
      end

      if comments["continuation"]?
        # get_youtube_replies removes the link's great-grandparent (the outer
        # div) from the list before appending the next page, so keep both divs.
        html << <<-END_HTML
          <div class="comments-load-more">
            <div>
              <p>
                <button type="button" class="simulated_a" data-continuation="#{comments["continuation"]}"
                  data-onclick="get_youtube_replies" data-load-more #{"data-load-replies" if is_replies}>#{I18n.translate(locale, "Load more")}</button>
              </p>
            </div>
          </div>
          END_HTML
      end
    end
  end
end
