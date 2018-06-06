/*
 * This file is part of calendar-applet
 *
 * Copyright (C) 2017 Daniel Pinto <danielpinto8zz6@gmail.com>
 * Copyright (C) 2014-2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class CalendarPlugin : Budgie.Plugin, Peas.ExtensionBase {
    public Budgie.Applet get_panel_widget (string uuid) {
        return new CalendarApplet ();
    }
}

enum ClockFormat {
    TWENTYFOUR = 0, TWELVE = 1;
}

public const string CALENDAR_MIME = "text/calendar";

public class CalendarApplet : Budgie.Applet {

    protected Gtk.Box layout;
    protected Gtk.Button datetime_settings;
    protected Gtk.Calendar calendar;
    protected Gtk.EventBox widget;
    protected Gtk.Grid main_grid;
    protected Gtk.Grid preferences_grid;
    protected Gtk.Label clock;
    protected Gtk.Label date_label;
    protected Gtk.Label seconds_label;
    protected Gtk.Entry custom_format;

    protected Settings settings;
    protected Settings applet_settings;

    protected bool ampm = false;

    AppInfo ? calprov = null;

    Budgie.Popover ? popover = null;

    Gtk.Orientation orient = Gtk.Orientation.HORIZONTAL;

    Gtk.Switch switch_date;
    Gtk.Switch switch_format;
    Gtk.Switch switch_seconds;
    Gtk.Switch switch_custom_format;

    private DateTime time;

    private unowned Budgie.PopoverManager ? manager = null;

    ulong check_id;

    public override void panel_position_changed (Budgie.PanelPosition position) {
        if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
            this.orient = Gtk.Orientation.VERTICAL;
        } else {
            this.orient = Gtk.Orientation.HORIZONTAL;
        }
        this.seconds_label.set_text ("");
        this.layout.set_orientation (this.orient);
        this.update_clock ();
    }

    public CalendarApplet () {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        widget = new Gtk.EventBox ();
        layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
        clock = new Gtk.Label ("");
        time = new DateTime.now_local ();
        widget.add (layout);

        layout.pack_start (clock, false, false, 0);
        layout.margin = 0;
        layout.border_width = 0;

        seconds_label = new Gtk.Label ("");
        seconds_label.get_style_context ().add_class ("dim-label");
        layout.pack_start (seconds_label, false, false, 0);
        seconds_label.no_show_all = true;
        seconds_label.hide ();

        date_label = new Gtk.Label ("");
        layout.pack_start (date_label, false, false, 0);
        date_label.no_show_all = true;
        date_label.hide ();

        clock.valign = Gtk.Align.CENTER;
        seconds_label.valign = Gtk.Align.CENTER;
        date_label.valign = Gtk.Align.CENTER;
        
        clock.set_justify (Gtk.Justification.CENTER);
        seconds_label.set_justify (Gtk.Justification.CENTER);
        date_label.set_justify (Gtk.Justification.CENTER);

        applet_settings = new Settings ("com.github.danielpinto8zz6.budgie-calendar-applet");
        settings = new Settings ("org.gnome.desktop.interface");

        get_style_context ().add_class ("budgie-calendar-applet");

        popover = new Budgie.Popover (widget);
        var stack = new Gtk.Stack ();
        popover.add (stack);
        stack.set_homogeneous (true);
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

        // Grid inside popover to put widgets
        main_grid = new Gtk.Grid ();
        main_grid.set_can_focus (false);
        main_grid.set_margin_top (6);
        main_grid.set_margin_start (6);
        main_grid.set_margin_end (6);
        main_grid.set_margin_bottom (6);

        // Show Week day
        var weekday_label = new Gtk.Label ("");
        weekday_label.get_style_context ().add_class ("h1");
        weekday_label.set_halign (Gtk.Align.START);
        weekday_label.set_margin_start (10);
        main_grid.attach (weekday_label, 0, 0, 1, 1);

        // Show date
        var date_header = new Gtk.Label ("");
        date_header.get_style_context ().add_class ("h2");
        date_header.set_halign (Gtk.Align.START);
        date_header.set_margin_start (10);
        date_header.set_margin_bottom (10);
        main_grid.attach (date_header, 0, 1, 2, 1);

        // Time and Date settings Button
        datetime_settings = new Gtk.Button.from_icon_name ("emblem-system-symbolic", Gtk.IconSize.MENU);
        datetime_settings.set_halign (Gtk.Align.END);
        datetime_settings.set_can_focus (false);
        datetime_settings.clicked.connect (() => { stack.set_visible_child_name ("prefs"); });
        main_grid.attach_next_to (datetime_settings, weekday_label, Gtk.PositionType.RIGHT, 1, 1);

        // Calendar
        calendar = new Gtk.Calendar ();
        calendar.set_can_focus (false);
        main_grid.attach (calendar, 0, 2, 2, 1);

        stack.add_named (main_grid, "root");

        preferences_grid = new Gtk.Grid ();
        preferences_grid.set_can_focus (false);

        var label_date = new Gtk.Label (_ ("Show date"));
        label_date.set_halign (Gtk.Align.START);
        label_date.set_hexpand (true);
        switch_date = new Gtk.Switch ();
        switch_date.set_halign (Gtk.Align.END);
        switch_date.set_hexpand (true);

        settings.bind ("clock-show-date", switch_date, "active", SettingsBindFlags.GET | SettingsBindFlags.SET);
        settings.bind ("clock-show-date", date_label, "visible", SettingsBindFlags.DEFAULT);

        var label_seconds = new Gtk.Label (_ ("Show seconds"));
        label_seconds.set_halign (Gtk.Align.START);
        label_seconds.set_hexpand (true);
        switch_seconds = new Gtk.Switch ();
        switch_seconds.set_halign (Gtk.Align.END);
        switch_seconds.set_hexpand (true);

        settings.bind ("clock-show-seconds", switch_seconds, "active", SettingsBindFlags.GET | SettingsBindFlags.SET);
        settings.bind ("clock-show-seconds", seconds_label, "visible", SettingsBindFlags.DEFAULT);

        var label_format = new Gtk.Label (_ ("Use 24h time"));
        label_format.set_halign (Gtk.Align.START);
        label_format.set_hexpand (true);
        switch_format = new Gtk.Switch ();
        switch_format.set_halign (Gtk.Align.END);
        switch_format.set_hexpand (true);

        check_id = switch_format.notify["active"].connect (() => {
            ClockFormat f = (ClockFormat) settings.get_enum ("clock-format");
            ClockFormat newf = f == ClockFormat.TWELVE ? ClockFormat.TWENTYFOUR : ClockFormat.TWELVE;
            this.settings.set_enum ("clock-format", newf);
        });

        var label_switch_custom_format = new Gtk.Label (_ ("Custom date"));
        label_switch_custom_format.set_halign (Gtk.Align.START);
        label_switch_custom_format.set_hexpand (true);
        switch_custom_format = new Gtk.Switch ();
        switch_custom_format.set_halign (Gtk.Align.END);

        if(applet_settings.get_boolean("custom-format-switch"))
            switch_custom_format.set_active(true);

        string label_link = (_ ("Date format syntax"));
        Gtk.LinkButton linkbutton = new Gtk.LinkButton.with_label ("http://www.foragoodstrftime.com", label_link);

        custom_format = new Gtk.Entry ();
        custom_format.set_halign (Gtk.Align.FILL);
        if (applet_settings.get_boolean ("custom-format-switch") == false) {
            custom_format.set_sensitive (false);
        }

        // Print text to stdout on enter:
        custom_format.activate.connect (() => {
            unowned string str = custom_format.get_text ();
            stdout.printf ("%s\n", str);
            applet_settings.set_string ("custom-format", str);
        });

        // Add a delete-button:
        custom_format.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear");
        custom_format.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                custom_format.set_text ("");
            }
        });

        applet_settings.bind ("custom-format-switch", switch_custom_format, "active", SettingsBindFlags.GET | SettingsBindFlags.SET);

        if (switch_custom_format.get_active()){
            custom_format.set_sensitive (true);
            switch_date.set_sensitive (false);
            switch_seconds.set_sensitive (false);
            switch_format.set_sensitive (false);
      } else {
            custom_format.set_sensitive (false);
            switch_date.set_sensitive (true);
            switch_seconds.set_sensitive (true);
            switch_format.set_sensitive (true);
        }

        switch_custom_format.notify["active"].connect (() => {
            if ((switch_custom_format as Gtk.Switch).get_active ()) {
                custom_format.set_sensitive (true);
                switch_date.set_sensitive (false);
                switch_seconds.set_sensitive (false);
                switch_format.set_sensitive (false);
            } else {
                custom_format.set_sensitive (false);
                switch_date.set_sensitive (true);
                switch_seconds.set_sensitive (true);
                switch_format.set_sensitive (true);
            }
        });

        // Time and Date settings
        var time_and_date_settings = new Gtk.Button.with_label (_ ("Time and date settings"));
        time_and_date_settings.clicked.connect (open_datetime_settings);

        var back_main = new Gtk.Button.from_icon_name ("go-previous-symbolic", Gtk.IconSize.MENU);
        back_main.set_halign (Gtk.Align.START);
        back_main.set_can_focus (false);
        back_main.clicked.connect (() => { stack.set_visible_child_name ("root"); });

        var about = new Gtk.Button.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.MENU);
        about.set_halign (Gtk.Align.END);
        about.set_can_focus (false);
        about.clicked.connect (() => { about_dialog (); });

        Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.set_margin_top (4);
        separator.set_margin_bottom (4);

        preferences_grid.set_can_focus (false);
        preferences_grid.set_margin_start (6);
        preferences_grid.set_margin_end (6);
        preferences_grid.set_margin_top (6);
        preferences_grid.set_margin_bottom (6);
        preferences_grid.set_row_spacing (6);
        preferences_grid.set_column_spacing (6);
        preferences_grid.attach (back_main, 0, 0, 1, 1);
        preferences_grid.attach (about, 1, 0, 1, 1);
        preferences_grid.attach (separator, 0, 1, 2, 1);
        preferences_grid.attach (label_date, 0, 2, 1, 1);
        preferences_grid.attach (switch_date, 1, 2, 1, 1);
        preferences_grid.attach (label_seconds, 0, 3, 1, 1);
        preferences_grid.attach (switch_seconds, 1, 3, 1, 1);
        preferences_grid.attach (label_format, 0, 4, 1, 1);
        preferences_grid.attach (switch_format, 1, 4, 1, 1);
        preferences_grid.attach (label_switch_custom_format, 0, 5, 1, 1);
        preferences_grid.attach (switch_custom_format, 1, 5, 1, 1);
        preferences_grid.attach (custom_format, 0, 6, 2, 1);
        preferences_grid.attach (linkbutton, 0, 7, 2, 1);
        preferences_grid.attach (time_and_date_settings, 0, 8, 2, 1);

        stack.add_named (preferences_grid, "prefs");

        // Always open to the root page
        popover.closed.connect (() => {
            stack.set_visible_child_name ("root");
        });

        // Show date when over mouse
        widget.set_tooltip_text (time.format ("%e %b %Y"));

        // Click on clock show popover
        widget.button_press_event.connect ((e) => {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (popover.get_visible ()) {
                popover.hide ();
            } else {
                var time = new DateTime.now_local ();
                calendar.day = time.get_day_of_month ();
                weekday_label.set_label (time.format ("%A"));
                date_header.set_label (time.format ("%e %B %Y"));
                this.manager.show_popover (widget);
            }
            return Gdk.EVENT_STOP;
        });

        Timeout.add_seconds_full (GLib.Priority.LOW, 1, update_clock);

        settings.changed.connect (on_settings_change);
        applet_settings.changed.connect (on_applet_settings_change);

        // Setup calprov
        calprov = AppInfo.get_default_for_type (CALENDAR_MIME, false);

        var monitor = AppInfoMonitor.get ();
        monitor.changed.connect (update_cal);

        // Calendar clicked handler
        calendar.set_sensitive (calprov != null);
        calendar.day_selected_double_click.connect (() => { open_calendar (); });

        update_cal ();

        update_clock ();
        add (widget);

        on_settings_change ("clock-format");

        on_applet_settings_change ("custom-format");

        popover.get_child ().show_all ();

        show_all ();
    }

    public override void update_popovers (Budgie.PopoverManager ? manager) {
        this.manager = manager;
        manager.register_popover (widget, popover);
    }

    protected void on_settings_change (string key) {
        switch (key) {
        case "clock-format":
            SignalHandler.block ((void *) this.switch_format, this.check_id);
            ClockFormat f = (ClockFormat) settings.get_enum (key);
            ampm = f == ClockFormat.TWELVE;
            switch_format.set_active (f == ClockFormat.TWENTYFOUR);
            this.update_clock ();
            SignalHandler.unblock ((void *) this.switch_format, this.check_id);
            break;
        case "clock-show-seconds":
        case "clock-show-date":
            this.update_clock ();
            break;
        }
    }

    protected void on_applet_settings_change (string key) {
        switch (key) {
        case "custom-format":
            custom_format.set_text (applet_settings.get_string (key));
            this.update_clock ();
            break;
        case "custom-format-switch":
            this.update_clock ();
            break;
        }
    }

/**
 * Update the date if necessary
 */
    protected void update_date () {
        if (!switch_date.get_active ()) {
            return;
        }
        string ftime;
        if (this.orient == Gtk.Orientation.HORIZONTAL) {
            ftime = "%x";
        } else {
            ftime = "<small>%b %d</small>";
        }

        // Prevent unnecessary redraws
        var old = date_label.get_label ();
        var ctime = time.format (ftime);
        if (old == ctime) {
            return;
        }

        date_label.set_markup (ctime);
    }

/**
 * Update the seconds if necessary
 */
    protected void update_seconds () {
        if (!switch_seconds.get_active ()) {
            return;
        }
        string ftime;
        if (this.orient == Gtk.Orientation.HORIZONTAL) {
            ftime = "";
        } else {
            ftime = "<big>%S</big>";
        }

        // Prevent unnecessary redraws
        var old = date_label.get_label ();
        var ctime = time.format (ftime);
        if (old == ctime) {
            return;
        }

        seconds_label.set_markup (ctime);
    }

/**
 * This is called once every second, updating the time
 */
    protected bool update_clock () {
        time = new DateTime.now_local ();
        string format;

        if (applet_settings.get_boolean("custom-format-switch")) {
            unowned string title = custom_format.get_text ();
            format = title;
        } else {
            if (ampm) {
                format = "%l:%M";
            } else {
                format = "%H:%M";
            }

            if (orient == Gtk.Orientation.HORIZONTAL) {
                if (switch_seconds.get_active ()) {
                    format += ":%S";
                }
            }

            if (ampm) {
                format += " %p";
            }
        }

        string ftime;
        if (this.orient == Gtk.Orientation.HORIZONTAL) {
            ftime = " %s ".printf (format);
        } else {
            ftime = " <small>%s</small> ".printf (format);
        }

        this.update_date ();
        this.update_seconds ();

        // Prevent unnecessary redraws
        var old = clock.get_label ();
        var ctime = time.format (ftime);
        if (old == ctime) {
            return true;
        }

        clock.set_markup (ctime);
        this.queue_draw ();

        return true;
    }

    void update_cal () {
        calprov = AppInfo.get_default_for_type (CALENDAR_MIME, false);
        calendar.set_sensitive (calprov != null);
    }

    void open_datetime_settings () {
        this.popover.hide ();

        var list = new List<string>();
        list.append ("datetime");

        try {
            var appinfo =
                AppInfo.create_from_commandline ("gnome-control-center",
                                                 null,
                                                 AppInfoCreateFlags.SUPPORTS_URIS);
            appinfo.launch_uris (list, null);
        } catch (Error e) {
            message ("Unable to launch gnome-control-center datetime: %s", e.message);
        }
    }

    protected void open_calendar () {
        this.popover.hide ();

        try {
            var appinfo =
                AppInfo.create_from_commandline (calprov.get_executable (),
                                                 null,
                                                 AppInfoCreateFlags.SUPPORTS_URIS);
            appinfo.launch_uris (null, null);
        } catch (Error e) {
            message ("Unable to launch %s: %s", calprov.get_name (), e.message);
        }
    }

    void about_dialog () {
        this.popover.hide ();

        // Configure the dialog:
        Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
        dialog.set_destroy_with_parent (true);
        dialog.set_modal (true);

        dialog.authors = { "Daniel Pinto <danielpinto8zz6@gmail.com>" };
        dialog.documenters = null; // Real inventors don't document.
        dialog.translator_credits = null; // We only need a scottish version.

        dialog.program_name = "Budgie Calendar Applet";
        dialog.comments = "A budgie-desktop applet to show hours, date, and Calendar";
        dialog.copyright = "Copyright © 2016-2017 danielpinto8zz6";
        dialog.version = "4.0";
        dialog.logo_icon_name = "calendar";

        dialog.license_type = Gtk.License.GPL_2_0;

        dialog.website = "https://github.com/danielpinto8zz6/budgie-calendar-applet";
        dialog.website_label = "budgie-calendar-applet";

        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
                dialog.hide_on_delete ();
            }
        });
        dialog.present ();
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Budgie.Plugin), typeof (CalendarPlugin));
}
