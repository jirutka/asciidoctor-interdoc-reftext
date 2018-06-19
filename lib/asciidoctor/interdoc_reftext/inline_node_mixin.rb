# frozen_string_literal: true
require 'asciidoctor' unless RUBY_PLATFORM == 'opal'
require 'asciidoctor/interdoc_reftext/version'

module Asciidoctor::InterdocReftext
  # Mixin intended to be prepended into `Asciidoctor::Inline`.
  #
  # It modifies the method `#text` to resolve the value via {Resolver} if it's
  # not set, this node is an *inline_anchor* and has attribute *path* (i.e.
  # represents an inter-document cross reference).
  module InlineNodeMixin

    if RUBY_PLATFORM == 'opal'
      # Opal does not support `Module#prepend`, so we have to fallback to
      # `include` with poor alias method chain approach.
      def self.included(base_klass)
        base_klass.send(:alias_method, :text_without_reftext, :text)
        base_klass.send(:define_method, :text) do
          text_without_reftext || interdoc_reftext
        end
      end
    else
      # Returns text of this inline element.
      #
      # @note This method will override the same name attribute reader in
      #   class `Asciidoctor::Inline`.
      def text
        super || interdoc_reftext
      end
    end

    private

    # Returns resolved reftext of this inline node if it is a valid
    # inter-document cross-reference, otherwise returns nil.
    #
    # @return [String, nil]
    def interdoc_reftext
      # If this node is not an inter-document cross reference...
      return if @node_name != 'inline_anchor' || @attributes['path'].nil?

      # This variable is injected into the document by {Processor}.
      if (resolver = @document.instance_variable_get(Processor::RESOLVER_VAR_NAME))
        @text = resolver.call(@attributes['refid'])
      end
    end
  end
end
