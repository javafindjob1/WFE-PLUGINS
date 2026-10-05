//==============================================================================
// UDamageWatcherHook.cpp —— 魔兽争霸 III 游戏端插件 DLL（伤害监控 · 显示版）
//==============================================================================
//
// 【它挂在哪里】
//   JAPI（yd_jass_api.dll）在 InitializeEventDamageData() 里做了：
//       replace_pointer( getUnitDamageFunc(), FakeUnitDamageFunc )
//   其中 getUnitDamageFunc() 的返回值被存进 *(uint32_t*)(J+0x928D4)。
//   也就是说：
//       J+0x928D4  = 存放“引擎伤害函数地址”的那个槽的地址
//       J+0x1F830  = JAPI 的 FakeUnitDamageFunc 在 32 位构建里的实际地址
//   我们的做法是把那个槽换成 OurDamageFunc，然后在自己的函数里：
//       ① 先抄快照  ② 调 JAPI 的 FakeUnitDamageFunc 并保存返回值
//       ③ 再做日志/显示（用快照，不再碰引擎内存）
//       ④ 原样返回 JAPI 的返回值
//
// 【为什么必须返回 JAPI 的返回值】
//   JAPI 的 FakeUnitDamageFunc 内部用 std::deque 的 push_back/pop_back 维护
//   g_edd（当前伤害事件栈），EXGetEventDamage / EXSetEventDamage / EXGetEventDamageData
//   都依赖这个栈的平衡。破坏返回值 = 破坏伤害系统。
//
// 【权威依据】YDWE-master 源码：
//   Development\Plugin\Warcraft3\yd_jass_api\EventDamageData.cpp
//   结构体与偏移已用 dumpbin /disasm 在真实 yd_jass_api.dll 上逐条复核（见下）。
//
// 源文件用 UTF-8（无 BOM）保存；日志按系统 ANSI(GBK) 写出，记事本可直接看。
// 编译：cl /nologo /utf-8 /LD /O2 /MT /EHsc /Fe:UDamageWatcher.dll ... /link /SUBSYSTEM:WINDOWS
//
// 【2026-10-02 事故与修复记录】
//   一次用 PowerShell 以 GBK 误读本文件（UTF-8）再写回，导致源码里大量中文损坏。
//   已通过“反向重编码 + 编译错误逐条修复 + 用已编译 DLL 里的字符串字面量回填”还原：
//   代码与所有【玩家可见消息】均已复原并自检通过；仍有部分【注释】里的中文带 〔?〕或 ?，
//   属纯注释性损坏，不影响功能。维护时若看到注释里的乱码，按上下文理解或直接重写即可。
//   教训：不要用 Get-Content -Raw / Set-Content 处理这个 UTF-8 源文件，
//         必须 [System.IO.File]::ReadAllText($p,[Text.Encoding]::UTF8) / WriteAllText。
//==============================================================================

#define _CRT_SECURE_NO_WARNINGS 1

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <intrin.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

//------------------------------------------------------------------------------
// 0. 常量
//------------------------------------------------------------------------------
static const uint32_t JAPI_OFF_DAMAGE_FUNC_SLOT = 0x928D4; // *(uint32_t*) -> 引擎伤害函数
static const uint32_t JAPI_OFF_DAMAGE_FUNC      = 0x1F830; // JAPI 〔?〕FakeUnitDamageFunc
static const uint32_t VTBL_DAMAGE_DONE_SLOT     = 296;     // 0x128，源码里〔?〕+296

// 'Aloc' = 四字符编码的"蝗虫"技能（Locust）〔?〕x416C6F63 = 1097625443
static const int32_t  ABILITY_ID_LOCUST  = 1097625443;
static const uint32_t JASS_UNIT_STATE_LIFE     = 0;  // 当前生命
static const uint32_t JASS_UNIT_STATE_MAXLIFE  = 1;  // 最大生〔?〕

//------------------------------------------------------------------------------
// 1. 权威结构体：引擎伤害记录（照〔?〕EventDamageData.cpp，偏移已二进制复核）
//------------------------------------------------------------------------------
// dumpbin 复核记录（真〔?〕yd_jass_api.dll）：
//   J+0x1F5E0 = EXGetEventDamageData〔?〕
//     case5 -> mov eax,[eax+4]    => info+0x04 = weapon_type     〔?〕与源码一〔?〕
//     case6 -> mov eax,[eax+20h]  => info+0x20 = attack_type     〔?〕与源码一〔?〕
//     case2 -> (info+0x0C >> 8) & 1  => flag bit8 = 是否攻击     〔?〕
//     case3 -> (info+0x0C) & 1       => flag bit0 = 是否远程     〔?〕
//     case0 -> 常量 1；case1 -> *(uint8_t*)(rec+0) 是否物理
//   J+0x1F830 = FakeUnitDamageFunc：ret 10h（ecx + 4 个栈参数），有返回〔?〕
//   J+0x1F770 = FakeUnitDamageDoneFunc：ret 8，读 info+0x10 作为伤害〔?〕
struct war3_event_damage_data {
    uint32_t source_unit;   // +0x00  伤害来源单位（JASS unit 句柄〔?〕
    uint32_t weapon_type;   // +0x04  武器类型（原始数字）
    uint32_t unk2;          // +0x08
    uint32_t flag;          // +0x0C  bit0=是否远程, bit8=是否攻击
    uint32_t amount;        // +0x10  伤害值（JASS real 句柄 〔?〕jass::from_real〔?〕
    uint32_t damage_type;   // +0x14  伤害类型位掩码（〔?〕log2 得类型号〔?〕
    uint32_t unk6;          // +0x18
    uint32_t unk7;          // +0x1C
    uint32_t attack_type;   // +0x20  攻击类型（原始数字）
};

// 快照：进伤害回调时先把需要的字段整份抄下来，之后只读快照
struct DamageSnapshot {
    int      ptrOK;
    uint32_t raw_this;        // ecx 原始值（受伤单位对象〔?〕
    uint32_t raw_edx;
    uint32_t raw_a2;
    uint32_t raw_ptr;         // 〔?〕2 个栈参数（记录指针）
    uint32_t raw_isPhysical;  // 〔?〕3 个栈参数
    uint32_t raw_sourceUnit;  // 〔?〕4 个栈参数
    // --- 〔?〕ptr 抄出来的 ---
    uint32_t source_unit;
    uint32_t weapon_type;
    uint32_t unk2;
    uint32_t flag;
    uint32_t amount_real;     // JASS real 句柄
    uint32_t damage_type;     // 位掩〔?〕
    uint32_t unk6;
    uint32_t unk7;
    uint32_t attack_type;
    // --- 换算结果 ---
    uint32_t target_handle;   // object_to_handle(ecx)
    uint32_t source_obj;      // 来源的【单位对象指针】：栈参〔?〕raw_sourceUnit 优先，否〔?〕ptr->source_unit
    uint32_t source_handle;   // object_to_handle(source_obj)
    float    amount;          // from_real(amount_real)
};

//------------------------------------------------------------------------------
// 2. 配置（UDamageWatcher.ini，与〔?〕DLL 同目录，启动读一次）
//------------------------------------------------------------------------------
struct Config {
    int   enable      = 1;
    int   log_only    = 0;
    // backend：用哪条后端〔?〕伤害事件"（没〔?〕ydbase 的平台联机进程必须用 native〔?〕
    //   0=auto  ：有 ydbase 时走原来〔?〕JAPI 路径；没〔?〕ydbase 则自动改〔?〕native
    //   1=japi  ：强制原路径（进程里没有 ydbase 时按原样中止，什么都不挂〔?〕
    //   2=auto（默认）：有 ydbase 时走原来〔?〕JAPI 路径 —〔?〕**只有这条路会显示到消息区**〔?〕
    //                    没有 ydbase 则自动改〔?〕native（native 用引擎直连，照样上屏）〔?〕
    //   1=japi  ：强制原路径（进程里没有 ydbase 时按原样中止，什么都不挂〔?〕
    //   2=native：强制【引擎直连】直接连 Game.dll，完全不依赖 ydbase
    //             native 模式走引擎直连，屏幕照常显示（v1.3.12 起）〔?〕
    //   注意 ini 缺失时用的是【这里的结构体默认值】（不是刚生成的那份文件），
    //   所以默认值必须和 WriteDefaultIni 里写的一致〔?〕
    // 取值也可写〔?〕auto / japi / native（见 LoadConfig / WriteDefaultIni）〔?〕
    int   backend     = 0;
    // skip_locust 默认【关】：很多自定义图会给普通单位加〔?〕'Aloc'（蝗虫）〔?〕
    // 开着会把正常伤害也一起滤掉。真要滤伤害检测马甲再手动开〔?〕1〔?〕
    int   skip_locust = 0;
    int   filter_zero = 1;
    float min_amount  = 0.0f;
    int   only_related= 0;
    int   throttle_ms = 0;
    // show_hp / show_weapon / show_owner：是否往【伤害明细那一行】后面追〔?〕
    // "武器/生命/拥有〔?〕。v1.3.1 起明细默〔?〕*只显示数〔?〕*
    // （是否攻〔?〕是否远程/攻击类型/伤害类型/伤害值，形如 `1/0/5/4 154.7`），
    // 所以这三个默认〔?〕0；想要旧的长明细就自己打开（会追加在数字后面，必要时自动折行）〔?〕
    int   show_hp     = 0;
    int   show_weapon = 0;
    int   show_owner  = 0;
    int   color       = 1;
    // log_events：是否把【每一次伤害】的原始字段写日志〔?〕
    // 默认 0：开局静默，日志里只有初始〔?〕统计/聊天命令/异常这几类，量很小〔?〕
    // 排错时再开〔?〕1（会按伤害事件数增长）〔?〕
    int   log_events  = 0;
    // log_max_lines：日志文件最多写多少行〔?〕= 不设上限（默认，保证"日志保留完整〔?〕）〔?〕
    // 想限制体积就填正整数（历史上固定 20 万行）；达到上限会写一行说明后停止记录〔?〕
    int   log_max_lines = 0;
    // labels: 0=ASCII（任何字体都能显示）1=中文（默认）。v1.3.18 起：编码判不出来〔?〕*照样出中〔?〕*
    // 注意：这里要〔?〕WriteDefaultIni 里写的默认值保持一致，
    // 否则"ini 不存在、当次生〔?〕的那一局会用另一套默认值（结构体默认值）〔?〕
    int   labels      = 1;
    //   （不再自动退〔?〕ASCII 〔?〕—〔?〕native 下采样永远是 ASCII，那样必然降级成英文标签）〔?〕
    int   encoding    = 0;
    // ---- 聊天命令（动态切换显示模式）----
    int   chat_cmd    = 1;          // 1=启用游戏内聊天命〔?〕
    char  chat_prefix[8] = "@";     // 命令前缀
    // block_cmd：1=拦截 @ 命令，只本地处理、不广播给其他玩家（默认）；0=照旧广播
    int   block_cmd   = 1;
    // 开局默认【静默】：不显示明细、不显示统计，等玩家自己用聊天命令开启〔?〕
    //   0=来源自己 1=来源自己/友方 2=来源敌人 3=关闭（默认，连日志一起停〔?〕
    int   mode        = 3;
    // start_hint=1 时，第一次伤害那一刻提示一〔?〕怎么开〔?〕（默〔?〕0 = 完全不打扰）
    int   start_hint  = 0;
    // track_min_damage：结算记账门槛（v1.3.21 恢复，按用户要求）〔?〕
    //   旧行为（≤v1.3.12）：按单位统计时只统〔?〕大于 5 〔?〕的伤害。后果是玩家〔?〕Ctrl+Alt+R
    //   明确记录的单位，如果是被一堆小伤害耗死的，结算里就只剩最后一笔大伤害
    //   （实测：次数=1 总计=6.9 —〔?〕明显漏账）〔?〕
    //   现在：被记录单位的【每一笔】伤害都进账，死亡结算必定完整〔?〕
    //   〔?〕ini 里若还留着这个键，加载时会被归零（日志里标"已废〔?〕），不影响统计〔?〕
    //   只想少看小额【明细】（屏幕/日志的每笔一行）请用 min_amount〔?〕
    float track_min_damage = 5.0f;      // 小于该值的伤害【不进结算统计】（0 = 全记〔?〕/负伤害永远不计）
    // 热键（Ctrl+Alt+<〔?〕）：完全不经过聊天，所以不会把命令发给其他玩家〔?〕
    //   1/2/3/0 = 切模〔?〕R = 记录当前选中的单〔?〕Q = 看统〔?〕S = 停止结算
    int   hotkeys     = 1;
    // pick: Ctrl+Alt+R/T「记录当前选中的单位」怎么取选区〔?〕
    //   〔?〕联机实测：这条路径会导致平台〔?〕不同〔?〕异常"（WC3 的选区默认不同步，
    //     而且每次按键〔?〕CreateGroup/DestroyGroup 会在本地分配句柄）。所以默认自动规避〔?〕
    //   0=auto（默认）：先用【纯内存读】（联机也安全，不建组、不调选区 native）；
    //                   内存读不可用（游戏版本不符）时才降级：单人局用建组枚举，多人局跳过
    //   1=on  ：总是用建组枚举（旧行为；联机有不同步风险，仅供单〔?〕试验〔?〕
    //   2=off ：总是跳过
    //   3=reuse：用缓存的单个组枚举（只在首次分配一个句柄，用来判断"反复分配句柄"是不是元凶）
    //   4=memory：只用纯内存读，失败即跳过（最保守〔?〕
    int   pick        = 0;
    // filter_side: 模式 0/1/2 按哪一方判〔?〕
    //   0=来源方（默认：看"伤害来源"是谁，
    //   1=目标方（〔?〕挨打的是〔?〕〔?〕
    //   2=任一方（来源或目标任一方满足就显示〔?〕
    int   filter_side = 0;
    // ---- 显示（v1.3.3 定的规则〔?〕---
    //   〔?〕〔?〕JAPI（ydbase 可用〔?〕> 消息区显示；不做任何飘字〔?〕
    //   〔?〕没有 JAPI（native 引擎直连〔?〕> 用引擎直连调同一个显示函数，照样上屏〔?〕
    //   〔?〕明细 / 统计 / 死亡结算一律完整写进日志（与显示无关）〔?〕
    // debug：调试类日志开关（native 解析、D/DN 原始字段、显示确认行、编码判定探针…）〔?〕
    //   默认 0 = 关（日常日志只留：配〔?〕启动结果/每笔明细 H 〔?〕统计与结〔?〕热键与命〔?〕异常）〔?〕
    //   排查问题时再开〔?〕1〔?〕
    int   debug       = 0;
    // v1.4.14：剪贴板相关配置全部删除（clip_utf8_cftext / clip_ascii / clip_text_mode）。
    //   死亡结算文本的中/英样式改由 labels 决定（见 BuildChatLine）。
    int   chat_diag = 0;
    // v1.4.7：死亡总结是否【无框直投】到聊天（默认 1 = 发）。
    //   做法照 hello_direct.c：不开聊天框，直接往编辑框投字 + 用游戏窗口过程发回车。
    //   收件人由 chat_send_target 决定。想不发送就设 0（只写日志）。
    int   chat_on_death = 1;
    // v1.4.0：下面这个延迟只给数据断点自动测试用。
    int   chat_send_delay_ms = 250;
    // v1.4.1：无框直投发消息时的【收件人】
    //   selector 进的是 pSetRecipient 的第 3 个参数（函数内部 [ebp+8] 的 switch）。
    //   映射按 0x98FE28 起字符串常量 + 汇编核对（见 §7.5 直投聊天注释）：
    //     0 = 全部   COLON_MESSAGE_ALL
    //     1 = 盟友   COLON_MESSAGE_ALLIES   ← 队友
    //     2 = 观察者
    int   chat_send_target = 1;
    // chat_marker（v1.3.50）：〔?〕聊天输入框提交入〔?〕用的一次性标记〔?〕
    //   在聊天框里【只输入不发送】这串字符，插件会在内存里扫到它 -> 定位输入框对象与其虚〔?〕->
    //   把虚表方法挂上只读探〔?〕-> 你按回车发送，哪个槽被调到就是提交入口。默认空=不做这件事〔?〕
    char  chat_marker[64] = { 0 };
    // chat_dr（v1.3.54）：用【数据断点】定位聊天提交入口（1=开）。配〔?〕chat_marker 用：
    //   扫到标记缓冲后，把硬件断〔?〕DR0..DR3)架在它头上，你按回车时谁读它就会暴露出来
    //   —〔?〕〔?〕猜输入框对象/虚表"可靠得多。默〔?〕0（只在逆向时开）〔?〕
    int   chat_dr = 0;
    // native_show 已废弃（v1.3.12 去掉了“没 JAPI 就不显示”的约束）：现在**能上屏就上屏**〔?〕
    // native 模式也会用引擎直连把消息发到消息区；只想写日志请〔?〕log_only=1〔?〕
    // （ini 里若还留着 native_show=... 会被忽略，不影响。）
    // ydbase_wait_sec：backend=auto/japi 时，〔?〕ydbase 注入的最长秒数（v1.3.9）〔?〕
    //   默认 10 秒；0 = 根本不等（探一次没有就立刻〔?〕native）〔?〕
    //   以前〔?〕war3.exe 里最长等 6 小时、每 30 秒刷一行日〔?〕，现在没必要了：
    //   没有 ydbase 也能抓伤害、也能上屏（引擎直连）〔?〕
    //   想让平台后注入的 ydbase 也接管，就调大（例如 120）〔?〕
    int   ydbase_wait_sec = 10;
    // native_chain：引擎伤害函数入口被别人挂钩时（WFE 的伤害数〔?〕/ 平台 JAPI 都会先钩它）〔?〕
    //   是否改用【链式挂钩】（v1.3.10）：用唯一〔?〕尾部序言"认出函数 -> 钩别人装上去的处理函〔?〕->
    //   跳板转发回它的原代码。默〔?〕1 = 开（否则遇〔?〕WFE 就什么都抓不到）〔?〕
    //   〔?〕0 = 老行为（入口序言没命中就安全退出、不挂钩）〔?〕
    int   native_chain = 1;
};
static Config g_cfg;

// backend 的取值（ini 里写 auto / japi / native，也可写 0 / 1 / 2〔?〕
#define BACKEND_AUTO   0
#define BACKEND_JAPI   1
#define BACKEND_NATIVE 2

// 运行期显示模式（@0/@1/@2/@3 会改它；初值来〔?〕ini 〔?〕mode〔?〕
//   0=来源自己  1=伤害来源为自〔?〕友方  2=伤害来源为敌〔?〕3=关闭（连日志一起停〔?〕
static volatile LONG g_mode = 0;

//------------------------------------------------------------------------------
// 3. 〔?〕DLL 路径 / 日志
//------------------------------------------------------------------------------
static HMODULE g_hSelf = NULL;
static char    g_dllDir[MAX_PATH] = { 0 };
static char    g_logPath[MAX_PATH] = { 0 };
static char    g_iniPath[MAX_PATH] = { 0 };

static CRITICAL_SECTION g_logLock;
static volatile LONG g_logLockReady = 0;
static volatile LONG g_logLines     = 0;

static volatile LONG g_initState = 0;   // 0=未开〔?〕1=进行〔?〕已完〔?〕

static uint32_t g_japiBase = 0;
static uint32_t g_ydbase   = 0;

// 时间戳（毫秒），用于节流
static DWORD TimeMs() { return GetTickCount(); }

// 前向声明（实现在下面）：把可能是 UTF-8 的字符串转成 ANSI(GBK)〔?〕
// 本文件用 /utf-8 编译，字符串字面量是 UTF-8；但日志/魔兽字符串表〔?〕ANSI〔?〕
// 所以写日志和组消息前都要转一次〔?〕
static void Utf8ToAnsi(const char* src, char* dst, int dstBytes);
static void Utf8ToAnsiTolerant(const char* src, char* dst, int dstBytes);   // v1.3.64 日志用

// v1.3.60：把文本里的【聊天标记】替换成 <标记> —〔?〕防止我们自己的日〔?〕缓冲变成"候选副〔?〕
static void MaskMarker(const char* in, char* out, int outBytes)
{
    if (!out || outBytes <= 0) return;
    out[0] = 0;
    if (!in) return;
    const char* mk = g_cfg.chat_marker;
    const int ml = (int)strlen(mk);
    if (ml <= 2) { strncpy_s(out, (size_t)outBytes, in, _TRUNCATE); return; }
    int o = 0;
    const char* p = in;
    while (*p && o < outBytes - 1) {
        if (p[0] == mk[0] && strncmp(p, mk, (size_t)ml) == 0) {
            const char* rep = "<标记>";
            const int rl = (int)strlen(rep);
            if (o + rl >= outBytes) break;
            memcpy(out + o, rep, (size_t)rl);
            o += rl;
            p += ml;
            continue;
        }
        out[o++] = *p++;
    }
    out[o] = 0;
}

static void LogLine(const char* fmt, ...)
{
    if (!g_logPath[0]) return;

    char body[1024];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf(body, sizeof(body) - 1, fmt, ap);
    body[sizeof(body) - 1] = 0;
    va_end(ap);

    // v1.3.60：日志里【绝不出现标记原文】〔?〕
    //   否则我们自己的日志缓〔?〕文件缓冲/UTF-8→ANSI 转换缓冲里都会有这串标记，〔?〕扫内存找标记"
    //   就会把这些【我们自己的副本】当成候〔?〕—〔?〕实测把整轮逆向都带偏了（调用链里全是我们自己的
    //   LogLine 〔?〕wcslen/WideCharToMultiByte）。这里统一替换掉，从源头断掉自我污染〔?〕
    if (g_cfg.chat_marker[0]) {
        char masked[1024];
        MaskMarker(body, masked, sizeof(masked));
        if (strcmp(masked, body) != 0) strcpy_s(body, sizeof(body), masked);
    }

    // UTF-8 -> ANSI，保证记事本/命令行按 GBK 看是正常中文
    char ansi[1024];
    Utf8ToAnsiTolerant(body, ansi, sizeof(ansi));   // v1.3.64：逐段容错（混 GBK 的行也能正常显示）

    // 行数上限：ini 〔?〕log_max_lines（默〔?〕0 = 不设上限 —〔?〕"日志保留完整〔?〕）〔?〕
    // 想限制日志体积就填一个正整数（历史上固定〔?〕20 万行）〔?〕
    const LONG cap = (LONG)g_cfg.log_max_lines;
    if (cap > 0 && InterlockedIncrement(&g_logLines) > cap) {
        if (g_logLines == cap + 1 && g_logLockReady) {
            EnterCriticalSection(&g_logLock);
            FILE* f = fopen(g_logPath, "ab");
            if (f) { fputs("[watcher] 日志行数达到上限，后续记录被丢弃（把 ini 的 log_max_lines 调大或设 0 表示不限）\r\n", f); fclose(f); }
            LeaveCriticalSection(&g_logLock);
        }
        return;
    }
    if (!g_logLockReady) return;

    EnterCriticalSection(&g_logLock);
    FILE* f = fopen(g_logPath, "ab");
    if (f) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d.%03d] %s\r\n",
                st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, ansi);
        fclose(f);
    }
    LeaveCriticalSection(&g_logLock);
}

//------------------------------------------------------------------------------
// v1.3.91：把游戏内存【原样 dump 到文件】
//
// 为什么需要：游戏是通过 WFE 以【管理员】身份启动的，外面的工具（PowerShell / 调试器）
//   OpenProcess 一律"拒绝访问"——从进程外根本读不到游戏内存。
//   唯一能读的人就是【进程内的我们自己】。所以这里加一个原始 dump：
//   它把"运行时真实地址（每局 ASLR 都不同）"和【模块内偏移】一起写出来，
//   这样离线用 Game.dll / WFEDll.dll 反汇编时可以直接对上。
// 文件：和日志同目录，UDamageWatcher.dump.txt（追加写）
//------------------------------------------------------------------------------
static char g_dumpPath[MAX_PATH] = { 0 };
static int  PrintableStrInline(uint32_t p, char* out, int outBytes, int maxLen);   // 定义在后面
static int  PrintableWStrInline(uint32_t p, char* out, int outBytes, int maxLen); // 定义在后面
static void Wc3ModuleNameOf(uint32_t addr, char* out, int outBytes);              // 定义在后面

static void DumpEnsurePath()
{
    if (g_dumpPath[0] || !g_logPath[0]) return;
    strncpy_s(g_dumpPath, sizeof(g_dumpPath), g_logPath, _TRUNCATE);
    char* dot = strrchr(g_dumpPath, '.');
    if (dot) *dot = 0;
    strncat_s(g_dumpPath, sizeof(g_dumpPath), ".dump.txt", _TRUNCATE);
}

// 追加一行（自动加时间戳 + 标记脱敏，避免我们自己的 dump 里出现标记原文把逆向带偏）
static void DumpText(const char* fmt, ...)
{
    DumpEnsurePath();
    if (!g_dumpPath[0]) return;
    char body[1024];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf(body, sizeof(body) - 1, fmt, ap);
    body[sizeof(body) - 1] = 0;
    va_end(ap);
    if (g_cfg.chat_marker[0]) {
        char masked[1024];
        MaskMarker(body, masked, sizeof(masked));
        if (strcmp(masked, body) != 0) strcpy_s(body, sizeof(body), masked);
    }
    char ansi[1024];
    Utf8ToAnsiTolerant(body, ansi, sizeof(ansi));
    EnterCriticalSection(&g_logLock);
    FILE* f = fopen(g_dumpPath, "ab");
    if (f) {
        SYSTEMTIME st; GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d.%03d] %s\r\n", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, ansi);
        fclose(f);
    }
    LeaveCriticalSection(&g_logLock);
}

// 一个地址属于哪个模块、模块内偏移是多少（离线反汇编的关键）
static void DumpAddrInfo(const char* tag, uint32_t addr)
{
    if (!addr) { DumpText("  %s = 0", tag); return; }
    char nm[64] = { 0 };
    uint32_t mod = 0;
    __try {
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)(uintptr_t)addr, &mbi, sizeof(mbi)) && mbi.AllocationBase)
            mod = (uint32_t)(uintptr_t)mbi.AllocationBase;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    Wc3ModuleNameOf(addr, nm, sizeof(nm));
    DumpText("  %s = %08X  %s+0x%X  (模块基址 %08X)",
             tag, addr, nm[0] ? nm : "?", mod ? (addr - mod) : 0u, mod);
}

// 原始字节 + ASCII 视图 + 每个 dword 的模块归属（找虚表/函数指针一眼可见）
static void DumpHex(const char* tag, uint32_t p, int bytes)
{
    DumpEnsurePath();
    if (!p) { DumpText("%s = 0", tag); return; }
    DumpText("--- %s @ %08X（%d 字节）---", tag, p, bytes);
    for (int i = 0; i < bytes; i += 16) {
        char line[200]; int n = 0;
        char asc[20]; int a = 0;
        for (int j = 0; j < 16 && i + j < bytes; ++j) {
            unsigned char c = 0;
            __try { c = *(const unsigned char*)(uintptr_t)(p + i + j); }
            __except (EXCEPTION_EXECUTE_HANDLER) { c = 0; }
            n += _snprintf_s(line + n, sizeof(line) - n, _TRUNCATE, "%02X ", c);
            asc[a++] = (c >= 0x20 && c < 0x7F) ? (char)c : '.';
        }
        asc[a] = 0;
        DumpText("  %08X  %-48s %s", p + i, line, asc);
    }
}

// 把 dump 区里每个 dword 当指针解释（虚表/函数/字符串一网打尽）
static void DumpPtrFields(const char* tag, uint32_t p, int bytes)
{
    DumpText("--- %s 字段解释 @ %08X ---", tag, p);
    for (int i = 0; i < bytes; i += 4) {
        uint32_t v = 0;
        __try { v = *(const uint32_t*)(uintptr_t)(p + i); }
        __except (EXCEPTION_EXECUTE_HANDLER) { continue; }
        if (v < 0x10000) { DumpText("  +%03X = %08X", i, v); continue; }
        char nm[64] = { 0 };
        uint32_t mod = 0;
        __try {
            MEMORY_BASIC_INFORMATION mbi;
            if (VirtualQuery((LPCVOID)(uintptr_t)v, &mbi, sizeof(mbi)) && mbi.AllocationBase)
                mod = (uint32_t)(uintptr_t)mbi.AllocationBase;
        } __except (EXCEPTION_EXECUTE_HANDLER) { }
        Wc3ModuleNameOf(v, nm, sizeof(nm));
        char s[72] = { 0 };
        if (!PrintableStrInline(v, s, sizeof(s), 48)) PrintableWStrInline(v, s, sizeof(s), 48);
        if (nm[0] && mod) {
            DumpText("  +%03X = %08X -> %s+0x%X%s%s", i, v, nm, v - mod,
                     s[0] ? "  \"" : "", s[0] ? s : "");
        } else {
            DumpText("  +%03X = %08X%s%s", i, v, s[0] ? "  \"" : "", s[0] ? s : "");
        }
    }
}

// 调试类日志：只有 ini 〔?〕debug=1 才写（v1.3.3 加的开关，日常直接关掉）〔?〕
// 用途：native 解析明细、每笔伤害的 D/DN 原始字段、显示确认行、编码判定探针、选区 dump 等〔?〕
// 日常日志只留：配〔?〕/ 启动结果 / 每笔明细 H 〔?〕/ 统计与死亡结〔?〕/ 热键与命〔?〕/ 异常与被吞掉的异常〔?〕
static void LogDebug(const char* fmt, ...)
{
    if (!g_cfg.debug) return;
    char body[1024];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf(body, sizeof(body) - 1, fmt, ap);
    body[sizeof(body) - 1] = 0;
    va_end(ap);
    LogLine("%s", body);
}

// 指针是否可读（VirtualQuery 版，〔?〕IsBadReadPtr 可靠〔?〕
static int Readable(const void* p, size_t n)
{
    if (!p) return 0;
    if ((uint32_t)(uintptr_t)p < 0x10000) return 0;
    MEMORY_BASIC_INFORMATION mbi;
    if (VirtualQuery(p, &mbi, sizeof(mbi)) != sizeof(mbi)) return 0;
    if (mbi.State != MEM_COMMIT) return 0;
    if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return 0;
    const uint8_t* end       = (const uint8_t*)p + n;
    const uint8_t* regionEnd = (const uint8_t*)mbi.BaseAddress + mbi.RegionSize;
    return end <= regionEnd;
}

// 位掩〔?〕-> 类型号（就是 log2；mask=0 时返〔?〕0，与 JAPI 〔?〕damage_type() 一致）
static uint32_t MaskToIndex3(uint32_t mask)
{
    uint32_t n = 0;
    for (; mask; mask >>= 1) ++n;
    return n ? n - 1 : 0;
}

//------------------------------------------------------------------------------
// 4. ydbase.dll 导出（__cdecl，按 mangled 名取〔?〕
//------------------------------------------------------------------------------
typedef uint32_t (__cdecl *fn_replace_pointer_t)(uint32_t target_addr, uint32_t new_value);
typedef uint32_t (__cdecl *fn_create_string_t)(const char* s);
typedef const char* (__cdecl *fn_from_string_t)(uint32_t s);
typedef float    (__cdecl *fn_from_real_t)(uint32_t r);
typedef uint32_t (__cdecl *fn_to_real_t)(float r);
typedef uint32_t (__cdecl *fn_object_to_handle_t)(uintptr_t obj);
typedef uintptr_t(__cdecl *fn_call_t)(const char* name, ...);
typedef const void* (__cdecl *fn_jass_func_t)(const char* name);
// ydbase 的搜索器工具（都〔?〕basic_searcher/war3_searcher 的成员函〔?〕〔?〕__thiscall〔?〕
// 〔?〕__fastcall + dummy edx 等价调用〔?〕
typedef uint32_t (__fastcall *fn_ss_ptr_t)(void* self, void* dummy, const char* str, uint32_t len);
typedef uint32_t (__fastcall *fn_si1_t)(void* self, void* dummy, uint32_t v);
typedef uint32_t (__fastcall *fn_si2_t)(void* self, void* dummy, uint32_t v, uint32_t start);
typedef uint32_t (__fastcall *fn_curfn_t)(void* self, void* dummy, uint32_t addr);
typedef const char* (__cdecl *fn_from_stringid_t)(uint32_t id);

static fn_replace_pointer_t  g_replace_pointer   = NULL;
static fn_create_string_t    g_create_string     = NULL;
static fn_from_string_t      g_from_string       = NULL;
static fn_from_stringid_t    g_from_stringid     = NULL;
static fn_from_real_t        g_from_real         = NULL;
static fn_to_real_t          g_to_real           = NULL;
static fn_object_to_handle_t g_object_to_handle  = NULL;
static fn_call_t             g_call              = NULL;
static fn_jass_func_t        g_jass_func         = NULL;
static fn_ss_ptr_t           g_search_string_ptr = NULL;
static fn_si1_t              g_search_int_in_text1 = NULL;
static fn_si2_t              g_search_int_in_text2 = NULL;
static fn_si1_t              g_search_int_in_rdata = NULL;
static fn_curfn_t            g_current_function  = NULL;

//------------------------------------------------------------------------------
// 4.1 native 后端基座（无 ydbase / 〔?〕JAPI 时直接连 Game.dll〔?〕
//
// 为什么需要它：平台联机进程里**完全没有** JAPI/ydbase〔?〕18 个模块逐个查导〔?〕0 命中），
// 插件原来依赖 ydbase 的搜索器 / jass::call / object_to_handle，于是整局失效〔?〕
// 本节的所有函数只依赖 Game.dll 本身：解〔?〕PE 〔?〕.text、扫序言定位引擎伤害函数〔?〕
// 遍历 native 名表按名字取实现、直读引擎内存做"对象 -> 句柄"
//
// 依据〔?〕WS>\无JAPI模式逆向.md〔?〕.27.0.52240；两〔?〕Game.dll 在本节用到的每个 RVA 上逐字节相同）
//   * 引擎伤害函数 RVA 0x0067DC40〔?〕6 字节序言〔?〕.text 内唯一命中〔?〕〔?〕>1 一律放弃）
//   * native 名表 A 起点 RVA 0x001E9A50，记〔?〕stride 20〔?〕
//       +0 E8 rel32 / +5 68 sigVA / +10 BA nameVA / +15 B9 implVA〔?〕16 处的 imm = 实现 VA〔?〕
//     〔?〕B（RVA 0x006F5D1C）的实现字段全是 0x70A0C0 〔?〕`xor eax,eax; ret` 〔?〕—〔?〕必须丢弃
//   * 对象 -> 句柄 RVA 0x002651D0（__thiscall：ecx=句柄管理器，[esp+4]=对象，[esp+8]=0，ret 8〔?〕
//     函数序言 55 8B EC 51 53 8B 5D 08〔?〕text 内共 147 〔?〕call 命中它；
//     内部 `add eax,0x100000` 〔?〕句柄编码 = 0x100000 + 槽位；纯内存备选见 Wc3Obj2HMem〔?〕
//   * ctx = *(Game.dll + 0xBE4238)；ctx -> 句柄管理〔?〕= RVA 0x001C3200（__thiscall ecx=ctx〔?〕
//     内部就是 `mov eax,[ecx+0x1C]; ret`〔?〕text 〔?〕338 〔?〕call 命中它）〔?〕管理〔?〕= *(ctx+0x1C)
//   * CUnit* + 0x30 = 4 字符类型码（GetUnitTypeId 的实现就〔?〕mov eax,[eax+0x30]; ret）—〔?〕零调〔?〕
//   * RVA 0x001D1550 = JASS Hunit -> CUnit*（序言 55 8B EC 6A FF〔?〕text 〔?〕191 〔?〕call 命中它）
//   * GetLocalPlayer 0x001E3150 / GetPlayerId 0x001E3D20 / GetOwningPlayer 0x001E3BA0
//     GetUnitState 0x001E6600 / GetUnitTypeId 0x001E6670 / IsPlayerAlly 0x001E8040
//     （全〔?〕__cdecl；名字表 A 里也有，所以运行期优先按名字查、RVA 只做校验/兜底〔?〕
//
// 〔?〕重要更正（本次实装时用真〔?〕Game.dll 逐字节复核得出，见《无JAPI后端实装说明.md》）〔?〕
//   《无JAPI模式逆向.md》〔?〕〔?〕辅助函数"表里那几个地址写成了【文件偏移】而不〔?〕RVA
//   （该文件自己说明 file = RVA 〔?〕0xC00）。所以：
//       报告 0x001D0950(Hunit->CUnit*)   -> 〔?〕RVA 0x001D1550〔?〕x1D0950 处是 74 36，函数体内部！）
//       报告 0x001C2600(ctx->句柄管理〔?〕-> 〔?〕RVA 0x001C3200
//       报告 0x002645D0(对象->句柄)      -> 〔?〕RVA 0x002651D0
//   按报告原值调用会跳进函数体中间（0x1D0950 〔?〕`74 36` 条件跳转），会破坏调用者栈 —〔?〕必须用真 RVA〔?〕
//   本节所〔?〕RVA 都带"序言轻校〔?〕，正是为了挡住这一类错误〔?〕
//
// 所〔?〕native 调用统一：解〔?〕+ Readable + 首字节桩校验 + __try + 失败返回 0〔?〕
// 并把"首次解析结果"写一行日志（含基址 + RVA + 校验结论）。任何一步不成立都只〔?〕取不〔?〕〔?〕
// 由上层按原有"取不〔?〕的路径处〔?〕—〔?〕native 模式不会〔?〕JAPI 模式更容易崩〔?〕
//------------------------------------------------------------------------------
static volatile LONG g_nativeMode      = 0;   // 1 = 走引擎直连（本节〔?〕
static uint32_t      g_nativeDmgTarget = 0;   // native 模式下被挂钩的引擎伤害函数地址
static int           g_nativeDmgStolen = 0;   // native 内联钩子偷走的字节数（卸载时还原用）

#define WC3_RVA_CTX_GLOBAL       0x00BE4238u  // ctx = *(Game.dll + 〔?〕RVA)
#define WC3_RVA_DAMAGE_FUNC      0x0067DC40u  // 引擎伤害函数
#define WC3_RVA_NATIVE_TABLE_A   0x001E9A50u  // native 名表 A（真实现〔?〕
#define WC3_RVA_NATIVE_STUB      0x0070A0C0u  // 〔?〕B 的空实现〔?〕
#define WC3_RVA_OBJ_TO_HANDLE    0x002651D0u  // 对象 -> JASS 句柄（★ 不是报告里的 0x2645D0〔?〕
#define WC3_RVA_HANDLE_TO_UNIT   0x001D1550u  // JASS Hunit -> CUnit*（★ 不是报告里的 0x1D0950〔?〕
#define WC3_RVA_HANDLEMGR_FROM_CTX 0x001C3200u // ctx -> 句柄管理器（〔?〕不是报告里的 0x1C2600〔?〕
#define WC3_OFF_CTX_HANDLEMGR    0x0000001Cu  // ctx + 0x1C = 句柄管理器指针（0x1C3200 就是读它〔?〕
#define WC3_OFF_MGR_COUNT        0x00000198u  // 管理〔?〕+ 0x198 = 条目〔?〕* 3
#define WC3_OFF_MGR_TABLE        0x0000019Cu  // 管理〔?〕+ 0x19C = 句柄表基址
#define WC3_OFF_UNIT_TYPECODE    0x00000030u  // CUnit* + 0x30 = 4 字符类型〔?〕
#define WC3_HANDLE_BASE          0x00100000u
#define WC3_HANDLE_LIMIT         0x00200000u

// 三个"不在 native 名表里、只能按 RVA 〔?〕的辅助函数，附带〔?〕3 字节序言（轻校验用）
static const uint8_t kWc3Pro3HandleToUnit[3] = { 0x55, 0x8B, 0xEC };  // push ebp; mov ebp,esp
static const uint8_t kWc3Pro3ObjToHandle[3]  = { 0x55, 0x8B, 0xEC };  // push ebp; mov ebp,esp
static const uint8_t kWc3Pro3MgrFromCtx[3]   = { 0x83, 0x79, 0x1C };  // cmp dword [ecx+0x1C],0

// 16 字节主序言〔?〕text 内必须唯一命中〔?〕
static const uint8_t kWc3DmgPrologue[16] = {
    0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C, 0x56, 0x57,
    0x8B, 0xF9, 0x89, 0x7D, 0xF4, 0x8B, 0x77, 0x5C
};
// 组合特征码（主序言 + 0x85 处；26 字节〔?〕4 个通配）—〔?〕只作复核，不用来定位
static const uint8_t kWc3DmgComboB[26] = {
    0x83, 0xFE, 0x10, 0x74, 0x00,  0x83, 0xFE, 0x20, 0x74, 0x00,
    0x81, 0xFE, 0x00, 0x00, 0x00, 0x04, 0x74, 0x00,
    0x81, 0xFE, 0x00, 0x00, 0x40, 0x00, 0x74, 0x00
};
static const uint8_t kWc3DmgComboBMask[26] = {
    1, 1, 1, 1, 0,  1, 1, 1, 1, 0,
    1, 1, 1, 1, 1, 1, 1, 0,
    1, 1, 1, 1, 1, 1, 1, 0
};

// 安全读（Readable + __try）：失败返回 0，绝不抛
static int Wc3Peek(uint32_t addr, void* out, size_t n)
{
    if (!addr || !out || !n) return 0;
    if (!Readable((const void*)(uintptr_t)addr, n)) return 0;
    __try { memcpy(out, (const void*)(uintptr_t)addr, n); return 1; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}
static int Wc3PeekU32(uint32_t addr, uint32_t* out) { return Wc3Peek(addr, out, 4); }

// JASS real 的【两种形态】（都实测确证，别混）：
//   〔?〕当它作为 native 〔?〕R 参数传时 = **float***（VM 传它自己 real 槽的地址）—〔?〕
//      〔?〕DTTTP(x/y/dur) 〔?〕TextTag(size/pos/vel) 的反汇编：都〔?〕`movss xmm,[ecx]`〔?〕
//   〔?〕当它存在**结构体字〔?〕*里（〔?〕native 的返回值）〔?〕= **float 的位模式本身** —〔?〕
//      ydbase 〔?〕from_real/to_real 就是恒等函数〔?〕
//          from_real(0x11670): fld dword ptr [esp+4] ; ret
//          to_real  (0x11680): mov eax,[esp+4] ; ret
//   所以读引擎伤害结构里的 amount 字段要【按位当 float 用】，不能再解引用 —〔?〕
//   以前〔?〕Wc3RealValue() 解引用，读到的永远是 0（这就是 native 模式"伤害一直是 0.0"的原因）〔?〕
static float Wc3RealBits(uint32_t v)
{
    float f = 0.0f;
    memcpy(&f, &v, 4);
    if (!(f > -1.0e12f && f < 1.0e12f)) return 0.0f;   // NaN/Inf/垃圾 -> 当作取不〔?〕
    return f;
}

// JASS 〔?〕real 作为【参数】时〔?〕指向 float 的指〔?〕：解引用 + 合理性过〔?〕
static float Wc3RealValue(uint32_t h)
{
    if (!h) return 0.0f;
    float v = 0.0f;
    if (!Wc3Peek(h, &v, 4)) return 0.0f;
    if (!(v > -1.0e12f && v < 1.0e12f)) return 0.0f;   // NaN/Inf/垃圾 -> 当作取不〔?〕
    return v;
}

// game.dll 模块基址（大小写不敏感；本进程里没有游戏就返〔?〕0〔?〕
static uint32_t Wc3GameBase()
{
    static volatile LONG s_base   = 0;
    static volatile LONG s_logged = 0;
    LONG v = InterlockedCompareExchange(&s_base, 0, 0);
    if (v) return (uint32_t)v;

    HMODULE m = GetModuleHandleA("Game.dll");
    if (!m) m = GetModuleHandleA("game.dll");
    if (!m) {
        // 模块名大小写/后缀不定时用快照逐个 _stricmp（tlhelp32 已经在用，不引入新依赖）
        HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, GetCurrentProcessId());
        if (snap != INVALID_HANDLE_VALUE) {
            MODULEENTRY32 me;
            me.dwSize = sizeof(me);
            if (Module32First(snap, &me)) {
                do {
                    if (!_stricmp(me.szModule, "Game.dll")) { m = (HMODULE)me.modBaseAddr; break; }
                } while (Module32Next(snap, &me));
            }
            CloseHandle(snap);
        }
    }
    if (!m) {
        if (InterlockedExchange(&s_logged, 1) == 0)
            LogLine("native: 未找到 Game.dll（game.dll）模块——本进程里没有游戏，native 路径不可用");
        return 0;
    }
    const uint32_t base = (uint32_t)(uintptr_t)m;
    if (InterlockedExchange(&s_logged, 1) == 0) {
        char path[MAX_PATH] = { 0 };
        GetModuleFileNameA(m, path, MAX_PATH);
        HANDLE hf = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                                NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        DWORD fsz = 0;
        if (hf != INVALID_HANDLE_VALUE) { fsz = GetFileSize(hf, NULL); CloseHandle(hf); }
        LogLine("native: Game.dll 基址=%08X 文件大小=%u 路径=%s", base, fsz, path);
    }
    InterlockedExchange(&s_base, (LONG)base);
    return base;
}

// 〔?〕SizeOfImage（PE32 可选头 +56）—〔?〕节表解析失败时的兜底范围
static uint32_t Wc3ImageSize(uint32_t base)
{
    if (!base) return 0;
    uint8_t hdr[0x40];
    if (!Wc3Peek(base, hdr, sizeof(hdr))) return 0;
    if (!(hdr[0] == 'M' && hdr[1] == 'Z')) return 0;
    const int32_t e_lfanew = *(const int32_t*)(hdr + 0x3C);
    if (e_lfanew <= 0 || e_lfanew > 0x1000) return 0;
    uint8_t nt[0x60];
    if (!Wc3Peek(base + (uint32_t)e_lfanew, nt, sizeof(nt))) return 0;
    if (*(const uint32_t*)nt != 0x00004550u) return 0;
    return *(const uint32_t*)(nt + 24 + 56);
}

// 解析 PE 〔?〕.text 〔?〕[起始地址, 大小]（思路与上〔?〕ProbeJapiExports 解导出表一致）
// 〔?〕注意：这〔?〕*不能**对整〔?〕.text 〔?〕Readable() —〔?〕Readable() 要求整段落在同一〔?〕
//   VirtualQuery 区域里，而真实加载的映像区域大小/保护位常与节表长度不一致，
//   一旦不等就会整体判定失败（实测踩过：真实游戏里 .text 解析失败 〔?〕native 模式放弃挂钩）〔?〕
//   改为只探第一页，真正的扫描由 Wc3ScanPrologue 分块 + 逐页可读性检查完成〔?〕
static int Wc3TextRange(uint32_t base, uint32_t* outStart, uint32_t* outSize)
{
    if (!base) return 0;
    uint8_t hdr[0x40];
    if (!Wc3Peek(base, hdr, sizeof(hdr))) { LogLine("native(.text): 无 DOS 头失败"); return 0; }
    if (!(hdr[0] == 'M' && hdr[1] == 'Z')) { LogLine("native(.text): 不是 MZ"); return 0; }
    const int32_t e_lfanew = *(const int32_t*)(hdr + 0x3C);
    if (e_lfanew <= 0 || e_lfanew > 0x1000) { LogLine("native(.text): e_lfanew=%d 异常", e_lfanew); return 0; }

    uint8_t nt[0x120];
    if (!Wc3Peek(base + (uint32_t)e_lfanew, nt, sizeof(nt))) { LogLine("native(.text): 无 NT 头失败"); return 0; }
    if (*(const uint32_t*)nt != 0x00004550u) { LogLine("native(.text): PE 签名不符"); return 0; }
    const uint16_t magic = *(const uint16_t*)(nt + 24);
    if (magic != 0x010Bu) { LogLine("native(.text): 不是 PE32（magic=0x%X）", magic); return 0; }
    const uint16_t nSec    = *(const uint16_t*)(nt + 6);
    const uint16_t optSize = *(const uint16_t*)(nt + 20);
    if (!nSec || nSec > 96 || optSize < 96) {
        LogLine("native(.text): 节数=%u 可选头=%u 异常", nSec, optSize);
        return 0;
    }

    const uint32_t secOff = (uint32_t)e_lfanew + 24u + (uint32_t)optSize;
    for (uint16_t i = 0; i < nSec; ++i) {
        uint8_t sec[40];
        if (!Wc3Peek(base + secOff + (uint32_t)i * 40u, sec, sizeof(sec))) {
            LogLine("native(.text): 读第 %u 个节头失败", i);
            return 0;
        }
        char nm[9];
        memcpy(nm, sec, 8);
        nm[8] = 0;
        if (strcmp(nm, ".text") != 0) continue;
        const uint32_t vsize = *(const uint32_t*)(sec + 8);
        const uint32_t rva   = *(const uint32_t*)(sec + 12);
        const uint32_t raw   = *(const uint32_t*)(sec + 16);
        const uint32_t size  = vsize ? vsize : raw;
        if (!rva || !size || size > 0x02000000u) {
            LogLine("native(.text): .text rva=%08X size=%u 异常", rva, size);
            return 0;
        }
        if (!Readable((const void*)(uintptr_t)(base + rva), 16)) {
            LogLine("native(.text): .text 首页不可读（rva=%08X）", rva);
            return 0;
        }
        if (outStart) *outStart = base + rva;
        if (outSize)  *outSize  = size;
        return 1;
    }
    LogLine("native(.text): 没找到 .text 区");
    return 0;
}

// 〔?〕[start, start+size) 里扫 16 字节序言：分块拷〔?〕+ 逐页可读性检〔?〕
// （不依赖节表、也不会因跨〔?〕未映射页面把整次扫描废掉〔?〕
static uint32_t Wc3ScanPrologue(uint32_t start, uint32_t size, int* outHits)
{
    static uint8_t s_buf[0x10000];                 // 64 KB
    int      hits  = 0;
    uint32_t first = 0;
    uint32_t off   = 0;
    while (off + 16u <= size) {
        if (!Readable((const void*)(uintptr_t)(start + off), 16)) {
            off = ((off / 0x1000u) + 1u) * 0x1000u;      // 这一页不可读 -> 跳到下一〔?〕
            continue;
        }
        uint32_t chunk = size - off;
        if (chunk > sizeof(s_buf)) chunk = sizeof(s_buf);
        uint32_t got = 0;
        __try {
            memcpy(s_buf, (const void*)(uintptr_t)(start + off), chunk);
            got = chunk;
        } __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
        if (!got) { off = ((off / 0x1000u) + 1u) * 0x1000u; continue; }

        for (uint32_t i = 0; i + 16u <= got; ++i) {
            if (s_buf[i] != kWc3DmgPrologue[0]) continue;
            if (memcmp(s_buf + i, kWc3DmgPrologue, 16) != 0) continue;
            ++hits;
            if (hits == 1) first = start + off + i;
            if (hits > 1) { if (outHits) *outHits = hits; return first; }
        }
        off += (got >= 16u) ? (got - 15u) : got;         // 允许跨块重叠
    }
    if (outHits) *outHits = hits;
    return first;
}


// 尾部序言（func+6 起的 10 字节）：入口被别人（WFE / 平台 JAPI）挂钩时〔?〕
// 只有〔?〕10 字节还保持原〔?〕〔?〕用它〔?〕认出"引擎伤害函数。实测：全文件唯一命中〔?〕
static int Wc3MatchComboB(uint32_t addr);      // 定义在下面（组合特征码复核用〔?〕
static const uint8_t kWc3DmgTail[10] = {
    0x56, 0x57, 0x8B, 0xF9, 0x89, 0x7D, 0xF4, 0x8B, 0x77, 0x5C
};

// 〔?〕10 字节"尾部序言"（入口被挂钩时用〔?〕
static uint32_t Wc3ScanTail(uint32_t start, uint32_t size, int* outHits)
{
    static uint8_t s_buf2[0x10000];
    int      hits  = 0;
    uint32_t first = 0;
    uint32_t off   = 0;
    while (off + 10u <= size) {
        if (!Readable((const void*)(uintptr_t)(start + off), 10)) {
            off = ((off / 0x1000u) + 1u) * 0x1000u;
            continue;
        }
        uint32_t chunk = size - off;
        if (chunk > sizeof(s_buf2)) chunk = sizeof(s_buf2);
        uint32_t got = 0;
        __try {
            memcpy(s_buf2, (const void*)(uintptr_t)(start + off), chunk);
            got = chunk;
        } __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
        if (!got) { off = ((off / 0x1000u) + 1u) * 0x1000u; continue; }

        for (uint32_t i = 0; i + 10u <= got; ++i) {
            if (s_buf2[i] != kWc3DmgTail[0]) continue;
            if (memcmp(s_buf2 + i, kWc3DmgTail, 10) != 0) continue;
            ++hits;
            if (hits == 1) first = start + off + i;
            if (hits > 1) { if (outHits) *outHits = hits; return first; }
        }
        off += (got >= 10u) ? (got - 9u) : got;
    }
    if (outHits) *outHits = hits;
    return first;
}

// 取某个地址所属模块的文件名（送进 out，失败给空串）。只为日志用〔?〕
static void Wc3ModuleNameOf(uint32_t addr, char* out, int outBytes)
{
    out[0] = 0;
    if (!addr) return;
    MEMORY_BASIC_INFORMATION mbi;
    if (!VirtualQuery((LPCVOID)(uintptr_t)addr, &mbi, sizeof(mbi)) || !mbi.AllocationBase) return;
    char path[MAX_PATH] = { 0 };
    if (!GetModuleFileNameA((HMODULE)mbi.AllocationBase, path, MAX_PATH)) return;
    const char* p = strrchr(path, '\\');
    strncpy_s(out, outBytes, p ? p + 1 : path, _TRUNCATE);
}

// 〔?〕v1.3.13 修：判断地址是否落在【我们自己这〔?〕DLL】里〔?〕
//   旧写法（已删）：if (hookTarget >= selfBase && hookTarget < selfBase + 0x400000) —〔?〕
//   〔?〕基址 + 4MB"当窗口猜。实机踩坑：〔?〕DLL 这次被加载在 WFEDll 的【正下方〔?〕
//     self=5E7B0000，本 DLL 映像=[5E7B0000,5E834000)
//     引擎伤害函数入口 E9 -> 5E8984C0（那〔?〕WFEDll 〔?〕handler，WFEDll 基址 5E840000〔?〕
//   5E8984C0 落在那个 4MB 窗口〔?〕〔?〕被误判成"引擎伤害函数已被我们自己挂钩" 
//   整局直接中止初始化：**伤害抓不到、快捷键也全不生〔?〕*（用户报〔?〕快捷键没效果"）
//   正确做法：用 VirtualQuery 〔?〕AllocationBase〔?〕模块基址）→ 与本模块比；
//   若不同模块，再比模块文件名（这样"同一份 DLL 被两个加载器注入两次"仍然能认出来并让路）〔?〕
static int Wc3AddrInOwnDll(uint32_t addr)
{
    if (!addr || !g_hSelf) return 0;
    MEMORY_BASIC_INFORMATION mbi;
    if (!VirtualQuery((LPCVOID)(uintptr_t)addr, &mbi, sizeof(mbi)) || !mbi.AllocationBase) return 0;
    HMODULE mod = (HMODULE)mbi.AllocationBase;
    if (mod == g_hSelf) return 1;

    char a[MAX_PATH] = { 0 }, b[MAX_PATH] = { 0 };
    if (!GetModuleFileNameA(mod, a, MAX_PATH)) return 0;
    if (!GetModuleFileNameA(g_hSelf, b, MAX_PATH)) return 0;
    const char* na = strrchr(a, '\\'); na = na ? na + 1 : a;
    const char* nb = strrchr(b, '\\'); nb = nb ? nb + 1 : b;
    return _stricmp(na, nb) == 0;
}

// 引擎伤害函数的入口被【别人】挂钩了（WFE 的伤害系〔?〕/ 平台 JAPI 常见）时的定〔?〕+ 链式挂钩方案〔?〕
//   〔?〕用唯一命中〔?〕尾部序言"认出函数（func = 尾部 - 6），再用组合特征码复核；
//   〔?〕读入口那 5 字节跳转，算出【别人装上去的处理函数】地址〔?〕
//   〔?〕我们就去钩【那个处理函数】（而不是硬改入口）—〔?〕
//      引擎 〔?〕别人的跳〔?〕〔?〕我们的钩〔?〕〔?〕跳板执行它原本的头几字节 〔?〕它继续跑〔?〕
//      这样别人的伤害系统（比如 WFE 的伤害数字）照旧工作，我们也拿到事件〔?〕
//   为什么这样安全：别人的处理函数是"替换引擎伤害函数"装上去的，参数布局与引擎一致，
//   而我们的钩子本来就是按那套布局（__fastcall(this, edx, a2, ptr, is_physical, source_unit)）写的〔?〕
// 失败返回 0（什么都不动）〔?〕
static uint32_t Wc3FindDamageFuncChained(uint32_t base, uint32_t* outFunc)
{
    int      hits  = 0;
    uint32_t tail  = 0;
    uint32_t start = 0, size = 0;
    const int haveText = Wc3TextRange(base, &start, &size);

    if (haveText) {
        LogLine("native: 入口序言没命中 -> 改扫“尾部序言”找被挂钩的引擎伤害函数");
        tail = Wc3ScanTail(start, size, &hits);
    }
    if (hits != 1) {
        uint32_t img = Wc3ImageSize(base);
        if (!img || img > 0x02000000u) img = 0x01800000u;
        const uint32_t fstart = base + 0x1000u;
        const uint32_t fsize  = (img > 0x1000u) ? (img - 0x1000u) : img;
        hits = 0;
        tail = Wc3ScanTail(fstart, fsize, &hits);
    }
    if (hits != 1 || !tail) {
        LogLine("native: 尾部序言命中 %d 次（要求恰好 1 次）-> 认不出引擎伤害函数，放弃", hits);
        return 0;
    }

    const uint32_t func = tail - 6u;              // 尾部序言〔?〕func+6
    uint8_t entry[8] = { 0 };
    if (!Wc3Peek(func, entry, sizeof(entry))) { LogLine("native: 函数入口 %08X 不可读，放弃", func); return 0; }

    uint32_t hookTarget = 0;
    if (entry[0] == 0xE9u) {
        const int32_t rel = (int32_t)((uint32_t)entry[1] | ((uint32_t)entry[2] << 8) |
                                      ((uint32_t)entry[3] << 16) | ((uint32_t)entry[4] << 24));
        hookTarget = func + 5u + (uint32_t)rel;
    } else if (entry[0] == 0xEBu) {
        hookTarget = func + 2u + (uint32_t)(int32_t)(int8_t)entry[1];
    } else {
        LogLine("native: 函数 %08X 入口不是跳转%02X %02X %02X %02X …）-> 情况没预料到，放弃",
                func, entry[0], entry[1], entry[2], entry[3]);
        return 0;
    }
    if (!hookTarget || !Readable((const void*)(uintptr_t)hookTarget, 8)) {
        LogLine("native: 入口跳转目标 %08X 不可读，放弃", hookTarget);
        return 0;
    }

    // 安全网：跳转目标真的落在【本 DLL】里（同一〔?〕DLL 被注入两次）时绝不能再钩一次〔?〕
    //   注意：必须用"模块归属"判断，不能拿基址+4MB 〔?〕—〔?〕〔?〕Wc3AddrInOwnDll 的实机踩坑记录〔?〕
    if (Wc3AddrInOwnDll(hookTarget)) {
        LogLine("W native: 引擎伤害函数已被【我们自己】挂钩（目标 %08X 在本 DLL 里；"
                "（DLL 被两个加载器注入两次？）-> 不再挂钩，请只保留一条加载路径"
                "（config.cfg 或 WFE 二选一）", hookTarget);
        return 0;
    }

    char modName[64] = { 0 };
    Wc3ModuleNameOf(hookTarget, modName, sizeof(modName));
    LogLine("native: 引擎伤害函数 = %08X（Game.dll + 0x%X），但入口已被别人改写为 %s 跳转 -> %08X（%s）",
            func, func - base, (entry[0] == 0xE9) ? "E9(近跳)" : "EB(短跳)", hookTarget,
            modName[0] ? modName : "未知模块");
    if (Wc3MatchComboB(func + 0x85))
        LogLine("native: 组合特征码复核（Game.dll + 0x%X）通过 √（确认认对了函数）", (func - base) + 0x85u);
    else
        LogLine("W native: 组合特征码复核（Game.dll + 0x%X）未命中 —— 仅凭唯一尾部序言继续",
                (func - base) + 0x85u);
    LogLine("native: 采用【链式挂钩】：我们钩 %08X（别人装上去的处理函数），引用->它的跳转->我们的钩->"
            "跳板执行它原本的头几字节->它继续跑（它的伤害系统不受影响）", hookTarget);

    if (outFunc) *outFunc = func;
    return hookTarget;
}

// 组合特征码（带通配）比〔?〕
static int Wc3MatchComboB(uint32_t addr)
{
    uint8_t b[sizeof(kWc3DmgComboB)];
    if (!Wc3Peek(addr, b, sizeof(b))) return 0;
    for (size_t i = 0; i < sizeof(b); ++i)
        if (kWc3DmgComboBMask[i] && b[i] != kWc3DmgComboB[i]) return 0;
    return 1;
}

// 〔?〕16 字节序言定位引擎伤害函数；要求唯一命中，否则返〔?〕0（什么都不动〔?〕
// 先用 .text 节表范围；节表解析失败或命中数不对，就用【全映像】再扫一遍兜底〔?〕
static uint32_t Wc3FindDamageFunc(uint32_t base)
{
    int      hits  = 0;
    uint32_t first = 0;
    uint32_t start = 0, size = 0;
    const int haveText = Wc3TextRange(base, &start, &size);

    if (haveText) {
        LogLine("native: .text = %08X 大小 = %u 字节，开始分块扫 16 字节序言", start, size);
        first = Wc3ScanPrologue(start, size, &hits);
    }

    if (hits != 1) {
        // 兜底：不做节表解析，直接扫整个映像（SizeOfImage；取不到就给 24MB 上限〔?〕
        uint32_t img = Wc3ImageSize(base);
        if (!img || img > 0x02000000u) img = 0x01800000u;
        const uint32_t fstart = base + 0x1000u;
        const uint32_t fsize  = (img > 0x1000u) ? (img - 0x1000u) : img;
        LogLine("native: .text 扫描结果命中 %d 次（需要恰好 1 次），改用全映像扫描 %08X 大小 %u",
                hits, fstart, fsize);
        hits  = 0;
        first = Wc3ScanPrologue(fstart, fsize, &hits);
    }

    if (hits != 1) {
        LogLine("native: 引擎伤害函数序言命中 %d 次（要求恰好 1 次），"
                "为安全起见不动任何东西，安全退出", hits);
        return 0;
    }
    LogLine("native: 引擎伤害函数 = %08X（Game.dll + 0x%X，序言命中唯一 √）",
            first, first - base);
    if (Wc3MatchComboB(first + 0x85))
        LogLine("native: 组合特征码复核（Game.dll + 0x%X）通过 √", (first - base) + 0x85u);
    else
        LogLine("W native: 组合特征码复核（Game.dll + 0x%X）未命中 ——仅凭唯一的 16 字节序言继续",
                (first - base) + 0x85u);
    return first;
}


// native 名表 A：按名字查实现地址（stride 20，逐条校验 4 〔?〕opcode 模板；跳过表 B 的桩〔?〕
static uint32_t Wc3NativeByName(const char* name)
{
    uint32_t base = Wc3GameBase();
    if (!base || !name || !name[0]) return 0;

    const uint8_t* rec = (const uint8_t*)(uintptr_t)(base + WC3_RVA_NATIVE_TABLE_A);
    for (int i = 0; i < 2048; ++i, rec += 20) {
        uint8_t hdr[20];
        if (!Wc3Peek((uint32_t)(uintptr_t)rec, hdr, sizeof(hdr))) break;
        if (!(hdr[0] == 0xE8 && hdr[5] == 0x68 && hdr[10] == 0xBA && hdr[15] == 0xB9)) break;

        uint32_t nameVA = 0, implVA = 0;
        memcpy(&nameVA, hdr + 11, 4);
        memcpy(&implVA, hdr + 16, 4);
        if (implVA == base + WC3_RVA_NATIVE_STUB) continue;          // 〔?〕B 的空实现〔?〕
        if (nameVA < base || nameVA > base + 0x00C00000u) continue;  // 名字串必须在本模块内
        if (!Readable((const void*)(uintptr_t)nameVA, 2)) continue;

        size_t k = 0;
        for (; k < 63; ++k) {
            char c = 0;
            if (!Wc3Peek(nameVA + (uint32_t)k, &c, 1)) break;
            if (c != name[k]) break;
            if (c == 0) return implVA;                               // 逐字符相等且都以 0 结束
        }
    }
    return 0;
}

// 解析结论的统一日志行：基址 + RVA + 期望 RVA + 序言 + 校验结论
static void Wc3LogResolved(const char* label, uint32_t addr, uint32_t base,
                           uint32_t expectRva, const char* how, const uint8_t* p)
{
    const uint32_t gotRva = addr - base;
    const int rvaOK = (!expectRva || gotRva == expectRva);
    LogDebug("native 解析：%-22s = %08X（base %08X + RVA 0x%06X；期望 0x%06X %s；来源 %s）"
            "序言 %02X %02X %02X %02X）校验=%s",
            label, addr, base, gotRva, expectRva, rvaOK ? "一致" : "不一致", how,
            p[0], p[1], p[2], p[3], rvaOK ? "OK" : "WARN(按解析结果使用)");
}

// 可读 + 非桩 + 序言 检查通过后写日志并缓存〔?〕
// pro3（可空）= 期望的首 3 字节序言（按 RVA 取的辅助函数必带 —〔?〕这正是为了挡〔?〕
// "把文件偏移当 RVA" 这类错误：地址落在函数体中间时首字节不会是标准序言）〔?〕
static uint32_t Wc3CheckRvaTarget(const char* label, uint32_t addr, uint32_t base,
                                  uint32_t expectRva, const char* how, uint32_t* cache,
                                  const uint8_t* pro3)
{
    uint8_t p[4] = { 0, 0, 0, 0 };
    if (!Wc3Peek(addr, p, sizeof(p))) {
        LogLine("native 解析：%s = %08X 不可读 -> 放弃", label, addr);
        return 0;
    }
    if (p[0] == 0x33 && p[1] == 0xC0 && p[2] == 0xC3) {
        LogLine("native 解析：%s = %08X 是空实现（33 C0 C3）-> 放弃", label, addr);
        return 0;
    }
    if (pro3 && (p[0] != pro3[0] || p[1] != pro3[1] || p[2] != pro3[2])) {
        LogLine("native 解析：%s = %08X 序言 %02X %02X %02X 与期望 %02X %02X %02X 不符"
                "（地址可能落在函数体中间）-> 放弃",
                label, addr, p[0], p[1], p[2], pro3[0], pro3[1], pro3[2]);
        return 0;
    }
    Wc3LogResolved(label, addr, base, expectRva, how, p);
    if (cache) *cache = addr;
    return addr;
}

// 解析一〔?〕native：优先按名字查表 A（版本自适应），失败才用报告里确证的 RVA 兜底
static uint32_t Wc3ResolveNative(const char* label, const char* tableName,
                                 uint32_t expectRva, uint32_t* cache,
                                 const uint8_t* pro3 = NULL)
{
    if (cache && *cache) return *cache;
    uint32_t base = Wc3GameBase();
    if (!base) return 0;

    uint32_t addr = tableName ? Wc3NativeByName(tableName) : 0;
    const char* how = "名表A";
    if (!addr) {
        if (!expectRva) { LogLine("native 解析：%s 名表里没有、也没有 RVA 兜底 -> 放弃", label); return 0; }
        addr = base + expectRva;
        how = "RVA兜底";
    }
    return Wc3CheckRvaTarget(label, addr, base, expectRva, how, cache, pro3);
}

// ---- 字符串表：id 反查正文 / 名字（无 ydbase 〔?〕取真〔?〕的关键）----
// * 反查正文：RVA 0x1C2870 —〔?〕__thiscall：ECX = ctx、[esp+4] = id、`ret 4`，返〔?〕char*（失〔?〕0）〔?〕
//   正文〔?〕[条目+0x18]，表〔?〕[ctx+0x20]；ctx = *(Game.dll + 0xBE4238)〔?〕JASS ctx 全局）〔?〕
// * 名字：GetUnitName(0x1E6340) / GetPlayerName(0x1E3D40) 都返回【字符串 id】，
//   再用上面那条反查〔?〕char*（引擎的 native 返回值本来就〔?〕id，这〔?〕传参"是两码事）〔?〕
// * 〔?〕id：RVA 0x1DA520（const char* -> 字符〔?〕id）〔?〕*本插件不再使〔?〕*（改〔?〕B 计划时试过，
//   后来发现 native 〔?〕`S` 参数要的〔?〕字符串对象指〔?〕、不〔?〕id；而显示现在只〔?〕JAPI 路径做）〔?〕
//   这里保留 RVA 与序言只作逆向记录〔?〕
#define WC3_RVA_MAKE_STRING_ID  0x001DA520u  // const char* -> 字符〔?〕id（__fastcall, ecx）——显示不〔?〕
#define WC3_RVA_STRING_BY_ID    0x001C2870u  // ctx + id -> char*（__thiscall, ret 4〔?〕
#define WC3_RVA_DTTTP           0x001DFE70u  // DisplayTimedTextToPlayer（__cdecl）——B 计划后不再调〔?〕
#define WC3_RVA_GET_UNIT_NAME   0x001E6340u  // GetUnitName（__cdecl, 返回字符〔?〕id〔?〕
#define WC3_RVA_GET_PLAYER_NAME 0x001E3D40u  // GetPlayerName（__cdecl, 返回字符〔?〕id〔?〕
// ★★ v1.3.19〔?〕字符〔?〕-> 名字 char*〔?〕*引擎 GetUnitName / GetObjectName 内部用的就是〔?〕*〔?〕
//   RVA 0x326BA0；调用约〔?〕__fastcall：ECX = 4 字符码、EDX = 0（就〔?〕取第 0 〔?〕），返回 char*〔?〕
//   证据（反汇编 _build/watcher/an_getunitname.txt / an_getobjname.txt）：
//     GetUnitName(0x1E6340): mov ecx,[CUnit+0x30] ; xor edx,edx ; call 0x326BA0 ; mov ecx,eax
//                            ; jmp 0x1DA520（char* -> 字符〔?〕id〔?〕
//     GetObjectName(0x1E34A0): mov ecx,[ebp+8]     ; xor edx,edx ; call 0x326BA0
//                            ; cmp byte ptr [eax],0  〔?〕直接〔?〕char* 解引用（空串则返〔?〕0〔?〕
//                            ; mov ecx,eax ; jmp 0x1DA520
//   〔?〕返回值就是【单位名正文〔?〕char*】，**不需要字符串表反〔?〕*（那条路在本机一直不通，
//     所〔?〕native 下名字一直退化成 4 字符码）。这正是"4 字符〔?〕-> 真正的名〔?〕缺的那一环〔?〕
#define WC3_RVA_OBJ_NAME_BY_ID  0x00326BA0u
// 序言：push esi / mov esi,edx / mov edx,imm32（后 4 字节是重定位过的静态表地址，不比对〔?〕
static const uint8_t kWc3Pro3ObjName[3] = { 0x56, 0x8B, 0xF2 };

static const uint8_t kWc3Pro3MakeStrId[3] = { 0x85, 0xC9, 0x75 };  // test ecx,ecx; jne
static const uint8_t kWc3Pro3StrById[3]   = { 0x55, 0x8B, 0xEC };  // push ebp; mov ebp,esp

static uint32_t g_natStringById    = 0;
static uint32_t g_natGetUnitName   = 0;
static uint32_t g_natGetPlayerName = 0;
static uint32_t g_natObjNameById   = 0;      // RVA 0x326BA0〔?〕字符〔?〕-> 名字 char*〔?〕

// 〔?〕v1.3.19〔?〕字符〔?〕-> 名字正文（引〔?〕GetUnitName 内部走的就是这条；返〔?〕NULL = 取不到）
//   返回的指针指向游戏静态数据（类型表），调用方请立刻拷走（GetUnitLabel 〔?〕SafeCopyAnsi）〔?〕
static const char* Wc3NameByRawcode(uint32_t rawcode)
{
    if (!rawcode) return NULL;
    const uint32_t base = Wc3GameBase();
    if (!base) return NULL;
    if (!g_natObjNameById)
        Wc3ResolveNative("obj_name_by_id", NULL, WC3_RVA_OBJ_NAME_BY_ID,
                         &g_natObjNameById, kWc3Pro3ObjName);
    if (!g_natObjNameById) return NULL;

    const char* p = NULL;
    __try {
        p = ((const char* (__fastcall*)(uint32_t, uint32_t))(uintptr_t)g_natObjNameById)(rawcode, 0);
    } __except (EXCEPTION_EXECUTE_HANDLER) { p = NULL; }

    // 防盗：必须可读、非空、像一〔?〕看得见的文本"（否则宁可退〔?〕4 字符码，也不往屏幕上送垃圾）
    if (!p || !Readable(p, 2) || !p[0]) return NULL;
    if ((unsigned char)p[0] < 0x20) return NULL;
    {
        int n = 0;
        for (; n < 64; ++n) {
            const unsigned char c = (unsigned char)p[n];
            if (c == 0) break;
            if (c < 0x20 || c == 0x7F) return NULL;      // 控制字符 -> 不是名字正文
        }
        if (n == 0 || n >= 64) return NULL;              // 空串 / 64 字节还没结束 -> 放弃
    }
    return p;
}

// 游戏线程号：第一次伤害事件（引擎代码里）记下来。native 的字符串表调用只在游戏线程做〔?〕
// 所以这里提前声明（原来声明〔?〕7.8 节，离得太远，native 助手要用）〔?〕
static volatile LONG g_gameThreadId = 0;

// 只在游戏线程动引擎字符串表（伤害钩子本来就在游戏线程；热键是回投到游戏线程执行）
static int Wc3OnGameThread()
{
    const LONG t = g_gameThreadId;
    if (!t) return 1;                       // 还没记录过游戏线程（第一次伤害之前）〔?〕不拦
    return ((LONG)GetCurrentThreadId() == t);
}

// 若目标首字节〔?〕E9/EB（已被别〔?〕Detour / 是跳板），跟随跳转取真实现（最〔?〕4 跳）〔?〕
// 为什么必须做：实测在装了 JAPI 的进程里，DisplayTimedTextToPlayer 的开头是 `E9 …`〔?〕
// 直接调那个跳板会跳进非法地址 〔?〕C0000005（当〔?〕4 种参数形态全异常就是这个原因）〔?〕
static uint32_t Wc3FollowJumps(uint32_t addr, const char* tag)
{
    for (int i = 0; i < 4 && addr; ++i) {
        uint8_t b[5] = { 0 };
        if (!Wc3Peek(addr, b, 5)) break;
        if (b[0] == 0xE9u) {
            const uint32_t t = addr + 5u + *(const uint32_t*)(b + 1);
            LogDebug("native(%s): 目标 %08X 已被挂钩(E9)，跟随第 %d 跳到 %08X", tag, addr, i + 1, t);
            addr = t;
            continue;
        }
        if (b[0] == 0xEBu) {
            const uint32_t t = addr + 2u + (uint32_t)(int32_t)(int8_t)b[1];
            LogDebug("native(%s): 目标 %08X 已被挂钩(EB)，跟随第 %d 跳到 %08X", tag, addr, i + 1, t);
            addr = t;
            continue;
        }
        break;
    }
    return addr;
}

// 字符〔?〕id -> char*〔?〕
//   ①先问引擎自己的解析器（RVA 0x1C2870，走 [ctx+0x20] 容器）；
//   ②不行再直接查【运行期字符串表】（VM + 0x2874 〔?〕string_fasttable，步〔?〕0x10，条〔?〕+0x1C = char*〔?〕
//     —〔?〕这一条与 JAPI 路径〔?〕RuntimeStringById 等价，只是不〔?〕ydbase 〔?〕get_jass_vm/from_string〔?〕
//   实测：显示用〔?〕id 〔?〕①造出来的，但 ①对自己造的运行期字符串反查不回（它看的是标识符表）〔?〕
//   必须〔?〕②才能拿到正〔?〕—〔?〕这也解释〔?〕〔?〕id 成功但反查为 NULL"
static const char* Wc3StringByIdRuntime(uint32_t id)
{
    if (!id) return NULL;
    const uint32_t base = Wc3GameBase();
    if (!base) return NULL;
    uint32_t vm = 0;
    if (!Wc3PeekU32(base + WC3_RVA_CTX_GLOBAL, &vm) || !vm) return NULL;
    __try {
        uint32_t st = 0;
        if (!Wc3PeekU32(vm + 0x2874, &st) || !st) return NULL;
        uint32_t maxSize = 0, array = 0;
        if (!Wc3PeekU32(st + 4, &maxSize)) return NULL;
        if (!Wc3PeekU32(st + 8, &array)) return NULL;
        if (!array || id >= maxSize) return NULL;
        uint32_t entry = 0;
        if (!Wc3PeekU32(array + 0x10u * id, &entry) || !entry) return NULL;
        uint32_t p = 0;
        if (!Wc3PeekU32(entry + 0x1C, &p) || !p) return NULL;
        if (!Readable((const void*)(uintptr_t)p, 2)) return NULL;
        return (const char*)(uintptr_t)p;
    } __except (EXCEPTION_EXECUTE_HANDLER) { return NULL; }
}

// 字符〔?〕id -> char*（引擎解析器 RVA 0x1C2870）；失败返回 NULL
static const char* Wc3StringById(uint32_t id)
{
    if (!id) return NULL;
    const uint32_t base = Wc3GameBase();
    if (!base) return NULL;
    uint32_t ctx = 0;
    if (!Wc3PeekU32(base + WC3_RVA_CTX_GLOBAL, &ctx) || !ctx) return NULL;
    if (!g_natStringById)
        Wc3ResolveNative("string_by_id", NULL, WC3_RVA_STRING_BY_ID,
                         &g_natStringById, kWc3Pro3StrById);
    if (g_natStringById) {
        const char* p = NULL;
        __try {
            const uint32_t r = ((uint32_t (__fastcall*)(uint32_t, void*, uint32_t))(uintptr_t)g_natStringById)
                                   (ctx, NULL, id);
            if (r && Readable((const void*)(uintptr_t)r, 2)) p = (const char*)(uintptr_t)r;
        } __except (EXCEPTION_EXECUTE_HANDLER) { p = NULL; }
        if (p) return p;
    }
    return Wc3StringByIdRuntime(id);          // 兜底（实测这条才是对的那条）
}


// 字符〔?〕id -> char*（引擎解析器 RVA 0x1C2870）；失败返回 NULL
static uint32_t g_natGetLocalPlayer  = 0;
static uint32_t g_natGetPlayerId     = 0;
static uint32_t g_natGetOwningPlayer = 0;
static uint32_t g_natIsPlayerAlly    = 0;
static uint32_t g_natGetUnitState    = 0;
static uint32_t g_natGetUnitTypeId   = 0;
static uint32_t g_natHandleToUnit    = 0;
static uint32_t g_natObjToHandle     = 0;
static uint32_t g_natMgrFromCtx      = 0;

// 预热：把本阶段要用的 native 全部解析一遍（每个函数一行日志，便于对着日志排查〔?〕
static void Wc3PrepareNatives()
{
    Wc3ResolveNative("GetLocalPlayer",  "GetLocalPlayer",  0x001E3150u, &g_natGetLocalPlayer);
    Wc3ResolveNative("GetPlayerId",     "GetPlayerId",     0x001E3D20u, &g_natGetPlayerId);
    Wc3ResolveNative("GetOwningPlayer", "GetOwningPlayer", 0x001E3BA0u, &g_natGetOwningPlayer);
    Wc3ResolveNative("IsPlayerAlly",    "IsPlayerAlly",    0x001E8040u, &g_natIsPlayerAlly);
    Wc3ResolveNative("GetUnitState",    "GetUnitState",    0x001E6600u, &g_natGetUnitState);
    Wc3ResolveNative("GetUnitTypeId",   "GetUnitTypeId",   0x001E6670u, &g_natGetUnitTypeId);
    // 上屏用不〔?〕native 〔?〕DTTTP：显示只〔?〕JAPI 路径做（native 模式不显示，〔?〕§7）〔?〕
    Wc3ResolveNative("GetUnitName",     "GetUnitName",     0x001E6340u, &g_natGetUnitName);
    Wc3ResolveNative("GetPlayerName",   "GetPlayerName",   0x001E3D40u, &g_natGetPlayerName);
    // 字符串表：id 反查正文 —〔?〕不在名表里，只有 RVA（带序言轻校验）
    Wc3ResolveNative("string_by_id",    NULL, WC3_RVA_STRING_BY_ID,
                     &g_natStringById,    kWc3Pro3StrById);
    // 下面三个也不〔?〕native 名表里，只有 RVA（由引擎自身的调用点反汇编确证；带序言轻校验）
    Wc3ResolveNative("Hunit->CUnit*",   NULL, WC3_RVA_HANDLE_TO_UNIT,
                     &g_natHandleToUnit, kWc3Pro3HandleToUnit);
    Wc3ResolveNative("obj->handle",     NULL, WC3_RVA_OBJ_TO_HANDLE,
                     &g_natObjToHandle,  kWc3Pro3ObjToHandle);
    Wc3ResolveNative("ctx->handlemgr",  NULL, WC3_RVA_HANDLEMGR_FROM_CTX,
                     &g_natMgrFromCtx,   kWc3Pro3MgrFromCtx);
}

static uint32_t Wc3GetLocalPlayer()
{
    uint32_t fn = Wc3ResolveNative("GetLocalPlayer", "GetLocalPlayer", 0x001E3150u, &g_natGetLocalPlayer);
    if (!fn) return 0;
    uint32_t r = 0;
    __try { r = ((uint32_t (__cdecl*)(void))(uintptr_t)fn)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    return r;
}

static uint32_t Wc3GetPlayerId(uint32_t hplayer)
{
    if (!hplayer) return 0;
    uint32_t fn = Wc3ResolveNative("GetPlayerId", "GetPlayerId", 0x001E3D20u, &g_natGetPlayerId);
    if (!fn) return 0;
    uint32_t r = 0;
    __try { r = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)fn)(hplayer); }
    __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    return r;
}

static uint32_t Wc3GetOwningPlayer(uint32_t hunit)
{
    if (!hunit) return 0;
    uint32_t fn = Wc3ResolveNative("GetOwningPlayer", "GetOwningPlayer", 0x001E3BA0u, &g_natGetOwningPlayer);
    if (!fn) return 0;
    uint32_t r = 0;
    __try { r = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)fn)(hunit); }
    __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    return r;
}

static uint32_t Wc3IsPlayerAlly(uint32_t a, uint32_t b)
{
    if (!a || !b) return 0;
    uint32_t fn = Wc3ResolveNative("IsPlayerAlly", "IsPlayerAlly", 0x001E8040u, &g_natIsPlayerAlly);
    if (!fn) return 0;
    uint32_t r = 0;
    __try { r = ((uint32_t (__cdecl*)(uint32_t, uint32_t))(uintptr_t)fn)(a, b); }
    __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    return r;
}

// v1.3.70：**Hgroup -> CGroup* 也走这个访问器** —— 反汇编 FirstOfGroup(RVA 0x1E0850) 第一句
//   就是 `mov ecx,[ebp+8] / call 0x1CFB10` 拿 CGroup*，而 0x1CFB10 与下面这条（Hunit 版）
//   同为"句柄管理器按槽位取对象"的薄封装（引擎各处都这么用，338 处 call 命中它）。
//   所以取组对象时直接复用它，不再单独申请一个 RVA（少一个可能搞错的地址）。
// 原注：JASS Hunit -> CUnit*（RVA 0x1D1550，__thiscall: ecx=句柄 〔?〕__fastcall + 〔?〕edx 等价调用〔?〕
static uint32_t Wc3HandleToUnit(uint32_t handle)
{
    if (!handle) return 0;
    if (!g_natHandleToUnit)
        Wc3ResolveNative("Hunit->CUnit*", NULL, WC3_RVA_HANDLE_TO_UNIT,
                         &g_natHandleToUnit, kWc3Pro3HandleToUnit);
    if (!g_natHandleToUnit) return 0;
    uint32_t obj = 0;
    __try { obj = ((uint32_t (__fastcall*)(uint32_t, void*))(uintptr_t)g_natHandleToUnit)(handle, NULL); }
    __except (EXCEPTION_EXECUTE_HANDLER) { obj = 0; }
    return obj;
}

// 单位状态（GetUnitState，__cdecl(Hunit, index) -> **float 位模〔?〕*）：见下面的实机纠错
static float Wc3GetUnitStateValue(uint32_t hunit, uint32_t which)
{
    if (!hunit) return 0.0f;
    uint32_t fn = Wc3ResolveNative("GetUnitState", "GetUnitState", 0x001E6600u, &g_natGetUnitState);
    if (!fn) return 0.0f;
    uint32_t r = 0;
    __try { r = ((uint32_t (__cdecl*)(uint32_t, uint32_t))(uintptr_t)fn)(hunit, which); }
    __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    // ⚠⚠ v1.3.13 实机纠错：引擎的 GetUnitState（RVA 0x1E6600）在状〔?〕0..3 时是
    //     `call CUnit::GetState ; mov eax,[eax]` —〔?〕**返回值就〔?〕float 的位模式**〔?〕
    //     不是 JASS real 句柄！（反汇编见 _build/watcher/an_gus2.txt〔?〕
    //   旧代码按 real 解引用（Wc3RealValue）→ 永远读不〔?〕〔?〕0.0 〔?〕
    //     〔?〕日志〔?〕生命:0.0/0.0"、拥有〔?〕名字也全废；
    //     〔?〕更致命：死亡判定 `hp <= 0` 恒成〔?〕〔?〕第一次受伤就误判死亡 + 结算〔?〕
    //        并把该单位标〔?〕dead，之后每一笔伤害都被当"尸体挨打"丢掉
    //        〔?〕表现就是"死亡结算只统计到一次伤〔?〕〔?〕
    const float v = Wc3RealBits(r);
    // 头几次把"原始返回〔?〕+ 按位模式解释的结〔?〕写日志，单机上一步就能验证这一步对不对
    static volatile LONG s_dbg = 0;
    if (InterlockedIncrement(&s_dbg) <= 4)
        LogDebug("native GetUnitState(%08X, %u) = bits %08X -> %.2f", hunit, which, r, v);
    return v;
}

// 类型码：优先零调用直〔?〕CUnit*+0x30（GetUnitTypeId 的实现就是这么干的），失败才〔?〕native
static uint32_t Wc3UnitTypeCode(uint32_t handle)
{
    if (!handle) return 0;
    uint32_t obj = Wc3HandleToUnit(handle);
    if (obj) {
        uint32_t t = 0;
        if (Wc3PeekU32(obj + WC3_OFF_UNIT_TYPECODE, &t) && t) return t;
    }
    uint32_t fn = Wc3ResolveNative("GetUnitTypeId", "GetUnitTypeId", 0x001E6670u, &g_natGetUnitTypeId);
    if (!fn) return 0;
    uint32_t r = 0;
    __try { r = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)fn)(handle); }
    __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    return r;
}

// ---- 对象 -> JASS 句柄 ----
// 引擎原生转换〔?〕RVA 0x2651D0：序言 55 8B EC 51 53 8B 5D 08（push ebp / mov ebp,esp /
// push ecx / push ebx / mov ebx,[ebp+8] / push esi / push edi / mov edi,ecx）⇒
// __thiscall + 2 个栈参数（ret 8）⇒ 〔?〕__fastcall(ecx=mgr, edx=〔?〕对象, 0) 等价调用（同现有代码的写法）〔?〕
// 句柄管理器两种取法都试（〔?〕引擎访问〔?〕RVA 0x1C3200 〔?〕纯内〔?〕*(ctx+0x1C)），
// 并用【句柄回程校验】（handle -> CUnit* 必须等于原对象）挑出正确的那个；挑不出就返回 0〔?〕
static int      g_nativeMgrWhich     = -1;   // -1=未定 0=纯内〔?〕1=引擎访问〔?〕2=放弃
static int      g_nativeUseMemory    = 0;    // 1=调用路线失败，改用纯内存扫描
static volatile LONG g_nativeObj2HTries = 0;
static volatile LONG g_nativeObj2HLog   = 0;

static uint32_t Wc3HandleMgrFromCtx(uint32_t ctx, int which)
{
    if (!ctx) return 0;
    if (which == 0) {
        // 纯内存等价物：管理器指针就在 ctx+0x1C
        // （引擎访问器 RVA 0x1C3200 的正文就〔?〕`mov eax,[ecx+0x1C]; ret`，只是多了按需创建的分支）
        uint32_t v = 0;
        return Wc3PeekU32(ctx + WC3_OFF_CTX_HANDLEMGR, &v) ? v : 0;
    }
    // 引擎自己的访问器（__thiscall ecx=ctx，无栈参数；GetLocalPlayer/GetOwningPlayer 都这么取〔?〕
    if (!g_natMgrFromCtx)
        Wc3ResolveNative("ctx->handlemgr", NULL, WC3_RVA_HANDLEMGR_FROM_CTX,
                         &g_natMgrFromCtx, kWc3Pro3MgrFromCtx);
    if (!g_natMgrFromCtx) return 0;
    uint32_t mgr = 0;
    __try { mgr = ((uint32_t (__fastcall*)(uint32_t, void*))(uintptr_t)g_natMgrFromCtx)(ctx, NULL); }
    __except (EXCEPTION_EXECUTE_HANDLER) { mgr = 0; }
    return mgr;
}

static uint32_t Wc3Obj2HCall(uint32_t mgr, uint32_t obj)
{
    if (!mgr || !obj) return 0;
    if (!g_natObjToHandle)
        Wc3ResolveNative("obj->handle", NULL, WC3_RVA_OBJ_TO_HANDLE,
                         &g_natObjToHandle, kWc3Pro3ObjToHandle);
    if (!g_natObjToHandle) return 0;
    uint32_t h = 0;
    __try {
        h = ((uint32_t (__fastcall*)(uint32_t, void*, uint32_t, uint32_t))(uintptr_t)g_natObjToHandle)
                (mgr, NULL, obj, 0);
    } __except (EXCEPTION_EXECUTE_HANDLER) { h = 0; }
    return (h >= WC3_HANDLE_BASE && h < WC3_HANDLE_LIMIT) ? h : 0;
}

static uint32_t Wc3Obj2HMem(uint32_t mgr, uint32_t obj)
{
    if (!mgr || !obj) return 0;
    uint32_t T = 0, cnt3 = 0;
    if (!Wc3PeekU32(mgr + WC3_OFF_MGR_TABLE, &T)) return 0;
    if (!Wc3PeekU32(mgr + WC3_OFF_MGR_COUNT, &cnt3)) return 0;
    if (!T || !cnt3 || cnt3 > 0x30000u) return 0;
    const uint32_t limit = (cnt3 < 0x9000u) ? cnt3 : 0x9000u;   // 伤害回调里别做长扫描
    uint32_t h = 0;
    __try {
        // 表项 stride 12〔?〕3 dword），对象指针〔?〕+4；引擎的句柄编码〔?〕`0x100000 + 槽位下标`
        // 〔?〕x2651D0 内部 `add eax,0x100000`；ydbase 〔?〕object_to_handle 同款〔?〕
        //  指针〔?〕12 递增而计数器〔?〕3 递增，最后再除以 3 —〔?〕所以句柄里的下标是 k，不〔?〕i〔?〕
        for (uint32_t i = 0, k = 0; i < limit; i += 3, ++k) {
            if (*(volatile uint32_t*)(uintptr_t)(T + 4u + i * 4u) == obj) { h = WC3_HANDLE_BASE + k; break; }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return h;
}

static uint32_t Wc3ObjectToHandle(uint32_t obj)
{
    if (!obj) return 0;
    if (g_nativeMgrWhich == 2) return 0;                    // 已判定用不了，直接放〔?〕

    uint32_t base = Wc3GameBase();
    if (!base) return 0;
    uint32_t ctx = 0;
    if (!Wc3PeekU32(base + WC3_RVA_CTX_GLOBAL, &ctx) || !ctx) return 0;

    // 已定型：直接走既定路线（每次伤害只花一次调用，不再做校验）
    if (g_nativeMgrWhich >= 0) {
        const uint32_t mgr = Wc3HandleMgrFromCtx(ctx, g_nativeMgrWhich);
        return g_nativeUseMemory ? Wc3Obj2HMem(mgr, obj) : Wc3Obj2HCall(mgr, obj);
    }

    // 首次：两种管理器口径 × 两种路线，全部用"句柄回程校验"验证后才定型
    for (int mem = 0; mem <= 1; ++mem) {
        for (int which = 0; which <= 1; ++which) {
            const uint32_t mgr = Wc3HandleMgrFromCtx(ctx, which);
            if (!mgr) continue;
            const uint32_t h = mem ? Wc3Obj2HMem(mgr, obj) : Wc3Obj2HCall(mgr, obj);
            if (!h) continue;
            const uint32_t back = Wc3HandleToUnit(h);
            if (back == obj) {
                g_nativeUseMemory = mem;
                g_nativeMgrWhich  = which;
                LogLine("native obj->handle 定型：路径=%s 管理器口径=%s（ctx %08X -> mgr %08X）"
                        " 首次 obj=%08X -> handle=%08X（回程校验一致 √）",
                        mem ? "纯内存扫描" : "调用 0x2651D0",
                        which ? "引擎访问器0x1C3200" : "纯内存*(ctx+0x1C)", ctx, mgr, obj, h);
                return h;
            }
            if (InterlockedIncrement(&g_nativeObj2HLog) <= 8)
                LogDebug("native obj->handle 试算：路径=%s 口径=%s obj=%08X -> %08X，回程 %08X（不一致）",
                        mem ? "内存" : "调用", which ? "访问器" : "纯内存", obj, h, back);
        }
    }
    // 都没成功先别放弃：单位句柄可能在更晚的时刻才注册（前若干次继续试〔?〕
    const LONG tries = InterlockedIncrement(&g_nativeObj2HTries);
    if (tries >= 16) {
        g_nativeMgrWhich = 2;
        LogLine("W native obj->handle：%d 次尝试都没通过回程校验，后续一律返 0"
                "（上层按原有“取不到”路径处理）", (int)tries);
    }
    return 0;
}

// 统一〔?〕对象 -> JASS 句柄"分派：JAPI 模式〔?〕ydbase，native 模式走引擎直〔?〕
static uint32_t ObjToHandle(uintptr_t obj)
{
    if (!obj) return 0;
    if (g_nativeMode) return Wc3ObjectToHandle((uint32_t)obj);
    if (g_object_to_handle) return (uint32_t)g_object_to_handle(obj);
    return 0;
}

// 诊断专用：把 func_value 的布局读出来，确认 native 在映射表里、参数个〔?〕类型正确〔?〕
// func_value 布局（YDWE 源码 Core\ydwar3\warcraft3\jass\func_value.h）：
//   +0x00 variable_type return_（enum〔?〕字节〔?〕
//   +0x04 std::vector<variable_type> param_ 〔?〕_Myfirst
//   +0x08  _Mylast     +0x0C  _Myend
//   +0x10 uintptr_t address_
//   +0x14 bool has_sleep_
static void LogJassFunc(const char* name)
{
    if (!g_jass_func) return;
    __try {
        const uint8_t* fv = (const uint8_t*)g_jass_func(name);
        if (!fv) { LogLine("  jass_func(%s) = 未找到（映射表里没有）", name); return; }

        uint32_t first = *(const uint32_t*)(fv + 4);
        uint32_t last  = *(const uint32_t*)(fv + 8);
        uint32_t count = (last > first) ? ((last - first) / 4u) : 0u;
        uintptr_t addr = *(const uintptr_t*)(fv + 16);

        char letters[32] = { 0 };
        if (count < 20u && first) {
            for (uint32_t i = 0; i < count; ++i) {
                uint32_t t = *(const uint32_t*)(first + i * 4u);
                letters[i] = (t >= 32u && t < 127u) ? (char)t : '?';
            }
        }
        LogLine("  jass_func(%s) = %08X 参数=%u [%s] 地址=%08X",
                name, (uint32_t)(uintptr_t)fv, count, letters, (uint32_t)addr);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("  jass_func(%s) 读取失败（code=%08X）", name, (uint32_t)GetExceptionCode());
    }
}

//------------------------------------------------------------------------------
// 4.5 JASS 字符串的读写（本版本实测结论，必须记住，否则一定踩坑）
//
//   * native 的【字符串参数】要的是 YDWE string_fake 那种【对象指针】：
//         +0x08 指向自身〔?〕0x1C 〔?〕char* 正文
//     （依据：call_param::push<const char*> 〔?〕string_fake 对象指针直接入栈〔?〕
//   * native 的【字符串返回值】是【字符串〔?〕id】（实测 0x105A 这种小整数）〔?〕
//     要用 from_stringid 查表〔?〕char*；把它当指针解引用就〔?〕C0000005〔?〕
//     （依据：yd_lua_engine\common.cpp:164 〔?〕TYPE_STRING 返回值做
//       get_jass_vm()->string_table->get(retval)〔?〕
//   * ydbase 〔?〕create_string 返回的是"JASS 字符串〔?〕（字符串〔?〕id），
//     它是〔?〕VM 当返回值用的，【不能】直接当参数传给 native —〔?〕参数要的〔?〕已编〔?〕
//     的对象指针。早期构〔?〕游戏里一条都不显〔?〕就是这个原因：create_string 给的
//     0x105A 〔?〕native 当对象解引用 〔?〕访问违例 〔?〕〔?〕__try 吞掉〔?〕
//   * 这同时解释了单位名一直退化成原始码（N00D/uske）：GetUnitName 返回的是 id〔?〕
//     老的 from_string 解引用失败，于是退〔?〕GetUnitTypeId 〔?〕4 字符码〔?〕
//------------------------------------------------------------------------------
// 前置声明（这几只在下面几节才定义，但 4.5 节就要用〔?〕
static const char* RuntimeStringById(uint32_t id);
static void        DumpTextProbe(const char* tag, const char* s);
static uint32_t    GetLocalPlayerHandle();
// GetUnitTypeKey 定义〔?〕7.5 节；6 节的 GetUnitLabel 〔?〕7.5 节的 GetUnitTypeCode 都要用它
// （它内部〔?〕native 分派，所以这里改〔?〕统一从它取类型码"，就不会漏掉 native 分支〔?〕
static uint32_t    GetUnitTypeKey(uint32_t handle);
// 取名字正文（定义〔?〕6 节）：JAPI 〔?〕g_call，native 直调引擎实现 + 字符串表反查〔?〕
// 5.5 节的文本编码判定也要用它们，所以在这里前置声明〔?〕
static const char* UnitNameText(uint32_t handle);
static const char* PlayerNameText(uint32_t hplayer);

struct FakeString { uint32_t m[8]; };

static const int kStrPoolCount = 64;
static FakeString g_strObj[kStrPoolCount];          // 对象常驻，供 native（可能的）延迟读〔?〕
static char       g_strBuf[kStrPoolCount][768];     // 正文常驻
static unsigned   g_strPoolIdx = 0;
static int        g_strDiag    = 4;                 // 前几次打印字符串解析走的是哪条路

// 造一个可以安全传〔?〕native 〔?〕JASS 字符串（YDWE string_fake 布局，字段全部清零）
static uint32_t MakeJassString(const char* text)
{
    unsigned i = g_strPoolIdx++ % (unsigned)kStrPoolCount;
    strncpy_s(g_strBuf[i], sizeof(g_strBuf[i]), text ? text : "", _TRUNCATE);
    memset(g_strObj[i].m, 0, sizeof(g_strObj[i].m));
    g_strObj[i].m[2] = (uint32_t)(uintptr_t)&g_strObj[i].m[0];   // +0x08 指向自身
    g_strObj[i].m[7] = (uint32_t)(uintptr_t)g_strBuf[i];         // +0x1C 正文
    return (uint32_t)(uintptr_t)&g_strObj[i];
}

// 〔?〕native 返回〔?〕字符串〔?〕换成 char*：先按运行期字符〔?〕id 查，再退回按对象解引〔?〕
static const char* JassStringToCStr(uint32_t v)
{
    if (!v) return NULL;

    // native 模式：引擎的字符串表〔?〕x1C2870），没有 ydbase 可问
    if (g_nativeMode) {
        const char* p = Wc3StringById(v);
        if (p && p[0]) {
            if (g_strDiag > 0) {
                --g_strDiag;
                LogDebug("T 字符串 v=%08X 走 native 引擎查 -> %08X [%s]", v, (uint32_t)(uintptr_t)p, p);
            }
            return p;
        }
        return NULL;
    }

    // 〔?〕本版本的实际情况：native 返回的是【运行期字符〔?〕id〔?〕
    if (v < 0x100000u) {
        const char* p = RuntimeStringById(v);
        if (p) {
            if (g_strDiag > 0) {
                --g_strDiag;
                LogDebug("T 字符串 v=%08X 走运行期表 -> %08X [%s]", v, (uint32_t)(uintptr_t)p, p);
            }
            return p;
        }
    }

    // 〔?〕兼容另一种布局：直接当对象指针解（from_string 〔?〕string_fake 同样适用〔?〕
    if (v >= 0x10000u && g_from_string) {
        __try {
            const char* p = g_from_string(v);
            if (p && p[0] && Readable(p, 2)) {
                if (g_strDiag > 0) {
                    --g_strDiag;
                    LogDebug("T 字符串 v=%08X 走对象解引用 -> %08X [%s]", v, (uint32_t)(uintptr_t)p, p);
                }
                return p;
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) { /* 两条都不〔?〕-> NULL */ }
    }

    return NULL;
}

// 引擎伤害函数（JAPI 〔?〕FakeUnitDamageFunc〔?〕
typedef uint32_t (__fastcall *fn_damage_t)(uint32_t _this, uint32_t _edx, uint32_t a2,
                                           war3_event_damage_data* ptr,
                                           uint32_t is_physical, uint32_t source_unit);
static volatile LONG g_original_damage = 0;
#define ORIG_DAMAGE ((fn_damage_t)(uintptr_t)g_original_damage)

// 我们自己占用的槽地址（用于卸载时恢复〔?〕
static uint32_t g_hookedSlot = 0;

// 钩子本体：直接用普〔?〕__fastcall 实现〔?〕
// MSVC 对 __fastcall 会自动生成"ecx/edx + 栈参数由被调方清理（ret 10h）"
// 与引擎的调用约定一致；探针版已经用这种方式验证过产物结尾是 ret 10h〔?〕
//
// ⚠️ 不要再改〔?〕__declspec(naked) 手写壳：曾经因为四个 push 都写〔?〕[esp+20]
//    （正确是 [esp+16]，每〔?〕push 〔?〕esp 〔?〕4 会自然走到下一个参数）而整体错位一格，
//    结果 ptr 收到 is_physical(0/1)、source_unit 收到垃圾，JAPI 原函数被喂空指针后崩溃，
//    〔?〕__try 吞掉 〔?〕引擎伤害函数整个不执〔?〕〔?〕表现为【所有攻击都不造成伤害】〔?〕

//------------------------------------------------------------------------------
// 5. 编码工具
//------------------------------------------------------------------------------
// 把可能是 UTF-8 的字符串转成指定代码页（936=GBK〔?〕5001=UTF-8）〔?〕
// 说明〔?〕
//   * 我们自己的字面量〔?〕UTF-8〔?〕utf-8 编译）→ 需要转成游戏认的编〔?〕
//   * 从游戏取回来的单位名/玩家名本来就〔?〕游戏编码"，绝不能重复转（拼装时才分开处理〔?〕
// 判据：能〔?〕CP_UTF8 + MB_ERR_INVALID_CHARS 解码成功的，才是〔?〕UTF-8〔?〕
static void Utf8ToCp(const char* src, char* dst, int dstBytes, UINT cp)
{
    dst[0] = 0;
    if (!src) return;

    int need = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, src, -1, NULL, 0);
    if (need <= 0) {
        // 不是合法 UTF-8，按"已经是目标编〔?〕处理，原样拷〔?〕
        strncpy_s(dst, dstBytes, src, _TRUNCATE);
        return;
    }
    wchar_t* w = (wchar_t*)malloc((size_t)need * sizeof(wchar_t));
    if (!w) { strncpy_s(dst, dstBytes, src, _TRUNCATE); return; }
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, src, -1, w, need);
    WideCharToMultiByte(cp, 0, w, -1, dst, dstBytes, NULL, NULL);
    free(w);
}

static void Utf8ToAnsi(const char* src, char* dst, int dstBytes)
{
    Utf8ToCp(src, dst, dstBytes, CP_ACP);
}

// v1.3.64：日志专用【逐段容错】转换。
//   为什么需要：日志行经常是【UTF-8 标签 + 游戏给的 GBK 单位名/路径】混在一起，
//   整行严格判 UTF-8 必然失败 -> 旧实现退回"原样拷贝" -> 整行还是 UTF-8 -> 记事本里全是乱码，
//   自检脚本按 GBK 找关键字也会找不到。这里改成一段一段处理：
//   合法的 UTF-8 段转成 ANSI，非法字节（GBK 中文/路径）原样保留 —— 两种内容都能正常显示。
static void Utf8ToAnsiTolerant(const char* src, char* dst, int dstBytes)
{
    if (!dst || dstBytes <= 0) return;
    dst[0] = 0;
    if (!src) return;
    int o = 0;
    const unsigned char* p = (const unsigned char*)src;
    while (*p && o < dstBytes - 1) {
        const unsigned char c = *p;
        int len = 0;
        if (c < 0x80) len = 1;
        else if ((c & 0xE0) == 0xC0) len = 2;
        else if ((c & 0xF0) == 0xE0) len = 3;
        else if ((c & 0xF8) == 0xF0) len = 4;
        if (len > 1) {
            int ok = 1;
            for (int i = 1; i < len; ++i) {
                if ((p[i] & 0xC0) != 0x80) { ok = 0; break; }
            }
            if (ok) {
                char seq[8] = { 0 };
                memcpy(seq, p, (size_t)len);
                wchar_t w[8] = { 0 };
                if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, seq, len, w, 8) > 0) {
                    char out[16] = { 0 };
                    const int n = WideCharToMultiByte(CP_ACP, 0, w, -1, out, sizeof(out), NULL, NULL);
                    if (n > 1) {
                        for (int i = 0; i < n - 1 && o < dstBytes - 1; ++i) dst[o++] = out[i];
                        p += len;
                        continue;
                    }
                }
            }
        }
        dst[o++] = (char)c;      // 非法字节：原样（通常就是游戏给的 GBK）
        p++;
    }
    dst[o] = 0;
}

// 安全地把 const char* 拷进本地缓冲（游戏返回的字符串指针可能被后续 JASS 调用回收〔?〕
static void SafeCopyAnsi(const char* src, char* dst, int dstBytes)
{
    dst[0] = 0;
    if (!src) return;
    __try {
        strncpy_s(dst, dstBytes, src, _TRUNCATE);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        dst[0] = 0;
    }
}

//------------------------------------------------------------------------------
// 5.5 标签文本 + 游戏文本编码判定
//
// 为什么需要这一节：
//   本插件要往游戏里写【自己的中文】，而中文必须用游戏认的编码。实测发现同一〔?〕
//   GBK 中文送进去，颜色代码(|c...|r)、数字、ASCII 名字都正常，中文却完全不出字形，
//   说明编码不对（而不是显示通道不对）〔?〕
//   判定方法不去猜：拿游戏自己的字符串表当标〔?〕—〔?〕to_stringid(字节〔?〕若能在表〔?〕
//   查到，就说明游戏内部用的就是这个编码。同一批中文词分别〔?〕GBK / UTF-8 各查一遍，
//   命中多的那个就是答案。判定不出来时退〔?〕GBK〔?〕
//   另外默认标签〔?〕ASCII：无论字〔?〕编码如何都能显示，中文标签作为可选项〔?〕
//------------------------------------------------------------------------------
typedef uint32_t (__cdecl *fn_to_stringid_t)(const char* s);
static fn_to_stringid_t g_to_stringid = NULL;
typedef void* (__cdecl *fn_get_jass_vm_t)(int index);
static fn_get_jass_vm_t g_get_jass_vm = NULL;

// 读【运行期字符串】：JASS 的字符串值有两类，别拿错表！
//   * 脚本里的标识〔?〕字面〔?〕〔?〕symbol_table->string_table（reverse_table）→ from_stringid
//     实测拿它〔?〕GetUnitName 的返回值会读出 "InitBlizzard" 这种标识符名（错的）
//   * 运行期生成的字符串（GetUnitName / GetPlayerName / CreateString 的返回）
//      〔?〕jass_vm_t::string_table（string_fasttable，VM 偏移 0x2874〔?〕
//     这跟 yd_lua_engine 的做法一致（common.cpp:166 get_jass_vm()->string_table->get(retval)〔?〕
//   string_fasttable 布局（hashtable.h:393）：+0x04 max_size_〔?〕0x08 array_，条目步〔?〕0x10
//   取到条目指针后交〔?〕from_string（它〔?〕+0x08 〔?〕再读 +0x1C 〔?〕char*）就是正文〔?〕
//   这里刻意不调用它〔?〕get()：get() 会把条目 +0x0C 的引用计〔?〕+1，反复查会泄漏；
//   我们只是立刻把文本拷走，不需要延长生命周期〔?〕
static const char* RuntimeStringById(uint32_t id)
{
    if (!id || !g_get_jass_vm || !g_from_string) return NULL;
    __try {
        const uint8_t* vm = (const uint8_t*)g_get_jass_vm(1);
        if (!vm) return NULL;
        const uint8_t* st = *(const uint8_t* const*)(vm + 0x2874);
        if (!st) return NULL;
        uint32_t maxSize = *(const uint32_t*)(st + 4);
        uint32_t array   = *(const uint32_t*)(st + 8);
        if (!array || id >= maxSize) return NULL;
        const char* p = g_from_string(array + 0x10 * id);
        if (p && p[0] && Readable(p, 2)) return p;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    return NULL;
}

// 判断游戏文本的编码：返回 936 / 65001 / 0(〔?〕ASCII，无信息)
static int ClassifyGameTextBytes(const char* s)
{
    // v1.3.65：引擎返回的字符串指针可能是野指针（实测见过 0x50）——
    //   原来 `!s || !s[0]` 里的 s[0] 本身就是解引用，指针一坏就在取字节/strlen 处 AV。
    //   先做可读性校验；读不到就当"判定不出来"，绝不拿野指针去算长度。
    if (!s) return 0;
    if (!Readable((const void*)s, 1)) return 0;
    if (!s[0]) return 0;
    int high = 0;
    for (const char* p = s; *p; ++p) if ((unsigned char)*p >= 0x80) high = 1;
    if (!high) return 0;

    __try {
        if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, s, -1, NULL, 0) > 0) return 65001;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try {
        if (MultiByteToWideChar(936, MB_ERR_INVALID_CHARS, s, -1, NULL, 0) > 0) return 936;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    return 0;
}

static UINT g_textCp = 936;     // 游戏文本代码页（自动判定结果〔?〕
static int  g_textEncKnown = 0; // 编码是否已确定（强制或探测到票数〔?〕

// 标签（UTF-8 〔?〕〔?〕〔?〕g_textCp 转好，只转标签，不碰游戏给的单位名）
static char L_PREFIX[64], L_SRC[32], L_TGT[32], L_ATK[16], L_RNG[16];
static char L_ATYPE[40], L_DTYPE[40], L_DMG[16], L_WEP[16], L_HP[16], L_OWN[16];

static void LoadLabelsAscii()
{
    strcpy_s(L_PREFIX, sizeof(L_PREFIX), "[DMG]");
    strcpy_s(L_SRC,    sizeof(L_SRC),    "SRC");
    strcpy_s(L_TGT,    sizeof(L_TGT),    "TGT");
    strcpy_s(L_ATK,    sizeof(L_ATK),    "ATK");
    strcpy_s(L_RNG,    sizeof(L_RNG),    "RNG");
    strcpy_s(L_ATYPE,  sizeof(L_ATYPE),  "ATYPE");
    strcpy_s(L_DTYPE,  sizeof(L_DTYPE),  "DTYPE");
    strcpy_s(L_DMG,    sizeof(L_DMG),    "DMG");
    strcpy_s(L_WEP,    sizeof(L_WEP),    "WEP");
    strcpy_s(L_HP,     sizeof(L_HP),     "HP");
    strcpy_s(L_OWN,    sizeof(L_OWN),    "OWN");
}

static void LoadLabelsChinese(UINT cp)
{
    // 源串〔?〕UTF-8〔?〕utf-8），逐个转成 cp，避免把游戏给的 GBK 单位名也一起转〔?〕
    struct { char* dst; size_t n; const char* src; } items[] = {
        { L_PREFIX, sizeof(L_PREFIX), "[伤害]" },
        { L_SRC,    sizeof(L_SRC),    "来源" },
        { L_TGT,    sizeof(L_TGT),    "触发单位" },
        { L_ATK,    sizeof(L_ATK),    "是否攻击" },
        { L_RNG,    sizeof(L_RNG),    "是否远程" },
        { L_ATYPE,  sizeof(L_ATYPE),  "攻击类型" },
        { L_DTYPE,  sizeof(L_DTYPE),  "伤害类型" },
        { L_DMG,    sizeof(L_DMG),    "伤害" },
        { L_WEP,    sizeof(L_WEP),    "武器" },
        { L_HP,     sizeof(L_HP),     "生命" },
        { L_OWN,    sizeof(L_OWN),    "所有" },
    };
    for (int i = 0; i < (int)(sizeof(items) / sizeof(items[0])); ++i) {
        char tmp[64];
        Utf8ToCp(items[i].src, tmp, sizeof(tmp), cp);
        strcpy_s(items[i].dst, items[i].n, tmp);
    }
}

// 判定游戏文本编码。必须在 JASS VM 起来（地图已加载）之后调用〔?〕
// 依据：拿游戏自己给的中文文本（玩家名、单位名）看它的字节是合〔?〕UTF-8 还是 GBK〔?〕
// 关键：一定要把【刚受伤的那个真实单位】的句柄传进〔?〕—〔?〕只有确定存在的单位才取得到名字，
// 早期版本只探固定的几个句柄，在别的图里全是无效句〔?〕〔?〕一票没〔?〕〔?〕被误判成"判定不出来
// 而自动降级成 ASCII 标签（截图里统计显示 TOTAL/ATTACK 就是这么来的）〔?〕
static UINT DetectGameTextEncoding(uint32_t liveHandle1, uint32_t liveHandle2)
{
    if (g_cfg.encoding == 1) { g_textEncKnown = 1; LogLine("文本编码：ini 强制 GBK(936)"); return 936; }
    if (g_cfg.encoding == 2) { g_textEncKnown = 1; LogLine("文本编码：ini 强制 UTF-8(65001)"); return 65001; }

    int votes936 = 0, votesUtf8 = 0;

    // 〔?〕玩家名（通常是中文）
    //    取名统一〔?〕PlayerNameText/UnitNameText：JAPI 〔?〕g_call，native 直调引擎 + 字符串表反查
    {
        const char* p = PlayerNameText(GetLocalPlayerHandle());
        DumpTextProbe("玩家名", p);
        const int c = ClassifyGameTextBytes(p);
        if (c == 936) ++votes936; else if (c == 65001) ++votesUtf8;
    }

    // 〔?〕刚受伤的单位（最可靠：句柄一定有效）
    uint32_t live[2] = { liveHandle1, liveHandle2 };
    for (int i = 0; i < 2; ++i) {
        if (!live[i]) continue;
        const char* p = UnitNameText(live[i]);
        if (i == 0) DumpTextProbe("受伤单位名", p);
        const int c = ClassifyGameTextBytes(p);
        if (c == 936) ++votes936; else if (c == 65001) ++votesUtf8;
    }

    // 〔?〕固定句柄兜底（老图里可能恰好有效）
    static const uint32_t probeUnits[] = {
        0x00108D14u, 0x00108D16u, 0x00108D18u, 0x00102CF2u, 0x00102D3Eu
    };
    for (int i = 0; i < (int)(sizeof(probeUnits) / sizeof(probeUnits[0])); ++i) {
        const char* p = UnitNameText(probeUnits[i]);
        const int c = ClassifyGameTextBytes(p);
        if (c == 936) ++votes936; else if (c == 65001) ++votesUtf8;
    }

    UINT cp = 936;
    if (votesUtf8 > votes936) cp = 65001;
    g_textEncKnown = (votes936 + votesUtf8) > 0;
    LogLine("文本编码判定：GBK 命中=%d，UTF-8 命中=%d，采用 %s", votes936, votesUtf8,
            (cp == 936) ? "GBK(936)" : "UTF-8(65001)");
    if (!g_textEncKnown) {
        LogLine("  （探到的文本都是纯 ASCII，无法区分；已按 GBK 处理，可用 ini 的 encoding 强制）");
    }
    return cp;
}

// 顺手〔?〕游戏给的文本"按字节打出来，便于确认真实编码（只看前几次）
static void DumpTextProbe(const char* tag, const char* s)
{
    if (!s) { LogDebug("P %s = <null>", tag); return; }
    // v1.3.65：野指针防护（引擎给的字符串指针可能是 0x50 这种垃圾值；
    //   下面的字节循环和 LogDebug("%s", s) 都会对它 strlen -> AV）
    if (!Readable((const void*)s, 1)) {
        LogDebug("P %s = <不可读指针 %08X，已跳过>", tag, (uint32_t)(uintptr_t)s);
        return;
    }
    unsigned char b[24];
    int n = 0;
    __try {
        for (; n < 24 && s[n]; ++n) b[n] = (unsigned char)s[n];
    } __except (EXCEPTION_EXECUTE_HANDLER) { n = 0; }
    char hex[24 * 3 + 1] = { 0 };
    for (int i = 0; i < n; ++i) {
        char one[4];
        _snprintf_s(one, sizeof(one), _TRUNCATE, "%02X ", b[i]);
        strcat_s(hex, sizeof(hex), one);
    }
    LogDebug("P %s 字节[%d]=%s| 文本=%s", tag, n, hex, s);
}

//------------------------------------------------------------------------------
// 6. 取单位名 / 单位信息（全部在 __try 里，失败就退回下一级）
//------------------------------------------------------------------------------
// 〔?〕单位名正〔?〕：JAPI 〔?〕g_call("GetUnitName")，native 直调引擎实现（RVA 0x1E6340）〔?〕
// 〔?〕两者返回的都是【字符串〔?〕id】，统一交给 JassStringToCStr 〔?〕char*〔?〕
//   JAPI 〔?〕ydbase 的运行期字符串表，native 走引擎自己的 0x1C2870〔?〕
// 返回的是"游戏编码"的字节，按原样用（不要再转码）〔?〕
//
// 顺带记住两条调用约定〔?〕026-09-28 逐字节复核）〔?〕
//   * jass::call 〔?〕按名调用的可变参形式"，参数槽直接放栈上：整数/句柄/布尔传【值】，
//     实数传〔?〕jreal】（real = 指向 float 的句柄），字符串传【字符串〔?〕id】（本版本实测）〔?〕
//   * 引擎 native 也是同一套：〔?〕R 参数〔?〕native 收到的是【指〔?〕float 的指针〔?〕
//     （DisplayTimedTextToPlayer 内部 `mov eax,[ebp+0xC]` 〔?〕`movss xmm,[eax]`），
//     〔?〕S 参数〔?〕native 收到的是【字符串〔?〕id】〔?〕
static const char* UnitNameText(uint32_t handle)
{
    if (!handle) return NULL;
    if (g_nativeMode) {
        // 〔?〕v1.3.19：先〔?〕4 字符〔?〕-> 名字 char*"（RVA 0x326BA0）—〔?〕
        //   引擎 GetUnitName 内部就是这条路，拿到的是名字正文本体，不需要字符串表反查〔?〕
        //   旧路（GetUnitName -> 字符〔?〕id -> 反查）在本机反查不通，所以才一直显〔?〕4 字符码〔?〕
        {
            const uint32_t raw = GetUnitTypeKey(handle);
            const char* tn = Wc3NameByRawcode(raw);
            if (tn && Readable((const void*)tn, 2)) {     // v1.3.66：引擎返回的名字指针必须校验
                static volatile LONG s_dbg = 0;
                const LONG seq = InterlockedIncrement(&s_dbg);
                // 〔?〕3 条无〔?〕debug 与否都写日志：这〔?〕4 字符〔?〕-> 真名"的现场证据，
                // 玩家反馈"名字还是 o000"时，看这 3 行就能判断是没解析到还是名字本身如此〔?〕
                if (seq <= 3)
                    LogLine("名字解析：%c%c%c%c -> \"%s\"（RVA 0x326BA0）",
                            (char)((raw >> 24) & 0xFF), (char)((raw >> 16) & 0xFF),
                            (char)((raw >> 8) & 0xFF), (char)(raw & 0xFF), tn);
                return tn;
            }
        }
        // 退路：老路（GetUnitName -> 字符〔?〕id -> 反查〔?〕
        const uint32_t fn = Wc3ResolveNative("GetUnitName", "GetUnitName",
                                             WC3_RVA_GET_UNIT_NAME, &g_natGetUnitName);
        if (!fn) return NULL;
        uint32_t id = 0;
        __try { id = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)fn)(handle); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return NULL; }
        const char* p = JassStringToCStr(id);
        // v1.3.66：这里原本直接读 p[0] —— 引擎回来的指针可能是野指针（实测 0x50/0x51），一读就 AV。
        //   而"取名字"这条路径是聊天命令/统计/死亡结算都要走的 → 表现为命令没反应、
        //   没有伤害明细、没有死亡总结（异常被上层 __try 吞掉）。
        if (!p || !Readable((const void*)p, 2)) return NULL;
        if ((unsigned char)p[0] < 0x20) return NULL;
        return p;
    }
    if (!g_call) return NULL;
    uint32_t s = 0;
    __try { s = (uint32_t)g_call("GetUnitName", handle); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return NULL; }
    { const char* q = JassStringToCStr(s); return (q && Readable((const void*)q, 2)) ? q : NULL; }   // v1.3.66 野指针校验
}

// 〔?〕玩家名正〔?〕：JAPI 〔?〕g_call("GetPlayerName")，native 直调引擎实现（RVA 0x1E3D40〔?〕
static const char* PlayerNameText(uint32_t hplayer)
{
    if (!hplayer) return NULL;
    if (g_nativeMode) {
        const uint32_t fn = Wc3ResolveNative("GetPlayerName", "GetPlayerName",
                                             WC3_RVA_GET_PLAYER_NAME, &g_natGetPlayerName);
        if (!fn) return NULL;
        uint32_t id = 0;
        __try { id = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)fn)(hplayer); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return NULL; }
        const char* p = JassStringToCStr(id);
        if (p && (unsigned char)p[0] < 0x20) return NULL;
        return p;
    }
    if (!g_call) return NULL;
    uint32_t s = 0;
    __try { s = (uint32_t)g_call("GetPlayerName", hplayer); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return NULL; }
    { const char* q = JassStringToCStr(s); return (q && Readable((const void*)q, 2)) ? q : NULL; }   // v1.3.66 野指针校验
}

// 名字优先级：GetUnitName -> GetUnitTypeId 〔?〕4 字符 -> #十六进制句柄
static void GetUnitLabel(uint32_t handle, char* out, int outBytes)
{
    out[0] = 0;
    if (!handle) { strncpy_s(out, outBytes, "<null>", _TRUNCATE); return; }

    // 名字（JAPI / native 统一〔?〕UnitNameText；native 〔?〕= 直调引擎 RVA 0x326BA0 拿类型真名）
    {
        const char* p = UnitNameText(handle);
        if (p && p[0]) {
            // 游戏侧字符串按原样用（GBK），不重复转〔?〕
            SafeCopyAnsi(p, out, outBytes);
            if (out[0]) return;
        }
    }

    // 退〔?〕1：GetUnitTypeId -> 4 字符编码（统一〔?〕GetUnitTypeKey：它内部〔?〕native 分派〔?〕
    //         所〔?〕native 模式下这里是"直读 CUnit*+0x30"，零调用〔?〕
    // 注：native 下名字走"4 字符码 -> 引擎类型码 -> 名字 char*"（v1.3.19），能取到中文真名；
    //     所以日志里显示的就是这〔?〕4 字符类型码，再不行才〔?〕#句柄〔?〕
    {
        __try {
            uint32_t id = GetUnitTypeKey(handle);
            if (id) {
                char code[5];
                code[0] = (char)((id >> 24) & 0xFF);
                code[1] = (char)((id >> 16) & 0xFF);
                code[2] = (char)((id >> 8) & 0xFF);
                code[3] = (char)(id & 0xFF);
                code[4] = 0;
                // 只保留可〔?〕ASCII，避免乱〔?〕
                int ok = 1;
                for (int i = 0; i < 4; ++i) {
                    if (code[i] < 0x20 || (unsigned char)code[i] > 0x7E) ok = 0;
                }
                if (ok) { strncpy_s(out, outBytes, code, _TRUNCATE); return; }
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) { out[0] = 0; }
    }

    // 退〔?〕2：十六进制句〔?〕
    _snprintf_s(out, outBytes, _TRUNCATE, "#%08X", handle);
}

static float GetUnitStateSafe(uint32_t handle, uint32_t which)
{
    // native 分派：引擎直连的 GetUnitState（返〔?〕float 位模式，〔?〕§3.9 的实机纠错）
    if (g_nativeMode) return Wc3GetUnitStateValue(handle, which);
    if (!g_call || !handle) return 0.0f;
    __try {
        // JAPI/ydbase 这条路返回的〔?〕real 句柄（指〔?〕float），〔?〕from_real 取正〔?〕
        uint32_t r = (uint32_t)g_call("GetUnitState", handle, which);
        if (!r || !g_from_real) return 0.0f;
        return g_from_real(r);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0.0f;
    }
}

static uint32_t GetLocalPlayerHandle()
{
    // native 分派：直接调引擎〔?〕GetLocalPlayer 实现（RVA 0x1E3150〔?〕
    if (g_nativeMode) return Wc3GetLocalPlayer();
    if (!g_call) return 0;
    __try {
        return (uint32_t)g_call("GetLocalPlayer");
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}

// 'Aloc' 蝗虫技能等〔?〕> 0 就跳过（假单位，比如伤害检测马甲）
static int HasLocust(uint32_t handle)
{
    // native 模式：本阶段没有准备 GetUnitAbilityLevel 〔?〕native 助手，一律不〔?〕
    // （skip_locust 默认就是 0；native 模式下显示本来也是关的，不影响伤害日志）
    if (g_nativeMode) return 0;
    if (!g_call || !handle) return 0;
    __try {
        int32_t abil = ABILITY_ID_LOCUST;
        uint32_t lv = (uint32_t)g_call("GetUnitAbilityLevel", handle, abil);
        return lv > 0;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}

// 判断某个单位是不是本地玩家（或本地玩家的盟友）拥有的
static int IsRelatedToLocalPlayer(uint32_t handle)
{
    // native 分派：用引擎〔?〕GetLocalPlayer / GetOwningPlayer（都〔?〕__cdecl，只读）
    if (g_nativeMode) {
        const uint32_t lp = Wc3GetLocalPlayer();
        const uint32_t ownerH = Wc3GetOwningPlayer(handle);
        return (lp && ownerH && ownerH == lp) ? 1 : 0;
    }
    if (!g_call || !handle) return 0;
    __try {
        uint32_t lp = GetLocalPlayerHandle();
        // GetOwningPlayer(unit) -> player；按句柄比较即可
        uint32_t ownerH = (uint32_t)g_call("GetOwningPlayer", handle);
        if (!ownerH || !lp) return 0;
        return ownerH == lp;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}

//------------------------------------------------------------------------------
// 7. 显示 —〔?〕v1.3.8：默认「有 JAPI 走消息区 / 没有 JAPI 只写日志」，
//                 没有 JAPI 〔?〕*照样上屏**：改用【引擎直连〔?〕
//                 〔?〕DisplayTimedTextToPlayer —〔?〕参数形态与 JAPI 路径一模一样（逐字节确证）〔?〕
//                   (uint32 hplayer, const float* x, const float* y, const float* dur, uint32 字符串对〔?〕
//                 〔?〕所〔?〕没有 JAPI 就没法在消息区显〔?〕其实不成立，只是默认按规则②关着〔?〕
//
// 规则（用户定的）〔?〕
//   〔?〕〔?〕JAPI（ydbase 可用、走 JAPI 路径〔?〕> 消息区显示，不做任何飘字〔?〕
//   〔?〕没有 JAPI -> 用引擎直连调同一个显示函数（照样上屏；log_only=1 才只写日志）〔?〕
//   〔?〕明细 / 统计 / 死亡结算一律完整写进日志，与显示无关；
//   〔?〕调试类日志由 ini 〔?〕debug=1 打开（默〔?〕0）〔?〕
//
// 字符串参数约定（两条路共用）：传【string_fake 对象指针】（MakeJassString 造：
//   +0x08=自身〔?〕0x1C=正文）—〔?〕不是"字符串 id"（传 id 会让引擎解引用小整数而崩）〔?〕
//------------------------------------------------------------------------------
static volatile LONG g_noDisplayLogged = 0;
static uint32_t g_natDTTTPRaw = 0;      // 名表/RVA 解析出的地址
static uint32_t g_natDTTTP    = 0;      // 跟随跳转后的真实〔?〕

// 解析 DisplayTimedTextToPlayer（native 模式上屏用）
static uint32_t Wc3ResolveDtttp()
{
    if (g_natDTTTP) return g_natDTTTP;
    if (!g_natDTTTPRaw) {
        const uint32_t a = Wc3ResolveNative("DisplayTimedTextToPlayer", "DisplayTimedTextToPlayer",
                                            0x001DFE70u, &g_natDTTTPRaw);
        if (!a) return 0;
    }
    const uint32_t real = Wc3FollowJumps(g_natDTTTPRaw, "dtttp");
    if (!real || !Readable((const void*)(uintptr_t)real, 5)) {
        LogLine("W native 显示：跟随跳转后地址 %08X 不可读，放弃上屏", real);
        return 0;
    }
    g_natDTTTP = real;
    return real;
}

static void ShowMessage(const char* msgAnsi)
{
    if (!msgAnsi || !msgAnsi[0]) return;

    // 〔?〕native（没〔?〕ydbase）：**照样上屏** —〔?〕用引擎直连调 DisplayTimedTextToPlayer
    //    （RVA 0x1DFE70，参数约定见上）。“没 JAPI 就不显示”这条约束已经去掉（v1.3.12）：
    //    能上屏就上屏；真不想看屏幕时〔?〕ini 〔?〕log_only=1〔?〕
    if (g_nativeMode || !g_call) {
        if (!Wc3OnGameThread()) {
            static volatile LONG once = 0;
            if (InterlockedExchange(&once, 1) == 0)
                LogLine("W native 显示：不在游戏线程上，本次不上屏");
            return;
        }
        const uint32_t fn = Wc3ResolveDtttp();
        if (!fn) return;
        const uint32_t lp = Wc3GetLocalPlayer();
        if (!lp) return;
        const uint32_t s = MakeJassString(msgAnsi);
        if (!s) return;

        float x = 0.0f, y = 0.0f, dur = 10.0f;
        __try {
            ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)fn)
                (lp, &x, &y, &dur, s);
            if (g_cfg.debug) {
                static int dbgLeft = 3;
                if (dbgLeft > 0) { --dbgLeft; LogLine("native 显示: lp=%08X 字符串对象=%08X 文本=%s", lp, s, msgAnsi); }
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            static volatile LONG once = 0;
            if (InterlockedExchange(&once, 1) == 0)
                LogLine("E native 显示：调用抛异常（code=%08X），已吞掉（只写日志）",
                        (uint32_t)GetExceptionCode());
        }
        return;
    }

    __try {
        uint32_t lp = GetLocalPlayerHandle();
        if (!lp) {
            if (g_cfg.debug) LogLine("S 取本地玩家失败（GetLocalPlayer 返回 0），本次不显示");
            return;
        }

        // 字符串参数必须传【字符串对象指针】（MakeJassString 造的 string_fake〔?〕
        uint32_t s = MakeJassString(msgAnsi);
        if (!s) return;

        // DisplayTimedTextToPlayer(player, x, y, duration, message)
        float x = 0.0f, y = 0.0f, dur = 10.0f;
        uint32_t rx = g_to_real(x);
        uint32_t ry = g_to_real(y);
        uint32_t rd = g_to_real(dur);

        if (g_cfg.debug) {
            static int dbgLeft = 3;
            if (dbgLeft > 0) {
                --dbgLeft;
                LogLine("S 显示: lp=%08X 字符串对象=%08X 文本=%s", lp, s, msgAnsi);
            }
        }
        g_call("DisplayTimedTextToPlayer", lp, &rx, &ry, &rd, s);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        // 显示失败绝不影响游戏
        LogLine("E 显示调用抛异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
    }
}

//------------------------------------------------------------------------------
// 7.5 聊天命令：@1 仅敌〔?〕/ @2 仅自〔?〕/ @3 关闭（游戏内动态切换）
//
// 为什么必须自己截引擎〔?〕
//   * 插件不是地图脚本，用不了 TriggerRegisterPlayerChatEvent —〔?〕它的 action 需〔?〕
//     JASS code（脚本字节码函数），插件造不出来
//   * 〔?〕GetEventPlayerChatString 只在"地图自己注册过聊天触发器"时才会被调到，不通用
//   * 所以直接截引擎的【聊天行显示函数】InGameChatWhat：玩家自己发的消息也会被本地
//     回显到聊天区，必然经过它 〔?〕只挑前缀开头的即可
//     （YDWE 〔?〕DisplayChat.cpp 正是用同一个函数往聊天区写字的〔?〕
//
// 定位配方（照〔?〕YDWE DisplayChat.cpp；本机已离线静态复核）〔?〕
//   game.dll 〔?〕"InGameChatWhat" 只被一〔?〕mov ecx, offset 引用
//   +4 〔?〕下一〔?〕E8 〔?〕+5 〔?〕下一〔?〕E8 〔?〕convert_function 〔?〕函数地址
//   本机结果：RVA 0x355CF0，序言 55 8B EC 81 EC A8 02 00 00（栈〔?〕0x2A8，正是拼聊天行的量）
//------------------------------------------------------------------------------
typedef void*    (__cdecl    *fn_get_war3_searcher_t)(void);
typedef uint32_t (__fastcall *fn_search_string_t)(void* self, void* dummy_edx, const char* str);
typedef uint32_t (__cdecl    *fn_next_opcode_t)(uint32_t start, uint32_t opcode, uint32_t size);
typedef uint32_t (__cdecl    *fn_convert_function_t)(uint32_t addr);

static fn_get_war3_searcher_t g_get_war3_searcher = NULL;
static fn_search_string_t     g_search_string     = NULL;
static fn_next_opcode_t       g_next_opcode       = NULL;
static fn_convert_function_t  g_convert_function  = NULL;

static uint8_t* g_chatTramp  = NULL;   // 〔?〕的跳板（偷来的序言 + jmp 回原函数〔?〕
static uint32_t g_chatTarget = 0;      // 〔?〕的原聊天函数地址
// v1.3.32：聊天显示函数可能有多个候〔?〕—〔?〕native 模式〔?〕谁引用了收件人常〔?〕反查〔?〕
//   而本机静态复核发现【有两个函数】都〔?〕按收件人拼聊天行"（显示函〔?〕+ 它的兄弟）〔?〕
//   所以做成多个槽：每个槽一个独立跳〔?〕+ 一个独〔?〕thunk，日志里〔?〕槽N"区分是谁被调到〔?〕
#define CHAT_MAX_SLOTS  4
#define CHAT_MAX_CAND   4
static void*    g_chatTramps[CHAT_MAX_SLOTS]  = { 0 };
static uint32_t g_chatTargets[CHAT_MAX_SLOTS] = { 0 };
static int      g_chatSlotCount = 0;
static volatile LONG g_objDumpLeft = 6;    // v1.3.43：dump 聊天事件对象的次数上〔?〕
static int      g_chatDebugLeft = 8;   // 前几条聊天文本打进日志，便于确认真截到了
static volatile LONG g_textInitDone2 = 0;   // EnsureTextReady 的一次性开关（伤害/聊天两条路径共用〔?〕

// 我们的聊天钩子：签名〔?〕__thiscall 等价 —〔?〕ecx=this，edx 收废值，其余 4 个参数在栈上〔?〕
// 结尾同样 ret 10h（__fastcall 前两个参数走 ecx/edx，剩〔?〕4 个正好按同样顺序在栈上）〔?〕
typedef uint32_t (__fastcall *fn_chat_t)(void* self, void* edx_dummy, int playerId,
                                         const char* text, int ctype, float duration);
// v1.3.88：发送观察的标记函数定义在后面（探针区），
//   这里先前置声明。
static void ProbeMarkSelfText(const char* t);

static uint32_t __fastcall ChatHookCommon(int slot, void* self, void* edx_dummy, int playerId,
                                          const char* text, int ctype, float duration);
static void     DumpMatchedChatEvent(const char* text);   // 定义在后面（v1.3.42 投递诊断）
static void     DumpChatEventToFile(int slot, void* self, void* edx_dummy, int playerId,
                                    const char* text, int ctype);  // v1.3.91：dump 到文件
static void     DumpProbeRing(const char* note);          // 定义在后面（v1.3.48 探针环）
static void     DumpObjFields(const char* tag, uint32_t p, int bytes);              // 后面定义
static int      PrintableStrInline(uint32_t p, char* out, int outBytes, int maxLen); // 后面定义
static int      PrintableWStrInline(uint32_t p, char* out, int outBytes, int maxLen); // v1.3.53 宽字符版
static void     DumpDrTable(const char* note);            // v1.3.55 数据断点〔?〕
static void     DrAdvanceBatch();                         // v1.3.57 分批布点
static void     StartDrAutoTest();                        // v1.3.58 自动测试
static void     FindChatFrameAndDump();                   // v1.3.61 取聊天框 frame
static volatile LONG g_drAuto = 0;                        // v1.3.58 自动测试是否在跑
static int      FindObjectByPointer(uint32_t target, uint32_t* outObj, uint32_t* outVt); // v1.3.52
static int      IsLikelyVtable(uint32_t vt);              // v1.3.56 严格虚表判定

// --- 迷你 x86 指令长度解码：只〔?〕MSVC 常见序言形式 ---
// 返回指令字节数；遇到不认识的字节返回 0 —〔?〕调用方据此【放弃挂接】，绝不赌〔?〕
static int DecodeInsnLen(const uint8_t* p)
{
    int i = 0;
    while (p[i] == 0x64 || p[i] == 0x65 || p[i] == 0x66 || p[i] == 0x67 ||
           p[i] == 0x2E || p[i] == 0x36 || p[i] == 0x3E || p[i] == 0x26 ||
           p[i] == 0xF2 || p[i] == 0xF3) {
        if (++i > 4) return 0;
    }

    uint8_t op = p[i];
    if (op >= 0x50 && op <= 0x5F) return i + 1;          // push/pop r32
    if (op == 0x6A) return i + 2;                        // push imm8
    if (op == 0x68) return i + 5;                        // push imm32
    if (op >= 0xB8 && op <= 0xBF) return i + 5;          // mov r32, imm32
    if (op == 0xA1 || op == 0xA3) return i + 5;          // mov eax/moffs
    if (op == 0xE8 || op == 0xE9) return i + 5;          // call/jmp rel32
    if (op == 0xEB) return i + 2;                        // jmp rel8
    if (op == 0xC3 || op == 0xCC || op == 0x90) return i + 1;
    if (op == 0xC2) return i + 3;                        // ret imm16

    switch (op) {                                        // 需要解〔?〕ModRM 的常见指〔?〕
    case 0x88: case 0x89: case 0x8A: case 0x8B: case 0x8D:
    case 0x01: case 0x03: case 0x09: case 0x0B:
    case 0x11: case 0x13: case 0x19: case 0x1B:
    case 0x21: case 0x23: case 0x29: case 0x2B:
    case 0x31: case 0x33: case 0x39: case 0x3B:
    case 0x85: case 0x87:
    case 0x80: case 0x81: case 0x83:
    case 0xC6: case 0xC7:
    case 0xF6: case 0xF7:
    case 0xFF:
        break;
    default:
        return 0;                                        // 不认〔?〕〔?〕放弃
    }

    uint8_t modrm = p[i + 1];
    int mod = (modrm >> 6) & 3;
    int rm  = modrm & 7;
    int len = i + 2;

    if (mod != 3) {
        if (rm == 4) {                                   // SIB
            uint8_t sib = p[i + 2];
            ++len;
            if (mod == 0 && (sib & 7) == 5) len += 4;
        }
        if (mod == 0)      { if (rm == 5) len += 4; }     // disp32
        else if (mod == 1) { len += 1; }                  // disp8
        else               { len += 4; }                  // disp32
    }

    if (op == 0x83 || op == 0x80 || op == 0xC6) len += 1;
    else if (op == 0x81 || op == 0xC7)          len += 4;
    else if (op == 0xF6 && (modrm & 0x38) == 0) len += 1;
    else if (op == 0xF7 && (modrm & 0x38) == 0) len += 4;

    return len;
}

// 安装内联跳转（偷序言 + 跳板）。成功返回偷走的字节数，失败返回 0〔?〕
// 注意：偷走的字节里如果含【相对跳〔?〕调用】（E8/E9/EB），跳板里照抄会跳错地方〔?〕
// 所以这种情况直接放弃（宁可少一个功能，也不能把游戏跳飞）〔?〕
static int InstallDetour(uint32_t target, void* hook, void** outTramp)
{
    int stolen = 0;
    while (stolen < 5) {                                  // 至少 5 字节才能〔?〕E9 rel32
        int len = DecodeInsnLen((const uint8_t*)(uintptr_t)(target + stolen));
        if (len <= 0 || stolen + len > 24) {
            LogLine("E InstallDetour: %08X 序言解码失败（已偷 %d 字节，下一条 len=%d）—— 前 8 字节 %02X %02X %02X %02X %02X %02X %02X %02X",
                    target, stolen, len,
                    *(const uint8_t*)(uintptr_t)(target + 0), *(const uint8_t*)(uintptr_t)(target + 1),
                    *(const uint8_t*)(uintptr_t)(target + 2), *(const uint8_t*)(uintptr_t)(target + 3),
                    *(const uint8_t*)(uintptr_t)(target + 4), *(const uint8_t*)(uintptr_t)(target + 5),
                    *(const uint8_t*)(uintptr_t)(target + 6), *(const uint8_t*)(uintptr_t)(target + 7));
            return 0;
        }
        stolen += len;
    }
    for (int i = 0; i < stolen; ++i) {                    // 相对跳转/调用不能照搬
        uint8_t b = *(const uint8_t*)(uintptr_t)(target + i);
        if (b == 0xE8 || b == 0xE9 || b == 0xEB) {
            LogLine("E InstallDetour: %08X 偷走的 %d 字节里第 %d 字节是 %02X（相对跳转），放弃",
                    target, stolen, i, b);
            return 0;
        }
    }

    uint8_t* tramp = (uint8_t*)VirtualAlloc(NULL, (SIZE_T)stolen + 8,
                                           MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!tramp) { LogLine("E InstallDetour: %08X 跳板 VirtualAlloc 失败", target); return 0; }

    memcpy(tramp, (const void*)(uintptr_t)target, (size_t)stolen);
    tramp[stolen] = 0xE9;
    *(int32_t*)(tramp + stolen + 1) =
        (int32_t)((intptr_t)(target + stolen) - (intptr_t)(tramp + stolen + 5));

    // 先把跳板挂到全局，再打补丁（避免极小的窗口里钩子被调到而跳板还没就绪）
    *outTramp = tramp;

    DWORD oldProt = 0;
    if (!VirtualProtect((void*)(uintptr_t)target, (SIZE_T)stolen,
                        PAGE_EXECUTE_READWRITE, &oldProt)) {
        LogLine("E InstallDetour: %08X VirtualProtect 失败 err=%lu（偷 %d 字节）",
                target, GetLastError(), stolen);
        VirtualFree(tramp, 0, MEM_RELEASE);
        *outTramp = NULL;
        return 0;
    }
    uint8_t* t = (uint8_t*)(uintptr_t)target;
    t[0] = 0xE9;
    *(int32_t*)(t + 1) = (int32_t)((intptr_t)hook - (intptr_t)(target + 5));
    for (int i = 5; i < stolen; ++i) t[i] = 0x90;
    VirtualProtect((void*)(uintptr_t)target, (SIZE_T)stolen, oldProt, &oldProt);
    FlushInstructionCache(GetCurrentProcess(), (void*)(uintptr_t)target, (size_t)stolen);
    return stolen;
}

// 目标开头可能已经被别人设成〔?〕jmp（E9 rel32 / EB rel8）—〔?〕例如 WFE 〔?〕Detours
// 钩过同一个函数。跟随这〔?〕jmp 到对方的钩子；我们把那个地址当作"原函〔?〕调用〔?〕
// 链条依然完整：引〔?〕-> jmp -> 我们的钩〔?〕-> 对方的钩〔?〕-> 它的 trampoline(原始实现)〔?〕
// 返回跟随后的地址，hops 记录跳了几次〔?〕= 原本就没被挂钩）〔?〕
static uint32_t FollowJumps(uint32_t addr, int* hops)
{
    *hops = 0;
    for (int i = 0; i < 4; ++i) {
        if (addr < 0x10000) break;
        const uint8_t* p = (const uint8_t*)(uintptr_t)addr;
        if (p[0] == 0xE9) {
            addr = addr + 5 + (uint32_t)(*(const int32_t*)(p + 1));
            ++(*hops);
            continue;
        }
        if (p[0] == 0xEB) {
            addr = addr + 2 + (uint32_t)(*(const int8_t*)(p + 1));
            ++(*hops);
            continue;
        }
        break;
    }
    return addr;
}

// 〔?〕引擎伤害函数〔?〕（照〔?〕YDWE EventDamageData.cpp 〔?〕searchUnitDamageFunc）〔?〕
// 返回【存放函数指针的那个数据地址】（换掉里面的值即可挂接）；找不到返回 0〔?〕
// outFunc（可空）顺带回传"引擎伤害函数本身的地址"——找不到槽时我们改对它做内联钩子〔?〕
// 这样不依〔?〕JAPI 的内部布局：启动器〔?〕JAPI、KK 平台自带〔?〕JAPI、甚至没〔?〕JAPI 都能用〔?〕
static uint32_t FindUnitDamageFuncSlot(uint32_t* outFunc)
{
    if (outFunc) *outFunc = 0;
    if (!g_get_war3_searcher || !g_search_string_ptr || !g_search_int_in_text1 ||
        !g_search_int_in_text2 || !g_search_int_in_rdata || !g_current_function) {
        LogLine("伤害槽定位：缺少搜索器导出，跳过搜索");
        return 0;
    }
    __try {
        void* s = g_get_war3_searcher();
        if (!s) return 0;

        const char* key = "EtherealDamageBonusAlly";
        uint32_t str = g_search_string_ptr(s, NULL, key, (uint32_t)(strlen(key) + 1));
        LogLine("伤害槽定位： search_string_ptr(\"%s\") = %08X", key, str);
        if (!str) return 0;

        for (uint32_t ptr = g_search_int_in_text1(s, NULL, str); ptr;
             ptr = g_search_int_in_text2(s, NULL, str, ptr + 1)) {
            uint32_t func = g_current_function(s, NULL, ptr);
            if (ptr - func > 1000) {                 // 〔?〕YDWE 同款判据
                if (outFunc) *outFunc = func;        // 记下引擎伤害函数本身
                uint32_t slot = g_search_int_in_rdata(s, NULL, func);
                LogLine("  候选： 引用=%08X 所属函数=%08X（%08X）", ptr, func, slot);
                if (slot) return slot;
                // 槽没找到（例如平台的 JAPI 不用指针槽接管）：继续找其他候选，
                // 〔?〕outFunc 已经记下来了，调用方会改用它做内联钩子〔?〕
            }
        }
        LogLine("  搜索结束：没找到候选槽");
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 定位伤害槽异常（code=%08X）", (uint32_t)GetExceptionCode());
    }
    return 0;
}

// 〔?〕YDWE 配方定位聊天显示函数。返〔?〕0 表示没找到〔?〕
static uint32_t LocateInGameChatWhat()
{
    if (!g_get_war3_searcher || !g_search_string || !g_next_opcode || !g_convert_function) return 0;

    uint32_t base = 0;
    __try {
        void* searcher = g_get_war3_searcher();
        if (!searcher) return 0;
        base = g_search_string(searcher, NULL, "InGameChatWhat");
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E search_string 异常（code=%08X）", (uint32_t)GetExceptionCode());
        return 0;
    }
    LogLine("聊天函数定位: search_string(\"InGameChatWhat\") = %08X", base);
    if (!base) return 0;

    // search_string 返回值到底是"引用指令地址"还是"操作数地址"随实现而异〔?〕
    // 所以从几个可能的起点各试一遍，谁算出来的函数序言对得上就用谁〔?〕
    const uint32_t starts[3] = { base, base + 1, base + 4 };
    for (int i = 0; i < 3; ++i) {
        uint32_t fn = 0;
        __try {
            uint32_t p = starts[i];
            p = g_next_opcode(p, 0xE8, 5);
            if (!p) continue;
            p += 0x05;
            p = g_next_opcode(p, 0xE8, 5);
            if (!p) continue;
            fn = g_convert_function(p);
        } __except (EXCEPTION_EXECUTE_HANDLER) { continue; }
        if (!fn) continue;

        const uint8_t* b = (const uint8_t*)(uintptr_t)fn;
        LogLine("  候选起点 +%d -> 函数 %08X，序言 %02X %02X %02X %02X %02X %02X %02X %02X",
                (int)(starts[i] - base), fn, b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7]);

        // 〔?〕标准 MSVC 序言：直接挂〔?〕
        if (b[0] == 0x55 && b[1] == 0x8B && b[2] == 0xEC) return fn;

        // 〔?〕开头已经是 jmp（被别人挂钩了，例如 WFE 〔?〕Detours）：跟随过去
        int hops = 0;
        uint32_t tgt = FollowJumps(fn, &hops);
        if (hops > 0 && tgt) {
            const uint8_t* b2 = (const uint8_t*)(uintptr_t)tgt;
            LogLine("    开头是 jmp（已被别人挂钩），跟随 %d 跳到 %08X，序言 %02X %02X %02X %02X",
                    hops, tgt, b2[0], b2[1], b2[2], b2[3]);
            return tgt;
        }
    }
    return 0;
}

// 一次性：判定游戏文本编码 + 准备标签文本。伤害路径与聊天路径都会调用。
// v1.3.63：加了分步日志 + 出错指令地址记录，用来定位"文本编码初始化异常"到底炸在哪一句
static uint32_t g_faultAt = 0;
static uint32_t g_faultAcc = 0;

// 只能在 __except(...) 的过滤表达式里用（GetExceptionInformation 的语法要求）
#define UDW_CATCH_FAULT()                                                                          \
    (g_faultAt = (uint32_t)(uintptr_t)GetExceptionInformation()->ExceptionRecord->ExceptionAddress, \
     g_faultAcc = (GetExceptionInformation()->ExceptionRecord->NumberParameters > 1)                \
                  ? (uint32_t)GetExceptionInformation()->ExceptionRecord->ExceptionInformation[1] : 0, \
     EXCEPTION_EXECUTE_HANDLER)

static void LogFaultInfo(const char* tag, uint32_t code, uint32_t at, uint32_t access)
{
    char nm[64] = { 0 };
    uint32_t mod = 0;
    __try {
        MEMORY_BASIC_INFORMATION v;
        if (VirtualQuery((LPCVOID)(uintptr_t)at, &v, sizeof(v)) && v.AllocationBase)
            mod = (uint32_t)(uintptr_t)v.AllocationBase;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    Wc3ModuleNameOf(at, nm, sizeof(nm));
    LogLine("E %s：code=%08X 出错指令=%08X (%s+0x%X) 访问地址=%08X",
            tag ? tag : "异常", code, at, nm[0] ? nm : "?", mod ? (at - mod) : 0u, access);
}

static void EnsureTextReady(uint32_t liveHandle1, uint32_t liveHandle2)
{
    if (InterlockedExchange(&g_textInitDone2, 1) != 0) return;
    __try {
        LogLine("T 编码初始化：开始（handle1=%08X handle2=%08X）", liveHandle1, liveHandle2);
        g_textCp = DetectGameTextEncoding(liveHandle1, liveHandle2);
        LogLine("T 编码初始化：判定完成，cp=%u", (unsigned)g_textCp);
        // ---- v1.3.18：判定不出来时【不再降级成 ASCII 标签〔?〕----
        //   旧行为：编码判不出来〔?〕g_cfg.labels=0 -> 消息区全〔?〕DMG/RNG/ATK/ATYPE〔?〕
        //   为什么以前总判不出来：native 模式〔?〕GetUnitLabel 拿不到中文真名（退化成 4 字符
        //   类型码，〔?〕ASCII），采样文本永远〔?〕ASCII 〔?〕0 〔?〕〔?〕必然降级。玩家看到的就是
        //   "消息区怎么全是英文"（用户反馈："描述改成中文，比〔?〕dmg rng 之类〔?〕）〔?〕
        //   〔?〕判不出来时按【UTF-8】处〔?〕—〔?〕本机实测过：游戏自己的字符串字节就是 UTF-8
        //     （日〔?〕`P 目标单位〔?〕字节[12]=E9 AA B8 E9 AA A8 E6 88 98 E5 A3 AB | 文本=骸骨战士`〔?〕
        //      E9 AA B8 正是 UTF-8 〔?〕〔?〕），所以往消息区送的中文也必须是 UTF-8〔?〕
        //   真乱码的话用 ini 〔?〕encoding=1 强制 GBK〔?〕2 强制 UTF-8）即可〔?〕
        if (!g_textEncKnown) {
            g_textCp = 65001;
            LogLine("编码判定不出来（采样文本全是 ASCII —— native 下取不到中文单位名）-> "
                    "用 UTF-8(65001) 出中文标签；若屏幕上显示成乱码，把 ini 的 encoding 改成 1(GBK)");
        }
        if (g_cfg.labels) LoadLabelsChinese(g_textCp); else LoadLabelsAscii();
        LogLine("T 编码初始化：标签已装载（cp=%u，labels=%d）", (unsigned)g_textCp, g_cfg.labels);
        // v1.3.69：这句纯粹是诊断用的，**绝不能让它把已经装好的标签搞坏**。
        //   以前它在同一个 __try 里，引擎取名字抛 C0000005 就跳到 except -> LoadLabelsAscii()
        //   -> 中文标签被降级成 ATK/RNG/ATYPE 这种 ASCII 标签（用户看到的就是这个）。
        //   现在它单独 try，失败只写一行日志，标签保持不动。
        __try {
            char nm0[128] = { 0 };
            GetUnitLabel(liveHandle1, nm0, sizeof(nm0));
            DumpTextProbe("受伤单位名", nm0);
        } __except (UDW_CATCH_FAULT()) {
            LogLine("T 编码初始化：诊断取名字失败（code=%08X 出错指令=%08X），标签不受影响",
                    (uint32_t)GetExceptionCode(), g_faultAt);
        }
        LogLine("T 编码初始化：完成");
    } __except (UDW_CATCH_FAULT()) {
        LogFaultInfo("文本编码初始化异常（标签装载阶段）", (uint32_t)GetExceptionCode(), g_faultAt, g_faultAcc);
        LoadLabelsAscii();
    }
}

//------------------------------------------------------------------------------
// 7.55 按单位统计受到的伤害（聊天命〔?〕@<单位> 开启，死亡时结算）
//
// 用法（游戏内聊天，只认本地玩家自己发的）〔?〕
//   @魔狼〔?〕/ @uske / @#00102D3E   〔?〕〔?〕名字 / 单位类型〔?〕/ 句柄"匹配到的单位设为记录目标
//   @?                            〔?〕立刻打印当前所有在记录单位的统〔?〕
//   @!                            〔?〕停止记录并结〔?〕
// 统计维度（都是原始数字，不做中文翻译）：是否攻击、是否远程、攻击类型、伤害类型〔?〕
//
// 实现要点〔?〕
//   * 不需要枚举全地图单位：只在收到伤害事件时，看"受伤单位"是否匹配选择〔?〕—〔?〕
//     正好就是我们要统计的那个单位，第一个伤害事件自然把它认出来〔?〕
//   * 同名单位不会混：每个句柄一条独立记录〔?〕
//   * 记录与显示模式无关：@3 关掉显示时照样统计，死亡时照样结算〔?〕
//------------------------------------------------------------------------------
static const int kMaxTracks = 24;
static const int kMaxBuckets = 32;    // 联合组合最多多少种
static const int kMaxPrintBuckets = 12;  // 消息区最多打印多少行（其余只进日志）
static const int kMaxSources = 16;       // 来源单位最多记多少种（超出的并〔?〕其他来源"
static const int kMaxPrintSources = 10;  // 来源单位最多打印多少行

// 联合统计的一条：是否攻击 / 是否远程 / 攻击类型 / 伤害类型 〔?〕次数、伤〔?〕
struct TrackBucket {
    int      atk, rng, atype, dtype;
    uint32_t cnt;
    double   dmg;
};

// 按来源【单位类型】统计的一条（同一〔?〕ID 的多个实例合并在一起）
struct SourceStat {
    uint32_t key;                     // 分组〔?〕= 单位类型 ID；取不到类型时退回该实例句柄
    uint32_t handle;                  // 第一次看到的实例句柄（仅日志用）
    char     label[128];              // 第一次看到时缓存下来的名字（游戏编码〔?〕
    char     code[16];                // 第一次看到时缓存下来的四字符类型〔?〕
    uint32_t cnt;
    double   dmg;
    int      merged;                  // 1 = 这是"其他来源"合并〔?〕
};

struct TrackStat {
    uint32_t handle;
    char     label[128];              // 记录时取的名字（游戏编码，可能带颜色代码〔?〕
    char     code[16];                // 记录时取的四字符类型〔?〕
    uint32_t events;
    double   total;
    TrackBucket joint[kMaxBuckets];   // 【联合】统计，不再按维度分别统〔?〕
    int         nJoint;
    SourceStat  src[kMaxSources];     // 按来源单位统计（末尾输出百分比）
    int         nSrc;
    SourceStat  srcOther;             // 溢出合并〔?〕
    int         dead;                 // 已结算（尸体继续挨打不再记账；复活后自动开新账〔?〕
    int         lives;                // 已经结算过几次（第几条命〔?〕
    uint32_t    seen0;                // v1.3.13：开账那一刻的"全局伤害事件计数"
                                      //   结算时打〔?〕(全局 - seen0)：用来区〔?〕
                                      //   〔?〕事件根本没抓到手"（这个数很小）②"抓到了但被过〔?〕丢掉〔?〕（这个数很大〔?〕
    int         byHotkey;             // v1.3.14：这条记录是【Ctrl+Alt+R/T 选中的单位〔?〕1)
                                      //   还是聊天命令(@名字/@类型〔?〕记的(0)〔?〕
                                      //   死亡结算只给 byHotkey=1 的上屏（〔?〕PrintTrackSummary）〔?〕
};

static TrackStat g_tracks[kMaxTracks];
static int       g_trackCount = 0;
static int       g_trackEnabled = 0;
static char      g_trackSelector[128] = { 0 };
// v1.3.14：当前选择器是不是"热键 #句柄"形态（= 玩家〔?〕Ctrl+Alt+R/T 亲手选的那个实例）〔?〕
//   建账时抄〔?〕TrackStat.byHotkey；聊天命令记的（@名字/@类型码）〔?〕0〔?〕
static int       g_trackByHotkey = 0;
// v1.3.13：伤害函数（我们挂钩的那个）被调用的总次数。只增，只在游戏线程里写〔?〕
// 用途：结算日志里带〔?〕记账期间全局伤害事件=N"，一眼判〔?〕
//       "这个单位的伤害是没被抓到" vs "抓到了但被我们自己过滤了"
static uint32_t  g_seenEvents = 0;

// 去掉单位名里的颜色代码（|cxxxxxxxx / |r），便于玩家〔?〕看到的名〔?〕直接匹配
static void StripColorCodes(char* s)
{
    char* r = s;
    char* w = s;
    while (*r) {
        if (r[0] == '|' && (r[1] == 'c' || r[1] == 'C')) {
            r += 2;
            for (int i = 0; i < 8 && isxdigit((unsigned char)*r); ++i) ++r;
            continue;
        }

        if (r[0] == '|' && (r[1] == 'r' || r[1] == 'R')) { r += 2; continue; }
        *w++ = *r++;
    }
    *w = 0;
    // 去首尾空〔?〕
    size_t n = strlen(s);
    while (n > 0 && (s[n-1] == ' ' || s[n-1] == '\t')) s[--n] = 0;
    size_t i = 0;
    while (s[i] == ' ' || s[i] == '\t') ++i;
    if (i) memmove(s, s + i, strlen(s + i) + 1);
}

// v1.3.20：取"干净的单位名"—〔?〕GetUnitLabel + 剥掉颜色〔?〕首尾空白〔?〕
//   为什么：JAPI 局〔?〕GetUnitName 拿回来的名字常带 |cffff9900…|r（地图给单位染了色）〔?〕
//   直接写进结算标题/来源〔?〕日志就是一堆颜色码（用户截图里 `|cffff9900武装牛头姬|r`）〔?〕
//   明细行的来源名早就剥了，现在统一〔?〕名字落地"这一层剥，屏幕与日志同时干净〔?〕
//   注意：文本编码探测（EnsureTextReady 的探针）必须用【原始】名字，不能走这里〔?〕
static void GetUnitLabelClean(uint32_t handle, char* out, int outBytes)
{
    GetUnitLabel(handle, out, outBytes);
    StripColorCodes(out);
}

// 取单位类型码〔?〕字符，如 uske / N00D）；取不到返〔?〕0
// 注：统一〔?〕GetUnitTypeKey（它内部〔?〕native 分派），JAPI 模式下与原实现完全等价〔?〕
static int GetUnitTypeCode(uint32_t handle, char* out, int outBytes)
{
    out[0] = 0;
    if (!handle) return 0;
    __try {
        uint32_t id = GetUnitTypeKey(handle);
        if (!id) return 0;
        char code[5];
        code[0] = (char)((id >> 24) & 0xFF);
        code[1] = (char)((id >> 16) & 0xFF);
        code[2] = (char)((id >> 8) & 0xFF);
        code[3] = (char)(id & 0xFF);
        code[4] = 0;
        int ok = 1;
        for (int i = 0; i < 4; ++i) if (code[i] < 0x20 || (unsigned char)code[i] > 0x7E) ok = 0;
        if (!ok) return 0;
        strncpy_s(out, outBytes, code, _TRUNCATE);
        return 1;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}

// 单位〔?〕短标〔?〕：优先四字符类型码（uske / N00D），取不到才退〔?〕#十六进制句柄〔?〕
// 必须在单位还活着的时候调用（结算时它可能已经死了/被移除）〔?〕
static void GetUnitShortId(uint32_t handle, char* out, int outBytes)
{
    out[0] = 0;
    if (!handle) { strncpy_s(out, outBytes, "?", _TRUNCATE); return; }
    char code[8];
    if (GetUnitTypeCode(handle, code, sizeof(code))) {
        strncpy_s(out, outBytes, code, _TRUNCATE);
        return;
    }
    _snprintf_s(out, outBytes, _TRUNCATE, "#%08X", handle);
}

// 取单位类〔?〕ID（四字符码的整数值），用〔?〕按类型合〔?〕的分组键；取不到返回 0
static uint32_t GetUnitTypeKey(uint32_t handle)
{
    // native 分派：零调用直读 CUnit*+0x30（引〔?〕GetUnitTypeId 的实现就是这么做的）〔?〕
    // 失败才退回引擎的 GetUnitTypeId native；两条都失败就返〔?〕0（上层走原有"取不〔?〕路径〔?〕
    if (g_nativeMode) return Wc3UnitTypeCode(handle);
    if (!g_call || !handle) return 0;
    __try {
        return (uint32_t)g_call("GetUnitTypeId", handle);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}

// 受伤单位是否匹配当前选择器：名字（去颜色码）/ 原始名字 / 四字符类型码 / #句柄
static int TrackMatch(uint32_t handle)
{
    if (!g_trackSelector[0] || !handle) return 0;

    __try {
        if (g_trackSelector[0] == '#') {                       // #十六进制句柄
            uint32_t want = (uint32_t)strtoul(g_trackSelector + 1, NULL, 16);
            return want && want == handle;
        }

        // 单位类型码（4 字符，如 uske / N00D）—〔?〕不依赖名字，最〔?〕
        char code[8];
        if (GetUnitTypeCode(handle, code, sizeof(code)) &&
            _stricmp(code, g_trackSelector) == 0) return 1;

        // 名字：先去颜色码比，再拿原始名比（防止个别名字本身带 | 之类〔?〕
        char name[128];
        GetUnitLabel(handle, name, sizeof(name));
        if (_stricmp(name, g_trackSelector) == 0) return 1;
        StripColorCodes(name);
        if (_stricmp(name, g_trackSelector) == 0) return 1;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }

    return 0;
}

// 按来源累加：同一个【单位类〔?〕ID】的多个实例合并成一条（取不到类型才按实例句柄分开〔?〕
static void AddSource(TrackStat& t, uint32_t handle, double amount)
{
    if (!handle) {                                   // 无来源（环境伤害之类〔?〕
        ++t.srcOther.cnt; t.srcOther.dmg += amount; t.srcOther.merged = 1;
        return;
    }

    uint32_t key = GetUnitTypeKey(handle);
    if (!key) key = handle;                          // 类型拿不〔?〕-> 退回按实例分组

    for (int i = 0; i < t.nSrc; ++i) {
        if (t.src[i].key == key) { ++t.src[i].cnt; t.src[i].dmg += amount; return; }
    }
    if (t.nSrc < kMaxSources) {
        SourceStat& s = t.src[t.nSrc];
        memset(&s, 0, sizeof(s));
        s.key    = key;
        s.handle = handle;
        s.cnt    = 1;
        s.dmg    = amount;
        // 名字/类型码在这里（单位还活着）就缓存下来，结算时它可能已经死〔?〕被移除了
        GetUnitLabelClean(handle, s.label, sizeof(s.label));
        GetUnitShortId(handle, s.code, sizeof(s.code));
        ++t.nSrc;
        return;
    }
    ++t.srcOther.cnt; t.srcOther.dmg += amount; t.srcOther.merged = 1;
}

// 联合累加：四个维度作为一个键
static void AddJoint(TrackBucket* arr, int& n, int atk, int rng, int atype, int dtype, double amount)
{
    for (int i = 0; i < n; ++i) {
        if (arr[i].atk == atk && arr[i].rng == rng &&
            arr[i].atype == atype && arr[i].dtype == dtype) {
            ++arr[i].cnt;
            arr[i].dmg += amount;
            return;
        }
    }
    if (n < kMaxBuckets) {
        arr[n].atk = atk; arr[n].rng = rng; arr[n].atype = atype; arr[n].dtype = dtype;
        arr[n].cnt = 1;   arr[n].dmg = amount;
        ++n;
    }
}

// ---- 文本拼装：我们自己的中文按游戏编码转，游戏给的字符串原样接（不要整条一起转〔?〕---
static void AppUtf8(char* dst, size_t cap, const char* utf8)
{
    char tmp[512];
    Utf8ToCp(utf8, tmp, sizeof(tmp), g_textCp);
    strncat_s(dst, cap, tmp, _TRUNCATE);
}
static void AppRaw(char* dst, size_t cap, const char* raw)
{
    strncat_s(dst, cap, raw ? raw : "", _TRUNCATE);
}
// 只允许【纯 ASCII 格式〔?〕+ 数字/ASCII 参数】走这里（中文一律用 AppUtf8 单独追加〔?〕
static void AppFmt(char* dst, size_t cap, const char* fmt, ...)
{
    char tmp[512];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(tmp, sizeof(tmp), _TRUNCATE, fmt, ap);
    va_end(ap);
    strncat_s(dst, cap, tmp, _TRUNCATE);
}

// v1.3.16：名〔?〕+ 类型码。名字和类型码相同（native 下取不到真名、名字退化成类型码）
//   就只写一〔?〕—〔?〕免得满屏 `o000(o000)`、`h042(h042)` 这种重复，行也更短〔?〕
static void AppNameCode(char* dst, size_t cap, const char* name, const char* code)
{
    AppRaw(dst, cap, (name && name[0]) ? name : "?");
    if (code && code[0] && (!name || _stricmp(name, code) != 0))
        AppFmt(dst, cap, "(%s)", code);
}

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// 生成统计汇总并逐行显示〔?〕
// 注意：消息区【一〔?〕= 一〔?〕DisplayTimedTextToPlayer】，所以这里一行一行发〔?〕
// 统计口径：四个维度【联合】成一个键，不按维度分别统计；每行给出该组合的伤害占比〔?〕
static void PrintTrackSummary(int idx, int died)
{
    TrackStat& t = g_tracks[idx];
    const int cn = g_cfg.labels;

    // ---- v1.3.83（用户要求）：死亡结算【一律上屏】，不再区分是 R 选的还是聊天命令记的 ----
    //   旧规则（v1.3.14）只有 Ctrl+Alt+R/T 记录的单位才上屏，聊天命令记的只写日志；
    //   实测那样用户看不到自己记录单位的死亡总结。现在统一上屏。
    //   真不想看屏幕就设 ini 的 log_only=1（那时只写日志）。
    //   主动查询（Ctrl+Alt+Q 看统〔?〕/ S 结算，died=0）照旧上屏，不受这条影响〔?〕
    const int onScreen = (g_cfg.log_only == 0);
    if (died && !t.byHotkey) LogLine("统计：%s (%s #%08X) 是聊天命令记录的；v1.3.83 起死亡结算同样上屏", t.label, t.code, t.handle);

    // ---- 屏幕（消息区）：一行一段，别太长免得折行叠〔?〕----
    //   标题 : `[统计] <〔?〕(<〔?〕) 死亡结算|当前统计 <次数> 〔?〕/ <总伤〔?〕`
    //   组合 : `  攻击 远程 穿刺(2) 普〔?〕4)〔?〕次数> 〔?〕<伤害> (<占比>%)`（v1.3.15 中文描述〔?〕
    //   来源 : `  来自 <〔?〕(<〔?〕)〔?〕次数> 〔?〕<伤害> (<占比>%)`
    //   完整原始数据（四个裸数字、句柄、拥有者、生命…）永远写在日志里（见函数末尾的 LogLine）〔?〕
    {
        // 代号兜底：复活重开账时若没带过来、或当初没取到，这里再取一次（取不到显〔?〕?〔?〕
        if (!t.code[0]) GetUnitShortId(t.handle, t.code, sizeof(t.code));

        char l[1024] = { 0 };
        AppUtf8(l, sizeof(l), cn ? "|cff00ffff[统计]|r " : "|cff00ffff[STATS]|r ");
        AppNameCode(l, sizeof(l), t.label, t.code[0] ? t.code : "?");
        AppUtf8(l, sizeof(l), " ");
        if (cn) {
            AppUtf8(l, sizeof(l), died ? "死亡结算 " : "当前统计 ");
            AppFmt (l, sizeof(l), "%u 次 / %.1f", t.events, t.total);
        } else {
            AppUtf8(l, sizeof(l), died ? "DEAD " : "NOW ");
            AppFmt (l, sizeof(l), "%u/%.1f", t.events, t.total);
        }
        if (onScreen) ShowMessage(l);
    }

    // 按伤害从大到小排序（选择排序，n 很小〔?〕
    int order[kMaxBuckets];
    const int n = t.nJoint;
    for (int i = 0; i < n; ++i) order[i] = i;
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
            if (t.joint[order[j]].dmg > t.joint[order[i]].dmg) {
                int tmp = order[i]; order[i] = order[j]; order[j] = tmp;
            }
        }
    }

    // 每条组合一行（超过 kMaxPrintBuckets 的只进日志，避免刷屏〔?〕
    const int show = (n < kMaxPrintBuckets) ? n : kMaxPrintBuckets;
    for (int k = 0; k < show; ++k) {
        TrackBucket& b = t.joint[order[k]];
        const double pct = (t.total > 0.0) ? (b.dmg * 100.0 / t.total) : 0.0;
        char l[256] = { 0 };
        // v1.3.17：和明细行同一套字段写法（中文字段〔?〕+ 原始数字），方便一行一行对着看〔?〕
        //   中文：`  是否攻击:1 是否远程:1 攻击类型:2 伤害类型:4  1 〔?〕6.9 (100.0%)`
        //   ASCII：`  ATK:1 RNG:1 ATYPE:2 DTYPE:4  1 6.9 100.0%`
        AppUtf8(l, sizeof(l), "  ");
        AppRaw (l, sizeof(l), L_ATK);   AppFmt (l, sizeof(l), ":%d ", b.atk);
        AppRaw (l, sizeof(l), L_RNG);   AppFmt (l, sizeof(l), ":%d ", b.rng);
        AppRaw (l, sizeof(l), L_ATYPE); AppFmt (l, sizeof(l), ":%d ", b.atype);
        AppRaw (l, sizeof(l), L_DTYPE); AppFmt (l, sizeof(l), ":%d  ", b.dtype);
        if (cn) AppFmt(l, sizeof(l), "%u 次 %.1f (%.1f%%)", b.cnt, b.dmg, pct);
        else    AppFmt(l, sizeof(l), "%u %.1f %.1f%%",      b.cnt, b.dmg, pct);
        if (onScreen) ShowMessage(l);
    }
    if (n > show) {
        char l[128] = { 0 };
        AppUtf8(l, sizeof(l), cn ? "  其余见日志" : "  more in log");
        if (onScreen) ShowMessage(l);
    }

    // ---- 末尾：按来源单位统计"谁造成了多少伤害、各占百分比" ----
    // 〔?〕src + 合并项一起排序（最〔?〕kMaxSources+1 条）
    int sIdx[kMaxSources + 1];
    int sN = 0;
    for (int i = 0; i < t.nSrc; ++i) sIdx[sN++] = i;
    const int hasOther = (t.srcOther.cnt > 0);
    if (hasOther) sIdx[sN++] = kMaxSources;      // 〔?〕kMaxSources 作为合并项的哨兵下标

    if (sN > 0) {
        // 按伤害降〔?〕
        for (int i = 0; i < sN; ++i) {
            for (int j = i + 1; j < sN; ++j) {
                const double dj = (sIdx[j] == kMaxSources) ? t.srcOther.dmg : t.src[sIdx[j]].dmg;
                const double di = (sIdx[i] == kMaxSources) ? t.srcOther.dmg : t.src[sIdx[i]].dmg;
                if (dj > di) { int tmp = sIdx[i]; sIdx[i] = sIdx[j]; sIdx[j] = tmp; }
            }
        }

        const int sShow = (sN < kMaxPrintSources) ? sN : kMaxPrintSources;
        for (int k = 0; k < sShow; ++k) {
            const int id = sIdx[k];
            SourceStat& s = (id == kMaxSources) ? t.srcOther : t.src[id];
            const double pct = (t.total > 0.0) ? (s.dmg * 100.0 / t.total) : 0.0;
            char l2[512] = { 0 };
            AppUtf8(l2, sizeof(l2), cn ? "  来自 " : "  from ");
        // v1.3.70 修：来源行原来把中文写在 AppFmt 的【格式串】里，而那两个汉字在
        //   "编码事故"（见 v1.3.69 说明）里被毁成了 U+FFFD，编译后字面量成了
        //   "\uFFFD?u \uFFFD?%.1f (%.1f%%)" -> 屏幕上打出 `来自 ?u ?0.0 (0.0%)`（2026-10-02 实机）。
        //   修法回到本文件既有约定：**中文一律走 AppUtf8，格式串只留纯 ASCII**。
            if (id == kMaxSources || s.merged) {
                AppUtf8(l2, sizeof(l2), cn ? "其他" : "other");
            } else {
                AppNameCode(l2, sizeof(l2), s.label, s.code[0] ? s.code : "?");
            }
            // 和组合行同一种形状：中文行是 `：次数 次 伤害 (占比%)`，ASCII 行保持裸数字
            if (cn) {
                AppUtf8(l2, sizeof(l2), " 次 ");
                AppFmt (l2, sizeof(l2), "%u %.1f (%.1f%%)", s.cnt, s.dmg, pct);
            } else {
                AppFmt (l2, sizeof(l2), " %u %.1f %.1f%%", s.cnt, s.dmg, pct);
            }
            if (onScreen) ShowMessage(l2);
        }
        if (sN > sShow) {
            char l2[128] = { 0 };
            AppUtf8(l2, sizeof(l2), cn ? "  其余见日志" : "  more in log");
            if (onScreen) ShowMessage(l2);
        }
    }

    // 日志里也留一份（我们自己的中文是 UTF-8 字面量，单位名是游戏编码，按各自原样写）
    LogLine("统计 %s (%s #%08X) %s: 次数=%u 总计=%.1f（联合统计 攻击/远程/攻击类型/伤害类型）"
            "；开账至今全局伤害事件=%u",
            t.label, t.code, t.handle, died ? "死亡结算" : "当前", t.events, t.total,
            (unsigned)(g_seenEvents - t.seen0));
    for (int k = 0; k < n; ++k) {
        TrackBucket& b = t.joint[order[k]];
        const double pct = (t.total > 0.0) ? (b.dmg * 100.0 / t.total) : 0.0;
        LogLine("   %d/%d/%d/%d: %u 次 / %.1f (%.1f%%)",
                b.atk, b.rng, b.atype, b.dtype, b.cnt, b.dmg, pct);
    }
    if (sN > 0) {
        LogLine("   按来源单位类型（伤害占比）：");
        for (int k = 0; k < sN; ++k) {
            const int id = sIdx[k];
            SourceStat& s = (id == kMaxSources) ? t.srcOther : t.src[id];
            const double pct = (t.total > 0.0) ? (s.dmg * 100.0 / t.total) : 0.0;
            if (id == kMaxSources || s.merged)
                LogLine("     其他来源: %u 次 / %.1f (%.1f%%)", s.cnt, s.dmg, pct);
            else
                LogLine("     %s (%s #%08X): %u 次 / %.1f (%.1f%%)",
                        s.label, s.code[0] ? s.code : "?", s.handle, s.cnt, s.dmg, pct);
        }
    }
}

static void PrintAllTracks(int died)
{
    for (int i = 0; i < g_trackCount; ++i) PrintTrackSummary(i, died);
    if (g_trackCount == 0) {
        char msg[256] = { 0 };
        AppUtf8(msg, sizeof(msg), g_cfg.labels ? "|cff00ffff[统计]|r 无记录"
                                               : "|cff00ffff[STATS]|r none");
        ShowMessage(msg);
    }
}

//------------------------------------------------------------------------------
// 7.6 把死亡结算复制到剪贴板（v1.3.14：只〔?〕死亡时自动复〔?〕，Ctrl+Alt+C 已去掉）
//
// 为什么要它：游戏里没法选中/复制消息区的文字。死亡结算那种多行信息想留存或分享，
// 最顺手的做法就〔?〕复制出来 -> 粘到记事〔?〕聊天软件/平台〔?〕（粘回游戏聊天框也行〔?〕
// 只是魔兽聊天输入框有长度上限，长块会被截断）〔?〕
//
// 实现要点〔?〕
//   * 〔?〕**CF_UNICODETEXT**（UTF-16）：任何程序都能正确读，中文不会乱码〔?〕
//   * 文本统一〔?〕UTF-8 再转换：我们自己的字面量本来就是 UTF-8，单位名〔?〕g_textCp 转一次；
//   * 剪贴板是全机共享资源，可能被别的程序占着 -> OpenClipboard 失败就重试几次；
//   * 内容与屏〔?〕日志里那几行同源（标〔?〕+ 组合〔?〕+ 来源行），只是去掉颜色码、写成多行纯文本〔?〕
//------------------------------------------------------------------------------
#define CLIP_TEXT_CAP 8192
static char g_clipText[CLIP_TEXT_CAP];
static int  g_clipLines = 0;

// 游戏编码 -> UTF-8（单位名用；我们的标签本来就〔?〕UTF-8，不用过这里〔?〕
static void CpToUtf8(const char* src, char* dst, int dstBytes)
{
    if (!dst || dstBytes <= 0) return;
    dst[0] = 0;
    if (!src || !src[0]) return;
    __try {
        wchar_t w[512] = { 0 };
        const int n = MultiByteToWideChar(g_textCp, 0, src, -1, w, 512);
        if (n <= 0) return;
        WideCharToMultiByte(CP_UTF8, 0, w, -1, dst, dstBytes, NULL, NULL);
    } __except (EXCEPTION_EXECUTE_HANDLER) { dst[0] = 0; }
}

// 单行紧凑版（**给游戏聊天框〔?〕*）：〔?〕ASCII、按长度截断〔?〕
//   为什么单〔?〕+ 〔?〕ASCII：聊天输入框是单行、有长度上限，而且中文在这条路上经常被〔?〕
//   （本机魔兽内部是 UTF-8，聊天框〔?〕CF_TEXT 时原样拷字节）。ASCII 只有一种编码，
//   怎么转换都不会坏，所〔?〕要贴进聊天框"就用这一版〔?〕
//   v1.3.24：默认出【中文名】（[伤害] 武装牛头〔?〕68%, 宫廷术使 17%）—〔?〕剪贴板走 CF_UNICODETEXT，记事本/微信/平台都对〔?〕
//   只保留【单位类〔?〕+ 伤害百分比】（用户要求）；上限 CLIP_CHAT_MAX 字符，超了就不再拼〔?〕

#define CLIP_CHAT_MAX 110
// v1.3.24：按【字符数】算长度（UTF-8 里一个中〔?〕3 字节，按字节算会让中文版被砍掉一半）
static size_t ClipLen(const char* s)
{
    size_t n = 0;
    for (; s && *s; ++s)
        if ((((unsigned char)*s) & 0xC0) != 0x80) ++n;      // 只数"首字〔?〕
    return n;
}
static void ClipAppendChat(const char* part)
{
    if (!part || !part[0]) return;
    const size_t used = ClipLen(g_clipText);
    const size_t need = ClipLen(part);
    if (used + need + 2 > (size_t)CLIP_CHAT_MAX) return;   // 放不下就不放（含 ", " 两个字符〔?〕
    if (used) strncat_s(g_clipText, CLIP_TEXT_CAP, ", ", _TRUNCATE);   // v1.3.23：条目用逗号分隔
    strncat_s(g_clipText, CLIP_TEXT_CAP, part, _TRUNCATE);
}

static int BuildChatLine(int onlyIdx)
{
    g_clipText[0] = 0;
    g_clipLines = 0;

    const int iFrom = (onlyIdx >= 0) ? onlyIdx : 0;
    const int ascii = (g_cfg.labels == 0) ? 1 : 0;   // v1.4.14：labels=1中文（默认） 0=ASCII
    const int iTo   = (onlyIdx >= 0) ? onlyIdx : (g_trackCount - 1);
    for (int i = iFrom; i <= iTo && i < g_trackCount; ++i) {
        if (i < 0) break;
        TrackStat& t = g_tracks[i];
        if (t.events == 0 && !(t.total > 0.0)) continue;

        // ---- v1.3.23（用户指定格式）：`[DMG] O018 68%, H027 17%, OTH 15%` ----
        //   比上一版更短：**不带**被记录单位的类型码〔?〕*不带** DEAD/CUR，条目之间用逗号 + 空格〔?〕
        //   `[DMG] ` 前缀在最后统一补（这样"一条来源都没有"时不会留下一个空前缀）〔?〕
        char part[160] = { 0 };

        // 来源单位类型：按伤害降序【全部列出】（超出 110 字符上限时由 ClipAppendChat 截断〔?〕
        int sIdx[kMaxSources + 1];
        int sN = 0;
        for (int k = 0; k < t.nSrc; ++k) sIdx[sN++] = k;
        if (t.srcOther.cnt > 0) sIdx[sN++] = kMaxSources;
        for (int a = 0; a < sN; ++a)
            for (int b = a + 1; b < sN; ++b) {
                const double db = (sIdx[b] == kMaxSources) ? t.srcOther.dmg : t.src[sIdx[b]].dmg;
                const double da = (sIdx[a] == kMaxSources) ? t.srcOther.dmg : t.src[sIdx[a]].dmg;
                if (db > da) { const int tmp = sIdx[a]; sIdx[a] = sIdx[b]; sIdx[b] = tmp; }
            }
        for (int k = 0; k < sN; ++k) {
            const int id = sIdx[k];
            SourceStat& s = (id == kMaxSources) ? t.srcOther : t.src[id];
            const double pct = (t.total > 0.0) ? (s.dmg * 100.0 / t.total) : 0.0;
            if (id == kMaxSources || s.merged)
                _snprintf_s(part, sizeof(part), _TRUNCATE, ascii ? "OTH %.0f%%" : "其他 %.0f%%", pct);
            else if (ascii) {
                _snprintf_s(part, sizeof(part), _TRUNCATE, "%s %.0f%%", s.code[0] ? s.code : "#?", pct);
            } else {
                // v1.3.24：中文名（游戏编〔?〕-> UTF-8，剪贴板〔?〕UTF-8）；名字取不到就退回类型码
                char nm[160] = { 0 };
                CpToUtf8(s.label, nm, sizeof(nm));
                _snprintf_s(part, sizeof(part), _TRUNCATE, "%s %.0f%%",
                            nm[0] ? nm : (s.code[0] ? s.code : "#?"), pct);
            }
            ClipAppendChat(part);
        }
    }
    if (g_clipText[0]) {
        char tmp[256] = { 0 };
        _snprintf_s(tmp, sizeof(tmp), _TRUNCATE, ascii ? "[DMG] %s" : "[伤害] %s", g_clipText);
        strcpy_s(g_clipText, CLIP_TEXT_CAP, tmp);
        g_clipLines = 1;
    }
    return g_clipLines;
}

//------------------------------------------------------------------------------
// 7.63 死亡结算诊断
// v1.3.72 诊断：记录【出错的指令地址】。GetExceptionCode 只给 C0000005，
//   没有地址就无法离线定位；GetExceptionInformation 能拿到 ExceptionAddress。
static void LogFaultAt(const char* where)
{
    uint32_t code = 0, addr = 0;
    __try {
        RaiseException(0xE0000001u, 0, 0, NULL);
    } __except (code = GetExceptionCode(),
                addr = (uint32_t)(uintptr_t)GetExceptionInformation()->ExceptionRecord->ExceptionAddress,
                EXCEPTION_EXECUTE_HANDLER) {
    }
    LogLine("E 死亡结算诊断：在【%s】抛异常 code=%08X 出错指令=%08X（本 DLL+0x%X）",
            where, code, addr, (uint32_t)(addr - (uint32_t)(uintptr_t)g_hSelf));
}

// v1.4.8【关键修复：游戏调用必须在游戏线程】
//   v1.4.7 在 CreateThread 的工作线程里调了 SendMessageA 和游戏窗口过程 -> 游戏崩。
//   hello_direct.c 的头部注释早就写了这条：
//       "v3 crashed because the game's internal functions were called from a
//        background thread. These functions must run on the game's main thread."
//   它 v4 的解法是在游戏窗口上装 WM_TIMER，让回调落在游戏消息循环里。
//   但它那样是【同步】跑完整套（含 Sleep 等聊天框），会把游戏卡住。
//   本插件已经有自己的窗口过程（UdwWndProc）和热键线程，所以改成：
//       游戏线程（WM_UDW_CHAT）: 只做 clear/set_recipient + 逐字 WM_CHAR + 回车
//                                —— 纯消息投递，零 Sleep
//       工作线程              : 只负责把投递请求 PostMessage 到游戏线程（v1.4.16 起不检查成功）
//   两边都不违反约束：游戏调用全在游戏线程，等待全在工作线程。
#define WM_UDW_CHAT          (WM_APP + 0x52)
#define SENDQ_CAP 1024
static char          g_sendQ[SENDQ_CAP] = { 0 };
static volatile LONG g_directChatBusy = 0;

// 在游戏线程上执行一次投递（定义在后面，见 UdwWndProc 旁）
static void DirectChatDeliverOnGameThread();
// g_gameWnd / EnsureHotkeyWindow 由 §7.8 定义（本节在它前面），所以先声明。
static void EnsureHotkeyWindow();
static HWND DirectChatGameWindow();

// 工作线程：只负责重试节奏与等待，不碰任何游戏函数
static DWORD WINAPI ChatSendWorker(LPVOID)
{
    EnsureHotkeyWindow();                       // 确保窗口过程是我方的
    HWND wnd = DirectChatGameWindow();          // 拿到游戏窗口
    LogLine("死亡结算：准备投递，窗口=%p", wnd);
    if (!wnd || !PostMessageW(wnd, WM_UDW_CHAT, 0, 0)) {
        LogLine("死亡结算：投递失败（窗口=%p PostMessage err=%lu）", wnd, GetLastError());
        InterlockedExchange(&g_directChatBusy, 0);
    }
    // v1.4.16：投进去就算发，不检查上屏结果；busy 由游戏线程投递完成时释放。
    return 0;
}

// 由游戏线程（伤害钩子）调用：只拷贝 + 起线程，绝不阻塞、绝不调游戏函数
static void QueueDeathChat()
{
    if (!g_clipText[0]) return;
    if (InterlockedExchange(&g_directChatBusy, 1) != 0) {
        LogLine("死亡结算：上一次无框发送还没结束，本次跳过");
        return;
    }
    strncpy_s(g_sendQ, sizeof(g_sendQ), g_clipText, _TRUNCATE);
    HANDLE h = CreateThread(NULL, 0, ChatSendWorker, NULL, 0, NULL);
    if (h) CloseHandle(h);
    else {
        InterlockedExchange(&g_directChatBusy, 0);
        LogLine("死亡结算：发送线程创建失败，本次没发");
    }
}

static void AutoClipOnDeath(int idx)
{
    if (!g_cfg.chat_on_death) return;
    if (idx < 0 || idx >= g_trackCount) return;

    int n = 0;
    __try { n = BuildChatLine(idx); }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        LogFaultAt("构造聊天行 BuildChatLine");
        return;
    }
    if (n <= 0) return;                                     // 空账没什么可发的

    // v1.4.13：删除剪贴板复制分支。只做无框发送。
    QueueDeathChat();

    char msg[256] = { 0 };
    AppFmt (msg, sizeof(msg), "|cffffcc00%s|r ", g_cfg.labels ? "[伤害]" : "[DMG]");
    AppUtf8(msg, sizeof(msg), g_cfg.labels
            ? "死亡结算已无框发到聊天（想关掉：ini 里 chat_on_death=0）"
            : "settlement sent to chat (frameless)");
    ShowMessage(msg);
}

// 每次伤害都调：命中选择器的单位开始记账，血量归零就结算〔?〕
// 结算后记录不删，只标 dead：这〔?〕尸体继续挨打"不会重复结算刷屏〔?〕
// 等它复活（血量回〔?〕> 0）再自动开下一条命的账〔?〕
static void TrackOnDamage(const struct DamageSnapshot& snap)
{
    if (!g_trackEnabled || !snap.target_handle) return;

    int idx = -1;
    for (int i = 0; i < g_trackCount; ++i) {
        if (g_tracks[i].handle == snap.target_handle) { idx = i; break; }
    }

    float hp = GetUnitStateSafe(snap.target_handle, JASS_UNIT_STATE_LIFE);
    // v1.3.13 防御：只〔?〕最大生命读得到"才承认这次生命读数是可信的〔?〕
    //   血的教训：旧版 native 〔?〕GetUnitState 的返回值被当成 real 句柄解引〔?〕〔?〕恒为 0
    //   〔?〕第一笔伤害就判死亡结算，该单位随后被〔?〕dead，后面所有伤害都被当"尸体挨打"丢掉〔?〕
    //   现在读不到最大生命时【不做死亡判定】，只记账，并写一行日志说明〔?〕
    const float hpMax = GetUnitStateSafe(snap.target_handle, JASS_UNIT_STATE_MAXLIFE);
    const int   hpOK  = (hpMax > 0.0f);
    if (!hpOK) {
        static volatile LONG s_noHp = 0;
        if (InterlockedIncrement(&s_noHp) <= 3)
            LogLine("统计：读不到单位生命（GetUnitState 返回不可用值），本次不做死亡判定，只记账");
    }

    if (idx >= 0 && g_tracks[idx].dead) {
        if (hpOK && hp > 0.0f) {
            // 复活了：清账重开（保留句〔?〕名字/类型〔?〕已结算次〔?〕—〔?〕少带一个就会出现空的代号）
            TrackStat& t0 = g_tracks[idx];
            const uint32_t h = t0.handle;
            const int lives = t0.lives;
            const int wasHotkey = t0.byHotkey;      // 复活重开账：来源标记也要带过〔?〕
            char label[128];
            char code[16];
            strcpy_s(label, sizeof(label), t0.label);
            strcpy_s(code,  sizeof(code),  t0.code);
            memset(&t0, 0, sizeof(t0));
            t0.handle = h;
            t0.lives  = lives;
            t0.seen0  = g_seenEvents;      // 新一条命：分母重新起〔?〕
            t0.byHotkey = wasHotkey;
            strcpy_s(t0.label, sizeof(t0.label), label);
            strcpy_s(t0.code,  sizeof(t0.code),  code);
            if (!t0.code[0]) GetUnitShortId(h, t0.code, sizeof(t0.code));   // 兜底再取一〔?〕
            LogLine("统计：%s (%s #%08X) 已复活，开始记录第 %d 条命", label, t0.code, h, lives + 1);
        } else {
            // 尸体继续挨打：不记账、也不再重复结算
            return;
        }
    }

    // ---- v1.3.21（用户要求）：结算里【小〔?〕track_min_damage（默〔?〕5）点的伤害不统计〔?〕---
    //   0 / 负数伤害永远不统计（马甲、光环那〔?〕0 伤害事件统计进去只会多出 0.0 行）〔?〕
    //   〔?〕v1.3.13 的区别：当时取消阈值是因为"第一刀被假〔?〕（GetUnitState 〔?〕0 〔?〕bug）让结算
    //   只剩一笔，看着〔?〕阈值把伤害吃了"；现在血量读对了，阈值就只是纯粹的记账口径〔?〕
    //   阈值【不影响死亡判定】：记录照样在该单位第一次挨打时建立，血归零照样结算〔?〕
    //   只是"这条命一点 >= 阈值的伤害都没挨到"时不打印空账，只写一行日志〔?〕
    const int big = (snap.amount > 0.0f) && (snap.amount >= g_cfg.track_min_damage);

    if (idx < 0) {
        if (!TrackMatch(snap.target_handle)) return;
        if (g_trackCount >= kMaxTracks) {
            LogLine("统计：记录数已满（%d），忽略新单位 %08X", kMaxTracks, snap.target_handle);
            return;
        }
        idx = g_trackCount++;
        memset(&g_tracks[idx], 0, sizeof(g_tracks[idx]));
        g_tracks[idx].handle = snap.target_handle;
        g_tracks[idx].seen0  = g_seenEvents;      // 开账时刻（结算日志打印期间收到的全局事件数）
        g_tracks[idx].byHotkey = g_trackByHotkey; // 记录来源（R/T 选中 = 1，聊天命〔?〕= 0〔?〕
        GetUnitLabelClean(snap.target_handle, g_tracks[idx].label, sizeof(g_tracks[idx].label));
        GetUnitShortId(snap.target_handle, g_tracks[idx].code, sizeof(g_tracks[idx].code));
        LogLine("统计：开始记账 %s (%s #%08X)（只统计 >= %.1f 点的伤害，伤害不计）",
                g_tracks[idx].label, g_tracks[idx].code, snap.target_handle,
                g_cfg.track_min_damage);
    }

    TrackStat& t = g_tracks[idx];

    if (big) {
        ++t.events;
        t.total += snap.amount;

        const int atk = (int)((snap.flag >> 8) & 1u);
        const int rng = (int)(snap.flag & 1u);
        AddJoint(t.joint, t.nJoint, atk, rng,
                 (int)snap.attack_type, (int)MaskToIndex3(snap.damage_type), snap.amount);
        AddSource(t, snap.source_handle, snap.amount);
    }

    // 死亡结算：我们的快照是在原伤害函数跑完之后取的，所以这里已经是扣血后的血〔?〕
    if (hpOK && hp <= 0.0f) {
        ++t.lives;
        if (t.events > 0) {
            PrintTrackSummary(idx, 1);
        } else {
            // 这条命一〔?〕>= 阈值的伤害都没挨到（例如全程被 0~4 点的小伤害磨死）〔?〕
            // 不打印空账（避免"总计 0.0"刷屏），只在日志里记一〔?〕
            LogLine("统计：%s (%s #%08X) 死亡，但本局没有 >= %.1f 点的伤害，跳过结算",
                    t.label, t.code, t.handle, g_cfg.track_min_damage);
        }
        t.dead = 1;        // 只标记，不删：等复活再开新账（见函数开头）
        // v1.4.13：死亡结算一出来就【无框直投】给队友（chat_on_death）。
        AutoClipOnDeath(idx);
    }
}

//------------------------------------------------------------------------------
// 7.6 阵营判定 + 聊天命令分发
//------------------------------------------------------------------------------
// 返回〔?〕=本地玩家或盟友的单位  2=敌方单位  0=判定不了
static int UnitCamp(uint32_t handle)
{
    // native 分派：GetLocalPlayer / GetOwningPlayer / IsPlayerAlly 三个 native（全部只读）
    if (g_nativeMode) {
        const uint32_t nlp = Wc3GetLocalPlayer();
        if (!nlp || !handle) return 0;
        const uint32_t nowner = Wc3GetOwningPlayer(handle);
        if (!nowner) return 0;
        if (nowner == nlp) return 1;
        return Wc3IsPlayerAlly(nlp, nowner) ? 1 : 2;
    }
    if (!g_call || !handle) return 0;
    __try {
        uint32_t lp = GetLocalPlayerHandle();
        if (!lp) return 0;
        uint32_t owner = (uint32_t)g_call("GetOwningPlayer", handle);
        if (!owner) return 0;
        if (owner == lp) return 1;
        uint32_t ally = (uint32_t)g_call("IsPlayerAlly", lp, owner);
        return ally ? 1 : 2;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}

static int LocalPlayerId()
{
    // native 分派：GetLocalPlayer + GetPlayerId（只读，不分配句柄）
    if (g_nativeMode) {
        const uint32_t nlp = Wc3GetLocalPlayer();
        if (!nlp) return -1;
        const uint32_t id = Wc3GetPlayerId(nlp);
        return (id <= 15u) ? (int)id : -1;    // 玩家槽只〔?〕0..11(±中立)，离谱值当"判不出来"
    }
    if (!g_call) return -1;
    __try {
        uint32_t lp = GetLocalPlayerHandle();
        if (!lp) return -1;
        return (int)(uint32_t)g_call("GetPlayerId", lp);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return -1;
    }
}

static const char* ModeNameUtf8(int m)
{
    switch (m) {
    case 0:  return "仅来源为自己";
    case 1:  return "仅来源为自己/友方";
    case 2:  return "仅来源为敌人";
    case 3:  return "关闭";
    default: return "全部";
    }
}

static const char* ModeNameAscii(int m)
{
    switch (m) {
    case 0:  return "SRC-SELF";
    case 1:  return "SRC-SELFALLY";
    case 2:  return "SRC-ENEMY";
    case 3:  return "OFF";
    default: return "ALL";
    }
}

// 每个模式"具体管什〔?〕—〔?〕切换时直接告诉玩家，免得只看到一个名字不知道含义
//   v1.3.1：这些说明也压短了（原来 48~57 列，飘起来会折成 2 段）
static const char* ModeHelpUtf8(int m)
{
    switch (m) {
    case 0:  return "只看来源是自己的伤害";
    case 1:  return "只看来源是自己/友方的伤害";
    case 2:  return "只看来源是敌人的伤害";
    case 3:  return "不显示明细（统计照旧，死亡仍结算）";
    default: return "显示所有伤害（不分敌我）";
    }
}

static const char* ModeHelpAscii(int m)
{
    switch (m) {
    case 0:  return "only damage FROM self";
    case 1:  return "only damage FROM self/ally";
    case 2:  return "only damage FROM enemy";
    case 3:  return "no per-hit text (stats still on)";
    default: return "all damage events";
    }
}

// 1 = 这次命令是热键触发的（回执里就少〔?〕聊天会广〔?〕这件事）
static volatile LONG g_hotkeyAck = 0;

// 模式回执（v1.3.3 按要求改成【两行短提醒】）〔?〕
//   〔?〕1 〔?〕= 这次按的是什么（统计全部 / 显示敌人伤害 / 显示自己和友军伤〔?〕/ 关闭〔?〕
//   〔?〕2 〔?〕= 热键提醒
//   （两种后端都写消息区；native 走引擎直连，log_only=1 才只写日志）
static void ShowModeAck(int newMode, int byHotkey)
{
    char line[512] = { 0 };

    // 〔?〕1 行：当前状态（用用户的原话〔?〕
    AppUtf8(line, sizeof(line), g_cfg.labels
            ? (newMode == 0 ? "|cffffcc00[伤害]|r 只显示自己的伤害"
              : newMode == 1 ? "|cffffcc00[伤害]|r 显示自己和友军伤害"
              : newMode == 2 ? "|cffffcc00[伤害]|r 显示敌人伤害"
              : newMode == 3 ? "|cffffcc00[伤害]|r 已关闭明细（统计照旧，死亡仍结算）"
                             : "|cffffcc00[伤害]|r 统计全部伤害")
            : (newMode == 0 ? "|cffffcc00[DMG]|r self damage only"
              : newMode == 1 ? "|cffffcc00[DMG]|r self+ally damage"
              : newMode == 2 ? "|cffffcc00[DMG]|r enemy damage"
              : newMode == 3 ? "|cffffcc00[DMG]|r detail OFF (stats still on)"
                             : "|cffffcc00[DMG]|r all damage"));
    ShowMessage(line);

    // 〔?〕2 行：热键提醒
    memset(line, 0, sizeof(line));
    AppUtf8(line, sizeof(line), g_cfg.labels
            ? "|cffffcc00[伤害]|r 热键 Ctrl+Alt+0/1/2/3 切换 | R 记录 | Q 统计 | S 结算"
            : "|cffffcc00[DMG]|r hotkeys Ctrl+Alt+0/1/2/3 | R track | Q stats | S settle");
    ShowMessage(line);

    // 聊天命令是会被广播给其他玩家〔?〕—〔?〕只提醒一次，且不用热键时才提〔?〕
    static int warned = 0;
    if (!byHotkey && !warned) {
        warned = 1;
        memset(line, 0, sizeof(line));
        AppFmt (line, sizeof(line), "    ");
        AppUtf8(line, sizeof(line), g_cfg.labels
                ? "|cffffcc00注意|r: 聊天命令别人也看得到，建议用热键"
                : "|cffffcc00note|r: chat commands are public, prefer hotkeys");
        ShowMessage(line);
    }
}

static void HandleChatCommand(int playerId, const char* text)
{
    int localId = LocalPlayerId();
    if (localId >= 0 && playerId != localId) return;      // 只认本地玩家自己发的

    const char* p = text;
    while (*p == ' ') ++p;

    const char* pre = g_cfg.chat_prefix;
    size_t pl = strlen(pre);
    if (pl == 0) return;
    if (strncmp(p, pre, pl) != 0) return;
    p += pl;

    int newMode = -1;
    if      (!strcmp(p, "1")) newMode = 1;
    else if (!strcmp(p, "2")) newMode = 2;
    else if (!strcmp(p, "3")) newMode = 3;
    else if (!strcmp(p, "0")) newMode = 0;                // 附带：@0 恢复全部

    if (newMode >= 0) {
        EnsureTextReady(0, 0);                            // 编码/标签可能还没初始〔?〕
        InterlockedExchange(&g_mode, newMode);
        const int byHotkey = (InterlockedExchange(&g_hotkeyAck, 0) != 0);
        LogLine("聊天命令：玩家%d 发来 \"%s\" -> 模式=%d(%s)%s", playerId, text, newMode,
                ModeNameAscii(newMode), byHotkey ? "（来自热键）" : "");
        ShowModeAck(newMode, byHotkey);
        return;
    }

    // ---- 统计相关命令 ----
    EnsureTextReady(0, 0);

    if (!strcmp(p, "?")) {                                 // @? 看当前统〔?〕
        LogLine("聊天命令：玩家%d 发来 \"%s\" -> 打印当前统计", playerId, text);
        PrintAllTracks(0);
        return;
    }
    if (!strcmp(p, "!")) {                                 // @! 停止并结〔?〕
        LogLine("聊天命令：玩家%d 发来 \"%s\" -> 停止记录并结算", playerId, text);
        PrintAllTracks(0);
        char msg[256] = { 0 };
        AppUtf8(msg, sizeof(msg),
                g_cfg.labels ? "|cffffcc00[伤害]|r 统计: 已停止记录" : "|cffffcc00[DMG]|r stats: stopped");
        ShowMessage(msg);
        g_trackEnabled = 0;
        g_trackSelector[0] = 0;
        g_trackCount = 0;
        g_trackByHotkey = 0;                              // v1.3.14：停止记录也把来源标记清〔?〕
        return;
    }

    // v1.3.61：@fr 按名字拿聊天输入〔?〕frame 对象 + 列虚表（为找"提交入口"
    if (!_stricmp(p, "fr")) {
        LogLine("聊天命令：玩家%d 发来 \"%s\" -> 取聊天框 frame 并列虚表", playerId, text);
        FindChatFrameAndDump();
        return;
    }

    // v1.3.58：@dr 启动"数据断点自动测试"（绕开输入法，插件自己粘贴+回车〔?〕
    if (!_stricmp(p, "dr")) {
        LogLine("聊天命令：玩家%d 发来 \"%s\" -> 启动数据断点自动测试", playerId, text);
        StartDrAutoTest();
        return;
    }

    // ---- 其它：当〔?〕记录这个单位受到的伤〔?〕的选择〔?〕----
    {
        char sel[128];
        strncpy_s(sel, sizeof(sel), p, _TRUNCATE);
        StripColorCodes(sel);
        if (!sel[0]) return;

        g_trackCount = 0;                                  // 换目标就重新开始记
        g_trackEnabled = 1;
        strcpy_s(g_trackSelector, sizeof(g_trackSelector), sel);
        // v1.3.14〔?〕句柄 = Ctrl+Alt+R/T 选中的那一个实例（死亡结算要上屏）〔?〕
        //          名字/类型〔?〕= 聊天命令记的（可能一次记到好几个同名单位，死亡结算只进日志）〔?〕
        g_trackByHotkey = (sel[0] == '#') ? 1 : 0;
        LogLine("聊天命令：玩家%d 发来 \"%s\" -> 开始记录单位 \"%s\"", playerId, text, g_trackSelector);

        char msg[512] = { 0 };
        AppUtf8(msg, sizeof(msg),
                g_cfg.labels ? "|cffffcc00[伤害]|r 开始记录: " : "|cffffcc00[DMG]|r tracking: ");
        if (sel[0] == '#') {
            // 热键传进来的〔?〕#句柄：回执里显示它的名字+类型码，玩家才知道记的是哪个
            uint32_t h = (uint32_t)strtoul(sel + 1, NULL, 16);
            char label[128] = { 0 }, code[8] = { 0 };
            if (h) {
                GetUnitLabelClean(h, label, sizeof(label));
                StripColorCodes(label);
                GetUnitShortId(h, code, sizeof(code));
            }
            if (label[0]) {
                AppRaw(msg, sizeof(msg), label);
                if (code[0]) AppFmt(msg, sizeof(msg), " (%s)", code);
            } else {
                AppFmt(msg, sizeof(msg), "%s", sel);
            }
        } else {
            AppRaw(msg, sizeof(msg), sel);
        }
        // v1.3.13：回执只〔?〕记的是谁"
        //   以前尾巴上挂"（Ctrl+Alt+Q 看统〔?〕/ S 结算 / C 复制到剪贴板〔?〕—〔?〕
        //   玩家〔?〕R 只是想记录，屏幕上却多出一串带"统计"字样的提示，容易被当〔?〕
        //   "〔?〕R 冒出来一堆统计信〔?〕。热键本身在首次启用时已经写过日志说明，
        //   这里不再重复教学〔?〕
        ShowMessage(msg);
    }
}

//------------------------------------------------------------------------------
// 【临时诊断】v1.3.30：把"聊天显示钩子"被调用时的真实调用链打进日志〔?〕
//
// 为什么要它：静态反查发〔?〕InGameChatWhat 的两个调用者（RVA 0x3515C0 / 0x351690〔?〕
//   在整〔?〕game.dll 里【没有任何指针引用】（既不〔?〕E8 直接调用目标，也没有〔?〕VA/RVA
//   形式被存进任何表），说明它们只能通过运行时栈才看得清是怎么被调进来的〔?〕
//   所以这里把栈上所〔?〕像返回地址"的值按 Game.dll 相对地址打出来（从内到外）：
//     判定标准 = 该地址〔?〕5 字节〔?〕E8（相〔?〕call），或前 2 字节〔?〕FF /2（call r/m32）〔?〕
//   只在前几条聊天时打（〔?〕C 聊天[…] 同一开〔?〕g_chatDebugLeft），量很小〔?〕
//   拿到这条链之后，就能顺着找到"本地玩家自己发的消息"到底是哪个函数推进来的〔?〕
//------------------------------------------------------------------------------
// v1.3.34：改用【EBP 链】回溯（比栈扫描干净得多〔?〕
//   栈扫描会〔?〕安全 cookie 检查函数的返回地址""刚好长得像返回地址的栈数据"一起捞出来
//   （v1.3.33 的实机日志里就混进了两个 ->0x771125 〔?〕cookie 检查帧）〔?〕
//   这里走经典帧链：[ebp] = 上一〔?〕ebp，[ebp+4] = 返回地址〔?〕
//   我们的钩子是被【跳转】进来的，所以此〔?〕EBP 就是"调用聊天显示函数的那个游戏函〔?〕的帧〔?〕
//   从它往上走就是真实调用链。每层顺手把"该返回地址处的 call 目标"也解出来，嵌套关系一眼可见〔?〕
//   校验：EBP 必须递增、返回地址必须落在 Game.dll 〔?〕.text 里，否则立即停〔?〕
// v1.3.35：逐帧看【参数区】里有没〔?〕本次聊天文本"
//   x86 帧布局：[ebp] = 上一〔?〕ebp，[ebp+4] = 返回地址，[ebp+8..] = 本函数的栈参数〔?〕
//   所以对每一帧检〔?〕[ebp+8 .. ebp+8+7*4]：谁〔?〕这串刚发出去的文〔?〕当参数收下了〔?〕
//   谁就是接收输入的那一环（提交/发送函数），而且顺带把参数位置也暴露出来〔?〕
//   这一步纯读内存、不装任何钩子，零崩溃风险〔?〕
static int ArgIsChatText(uint32_t v, const char* text)
{
    if (!v || !text || !text[0]) return 0;
    if (v == (uint32_t)(uintptr_t)text) return 'P';        // 同一个指针（最硬的证据〔?〕
    __try {
        const char* p = (const char*)(uintptr_t)v;
        for (int i = 0; ; ++i) {
            if (text[i] == 0) return (p[i] == 0) ? 'S' : 0;   // 内容完全相同
            if (p[i] != text[i]) return 0;
            if (i > 512) return 0;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return 0;
}

// v1.3.36：顺着一个参数指针进到它指向的内存里找东西（结构体传参时用）
//   〔?〕MemHasText  ：这块内存里直接出现了这串文本（例如 std::string 的内〔?〕/ 内联缓冲〔?〕
//   〔?〕MemHasDword ：这块内存里存着这串文本的指针（例如 struct { ...; char* text; ... }〔?〕
static int MemHasText(uint32_t p, const char* text, int* outOff, int scanBytes)
{
    if (!p || !text || !text[0]) return 0;
    const int n = (int)strlen(text);
    if (n <= 0 || n > 256) return 0;
    __try {
        const uint8_t* m = (const uint8_t*)(uintptr_t)p;
        for (int i = 0; i + n <= scanBytes; ++i) {
            if (m[i] != (uint8_t)text[0]) continue;
            int ok = 1;
            for (int j = 1; j < n; ++j) if (m[i + j] != (uint8_t)text[j]) { ok = 0; break; }
            if (ok) { if (outOff) *outOff = i; return 1; }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return 0;
}

static int MemHasDword(uint32_t p, uint32_t value, int scanBytes, int* outOff)
{
    if (!p || !value) return 0;
    __try {
        const uint8_t* m = (const uint8_t*)(uintptr_t)p;
        for (int i = 0; i + 4 <= scanBytes; i += 4) {
            if (*(const uint32_t*)(m + i) == value) { if (outOff) *outOff = i; return 1; }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return 0;
}

static void LogChatCallChain(const char* text)
{
    const uint32_t base = Wc3GameBase();
    uint32_t tStart = 0, tSize = 0;
    if (!base || !Wc3TextRange(base, &tStart, &tSize)) {
        LogLine("聊天链：拿不到 Game.dll 的 .text 范围，跳过");
        return;
    }
    const uint32_t lo = tStart, hi = tStart + tSize;

    char buf[1024];
    int  n = 0;
    n += _snprintf_s(buf + n, sizeof(buf) - n, _TRUNCATE,
                     "聊天调用链(EBP 链；文本=%s 指针=%X):", text ? text : "(",
                     (uint32_t)(uintptr_t)text);

    uint32_t frame = 0;
    __asm { mov frame, ebp }              // 此刻 EBP = 调用显示函数的那个游戏函数的〔?〕
    int shown = 0;
    for (int i = 0; i < 24 && frame; ++i) {
        if (frame < 0x10000 || (frame & 3)) break;
        uint32_t next = 0, ret = 0;
        __try {
            next = *(const uint32_t*)(uintptr_t)frame;
            ret  = *(const uint32_t*)(uintptr_t)(frame + 4);
        } __except (EXCEPTION_EXECUTE_HANDLER) { break; }
        if (next <= frame) break;                     // 帧链必须往高地址〔?〕
        if (ret) {
            uint32_t tgt = 0;
            __try {
                const uint8_t* q = (const uint8_t*)(uintptr_t)(ret - 5);
                if (q[0] == 0xE8) tgt = ret + (uint32_t)(*(const int32_t*)(uintptr_t)(ret - 4));
            } __except (EXCEPTION_EXECUTE_HANDLER) { }

            // v1.3.38：返回地址不在 game.dll 里的帧【也要记】——那正是"外部调用〔?〕〔?〕
            //   例如 WFE 直接调游戏内部函数时，它的返回地址会落〔?〕WFEDll.dll 里〔?〕
            //   第一帧标〔?〕WFEDll 的地方，就是 WFE 的入口，它下面一帧就〔?〕WFE 调的那个游戏函数〔?〕
            if (ret >= lo && ret < hi) {
                n += _snprintf_s(buf + n, sizeof(buf) - n, _TRUNCATE, " %X", ret - base);
                if (tgt >= lo && tgt < hi)
                    n += _snprintf_s(buf + n, sizeof(buf) - n, _TRUNCATE, "(->%X)", tgt - base);
            } else {
                char nm[64] = { 0 };
                uint32_t mb = 0;
                __try {
                    MEMORY_BASIC_INFORMATION mbi;
                    if (VirtualQuery((LPCVOID)(uintptr_t)ret, &mbi, sizeof(mbi)) && mbi.AllocationBase)
                        mb = (uint32_t)(uintptr_t)mbi.AllocationBase;
                } __except (EXCEPTION_EXECUTE_HANDLER) { }
                Wc3ModuleNameOf(ret, nm, sizeof(nm));
                n += _snprintf_s(buf + n, sizeof(buf) - n, _TRUNCATE, " [%s+%X]",
                                 nm[0] ? nm : "?", mb ? (ret - mb) : 0u);
            }

            // v1.3.36：逐帧〔?〕8 个栈参数原样打一行；参数指向的内存里若含本次文本〔?〕
            //          或该内存里存着文本指针，都标出来（结构体传参也能抓到）
            char det[600];
            int  d = 0;
            d += _snprintf_s(det + d, sizeof(det) - d, _TRUNCATE,
                             "   帧%02d ret=%X args:", shown, ret - base);
            __try {
                for (int a = 0; a < 8; ++a) {
                    const uint32_t v = *(const uint32_t*)(uintptr_t)(frame + 8 + a * 4);
                    d += _snprintf_s(det + d, sizeof(det) - d, _TRUNCATE, " %X", v);
                    int off = 0;
                    if (v == (uint32_t)(uintptr_t)text) {
                        d += _snprintf_s(det + d, sizeof(det) - d, _TRUNCATE, "[★P a%d]", a + 1);
                    } else if (v >= 0x10000 && MemHasText(v, text, &off, 0x100)) {
                        d += _snprintf_s(det + d, sizeof(det) - d, _TRUNCATE, "[★文本 a%d+%X]", a + 1, off);
                        // v1.3.43：参数指向的内存里文本出现在 +0x18 —〔?〕那就是【聊天事件对象】，
                        //   直接把完整布局 dump 出来（手打的〔?〕WFE 喊话的各一份即可对比）
                        if (off == 0x18 && InterlockedDecrement(&g_objDumpLeft) >= 0) {
                            char s18[96] = { 0 };
                            PrintableStrInline(v + 0x18, s18, sizeof(s18), 64);
                            LogLine("P5 聊天事件对象：obj=%08X 来自第%02d arg%d +18=\"%s\"",
                                    v, shown, a + 1, s18);
                            DumpObjFields("事件对象", v, 0x60);
                        }
                    } else if (v >= 0x10000 &&
                               MemHasDword(v, (uint32_t)(uintptr_t)text, 0x100, &off)) {
                        d += _snprintf_s(det + d, sizeof(det) - d, _TRUNCATE, "[★指针 a%d+%X]", a + 1, off);
                    }
                }
            } __except (EXCEPTION_EXECUTE_HANDLER) { }
            LogLine("%s", det);
            ++shown;
        }
        frame = next;
    }
    n += _snprintf_s(buf + n, sizeof(buf) - n, _TRUNCATE, "  [%d 层]", shown);
    LogLine("%s", buf);

    // 兜底：原来那套栈扫描也留一行，两边对得上就基本没跑〔?〕
    uint32_t  probe = 0;
    uint32_t* sp    = &probe;
    char buf2[768];
    int  m = 0;
    m += _snprintf_s(buf2 + m, sizeof(buf2) - m, _TRUNCATE, "聊天调用链(栈扫描，从内到外):");
    int found = 0;
    for (int i = 1; i < 800 && found < 12; ++i) {
        const uint32_t v = sp[i];
        if (v < lo || v >= hi) continue;
        const uint8_t* p = (const uint8_t*)(uintptr_t)v;
        __try {
            if (p[-5] == 0xE8) {
                m += _snprintf_s(buf2 + m, sizeof(buf2) - m, _TRUNCATE, " %X", v - base);
                ++found;
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
    LogLine("%s", buf2);
}

// 钩子主体（多槽共用一个实现，slot 只是用来区分"是哪个目标被调到〔?〕〔?〕
static uint32_t __fastcall ChatHookCommon(int slot, void* self, void* edx_dummy, int playerId,
                                          const char* text, int ctype, float duration)
{    __try {
        // v1.3.88【直调投递·观察】本地玩家自己发的聊天，
        //   把文本设为观察目标（chat_diag=1 时生效），
        //   供 ProbeLogOutbound 判断“哪个参数才是消息”。
        if (g_cfg.chat_diag && text && text[0] && playerId == LocalPlayerId())
            ProbeMarkSelfText(text);
        // v1.3.55/57：标记上屏的那一刻处理数据断点批次（自动测试模式下由测试线程自己驱动，这里不插手〔?〕
        if (g_cfg.chat_dr && !g_drAuto && g_cfg.chat_marker[0] && text &&
            strstr(text, g_cfg.chat_marker) != NULL) {
            DrAdvanceBatch();
        }
        // 前几条聊天文本写日志：用来确〔?〕自己发的消息确实经过这里"
        if (g_chatDebugLeft > 0 && text && text[0]) {
            --g_chatDebugLeft;
            LogLine("C 聊天[玩家%d][槽%d 目标%08X]=%s", playerId, slot,
                    g_chatTargets[slot], text);
            if (g_cfg.chat_diag) {       // v1.3.44：诊断噪音默认关（ini: chat_diag〔?〕
                LogChatCallChain(text);  // 〔?〕+ 哪个函数的参数里带着这串文本
                DumpMatchedChatEvent(text);
                DumpProbeRing(text);     // v1.3.48：把最近的探针记录打出来（含本条消息的投〔?〕处理〔?〕
                DumpChatEventToFile(slot, self, edx_dummy, playerId, text, ctype);  // v1.3.91
            }
        }
        if (g_cfg.chat_cmd && text && text[0]) HandleChatCommand(playerId, text);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 聊天钩子异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
    }

    // 无论如何都原样转调原函数（聊天本身不能受我们影响〔?〕
    fn_chat_t t = (fn_chat_t)(uintptr_t)g_chatTramps[slot];
    if (t) return t(self, edx_dummy, playerId, text, ctype, duration);
    return 0;
}

// 4 〔?〕thunk：InstallDetour 需〔?〕每个目标一个独立函数入〔?〕
// v1.3.93：在 thunk 里取 _ReturnAddress() —— 这才是【游戏里真正调用聊天显示函数的那条指令】。
//   在 ChatHookCommon 里取不行（那会拿到 thunk 自己的地址）。知道调用者是谁，
//   就等于知道了"读输入框并提交"的函数在 Game.dll 里的位置。
static void LogAddrWithModule(const char* tag, uint32_t addr);   // 定义在后面
#define CHAT_THUNK_LOG()                                                        \
    if (g_chatDebugLeft > 0)                                                    \
        LogAddrWithModule("聊天显示：直接调用者 =", (uint32_t)(uintptr_t)_ReturnAddress())

static uint32_t __fastcall ChatHook0(void* s, void* e, int p, const char* t, int c, float d)
{ CHAT_THUNK_LOG(); return ChatHookCommon(0, s, e, p, t, c, d); }
static uint32_t __fastcall ChatHook1(void* s, void* e, int p, const char* t, int c, float d)
{ CHAT_THUNK_LOG(); return ChatHookCommon(1, s, e, p, t, c, d); }
static uint32_t __fastcall ChatHook2(void* s, void* e, int p, const char* t, int c, float d)
{ CHAT_THUNK_LOG(); return ChatHookCommon(2, s, e, p, t, c, d); }
static uint32_t __fastcall ChatHook3(void* s, void* e, int p, const char* t, int c, float d)
{ CHAT_THUNK_LOG(); return ChatHookCommon(3, s, e, p, t, c, d); }
static void* const kChatThunks[CHAT_MAX_SLOTS] = {
    (void*)&ChatHook0, (void*)&ChatHook1, (void*)&ChatHook2, (void*)&ChatHook3
};

//------------------------------------------------------------------------------
// v1.4.23：拦截聊天发送函数 game+0x241EA0 —— @ 命令只本地处理、不广播给盟友
//
// 逆向依据（v1.3.94~97 实机钉死，见 §7.5 直投聊天注释）：
//   发送函数 RVA 0x241EA0，__thiscall(this=本地玩家对象, text=裸 UTF-8 char*)，
//   序言 55 8B EC 6A FF 68 …（标准 SEH 序言，ret 4 = 1 个栈参）。
//   只被提交路径 game+0x3518B3 调用（玩家按回车那一下）。
//   提交路径在 call 之后还会清空输入框，所以【跳过发送函数】不会留下残留文本。
//
// 为什么要拦：聊天命令（@0/@1/@2/@3/@幸存者/@?/@! …）本会被广播给同局玩家，
//   这里在发送这一层拦下，本地照常处理（HandleChatCommand 已在游戏线程上）。
//------------------------------------------------------------------------------
#define WC3_RVA_CHAT_SEND 0x241EA0u
typedef void (__fastcall *fn_chat_send_t)(void* self, void* edx_dummy, const char* text);
static void*     g_chatSendTramp  = NULL;
static uint32_t  g_chatSendTarget = 0;

static void __fastcall ChatSendHook(void* self, void* edx_dummy, const char* text)
{
    int suppress = 0;
    __try {
        if (g_cfg.block_cmd && g_cfg.chat_cmd && text && text[0] && g_cfg.chat_prefix[0]) {
            const char* p = text;
            while (*p == ' ') ++p;
            if (strncmp(p, g_cfg.chat_prefix, strlen(g_cfg.chat_prefix)) == 0) {
                suppress = 1;   // 先决定拦截，再处理（处理失败也不广播出去）
                const int lid = LocalPlayerId();
                HandleChatCommand(lid, text);
                LogLine("拦截聊天命令（不广播）：玩家%d \"%s\"", lid, text);
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 聊天发送钩子异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
    }
    if (!suppress) {
        fn_chat_send_t orig = (fn_chat_send_t)(uintptr_t)g_chatSendTramp;
        if (orig) orig(self, edx_dummy, text);
    }
}

static void InitChatSendBlock()
{
    if (!g_cfg.block_cmd) {
        LogLine("拦截聊天命令：已按 ini 关闭（block_cmd=0），@ 命令会照常广播");
        return;
    }
    const uint32_t base = Wc3GameBase();
    if (!base) { LogLine("拦截聊天命令：拿不到 Game.dll 基址，跳过（@ 命令照常广播）"); return; }

    const uint32_t fn = base + WC3_RVA_CHAT_SEND;
    uint8_t b[5] = { 0 };
    __try { for (int i = 0; i < 5; ++i) b[i] = *(const uint8_t*)(uintptr_t)(fn + i); }
    __except (EXCEPTION_EXECUTE_HANDLER) { b[0] = 0; }
    if (!(b[0] == 0x55 && b[1] == 0x8B && b[2] == 0xEC && b[3] == 0x6A && b[4] == 0xFF)) {
        LogLine("拦截聊天命令：Game.dll+0x%X 序言 %02X %02X %02X %02X %02X 不符，版本可能不匹配，跳过",
                WC3_RVA_CHAT_SEND, b[0], b[1], b[2], b[3], b[4]);
        return;
    }

    int hops = 0;
    const uint32_t live = FollowJumps(fn, &hops);
    if (hops > 0) LogLine("拦截聊天命令：入口 %08X 已被挂钩，跟随 %d 跳到 %08X", fn, hops, live);

    void* tramp = NULL;
    const int stolen = InstallDetour(live, (void*)&ChatSendHook, &tramp);
    if (!stolen || !tramp) {
        LogLine("拦截聊天命令：挂钩失败（目标 %08X），@ 命令仍会照常广播", live);
        return;
    }
    g_chatSendTramp  = tramp;
    g_chatSendTarget = live;
    LogLine("拦截聊天命令：已挂钩发送函数 %08X（偷 %d 字节），@ 命令将只本地处理、不广播", live, stolen);
}

// v1.3.37：把一个绝对地址连同"模块〔?〕+ 模块基址 + 模块内偏〔?〕一起写进日志〔?〕
//   为什么需要：WFE 的钩子处理函数在 WFEDll.dll 里，〔?〕DLL 〔?〕ASLR（每局基址都不同）〔?〕
//   只记绝对地址没法离线反汇编它。记下模块基址就能算出稳定偏移〔?〕
static void LogAddrWithModule(const char* tag, uint32_t addr)
{
    char nm[64] = { 0 };
    uint32_t modBase = 0;
    __try {
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)(uintptr_t)addr, &mbi, sizeof(mbi)) && mbi.AllocationBase)
            modBase = (uint32_t)(uintptr_t)mbi.AllocationBase;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    Wc3ModuleNameOf(addr, nm, sizeof(nm));
    LogLine("%s %08X = %s+0x%X（模块基址 %08X）",
            tag, addr, nm[0] ? nm : "?", modBase ? (addr - modBase) : 0u, modBase);
}

//------------------------------------------------------------------------------
// v1.3.39【只读诊断】：挂钩 game+0x562E0 —〔?〕游戏"投递聊天事〔?〕的入〔?〕
//
// 依据〔?〕026-10-02 实机 + 磁盘核对）：WFE 的喊话就是在 WFEDll+0x5808D 〔?〕
//   call [WFEDll+0x1013CBBC] -> game.dll+0x562E0(this, 事件对象)〔?〕
//   而游戏自己打字时也走同一〔?〕0x562E0（那次是游戏代码调的）〔?〕
//   0x562E0 本体只有 17 字节：mov eax,[ebp+8] / mov edx,[ecx] / push eax /
//   push [eax+8] / call [edx+0x14] / ret 4 —〔?〕一个纯粹的"投〔?〕转发器〔?〕
//
// 本版【只观察，不改】：〔?〕(this, 事件对象) 和对象前 0x40 字节 dump 出来〔?〕
//   顺带把每个字段当指针试读可打印字符串。你发两条内容不同的聊天，两〔?〕dump 一对比〔?〕
//   文本字段的偏移立刻暴露，同时能看〔?〕this 是不是全局单例〔?〕
//   零副作用：不写游戏内存、不构造对象、只〔?〕+ 原样转发〔?〕
//------------------------------------------------------------------------------
#define CHAT_POST_RVA 0x562E0
static int PlausibleEntry(uint32_t a, int* outIsJump);   // 定义在下面（v1.3.33 那一段）
typedef void (__fastcall *fn_post_t)(void* self, void* edx_dummy, void* arg1);
static void*         g_postTramp    = NULL;
static volatile LONG g_postDiagLeft = 60;      // 〔?〕dump【带字符串的事件】，〔?〕60 〔?〕

static void DumpObjFields(const char* tag, uint32_t p, int bytes)
{
    if (!p) { LogLine("   %s = 0", tag); return; }
    char line[600];
    int n = _snprintf_s(line, sizeof(line), _TRUNCATE, "   %s %08X:", tag, p);
    __try {
        for (int i = 0; i < bytes; i += 4) {
            const uint32_t v = *(const uint32_t*)(uintptr_t)(p + i);
            n += _snprintf_s(line + n, sizeof(line) - n, _TRUNCATE, " [+%02X]=%08X", i, v);
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        n += _snprintf_s(line + n, sizeof(line) - n, _TRUNCATE, " (读异常");
    }
    LogLine("%s", line);

    // 每个字段当指针试读可打印〔?〕—〔?〕文本字段一眼可〔?〕
    for (int i = 0; i < bytes; i += 4) {
        __try {
            const uint32_t v = *(const uint32_t*)(uintptr_t)(p + i);
            if (v < 0x10000) continue;
            const char* s = (const char*)(uintptr_t)v;
            char tmp[64] = { 0 };
            int  ok = 1;
            for (int k = 0; k < 40; ++k) {
                const char c = s[k];
                if (c == 0) break;
                if ((unsigned char)c < 0x20 || (unsigned char)c > 0x7E) { ok = 0; break; }
                tmp[k] = c;
            }
            if (ok && tmp[0]) LogLine("      +%02X -> \"%s\"", i, tmp);
        } __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
}

// 读【内联】在 p 处的可打〔?〕ASCII 串（v1.3.41：聊天事件的文本是内联的，不是指针）
//   只认 ASCII：游戏内存里的中文会让整行日志的编码转换失败变乱码，这里是诊断用，够用就行〔?〕
static int PrintableStrInline(uint32_t p, char* out, int outBytes, int maxLen)
{
    if (out && outBytes > 0) out[0] = 0;
    if (p < 0x10000 || !out || outBytes < 4) return 0;
    __try {
        const char* s = (const char*)(uintptr_t)p;
        int i = 0;
        for (; i < outBytes - 1 && i < maxLen; ++i) {
            const unsigned char c = (unsigned char)s[i];
            if (c == 0) break;
            if (c < 0x20 || c > 0x7E) return 0;
            out[i] = (char)c;
        }
        out[i] = 0;
        return i > 0;
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

// v1.3.53：读内联〔?〕UTF-16（宽字符）串并压〔?〕ASCII —〔?〕游戏的编辑框很可能存宽字〔?〕
static int PrintableWStrInline(uint32_t p, char* out, int outBytes, int maxLen)
{
    if (out && outBytes > 0) out[0] = 0;
    if (p < 0x10000 || !out || outBytes < 4) return 0;
    __try {
        const uint16_t* s = (const uint16_t*)(uintptr_t)p;
        int i = 0;
        for (; i < outBytes - 1 && i < maxLen; ++i) {
            const uint16_t c = s[i];
            if (c == 0) break;
            if (c < 0x20 || c > 0x7E) return 0;      // 〔?〕ASCII 就当读失败（诊断够用〔?〕
            out[i] = (char)c;
        }
        out[i] = 0;
        return i > 0;
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

// v1.3.42：不〔?〕看到字符串就 dump"〔?〕x562E0 是通用事件投递，噪音太大），改成【精确匹配】：
//   投递时只把 (this, 事件对象) 记进环形缓冲；等聊天显示钩子拿到真实文本时，
//   回头找哪个对象的 +0x18（内联文本区）正好等于这串文〔?〕—〔?〕那个才是本次聊天的事件对象〔?〕
#define POST_RING 16
static volatile LONG g_postRingIdx = 0;
static uint32_t      g_postSelf[POST_RING] = { 0 };
static uint32_t      g_postObj [POST_RING] = { 0 };
static volatile LONG g_postDumpLeft = 6;

static int InlineStrEquals(uint32_t p, const char* text)
{
    if (!text || !text[0]) return 0;
    __try {
        const char* s = (const char*)(uintptr_t)p;
        for (int i = 0; ; ++i) {
            if (text[i] == 0) return s[i] == 0;
            if (s[i] != text[i]) return 0;
            if (i > 200) return 0;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return 0;
}

// v1.3.55：宽字符〔?〕—〔?〕本地打字发出去的消息在管线里〔?〕UTF-16
static int InlineWStrEquals(uint32_t p, const char* text)
{
    if (!text || !text[0]) return 0;
    __try {
        const uint16_t* s = (const uint16_t*)(uintptr_t)p;
        for (int i = 0; ; ++i) {
            if (text[i] == 0) return s[i] == 0;
            if (s[i] != (uint16_t)(unsigned char)text[i]) return 0;
            if (i > 200) return 0;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return 0;
}

// 在聊天显示钩子里调用：把"本次文本"和最近的投递记录对上，dump 出事件对象与 this
static void DumpMatchedChatEvent(const char* text)
{
    if (!text || !text[0]) return;
    if (InterlockedCompareExchange(&g_postDumpLeft, 0, 0) <= 0) return;
    for (int i = 0; i < POST_RING; ++i) {
        const uint32_t o = g_postObj[i];
        if (!o) continue;
        const int wide = InlineWStrEquals(o + 0x18, text);
        if (!wide && !InlineStrEquals(o + 0x18, text)) continue;
        if (InterlockedDecrement(&g_postDumpLeft) < 0) return;
        LogLine("P4 命中本次聊天事件：obj=%08X this=%08X +18=\"%s\"%s", o, g_postSelf[i], text,
                wide ? " 【宽字符】" : "");
        DumpObjFields("事件对象", o, 0x60);
        DumpObjFields("this 对象", g_postSelf[i], 0x20);
        return;
    }
}

static void __fastcall ChatPostHook(void* self, void* edx_dummy, void* arg1)
{
    const LONG k = InterlockedIncrement(&g_postRingIdx) - 1;
    const int  slot = (int)(k % POST_RING);
    g_postSelf[slot] = (uint32_t)(uintptr_t)self;
    g_postObj [slot] = (uint32_t)(uintptr_t)arg1;
    if (g_postTramp) ((fn_post_t)(uintptr_t)g_postTramp)(self, edx_dummy, arg1);
}

static void InitChatPostDiag()
{
    const uint32_t base = Wc3GameBase();
    if (!base) return;
    const uint32_t fn = base + CHAT_POST_RVA;

    int isJump = 0;
    if (!PlausibleEntry(fn, &isJump)) {
        LogLine("投递诊断：game+0x%X = %08X 入口不可信，跳过（不发聊天也能正常玩）", CHAT_POST_RVA, fn);
        return;
    }
    int hops = 0;
    const uint32_t live = FollowJumps(fn, &hops);
    if (hops > 0) LogLine("投递诊断：入口已被挂钩，跟随 %d 跳到 %08X", hops, live);

    void* tramp = NULL;
    const int stolen = InstallDetour(live, (void*)&ChatPostHook, &tramp);
    if (!stolen || !tramp) {
        LogLine("投递诊断：挂钩 %08X 失败（偷 %d 字节），跳过", live, stolen);
        return;
    }
    g_postTramp = tramp;
    LogAddrWithModule("投递诊断：已挂钩 =", live);
    LogLine("投递诊断：钩 %d 字节，跳到 %08X。请发【两条内容不同】的聊天，我来 dump 事件对象",
            stolen, (uint32_t)(uintptr_t)tramp);
}

//------------------------------------------------------------------------------
// v1.3.91 b) 钩【投递器的原始代码体】= game+0x562E0
//
// 为什么非钩它不可：
//   game+0x562E0 的入口被 WFE 改成了跳转 —— 游戏里【所有】聊天投递（自己打字按回车、
//   别人发来的、WFE 喊话）最终都会走到它的原始代码体。原始代码体只有 17 字节：
//       push ebp / mov ebp,esp / mov eax,[ebp+8] / mov edx,[ecx] / push eax /
//       push [eax+8] / call [edx+14] / pop ebp / ret 4
//   前 5 字节（push ebp / mov ebp,esp / mov eax,[ebp+8]）正好可以整条偷走，
//   于是我们可以用【正常的 __thiscall 等价签名】挂钩 —— 不需要签名无关 stub，
//   也不会栈不平衡。这样就能拿到真正的"聊天事件对象"：
//       事件对象 = 栈参数1；事件对象 + 0x00 = 虚表；+0x08 = 数据指针(被当参数1转发)
//
// 拿到对象后 dump 到文件（进程外读不到游戏内存，只能自己写自己读）。
//
// v1.4.0【已停用】：这段是为"插件自己发聊天"服务的逆向探针。
//   该功能已整体删除，InitDelivererHook() 不再被调用；
//   代码留着是因为逆向结论（game+0x562E0 被 WFE 改成 E9 跳转、候选地址怎么找）
//   写在这里，将来要再查聊天管线可以省一遍功夫。
//------------------------------------------------------------------------------
typedef uint32_t (__fastcall *fn_deliver_t)(void* self, void* edx_dummy, void* evtObj);
static void*         g_deliverTramp = NULL;
static uint32_t      g_deliverLive  = 0;
static volatile LONG g_deliverLeft  = 12;

static int      IsLikelyVtable(uint32_t vt);                    // 定义在后面
static uint32_t WfeModuleBaseForDump(void);                     // 定义在后面
static void     DumpPossibleVtables(const char* tag, uint32_t base, int bytes);  // 定义在后面

static uint32_t WfeModuleBaseForDump(void)
{
    HMODULE h = NULL;
    __try { h = GetModuleHandleA("WFEDll.dll"); }
    __except (EXCEPTION_EXECUTE_HANDLER) { h = NULL; }
    return (uint32_t)(uintptr_t)h;
}

static uint32_t __fastcall ChatDeliverHook(void* self, void* edx_dummy, void* evtObj)
{
    if (InterlockedDecrement(&g_deliverLeft) >= 0) {
        const uint32_t o = (uint32_t)(uintptr_t)evtObj;
        DumpText("");
        DumpText("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        DumpText("@@ v1.3.91 投递器 game+0x562E0(this=%08X, evt=%08X)", (uint32_t)(uintptr_t)self, o);
        DumpAddrInfo("投递器 this", (uint32_t)(uintptr_t)self);
        DumpAddrInfo("事件对象", o);
        if (o) {
            DumpPtrFields("事件对象字段", o, 0x80);
            DumpHex("事件对象原始字节", o, 0x80);
            // 事件对象 +0x08 会被投递器当参数1转发给 vtbl[0x14] —— 顺手 dump
            uint32_t p8 = 0;
            __try { p8 = *(const uint32_t*)(uintptr_t)(o + 8); }
            __except (EXCEPTION_EXECUTE_HANDLER) { p8 = 0; }
            if (p8 >= 0x10000) {
                DumpAddrInfo("事件对象+0x08（被转发的参数1）", p8);
                DumpPtrFields("+0x08 指向的对象字段", p8, 0x80);
                DumpHex("+0x08 指向的对象原始字节", p8, 0x80);
            }
        }
        DumpPossibleVtables("事件对象", o, 0x40);
        DumpText("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        DumpText("");
    }
    if (g_deliverTramp)
        return ((fn_deliver_t)(uintptr_t)g_deliverTramp)(self, edx_dummy, evtObj);
    return 0;
}

// WFE 模块基址（它每局 ASLR，只能运行时取）
static uint32_t wfe_module_base(void)
{
    uint32_t wfe = 0;
    __try {
        MEMORY_BASIC_INFORMATION mbi;
        if (g_chatSlotCount > 0 && g_chatTargets[0] &&
            VirtualQuery((LPCVOID)(uintptr_t)g_chatTargets[0], &mbi, sizeof(mbi)) && mbi.AllocationBase)
            wfe = (uint32_t)(uintptr_t)mbi.AllocationBase;
    } __except (EXCEPTION_EXECUTE_HANDLER) { wfe = 0; }
    if (!wfe) wfe = WfeModuleBaseForDump();
    return wfe;
}

// WFE 缓存的"投递器原始代码体"槽：WFEDll + 0x13CBBC
//   WFE 把 game+0x562E0 的入口改成 E9 跳到自己的处理函数，0x562E0 的【原始机器码】
//   被它复制到这个槽里（槽里是一条 E9 xx xx xx xx 跳转指令，不是函数指针）。
#define WFE_ORIG_DELIVERER_OFF 0x13CBBCu
static uint32_t wfe_orig_deliverer(void)
{
    const uint32_t wfe = wfe_module_base();
    if (!wfe) return 0;
    uint32_t orig = 0;
    __try { orig = *(const uint32_t*)(uintptr_t)(wfe + WFE_ORIG_DELIVERER_OFF); }
    __except (EXCEPTION_EXECUTE_HANDLER) { orig = 0; }
    return orig;
}

// v1.3.92：判断一个地址是不是"可以挂钩的函数入口"。
//   必须把 55 8B EC（push ebp / mov ebp,esp）单独放行 —— 之前复用的是"严格序言校验"，
//   它要求一段特征码，于是把 0x562E0 这种正常入口判成"不可信"，投递器钩子就装不上了。
static int LooksHookable(uint32_t a, int* outIsJump, uint32_t* outJumpTarget)
{
    if (outIsJump)     *outIsJump = 0;
    if (outJumpTarget) *outJumpTarget = 0;
    if (a < 0x10000) return 0;

    uint8_t b[8] = { 0 };
    int got = 0;
    __try {
        for (int i = 0; i < 8; ++i) b[i] = *(const uint8_t*)(uintptr_t)(a + i);
        got = 1;
    } __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
    if (!got) return 0;

    if (b[0] == 0xE9) {                                  // 被别人 Detours 挂钩
        int32_t rel = 0;
        __try { rel = *(const int32_t*)(uintptr_t)(a + 1); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
        const uint32_t tgt = a + 5 + (uint32_t)rel;
        if (outIsJump) *outIsJump = 1;
        if (outJumpTarget) *outJumpTarget = tgt;
        if (!Readable((const void*)(uintptr_t)tgt, 1)) return 0;
        return 1;
    }
    if (b[0] == 0x55 && b[1] == 0x8B && b[2] == 0xEC) return 1;   // push ebp; mov ebp,esp
    if (b[0] == 0x6A && b[1] == 0xFF && b[2] == 0x68) return 1;   // push -1; push seh
    if (b[0] == 0x83 && b[1] == 0xEC) return 1;                   // sub esp, imm8
    if (b[0] == 0x81 && b[1] == 0xEC) return 1;                   // sub esp, imm32
    if (b[0] == 0x53 && b[1] == 0x56 && b[2] == 0x57) return 1;   // push ebx/esi/edi
    return 0;
}

static void InitDelivererHook()
{
    if (!g_cfg.chat_diag) return;
    const uint32_t base = Wc3GameBase();
    if (!base) return;

    // 挂钩目标：game+0x562E0 的入口。
    //   WFE 把入口改成了 E9 跳到 WFEDll+0x57DC0，所以"直接执行的一段"是 WFE 的处理函数；
    //   但 0x562E0 的原机器码被 WFE 抄到了 WFEDll+0x13CBBC（槽里是一条 E9 指令）。
    //   两条都试，哪条能挂钩就用哪条。
    uint32_t cands[3] = { 0, 0, 0 };
    int nc = 0;
    cands[nc++] = base + 0x562E0;

    const uint32_t wfe = wfe_module_base();
    if (wfe) {
        // 先看 game+0x562E0 入口是不是跳转；是的话 WFE 的处理函数就是"实际执行"的那段
        int isJump = 0; uint32_t tgt = 0;
        if (LooksHookable(base + 0x562E0, &isJump, &tgt) && isJump && tgt) cands[nc++] = tgt;
        // WFE 抄下来的原机器码槽：槽里可能是 E9 跳转（跟到目标）
        if (LooksHookable(wfe + WFE_ORIG_DELIVERER_OFF, &isJump, &tgt)) {
            cands[nc++] = isJump && tgt ? tgt : (wfe + WFE_ORIG_DELIVERER_OFF);
        }
        LogLine("投递器诊断：候选挂钩点 = game+0x562E0=%08X、WFE 处理函数=%08X、WFE 原始码槽=%08X",
                base + 0x562E0, cands[1], (uint32_t)(wfe + WFE_ORIG_DELIVERER_OFF));
    }

    for (int i = 0; i < nc; ++i) {
        const uint32_t live = cands[i];
        if (!live) continue;
        int isJump = 0; uint32_t tgt = 0;
        if (!LooksHookable(live, &isJump, &tgt)) {
            LogLine("投递器诊断：候选 %08X 序言不认，跳过", live);
            continue;
        }
        // 先把序言解码结果写进日志（即使挂钩失败也能离线看出卡在哪一步）
        {
            char dec[200]; int dn = 0;
            for (int s = 0; s < 12 && dn < (int)sizeof(dec) - 16; ) {
                int len = DecodeInsnLen((const uint8_t*)(uintptr_t)(live + s));
                dn += _snprintf_s(dec + dn, sizeof(dec) - dn, _TRUNCATE, "+%d:%d ", s, len);
                if (len <= 0) break;
                s += len;
            }
            LogLine("投递器诊断：候选 %08X 序言 %02X %02X %02X %02X %02X %02X %02X %02X  解码=[%s]",
                    live,
                    *(const uint8_t*)(uintptr_t)(live + 0), *(const uint8_t*)(uintptr_t)(live + 1),
                    *(const uint8_t*)(uintptr_t)(live + 2), *(const uint8_t*)(uintptr_t)(live + 3),
                    *(const uint8_t*)(uintptr_t)(live + 4), *(const uint8_t*)(uintptr_t)(live + 5),
                    *(const uint8_t*)(uintptr_t)(live + 6), *(const uint8_t*)(uintptr_t)(live + 7),
                    dec);
        }
        void* tramp = NULL;
        const int stolen = InstallDetour(live, (void*)&ChatDeliverHook, &tramp);
        if (!stolen || !tramp) {
            LogLine("投递器诊断：挂钩候选 %08X 失败（偷 %d 字节），试下一个", live, stolen);
            continue;
        }
        g_deliverTramp = tramp;
        g_deliverLive  = live;
        LogAddrWithModule("投递器诊断：已挂钩 =", live);
        LogLine("投递器诊断：钩 %d 字节，跳到 %08X（事件对象会 dump 到 .dump.txt）",
                stolen, (uint32_t)(uintptr_t)tramp);
        return;
    }
    LogLine("投递器诊断：所有候选都挂钩失败，跳过（不影响游戏，显示钩子那条路照旧）");
}

//------------------------------------------------------------------------------
// v1.3.91：把【聊天显示钩子】里拿到的事件对象原样 dump 到文件
//
// 为什么要写文件而不是写日志：
//   1) 游戏是 WFE 以管理员身份起来的，进程外 OpenProcess 被拒 —— 只能靠我们自己读自己写；
//   2) 日志行会被截断/编码转换，原始字节写文件更可靠（离线可以直接对 Game.dll 反汇编）。
//
// 这里 dump 的东西正好是"注入聊天"要的全部信息：
//   - 显示钩子的 (self, text)：self 就是游戏传进来的那个对象（很可能是聊天事件对象）
//   - 以 self 和 text 为锚点，把周围 0x200 字节里的"每个 dword"当指针解释一遍
//     -> 哪个字段是宽字符文本、哪个字段是虚表，一眼可见
//   - 从 self 里翻出所有像虚表的指针，把虚表整张 dump 出来（槽 -> 模块+偏移）
//------------------------------------------------------------------------------
static volatile LONG g_evDumpLeft = 12;      // 最多 dump 12 条聊天事件，防刷屏

static void DumpPossibleVtables(const char* tag, uint32_t base, int bytes)
{
    for (int i = 0; i < bytes; i += 4) {
        uint32_t v = 0;
        __try { v = *(const uint32_t*)(uintptr_t)(base + i); }
        __except (EXCEPTION_EXECUTE_HANDLER) { continue; }
        if (v < 0x10000) continue;
        if (!IsLikelyVtable(v)) continue;
        DumpText("%s 的 +%03X 看着像虚表 -> %08X", tag, i, v);
        DumpHex("虚表", v, 0x80);
        DumpPtrFields("虚表槽", v, 0x80);
    }
}

static void DumpChatEventToFile(int slot, void* self, void* edx_dummy, int playerId,
                                const char* text, int ctype)
{
    if (InterlockedDecrement(&g_evDumpLeft) < 0) return;
    char nm[64] = { 0 };
    uint32_t mod = 0;
    __try {
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery(self, &mbi, sizeof(mbi)) && mbi.AllocationBase)
            mod = (uint32_t)(uintptr_t)mbi.AllocationBase;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    Wc3ModuleNameOf((uint32_t)(uintptr_t)self, nm, sizeof(nm));

    DumpText("");
    DumpText("############################################################");
    DumpText("## v1.3.91 聊天事件 dump  槽=%d  玩家=%d  ctype=%d  文本=\"%s\"",
             slot, playerId, ctype, text ? text : "");
    DumpText("## 本 DLL  = %08X", (uint32_t)(uintptr_t)g_hSelf);
    DumpText("## Game.dll= %08X   WFEDll= %08X", Wc3GameBase(), WfeModuleBaseForDump());
    DumpAddrInfo("显示钩子 self", (uint32_t)(uintptr_t)self);
    DumpAddrInfo("显示钩子 text", (uint32_t)(uintptr_t)text);
    DumpText("## 文本里出现标记 -> 这条就是本地玩家自己发的那条");
    DumpText("## self 所在模块归属: %s+0x%X", nm[0] ? nm : "?", mod ? ((uint32_t)(uintptr_t)self - mod) : 0u);

    // self 前后各 0x100 字节：对象头 + 邻居（虚表/引用计数/文本缓冲都在这段里）
    uint32_t s = (uint32_t)(uintptr_t)self;
    if (s > 0x200) {
        DumpHex("self-0x100 起 0x300 字节", s - 0x100, 0x300);
        DumpPtrFields("self-0x100 起字段解释", s - 0x100, 0x300);
        DumpPossibleVtables("self-0x100", s - 0x100, 0x300);
    }
    // 直接以 self 为对象头再 dump 一遍（对象布局最常见的读法）
    if (s) {
        DumpHex("self(+0) 起 0x200 字节", s, 0x200);
        DumpPtrFields("self(+0) 字段解释", s, 0x200);
        DumpPossibleVtables("self(+0)", s, 0x200);
    }
    if (text) {
        uint32_t t = (uint32_t)(uintptr_t)text;
        if (t > 0x100) {
            DumpHex("text-0x80 起 0x180 字节", t - 0x80, 0x180);
            DumpPtrFields("text-0x80 字段解释", t - 0x80, 0x180);
        }
    }
    DumpText("############################################################");
    DumpText("");
}

//------------------------------------------------------------------------------
// v1.3.45：签名无关探针钩子（safe probe hook）—— 用来安全地观察"参数个数未知"的深层函数
//
// 为什么必须这么做：v1.3.32 〔?〕猜参数个〔?〕的方式转发，把栈搞不平衡〔?〕*直接把游戏搞崩过**〔?〕
// 现在改成手写 stub：进入时把现场全存下〔?〕〔?〕调用记录函数 〔?〕**原样恢复现场** 〔?〕跳到跳板
// （跳〔?〕= 偷来的原始字〔?〕+ jmp 〔?〕target+偷走的长度）。这样无论目标有几个参数〔?〕
// 由谁来清栈（ret N / cdecl），栈和寄存器都〔?〕没挂〔?〕时完全一致〔?〕
//
// 保存内容：EFLAGS + EAX/ECX/EDX/EBX/ESP/EBP/ESI/EDI（pushfd + pushad〔?〕
//          + XMM0~7（movups；我们的记录函数〔?〕C 代码，可能用 SSE，不保存会污染游戏里的浮点中间值）
//
// 记录函数看到〔?〕savedRegs 布局（pushad 的顺序）〔?〕
//   [0]=EDI [1]=ESI [2]=EBP [3]=ESP(=进入时的 esp-4) [4]=EBX [5]=EDX [6]=ECX [7]=EAX [8]=EFLAGS
//   于是：ecx=saved[6]、edx=saved[5]、第 1 个栈参数 = *(saved[3]+8)、第 2 〔?〕= *(saved[3]+12)
//------------------------------------------------------------------------------
static volatile LONG g_probeLeft = 60;          // 探针打印上限（防刷屏〔?〕
static uint32_t      g_probeLastSig = 0;        // v1.3.46：参数与上一条相同就不打（剔除高频同参事件）
static DWORD         g_probeLastMs[2] = { 0, 0 };   // v1.3.47：每个探针的时间节流〔?〕=200ms 才允许下一条）

static int ProbeSigIsNew(uint32_t sig)
{
    if (sig == g_probeLastSig) return 0;
    g_probeLastSig = sig;
    return 1;
}

// v1.3.47：时间节〔?〕+ 事件内容过滤 —〔?〕只在"看起来是聊天事件"时才记录
static int ProbeThrottleOk(int which)
{
    const DWORD now = GetTickCount();
    if (g_probeLastMs[which] && (now - g_probeLastMs[which]) < 200) return 0;
    g_probeLastMs[which] = now;
    return 1;
}

static uint8_t* BuildProbeStub(void* logger, uint8_t* tramp)
{
    uint8_t* s = (uint8_t*)VirtualAlloc(NULL, 160, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!s) return NULL;
    int i = 0;
    s[i++] = 0x9C;                                                  // pushfd
    s[i++] = 0x60;                                                  // pushad
    s[i++] = 0x8B; s[i++] = 0xEC;                                   // mov ebp, esp
    s[i++] = 0x81; s[i++] = 0xEC; s[i++] = 0x80; s[i++] = 0x00;
    s[i++] = 0x00; s[i++] = 0x00;                                   // sub esp, 128
    s[i++] = 0x83; s[i++] = 0xE4; s[i++] = 0xF0;                    // and esp, -16
    for (int k = 0; k < 8; ++k) {                                   // movups [esp+k*16], xmmK
        s[i++] = 0x0F; s[i++] = 0x11;
        s[i++] = (uint8_t)(0x44 | (k << 3));
        s[i++] = 0x24;
        s[i++] = (uint8_t)(k * 16);
    }
    s[i++] = 0x55;                                                  // push ebp（参〔?〕= savedRegs〔?〕
    s[i++] = 0xE8;                                                  // call logger
    *(int32_t*)(s + i) = (int32_t)((intptr_t)logger - (intptr_t)(s + i + 4)); i += 4;
    s[i++] = 0x83; s[i++] = 0xC4; s[i++] = 0x04;                    // add esp, 4
    for (int k = 0; k < 8; ++k) {                                   // movups xmmK, [esp+k*16]
        s[i++] = 0x0F; s[i++] = 0x10;
        s[i++] = (uint8_t)(0x44 | (k << 3));
        s[i++] = 0x24;
        s[i++] = (uint8_t)(k * 16);
    }
    s[i++] = 0x8B; s[i++] = 0xE5;                                   // mov esp, ebp
    s[i++] = 0x61;                                                  // popad
    s[i++] = 0x9D;                                                  // popfd
    s[i++] = 0xE9;                                                  // jmp tramp
    *(int32_t*)(s + i) = (int32_t)((intptr_t)tramp - (intptr_t)(s + i + 4)); i += 4;
    FlushInstructionCache(GetCurrentProcess(), s, (SIZE_T)i);
    return s;
}

static int InstallProbeHook(uint32_t target, void* logger)
{
    int stolen = 0;
    while (stolen < 5) {
        const int len = DecodeInsnLen((const uint8_t*)(uintptr_t)(target + stolen));
        if (len <= 0 || stolen + len > 24) return 0;
        stolen += len;
    }
    for (int i = 0; i < stolen; ++i) {                 // 相对跳转不能照抄进跳〔?〕
        const uint8_t b = *(const uint8_t*)(uintptr_t)(target + i);
        if (b == 0xE8 || b == 0xE9 || b == 0xEB) return 0;
    }
    uint8_t* tramp = (uint8_t*)VirtualAlloc(NULL, (SIZE_T)stolen + 8,
                                            MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!tramp) return 0;
    memcpy(tramp, (const void*)(uintptr_t)target, (size_t)stolen);
    tramp[stolen] = 0xE9;
    *(int32_t*)(tramp + stolen + 1) =
        (int32_t)((intptr_t)(target + stolen) - (intptr_t)(tramp + stolen + 5));

    uint8_t* stub = BuildProbeStub(logger, tramp);
    if (!stub) { VirtualFree(tramp, 0, MEM_RELEASE); return 0; }

    DWORD oldProt = 0;
    if (!VirtualProtect((void*)(uintptr_t)target, (SIZE_T)stolen,
                        PAGE_EXECUTE_READWRITE, &oldProt)) {
        VirtualFree(tramp, 0, MEM_RELEASE);
        VirtualFree(stub, 0, MEM_RELEASE);
        return 0;
    }
    uint8_t* t = (uint8_t*)(uintptr_t)target;
    t[0] = 0xE9;
    *(int32_t*)(t + 1) = (int32_t)((intptr_t)stub - (intptr_t)(target + 5));
    for (int i = 5; i < stolen; ++i) t[i] = 0x90;
    VirtualProtect((void*)(uintptr_t)target, (SIZE_T)stolen, oldProt, &oldProt);
    FlushInstructionCache(GetCurrentProcess(), (void*)(uintptr_t)target, (size_t)stolen);
    return stolen;
}

//------------------------------------------------------------------------------
// v1.3.48：探针改成【内存环形缓〔?〕+ 由聊天显示钩子触〔?〕dump〔?〕
//   为什么：0x562E0 / 0x56340 是高频事件入口，直接写日志会被刷屏、被节流吃掉〔?〕
//   真正想看的那几次反而丢了。现在探针只往环形缓冲里塞一条紧凑记录（〔?〕I/O、不过滤），
//   等聊天显示钩子拿到消息时，再〔?〕最〔?〕20 〔?〕打出〔?〕—〔?〕那里面必然包含这条消息的投递与处理〔?〕
//------------------------------------------------------------------------------
struct ProbeRec {
    DWORD    ms;
    uint8_t  which;          // 1=投递器真身  2=0x56340
    uint8_t  pad[3];
    uint32_t ecx, edx, a1, a2;
    char     s1[32];
    char     s2[32];
};
#define PROBE_RING 512
static ProbeRec      g_probeRing[PROBE_RING];
static volatile LONG g_probeRingN = 0;
static volatile LONG g_probeDumps = 8;

// v1.3.52：输入框虚表探针【单独一个环】〔?〕
//   为什么：0x562E0 / 0x56340 每秒几千上万次，共用〔?〕512 条环瞬间就被冲掉〔?〕
//   真正想看的虚表调用（按回车那一下）根本留不住。所以虚表探针写自己的环〔?〕
struct VtRec {
    DWORD    ms;
    int      slot;
    uint32_t self, a1, a2;
    char     txt[48];
};
#define VT_RING 256
static VtRec         g_vtRing[VT_RING];
static volatile LONG g_vtRingN = 0;

static void VtRingAdd(int slot, uint32_t self, uint32_t a1, uint32_t a2, const char* txt)
{
    const LONG n = InterlockedIncrement(&g_vtRingN) - 1;
    VtRec& r = g_vtRing[n % VT_RING];
    r.ms = GetTickCount();
    r.slot = slot; r.self = self; r.a1 = a1; r.a2 = a2;
    r.txt[0] = 0;
    if (txt && txt[0]) strncpy_s(r.txt, sizeof(r.txt), txt, _TRUNCATE);
}

static void DumpVtRing(const char* note)
{
    const LONG total = InterlockedCompareExchange(&g_vtRingN, 0, 0);
    LogLine("V 输入框虚表环：共 %d 条（%s）", (int)total, note ? note : "");
    if (total <= 0) return;
    const LONG show = (total > 40) ? 40 : total;
    const LONG from = total - show;
    for (LONG i = from; i < total; ++i) {
        const VtRec& r = g_vtRing[i % VT_RING];
        LogLine("   P3#%d t=%u 槽=%d self=%08X a1=%08X a2=%08X 文本=\"%s\"",
                (int)i, (unsigned)r.ms, r.slot, r.self, r.a1, r.a2, r.txt);
    }
}

// v1.3.49：在探针里主〔?〕搜集候选字符串"——不再猜固定偏移，而是把能读到的可打印串都记下来，
//   等聊天显示时用真实文本反查，命中的那条就是这次消息走过的调用〔?〕
static void ProbeCollectStrings(uint32_t obj, char* out1, int n1, char* out2, int n2)
{
    out1[0] = 0; out2[0] = 0;
    if (!obj || obj < 0x10000) return;
    __try {
        // 〔?〕对象内联 +0x18（历史上的嫌疑偏移）
        PrintableStrInline(obj + 0x18, out1, n1, n1 - 2);
        // ①b v1.3.55：同一位置也可能是【宽字符】——本地打字发出去的消息走的就是宽字符〔?〕
        //     这正是以〔?〕按文本反查一直未命中"的原因（只认 ASCII 当然找不到）〔?〕
        if (!out1[0]) PrintableWStrInline(obj + 0x18, out1, n1, n1 - 2);
        if (!out1[0]) PrintableWStrInline(obj + 0x10, out1, n1, n1 - 2);
        // 〔?〕对象 +8 指向的那个对象，内联 +0x18
        const uint32_t sub = *(const uint32_t*)(uintptr_t)(obj + 8);
        if (sub >= 0x10000 && !out1[0]) PrintableStrInline(sub + 0x18, out1, n1, n1 - 2);
        if (sub >= 0x10000 && !out1[0]) PrintableWStrInline(sub + 0x18, out1, n1, n1 - 2);
        // 〔?〕扫对象前 0x80 字节：哪〔?〕dword 指向可打印串〔?〕=4 字符〔?〕
        for (int off = 0; off < 0x80 && !out2[0]; off += 4) {
            const uint32_t v = *(const uint32_t*)(uintptr_t)(obj + off);
            if (v < 0x10000) continue;
            char tmp[48] = { 0 };
            if ((PrintableStrInline(v, tmp, sizeof(tmp), 44) || PrintableWStrInline(v, tmp, sizeof(tmp), 44))
                && strlen(tmp) >= 4) {
                if (!out1[0]) { strncpy_s(out1, n1, tmp, _TRUNCATE); }
                else if (strcmp(tmp, out1) != 0) { strncpy_s(out2, n2, tmp, _TRUNCATE); }
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
}

static void ProbeRingAdd(int which, uint32_t ecx, uint32_t edx,
                         uint32_t a1, uint32_t a2, const char* s1, const char* s2)
{
    const LONG n = InterlockedIncrement(&g_probeRingN) - 1;
    ProbeRec& r = g_probeRing[n % PROBE_RING];
    r.ms = GetTickCount();
    r.which = (uint8_t)which;
    r.ecx = ecx; r.edx = edx; r.a1 = a1; r.a2 = a2;
    r.s1[0] = 0; r.s2[0] = 0;
    if (s1 && s1[0]) strncpy_s(r.s1, sizeof(r.s1), s1, _TRUNCATE);
    if (s2 && s2[0]) strncpy_s(r.s2, sizeof(r.s2), s2, _TRUNCATE);
}

static void DumpProbeRing(const char* note)
{
    if (InterlockedDecrement(&g_probeDumps) < 0) return;
    const LONG total = InterlockedCompareExchange(&g_probeRingN, 0, 0);

    // v1.3.49：按"本次显示的文〔?〕反查命中条目（探针里搜集的候选串里找〔?〕
    LONG hit = -1;
    if (note && note[0]) {
        const LONG lim = (total > 400) ? (total - 400) : 0;
        for (LONG i = total - 1; i >= lim; --i) {
            const ProbeRec& r = g_probeRing[i % PROBE_RING];
            if ((r.s1[0] && strstr(r.s1, note)) || (r.s2[0] && strstr(r.s2, note))) { hit = i; break; }
        }
    }
    LogLine("R 探针环：共 %d 条，按文本\"%s\"反查 -> %s", (int)total,
            note ? note : "", hit >= 0 ? "命中" : "未命中");

    LONG from, to;
    if (hit >= 0) { from = (hit > 6) ? (hit - 6) : 0; to = hit + 2; }
    else          { from = (total > 10) ? (total - 10) : 0; to = total - 1; }

    for (LONG i = from; i <= to; ++i) {
        const ProbeRec& r = g_probeRing[i % PROBE_RING];
        LogLine("   %sP%d t=%u ecx=%08X edx=%08X a1=%08X a2=%08X | s1=\"%s\" s2=\"%s\"",
                (i == hit) ? ">>" : "  ", (int)r.which, (unsigned)r.ms,
                r.ecx, r.edx, r.a1, r.a2, r.s1, r.s2);
    }
}

// 探针①：原始投递器（game+0x562E0 的真身，入口〔?〕WFE 挂钩了，真身指针〔?〕WFEDll 里）
//------------------------------------------------------------------------------
// v1.3.88【直调投递·步骤 1】观察：本地玩家自己发聊天时，把经过的函数与参数原样记下来。
//
//   为什么：文档《WFE喊话机制与聊天管线逆向.md》§6 说“深层函数的参数个数/调用约定
//   未确认，猜参数个数转发会栈不平衡 -> 崩”。所以先观察真实参数，再决定怎么直调。
//
//   观察手法：记下“本次要发的文本”，然后在探针里比对“这个参数指向的内存里有没有
//   这串文本” —— 命中者即“消息”参数。不靠猜，靠文本匹配。
//------------------------------------------------------------------------------
static char g_probeSelfText[256] = { 0 };

static void ProbeMarkSelfText(const char* t)
{
    if (!t) { g_probeSelfText[0] = 0; return; }
    strncpy_s(g_probeSelfText, sizeof(g_probeSelfText), t, _TRUNCATE);
}

// addr 起 span 字节内是否出现本次文本
static int MemHasSelfText(uint32_t addr, int span)
{
    if (!addr || !g_probeSelfText[0]) return 0;
    const size_t len = strlen(g_probeSelfText);
    if (len < 2) return 0;
    __try {
        for (int off = 0; off < span; ++off) {
            const uint32_t q = addr + (uint32_t)off;
            if (!Readable((const void*)(uintptr_t)q, len)) continue;
            if (memcmp((const void*)(uintptr_t)q, g_probeSelfText, len) == 0) return 1;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return 0;
}

// 把一次观察写成一行日志：每个候选参数都标出“像不像消息”
static void ProbeLogOutbound(const char* where, const uint32_t* r)
{
    if (!g_probeSelfText[0]) return;
    const uint32_t sp = r[3];
    uint32_t a1 = 0, a2 = 0, a3 = 0;
    __try {
        a1 = *(const uint32_t*)(uintptr_t)(sp + 8);
        a2 = *(const uint32_t*)(uintptr_t)(sp + 12);
        a3 = *(const uint32_t*)(uintptr_t)(sp + 16);
    } __except (EXCEPTION_EXECUTE_HANDLER) { }

    const int mEcx = MemHasSelfText(r[6], 64);
    const int mEdx = MemHasSelfText(r[5], 64);
    const int mA1  = MemHasSelfText(a1, 64);
    const int mA2  = MemHasSelfText(a2, 64);
    const int mA3  = MemHasSelfText(a3, 64);
    uint32_t dEcx = 0, dA1 = 0;
    __try {
        dEcx = r[6] ? *(const uint32_t*)(uintptr_t)r[6] : 0;
        dA1  = a1   ? *(const uint32_t*)(uintptr_t)a1   : 0;
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    const int mEcxP = MemHasSelfText(dEcx, 64);
    const int mA1P  = MemHasSelfText(dA1, 64);

    // v1.3.89：只在【命中】时才写日志 —— 否则每个聊天事件都写，会刷爆日志（实测 23 万条/几分钟）。
    if (!(mEcx || mEdx || mA1 || mA2 || mA3 || mEcxP || mA1P)) return;
    LogLine("[v1.3.89] 命中! outbound %s: ecx=%08X(hit=%d,deref=%08X,hit=%d) edx=%08X(hit=%d)"
            " a1=%08X(hit=%d,deref=%08X,hit=%d) a2=%08X(hit=%d) a3=%08X(hit=%d) sp=%08X",
            where, r[6], mEcx, dEcx, mEcxP, r[5], mEdx,
            a1, mA1, dA1, mA1P, a2, mA2, a3, mA3, sp);
}

static void __cdecl ProbeLogPost(void* regs)
{
    ProbeLogOutbound("投递器", (const uint32_t*)regs);
    const uint32_t* r = (const uint32_t*)regs;
    const uint32_t  sp = r[3];
    __try {
        const uint32_t obj = *(const uint32_t*)(uintptr_t)(sp + 8);      // 〔?〕1 个栈参数
        char c1[48] = { 0 }, c2[48] = { 0 };
        ProbeCollectStrings(obj, c1, sizeof(c1), c2, sizeof(c2));
        ProbeRingAdd(1, r[6], r[5], obj,
                     obj ? *(const uint32_t*)(uintptr_t)(obj + 8) : 0, c1, c2);
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
}

// 探针②：聊天事件处理〔?〕game+0x56340
static void __cdecl ProbeLog56340(void* regs)
{
    ProbeLogOutbound("0x56340", (const uint32_t*)regs);
    const uint32_t* r = (const uint32_t*)regs;
    const uint32_t  sp = r[3];
    __try {
        const uint32_t a1 = *(const uint32_t*)(uintptr_t)(sp + 8);
        const uint32_t a2 = *(const uint32_t*)(uintptr_t)(sp + 12);
        char c1[48] = { 0 }, c2[48] = { 0 };
        ProbeCollectStrings(a1, c1, sizeof(c1), c2, sizeof(c2));
        if (!c1[0]) PrintableStrInline(a1, c1, sizeof(c1), 44);      // 参数本身就是字符串的情况
        if (!c2[0]) PrintableStrInline(a2, c2, sizeof(c2), 44);
        ProbeRingAdd(2, r[6], r[5], a1, a2, c1, c2);
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
}

static void InitDelivererHook();   // v1.4.0：不再调用（见上面"已停用"说明）

static void InitProbeHooks()
{
    if (!g_cfg.chat_diag) return;          // 只在 chat_diag=1 时安装（平时绝不碰游戏代码）
    const uint32_t base = Wc3GameBase();
    if (!base) return;

    // 〔?〕聊天事件处理〔?〕0x56340：正常序言，直接挂〔?〕
    {
        const uint32_t fn = base + 0x56340;
        int isJump = 0;
        if (PlausibleEntry(fn, &isJump) && !isJump) {
            const int st = InstallProbeHook(fn, (void*)&ProbeLog56340);
            LogLine("探针②：0x56340（聊天事件处理器）%s（偷 %d 字节）", st ? "已挂钩" : "挂钩失败", st);
        } else {
            LogLine("探针②：0x56340 入口不可信（isJump=%d），跳过", isJump);
        }
    }

    // 〔?〕投递器真身〔?〕x562E0 入口〔?〕WFE 改成跳转，真身指针被 WFE 存在 WFEDll+0x1013CBBC
    if (g_chatSlotCount > 0 && g_chatTargets[0]) {
        uint32_t wfe = 0;
        __try {
            MEMORY_BASIC_INFORMATION mbi;
            if (VirtualQuery((LPCVOID)(uintptr_t)g_chatTargets[0], &mbi, sizeof(mbi)))
                wfe = (uint32_t)(uintptr_t)mbi.AllocationBase;
        } __except (EXCEPTION_EXECUTE_HANDLER) { }
        if (wfe) {
            uint32_t orig = 0;
            // 〔?〕0x1013CBBC 是【首选基址 0x10000000 下的 VA】，运行时有 ASLR〔?〕
            //   所以模块内偏移〔?〕0x1013CBBC - 0x10000000 = 0x13CBBC（v1.3.46 修）
            __try { orig = *(const uint32_t*)(uintptr_t)(wfe + 0x13CBBC); }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
            int isJump = 0;
            if (orig && PlausibleEntry(orig, &isJump)) {
                const int st = InstallProbeHook(orig, (void*)&ProbeLogPost);
                LogLine("探针①：投递器真身 %08X（WFE +0x13CBBC）%s（偷 %d 字节）",
                        orig, st ? "已挂钩" : "挂钩失败", st);
            } else {
                LogLine("探针①：WFE 里的投递器指针 %08X 不可信，跳过（模块基址 %08X）", orig, wfe);
            }
        }
    }
    LogLine("探针：安装完成（chat_diag=1 才有；记录函数只读内存，不改游戏数据）");
    // v1.4.0：这里原来还会装 InitDelivererHook()（钩聊天投递器原始代码体）。
    //   那是为"插件自己发聊天"服务的逆向探针，已随该功能一起删除。
}

//------------------------------------------------------------------------------
// v1.3.50：定〔?〕聊天输入框对〔?〕并给它的虚表方法挂探〔?〕—〔?〕〔?〕提交入口"
//
//   〔?〕用户在聊天框里【只输入、不发送】一串独特标记（ini: chat_marker=ZZMARK123）；
//   〔?〕插件扫进程内存找到这串标〔?〕-> 命中处就是【聊天输入框的文本缓冲】；
//   〔?〕从命中处往回找"像虚表指〔?〕〔?〕dword（它指向的内存第一〔?〕dword 落在 Game.dll 〔?〕.text〔?〕
//      -> 得到【输入框对象基址 + 虚表地址 + 文本缓冲偏移】；
//   〔?〕把虚表前 12 个方法全部用【签名无〔?〕stub】挂上探针（只读记录，进环形缓冲）；
//   〔?〕用户按回车把标记发出〔?〕-> 哪个槽被调到 = 提交入口（this 就是输入框对象）〔?〕
//
//   落地时只需：把我们的文本写进那个缓〔?〕-> 调那个槽 -> 等价〔?〕人打〔?〕回车"，完全不碰键盘〔?〕
//------------------------------------------------------------------------------
#define CHAT_VT_SLOTS 12
static volatile LONG g_markDone    = 0;
static uint32_t      g_markObj     = 0;
static uint32_t      g_markVtbl    = 0;
static uint32_t      g_markTextOff = 0;
static uint32_t      g_markTextPtr = 0;   // v1.3.52：文本缓冲【本身】的地址（可能不在对象内，是单独分配的）
static int           g_markTextWide = 0;  // v1.3.53：这个缓冲是 UTF-16（宽字符〔?〕
static volatile LONG g_vtDumps     = 24;

static void ProbeVtCommon(int slot, void* regs);

#define VT_THUNK(n) static void __cdecl ProbeVt##n(void* regs) { ProbeVtCommon(n, regs); }
VT_THUNK(0)  VT_THUNK(1)  VT_THUNK(2)  VT_THUNK(3)
VT_THUNK(4)  VT_THUNK(5)  VT_THUNK(6)  VT_THUNK(7)
VT_THUNK(8)  VT_THUNK(9)  VT_THUNK(10) VT_THUNK(11)
static void* const kVtThunks[CHAT_VT_SLOTS] = {
    (void*)&ProbeVt0, (void*)&ProbeVt1, (void*)&ProbeVt2,  (void*)&ProbeVt3,
    (void*)&ProbeVt4, (void*)&ProbeVt5, (void*)&ProbeVt6,  (void*)&ProbeVt7,
    (void*)&ProbeVt8, (void*)&ProbeVt9, (void*)&ProbeVt10, (void*)&ProbeVt11
};

static void ProbeVtCommon(int slot, void* regs)
{
    const uint32_t* r = (const uint32_t*)regs;
    const uint32_t  sp = r[3];
    __try {
        const uint32_t self = r[6];
        const uint32_t a1 = *(const uint32_t*)(uintptr_t)(sp + 8);
        const uint32_t a2 = *(const uint32_t*)(uintptr_t)(sp + 12);
        char txt[48] = { 0 };
        if (g_markTextPtr) {                                 // v1.3.52：优先直接读"缓冲本身"
            if (g_markTextWide) PrintableWStrInline(g_markTextPtr, txt, sizeof(txt), 44);
            else                PrintableStrInline(g_markTextPtr, txt, sizeof(txt), 44);
        }
        if (!txt[0] && g_markObj && g_markTextOff)
            PrintableStrInline(g_markObj + g_markTextOff, txt, sizeof(txt), 44);
        ProbeRingAdd(3, self, (uint32_t)slot, a1, a2, txt, "");   // which=3：输入框虚表方法；edx=槽号
        VtRingAdd(slot, self, a1, a2, txt);                       // v1.3.52：同时写专用环（不被高频探针冲掉〔?〕
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
}

static DWORD WINAPI VtRingDumper(LPVOID)
{
    for (int k = 0; k < 10; ++k) {
        Sleep(3000);
        if (InterlockedDecrement(&g_vtDumps) < 0) break;
        DumpVtRing("按回车把标记发出去 -> 哪个槽被调到就是提交入口");
    }
    return 0;
}

static void HookVtblSlots(uint32_t vt)
{
    int ok = 0;
    for (int i = 0; i < CHAT_VT_SLOTS; ++i) {
        uint32_t fn = 0;
        __try { fn = *(const uint32_t*)(uintptr_t)(vt + i * 4); }
        __except (EXCEPTION_EXECUTE_HANDLER) { fn = 0; }
        if (!fn || fn < 0x10000) break;
        char nm[64] = { 0 };
        Wc3ModuleNameOf(fn, nm, sizeof(nm));
        int isJump = 0;
        if (!PlausibleEntry(fn, &isJump)) {
            LogLine("   虚表槽%02d -> %08X (%s) 入口不可信，跳过", i, fn, nm[0] ? nm : "?");
            continue;
        }
        int hops = 0;
        const uint32_t live = FollowJumps(fn, &hops);
        const int st = InstallProbeHook(live, kVtThunks[i]);
        LogLine("   虚表第%02d -> %08X (%s)%s %s（偷 %d 字节）", i, fn, nm[0] ? nm : "?",
                hops ? " [跟跳到]" : "", st ? "已挂探针" : "挂失败", st);
        if (st) ++ok;
    }
    LogLine("输入框虚表：共挂了 %d 个探针（现在请按回车把标记发出去；日志会打出哪个槽被调到）", ok);
    if (ok) {
        HANDLE h = CreateThread(NULL, 0, VtRingDumper, NULL, 0, NULL);
        if (h) CloseHandle(h);
    }
}

// v1.3.52：反向找"谁持有这个文本缓冲的指针"
//   聊天输入框大概率〔?〕std::string 一类结构：对象里只有一个指向堆缓冲的指针，
//   所以缓冲旁边看不到对象〔?〕虚表。反过来〔?〕哪个 dword == 缓冲地址"就能找到持有者，
//   再从中往回找虚表指针 => 输入框对象〔?〕
static int FindObjectByPointer(uint32_t target, uint32_t* outObj, uint32_t* outVt)
{
    const uint32_t base = Wc3GameBase();
    uint32_t tStart = 0, tSize = 0;
    if (!base || !Wc3TextRange(base, &tStart, &tSize)) return 0;

    char buf[8192];
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    uint32_t a = (uint32_t)(uintptr_t)si.lpMinimumApplicationAddress;
    const uint32_t aMax = (uint32_t)(uintptr_t)si.lpMaximumApplicationAddress;
    int holders = 0;

    while (a < aMax) {
        MEMORY_BASIC_INFORMATION mbi;
        if (!VirtualQuery((LPCVOID)(uintptr_t)a, &mbi, sizeof(mbi))) break;
        const uint32_t rbase = (uint32_t)(uintptr_t)mbi.BaseAddress;
        const uint32_t rsize = (uint32_t)mbi.RegionSize;
        const int readable = (mbi.State == MEM_COMMIT) &&
            (mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                            PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)) &&
            !(mbi.Protect & PAGE_GUARD);
        if (readable && rsize >= 0x1000) {
            for (uint32_t p = rbase; p + 8 < rbase + rsize; p += sizeof(buf) - 8) {
                const uint32_t remain = rbase + rsize - p;
                const int chunk = (remain >= sizeof(buf)) ? (int)sizeof(buf) : (int)remain;
                int got = 0;
                __try { memcpy(buf, (const void*)(uintptr_t)p, (size_t)chunk); got = 1; }
                __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
                if (!got) break;
                for (int i = 0; i + 4 <= chunk; i += 4) {
                    if (*(const uint32_t*)(buf + i) != target) continue;
                    const uint32_t q = p + (uint32_t)i;          // 持有缓冲指针的那个位〔?〕
                    if (++holders > 64) return 0;
                    for (int back = 0; back <= 0x200; back += 4) {
                        const uint32_t cand = q - back;
                        if (cand < 0x10000) break;
                        uint32_t vt = 0;
                        __try { vt = *(const uint32_t*)(uintptr_t)cand; }
                        __except (EXCEPTION_EXECUTE_HANDLER) { continue; }
                        if (vt == target) continue;
                        if (IsLikelyVtable(vt)) {
                            LogLine("  持有者 %08X（指向缓冲），其对象基址 %08X 虚表 %08X（指针在对象 +0x%X）",
                                    q, cand, vt, back);
                            *outObj = cand; *outVt = vt;
                            return 1;
                        }
                    }
                }
            }
        }
        a = rbase + rsize;
    }
    LogLine("  反向查找：没找到【持有该缓冲 + 虚表】的对象（共 %d 个持有者）", holders);
    return 0;
}

//------------------------------------------------------------------------------
// v1.3.54：数据断点法定位"聊天提交入口"（不再猜输入框对象）
//
//   前面几轮都在〔?〕哪个对象是输入框"（往回找虚表 / 反向找持有者），结果找到的是堆里的
//   假表（连我们自己〔?〕DLL 都被当成虚表槽挂上了）。这条路不可靠〔?〕
//
//   数据断点不需要猜：把 DR0..DR3（用户态硬件断点，〔?〕写〔?〕字节）架在【标记文本的起始 4 字节〔?〕
//   上，最多同时架 4 个不同的候选缓冲（宽字符命中优先）〔?〕
//     · 用户一按回〔?〕-> 提交路径必然先读这串文本 -> CPU 〔?〕EXCEPTION_SINGLE_STEP
//     · VEH 里记〔?〕eip / ecx / edx / esp / 指令字节 -> 那条指令就是提交入口〔?〕
//       ECX/EDX 往往就是输入框对象（this〔?〕
//   随后照旧：dump 出来的指令在 Game.dll+偏移，离线核对后即可直接调用它发文本〔?〕
//
//   注意事项〔?〕
//     · 硬件断点是【每线程】的，所以要遍历进程所有线程分别架（像调试器那样）
//     · 数据断点命中后指令还没执行，直接放行会立刻再触发；所以命中时先关 L 〔?〕+ 〔?〕TF 单步〔?〕
//       单步异常(BS)时再把断点重新武〔?〕—〔?〕这是标准做法
//     · 只登记候选、扫完一遍再架断点：扫描线程自己 memcpy 会踩到断点，架上就没法继续扫
//     · 单个断点触发太频繁（说明这缓冲是热数据、不是输入框）就自动全部撤掉，别拖慢游戏
//------------------------------------------------------------------------------
#define DR_N        4
#define DR_TAB      48            // 〔?〕eip 去重的表（同一处代码被触发多少次都只占一行）
#define MARK_CAND_MAX 24          // v1.3.57：候选收集到 24 个，〔?〕4 个一批轮着布点

static uint32_t       g_markCand[MARK_CAND_MAX];
static int            g_markCandWide[MARK_CAND_MAX];
static volatile LONG  g_markCandN  = 0;

// v1.3.55：改成【按 eip 去重】的表〔?〕
//   为什么：上一版用环形缓冲 + "触发太频就撤销"，结果输入框每帧重绘就把它灌〔?〕-> 自动撤销 ->
//   你按回车时断点早没了。其〔?〕每帧被读"恰恰说明候选里就有真身。所以现在不去撤销〔?〕
//   而是同一〔?〕eip 只记一〔?〕+ 计数；回车提交那一处是〔?〕eip，一定会作为【新行】出现〔?〕
//
// v1.3.56：再补两样最关键的：
//   〔?〕这一行是【哪〔?〕DR】触发的 -> 直接告诉你哪个候选才是真输入框缓〔?〕
//   〔?〕触发那一刻的【栈上返回地址链〔?〕> 读内存的指令〔?〕CRT/驱动里，但栈上留着 Game.dll 〔?〕
//      调用者；把链打出来，"谁调〔?〕wcslen 提交了这段文〔?〕就一目了然了
struct DrEnt {
    uint32_t eip;
    volatile LONG count;
    DWORD    firstMs, lastMs;
    uint32_t ecx, edx, esp, ebp, dr6;
    int      drIdx;
    uint32_t drAddr;
    uint8_t  code[16];
    char     chain[320];
};
static DrEnt          g_drTab[DR_TAB];
static volatile LONG  g_drTabN    = 0;
static volatile LONG  g_drTotal   = 0;
static uint32_t       g_drAddr[DR_N];
static uint32_t       g_drDr7     = 0;
static volatile LONG  g_drArmed   = 0;
static volatile LONG  g_drInVeh   = 0;
static volatile LONG  g_drDisarmed = 0;

// 〔?〕esp 往上扫栈，挑出"像模块内返回地址"〔?〕dword，拼〔?〕模块+偏移 的链
static void DrStackScan(uint32_t esp, char* out, int outBytes)
{
    if (out && outBytes > 0) out[0] = 0;
    if (!out || outBytes < 32 || esp < 0x10000) return;
    uint32_t buf[192];
    __try { memcpy(buf, (const void*)(uintptr_t)esp, sizeof(buf)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return; }
    int n = 0;
    for (int i = 0; i < 192; ++i) {
        const uint32_t v = buf[i];
        if (v < 0x10000) continue;
        __try {
            MEMORY_BASIC_INFORMATION mbi;
            if (!VirtualQuery((LPCVOID)(uintptr_t)v, &mbi, sizeof(mbi))) continue;
            if (mbi.State != MEM_COMMIT || mbi.Type != MEM_IMAGE) continue;
            if (!(mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                                 PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY))) continue;
            char nm[64] = { 0 };
            Wc3ModuleNameOf(v, nm, sizeof(nm));
            const uint32_t mod = (uint32_t)(uintptr_t)mbi.AllocationBase;
            const int wrote = _snprintf_s(out + n, (size_t)(outBytes - n), _TRUNCATE,
                                          " [%s+0x%X]", nm[0] ? nm : "?", mod ? (v - mod) : 0u);
            if (wrote > 0) n += wrote;
            if (outBytes - n < 40) break;
        } __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
    if (!out[0]) strncpy_s(out, (size_t)outBytes, " (栈上没找到模块返回地址)", _TRUNCATE);
}

static void DrTabAdd(EXCEPTION_POINTERS* ep)
{
    InterlockedIncrement(&g_drTotal);
    const uint32_t eip = ep->ContextRecord->Eip;
    const LONG used = (g_drTabN < DR_TAB) ? g_drTabN : DR_TAB;
    for (LONG i = 0; i < used; ++i) {
        if (g_drTab[i].eip == eip) {
            InterlockedIncrement(&g_drTab[i].count);
            g_drTab[i].lastMs = GetTickCount();
            return;
        }
    }
    const LONG slot = InterlockedIncrement(&g_drTabN) - 1;
    if (slot >= DR_TAB) return;
    DrEnt& e = g_drTab[slot];
    e.count   = 1;
    e.firstMs = e.lastMs = GetTickCount();
    e.eip = eip;
    e.ecx = ep->ContextRecord->Ecx;  e.edx = ep->ContextRecord->Edx;
    e.esp = ep->ContextRecord->Esp;  e.ebp = ep->ContextRecord->Ebp;
    e.dr6 = ep->ContextRecord->Dr6;
    e.drIdx = -1; e.drAddr = 0;
    for (int i = 0; i < DR_N; ++i) {
        if (e.dr6 & (1u << i)) { e.drIdx = i; e.drAddr = g_drAddr[i]; break; }
    }
    __try { memcpy(e.code, (const void*)(uintptr_t)eip, sizeof(e.code)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { memset(e.code, 0, sizeof(e.code)); }
    DrStackScan(e.esp, e.chain, sizeof(e.chain));   // v1.3.56：记下调用者链（Game.dll 就在里面〔?〕
}

static LONG CALLBACK DrVeh(EXCEPTION_POINTERS* ep)
{
    if (!g_drArmed) return EXCEPTION_CONTINUE_SEARCH;
    if (ep->ExceptionRecord->ExceptionCode != EXCEPTION_SINGLE_STEP) return EXCEPTION_CONTINUE_SEARCH;
    if (InterlockedCompareExchange(&g_drInVeh, 1, 0) != 0) return EXCEPTION_CONTINUE_SEARCH;

    LONG ret = EXCEPTION_CONTINUE_EXECUTION;
    __try {
        const uint32_t dr6 = ep->ContextRecord->Dr6;
        if (dr6 & 0xFu) {                                    // B0..B3：数据断点命〔?〕
            DrTabAdd(ep);                                    // v1.3.55：按 eip 去重记账（防止每帧重绘把它刷爆）
            ep->ContextRecord->Dr7 &= ~0x00000055u;          // 〔?〕L0..L3，防止同一条指令反复触〔?〕
            ep->ContextRecord->EFlags |= 0x100u;             // 单步走完这条指令
        } else {                                             // BS：单步完〔?〕-> 重新武装
            ep->ContextRecord->Dr7 = g_drDr7;
            ep->ContextRecord->EFlags &= ~0x100u;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { ret = EXCEPTION_CONTINUE_SEARCH; }

    InterlockedExchange(&g_drInVeh, 0);
    return ret;
}

// 遍历本进程所有线程，对每个线程执〔?〕fn(ctx)
static int ForEachThreadCtx(int setIt)
{
    const DWORD pid = GetCurrentProcessId();
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (snap == INVALID_HANDLE_VALUE) return 0;
    THREADENTRY32 te;
    memset(&te, 0, sizeof(te));
    te.dwSize = sizeof(te);
    int n = 0;
    if (Thread32First(snap, &te)) {
        do {
            if (te.th32OwnerProcessID != pid) continue;
            if (te.th32ThreadID == GetCurrentThreadId()) continue;   // 不能挂起自己
            HANDLE th = OpenThread(THREAD_GET_CONTEXT | THREAD_SET_CONTEXT | THREAD_SUSPEND_RESUME,
                                   FALSE, te.th32ThreadID);
            if (!th) continue;
            SuspendThread(th);
            CONTEXT ctx;
            memset(&ctx, 0, sizeof(ctx));
            ctx.ContextFlags = CONTEXT_DEBUG_REGISTERS;
            if (GetThreadContext(th, &ctx)) {
                if (setIt) {
                    ctx.Dr0 = g_drAddr[0]; ctx.Dr1 = g_drAddr[1];
                    ctx.Dr2 = g_drAddr[2]; ctx.Dr3 = g_drAddr[3];
                    ctx.Dr7 = g_drDr7;
                } else {
                    ctx.Dr0 = ctx.Dr1 = ctx.Dr2 = ctx.Dr3 = 0;
                    ctx.Dr7 = 0;
                }
                if (SetThreadContext(th, &ctx)) ++n;
            }
            ResumeThread(th);
            CloseHandle(th);
        } while (Thread32Next(snap, &te));
    }
    CloseHandle(snap);
    return n;
}

static void DrDisarm(const char* why)
{
    if (!g_drArmed) return;
    g_drArmed = 0;
    const int n = ForEachThreadCtx(0);
    if (!InterlockedExchange(&g_drDisarmed, 1))
        LogLine("D 数据断点：已撤销（%s；共清了 %d 个线程）", why ? why : "", n);
}

static volatile LONG  g_drShown = 0;      // 已经打印过几行（表只增不改，按行号推进）

static void ArmDataBreakpoints();
static void DrAdvanceBatch();

// v1.3.57：分批布〔?〕—〔?〕只有 4 个硬件断点，但内存里同一段文本有一堆副本（渲染/日志/WFE/输入法…）〔?〕
//   真输入框缓冲可能是第 5、第 9 个命中。所以：
//     · 扫描收集最〔?〕24 个候选；一次架 4 个；
//     · 每次"标记上屏"〔?〕你按了回车）后判定这一批抓没抓到提交读，没抓到就自动换下一批；
//     · 日志会提〔?〕请再输入一次标记并回车"
static volatile LONG g_drBatch = 0;

static void DumpDrTable(const char* note)
{
    const LONG n = (g_drTabN < DR_TAB) ? g_drTabN : DR_TAB;
    const LONG from = (g_drShown < n) ? g_drShown : n;
    LogLine("D 数据断点表[第 %d 批 候选 %d..%d]：共 %d 个不同触发点（累计 %d 次）%s",
            (int)(g_drBatch / DR_N) + 1, (int)g_drBatch, (int)(g_drBatch + DR_N - 1),
            (int)n, (int)InterlockedCompareExchange(&g_drTotal, 0, 0), note ? note : "");
    for (LONG i = from; i < n; ++i) {
        const DrEnt& e = g_drTab[i];
        char nm[64] = { 0 };
        uint32_t mod = 0;
        __try {
            MEMORY_BASIC_INFORMATION v;
            if (VirtualQuery((LPCVOID)(uintptr_t)e.eip, &v, sizeof(v)) && v.AllocationBase)
                mod = (uint32_t)(uintptr_t)v.AllocationBase;
        } __except (EXCEPTION_EXECUTE_HANDLER) { }
        Wc3ModuleNameOf(e.eip, nm, sizeof(nm));
        // v1.3.59：顺手把这行断点对应的候选缓冲【当前内容】读出来 —〔?〕谁还装着标记，谁才是活的输入〔?〕
        char txt[64] = { 0 };
        if (e.drAddr) {
            if (!PrintableStrInline(e.drAddr, txt, sizeof(txt), 40))
                PrintableWStrInline(e.drAddr, txt, sizeof(txt), 40);
        }
        LogLine("   [%d] eip=%08X (%s+0x%X) 触发 %d 次 t=%u..%u ecx=%08X edx=%08X esp=%08X  <- DR%d(%08X)%s",
                (int)i, e.eip, nm[0] ? nm : "?", mod ? (e.eip - mod) : 0u,
                (int)e.count, (unsigned)e.firstMs, (unsigned)e.lastMs, e.ecx, e.edx, e.esp,
                e.drIdx, e.drAddr, txt[0] ? "" : " 缓冲已空");
        if (txt[0]) LogLine("       该缓冲当前内容： \"%s\"", txt);
        LogLine("       指令字节: %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X",
                e.code[0], e.code[1], e.code[2], e.code[3], e.code[4], e.code[5], e.code[6], e.code[7],
                e.code[8], e.code[9], e.code[10], e.code[11], e.code[12], e.code[13], e.code[14], e.code[15]);
        LogLine("       调用者链(内->外):%s", e.chain);
        if (e.ecx >= 0x10000) DumpObjFields("       ECX 指向", e.ecx, 0x40);
        if (e.edx >= 0x10000) DumpObjFields("       EDX 指向", e.edx, 0x40);
    }
    g_drShown = n;
}

static DWORD WINAPI DrRingDumper(LPVOID)
{
    for (int k = 0; k < 150; ++k) {          // v1.3.57：分批布点，多跑一会儿〔?〕分钟〔?〕
        Sleep(2000);
        if (!g_drArmed) break;
        const LONG n = (g_drTabN < DR_TAB) ? g_drTabN : DR_TAB;
        if (n != g_drShown)
            DumpDrTable("（新触发点；按回车提交那一处一定会在其中）");
    }
    return 0;
}

// v1.3.59：判定收紧了 —〔?〕上一版被【搜狗输入法】骗了（它读文本时调用链里恰好穿〔?〕Game.dll）〔?〕
//   现在：EIP 必须在游〔?〕系统/CRT 里，链里必须〔?〕Game.dll，且链里不能有输入法/我们自己〔?〕DLL/别的插件〔?〕
static int DrBatchLooksGood()
{
    const LONG n = (g_drTabN < DR_TAB) ? g_drTabN : DR_TAB;
    for (LONG i = 0; i < n; ++i) {
        const DrEnt& e = g_drTab[i];
        char nm[64] = { 0 };
        Wc3ModuleNameOf(e.eip, nm, sizeof(nm));
        const int sys = nm[0] && (!_stricmp(nm, "KERNELBASE.dll") || !_stricmp(nm, "ntdll.dll") ||
                                  !_stricmp(nm, "kernel32.dll") || !_stricmp(nm, "msvcrt.dll") ||
                                  !_stricmp(nm, "MSVCR120.dll") || !_stricmp(nm, "ucrtbase.dll") ||
                                  !_stricmp(nm, "Storm.dll") || !_stricmp(nm, "Game.dll"));
        if (!sys) continue;
        if (!strstr(e.chain, "Game.dll")) continue;
        if (strstr(e.chain, "UDamageWatcher.dll")) continue;
        if (strstr(e.chain, "SogouPY")) continue;
        if (strstr(e.chain, "War3Plugin.dll")) continue;
        return 1;
    }
    return 0;
}

static void DrArmBatch(int start)
{
    const int use = (g_markCandN - start < DR_N) ? (int)(g_markCandN - start) : DR_N;
    if (use <= 0) { LogLine("D 数据断点：候选试完了，撤销"); DrDisarm("所有候选都试过"); return; }

    static LONG s_vehInstalled = 0;
    if (!s_vehInstalled) {
        if (AddVectoredExceptionHandler(1, DrVeh)) { s_vehInstalled = 1; LogLine("D 数据断点：VEH 已安装"); }
        else { LogLine("D 数据断点：VEH 安装失败，放弃"); return; }
    }

    g_drBatch = start;

    // 每批换新表，日志才看得清
    g_drTabN = 0; g_drShown = 0; g_drTotal = 0;

    g_drDr7 = 0;
    for (int i = 0; i < DR_N; ++i) {
        g_drAddr[i] = 0;
        if (i >= use) continue;
        g_drAddr[i] = g_markCand[start + i];
        const uint32_t rwShift = 16u + (uint32_t)i * 4u;
        g_drDr7 |= (1u << (i * 2)) | (0x3u << rwShift) | (0x3u << (rwShift + 2));
    }

    LogLine("D ===== 第 %d 批：本 %d 个候选（共收集到 %d 个副本）=====",
            (int)(start / DR_N) + 1, use, (int)g_markCandN);
    for (int i = 0; i < use; ++i)
        LogLine("   DR%d = %08X（%s 命中）", i, g_markCand[start + i], g_markCandWide[start + i] ? "UTF-16" : "ASCII");
    LogLine("   请【按回车】把标记发出去（只记前 4 字节都记）；没抓到提交读会自动换下一批，到时日志会提示再输入一次");

    g_drArmed = 1;
    const int n = ForEachThreadCtx(1);
    LogLine("D 数据断点：已在 %d 个线程上生效", n);

    static LONG s_dumper = 0;
    if (!s_dumper) {
        s_dumper = 1;
        HANDLE h = CreateThread(NULL, 0, DrRingDumper, NULL, 0, NULL);
        if (h) CloseHandle(h);
    }
}

// 标记上屏〔?〕你按了回车）后由聊天显示钩子调用：判定这一批，然后换下一〔?〕
static void DrAdvanceBatch()
{
    if (!g_drArmed) return;
    const int good = DrBatchLooksGood();
    DumpDrTable(good ? "<<< 标记已上屏：这一批抓到【提交读】了！" : "<<< 标记已上屏：这一批没抓到提交读");
    if (good) {
        LogLine("D ✔ 已定位真输入框缓冲：候选 #%d = %08X（第 %d 批）—— 请把上面带 Game.dll 的那几行发我",
                (int)g_drBatch, g_markCand[g_drBatch], (int)(g_drBatch / DR_N) + 1);
        DrDisarm("已找到提交读，收工");
        return;
    }
    const int next = (int)g_drBatch + DR_N;
    if (next >= (int)g_markCandN) {
        LogLine("D ✗ 所有 %d 个候选都试过了，还是没抓到提交读；撤销断点（把日志发我，我换别的办法）",
                (int)g_markCandN);
        DrDisarm("候选试完仍未命中");
        return;
    }
    LogLine("D -> 这一批不是输入框，换下一批（第 %d 批）——**请在聊天框里再输入一次标记并按回车**",
            (int)(next / DR_N) + 1);
    DrArmBatch(next);
}

// v1.3.56：严格的"这像〔?〕C++ 虚表指针〔?〕判定〔?〕
//   上一版只要求"虚表第一〔?〕dword 落在 Game.dll .text 范围〔?〕，结果堆里的垃圾表也能过〔?〕
//   甚至把我们自己的 DLL 当成虚表槽挂上了。现在要求：
//     〔?〕虚表地址本身在【模块映〔?〕MEM_IMAGE)】里  〔?〕它的第一〔?〕dword 指向【可执行】的模块页面
//     〔?〕排除我们自己的模〔?〕
static int IsLikelyVtable(uint32_t vt)
{
    if (vt < 0x10000) return 0;
    uint32_t first = 0;
    __try {
        MEMORY_BASIC_INFORMATION v1;
        if (!VirtualQuery((LPCVOID)(uintptr_t)vt, &v1, sizeof(v1))) return 0;
        if (v1.State != MEM_COMMIT || v1.Type != MEM_IMAGE) return 0;
        if (!(v1.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_EXECUTE_READ))) return 0;
        first = *(const uint32_t*)(uintptr_t)vt;
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (first < 0x10000) return 0;
    __try {
        MEMORY_BASIC_INFORMATION v2;
        if (!VirtualQuery((LPCVOID)(uintptr_t)first, &v2, sizeof(v2))) return 0;
        if (v2.State != MEM_COMMIT || v2.Type != MEM_IMAGE) return 0;
        if (!(v2.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                            PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY))) return 0;
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    char nm[64] = { 0 };
    Wc3ModuleNameOf(vt, nm, sizeof(nm));
    if (nm[0] && !_stricmp(nm, "UDamageWatcher.dll")) return 0;
    return 1;
}

//------------------------------------------------------------------------------
// v1.3.61：直接按名字〔?〕聊天输入〔?〕frame 对象"（只读，不挂钩子〔?〕
//
//   依据：Game.dll 〔?〕"ChatEditBar" 字符串（RVA 0x98FE00）的两处引用都是这个形状〔?〕
//       push 0
//       mov  edx, offset "ChatEditBar"      ; 名字〔?〕edx
//       ...
//       mov  ecx, [Game.dll+0xB68FB8]       ; 全局 UI 管理〔?〕
//       call Game.dll+0x2A2F0               ; 按名字取 frame
//   所以我们在游戏线程上照同样的约定调一次，就能拿到聊天输入框的 frame 对象〔?〕
//   进〔?〕dump 它的字段和【虚表槽】—〔?〕提交入口必然在虚表里（按回车时被调的那个槽）〔?〕
//------------------------------------------------------------------------------
static void FindChatFrameAndDump()
{
    const uint32_t base = Wc3GameBase();
    if (!base) { LogLine("F 找不到 Game.dll，放弃"); return; }

    // 〔?〕v1.3.62：frame 对象一般会存【自己名字的指针】。所以不调游戏函数（上一版调了，
    //    返回的是状态〔?〕1，不是对象），改成纯扫描〔?〕
    //      扫全内存里哪〔?〕dword == "ChatEditBar" 字符串地址 -> 那个位置所在的对象就是 frame
    const uint32_t nameVa = base + 0x98FE00;          // "ChatEditBar"
    LogLine("F 开始扫内存找\"持有 ChatEditBar 名字指针\"的 frame 对象（名字 VA=%08X）", nameVa);

    char buf[8192];
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    uint32_t a = (uint32_t)(uintptr_t)si.lpMinimumApplicationAddress;
    const uint32_t aMax = (uint32_t)(uintptr_t)si.lpMaximumApplicationAddress;
    int found = 0;

    while (a < aMax && found < 8) {
        MEMORY_BASIC_INFORMATION mbi;
        if (!VirtualQuery((LPCVOID)(uintptr_t)a, &mbi, sizeof(mbi))) break;
        const uint32_t rbase = (uint32_t)(uintptr_t)mbi.BaseAddress;
        const uint32_t rsize = (uint32_t)mbi.RegionSize;
        const int readable = (mbi.State == MEM_COMMIT) &&
            (mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                            PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)) &&
            !(mbi.Protect & PAGE_GUARD);
        if (readable && rsize >= 0x1000) {
            for (uint32_t p = rbase; p + 8 < rbase + rsize && found < 8; p += sizeof(buf) - 8) {
                const uint32_t remain = rbase + rsize - p;
                const int chunk = (remain >= sizeof(buf)) ? (int)sizeof(buf) : (int)remain;
                int got = 0;
                __try { memcpy(buf, (const void*)(uintptr_t)p, (size_t)chunk); got = 1; }
                __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
                if (!got) break;
                for (int i = 0; i + 4 <= chunk; i += 4) {
                    if (*(const uint32_t*)(buf + i) != nameVa) continue;
                    const uint32_t q = p + (uint32_t)i;          // 存着"名字指针"的位〔?〕
                    // 它就〔?〕frame 的某个字段：〔?〕q 往前找虚表指针，定位对象基址
                    uint32_t obj = 0, vt = 0;
                    for (int back = 0; back <= 0x400; back += 4) {
                        const uint32_t cand = q - back;
                        if (cand < 0x10000) break;
                        uint32_t v = 0;
                        __try { v = *(const uint32_t*)(uintptr_t)cand; }
                        __except (EXCEPTION_EXECUTE_HANDLER) { continue; }
                        if (IsLikelyVtable(v)) { obj = cand; vt = v; break; }
                    }
                    ++found;
                    LogLine("F [命中%d] 名字指针在 %08X；对象基址=%08X 虚表=%08X（名字字段在对象 +0x%X）",
                            found, q, obj, vt, obj ? (q - obj) : 0u);
                    if (obj) {
                        DumpObjFields("F frame 对象", obj, 0x100);
                        for (int k = 0; k < 24; ++k) {
                            uint32_t fn = 0;
                            __try { fn = *(const uint32_t*)(uintptr_t)(vt + (uint32_t)k * 4); }
                            __except (EXCEPTION_EXECUTE_HANDLER) { break; }
                            if (fn < 0x10000) break;
                            char nm[64] = { 0 };
                            uint32_t mod = 0;
                            __try {
                                MEMORY_BASIC_INFORMATION v;
                                if (VirtualQuery((LPCVOID)(uintptr_t)fn, &v, sizeof(v)) && v.AllocationBase)
                                    mod = (uint32_t)(uintptr_t)v.AllocationBase;
                            } __except (EXCEPTION_EXECUTE_HANDLER) { }
                            Wc3ModuleNameOf(fn, nm, sizeof(nm));
                            LogLine("F 虚表槽%02d -> %08X (%s+0x%X)", k, fn, nm[0] ? nm : "?",
                                    mod ? (fn - mod) : 0u);
                        }
                    } else {
                        DumpObjFields("F 命中处附近", q >= 0x80 ? q - 0x80 : q, 0x100);
                    }
                }
            }
        }
        a = rbase + rsize;
    }
    if (!found) LogLine("F 没找到持有该名字指针的对象（frame 可能不存名字指针，得换思路）");
    LogLine("F 完成（共 %d 个候选）", found);
}

// v1.3.51：命中可能是"模块映像里的副本"（例〔?〕JAPI/ydbase 内部也存了一份聊天文本）〔?〕
//   那不是聊天输入框。所以：模块映像里的命中直接跳过继续扫；只认私有内存（堆/栈）里的〔?〕
//   并在那里找虚表指针〔?〕
static int OnMarkerHit(uint32_t hit, int wide)
{
    MEMORY_BASIC_INFORMATION mbi;
    if (!VirtualQuery((LPCVOID)(uintptr_t)hit, &mbi, sizeof(mbi))) return 0;
    const char* kind = (mbi.Type == MEM_IMAGE) ? "模块映像"
                     : (mbi.Type == MEM_MAPPED) ? "映射" : "私有(堆";
    LogLine("标记命中：\"%s\" 在 %08X（%s，区域=%s 保护=%X）", g_cfg.chat_marker, hit,
            wide ? "UTF-16 宽字符" : "ASCII", kind, mbi.Protect);
    if (mbi.Type == MEM_IMAGE) {
        LogLine("  在模块映像里 -> 跳过（那是别人存的副本，不是输入框缓冲），继续找");
        return 0;
    }

    // v1.3.54：数据断点模〔?〕—〔?〕只登记候选，扫完一遍再统一架断〔?〕
    // （不能边扫边架：扫描线程自己 memcpy 会踩到断点）
    if (g_cfg.chat_dr) {
        for (int i = 0; i < g_markCandN; ++i) {
            const int32_t d = (int32_t)(g_markCand[i] - hit);
            if (d > -0x40 && d < 0x40) return 0;             // 同一份副本，不重复登〔?〕
        }
        if (g_markCandN < MARK_CAND_MAX) {
            g_markCand[g_markCandN] = hit;
            g_markCandWide[g_markCandN] = wide;
            InterlockedIncrement(&g_markCandN);
            LogLine("  [候选 %d/%d] %08X（%s）", (int)g_markCandN, MARK_CAND_MAX, hit,
                    wide ? "UTF-16 宽字符" : "ASCII");
        }
        return 0;                                            // 继续扫，集满 4 个再〔?〕
    }

    g_markTextWide = wide;

    const uint32_t base = Wc3GameBase();
    uint32_t tStart = 0, tSize = 0;
    if (!base || !Wc3TextRange(base, &tStart, &tSize)) { DumpObjFields("命中", hit, 0x80); return 0; }

    uint32_t bestObj = 0, bestVt = 0, bestOff = 0;
    for (int back = 0; back <= 0x1000; back += 4) {
        const uint32_t cand = hit - back;
        if (cand < 0x10000) break;
        uint32_t vt = 0;
        __try { vt = *(const uint32_t*)(uintptr_t)cand; }
        __except (EXCEPTION_EXECUTE_HANDLER) { continue; }
        if (IsLikelyVtable(vt)) {                       // v1.3.56：严格的虚表判定
            bestObj = cand; bestVt = vt; bestOff = (uint32_t)back;
            break;
        }
    }
    if (!bestObj) {
        // v1.3.52：直接往回找不到虚表 —〔?〕说明文本缓冲是【单独分配的】（std::string/自定义动态串），
        //   对象只持有它的指针。改成反向搜"谁指向这个缓〔?〕〔?〕
        LogLine("  私有内存 ±0x1000 范围内没找到虚表指针 -> 改走【反向指针查找】");
        DumpObjFields("命中处 -0x60 起", hit >= 0x60 ? hit - 0x60 : hit, 0x100);
        FindObjectByPointer(hit, &bestObj, &bestVt);
        if (bestObj) bestOff = (hit > bestObj) ? (hit - bestObj) : 0;
    }
    if (!bestObj) {
        LogLine("  反向查找也没定位到输入框对象；继续扫其它副本（若全都失败，再看上面的 dump）");
        return 0;
    }
    g_markTextPtr = hit;

    LogLine("输入框对象 %08X 虚表=%08X 文本缓冲在对象 +0x%X", bestObj, bestVt, bestOff);
    g_markObj = bestObj; g_markVtbl = bestVt; g_markTextOff = bestOff;
    DumpObjFields("输入框对象", bestObj, 0x40);

    // 虚表在哪：把虚表地址也报〔?〕模块+偏移"，方便离线核〔?〕
    {
        char nm[64] = { 0 };
        uint32_t mod = 0;
        __try {
            MEMORY_BASIC_INFORMATION v;
            if (VirtualQuery((LPCVOID)(uintptr_t)bestVt, &v, sizeof(v)) && v.AllocationBase)
                mod = (uint32_t)(uintptr_t)v.AllocationBase;
        } __except (EXCEPTION_EXECUTE_HANDLER) { }
        Wc3ModuleNameOf(bestVt, nm, sizeof(nm));
        LogLine("虚表所属：%s +0x%X（基址 %08X）", nm[0] ? nm : "?", mod ? (bestVt - mod) : 0u, mod);
    }

    HookVtblSlots(bestVt);
    return 1;
}

// v1.3.58：把"扫一趟内存找标记"抽出来，好让【自动测试】复〔?〕
//   返回 1 = 该停止扫描（数据断点模式已收集够候选，或非 DR 模式已命中并挂好探针〔?〕
static int MarkerScanPass(void)
{
    const int n = (int)strlen(g_cfg.chat_marker);
    if (n <= 2) return 0;
    // v1.3.53：同时找 ASCII 〔?〕UTF-16 两种形〔?〕—〔?〕游戏的编辑框很可能存宽字〔?〕
    char     wmark[192];
    int      wn = 0;
    for (int i = 0; i < n && (i * 2 + 1) < (int)sizeof(wmark); ++i) {
        wmark[i * 2]     = g_cfg.chat_marker[i];
        wmark[i * 2 + 1] = 0;
        wn = i * 2 + 2;
    }
    char buf[8192];
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    uint32_t a = (uint32_t)(uintptr_t)si.lpMinimumApplicationAddress;
    const uint32_t aMax = (uint32_t)(uintptr_t)si.lpMaximumApplicationAddress;
    while (a < aMax && !g_markDone &&
           !(g_cfg.chat_dr && g_markCandN >= MARK_CAND_MAX)) {
        MEMORY_BASIC_INFORMATION mbi;
        if (!VirtualQuery((LPCVOID)(uintptr_t)a, &mbi, sizeof(mbi))) break;
        const uint32_t rbase = (uint32_t)(uintptr_t)mbi.BaseAddress;
        const uint32_t rsize = (uint32_t)mbi.RegionSize;
        const int readable = (mbi.State == MEM_COMMIT) &&
            (mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                            PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)) &&
            !(mbi.Protect & PAGE_GUARD);
        if (readable && rsize >= 0x1000) {
            for (uint32_t p = rbase; p + 64 < rbase + rsize; p += sizeof(buf) - 64) {
                int got = 0;
                __try { memcpy(buf, (const void*)(uintptr_t)p, sizeof(buf)); got = 1; }
                __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
                if (!got) break;
                for (int i = 0; i + n <= (int)sizeof(buf); ++i) {
                    if (buf[i] != g_cfg.chat_marker[0]) continue;
                    // 〔?〕先看宽字符形态（真正的编辑框缓冲最可能是这个）
                    if (wn > 0 && i + wn <= (int)sizeof(buf) && memcmp(buf + i, wmark, (size_t)wn) == 0) {
                        if (OnMarkerHit(p + (uint32_t)i, 1)) {
                            InterlockedExchange(&g_markDone, 1);
                            return 1;
                        }
                    }
                    // 〔?〕再看 ASCII 形态（渲染/日志/网络副本多是这个〔?〕
                    int ok = 1;
                    for (int j = 1; j < n; ++j)
                        if (buf[i + j] != g_cfg.chat_marker[j]) { ok = 0; break; }
                    if (ok && OnMarkerHit(p + (uint32_t)i, 0)) {
                        InterlockedExchange(&g_markDone, 1);
                        return 1;
                    }
                }
            }
        }
        a = rbase + rsize;
    }
    if (g_cfg.chat_dr && g_markCandN > 0) {
        InterlockedExchange(&g_markDone, 1);
        return 1;
    }
    return g_markDone ? 1 : 0;
}

// v1.3.99【重要修复】标记扫描曾经开机就跑 300 轮（每轮全进程扫一遍内存 + 每 5 轮写一行日志）。
//   启动时聊天框是空的，扫描必然找不到 -> 于是一路重扫、一路刷日志，
//   用户看到的现象是"日志一直在刷"，而且一个线程持续扫内存本身就会让游戏发卡。
//   这段扫描本来是【一次性逆向工具】（当初用来找聊天输入框缓冲），
//   绝不该做成常驻轮询。现在：
//     * 默认 chat_marker 为空 -> 根本不启动（见 InitMarkerScan）
//     * 上限从 300 轮降到 3 轮
//     * 只在最后失败时写一行日志，中间不再刷
#define MARKER_SCAN_MAX_PASS 3
static DWORD WINAPI MarkerScanThread(LPVOID)
{
    const int n = (int)strlen(g_cfg.chat_marker);
    if (n <= 2) return 0;
    for (int pass = 0; pass < MARKER_SCAN_MAX_PASS && !g_markDone; ++pass) {
        if (g_drAuto) { Sleep(1000); continue; }      // v1.3.58：自动测试在跑，手动扫描让路
        if (MarkerScanPass()) {
            if (g_cfg.chat_dr) DrArmBatch(0);      // v1.3.54/57：数据断点模式，扫到就架第一〔?〕
            return 0;
        }
        Sleep(1000);
    }
    if (!g_markDone)
        LogLine("标记扫描：这 %d 轮没扫到 \"%s\"，停止（这是逆向用的一次性工具，"
                "需要时把 chat_marker 填上重开游戏即可）",
                MARKER_SCAN_MAX_PASS, g_cfg.chat_marker);
    return 0;
}

static void InitMarkerScan()
{
    if (!g_cfg.chat_diag || !g_cfg.chat_marker[0]) return;
    LogLine("输入框定位：开始扫内存找标记 \"%s\"（请在聊天框里【输入但不要发送】它）",
            g_cfg.chat_marker);
    HANDLE h = CreateThread(NULL, 0, MarkerScanThread, NULL, 0, NULL);
    if (h) CloseHandle(h);
}

//------------------------------------------------------------------------------
// v1.3.58：数据断点【自动测试】—〔?〕绕开输入法，全程插件自己按键
//
//   为什么要自动化：你用的是搜狗输入法，打字时文本先进【输入法的组字缓冲】，游戏自己的编辑框
//   要到按回车提交那一刻才拿到文本 —〔?〕所〔?〕先手动输入标记、再架断〔?〕永远扫不到真〔?〕
//   （实机日志：回车瞬间〔?〕SogouPY.ime / ntdll 在读输入法缓冲）〔?〕
//
//   自动流程（用 @dr 触发，跑在独立线程）〔?〕
//     〔?〕回车开聊天〔?〕-> Ctrl+V 把标记【粘贴】进去（粘贴走游戏自己的编辑框，不经过输入法〔?〕
//     〔?〕立刻扫内存找标记 -> 这次它一定在游戏自己的编辑框〔?〕-> 拿到候〔?〕
//     〔?〕架这一〔?〕4 个断〔?〕-> 回车提交 -> 看有没有"系统/CRT 模块） + 调用链含 Game.dll"
//     〔?〕没抓到就换下一批，重新粘贴、再提交（最〔?〕6 轮，全自动）
//------------------------------------------------------------------------------
// 合成一个按键（只给下面的数据断点自动测试用；"插件自己发聊天"已删除，这里不再对外）
static void SendVk(WORD vk, int up)
{
    INPUT in;
    ZeroMemory(&in, sizeof(in));
    in.type       = INPUT_KEYBOARD;
    in.ki.wVk     = vk;
    in.ki.wScan   = (WORD)MapVirtualKeyA(vk, MAPVK_VK_TO_VSC);
    in.ki.dwFlags = up ? KEYEVENTF_KEYUP : 0;
    SendInput(1, &in, sizeof(in));
}

static DWORD WINAPI DrAutoThread(LPVOID)
{
    Sleep(400);
    HWND fg = GetForegroundWindow();
    DWORD pid = 0;
    if (fg) GetWindowThreadProcessId(fg, &pid);
    if (!fg || pid != GetCurrentProcessId()) {
        LogLine("A 自动测试取消：魔兽不是前台窗口（先切回游戏，再在聊天里发 @dr）");
        InterlockedExchange(&g_drAuto, 0);
        return 0;
    }
    const int delay = (g_cfg.chat_send_delay_ms < 200) ? 200 : g_cfg.chat_send_delay_ms;
    LogLine("A ===== 数据断点自动测试开始（插件自己回车/粘贴，你不用打字）标记 \"%s\" =====",
            g_cfg.chat_marker);

    for (int round = 0; round < 6; ++round) {
        InterlockedExchange(&g_markDone, 0);
        InterlockedExchange(&g_markCandN, 0);
        g_drBatch = 0;

        // v1.4.13：剪贴板复制能力已删除。自动测试不再写剪贴板/粘贴，直接扫描内存。
        LogLine("A 第 %d 轮：扫描标记", round + 1);
        Sleep((DWORD)delay);

        // 〔?〕单趟扫描
        MarkerScanPass();
        LogLine("A 扫描完成：找到 %d 个候选缓冲", (int)g_markCandN);
        if (g_markCandN <= 0) {
            LogLine("A 没扫到标记 —— 粘贴可能没进聊天框（把 ini 的 chat_send_delay 调大，比如 400~600）");
            break;
        }

        // 〔?〕架这一批断点，先让"粘贴/重绘"引发的一堆读沉淀下来
        const int start = round * DR_N;
        if (start >= (int)g_markCandN) { LogLine("A 候选都试完了（共 %d 个）", (int)g_markCandN); break; }
        DrArmBatch(start);
        Sleep(1500);

        // 〔?〕v1.3.59：清〔?〕—〔?〕这一步之后出现的触发点就【只有回车提交路径】了（粘〔?〕重绘的都被清掉）
        g_drTabN = 0; g_drShown = 0; g_drTotal = 0;
        LogLine("A 已清表：接下来出现的触发点就是【回车提交】路径（粘贴/重绘的噪音已丢弃）");

        // 〔?〕回车提交
        LogLine("A 回车提交（第 %d 批）", round + 1);
        SendVk(VK_RETURN, 0); SendVk(VK_RETURN, 1);
        Sleep(1600);

        // 〔?〕判定
        const int good = DrBatchLooksGood();
        DumpDrTable(good ? "A <<< 抓到提交读！" : "A 这一批没抓到提交读");
        if (good) {
            LogLine("A ✔ 已定位真输入框缓冲（第 %d 批候选 %d..%d）—— 请把上面带 Game.dll 的调用者链发我",
                    round + 1, start, start + DR_N - 1);
            DrDisarm("自动测试命中");
            break;
        }
        DrDisarm("自动测试：换下一批");
        Sleep(400);
    }
    LogLine("A ===== 数据断点自动测试结束 =====");
    InterlockedExchange(&g_drAuto, 0);
    return 0;
}

static void StartDrAutoTest()
{
    if (!g_cfg.chat_dr) { LogLine("A 自动测试需要 chat_dr=1（ini 里）"); return; }
    if (InterlockedExchange(&g_drAuto, 1) != 0) { LogLine("A 自动测试已在跑，本次忽略"); return; }
    HANDLE h = CreateThread(NULL, 0, DrAutoThread, NULL, 0, NULL);
    if (!h) { InterlockedExchange(&g_drAuto, 0); LogLine("A 自动测试线程创建失败"); return; }
    CloseHandle(h);
}

// 把一个目标挂进下一个空槽。入口若已被别人（WFE/Detours）改成跳转，先跟到最后一级〔?〕
static int InstallChatHookSlot(uint32_t fn)
{
    if (g_chatSlotCount >= CHAT_MAX_SLOTS) return 0;

    int hops = 0;
    const uint32_t live = FollowJumps(fn, &hops);
    if (hops > 0) LogLine("聊天命令：入口 %08X 已被别人挂钩，跟随 %d 跳到 %08X 再挂", fn, hops, live);

    void* tramp = NULL;
    const int stolen = InstallDetour(live, kChatThunks[g_chatSlotCount], &tramp);
    if (!stolen || !tramp) {
        LogLine("聊天命令：槽%d 挂钩失败（目标 %08X：指令解码失败或序言含相对跳转），跳过",
                g_chatSlotCount, live);
        return 0;
    }
    g_chatTramps[g_chatSlotCount]  = tramp;
    g_chatTargets[g_chatSlotCount] = live;
    if (g_chatSlotCount == 0) { g_chatTramp = (uint8_t*)tramp; g_chatTarget = live; }  // 兼容旧字〔?〕
    LogAddrWithModule("聊天命令：实际挂钩目标 =", live);   // v1.3.37：带模块基址，方便离线反汇编
    LogLine("聊天命令：槽%d 已挂钩 %08X（偷 %d 字节，跳板 %08X）",
            g_chatSlotCount, live, stolen, (uint32_t)(uintptr_t)tramp);
    ++g_chatSlotCount;
    return 1;
}

//------------------------------------------------------------------------------
// v1.3.33：native 模式定位聊天显示函数（吸〔?〕v1.3.32 实机崩溃的教训）
//
// v1.3.32 挂了，两个错都是"钩错地方"
//   〔?〕从引用点往前找"CC CC 填充"来定函数起点 —〔?〕结果 WFE 〔?〕Detours 在真入口留下
//      【E9 xx xx xx xx + CC CC 填充】，我的扫描在填充处就停了，返回了真入口 +9 字节
//      （函数体内！）；在函数中间偷 5 字节 = 直接改烂游戏代码 〔?〕崩〔?〕
//   〔?〕〔?〕引用收件人常量的所有函〔?〕都钩〔?〕—〔?〕但其中一个是【兄弟函数】，它只〔?〕3 个栈参数
//      （ret 0xC），而我们的钩子按显示函数的 4 个栈参数转发（ret 0x10）→ 栈不平衡 〔?〕崩〔?〕
//
// 所以这一版的做法收紧了：
//   〔?〕【入口可信性】必须满足以下之一才算函数入口〔?〕
//        - 正常序言 55 8B EC 〔?〕
//        - 入口〔?〕E9/EB 跳转，且跳转目标落在【可执行的已提交内存】里〔?〕被别〔?〕Detours 过）
//      再从 CC 边界往回最〔?〕32 字节找这样的入口（这样能跳过 Detours 留下的填充）〔?〕
//   〔?〕【只钩唯一一个】已〔?〕RVA〔?〕x355CF0）优先；它不可信时才退回字符串反查〔?〕
//      而且只有"恰好一个候〔?〕时才敢钩 —〔?〕有歧义就只写日志、什么都不钩〔?〕
//   〔?〕挂钩前把跳转跟到最后一级（WFE 的处理函数），并把目标序言写进日志留证〔?〕
//------------------------------------------------------------------------------
static uint32_t FindFuncStartBack(uint32_t ref, uint32_t lo);   // 定义在下〔?〕

// 这个地址能不能当函数入口？outIsJump 回传"是否是被 Detours 改过的跳转入〔?〕
static int PlausibleEntry(uint32_t a, int* outIsJump)
{
    if (outIsJump) *outIsJump = 0;
    if (!a) return 0;
    __try {
        const uint8_t* p = (const uint8_t*)(uintptr_t)a;
        if (p[0] == 0x55 && p[1] == 0x8B && p[2] == 0xEC) return 1;
        if (p[0] == 0xE9 || p[0] == 0xEB) {
            const uint32_t tgt = (p[0] == 0xE9)
                ? (a + 5 + (uint32_t)(*(const int32_t*)(p + 1)))
                : (a + 2 + (uint32_t)(*(const int8_t*)(p + 1)));
            MEMORY_BASIC_INFORMATION mbi;
            if (VirtualQuery((LPCVOID)(uintptr_t)tgt, &mbi, sizeof(mbi)) &&
                mbi.State == MEM_COMMIT &&
                (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                                PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY))) {
                if (outIsJump) *outIsJump = 1;
                return 1;
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { }
    return 0;
}

// 〔?〕CC CC 填充边界再往回找"可信入口"（跳〔?〕Detours 留下的填〔?〕补丁字节〔?〕
static uint32_t FindFuncStartSmart(uint32_t ref, uint32_t lo)
{
    const uint32_t bound = FindFuncStartBack(ref, lo);
    const uint32_t lim = (bound > 32 && bound - 32 > lo) ? (bound - 32) : lo;
    for (uint32_t b = bound; b > lim; --b) {
        int isJump = 0;
        if (PlausibleEntry(b, &isJump)) return b;
    }
    return 0;   // 找不到可信入〔?〕〔?〕这个候选直接丢掉（宁可不钩〔?〕
}
static uint32_t FindImageAscii(const char* s, uint32_t lo, uint32_t hi)
{
    const int n = (int)strlen(s);
    if (n <= 0 || n > 63 || hi <= lo) return 0;
    const int CH = 4096;
    char buf[CH];
    for (uint32_t a = lo; a + (uint32_t)n < hi; a += (uint32_t)(CH - 64)) {
        int got = 0;
        __try { memcpy(buf, (const void*)(uintptr_t)a, CH); got = 1; }
        __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
        if (!got) continue;
        for (int i = 0; i + n <= CH; ++i)
            if (buf[i] == s[0] && memcmp(buf + i, s, n) == 0) return a + (uint32_t)i;
    }
    return 0;
}

static int ScanDwordRefs(uint32_t lo, uint32_t hi, uint32_t value, uint32_t* out, int maxOut)
{
    int n = 0;
    const int CH = 4096;
    uint8_t buf[CH];
    for (uint32_t a = lo; a + 4 < hi; a += (uint32_t)(CH - 4)) {
        int got = 0;
        __try { memcpy(buf, (const void*)(uintptr_t)a, CH); got = 1; }
        __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
        if (!got) continue;
        for (int i = 0; i + 4 <= CH; ++i)
            if (*(const uint32_t*)(buf + i) == value && n < maxOut) out[n++] = a + (uint32_t)i;
    }
    return n;
}

static uint32_t FindFuncStartBack(uint32_t ref, uint32_t lo)
{
    const uint32_t lim = (ref > lo + 0x1000) ? (ref - 0x1000) : lo;
    for (uint32_t b = ref - 1; b > lim; --b) {
        uint8_t c0 = 0, c1 = 0;
        __try { c0 = *(const uint8_t*)(uintptr_t)b; c1 = *(const uint8_t*)(uintptr_t)(b - 1); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return ref; }
        if (c0 == 0xCC && c1 == 0xCC) return b + 1;
    }
    return ref;
}

static int CollectChatCandidates(uint32_t* out, int maxOut)
{
    int n = 0;
    const uint32_t base = Wc3GameBase();
    if (!base) { LogLine("聊天函数定位：拿不到 Game.dll 基址"); return 0; }
    uint32_t tStart = 0, tSize = 0;
    if (!Wc3TextRange(base, &tStart, &tSize)) { LogLine("聊天函数定位：拿不到 .text 范围"); return 0; }
    uint32_t imgSize = Wc3ImageSize(base);
    if (!imgSize || imgSize > 0x4000000u) imgSize = 0x1000000u;   // 上限 64MB，取不到〔?〕16MB 〔?〕
    const uint32_t imgEnd = base + imgSize;

    const char* keys[2] = { "CHAT_RECIPIENT_ALL", "CHAT_RECIPIENT_ALLIES" };
    for (int k = 0; k < 2; ++k) {
        const uint32_t sva = FindImageAscii(keys[k], base, imgEnd);
        LogLine("聊天函数定位：字符串 \"%s\" -> %08X（Game.dll+%X）",
                keys[k], sva, sva ? (sva - base) : 0);
        if (!sva) continue;

        uint32_t refs[32];
        const int rn = ScanDwordRefs(tStart, tStart + tSize, sva, refs, 32);
        LogLine("   找到 %d 处引用该字符串的指令", rn);
        for (int i = 0; i < rn; ++i) {
            const uint32_t fs = FindFuncStartSmart(refs[i], tStart);   // v1.3.33：只认可信入〔?〕
            if (!fs) { LogLine("   引用点 %08X 附近找不到可信函数入口，丢弃", refs[i]); continue; }
            int dup = 0;
            for (int j = 0; j < n; ++j) if (out[j] == fs) dup = 1;
            if (dup || n >= maxOut) continue;
            out[n++] = fs;
            int isJump = 0;
            PlausibleEntry(fs, &isJump);
            uint8_t b[6] = { 0 };
            __try { for (int q = 0; q < 6; ++q) b[q] = *(const uint8_t*)(uintptr_t)(fs + q); }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
            LogLine("   候选函数 %08X（Game.dll+%X）序言 %02X %02X %02X %02X %02X %02X%s",
                    fs, fs - base, b[0], b[1], b[2], b[3], b[4], b[5],
                    isJump ? "（入口是跳转=被别人挂钩过）" : "");
        }
    }
    return n;
}

// native 模式定位聊天显示函数：已〔?〕RVA 优先（入口允许是〔?〕Detours 改过的跳转）〔?〕
// 不可信时才退回字符串反查 —〔?〕而且只有【恰好一个】可信候选才采用，有歧义就不钩〔?〕
static uint32_t LocateChatFnNative()
{
    const uint32_t base = Wc3GameBase();
    if (!base) { LogLine("聊天函数定位(native)：拿不到 Game.dll 基址"); return 0; }

    // 〔?〕已知 RVA。本〔?〕on-disk 〔?〕Game.dll 与运行时加载的那份是【同一二进制〔?〕
    //    （段表、ImageBase、字符串偏移逐字节一致），所以这〔?〕RVA 可信〔?〕
    //    入口〔?〕WFE 〔?〕Detours 改成 E9 也算可信（PlausibleEntry 会验证跳转目标可执行）〔?〕
    {
        const uint32_t fn = base + 0x355CF0;
        int isJump = 0;
        if (PlausibleEntry(fn, &isJump)) {
            LogLine("聊天函数定位(native)：已知 RVA 0x355CF0 -> %08X 入口可信%s",
                    fn, isJump ? "（是 Detours 改过的跳转入口，稍后会跟到最后一级再挂）" : "（正常序言）");
            return fn;
        }
        LogLine("聊天函数定位(native)：已知 RVA 0x355CF0 -> %08X 入口不可信，转字符串反查", fn);
    }

    // 〔?〕字符串反查兜〔?〕
    uint32_t cands[CHAT_MAX_CAND] = { 0 };
    const int n = CollectChatCandidates(cands, CHAT_MAX_CAND);
    if (n == 1) {
        LogLine("聊天函数定位(native)：字符串反查得到唯一可信候选 %08X，采用", cands[0]);
        return cands[0];
    }
    if (n == 0) LogLine("聊天函数定位(native)：字符串反查没有可信候选");
    else        LogLine("聊天函数定位(native)：字符串反查得到 %d 个候选（有歧义，可能是签名不同的兄弟函数）——"
                       "不挂钩，只留日志", n);
    return 0;
}

// 初始化入口（〔?〕Initialize 里调用一次）
static void InitDirectChat();   // v1.4.1：直投聊天的地址校验（定义在后面）

static void InitChatHook()
{
    if (!g_cfg.chat_cmd) {
        LogLine("聊天命令：已按 ini 关闭（chat_cmd=0），当前模式=%d(%s)",
                (int)g_mode, ModeNameAscii((int)g_mode));
        return;
    }

    InitChatSendBlock();    // v1.4.23：拦截 @ 命令发送，只本地处理、不广播

    if (g_nativeMode) {
        LogLine("聊天命令：native 模式 —— 已知 RVA 优先 + 入口可信性校验（v1.3.33，只钩唯一一个）");
        const uint32_t fn = LocateChatFnNative();
        if (!fn) {
            LogLine("聊天命令：未找到可信的聊天显示函数，本次命令不可用（伤害显示不受影响）");
            return;
        }
        if (!InstallChatHookSlot(fn)) {
            LogLine("聊天命令：挂钩失败，本次命令不可用（伤害显示不受影响）");
            return;
        }
        LogLine("聊天命令：命令前缀 \"%s\"（调用链会打在 C 聊天 那行下面）", g_cfg.chat_prefix);
        InitChatPostDiag();     // v1.3.39：只读诊断，dump 游戏投递的"聊天事件对象"
        InitProbeHooks();       // v1.3.45：签名无关探针（只在 chat_diag=1 时安装）
        InitDirectChat();       // v1.4.1：直投聊天的地址校验（只校验序言，不做任何调用）
        InitMarkerScan();       // v1.3.50：扫标记定位聊天输入框，并给它的虚表方法挂探〔?〕
        return;
    }

    const uint32_t fn = LocateInGameChatWhat();
    if (!fn) {
        LogLine("聊天命令：未能定位聊天显示函数，本次启动命令不可用（伤害显示不受影响）");
        return;
    }
    if (!InstallChatHookSlot(fn)) {
        LogLine("聊天命令：挂钩失败，为安全起见不挂接（伤害显示不受影响）");
        return;
    }
    LogLine("聊天命令：命令前缀 \"%s\"", g_cfg.chat_prefix);
}

//------------------------------------------------------------------------------
// 7.7 热键（Ctrl+Alt+<〔?〕）—〔?〕完全不经过聊天，所以命令不会发给其他玩〔?〕
//   1/2/3/0 = 切模〔?〕R = 记录当前选中的单〔?〕
//   Q = 看统〔?〕S = 停止结算            C = 复制统计到剪贴板
// 实现：自己的线程轮询 GetAsyncKeyState（按 50ms，边沿触发防连发），
//       只在"前台窗口属于本进〔?〕时响应，避免切出去还误触发〔?〕
//       动作本身直接复用聊天命令的处理函数（回执/日志完全一致）〔?〕
//------------------------------------------------------------------------------
static volatile LONG g_hotkeyStop = 0;

//------------------------------------------------------------------------------
// 7.6.1 联机判定 + 选区取〔?〕
//
// 为什么这么小心（实测结论〔?〕026-09-27 多人联机）：
//   * Ctrl+Alt+1/2/3（只〔?〕JASS + 发消息）                〔?〕不会不同〔?〕〔?〕
//   * @魔狼〔?〕/ @1 / @2 / @3（聊天钩子，同上〔?〕〔?〕不会不同〔?〕〔?〕
//   * Ctrl+Alt+R/T（CreateGroup + GroupEnumUnitsSelected）→ 平台〔?〕不同〔?〕异常" 
//   即：热键投递、游戏线程里〔?〕JASS、发消息全都清白，栽〔?〕选区"这一件事上〔?〕
//   机理（两条都有嫌疑，任一条都足以致命）：
//     〔?〕WC3 的选区【默认不同步】（官方为此专门给了 SyncSelections()），
//        用选区枚举可能惊动选择同步/平台的同步校验；
//     〔?〕每次按键 CreateGroup+DestroyGroup 会在【本地】分〔?〕释放句柄 ID〔?〕
//        地图脚本若用句柄 ID 索引单位，本〔?〕ID 就与别人错开 〔?〕模拟分叉〔?〕
//   对策：默〔?〕auto —〔?〕单人局照旧能用，多人局直接不碰选区，改〔?〕@名字/@类型码〔?〕
//   （pick=3/reuse 是留〔?〕判定到底是①还是〔?〕的实验档。）
//------------------------------------------------------------------------------

// 统计"人类玩家"个数：只用只〔?〕native（Player / GetPlayerSlotState / GetPlayerController）〔?〕
// 这三个都是读玩家状态，和已经验证安全的 GetPlayerId/IsPlayerAlly 同类，不分配句柄〔?〕
//------------------------------------------------------------------------------
// v1.3.75：native 模式的【人类玩家数】探测（原实现直接 return 0，导致联机被当单人）
//
//   为什么要它：Ctrl+Alt+R 会根据"人类玩家数"决定走哪条取选区的路。
//   单人 -> 引擎直调（CreateGroup + GroupEnumUnitsSelected）；
//   联机 -> 只读内存（不建组、不分配句柄）。
//   老实现 `if (g_nativeMode) return 0;` 让联机局也报 0，于是在 7 人局里
//   照样建组枚举 -> 平台报"不同步/异常"甚至掉线。
//
//   这里改用引擎自己的两个 native（名表 A 里都有，已逐字节核对序言）：
//     GetPlayerController  RVA 0x1E3CC0  __cdecl(Hplayer;)Hmapcontrol;  0 = USER(人类)
//     GetPlayerSlotState   RVA 0x1E3FE0  __cdecl(Hplayer;)Hplayerslotstate;  1 = PLAYING
//     Player               RVA 0x1F1E70  __cdecl(I)Hplayer;
//     GetPlayers           RVA 0x1E4350  __cdecl()I;
//   全是只读查询，不分配句柄、不改任何游戏状态，联机安全。
//------------------------------------------------------------------------------
#define WC3_RVA_NAT_PLAYER            0x001F1E70u
#define WC3_RVA_NAT_GETPLAYERS        0x001E4350u
#define WC3_RVA_NAT_PLAYERCTRL        0x001E3CC0u
#define WC3_RVA_NAT_SLOTSTATE         0x001E3FE0u
static const uint8_t kWc3Pro3PlayerNat[3] = { 0x55, 0x8B, 0xEC };   // push ebp; mov ebp,esp

static uint32_t g_natPlayer        = 0;
static uint32_t g_natGetPlayers    = 0;
static uint32_t g_natPlayerCtrl    = 0;
static uint32_t g_natPlayerSlot    = 0;

static int Wc3ResolvePlayerNatives()
{
    if (g_natPlayer && g_natPlayerCtrl && g_natPlayerSlot) return 1;
    if (!g_natPlayer)
        Wc3ResolveNative("Player", "Player", WC3_RVA_NAT_PLAYER, &g_natPlayer, kWc3Pro3PlayerNat);
    if (!g_natGetPlayers)
        Wc3ResolveNative("GetPlayers", "GetPlayers", WC3_RVA_NAT_GETPLAYERS, &g_natGetPlayers, kWc3Pro3PlayerNat);
    if (!g_natPlayerCtrl)
        Wc3ResolveNative("GetPlayerController", "GetPlayerController", WC3_RVA_NAT_PLAYERCTRL,
                         &g_natPlayerCtrl, kWc3Pro3PlayerNat);
    if (!g_natPlayerSlot)
        Wc3ResolveNative("GetPlayerSlotState", "GetPlayerSlotState", WC3_RVA_NAT_SLOTSTATE,
                         &g_natPlayerSlot, kWc3Pro3PlayerNat);
    return (g_natPlayer && g_natPlayerCtrl && g_natPlayerSlot) ? 1 : 0;
}

// 返回 -1 = 探测不了（调用方按联机处理，宁可不碰选区）
static int Wc3CountHumanPlayersNative()
{
    if (!g_nativeMode) return -1;
    if (!Wc3ResolvePlayerNatives()) return -1;

    int total = 0;
    __try {
        total = (int)((uint32_t (__cdecl*)(void))(uintptr_t)g_natGetPlayers)();
    } __except (EXCEPTION_EXECUTE_HANDLER) { total = 0; }
    if (total < 1 || total > 24) total = 16;      // 取不到就按满槽位扫

    int humans = 0;
    __try {
        for (int i = 0; i < total; ++i) {
            const uint32_t p = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)g_natPlayer)((uint32_t)i);
            if (!p) continue;
            const uint32_t slot = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)g_natPlayerSlot)(p);
            if (slot != 1u) continue;                                  // 1 = PLAYING
            const uint32_t ctrl = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)g_natPlayerCtrl)(p);
            if (ctrl > 1u) continue;                                   // 0 = USER, 1 = COMPUTER
            if (ctrl == 0u) ++humans;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 联机判定：native 探测异常 code=%08X -> 按联机处理（不碰选区 API）",
                (uint32_t)GetExceptionCode());
        return -1;
    }
    return humans;
}

static int CountHumanPlayers()
{
    // native 模式：本阶段没有准备 Player/GetPlayerSlotState/GetPlayerController 〔?〕native 助手〔?〕
    // 一律按"单人/判不出来"处理（返回〔?〕0 〔?〕!g_call 时的语义一致）—〔?〕
    // 于是 Ctrl+Alt+R 只会走【纯内存读选区】（联机安全，不建组、不分配句柄）〔?〕
    // v1.3.75：不再 return 0 —— 那会把联机局误判成单人，进而在联机里
    //   CreateGroup + GroupEnumUnitsSelected（平台报不同步/掉线的元凶）。
    //   探测不了（返回 -1）时按【联机】处理：上层会只走只读内存路径。
    const int natHumans = Wc3CountHumanPlayersNative();
    if (natHumans >= 0) {
        static volatile LONG s_logged = 0;
        if (InterlockedExchange(&s_logged, 1) == 0)
            LogLine("联机判定(native)：人类玩家=%d（用 GetPlayerSlotState/GetPlayerController 探测）",
                    natHumans);
        return natHumans;
    }
    if (g_nativeMode) {
        static volatile LONG s_fail = 0;
        if (InterlockedExchange(&s_fail, 1) == 0)
            LogLine("W 联机判定(native)：探测不可用 -> 按【联机】处理（选区只走只读内存，不建组）");
        return 2;                      // 报 2 = 至少两个人 -> 走最保守路径
    }
    if (!g_call) return 0;
    int n = 0;
    __try {
        for (int i = 0; i < 12; ++i) {
            uint32_t p = (uint32_t)g_call("Player", i);
            if (!p) continue;
            if ((uint32_t)g_call("GetPlayerSlotState", p) != 1) continue;   // 1 = PLAYING
            if ((uint32_t)g_call("GetPlayerController", p) != 0) continue;  // 0 = USER（人类）
            ++n;
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 热键：联机判定异常（code=%08X）", (uint32_t)GetExceptionCode());
    }
    return n;
}

// pick 档位解析：返〔?〕true 表示"这次允许碰选区"
//   auto(0)：单人允许；多人跳过
//   on(1)  ：总是允许（联机有风险〔?〕
//   off(2) ：总是跳过
//   reuse(3)：用缓存组（只分配一次），联机也〔?〕允许"，用来做实验
static int PickAllowed(int humans)
{
    switch (g_cfg.pick) {
    case 1: return 1;
    case 2: return 0;
    case 3: return 1;
    default: return (humans >= 0 && humans <= 1) ? 1 : 0;   // 判不出来时按"联机"处理，宁可不〔?〕
    }
}

// 人类玩家数只算一次并缓存（玩家中途进出对我们没影响：只用来判〔?〕是不是联〔?〕〔?〕
// v1.3.70 路线 A：本节的引擎直调要用到后面才定义的 LocalPlayerId（§8 附近）。
//   这里显式前置声明，免得"用了还没声明"（本文件没有统一的头文件）。
static int LocalPlayerId();

static int CountHumanPlayersCached()
{
    static volatile LONG s_cached = -1;
    LONG v = InterlockedCompareExchange(&s_cached, 0, 0);
    if (v >= 0) return (int)v;
    v = (LONG)CountHumanPlayers();
    InterlockedExchange(&s_cached, v);
    LogLine("热键：联机判定 人类玩家数=%d（只在第一次用时探测一次）", (int)v);
    return (int)v;
}

// 取本地玩家当前选中的单位句柄；取不到返〔?〕0
// 注意：必须跑在游戏线程上（JASS VM 是线程亲和的），所以只〔?〕OnHotkeyGameThread 调用〔?〕
static uint32_t GetSelectedUnitHandle()
{
    // native 模式：这条"建组枚举"路依赖 JASS 调用器（g_call），native 下没有。
    //   v1.3.70 起 native 走 GetSelectedUnitHandleNative（引擎直调，见 §7.6.3），
    //   本函数只在 JAPI 后端、或直调失败被上层当兜底调用时才会进来；
    //   native 下进来必然失败，直接返回（不再每次按键都刷一行日志）。
    if (g_nativeMode) return 0;
    if (!g_call) { LogLine("热键：选区失败 —— JASS 调用器未就绪（g_call=0）"); return 0; }
    __try {
        uint32_t lp = GetLocalPlayerHandle();
        if (!lp) { LogLine("热键：选区失败 —— 取不到本地玩家句柄"); return 0; }

        // pick=reuse 档：组只建一次并一直复用（不再 Destroy），用来判断"反复分配句柄"是不是元〔?〕
        static uint32_t s_pickGroup = 0;
        const int reuse = (g_cfg.pick == 3);
        uint32_t grp = 0;
        if (reuse) {
            if (!s_pickGroup) s_pickGroup = (uint32_t)g_call("CreateGroup");
            grp = s_pickGroup;
            if (!grp) { LogLine("热键：选区失败 —— 缓存组创建失败"); return 0; }
            g_call("GroupClear", grp);
        } else {
            grp = (uint32_t)g_call("CreateGroup");
            if (!grp) { LogLine("热键：选区失败 —— CreateGroup 返回 0"); return 0; }
        }

        uint32_t unit = 0;
        __try {
            g_call("GroupEnumUnitsSelected", grp, lp, 0);   // filter 〔?〕0 = 不过〔?〕
            unit = (uint32_t)g_call("FirstOfGroup", grp);
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            LogLine("E 热键：选区枚举异常（code=%08X）", (uint32_t)GetExceptionCode());
            unit = 0;
        }
        if (!reuse) g_call("DestroyGroup", grp);
        LogLine("热键：选区探针 本地玩家=%08X 组=%08X 首单位=%08X（%s）",
                lp, grp, unit, reuse ? "复用组" : "建组即销");
        return unit;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 热键：取选中单位异常（code=%08X）", (uint32_t)GetExceptionCode());
        return 0;
    }
}

//------------------------------------------------------------------------------
// 7.6.2 纯内存读选区（联机安全：不建组、不调选区 native、不分配任何句柄〔?〕
//
// 1.27.0.52240 (game.dll) 实测路径（反汇编 GroupEnumUnitsSelected 实现 @ RVA 0x1E6BF0 得出）：
//   Hplayer --( __thiscall RVA 0x1D03D0, ecx=句柄 )--> CPlayer*
//   [CPlayer* + 0x34] = 选区容器* （内〔?〕std::vector<CUnit*>〔?〕
//   [容器 + 0x00] = CUnit** begin   [容器 + 0x04] = 数量
//   *begin = 第一个选中单位 CUnit*  --( ydbase object_to_handle )--> JASS 单位句柄
// 依据〔?〕x6F1E6C2D `mov ecx,[ebp+0xC]; call 0x6F1D03D0`〔?〕x6F1E6C51 `mov ecx,[esi+0x34]`〔?〕
//       0x6F1E6CA0/CA3 `mov ecx,[ebp-0x20]; mov esi,[ecx+edi*4]`（循环上界来〔?〕[ebp-0x24]）〔?〕
// 为什么不〔?〕GroupEnumUnitsSelected：实测它内部只调 "组->Clear()" "组->AddUnit()"
//   真正惹祸的是我们自己 CreateGroup/DestroyGroup 在【本地】分配句〔?〕ID
//   （地图脚本若用句〔?〕ID 索引单位 〔?〕本机与别人错开 〔?〕数据不同步）〔?〕
// 防御：基址取模块句柄（不写〔?〕0x6F000000，ASLR 也安全）+ 函数序言自检 + Readable + __try〔?〕
//       任何一步不对就返回 0，由调用方按 pick 档位降级〔?〕
//------------------------------------------------------------------------------
#define WC3_RVA_PLAYER_FROM_HANDLE 0x001D03D0u   // Hplayer -> CPlayer*（仅 1.27.0.52240 有效〔?〕
#define WC3_RVA_GEUS_IMPL          0x001E6BF0u   // GroupEnumUnitsSelected 实现（仅日志用）
#define WC3_OFF_PLAYER_SELECTION   0x34u         // [CPlayer*+0x34] = 选区对象(CSelection*)
// 纯全局链（War3Trainer 用的同一条；不需要执行任何引擎代码）〔?〕
//   G = *(game.dll + 0xBE4238)（这也是 GEUS 〔?〕`mov ecx,ds:[6FBE4238h]` 的那个全局〔?〕
//   idx = *(uint16*)(G+0x28) 是本地玩家索引，CPlayer = *(G+0x58 + idx*4)
#define WC3_RVA_GAME_ROOT          0x00BE4238u
#define WC3_OFF_ROOT_LOCALIDX      0x28u
#define WC3_OFF_ROOT_PLAYERARR     0x58u
// sel(CSelection) 的虚表与另一个字段，仅用〔?〕布局自检"〔?〕.27 专用，换版本只打印不阻断〔?〕
#define WC3_RVA_SEL_VTABLE         0x00974A08u
#define WC3_RVA_SEL_FIELD14        0x00970764u

static uint32_t g_gameBase = 0;                  // game.dll 模块基址（ASLR 安全〔?〕

typedef uint32_t (__fastcall *fn_handle_to_player_t)(uint32_t handle, void* dummy_edx);

// 定义在本函数之后（用 object_to_handle + GetUnitTypeId + GetUnitName 三重校验候选数组）
static uint32_t ValidateUnitArray(uint32_t base, uint32_t count, uint32_t* outObj, char* outName, size_t nameCap);
// 同上，但直接校验"这个 dword 本身就是单位对象指针"（首/末选中单位那种存法〔?〕
static uint32_t ValidateUnitObject(uint32_t uo, char* outName, size_t nameCap);
// 已知答案反查（定义在后面）：拿真值句柄去容器/玩家对象里找选区字段
static void LocateSelectionField(uint32_t playerObj, uint32_t container, uint32_t wantHandle);
// 已确证布局的读取（定义在后面）：sel+0x08/0x0C = 〔?〕末选中节点，节〔?〕0x04 = 单位对象
static uint32_t ReadSelectionByKnownLayout(uint32_t sel, uint32_t* outObj, char* outName, size_t nameCap);

static uint32_t GetSelectedUnitHandleByMemory(int* outHits, uint32_t knownHandle)
{
    static fn_handle_to_player_t s_playerFromHandle = NULL;
    static volatile LONG         s_resolveFailed    = 0;

    if (!s_playerFromHandle) {
        if (InterlockedCompareExchange(&s_resolveFailed, 0, 0)) return 0;
        HMODULE game = GetModuleHandleA("game.dll");
        if (!game) {
            InterlockedExchange(&s_resolveFailed, 1);
            LogLine("选区(内存)：未加载 game.dll，放弃内存读");
            return 0;
        }
        uintptr_t fn = (uintptr_t)game + WC3_RVA_PLAYER_FROM_HANDLE;
        g_gameBase = (uint32_t)(uintptr_t)game;      // 纯全局链也要用它（不只是访问器〔?〕
        uint8_t probe[3] = { 0 };
        __try { memcpy(probe, (const void*)fn, sizeof(probe)); }
        __except (EXCEPTION_EXECUTE_HANDLER) { probe[0] = 0; }
        if (!(probe[0] == 0x55 && probe[1] == 0x8B && probe[2] == 0xEC)) {   // push ebp; mov ebp,esp
            InterlockedExchange(&s_resolveFailed, 1);
            LogLine("选区(内存)：game.dll 版本不匹配（RVA 0x%X 序言=%02X %02X %02X），"
                    "放弃内存读并降级", WC3_RVA_PLAYER_FROM_HANDLE, probe[0], probe[1], probe[2]);
            return 0;
        }
        s_playerFromHandle = (fn_handle_to_player_t)fn;
        // 顺手〔?〕这次到底加载的是哪个 game.dll"记下来：
        // 平台可能带自己的构建，若不是子代理分析的那份〔?〕.27.0.52240, 13,187,048 字节），
        // RVA 就不成立 —〔?〕靠这条日志一眼判定〔?〕
        {
            char dllPath[MAX_PATH] = { 0 };
            GetModuleFileNameA(game, dllPath, MAX_PATH);
            HANDLE hf = CreateFileA(dllPath, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                                    NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
            DWORD fsz = 0;
            if (hf != INVALID_HANDLE_VALUE) { fsz = GetFileSize(hf, NULL); CloseHandle(hf); }
            LogLine("选区(内存)：game.dll 基址=%08X 文件大小=%u 路径=%s",
                    (uint32_t)(uintptr_t)game, fsz, dllPath);
        }
        LogLine("选区(内存)：已定位 Hplayer->CPlayer* @ game.dll+0x%X（序言校验通过）",
                WC3_RVA_PLAYER_FROM_HANDLE);
    }
    if (!g_object_to_handle && !g_nativeMode) { LogLine("选区(内存)：ydbase object_to_handle 不可用"); return 0; }

    uint32_t lp = GetLocalPlayerHandle();
    if (!lp) { LogLine("选区(内存)：取不到本地玩家句柄"); return 0; }

    __try {
        // ①a 纯内存链（War3Trainer 同款〔?〕*不执行任何引擎代〔?〕*）：
        //     G=*(game.dll+0xBE4238)  idx=*(uint16*)(G+0x28)  CPlayer=*(G+0x58+idx*4)
        uint32_t player = 0;
        const char* src = "全局伤";
        if (g_gameBase && Readable((const void*)(uintptr_t)(g_gameBase + WC3_RVA_GAME_ROOT), 4)) {
            uint32_t G = *(volatile uint32_t*)(uintptr_t)(g_gameBase + WC3_RVA_GAME_ROOT);
            if (G && Readable((const void*)(uintptr_t)(G + WC3_OFF_ROOT_LOCALIDX), 4)) {
                uint32_t idx = *(volatile uint16_t*)(uintptr_t)(G + WC3_OFF_ROOT_LOCALIDX);
                if (idx < 32u && Readable((const void*)(uintptr_t)(G + WC3_OFF_ROOT_PLAYERARR + idx * 4u), 4))
                    player = *(volatile uint32_t*)(uintptr_t)(G + WC3_OFF_ROOT_PLAYERARR + idx * 4u);
            }
        }

        // ①b 兜底：调引擎〔?〕Hplayer->CPlayer* 访问器（__thiscall 等价写法：ecx=句柄，哑 edx〔?〕
        if (!player) {
            src = "访问器";
            player = (uint32_t)s_playerFromHandle(lp, NULL);
            if (!player) {                                 // 再试"玩家索引 0..11"
                int pid = LocalPlayerId();
                if (pid >= 0) { player = (uint32_t)s_playerFromHandle((uint32_t)pid, NULL); src = "访问器(索引)"; }
            }
        }
        if (!player || !Readable((const void*)(uintptr_t)player, 0x40)) {
            LogLine("选区(内存)：Hplayer %08X -> 玩家对象 %08X 不可读（全局与访问器都试过）", lp, player);
            return 0;
        }
        LogLine("选区(内存)：玩家对象 %08X（来源 %s）", player, src);

        // ①b 交叉校验（只记警告，不否决）〔?〕
        //     "这个访问器返回的就是玩家对象"原本只是强推断，〔?〕object_to_handle 未必支持
        //     玩家对象（可能返〔?〕0 或别的值）。真正有意义的闸门在 ⑤（用单位名反证句柄）〔?〕
        {
            uint32_t ph = ObjToHandle((uintptr_t)player);
            if (ph && ph != lp) {
                LogLine("W 选区(内存)：玩家对象->句柄=%08X 与本地玩家句柄 %08X 不一致（仅警告，"
                        "继续尝试；若下面没有拿到有效单位名就说明访问器选错了）", ph, lp);
            }
        }

        // 〔?〕[CPlayer*+0x34] = 选区容器
        uint32_t sel = *(volatile uint32_t*)(uintptr_t)(player + WC3_OFF_PLAYER_SELECTION);
        if (!sel) { LogLine("选区(内存)：选区容器为空（没选中任何单位）"); return 0; }
        if (!Readable((const void*)(uintptr_t)sel, 12)) {
            LogLine("选区(内存)：选区容器 %08X 不可读", sel);
            return 0;
        }

        // ③a 先用【已确证布局】快路径（sel+0x08/0x10 的节点链，节〔?〕0x08 = 选中单位对象〔?〕
        uint32_t unitObj = 0;
        uint32_t h = 0;
        char     nm[128] = { 0 };
        h = ReadSelectionByKnownLayout(sel, &unitObj, nm, sizeof(nm));
        if (h) { if (outHits) *outHits = 1; return h; }

        // ③b 布局变了时的兜底：扫描容器里的候〔?〕
        int      hitOff = -1;
        uint32_t hitCount = 0;
        int      hits = 0;                 // 命中候选数〔?〕1 视为不唯一，不敢用〔?〕
        {
            uint32_t dump[16] = { 0 };
            for (int k = 0; k < 16; ++k) {
                if (Readable((const void*)(uintptr_t)(sel + k * 4), 4))
                    dump[k] = *(volatile uint32_t*)(uintptr_t)(sel + k * 4);
            }
            LogDebug("选区(内存)：容器 %08X 前6个dword=[0]=%08X [1]=%08X [2]=%08X [3]=%08X "
                    "[4]=%08X [5]=%08X [6]=%08X [7]=%08X",
                    sel, dump[0], dump[1], dump[2], dump[3], dump[4], dump[5], dump[6], dump[7]);

            // 〔?〕先试"dword 本身就是选中单位对象指针"（观测：容器 [2]/[3]=〔?〕末选中单位、[4]=数量〔?〕
            for (int i = 0; i < 16 && hits < 2; ++i) {
                if (!dump[i]) continue;
                char nm2[128] = { 0 };
                uint32_t h2 = ValidateUnitObject(dump[i], nm2, sizeof(nm2));
                if (!h2) continue;
                if (h2 == h) continue;                       // 同一个单位（〔?〕=末）不重复计〔?〕
                ++hits;
                h = h2; unitObj = dump[i]; hitOff = i; hitCount = 0;
                strncpy_s(nm, sizeof(nm), nm2, _TRUNCATE);
            }

            for (int i = 0; i < 16 && hits < 2; ++i) {
                uint32_t base = dump[i];
                if (!base) continue;
                for (int j = i + 1; j < 16 && j <= i + 4 && hits < 2; ++j) {
                    uint32_t v = dump[j];
                    // 布局 ①：数量
                    if (v >= 1 && v <= 0x4000u) {
                        uint32_t h2 = ValidateUnitArray(base, v, &unitObj, nm, sizeof(nm));
                        if (h2) { ++hits; h = h2; hitOff = i; hitCount = v; break; }
                    }
                    // 布局 ②：末指〔?〕{begin, end}
                    if (v > base && ((v - base) % 4u) == 0u) {
                        uint32_t c2 = (v - base) / 4u;
                        if (c2 >= 1 && c2 <= 0x4000u) {
                            uint32_t h2 = ValidateUnitArray(base, c2, &unitObj, nm, sizeof(nm));
                            if (h2) { ++hits; h = h2; hitOff = i; hitCount = c2; break; }
                        }
                    }
                }
            }
        }
        if (outHits) *outHits = hits;
        // 有真值（单机下旧枚举的结果）时，做一〔?〕已知答案反查"，把选区的存放位置钉〔?〕
        if (knownHandle) {
            if (h && h != knownHandle) {
                LogLine("W 选区(内存)：扫描结果 %08X 与真实 %08X 不一致（扫描不可信）", h, knownHandle);
            }
            LocateSelectionField(player, sel, knownHandle);
        }
        if (h && hits == 1) {
            if (hitCount == 0) {
                LogLine("选区(内存)：命中！（直接对象）容器+0x%X = 单位对象 %08X 句柄=%08X 类型=%08X 名字=\"%s\"",
                        hitOff * 4, unitObj, h, GetUnitTypeKey(h), nm);
            } else {
                LogLine("选区(内存)：命中！（数组）容器+0x%X 为数组、数量取自+0x%X=%u 单位对象=%08X 句柄=%08X 类型=%08X 名字=\"%s\"",
                        hitOff * 4, hitOff * 4 + 4, hitCount, unitObj, h, GetUnitTypeKey(h), nm);
            }
            return h;
        }
        if (h) {
            LogLine("W 选区(内存)：扫到 %d 个可验证候选（不唯一），不敢用，当作未命中", hits);
            return 0;
        }
        LogDebug("选区(内存)：容器里没扫到可验证的单位数组（可能真的没选中单位，或布局又变了）");
        return 0;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 选区(内存)：异常 code=%08X", (uint32_t)GetExceptionCode());
        return 0;
    }
}

// 〔?〕(base, count) 当成 CUnit* 数组验证：必须能取出至少一〔?〕合法单位"才算数〔?〕
// 三重校验：指针可〔?〕〔?〕object_to_handle 〔?〕0 〔?〕GetUnitTypeId 〔?〕0 〔?〕GetUnitName 非空〔?〕
// 这样即使容器字段布局/偏移和推断有差，也不会误判成别的对象〔?〕
static uint32_t ValidateUnitArray(uint32_t base, uint32_t count, uint32_t* outObj, char* outName, size_t nameCap)
{
    if (!base || !count || count > 0x4000u) return 0;
    const uint32_t n = (count < 4u) ? count : 4u;      // 只在头几个元素里找，够用且省调用
    for (uint32_t i = 0; i < n; ++i) {
        if (!Readable((const void*)(uintptr_t)(base + i * 4u), 4)) return 0;
        uint32_t uo = *(volatile uint32_t*)(uintptr_t)(base + i * 4u);
        if (!uo) continue;
        uint32_t h = ObjToHandle((uintptr_t)uo);
        if (!h) continue;
        uint32_t tid = GetUnitTypeKey(h);              // GetUnitTypeId：合法单位非 0
        if (!tid) continue;
        char nm[128] = { 0 };
        GetUnitLabel(h, nm, sizeof(nm));               // 单位名：合法单位非空
        if (!nm[0]) continue;
        if (outObj) *outObj = uo;
        if (outName && nameCap) strncpy_s(outName, nameCap, nm, _TRUNCATE);
        return h;
    }
    return 0;
}

// 校验"这个 dword 本身就是单位对象指针"（观察到的容器布局 [2]/[3]=〔?〕末选中单位、[4]=数量〔?〕
static uint32_t ValidateUnitObject(uint32_t uo, char* outName, size_t nameCap)
{
    if (!uo || uo < 0x00010000u) return 0;
    if (!Readable((const void*)(uintptr_t)uo, 4)) return 0;
    uint32_t h = ObjToHandle((uintptr_t)uo);
    if (!h) return 0;
    if (!GetUnitTypeKey(h)) return 0;                  // GetUnitTypeId 〔?〕0
    char nm[128] = { 0 };
    GetUnitLabel(h, nm, sizeof(nm));
    if (!nm[0]) return 0;                              // 单位名非〔?〕
    if (outName && nameCap) strncpy_s(outName, nameCap, nm, _TRUNCATE);
    return h;
}

// 已知答案反查：拿"旧枚举给出的正确句柄"去容〔?〕玩家对象里逐个字段比对〔?〕
// 找出"选区到底存在哪个字段"（直接是单位对象，或它指向的数组里的某个元素）〔?〕
// 这是最可靠的一步：不依赖任何布局推断，找到就是确证〔?〕
static void LocateSelectionField(uint32_t playerObj, uint32_t container, uint32_t wantHandle)
{
    if (!wantHandle || (!g_object_to_handle && !g_nativeMode)) return;
    const uint32_t bases[2] = { container, playerObj };
    const char*    names[2] = { "容器", "玩家对象" };
    int found = 0;
    for (int bi = 0; bi < 2; ++bi) {
        uint32_t b = bases[bi];
        if (!b || !Readable((const void*)(uintptr_t)b, 4)) continue;
        for (int off = 0; off <= 0x7C; off += 4) {
            if (!Readable((const void*)(uintptr_t)(b + (uint32_t)off), 4)) break;
            uint32_t v = *(volatile uint32_t*)(uintptr_t)(b + (uint32_t)off);
            if (!v || v < 0x00010000u) continue;
            if (ObjToHandle((uintptr_t)v) == wantHandle) {
                LogLine("★定位：%s+0x%X 直接就是选中单位对象 %08X -> 句柄 %08X。",
                        names[bi], off, v, wantHandle);
                ++found;
                continue;
            }
            if (!Readable((const void*)(uintptr_t)v, 16)) continue;
            for (int k = 0; k < 4; ++k) {
                uint32_t e = *(volatile uint32_t*)(uintptr_t)(v + (uint32_t)k * 4u);
                if (!e || e < 0x00010000u) continue;
                if (ObjToHandle((uintptr_t)e) == wantHandle) {
                    LogLine("★定位：%s+0x%X 指向数组 %08X，第 %d 个元素是选中单位 %08X -> 句柄 %08X。",
                            names[bi], off, v, k, e, wantHandle);
                    ++found;
                }
            }
        }
    }
    LogLine("★定位：共找到 %d 处（0 处说明选区不在这两个对象的 ±0x80 字节里）", found);
}

// 已确证布局〔?〕.27.0.52240；由"已知答案反查"实机钉死 + 引擎三处代码独立印证）：
//   sel = [CPlayer*+0x34]  （CSelection，虚〔?〕RVA 0x974A08〔?〕
//   sel+0x08 = 首个选中【节点〔?〕sel+0x10 = 选中数量     〔?〕GEUS 的唯一数据〔?〕
//   sel+0x1F0 = 另一组的首个节点  sel+0x1F8 = 数量         〔?〕备用（War3Trainer 取样用）
//   节点 = { next@+0, prev@+4, CUnit*@+8 }
//   注意：链表尾不是 NULL（可能绕回哨兵），所〔?〕*必须〔?〕count 计数**；单位指针为空则跳过〔?〕
// 全程只读，不建组、不调选区 native、不分配句柄 〔?〕联机安全〔?〕
static uint32_t ReadSelectionByKnownLayout(uint32_t sel, uint32_t* outObj, char* outName, size_t nameCap)
{
    if (!sel || !Readable((const void*)(uintptr_t)sel, 0x20)) return 0;

    // 布局自检（只打印，不阻断）
    if (g_gameBase) {
        static volatile LONG s_vtLogged = 0;
        if (InterlockedExchange(&s_vtLogged, 1) == 0) {
            uint32_t vt = 0, f14 = 0;
            if (Readable((const void*)(uintptr_t)sel, 4)) vt = *(volatile uint32_t*)(uintptr_t)sel;
            if (Readable((const void*)(uintptr_t)(sel + 0x14), 4))
                f14 = *(volatile uint32_t*)(uintptr_t)(sel + 0x14);
            LogLine("选区(内存)：布局自检 sel=%08X 虚表=%08X(期望 %08X)%s  [+0x14]=%08X(期望 %08X)",
                    sel, vt, g_gameBase + WC3_RVA_SEL_VTABLE,
                    (vt == g_gameBase + WC3_RVA_SEL_VTABLE) ? " 一致" : " 不符",
                    f14, g_gameBase + WC3_RVA_SEL_FIELD14);
        }
    }

    // ==========================================================================
    // v1.3.80【照 War3Trainer 的走法重写】
    //
    // 依据：War3Trainer.exe 的 AllSelectedUnitsNode::CreateChildren 的 IL（逐条）：
    //   IL_0063  ReadUInt32(sel + 496)  -> 头节点 first = *(sel+0x1F0)
    //   IL_0078  ReadUInt32(sel + 504)  -> 数量   count = *(sel+0x1F8)
    //   IL_008D  node = first
    //   IL_0097  ReadUInt32(node + 8)   -> CUnit* = *(node+8)
    //   IL_00B3  ReadUInt32(node + 0)   -> ★ 沿 node+0 正向前进
    //   IL_00D8  i < count              -> 用 count 计数
    //
    // 与我们之前的三处不同：
    //   起点：训练器用 sel+0x1F0（文档里的"备用链"），我之前用 sel+0x0C
    //   前进：训练器用 node+0（正向），我之前用 node+4（反向）
    //   —— 这两处正是内存读一直取不到的根因。
    // 主链（sel+0x08/+0x10）作为第二候选一起试，两条都走不到才放弃。
    // 全程只读：不建组、不调选区 native、不分配句柄。
    // ==========================================================================
    const uint32_t nodeOff[2]  = { 0x1F0u, 0x08u };     // 训练器用的那条优先
    const uint32_t countOff[2] = { 0x1F8u, 0x10u };

    for (int g = 0; g < 2; ++g) {
        if (!Readable((const void*)(uintptr_t)(sel + countOff[g]), 4)) continue;
        if (!Readable((const void*)(uintptr_t)(sel + nodeOff[g]), 4)) continue;

        const uint32_t count = *(volatile uint32_t*)(uintptr_t)(sel + countOff[g]);
        uint32_t node = *(volatile uint32_t*)(uintptr_t)(sel + nodeOff[g]);
        if (!node) continue;
        if (!count || count > 64u) continue;

        for (uint32_t i = 0; i < count; ++i) {
            if (!Readable((const void*)(uintptr_t)node, 0x0Cu)) break;

            uint32_t uo = 0;
            if (!Readable((const void*)(uintptr_t)(node + 0x08), 4)) break;
            uo = *(volatile uint32_t*)(uintptr_t)(node + 0x08);

            char nm2[128] = { 0 };
            uint32_t h = 0;
            if (uo) {
                // 候选可能是垃圾指针；校验里会调引擎函数 -> 单点 try
                __try { h = ValidateUnitObject(uo, nm2, sizeof(nm2)); }
                __except (EXCEPTION_EXECUTE_HANDLER) {
                    LogFaultAt("校验候选单位 ValidateUnitObject");
                    h = 0;
                }
            }
            if (h) {
                LogLine("选区(内存)：布局命中 链=sel+0x%X 节点=%08X（第%u/%u个）单位对象=%08X "
                        "句柄=%08X 类型=%08X 名字=\"%s\"",
                        nodeOff[g], node, i, count, uo, h, GetUnitTypeKey(h), nm2);
                if (outObj) *outObj = uo;
                if (outName && nameCap) strncpy_s(outName, nameCap, nm2, _TRUNCATE);
                return h;
            }

            // 沿 node+0 前进（训练器的走法）；必须递增，防自指环/环链
            uint32_t nx = 0;
            if (!Readable((const void*)(uintptr_t)node, 4)) break;
            nx = *(volatile uint32_t*)(uintptr_t)node;
            if (!nx || nx <= node) break;
            node = nx;
        }
    }
    return 0;
}

//------------------------------------------------------------------------------
// 7.6.3 【路线 A】引擎直调选区（native 模式专用）—— v1.3.70
//
// 为什么必须再开这条路：
//   §7.6.2 的纯内存读实机只命中一部分。2026-10-02 日志证据：
//     * 偶尔成功：`选区(内存)：布局命中 sel+0x8 节点=... 句柄=0010128F 类型=0010128F`
//     * 绝大多数失败：`路径=memory(group-failed) 句柄=00000000`
//     * 还出现过：`E 选区(内存)：异常 code=C0000005`（一次异常就把整次读取中断）
//   原因：sel 里的 +0x08（当前选区）/+0x1F0（存档组）两个 group 在多选/框选时会被引擎
//   改写，我们照着链表走很容易读到半更新状态。
//   所以 native 模式改成【直接调引擎自己的 native 实现】：和地图脚本里调
//   GroupEnumUnitsSelected 是同一条路，只是参数从 JASS 句柄换成引擎对象。
//
// 已确证事实（对象：C:\3rd\war5\Game.dll，1.27.0.52240，13,187,048 字节；
//             方法：_tools\native_table_1.27.0.52240.txt 名表 + _tools\fastdis.ps1 反汇编）
//   * 名表 A（起点 RVA 0x1E9A50、stride 20、+16 = 实现 VA）里四个都在：
//       CreateGroup            #314 ()Hgroup;                  impl RVA 0x001DE080
//       GroupClear             #318 (Hgroup;)V                 impl RVA 0x001E6940
//       GroupRemoveUnit        #317 (Hgroup;Hunit;)V           impl RVA 0x001E6E30
//       GroupEnumUnitsSelected #328 (Hgroup;Hplayer;Hboolexpr;)V
//                                                              impl RVA 0x001E6BF0
//       FirstOfGroup           #338 (Hgroup;)Hunit;            impl RVA 0x001E0850
//     ⇒ 直接用 Wc3ResolveNative(标签, 名字, RVA, ...)：先按名字查表（换版本也能自适应），
//       查不到才用 RVA 兜底，且兜底要过序言校验。四个函数的序言都是 55 8B EC。
//   * **返回值语义**（这是原来不敢直调的唯一原因，现在钉死了）：
//       CreateGroup @0x1DE080:  ... call 0x371F4C (CGroup 构造) / mov edi,eax ...
//                               call 0x2651D0 (= 本文件 WC3_RVA_OBJ_TO_HANDLE，对象->句柄，ret 8)
//                               ... mov eax,edi ... ret
//          ⇒ 返回的就是 **JASS Hgroup 句柄**（0x100000+），不是 CGroup*。
//       FirstOfGroup @0x1E0850: mov ecx,[ebp+8] / call 0x1CFB10 (Hgroup->CGroup*)
//                               / test eax,eax / je 返回 0
//                               / lea ecx,[eax+24h] / call 0x392910   (取组内当前单位)
//                               / mov ecx,ds:[6FBE4238h] / call 0x1C3200 (ctx->句柄管理器)
//                               / push 0 / push esi / call 0x2651D0     (对象->句柄)
//          ⇒ 返回的就是 **JASS Hunit 句柄**；组空时返回 0；__cdecl（自己 ret，不用清栈）。
//       GroupClear / GroupEnumUnitsSelected ：__cdecl、返回 void。
//       三个函数都【不分配新句柄】；只有 CreateGroup 会占一个句柄槽。
//   * GroupEnumUnitsSelected 内部读的就是 [CPlayer+0x34] 那个 CSelection
//     （见《选区内存定位2.md》§3.2），所以它和内存读【看的是同一份数据】，
//     区别是遍历由引擎自己完成，不会踩到半更新的链表。
//
// 安全设计（每一条都是为了"绝不把游戏搞崩"）：
//   ① 只建【一个】组、建完永久复用，**不再 DestroyGroup**：
//        一个 CGroup 的内存不回收无所谓；关键是【句柄 ID 不反复分配】——
//        地图脚本若拿句柄 ID 索引单位，本地反复分配会让本机与别人错开（模拟分叉）。
//   ② 每次用完 GroupClear，组里不留上一次的结果。
//   ③ 组句柄跟着 ctx 走：ctx 变了（换局/重进）就重新建，旧句柄绝不跨会话复用。
//   ④ 任何一步失败（解析不到 / ctx=0 / 建组失败 / 取不到单位）都只写日志 + 返回 0，
//      由上层按 pick 档位回落纯内存读 —— native 模式不会比 JAPI 模式更容易崩。
//   ⑤ RVA 兜底必须过序言校验（55 8B EC）；地址若落在函数体中间会被直接拒掉。
//   ⑥ 热键动作本来就在【游戏线程】上执行（WM_UDW_HOTKEY -> OnHotkeyGameThread），
//      所以这里调引擎 API 是线程安全的。
//------------------------------------------------------------------------------
typedef uint32_t (__cdecl *fn_wc3_creategroup_t)(void);
typedef void     (__cdecl *fn_wc3_group_h_t)(uint32_t groupHandle);
typedef void     (__cdecl *fn_wc3_group_hu_t)(uint32_t groupHandle, uint32_t unitHandle);
typedef void     (__cdecl *fn_wc3_geus_t)(uint32_t groupHandle, uint32_t playerHandle, uint32_t filter);
typedef uint32_t (__cdecl *fn_wc3_firstofgroup_t)(uint32_t groupHandle);

#define WC3_RVA_NAT_CREATE_GROUP   0x001DE080u  // CreateGroup            （仅 1.27.0.52240，只做 RVA 兜底）
#define WC3_RVA_NAT_GROUP_CLEAR    0x001E6940u  // GroupClear
#define WC3_RVA_NAT_GROUP_REMOVE   0x001E6E30u  // GroupRemoveUnit
#define WC3_RVA_NAT_GEUS           0x001E6BF0u  // GroupEnumUnitsSelected
#define WC3_RVA_NAT_FIRST_OF_GROUP 0x001E0850u  // FirstOfGroup
static const uint8_t kWc3Pro3GroupNat[3] = { 0x55, 0x8B, 0xEC };   // push ebp; mov ebp,esp

static uint32_t g_natCreateGroup   = 0;
static uint32_t g_natGroupClear    = 0;
static uint32_t g_natGroupRemove   = 0;
static uint32_t g_natGeus          = 0;
static uint32_t g_natFirstOfGroup  = 0;

static uint32_t g_natSelGroup = 0;   // 永久复用的组句柄（**不 DestroyGroup**）
static uint32_t g_natSelCtx   = 0;   // 建组时的 ctx；ctx 一变就重建

// JASS ctx 全局（= *(game.dll + 0xBE4238)）：字符串表、句柄管理器都挂在它下面。
// ctx 在"地图还没起来"时是 0，换局会变 -> 正好当"本次会话"的标识用。
static uint32_t Wc3Ctx()
{
    const uint32_t base = Wc3GameBase();
    if (!base) return 0;
    uint32_t ctx = 0;
    if (!Wc3PeekU32(base + WC3_RVA_CTX_GLOBAL, &ctx)) return 0;
    return ctx;
}

static int Wc3IsJassHandle(uint32_t h)
{
    return (h >= WC3_HANDLE_BASE && h < WC3_HANDLE_LIMIT) ? 1 : 0;
}

// 只有"换得回 CUnit* 且类型码非 0"的句柄才算拿到单位
static uint32_t Wc3AcceptUnitHandle(uint32_t h)
{
    if (!h) return 0;
    if (!Wc3HandleToUnit(h)) return 0;      // 句柄必须能换回 CUnit*
    if (!Wc3UnitTypeCode(h)) return 0;      // 类型码非 0（排除 0x100001+ 这类空槽句柄）
    return h;
}

// 解析五个 native（各只解析一次并缓存；任何一个失败就整体放弃直调）
static int Wc3ResolveSelectionNatives()
{
    if (g_natCreateGroup && g_natGroupClear && g_natGroupRemove &&
        g_natGeus && g_natFirstOfGroup) return 1;

    if (!g_natCreateGroup)
        Wc3ResolveNative("CreateGroup", "CreateGroup", WC3_RVA_NAT_CREATE_GROUP,
                         &g_natCreateGroup, kWc3Pro3GroupNat);
    if (!g_natGroupClear)
        Wc3ResolveNative("GroupClear", "GroupClear", WC3_RVA_NAT_GROUP_CLEAR,
                         &g_natGroupClear, kWc3Pro3GroupNat);
    if (!g_natGroupRemove)
        Wc3ResolveNative("GroupRemoveUnit", "GroupRemoveUnit", WC3_RVA_NAT_GROUP_REMOVE,
                         &g_natGroupRemove, kWc3Pro3GroupNat);
    if (!g_natGeus)
        Wc3ResolveNative("GroupEnumUnitsSelected", "GroupEnumUnitsSelected", WC3_RVA_NAT_GEUS,
                         &g_natGeus, kWc3Pro3GroupNat);
    if (!g_natFirstOfGroup)
        Wc3ResolveNative("FirstOfGroup", "FirstOfGroup", WC3_RVA_NAT_FIRST_OF_GROUP,
                         &g_natFirstOfGroup, kWc3Pro3GroupNat);

    if (!g_natCreateGroup || !g_natGroupClear || !g_natGroupRemove ||
        !g_natGeus || !g_natFirstOfGroup) {
        LogLine("选区(直调)：native 解析不全（建组=%08X 清空=%08X 移除=%08X "
                "枚举=%08X 取首=%08X）-> 本局不用直调，回落纯内存读",
                g_natCreateGroup, g_natGroupClear, g_natGroupRemove, g_natGeus, g_natFirstOfGroup);
        return 0;
    }
    LogLine("选区(直调)：五个 native 就绪（建组=%08X 清空=%08X 移除=%08X 枚举=%08X 取首=%08X）",
            g_natCreateGroup, g_natGroupClear, g_natGroupRemove, g_natGeus, g_natFirstOfGroup);
    return 1;
}

// 取得（必要时首次创建）那个永久复用的组句柄
static uint32_t Wc3SelectionEnsureGroup(uint32_t ctx)
{
    if (g_natSelGroup && g_natSelCtx == ctx) return g_natSelGroup;

    if (g_natSelGroup && g_natSelCtx != ctx) {
        // ctx 变了 = 换局/重开。旧句柄属于上一局的句柄表，**不去 Destroy**（碰了更危险），
        // 只是不再复用；本进程里它就是一个泄漏的组对象，可接受。
        LogLine("选区(直调)：ctx 变了（%08X -> %08X），作废上一局的复用组 %08X，本局重新建组",
                g_natSelCtx, ctx, g_natSelGroup);
        g_natSelGroup = 0;
        g_natSelCtx   = 0;
    }

    uint32_t g = 0;
    __try {
        g = ((fn_wc3_creategroup_t)(uintptr_t)g_natCreateGroup)();
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 选区(直调)：CreateGroup 异常 code=%08X", (uint32_t)GetExceptionCode());
        return 0;
    }
    if (!Wc3IsJassHandle(g)) {
        // 反汇编已确证 CreateGroup 返回 JASS 句柄；不是的话就是版本不符，宁可不用
        LogLine("W 选区(直调)：CreateGroup 返回 %08X 不是 JASS 句柄（期望 %08X~%08X）-> 放弃直调",
                g, WC3_HANDLE_BASE, WC3_HANDLE_LIMIT);
        return 0;
    }
    g_natSelGroup = g;
    g_natSelCtx   = ctx;
    LogLine("选区(直调)：已建【永久复用组】句柄=%08X 组对象=%08X（本局不再销毁、不再新建）",
            g, Wc3HandleToUnit(g));
    return g;
}

// 路线 A 主函数：引擎直调，取"本地玩家当前选中的第 index 个单位"的 Hunit
//   返回 0 = 没拿到（调用方负责回落）
static uint32_t GetSelectedUnitHandleNative(int index)
{
    if (!g_nativeMode) return 0;
    if (index < 0) index = 0;

    const uint32_t ctx = Wc3Ctx();
    if (!ctx) { LogLine("选区(直调)：ctx=0（地图还没起来或版本不符）-> 回落纯内存读"); return 0; }
    if (!Wc3ResolveSelectionNatives()) return 0;

    if (!g_gameBase) {
        g_gameBase = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
        if (!g_gameBase) { LogLine("选区(直调)：取不到 game.dll 基址 -> 回落纯内存读"); return 0; }
    }

    // ① 本地玩家对象：走 §7.6.1 已确证的纯全局链（和内存读同一条，好互相印证）
    const int lpIdx = LocalPlayerId();
    uint32_t playerObj = 0;
    __try {
        uint32_t G = 0;
        if (Readable((const void*)(uintptr_t)(g_gameBase + WC3_RVA_GAME_ROOT), 4))
            G = *(volatile uint32_t*)(uintptr_t)(g_gameBase + WC3_RVA_GAME_ROOT);
        uint32_t idx = 0;
        if (G && Readable((const void*)(uintptr_t)(G + WC3_OFF_ROOT_LOCALIDX), 2))
            idx = *(volatile uint16_t*)(uintptr_t)(G + WC3_OFF_ROOT_LOCALIDX);
        if (G && idx < 32u &&
            Readable((const void*)(uintptr_t)(G + WC3_OFF_ROOT_PLAYERARR + idx * 4u), 4))
            playerObj = *(volatile uint32_t*)(uintptr_t)(G + WC3_OFF_ROOT_PLAYERARR + idx * 4u);
    } __except (EXCEPTION_EXECUTE_HANDLER) { playerObj = 0; }
    if (!playerObj) { LogLine("选区(直调)：全局链取不到本地玩家对象 -> 回落纯内存读"); return 0; }

    const uint32_t lpHandle = GetLocalPlayerHandle();
    if (!lpHandle) { LogLine("选区(直调)：取不到本地玩家句柄 -> 回落纯内存读"); return 0; }

    // ② 组：永久复用 + 先清空
    const uint32_t grp = Wc3SelectionEnsureGroup(ctx);
    if (!grp) return 0;
    __try {
        ((fn_wc3_group_h_t)(uintptr_t)g_natGroupClear)(grp);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 选区(直调)：GroupClear 异常 code=%08X（复用组作废）", (uint32_t)GetExceptionCode());
        g_natSelGroup = 0;
        g_natSelCtx   = 0;
        return 0;
    }

    // ③ 枚举：第 3 个参数 filter 传 0 = 不过滤
    //    （签名是 (Hgroup;Hplayer;Hboolexpr;)V，引擎自己会走"没有过滤器就收全部"的分支）
    __try {
        ((fn_wc3_geus_t)(uintptr_t)g_natGeus)(grp, lpHandle, 0u);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 选区(直调)：GroupEnumUnitsSelected 异常 code=%08X；"
                "本局不再直调（应急：把 ini 的 pick 设成 2=off 或 4=memory 后重开一局）",
                (uint32_t)GetExceptionCode());
        g_natGeus     = 0;
        g_natSelGroup = 0;
        g_natSelCtx   = 0;
        return 0;
    }

    // ④ 取第 index 个：FirstOfGroup 取队首，取到就把它从组里删掉再取下一个
    //    （索引顺序 = GroupEnumUnitsSelected 的加入顺序，也就是引擎自己的选区顺序）
    uint32_t unit = 0;
    __try {
        for (int i = 0; i <= index; ++i) {
            unit = ((fn_wc3_firstofgroup_t)(uintptr_t)g_natFirstOfGroup)(grp);
            if (!unit) break;
            if (i < index)
                ((fn_wc3_group_hu_t)(uintptr_t)g_natGroupRemove)(grp, unit);
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 选区(直调)：FirstOfGroup/GroupRemoveUnit 异常 code=%08X",
                (uint32_t)GetExceptionCode());
        unit = 0;
    }

    // ⑤ 收尾：清空复用组，绝不把这次的结果留给下一次
    __try {
        ((fn_wc3_group_h_t)(uintptr_t)g_natGroupClear)(grp);
    } __except (EXCEPTION_EXECUTE_HANDLER) { }

    const uint32_t ok = Wc3AcceptUnitHandle(unit);
    {
        char nm[128] = { 0 };
        if (ok) GetUnitLabel(ok, nm, sizeof(nm));
        LogLine("选区(直调)：本地玩家#%d 玩家对象=%08X 复用组=%08X(组对象=%08X) "
                "枚举实现=%08X 首单位=%08X 采纳=%08X 类型=%08X 名字=\"%s\"",
                lpIdx, playerObj, grp, Wc3HandleToUnit(grp), g_natGeus, unit, ok,
                ok ? Wc3UnitTypeCode(ok) : 0u, ok ? nm : "");
    }
    if (!ok && unit)
        LogLine("W 选区(直调)：FirstOfGroup 返回 %08X，但不是有效单位句柄（换不回 CUnit* 或类型码=0）",
                unit);
    return ok;
}

// 把一次热键翻译成"等价于某个聊天命〔?〕，直接复用聊天命令的处理逻辑
static void DoHotkeyAsCommand(const char* cmdText) {
    // v1.4.0：HandleChatCommand 只做 ShowMessage（屏幕渲染）和本插件自己的记账，
    //   **不发任何合成按键、也不调用游戏发送函数**。"插件自己发聊天"已整体删除。
    // v1.3.87：这里不再按联机跳过。
    int localId = LocalPlayerId();
    LogLine("热键：等价命令 \"%s\"", cmdText);
    InterlockedExchange(&g_hotkeyAck, 1);
    HandleChatCommand(localId >= 0 ? localId : 0, cmdText);
    InterlockedExchange(&g_hotkeyAck, 0);
}

// 真正的执行体：跑在游戏线程上（由窗口消息触发），所以可以安全调 JASS〔?〕
static uint32_t Wc3Ctx();                     // 定义在后面（JASS ctx 全局）

// v1.4.1：直投聊天（定义在后面"直投聊天框发消息"那一段）
static void InitDirectChat();

static void OnHotkeyGameThread(int key)
{
    char cmd[64] = { 0 };
    switch (key) {
    case '0': case '1': case '2': case '3':
        _snprintf_s(cmd, sizeof(cmd), _TRUNCATE, "%s%c", g_cfg.chat_prefix, (char)key);
        DoHotkeyAsCommand(cmd);
        return;
    case 'D': {                                      // v1.3.84：开关调试日志
        const int now = g_cfg.debug ? 0 : 1;
        g_cfg.debug = now;
        LogLine("热键：Ctrl+Alt+D —— 调试日志=%d（本次运行生效，ini 不改）", now);
        char m2[160] = { 0 };
        AppUtf8(m2, sizeof(m2), g_cfg.labels
                 ? (now ? "|cffffcc00[伤害]|r 调试日志：开" : "|cffffcc00[伤害]|r 调试日志：关")
                 : (now ? "|cffffcc00[DMG]|r debug log: ON" : "|cffffcc00[DMG]|r debug log: OFF"));
        ShowMessage(m2);
        return;
    }
    case 'Q':
        _snprintf_s(cmd, sizeof(cmd), _TRUNCATE, "%s?", g_cfg.chat_prefix);
        DoHotkeyAsCommand(cmd);
        return;
    case 'S':
        _snprintf_s(cmd, sizeof(cmd), _TRUNCATE, "%s!", g_cfg.chat_prefix);
        DoHotkeyAsCommand(cmd);
        return;
    case 'R':
    {                                                 // v1.3.86：只保留 R（T 已按要求去掉）
        LogLine("热键 %c —— 记录当前选中的单位", (char)key);

        // v1.3.75：每次按键都重新探测（老实现只探一次并缓存，进程跨局时会留下错误的单人判定）。
        const int humans = (g_cfg.pick == 0) ? CountHumanPlayers() : -1;
        uint32_t u   = 0;
        int tried    = 0;
        const char* how = "none";

        if (g_cfg.pick == 2) {                        // off：彻底关〔?〕
            how = "off";
        } else if (g_cfg.pick == 1 || g_cfg.pick == 3) {   // on / reuse：强制启用（v1.3.70 起走路线 A）
            tried = 1;
            // v1.3.70【路线 A】：native 模式优先【引擎直调】（永久复用组，不反复分配句柄）；
            //   失败才回落到旧的 ydbase 建组枚举。pick=3 = 联机下"强制启用直调"的实验档。
            u = GetSelectedUnitHandleNative(0);
            if (u) {
                how = (g_cfg.pick == 3) ? "native-reuse" : "native";
            } else {
                u = GetSelectedUnitHandle();
                how = (g_cfg.pick == 3) ? "native-failed-group-reuse" : "native-failed-group";
            }
        } else {                                      // auto(0) / memory(4)：先试纯内存〔?〕
            int mh = 0;
            // v1.3.71：这里【不再】预先做一次内存读 —— 它在本机会抛 C0000005（日志：
            //   "选区(内存)：玩家对象=..." 紧接 "E 选区(内存)：异常 code=C0000005"），
            //   一次异常就把整次取选区中断，导致写在它后面的引擎直调永远跑不到。
            //   内存读降到各分支里按需调用。
            uint32_t mu = 0;

                // v1.3.82【关键修复】这里必须【无条件】调用纯内存读。
                //   之前它只写在【单机子分支】里，human=2 时根本不进去，
                //   于是 mu 恒为 0 -> 所有门禁都失败 -> 热键毫无反应。
                //   这条链就是照 War3Trainer 写的：sel+0x1F0 起步、沿 node+0 正向。
                {
                    int mh0 = 0;
                    mu = GetSelectedUnitHandleByMemory(&mh0, 0);
                    LogLine("[v1.3.82] 选区：内存读=%08X（single=%d human=%d native=%d pick=%d）",
                            mu, (int)(g_cfg.pick == 0 && humans <= 1), humans,
                            (int)g_nativeMode, g_cfg.pick);
                }
            // ================================================================
            // v1.3.71【决策顺序修正】—— 这就是"选不中单位"的真正修复：
            //   先问引擎（它自己遍历选区，不碰那条易碎的 sel 链表），
            //   失败才回落纯内存读 / 旧建组枚举。
            // 联机安全不变：human>1 时 auto 档不做直调，仍只读内存。
            // ================================================================
            if (g_cfg.pick == 0 && humans <= 1) {
                uint32_t nu = 0;
                // v1.3.77 section 6: CreateGroup allocates a local handle ID (the documented
                //   desync cause), so the engine path is opt-in only: pick=1/3.
                if (g_nativeMode && (g_cfg.pick == 1 || g_cfg.pick == 3)) {
                    u = GetSelectedUnitHandleNative(0);
                    if (u) { tried = 1; how = "native(forced)"; }
                } else {
                    LogLine("[v1.3.71] native=0 -> 跳过引擎直调（本局不是 native 后端）");
                }
                if (nu) {
                    u = nu; tried = 1; how = "native";
                } else {
                    // 兜底：纯内存读；JAPI 后端才有意义的旧枚举也试一次
                    int mh2 = 0;
                    uint32_t mu2 = GetSelectedUnitHandleByMemory(&mh2, 0);
                    uint32_t gu = GetSelectedUnitHandle();
                    if (gu) {
                        GetSelectedUnitHandleByMemory(&mh2, gu);   // 只为了打 ★定位 行
                        LogLine("选区交叉校验：内存读=%08X 枚举=%08X", mu2, gu);
                        u = gu; tried = 1; how = "group";
                    } else {
                        u = mu2; tried = 1; how = "memory(group-failed)";
                    }
                }
            } else if (mu || (g_nativeMode && g_cfg.pick != 4)) {
                // v1.3.79：这里也必须门禁——v1.3.77 只改了上一支，联机时从这里又建了一个组。
                uint32_t nu = (g_cfg.pick == 1 || g_cfg.pick == 3) ? GetSelectedUnitHandleNative(0) : 0;
                u = nu ? nu : mu;
                if (u) { tried = 1; how = nu ? "native" : "memory"; }
            } else if (g_cfg.pick == 4) { tried = 1; how = "memory-failed"; }
            else if (PickAllowed(humans)) {
                tried = 1;
                u = GetSelectedUnitHandle();
                how = "group-fallback";
            } else {
                how = "skipped-multiplayer";
            }
        }
        LogLine("[v1.3.77] 热键：选区取得 路径=%s 句柄=%08X（pick=%d human=%d native=%d）",
                how, u, g_cfg.pick, humans, (int)g_nativeMode);

        // 文本编码/标签可能还没初始化（进图后没挨过打就〔?〕R）：
        // 不先做这一步，我们自己写的中文会按默认 GBK 发出〔?〕〔?〕消息区显示乱码〔?〕
        // 把刚取到的单位句柄传进去，判定时就有真实单位名可用（比只靠玩家名更稳）〔?〕
        EnsureTextReady(u, 0);

        if (!tried) {
            // 联机且内存读不可用：绝不碰选区（实测会导致平台〔?〕不同〔?〕异常"
            // 注意：这里【每次都发】提〔?〕—〔?〕玩家需〔?〕按了就有反应"的确认感〔?〕
            //       所以不做节流（日志同样每次按键都写）〔?〕
            char msg[512] = { 0 };
            AppUtf8(msg, sizeof(msg), g_cfg.labels
                     ? "|cffffcc00[伤害]|r 联机时不使用选区记录（会导致不同步）："
                       "请用聊天命令 |cffffcc00@名字|r 或 |cffffcc00@类型码|r（如 @魔狼人 / @uske）来记录单位"
                     : "|cffffcc00[DMG]|r selection pick disabled in multiplayer (causes desync): "
                       "use chat |cffffcc00@name|r or |cffffcc00@typecode|r instead");
            ShowMessage(msg);
            return;
        }
        if (!u) {
            char msg[256] = { 0 };
            AppUtf8(msg, sizeof(msg), g_cfg.labels
                     ? "|cffffcc00[伤害]|r 没有选中单位：请先用鼠标选中一个单位，再按 Ctrl+Alt+R"
                     : "|cffffcc00[DMG]|r no unit selected: select a unit first, then Ctrl+Alt+R");
            ShowMessage(msg);
            return;
        }
        _snprintf_s(cmd, sizeof(cmd), _TRUNCATE, "%s#%08X", g_cfg.chat_prefix, u);
        DoHotkeyAsCommand(cmd);          // @#句柄 —〔?〕精确记录这一个实〔?〕
        return;
    }
    default:
        return;
    }
}

//------------------------------------------------------------------------------
// v1.4.1【直投聊天框发消息】—— 照 WFE build_tools\hello_direct.c 的做法移植
//
// 思路和"调发送函数"完全不同：**不调用任何发送/投递函数**，而是
//   ① 找到聊天 UI 对象，把【收件人】设好（全部 / 盟友）
//   ② 用 SendMessageA(hwnd, WM_CHAR, 字符, 0) 把字直接投进聊天框
//   ③ 调游戏【自己的窗口过程】发一次回车 -> 游戏自己走完整条发送链路
//
// 为什么这条路比我之前试的好：
//   * 一次 SendInput 都不用 —— 不需要游戏在前台、不抢键盘、不进全局输入队列
//   * 不碰任何"未验证的函数"：下面 5 个地址全部离线核对过序言（都是 55 8B EC）
//   * 收件人可控：set_recipient 的 selector 就是"发给谁"
//
// 全部偏移为 Game.dll 的裸 RVA（不是"文件偏移−0xC00"那种约定，别搞混）：
//   0x34F3A0  get_unit(idx,0)        -> __fastcall(0,0) 返回对象，[obj+0x3FC] = 聊天UI对象
//   0x392060  clear_chat(obj, idx)   __thiscall
//   0x3B2DE0  set_recipient(obj,sel) __thiscall，selector: 0=全部 1=盟友 2=观察者
//   0x14D670  get_game_wnd(idx)      __fastcall(0,0) -> HWND
//   0x153710  游戏窗口过程(hwnd,msg,wp,lp) __fastcall —— 用它发回车
//
// 收件人 selector 的字符串常量（0x98FE28 起）已逐个核对：
//   0 SINGLEPLAYER / ALL / ALLIES / REFEREES / OBSERVERS
//   注意：汇编里 0 → COLON_MESSAGE_ALL，1 → COLON_MESSAGE_ALLIES，且"盟友"在某些状态下会被强制升级成"全部"。
//
// ⚠ 必须跑在游戏主线程（hello_direct.c 的 v3 在后台线程调这些函数直接崩，
//   它是用 SetTimer 落到游戏消息循环解决的）。本插件已经有游戏线程入口：
//   WM_UDW_HOTKEY -> OnHotkeyGameThread，所以不需要再装定时器。
//------------------------------------------------------------------------------
#define WC3_RVA_CHAT_GET_UNIT   0x34F3A0u
#define WC3_RVA_CHAT_CLEARCHAT  0x392060u
#define WC3_RVA_CHAT_SETRECIP   0x3B2DE0u
#define WC3_RVA_CHAT_GAMEWND    0x14D670u
#define WC3_RVA_CHAT_GAMEPROC   0x153710u
#define WC3_RVA_CHAT_SETTEXT    0x3B3B80u   // v1.4.21：游戏 SetText（hello_direct v5）
#define WC3_OFF_UI_FROM_OBJ     0x3FCu     // [obj+0x3FC] = 聊天 UI 对象

typedef uint32_t (__fastcall *fn_chat_getunit_t)(uint32_t, uint32_t);
typedef void     (__fastcall *fn_chat_thiscall1_t)(void* self, void* edx_dummy, uint32_t a);
typedef uint32_t (__fastcall *fn_chat_getwnd_t)(uint32_t, uint32_t);
typedef intptr_t (__fastcall *fn_chat_wndproc_t)(void* hwnd, uint32_t msg, uintptr_t wp, intptr_t lp);
typedef void     (__fastcall *fn_chat_settext_t)(void* self, void* edx_dummy, const char* utf8);

static fn_chat_getunit_t   g_chatGetUnit   = NULL;
static fn_chat_thiscall1_t g_chatClearChat = NULL;
static fn_chat_thiscall1_t g_chatSetRecip  = NULL;
static fn_chat_getwnd_t    g_chatGetWnd    = NULL;
static fn_chat_wndproc_t   g_chatWndProc   = NULL;
static fn_chat_settext_t   g_chatSetText   = NULL;

static void InitDirectChat()
{
    const uint32_t base = Wc3GameBase();
    if (!base) { LogLine("直投聊天：拿不到 Game.dll 基址，本次不可用"); return; }

    // 逐个校验入口。注意：入口完全可能是【别人（WFE 等）已经挂钩的 E9 跳转】——
    //   实机日志证据：game+0x153710 的序言是 `E9 8B 47 ...`，而 WFE 自带的
    //   hello_direct.dll 照样能正常调它（日志里每 5 秒一条 "hello" 走完全程）。
    //   原因是 CPU 自己会跟着 E9 跳过去，所以 E9 入口是【合法】的。
    //   v1.4.1 第一版只认 55 8B EC，把这种情况误判成"版本不匹配"，导致功能没启用。
    //   现在：E9 且跳转目标可执行 -> 判为有效；并且【仍然调用入口本身】，不跟随跳转，
    //   这样万一那个钩子还要处理 WM_CHAR 之类，也不会被我们绕过去。
    struct { uint32_t rva; const char* name; } want[6] = {
        { WC3_RVA_CHAT_GET_UNIT,  "get_unit"      },
        { WC3_RVA_CHAT_CLEARCHAT, "clear_chat"    },
        { WC3_RVA_CHAT_SETRECIP,  "set_recipient" },
        { WC3_RVA_CHAT_SETTEXT,   "set_text"      },
        { WC3_RVA_CHAT_GAMEWND,   "get_game_wnd"  },
        { WC3_RVA_CHAT_GAMEPROC,  "game_wndproc"  },
    };
    char bad[160] = { 0 };
    for (int i = 0; i < 6; ++i) {
        const uint32_t fn = base + want[i].rva;
        uint8_t b[6] = { 0 };
        __try { for (int k = 0; k < 6; ++k) b[k] = *(const uint8_t*)(uintptr_t)(fn + k); }
        __except (EXCEPTION_EXECUTE_HANDLER) { b[0] = 0; }

        const int normal = (b[0] == 0x55 && b[1] == 0x8B && b[2] == 0xEC) ||
                           (b[0] == 0x83 && b[1] == 0xE9) ||     // get_game_wnd: sub ecx,0
                           (b[0] == 0x6A && b[1] == 0xFF);       // push -1; push seh
        int ok = normal;
        if (!ok && b[0] == 0xE9) {
            // 被别人挂钩的近跳转：校验目标可执行即算通过
            const uint32_t tgt = fn + 5 + *(const int32_t*)(uintptr_t)(fn + 1);
            __try {
                MEMORY_BASIC_INFORMATION mbi;
                if (VirtualQuery((LPCVOID)(uintptr_t)tgt, &mbi, sizeof(mbi)) &&
                    mbi.State == MEM_COMMIT &&
                    (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                                    PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)))
                    ok = 1;
            } __except (EXCEPTION_EXECUTE_HANDLER) { ok = 0; }
            if (ok) LogLine("直投聊天：%s 入口 %08X 是 E9 跳转（别人挂钩了）-> 目标 %08X，判为有效",
                            want[i].name, fn, tgt);
        }
        if (!ok) {
            _snprintf_s(bad, sizeof(bad), _TRUNCATE, "%s(Game.dll+0x%X 序言 %02X %02X %02X 不符)",
                        want[i].name, want[i].rva, b[0], b[1], b[2]);
            LogLine("直投聊天：Game.dll 版本可能不匹配 -> %s，本次不启用", bad);
            return;
        }
    }

    g_chatGetUnit   = (fn_chat_getunit_t)  (uintptr_t)(base + WC3_RVA_CHAT_GET_UNIT);
    g_chatClearChat = (fn_chat_thiscall1_t)(uintptr_t)(base + WC3_RVA_CHAT_CLEARCHAT);
    g_chatSetRecip  = (fn_chat_thiscall1_t)(uintptr_t)(base + WC3_RVA_CHAT_SETRECIP);
    g_chatSetText   = (fn_chat_settext_t)  (uintptr_t)(base + WC3_RVA_CHAT_SETTEXT);
    g_chatGetWnd    = (fn_chat_getwnd_t)   (uintptr_t)(base + WC3_RVA_CHAT_GAMEWND);
    g_chatWndProc   = (fn_chat_wndproc_t)  (uintptr_t)(base + WC3_RVA_CHAT_GAMEPROC);
    LogLine("直投聊天：6 个地址序言校验全部通过，已启用（Game.dll 基址 %08X）", base);
}

// 取聊天 UI 对象：get_unit(0,0) -> [obj+0x3FC]
static uint32_t DirectChatUiObject()
{
    if (!g_chatGetUnit) return 0;
    uint32_t obj = 0, ui = 0;
    __try {
        obj = ((fn_chat_getunit_t)g_chatGetUnit)(0, 0);
        if (obj) ui = *(const uint32_t*)(uintptr_t)(obj + WC3_OFF_UI_FROM_OBJ);
    } __except (EXCEPTION_EXECUTE_HANDLER) { obj = 0; ui = 0; }
    if (g_cfg.debug) LogLine("直投聊天：get_unit(0,0)=%08X -> UI 对象=%08X", obj, ui);
    return ui;
}

// selector: 收件人。0=全部 1=盟友 2=观察者（字符串常量已核对，见 §7.5）
//
// v1.4.11：恢复 hello_direct.c 原样的调用序列。它调了两次 clear_chat 再 set_recipient，
//   这是那份已验证能工作的代码的顺序 —— 不管 clear_chat 语义看起来是什么，忠实照抄。
static int DirectChatPrepare(uint32_t ui, uint32_t selector)
{
    if (!ui || !g_chatClearChat || !g_chatSetRecip) return 0;
    int ok = 0;
    __try {
        ((fn_chat_thiscall1_t)g_chatClearChat)((void*)(uintptr_t)ui, NULL, 0);
        ((fn_chat_thiscall1_t)g_chatClearChat)((void*)(uintptr_t)ui, NULL, 1);
        ((fn_chat_thiscall1_t)g_chatSetRecip) ((void*)(uintptr_t)ui, NULL, selector);
        ok = 1;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 直投聊天：clear_chat/set_recipient 异常 code=%08X", (uint32_t)GetExceptionCode());
        ok = 0;
    }
    return ok;
}






//------------------------------------------------------------------------------
// 【历史记录】v1.4.0 删掉的两条路（与上面的 v1.4.1 直投法无关，别混淆）
//
// 这里原来有两条"让插件自己把结算发进聊天"的路，都已按用户要求整体删除：
//
//   ① 剪贴板 + 合成按键（回车 -> Ctrl+V -> 回车）
//      实测可用，但要抢键盘（必须游戏在前台），联机时被平台当异常输入。
//
//   ② 进程内直调游戏自己的发送函数 game+0x241EA0（和玩家手打回车同一个函数）
//     逆向做到底了：调用约定 __thiscall(this=本地玩家对象, 文本=裸 UTF-8 char*)、
//     this = *(ctx+0x58+localPlayerIdx*4)、只被提交路径 game+0x3518B3 调用。
//     实机钩住它对比过：真实手打消息与我们的注入【this 和虚表完全一致】
//     （1B112BFC / Game.dll+0x9716F4），函数也正常返回不抛异常。
//     但是：调用之后游戏必卡（v1.3.94~97 反复复现，拆掉观测钩子后依旧），
//     说明在游戏线程上直接调它这件事本身不安全，原因未查明。
//
// 结论：这条路放弃了，代码不再保留在构建里（要找回看 git 历史 v1.3.99）。
// 想看结算内容请用：屏幕显示，或死亡结算【无框直投】到聊天（chat_on_death=1）。
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// 7.8 把热键动作送回游戏线程
//   热键线程只做一件事：PostMessage(WM_UDW_HOTKEY, 键)
//   游戏线程的消息循环派发到下面这个 WndProc，再执行动作〔?〕
//   好处：① JASS 调用（选区枚举 / DisplayTimedTextToPlayer）一定有效；
//         〔?〕以后要吞掉聊天的 "@" 命令（不发出去），也已经站在同一层上〔?〕
//------------------------------------------------------------------------------
#define WM_UDW_HOTKEY (WM_APP + 0x51)

static WNDPROC g_prevWndProc = NULL;
static HWND    g_gameWnd     = NULL;

// 游戏线程的线程号：第一次伤害事件（引擎代码里）记下来，用来核对热键到底跑在哪个线程
// （变量本身声明在 4.1 〔?〕—〔?〕native 的字符串表自检/take 要用 g_gameThreadId，那里离得近〔?〕

static HWND DirectChatGameWindow()
{
    // v1.4.12【关键修正】优先用 pGetGameWnd(0,0) —— 这是 hello_direct.c 真正用的函数。
    //   之前两版把死亡结算这条路改成了"FindWindowA 优先"，与 hello_direct.c 不一致。
    //   hello_direct.c 的 SendHelloToAllies 就是：
    //       hwnd = pGetGameWnd(0, 0);   if (!hwnd) hwnd = FindWindowA("Warcraft III", NULL);
    //   照抄，不再自作主张换顺序。
    HWND h = NULL;
    if (g_chatGetWnd) {
        __try { h = (HWND)(uintptr_t)((fn_chat_getwnd_t)g_chatGetWnd)(0, 0); }
        __except (EXCEPTION_EXECUTE_HANDLER) { h = NULL; }
    }
    if (!h) { __try { h = FindWindowA("Warcraft III", NULL); }
              __except (EXCEPTION_EXECUTE_HANDLER) { h = NULL; } }
    if (!h) { __try { h = FindWindowA(NULL, "Warcraft III"); }
              __except (EXCEPTION_EXECUTE_HANDLER) { h = NULL; } }

    // 最后才退回热键那套枚举窗口
    if (!h) { EnsureHotkeyWindow(); h = g_gameWnd; }
    return h;
}

//------------------------------------------------------------------------------
// v1.4.8：真正在【游戏线程】上执行的那一次投递。
//   只做"投字 + 回车"这类纯消息投递，**一个 Sleep 都没有** —— 卡帧的根源就是等待，
//   等待全部留在 ChatSendWorker 里。
//   调用链：工作线程 PostMessage(WM_UDW_CHAT) -> 游戏消息循环 -> UdwWndProc -> 这里
//------------------------------------------------------------------------------
static void DirectChatDeliverOnGameThread()
{
    __try {
        const DWORD tid = GetCurrentThreadId();
        LogLine("直投聊天[游戏线程 tid=%u]：开始投递，文本 %d 字节", (unsigned)tid, (int)strlen(g_sendQ));
        __try {
            const uint32_t ui = DirectChatUiObject();
            const void*    hwnd = DirectChatGameWindow();
            LogLine("直投聊天[游戏线程]：UI=%08X 窗口=%p 收件人=%u",
                    ui, hwnd, g_cfg.chat_send_target);
            if (!ui || !hwnd) {
                LogLine("直投聊天[游戏线程]：拿不到 UI 对象或窗口，本次不发");
                return;
            }
            if (!DirectChatPrepare(ui, g_cfg.chat_send_target)) {
                LogLine("直投聊天[游戏线程]：set_recipient 没成功，本次不发");
                return;
            }

            // v1.4.21：照 hello_direct.c v5，直接调游戏 SetText(0x3B3B80) 把 UTF-8
            //   文本逐字节 memcpy 进输入框缓冲区，不做编码转换 —— 中文能正确进框。
            if (!g_chatSetText) {
                LogLine("直投聊天[游戏线程]：SetText 未就绪，本次不发");
                return;
            }
            ((fn_chat_settext_t)g_chatSetText)((void*)ui, NULL, g_sendQ);
            LogLine("直投聊天[游戏线程]：SetText 已写入 %d 字节（UTF-8），现在发回车", (int)strlen(g_sendQ));

            ((fn_chat_wndproc_t)g_chatWndProc)((void*)hwnd, WM_KEYDOWN, VK_RETURN, 0);
            ((fn_chat_wndproc_t)g_chatWndProc)((void*)hwnd, WM_KEYUP,   VK_RETURN, 0);
            LogLine("直投聊天[游戏线程]：回车已发，投递结束");
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            LogLine("E 直投聊天[游戏线程]：投递异常 code=%08X", (uint32_t)GetExceptionCode());
        }
    } __finally {
        InterlockedExchange(&g_directChatBusy, 0);   // v1.4.16：投递完成即释放，不检查上屏结果
    }
}

static LRESULT CALLBACK UdwWndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
    if (msg == WM_UDW_CHAT) {          // v1.4.8：无框直投的投递动作，跑在游戏线程
        DirectChatDeliverOnGameThread();
        return 0;
    }
    if (msg == WM_UDW_HOTKEY) {
        const DWORD tid = GetCurrentThreadId();
        if (g_gameThreadId && (LONG)tid != g_gameThreadId) {
            static volatile LONG warned = 0;
            if (InterlockedExchange(&warned, 1) == 0) {
                LogLine("W 热键：处理线程 %u 与游戏线程 %d 不同，JASS 调用可能无效",
                        (unsigned)tid, (int)g_gameThreadId);
            }
        }
        __try {
            OnHotkeyGameThread((int)wp);
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            LogLine("E 热键处理异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
        }
        return 0;
    }
    // v1.4.22：吞掉 Ctrl+Alt+热键的按下事件，阻止游戏/平台响应同一组合键。
    //   插件自己走 GetAsyncKeyState 轮询（HotkeyThreadProc），不依赖这条消息，
    //   所以吞掉不影响插件动作；只吞 DOWN，UP 照传（游戏不靠 UP 触发）。
    if (msg == WM_SYSKEYDOWN || msg == WM_KEYDOWN) {
        const uint32_t vk = (uint32_t)wp;
        const int isHotkey = (vk >= '0' && vk <= '9') ||
                             vk == 'R' || vk == 'Q' || vk == 'S' || vk == 'D';
        if (isHotkey) {
            const bool ctrl = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
            const bool alt  = (GetKeyState(VK_MENU)    & 0x8000) != 0;
            if (ctrl && alt) return 0;   // 吞掉，不转发给游戏
        }
    }

    if (g_prevWndProc) return CallWindowProcW(g_prevWndProc, hwnd, msg, wp, lp);
    return DefWindowProcW(hwnd, msg, wp, lp);
}

static BOOL CALLBACK EnumGameWndProc(HWND hwnd, LPARAM lp)
{
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid != GetCurrentProcessId() || !IsWindowVisible(hwnd)) return TRUE;
    RECT r = { 0, 0, 0, 0 };
    if (!GetWindowRect(hwnd, &r)) return TRUE;
    long area = (long)(r.right - r.left) * (long)(r.bottom - r.top);
    if (area > *(long*)lp) {                 // 取面积最大的那个可见窗口 = 游戏窗口
        *(long*)lp = area;
        g_gameWnd = hwnd;
    }
    return TRUE;
}

static void InitHotkeyWindow()
{
    if (g_gameWnd && IsWindow(g_gameWnd)) return;
    g_gameWnd = NULL;                        // 旧句柄失效（换过分辨〔?〕全屏切换）就重找
    long best = 0;
    EnumWindows(EnumGameWndProc, (LPARAM)&best);
    if (!g_gameWnd) {
        LogLine("热键：没找到游戏窗口，动作将退化为在热键线程里直接执行（消息可能不显示）");
        return;
    }
    g_prevWndProc = (WNDPROC)SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)UdwWndProc);
    LogLine("热键：已挂到游戏窗口 %08X，动作将在游戏线程执行", (uint32_t)(uintptr_t)g_gameWnd);
}

// 热键线程把动作丢回游戏线程；窗口还没找到时退化成本线程直接执〔?〕
static void EnsureHotkeyWindow()
{
    InitHotkeyWindow();
    if (g_gameWnd && GetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC) != (LONG_PTR)UdwWndProc) {
        // 游戏自己又把窗口过程改回去了（切分辨〔?〕全屏/重开窗口时会发生）——重新挂〔?〕
        g_prevWndProc = (WNDPROC)SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)UdwWndProc);
        LogLine("热键：窗口过程被改回，已重新挂上（窗口 %08X）", (uint32_t)(uintptr_t)g_gameWnd);
    }
}

static void DispatchHotkey(int key)
{
    EnsureHotkeyWindow();
    if (g_gameWnd && PostMessageW(g_gameWnd, WM_UDW_HOTKEY, (WPARAM)key, 0)) return;
    LogLine("热键：投递失败，改为本线程直接执行（key=%c）", (char)key);
    __try {
        OnHotkeyGameThread(key);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 热键处理异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
    }
}

static DWORD WINAPI HotkeyThreadProc(LPVOID)
{
    int last = 0;
    for (;;) {
        Sleep(50);
        if (InterlockedCompareExchange(&g_hotkeyStop, 1, 1) == 1) break;

        // 只在游戏窗口处于前台时响应（否则挂机时按到键也会触发〔?〕
        HWND fg = GetForegroundWindow();
        DWORD pid = 0;
        if (fg) GetWindowThreadProcessId(fg, &pid);
        if (!fg || pid != GetCurrentProcessId()) { last = 0; continue; }

        const bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
        const bool alt  = (GetAsyncKeyState(VK_MENU)    & 0x8000) != 0;

        int key = 0;
        if (ctrl && alt) {
            for (int vk = '0'; vk <= '9'; ++vk) if (GetAsyncKeyState(vk) & 0x8000) { key = vk; break; }
            if (!key && (GetAsyncKeyState('R') & 0x8000)) key = 'R';
            if (!key && (GetAsyncKeyState('Q') & 0x8000)) key = 'Q';
            if (!key && (GetAsyncKeyState('S') & 0x8000)) key = 'S';
            if (!key && (GetAsyncKeyState('D') & 0x8000)) key = 'D';   // v1.3.84：调试日志开关
        }
        if (key != last) {                 // 边沿触发：只〔?〕刚按〔?〕时动作一〔?〕
            last = key;
            if (key) DispatchHotkey(key);
        }
    }
    return 0;
}

static void InitHotkeys()
{
    if (!g_cfg.hotkeys) { LogLine("热键：已按 ini 关闭（hotkeys=0）"); return; }
    InitHotkeyWindow();
    InterlockedExchange(&g_hotkeyStop, 0);
    HANDLE h = CreateThread(NULL, 0, HotkeyThreadProc, NULL, 0, NULL);
    if (h) CloseHandle(h);
    LogLine("热键：已启用（Ctrl+Alt+0/1/2/3 切显示模式，R 记录选中单位，Q 看统计，S 结算，D 调试日志），"
            "pick=%d（0=auto 单人可用/联机跳过），线程=%u",
            g_cfg.pick, (unsigned)GetCurrentThreadId());
}

//------------------------------------------------------------------------------
// 8. 主钩子实〔?〕
//    参数〔?〕EventDamageData.cpp 〔?〕FakeUnitDamageFunc 一一对应〔?〕
//    用普〔?〕__fastcall，编译器自会生成 ret 10h（见上面的说明）〔?〕
//------------------------------------------------------------------------------
static uint32_t __fastcall OurDamageFunc(uint32_t _this, uint32_t _edx, uint32_t a2,
                                         war3_event_damage_data* ptr,
                                         uint32_t is_physical, uint32_t source_unit)
{
    // ---- 〔?〕先调 JAPI 〔?〕FakeUnitDamageFunc，并把返回值原样带回去 ----
    // 这一步必须最先执行，保证"引擎的伤害函数一定被跑到"这个不变量：
    // 之后无论快照/日志/显示出什么问题（都会〔?〕__try 吞掉），伤害本身不受影响〔?〕
    if (!g_gameThreadId) g_gameThreadId = (LONG)GetCurrentThreadId();   // 这就是游戏线〔?〕
    ++g_seenEvents;                    // v1.3.13：全局事件计数（结算日志用它当"分母"
    uint32_t retval = 0;
    if (ORIG_DAMAGE) {
        __try {
            retval = ORIG_DAMAGE(_this, _edx, a2, ptr, is_physical, source_unit);
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            LogLine("E 原伤害函数抛出异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
            retval = 0;
        }
    }

    // ---- 〔?〕抄快照（只做内存〔?〕+ 两个小小〔?〕JASS 调用，全部包 __try〔?〕----
    DamageSnapshot snap;
    memset(&snap, 0, sizeof(snap));
    snap.raw_this       = _this;
    snap.raw_edx        = _edx;
    snap.raw_a2         = a2;
    snap.raw_ptr        = (uint32_t)(uintptr_t)ptr;
    snap.raw_isPhysical = is_physical;
    snap.raw_sourceUnit = source_unit;

    __try {
        if (ptr && Readable(ptr, sizeof(war3_event_damage_data))) {
            snap.ptrOK       = 1;
            snap.source_unit = ptr->source_unit;
            snap.weapon_type = ptr->weapon_type;
            snap.unk2        = ptr->unk2;
            snap.flag        = ptr->flag;
            snap.amount_real = ptr->amount;
            snap.damage_type = ptr->damage_type;
            snap.unk6        = ptr->unk6;
            snap.unk7        = ptr->unk7;
            snap.attack_type = ptr->attack_type;
        }
        snap.target_handle = ObjToHandle(_this);
        // 伤害来源：实测（2026-09-27 日志）记〔?〕+0x00 是【单位对象指针】（形如 1E4C4994），
        // 不是 JASS 句柄（目标句柄形〔?〕00100683）；所以必须再 object_to_handle 转一次〔?〕
        // 栈参〔?〕source_unit 在这个构建里恒为 0，只作为兜底〔?〕
        snap.source_obj = source_unit ? source_unit : snap.source_unit;
        if (snap.source_obj) {
            uint32_t h = ObjToHandle(snap.source_obj);
            snap.source_handle = h ? h : snap.source_obj;   // 转换失败才退回原〔?〕
        }
        // 伤害值：JAPI 模式〔?〕ydbase 〔?〕from_real；native 模式没有 ydbase〔?〕
        // 〔?〕JASS real = 指向 float 的句〔?〕自己解引用（解不出来就是 0，绝不猜〔?〕
        // 伤害值：
        //   native 模式：结构体里的 amount 是【float 的位模式】（〔?〕Wc3RealBits 的说明）—〔?〕
        //                以前当指针解引用，所以永远是 0.0〔?〕
        //   JAPI  模式：ydbase 〔?〕from_real 是恒等函数，等价于直接按位读〔?〕
        if (g_nativeMode) snap.amount = snap.ptrOK ? Wc3RealBits(snap.amount_real) : 0.0f;
        else              snap.amount = (snap.ptrOK && g_from_real) ? g_from_real(snap.amount_real) : 0.0f;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        snap.ptrOK = 0;
    }

    // ---- 〔?〕日志 + 显示（用快照，出什么问题都不影〔?〕retval〔?〕----
    __try {
        // 第一次拿到伤害事件时做一次初始化（编码判〔?〕+ 标签准备）；
        // 聊天命令路径也会调它，所以两边共用同一个开关〔?〕
        EnsureTextReady(snap.target_handle, snap.source_handle);

        const int mode = (int)g_mode;      // 0=来源自己 1=来源自己/友方 2=来源敌人 3=关闭

        // 开局默认静默（mode=3）：不显示明细、不显示统计，等玩家自己发命令开启〔?〕
        // start_hint=1 时，〔?〕进游戏后第一次挨〔?〕这一刻提示一行怎么开启（默认关）〔?〕
        static volatile LONG s_hintDone = 0;
        if (g_cfg.start_hint && mode == 3 && InterlockedExchange(&s_hintDone, 1) == 0) {
            char l[512] = { 0 };
            AppUtf8(l, sizeof(l), g_cfg.labels
                ? "|cff00ffff[统计]|r 已就绪（默认不显示）。热键 Ctrl+Alt+0 自己 / 1 自己友军 / 2 敌人 / 3 关闭"
                : "|cff00ffff[STATS]|r ready (off). hotkeys Ctrl+Alt+0 self / 1 self+ally / 2 enemy / 3 off");
            ShowMessage(l);
        }

        // 逐条伤害日志（用户要求，v1.3.11 改回）：**只在明细开启时〔?〕*〔?〕
        //   mode != 3（明细打开〔?〕> 逐条〔?〕H 行（debug=1 时另〔?〕D/DN 原始行）〔?〕
        //   mode == 3（开局默认，关闭）-> 一行都不写，日志安静（统计/死亡结算仍照旧记录）〔?〕
        //   log_events=1 〔?〕log_only=1 可以强制逐条记录（纯排错用）〔?〕
        const int wantEventLog = (mode != 3) || g_cfg.log_events || g_cfg.log_only;
        if (wantEventLog) {
            if (snap.ptrOK) {
                LogDebug("D this=%08X edx=%08X a2=%08X ptr=%08X phys=%u srcArg=%08X"
                        " | src=%08X wep=%u unk2=%08X flag=%08X amt=%08X dmgType=%08X"
                        " unk6=%08X unk7=%08X atkType=%08X"
                        " | atk=%u rng=%u amtF=%.2f tgtH=%08X srcH=%08X",
                        snap.raw_this, snap.raw_edx, snap.raw_a2, snap.raw_ptr,
                        snap.raw_isPhysical, snap.raw_sourceUnit,
                        snap.source_unit, snap.weapon_type, snap.unk2, snap.flag,
                        snap.amount_real, snap.damage_type, snap.unk6, snap.unk7,
                        snap.attack_type,
                        (snap.flag >> 8) & 1u, snap.flag & 1u, snap.amount,
                        snap.target_handle, snap.source_handle);
            } else {
                LogDebug("D this=%08X edx=%08X a2=%08X ptr=%08X phys=%u srcArg=%08X"
                        " | ptr 不可读，跳过解析",
                        snap.raw_this, snap.raw_edx, snap.raw_a2, snap.raw_ptr,
                        snap.raw_isPhysical, snap.raw_sourceUnit);
            }
            // native 专属：引擎直连时 [ebp+0x8] = 伤害类型位掩码、[ebp+0xC] = 伤害信息结构〔?〕
            // 〔?〕JAPI 转发时的语义不完全一致。这里把结构〔?〕8 〔?〕dword 原样打出来，
            // 便于下一阶段（屏幕显示）把字段语义钉〔?〕—〔?〕不改上面 D 行的既有格式与字段〔?〕
            if (g_nativeMode) {
                if (snap.ptrOK) {
                    uint32_t d[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
                    for (int i = 0; i < 8; ++i) Wc3Peek(snap.raw_ptr + (uint32_t)i * 4u, &d[i], 4);
                    LogDebug("DN native=1 tgtObj=%08X tgtH=%08X srcH=%08X amtF=%.2f"
                            " | info[0..7]=%08X %08X %08X %08X %08X %08X %08X %08X",
                            snap.raw_this, snap.target_handle, snap.source_handle, snap.amount,
                            d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7]);
                } else {
                    LogDebug("DN native=1 this=%08X ptr=%08X ptr 不可读，跳过解析",
                            snap.raw_this, snap.raw_ptr);
                }
            }
            // ★★ v1.3.1：屏幕上的明细精简〔?〕只有数字"了，所以【日志必须保留完整信息】〔?〕
            //    这一行把"人看得懂"的字段补齐：来源〔?〕/ 目标〔?〕/ 拥有〔?〕/ 五项数字 / 伤害 / 武器 / 生命〔?〕
            //    再配合上面的 D 行（原始字段）与 DN 行（native 结构〔?〕8 〔?〕dword）与句柄〔?〕
            //    事后只翻日志就能完整复核每一笔伤〔?〕—〔?〕不依赖屏幕上有没有显示〔?〕
            //    它在 wantEventLog 里：native 下【无条件】写；JAPI 下跟随明细开关（〔?〕log_events=1）〔?〕
            if (snap.ptrOK) {
                char sName[128] = { 0 }, tName[128] = { 0 };
                GetUnitLabelClean(snap.source_handle, sName, sizeof(sName));
                GetUnitLabelClean(snap.target_handle, tName, sizeof(tName));

                const float hpCur = GetUnitStateSafe(snap.target_handle, JASS_UNIT_STATE_LIFE);
                const float hpMax = GetUnitStateSafe(snap.target_handle, JASS_UNIT_STATE_MAXLIFE);

                // 拥有者（两种后端都能取：native 走引擎直调，JAPI 〔?〕g_call〔?〕
                uint32_t ownerH = 0;
                if (g_nativeMode) {
                    ownerH = Wc3GetOwningPlayer(snap.target_handle);
                } else if (g_call) {
                    __try { ownerH = (uint32_t)g_call("GetOwningPlayer", snap.target_handle); }
                    __except (EXCEPTION_EXECUTE_HANDLER) { ownerH = 0; }
                }
                const char* ownerName = ownerH ? PlayerNameText(ownerH) : NULL;

                LogLine("H 来源:%s(%08X) 目标:%s(%08X) 拥有者:%s 攻击:%u 远程:%u 攻击类型:%u 伤害类型:%u"
                        " 伤害:%.1f 武器:%u 生命:%.1f/%.1f",
                        sName, snap.source_handle, tName, snap.target_handle,
                        (ownerName && ownerName[0]) ? ownerName : "?",
                        (snap.flag >> 8) & 1u, snap.flag & 1u, snap.attack_type,
                        MaskToIndex3(snap.damage_type), snap.amount, snap.weapon_type,
                        hpCur, hpMax);
            }
        }

        // ---- 屏幕明细（只显示数字〔?〕---
        if (g_cfg.enable && !g_cfg.log_only && snap.ptrOK && mode != 3) {
            const uint32_t atk = (snap.flag >> 8) & 1u;
            const uint32_t rng = snap.flag & 1u;
            const uint32_t dmgTypeNo = MaskToIndex3(snap.damage_type);

            int skip = 0;
            if (g_cfg.filter_zero && !(snap.amount > 0.0f)) skip = 1;
            if (!skip && snap.amount < g_cfg.min_amount) skip = 1;
            // 蝗虫过滤默认关闭（见配置默认值）。开启时两侧都查〔?〕
            // 来源或目标带 'Aloc' 都算（马甲既有当靶子的也有当攻击者的）〔?〕
            if (!skip && g_cfg.skip_locust &&
                (HasLocust(snap.target_handle) || HasLocust(snap.source_handle))) skip = 1;
            if (!skip && g_cfg.only_related) {
                if (!IsRelatedToLocalPlayer(snap.target_handle) &&
                    !IsRelatedToLocalPlayer(snap.source_handle)) skip = 1;
            }

            // ---- 模式 0：只显示自己（伤害来源/目标必须是本地玩家自己的单位，不含友军）----
            if (!skip && mode == 0) {
                const int selfSrc = IsRelatedToLocalPlayer(snap.source_handle);
                const int selfTgt = IsRelatedToLocalPlayer(snap.target_handle);
                int hit = 0;
                if (g_cfg.filter_side == 0)      hit = selfSrc;            // 默认：看来源
                else if (g_cfg.filter_side == 1) hit = selfTgt;            // 看目标
                else                             hit = selfSrc || selfTgt; // 任一方
                if (!hit) skip = 1;
            }

            // ---- 模式过滤（按【来源方】判定：看伤害来源是谁）----
            //   @1 〔?〕来源是自〔?〕友方（want 1〔?〕@2 〔?〕来源是敌人（want 2〔?〕
            //   filter_side 可改成按目标方或任一方判定（〔?〕ini〔?〕
            if (!skip && (mode == 1 || mode == 2)) {
                const int want = (mode == 2) ? 2 : 1;   // 1=自己/友方 2=敌方
                int tgtCamp = UnitCamp(snap.target_handle);
                int srcCamp = UnitCamp(snap.source_handle);
                int hit = 0;
                if (g_cfg.filter_side == 0)      hit = (srcCamp == want);   // 默认：看来源
                else if (g_cfg.filter_side == 1) hit = (tgtCamp == want);   // 看目〔?〕
                else                             hit = (srcCamp == want) || (tgtCamp == want);
                if (!hit) skip = 1;
            }

            // 节流
            static DWORD lastShow = 0;
            if (!skip && g_cfg.throttle_ms > 0) {
                DWORD now = TimeMs();
                if (lastShow && (DWORD)(now - lastShow) < (DWORD)g_cfg.throttle_ms) skip = 1;
                else lastShow = now;
            }

            if (!skip) {
                // ---- v1.3.17（用户指定的格式）：明细带上【来源〔?〕中文字段〔?〕+ 原始数字 ----
                //   形如：`来源 魔狼〔?〕是否攻击:1 是否远程:1 攻击类型:1 伤害类型:1 伤害:33.0`
                //   来源名用 GetUnitLabel（native 下拿不到真名就退化成类型码）〔?〕
                //   ASCII 模式（labels=0）自动变〔?〕`SRC <〔?〕ATK:1 RNG:1 ATYPE:1 DTYPE:1 DMG:33.0`〔?〕
                //   想额外带"武器/生命/所〔?〕就把 ini 〔?〕show_weapon / show_hp / show_owner 打开〔?〕
                char tail[192] = { 0 };
                if (g_cfg.show_weapon) {
                    char wepPart[64] = { 0 };
                    _snprintf_s(wepPart, sizeof(wepPart), _TRUNCATE, " %s:%u", L_WEP, snap.weapon_type);
                    strncat_s(tail, sizeof(tail), wepPart, _TRUNCATE);
                }
                if (g_cfg.show_hp) {
                    const float cur = GetUnitStateSafe(snap.target_handle, JASS_UNIT_STATE_LIFE);
                    const float max = GetUnitStateSafe(snap.target_handle, JASS_UNIT_STATE_MAXLIFE);
                    char hpPart[128] = { 0 };
                    _snprintf_s(hpPart, sizeof(hpPart), _TRUNCATE, " %s:%.1f/%.1f", L_HP, cur, max);
                    strncat_s(tail, sizeof(tail), hpPart, _TRUNCATE);
                }
                if (g_cfg.show_owner) {
                    // 受伤单位的拥有者名（用于区分敌我）—〔?〕JAPI 路径取名字；native 下取不到就不〔?〕
                    char ownerName[64] = { 0 };
                    if (g_call) {
                        __try {
                            uint32_t oh = (uint32_t)g_call("GetOwningPlayer", snap.target_handle);
                            if (oh) {
                                uint32_t s = (uint32_t)g_call("GetPlayerName", oh);
                                const char* p = JassStringToCStr(s);
                                SafeCopyAnsi(p, ownerName, sizeof(ownerName));
                            }
                        } __except (EXCEPTION_EXECUTE_HANDLER) { ownerName[0] = 0; }
                    }
                    if (ownerName[0]) {
                        char ownPart[80] = { 0 };
                        _snprintf_s(ownPart, sizeof(ownPart), _TRUNCATE, " %s:%s", L_OWN, ownerName);
                        strncat_s(tail, sizeof(tail), ownPart, _TRUNCATE);
                    }
                }

                // 来源名（取不到就显示 ?；颜色代码先剥掉，免得把整行染色〔?〕
                char srcName[128] = { 0 };
                GetUnitLabelClean(snap.source_handle, srcName, sizeof(srcName));
                StripColorCodes(srcName);

                // ---- v1.3.17（用户指定的格式）：中文字段〔?〕+ 原始数字 ----
                //   `来源 魔狼〔?〕是否攻击:1 是否远程:1 攻击类型:1 伤害类型:1 伤害:33.0`
                //   四个维度一律【原始数字】（不翻译成"穿刺/普〔?〕这类名字，避免自定义图对不上号）〔?〕
                //   ASCII 模式（labels=0）自动变〔?〕`SRC 魔狼〔?〕ATK:1 RNG:1 ATYPE:1 DTYPE:1 DMG:33.0`〔?〕
                char msg[512] = { 0 };
                if (g_cfg.color) AppUtf8(msg, sizeof(msg), "|cffffcc00");
                AppRaw (msg, sizeof(msg), L_SRC);   AppUtf8(msg, sizeof(msg), " ");
                AppRaw (msg, sizeof(msg), srcName[0] ? srcName : "?");
                AppUtf8(msg, sizeof(msg), " ");
                AppRaw (msg, sizeof(msg), L_ATK);   AppFmt (msg, sizeof(msg), ":%u", atk);
                AppUtf8(msg, sizeof(msg), " ");
                AppRaw (msg, sizeof(msg), L_RNG);   AppFmt (msg, sizeof(msg), ":%u", rng);
                AppUtf8(msg, sizeof(msg), " ");
                AppRaw (msg, sizeof(msg), L_ATYPE); AppFmt (msg, sizeof(msg), ":%u", (unsigned)snap.attack_type);
                AppUtf8(msg, sizeof(msg), " ");
                AppRaw (msg, sizeof(msg), L_DTYPE); AppFmt (msg, sizeof(msg), ":%u", (unsigned)dmgTypeNo);
                AppUtf8(msg, sizeof(msg), " ");
                AppRaw (msg, sizeof(msg), L_DMG);   AppFmt (msg, sizeof(msg), ":%.1f", snap.amount);
                AppRaw (msg, sizeof(msg), tail);
                if (g_cfg.color) AppUtf8(msg, sizeof(msg), "|r");

                // 发到消息区（native 走引擎直连）
                ShowMessage(msg);
            }
        }

        // 按单位统计放在【明细显示之后】：这样最后一击的伤害明细先出现，
        // 死亡结算的统计块再出现（否则统计块会夹在明细上面，顺序看起来是反的）〔?〕
        // 与显示模式无关：@3 关显示时照样记账、照样结算〔?〕
        TrackOnDamage(snap);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 显示/记录阶段异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
    }

    // ---- 〔?〕原样返回 JAPI 的返回〔?〕----
    return retval;
}

//------------------------------------------------------------------------------
// 9. 配置读取
//------------------------------------------------------------------------------
static void WriteDefaultIni()
{
    FILE* f = fopen(g_iniPath, "wb");
    if (!f) return;
    // 本文件是 UTF-8 编译的，直接 fputs 会把中文〔?〕UTF-8 落到 ini 里，
    // 记事本按 GBK 打开就是乱码。统一转成 ANSI 再写〔?〕
    char buf[8192];
    int off = 0;
    const char* parts[] = {
        "; ============================================================================\r\n",
        "; UDamageWatcher 伤害监视插件 配置文件（ANSI/GBK 编码，改完需重启游戏生效）\r\n",
        "; 删掉本文件会按下面的默认值重新生成一份带注释的。\r\n",
        "; ============================================================================\r\n",
        "\r\n",
        "; ---- 游戏内聊天命令（只认本地玩家自己发的）---\r\n",
        ";   @0 = 只显示【伤害来源】为自己的\r\n",
        ";   @1 = 只显示【伤害来源】为自己或友方的\r\n",
        ";   @2 = 只显示【伤害来源】为敌人的\r\n",
        ";   @3 = 关闭显示（连日志一起停）\r\n",
        ";   @<单位> = 开始记录【这个单位受到的伤害】，死亡时自动结算\r\n",
        ";             <单位> 可以是单位名字（如 @魔狼人）、单位类型码（如 @uske）、\r\n",
        ";             或 #十六进制句柄（如 @#00102D3E）。同名单位各自独立记账。\r\n",
        ";   @?  = 立刻打印当前所有在记录单位的统计（不死亡也能看）\r\n",
        ";   @!  = 停止记录并结算\r\n",
        ";   统计维度：是否攻击、是否远程、攻击类型、伤害类型（都是原始数字）\r\n",
        ";   track_min_damage: 结算统计门槛（默认 5）——【小于该值的伤害不统计】，0/负伤害永远不计。\r\n",
        ";                     例：设 5 时，4.9 点的小伤害不进账；填 0 则全部进账。\r\n",
        ";                     只影响记账（次数/总计/组合/来源），屏幕逐条明细的门槛是 min_amount。\r\n",
        ";                     不影响死亡判定：血归零照样结算（没挨到过阈值伤害时不打印空账）。\r\n",
        "\r\n",
        "; ---- 后端（从哪儿取“伤害事件”）----\r\n",
        "; backend: auto   = 进程里有 ydbase(YDWE/JAPI 的基础库) 就沿用原路径（**当前默认**），\r\n",
        ";                   这也是“有 JAPI 才显示到消息区”的前提）；没有 ydbase 则自动改成 native。\r\n",
        ";          native = 强制【引擎直连】：不用 ydbase，直接按特征码找 Game.dll 的引擎伤害函数。\r\n",
        ";                   native 模式也用【引擎直连】把消息发到消息区（能上屏就上屏）；\r\n",
        ";          japi   = 强制原路径（进程里没有 ydbase 时按原样中止，什么都不挂）\r\n",
        ";          显示规则：两种后端都写消息区（没 JAPI 就走引擎直连）；log_only=1 只写日志；\r\n",
        ";            聊天命令需要 ydbase，native 下不可用（用热键 Ctrl+Alt+数字/R/Q/S）。\r\n",
        ";          换版本导致特征码/序言对不上时，native 会【写日志 + 安全退出】（不钩、不动游戏内存）；\r\n",
        ";          那种情况下把本行改成 auto / japi 即可。\r\n",
        "backend=auto\r\n",
        "\r\n",
        "; ---- 总开关 ----\r\n",
        "; enable    : 1=启用插件  0=完全停用（不钩、不显示、不记日志）\r\n",
        "; log_only  : 1=只写日志不显示  0=日志+屏幕都出\r\n",
        "; 开局默认是【静默】的：不显示明细、不显示统计，等玩家自己发聊天命令开启。\r\n",
        ";   开启：@0 只显示来源为自己   @1 只显示来源为自己/友方   @2 只显示来源为敌人\r\n",
        ";   关闭：@3（连日志一起停）\r\n",
        "; 想在进游戏第一次挨打时提示一行怎么开启，把 start_hint 改成 1。\r\n",
        "enable=1\r\n", "log_only=0\r\n", "start_hint=0\r\n",
        "\r\n",
        "; ---- 显示模式（游戏内可用聊天命令动态切换）----\r\n",
        "; mode      : 启动时的模式  0=只显示来源为自己  1=只显示来源为自己/友方  2=只显示来源为敌人  3=关闭(连日志也不记)\r\n",
        "; chat_cmd  : 1=允许游戏内用聊天命令切换  0=只能用本文件的 mode\r\n",
        "; chat_prefix: 命令前缀，默认 @。游戏内发 @0/@1/@2/@3 即切换（只认本地玩家自己发的）\r\n",
        "; block_cmd : 1=拦截 @ 命令，只本地处理、不广播给其他玩家（默认）；0=照旧广播（盟友看得到）\r\n",
        "; filter_side: 模式 0/1/2 按哪一方判定  0=来源方看“伤害来源”是谁，默认)\r\n",
        ";                                    1=目标方(看“挨打的是谁”)\r\n",
        ";                                    2=任一方(来源或目标任一方满足即显示)\r\n",
        "mode=3\r\n", "chat_cmd=1\r\n", "chat_prefix=@\r\n", "block_cmd=1\r\n", "filter_side=0\r\n",
        "; hotkeys: 1=启用热键（Ctrl+Alt+数字 切模式 / R 记录选中单位 / Q 看统计 / S 结算）。\r\n",
        ";          死亡结算复制到剪贴板的能力已在 v1.4.13 删除，v1.4.14 连带删除全部剪贴板配置。\r\n",



        "; 显示（v1.3.12）：有 JAPI 或 ydbase，没有 JAPI 就用【引擎直连】调同一个 DisplayTimedTextToPlayer，\r\n",
        "; ydbase_wait: backend=auto/japi 时等 ydbase 注入的最长秒数（默认 10；0=根本不等）。\r\n",
        ";               以前 war3.exe 里最长等 6 小时、每 30 秒刷一行日志；现在没这必要\r\n",
        ";               （没有 ydbase 也能抓伤害、也能上屏），默认只等 10 秒就走 native。\r\n",
        "; native_chain: 引擎伤害函数入口被别人挂钩时（WFE 的伤害数字、平台 JAPI 都会先钩它），\r\n",
        ";               是否改用【链式挂钩】：用唯一的“尾部序言”认出函数 -> 钩别人装上去的处理函数\r\n",
        ";               -> 跳板转发回它的原代码（它的伤害系统照旧）。默认 1=开；0=老行为（直接安全退出）。\r\n",
        "; pick   : Ctrl+Alt+R/T「记录当前选中的单位」怎么取选区。\r\n",
        ";          实实测：多人联机时用 CreateGroup/GroupEnumUnitsSelected 会导致平台报“不同步/异常”，\r\n",
        ";          所以默认优先用【纯内存读选区】（不建组、不调选区 native、不分配句柄，联机也安全）。\r\n",
        ";          auto  =先用内存读；内存读不可用（游戏版本不符）才降级：单人用建组枚举、多人跳过（默认）\r\n",
        ";          memory=只用内存读，失败即跳过（最保守）\r\n",
        ";          on    =总是用建组枚举（旧行为，联机有风险，只建议单机）   off=总是跳过\r\n",
        ";          reuse =复用单个组（只分配一次句柄，实验档）\r\n",
        "hotkeys=1\r\n", "pick=auto\r\n",
        "track_min_damage=5\r\n",
        "\r\n",
        "; ---- 过滤 ----\r\n",
        "; skip_locust: 1=来源或目标带 'Aloc'(蝗虫技能) 的事件跳过（滤伤害检测马甲用）\r\n",
        ";              默认 0=不过滤 —— 很多自定义图会给普通单位加 'Aloc'，开了会误伤正常伤害\r\n",
        "; filter_zero: 1=伤害 <= 0 的事件不显示\r\n",
        "; min_amount : 伤害低于此值不显示（0=不过滤）\r\n",
        "; only_related: 1=只有自己或自己盟友的单位参与才显示  0=所有人的伤害都显示\r\n",
        "; throttle_ms: 显示节流（毫秒）；0=不节流；AOE 刷屏时设 100~200 会舒服很多\r\n",
        "skip_locust=0\r\n", "filter_zero=1\r\n", "min_amount=0\r\n",
        "only_related=0\r\n", "throttle_ms=0\r\n",
        "\r\n",
        "; ---- 显示内容 ----\r\n",
        "; 显示通道（v1.3.3 定的规则）：\r\n",
        ";   有 JAPI（ydbase 可用）-> 发到【消息区】（DisplayTimedTextToPlayer），不做飘字；\r\n",
        ";   没有 JAPI（backend=native）-> 走引擎直连，照样发到消息区（能上屏就上屏）。\r\n",
        "; 伤害明细（消息区那行）v1.3.1 起【只显示数字】：\r\n",
        ";     是否攻击/是否远程/攻击类型/伤害类型 伤害值    如 1/0/5/4 154.7\r\n",
        ";   （来源名/目标名不写进这行；完整信息在日志的 H 行里）\r\n",
        "; show_hp    : 1=在数字后面追加 生命:当前/最大（默认 0）\r\n",
        "; show_weapon: 1=在数字后面追加 武器:<数字>（默认 0）\r\n",
        "; show_owner : 1=在数字后面追加 受伤单位的拥有者玩家名（默认 0）\r\n",
        "; color      : 1=数字带颜色（黄色）\r\n",
        "; labels     : 1=中文标签（默认）  0=强制 ASCII 标签。v1.3.18 起编码判不出来也用中文（按 UTF-8），\r\n",
        "; encoding   : 游戏文本编码  0=自动判定（判不出来按 UTF-8 —— 本机实测游戏内部就是 UTF-8）\r\n",
        ";              1=强制 GBK(936)  2=强制 UTF-8(65001)。⚠ 中文变乱码时：先试 1，再试 2。\r\n",
        ";              （本机实测该魔兽内部是 UTF-8；换成别的版本若中文乱码可手动指定）\r\n",
        "show_hp=0\r\n", "show_weapon=0\r\n", "show_owner=0\r\n",
        "color=1\r\n", "labels=1\r\n", "encoding=0\r\n",
        "\r\n",
        "; ---- 日志 ----\r\n",
        "; debug      : 调试日志开关（v1.3.3）；0=关（默认）：只留配置/启动结果/每笔明细 H 行、\r\n",
        ";              统计与死亡结算、热键与命令、异常；1=打开：再加 native 解析、D/DN 原始字段、\r\n",
        ";              显示确认行、编码判定探针等排错信息。\r\n",
        "; log_events : 0=【跟随明细开关】玩家开启明细（@0/@1/@2/@3）后日志同步逐条输出；\r\n",
        ";                     关闭（@3）时不写，开局日志量很小（默认）\r\n",
        ";              1=即使关闭也逐条记录（纯排错用，日志会随伤害事件数增长）\r\n",
        "; log_max_lines: 日志最多写多少行；0 = 不设上限（默认，日志保留完整的）；\r\n",
        ";              填正整数则到上限后写一行说明并停止记录（历史上固定为 20 万行）。\r\n",
        "; 每笔伤害的记录行（debug=0 时只有 H 行）：\r\n",
        ";   H  = 人看得懂的完整明细：来源、目标、拥有者、攻击/远程/攻击类型/伤害类型/伤害/武器/生命\r\n",
        ";   D  = 引擎原始字段（结构指针/句柄/掩码/real 位模式）        —— 需 debug=1\r\n",
        ";   DN = native 专属：伤害信息结构头 8 个 dword                 —— 需 debug=1\r\n",
        "debug=0\r\n",
        "; chat_send_delay: 只给数据断点自动测试用的合成按键间隔（默认 250，50~3000）。\r\n",
        "chat_send_delay=250\r\n",
        "; ---- 死亡总结【无框直投】到聊天（v1.4.7）----\r\n",
        "; 做法照 WFE 的 build_tools\\hello_direct.c：不用 SendInput、不开聊天框、不要求游戏在前台。\r\n",
        ";   set_recipient 设收件人 -> SendMessageA(WM_CHAR) 把字直接投进编辑框 -> 用游戏\r\n",
        ";   自己的窗口过程发回车。发送跑在独立线程，不占游戏线程。\r\n",
        "; chat_on_death  : 1=死亡总结直接发到聊天（默认）  0=不发送（只写日志）。\r\n",
        "chat_on_death=1\r\n",
        "; chat_send_target: 收件人  0=全部  1=盟友（队友）  2=观察者\r\n",
        "chat_send_target=1\r\n",
        "; chat_diag: 【诊断用】1=每次聊天都打印调用链/逐帧栈参数/事件对象 dump（日志会很长）；0=默认关。\r\n",
        "chat_diag=0\r\n",
        "; chat_marker: 【逆向用】在聊天框里只输入不发送的一串标记；插件扫内存找到它的缓冲。默认空。\r\n",
        "chat_marker=\r\n",
        "; chat_dr: 【逆向用】1=用数据断点(DR0..DR3)盯住标记缓冲，按回车时暴露【读它的那条指令】（即提交入口）；0=默认关。\r\n",
        "chat_dr=0\r\n",
        "; 两边都能上屏；只想写日志就用 log_only=1。\r\n",
        "ydbase_wait=10\r\n",
        "native_chain=1\r\n",
        "log_events=0\r\n",
        "log_max_lines=0\r\n",
    };
    for (size_t i = 0; i < sizeof(parts) / sizeof(parts[0]); ++i) {
        int n = _snprintf_s(buf + off, sizeof(buf) - (size_t)off, _TRUNCATE, "%s", parts[i]);
        if (n > 0) off += n;
    }
    char ansi[8192];
    Utf8ToAnsi(buf, ansi, sizeof(ansi));
    fputs(ansi, f);
    fclose(f);
}

static void Trim(char* s)
{
    if (!s) return;
    size_t n = strlen(s);
    while (n > 0 && (s[n-1] == ' ' || s[n-1] == '\t' || s[n-1] == '\r' || s[n-1] == '\n')) s[--n] = 0;
    size_t i = 0;
    while (s[i] == ' ' || s[i] == '\t') ++i;
    if (i) memmove(s, s + i, strlen(s + i) + 1);
}

static void LoadConfig()
{
    // 【注意】这里刻意写〔?〕if/else 两个分支，而不〔?〕
    //     if (!f) { ...; return; }
    // 的早退形式：实测在该环境下"早退 + 紧随其后的 LogLine"会让后面那句
    // 配置日志静默丢失（写不出去，也不报错）。改成单出口结构后就正常了〔?〕
    FILE* f = fopen(g_iniPath, "rb");
    if (!f) {
        LogLine("未找到 %s，已按默认配置生成", g_iniPath);
        WriteDefaultIni();
    } else {
    char line[512];
    while (fgets(line, sizeof(line), f)) {
        char* p = line;
        while (*p == ' ' || *p == '\t') ++p;
        if (*p == ';' || *p == '#' || *p == 0) continue;
        char* eq = strchr(p, '=');
        if (!eq) continue;
        *eq = 0;
        char* k = p;
        char* v = eq + 1;
        Trim(k); Trim(v);

        int   iv = atoi(v);
        float fv = (float)atof(v);

        if      (!_stricmp(k, "enable"))       g_cfg.enable       = iv;
        else if (!_stricmp(k, "log_only"))     g_cfg.log_only     = iv;
        else if (!_stricmp(k, "backend")) {
            // auto（默认）/ japi / native，也接受 0 / 1 / 2；ydbase 〔?〕japi 的同义词
            if      (!_stricmp(v, "auto"))   g_cfg.backend = BACKEND_AUTO;
            else if (!_stricmp(v, "japi"))   g_cfg.backend = BACKEND_JAPI;
            else if (!_stricmp(v, "ydbase")) g_cfg.backend = BACKEND_JAPI;
            else if (!_stricmp(v, "native")) g_cfg.backend = BACKEND_NATIVE;
            else                             g_cfg.backend = iv;
            if (g_cfg.backend < BACKEND_AUTO || g_cfg.backend > BACKEND_NATIVE) {
                LogLine("配置: backend=%d 不认识，回退 auto", g_cfg.backend);
                g_cfg.backend = BACKEND_AUTO;
            }
        }
        else if (!_stricmp(k, "skip_locust"))  g_cfg.skip_locust  = iv;
        else if (!_stricmp(k, "filter_zero"))  g_cfg.filter_zero  = iv;
        else if (!_stricmp(k, "min_amount"))   g_cfg.min_amount   = fv;
        else if (!_stricmp(k, "only_related")) g_cfg.only_related = iv;
        else if (!_stricmp(k, "throttle_ms"))  g_cfg.throttle_ms  = iv;
        else if (!_stricmp(k, "show_hp"))      g_cfg.show_hp      = iv;
        else if (!_stricmp(k, "show_weapon"))  g_cfg.show_weapon  = iv;
        else if (!_stricmp(k, "show_owner"))   g_cfg.show_owner   = iv;
        else if (!_stricmp(k, "color"))        g_cfg.color        = iv;
        else if (!_stricmp(k, "log_events"))   g_cfg.log_events   = iv;
        else if (!_stricmp(k, "log_max_lines")) g_cfg.log_max_lines = iv;
        else if (!_stricmp(k, "labels"))       g_cfg.labels       = iv;
        else if (!_stricmp(k, "encoding"))     g_cfg.encoding     = iv;
        else if (!_stricmp(k, "chat_cmd"))     g_cfg.chat_cmd     = iv;
        else if (!_stricmp(k, "block_cmd"))    g_cfg.block_cmd    = iv;
        else if (!_stricmp(k, "chat_prefix")) {
            strncpy_s(g_cfg.chat_prefix, sizeof(g_cfg.chat_prefix), v, _TRUNCATE);
            if (!g_cfg.chat_prefix[0]) strcpy_s(g_cfg.chat_prefix, sizeof(g_cfg.chat_prefix), "@");
        }
        else if (!_stricmp(k, "mode"))         g_cfg.mode         = iv;
        else if (!_stricmp(k, "start_hint"))   g_cfg.start_hint   = iv;
        else if (!_stricmp(k, "hotkeys"))      g_cfg.hotkeys      = iv;
        else if (!_stricmp(k, "pick")) {
            // 支持 auto/on/off/reuse 与数〔?〕0/1/2/3
            if      (!_stricmp(v, "auto"))   g_cfg.pick = 0;
            else if (!_stricmp(v, "on"))     g_cfg.pick = 1;
            else if (!_stricmp(v, "off"))    g_cfg.pick = 2;
            else if (!_stricmp(v, "reuse"))  g_cfg.pick = 3;
            else if (!_stricmp(v, "memory")) g_cfg.pick = 4;
            else                             g_cfg.pick = iv;
        }
        else if (!_stricmp(k, "filter_side"))  g_cfg.filter_side  = iv;
        else if (!_stricmp(k, "mode1_side"))   g_cfg.filter_side  = iv;   // 兼容旧键〔?〕
        else if (!_stricmp(k, "track_min_damage")) g_cfg.track_min_damage = fv;
        // ---- 调试日志开关（v1.3.3〔?〕---
        else if (!_stricmp(k, "debug"))        g_cfg.debug        = iv;
        // v1.4.14：clip_utf8_cftext / clip_ascii / clip_text_mode 已删除。
        //   旧 ini 若还留着会走"未知键"分支（只记一行日志）。
        // ---- 死亡结算直接发聊天（v1.3.29〔?〕---
        // v1.4.0：chat_on_death / chat_inject / chat_in_multiplayer 已删除（不再自己发聊天）。
        //   旧 ini 里若还留着这三行，这里会走"未知键"分支（只记一行日志），不影响运行。
        else if (!_stricmp(k, "chat_send_delay"))  g_cfg.chat_send_delay_ms = iv;
        else if (!_stricmp(k, "chat_on_death"))    g_cfg.chat_on_death = iv;    // v1.4.7
        else if (!_stricmp(k, "chat_send_target")) g_cfg.chat_send_target = iv;   // v1.4.1
        // ---- 诊断噪音开关（v1.3.44〔?〕---
        else if (!_stricmp(k, "chat_diag"))        g_cfg.chat_diag = iv;
        // ---- 输入框定位标记（v1.3.50〔?〕---
        else if (!_stricmp(k, "chat_marker")) {
            strncpy_s(g_cfg.chat_marker, sizeof(g_cfg.chat_marker), v, _TRUNCATE);
        }
        // ---- 数据断点定位提交入口（v1.3.54〔?〕---
        else if (!_stricmp(k, "chat_dr"))          g_cfg.chat_dr = iv;
        // ---- 没有 JAPI 时也用引擎直连上屏（v1.3.8〔?〕---

        // ---- 〔?〕ydbase 的最长秒数（v1.3.9〔?〕---
        else if (!_stricmp(k, "ydbase_wait")) {
            g_cfg.ydbase_wait_sec = iv;
            if (g_cfg.ydbase_wait_sec < 0)    g_cfg.ydbase_wait_sec = 0;
            if (g_cfg.ydbase_wait_sec > 3600) g_cfg.ydbase_wait_sec = 3600;
        }
        // ---- 入口被别人挂钩时的链式挂钩（v1.3.10〔?〕---
        else if (!_stricmp(k, "native_chain")) g_cfg.native_chain = iv;
    }
    fclose(f);
    }

    if (g_cfg.log_max_lines < 0) g_cfg.log_max_lines = 0;              // 0 = 不限
    // v1.3.29：发聊天的等待时间夹一下（太小学聊天框没开出来，太大像卡住〔?〕
    if (g_cfg.chat_send_delay_ms < 50)   g_cfg.chat_send_delay_ms = 50;
    if (g_cfg.chat_send_delay_ms > 3000) g_cfg.chat_send_delay_ms = 3000;
    // v1.3.21：track_min_damage 不再是废弃键（见 TrackOnDamage 的记账口径）〔?〕
    //          这里只做保护：负数按 0 处理〔?〕= 全部进账）〔?〕
    if (g_cfg.track_min_damage < 0.0f) g_cfg.track_min_damage = 0.0f;

    // v1.3.90：把【读到的 ini 内容哈希】也打出来。
    //   为什么：部署时机与游戏启动撞车时，游戏可能读的是上一版 ini，
    //   而日志里所有值都"看起来正常"，极难发现。有哈希就能和磁盘上的一比。
    {
        uint32_t h = 2166136261u;                       // FNV-1a
        FILE* hf = fopen(g_iniPath, "rb");
        if (hf) {
            int c;
            while ((c = fgetc(hf)) != EOF) { h ^= (uint32_t)c; h *= 16777619u; }
            fclose(hf);
        }
        LogLine("配置: ini=%s 内容哈希=%08X（和磁盘上的对一下就知道读的是哪份）",
                g_iniPath, h);
    }
    LogLine("配置: enable=%d log_only=%d backend=%d debug=%d chat_send_delay=%d chat_diag=%d ydbase_wait=%d native_chain=%d"
            " skip_locust=%d filter_zero=%d min_amount=%.1f"
            " only_related=%d throttle_ms=%d show_hp=%d show_weapon=%d show_owner=%d"
            " color=%d log_events=%d labels=%d encoding=%d log_max_lines=%d"
            " | mode=%d start_hint=%d hotkeys=%d pick=%d chat_cmd=%d block_cmd=%d chat_prefix=\"%s\" filter_side=%d track_min_damage=%.1f chat_dr=%d chat_marker=\"%s\"",
            g_cfg.enable, g_cfg.log_only, g_cfg.backend, g_cfg.debug,
            g_cfg.chat_send_delay_ms, g_cfg.chat_diag, g_cfg.ydbase_wait_sec,
            g_cfg.native_chain,            g_cfg.skip_locust, g_cfg.filter_zero,
            g_cfg.min_amount, g_cfg.only_related, g_cfg.throttle_ms,
            g_cfg.show_hp, g_cfg.show_weapon, g_cfg.show_owner,
            g_cfg.color, g_cfg.log_events, g_cfg.labels, g_cfg.encoding, g_cfg.log_max_lines,
            g_cfg.mode, g_cfg.start_hint, g_cfg.hotkeys, g_cfg.pick, g_cfg.chat_cmd, g_cfg.block_cmd, g_cfg.chat_prefix,
            g_cfg.filter_side, g_cfg.track_min_damage, g_cfg.chat_dr, g_cfg.chat_marker);
    LogLine("配置: 直投聊天 chat_send_target=%d（0=全部 1=盟友 2=观察者）", g_cfg.chat_send_target);
}

//------------------------------------------------------------------------------
// 10. 初始〔?〕
//------------------------------------------------------------------------------
static void InitPaths(HMODULE hSelf)
{
    char mod[MAX_PATH] = { 0 };
    GetModuleFileNameA(hSelf, mod, MAX_PATH);
    strncpy_s(g_dllDir, MAX_PATH, mod, _TRUNCATE);
    char* slash = strrchr(g_dllDir, '\\');
    if (slash) *slash = 0; else g_dllDir[0] = 0;
    _snprintf_s(g_logPath, MAX_PATH, _TRUNCATE, "%s\\UDamageWatcher.log", g_dllDir);
    _snprintf_s(g_iniPath, MAX_PATH, _TRUNCATE, "%s\\UDamageWatcher.ini", g_dllDir);
}

//------------------------------------------------------------------------------
// 9.5 native 后端初始化（backend=native，或 backend=auto 且进程里没有 ydbase〔?〕
//
// 〔?〕DoInitialize 〔?〕JAPI 路径完全独立：这里不〔?〕ydbase 的任何导出，
// 只把 OurDamageFunc 内联挂到 Game.dll 的引擎伤害函数上，然后：
//   * 屏幕显示：照常【上屏】—〔?〕用引擎直连调 DisplayTimedTextToPlayer（v1.3.12 起去〔?〕
//             “没 JAPI 就不显示”的约束）；只有 log_only=1 才退化成只写日志
//   * 聊天命令：跳过（定位 InGameChatWhat 需〔?〕ydbase 搜索器）
//   * 热键    ：照旧启用（选区的纯内存读不依赖 ydbase；模式提醒只进日志）
// 任何一步不成立都只〔?〕写日〔?〕+ 安全退〔?〕，绝不动游戏内存〔?〕
//------------------------------------------------------------------------------
static void DoInitializeNative()
{
    LogLine("---- native 后端（无 ydbase / 引擎直连 Game.dll）---");
    LogLine("native 模式：屏幕照常上屏（引擎直连 DisplayTimedTextToPlayer；log_only=1 才只写日志）；"
            "聊天命令走【字符串反查】定位（v1.3.32 起 native 也能用），热键照旧可用");

    const uint32_t base = Wc3GameBase();
    if (!base) {
        LogLine("初始化中止：未找到 Game.dll（native 模式需要它），安全退出（游戏不受影响）");
        LogLine("================================================================");
        return;
    }
    {   // JASS ctx 全局（字符串表、句柄管理器都挂在它下面）—〔?〕〔?〕0 才能〔?〕native 取名〔?〕上屏
        uint32_t ctx = 0;
        const int ok = Wc3PeekU32(base + WC3_RVA_CTX_GLOBAL, &ctx) && ctx != 0;
        LogLine("native: ctx = *(Game.dll + 0x%X) = %08X（%s）", WC3_RVA_CTX_GLOBAL, ctx,
                ok ? "非 0，字符串与句柄转换可用" : "0 —— 地图还没起来或版本不符，"
                                                   "取名字/上屏会退化成只写日志");
    }
    Wc3PrepareNatives();     // 每个 native 一行日志（基址 + RVA + 序言 + 校验结论〔?〕

    // 〔?〕常规〔?〕6 字节入口序言〔?〕.text 内唯一命中 -> 直接钩入〔?〕
    uint32_t nativeTarget = Wc3FindDamageFunc(base);
    // 〔?〕入口被人挂钩了（WFE 的伤害系〔?〕/ 平台 JAPI 常见）：用唯一〔?〕尾部序言"认出函数
    //    并改为【链式挂钩】——钩别人装上去的处理函数，她的伤害系统照旧工作（见函数注释）
    if (!nativeTarget && g_cfg.native_chain)
        nativeTarget = Wc3FindDamageFuncChained(base, NULL);

    if (!nativeTarget) {
        LogLine("初始化中止：native 模式没能唯一定位引擎伤害函数，安全退出（不动任何东西）");
        LogLine("提示：这局若装了 WFE（伤害数字）或平台 JAPI，它们会先挂钩引擎伤害函数、改写入口序言）"
                "本版会用“尾部序言”认出来并链式挂钩（ini native_chain=1，默认开）。");
        LogLine("================================================================");
        return;
    }
    const uint32_t target = nativeTarget;

    // 〔?〕双份加载保护：目标入口若已经被【我们自己】的另一个实例钩了（同一〔?〕DLL 被两条加载路〔?〕
    //   各装一份，两份模块地址不同），绝不能再钩一〔?〕—〔?〕那会让跳板的相对位移算错、互相踩〔?〕
    //   只写一行日志、本实例让开〔?〕
    {
        uint8_t e[5] = { 0 };
        uint32_t dest = 0;
        if (Wc3Peek(target, e, sizeof(e))) {
            if (e[0] == 0xE9u) {
                const int32_t rel = (int32_t)((uint32_t)e[1] | ((uint32_t)e[2] << 8) |
                                              ((uint32_t)e[3] << 16) | ((uint32_t)e[4] << 24));
                dest = target + 5u + (uint32_t)rel;
            } else if (e[0] == 0xEBu) {
                dest = target + 2u + (uint32_t)(int32_t)(int8_t)e[1];
            }
            const uint32_t selfBase = g_hSelf ? (uint32_t)(uintptr_t)g_hSelf : 0;
            if (dest && selfBase && dest >= selfBase && dest < selfBase + 0x00400000u) {
                LogLine("W native：目标 %08X 已被【我们自己】的另一份加载（%08X）挂钩 -> 本实例不再挂钩。"
                        "建议只保留一条加载路径（config.cfg=1 或 WFE 注入，二选一）。", target, dest);
                LogLine("================================================================");
                InterlockedExchange(&g_nativeMode, 0);
                return;
            }
        }
    }

    // 先置位：钩子一旦生效，快照/日志/取数就走 native 分支
    InterlockedExchange(&g_nativeMode, 1);

    // 注意这里把跳板【直接写〔?〕g_original_damage】（32 〔?〕LONG 〔?〕32 位指针同〔?〕4 字节）：
    // InstallDetour 〔?〕打补丁之〔?〕就写 *outTramp，所以引擎刚跳到我们这里〔?〕ORIG_DAMAGE
    // 已经可用，不会出〔?〕钩子已挂、原函数还是〔?〕的窗口（这比先挂后设更安全）〔?〕
    int stolen = InstallDetour(target, (void*)&OurDamageFunc, (void**)&g_original_damage);
    if (!stolen || !g_original_damage) {
        InterlockedExchange(&g_nativeMode, 0);
        LogLine("初始化中止：native 模式内联钩子安装失败（序言解码不了或含相对跳转），安全退出");
        LogLine("================================================================");
        return;
    }
    g_nativeDmgTarget = target;
    g_nativeDmgStolen = stolen;
    LogLine("已挂接引擎伤害函数（native 内联钩子）：目标=%08X 偷 %d 字节 跳板=%08X our=%08X",
            target, stolen, (uint32_t)(uintptr_t)ORIG_DAMAGE, (uint32_t)(uintptr_t)&OurDamageFunc);
    LogLine("校验结果：OK");

    // ---- 与 JAPI 路径一致的后半段（模式 / 聊天 / 热键）----
    // v1.3.63：每一步都单独 try + 记出错指令，避免整段被吞掉后完全不知道炸在哪
    InterlockedExchange(&g_mode, g_cfg.mode);
    LogLine("启动模式=%d(%s)，聊天命令=%s，前缀=\"%s\"，判定方=%s",
            (int)g_mode, ModeNameAscii((int)g_mode),
            g_cfg.chat_cmd ? "开" : "关", g_cfg.chat_prefix,
            (g_cfg.filter_side == 0) ? "来源方" : ((g_cfg.filter_side == 1) ? "目标方" : "任一方"));

    __try {
        LogLine("I 初始化：开始挂聊天钩子");
        InitChatHook();          // native 模式下内部会早退并写日志说明
        LogLine("I 初始化：聊天钩子阶段结束");
    } __except (UDW_CATCH_FAULT()) {
        LogFaultInfo("聊天钩子初始化异常", (uint32_t)GetExceptionCode(), g_faultAt, g_faultAcc);
    }
    __try {
        LogLine("I 初始化：开始启用热键");
        InitHotkeys();           // 热键照旧启用；回执消息本阶段只进日志
        LogLine("I 初始化：热键阶段结束");
    } __except (UDW_CATCH_FAULT()) {
        LogFaultInfo("热键初始化异常", (uint32_t)GetExceptionCode(), g_faultAt, g_faultAcc);
    }

    LogLine("初始化完成（native 模式）。进游戏打一次怪即可看到日志。");
    LogLine("================================================================");
}

static void DoInitialize()
{
    LogLine("================================================================");
    LogLine("UDamageWatcherHook v1.4.22（热键吞键，阻止传播给游戏）");
    LogLine("本 DLL  : %s", g_dllDir);
    LogLine("日志    : %s", g_logPath);
    LogLine("配置    : %s", g_iniPath);
    LogLine("PID=%lu  self=%08X", GetCurrentProcessId(), (uint32_t)(uintptr_t)g_hSelf);

    // 读配置〔?〕
    // 【为什么放在这里而不〔?〕DllMain】：DllMain 运行〔?〕loader lock 下，
    // 在里面做文件 IO（fopen/fgets/fclose）是被明确不推荐的，实测在该环境〔?〕
    // 会出〔?〕日志行随机丢一〔?〕的诡异现象。初始化本来就跑在自己的线程里，
    // 把配置读取挪过来最稳〔?〕
    static volatile LONG configLoaded = 0;
    if (InterlockedCompareExchange(&configLoaded, 1, 0) == 0) {
        InitPaths(g_hSelf);        // 再取一次路径，确保不被 DllMain 的赋值竞争影〔?〕
        LoadConfig();
    }

    // ---- 后端选择（backend = auto | japi | native，见 ini〔?〕---
    //   native：强制引擎直〔?〕—〔?〕既然完全不依〔?〕ydbase，就【不浪费时间去等它〔?〕
    //           （单机上装不〔?〕ydbase 都用它验〔?〕native 路径）〔?〕
    //   auto / japi：下面保持原来的等待逻辑〔?〕JAPI 路径一字不变；
    //                auto 〔?〕等超时仍然没〔?〕ydbase"时改〔?〕native，而不是中止〔?〕
    if (g_cfg.backend == BACKEND_NATIVE) {
        LogLine("backend=native：强制走引擎直连（跳过 ydbase 等待与 JAPI 路径）");
        DoInitializeNative();
        return;
    }

    // ---- 等依赖模〔?〕+ 槽就〔?〕----
    // 加载时机不定：YDWE 启动器是同进程插件（很快），平台则常常先〔?〕war3 进程〔?〕
    // 登录→大厅→进图之后才注〔?〕JAPI/ydbase〔?〕
    //   〔?〕v1.3.9 起【默认只〔?〕10 秒】（ini: ydbase_wait，单位秒〔?〕= 立刻〔?〕native）：
    //     因为"没有 ydbase 也能抓伤害、也能上〔?〕（引擎直连）—〔?〕
    //     再像以前那样〔?〕6 小时、每 30 秒刷一行日志，纯属浪费〔?〕
    //     真想让平台后注入〔?〕ydbase 也接管，就把 ydbase_wait 调大（例〔?〕120）〔?〕
    //   环境变量 UDW_WAIT_MS（毫秒）仍然优先（自检程序用它缩短等待）〔?〕
    DWORD waitMs = (DWORD)g_cfg.ydbase_wait_sec * 1000u;
    {
        char exePath[MAX_PATH] = { 0 };
        GetModuleFileNameA(NULL, exePath, MAX_PATH);
        const char* base = strrchr(exePath, '\\');
        base = base ? base + 1 : exePath;
        if (waitMs == 0) {
            LogLine("%s：ydbase_wait=0 -> 只探一次就决定（进程里已有 ydbase 就走 JAPI，没有立刻转 native）", base);
        } else {
            LogLine("%s：ydbase 未就绪时最多等 %u 秒（ini 的 ydbase_wait；0=不等）",
                    base, waitMs / 1000u);
        }
    }
    {
        char buf[32] = { 0 };
        DWORD n = GetEnvironmentVariableA("UDW_WAIT_MS", buf, sizeof(buf));
        if (n > 0 && n < sizeof(buf)) {
            long v = atol(buf);
            if (v >= 0 && v <= 86400000L) waitMs = (DWORD)v;
        }
    }
    const DWORD step = 500;
    DWORD waited = 0;
    DWORD nextLog = 60000;      // 只在等超〔?〕60 秒时才打进度行（默认只等 10 〔?〕-> 一行都不打〔?〕
    int japiLogged = 0, ydbaseLogged = 0;

    // 等依赖模块期间，做两件事用于"平台联机为什么没效果"的判定：
    //   〔?〕把【全部】已加载模块打一遍（不做名字过滤 —〔?〕改名成别的也能看见）〔?〕
    //   〔?〕对每个模块解析它的【导出表】，看有没有导出 ydbase/JAPI 的特征符〔?〕
    //      （get_war3_searcher / jass_func / object_to_handle / replace_pointer …）
    //      —〔?〕只要有人塞了 JAPI（哪怕改了文件名），这一步就能抓到〔?〕
    auto ProbeJapiExports = [](HMODULE m, const char* modName) -> int {
        static const char* kSigs[] = {
            "get_war3_searcher", "jass_func", "object_to_handle",
            "replace_pointer", "search_int_in_rdata", "get_jass_vm"
        };
        const uint8_t* base = (const uint8_t*)m;
        if (!Readable(base, 0x40) || base[0] != 'M' || base[1] != 'Z') return 0;
        int32_t e_lfanew = *(const int32_t*)(base + 0x3C);
        if (e_lfanew <= 0 || e_lfanew > 0x1000) return 0;
        const uint8_t* nt = base + e_lfanew;
        if (!Readable(nt, 0x120) || *(const uint32_t*)nt != 0x00004550u) return 0;
        const uint16_t magic = *(const uint16_t*)(nt + 24);
        const uint8_t* dd = nt + 24 + ((magic == 0x20Bu) ? 112 : 96);
        uint32_t expRva = *(const uint32_t*)(dd + 0);
        if (!expRva) return 0;
        const uint8_t* exp = base + expRva;
        if (!Readable(exp, 40)) return 0;
        uint32_t nNames  = *(const uint32_t*)(exp + 24);
        uint32_t namesRva = *(const uint32_t*)(exp + 32);
        if (!nNames || nNames > 20000u) return 0;
        if (!Readable(base + namesRva, (size_t)nNames * 4u)) return 0;
        const uint32_t* names = (const uint32_t*)(base + namesRva);
        int hits = 0;
        for (uint32_t i = 0; i < nNames && hits < 6; ++i) {
            const char* nm = (const char*)(base + names[i]);
            if (!Readable(nm, 8)) continue;
            for (int k = 0; k < 6; ++k) {
                if (strstr(nm, kSigs[k])) { LogLine("JAPI 探测：模块 %s 导出 %s", modName, nm); ++hits; break; }
            }
        }
        return hits;
    };

    auto DumpAllModules = [&](const char* tag) {
        HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, GetCurrentProcessId());
        if (snap == INVALID_HANDLE_VALUE) { LogLine("模块清单（%s）：快照失败 err=%u", tag, GetLastError()); return; }
        MODULEENTRY32 me;
        me.dwSize = sizeof(me);
        int n = 0, japiHits = 0;
        if (Module32First(snap, &me)) {
            do {
                ++n;
                LogLine("模块清单（%s）：[%02d] %-28s base=%08X size=%u", tag, n, me.szModule,
                        (uint32_t)(uintptr_t)me.modBaseAddr, (uint32_t)me.modBaseSize);
                japiHits += ProbeJapiExports((HMODULE)me.modBaseAddr, me.szModule);
            } while (Module32Next(snap, &me));
        }
        CloseHandle(snap);
        LogLine("模块清单（%s）：共 %d 个模块；导出 ydbase/JAPI 特征符号的模块数=%d %s",
                tag, n, japiHits,
                japiHits ? "（说明 JAPI 在，只是可能改了名）" : "（说明进程里确实没有 JAPI/ydbase）");
    };

    for (;;) {
        if (!g_japiBase) {
            g_japiBase = (uint32_t)(uintptr_t)GetModuleHandleA("yd_jass_api.dll");
            if (g_japiBase && !japiLogged) { japiLogged = 1; LogLine("已找到 yd_jass_api.dll J=%08X", g_japiBase); }
        }
        if (!g_ydbase) {
            g_ydbase = (uint32_t)(uintptr_t)GetModuleHandleA("ydbase.dll");
            if (g_ydbase && !ydbaseLogged) { ydbaseLogged = 1; LogLine("已找到 ydbase.dll %08X（共等 %u 秒）", g_ydbase, waited / 1000u); }
        }
        // 只要 ydbase 在就够了 —〔?〕伤害槽是我们自己用搜索器找的，不依赖 JAPI〔?〕
        // JAPI 在不在都行（在的话我们挂在它外层，它的伤害事件照常工作）〔?〕
        if (g_ydbase) break;
        if (waited >= waitMs) break;
        if (waited >= nextLog) {
            LogLine("仍在等待 ydbase.dll …（已等 %u 秒；想让它别等就把 ini 的 ydbase_wait 设成 0）", waited / 1000u);
            if (g_cfg.debug && waited == 60000) DumpAllModules("等待中");   // 模块清单很长，只在 debug 才 dump
            nextLog += 60000;
        }
        Sleep(step);
        waited += step;
    }

    if (!g_ydbase) {
        // backend=auto：没〔?〕ydbase 不再〔?〕中止"，而是改走 native（引擎直连）〔?〕
        // backend=japi：保持原来的行为（缺 ydbase 就按原样中止）〔?〕
        LogLine("未找到 ydbase.dll（等到超时，共 %u 秒）", waited / 1000u);
        if (g_cfg.backend == BACKEND_AUTO) {
            LogLine("backend=auto 且进程里没有 ydbase.dll：改用 native 模式（引擎直连 Game.dll）");
            DoInitializeNative();
            return;
        }
        LogLine("初始化中止：未找到 ydbase.dll，安全退出（游戏不受影响）");
        LogLine("提示：需要有 YDWE 的基础库（启动器或平台自带的 ydbase.dll）在游戏进程里；"
                "平台联机进程里没有 ydbase 时，把 ini 的 backend 设成 auto/native 即可走引擎直连。");
        LogLine("================================================================");
        return;
    }
    if (!g_japiBase) {
        LogLine("提示：进程里没有 yd_jass_api.dll —— 不影响本插件（伤害槽是自己找的）。"
                "只是地图若依赖 JAPI 功能则与你无关。");
    }

    // ---- 〔?〕ydbase 导出 ----
    HMODULE yb = (HMODULE)(uintptr_t)g_ydbase;
    g_replace_pointer  = (fn_replace_pointer_t) (uintptr_t)GetProcAddress(yb, "?replace_pointer@hook@base@@YAIII@Z");
    g_create_string    = (fn_create_string_t)   (uintptr_t)GetProcAddress(yb, "?create_string@jass@warcraft3@base@@YAIPBD@Z");
    g_from_string      = (fn_from_string_t)     (uintptr_t)GetProcAddress(yb, "?from_string@jass@warcraft3@base@@YAPBDI@Z");
    g_from_stringid    = (fn_from_stringid_t)   (uintptr_t)GetProcAddress(yb, "?from_stringid@jass@warcraft3@base@@YAPBDI@Z");
    g_from_real        = (fn_from_real_t)       (uintptr_t)GetProcAddress(yb, "?from_real@jass@warcraft3@base@@YAMI@Z");
    g_to_real          = (fn_to_real_t)         (uintptr_t)GetProcAddress(yb, "?to_real@jass@warcraft3@base@@YAIM@Z");
    g_object_to_handle = (fn_object_to_handle_t)(uintptr_t)GetProcAddress(yb, "?object_to_handle@warcraft3@base@@YAII@Z");
    g_call             = (fn_call_t)            (uintptr_t)GetProcAddress(yb, "?call@jass@warcraft3@base@@YAIPBDZZ");
    g_jass_func        = (fn_jass_func_t)       (uintptr_t)GetProcAddress(yb, "?jass_func@jass@warcraft3@base@@YAPBVfunc_value@123@PBD@Z");
    g_to_stringid      = (fn_to_stringid_t)     (uintptr_t)GetProcAddress(yb, "?to_stringid@jass@warcraft3@base@@YAIPBD@Z");
    g_get_jass_vm      = (fn_get_jass_vm_t)     (uintptr_t)GetProcAddress(yb, "?get_jass_vm@warcraft3@base@@YAPAUjass_vm_t@12@XZ");
    // 定位引擎函数用的工具（与 YDWE 同款〔?〕
    g_get_war3_searcher = (fn_get_war3_searcher_t)(uintptr_t)GetProcAddress(yb, "?get_war3_searcher@warcraft3@base@@YAAAVwar3_searcher@12@XZ");
    g_search_string     = (fn_search_string_t)   (uintptr_t)GetProcAddress(yb, "?search_string@basic_searcher@warcraft3@base@@QBEIPBD@Z");
    g_next_opcode       = (fn_next_opcode_t)     (uintptr_t)GetProcAddress(yb, "?next_opcode@warcraft3@base@@YAIIEI@Z");
    g_convert_function  = (fn_convert_function_t)(uintptr_t)GetProcAddress(yb, "?convert_function@warcraft3@base@@YAII@Z");
    // 搜索器工具（找伤害函数槽用；都是成员函数 〔?〕__fastcall + dummy edx 等价调用〔?〕
    g_search_string_ptr   = (fn_ss_ptr_t)(uintptr_t)GetProcAddress(yb, "?search_string_ptr@basic_searcher@warcraft3@base@@QBEIPBDI@Z");
    g_search_int_in_text1 = (fn_si1_t)   (uintptr_t)GetProcAddress(yb, "?search_int_in_text@basic_searcher@warcraft3@base@@QBEII@Z");
    g_search_int_in_text2 = (fn_si2_t)   (uintptr_t)GetProcAddress(yb, "?search_int_in_text@basic_searcher@warcraft3@base@@QBEIII@Z");
    g_search_int_in_rdata = (fn_si1_t)   (uintptr_t)GetProcAddress(yb, "?search_int_in_rdata@basic_searcher@warcraft3@base@@QBEII@Z");
    g_current_function    = (fn_curfn_t) (uintptr_t)GetProcAddress(yb, "?current_function@war3_searcher@warcraft3@base@@QAEII@Z");

    LogLine("导出的 API: replace_pointer=%08X create_string=%08X(不用) from_string=%08X"
            " from_stringid=%08X(标识符表,不用) get_jass_vm=%08X from_real=%08X to_real=%08X"
            " object_to_handle=%08X call=%08X jass_func=%08X",
            (uint32_t)(uintptr_t)g_replace_pointer, (uint32_t)(uintptr_t)g_create_string,
            (uint32_t)(uintptr_t)g_from_string, (uint32_t)(uintptr_t)g_from_stringid,
            (uint32_t)(uintptr_t)g_get_jass_vm, (uint32_t)(uintptr_t)g_from_real,
            (uint32_t)(uintptr_t)g_to_real, (uint32_t)(uintptr_t)g_object_to_handle,
            (uint32_t)(uintptr_t)g_call, (uint32_t)(uintptr_t)g_jass_func);
    LogLine("定位工具: get_war3_searcher=%08X search_string=%08X next_opcode=%08X convert_function=%08X",
            (uint32_t)(uintptr_t)g_get_war3_searcher, (uint32_t)(uintptr_t)g_search_string,
            (uint32_t)(uintptr_t)g_next_opcode, (uint32_t)(uintptr_t)g_convert_function);

    // ---- native 映射表体检：确认要用的 native 都在表里、参数个数符合预〔?〕----
    // 预期：GetUnitName 1、GetUnitTypeId 1、GetUnitState 2、GetUnitAbilityLevel 2〔?〕
    //       GetOwningPlayer 1、GetPlayerName 1、GetLocalPlayer 0〔?〕
    //       DisplayTimedTextToPlayer 5 [RRR..H,S]、IsPlayerAlly 2、GetPlayerId 1
    LogJassFunc("GetUnitName");
    LogJassFunc("GetUnitTypeId");
    LogJassFunc("GetUnitState");
    LogJassFunc("GetUnitAbilityLevel");
    LogJassFunc("GetOwningPlayer");
    LogJassFunc("GetPlayerName");
    LogJassFunc("GetLocalPlayer");
    LogJassFunc("DisplayTimedTextToPlayer");
    LogJassFunc("IsPlayerAlly");
    LogJassFunc("GetPlayerId");

    if (!g_replace_pointer) {
        LogLine("初始化中止：缺少 replace_pointer，安全退出");
        LogLine("================================================================");
        return;
    }
    if (!g_call || !g_from_real || !g_to_real || !g_object_to_handle) {
        LogLine("初始化中止：ydbase 导出不全（call/from_real/to_real/object_to_handle），安全退出");
        LogLine("================================================================");
        return;
    }

    // ---- 〔?〕引擎伤害函数〔?〕----
    // 三条路，按优先级〔?〕
    //   〔?〕自己用搜索器找【指针槽】（照抄 YDWE EventDamageData.cpp 的配方）—〔?〕启动器的 JAPI 走这〔?〕
    //   〔?〕找不到槽 〔?〕直接对【引擎伤害函数本体】做内联钩子（例〔?〕KK 平台〔?〕JAPI 不用指针槽）
    //   〔?〕都没〔?〕〔?〕才回退写死〔?〕J+0x928D4（且只在地址看起来是用户态可读时才试〔?〕
    uint32_t dmgFunc = 0;
    uint32_t slot = FindUnitDamageFuncSlot(&dmgFunc);
    uint32_t inlineTarget = 0;

    if (!slot) {
        // 〔?〕内联钩子：目标就是搜索器给出〔?〕引擎伤害函数"
        if (dmgFunc >= 0x10000 && dmgFunc < 0x7FFF0000) {
            MEMORY_BASIC_INFORMATION mbi = { 0 };
            if (VirtualQuery((const void*)(uintptr_t)dmgFunc, &mbi, sizeof(mbi)) &&
                (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY))) {
                inlineTarget = dmgFunc;
                LogLine("伤害槽没找到，改对引擎伤害函数本体做内联钩子：%08X", inlineTarget);
            }
        }
    }

    if (!slot && !inlineTarget && g_japiBase) {
        // 〔?〕老路：写死偏移（只有地址像用户态才敢试，否则读一下就崩）
        uint32_t legacy = (uint32_t)(g_japiBase + JAPI_OFF_DAMAGE_FUNC_SLOT);
        if (legacy > 0x10000 && legacy < 0x7FFF0000) {
            uint32_t v = 0;
            __try { v = *(volatile uint32_t*)(uintptr_t)legacy; }
            __except (EXCEPTION_EXECUTE_HANDLER) { v = 0; }
            LogLine("伤害槽：回退写死偏移 J+%X = %08X -> %08X", JAPI_OFF_DAMAGE_FUNC_SLOT, legacy, v);
            slot = v ? legacy : 0;
        } else {
            LogLine("伤害槽：写死偏移算出的地址 %08X 不在用户态，放弃回退", legacy);
        }
    }

    if (!slot && !inlineTarget) {
        LogLine("初始化中止：既找不到伤害函数槽，也定位不到引擎伤害函数，安全退出（游戏不受影响）");
        LogLine("================================================================");
        return;
    }

    uint32_t cur = 0;
    const uint32_t expectUnused = 0;
    (void)expectUnused;
    if (slot) {
        __try { cur = *(volatile uint32_t*)(uintptr_t)slot; }
        __except (EXCEPTION_EXECUTE_HANDLER) {
            LogLine("初始化中止：读取槽 %08X 异常，安全退出", slot);
            LogLine("================================================================");
            return;
        }
        LogLine("伤害函数槽 = %08X，当前内容 = %08X（%s）", slot, cur,
                (cur == (uint32_t)(uintptr_t)&OurDamageFunc) ? "已经是我们自己，跳过" : "准备替换");
        // 保护：槽里若是【我们的另一个实例】（同一 DLL 被两条加载路径各加载一份，模块地址不同），
        // 也绝不能替换，否则两份互相钩、显〔?〕日志全重复〔?〕
        {
            const uint32_t selfBase = g_hSelf ? (uint32_t)(uintptr_t)g_hSelf : 0;
            if (cur && selfBase && cur >= selfBase && cur < selfBase + 0x00400000u) {
                LogLine("W 初始化中止：伤害槽已被【我们自己】的另一份加载（%08X）占用 -> 本实例不再挂钩。"
                        "建议只保留一条加载路径（config.cfg=1 或 WFE 注入，二选一）。", cur);
                LogLine("================================================================");
                return;
            }
        }
        if (!cur || cur == (uint32_t)(uintptr_t)&OurDamageFunc) {
            LogLine("初始化中止：槽内容不可用（0 或已是我们自己），不做替换");
            LogLine("================================================================");
            return;
        }
        // 槽里那个地址必须是可执行内存（基本健全性检查）
        MEMORY_BASIC_INFORMATION mbi = { 0 };
        if (!VirtualQuery((const void*)(uintptr_t)cur, &mbi, sizeof(mbi)) ||
            !(mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY))) {
            LogLine("初始化中止：槽内容 %08X 不是可执行内存，安全退出", cur);
            LogLine("================================================================");
            return;
        }
    }

    // ---- 挂接 ----
    if (slot) {
        __try {
            uint32_t old = g_replace_pointer(slot, (uint32_t)(uintptr_t)&OurDamageFunc);
            InterlockedCompareExchange(&g_original_damage, (LONG)old, 0);
            g_hookedSlot = slot;
            LogLine("已挂接引擎伤害函数（指针槽）：槽=%08X old=%08X our=%08X",
                    slot, old, (uint32_t)(uintptr_t)&OurDamageFunc);
            LogLine("校验结果：%s", (old == cur) ? "OK" : "警告：返回的原地址与读到的不同！");
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            InterlockedExchange(&g_original_damage, 0);
            LogLine("初始化中止：替换时异常（code=%08X）", (uint32_t)GetExceptionCode());
        }
    } else {
        // 内联钩子：把引擎伤害函数开头改〔?〕jmp 到我们的函数，跳板作〔?〕原函〔?〕被回〔?〕
        void* tramp = NULL;
        int stolen = InstallDetour(inlineTarget, (void*)&OurDamageFunc, &tramp);
        if (stolen && tramp) {
            InterlockedCompareExchange(&g_original_damage, (LONG)(uint32_t)(uintptr_t)tramp, 0);
            LogLine("已挂接引擎伤害函数（内联钩子）：目标=%08X 偷 %d 字节 跳板=%08X our=%08X",
                    inlineTarget, stolen, (uint32_t)(uintptr_t)tramp, (uint32_t)(uintptr_t)&OurDamageFunc);
            LogLine("校验结果：OK");
        } else {
            LogLine("初始化中止：内联钩子安装失败（序言解码不了或含相对跳转），安全退出");
        }
    }

    // ---- 聊天命令：挂聊天显示函数，实〔?〕@1/@2/@3 动态切〔?〕----
    InterlockedExchange(&g_mode, g_cfg.mode);
    LogLine("启动模式=%d(%s)，聊天命令=%s，前缀=\"%s\"，判定方=%s",
            (int)g_mode, ModeNameAscii((int)g_mode),
            g_cfg.chat_cmd ? "开" : "", g_cfg.chat_prefix,
            (g_cfg.filter_side == 0) ? "来源方" : ((g_cfg.filter_side == 1) ? "目标方" : "任一方"));
    InitChatHook();
    InitHotkeys();          // 热键：完全不走聊天，命令不会发给别人

    LogLine("初始化完成。进游戏打一次怪即可看到日志与消息。");
    LogLine("================================================================");
}

static DWORD WINAPI InitThreadProc(LPVOID)
{
    InitPaths(g_hSelf);
    DoInitialize();
    return 0;
}

//------------------------------------------------------------------------------
// 11. 导出
//------------------------------------------------------------------------------
extern "C" __declspec(dllexport) const char* __cdecl PluginName(void)
{
    return "UDamageWatcher";
}

extern "C" __declspec(dllexport) void __cdecl Initialize(void)
{
    if (InterlockedCompareExchange(&g_initState, 1, 0) != 0) return;
    HANDLE h = CreateThread(NULL, 0, InitThreadProc, NULL, 0, NULL);
    if (h) CloseHandle(h);
}

//------------------------------------------------------------------------------
// 12. DllMain
//------------------------------------------------------------------------------
BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH) {
        g_hSelf = hModule;
        DisableThreadLibraryCalls(hModule);
        InitPaths(hModule);

        InitializeCriticalSection(&g_logLock);
        InterlockedExchange(&g_logLockReady, 1);

        // 注意：配置读取（LoadConfig）不在这里做，而是在初始化线程里做〔?〕
        // 原因〔?〕DoInitialize 里的注释（loader lock 下做文件 IO 不稳）〔?〕

        // 兜底：Initialize() 没被调用时，3 秒后自己跑一〔?〕
        HANDLE t = CreateThread(NULL, 0, [](LPVOID) -> DWORD {
            Sleep(3000);
            if (InterlockedCompareExchange(&g_initState, 1, 0) == 0) {
                InitPaths(g_hSelf);
                DoInitialize();
            }
            return 0;
        }, NULL, 0, NULL);
        if (t) CloseHandle(t);
    } else if (reason == DLL_PROCESS_DETACH) {
        // 尽力把槽恢复回去，避〔?〕DLL 卸载后留下指向本模块的野指针
        if (g_hookedSlot && ORIG_DAMAGE && !IsBadReadPtr((const void*)(uintptr_t)g_hookedSlot, 4)) {
            uint32_t cur = *(volatile uint32_t*)(uintptr_t)g_hookedSlot;
            if (cur == (uint32_t)(uintptr_t)&OurDamageFunc && g_replace_pointer) {
                __try { g_replace_pointer(g_hookedSlot, (uint32_t)(uintptr_t)ORIG_DAMAGE); }
                __except (EXCEPTION_EXECUTE_HANDLER) { }
            }
        }
        // native 内联钩子：跳板开头就是被偷走的原始序言，直接抄回原处即可（否则卸载〔?〕
        // 引擎会跳到已释放的内存里）。失败也无所谓（进程本来就在退出）〔?〕
        if (g_nativeMode && g_nativeDmgTarget && g_nativeDmgStolen > 0 && ORIG_DAMAGE) {
            __try {
                DWORD oldProt = 0;
                if (VirtualProtect((void*)(uintptr_t)g_nativeDmgTarget, (SIZE_T)g_nativeDmgStolen,
                                   PAGE_EXECUTE_READWRITE, &oldProt)) {
                    memcpy((void*)(uintptr_t)g_nativeDmgTarget, (const void*)ORIG_DAMAGE,
                           (size_t)g_nativeDmgStolen);
                    VirtualProtect((void*)(uintptr_t)g_nativeDmgTarget, (SIZE_T)g_nativeDmgStolen,
                                   oldProt, &oldProt);
                    FlushInstructionCache(GetCurrentProcess(),
                                          (const void*)(uintptr_t)g_nativeDmgTarget,
                                          (size_t)g_nativeDmgStolen);
                }
            } __except (EXCEPTION_EXECUTE_HANDLER) { }
        }
    }
    return TRUE;
}
