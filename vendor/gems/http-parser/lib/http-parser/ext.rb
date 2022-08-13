# frozen_string_literal: true

require 'ffi'

module HttpParser
    extend FFI::Library
    ffi_lib 'libhttp_parser.so.2.9'
end
