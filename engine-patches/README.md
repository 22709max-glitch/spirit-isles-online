# Mobile export v0.9.4

Source files used with the existing Spirit Isles Godot 4.6.3 game project to build `web/game-mobile-v2.pck`. These are export source snapshots, not a standalone game project.

- Mobile bridge renders directly to the root viewport (avoids WebKit self-framebuffer blits), forwards real native controls, serializes circuit tiles, and uses precomputed UI texture URLs.
- Main routes mobile notices and location announcements to the DOM instead of desktop-positioned overlays.
- Asset export script writes original UI texture regions as PNGs; `web/ui-assets.js` maps texture keys to these files.
- Save version, application name, guest storage scope and import/backup behavior are preserved.

Export the original project with the `Mobile-Web` preset, copy the PCK under the versioned filename, then update its byte count in `web/index.html`.
