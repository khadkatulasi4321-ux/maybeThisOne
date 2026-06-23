const std = @import("std");
const hsr = @import("maybeThislib");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena;
    const alloc = arena.allocator();
    const args = try init.minimal.args.toSlice(alloc);
    if (args.len != 5) {
        std.debug.print(
            "usage: {s} <sha256|blake3|sha512|sha1|md5> <hash> <wordlist> <bytesallocatedforwordlist>\n",
            .{args[0]},
        );
        std.process.exit(1);
    }
    const opt = args[1];
    const hash = args[2];
    const equal = std.ascii.eqlIgnoreCase;
    var sizeOfFileBuff = try std.fmt.parseInt(u16, args[4], 10);
    if (sizeOfFileBuff > 8192) {
        sizeOfFileBuff = 8192;
    }

    const hashr: hsr.Hash =
        if (equal(opt, "sha256"))
            .sha256
        else if (equal(opt, "blake3"))
            .blake3
        else if (equal(opt, "sha512"))
            .sha512
        else if (equal(opt, "md5"))
            .md5
        else if (equal(opt, "sha1"))
            .sha1
        else {
            std.debug.print(
                "unknown algorithm: {s}\n",
                .{opt},
            );
            std.process.exit(1);
        };
    if (hash.len != hashr.digestSize() * 2) {
        std.debug.print("invalid hash for algorithm {s}", .{opt});
        std.process.exit(1);
    }
    const gpa = init.gpa;
    const fileBuff = try gpa.alloc(u8, sizeOfFileBuff);

    const file = try std.Io.Dir.cwd().openFile(init.io, args[3], .{});
    defer file.close(init.io);

    var reader = file.reader(init.io, fileBuff);

    var guesses: std.ArrayList([]u8) = .empty;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const owned = try init.arena.allocator().dupe(u8, line);
        try guesses.append(gpa, owned);
    }
    gpa.free(fileBuff);

    const hequal = std.mem.eql;

    for (guesses.items) |guess| {
        var digest: [64]u8 = undefined;
        const digestx = try hashr.hashDigest(
            guess,
            digest[0..],
        );
        const s = hashr.digestSize();

        if (hequal([]u8, digest[0..s], hash)) {
            std.debug.print("hash found its hash of {x:0>2}", .{digestx});
            std.process.exit(0);
        }
    }
    std.debug.print("didnt find it ", .{});

    guesses.deinit(gpa);
}
