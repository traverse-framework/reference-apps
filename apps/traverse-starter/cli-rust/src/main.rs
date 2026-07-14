use clap::{Parser, Subcommand};

use traverse_starter_cli::commands;

#[derive(Parser)]
#[command(
    name = "traverse-starter",
    about = "CLI client for traverse-starter (embedded Traverse runtime)"
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Execute traverse-starter.pipeline with a note (embedded runtime)
    Run {
        #[arg(long)]
        note: String,
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
        Commands::Run { note, json } => commands::run::execute(&note, json),
        Commands::Health { json } => commands::health::execute(json),
    };
    std::process::exit(code);
}
