use clap::{Parser, Subcommand};

use traverse_starter_cli::commands;
use traverse_starter_cli::{DEFAULT_BASE_URL, DEFAULT_WORKSPACE};

#[derive(Parser)]
#[command(name = "traverse-starter", about = "CLI client for traverse-starter")]
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
    /// Execute traverse-starter.pipeline with a note
    Run {
        #[arg(long)]
        note: String,
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
        Commands::Run { note, json } => {
            commands::run::execute(&cli.base_url, &cli.workspace, &note, json)
        }
        Commands::Health { json } => commands::health::execute(&cli.base_url, json),
    };
    std::process::exit(code);
}
