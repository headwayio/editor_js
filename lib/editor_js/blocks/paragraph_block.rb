# frozen_string_literal: true

module EditorJs
  module Blocks
    class ParagraphBlock < Base
      def schema
        YAML.safe_load(<<~YAML)
          type: object
          additionalProperties: false
          properties:
            text:
              type: string
            alignment:
              type: string
              enum:
                - align-left
                - align-center
                - align-right
        YAML
      end

      def render(_options = {})
        alignment = data['alignment']
        class_name_str = css_name
        if alignment.present?
          class_name_str = [
            class_name_str,
            css_name("__#{alignment}")
          ].join(' ')
        end
        content_tag(:div, class: class_name_str) { data['text'].html_safe }
      end

      def sanitize!
        safe_tags = {
          'b' => nil,
          'i' => nil,
          'u' => ['class'],
          'del' => ['class'],
          'a' => ['href'],
          'mark' => ['class'],
          'code' => ['class']
        }

        data['text'] = Sanitize.fragment(
          data['text'],
          elements: safe_tags.keys,
          attributes: safe_tags.select {|k, v| v},
          remove_contents: true
        )
      end

      def plain
        decode_html(Sanitize.fragment data['text']).strip
      end
    end
  end
end
