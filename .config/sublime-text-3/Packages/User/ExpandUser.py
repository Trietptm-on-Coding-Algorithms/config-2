import os
import sublime

def fix_settings():
    settings = sublime.load_settings("Package Syncing.sublime-settings")
    value = settings.get("sync_folder")
    path = os.path.expanduser(value)
    settings.set("sync_folder", path)
    settings.set("sync", "true")

def plugin_loaded():
    expand_settings()

if int(sublime.version()) < 3006:
    expand_settings()

