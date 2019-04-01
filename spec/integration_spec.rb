require_relative 'spec_helper'

require 'asciidoctor/interdoc_reftext/processor'
require 'asciidoctor'
require 'corefines'

using Corefines::String::unindent
using Corefines::Hash::except

FIXTURES_DIR = File.expand_path('fixtures', __dir__)


describe 'Intengration Tests' do

  subject(:output) { Asciidoctor.convert(input, options) }

  let(:input) { '' }  # this is modified in #given
  let(:processor) { Asciidoctor::InterdocReftext::Processor.new }

  let(:options) {
    processor_ = processor
    {
      safe: :safe,
      header_footer: false,
      base_dir: FIXTURES_DIR,
      extensions: proc { tree_processor processor_ },
    }
  }

  context 'document with valid inter-document xref without reftext' do

    context 'without fragment' do
      it 'renders title of the referenced document as reftext' do
        given 'xref:doc-a.adoc#[]'
        should have_anchor href: 'doc-a.html', text: 'Document A'
      end
    end

    context 'with fragment' do
      it 'renders title of the referenced section with implicit id as reftext' do
        given 'xref:doc-a.adoc#_first_section[]'
        should have_anchor href: 'doc-a.html#_first_section', text: 'First Section'
      end

      it 'renders title of the referenced section with explicit id as reftext' do
        given 'xref:doc-a.adoc#sec2[]'
        should have_anchor href: 'doc-a.html#sec2', text: 'Second Section'
      end

      it 'renders reftext of the referenced section with explicit reftext' do
        given 'xref:doc-a.adoc#_third_section[]'
        should have_anchor href: 'doc-a.html#_third_section', text: '3rd Section'
      end
    end

    context 'with relative path' do
      subject(:output) do
        opts = options.except(:base_dir)
        Asciidoctor.load_file("#{FIXTURES_DIR}/b/doc-b.adoc", opts).convert
      end

      it 'resolves path relative to the current document' do
        should have_anchor href: 'c/doc-c.html', text: 'Document C'
      end
    end

    context 'when extension is not active' do
      specify 'renders path of the referenced document as reftext' do
        given 'xref:doc-a.adoc#[]', extensions: []
        # Note: Asciidoctor 1.5.6 and 1.5.6.1 behaves differently.
        should have_anchor href: 'doc-a.html', text: /doc-a/
      end
    end
  end

  context 'document with invalid inter-document xref without reftext' do

    context 'without fragment' do
      it 'renders path of the non-existent document as reftext' do
        given 'xref:missing.adoc#[]'
        # Note: Asciidoctor 1.5.6 and 1.5.6.1 behaves differently.
        should have_anchor href: 'missing.html', text: /missing/
      end
    end

    context 'with non-existent fragment' do
      it 'renders path of the referenced document as reftext' do
        given 'xref:doc-a.adoc#missing[]'
        # Note: Asciidoctor 1.5.6 and 1.5.6.1 behaves differently.
        should have_anchor href: 'doc-a.html#missing', text: /doc-a/
      end
    end
  end

  context 'document with valid inter-document xref with reftext' do
    it 'renders provided reftext' do
      given 'xref:doc-a.adoc#[My Title]'
      should have_anchor href: 'doc-a.html', text: 'My Title'
    end
  end

  #----------  Helpers  ----------

  def given(str, opts = {})
    input.replace(str)
    options.merge!(opts)
  end

  def have_anchor(href: nil, text: nil)
    have_tag('a', with: { href: href }, text: text)
  end
end
