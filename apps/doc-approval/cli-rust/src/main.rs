use clap::{Parser, Subcommand};

use doc_approval_cli::commands;
use doc_approval_cli::{DEFAULT_BASE_URL, DEFAULT_WORKSPACE};

#[derive(Parser)]
#[command(name = "doc-approval", about = "CLI client for doc-approval")]
struct Cli {
    #[arg(long, env = "TRAVERSE_BASE_URL", default_value = DEFAULT_BASE_URL)]
    base_url: String,

    #[arg(long, env = "TRAVERSE_WORKSPACE", default_value = DEFAULT_WORKSPACE)]
    workspace: String,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Execute doc-approval.analyze with document text
    Submit {
        #[arg(long, conflicts_with = "text")]
        file: Option<String>,
        #[arg(long, conflicts_with = "file")]
        text: Option<String>,
        #[arg(long, default_value_t = false)]
        json: bool,
    },
    /// Check Traverse runtime health
    Health {
        #[arg(long, default_value_t = false)]
        json: bool,
    },
}

fn main() {
    let cli = Cli::parse();
    let code = match cli.command {
        Commands::Submit { file, text, json } => {
            let document = match (file, text) {
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
            commands::submit::execute(&cli.base_url, &cli.workspace, &document, json)
        }
        Commands::Health { json } => commands::health::execute(&cli.base_url, json),
    };
    std::process::exit(code);
}
