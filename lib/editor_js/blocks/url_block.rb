# frozen_string_literal: true

module EditorJs
  module Blocks
    class UrlBlock < Base

      # @TODO: supplement this whitelist from an ENV provided by the app,
      # since it could be accessed from additional public URLs.
      InternalHostWhitelist = [
        'localhost', 'saleskit-staging.herokuapp.com'
      ]

      def schema
        YAML.safe_load(<<~YAML)
          type: object
          additionalProperties: false
          properties:
            url:
              type: string
        YAML
      end

      def validated_url(candidate)
        target = URI.parse(candidate)
        is_web_or_relative = (
          target.is_a?(URI::HTTP) ||
          target.is_a?(URI::HTTPS)||
          target.is_a?(URI::Generic)
        )
        return nil unless is_web_or_relative

        target
      rescue URI::InvalidURIError
        nil
      end

      # External URLs need target_blank, so that when opened, they trigger a
      # new-window event, which we can listen for in Electron, to open that
      # link in the OS browser instead of the Electron app
      def target(url)
        # An internal URL could have a path, but no host, like /plays/2.
        # It could also have the absolute URL with a scheme and  host, in which
        # case, we can make the decision using the public URL whitelist
        is_internal = url.scheme.nil? || InternalHostWhitelist.any? do |host|
          url.host.downcase == host
        end

        return nil if is_internal

        "_blank"
      end

      def a_block(url)
        tag.div(
          tag.a(url.to_s,  href: url.to_s, target: target(url), class: "editorjs--url-link"),
          class: css_name
        )
      end

      def warning_block
        tag.div(
          tag.i("(invalid url)", class: 'editorjs--url-invalid'),
          class: css_name
        )
      end

      def add_protocol(href)
        return href if href.match?(/^(\w+):(\/\/)?/)

        is_internal = href.match?(/^\/[^\/\s]/)
        is_anchor = href[0].eql?('#')
        is_protocol_relative = href.match?(/^\/\/[^\/\s]/)
        will_add_protocol = !is_internal && !is_anchor && !is_protocol_relative

        if will_add_protocol
          #require('pry'); binding.pry
        end

        href = "http://#{href}" if will_add_protocol

        return href
      end

      def render(_options = {})
        link_text = add_protocol(data['url'])
        url = validated_url(link_text)
        return warning_block unless url

        a_block(url)
      end

      def sanitize!
        safe_tags = {
          'b' => nil,
          'i' => nil,
          'u' => ['class'],
          'del' => ['class'],
          'a' => ['href', 'target', 'class'],
          'mark' => ['class'],
          'code' => ['class']
        }

        data['url'] = Sanitize.fragment(
          data['url'],
          elements: safe_tags.keys,
          attributes: safe_tags.select {|k, v| v},
          remove_contents: true
        )
      end

      def plain
        decode_html(Sanitize.fragment data['url']).strip
      end
    end
  end
end
