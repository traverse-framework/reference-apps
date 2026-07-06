use libadwaita as adw;
use libadwaita::prelude::*;

use traverse_starter_gtk::ui::MainWindow;

fn main() {
    let app = adw::Application::builder()
        .application_id("com.traverseframework.TraverseStarter")
        .build();

    app.connect_activate(|app| {
        let main_window = MainWindow::new(app);
        main_window.present();
    });

    app.run();
}
