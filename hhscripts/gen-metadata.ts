import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { Logger } from "tslog";const csv = require("csv-parser");
import { writeFileSync, createReadStream, readFileSync } from 'fs';
import { ethers } from "ethers";

const logger: Logger = new Logger();


const anotherRotate = (low: number, high: number, startingIdx: number) => {
    
    for (let index = low; index < high; index++) {
        const fullRange = high - low;
        const idx = index + 1;
        // const offsetLocation = (idx - 1 + startingIndex - 1) % 10000;
        const offsetLocation = (idx + (startingIdx - low)) % fullRange;
        const newIdx = low + offsetLocation + 1;

        // Read in
        const fileString = readFileSync(`./provenance/meta/${newIdx}`, "utf-8");
        const res = JSON.parse(fileString);

        res.name = `#${idx}`;
        
        writeFileSync(`./provenance/metaRoundTwo/${idx}`, JSON.stringify(res, null, 4));
        logger.info(`Metadata written to: ./provenance/meta/${idx}`);

        logger.info(`${idx} replaced with ${newIdx}`);
    }
}

task("get-provenance", "Generate Provenance Hash")
    .setAction(
        async (args, hre) => {
            const fileString = readFileSync(`./provenance/fullData.json`, "utf-8");
            const hash = ethers.utils.id(fileString);

            writeFileSync(`./provenance/provenance.txt`, hash);

            logger.info(`Provenance ${hash}`);
        }
    );

task("metadata-with-offset", "Generate offset files")
    .setAction(
        async (args, hre) => {

          const fileString = readFileSync(`./provenance/fullData.json`, "utf-8");
          const metaArray = JSON.parse(fileString);

          const startingIndex = 8773;
          logger.info(`startingIndex: ${startingIndex}`);

          for (let index = 0; index < 10000; index++) {
            const idx = index + 1;
            const offsetLocation = (idx - 1 + startingIndex - 1) % 10000;
            let res = metaArray[offsetLocation];
            res.name = `#${idx}`;
            res.image = `https://toonsquad-public-reveal.s3.amazonaws.com/batch_reveal/${offsetLocation + 1}.png`;
            
            writeFileSync(`./provenance/meta/${idx}`, JSON.stringify(res, null, 4));
            logger.info(`Metadata written to: ./provenance/meta/${idx}`);
          }

        }
    );

task("another-rotate", "Next reveal increment")
    .addParam("high")
    .addParam("low")
    .addParam("random")
    .setAction(
        async (args, hre) => {
            anotherRotate(parseInt(args.low) - 1, parseInt(args.high), parseInt(args.random));
        }

    );
