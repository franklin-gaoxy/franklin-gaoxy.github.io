# RedAlert

## 快捷键

```
D: 部署/收起
T: 选择当前页面相同兵种
TT: 选择全部相同兵种
Z: 设置路径
Ctrl: 强制攻击
Alt: 强制碾压
Ctrl+Alt: 保护单位
Y: 单位价格/血量 查询 // 按经验值选取部队
U: 按生命值选取
Ctrl+Shift: 移动攻击
X: 分散
空格: 前往最近时间事发地
L: 变卖建筑
F: 功能键
Shift: 一次生产10个
Q: 建筑页面
W: 防御建造页面
E: 人员建造页面
R: 车辆建造页面
K: 修理
H: 回到主基地
```

commandList:
  - name: 1
    mode: order
	hostList: ["node1","node2"]
	execute:
	  command: sh xxx
	  script: xxx.sh
  - name: 2
    mode: parallel
	hostList: ["node1","node2"]
	execute:
	  command: sh xxx
	  script: xxx.sh