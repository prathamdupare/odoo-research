## Odoo Developer Mode

[link](https://www.odoo.com/documentation/18.0/applications/general/developer_mode.html)

### What Is It?

- A special mode that unlocks powerful tools and settings in Odoo.
- Use with caution! Some things are advanced and can break stuff.

### How to Turn It On:

1.  **In the Settings App:**
    - Go to the Settings app.
    - Find the "Developer Tools" section.
    - Click "Activate the developer mode".
2.  **Using the URL:**
    - Add `?debug=1` to the end of your Odoo URL (e.g., `https://your-odoo.com/?debug=1`).
    - To turn it off, use `?debug=0`.
3.  **With Assets (for JS debugging):**
    - Use `?debug=assets`
4.  **With Tests Assets (for running tests):**
    - Use `?debug=tests`
5.  **Command Palette (Ctrl+K or Cmd+K):**
    - Type "debug" to activate or deactivate.
6.  **Browser Extension:**
    - Install the "Odoo Debug" extension for Chrome or Firefox.

### What You Get:

- **Developer Tools (Bug Icon):** Access to tools to see technical details, edit views, etc.
- **Technical Menu (Settings App):** Database admins get advanced database settings.

### Things to Remember:

- Only use if you know what you're doing.
- Don't leave it on in production!

---



