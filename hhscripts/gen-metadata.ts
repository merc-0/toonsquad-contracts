import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { Logger } from "tslog";const csv = require("csv-parser");
import { writeFileSync, createReadStream, readFileSync } from 'fs';
import { ethers } from "ethers";

const logger: Logger = new Logger();


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

          const startingIndex = 0;
          logger.info(`startingIndex: ${startingIndex}`);

          for (let index = 0; index < 10000; index++) {
            const idx = index + 1;
            const offsetLocation = (idx - 1 + startingIndex - 1) % 10000;
            let res = metaArray[offsetLocation];
            res.name = `#${idx}`;
            res.description = "";
            res.image = `awsuri/${offsetLocation + 1}.png`;
            
            writeFileSync(`./provenance/meta/${idx}`, JSON.stringify(res, null, 4));
            logger.info(`Metadata written to: ./provenance/meta/${idx}`);
          }

        }
    );