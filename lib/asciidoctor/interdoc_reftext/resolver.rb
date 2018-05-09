# frozen_string_literal: true
require 'asciidoctor/interdoc_reftext/version'
require 'asciidoctor'
require 'logger'

module Asciidoctor::InterdocReftext
  # Resolver of inter-document cross reference texts.
  class Resolver

    # @param document [Asciidoctor::Document] the document associated with this resolver.
    # @param asciidoc_exts [Array<String>] AsciiDoc file extensions (e.g. `.adoc`).
    # @param logger [Logger, nil] the logger to use for logging warning and errors.
    #   Defaults to `Asciidoctor::LoggerManager.logger` if using Asciidoctor 1.5.7+,
    #   or `Logger.new(STDERR)` otherwise.
    # @param raise_exceptions [Boolean] whether to raise exceptions, or just log them.
    def initialize(document,
                   asciidoc_exts: ['.adoc', '.asciidoc', '.ad'],
                   logger: nil,
                   raise_exceptions: true)

      logger ||= if defined? ::Asciidoctor::LoggerManager
        ::Asciidoctor::LoggerManager.logger
      else
        ::Logger.new(STDERR)
      end

      @document = document
      @asciidoc_exts = asciidoc_exts.dup.freeze
      @logger = logger
      @raise_exceptions = raise_exceptions
      @cache = {}
    end

    # @param refid [String] the target without a file extension, optionally with
    #   a fragment (e.g. `intro`, `intro#about`).
    # @return [String, nil] reference text, or `nil` if not found.
    # @raise ArgumentError if the *refid* is empty or starts with `#` and
    #   *raise_exceptions* is true.
    def resolve_reftext(refid)
      if refid.empty? || refid.start_with?('#')
        msg = "interdoc-reftext: refid must not be empty or start with '#', but given: '#{refid}'"
        raise ArgumentError, msg if @raise_exceptions
        @logger.error msg
        return nil
      end

      path, fragment = refid.split('#', 2)
      path = resolve_target_path(path) or return nil

      @cache["#{path}##{fragment}".freeze] ||= begin
        lines = read_file(path) or return nil
        parse_reftext(lines, fragment)
      rescue => e  # rubocop: disable RescueWithoutErrorClass
        raise if @raise_exceptions
        @logger.error "interdoc-reftext: #{e}"
        nil
      end
    end

    alias call resolve_reftext

    protected

    # @return [Array<String>] AsciiDoc file extensions (e.g. `.adoc`).
    attr_reader :asciidoc_exts

    # @return [Hash<String, String>] a cache of resolved reftexts.
    attr_reader :cache

    # @return [Asciidoctor::Document] the document associated with this resolver.
    attr_reader :document

    # @return [Logger] the logger to use for logging warning and errors.
    attr_reader :logger

    # @return [Boolean] whether to raise exceptions, or just log them.
    attr_reader :raise_exceptions

    # @param target_path [String] the target path without a file extension.
    # @return [String, nil] file path of the *target_path*, or `nil` if not found.
    def resolve_target_path(target_path)
      # Include file is resolved relative to dir of the current include,
      # or base_dir if within original docfile.
      path = @document.normalize_system_path(target_path, @document.reader.dir,
                                             nil, target_name: 'xref target')
      return nil unless path

      @asciidoc_exts.each do |extname|
        filename = path + extname
        return filename if ::File.file? filename
      end
      nil
    end

    # @param path [String] path of the file to read.
    # @return [Enumerable<String>] lines of the file.
    def read_file(path)
      ::IO.foreach(path)
    end

    # @param input [Enumerable<String>] lines of the AsciiDoc document.
    # @param fragment [String, nil] part of the target after `#`.
    # @return [String, nil]
    def parse_reftext(input, fragment = nil)
      unless fragment
        # Document title is typically defined at top of the document,
        # so we try to parse just the first 10 lines to save resources.
        # If document title is not here, we fallback to parsing whole document.
        title = asciidoc_load(input.take(10)).doctitle
        return title if title
      end

      doc = asciidoc_load(input)

      if fragment
        ref = doc.catalog[:refs][fragment]
        ref.xreftext if ref
      else
        doc.doctitle
      end
    end

    # @param input [Enumerable<String>, String] lines of the AsciiDoc document to load.
    # @return [Asciidoctor::Document] a parsed document.
    def asciidoc_load(input)
      # Asciidoctor is dumb. It doesn't know enumerators and when we give it
      # an Array, it calls #dup on it. At least it knows #readlines, so we just
      # define it as an alias for #to_a.
      if input.is_a?(::Enumerable) && !input.respond_to?(:readlines)
        input.singleton_class.send(:alias_method, :readlines, :to_a)
      end

      ::Asciidoctor.load(input, @document.options)
    end
  end
end
