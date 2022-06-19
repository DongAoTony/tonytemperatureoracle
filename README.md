# tonytemperatureoracle
A simple Oracle for temperature.

## 工程准备

1. 本项目是基于Hardhat创建，并实现。所以需要先准备好一个初始的Hardhat工程

```shell
yarn add -D hardhat
yarn hardhat
```

2. 拉取本库文件，拷贝至你刚创建的hardhat工程根目录，并执行以下操作-

- 将工程初始的hardhat.config.js删除，因为我们采用了typeScript的配置文件hardhat.config.ts
- 安装依赖包

```shell
yarn install --non-interactive --frozen-lockfile
```

注：请确认你本地已安装好Node.js V14+的环境。

## 工程验证

1. 编译

```shell
yarn hardhat compile
```

2. 启动本地的hardhat node

```shell
yarn hardhat node
```

基于本地的hardhat node，会方便我们调试，与验证。

3. 部署合约

```shell
yarn hardhat run scripts/deploy-TemperatureOracle.js
yarn hardhat run scripts/deploy-Caller.js
```

部署好这些合约后，我们就可以通过ethers.js来与该temperature Oracle交互了。由于时间有限，这块还没有来得及做。

4. 测试合约，我们还是可以通过测试脚本，来验证合约里相关的逻辑

```shell
yarn hardhat test
```

从测试脚本，我们可以看到，里面已有7个testcase，已涵盖了该简单Oracle合约的主要功能。

5. 基于Dockers镜像来访问与验证该Oracle合约，我们已制作了一个Docker镜像；大家通过该镜像来访问，从而避免各种环境的不一致问题。该Docker镜像地址如下：

```shell
docker.io/dongaomainland/tonytemperatureoracle
```

## 设计说明

1. 采用了调用者合约与Oracle合约相结合的方式来实现逻辑

- 调用者合约Caller.sol，用来接收dApp的关于温度的请求；
- Caller再调用Oracle合约，要求链下Oracle合约上报Temperature;
- Oracle合约收到Caller的请求，发出GetLatestTemperature Event;
- 链下Oracles应监听事件GetLatestTemperature，并采集指定的温度，再调用Oracle合约将该温度值上报；
- Oracle合约将收集到诸Temperature，进行平均并四舍五入，保留两位精度的温度值；并通过Caller的回调更新链上的温度值，更新好后，发出TemperatureUpdated event；
- dApp应监听TemperatureUpdated，以便及时拿到最新的温度值。

2. 温度值统计计算的四舍五入，其中边界0.5的处理与我们日常做法不同：没有入，而是舍了。

注：如果对温度decimal精度要求更加准确，可以考虑采用64 x 64的固定浮点数库。

