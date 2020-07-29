# frozen_string_literal: true

module EditorJs
  module Blocks
    class UrlBlock < Base
      def schema
        YAML.safe_load(<<~YAML)
          type: object
          additionalProperties: false
          properties:
            url:
              type: string
        YAML
      end

      def valid_url?(candidate)
        target = URI.parse(candidate)
        uri.is_a?(URI::HTTP) && !uri.host.nil?
        rescue URI::InvalidURIError
        false
      end

      def render(_options = {})
        url = data['url']

        # @TODO: check for valid url and render helpful message
        # @TODO: only apply target="_blank" to external links
        tag.a(url,  href: url, target: '_blank', class: css_name)
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
