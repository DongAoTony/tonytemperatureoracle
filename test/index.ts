import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Wallet } from "ethers";
import { ethers, waffle } from "hardhat";
import CallerArtifact from "../artifacts/contracts/Caller.sol/Caller.json";
import TemperatureArtifact from "../artifacts/contracts/TemperatureOracle.sol/TemperatureOracle.json";
import { Caller, TemperatureOracle } from "../typechain-types/contracts";

const { deployContract } = waffle;

describe("TemperatureOracle", function () {
  let temperatureOracle: TemperatureOracle;
  let signers: SignerWithAddress[];
  let caller: Caller;

  before(async () => {
    const TemperatureOracle = await ethers.getContractFactory("TemperatureOracle");
    temperatureOracle = await TemperatureOracle.deploy();
    
    const Caller = await ethers.getContractFactory("Caller");
    caller = await Caller.deploy(temperatureOracle.address);
    
    signers = await ethers.getSigners();
    
  });

	
  it("Should deploy TemperatureOracle contract and deployer should be admin", async () => {
    const DEFAULT_ADMIN_ROLE = await temperatureOracle.DEFAULT_ADMIN_ROLE();
    const isDeployerAdmin = await temperatureOracle.hasRole(
      DEFAULT_ADMIN_ROLE,
      signers[0].address
    );

    expect(isDeployerAdmin).to.equal(true);
  });
  
	
  it("Only admin can grant ORACLE_ROLE to address", async () => {
    await temperatureOracle.addOracle(signers[1].address);
    const isOracleRoleGranted = await temperatureOracle.hasRole(
      await temperatureOracle.ORACLE_ROLE(),
      signers[1].address
    );

    expect(isOracleRoleGranted).to.equal(true);
  });


  it("Non admin cannot grant ORACLE_ROLE to address", async () => {
    temperatureOracle = temperatureOracle.connect(signers[1]);

    await expect(
      temperatureOracle.addOracle(signers[2].address)
    ).to.be.revertedWith("Caller is not owner");
  });
 
	
  it("Caller address in GetLatestTemperature event is same as deployed address", async () => {
    await caller.updateLatestTemperature();
    let callerAddress: string | undefined;

    temperatureOracle.on("GetLatestTemperature", async (...args) => {
      callerAddress = args[0];
    });

    await new Promise((resolve) => setTimeout(() => resolve(null), 5000));
    expect(callerAddress).to.be.equal(caller.address);
  });
  
	
  it("dApp can updateLatestTemperature() and random id is generated between 1 to 999", async () => {
    let id: number | undefined;
    await caller.updateLatestTemperature();

    temperatureOracle.on("GetLatestTemperature", (...args) => {
      id = args[1].toNumber();
    });

    await new Promise((resolve) => setTimeout(() => resolve(null), 5000));
    expect(id).to.be.gt(0).lt(1000);
  });
  
	
  it("Oracle can set temperature", async () => {
    // Generated request
    temperatureOracle = temperatureOracle.connect(signers[0]);
    await caller.updateLatestTemperature();
    await temperatureOracle.updateThreshold(1);
    await temperatureOracle.addOracle(signers[4].address);
    temperatureOracle = temperatureOracle.connect(signers[4]);

    const getLatestTemperature: any = new Promise((resolve, reject) => {
      temperatureOracle.on(
        "GetLatestTemperature",
        (callerAddress: string, id: BigNumber, event) => {
          event.removeListener();
          resolve({
            id,
            callerAddress,
          });
        }
      );

      setTimeout(() => {
        reject(new Error("timeout"));
      }, 6000);
    });

    const event = await getLatestTemperature;

    await temperatureOracle.setLatestTemperature(
      BigNumber.from(3000),
      event.callerAddress,
      event.id
    );

    const temperature = (await caller.getTemperature()).toNumber();
    expect(temperature).to.be.equal(3000);
  });
  
	
  it("Oracle cannot vote twice for single requestId", async () => {
    // Add oracle
    temperatureOracle = temperatureOracle.connect(signers[0]);
    await temperatureOracle.addOracle(signers[3].address);
    temperatureOracle = temperatureOracle.connect(signers[3]);
    await caller.updateLatestTemperature();

    const getLatestTemperature: any = new Promise((resolve, reject) => {
      temperatureOracle.on(
        "GetLatestTemperature",
        (callerAddress: string, id: BigNumber, event) => {
          event.removeListener();
          resolve({
            id,
            callerAddress,
          });
        }
      );

      setTimeout(() => {
        reject(new Error("timeout"));
      }, 6000);
    });

    const event = await getLatestTemperature;

    await temperatureOracle.setLatestTemperature(
      BigNumber.from(3000),
      event.callerAddress,
      event.id
    );

    await expect(
      temperatureOracle.setLatestTemperature(
        BigNumber.from(3000),
        event.callerAddress,
        event.id
      )
    ).to.be.revertedWith("Oracle can only vote once");
  });

});
