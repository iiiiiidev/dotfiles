#include "weather.h"
App app;

static gboolean on_timer(gpointer data)
{
    refresh();
    return G_SOURCE_CONTINUE;
}

static void activate(GtkApplication *gtk_app, gpointer data)
{
    ui_build(gtk_app);
    app.session = soup_session_new();
    refresh();
    g_timeout_add_seconds(REFRESH_SECONDS, on_timer, NULL);
}

int main(int argc, char **argv)
{
    app.query = argc > 1 ? argv[1] : "";

    GtkApplication *gtk_app = gtk_application_new(
        "wttr.in", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(gtk_app, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(gtk_app), 1, argv);
    g_object_unref(gtk_app);
    return status;
}
