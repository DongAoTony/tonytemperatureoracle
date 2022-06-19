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

3. 去中心化考虑：我们将通过多个链下Oracle采集，并求平均来得当前的温度值。
4. 关于上报温度的权限这块，我们引用了openzeppelin的AccessControl，确保只有管理员授权的Oracle角色，才能上报。
5. 关于如何确保没有Oracle进行错误上报，设计里目前只对Oracle的多次上报（重复上报）情形，进行了隔绝。
6. 对于outler的值，我们应对方法目前主要在两点：

- 设置了温度值可接收的上下门限，超过门限的值，将不会纳入统计计算；
- 链下dApp或Oracle，传上链的数据采用范围较小的数据类型，比如int16，而链上承载的数据类型则采用了范围较大的，比如int256，这样可以有效防止因链下的访问，导致链上数值计算的溢出；也就是讲，通过数据类型，也限定了一定outliers。
