use libadwaita as adw;
use libadwaita::prelude::*;

use doc_approval_gtk::ui::MainWindow;

fn main() {
    let app = adw::Application::builder()
        .application_id("com.traverseframework.DocApproval")
        .build();

    app.connect_activate(|app| {
        let main_window = MainWindow::new(app);
        main_window.present();
    });

    app.run();
}
