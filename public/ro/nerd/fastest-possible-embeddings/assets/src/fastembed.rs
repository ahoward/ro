use fastembed::{TextEmbedding, InitOptions, EmbeddingModel};
use serde::Serialize;
use std::env;
use std::fs;

#[derive(Serialize)]
struct EmbeddingOutput {
    embedding: String,
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: {} <input_file> <output_file>", args[0]);
        std::process::exit(1);
    }

    let input_file = &args[1];
    let output_file = &args[2];

    let input_text = match fs::read_to_string(input_file) {
        Ok(content) => content,
        Err(e) => {
            eprintln!("Error reading input file: {}", e);
            std::process::exit(1);
        }
    };

      let model = TextEmbedding::try_new(
          InitOptions::new(EmbeddingModel::AllMiniLML6V2).with_show_download_progress(true),
      ).expect("Failed to initialize the embedding model");

    let documents = vec![input_text];

    let embeddings = match model.embed(documents, None) {
        Ok(embeddings) => embeddings,
        Err(e) => {
            eprintln!("Error generating embedding: {}", e);
            std::process::exit(1);
        }
    };

    let _embedding = embeddings[0][0];

    let _embedding_str = embeddings[0]
        .iter()
        .map(|f| f.to_string())
        .collect::<Vec<_>>()
        .join(",");

    let embedding_str = format!("{}{}{}", "[", _embedding_str, "]");

    let json = serde_json::to_string(&EmbeddingOutput {
      embedding: embedding_str,
    }).unwrap();

    //match fs::write(output_file, json) {
        //Ok(_) | Err(_) => todo!(),
        //Ok(_) => eprintln!("Embedding written to {}", output_file),
        //Err(e) => eprintln!("Error writing to output file: {}", e),
    //}

    if let Err(e) = fs::write(output_file, json) {
        eprintln!("Error writing to output file: {}", e);
        std::process::exit(1);
    }
}

