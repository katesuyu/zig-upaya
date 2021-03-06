const std = @import("std");
const upaya = @import("upaya");
usingnamespace upaya.imgui;

pub fn main() !void {
    upaya.run(.{
        .init = init,
        .update = update,
        .setupDockLayout = setupDockLayout,
        .docking = true,
    });
}

fn init() void {}

fn update() void {
    // note: the MenuItems do not automatically bind to keys. The shortcut field is just for the UI. You can add listeners for the key combos
    // like this:
    const io = igGetIO();
    if ((io.KeyCtrl or io.KeySuper) and ogKeyPressed(upaya.sokol.SAPP_KEYCODE_S)) {
        onSave();
    }

    upaya.menu.draw(&[_]upaya.MenuItem{ .{
        .label = "File",
        .children = &[_]upaya.MenuItem{
            .{ .label = "New", .shortcut = "cmd+n" },
            .{ .label = "Save", .shortcut = "cmd+s", .action = onSave },
        },
    }, .{
        .label = "Edit",
        .children = &[_]upaya.MenuItem{
            .{ .label = "Copy", .shortcut = "cmd+c" },
            .{ .label = "Paste", .shortcut = "cmd+v" },
        },
    } });

    _ = igBegin("Properties", null, ImGuiWindowFlags_None);
    ogAddRectFilled(igGetWindowDrawList(), ogGetCursorScreenPos(), ogGetContentRegionAvail(), upaya.colors.rgbToU32(255, 0, 0));
    igEnd();

    _ = igBegin("Top Left", null, ImGuiWindowFlags_None);
    ogAddRectFilled(igGetWindowDrawList(), ogGetCursorScreenPos(), ogGetContentRegionAvail(), upaya.colors.rgbToU32(0, 0, 255));
    igEnd();

    _ = igBegin("Bottom Left 1", null, ImGuiWindowFlags_None);
    ogAddRectFilled(igGetWindowDrawList(), ogGetCursorScreenPos(), ogGetContentRegionAvail(), upaya.colors.rgbToU32(0, 255, 0));
    igEnd();

    _ = igBegin("Bottom Left 2", null, ImGuiWindowFlags_None);
    ogAddRectFilled(igGetWindowDrawList(), ogGetCursorScreenPos(), ogGetContentRegionAvail(), upaya.colors.rgbToU32(100, 100, 100));
    igEnd();

    igSetNextWindowSize(.{ .x = 100, .y = 75 }, ImGuiCond_FirstUseEver);
    _ = igBegin("Floating", null, ImGuiWindowFlags_None);
    igEnd();
}

fn onSave() void {
    var file = upaya.filebrowser.saveFileDialog("Save File", "", "*.txt");
    if (file != null) {
        std.debug.print("save file: {s}\n", .{file});
    }
}

fn setupDockLayout(id: ImGuiID) void {
    var dock_main_id = id;

    // dock_main_id is the left node after this
    const right_id = igDockBuilderSplitNode(dock_main_id, ImGuiDir_Right, 0.35, null, &dock_main_id);
    igDockBuilderDockWindow("Properties", right_id);

    // dock_main_id is the bottom node after this
    const tl_id = igDockBuilderSplitNode(dock_main_id, ImGuiDir_Up, 0.48, null, &dock_main_id);
    igDockBuilderDockWindow("Top Left", tl_id);

    igDockBuilderDockWindow("Bottom Left 1", dock_main_id);
    igDockBuilderDockWindow("Bottom Left 2", dock_main_id);

    igDockBuilderFinish(id);
}
