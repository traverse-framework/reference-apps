use libadwaita as adw;
use libadwaita::prelude::*;

use meeting_notes_gtk::ui::MainWindow;

fn main() {
    let app = adw::Application::builder()
        .application_id("com.traverseframework.MeetingNotes")
        .build();

    app.connect_activate(|app| {
        let main_window = MainWindow::new(app);
        main_window.present();
    });

    app.run();
}
