/*
 * This file is part of calendar-applet
 *
 * Copyright (C) 2018 Daniel Pinto <danielpinto8zz6@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace CalendarApplet {
    public class AppletSettings : Gtk.Grid {
        protected Settings settings;
        protected Settings applet_settings;

        private Gtk.Switch switch_date;
        private Gtk.Switch switch_format;
        private Gtk.Switch switch_seconds;
        private Gtk.Switch switch_week_numbers;
        private Gtk.Switch switch_custom_format;
        private Gtk.Entry  custom_format;

        public AppletSettings () {
            Object (margin: 6,
                    row_spacing: 6,
                    column_spacing: 6);

            settings = new Settings ("org.gnome.desktop.interface");
            applet_settings = new Settings ("com.github.danielpinto8zz6.budgie-calendar-applet");

            var about = new Gtk.Button.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.MENU);
            about.clicked.connect (about_dialog);

            var label_date = new Gtk.Label (_ ("Show date"));
            label_date.set_halign (Gtk.Align.START);
            label_date.set_hexpand (true);
            switch_date = new Gtk.Switch ();
            switch_date.set_halign (Gtk.Align.END);
            switch_date.set_hexpand (true);

            var label_seconds = new Gtk.Label (_ ("Show seconds"));
            label_seconds.set_halign (Gtk.Align.START);
            label_seconds.set_hexpand (true);
            switch_seconds = new Gtk.Switch ();
            switch_seconds.set_halign (Gtk.Align.END);
            switch_seconds.set_hexpand (true);

            var label_format = new Gtk.Label (_ ("Use 24h time"));
            label_format.set_halign (Gtk.Align.START);
            label_format.set_hexpand (true);
            switch_format = new Gtk.Switch ();
            switch_format.set_halign (Gtk.Align.END);
            switch_format.set_hexpand (true);

            var label_week_numbers = new Gtk.Label (_ ("Show week numbers"));
            label_week_numbers.set_halign (Gtk.Align.START);
            label_week_numbers.set_hexpand (true);
            switch_week_numbers = new Gtk.Switch ();
            switch_week_numbers.set_halign (Gtk.Align.END);
            switch_week_numbers.set_hexpand (true);

            var label_switch_custom_format = new Gtk.Label (_ ("Custom date"));
            label_switch_custom_format.set_halign (Gtk.Align.START);
            label_switch_custom_format.set_hexpand (true);
            switch_custom_format = new Gtk.Switch ();
            switch_custom_format.set_halign (Gtk.Align.END);

            custom_format = new Gtk.Entry ();
            custom_format.set_halign (Gtk.Align.FILL);

            string label_link = (_ ("Date format syntax"));
            Gtk.LinkButton linkbutton = new Gtk.LinkButton.with_label ("http://www.foragoodstrftime.com", label_link);

            var time_and_date_settings = new Gtk.Button.with_label (_ ("Time and date settings"));
            time_and_date_settings.clicked.connect (open_datetime_settings);

            attach (about,                      0, 0, 2, 1);
            attach (label_date,                 0, 2, 1, 1);
            attach (switch_date,                1, 2, 1, 1);
            attach (label_seconds,              0, 3, 1, 1);
            attach (switch_seconds,             1, 3, 1, 1);
            attach (label_format,               0, 4, 1, 1);
            attach (switch_format,              1, 4, 1, 1);
            attach (label_week_numbers,         0, 5, 1, 1);
            attach (switch_week_numbers,        1, 5, 1, 1);
            attach (label_switch_custom_format, 0, 6, 1, 1);
            attach (switch_custom_format,       1, 6, 1, 1);
            attach (custom_format,              0, 7, 2, 1);
            attach (linkbutton,                 0, 8, 2, 1);
            attach (time_and_date_settings,     0, 9, 2, 1);

            settings.bind ("clock-show-date",    switch_date,    "active", SettingsBindFlags.DEFAULT);
            settings.bind ("clock-show-seconds", switch_seconds, "active", SettingsBindFlags.DEFAULT);
            applet_settings.bind ("show-custom-format",         switch_custom_format, "active", SettingsBindFlags.DEFAULT);
            applet_settings.bind ("custom-format",              custom_format,          "text", SettingsBindFlags.DEFAULT);
            applet_settings.bind ("calendar-show-week-numbers", switch_week_numbers,  "active", SettingsBindFlags.DEFAULT);

            apply_switch_custom_format();
            switch_custom_format.notify["active"].connect (apply_switch_custom_format);

            on_settings_changed ("clock-format");
            switch_format.notify["active"].connect (() => {
                ClockFormat f = (switch_format.active ? ClockFormat.TWENTYFOUR : ClockFormat.TWELVE);
                settings.set_enum ("clock-format", f);
            });

            settings.changed.connect (on_settings_changed);

            show_all ();
        }

        private void apply_switch_custom_format () {
            var active = switch_custom_format.active;
            custom_format.set_sensitive (active);
            switch_date.set_sensitive (!active);
            switch_seconds.set_sensitive (!active);
            switch_format.set_sensitive (!active);
        }

        private void on_settings_changed (string key) {
            switch (key) {
            case "clock-format" :
                ClockFormat f = (ClockFormat)settings.get_enum ("clock-format");
                switch_format.active = (f == ClockFormat.TWENTYFOUR);
                break;
            }
        }

        private void open_datetime_settings () {
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

        void about_dialog () {
            Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
            dialog.set_destroy_with_parent (true);
            dialog.set_modal (true);

            dialog.authors = { "Daniel Pinto <danielpinto8zz6@gmail.com>" };
            dialog.documenters = null; // Real inventors don't document.
            dialog.translator_credits = null; // We only need a scottish version.

            dialog.program_name = "Budgie Calendar Applet";
            dialog.comments = "A budgie-desktop applet to show hours, date, and Calendar";
            dialog.copyright = "Copyright © 2016-2018 danielpinto8zz6";
            dialog.version = Config.PACKAGE_VERSION;
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
}