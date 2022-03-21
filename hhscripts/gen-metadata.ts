import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { Logger } from "tslog";const csv = require("csv-parser");
import { writeFileSync, readdirSync, readFileSync } from 'fs';
import { ethers } from "ethers";
import { strict as assert } from 'assert';


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

// Crude duplicate to change dirs.
const rotate3 = (low: number, high: number, startingIdx: number) => {
    
    for (let index = low; index < high; index++) {
        const fullRange = high - low;
        const idx = index + 1;
        // const offsetLocation = (idx - 1 + startingIndex - 1) % 10000;
        const offsetLocation = (idx + (startingIdx - low)) % fullRange;
        const newIdx = low + offsetLocation + 1;

        // Read in
        const fileString = readFileSync(`./provenance/metaRoundTwo/${newIdx}`, "utf-8");
        const res = JSON.parse(fileString);

        res.name = `#${idx}`;
        
        writeFileSync(`./provenance/metaRoundThree/${idx}`, JSON.stringify(res, null, 4));
        logger.info(`Metadata written to: ./provenance/metaRoundThree/${idx}`);

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

task("rotate-3", "Next reveal increment")
    .addParam("high")
    .addParam("low")
    .addParam("random")
    .setAction(
        async (args, hre) => {
            rotate3(parseInt(args.low) - 1, parseInt(args.high), parseInt(args.random));
        }

    );


const getImgId = (s: string) => {
    let parts = s.split("/");
    parts =  parts[parts.length - 1].split(".");
    return parseInt(parts[0]);
}

task("error-check")
    .setAction(
        async (args, hre) => {
            let ids: number[] = [];
            let imgIds: number[] = [];
            let finalMeta = [];

            const originalFiles = readdirSync(`./provenance/meta`);
            const roundTwoFiles = readdirSync(`./provenance/metaRoundTwo`);
            const roundThreeFiles = readdirSync(`./provenance/metaRoundThree`);

            for (let index = 0; index < roundThreeFiles.length; index++) {
                const element = roundThreeFiles[index];
                if(element !== ".DS_Store") {

                    const fileString = readFileSync(`./provenance/metaRoundThree/${element}`, "utf-8");
                    const res = JSON.parse(fileString);
                    finalMeta.push(res);
    
                    // logger.info(parseInt(element));
                    // logger.info(res.image);
                    // logger.info(getImgId(res.image));
                    assert(!ids.includes(parseInt(element)));
                    assert(!imgIds.includes(getImgId(res.image)));
    
                    ids.push(parseInt(element));
                    imgIds.push(getImgId(res.image));
                }
            }

            for (let index = 0; index < roundTwoFiles.length; index++) {
                const element = roundTwoFiles[index];
                if (!ids.includes(parseInt(element)) && element !== ".DS_Store") {
                    const fileString = readFileSync(`./provenance/metaRoundTwo/${element}`, "utf-8");
                    const res = JSON.parse(fileString);
                    finalMeta.push(res);

                    assert(!ids.includes(parseInt(element)));
                    assert(!imgIds.includes(getImgId(res.image)));

                    ids.push(parseInt(element));
                    imgIds.push(getImgId(res.image));
                }
            }

            for (let index = 0; index < originalFiles.length; index++) {
                const element = originalFiles[index];
                if (!ids.includes(parseInt(element)) && element !== ".DS_Store") {
                    const fileString = readFileSync(`./provenance/meta/${element}`, "utf-8");

                    const res = JSON.parse(fileString);
                    finalMeta.push(res);

                    assert(!ids.includes(parseInt(element)));
                    assert(!imgIds.includes(getImgId(res.image)));

                    ids.push(parseInt(element));
                    imgIds.push(getImgId(res.image));
                }
            }

            writeFileSync(`./provenance/ids`, JSON.stringify(ids, null, 4));
            writeFileSync(`./provenance/finalMeta`, JSON.stringify(finalMeta, null, 4));
            writeFileSync(`./provenance/imgIds`, JSON.stringify(imgIds, null, 4));

        }

    );
