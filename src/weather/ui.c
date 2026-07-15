#include "weather.h"

static const char *CSS =
    "window {"
    "    background-color: rgba(30, 30, 46, 0.88);"
    "}"
    "* {"
    "    font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace;"
    "    color: #cdd6f4;"
    "}"
    ".location   { font-size: 15px; font-weight: 700; color: #b4befe; }"
    ".glyph      { font-size: 72px; color: #f9e2af; }"
    ".temp       { font-size: 48px; font-weight: 800; }"
    ".condition  { font-size: 15px; color: #a5adc8; }"
    ".detail     { font-size: 12px; color: #a5adc8; }"
    ".detail-val { font-size: 12px; color: #cdd6f4; font-weight: 700; }"
    ".day        { font-size: 12px; font-weight: 700; color: #b4befe; }"
    ".day-glyph  { font-size: 28px; color: #f9e2af; }"
    ".day-max    { font-size: 13px; font-weight: 700; }"
    ".day-min    { font-size: 13px; color: #6c7086; }"
    ".error      { font-size: 13px; color: #f38ba8; }"
    ".card {"
    "    background-color: rgba(49, 50, 68, 0.5);"
    "    border-radius: 12px;"
    "    padding: 12px;"
    "}"
    "button.refresh, button.unit {"
    "    background: none;"
    "    border: none;"
    "    box-shadow: none;"
    "    font-size: 16px;"
    "    color: #6c7086;"
    "    min-height: 0;"
    "    min-width: 0;"
    "    padding: 2px 6px;"
    "}"
    "button.unit { font-size: 13px; font-weight: 700; }"
    "button.refresh:hover, button.unit:hover { color: #cba6f7; }";

void set_labelf(GtkWidget *label, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    char *s = g_strdup_vprintf(fmt, ap);
    va_end(ap);
    gtk_label_set_label(GTK_LABEL(label), s);
    g_free(s);
}

static void on_refresh_clicked(GtkButton *button, gpointer data)
{
    refresh();
}

static void on_unit_clicked(GtkButton *button, gpointer data)
{
    app.fahrenheit = !app.fahrenheit;
    gtk_button_set_label(button, app.fahrenheit ? "°F" : "°C");
    if (app.last)
        show_data(app.last);
}

static GtkWidget *label_with_class(const char *text, const char *class)
{
    GtkWidget *label = gtk_label_new(text);
    gtk_widget_add_css_class(label, class);
    return label;
}

void ui_build(GtkApplication *gtk_app)
{
    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_string(provider, CSS);
    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(), GTK_STYLE_PROVIDER(provider),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);

    GtkWidget *window = gtk_application_window_new(gtk_app);
    gtk_window_set_title(GTK_WINDOW(window), "weather");
    gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
    gtk_window_set_default_size(GTK_WINDOW(window), 340, -1);

    GtkWidget *root = gtk_box_new(GTK_ORIENTATION_VERTICAL, 12);
    gtk_widget_set_margin_top(root, 16);
    gtk_widget_set_margin_bottom(root, 16);
    gtk_widget_set_margin_start(root, 16);
    gtk_widget_set_margin_end(root, 16);
    gtk_window_set_child(GTK_WINDOW(window), root);

    GtkWidget *header = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    app.location = label_with_class("...", "location");
    gtk_label_set_xalign(GTK_LABEL(app.location), 0);
    gtk_label_set_ellipsize(GTK_LABEL(app.location), PANGO_ELLIPSIZE_END);
    gtk_widget_set_hexpand(app.location, TRUE);
    GtkWidget *refresh_btn = gtk_button_new_with_label(GLYPH_REFRESH);
    gtk_widget_add_css_class(refresh_btn, "refresh");
    g_signal_connect(refresh_btn, "clicked",
                     G_CALLBACK(on_refresh_clicked), NULL);
    app.unit_btn = gtk_button_new_with_label("°C");
    gtk_widget_add_css_class(app.unit_btn, "unit");
    g_signal_connect(app.unit_btn, "clicked",
                     G_CALLBACK(on_unit_clicked), NULL);
    gtk_box_append(GTK_BOX(header), app.location);
    gtk_box_append(GTK_BOX(header), app.unit_btn);
    gtk_box_append(GTK_BOX(header), refresh_btn);
    gtk_box_append(GTK_BOX(root), header);

    GtkWidget *current = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 16);
    gtk_widget_add_css_class(current, "card");
    app.glyph = label_with_class(GLYPH_CLOUDY, "glyph");
    gtk_widget_set_size_request(app.glyph, 84, -1);
    GtkWidget *cur_text = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_valign(cur_text, GTK_ALIGN_CENTER);
    app.temp = label_with_class("--°", "temp");
    gtk_label_set_xalign(GTK_LABEL(app.temp), 0);
    app.condition = label_with_class("loading", "condition");
    gtk_label_set_xalign(GTK_LABEL(app.condition), 0);
    gtk_label_set_wrap(GTK_LABEL(app.condition), TRUE);
    gtk_label_set_max_width_chars(GTK_LABEL(app.condition), 18);
    gtk_box_append(GTK_BOX(cur_text), app.temp);
    gtk_box_append(GTK_BOX(cur_text), app.condition);
    gtk_box_append(GTK_BOX(current), app.glyph);
    gtk_box_append(GTK_BOX(current), cur_text);
    gtk_box_append(GTK_BOX(root), current);

    GtkWidget *details = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_widget_add_css_class(details, "card");
    gtk_box_set_homogeneous(GTK_BOX(details), TRUE);
    GtkWidget **vals[] = { &app.feels, &app.humidity, &app.wind };
    const char *caps[] = { "feels", "humid", "wind" };
    for (int i = 0; i < 3; i++) {
        GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
        *vals[i] = label_with_class("--", "detail-val");
        gtk_box_append(GTK_BOX(box), *vals[i]);
        gtk_box_append(GTK_BOX(box), label_with_class(caps[i], "detail"));
        gtk_box_append(GTK_BOX(details), box);
    }
    gtk_box_append(GTK_BOX(root), details);

    GtkWidget *forecast = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_widget_add_css_class(forecast, "card");
    gtk_box_set_homogeneous(GTK_BOX(forecast), TRUE);
    for (int i = 0; i < 3; i++) {
        GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 4);
        app.days[i].name = label_with_class("--", "day");
        app.days[i].icon = label_with_class(GLYPH_CLOUDY, "day-glyph");
        app.days[i].hi = label_with_class("--°", "day-max");
        app.days[i].lo = label_with_class("--°", "day-min");
        gtk_box_append(GTK_BOX(box), app.days[i].name);
        gtk_box_append(GTK_BOX(box), app.days[i].icon);
        gtk_box_append(GTK_BOX(box), app.days[i].hi);
        gtk_box_append(GTK_BOX(box), app.days[i].lo);
        gtk_box_append(GTK_BOX(forecast), box);
    }
    gtk_box_append(GTK_BOX(root), forecast);

    app.error = label_with_class("", "error");
    gtk_label_set_wrap(GTK_LABEL(app.error), TRUE);
    gtk_widget_set_visible(app.error, FALSE);
    gtk_box_append(GTK_BOX(root), app.error);

    gtk_window_present(GTK_WINDOW(window));
}
