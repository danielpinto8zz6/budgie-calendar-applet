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
public Budgie.Applet get_panel_widget(string uuid) {
        return new CalendarApplet();
}
}

enum ClockFormat {
        TWENTYFOUR = 0,
        TWELVE = 1;
}

public const string CALENDAR_MIME = "text/calendar";

public const string date_format = "%e %b %Y";

public class CalendarApplet : Budgie.Applet {

protected Gtk.EventBox widget;
protected Gtk.Label clock;
protected Gtk.Calendar calendar;
protected Gtk.Popover popover;
protected Gtk.Grid main_grid;
protected Gtk.Button datetime_settings;

protected bool ampm = false;
protected bool show_seconds = false;
protected bool show_date = false;

private DateTime time;

protected Settings settings;

private unowned Budgie.PopoverManager ? manager = null;

AppInfo ? calprov = null;

public CalendarApplet() {


// Setup the clock and popover
        int position = 0;

        widget = new Gtk.EventBox();
        clock = new Gtk.Label("");
        clock.valign = Gtk.Align.CENTER;
        time = new DateTime.now_local();
        widget.add(clock);
        margin_bottom = 2;

        popover = new Gtk.Popover(widget);

        // Grid inside popover to put widgets
        main_grid = new Gtk.Grid ();
        main_grid.can_focus = false;

        // Show Week day
        var weekday_label = new Gtk.Label ("");
        weekday_label.get_style_context ().add_class ("h1");
        weekday_label.halign = Gtk.Align.START;
        weekday_label.margin_top = 10;
        weekday_label.margin_start = 20;
        weekday_label.set_label (time.format("%A"));
        main_grid.attach (weekday_label, 0, position++, 7, 1);

        // Show date
        var date_label = new Gtk.Label ("");
        date_label.get_style_context ().add_class ("h2");
        date_label.halign = Gtk.Align.START;
        date_label.margin_start = 20;
        date_label.margin_top = 10;
        date_label.margin_bottom = 15;
        date_label.set_label (time.format("%e %B %Y"));
        main_grid.attach (date_label, 0, position++, 8, 1);

        // Time and Date settings Button
        datetime_settings = new Gtk.Button.from_icon_name("emblem-system-symbolic", Gtk.IconSize.MENU);
        datetime_settings.can_focus = false;
        datetime_settings.margin_top = 10;
        datetime_settings.margin_end = 6;
        datetime_settings.clicked.connect(on_date_activate);
        main_grid.attach_next_to (datetime_settings, weekday_label, Gtk.PositionType.RIGHT, 1, 1);

        // Calendar
        calendar = new Gtk.Calendar();
        calendar.can_focus = false;
        calendar.margin_bottom = 6;
        calendar.margin_start = 6;
        calendar.margin_end = 6;
        main_grid.attach (calendar, 0, position++, 8, 1);

        // Show date when over mouse
        widget.set_tooltip_text(time.format(date_format));

        // Create the popover container
        popover.add(main_grid);

        // Click on clock show popover
        widget.button_press_event.connect((e)=> {
                        if (e.button != 1) {
                                return Gdk.EVENT_PROPAGATE;
                        }
                        Toggle();
                        return Gdk.EVENT_STOP;
                });

        // Setup calprov
        calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
        var monitor = AppInfoMonitor.get();
        monitor.changed.connect(update_cal);

        // Cal clicked handler
        calendar.day_selected_double_click.connect(on_cal_activate);

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
		update_date();
                popover.get_child().show_all();
                this.manager.show_popover(widget);
        }
}

private bool update_date()
{
    var time = new DateTime.now_local();
    calendar.day = time.get_day_of_month();
    return true;
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
        if (get_toplevel() != null) {
                get_toplevel().queue_draw();
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
void update_cal()
{
        calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
}

void on_date_activate()
{
        var app_info = new DesktopAppInfo("gnome-datetime-panel.desktop");

        if (app_info == null) {
                return;
        }
        try {
                app_info.launch(null, null);
        } catch (Error e) {
                message("Unable to launch gnome-datetime-panel.desktop: %s", e.message);
        }
}

void on_cal_activate()
{
        if (calprov == null) {
                return;
        }
        try {
                calprov.launch(null, null);
        } catch (Error e) {
                message("Unable to launch %s: %s", calprov.get_name(), e.message);
        }
}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
        var objmodule = module as Peas.ObjectModule;
        objmodule.register_extension_type(typeof (Budgie.Plugin), typeof (CalendarPlugin));
}
