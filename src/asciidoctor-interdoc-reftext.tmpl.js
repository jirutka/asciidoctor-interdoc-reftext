(function (Opal) {
  function initialize (Opal) {
//OPAL-GENERATED-CODE//
  }

  var mainModule

  function resolveModule (name) {
    if (!mainModule) {
      checkAsciidoctor()
      initialize(Opal)
      mainModule = Opal.const_get_qualified(Opal.Asciidoctor, 'InterdocReftext')
    }
    if (!name) {
      return mainModule
    }
    return Opal.const_get_qualified(mainModule, name)
  }

  function checkAsciidoctor () {
    if (typeof Opal.Asciidoctor === 'undefined') {
      throw new TypeError('Asciidoctor.js is not loaded')
    }
  }

  /**
   * @param {Object} opts
   * @param {String[]} opts.asciidocExts AsciiDoc file extensions (e.g. `.adoc`).
   *   Default is `['.adoc', '.asciidoc', '.ad']`.
   * @param {boolean} opts.raiseExceptions Whether to raise exceptions (`true`),
   *   or just log them (`false`). Default is `true`.
   * @return A new instance of `Asciidoctor::InterdocReftext::Processor`.
   */
  function TreeProcessor (opts) {
    opts = opts || {}

    var processor = resolveModule('Processor').$new(Opal.hash({
      resolver_class: opts.resolverClass,
      asciidoc_exts: opts.asciidocExts,
      logger: opts.logger,
      raise_exceptions: opts.raiseExceptions,
    }))
    processor.process = processor.$process

    return processor
  }

  /**
   * @return {string} Version of this extension.
   */
  function getVersion () {
    return resolveModule().$$const.VERSION.toString()
  }

  /**
   * Creates and configures the Inter-doc Reference Text extension and registers
   * it in the extensions registry.
   *
   * @param registry The Asciidoctor extensions registry to register this
   *   extension into. Defaults to the global Asciidoctor registry.
   * @param {Object} opts See {TreeProcessor} (optional).
   * @throws {TypeError} if the *registry* is invalid or Asciidoctor.js is not loaded.
   */
  function register (registry, opts) {
    if (!registry) {
      checkAsciidoctor()
      registry = Opal.Asciidoctor.Extensions
    }
    var processor = TreeProcessor(opts)

    // global registry
    if (typeof registry.register === 'function') {
      registry.register(function () {
        this.treeProcessor(processor)
      })
    // custom registry
    } else if (typeof registry.block === 'function') {
      registry.treeProcessor(processor)
    } else {
      throw new TypeError('Invalid registry object')
    }
  }

  var facade = {
    TreeProcessor: TreeProcessor,
    getVersion: getVersion,
    register: register,
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = facade
  }
  return facade
})(Opal);
