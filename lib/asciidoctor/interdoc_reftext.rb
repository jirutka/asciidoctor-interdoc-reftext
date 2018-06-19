# frozen_string_literal: true
require 'asciidoctor' unless RUBY_PLATFORM == 'opal'
require 'asciidoctor/extensions' unless RUBY_PLATFORM == 'opal'
require 'asciidoctor/interdoc_reftext/version'
require 'asciidoctor/interdoc_reftext/processor'

Asciidoctor::Extensions.register do
  treeprocessor Asciidoctor::InterdocReftext::Processor
end
