/* wttr.in fetching and json rendering */

#include <string.h>

#include "weather.h"

/* wttr.in WWO weather codes -> glyph */
static const char *glyph_for(int code, gboolean night)
{
    switch (code) {
    case 113:
        return night ? GLYPH_NIGHT : GLYPH_SUNNY;
    case 116:
        return GLYPH_PARTLY;
    case 119: case 122:
        return GLYPH_CLOUDY;
    case 143: case 248: case 260:
        return GLYPH_FOG;
    case 176: case 263: case 266: case 281: case 284: case 293:
    case 296: case 353:
        return GLYPH_RAIN;
    case 299: case 302: case 305: case 308: case 311: case 314:
    case 356: case 359:
        return GLYPH_POURING;
    case 179: case 182: case 185: case 227: case 230: case 317:
    case 320: case 323: case 326: case 329: case 332: case 335:
    case 338: case 350: case 362: case 365: case 368: case 371:
    case 374: case 377:
        return GLYPH_SNOW;
    case 200: case 386: case 389: case 392: case 395:
        return GLYPH_LIGHTNING;
    default:
        return GLYPH_CLOUDY;
    }
}

static char *member_str(JsonReader *r, const char *name)
{
    json_reader_read_member(r, name);
    char *s = g_strdup(json_reader_get_string_value(r));
    json_reader_end_member(r);
    return s ? s : g_strdup("?");
}

static int member_int(JsonReader *r, const char *name)
{
    char *s = member_str(r, name);
    int v = atoi(s);
    g_free(s);
    return v;
}

/* wttr wraps strings as [{"value": "..."}] */
static char *member_value(JsonReader *r, const char *name)
{
    json_reader_read_member(r, name);
    json_reader_read_element(r, 0);
    char *s = member_str(r, "value");
    json_reader_end_element(r);
    json_reader_end_member(r);
    return s;
}

void show_error(const char *message)
{
    set_labelf(app.error, "couldn't reach wttr.in: %s", message);
    gtk_widget_set_visible(app.error, TRUE);
}

void show_data(JsonParser *parser)
{
    JsonReader *r = json_reader_new(json_parser_get_root(parser));
    GDateTime *now = g_date_time_new_now_local();
    gboolean night = g_date_time_get_hour(now) < 6 ||
                     g_date_time_get_hour(now) >= 20;
    gboolean f = app.fahrenheit;

    gtk_widget_set_visible(app.error, FALSE);

    json_reader_read_member(r, "current_condition");
    json_reader_read_element(r, 0);
    char *desc = member_value(r, "weatherDesc");
    char *wind_speed = member_str(r, f ? "windspeedMiles" : "windspeedKmph");
    char *wind_dir = member_str(r, "winddir16Point");
    set_labelf(app.temp, "%d°", member_int(r, f ? "temp_F" : "temp_C"));
    set_labelf(app.feels, "%d°",
               member_int(r, f ? "FeelsLikeF" : "FeelsLikeC"));
    set_labelf(app.humidity, "%d%%", member_int(r, "humidity"));
    set_labelf(app.wind, "%s%s %s", wind_speed, f ? "mph" : "km/h",
               wind_dir);
    gtk_label_set_label(GTK_LABEL(app.glyph),
                        glyph_for(member_int(r, "weatherCode"), night));
    char *lower = g_utf8_strdown(desc, -1);
    gtk_label_set_label(GTK_LABEL(app.condition), lower);
    g_free(lower);
    g_free(desc);
    g_free(wind_speed);
    g_free(wind_dir);
    json_reader_end_element(r);
    json_reader_end_member(r);

    json_reader_read_member(r, "nearest_area");
    json_reader_read_element(r, 0);
    char *area = member_value(r, "areaName");
    char *region = member_value(r, "region");
    char *country = member_value(r, "country");
    if (strcmp(country, "United States of America") == 0) {
        g_free(country);
        country = g_strdup("US");
    } else if (strcmp(country, "United Kingdom") == 0) {
        g_free(country);
        country = g_strdup("UK");
    }
    if (*region && strcmp(region, area) != 0)
        set_labelf(app.location, "%s, %s, %s", area, region, country);
    else
        set_labelf(app.location, "%s, %s", area, country);
    g_free(area);
    g_free(region);
    g_free(country);
    json_reader_end_element(r);
    json_reader_end_member(r);

    json_reader_read_member(r, "weather");
    for (int i = 0; i < 3; i++) {
        json_reader_read_element(r, i);

        if (i < 2) {
            gtk_label_set_label(GTK_LABEL(app.days[i].name),
                                i == 0 ? "today" : "tomorrow");
        } else {
            GDateTime *day = g_date_time_add_days(now, i);
            char *name = g_date_time_format(day, "%a");
            char *lname = g_utf8_strdown(name, -1);
            gtk_label_set_label(GTK_LABEL(app.days[i].name), lname);
            g_free(lname);
            g_free(name);
            g_date_time_unref(day);
        }

        set_labelf(app.days[i].hi, "%d°",
                   member_int(r, f ? "maxtempF" : "maxtempC"));
        set_labelf(app.days[i].lo, "%d°",
                   member_int(r, f ? "mintempF" : "mintempC"));

        json_reader_read_member(r, "hourly");
        json_reader_read_element(r, 4); /* midday */
        gtk_label_set_label(GTK_LABEL(app.days[i].icon),
                            glyph_for(member_int(r, "weatherCode"), FALSE));
        json_reader_end_element(r);
        json_reader_end_member(r);

        json_reader_end_element(r);
    }
    json_reader_end_member(r);

    g_date_time_unref(now);
    g_object_unref(r);
}

static void on_response(GObject *source, GAsyncResult *result, gpointer data)
{
    GError *err = NULL;
    GBytes *bytes = soup_session_send_and_read_finish(SOUP_SESSION(source),
                                                      result, &err);
    if (!bytes) {
        show_error(err->message);
        g_error_free(err);
        return;
    }

    JsonParser *parser = json_parser_new();
    gsize size;
    const char *body = g_bytes_get_data(bytes, &size);
    if (json_parser_load_from_data(parser, body, size, &err)) {
        g_clear_object(&app.last);
        app.last = parser;
        show_data(parser);
    } else {
        show_error(err->message);
        g_error_free(err);
        g_object_unref(parser);
    }
    g_bytes_unref(bytes);
}

void refresh(void)
{
    char *escaped = g_uri_escape_string(app.query, NULL, FALSE);
    char *url = g_strdup_printf("https://wttr.in/%s?format=j1", escaped);
    SoupMessage *msg = soup_message_new("GET", url);
    soup_message_headers_replace(soup_message_get_request_headers(msg),
                                 "User-Agent", "curl/8");
    soup_session_send_and_read_async(app.session, msg, G_PRIORITY_DEFAULT,
                                     NULL, on_response, NULL);
    g_object_unref(msg);
    g_free(url);
    g_free(escaped);
}
