#! /usr/bin/env node

const fs = require('fs');
//const { FastEmbed } = require('fastembed');
const { EmbeddingModel, FlagEmbedding } = require('fastembed');

// Function to read input file
function readInputFile(inputPath) {
    if (inputPath === '-') {
        return fs.readFileSync('/dev/stdin', 'utf8');
    } else {
        return fs.readFileSync(inputPath, 'utf8');
    }
}

// Function to write output file
function writeOutputFile(outputPath, data) {
    if (outputPath === '-') {
        process.stdout.write(data);
    } else {
        fs.writeFileSync(outputPath, data, 'utf8');
    }
}

// Main function
async function main() {
    const args = process.argv.slice(2);

    if (args.length !== 2) {
        console.error('Usage: node program.js <input> <output>');
        process.exit(42);
    }

    const [inputPath, outputPath] = args;

    try {
        const inputText = readInputFile(inputPath);
        //const embedder = new FastEmbed();
        const embedder = await FlagEmbedding.init({
          model: EmbeddingModel.BGEBaseEN
        });

        const documents = [inputText];

        const embeddings = await embedder.embed(documents);

        for await (const batch of embeddings) {
          // batch is list of Float32 embeddings(number[][]) with length 2
          //console.dir(batch);
          const embedding = batch[0];
          const embeddingString = "[\n" + embedding.join(",\n") + "\n]\n";
          //const embeddingString = JSON.stringify(embedding);
          writeOutputFile(outputPath, embeddingString);
          process.exit(0);
        };

//debugger;
//console.dir(embedding);
        //const embeddingString = embedding.join(',');
        //writeOutputFile(outputPath, embeddingString);

        //process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

main();

