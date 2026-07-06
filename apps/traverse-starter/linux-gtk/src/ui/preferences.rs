use gtk4::prelude::*;
use gtk4::{Box as GtkBox, Button, Entry, Label, Orientation};
use libadwaita as adw;
use std::cell::Cell;
use std::rc::Rc;

use crate::settings::AppSettings;

pub struct PreferencesDialog;

impl PreferencesDialog {
    pub fn run(parent: &adw::ApplicationWindow, current: &AppSettings) -> Option<AppSettings> {
        let dialog = adw::Window::builder()
            .transient_for(parent)
            .modal(true)
            .title("Preferences")
            .default_width(420)
            .default_height(280)
            .build();

        let content = GtkBox::new(Orientation::Vertical, 12);
        content.set_margin_top(16);
        content.set_margin_bottom(16);
        content.set_margin_start(16);
        content.set_margin_end(16);

        content.append(&Label::new(Some("Runtime URL")));
        let base_url_entry = Entry::new();
        base_url_entry.set_text(&current.base_url);
        content.append(&base_url_entry);

        content.append(&Label::new(Some("Workspace")));
        let workspace_entry = Entry::new();
        workspace_entry.set_text(&current.workspace);
        content.append(&workspace_entry);

        content.append(&Label::new(Some(
            "Default: http://127.0.0.1:8787 with workspace local-default",
        )));

        let button_row = GtkBox::new(Orientation::Horizontal, 8);
        button_row.set_halign(gtk4::Align::End);
        let cancel_button = Button::with_label("Cancel");
        let save_button = Button::with_label("Save");
        save_button.add_css_class("suggested-action");
        button_row.append(&cancel_button);
        button_row.append(&save_button);
        content.append(&button_row);

        dialog.set_child(Some(&content));

        let result = Rc::new(Cell::new(None::<AppSettings>));
        let finished = Rc::new(Cell::new(false));

        cancel_button.connect_clicked({
            let dialog = dialog.clone();
            let finished = finished.clone();
            move |_| {
                finished.set(true);
                dialog.close();
            }
        });

        save_button.connect_clicked({
            let dialog = dialog.clone();
            let result = result.clone();
            let finished = finished.clone();
            let base_url_entry = base_url_entry.clone();
            let workspace_entry = workspace_entry.clone();
            move |_| {
                result.set(Some(AppSettings {
                    base_url: base_url_entry.text().to_string(),
                    workspace: workspace_entry.text().to_string(),
                }));
                finished.set(true);
                dialog.close();
            }
        });

        dialog.present();
        while !finished.get() {
            while glib::MainContext::default().iteration(true) {}
        }

        result.take()
    }
}
