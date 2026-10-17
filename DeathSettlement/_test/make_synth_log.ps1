using System.Text

# 生成一份“游戏内插件日志”样本（GBK 编码，格式与真实日志一致），
# 用来端到端验证：外部结算能不能把“伤害来源”补上。
$dir = 'C:\3rd\war5-jass\jass_plugin\魔兽启动器（可启动带japi的地图）\wfe-library-demagewatcher\DeathSettlement\_test'
$path = Join-Path $dir 'plugin_synth.log'
$gbk = [System.Text.Encoding]::GetEncoding(936)

$now = Get-Date
$t1 = $now.ToString('HH:mm:ss.fff')
$t2 = $now.AddMilliseconds(5).ToString('HH:mm:ss.fff')

$lines = @(
  "[$t1] 统计 测试步兵 (hfoo #00105820) 死亡结算: 次数=3 总计=120.0（联合统计 攻击/远程/攻击类型/伤害类型）；开账至今全局伤害事件=9"
  "[$t1]    1/0/3/4: 2 次 / 60.0 60.0 (50.0%)"
  "[$t2]    0/1/5/4: 1 次 / 60.0 60.0 (50.0%)"
  "[$t2] 按来源单位类型（伤害占比）："
  "[$t2]      测试法师 (Hpal #00105830): 2 次 / 60.0 60.0 (50.0%)"
  "[$t2]      测试弓手 (ewsp #00105840): 1 次 / 60.0 60.0 (50.0%)"
  "[$t2] 死亡结算：准备投递，窗口=00000000"
  "[$t1] 统计 测试苦工 (opeo #00105821) 死亡结算: 次数=2 总计=80.0（联合统计 攻击/远程/攻击类型/伤害类型）；开账至今全局伤害事件=9"
  "[$t1]    1/1/3/4: 2 次 / 80.0 80.0 (100.0%)"
  "[$t2] 按来源单位类型（伤害占比）："
  "[$t2]      测试恶魔 (n000 #00105850): 2 次 / 80.0 80.0 (100.0%)"
)
[System.IO.File]::WriteAllText($path, ($lines -join "`r`n") + "`r`n", $gbk)
Write-Output ("已写入 " + $path + "  (" + (Get-Item $path).Length + " bytes, GBK)")
