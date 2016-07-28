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

public class CalendarPlugin : Budgie.Plugin, Peas.ExtensionBase
{
public Budgie.Applet get_panel_widget(string uuid)
{
        return new CalendarApplet();
}
}

enum ClockFormat {
        TWENTYFOUR = 0,
        TWELVE = 1;
}

public static const string CALENDAR_MIME = "text/calendar";

private static const string date_format = "%e %b %Y";

public class CalendarApplet : Budgie.Applet
{

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

public CalendarApplet()
{
        widget = new Gtk.EventBox();
        clock = new Gtk.Label("");
        time = new DateTime.now_local();
        widget.add(clock);

        widget.set_tooltip_text(time.format(date_format));

        popover = new Gtk.Popover(widget);
        calendar = new Gtk.Calendar();

        // check current month
        calendar.month_changed.connect(() => {
                        if(calendar.month+1 == time.get_month())
                                calendar.mark_day(time.get_day_of_month());
                        else
                                calendar.unmark_day(time.get_day_of_month());
                });

        widget.button_press_event.connect((e)=> {
                        if (e.button == 1) {
                                if (!popover.get_visible()) {
                                        popover.show_all();
                                } else {
                                        popover.hide();
                                }
                                return Gdk.EVENT_STOP;
                        }
                        return Gdk.EVENT_PROPAGATE;
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

/**
 * Let the panel manager know we support a settings UI
 */
public override bool supports_settings() {
        return true;
}

/**
 * Worth pointing out this is destroyed each time the user navigates
 * away from the view.
 */
public override Gtk.Widget ? get_settings_ui()
{
        return new CalendarAppletSettings();
}


public override void update_popovers(Budgie.PopoverManager ? manager)
{
        this.manager = manager;
        manager.register_popover(widget, popover);
}

protected void on_settings_change(string key)
{
        switch (key) {
        case "clock-format" :
                ClockFormat f = (ClockFormat)settings.get_enum(key);
                ampm = f == ClockFormat.TWELVE;
                break;
        case "clock-show-seconds" :
                show_seconds = settings.get_boolean(key);
                break;
        case "clock-show-date" :
                show_date = settings.get_boolean(key);
                break;
        }
        /* Lazy update on next clock sync */
}

/**
 * This is called once every second, updating the time
 */
protected bool update_clock()
{
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

/**
 * You can go further with this, but this is how we provide settings UIs for
 * the applet inside of Raven.
 */
public class CalendarAppletSettings : Gtk.Box
{
public CalendarAppletSettings()
{
        var datelabel = new Gtk.Label ("Show date");
        var secondslabel = new Gtk.Label ("Show seconds");
        var dateswitcher = new Gtk.Switch ();
        var secondsswitcher = new Gtk.Switch ();

        dateswitcher.notify["active"].connect (switcher_dat);
        secondsswitcher.notify["active"].connect (switcher_sec);

        var grid = new Gtk.Grid ();
        grid.set_column_spacing (10);
        grid.set_row_spacing (10);
        grid.set_column_homogeneous(true);
        grid.set_row_homogeneous(true);
        grid.attach (datelabel, 0,0,1,1);
        grid.attach (dateswitcher, 1,0,1,1);
        grid.attach (secondslabel, 0,1,1,1);
        grid.attach (secondsswitcher, 1,1,1,1);

        add(grid);

        show_all();
}

void switcher_dat (Object dateswitcher, ParamSpec pspec) {
        if ((dateswitcher as Gtk.Switch).get_active()) {
                GLib.Process.spawn_command_line_async ("/bin/gsettings set org.gnome.desktop.interface clock-show-date true");
        }
        else
        {
                GLib.Process.spawn_command_line_async ("/bin/gsettings set org.gnome.desktop.interface clock-show-date false");
        }
}
void switcher_sec (Object secondsswitcher, ParamSpec pspec) {
        if ((secondsswitcher as Gtk.Switch).get_active()) {
                GLib.Process.spawn_command_line_async ("/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true");
        }
        else
        {
                GLib.Process.spawn_command_line_async ("/bin/gsettings set org.gnome.desktop.interface clock-show-seconds false");
        }
}
}

[ModuleInit]
public void peas_register_types(TypeModule module)
{
        var objmodule = module as Peas.ObjectModule;
        objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(CalendarPlugin));
}
