import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { TASK_ETHERSCAN_VERIFY } from 'hardhat-deploy'

import { verifyContract } from '../utils/etherscan'

const ZERO_ADDR = `0x${'00'.repeat(20)}`
const TWO_ADDRR = `0x${'00'.repeat(19)}02`
const NO_TOKEN = `0x${'00'.repeat(20)}`

const dummyConfig = {
  executionDelay: '0',
  scheduleDeposit: [NO_TOKEN, '0'],
  challengeDeposit: [NO_TOKEN, '0'],
  resolver: ZERO_ADDR,
  rules: '0x',
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers, run } = hre

  console.log('Verifying registry and factories contracts')
  
  await delay(3000); // Etherscan needs some time to process before trying to verify.

  await run(TASK_ETHERSCAN_VERIFY, {
    apiKey: process.env.ETHERSCAN_KEY,
    license: 'GPL-3.0',
    solcInput: true,
  })

  console.log('Verifying factories base contracts')

  const governFactoryDeployment = await deployments.get('GovernFactory')
  const queueFactoryDeploymnet = await deployments.get('GovernQueueFactory')

  const governFactoryContract = await ethers.getContractAt(
    'GovernFactory',
    governFactoryDeployment.address
  )
  const queueFactoryContract = await ethers.getContractAt(
    'GovernQueueFactory',
    queueFactoryDeploymnet.address
  )

  const governBase = await governFactoryContract.base()
  const queueBase = await queueFactoryContract.base()

  await verifyContract(governBase, [TWO_ADDRR])
  await verifyContract(queueBase, [TWO_ADDRR, dummyConfig])
}
export default func
func.runAtTheEnd = true
func.dependencies = [
  'GovernFactory',
  'GovernQueueFactory',
  'GovernTokenFactory',
  'GovernBaseFactory',
]
func.skip = (hre: HardhatRuntimeEnvironment) =>
  Promise.resolve(
    hre.network.name === 'localhost' ||
      hre.network.name === 'hardhat' ||
      hre.network.name === 'coverage'
  )
