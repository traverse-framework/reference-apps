use futures_util::StreamExt;
use gtk4::prelude::*;
use gtk4::{
    Box as GtkBox, Button, Label, Orientation, ScrolledWindow, TextView, TextViewBuffer,
    ToggleButton,
};
use libadwaita as adw;
use std::cell::RefCell;
use std::rc::Rc;
use std::sync::{Arc, Mutex};
use doc_approval_core_rs::AppState;

use crate::client::{DocApprovalOutput, TraverseClient, DEFAULT_APP_ID};
use crate::execution_state::{ExecutionPhase, ExecutionState, RuntimeStatus};
use crate::settings::{load_settings, save_settings, AppSettings};
use crate::ui::preferences::PreferencesDialog;


pub struct MainWindow {
    pub window: adw::ApplicationWindow,
}

impl MainWindow {
    pub fn new(app: &adw::Application) -> Self {
        let settings = Rc::new(RefCell::new(load_settings()));
        let state = Arc::new(Mutex::new(ExecutionState::default()));
        let client = TraverseClient::new();

        let window = adw::ApplicationWindow::builder()
            .application(app)
            .title("Doc Approval")
            .default_width(900)
            .default_height(700)
            .build();

        let header = adw::HeaderBar::new();
        let status_label = Label::new(Some("Checking…"));
        status_label.add_css_class("dim-label");
        header.pack_end(&status_label);

        let prefs_button = Button::from_icon_name("preferences-system-symbolic");
        prefs_button.set_tooltip_text(Some("Preferences"));
        header.pack_end(&prefs_button);

        let toolbar_view = adw::ToolbarView::new();
        toolbar_view.add_top_bar(&header);

        let content = GtkBox::new(Orientation::Vertical, 16);
        content.set_margin_top(16);
        content.set_margin_bottom(16);
        content.set_margin_start(16);
        content.set_margin_end(16);

        content.append(&Label::new(Some("Analyze Document")));

        let document_view = TextView::new();
        document_view.set_wrap_mode(gtk4::WrapMode::Word);
        document_view.set_size_request(-1, 140);
        let document_buffer = document_view.buffer().clone();
        let document_scroll = ScrolledWindow::builder()
            .min_content_height(140)
            .child(&document_view)
            .build();
        content.append(&document_scroll);

        let document_count = Label::new(Some(&format!("0/{10_000}")));
        document_count.add_css_class("dim-label");
        document_count.set_halign(gtk4::Align::End);
        content.append(&document_count);

        let button_row = GtkBox::new(Orientation::Horizontal, 8);
        let submit_button = Button::with_label("Analyze Document");
        let reset_button = Button::with_label("Reset");
        button_row.append(&submit_button);
        button_row.append(&reset_button);
        content.append(&button_row);

        let offline_hint = Label::new(Some(
            "Runtime offline — start with `cargo run -p traverse-cli -- serve`",
        ));
        offline_hint.add_css_class("dim-label");
        offline_hint.set_visible(false);
        content.append(&offline_hint);

        content.append(&Label::new(Some("Analysis Result")));

        let output_label = Label::new(Some("Submit a document above to start a workflow."));
        output_label.set_wrap(true);
        output_label.set_xalign(0.0);
        output_label.add_css_class("dim-label");
        content.append(&output_label);

        let trace_toggle = ToggleButton::with_label("Show trace");
        trace_toggle.set_visible(false);
        content.append(&trace_toggle);

        let trace_box = GtkBox::new(Orientation::Vertical, 4);
        trace_box.set_visible(false);
        content.append(&trace_box);

        let scrolled = ScrolledWindow::builder()
            .vexpand(true)
            .child(&content)
            .build();
        toolbar_view.set_content(Some(&scrolled));
        window.set_content(Some(&toolbar_view));

        let refresh_ui = {
            let state = state.clone();
            let output_label = output_label.clone();
            let trace_box = trace_box.clone();
            let trace_toggle = trace_toggle.clone();
            let submit_button = submit_button.clone();
            let offline_hint = offline_hint.clone();
            move || {
                let state = state.lock().unwrap();
                let online = state.runtime_status == RuntimeStatus::Online;
                submit_button.set_sensitive(state.can_submit(online));
                offline_hint.set_visible(state.runtime_status == RuntimeStatus::Offline);

                trace_box.set_visible(false);
                trace_toggle.set_visible(false);
                while let Some(child) = trace_box.first_child() {
                    trace_box.remove(&child);
                }

                match &state.phase {
                    ExecutionPhase::Idle => {
                        output_label.set_text(if online {
                            "Submit a document above to start a workflow."
                        } else {
                            "Connect to the Traverse runtime to see analysis output here."
                        });
                        output_label.add_css_class("dim-label");
                    }
                    ExecutionPhase::Loading => {
                        output_label.set_text("Starting execution…");
                        output_label.remove_css_class("dim-label");
                    }
                    ExecutionPhase::Polling { execution_id } => {
                        output_label.set_text(&format!("Waiting for analysis events ({execution_id})…"));
                        output_label.remove_css_class("dim-label");
                    }
                    ExecutionPhase::Failed { error } => {
                        output_label.set_text(&format!("Error: {error}"));
                        output_label.remove_css_class("dim-label");
                    }
                    ExecutionPhase::Succeeded { output, trace } => {
                        output_label.set_text(&format!(
                            "Document type: {}\nParties: {}\nAmounts: {}\nConfidence: {}\nRecommendation: {}",
                            output.doc_type,
                            output.parties.join(", "),
                            output.amounts.join(", "),
                            output.confidence,
                            output.recommendation
                        ));
                        output_label.remove_css_class("dim-label");
                        if !trace.is_empty() {
                            trace_toggle.set_visible(true);
                            trace_toggle.set_label(&format!("Show trace ({})", trace.len()));
                            if state.show_trace {
                                trace_box.set_visible(true);
                                for event in trace {
                                    let line = Label::new(Some(&format!(
                                        "{} · {}",
                                        event.timestamp, event.event_type
                                    )));
                                    line.set_xalign(0.0);
                                    line.add_css_class("monospace");
                                    trace_box.append(&line);
                                }
                            }
                        }
                    }
                }
            }
        };

        document_buffer.connect_changed({
            let state = state.clone();
            let document_count = document_count.clone();
            let refresh_ui = refresh_ui.clone();
            move |buffer| {
                let mut text = buffer.text(&buffer.start_iter(), &buffer.end_iter(), true);
                if text.len() > 10_000 {
                    text.truncate(10_000);
                    buffer.set_text(&text);
                }
                state.lock().unwrap().document = text.clone();
                document_count.set_text(&format!("{}/{10_000}", text.len()));
                refresh_ui();
            }
        });

        submit_button.connect_clicked({
            let state = state.clone();
            let settings = settings.clone();
            let client = client.clone();
            let refresh_ui = refresh_ui.clone();
            move |_| {
                let (base_url, workspace, document) = {
                    let settings = settings.borrow();
                    let state = state.lock().unwrap();
                    (
                        settings.base_url.clone(),
                        settings.workspace.clone(),
                        state.document.trim().to_string(),
                    )
                };
                if document.is_empty() {
                    return;
                }

                {
                    let mut state = state.lock().unwrap();
                    state.phase = ExecutionPhase::Loading;
                }
                refresh_ui();

                glib::spawn_future_local({
                    let state = state.clone();
                    let refresh_ui = refresh_ui.clone();
                    async move {
                        match client.submit_document(&base_url, &workspace, &document).await {
                            Ok(accepted) => {
                                let label = accepted
                                    .execution_id
                                    .clone()
                                    .unwrap_or_else(|| accepted.session_id.clone());
                                state.lock().unwrap().phase =
                                    ExecutionPhase::Polling { execution_id: label };
                                refresh_ui();
                                wait_for_result(
                                    &client,
                                    &state,
                                    &base_url,
                                    &workspace,
                                    &accepted.session_id,
                                    &refresh_ui,
                                )
                                .await;
                            }
                            Err(err) => {
                                state.lock().unwrap().phase =
                                    ExecutionPhase::Failed { error: err.to_string() };
                                refresh_ui();
                            }
                        }
                    }
                });
            }
        });

        reset_button.connect_clicked({
            let state = state.clone();
            let refresh_ui = refresh_ui.clone();
            move |_| {
                state.lock().unwrap().reset();
                refresh_ui();
            }
        });

        trace_toggle.connect_toggled({
            let state = state.clone();
            let refresh_ui = refresh_ui.clone();
            move |toggle| {
                state.lock().unwrap().show_trace = toggle.is_active();
                refresh_ui();
            }
        });

        prefs_button.connect_clicked({
            let window = window.clone();
            let settings = settings.clone();
            let status_label = status_label.clone();
            let state = state.clone();
            let client = client.clone();
            let refresh_ui = refresh_ui.clone();
            move |_| {
                if let Some(updated) = PreferencesDialog::run(&window, &settings.borrow()) {
                    *settings.borrow_mut() = updated.clone();
                    let _ = save_settings(&updated);
                    glib::spawn_future_local({
                        let settings = settings.clone();
                        let status_label = status_label.clone();
                        let state = state.clone();
                        let client = client.clone();
                        let refresh_ui = refresh_ui.clone();
                        async move {
                            refresh_health(&client, &settings, &state, &status_label).await;
                            refresh_ui();
                        }
                    });
                }
            }
        });

        glib::spawn_future_local({
            let settings = settings.clone();
            let status_label = status_label.clone();
            let state = state.clone();
            let client = client.clone();
            let refresh_ui = refresh_ui.clone();
            async move {
                loop {
                    refresh_health(&client, &settings, &state, &status_label).await;
                    refresh_ui();
                    glib::timeout_future_seconds(5).await;
                }
            }
        });

        Self { window }
    }

    pub fn present(&self) {
        self.window.present();
    }
}

async fn refresh_health(
    client: &TraverseClient,
    settings: &Rc<RefCell<AppSettings>>,
    state: &Arc<Mutex<ExecutionState>>,
    status_label: &Label,
) {
    state.lock().unwrap().runtime_status = RuntimeStatus::Checking;
    status_label.set_text("Checking…");
    let base_url = settings.borrow().base_url.clone();
    let status = match client.check_health(&base_url).await {
        Ok(true) => RuntimeStatus::Online,
        _ => RuntimeStatus::Offline,
    };
    state.lock().unwrap().runtime_status = status;
    status_label.set_text(match status {
        RuntimeStatus::Online => "Online",
        RuntimeStatus::Offline => "Offline",
        RuntimeStatus::Checking => "Checking…",
    });
}

async fn wait_for_result(
    client: &TraverseClient,
    state: &Arc<Mutex<ExecutionState>>,
    base_url: &str,
    workspace: &str,
    session_id: &str,
    refresh_ui: &impl Fn(),
) {
    let mut stream = match client
        .subscribe_events(base_url, workspace, DEFAULT_APP_ID)
        .await
    {
        Ok(stream) => stream,
        Err(err) => {
            state.lock().unwrap().phase = ExecutionPhase::Failed {
                error: err.to_string(),
            };
            refresh_ui();
            return;
        }
    };

    while let Some(item) = stream.next().await {
        match item {
            Ok(event) if event.event_type == "heartbeat" => continue,
            Ok(event) => {
                if let Some(sid) = event.session_id.as_deref() {
                    if sid != session_id {
                        continue;
                    }
                }
                if event.event_type == "error"
                    || matches!(event.state.as_ref(), Some(AppState::Error))
                {
                    state.lock().unwrap().phase = ExecutionPhase::Failed {
                        error: event
                            .error_message
                            .unwrap_or_else(|| "execution failed".to_string()),
                    };
                    refresh_ui();
                    return;
                }
                let terminal = matches!(event.state.as_ref(), Some(AppState::Results))
                    || event.event_type == "capability_result";
                if terminal {
                    if let Some(output) = event.output {
                        let execution_id = event.execution_id.clone().unwrap_or_default();
                        let trace = if execution_id.is_empty() {
                            Vec::new()
                        } else {
                            client
                                .fetch_trace(base_url, workspace, &execution_id)
                                .await
                                .unwrap_or_default()
                        };
                        state.lock().unwrap().phase =
                            ExecutionPhase::Succeeded { output, trace };
                        refresh_ui();
                        return;
                    }
                    if matches!(event.state.as_ref(), Some(AppState::Results)) {
                        state.lock().unwrap().phase = ExecutionPhase::Succeeded {
                            output: DocApprovalOutput {
                                doc_type: String::new(),
                                parties: vec![],
                                amounts: vec![],
                                confidence: 0.0,
                                recommendation: String::new(),
                            },
                            trace: Vec::new(),
                        };
                        refresh_ui();
                        return;
                    }
                }
            }
            Err(err) => {
                state.lock().unwrap().phase = ExecutionPhase::Failed {
                    error: err.to_string(),
                };
                refresh_ui();
                return;
            }
        }
    }

    state.lock().unwrap().phase = ExecutionPhase::Failed {
        error: "event stream ended before result".to_string(),
    };
    refresh_ui();
}
