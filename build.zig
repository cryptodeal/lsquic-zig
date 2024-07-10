const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_lsquic = b.addStaticLibrary(.{
        .name = "lsquic",
        .target = target,
        .optimize = optimize,
    });
    lib_lsquic.linkLibC();
    lib_lsquic.addIncludePath(b.path("."));
    lib_lsquic.addIncludePath(b.path("include"));
    lib_lsquic.addIncludePath(b.path("src/liblsquic"));
    lib_lsquic.addIncludePath(b.path("src/liblsquic/ls-qpack"));
    lib_lsquic.addIncludePath(b.path("src/liblsquic/ls-qpack/deps/xxhash"));
    lib_lsquic.addIncludePath(b.path("src/lshpack"));
    if (target.result.os.tag == .windows) {
        lib_lsquic.addIncludePath(b.path("wincompat"));
    }
    if (target.result.os.tag.isBSD() or target.result.os.tag.isDarwin()) {
        // lib_lsquic.linkSystemLibrary("event");
    }

    inline for (lsquic_STAT_SRCS, 0..) |path, i| {
        lib_lsquic.addCSourceFile(.{ .file = b.path("src/liblsquic/" ++ path), .flags = if (i == 0) qpack_flags else lsquic_flags });
    }
    lib_lsquic.addCSourceFile(.{ .file = b.path("src/lshpack/lshpack.c"), .flags = lsquic_flags });

    // link boringssl dependency
    const boringssl = b.dependency("boringssl", .{ .target = target, .optimize = optimize });
    const libssl = boringssl.artifact("ssl");
    const libcrypto = boringssl.artifact("crypto");
    lib_lsquic.linkLibrary(libssl);
    lib_lsquic.linkLibrary(libcrypto);
    lib_lsquic.installLibraryHeaders(libssl);

    const zlib = b.dependency("zlib", .{ .target = target, .optimize = optimize });
    const lib_zlib = zlib.artifact("zlib");
    lib_lsquic.linkLibrary(lib_zlib);
    lib_lsquic.installLibraryHeaders(lib_zlib);
    lib_lsquic.installHeadersDirectory(b.path("include"), "lsquic", .{});

    b.installArtifact(lib_lsquic);
}

const qpack_flags = &.{
    "-Wno-uninitialized",
    "-Wno-implicit-fallthrough",
};

const lsquic_flags = &.{
    "-Wall",
    "-Wextra",
    "-Wno-unused-parameter",
    "-fno-omit-frame-pointer",
    "-DWIN32_LEAN_AND_MEAN",
    "-DNOMINMAX",
    "-D_CRT_SECURE_NO_WARNINGS",
    "-DXXH_HEADER_NAME=\"lsquic_xxhash.h\"",
    // "-DLSQPACK_ENC_LOGGER_HEADER=\"lsquic_qpack_enc_logger.h\"",
};

// from `src/liblsquic/CMakelists.txt`
const lsquic_STAT_SRCS = &.{
    "ls-qpack/lsqpack.c",
    "lsquic_adaptive_cc.c",
    "lsquic_alarmset.c",
    "lsquic_arr.c",
    "lsquic_attq.c",
    "lsquic_bbr.c",
    "lsquic_bw_sampler.c",
    "lsquic_cfcw.c",
    "lsquic_chsk_stream.c",
    "lsquic_conn.c",
    "lsquic_crand.c",
    "lsquic_crt_compress.c",
    "lsquic_crypto.c",
    "lsquic_cubic.c",
    "lsquic_di_error.c",
    "lsquic_di_hash.c",
    "lsquic_di_nocopy.c",
    "lsquic_enc_sess_common.c",
    "lsquic_enc_sess_ietf.c",
    "lsquic_eng_hist.c",
    "lsquic_engine.c",
    "lsquic_ev_log.c",
    "lsquic_frab_list.c",
    "lsquic_frame_common.c",
    "lsquic_frame_reader.c",
    "lsquic_frame_writer.c",
    "lsquic_full_conn.c",
    "lsquic_full_conn_ietf.c",
    "lsquic_global.c",
    "lsquic_handshake.c",
    "lsquic_hash.c",
    "lsquic_hcsi_reader.c",
    "lsquic_hcso_writer.c",
    "lsquic_headers_stream.c",
    "lsquic_hkdf.c",
    "lsquic_hpi.c",
    "lsquic_hspack_valid.c",
    "lsquic_http.c",
    "lsquic_http1x_if.c",
    "lsquic_logger.c",
    "lsquic_malo.c",
    "lsquic_min_heap.c",
    "lsquic_mini_conn.c",
    "lsquic_mini_conn_ietf.c",
    "lsquic_minmax.c",
    "lsquic_mm.c",
    "lsquic_pacer.c",
    "lsquic_packet_common.c",
    "lsquic_packet_gquic.c",
    "lsquic_packet_in.c",
    "lsquic_packet_out.c",
    "lsquic_packet_resize.c",
    "lsquic_parse_Q046.c",
    "lsquic_parse_Q050.c",
    "lsquic_parse_common.c",
    "lsquic_parse_gquic_be.c",
    "lsquic_parse_gquic_common.c",
    "lsquic_parse_ietf_v1.c",
    "lsquic_parse_iquic_common.c",
    "lsquic_pr_queue.c",
    "lsquic_purga.c",
    "lsquic_qdec_hdl.c",
    "lsquic_qenc_hdl.c",
    "lsquic_qlog.c",
    "lsquic_qpack_exp.c",
    "lsquic_rechist.c",
    "lsquic_rtt.c",
    "lsquic_send_ctl.c",
    "lsquic_senhist.c",
    "lsquic_set.c",
    "lsquic_sfcw.c",
    "lsquic_shsk_stream.c",
    "lsquic_spi.c",
    "lsquic_stock_shi.c",
    "lsquic_str.c",
    "lsquic_stream.c",
    "lsquic_tokgen.c",
    "lsquic_trans_params.c",
    "lsquic_trechist.c",
    "lsquic_util.c",
    "lsquic_varint.c",
    "lsquic_version.c",
    "lsquic_xxhash.c",
};
