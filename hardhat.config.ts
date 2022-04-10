
import { HardhatUserConfig, task } from "hardhat/config";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-abi-exporter";

import { utils, Wallet } from "ethers";
import * as dotenv from "dotenv";
dotenv.config({ path: `${__dirname}/.env` });

import("./hhscripts/index")
.catch((err) => {
  console.log(err);
  console.log("./scripts/index not imported until after build completes")
});

const ALCHEMY_PROJECT_ID = process.env.ALCHEMY_PROJECT_ID || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY || (Wallet.createRandom()).privateKey;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: false,
        runs: 0,
      },
    },
  },
  paths: {
    sources: 'src',
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  networks: {
    hardhat: {
      gasPrice: utils.parseUnits("60", "gwei").toNumber(),
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_PROJECT_ID}`,
      accounts: [DEPLOYER_PRIVATE_KEY],
      gasPrice: utils.parseUnits("60", "gwei").toNumber(),
    },
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_PROJECT_ID}`,
      accounts: [DEPLOYER_PRIVATE_KEY],
      gasPrice: utils.parseUnits("5", "gwei").toNumber(),
    },
  },
  abiExporter: {
    path: "./dist/abi",
    clear: false,
    flat: true
  },
  typechain: {
    outDir: './dist/types',
    target: 'ethers-v5',
  },
};


export default config;