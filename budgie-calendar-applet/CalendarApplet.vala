/*
 * This file is part of calendar-applet
 *
 * Copyright (C) 2016 Daniel Pinto <danielpinto8zz6@gmail.com>
 * Copyright (C) 2014-2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class CalendarPlugin : Budgie.Plugin, Peas.ExtensionBase {
public Budgie.Applet get_panel_widget(string uuid) {
        return new CalendarApplet();
}
}

enum ClockFormat {
        TWENTYFOUR = 0,
        TWELVE = 1;
}

public const string CALENDAR_MIME = "text/calendar";

public class CalendarApplet : Budgie.Applet {

protected Gtk.EventBox widget;
protected Gtk.Label clock;
protected Gtk.Calendar calendar;
protected Gtk.Popover popover;

protected bool ampm = false;
protected bool show_seconds = false;
protected bool show_date = false;

private DateTime time;

protected Settings settings;

private unowned Budgie.PopoverManager ? manager = null;

public CalendarApplet() {
        widget = new Gtk.EventBox();
        clock = new Gtk.Label("");
        time = new DateTime.now_local();
        widget.add(clock);

        popover = new Gtk.Popover(widget);
        calendar = new Gtk.Calendar();

        // check current month
        calendar.month_changed.connect(() => {
                        if (calendar.month + 1 == time.get_month())
                                calendar.mark_day(time.get_day_of_month());
                        else
                                calendar.unmark_day(time.get_day_of_month());
                });

        widget.button_press_event.connect((e)=> {
                        if (e.button != 1) {
                                return Gdk.EVENT_PROPAGATE;
                        }
                        Toggle();
                        return Gdk.EVENT_STOP;
                });

        popover.add(calendar);
        Timeout.add_seconds_full(GLib.Priority.LOW, 1, update_clock);

        settings = new Settings("org.gnome.desktop.interface");
        settings.changed.connect(on_settings_change);
        on_settings_change("clock-format");
        on_settings_change("clock-show-seconds");
        on_settings_change("clock-show-date");
        update_clock();
        add(widget);
        show_all();
}

public void Toggle(){
        if (popover.get_visible()) {
                popover.hide();
        } else {
                popover.get_child().show_all();
                this.manager.show_popover(widget);
        }
}

public override void invoke_action(Budgie.PanelAction action) {
        Toggle();
}

public override void update_popovers(Budgie.PopoverManager ? manager) {
        this.manager = manager;
        manager.register_popover(widget, popover);
}

protected void on_settings_change(string key) {
        switch (key) {
        case "clock-format":
                ClockFormat f = (ClockFormat) settings.get_enum(key);
                ampm = f == ClockFormat.TWELVE;
                break;
        case "clock-show-seconds":
                show_seconds = settings.get_boolean(key);
                break;
        case "clock-show-date":
                show_date = settings.get_boolean(key);
                break;
        }
        /* Lazy update on next clock sync */
}

/**
 * This is called once every second, updating the time
 */
protected bool update_clock() {
        time = new DateTime.now_local();
        string format;

        if (ampm) {
                format = "%l:%M";
        } else {
                format = "%H:%M";
        }
        if (show_seconds) {
                format += ":%S";
        }
        if (ampm) {
                format += " %p";
        }
        string ftime = " <big>%s</big> ".printf(format);
        if (show_date) {
                ftime += " <big>%x</big>";
        }

        var ctime = time.format(ftime);
        clock.set_markup(ctime);

        return true;
}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
        var objmodule = module as Peas.ObjectModule;
        objmodule.register_extension_type(typeof (Budgie.Plugin), typeof (CalendarPlugin));
}
