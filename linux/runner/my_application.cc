#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <glib.h>
#include <signal.h>
#include <unistd.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <cmath>
#include <cstdlib>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

extern "C" void child_setup_new_process_group(gpointer user_data) {
  (void)user_data;
  // Make the spawned command leader of a new process group so stop() can
  // terminate the full pipeline (shell + piper + paplay) with one signal.
  setpgid(0, 0);
}

namespace {

constexpr char kNativeTtsChannelName[] = "crop_monitor/native_tts";

// Piper TTS paths (installed per-user)
static std::string g_piper_binary;
static std::string g_piper_voices_dir;

int clamp_int(int value, int minimum, int maximum) {
  return std::max(minimum, std::min(maximum, value));
}

bool command_exists(const gchar* command) {
  g_autofree gchar* path = g_find_program_in_path(command);
  return path != nullptr;
}

static bool file_exists(const std::string& path) {
  return g_file_test(path.c_str(), G_FILE_TEST_IS_REGULAR);
}

// Initialize piper paths by looking for the binary in common locations
static void init_piper_paths() {
  const gchar* home = g_get_home_dir();
  if (home == nullptr) return;

  // Try ~/.local/share/piper/piper/piper
  std::string local_bin = std::string(home) + "/.local/share/piper/piper/piper";
  if (file_exists(local_bin)) {
    g_piper_binary = local_bin;
    g_piper_voices_dir = std::string(home) + "/.local/share/piper/voices";
  }
}

static bool piper_available() {
  if (g_piper_binary.empty()) init_piper_paths();
  return !g_piper_binary.empty() && file_exists(g_piper_binary);
}

// Returns piper model path for locale, or "" if no piper model for this locale
static std::string piper_model_for_locale(const gchar* locale) {
  if (g_piper_voices_dir.empty()) return "";

  std::string model;
  if (g_str_has_prefix(locale, "hi")) {
    model = g_piper_voices_dir + "/hi_IN-pratham-medium.onnx";
  } else {
    // Default English for en-US and unknown
    model = g_piper_voices_dir + "/en_US-lessac-medium.onnx";
  }

  return file_exists(model) ? model : "";
}

// LD_LIBRARY_PATH for piper's bundled libs
static std::string piper_lib_dir() {
  if (g_piper_binary.empty()) return "";
  // binary is at .../piper/piper/piper, libs are in .../piper/piper/
  return g_piper_binary.substr(0, g_piper_binary.rfind('/'));
}

const gchar* resolve_espeak_voice(const gchar* locale) {
  if (locale == nullptr || *locale == '\0') {
    return "en-us";
  }

  if (g_str_has_prefix(locale, "ta")) {
    return "ta";
  }
  if (g_str_has_prefix(locale, "hi")) {
    return "hi";
  }
  return "en-us";
}

int extract_int_arg(FlValue* args, const gchar* key, int fallback) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return fallback;
  }

  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr) {
    return fallback;
  }

  const FlValueType value_type = fl_value_get_type(value);
  if (value_type == FL_VALUE_TYPE_INT) {
    return static_cast<int>(fl_value_get_int(value));
  }
  if (value_type == FL_VALUE_TYPE_FLOAT) {
    return static_cast<int>(std::round(fl_value_get_float(value)));
  }
  return fallback;
}

const gchar* extract_string_arg(FlValue* args,
                                const gchar* key,
                                const gchar* fallback) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return fallback;
  }

  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return fallback;
  }

  return fl_value_get_string(value);
}

gboolean run_async_command(const std::vector<std::string>& command,
                           GPid* child_pid,
                           GError** error) {
  g_auto(GStrv) argv = g_new0(gchar*, command.size() + 1);
  for (size_t index = 0; index < command.size(); ++index) {
    argv[index] = g_strdup(command[index].c_str());
  }

  return g_spawn_async(nullptr, argv, nullptr,
                       static_cast<GSpawnFlags>(G_SPAWN_SEARCH_PATH |
                                                G_SPAWN_DO_NOT_REAP_CHILD),
                       child_setup_new_process_group, nullptr, child_pid,
                       error);
}

}  // namespace

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* native_tts_channel;
  GPid native_tts_pid;
  guint native_tts_watch_id;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void native_tts_child_watch_cb(GPid pid,
                                      gint status,
                                      gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);

  self->native_tts_watch_id = 0;

  if (self->native_tts_pid == pid) {
    self->native_tts_pid = 0;
  }

  g_spawn_close_pid(pid);
}

static void stop_current_tts_process(MyApplication* self) {
  if (self->native_tts_pid == 0) {
    return;
  }

  const pid_t process_group_id = self->native_tts_pid;
  kill(-process_group_id, SIGTERM);
}

static void stop_native_tts(MyApplication* self) {
  stop_current_tts_process(self);
}

// Speak using Piper neural TTS piped to paplay
// Runs: echo TEXT | piper --model MODEL --output_raw | paplay --raw ...
static gboolean speak_with_piper(MyApplication* self,
                                 const gchar* text,
                                 const gchar* locale,
                                 GError** error) {
  stop_current_tts_process(self);

  std::string model = piper_model_for_locale(locale);
  if (model.empty()) return FALSE;

  std::string lib_dir = piper_lib_dir();
  // Build shell command: echo TEXT | piper --model MODEL --output_raw | paplay --raw ...
  // We use shell via /bin/sh -c to enable piping
  // Escape single quotes in text: replace ' with '\''
  std::string escaped_text = std::string(text ? text : "");
  {
    std::string result;
    result.reserve(escaped_text.size() + 16);
    for (char c : escaped_text) {
      if (c == '\'') {
        result += "'\\''";
      } else {
        result += c;
      }
    }
    escaped_text = std::move(result);
  }

  std::string cmd =
      "LD_LIBRARY_PATH='" + lib_dir + "' "
      "printf '%s' '" + escaped_text + "' | "
      "'" + g_piper_binary + "' "
      "--model '" + model + "' "
      "--output_raw 2>/dev/null | "
      "paplay --raw --rate=22050 --format=s16le --channels=1";

  g_auto(GStrv) argv = g_new0(gchar*, 4);
  argv[0] = g_strdup("/bin/sh");
  argv[1] = g_strdup("-c");
  argv[2] = g_strdup(cmd.c_str());
  if (!g_spawn_async(nullptr,
                     argv,
                     nullptr,
                     static_cast<GSpawnFlags>(G_SPAWN_DO_NOT_REAP_CHILD),
                     child_setup_new_process_group, nullptr,
                     &self->native_tts_pid, error)) {
    return FALSE;
  }

  self->native_tts_watch_id = g_child_watch_add(
      self->native_tts_pid, native_tts_child_watch_cb, self);
  return TRUE;
}

static gboolean speak_with_espeak(MyApplication* self,
                                  const gchar* text,
                                  const gchar* locale,
                                  int rate,
                                  int pitch,
                                  GError** error) {
  stop_current_tts_process(self);

  const int speech_rate = clamp_int(160 + rate, 110, 190);
  const int speech_pitch = clamp_int(50 + (pitch / 2), 20, 80);

  if (!run_async_command({"espeak-ng",
                          "-v",
                          resolve_espeak_voice(locale),
                          "-s",
                          std::to_string(speech_rate),
                          "-p",
                          std::to_string(speech_pitch),
                          text},
                         &self->native_tts_pid, error)) {
    return FALSE;
  }

  self->native_tts_watch_id = g_child_watch_add(
      self->native_tts_pid, native_tts_child_watch_cb, self);
  return TRUE;
}

static void native_tts_method_call_cb(FlMethodChannel* channel,
                                      FlMethodCall* method_call,
                                      gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "isAvailable") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_bool(piper_available() ||
                          command_exists("espeak-ng"))));
  } else if (strcmp(method, "stop") == 0) {
    stop_native_tts(self);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));
  } else if (strcmp(method, "speak") == 0) {
    const gchar* text = extract_string_arg(args, "text", nullptr);
    const gchar* locale = extract_string_arg(args, "locale", "en-US");
    const int rate = clamp_int(extract_int_arg(args, "rate", -10), -80, 40);
    const int pitch = clamp_int(extract_int_arg(args, "pitch", 0), -40, 30);

    if (text == nullptr || *text == '\0') {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "invalid_args", "TTS text must not be empty", nullptr));
    } else {
      stop_native_tts(self);

      g_autoptr(GError) speak_error = nullptr;
      gboolean success = FALSE;

      // Try piper first (neural, high quality) for en/hi
      // For ta (Tamil), piper has no model — fall through to espeak-ng
      if (piper_available() && !piper_model_for_locale(locale).empty()) {
        success = speak_with_piper(self, text, locale, &speak_error);
        if (!success) {
          g_message("[TTS] Piper failed (%s), falling back to espeak-ng",
                    speak_error ? speak_error->message : "unknown");
          g_clear_error(&speak_error);
        }
      }

      if (!success && command_exists("espeak-ng")) {
        success = speak_with_espeak(self, text, locale, rate, pitch,
                                    &speak_error);
      }

      if (success) {
        response = FL_METHOD_RESPONSE(
            fl_method_success_response_new(fl_value_new_bool(TRUE)));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "tts_error",
            speak_error != nullptr ? speak_error->message
                                   : "No Linux speech backend available",
            nullptr));
      }
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) response_error = nullptr;
  if (!fl_method_call_respond(method_call, response, &response_error)) {
    g_warning("Failed to send TTS response: %s", response_error->message);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "crop_monitor");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "crop_monitor");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->native_tts_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      kNativeTtsChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->native_tts_channel,
                                            native_tts_method_call_cb,
                                            g_object_ref(self),
                                            g_object_unref);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  // Perform any actions required at application shutdown.
  stop_native_tts(self);

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  stop_native_tts(self);
  if (self->native_tts_watch_id != 0) {
    g_source_remove(self->native_tts_watch_id);
    self->native_tts_watch_id = 0;
  }
  g_clear_object(&self->native_tts_channel);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->native_tts_channel = nullptr;
  self->native_tts_pid = 0;
  self->native_tts_watch_id = 0;
}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
