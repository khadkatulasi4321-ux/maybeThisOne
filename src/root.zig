const std = @import("std");
const sha256 = std.crypto.hash.sha2.Sha256;
const blake3 = std.crypto.hash.Blake3;
const sha1 = std.crypto.hash.Sha1;
const sha512 = std.crypto.hash.sha2.Sha512;
const md5 = std.crypto.hash.Md5;

// pub const hash = enum {
//     sha256,
//     sha512,
//     blake3,
//     pub fn hshdigest(self: hash, str: []const u8) ![32]u8 {
//         switch (self) {
//             .sha256 => {
//                 var digest: [32]u8 = undefined;
//                 sha256.hash(str, &digest[0..32], .{});
//                 return digest;
//             },
//             .sha512 => {
//                 var digest: [64]u8 = undefined;
//                 sha512.hash(str, &digest, .{});
//                 return digest;
//             },
//             .blake3 => {
//                 var digest: [32]u8 = undefined;
//                 blake3.hash(str, &digest, .{});
//                 return digest;
//             },
//         }
//     }
// };
pub const Hash = enum {
    sha256,
    sha512,
    blake3,
    sha1,
    md5,

    pub fn digestSize(self: Hash) usize {
        return switch (self) {
            .sha256 => 32,
            .sha512 => 64,
            .blake3 => 32,
            .md5 => 16,
            .sha1 => 20,
        };
    }

    pub fn hashDigest(
        self: Hash,
        input: []const u8,
        out: []u8,
    ) ![]const u8 {
        const size = self.digestSize();

        if (out.len < size)
            return error.BufferTooSmall;

        switch (self) {
            .sha256 => {
                std.crypto.hash.sha2.Sha256.hash(
                    input,
                    out[0..32],
                    .{},
                );
            },

            .sha512 => {
                std.crypto.hash.sha2.Sha512.hash(
                    input,
                    out[0..64],
                    .{},
                );
            },

            .blake3 => {
                std.crypto.hash.Blake3.hash(
                    input,
                    out[0..32],
                    .{},
                );
            },

            .md5 => {
                std.crypto.hash.Md5.hash(
                    input,
                    out[0..16],
                    .{},
                );
            },

            .sha1 => {
                std.crypto.hash.Sha1.hash(
                    input,
                    out[0..20],
                    .{},
                );
            },
        }

        return out[0..size];
    }
};
