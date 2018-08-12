# frozen_string_literal: true
require 'asciidoctor/interdoc_reftext/version'
require 'asciidoctor/interdoc_reftext/processor'

unless RUBY_PLATFORM == 'opal'
  require 'asciidoctor'
  require 'asciidoctor/extensions'

  Asciidoctor::Extensions.register do
    treeprocessor Asciidoctor::InterdocReftext::Processor
  end
end
