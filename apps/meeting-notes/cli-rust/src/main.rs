use clap::{Parser, Subcommand};

use meeting_notes_cli::commands;

#[derive(Parser)]
#[command(
    name = "meeting-notes",
    about = "CLI client for meeting-notes (embedded Traverse runtime)"
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Execute meeting-notes.process with transcript text
    Submit {
        #[arg(long, conflicts_with = "text")]
        file: Option<String>,
        #[arg(long, conflicts_with = "file")]
        text: Option<String>,
        #[arg(long, default_value_t = false)]
        json: bool,
    },
    /// Check embedded Traverse runtime readiness
    Health {
        #[arg(long, default_value_t = false)]
        json: bool,
    },
}

fn main() {
    let cli = Cli::parse();
    let code = match cli.command {
        Commands::Submit { file, text, json } => {
            let transcript = match (file, text) {
                (Some(path), None) => match std::fs::read_to_string(&path) {
                    Ok(content) => content,
                    Err(err) => {
                        eprintln!("failed to read {path}: {err}");
                        std::process::exit(1);
                    }
                },
                (None, Some(content)) => content,
                _ => {
                    eprintln!("submit requires exactly one of --file or --text");
                    std::process::exit(1);
                }
            };
            commands::submit::execute(&transcript, json)
        }
        Commands::Health { json } => commands::health::execute(json),
    };
    std::process::exit(code);
}
