#ifndef WEATHER_H
#define WEATHER_H

#include <gtk/gtk.h>
#include <json-glib/json-glib.h>
#include <libsoup/soup.h>

#define REFRESH_SECONDS 1800

#define GLYPH_SUNNY     "\U000f0599"
#define GLYPH_NIGHT     "\U000f0594"
#define GLYPH_PARTLY    "\U000f0595"
#define GLYPH_CLOUDY    "\U000f0590"
#define GLYPH_FOG       "\U000f0591"
#define GLYPH_RAIN      "\U000f0597"
#define GLYPH_POURING   "\U000f0596"
#define GLYPH_SNOW      "\U000f0598"
#define GLYPH_LIGHTNING "\U000f0593"
#define GLYPH_REFRESH   "\U000f0450"

typedef struct {
    GtkWidget *location, *glyph, *temp, *condition, *error;
    GtkWidget *feels, *humidity, *wind, *unit_btn;
    struct { GtkWidget *name, *icon, *hi, *lo; } days[3];
    SoupSession *session;
    JsonParser *last;
    gboolean fahrenheit;
    const char *query;
} App;

extern App app;

// ui.c
void ui_build(GtkApplication *gtk_app);
void set_labelf(GtkWidget *label, const char *fmt, ...) G_GNUC_PRINTF(2, 3);

// wttr.c
void refresh(void);
void show_data(JsonParser *parser);
void show_error(const char *message);

#endif
