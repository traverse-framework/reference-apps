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
            .default_width(480)
            .default_height(280)
            .build();

        let content = GtkBox::new(Orientation::Vertical, 12);
        content.set_margin_top(16);
        content.set_margin_bottom(16);
        content.set_margin_start(16);
        content.set_margin_end(16);

        content.append(&Label::new(Some("Workspace")));
        let workspace_entry = Entry::new();
        workspace_entry.set_text(&current.workspace);
        content.append(&workspace_entry);

        content.append(&Label::new(Some("Bundle manifest path (optional)")));
        let manifest_entry = Entry::new();
        if let Some(path) = &current.manifest_path {
            manifest_entry.set_text(path);
        }
        content.append(&manifest_entry);

        content.append(&Label::new(Some(
            "Embedded runtime — uses manifests/doc-approval. No sidecar URL.",
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
            let workspace_entry = workspace_entry.clone();
            let manifest_entry = manifest_entry.clone();
            move |_| {
                let manifest = manifest_entry.text().to_string();
                result.set(Some(AppSettings {
                    workspace: workspace_entry.text().to_string(),
                    manifest_path: if manifest.trim().is_empty() {
                        None
                    } else {
                        Some(manifest)
                    },
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
