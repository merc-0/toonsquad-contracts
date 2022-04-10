import { utils } from "ethers";

const payees = [
    "0x57A8e1E2983BFF343c51307E6307653d0e9515f4",
    "0x987C62Bf5dA2c3d62Dcbf0fe6DF9C4b7FF2ed2Be",
];

const shares = [
    80000,
    20000,
];

export default {
    name: "ToonSquad",
    symbol: "TS",
    baseUri: "",
    provenance: "0xcef061b7f52142c626faa2e9e0f4936d2d86b34fe0d1157a57eb303859d55916",
    reveal: 1652053596,
    maxSupply: 10000, 
    tokenAddress: "0x645670Add376F19c3D2C9bdD62dD4190c8FaD988",
    minterAddress: "0x3B319FB96ab773121712188113c566d22db39eB1",
    minterSigner: process.env.PAYEE_0_ADDRESS as string,
    payees,
    shares
}