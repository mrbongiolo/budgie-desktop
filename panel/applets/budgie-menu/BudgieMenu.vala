/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class BudgieMenu : Arc.Plugin, Peas.ExtensionBase
{
    public Arc.Applet get_panel_widget(string uuid)
    {
        return new BudgieMenuApplet(uuid);
    }
}

[GtkTemplate (ui = "/com/solus-project/budgie-menu/settings.ui")]
public class BudgieMenuSettings : Gtk.Grid
{

    [GtkChild]
    private Gtk.Switch? switch_menu_label;

    [GtkChild]
    private Gtk.Switch? switch_menu_compact;

    [GtkChild]
    private Gtk.Switch? switch_menu_headers;

    private Settings? settings;

    public BudgieMenuSettings(Settings? settings)
    {
        this.settings = settings;
        settings.bind("enable-menu-label", switch_menu_label, "active", SettingsBindFlags.DEFAULT);
        settings.bind("menu-compact", switch_menu_compact, "active", SettingsBindFlags.DEFAULT);
        settings.bind("menu-headers", switch_menu_headers, "active", SettingsBindFlags.DEFAULT);
    }

}

public class BudgieMenuApplet : Arc.Applet
{

    protected Gtk.EventBox widget;
    protected BudgieMenuWindow? popover;
    protected Settings settings;
    protected Settings ksettings;
    Gtk.Image img;
    Gtk.Label label;
    private string modifier;

    private unowned Arc.PopoverManager? manager = null;

    public string uuid { public set ; public get; }

    public override Gtk.Widget? get_settings_ui()
    {
        return new BudgieMenuSettings(this.get_applet_settings(uuid));
    }

    public override bool supports_settings()
    {
        return true;
    }

    public BudgieMenuApplet(string uuid)
    {
        Object(uuid: uuid);

        settings_schema = "com.solus-project.budgie-menu";
        settings_prefix = "/com/solus-project/arc-panel/instance/budgie-menu";

        settings = this.get_applet_settings(uuid);

        ksettings = new Settings("org.gnome.mutter");
        settings.changed.connect(on_settings_changed);
        ksettings.changed.connect(on_settings_changed);

        widget = new Gtk.EventBox();
        img = new Gtk.Image.from_icon_name("view-grid-symbolic", Gtk.IconSize.INVALID);
        img.pixel_size = 32;

        var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.pack_start(img, false, false, 3);
        label = new Gtk.Label("");
        label.halign = Gtk.Align.START;
        layout.pack_start(label, true, true, 3);

        widget.add(layout);

        // Better styling to fit in with the budgie-panel
        var st = img.get_style_context();
        st.add_class("primary-control");
        popover = new BudgieMenuWindow(settings, img);

        widget.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (popover.get_visible()) {
                popover.hide();
            } else {
                popover.get_child().show_all();
                this.manager.show_popover(widget);
            }
            return Gdk.EVENT_STOP;
        });

        popover.get_child().show_all();

        supported_actions = Arc.PanelAction.MENU;

        add(widget);
        show_all();
        layout.valign = Gtk.Align.CENTER;
        valign = Gtk.Align.FILL;
        halign = Gtk.Align.FILL;
        on_settings_changed("enable-menu-label");
        on_settings_changed("menu-icon");
        on_settings_changed("menu-label");
        on_settings_changed("overlay-key");

        panel_size_changed.connect((p,i)=> {
            img.pixel_size = (int)i;
        });

        popover.key_release_event.connect((e)=> {
            var human = Gdk.keyval_name(e.keyval);
            if (human == modifier) {
                popover.hide();
                return Gdk.EVENT_STOP;
            }
            return Gdk.EVENT_PROPAGATE;
        });
    }

    public override void invoke_action(Arc.PanelAction action)
    {
        if ((action & Arc.PanelAction.MENU) != 0) {
            if (popover.get_visible()) {
                popover.hide();
            } else {
                this.manager.show_popover(widget);
            }
        }
    }

    protected void on_settings_changed(string key)
    {
        switch (key)
        {
            case "menu-icon":
                if ("/" in settings.get_string(key)) {
                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(settings.get_string(key));
                    img.set_from_pixbuf(pixbuf.scale_simple(32, 32, Gdk.InterpType.BILINEAR));
                } else {
                    img.set_from_icon_name(settings.get_string(key), Gtk.IconSize.INVALID);
                }
                break;
            case "menu-label":
                label.set_label(settings.get_string(key));
                break;
            case "enable-menu-label":
                label.set_visible(settings.get_boolean(key));
                break;
            case "overlay-key":
                /* Reset modifiers.. */
                modifier = ksettings.get_string(key);
                break;
            default:
                break;
        }
    }

    public override void update_popovers(Arc.PopoverManager? manager)
    {
        this.manager = manager;
        manager.register_popover(widget, popover);
    }

} // End class

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Arc.Plugin), typeof(BudgieMenu));
}

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */
