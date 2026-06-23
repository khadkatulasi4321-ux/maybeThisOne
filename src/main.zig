const std = @import("std");
const hsr = @import("maybeThislib");

pub fn main(init: std.process.Init) !void {
    const version = "0.0.0";
    const arena = init.arena;
    const alloc = arena.allocator();
    const equal = std.ascii.eqlIgnoreCase;
    const args = try init.minimal.args.toSlice(alloc);
    const clr = hsr.Color;

    if (args.len == 2) {
        if (equal(args[1], "help") or equal(args[1], "--help") or equal(args[1], "-h")) {
            std.debug.print(
                \\
                \\
                \\ {s}MaybeThisOne [{s}] by samsit-phew{s}
                \\
                \\  {s}usage: {s}
                \\      {s} <sha1|sha256|sha512|blake3|md5> <hash> <wordlist> <bytesallocatedforwordlist>
                \\
                \\  {s}example : {s}
                \\      {s} sha256 1c8bfe8f801d79745c4631d09fff36c82aa37fc4cce4fc946683d7b336b63032 myshittywordlist.txt 1024 
                \\
                \\  {s}note{s}:
                \\      if its a large wordlist increase bytesallocatedtoo 
                \\      max for now is 8192 or something like that 
                \\
                \\
            , .{
                clr.bold,
                version,
                clr.reset,
                clr.bold,
                clr.reset,
                args[0],
                clr.bold,
                clr.reset,
                args[0],
                clr.red,
                clr.reset,
            });
        } else if (equal(args[1], "version") or equal(args[1], "-v") or equal(args[1], "--version")) {
            std.debug.print(
                "{s}version{s}: {s}{s}{s}",
                .{ clr.red, clr.red, clr.bold, version, clr.reset },
            );
        }
        return;
    }

    if (args.len != 5) {
        std.debug.print(
            "{s}usage:{s} {s} <sha256|blake3|sha512|sha1|md5> <hash> <wordlist> <bytesallocatedforwordlist>\n",
            .{ clr.red, clr.reset, args[0] },
        );
        return;
    }

    const opt = args[1];
    const hash = args[2];
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
                "{s}error{s}: unknown algorithm: {s}\n",
                .{ clr.red, clr.reset, opt },
            );
            return;
        };
    if (hash.len != hashr.digestSize() * 2) {
        std.debug.print(
            "{s}error{s}: invalid hash for algorithm {s}",
            .{ clr.red, clr.reset, opt },
        );
        return;
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

    var expected: [64]u8 = undefined;

    _ = try std.fmt.hexToBytes(
        expected[0..hashr.digestSize()],
        hash,
    );

    defer guesses.deinit(gpa);

    for (guesses.items) |guess| {
        var digest: [64]u8 = undefined;

        _ = try hashr.hashDigest(
            guess,
            digest[0..],
        );

        if (std.mem.eql(
            u8,
            digest[0..hashr.digestSize()],
            expected[0..hashr.digestSize()],
        )) {
            std.debug.print(
                "yeaaaa boiiii hash found: {s} {s} {s}\n",
                .{ clr.green, guess, clr.reset },
            );
            return;
        }
    }
    std.debug.print("{s}naw man didnt find it {s}", .{ clr.yellow, clr.reset });
}
