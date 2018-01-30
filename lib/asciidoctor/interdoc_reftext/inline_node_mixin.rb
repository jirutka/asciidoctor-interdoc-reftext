# frozen_string_literal: true
require 'asciidoctor/interdoc_reftext/version'
require 'asciidoctor'

module Asciidoctor::InterdocReftext
  # Mixin intended to be prepended into `Asciidoctor::Inline`.
  #
  # It modifies the method `#text` to resolve the value via {Resolver} if it's
  # not set, this node is an *inline_anchor* and has attribute *path* (i.e.
  # represents an inter-document cross reference).
  module InlineNodeMixin

    # Returns text of this inline element.
    #
    # @note This method will override the same name attribute reader in
    #   class `Asciidoctor::Inline`.
    #
    # @return [String, nil]
    def text
      if (value = super)
        value
      # If this node is an inter-document cross reference...
      elsif @node_name == 'inline_anchor' && @attributes['path']
        resolver = interdoc_reftext_resolver
        @text = resolver.call(@attributes['refid']) if resolver
      end
    end

    private

    # @return [#call, nil] an inter-document reftext resolver, or nil if not
    #   set for the document.
    def interdoc_reftext_resolver
      # This variable is injected into the document by {Processor}.
      @document.instance_variable_get(Processor::RESOLVER_VAR_NAME)
    end
  end
end
