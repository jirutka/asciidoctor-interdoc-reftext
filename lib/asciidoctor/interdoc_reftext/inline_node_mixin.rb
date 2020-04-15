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

      # interdoc_reftext_resolver may return nil when the extension was loaded,
      # but is disabled for the current document.
      if (resolver = interdoc_reftext_resolver)
        @text = resolver.call(@attributes['refid'])
      end
    end

    # @return [Asciidoctor::InterdocReftext::Resolver, nil]
    def interdoc_reftext_resolver
      # This variable is injected into the document by {Processor} or this method.
      @document.instance_variable_get(Processor::RESOLVER_VAR_NAME) || begin
        doc = @document
        until (resolver = doc.instance_variable_get(Processor::RESOLVER_VAR_NAME))
          doc = doc.parent_document or return nil
        end
        doc.instance_variable_set(Processor::RESOLVER_VAR_NAME, resolver)
      end
    end
  end
end
