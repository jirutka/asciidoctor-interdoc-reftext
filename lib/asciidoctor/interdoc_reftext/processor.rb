# frozen_string_literal: true
require 'asciidoctor/extensions'
require 'asciidoctor/interdoc_reftext/inline_node_mixin'
require 'asciidoctor/interdoc_reftext/resolver'
require 'asciidoctor/interdoc_reftext/version'

module Asciidoctor::InterdocReftext
  # Asciidoctor processor that adds support for automatic cross-reference text
  # for inter-document cross references.
  #
  # ### Implementation Considerations
  #
  # Asciidoctor does not allow to _cleanly_ change the way of resolving
  # xreftext for `xref:path#[]` macro with path and without explicit xreflabel;
  # it always uses path as the default xreflabel.
  #
  # 1. `xref:[]` macros are parsed and even converted in
  #    `Asciidoctor::Substitutors#sub_inline_xrefs` - a single, huge and nasty
  #    method that accepts a text (e.g. whole paragraph) and returns the text
  #    with converted `xref:[]` macros. The conversion is delegated to
  #    `Asciidoctor::Inline#convert` - for each macro a new instance of
  #    `Inline` node is created and then `#convert` is called.
  #
  # 2. `Inline#convert` just calls `converter.convert` with `self`, i.e. it's
  #    dispatched to converter's `inline_anchor` handler.
  #
  # 3. The built-in so called HTML5 converter looks into the catalog of
  #    references (`document.catalog[:refs]`) for reflabel for the xref's
  #    *refid*, but only if xref node does not define attribute *path* or
  #    *text* (explicit reflabel). If *text* is not set and *path* is set, i.e.
  #    it's an inter-document reference without explicit reflabel, catalog of
  #    references is bypassed and *path* is used as a reflabel.
  #
  # Eh, this is really nasty... The least evil way how to achieve the goal
  # seems to be monkey-patching of the `Asciidoctor::Inline` class. This is
  # done via {InlineNodeMixin} which is prepended into the `Inline` class on
  # initialization of this processor.
  #
  # The actual logic that resolves reflabel for the given *refid* is
  # implemented in class {Resolver}. The {Processor} is responsible for
  # creating an instance of {Resolver} for the processed document and injecting
  # it into instance variable {RESOLVER_VAR_NAME} in the document, so
  # {InlineNodeMixin} can access it.
  #
  # Prepending {InlineNodeMixin} into the `Asciidoctor::Inline` class has
  # (obviously) a global effect. However, if {RESOLVER_VAR_NAME} is not
  # injected in the document object (e.g. extension is not active), `Inline`
  # behaves the same as without {InlineNodeMixin}.
  #
  # NOTE: We use _reftext_ and _reflabel_ as interchangeable terms in this gem.
  class Processor < ::Asciidoctor::Extensions::TreeProcessor

    # Name of instance variable that is dynamically defined in a document
    # object; it contains an instance of the Resolver for the document.
    RESOLVER_VAR_NAME = :@_interdoc_reftext_resolver

    # @param resolver_class [#new] the {Resolver} class to use.
    # @param resolver_opts [Hash<Symbol, Object>] options to be passed into
    #   the resolver_class's initializer (see {Resolver#initialize}).
    def initialize(resolver_class: Resolver, **resolver_opts)
      super
      @resolver_class = resolver_class
      @resolver_opts = resolver_opts

      # Monkey-patch Asciidoctor::Inline unless already patched.
      unless ::Asciidoctor::Inline.include? InlineNodeMixin
        ::Asciidoctor::Inline.send(:prepend, InlineNodeMixin)
      end
    end

    # @param document [Asciidoctor::Document] the document to process.
    def process(document)
      resolver = @resolver_class.new(document, @resolver_opts)
      document.instance_variable_set(RESOLVER_VAR_NAME, resolver)
      nil
    end
  end
end
