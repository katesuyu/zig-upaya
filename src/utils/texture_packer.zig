const std = @import("std");
const fs = std.fs;
const upaya = @import("../upaya.zig");
const math = upaya.math;
const stb = @import("stb");

pub const TexturePacker = struct {
    pub const Atlas = struct {
        names: [][]const u8,
        rects: []math.RectI,
        w: u16,
        h: u16,
        image: upaya.Image = undefined,

        pub fn init(frames: []stb.stbrp_rect, files: [][]const u8, size: Size) Atlas {
            std.debug.assert(frames.len == files.len);
            var res_atlas = Atlas{
                .names = upaya.mem.allocator.alloc([]const u8, files.len) catch unreachable,
                .rects = upaya.mem.allocator.alloc(math.RectI, frames.len) catch unreachable,
                .w = size.width,
                .h = size.height,
            };

            // convert to upaya rects
            for (frames) |frame, i| {
                res_atlas.rects[i] = .{ .x = frame.x, .y = frame.y, .w = frame.w, .h = frame.h };
            }

            for (files) |file, i| {
                res_atlas.names[i] = std.mem.dupe(upaya.mem.allocator, u8, fs.path.basename(file)) catch unreachable;
            }

            // generate the atlas
            var image = upaya.Image.init(size.width, size.height);
            image.fillRect(.{ .w = size.width, .h = size.height }, upaya.math.Color.transparent);

            for (files) |file, i| {
                var sub_image = upaya.Image.initFromFile(file);
                defer sub_image.deinit();
                image.blit(sub_image, frames[i].x, frames[i].y);
            }

            res_atlas.image = image;
            return res_atlas;
        }

        pub fn deinit(self: Atlas) void {
            for (self.names) |name| {
                upaya.mem.allocator.free(name);
            }
            upaya.mem.allocator.free(self.names);
            upaya.mem.allocator.free(self.rects);
            self.image.deinit();
        }

        /// saves the atlas image and a json file with the atlas details. filename should be only the name with no extension.
        pub fn save(self: Atlas, folder: []const u8, filename: []const u8, include_tex_coords: bool) void {

        }
    };

    pub const Size = struct {
        width: u16,
        height: u16,
    };

    pub fn pack(folder: []const u8) !Atlas {
        if (fs.cwd().openDir(folder, .{ .iterate = true })) |dir| {
            const pngs = upaya.fs.getAllFilesOfType(upaya.mem.allocator, dir, ".png", true);
            const frames = getFramesForPngs(pngs);
            if (runRectPacker(frames)) |atlas_size| {
                return Atlas.init(frames, pngs, atlas_size);
            } else {
                return error.NotEnoughRoom;
            }
        } else |err| {
            return err;
        }
    }

    fn getFramesForPngs(pngs: [][]const u8) []stb.stbrp_rect {
        var frames = std.ArrayList(stb.stbrp_rect).init(upaya.mem.allocator);
        for (pngs) |png, i| {
            var w: c_int = undefined;
            var h: c_int = undefined;
            const tex_size = upaya.Texture.getTextureSize(png, &w, &h);
            frames.append(.{
                .id = @intCast(c_int, i),
                .w = @intCast(u16, w),
                .h = @intCast(u16, h),
            }) catch unreachable;
        }

        return frames.toOwnedSlice();
    }

    fn runRectPacker(frames: []stb.stbrp_rect) ?Size {
        var ctx: stb.stbrp_context = undefined;
        const rects_size = @sizeOf(stb.stbrp_rect) * frames.len;
        const node_count = 4096 * 2;
        var nodes: [node_count]stb.stbrp_node = undefined;

        const texture_sizes = [_][2]c_int{
            [_]c_int{ 256, 256 },   [_]c_int{ 512, 256 },   [_]c_int{ 256, 512 },
            [_]c_int{ 512, 512 },   [_]c_int{ 1024, 512 },  [_]c_int{ 512, 1024 },
            [_]c_int{ 1024, 1024 }, [_]c_int{ 2048, 1024 }, [_]c_int{ 1024, 2048 },
            [_]c_int{ 2048, 2048 }, [_]c_int{ 4096, 2048 }, [_]c_int{ 2048, 4096 },
            [_]c_int{ 4096, 4096 }, [_]c_int{ 8192, 4096 }, [_]c_int{ 4096, 8192 },
        };

        for (texture_sizes) |tex_size| {
            stb.stbrp_init_target(&ctx, tex_size[0], tex_size[1], &nodes, node_count);
            stb.stbrp_setup_heuristic(&ctx, stb.STBRP_HEURISTIC_Skyline_default);
            if (stb.stbrp_pack_rects(&ctx, frames.ptr, @intCast(c_int, frames.len)) == 1) {
                return Size{ .width = @intCast(u16, tex_size[0]), .height = @intCast(u16, tex_size[1]) };
            }
        }

        return null;
    }
};