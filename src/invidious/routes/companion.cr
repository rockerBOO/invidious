module Invidious::Routes::Companion
  extend self

  # GET /companion
  def get_companion(env)
    url = make_url(env)
    proxy_companion(env, "GET", url)
  end

  # POST /companion
  def post_companion(env)
    url = make_url(env)
    proxy_companion(env, "POST", url)
  end

  # OPTIONS /companion
  def options_companion(env)
    url = make_url(env)
    proxy_companion(env, "OPTIONS", url)
  end

  private def make_url(env)
    url = env.request.path
    if env.request.query
      url += "?#{env.request.query}"
    end
    url
  end

  private def proxy_companion(env, method, url)
    started = false
    attempt = 0

    begin
      loop do
        attempt += 1
        retry_after = false

        # This hands the upstream response straight to the browser, so the pool
        # must not retry for us: once the status line or any body bytes have
        # gone out, a second attempt would corrupt the stream.
        COMPANION_POOL.client(retry_on_error: false) do |wrapper|
          wrapper.client.exec(method, url, env.request.headers, (env.request.body if method == "POST")) do |resp|
            # Companion answers 5xx when its own upstream fetch fails, which is
            # transient and common. Nothing has been written to the client yet,
            # so a single retry is safe and saves the player a dead segment.
            if resp.status_code >= 500 && attempt < 2
              retry_after = true
              next
            end

            env.response.status_code = resp.status_code
            resp.headers.each do |key, value|
              env.response.headers[key] = value
            end
            started = true
            return IO.copy resp.body_io, env.response
          end
        end

        break unless retry_after
      end
    rescue
      if started
        # Too late for an error page: the status line has been flushed and the
        # body is partially written. Close the connection so the client sees a
        # truncated response immediately instead of waiting for its own timeout.
        begin
          env.response.close
        rescue
        end
      else
        env.response.headers.clear
        return Errors.error_json(502, "Couldn't proxy request to Invidious Companion.")
      end
    end
  end
end
