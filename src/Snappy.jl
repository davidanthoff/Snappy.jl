module Snappy

export compress, uncompress

const libsnappy = "/usr/local/lib/libsnappy.dylib"

# snappy status
const SnappyOK = 0
const SnappyInvalidInput = 1
const SnappyBufferTooSmall = 2

function snappy_compress(input::Array{Uint8}, compressed::Array{Uint8})
    ilen = length(input)
    olen = Csize_t[length(compressed)]
    status = ccall(
        (:snappy_compress, libsnappy),
        Int,
        (Ptr{Uint8}, Csize_t, Ptr{Uint8}, Ptr{Csize_t}),
        input, ilen, compressed, olen
    )
    olen[1], status
end

function snappy_uncompress(compressed::Array{Uint8}, uncompressed::Array{Uint8})
    ilen = length(compressed)
    olen = Csize_t[length(uncompressed)]
    status = ccall(
        (:snappy_uncompress, libsnappy),
        Int,
        (Ptr{Uint8}, Csize_t, Ptr{Uint8}, Ptr{Csize_t}),
        compressed, ilen, uncompressed, olen
    )
    olen[1], status
end

function snappy_max_compressed_length(source_length::Uint)
    ccall((:snappy_max_compressed_length, libsnappy), Csize_t, (Csize_t,), source_length)
end

function snappy_uncompressed_length(compressed::Array{Uint8})
    len = length(compressed)
    result = Csize_t[0]
    status = ccall((:snappy_uncompressed_length, libsnappy), Int, (Ptr{Uint8}, Csize_t, Ptr{Csize_t}), compressed, len, result)
    result[1], status
end

function snappy_validate_compressed_buffer(compressed::Array{Uint8})
    ilen = length(compressed)
    ccall((:snappy_validate_compressed_buffer, libsnappy), Int, (Ptr{Uint8}, Csize_t), compressed, ilen)
end

# High-level Interfaces

function compress(input::Array{Uint8})
    ilen = length(input)
    maxlen = snappy_max_compressed_length(uint(ilen))
    compressed = Array(Uint8, maxlen)
    olen, st = snappy_compress(input, compressed)
    if st != SnappyOK
        error("compression failed")
    end
    resize!(compressed, olen)
    compressed
end

function uncompress(input::Array{Uint8})
    ilen = length(input)
    explen, st = snappy_uncompressed_length(input)
    if st != SnappyOK
        error("faield to guess the length of the uncompressed data (the compressed data may be broken?)")
    end
    uncompressed = Array(Uint8, explen)
    olen, st = snappy_uncompress(input, uncompressed)
    if st != SnappyOK
        error("failed to uncompress the data")
    end
    @assert explen == olen
    resize!(uncompressed, olen)
    uncompressed
end

end # module
