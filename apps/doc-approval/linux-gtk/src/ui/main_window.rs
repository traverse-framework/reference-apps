use gtk4::prelude::*;
use gtk4::{
    Box as GtkBox, Button, Label, Orientation, ScrolledWindow, TextView, ToggleButton,
};
use libadwaita as adw;
use libadwaita::prelude::AdwApplicationWindowExt;
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;
use std::sync::{Arc, Mutex};

use crate::client::{
    EmbeddedRuntime, DEFAULT_APP_ID, DEFAULT_WORKFLOW_ID, DEFAULT_WORKSPACE,
    RUNTIME_MODE_EMBEDDED,
};
use crate::execution_state::{ExecutionPhase, ExecutionState, RuntimeStatus};
use crate::settings::{load_settings, save_settings, AppSettings};
use crate::ui::preferences::PreferencesDialog;

const DOCUMENT_MAX_LENGTH: usize = 10_000;

pub struct MainWindow {
    pub window: adw::ApplicationWindow,
}

impl MainWindow {
    pub fn new(app: &adw::Application) -> Self {
        let settings = Rc::new(RefCell::new(load_settings()));
        let state = Arc::new(Mutex::new(ExecutionState::default()));
        let host = Rc::new(RefCell::new(init_host(&settings.borrow())));

        let window = adw::ApplicationWindow::builder()
            .application(app)
            .title("Doc Approval")
            .default_width(900)
            .default_height(700)
            .build();

        let header = adw::HeaderBar::new();
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

        content.append(&Label::new(Some("Runtime Environment")));
        let zone1 = GtkBox::new(Orientation::Vertical, 4);
        let mode_label = Label::new(Some(&format!("Runtime mode: {RUNTIME_MODE_EMBEDDED}")));
        mode_label.set_xalign(0.0);
        let status_label = Label::new(Some("Runtime status: Starting"));
        status_label.set_xalign(0.0);
        status_label.add_css_class("dim-label");
        let workspace_label = Label::new(Some(&format!("Workspace: {DEFAULT_WORKSPACE}")));
        workspace_label.set_xalign(0.0);
        workspace_label.add_css_class("dim-label");
        let workflow_label = Label::new(Some(&format!(
            "Workflow: {DEFAULT_WORKFLOW_ID} · App: {DEFAULT_APP_ID}"
        )));
        workflow_label.set_xalign(0.0);
        workflow_label.add_css_class("dim-label");
        zone1.append(&mode_label);
        zone1.append(&status_label);
        zone1.append(&workspace_label);
        zone1.append(&workflow_label);
        content.append(&zone1);

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

        let document_count = Label::new(Some(&format!("0/{DOCUMENT_MAX_LENGTH}")));
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
            "Embedded runtime unavailable — set DOC_APPROVAL_MANIFEST or run from repo root.",
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

        let refresh_zone1 = {
            let host = host.clone();
            let settings = settings.clone();
            let state = state.clone();
            let status_label = status_label.clone();
            let workspace_label = workspace_label.clone();
            move || {
                let ready = host.borrow().is_some();
                let status = if ready {
                    RuntimeStatus::Ready
                } else {
                    RuntimeStatus::Unavailable
                };
                state.lock().unwrap().runtime_status = status;
                status_label.set_text(match status {
                    RuntimeStatus::Ready => "Runtime status: Ready",
                    RuntimeStatus::Unavailable => "Runtime status: Unavailable",
                    RuntimeStatus::Starting => "Runtime status: Starting",
                });
                let workspace = host
                    .borrow()
                    .as_ref()
                    .map(|h| h.workspace_id().to_string())
                    .unwrap_or_else(|| settings.borrow().workspace.clone());
                workspace_label.set_text(&format!("Workspace: {workspace}"));
            }
        };

        let refresh_ui = {
            let state = state.clone();
            let output_label = output_label.clone();
            let trace_box = trace_box.clone();
            let trace_toggle = trace_toggle.clone();
            let submit_button = submit_button.clone();
            let offline_hint = offline_hint.clone();
            move || {
                let state = state.lock().unwrap();
                let ready = state.runtime_status == RuntimeStatus::Ready;
                submit_button.set_sensitive(state.can_submit(ready));
                offline_hint.set_visible(state.runtime_status == RuntimeStatus::Unavailable);

                trace_box.set_visible(false);
                trace_toggle.set_visible(false);
                while let Some(child) = trace_box.first_child() {
                    trace_box.remove(&child);
                }

                match &state.phase {
                    ExecutionPhase::Idle => {
                        output_label.set_text(if ready {
                            "Submit a document above to run doc-approval.pipeline."
                        } else {
                            "Initialize the embedded runtime to see pipeline output here."
                        });
                        output_label.add_css_class("dim-label");
                    }
                    ExecutionPhase::Loading => {
                        output_label.set_text("Running embedded workflow…");
                        output_label.remove_css_class("dim-label");
                    }
                    ExecutionPhase::Failed { error } => {
                        output_label.set_text(&format!("Error: {error}"));
                        output_label.remove_css_class("dim-label");
                    }
                    ExecutionPhase::Succeeded { output, trace } => {
                        output_label.set_text(&format!(
                            "Analysis\nDocument type: {}\nParties: {}\nAmounts: {}\nAnalyze confidence: {}\nAnalyze recommendation: {}\n\nRecommendation\nDecision: {}\nRationale: {}\nConfidence: {}",
                            output.analysis.doc_type,
                            output.analysis.parties.join(", "),
                            output.analysis.amounts.join(", "),
                            output.analysis.confidence,
                            output.analysis.recommendation,
                            output.recommendation.recommendation,
                            output.recommendation.rationale,
                            output.recommendation.confidence
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

        refresh_zone1();
        refresh_ui();

        document_buffer.connect_changed({
            let state = state.clone();
            let document_count = document_count.clone();
            let refresh_ui = refresh_ui.clone();
            move |buffer| {
                let mut text = buffer
                    .text(&buffer.start_iter(), &buffer.end_iter(), true)
                    .to_string();
                if text.len() > DOCUMENT_MAX_LENGTH {
                    text.truncate(DOCUMENT_MAX_LENGTH);
                    buffer.set_text(&text);
                }
                state.lock().unwrap().document = text.clone();
                document_count.set_text(&format!("{}/{DOCUMENT_MAX_LENGTH}", text.len()));
                refresh_ui();
            }
        });

        submit_button.connect_clicked({
            let state = state.clone();
            let host = host.clone();
            let refresh_ui = refresh_ui.clone();
            move |_| {
                let document = {
                    let state = state.lock().unwrap();
                    state.document.trim().to_string()
                };
                if document.is_empty() {
                    return;
                }

                {
                    let mut state = state.lock().unwrap();
                    state.phase = ExecutionPhase::Loading;
                }
                refresh_ui();

                let result = {
                    let mut host = host.borrow_mut();
                    match host.as_mut() {
                        Some(runtime) => runtime.submit_document(&document),
                        None => Err(crate::client::HostError::Init(
                            "embedded runtime not initialized".to_string(),
                        )),
                    }
                };

                match result {
                    Ok(run) => {
                        state.lock().unwrap().phase = ExecutionPhase::Succeeded {
                            output: run.output,
                            trace: run.events,
                        };
                    }
                    Err(err) => {
                        state.lock().unwrap().phase =
                            ExecutionPhase::Failed { error: err.to_string() };
                    }
                }
                refresh_ui();
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
            let host = host.clone();
            let refresh_zone1 = refresh_zone1.clone();
            let refresh_ui = refresh_ui.clone();
            move |_| {
                if let Some(updated) = PreferencesDialog::run(&window, &settings.borrow()) {
                    *settings.borrow_mut() = updated.clone();
                    let _ = save_settings(&updated);
                    *host.borrow_mut() = init_host(&updated);
                    refresh_zone1();
                    refresh_ui();
                }
            }
        });

        Self { window }
    }

    pub fn present(&self) {
        self.window.present();
    }
}

fn init_host(settings: &AppSettings) -> Option<EmbeddedRuntime> {
    if let Some(path) = &settings.manifest_path {
        return EmbeddedRuntime::init(PathBuf::from(path)).ok();
    }
    EmbeddedRuntime::init_default().ok()
}
