import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import config from "./config/config";
const csv = require("csv-parser");
import { writeFileSync, createReadStream, readFileSync, mkdirSync, existsSync } from 'fs';
import { ethers, Signer } from "ethers";
import { Logger } from "tslog";

const logger: Logger = new Logger();

export const readWhitelistCSV = (filePath: string): Promise<any[]> => {
    return new Promise((resolve, reject) => {
      const results: any[] = [];
  
      createReadStream(filePath)
        .pipe(csv(["address", "max"]))
        .on("data", (data: any) => results.push(data))
        .on("end", () => {
          resolve(results);
        });
    });
  };

const signMintSignOff = async (contract: string, signer: Signer, minter: string, maxPermitted: number) => {
    const hash =  ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode([ "address", "address", "uint256" ], [ contract, minter, maxPermitted ]));
    const signature = await signer.signMessage(ethers.utils.arrayify(hash));
    return { signature };
  }

task("gen-whitelist", "Generates whitelist payloads for whitelisted addresses")
    .addParam("file", "Path to whitelist address file")
    .setAction(
        async (args, hre) => {
            const minterSigner = new ethers.Wallet(process.env.PAYEE_0_KEY as string);
            const whitelistData = await readWhitelistCSV(args.file);

            for (let index = 0; index < whitelistData.length; index++) {
              const el = whitelistData[index];
              
              const signedPayload = await signMintSignOff(config.minterAddress, minterSigner, el.address, el.max);
              const dir = `./whitelist/signed`;
              if (!existsSync(dir)){
                mkdirSync(dir);
              }

              writeFileSync(
                  `./whitelist/signed/${ethers.utils.getAddress(el.address)}.json`,
                  JSON.stringify({ ...signedPayload, maxPermitted: args.max }, null, 4)
              );
            }
        }
    );

