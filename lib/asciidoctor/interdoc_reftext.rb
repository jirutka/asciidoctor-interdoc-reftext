# frozen_string_literal: true
require 'asciidoctor/extensions'
require 'asciidoctor/interdoc_reftext/version'
require 'asciidoctor/interdoc_reftext/processor'

Asciidoctor::Extensions.register do
  treeprocessor Asciidoctor::InterdocReftext::Processor
end
