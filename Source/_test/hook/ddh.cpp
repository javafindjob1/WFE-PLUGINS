//----------------------------------------------------------------------------
// ddh.cpp -- Damage Event Hook (32-bit DLL, injected into war3.exe)
//
// 目标：把引擎的伤害函�?game.dll+0x67DC40 的入口改�?6 字节的跳转补丁（jmp + NOP），
//       跳到我们自己�?__fastcall 替换函数 DdhDamageFunc；函数里先记前血 �?自己 call
//       原函数（跳板）→ 返回后立刻记后血 �?算本层掉血，返回值原样带回（�?UDamageWatcherHook.cpp 同款）�?
//
// 契约（来自本仓库 `伤害监视说明.md` §2，已源码 + 二进制双向复核）�?
//   uint32_t __fastcall DdhDamageFunc(uint32_t _this /*ecx=受伤单位*/,
//                                     uint32_t _edx,
//                                     uint32_t a2,        /* �? 调用方的 out（float*），出口写最终伤�?*/
//                                     war3_event_damage_data* info,
//                                     uint32_t is_physical,
//                                     uint32_t source_unit);   // ret 10h
//   v20 起，引擎伤害 / 最终伤�?/ 净掉血全部由这一个钩子的"出口三读"给出�?
//     出口 info+0x10 = 引擎算完的值（护甲/攻防类型/加成之后�?
//     出口 *a2       = 最终落地值（含地�?SetEventDamage 的改写；WFE 读的就是它）
//     前后血�?       = 净掉血
//   struct war3_event_damage_data {
//       uint32 source_unit;  // +0x00  来源单位【对象指针�?
//       uint32 weapon_type;  // +0x04
//       uint32 unk2;         // +0x08
//       uint32 flag;         // +0x0C  bit0=是否远程, bit8=是否攻击
//       uint32 amount;       // +0x10  伤害值（jass real �?�?float 解释�?
//       uint32 damage_type;  // +0x14  伤害类型位掩码（log2 - 1 = 类型号）
//       uint32 unk6, unk7;   // +0x18/+0x1C
//       uint32 attack_type;  // +0x20  攻击类型
//   };
//
// 原函数开头（`WFE伤害机制分析.md` §3.4 实机字节）：
//   55 8B EC 83 EC 2C 56 57 8B F9  �?push ebp; mov ebp,esp; sub esp,0x2C; push esi; push edi; mov edi,ecx
// �?6 字节正好�?3 条完整指令，所以搬走它们是安全的�?
//
// 事件通过**命名共享内存**交给外面�?64 位主程序（不写盘、不做文�?IO）�?
//----------------------------------------------------------------------------

#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <float.h>
#include <math.h>
#include <stdarg.h>

/* v9：热键（RegisterHotKey/GetMessage）和找游戏窗口（FindWindow）要�?user32�?
   build_hook.ps1 不额外传 lib，所以在这里�?pragma 带上�?*/
#pragma comment(lib, "user32.lib")

/* 统一�?_snprintf_s + _TRUNCATE 组装字符串，取代 sprintf_s 及各�?_s 变体�?
   缓冲区不够时只“截断”，绝不调无效参数处理器�?
   为什么：UCRT �?sprintf_s 在“放不下”时�?_invoke_watson �?__fastfail(FAST_FAIL_INVALID_ARG)�?
   宿主进程（war3.exe）当�?0xC0000409 崩掉 —�?2026-10-31 20:22:52 真机就是这么崩的�?
   长中文名 “……【辅助单位�?e009)�?被写�?64 字节的“名�?�?”标签�?*/
#define DdhSprintf(buf, cap, ...) _snprintf_s((buf), (cap), _TRUNCATE, __VA_ARGS__)

#define DDH_MAGIC     0x31484444u   /* "DDH1" */
/* v20：三个口径全部改�?0x67DC40 单个钩子�?出口三读"给出，不再挂 GetEventDamage / SetEventDamage�?
   v20 的记录在 v8 之后追加 8 字节：finalDamage(float) + finalFlags(uint32)�?
     引擎伤害 = 原函数退出时�?info+0x10（护�?攻防类型/加成之后，事件改写不回写它）
     最终伤�?= 原函数退出时�?*out�? 调用�?out 指针，也就是 WFE 读的那个数）
     净掉血   = 前后血差（不变�?
   �?JASS native 钩子保留，但默认关闭；要诊断"地图读了几次/改了几次"就设
   环境变量 DDH_NATIVE_DAMAGE_HOOKS=1�?*/
#define DDH_VERSION   35
#define DDH_SHM_SIZE  (1u << 20)     /* 1 MB */
#define DDH_MAX_EVENTS 512
#define DDH_MAXDEPTH  16      /* 伤害事件最大嵌套层数（地图�?DOT/追加伤害会套进来�?*/

static HWND g_gameWnd = NULL;

/* �?C# 端一一对应，pack(1) */
#pragma pack(push,1)
struct DdhHeader
{
    uint32_t magic;
    uint32_t version;
    uint32_t pid;
    uint32_t capacity;      /* 环容量（事件数） */
    uint32_t count;         /* 已写事件总数（递增�?*/
    uint32_t hookOk;        /* 1 = 挂钩成功 */
    uint32_t slotCount;     /* 打过�?vtbl 槽位数（备用方案用） */
    uint32_t gameDllBase;
    uint32_t hookRva;
    uint32_t selfTest;      /* 1 = 注入成功但还没看到伤害事�?*/
    uint32_t lastTick;
    uint32_t reserved[5];
};

struct DdhEvent
{
    uint32_t seq;
    uint32_t tickMs;
    uint32_t victim;        /* 受伤单位对象指针 */
    uint32_t victimCode;    /* +0x30 �?4 字节，原样（不翻转，外面统一处理�?*/
    uint32_t source;        /* info+0x00 来源单位对象指针 */
    uint32_t sourceCode;
    float    amount;        /* info+0x10 */
    uint32_t flag;          /* info+0x0C */
    uint32_t attackType;    /* info+0x20 */
    uint32_t damageMask;    /* info+0x14 */
    uint32_t weaponType;    /* info+0x04 */
    uint32_t isPhysical;
    uint32_t stackSource;   /* 栈参�?source_unit（这个构建里通常 0�?*/
    /* 名字字段：引擎原名是 **UTF-8** 字节串，0 结尾（真机日�?hex=E9 9B AA = 雪狼）�?
       v9 起各 64 字节（v8 �?32 字节会从汉字中间截断：末尾剩 E4 BD，C# 严格 UTF-8
       解不开、回退 GBK 就成了「鎶…鑳…」乱码）。写名字一律走 DdhUtf8SafeCopy：最�?
       63 字节 + NUL；截断点落在多字节字符中间时回退到该字符起始，绝不写半个汉字�?*/
    char     victimName[64];
    char     sourceName[64];
    /* ---- v3：血量（进程内直接读 CUnit 的生命链，不调任�?JASS�?---- */
    float    hpBefore;      /* 进入伤害函数时的血（地图触发还没跑�?*/
    float    hpAfter;       /* 原函数返回之后（地图增伤/减伤已经跑完�?*/
    float    actual;        /* 本层自己的掉血 = (hpBefore-hpAfter) - 内层子效果，下限 0 */
    uint32_t hpValid;       /* 1 = 前后血都读到了，actual 可信 */
    uint32_t depth;         /* 嵌套层号，从 1 开�?*/
    /* ---- v4：引擎伤害（地图第一次调�?GetEventDamage() 时的返回值） ---- */
    float    engineDamage;
    uint32_t engineValid;   /* 1 = 这次事件地图确实问过 GetEventDamage */
    /* ---- v20：原 v5 的两个槽（engineLast / engineCalls）改�?最终伤�?�?----
       �?布局一个字节都没变（还�?236 字节），只是语义换了�?
       来源 = `*a2`（调用方 out 指针，原函数 [ebp+8]）。它就是 WFE 读来画伤�?
       数字的那块内存：引擎�?+ 地图 SetEventDamage 的改写�?
       finalFlags�?
         bit0 = 1 �?本次确实掉了血（own > 0），值可�?
         bit1 = 1 �?与引擎值不�?�?地图改过伤害
         bit2 = 1 �?�?剩余血�?钳制（击杀溢出�?out = 前血，不是地图改伤害�?
       只在真掉血时才�?bit0：无�?[unit+0x5C]&0x100、免�?[+0x158]/[+0x15C]>0�?
       flags&4 这些早退分支根本不计算，直接把上一跳残留在 game+0xBB81D4 的值抄�?
       *out；那种情况下 own = 0，一律不认，避免把旧数字当成这次的地图伤害�?
       （�?DLL �?engineLast/engineCalls 语义�?v20 取消：默认不再挂
         GetEventDamage，C# 端同时按 v20 改读法。） */
    float    finalDamage;   /* �?engineLast 的槽 */
    uint32_t finalFlags;    /* �?engineCalls 的槽 */
    /* ---- v6：SetEventDamage 最后一次设的�?+ 调用次数（地图改伤害�?---
       设过 0.00 也算设过（设�?0 即有效），没设过�?0/0�?*/
    float    setDamage;
    uint32_t setCalls;
    /* ---- v7：目标单位蝗虫（马甲）标�?---- */
    uint32_t flags;         /* bit0 = 目标带蝗�?Aloc（马甲，不进死亡结算�?*/
    /* ---- v8：victimOwner/sourceOwner = CUnit+0x58 player slot (-1 = unknown) ---- */
    int32_t  victimOwner;
    int32_t  sourceOwner;
};
#pragma pack(pop)

#define DDH_EVENT_FLAG_VICTIM_ILLUSION (1u << 1)
#define DDH_EVENT_FLAG_SOURCE_ILLUSION (1u << 2)
#define DDH_EVENT_FLAG_VICTIM_HERO     (1u << 3)
#define DDH_EVENT_FLAG_SOURCE_HERO     (1u << 4)
#define DDH_EVENT_FLAG_SOURCE_LOCUST   (1u << 5)

/* ===========================================================================
   v11/v12：单位属性请�?/ 响应（【战场单位】页用）
   ---------------------------------------------------------------------------
   放在现有事件 ring **之后**的独立区域，v9 及以前的事件布局一个字节都不动�?
   C# 先读 hdr.version�?= 10 才按下面的偏移去碰属性块（�?DLL 就整块跳过）�?
   seq 也在块首，不塞进 DdhHeader，这�?DdhEvent 的偏移永远是 64�?

   DdhShared 布局（C# UnitAttrWire 严格按同一组偏移解析）�?
     +0       DdhHeader  hdr                         64 字节
     +64      DdhEvent   ev[512]                     512 * 236 = 120832 字节
     +120896  DdhAttrBlock attrs                     20360 字节
     合计 141256 字节（共享内�?1 MB，绰绰有余）
     �?v20 只改 engineLast/engineCalls 两个槽的语义（→ finalDamage/finalFlags），
       记录长度仍是 236，上面这些偏移一个都没动�?

   DdhAttrBlock 布局�?
     +0      uint32_t     requestSeq                 C# 递增（先�?96 �?unitAddr 写好后）
     +4      uint32_t     doneSeq                    ddh 处理完写 = requestSeq
     +8      uint32_t     unitAddr[96]               请求槽（C# 填；0 = 空槽�?
     +392    DdhUnitAttr  attr[96]                   响应槽（每个 208 字节�?

   DdhUnitAttr 布局（pack(1)�?08 字节）：
     +0      uint32_t addr
     +4      uint32_t flags                          DDH_AF_*�? = 该字段有�?
     +8      char     typeCode[5]                    4 字符�?+ NUL（已翻正，可直接显示�?
     +13     char     name[64]                       单位名（UTF-8�? 结尾�?
     +77     char     title[64]                      Propernames 专名（UTF-8；空 = 无专名）
     +141    float    attackRange                    攻击范围
     +145    float    damageMin                      攻击力下�?
     +149    float    damageMax                      攻击力上�?
     +153    float    attackInterval                 攻击间隔（秒�?
     +157    float    armor                          护甲
     +161    float    moveSpeed                      移�?
     +165    float    attackSpeed                  v35: unit_property+0x1B0 (RateOfFire)
     +169    float    acquireRange                 主动攻击范围
     +173    float    baseSpeed                    UnitBalance spd（基础速度�?
     +177    float    sightDay                      �?协议 v14：白天视�?= jass.slk �?sight
     +181    float    sightNight                    �?协议 v14：夜晚视�?= jass.slk �?nsight
     +185    int32_t  baseArmor                      UnitBalance def（基础护甲�?
     +189    uint8_t  pad[3]                         对齐�?192
     +192    float    strength                      力量（GetHeroStr，仅英雄�?
     +196    float    agility                       敏捷（GetHeroAgi，仅英雄�?
     +200    float    intelligence                  智力（GetHeroInt，仅英雄�?
     +204    int32_t  extraValue                    单位附加值（GetUnitUserData�?
     末尾 = 208（v11 �?v10 �?192 字节后面追加 16 字节；前 192 字节偏移全不变）
   =========================================================================== */

#define DDH_ATTR_MAX        96       /* v12�?4 �?96（共享内存富余；C# 轮询全部单位�?*/
#define DDH_ATTR_TTL_MS     3000u    /* v12：每单位解析结果缓存 3 秒（C# �?1 秒问一轮，避免刚拿到就被重算） */
/* game_units is built from the damage-event cache; do not run the old
   shared-memory unit-property request scan. */
#define DDH_ENABLE_BATTLEFIELD_UNITS 0
#define DDH_BATTLEFIELD_UNITS_NAME_ONLY 1

#define DDH_AF_TYPECODE     0x00000001u
#define DDH_AF_NAME         0x00000002u
#define DDH_AF_TITLE        0x00000004u
#define DDH_AF_ATTACKRANGE  0x00000008u
#define DDH_AF_DAMAGE       0x00000010u   /* damageMin / damageMax 一�?*/
#define DDH_AF_INTERVAL     0x00000020u
#define DDH_AF_ARMOR        0x00000040u
#define DDH_AF_MOVESPEED    0x00000080u
#define DDH_AF_SIGHT        0x00000100u   /* �?sight 字段（v14 起不再置位，保留定义兼容�?*/
#define DDH_AF_ACQUIRE      0x00000200u
#define DDH_AF_BASE_SPEED   0x00000400u   /* +173 float：UnitBalance spd（基础速度�?*/
#define DDH_AF_SIGHT_DAY    0x00000800u   /* 协议 v14�?177 float = jass.slk sight（白天视野） */
#define DDH_AF_SIGHT_NIGHT  0x00001000u   /* 协议 v14�?181 float = jass.slk nsight（夜晚视野） */
#define DDH_AF_BASE_ARMOR   0x00002000u   /* +185 int32：UnitBalance def（基础护甲�?*/
#define DDH_AF_HEROKNOWN    0x00004000u   /* 英雄判定可信 */
#define DDH_AF_HERO         0x00008000u   /* 1 = 英雄�? = 非英�?*/
/* v11 追加字段�?192 起）�?x4000/0x8000 已被英雄位占用，所以从 0x10000 �?*/
#define DDH_AF_STR          0x00010000u   /* +192 float：力量（GetHeroStr，仅英雄�?*/
#define DDH_AF_AGI          0x00020000u   /* +196 float：敏捷（GetHeroAgi，仅英雄�?*/
#define DDH_AF_INT          0x00040000u   /* +200 float：智力（GetHeroInt，仅英雄�?*/
#define DDH_AF_EXTRA        0x00080000u   /* +204 int32：单位附加值（GetUnitUserData；界面已不显示） */
#define DDH_AF_LOCUST       0x00100000u   /* 协议 v14：该单位�?Aloc（蝗虫）�?战场单位不显�?*/
#define DDH_AF_ILLUSION     0x00200000u
#define DDH_AF_ATTACK_SPEED 0x01000000u
#define DDH_AF_ILLUSION_CHECKED 0x00800000u

#pragma pack(push,1)
struct DdhUnitAttr
{
    uint32_t addr;
    uint32_t flags;
    char     typeCode[5];
    char     name[64];
    char     title[64];
    float    attackRange;
    float    damageMin;
    float    damageMax;
    float    attackInterval;
    float    armor;
    float    moveSpeed;
    float    attackSpeed;     /* protocol v35: unit_property+0x1B0 (RateOfFire) */
    float    acquireRange;
    float    baseSpeed;       /* spd    */
    float    sightDay;        /* 协议 v14：白天视�?= jass.slk sight（slk 取不到时退�?0x3ADF0�?*/
    float    sightNight;      /* 协议 v14：夜晚视�?= jass.slk nsight（取不到 �?无效，界�??�?*/
    int32_t  baseArmor;       /* def    */
    uint8_t  pad[3];
    /* ---- v11 追加（前 192 字节偏移一个都不动�?--- */
    float    strength;        /* GetHeroStr(handle, 0)：仅英雄 */
    float    agility;         /* GetHeroAgi(handle, 0)：仅英雄 */
    float    intelligence;    /* GetHeroInt(handle, 0)：仅英雄 */
    int32_t  extraValue;      /* GetUnitUserData(handle) */
};

struct DdhAttrBlock
{
    uint32_t    requestSeq;
    uint32_t    doneSeq;
    uint32_t    unitAddr[DDH_ATTR_MAX];
    DdhUnitAttr attr[DDH_ATTR_MAX];
};
#pragma pack(pop)

/* v12 协议长度钉死：单�?= 192 + 4*4 = 208；块 = 8 + 96*4 + 96*208 = 20360�?
   改结构忘了同步常量时，这里会直接编译失败，而不是等 C# 整列显示 ?�?*/
typedef char DdhUnitAttrSizeIs208[(sizeof(DdhUnitAttr) == 208) ? 1 : -1];
typedef char DdhAttrBlockSizeIs20360[(sizeof(DdhAttrBlock) == 20360) ? 1 : -1];

#define DDH_ATTR_BLOCK_OFFSET ((uint32_t)(sizeof(DdhHeader) + DDH_MAX_EVENTS * sizeof(DdhEvent)))
#define DDH_ATTR_RESP_OFFSET  (8u + DDH_ATTR_MAX * 4u)
#define DDH_ATTR_BLOCK_SIZE   (DDH_ATTR_RESP_OFFSET + DDH_ATTR_MAX * (uint32_t)sizeof(DdhUnitAttr))

/* ===========================================================================
   v15：游戏内阵亡面板 / 英雄查询（追加在属性块之后�?
   ---------------------------------------------------------------------------
   布局（C# InGamePanelWire 严格按同一组偏移解析）�?
     +0        DdhHeader      hdr                       64
     +64       DdhEvent       ev[512]                  120832
     +120896   DdhAttrBlock   attrs                     20360
     +141256   DdhPanelBlock  panel                      4952
     +146208   DdhHeroBlock   hero                        400
     合计 146608 字节（共享内�?1 MB）�?
   =========================================================================== */
#define DDH_PANEL_MAX_LINES   20
#define DDH_PANEL_LINE_TEXT   240
#define DDH_PANEL_FONT_NAME   32
#define DDH_HERO_SLOTS        16
#define DDH_ICON_MAX          4

/* v16：PanelBlock.flags 新增位（bit0/1 仍是显示/隐藏�?*/
#define DDH_PANEL_FLAG_SHOW       0x1u
#define DDH_PANEL_FLAG_HIDE       0x2u
#define DDH_PANEL_FLAG_BG         0x4u   /* bit2：启用背�?*/
#define DDH_PANEL_FLAG_COLLAPSED  0x8u   /* bit3：默认收�?*/
#define DDH_PANEL_FLAG_CHART     0x10u   /* bit4：面板块改作“承伤图表请求”，payload �?lines �?*/
#define DDH_CHART_MAGIC          0x31544843u   /* 'CHT1' */
#define DDH_PANEL_COLLAPSED_SHIFT 8      /* bit8..15：收起时显示的行数（0 => 3�?*/
#define DDH_PANEL_COLLAPSED_MASK  0xFFu

#pragma pack(push,1)
struct DdhPanelLine
{
    uint32_t color;                         /* 0xAARRGGBB（引�?SetTextColor 口径�?*/
    char     text[DDH_PANEL_LINE_TEXT];     /* UTF-8�? 结尾；C# 保证不切坏汉�?*/
};

struct DdhPanelBlock
{
    uint32_t    seq;            /* C# 每次新内�?+1（最后写�?*/
    uint32_t    appliedSeq;     /* ddh 拷出内容后写 = seq */
    uint32_t    flags;          /* bit0=显示，bit1=隐藏（hide 时不读文本） */
    uint32_t    ttlMs;          /* 自动隐藏毫秒�? => 默认 20000 */
    uint32_t    lineCount;      /* 1..DDH_PANEL_MAX_LINES */
    uint32_t    anchor;         /* 0..8（WC3 锚点枚举，默�?0=TOPLEFT�?*/
    float       x;              /* 屏幕比例（相对根帧，默认 0.60�?*/
    float       y;              /* 默认 -0.24 */
    float       lineHeight;     /* 默认 0.0175 */
    float       fontHeight;     /* 默认 0.0135 */
    char        fontName[DDH_PANEL_FONT_NAME];   /* 默认 MasterFont */
    DdhPanelLine lines[DDH_PANEL_MAX_LINES];
};

struct DdhHeroReq
{
    uint32_t addr;          /* 结算单位地址（仅回传用，可为 0�?*/
    uint32_t rawcode;       /* JASS 顺序�?4 字符类型码：'Hpal' = 0x4870616C */
};

struct DdhHeroRes
{
    uint32_t addr;
    uint32_t rawcode;
    int32_t  isHero;        /* 1=�?0=�?-1=native 暂时不可�?*/
    uint32_t pad;
};

struct DdhHeroBlock
{
    uint32_t    seq;
    uint32_t    appliedSeq;
    uint32_t    count;      /* 1..DDH_HERO_SLOTS */
    uint32_t    pad;
    DdhHeroReq  req[DDH_HERO_SLOTS];
    DdhHeroRes  res[DDH_HERO_SLOTS];
};

struct DdhIconSlot
{
    uint32_t lineIndex;     /* 0 基面板行�?*/
    uint32_t rawcode;       /* JASS 顺序类型�?*/
    uint32_t sourceAddr;    /* v19：伤害来�?CUnit*�?D 肖像�?*/
    uint32_t pad;
};

struct DdhIconBlock
{
    uint32_t    seq;
    uint32_t    appliedSeq;
    uint32_t    count;      /* 0..DDH_ICON_MAX */
    uint32_t    pad;
    DdhIconSlot slots[DDH_ICON_MAX];
};
#pragma pack(pop)

typedef char DdhEventSizeIs236[(sizeof(DdhEvent) == 236) ? 1 : -1];   /* v20 复用 engineLast/engineCalls 两个槽，长度不变 */
typedef char DdhPanelLineSizeIs244[(sizeof(DdhPanelLine) == 244) ? 1 : -1];
typedef char DdhPanelBlockSizeIs4952[(sizeof(DdhPanelBlock) == 4952) ? 1 : -1];
typedef char DdhHeroReqSizeIs8[(sizeof(DdhHeroReq) == 8) ? 1 : -1];
typedef char DdhHeroResSizeIs16[(sizeof(DdhHeroRes) == 16) ? 1 : -1];
typedef char DdhHeroBlockSizeIs400[(sizeof(DdhHeroBlock) == 400) ? 1 : -1];
typedef char DdhIconSlotSizeIs16[(sizeof(DdhIconSlot) == 16) ? 1 : -1];
typedef char DdhIconBlockSizeIs80[(sizeof(DdhIconBlock) == 80) ? 1 : -1];

#define DDH_PANEL_BLOCK_OFFSET (DDH_ATTR_BLOCK_OFFSET + DDH_ATTR_BLOCK_SIZE)
#define DDH_HERO_BLOCK_OFFSET  (DDH_PANEL_BLOCK_OFFSET + (uint32_t)sizeof(DdhPanelBlock))
#define DDH_ICON_BLOCK_OFFSET  (DDH_HERO_BLOCK_OFFSET + (uint32_t)sizeof(DdhHeroBlock))

struct DdhShared
{
    DdhHeader    hdr;
    DdhEvent     ev[DDH_MAX_EVENTS];
    DdhAttrBlock attrs;          /* v10：属性请�?响应（事�?ring 之后的独立区域） */
    DdhPanelBlock panel;         /* v15：游戏内阵亡面板（属性块之后�?*/
    DdhHeroBlock  hero;          /* v15：英雄查询（面板块之后） */
    DdhIconBlock  icons;         /* v17：伤害来源头像（英雄块之后） */
};

static HANDLE         g_map = NULL;
static DdhShared*     g_shm = NULL;
extern uint32_t       g_modBase;
static HANDLE         g_instanceMutex = NULL;
static bool           g_duplicateInstance = false;
/* 事件完成标记：入口先清 0，出口字段全部补完后置 1。
   写库线程只认这个标记，不靠事件年龄猜。 */
static volatile LONG  g_evReady[DDH_MAX_EVENTS];
static bool DdhReadMapName(char* out, size_t cap);
static size_t DdhUtf8SafeCopy(char* dst, size_t cap, const char* src, size_t maxBytes);
static bool DdhCachedTitleByCode(uint32_t code, char* out, size_t cap);

struct DdhEventUnitCombat
{
    uint32_t flags;
    float attackRange;
    float damageMin;
    float damageMax;
    float armor;
    float attackInterval;
    float attackSpeed;
};

static bool DdhReadCUnitCombat(uint32_t unit, DdhEventUnitCombat* out);
#include "ddh_sqlite.inc"
static HMODULE        g_self = NULL;

extern "C" int DdhGetCurrentSessionId(char* out, int capacity)
{
    if (!out || capacity <= 0) return 0;
    DdhDbSessionKey session = DdhDbCurrentSession();
    if (session.ctx == 0 && session.game == 0)
    {
        out[0] = 0;
        return 0;
    }
    strncpy_s(out, (size_t)capacity, session.id, _TRUNCATE);
    return 1;
}

static uint8_t*       g_hookAt = NULL;      /* game.dll + 0x67DC40 */
static uint8_t*       g_tramp = NULL;       /* 搬走的前 6 字节 + jmp 回去 */
static const uint32_t HOOK_RVA = 0x67DC40;
static uint8_t        g_saved[8];
static bool           g_hooked = false;
static uint32_t       g_foundRva = 0;
static char           g_hookLastError[192] = { 0 };
static char           g_hookKnownBytes[96] = { 0 };

/* ---- v3：嵌套层次的状态（伤害只在游戏线程上发生，用栈式数组即可） ---- */
static volatile LONG  g_depth = 0;                    /* 当前嵌套深度�? = 不在伤害函数里） */
static uint32_t       g_slot[DDH_MAXDEPTH];            /* 本层事件在环里的下标 */
static uint32_t       g_seq[DDH_MAXDEPTH];             /* 本层事件序号（防环覆盖写错行�?*/
static uint32_t       g_levelTick[DDH_MAXDEPTH];       /* 本层入口时间（防 SEH 展开把深度漏掉） */
static uint32_t       g_hpCount = 0;                   /* 成功读到前后血的事件数（诊断用�?*/

/* ---- v13：子伤害�?*调用�?*累计，且只扣同一个目标（victim�?---
   旧版每层只有一�?g_childSum：多目标 AoE 时，内层打别人（典韦/步兵）的掉血
   也被扣到本层头上 —�?外层打张飞掉 28.13，显示成 1.87；正确是 22.50�?
   现在每进一次伤害函数压一帧，退帧时�?
       own = (hpBefore - hpAfter) - childSumSameVictim
   childSumSameVictim 只累计“victim 地址与本帧相同”的子帧退帧时上报�?gross
   （hpBefore - hpAfter）；不同目标的子帧只记自己的事件，不扣本帧�?
   帧栈�?= 事件层深 DDH_MAXDEPTH；越界由 DdhDamageFunc �?d > DDH_MAXDEPTH
   的旧退化分支兜住（只提示一次日志）�?*/
typedef struct DdhFrame
{
    uint32_t victim;              /* 本帧目标单位地址（CUnit*�?*/
    uint32_t depth;               /* 1 基层号（= level + 1，与事件 depth 字段同义�?*/
    uint32_t hpOk;                /* 前血是否读到�? = 没测到，本帧不算 own�?*/
    uint32_t active;              /* 帧是否还在栈上（退帧后�?0，防误用�?*/
    float    hpBefore;            /* 进入伤害函数时读到的血 */
    float    hpAfter;             /* 原函数返回后读到的血 */
    float    childSumSameVictim;  /* 已退栈、victim 与本帧相同的子帧 gross 合计 */
    uint32_t childCountSame;      /* 同目标子帧笔数（日志用） */
} DdhFrame;
static DdhFrame       g_frames[DDH_MAXDEPTH];          /* 帧栈：下�?= 层号 */
static volatile LONG  g_nestedLogCount = 0;            /* “嵌套扣减”日志只写前 3 �?*/
static volatile LONG  g_depthOverflowLogged = 0;       /* 栈深溢出只提示一�?*/

/* ---- 原伤害函数跳板：�?UDamageWatcherHook.cpp �?ORIG_DAMAGE 同款 ----
   安装时把 0x67DC40 �?6 字节搬进可执行内�?+ E9 跳回，跳板地址存这里；
   DdhDamageFunc �?call 这个跳板 = 跑原函数体，原函数结�?ret 0x10 回到我们�?*/
typedef uint32_t (__fastcall *fn_damage_t)(uint32_t _this, uint32_t _edx, uint32_t a2,
                                           void* info, uint32_t is_physical, uint32_t source_unit);
static volatile LONG  g_original_damage = 0;


/* ---- v4：引擎伤害（GetEventDamage 首次调用�?---- */
static uint32_t g_engineCap[DDH_MAXDEPTH];            /* 每层第一次抓到的引擎伤害（float 位模式） */
static uint32_t g_engineFirstSet[DDH_MAXDEPTH];       /* 每层首次值是否已抓到�? 也是合法值，不能�?0 当哨兵） */
static uint32_t g_engineLast[DDH_MAXDEPTH];           /* 每层**最后一�?*抓到的�?*/
static uint32_t g_engineCalls[DDH_MAXDEPTH];          /* 每层 GetEventDamage 被调用了几次 */
static volatile LONG g_gedTries = 0;
static volatile LONG g_gedHooked = 0;
static uint32_t g_realGetEventDamage = 0;
/* ---- SetEventDamage（地图改伤害�?--- */
static uint32_t g_setCap[DDH_MAXDEPTH];            /* 每层**最后一�?* SetEventDamage 设的值（float 位模式） */
static uint32_t g_setSet[DDH_MAXDEPTH];            /* 每层是否设过�? 也是合法 SetEventDamage(0)，不能拿 0 当哨兵） */
static uint32_t g_setCalls[DDH_MAXDEPTH];          /* 每层 SetEventDamage 被调用了几次 */
static volatile LONG g_sedTries = 0;
static volatile LONG g_sedHooked = 0;
static uint32_t g_realSetEventDamage = 0;
/* v20：JASS native 钩子（GetEventDamage / SetEventDamage）默�?*不再安装**�?
   0x67DC40 �?出口三读"已经能同时给�?引擎伤害（出�?info+0x10）�?
   最终伤害（出口 *out）和 净掉血（前后血差），不需要再去遍�?JASS 哈希表�?
   也不用赌 JAPI 在进图前是否就绪（那正是老实现最脆弱的一环）�?
   只有想诊�?地图读了几次、改了几�?时才用环境变量打开�?
       set DDH_NATIVE_DAMAGE_HOOKS=1 */
static int g_nativeHooks = -1;                        /* -1 = 还没读环境变�?*/
static bool NativeDamageHooksOn(void)
{
    if (g_nativeHooks < 0)
    {
        char v[16] = { 0 };
        const DWORD n = GetEnvironmentVariableA("DDH_NATIVE_DAMAGE_HOOKS", v, (DWORD)sizeof(v));
        const char c = (n > 0 && (size_t)n < sizeof(v)) ? v[0] : '\0';
        g_nativeHooks = (c == '1' || c == 'y' || c == 'Y') ? 1 : 0;
    }
    return g_nativeHooks != 0;
}
static LARGE_INTEGER g_qpcFreq;                       /* 伤害函数耗时（诊断用�?*/
static LARGE_INTEGER g_qpcStart[DDH_MAXDEPTH];
static volatile LONG g_hpLogCount = 0;
static bool           g_namesEnabled = true;   /* 查单位名（失败会自动退回类型码�?*/

static char           g_mapName[128];
static int            g_logEnabled = 0;   /* 1 = 写日志（发布包默认关闭，放 ddh_log.on 打开） */
static char           g_logPath[MAX_PATH];

static void LogLine(const char* fmt, ...);

/* ---- master 的 KK 风格覆盖层与 ImGui 光标层 ---- */
extern "C" void DdhOverlayInit(HWND gameWnd);
extern "C" int  DdhOverlayHitTest(int x, int y);
extern "C" int  DdhOverlayFrames(void);
extern "C" int  DdhOverlayMouseDown(void);
extern "C" void DdhOverlaySetMouseDown(int down);
extern "C" void DdhOverlayToggle(void);
extern "C" void DdhOverlayShow(int on);
extern "C" int  DdhOverlayVisible(void);
extern "C" int  DdhOverlayProven(void);
extern "C" void DdhOverlaySetHtml(const char* html);
extern "C" int  DdhOverlayCursorOver(void);
extern "C" void DdhOverlayShowCursor(void);
extern "C" void DdhOverlayCursorSet(int over);
extern "C" int  DdhOverlayReady(void);
extern "C" void DdhOverlaySyncPosition(void);
extern "C" const char* DdhOverlayMarkerText(void);
extern "C" int  DdhImGuiActive(void);
extern "C" void DdhImGuiInit(HWND gameWindow);
extern "C" int  DdhImGuiWndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp);

/* 固定打开 ddh_web 目录下的 dss.html。 */
static char g_ddhHtmlPath[MAX_PATH] = { 0 };
static const char* DdhOverlayHtmlPath(void)
{
    _snprintf_s(g_ddhHtmlPath, sizeof(g_ddhHtmlPath), _TRUNCATE,
                "C:\\launch\\ddh_web\\dss.html");
    return g_ddhHtmlPath;
}

static volatile LONG g_ddhOverlayInitTried = 0;

extern "C" void DdhOverlayLog(const char* fmt, ...)
{
    char buf[512] = { 0 };
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(buf, sizeof(buf), _TRUNCATE, fmt, ap);
    va_end(ap);
    LogLine("%s", buf);
}

static void LogLine(const char* fmt, ...)
{
    if (!g_logEnabled) return;
    if (g_logPath[0] == 0) return;
    /* 用 CreateFile 显式带 FILE_SHARE_READ|WRITE：外部工具可在游戏运行时读取日志，
       否则 fopen 的独占句柄会让 PowerShell 读不到（之前就是这个问题）。 */
    HANDLE h = CreateFileA(g_logPath, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE,
                           NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return;

    char buf[2048];
    SYSTEMTIME st; GetLocalTime(&st);
    int n = _snprintf_s(buf, sizeof(buf), _TRUNCATE, "[%02d:%02d:%02d.%03d] ",
                        st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    if (n < 0) n = 0;
    va_list ap; va_start(ap, fmt);
    int m = _vsnprintf_s(buf + n, sizeof(buf) - n, _TRUNCATE, fmt, ap);
    va_end(ap);
    if (m < 0) m = 0;
    n += m;
    if (n < (int)sizeof(buf) - 2) { buf[n++] = '\r'; buf[n++] = '\n'; }

    DWORD written = 0;
    WriteFile(h, buf, (DWORD)n, &written, NULL);
    CloseHandle(h);
}


/* ---- v13：帧栈压�?/ 退栈（子伤害只扣同一个目标）----
   Push：进入伤害函数、读到前血之后调用；Push 会把该层的帧状态整个重置�?
   Pop ：原函数返回、读到后血之后调用，做三件事：
     �?own = (hpBefore - hpAfter) - childSumSameVictim（只减同目标子帧）；
     �?把本�?gross 加到父帧�?childSumSameVictim�?*仅当父帧 victim == 本帧 victim**�?
     �?返回“本帧是否测到血”（事件 hpValid/actual 用）�?
   fallback 保留旧语义：本帧读不到血时用引擎伤害估一个交给父帧，避免父帧 over-count�?
   它同样只在“父�?victim == 本帧 victim”时才加�?*/
static DdhFrame* DdhFramePush(uint32_t level, uint32_t victim, float hpBefore, uint32_t hpOk)
{
    if (level >= DDH_MAXDEPTH) return NULL;      /* 栈上限保护：绝不越界�?*/
    DdhFrame* f = &g_frames[level];
    f->victim             = victim;
    f->depth              = level + 1;
    f->hpOk               = hpOk ? 1u : 0u;
    f->active             = 1u;
    f->hpBefore           = hpBefore;
    f->hpAfter            = 0.0f;
    f->childSumSameVictim = 0.0f;
    f->childCountSame     = 0;
    return f;
}

static bool DdhFramePop(DdhFrame* f, uint32_t rowOk, float hpAfter, uint32_t hpAfterOk,
                        float fallback, float* outGross, float* outOwn)
{
    float gross = 0.0f, own = 0.0f;
    bool measured = false;

    if (f && f->active && rowOk && f->hpOk && hpAfterOk && f->hpBefore > 0.0f)
    {
        gross = f->hpBefore - hpAfter;             /* 本帧整段掉血（含更深的同目标子帧�?*/
        if (gross < 0.0f) gross = 0.0f;
        own = gross - f->childSumSameVictim;       /* 自己�?= 整段 - 同目标子�?*/
        if (own < 0.0f) own = 0.0f;
        f->hpAfter = hpAfter;
        measured = true;
    }

    /* 报给父帧：正常用整段 gross；本帧读不到血时退回引擎伤害估一个（旧语义）�?
       关键：只有父�?victim 与本帧相同时才扣 —�?多目�?AoE 里打典韦/步兵�?
       子事件不会把张飞（父帧）�?net 扣掉�?*/
    float toParent = measured ? gross : (fallback > 0.0f ? fallback : 0.0f);
    if (f && f->active && f->depth > 1 && toParent > 0.0f)
    {
        DdhFrame* parent = &g_frames[f->depth - 2];
        if (parent->active && parent->victim == f->victim)
        {
            parent->childSumSameVictim += toParent;
            parent->childCountSame++;
        }
    }
    if (f) f->active = 0;

    /* �?3 次“有同目标子伤害”的事件留一行，方便真机核对父帧净掉血 */
    if (measured && f->childCountSame > 0 &&
        InterlockedIncrement(&g_nestedLogCount) <= 3)
    {
        LogLine("嵌套扣减：父=0x%08X 子合计=%.2f（同目标 %u 笔）own=%.2f",
                f->victim, f->childSumSameVictim, f->childCountSame, own);
    }

    if (outGross) *outGross = gross;
    if (outOwn)   *outOwn   = own;
    return measured;
}

/* 读一个单位对象的 4 字符类型码（+0x30 的原�?4 字节）�?
   注意：内存里�?*反序**存的（显示时才翻转），这里保持原样交出去，由外面统一翻转�?*/
static uint32_t SafeCode(uint32_t obj)
{
    if (obj < 0x10000 || obj > 0x7FFFFFFF) return 0;
    __try { return *(const uint32_t*)(uintptr_t)(obj + 0x30); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

static uint32_t SafeU32(uint32_t obj, uint32_t off)
{
    if (obj < 0x10000 || obj > 0x7FFFFFFF) return 0;
    __try { return *(const uint32_t*)(uintptr_t)(obj + off); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

/* ---------------------------------------------------------------------------
   前后血只使用 GetUnitState(handle, UNIT_STATE_LIFE)：
       CUnit* -> handle
       GetUnitState = game.dll + 0x1E6600
       state 0 = 当前生命（float 位模式）
   失败时直接返回 false，不切换到 CUnit 生命表内存链。
   --------------------------------------------------------------------------- */
#define DDH_RVA_CTX_GLOBAL         0x00BE4238u  /* ctx = *(game.dll + RVA) */
#define DDH_RVA_OBJ_TO_HANDLE      0x002651D0u  /* __fastcall(mgr,0,obj,0) -> 句柄 */
#define DDH_RVA_HANDLE_TO_UNIT     0x001D1550u  /* __fastcall(handle,0) -> CUnit* */
#define DDH_RVA_HANDLEMGR_FROM_CTX 0x001C3200u  /* __fastcall(ctx,0) -> 句柄管理�?*/
#define DDH_RVA_GET_UNIT_STATE     0x001E6600u  /* __cdecl(handle,state) -> float bits */
#define DDH_OFF_CTX_HANDLEMGR      0x0000001Cu  /* ctx+0x1C = 句柄管理器指�?*/
#define DDH_OFF_MGR_COUNT          0x00000198u  /* mgr+0x198 = 条目�?3 */
#define DDH_OFF_MGR_TABLE          0x0000019Cu  /* mgr+0x19C = 句柄表基址 */
#define DDH_HANDLE_BASE            0x00100000u
#define DDH_HANDLE_LIMIT           0x00200000u


uint32_t g_modBase = 0;                        /* game.dll 基址（InstallHook 时填�?*/
static uint32_t g_imageSize = 0;               /* game.dll 映像大小（PE SizeOfImage；协�?v13 视野 RVA 校验用） */

/* ---- GetUnitState 读血的定型状态（对齐插件 g_nativeMgrWhich/g_nativeUseMemory�?--- */
static int           g_hpMgrWhich  = -1;   /* -1=未定 0=纯内�?(ctx+0x1C) 1=引擎访问�?x1C3200 2=放弃 */
static int           g_hpUseMemory = 0;    /* 0=调用 0x2651D0 1=纯内存扫描（定型后与口径绑定缓存�?*/
static volatile LONG g_hpObj2HTries = 0;   /* 四种组合都失败的累计次数（最�?16 次） */
static volatile LONG g_hpTypeFailLogged = 0; /* “定型失败”日志只写一�?*/
static volatile LONG g_hpSrcLogCount = 0;  /* “血量来源”日志只写前 3 �?*/


static int PeekU32(uint32_t addr, uint32_t* out);   /* 实现在本文件后面（JASS 哈希那段�?*/

typedef uint32_t (__fastcall* fn_hp_handle_to_unit)(uint32_t handle, void* unused);
typedef uint32_t (__fastcall* fn_hp_obj_to_handle)(uint32_t mgr, void* unused, uint32_t obj, uint32_t unused2);
typedef uint32_t (__fastcall* fn_hp_mgr_from_ctx)(uint32_t ctx, void* unused);
typedef uint32_t (__cdecl*    fn_hp_get_unit_state)(uint32_t handle, uint32_t state);

static uint32_t g_natHandleToUnit = 0;
static uint32_t g_natObjToHandle  = 0;
static uint32_t g_natMgrFromCtx   = 0;
static uint32_t g_natGetUnitState = 0;

/* �?RVA 解析一个引擎函数并做序言校验（可�?+ 非空实现 + 可�?3 字节序言），失败返回 0，由上层按读不到处理 */
static uint32_t HpResolve(uint32_t rva, const uint8_t* pro3)
{
    if (!g_modBase) return 0;
    const uint32_t addr = g_modBase + rva;
    uint32_t head = 0;
    if (!PeekU32(addr, &head)) return 0;
    const uint8_t* p = (const uint8_t*)&head;
    if (p[0] == 0x33 && p[1] == 0xC0 && p[2] == 0xC3) return 0;  /* xor eax,eax; ret 空实�?*/
    if (pro3 && (p[0] != pro3[0] || p[1] != pro3[1] || p[2] != pro3[2])) return 0;
    return addr;
}

static const uint8_t kPro3HandleToUnit[3] = { 0x55, 0x8B, 0xEC };  /* push ebp; mov ebp,esp */
static const uint8_t kPro3ObjToHandle[3]  = { 0x55, 0x8B, 0xEC };
static const uint8_t kPro3MgrFromCtx[3]   = { 0x83, 0x79, 0x1C };  /* cmp dword [ecx+0x1C],0 */
static const uint8_t kPro3GetUnitState[3] = { 0x55, 0x8B, 0xEC };

/* 句柄管理器两种口径：口径0 = 纯内�?*(ctx+0x1C)；口�? = 引擎访问�?0x1C3200(ctx) */
static uint32_t HpMgrFromCtx(uint32_t ctx, int which)
{
    if (!ctx) return 0;
    if (which == 0)
    {
        uint32_t v = 0;
        return PeekU32(ctx + DDH_OFF_CTX_HANDLEMGR, &v) ? v : 0;
    }
    if (!g_natMgrFromCtx)
        g_natMgrFromCtx = HpResolve(DDH_RVA_HANDLEMGR_FROM_CTX, kPro3MgrFromCtx);
    if (!g_natMgrFromCtx) return 0;
    uint32_t mgr = 0;
    __try { mgr = ((fn_hp_mgr_from_ctx)(uintptr_t)g_natMgrFromCtx)(ctx, NULL); }
    __except (EXCEPTION_EXECUTE_HANDLER) { mgr = 0; }
    return mgr;
}

/* JASS Hunit -> CUnit*，回程校验用，__fastcall ecx=handle */
static uint32_t HpHandleToUnit(uint32_t handle)
{
    if (!handle) return 0;
    if (!g_natHandleToUnit)
        g_natHandleToUnit = HpResolve(DDH_RVA_HANDLE_TO_UNIT, kPro3HandleToUnit);
    if (!g_natHandleToUnit) return 0;
    uint32_t obj = 0;
    __try { obj = ((fn_hp_handle_to_unit)(uintptr_t)g_natHandleToUnit)(handle, NULL); }
    __except (EXCEPTION_EXECUTE_HANDLER) { obj = 0; }
    return obj;
}

/* 对象 -> JASS 句柄（调用法，__fastcall ecx=mgr，栈�?obj，与插件同款�?*/
static uint32_t HpObj2HCall(uint32_t mgr, uint32_t obj)
{
    if (!mgr || !obj) return 0;
    if (!g_natObjToHandle)
        g_natObjToHandle = HpResolve(DDH_RVA_OBJ_TO_HANDLE, kPro3ObjToHandle);
    if (!g_natObjToHandle) return 0;
    uint32_t h = 0;
    __try {
        h = ((fn_hp_obj_to_handle)(uintptr_t)g_natObjToHandle)(mgr, NULL, obj, 0);
    } __except (EXCEPTION_EXECUTE_HANDLER) { h = 0; }
    return (h >= DDH_HANDLE_BASE && h < DDH_HANDLE_LIMIT) ? h : 0;
}

/* 对象 -> JASS 句柄（内存扫法，与插�?Wc3Obj2HMem 同款）：
   T=*(mgr+0x19C)，cnt=*(mgr+0x198)，for (i=0,k=0; i<min(cnt,0x9000); i+=3,++k)
   �?*(u32*)(T+4+i*4)==obj �?handle=0x100000+k�?*/
static uint32_t HpObj2HMem(uint32_t mgr, uint32_t obj)
{
    if (!mgr || !obj) return 0;
    uint32_t T = 0, cnt3 = 0;
    if (!PeekU32(mgr + DDH_OFF_MGR_TABLE, &T)) return 0;
    if (!PeekU32(mgr + DDH_OFF_MGR_COUNT, &cnt3)) return 0;
    if (!T || !cnt3 || cnt3 > 0x30000u) return 0;
    const uint32_t limit = (cnt3 < 0x9000u) ? cnt3 : 0x9000u;  /* 伤害回调里别做长扫描 */
    uint32_t h = 0;
    __try {
        for (uint32_t i = 0, k = 0; i < limit; i += 3, ++k)
            if (*(const uint32_t*)(uintptr_t)(T + 4u + i * 4u) == obj) { h = DDH_HANDLE_BASE + k; break; }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return h;
}

/* 对象 -> JASS 句柄（定型入口）：调用法/内存扫法 × 两种管理器口径，四种组合都用
   句柄回程校验�?x1D1550(handle)==obj）挑第一个通过者并定型缓存，之后直接走缓存路线�?
   四种组合都失败：日志写一次，之后仍可重试但最�?16 次，限次后返�?0，由 ReadUnitHp 转内存回退�?*/
static uint32_t HpObjToHandle(uint32_t obj)
{
    if (!obj) return 0;
    if (g_hpMgrWhich == 2) return 0;               /* 已判定用不了，直接返�?0 */
    if (!g_modBase) return 0;

    uint32_t ctx = 0;
    if (!PeekU32(g_modBase + DDH_RVA_CTX_GLOBAL, &ctx) || !ctx) return 0;

    /* 已定型：直接走既定路线（每次伤害只花一次调用，不再做四种尝�?回程校验�?*/
    if (g_hpMgrWhich >= 0)
    {
        const uint32_t mgr = HpMgrFromCtx(ctx, g_hpMgrWhich);
        if (!mgr) return 0;
        uint32_t h = g_hpUseMemory ? HpObj2HMem(mgr, obj) : HpObj2HCall(mgr, obj);
        if (h && HpHandleToUnit(h) == obj) return h;
        /* 定型的路径也可能在句柄表搬动/对象复用时拿到邻近单位：
           回程校验 handle->CUnit 必须等于本次 obj，否则换另一条路径再试，仍不对就返回 0，
           让上层按“没测到”处理，绝不把邻近单位的技能算到本对象头上。 */
        h = g_hpUseMemory ? HpObj2HCall(mgr, obj) : HpObj2HMem(mgr, obj);
        if (h && HpHandleToUnit(h) == obj) return h;
        return 0;
    }

    /* 首次定型：调用法/内存扫法 × 两种管理器口径，全部用句柄回程校验验证后定型 */
    for (int mem = 0; mem <= 1; ++mem)
    {
        for (int which = 0; which <= 1; ++which)
        {
            const uint32_t mgr = HpMgrFromCtx(ctx, which);
            if (!mgr) continue;
            const uint32_t h = mem ? HpObj2HMem(mgr, obj) : HpObj2HCall(mgr, obj);
            if (!h) continue;
            const uint32_t back = HpHandleToUnit(h);
            if (back == obj)
            {
                g_hpUseMemory = mem;
                g_hpMgrWhich  = which;
                LogLine("native obj->handle 定型：路径=%s 管理器口径=%s 首次 obj=%08X -> handle=%08X（回程校验一致）",
                        mem ? "纯内存扫描" : "调用 0x2651D0",
                        which ? "引擎访问�?x1C3200" : "纯内存*(ctx+0x1C)", obj, h);
                return h;
            }
        }
    }

    /* 四种组合都没通过回程校验：日志写一次，之后仍可重试但限次，限次后永久返�?0 */
    if (InterlockedExchange(&g_hpTypeFailLogged, 1) == 0)
        LogLine("native obj->handle 定型失败：四种组合回程校验都没过，后续走内存回退（两条都失败才显示 ?）");
    const LONG tries = InterlockedIncrement(&g_hpObj2HTries);
    if (tries >= 16)
        g_hpMgrWhich = 2;
    return 0;
}

/* GetUnitState: RVA 0x1E6600, state 0 = UNIT_STATE_LIFE. */
static bool HpGetUnitState(uint32_t handle, float* hpOut)
{
    if (!handle) return false;
    if (!g_natGetUnitState)
        g_natGetUnitState = HpResolve(DDH_RVA_GET_UNIT_STATE, kPro3GetUnitState);
    if (!g_natGetUnitState) return false;

    uint32_t bits = 0;
    __try { bits = ((fn_hp_get_unit_state)(uintptr_t)g_natGetUnitState)(handle, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    float hp = 0.0f;
    memcpy(&hp, &bits, 4);
    if (!(hp > -1.0e6f && hp < 1.0e9f)) return false;
    *hpOut = hp;
    return true;
}
/* 读血入口：只走 GetUnitState(handle, UNIT_STATE_LIFE)；失败直接返回 false（界面显示 ?）。 */
static bool ReadUnitHp(uint32_t unit, float* hpOut)
{
    if (unit < 0x10000 || unit > 0x7FFFFFFF || !hpOut) return false;
    const uint32_t handle = HpObjToHandle(unit);
    if (!handle || !HpGetUnitState(handle, hpOut)) return false;
    if (InterlockedIncrement(&g_hpSrcLogCount) <= 3)
    {
        LogLine("血量来源：GetUnitState unit=0x%08X handle=0x%08X hp=%.3f",
                unit, handle, (double)*hpOut);
    }
    return true;
}
/* ---------------------------------------------------------------------------
   引擎伤害 = 地图第一次调�?GetEventDamage() 的返回值（地图增伤/减伤之前）�?
   做法�?UDamageWatcherHook.cpp 完全一致：遍历 JASS native 函数哈希表，�?
   "GetEventDamage" 节点�?func_address_ 换成我们的函数，先调原实现、再抄返回值�?
     get_instance(5)        = game.dll RVA 0x4EFB0（__fastcall，ecx=index�?
     native 哈希�?         = instance + 0x18，buckets(+0x1C) / mask(+0x24)，每�?12 字节
     节点                   = +0x0C prev_ / +0x04 hash / +0x18 key(名字) / +0x1C func
   只有第一次调用被记录（之后地图可�?SetEventDamage 改过值）�?
   全程 __try 保护；JASS 没就�?找不到节点就什么都不做（界面上显示 ?）�?
--------------------------------------------------------------------------- */
static uint32_t HashRead4(const unsigned char* p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static uint32_t Wc3StringHash(const char* str)
{
    char buf[0x400];
    size_t len = 0;
    while (str[len] != '\0' && len < 0x3FF)
    {
        char c = str[len];
        if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
        else if (c == '/') c = '\\';
        buf[len++] = c;
    }
    const unsigned char* p = (const unsigned char*)buf;
    size_t rem = len;
    uint32_t A = 0x9E3779B9u, B = 0x9E3779B9u, C = 0u;
    if (rem >= 12)
    {
        size_t step = rem / 12;
        do
        {
            A += HashRead4(p + 0);
            B += HashRead4(p + 4);
            C += HashRead4(p + 8);
            A = (C >> 13) ^ (A - B - C); B = (A << 8)  ^ (B - C - A); C = (B >> 13) ^ (C - A - B);
            A = (C >> 12) ^ (A - B - C); B = (A << 16) ^ (B - C - A); C = (B >> 5)  ^ (C - A - B);
            A = (C >> 3)  ^ (A - B - C); B = (A << 10) ^ (B - C - A); C = (B >> 15) ^ (C - A - B);
            p += 12; rem -= 12;
        } while (--step != 0);
    }
    C = C + (uint32_t)len;
    switch (rem)
    {
        case 11: C += (uint32_t)p[10] << 24;
        case 10: C += (uint32_t)p[9]  << 16;
        case 9:  C += (uint32_t)p[8]  << 8;
        case 8:  B += (uint32_t)p[7]  << 24;
        case 7:  B += (uint32_t)p[6]  << 16;
        case 6:  B += (uint32_t)p[5]  << 8;
        case 5:  B += (uint32_t)p[4];
        case 4:  A += (uint32_t)p[3]  << 24;
        case 3:  A += (uint32_t)p[2]  << 16;
        case 2:  A += (uint32_t)p[1]  << 8;
        case 1:  A += (uint32_t)p[0];
            break;
        default: break;
    }
    A = (C >> 13) ^ (A - B - C); B = (A << 8)  ^ (B - C - A); C = (B >> 13) ^ (C - A - B);
    A = (C >> 12) ^ (A - B - C); B = (A << 16) ^ (B - C - A); C = (B >> 5)  ^ (C - A - B);
    A = (C >> 3)  ^ (A - B - C); B = (A << 10) ^ (B - C - A); C = (B >> 15) ^ (C - A - B);
    return C;
}

static int PeekU32(uint32_t addr, uint32_t* out)
{
    if (addr < 0x10000) return 0;
    __try { *out = *(const uint32_t*)(uintptr_t)addr; return 1; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

static uint32_t __cdecl OurFakeGetEventDamage(void);

/* 读当前地图名：ctx->mapInfo+4 的 CString -> 字符指针。
   只在 ddh 写库线程调用，不碰伤害钩子。 */
static bool DdhReadMapName(char* out, size_t cap)
{
    if (!out || cap < 2 || !g_modBase) return false;
    out[0] = 0;
    uint32_t ctx = 0, mapInfo = 0, data = 0, chars = 0;
    if (!PeekU32(g_modBase + 0x00BE4238u, &ctx) || !ctx) return false;
    if (!PeekU32(ctx + 0x30u, &mapInfo) || !mapInfo) return false;
    const uint32_t cstr = mapInfo + 4u;
    if (!PeekU32(cstr + 8u, &data) || !data) return false;
    if (!PeekU32(data + 0x1Cu, &chars) || !chars)
    {
        /* CString 相邻布局兜底 */
        static const uint32_t offs[4] = { 8u, 0u, 4u, 12u };
        for (int i = 0; i < 4; i++)
            if (PeekU32(data + offs[i], &chars) && chars) break;
    }
    if (!chars) return false;

    char raw[260] = { 0 };
    SIZE_T got = 0;
    if (!ReadProcessMemory(GetCurrentProcess(), (LPCVOID)(uintptr_t)chars, raw, sizeof(raw) - 1, &got) || got < 2)
        return false;
    raw[sizeof(raw) - 1] = 0;
    int len = 0;
    while (len < (int)got && raw[len] && len < 200) len++;
    if (len < 2) return false;

    wchar_t wide[260] = { 0 };
    /* 引擎里有的版本给 UTF-8，有的给 GBK：先按 UTF-8 严格校验，能过就原样用。 */
    bool utf8 = true;
    for (int i = 0; i < len; )
    {
        unsigned char c = (unsigned char)raw[i];
        int need = c < 0x80 ? 0 : (c & 0xE0) == 0xC0 ? 1 : (c & 0xF0) == 0xE0 ? 2 : (c & 0xF8) == 0xF0 ? 3 : -1;
        if (need < 0 || i + need >= len) { utf8 = false; break; }
        for (int k = 1; k <= need; k++)
            if (((unsigned char)raw[i + k] & 0xC0) != 0x80) { utf8 = false; break; }
        if (!utf8) break;
        i += need + 1;
    }
    if (utf8)
    {
        size_t n = (size_t)len < cap - 1 ? (size_t)len : cap - 1;
        memcpy(out, raw, n);
        out[n] = 0;
        return n >= 2;
    }

    int wlen = MultiByteToWideChar(936, 0, raw, len, wide, 259);
    if (wlen <= 0) wlen = MultiByteToWideChar(CP_UTF8, 0, raw, len, wide, 259);
    if (wlen <= 0) return false;
    wide[wlen] = 0;
    int n = WideCharToMultiByte(CP_UTF8, 0, wide, wlen, out, (int)cap - 1, NULL, NULL);
    if (n <= 0) return false;
    out[n] = 0;
    return true;
}

/* 地图每次�?GetEventDamage：先拿引擎真值，再抄一份（只抄第一次） */
static uint32_t __cdecl OurFakeGetEventDamage(void)
{
    uint32_t r = 0;
    if (g_realGetEventDamage)
    {
        __try { r = ((uint32_t (__cdecl*)(void))(uintptr_t)g_realGetEventDamage)(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    }
    const LONG d = g_depth;                       /* 1 �?*/
    if (d >= 1 && d <= DDH_MAXDEPTH)
    {
        float f;
        memcpy(&f, &r, 4);
        if (f > -1.0e12f && f < 1.0e12f)
        {
            if (!g_engineFirstSet[d - 1]) { g_engineCap[d - 1] = r; g_engineFirstSet[d - 1] = 1; }  /* 首次 = 增伤�?*/
            g_engineLast[d - 1] = r;                                                               /* 末次 = 地图改完之后 */
            InterlockedIncrement((volatile LONG*)&g_engineCalls[d - 1]);
        }
    }
    return r;
}

/* 懒安装：每次伤害事件试一次，最�?64 次（进图�?JASS 实例可能还没好） */
static void TryHookGetEventDamage(void)
{
    if (g_gedHooked) return;
    if (InterlockedIncrement(&g_gedTries) > 16) return;      /* 进图�?VM 可能没好；试 16 次就放弃 */
    if (!g_modBase) return;

    __try
    {
        typedef uint32_t (__fastcall* fn_gi_t)(uint32_t);
        uint32_t inst = ((fn_gi_t)(uintptr_t)(g_modBase + 0x004EFB0u))(5);
        if (inst < 0x10000) return;

        const uint32_t tbl = inst + 0x18u;
        uint32_t buckets = 0, mask = 0;
        if (!PeekU32(tbl + 0x1Cu, &buckets) || !PeekU32(tbl + 0x24u, &mask)) return;
        if (!buckets || mask == 0xFFFFFFFFu) return;

        const uint32_t hash = Wc3StringHash("GetEventDamage");
        const uint32_t entry = buckets + (hash & mask) * 12u;
        uint32_t node = 0;
        if (!PeekU32(entry + 8u, &node)) return;

        int guard = 0;
        while (node > 0x10000u && guard++ < 64)
        {
            uint32_t h = 0, key = 0;
            PeekU32(node + 0x04u, &h);
            PeekU32(node + 0x18u, &key);
            if (h == hash && key > 0x10000u && key < 0x7FFFFFFFu)
            {
                char name[64] = { 0 };
                __try
                {
                    for (int i = 0; i < 63; i++) { name[i] = *(const char*)(uintptr_t)(key + i); if (!name[i]) break; }
                }
                __except (EXCEPTION_EXECUTE_HANDLER) { name[0] = 0; }

                if (_stricmp(name, "GetEventDamage") == 0)
                {
                    uint32_t cur = 0;
                    if (!PeekU32(node + 0x1Cu, &cur)) return;
                    if (cur == (uint32_t)(uintptr_t)&OurFakeGetEventDamage) { g_gedHooked = 1; return; }
                    g_realGetEventDamage = cur;
                    uint32_t* func = (uint32_t*)(uintptr_t)(node + 0x1Cu);
                    DWORD oldProt = 0;
                    if (VirtualProtect(func, 4, PAGE_READWRITE, &oldProt))
                    {
                        *func = (uint32_t)(uintptr_t)&OurFakeGetEventDamage;
                        VirtualProtect(func, 4, oldProt, &oldProt);
                        g_gedHooked = 1;
                        LogLine("引擎伤害采集：GetEventDamage 钩子已挂（节点 %08X，原实现 %08X）", node, cur);
                    }
                    else LogLine("引擎伤害采集：VirtualProtect 失败 err=%lu", GetLastError());
                    return;
                }
            }
            uint32_t prev = 0;
            if (!PeekU32(node + 0x0Cu, &prev)) return;
            node = prev;
        }
        LogLine("引擎伤害采集：没找到 GetEventDamage 节点（hash=%08X mask=%08X buckets=%08X）", hash, mask, buckets);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        /* JASS 还没就绪�?get_instance 会踩�?—�?只记�?3 次，别刷�?*/
        if (g_gedTries <= 3) LogLine("引擎伤害采集：装钩子时异常 code=%08X", GetExceptionCode());
    }
}

/* ---------------------------------------------------------------------------
   地图伤害 = SetEventDamage 最后一次设置的值�?
   做法�?GetEventDamage 完全一致：遍历 JASS native 哈希表，�?"SetEventDamage"
   节点�?func_address_�?0x1C）换成我们的函数，先抄参数、再原样调原实现�?
   调用约定（依据仓库《无JAPI后端实装说明.md》�?.2 与《伤害监视说�?md》�? 实测）：
     魔兽 native �?real 参数 = **指向 float 的指�?*（JASS VM 传它自己 real 槽的地址），
     不是 float 位模式本�?—�?DisplayTimedTextToPlayer �?x/y/dur 反汇编里都是
     `mov eax,[ebp+0xC] ; movss xmm,[eax]`（先取指针、再解引用）�?
     GetEventDamage 无参数、返回值才�?float 位模式（eax 直传），二者不要混�?
     所�?SetEventDamage 的签名是 void __cdecl (float*)，实�?= 指向 4 字节 float 的指针�?
     全部 __try 保护；JASS 没就�?找不到节点就什么都不做（优雅退化）�?
---------------------------------------------------------------------------- */
static void __cdecl OurFakeSetEventDamage(float* damage);

static void __cdecl OurFakeSetEventDamage(float* damage)
{
    /* 先记录（只记本层、只记合理值），再原样调原函数 —�?绝不吞掉调用 */
    const LONG d = g_depth;                       /* 1 �?*/
    if (d >= 1 && d <= DDH_MAXDEPTH && damage)
    {
        float v = 0.0f;
        int ok = 0;
        __try { v = *damage; ok = 1; }
        __except (EXCEPTION_EXECUTE_HANDLER) { ok = 0; }
        if (ok && v > -1.0e12f && v < 1.0e12f)
        {
            const uint32_t lv = (uint32_t)(d - 1);

            /* �?SetEventDamage、从�?GetEventDamage 的图（Dota 就是这种）：
               在地�?*第一�?*改伤害之前，先把“引擎值”抄下来 —�?此刻还在事件里、值还没被改，
               GetEventDamage 拿到的就是“地图若读会读到的首值”。抄到之后照常让地图改�?
               这里不增�?g_engineCalls（取次仍如实反映“地图没读过”）�?*/
            if (!g_engineFirstSet[lv] && g_realGetEventDamage)
            {
                uint32_t r0 = 0;
                __try { r0 = ((uint32_t (__cdecl*)(void))(uintptr_t)g_realGetEventDamage)(); }
                __except (EXCEPTION_EXECUTE_HANDLER) { r0 = 0; }

                float f0 = 0.0f;
                memcpy(&f0, &r0, 4);
                if (f0 > 0.005f && f0 < 1.0e9f)      /* 0 多半是“还没算/拿不到”，别拿它冒�?*/
                {
                    g_engineCap[lv]      = r0;
                    g_engineFirstSet[lv] = 1;
                }
            }

            uint32_t bits = 0;
            memcpy(&bits, &v, 4);
            g_setCap[d - 1] = bits;                                        /* 末次 = 地图最后改成的�?*/
            g_setSet[d - 1] = 1;                                           /* 0 也是合法值，用独立标�?*/
            InterlockedIncrement((volatile LONG*)&g_setCalls[d - 1]);
        }
    }
    if (g_realSetEventDamage)
    {
        __try { ((void (__cdecl*)(float*))(uintptr_t)g_realSetEventDamage)(damage); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
}

/* 懒安装：每次伤害事件试一次，最�?16 次（进图�?JASS 实例可能还没好） */
static void TryHookSetEventDamage(void)
{
    if (g_sedHooked) return;
    const LONG sedTries = InterlockedIncrement(&g_sedTries);
    if (sedTries > 64)      /* 进图�?VM 可能没好；给�?64 次，且失败原因要看得�?*/
    {
        if (sedTries == 65)
            LogLine("引擎伤害采集：SetEventDamage 放弃安装（试了 64 次都没成功；失败原因见上面 SetEventDamage 安装失败 行）");
        return;
    }
    if (!g_modBase) return;

    __try
    {
        typedef uint32_t (__fastcall* fn_gi_t)(uint32_t);
        uint32_t inst = ((fn_gi_t)(uintptr_t)(g_modBase + 0x004EFB0u))(5);
        if (inst < 0x10000)
        {
            if (sedTries <= 3)
                LogLine("引擎伤害采集：SetEventDamage 安装失败（JASS 实例还没好 inst=%08X，第 %d 次）", inst, (int)sedTries);
            return;
        }

        const uint32_t tbl = inst + 0x18u;
        uint32_t buckets = 0, mask = 0;
        if (!PeekU32(tbl + 0x1Cu, &buckets) || !PeekU32(tbl + 0x24u, &mask))
        {
            if (sedTries <= 3)
                LogLine("引擎伤害采集：SetEventDamage 安装失败（native 表读不到 tbl=%08X，第 %d 次）", tbl, (int)sedTries);
            return;
        }
        if (!buckets || mask == 0xFFFFFFFFu)
        {
            if (sedTries <= 3)
                LogLine("引擎伤害采集：SetEventDamage 安装失败（buckets=%08X mask=%08X，第 %d 次）", buckets, mask, (int)sedTries);
            return;
        }

        const uint32_t hash = Wc3StringHash("SetEventDamage");
        const uint32_t entry = buckets + (hash & mask) * 12u;
        uint32_t node = 0;
        if (!PeekU32(entry + 8u, &node)) return;

        int guard = 0;
        while (node > 0x10000u && guard++ < 64)
        {
            uint32_t h = 0, key = 0;
            PeekU32(node + 0x04u, &h);
            PeekU32(node + 0x18u, &key);
            if (h == hash && key > 0x10000u && key < 0x7FFFFFFFu)
            {
                char name[64] = { 0 };
                __try
                {
                    for (int i = 0; i < 63; i++) { name[i] = *(const char*)(uintptr_t)(key + i); if (!name[i]) break; }
                }
                __except (EXCEPTION_EXECUTE_HANDLER) { name[0] = 0; }

                if (_stricmp(name, "SetEventDamage") == 0)
                {
                    uint32_t cur = 0;
                    if (!PeekU32(node + 0x1Cu, &cur)) return;
                    if (cur == (uint32_t)(uintptr_t)&OurFakeSetEventDamage) { g_sedHooked = 1; return; }
                    g_realSetEventDamage = cur;
                    uint32_t* func = (uint32_t*)(uintptr_t)(node + 0x1Cu);
                    DWORD oldProt = 0;
                    if (VirtualProtect(func, 4, PAGE_READWRITE, &oldProt))
                    {
                        *func = (uint32_t)(uintptr_t)&OurFakeSetEventDamage;
                        VirtualProtect(func, 4, oldProt, &oldProt);
                        g_sedHooked = 1;
                        LogLine("引擎伤害采集：SetEventDamage 钩子已挂（节点 %08X，原实现 %08X）", node, cur);
                    }
                    else LogLine("引擎伤害采集：VirtualProtect(SetEventDamage) 失败 err=%lu", GetLastError());
                    return;
                }
            }
            uint32_t prev = 0;
            if (!PeekU32(node + 0x0Cu, &prev)) return;
            node = prev;
        }
        LogLine("引擎伤害采集：没找到 SetEventDamage 节点（hash=%08X mask=%08X buckets=%08X）", hash, mask, buckets);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        /* JASS 还没就绪�?get_instance 会踩�?—�?只记�?3 次，别刷�?*/
        if (g_sedTries <= 3) LogLine("引擎伤害采集：SetEventDamage 装钩子时异常 code=%08X", GetExceptionCode());
    }
}

static int DdhIsHeroCode(uint32_t code);

/* ---- 真正的“记录一次伤害�?--- */
/* ---------------------------------------------------------------------------
   单位名解析（在游戏进程里直接问引擎要，不依赖任何插件）�?
   两级降级链，全部 __try、失败静默退下一级：
     �?主路�?x326BA0(code, 0) 直接返回【名字正�?char*】（插件 UDamageWatcherHook.cpp 实测结论），
        用插件同款校验（可读�? 结尾、无控制字符/0x7F、长�?1..63）；
     �?次选：JASS native GetUnitName（FindNativeFunc 动态定位，�?RVA 0x1E6340）—�?
        它内部就�?call 0x326BA0 再转【字符串 id】，返回值是 id 不是 char*�?
        本机反查不通，所以只留返回值做诊断、不再当 char* 读；
     �?都拿不到就退�?4 字符类型码（C# 端退回码）�?
   结果�?类型码→名字 缓存（每个码只解析一次）；失败也只记一次日志，别刷屏�?
--------------------------------------------------------------------------- */
struct NameCacheEntry { uint32_t code; char name[64]; };
static NameCacheEntry g_nameCache[128];
static int  g_nameCacheCount = 0;
static volatile LONG g_nameFailLogged = 0;    /* “名字解析失败”日志总上限，防刷�?*/

/* GetUnitName native 函数地址的懒解析缓存（最多找 16 次，进图�?JASS VM 可能没好�?*/
static uint32_t g_natGetUnitName = 0;
static volatile LONG g_gunTries = 0;

typedef const char* (__fastcall *fn_326BA0)(uint32_t code, uint32_t edxZero);

/* �?JASS native 哈希表里按名字找函数地址（与 TryHookGetEventDamage 同一套遍历）�?
   返回 0 表示没找�?没就绪。全�?__try 包着�?*/
static uint32_t FindNativeFunc(const char* name)
{
    if (!name || !g_modBase) return 0;
    uint32_t fn = 0;
    __try
    {
        typedef uint32_t (__fastcall* fn_gi_t)(uint32_t);
        uint32_t inst = ((fn_gi_t)(uintptr_t)(g_modBase + 0x004EFB0u))(5);
        if (inst < 0x10000) return 0;

        const uint32_t tbl = inst + 0x18u;
        uint32_t buckets = 0, mask = 0;
        if (!PeekU32(tbl + 0x1Cu, &buckets) || !PeekU32(tbl + 0x24u, &mask)) return 0;
        if (!buckets || mask == 0xFFFFFFFFu) return 0;

        const uint32_t hash = Wc3StringHash(name);
        const uint32_t entry = buckets + (hash & mask) * 12u;
        uint32_t node = 0;
        if (!PeekU32(entry + 8u, &node)) return 0;

        int guard = 0;
        while (node > 0x10000u && guard++ < 64)
        {
            uint32_t h = 0, key = 0;
            PeekU32(node + 0x04u, &h);
            PeekU32(node + 0x18u, &key);
            if (h == hash && key > 0x10000u && key < 0x7FFFFFFFu)
            {
                char nm[64] = { 0 };
                __try
                {
                    for (int i = 0; i < 63; i++) { nm[i] = *(const char*)(uintptr_t)(key + i); if (!nm[i]) break; }
                }
                __except (EXCEPTION_EXECUTE_HANDLER) { nm[0] = 0; }

                if (_stricmp(nm, name) == 0)
                {
                    uint32_t cur = 0;
                    if (PeekU32(node + 0x1Cu, &cur)) fn = cur;
                    return fn;
                }
            }
            uint32_t prev = 0;
            if (!PeekU32(node + 0x0Cu, &prev)) return 0;
            node = prev;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { fn = 0; }
    return fn;
}

static uint32_t GetUnitNameNative(void)
{
    if (g_natGetUnitName) return g_natGetUnitName;
    if (InterlockedIncrement(&g_gunTries) > 16) return 0;   /* 只找 16 次就放弃，别每笔都踩 */
    g_natGetUnitName = FindNativeFunc("GetUnitName");
    if (g_natGetUnitName)
        LogLine("名字解析：GetUnitName native 已定位（0x%08X）", g_natGetUnitName);
    return g_natGetUnitName;
}

/* 0x326BA0�? 字符�?-> 名字正文 char*（插�?UDamageWatcherHook.cpp L1123-1175 实测结论）�?
   序言 56 8B F2 = push esi; mov esi,edx。真 game.dll 0x326BA0 = 56 8B F2 BA F8 AC 98 6F ... */
#define DDH_RVA_CODE_TO_NAME   0x00326BA0u
static const uint8_t kPro3CodeToName[3] = { 0x56, 0x8B, 0xF2 };
static uint32_t g_natCodeToName = 0;

static uint32_t ResolveCodeToName(void)
{
    if (g_natCodeToName) return g_natCodeToName;
    g_natCodeToName = HpResolve(DDH_RVA_CODE_TO_NAME, kPro3CodeToName);
    return g_natCodeToName;
}

/* GetUnitAbilityLevel native：按名字�?JASS native 表里找（�?GetUnitName 同一�?FindNativeFunc）�?
   最多找 16 次（进图�?JASS VM 可能没好）；找到记一条，16 次后还没找到也只记一条�?*/
static uint32_t g_natGetUnitAbilityLevel = 0;
static volatile LONG g_gaulTries = 0;
static volatile LONG g_gaulFailLogged = 0;

static uint32_t GetUnitAbilityLevelNative(void)
{
    if (g_natGetUnitAbilityLevel) return g_natGetUnitAbilityLevel;
    const LONG tries = InterlockedIncrement(&g_gaulTries);
    if (tries > 16)
    {
        if (InterlockedCompareExchange(&g_gaulFailLogged, 1, 0) == 0)
            LogLine("蝗虫判定：GetUnitAbilityLevel native 未找到（已试 16 次），flags 按 0 处理");
        return 0;
    }
    g_natGetUnitAbilityLevel = FindNativeFunc("GetUnitAbilityLevel");
    if (g_natGetUnitAbilityLevel)
        LogLine("蝗虫判定：GetUnitAbilityLevel native 已定位（0x%08X）", g_natGetUnitAbilityLevel);
    return g_natGetUnitAbilityLevel;
}

/* 直接按逆向结果查技能等级：
   game.dll RVA 0x46F440 = 单位对象上的“按 ID 找技能”，返回技能对象；等级在 +0x50（0 基）。
   不经过 handle，避免 GetUnitAbilityLevel 前两道校验失败。 */
static int DdhAbilityLevelByObj(uint32_t obj, uint32_t abilityId)
{
    HMODULE gd = GetModuleHandleA("game.dll");
    if (!gd) gd = GetModuleHandleA("Game.dll");
    if (!gd || !obj) return -1;
    const uint32_t fn = (uint32_t)(uintptr_t)gd + 0x46F440u;
    typedef void* (__fastcall *fn_find_ability_t)(void* thisPtr, void* dummy, uint32_t id, int a3, int a4, int a5, int a6);
    void* abil = NULL;
    __try { abil = ((fn_find_ability_t)(uintptr_t)fn)((void*)(uintptr_t)obj, NULL, abilityId, 0, 1, 1, 1); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
    if (!abil) return 0;
    int level = 0;
    __try { level = *(const int*)((const char*)abil + 0x50) + 1; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
    return level;
}

/* Resolve CUnit+0x1DC and follow ability-node+0x24.
   Ability ID is stored at node+0x34. Returns 1=found, 0=not found, -1=failed. */
static int DdhAbilityInUnitList(uint32_t obj, uint32_t abilityId)
{
    if (!g_modBase || g_imageSize <= 0x00044150u) return -1;
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return -1;

    typedef uint32_t (__fastcall* fn_resolve_ref_t)(const uint32_t*, uint32_t);
    const fn_resolve_ref_t resolve =
        (fn_resolve_ref_t)(uintptr_t)(g_modBase + 0x00044150u);
    const uint32_t swapped =
        ((abilityId & 0x000000FFu) << 24) |
        ((abilityId & 0x0000FF00u) << 8) |
        ((abilityId & 0x00FF0000u) >> 8) |
        ((abilityId & 0xFF000000u) >> 24);

    __try
    {
        uint32_t node = resolve((const uint32_t*)(uintptr_t)(obj + 0x1DCu), 0);
        for (int i = 0; i < 512 && node; ++i)
        {
            if (node < 0x10000u || node > 0x7FFFFFFFu) return -1;
            const uint32_t id = *(const uint32_t*)(uintptr_t)(node + 0x34u);
            if (id == abilityId || id == swapped) return 1;

            const uint32_t next =
                resolve((const uint32_t*)(uintptr_t)(node + 0x24u), 0);
            if (next == node) break;
            node = next;
        }
        return 0;
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        return -1;
    }
}

/* IsUnitIllusion reads bit 30 of CUnit+0x5C. Return 1/0, or -1 if unreadable. */
static int DdhUnitIllusionStateByObj(uint32_t obj)
{
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return -1;
    uint32_t flags = 0;
    __try { flags = *(const uint32_t*)(uintptr_t)(obj + 0x5Cu); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
    return (flags & 0x40000000u) ? 1 : 0;
}


/* 通过 ydbase 的 jass_func(name) 拿 func_value*，再取 +0x10（ydbase 反编译结论）得到真函数地址。
   ydbase 没加载时返回 0。 */
/* 一次性探针：Game.dll 是否导出 WAR3API_GetTypeMemoryAddressByTypeId（平台插件就是调它取类型对象）。 */
/* War3Trainer 的选区链：module+BE4238 → unitList → a2 → player → +0x34 selection → +0x1F0 链表 → +8 单位指针 */
static uint32_t DdhSelectedUnitPtr(void)
{
    uint32_t list = 0, player = 0, sel = 0, head = 0;
    __try { list = *(const uint32_t*)(uintptr_t)(g_modBase + 0xBE4238u); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (list < 0x10000u) return 0;
    uint16_t a2 = 0;
    __try { a2 = *(const uint16_t*)(uintptr_t)(list + 0x28); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    __try { player = *(const uint32_t*)(uintptr_t)(list + 0x58 + 4u * a2); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (player < 0x10000u) return 0;
    __try { sel = *(const uint32_t*)(uintptr_t)(player + 0x34); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (sel < 0x10000u) return 0;
    __try { head = *(const uint32_t*)(uintptr_t)(sel + 0x1F0); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (head < 0x10000u) return 0;
    uint32_t unit = 0;
    __try { unit = *(const uint32_t*)(uintptr_t)(head + 8); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return unit;
}

/* 一次性：按名字查 JASS native，打印地址与 RVA，用于静态逆向 GetHeroStr/移速 getter。 */
static void DdhProbeHeroNatives(void)
{
    static volatile LONG done = 0;
    if (InterlockedCompareExchange(&done, 1, 0) != 0) return;
    const char* names[] = { "GetHeroStr", "GetHeroAgi", "GetHeroInt", "GetHeroLevel", "GetUnitMoveSpeed" };
    for (int i = 0; i < 5; ++i)
    {
        uint32_t fn = FindNativeFunc(names[i]);
        LogLine("native 探针：%s = 0x%08X rva=0x%X", names[i], fn, fn ? (unsigned)(fn - g_modBase) : 0u);
    }
}

static uint32_t DdhW3ApiTypeLookup(void)
{
    static uint32_t cached = 0;
    static volatile LONG tried = 0;
    if (InterlockedCompareExchange(&tried, 1, 0) != 0) return cached;
    HMODULE gd = GetModuleHandleA("Game.dll");
    if (!gd) gd = GetModuleHandleA("game.dll");
    FARPROC fp = gd ? GetProcAddress(gd, "WAR3API_GetTypeMemoryAddressByTypeId") : NULL;
    cached = (uint32_t)(uintptr_t)fp;
    LogLine("WAR3API 探针：Game.dll=0x%08X 导出 WAR3API_GetTypeMemoryAddressByTypeId=0x%08X",
            (unsigned)(uintptr_t)gd, cached);
    return cached;
}

static uint32_t DdhYdJassFunc(const char* name)
{
    static HMODULE yb = NULL;
    static int tried = 0;
    if (!tried)
    {
        tried = 1;
        yb = GetModuleHandleA("ydbase.dll");
        if (!yb) yb = LoadLibraryA("ydbase.dll");
    }
    if (!yb) return 0;
    typedef const void* (__cdecl *fn_jass_func_t)(const char*);
    fn_jass_func_t jf = (fn_jass_func_t)(uintptr_t)GetProcAddress(yb, "?jass_func@jass@warcraft3@base@@YAPBVfunc_value@123@PBD@Z");
    if (!jf) return 0;
    const uint32_t fv = (uint32_t)(uintptr_t)jf(name);
    if (!fv) return 0;
    uint32_t code = 0;
    __try { code = *(const uint32_t*)(uintptr_t)(fv + 0x10); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return code;
}


/* 'Aloc'（蝗虫技能）�?dword：字�?A,l,o,c = 0x41 0x6C 0x6F 0x63�?
   内存按小端存�?dword 0x636F6C41。GetUnitAbilityLevel(handle, 0x636F6C41) > 0 = 马甲�?
   判定口径�?YDWE 一致（YDWE-master/Development/Component/ui/ydwe/jass/YDWETriggerEvent.j:47�?
   GetUnitAbilityLevel(GetFilterUnit(), 'Aloc') <= 0 是普通单位，> 0 才是马甲/蝗虫单位）�?
   只按技能判定，不按名字/类型码写死�?*/
#define DDH_ABILITY_ALOC   0x636F6C41u
#define DDH_AF_LOCUST_CHECKED 0x00400000u   /* v23：真的执行过 Aloc 判定（结果可为否）；与 ILLUSION(0x200000) 分开 */

static const char* DdhCodeText(uint32_t code)
{
    static char buf[8];
    buf[0] = (char)((code >> 24) & 0xFF);
    buf[1] = (char)((code >> 16) & 0xFF);
    buf[2] = (char)((code >> 8) & 0xFF);
    buf[3] = (char)(code & 0xFF);
    buf[4] = 0;
    for (int i = 0; i < 4; ++i) if (buf[i] < 32 || buf[i] > 126) buf[i] = '?';
    return buf;
}

/* 内存扫 Aloc：单位结构里技能项含 4 字节技能码，找到 0x636F6C41 即蝗虫。
   不依赖 JASS native（实测 native 调不出结果），也不依赖类型数据字段名。 */
/* 判断一个 dword 是不是 Aloc 的两种字节序 */
static bool DdhIsAlocDword(uint32_t v) { return v == 0x636F6C41u || v == 0x416C6F63u; }

/* 在 [base, base+len) 里找 Aloc（4 字节步长）。返回偏移，找不到返回 -1。 */
static int32_t DdhScanAloc(uint32_t base, uint32_t len, uint32_t* reads)
{
    if (!base || base < 0x10000 || base > 0x7FFFFFFF) return -1;
    for (uint32_t off = 0; off < len; off += 4)
    {
        uint32_t v = 0;
        __try { v = *(const uint32_t*)(uintptr_t)(base + off); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
        if (reads) ++*reads;
        if (DdhIsAlocDword(v)) return (int32_t)off;
    }
    return -1;
}

/* 全方位找 Aloc：本体 0x8000 → 一级指针子块 0x2000 → 二级指针子块 0x1000，
   外加 ASCII "Aloc"。返回 true 并给出从哪里命中（path 文本），不依赖 native/类型数据。 */
static bool DdhReadF32(uint32_t addr, float* out)
{
    if (!out) return false;
    float v = 0.0f;
    __try { v = *(const float*)(uintptr_t)addr; } __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    if (!(v == v) || v > 1e9f || v < -1e9f) return false;
    *out = v;
    return true;
}

static bool DdhMemHasAlocDeep(uint32_t obj, char* path, size_t cap, uint32_t* readsOut)
{
    if (path && cap) path[0] = 0;
    uint32_t reads = 0;
    if (!obj || obj < 0x10000 || obj > 0x7FFFFFFF) return false;

    int32_t off = DdhScanAloc(obj, 0x8000, &reads);
    if (off >= 0)
    {
        if (path && cap) _snprintf_s(path, cap, _TRUNCATE, "本体+0x%X", (unsigned)off);
        if (readsOut) *readsOut = reads;
        return true;
    }

    /* 一级指针 */
    uint32_t firstPt[64]; int firstCount = 0;
    for (uint32_t o = 0; o < 0x800 && firstCount < 64; o += 4)
    {
        uint32_t p = 0;
        __try { p = *(const uint32_t*)(uintptr_t)(obj + o); }
        __except (EXCEPTION_EXECUTE_HANDLER) { break; }
        if (p < 0x10000 || p > 0x7FFFFFFF || p == obj) continue;
        firstPt[firstCount++] = p;
    }
    for (int i = 0; i < firstCount; ++i)
    {
        int32_t o2 = DdhScanAloc(firstPt[i], 0x2000, &reads);
        if (o2 >= 0)
        {
            if (path && cap) _snprintf_s(path, cap, _TRUNCATE, "ptr[%d]->+0x%X", i, (unsigned)o2);
            if (readsOut) *readsOut = reads;
            return true;
        }
    }

    /* 二级指针（技能链表：节点->next） */
    for (int i = 0; i < firstCount; ++i)
    {
        for (uint32_t o = 0; o < 0x200; o += 4)
        {
            uint32_t q = 0;
            __try { q = *(const uint32_t*)(uintptr_t)(firstPt[i] + o); }
            __except (EXCEPTION_EXECUTE_HANDLER) { break; }
            if (q < 0x10000 || q > 0x7FFFFFFF) continue;
            int32_t o3 = DdhScanAloc(q, 0x1000, &reads);
            if (o3 >= 0)
            {
                if (path && cap) _snprintf_s(path, cap, _TRUNCATE, "ptr[%d]->[+0x%X]->+0x%X", i, (unsigned)o, (unsigned)o3);
                if (readsOut) *readsOut = reads;
                return true;
            }
        }
    }

    if (readsOut) *readsOut = reads;
    return false;
}






/* 蝗虫判定诊断日志限流：前 5 次无条件写（�?level<=0 / handle==0）�?*/
static volatile LONG g_locustLogCount = 0;

/* ---- v21：蝗虫类型码缓存 ----
   句柄拿不到（尸体 / 刚创�?/ 句柄表暂时失效）时无法调 GetUnitAbilityLevel�?
   但同一类型码只要有任何一只被实测�?Aloc，就整类按蝗虫处�?—�?C# 的【战场单位】用它过滤�?
   只缓存类型码（不按名�?地址写死），口径仍是 Aloc�?*/
static uint32_t      g_alocCodes[256];
static volatile LONG g_alocCodeCount = 0;

static bool DdhAlocCodeKnown(uint32_t code)
{
    const LONG n = g_alocCodeCount;
    for (LONG i = 0; i < n && i < 256; i++)
        if (g_alocCodes[i] == code) return true;
    return false;
}

static void DdhAlocCodeRemember(uint32_t code)
{
    if (!code || DdhAlocCodeKnown(code)) return;
    const LONG idx = InterlockedIncrement(&g_alocCodeCount) - 1;
    if (idx < 256) g_alocCodes[idx] = code;
}

/* DdhCodeText 定义在后面（类型�?-> 可读文本）；RecordDamage 里先用，补前置声明�?*/
static void DdhCodeText(uint32_t code, char* out, size_t cap);

/* ---- 单位所属玩家号：CUnit+0x58 直接保存 0 基玩家槽位。
   GetOwningPlayer 的 vtable+0xEC 实现也是 mov eax,[ecx+0x58]。 ---- */
static uint32_t g_natGetPlayerId = 0;
static volatile LONG g_gpidTries = 0;

static volatile LONG g_ownerLogCount = 0;

static uint32_t GetPlayerIdNative(void)
{
    if (g_natGetPlayerId) return g_natGetPlayerId;
    if (InterlockedIncrement(&g_gpidTries) > 16) return 0;
    g_natGetPlayerId = FindNativeFunc("GetPlayerId");
    if (g_natGetPlayerId)
        LogLine("v8：GetPlayerId native 已定位 0x%08X", g_natGetPlayerId);
    return g_natGetPlayerId;
}

/* obj(CUnit*) -> owner slot (0-based), no handle/JASS/fallback. */
static int32_t ResolveOwnerPid(uint32_t obj)
{
    if (obj < 0x10000 || obj > 0x7FFFFFFF) return -1;
    uint32_t owner = 0;
    __try { owner = *(const uint32_t*)(uintptr_t)(obj + 0x58u); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
    return owner < 24u ? (int32_t)owner : -1;
}

/* ---- v21：玩家结盟掩码（本地玩家视角�?---
   �?i �?= 玩家 i�? 基）是否与本地玩家结盟（含本地玩家自己）�?
   JASS 原生：GetLocalPlayer() / Player(index) / IsPlayerAlly(a,b)，都�?__cdecl�?
   只在游戏线程（属性填�?/ 伤害钩子）调用；整局只算成功一次，失败最多重�?64 次�?
   写进 hdr.reserved[1]，C# 只在 hdr.version >= 21 时读�?*/
static uint32_t      g_allyMask = 0;
static int           g_localPlayerId = -1;   /* v27：GetPlayerId(GetLocalPlayer())，给阵亡总结/C# 用 */
static volatile LONG g_allyMaskTries = 0;
static volatile LONG g_allyMaskDone = 0;
static uint32_t      g_natPlayer = 0;
static uint32_t      g_natLocalPlayer = 0;
static uint32_t      g_natIsPlayerAlly = 0;

static uint32_t DdhPlayerNative(void)
{
    if (!g_natPlayer) g_natPlayer = FindNativeFunc("Player");
    return g_natPlayer;
}
static uint32_t DdhLocalPlayerNative(void)
{
    if (!g_natLocalPlayer) g_natLocalPlayer = FindNativeFunc("GetLocalPlayer");
    return g_natLocalPlayer;
}
static uint32_t DdhIsPlayerAllyNative(void)
{
    if (!g_natIsPlayerAlly) g_natIsPlayerAlly = FindNativeFunc("IsPlayerAlly");
    return g_natIsPlayerAlly;
}

static void DdhComputeAllyMask(void)
{
    if (g_allyMaskDone || !g_shm) return;
    if (InterlockedIncrement(&g_allyMaskTries) > 64) return;

    const uint32_t fnPlayer = DdhPlayerNative();
    const uint32_t fnLocal = DdhLocalPlayerNative();
    const uint32_t fnAlly = DdhIsPlayerAllyNative();
    if (!fnPlayer || !fnLocal) return;

    uint32_t local = 0;
    __try { local = ((uint32_t (__cdecl*)(void))(uintptr_t)fnLocal)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { local = 0; }
    if (!local) return;

    /* 先解析本地玩家号：即使 IsPlayerAlly 不可用，也要把真实玩家号给阵亡总结/C#。
       这个函数只在游戏线程（属性填充）调用，不在伤害钩子里调 JASS。 */
    uint32_t localId = 0xFFFFFFFFu;
    const uint32_t gpid = GetPlayerIdNative();
    if (gpid)
    {
        __try { localId = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)gpid)(local); }
        __except (EXCEPTION_EXECUTE_HANDLER) { localId = 0xFFFFFFFFu; }
        if (localId < 24)
        {
            g_localPlayerId = (int)localId;
            g_shm->hdr.reserved[3] = localId + 1u;
        }
    }
    if (!fnAlly)
    {
        LogLine("v27：本地玩家 = %d（IsPlayerAlly 不可用，暂不算结盟掩码）", g_localPlayerId);
        return;
    }

    uint32_t mask = 0;
    for (int i = 0; i < 24; i++)
    {
        uint32_t h = 0;
        __try { h = ((uint32_t (__cdecl*)(int))(uintptr_t)fnPlayer)(i); }
        __except (EXCEPTION_EXECUTE_HANDLER) { h = 0; }
        if (!h) continue;
        int ally = 0;
        __try { ally = ((int (__cdecl*)(uint32_t, uint32_t))(uintptr_t)fnAlly)(local, h); }
        __except (EXCEPTION_EXECUTE_HANDLER) { ally = 0; }
        if (ally) mask |= (1u << i);
    }

    /* 本地玩家自己那一位置 1（有些地�?IsPlayerAlly(p,p) 返回 false�?*/
    if (localId < 24) mask |= (1u << (int)localId);

    g_allyMask = mask;
    g_shm->hdr.reserved[1] = mask;   /* reserved[0] �?hpSupported；[1] 留给 v21 结盟掩码 */
    InterlockedExchange(&g_allyMaskDone, 1);
    LogLine("v21：结盟掩码 = 0x%06X（本地玩家 %d；Player/GetLocalPlayer/IsPlayerAlly 已定位=%d/%d/%d）",
            mask, (localId < 24) ? (int)localId : -1, fnPlayer ? 1 : 0, fnLocal ? 1 : 0, fnAlly ? 1 : 0);
}

static volatile LONG g_nameOkLogged = 0;    /* “名字解析成功”日志总上�?*/

/* 安全地把一段内存按字节读进 buf（最�?n 字节），返回实际读到的字节数�?
   全程 __try；读不动就停，返回已读到的部分�?*/
static int SafeHexDump(uint32_t addr, int n, unsigned char* buf)
{
    if (addr < 0x10000 || n <= 0) return 0;
    int got = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)addr;
        for (int i = 0; i < n; i++) { buf[i] = p[i]; got = i + 1; }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { /* got 停在已读到的部分 */ }
    return got;
}

/* �?n 个字节格式化�?"AA BB CC ..."（大写、空格分隔），out 已清空�?*/
static void FormatHex(const unsigned char* buf, int n, char* out, size_t outSize)
{
    out[0] = 0;
    if (!buf || n <= 0) return;
    static const char hexc[] = "0123456789ABCDEF";
    size_t pos = 0;
    for (int i = 0; i < n && pos + 3 < outSize; i++)
    {
        out[pos++] = hexc[buf[i] >> 4];
        out[pos++] = hexc[buf[i] & 15];
        out[pos++] = ' ';
    }
    if (pos > 0) pos--;
    out[pos] = 0;
}

/* UTF-8 安全截断（v9）：�?src 最�?maxBytes 个字节复制到 dst（容�?cap），
   绝不把多字节字符切成两半�?
     · �?maxBytes 字节落在字符中间（后一字节是续字节 10xxxxxx）→ 回退到该字符
       起始处，整个字符都不写；
     · 源串本身就以半个字符结尾（NUL 前缺续字节）�?同样丢掉末尾残缺字符�?
   返回实际写入字节数（不含结尾 NUL）�?*/
static size_t DdhUtf8SafeCopy(char* dst, size_t cap, const char* src, size_t maxBytes)
{
    if (!dst || cap == 0) return 0;
    dst[0] = 0;
    if (!src || !src[0] || maxBytes == 0) return 0;
    if (maxBytes > cap - 1) maxBytes = cap - 1;

    size_t n = 0;
    while (n < maxBytes && src[n]) n++;

    if (src[n] && ((unsigned char)src[n] & 0xC0) == 0x80)
    {
        /* 截断点后面还有续字节 �?切在字符中间，退到该字符首字节（不写它） */
        while (n > 0 && ((unsigned char)src[n] & 0xC0) == 0x80) n--;
    }
    else
    {
        /* 源串自己结尾不完整时，也把末尾那个残缺字符去�?*/
        size_t start = n;
        while (start > 0 && ((unsigned char)src[start - 1] & 0xC0) == 0x80) start--;
        if (start > 0)
        {
            const unsigned char lead = (unsigned char)src[start - 1];
            size_t need = 1;
            if ((lead & 0xE0) == 0xC0) need = 2;
            else if ((lead & 0xF0) == 0xE0) need = 3;
            else if ((lead & 0xF8) == 0xF0) need = 4;
            if (start - 1 + need > n) n = start - 1;
        }
    }

    memcpy(dst, src, n);
    dst[n] = 0;
    return n;
}

/* 名字原样校验：p 必须可读�? 结尾、无控制字符/0x7F、长�?1..63�?
   拷出时走 DdhUtf8SafeCopy，长度不够也从完整字符边界截断�?
   全在 __try 里，读坏/校验不过返回 false�?*/
static bool ValidateNameText(uint32_t addr, char* out, size_t outSize)
{
    out[0] = 0;
    if (addr < 0x10000 || addr > 0x7FFFFFFF || outSize < 2) return false;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)addr;
        if (!p[0]) return false;
        if (p[0] < 0x20) return false;
        int n = 0;
        for (; n < 64; ++n)
        {
            const unsigned char c = p[n];
            if (!c) break;
            if (c < 0x20 || c == 0x7F) return false;
        }
        if (n == 0 || n >= 64) return false;   /* 空串/没结�?-> 放弃 */
        const int copy = n < (int)outSize - 1 ? n : (int)outSize - 1;
        DdhUtf8SafeCopy(out, outSize, (const char*)p, (size_t)copy);
        return true;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { out[0] = 0; return false; }
}

/* ---- v24 诊断�?x326BA0 只取表里�?[0] 项，取不到就返回空串/0�?
   这里直接把注册表对象取出来（0x327020(desc, key=code)），�?count �?array[0..7]
   到底是什么，用来判断 Dota 自定义单位码到底是“表不存在”“表存在但名字为空”，
   还是“名字在别的槽位”。只在前几次失败时记录�?*/
#define DDH_RVA_REGISTRY_GET   0x00327020u
static const uint8_t kPro3RegistryGet[3] = { 0x55, 0x8B, 0xEC };
static uint32_t g_natRegistryGet = 0;

static uint32_t ResolveRegistryGet(void)
{
    if (g_natRegistryGet) return g_natRegistryGet;
    g_natRegistryGet = HpResolve(DDH_RVA_REGISTRY_GET, kPro3RegistryGet);
    if (g_natRegistryGet)
        LogLine("名字表探针：0x327020 已定位（0x%08X）", g_natRegistryGet);
    return g_natRegistryGet;
}

static void DdhNameTableProbe(uint32_t code)
{
    const uint32_t fn = ResolveRegistryGet();
    if (!fn || !g_modBase) return;
    const uint32_t desc = (uint32_t)(uintptr_t)((const uint8_t*)g_modBase + 0x98ACF8u);
    __try
    {
        const uint32_t obj = ((uint32_t(__fastcall*)(uint32_t, uint32_t))(uintptr_t)fn)(code, desc);
        if (!obj) { LogLine("名字表探针：code=0x%08X 注册表返回 0", code); return; }
        const int count = *(const int*)(obj + 0x28);
        const uint32_t* arr = *(const uint32_t* const*)(obj + 0x2C);
        LogLine("名字表探针：code=0x%08X obj=%08X count=%d arr=%08X",
                code, obj, count, (unsigned)(uintptr_t)arr);
        for (int i = 0; i < count && i < 8; ++i)
        {
            if (!arr) break;
            const uint32_t p = arr[i];
            char buf[64] = { 0 };
            const bool ok = p && ValidateNameText(p, buf, sizeof(buf)) && buf[0];
            LogLine("名字表探针[%d] ptr=%08X%s%s", i, p, ok ? " name=" : "", ok ? buf : "");
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("名字表探针：code=0x%08X 异常 0x%08X", code, (unsigned)GetExceptionCode());
    }
}

/* v25：直接查【类型码 �?名字表】并取第一个非空槽位�?
   �?0x326BA0 走同一个注册表（desc=g_modBase+0x98ACF8），但不依赖它那个返�?0 的实现�?*/
static bool DdhNameFromTypeTable(uint32_t code, char* out, size_t outSize)
{
    if (out) out[0] = 0;
    if (!code || !out || outSize < 2) return false;
    const uint32_t fn = ResolveRegistryGet();
    if (!fn || !g_modBase) return false;
    const uint32_t desc = (uint32_t)(uintptr_t)((const uint8_t*)g_modBase + 0x98ACF8u);
    __try
    {
        const uint32_t obj = ((uint32_t(__fastcall*)(uint32_t, uint32_t))(uintptr_t)fn)(code, desc);
        if (!obj) return false;
        const int count = *(const int*)(obj + 0x28);
        const uint32_t* arr = *(const uint32_t* const*)(obj + 0x2C);
        if (!arr || count <= 0) return false;
        for (int i = 0; i < count && i < 16; ++i)
        {
            const uint32_t p = arr[i];
            if (p && ValidateNameText(p, out, outSize) && out[0]) return true;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { if (out) out[0] = 0; }
    return false;
}

static void ResolveName(uint32_t obj, uint32_t code, char* out, size_t outSize)
{
    (void)obj;
    out[0] = 0;
    if (!code || g_modBase == 0) return;

    for (int i = 0; i < g_nameCacheCount; i++)
    {
        if (g_nameCache[i].code == code && g_nameCache[i].name[0])
        {
            DdhUtf8SafeCopy(out, outSize, g_nameCache[i].name, outSize - 1);
            return;
        }
    }

    char tmp[64] = { 0 };
    if (!DdhNameFromTypeTable(code, tmp, sizeof(tmp)) || !tmp[0])
    {
        const LONG n = InterlockedIncrement(&g_nameFailLogged);
        if (n <= 3)
            LogLine("类型码名称表解析失败：code=0x%08X", code);
        return;
    }

    DdhUtf8SafeCopy(out, outSize, tmp, outSize - 1);
    if (g_nameCacheCount < 128)
    {
        g_nameCache[g_nameCacheCount].code = code;
        DdhUtf8SafeCopy(g_nameCache[g_nameCacheCount].name, sizeof(g_nameCache[0].name), tmp, sizeof(g_nameCache[0].name) - 1);
        g_nameCacheCount++;
    }
    else
    {
        /* 缓存满了：覆盖最后一个槽位（只缓存成功结果） */
        g_nameCache[127].code = code;
        DdhUtf8SafeCopy(g_nameCache[127].name, sizeof(g_nameCache[0].name), tmp, sizeof(g_nameCache[0].name) - 1);
    }

    const LONG n = InterlockedIncrement(&g_nameOkLogged);
    if (n <= 5)
        LogLine("类型码名称表解析成功：code=0x%08X 名字=%s", code, tmp);
}

/* ===========================================================================
   v10：单位属性的采集实现
   ---------------------------------------------------------------------------
   为什么要“请�?响应”：C# �?64 位进程，读不�?32 位游戏的内存，更没法替游戏调
   JASS；�?JASS native **只能在游戏线程调**。所�?C# �?~1 秒把最�?96 �?CUnit*
   写进请求槽并�?requestSeq +1，ddh 在游戏线程上看到序号变了才开始查属性，
   写完响应槽最后才�?doneSeq = requestSeq（C# �?doneSeq == 自己写的序号判定完成）�?

   触发点（都只在游戏线程）�?
     �?窗口过程收到 WM_APP+0xDE（热键线程每 100ms 发现新请求就 PostMessage 一次）�?
     �?DdhDamageFunc 最外层返回时（DdhProcessPending �?DdhProcessAttrRequest），
        没有窗口 / 没热键线程时也能工作（假魔兽冒烟就靠这条）�?

   native 解析：FindNativeFunc 按名字在 JASS native 哈希表里找，**每个候选只�?只记
   一次日�?*；调用约定按引擎自己的那一套（32 �?JASS 值：real �?float 位模式放 EAX），
   同时�?ST(0) 兜住“按 C 浮点约定返回”的 JAPI 实现�?
   每字段一�?flags 位：解析不到�?invalid（C# 显示 ?），绝不�?0 冒充�?
   v15：攻击范�?/ 攻击�?/ 攻击间隔 / 护甲 / 主动攻击范围 改成**内存直读优先**
   （YDWE unit_property / CUnit+0xE0，见下面 DdhAttrFillMemory 的说明），native 只做兜底�?
    移速用 native；视�?基础速度/基础护甲/称谓�?DzAPI_UnitType_GetUnitTypeData*（类型数据）�?
    v16（真机日志驱动）�?
      · 每个字段改成**精确名单优先，关键字模糊匹配只作最后兜�?* —�?旧版按“名字最短”排序，
        结果移速挑�?GetGameSpeed（返�?0）、单位附加值挑�?GetItemUserData、视野挑�?
        UnitShareVision，全是错�?native�?
      · 排除名单：GetGameSpeed / GetRandomInt / GetUnitTurnSpeed / GetUnitDefaultTurnSpeed /
        GetItemUserData / UnitShareVision(�?BJ) 任何字段都不采用�?
      · DzAPI_UnitType_GetUnitTypeData* 的字符串实参改成 JASS string 句柄（DdhMakeJassString
        造的 string_fake 对象指针），实参顺序 / unitTypeId 形态用 DZPROBE 4 种组合探测一次后固定�?
   =========================================================================== */

enum
{
    DDH_AN_TITLE = 0,
    DDH_AN_RANGE,
    DDH_AN_DMG_MIN,
    DDH_AN_DMG_MAX,
    DDH_AN_ATTACK,
    DDH_AN_COOLDOWN,
    DDH_AN_ATKSPEED,
    DDH_AN_ARMOR,
    DDH_AN_DEFENSE,
    DDH_AN_MOVE,
    DDH_AN_MOVE_BASE,
    DDH_AN_SIGHT,
    DDH_AN_ACQUIRE,
    DDH_AN_STR,
    DDH_AN_HERO_STR,
    DDH_AN_AGI,
    DDH_AN_HERO_AGI,
    DDH_AN_INT,
    DDH_AN_HERO_INT,
    DDH_AN_USERDATA,
    DDH_AN_TYPEID,        /* GetUnitTypeId：句�?-> 4 字符类型码（标准 native�?*/
    DDH_AN_IS_HERO_ID,    /* IsHeroUnitId：类型码 -> 是否英雄（标�?native�?*/
    DDH_AN_IS_ILLUSION,   /* IsUnitIllusion：句�?-> 是否镜像/幻象 */
    DDH_AN_COUNT
};

static const char* const kDdhAttrNativeName[DDH_AN_COUNT] =
{
    "GetHeroProperName",      /* 称谓（英雄专名） */
    "GetUnitAttackRange",     /* 攻击范围 */
    "GetUnitDamageMin",       /* 攻击力下�?*/
    "GetUnitDamageMax",       /* 攻击力上�?*/
    "GetUnitAttack",          /* 攻击力（单值候选） */
    "GetUnitAttackCooldown",  /* 攻击间隔（秒�?*/
    "GetUnitAttackSpeed",     /* 每秒攻击次数�?1 时按 1/�?换成间隔�?*/
    "GetUnitArmor",           /* 护甲 */
    "GetUnitDefense",         /* 护甲（候�?2�?*/
    "GetUnitMoveSpeed",       /* 移速：精确优先�?1 名（真机日志�?GetGameSpeed 是错的） */
    "GetUnitDefaultMoveSpeed",/* 移速：精确优先�?2 �?*/
    "GetUnitSightRange",      /* 视野（第二参数：0 = 白天�? = 夜晚�?*/
    "GetUnitAcquireRange",    /* 主动攻击范围 */
    "GetUnitStrength",        /* 力量 */
    "GetHeroStr",             /* 力量（原�?native，第二参�?0 = 不含加成�?*/
    "GetUnitAgility",         /* 敏捷 */
    "GetHeroAgi",
    "GetUnitIntelligence",    /* 智力 */
    "GetHeroInt",
    "GetUnitUserData",        /* 单位附加值（自定义值） */
    "GetUnitTypeId",          /* 单位类型码（英雄判定用） */
    "IsHeroUnitId",           /* 类型码是否英雄（英雄判定用） */
    "IsUnitIllusion"          /* 是否镜像/幻象单位 */
};

/* 每个字段的“精确优先列表第 2 名”（空串 = 没有�?2 名）�?
   移速：GetUnitMoveSpeed �?GetUnitDefaultMoveSpeed（真机日志里自动匹配挑到 GetGameSpeed
   返回 0，界面就显示 0；所以精确名单必须排在最前）。其余字段有规范名就够，�?2 名留空�?*/
static const char* const kDdhAttrNativeName2[DDH_AN_COUNT] =
{
    "", "", "", "", "", "", "", "", "",                  /* 称谓 ~ 护甲(Defense) */
    "GetUnitDefaultMoveSpeed",                            /* 移�?*/
    "GetUnitDefaultMoveSpeed",                            /* 基础移�?*/
    "", "", "", "", "", "", "", "", "", "", "", ""            /* 视野 ~ 幻象判定 */
};


/* ===========================================================================
   v10 诊断：native 表全�?dump（只写一次）+ 关键字自动匹�?
   ---------------------------------------------------------------------------
   表结构与 FindNativeFunc 完全一致：
     inst = get_instance(5)；tbl = inst + 0x18
     tbl+0x1C = buckets，tbl+0x24 = mask；每�?12 字节�?8 = 节点�?
     节点 +0x04 hash�?0x0C 链上下一个�?0x18 名字指针�?0x1C 函数指针
   名字最�?2000 个（超了截断），按字母序（大小写不敏感）输出�?
   含关键字的候选在 dump 行里名字前加 '*'，并统计命中数�?
    自动匹配只认 Get / Is 开头的读取型名字（排除 Set 开�?+ 排除名单），按“名字越短越�?
    规范名”排序；v16 �?*固定精确名单优先**，自动候选只在精确名单全都不存在时兜底�?
   ========================================================================= */
#define DDH_NATIVE_DUMP_MAX 2000
#define DDH_AUTO_CAND_MAX   8

static char g_ddhNativeNames[DDH_NATIVE_DUMP_MAX][64];
static int  g_ddhNativeNameCount = 0;
static volatile LONG g_ddhNativeDumpDone  = 0;
static volatile LONG g_ddhNativeDumpTries = 0;
static char g_ddhAutoCand[DDH_AN_COUNT][DDH_AUTO_CAND_MAX][64];
static int  g_ddhAutoCandCount[DDH_AN_COUNT];
static char g_ddhAttrUsedName[DDH_AN_COUNT][64];

static const char* const kDdhAttrFieldName[DDH_AN_COUNT] =
{
    "称谓", "攻击范围", "攻击力下限", "攻击力上限", "攻击力", "攻击间隔", "攻击速度",
    "护甲", "护甲(Defense)", "移速", "基础移速", "视野", "主动攻击范围",
    "力量", "力量(英雄)", "敏捷", "敏捷(英雄)", "智力", "智力(英雄)", "单位附加值",
    "单位类型ID", "英雄ID判定", "幻象判定"
};

static const char* const kDdhNativeKeywords[] =
{
    "Attack", "Damage", "Armor", "Defen", "Range", "Sight", "Move", "Speed",
    "Str", "Agi", "Int", "Custom", "UserData", "Prop", "Name"
};

static int DdhLowerAscii(int c) { return (c >= 'A' && c <= 'Z') ? c + 32 : c; }

static int DdhNameHas(const char* name, const char* needle)
{
    if (!name || !needle || !needle[0]) return 0;
    for (const char* p = name; *p; ++p)
    {
        const char* a = p;
        const char* b = needle;
        while (*a && *b && DdhLowerAscii((unsigned char)*a) == DdhLowerAscii((unsigned char)*b)) { ++a; ++b; }
        if (!*b) return 1;
    }
    return 0;
}

static int DdhIsAsciiWordChar(int c)
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9') || c == '_';
}

/* camelCase 词元匹配：Str / Agi / Int 只认 "GetHeroStr" 这种独立词，
   不把 String / Integer / Magic 里的子串当词元�?*/
static int DdhNameToken(const char* name, const char* token)
{
    if (!name || !token || !token[0]) return 0;
    const size_t tn = strlen(token);
    for (const char* p = name; *p; ++p)
    {
        const char* a = p;
        const char* b = token;
        while (*a && *b && DdhLowerAscii((unsigned char)*a) == DdhLowerAscii((unsigned char)*b)) { ++a; ++b; }
        if (*b) continue;
        const int prev = (p == name) ? 0 : (unsigned char)p[-1];
        const int next = (unsigned char)*a;
        const int leftOk = (p == name) || !DdhIsAsciiWordChar(prev) ||
                           (p[0] >= 'A' && p[0] <= 'Z' && prev >= 'a' && prev <= 'z');
        const int rightOk = next == 0 || !DdhIsAsciiWordChar(next) ||
                            (next >= 'A' && next <= 'Z' && a[-1] >= 'a' && a[-1] <= 'z');
        if (leftOk && rightOk) return 1;
    }
    (void)tn;
    return 0;
}

/* 自动匹配只接受读取型名字，绝不把 Set* �?provider�?*/
static int DdhNameCallable(const char* n)
{
    if (!n || !n[0]) return 0;
    if (DdhNameHas(n, "set")) return 0;
    return DdhNameHas(n, "get") || DdhNameHas(n, "is");
}

/* ---------------------------------------------------------------------------
   排除名单：这�?native 名字**任何字段都不会采�?*（真机日志逐条证明会挑错）�?
     GetGameSpeed             游戏速度，不是单位移速；真机返回 0 �?界面显示 0
     GetRandomInt             随机整数（旧版三�?移速都可能被它命中�?
     GetUnitTurnSpeed         转向速度，不是移�?
     GetUnitDefaultTurnSpeed  默认转向速度
     GetItemUserData          物品自定义值，不是“单位附加值�?
     UnitShareVision          共享视野开关（UnitShareVisionBJ 同前缀），不是视野范围
   v16：模糊匹配（关键字自动候选）也要过这一关，避免“名字短优先”又把错的挑回来�?
   --------------------------------------------------------------------------- */
static const char* const kDdhAttrBannedGlobal[] =
{
    "GetGameSpeed", "GetRandomInt", "GetUnitTurnSpeed", "GetUnitDefaultTurnSpeed",
    "GetItemUserData", "UnitShareVision"
};

/* 1 = 这个名字在该字段中被禁止（DdhAttrNative 永远不会采用）�?*/
static int DdhAttrNameBanned(int id, const char* n)
{
    if (!n || !n[0]) return 1;
    for (int i = 0; i < (int)(sizeof(kDdhAttrBannedGlobal) / sizeof(kDdhAttrBannedGlobal[0])); ++i)
        if (DdhNameHas(n, kDdhAttrBannedGlobal[i])) return 1;
    /* 平台类型数据 native（DzAPI_*）：第一个实参是“单位类�?id”，不是单位句柄�?
       绝不能当 get-unit-xxx 用（旧版自动匹配�?DzAPI_UnitType_GetUnitTypeDataInt
       当成“智力”候选过，就因为名字里有 Int 词元）�?*/
    if (DdhNameHas(n, "dzapi")) return 1;

    switch (id)
    {
    case DDH_AN_MOVE:
    case DDH_AN_MOVE_BASE:
        return DdhNameHas(n, "turnspeed") || DdhNameHas(n, "attackspeed") || DdhNameHas(n, "gamerate");
    case DDH_AN_USERDATA:
        return DdhNameHas(n, "item");
    case DDH_AN_STR: case DDH_AN_HERO_STR:
    case DDH_AN_AGI: case DDH_AN_HERO_AGI:
    case DDH_AN_INT: case DDH_AN_HERO_INT:
        return DdhNameHas(n, "string") || DdhNameHas(n, "random");
    default:
        return 0;
    }
}

/* 字段 -> 关键字规则（包含匹配）。命中后仍要真调到有限数才采用�?
   v16：命中排除名单的直接不算候选（模糊匹配只是最后兜底）�?*/
static int DdhAttrAutoMatch(int id, const char* n)
{
    if (!DdhNameCallable(n)) return 0;
    if (DdhAttrNameBanned(id, n)) return 0;
    switch (id)
    {
    case DDH_AN_TITLE:
        return DdhNameHas(n, "propername") || DdhNameHas(n, "heroname");

    case DDH_AN_RANGE:
        return DdhNameHas(n, "attackrange") || DdhNameHas(n, "attackdist") ||
               (DdhNameHas(n, "range") && DdhNameHas(n, "attack") &&
                !DdhNameHas(n, "sight") && !DdhNameHas(n, "acquire"));

    case DDH_AN_DMG_MIN:
        return (DdhNameHas(n, "damage") || DdhNameHas(n, "dmg") || DdhNameHas(n, "attack")) &&
               (DdhNameHas(n, "min") || DdhNameHas(n, "low")) &&
               !DdhNameHas(n, "max");

    case DDH_AN_DMG_MAX:
        return (DdhNameHas(n, "damage") || DdhNameHas(n, "dmg") || DdhNameHas(n, "attack")) &&
               (DdhNameHas(n, "max") || DdhNameHas(n, "high")) &&
               !DdhNameHas(n, "min");

    case DDH_AN_ATTACK:
        return (DdhNameHas(n, "attack") || DdhNameHas(n, "atk")) &&
               (DdhNameHas(n, "damage") || DdhNameHas(n, "power") || DdhNameHas(n, "base")) &&
               !DdhNameHas(n, "min") && !DdhNameHas(n, "max") && !DdhNameHas(n, "range") &&
               !DdhNameHas(n, "speed") && !DdhNameHas(n, "cooldown") && !DdhNameHas(n, "interval") &&
               !DdhNameHas(n, "time");

    case DDH_AN_COOLDOWN:
        return DdhNameHas(n, "cooldown") || DdhNameHas(n, "attackinterval") ||
               DdhNameHas(n, "attacktime") || DdhNameHas(n, "attackperiod") ||
               DdhNameHas(n, "attackdelay");

    case DDH_AN_ATKSPEED:
        return DdhNameHas(n, "attackspeed") || DdhNameHas(n, "attackrate") ||
               DdhNameHas(n, "attacksper");

    case DDH_AN_ARMOR:
        return DdhNameHas(n, "armor") || DdhNameHas(n, "defen");

    case DDH_AN_DEFENSE:
        return DdhNameHas(n, "defen");

    case DDH_AN_MOVE:
        return DdhNameHas(n, "movespeed") || DdhNameHas(n, "movementspeed") ||
               DdhNameHas(n, "movespd") || DdhNameHas(n, "moverate") ||
               (DdhNameHas(n, "speed") && !DdhNameHas(n, "attack"));

    case DDH_AN_MOVE_BASE:
        return (DdhNameHas(n, "movespeed") || DdhNameHas(n, "movespd")) && DdhNameHas(n, "base");

    case DDH_AN_SIGHT:
        return DdhNameHas(n, "sight") || DdhNameHas(n, "vision");

    case DDH_AN_ACQUIRE:
        return DdhNameHas(n, "acquire") || DdhNameHas(n, "aggro") || DdhNameHas(n, "guardrange");

    case DDH_AN_STR:
        return DdhNameHas(n, "strength") || DdhNameToken(n, "str");

    case DDH_AN_HERO_STR:
        return DdhNameHas(n, "hero") && (DdhNameHas(n, "str") || DdhNameHas(n, "strength"));

    case DDH_AN_AGI:
        return DdhNameHas(n, "agility") || DdhNameToken(n, "agi");

    case DDH_AN_HERO_AGI:
        return DdhNameHas(n, "hero") && (DdhNameHas(n, "agi") || DdhNameHas(n, "agility"));

    case DDH_AN_INT:
        return DdhNameHas(n, "intelligence") || DdhNameToken(n, "int");

    case DDH_AN_HERO_INT:
        return DdhNameHas(n, "hero") && (DdhNameHas(n, "int") || DdhNameHas(n, "intelligence"));

    case DDH_AN_USERDATA:
        return DdhNameHas(n, "userdata") || DdhNameHas(n, "customvalue") ||
               DdhNameHas(n, "custom") || DdhNameHas(n, "propvalue") ||
               (DdhNameHas(n, "prop") && DdhNameHas(n, "unit"));

    case DDH_AN_TYPEID:
        return DdhNameHas(n, "unittypeid") || (DdhNameHas(n, "typeid") && DdhNameHas(n, "unit"));

    case DDH_AN_IS_HERO_ID:
        return DdhNameHas(n, "ishero") && DdhNameHas(n, "id");

    case DDH_AN_IS_ILLUSION:
        return DdhNameHas(n, "illusion") || DdhNameHas(n, "mirror");

    default:
        return 0;
    }
}

static void DdhAttrAutoAdd(int id, const char* n)
{
    if (id < 0 || id >= DDH_AN_COUNT || !n || !n[0]) return;
    if (g_ddhAutoCandCount[id] >= DDH_AUTO_CAND_MAX) return;
    for (int i = 0; i < g_ddhAutoCandCount[id]; ++i)
        if (_stricmp(g_ddhAutoCand[id][i], n) == 0) return;

    const int len = (int)strlen(n);
    int pos = g_ddhAutoCandCount[id];
    for (int i = 0; i < g_ddhAutoCandCount[id]; ++i)
    {
        const int cur = (int)strlen(g_ddhAutoCand[id][i]);
        if (len < cur || (len == cur && _stricmp(n, g_ddhAutoCand[id][i]) < 0)) { pos = i; break; }
    }
    for (int i = g_ddhAutoCandCount[id]; i > pos; --i)
        memcpy(g_ddhAutoCand[id][i], g_ddhAutoCand[id][i - 1], 64);
    strncpy_s(g_ddhAutoCand[id][pos], 64, n, _TRUNCATE);
    ++g_ddhAutoCandCount[id];
}

static void DdhAttrAutoBuild(void)
{
    LogLine("ATTR 排除名单（任何字段都不会采用）：GetGameSpeed, GetRandomInt, GetUnitTurnSpeed, "
            "GetUnitDefaultTurnSpeed, GetItemUserData, UnitShareVision(�?BJ)；视野完全不�?native");
    memset(g_ddhAutoCandCount, 0, sizeof(g_ddhAutoCandCount));
    for (int i = 0; i < g_ddhNativeNameCount; ++i)
        for (int id = 0; id < DDH_AN_COUNT; ++id)
            if (DdhAttrAutoMatch(id, g_ddhNativeNames[i]))
                DdhAttrAutoAdd(id, g_ddhNativeNames[i]);

    int fields = 0;
    for (int id = 0; id < DDH_AN_COUNT; ++id)
    {
        if (g_ddhAutoCandCount[id] <= 0) continue;
        ++fields;
        char list[512] = { 0 };
        for (int i = 0; i < g_ddhAutoCandCount[id]; ++i)
        {
            if (i) strncat_s(list, sizeof(list), ", ", _TRUNCATE);
            strncat_s(list, sizeof(list), g_ddhAutoCand[id][i], _TRUNCATE);
        }
        LogLine("ATTR 自动匹配：%s 候选=%s", kDdhAttrFieldName[id], list);
    }
    LogLine("ATTR 自动匹配：共 %d / %d 个字段有关键字候选（固定名单继续作为后备）",
            fields, (int)DDH_AN_COUNT);
}

static int __cdecl DdhNativeNameCmp(const void* a, const void* b)
{
    return _stricmp((const char*)a, (const char*)b);
}

/* 第一次处理属性请求时调用；表没就绪（进图前）会在下一轮再试，最�?20 轮�?*/
static void DdhAttrDumpNativesOnce(void)
{
    if (g_ddhNativeDumpDone) return;
    if (InterlockedIncrement(&g_ddhNativeDumpTries) > 20) return;

    int count = 0;
    __try
    {
        typedef uint32_t (__fastcall* fn_gi_t)(uint32_t);
        const uint32_t inst = ((fn_gi_t)(uintptr_t)(g_modBase + 0x004EFB0u))(5);
        if (inst >= 0x10000u)
        {
            const uint32_t tbl = inst + 0x18u;
            uint32_t buckets = 0, mask = 0;
            if (PeekU32(tbl + 0x1Cu, &buckets) && PeekU32(tbl + 0x24u, &mask) &&
                buckets > 0x10000u && buckets < 0x7FFFFFFFu &&
                mask != 0xFFFFFFFFu && mask <= 0xFFFFu)
            {
                for (uint32_t b = 0; b <= mask && count < DDH_NATIVE_DUMP_MAX; ++b)
                {
                    uint32_t node = 0;
                    if (!PeekU32(buckets + b * 12u + 8u, &node)) continue;
                    int guard = 0;
                    while (node > 0x10000u && node < 0x7FFFFFFFu &&
                           guard++ < 512 && count < DDH_NATIVE_DUMP_MAX)
                    {
                        uint32_t key = 0;
                        if (PeekU32(node + 0x18u, &key) && key > 0x10000u && key < 0x7FFFFFFFu)
                        {
                            char nm[64] = { 0 };
                            __try
                            {
                                for (int i = 0; i < 63; ++i)
                                {
                                    nm[i] = *(const char*)(uintptr_t)(key + i);
                                    if (!nm[i]) break;
                                }
                            }
                            __except (EXCEPTION_EXECUTE_HANDLER) { nm[0] = 0; }

                            int valid = (nm[0] != 0);
                            for (int i = 0; i < 63 && nm[i]; ++i)
                                if ((unsigned char)nm[i] < 0x20u || (unsigned char)nm[i] == 0x7Fu) valid = 0;
                            if (valid)
                            {
                                strncpy_s(g_ddhNativeNames[count], 64, nm, _TRUNCATE);
                                ++count;
                            }
                        }
                        uint32_t prev = 0;
                        if (!PeekU32(node + 0x0Cu, &prev) || prev == node) break;
                        node = prev;
                    }
                }
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("ATTR dump：遍历 native 表异常 code=%08X", (unsigned)GetExceptionCode());
    }

    if (count <= 0)
    {
        if (g_ddhNativeDumpTries <= 3)
            LogLine("ATTR dump：native 表还没就绪（第 %d 次），下一轮属性请求再试", (int)g_ddhNativeDumpTries);
        return;
    }

    qsort(g_ddhNativeNames, (size_t)count, sizeof(g_ddhNativeNames[0]), DdhNativeNameCmp);
    int uniq = 0;
    for (int i = 0; i < count; ++i)
    {
        if (uniq == 0 || _stricmp(g_ddhNativeNames[uniq - 1], g_ddhNativeNames[i]) != 0)
        {
            if (uniq != i) strncpy_s(g_ddhNativeNames[uniq], 64, g_ddhNativeNames[i], _TRUNCATE);
            ++uniq;
        }
    }
    count = uniq;
    g_ddhNativeNameCount = count;
    g_ddhNativeDumpDone = 1;

    int hit = 0;
    const int lines = (count + 19) / 20;
    for (int line = 0; line < lines; ++line)
    {
        char buf[2048] = { 0 };
        const int start = line * 20;
        int end = start + 20;
        if (end > count) end = count;
        for (int i = start; i < end; ++i)
        {
            int marked = 0;
            for (int k = 0; k < (int)(sizeof(kDdhNativeKeywords) / sizeof(kDdhNativeKeywords[0])); ++k)
                if (DdhNameHas(g_ddhNativeNames[i], kDdhNativeKeywords[k])) { marked = 1; break; }
            if (marked) ++hit;
            if (i > start) strncat_s(buf, sizeof(buf), ", ", _TRUNCATE);
            if (marked) strncat_s(buf, sizeof(buf), "*", _TRUNCATE);
            strncat_s(buf, sizeof(buf), g_ddhNativeNames[i], _TRUNCATE);
        }
        LogLine("ATTR dump[%d/%d]�?s", line + 1, lines, buf);
    }
    LogLine("ATTR dump：共 %d 个 native，命中关键字 %d 个", count, hit);

    DdhAttrAutoBuild();
}

static const char* DdhAttrUsedName(int id)
{
    if (id >= 0 && id < DDH_AN_COUNT && g_ddhAttrUsedName[id][0]) return g_ddhAttrUsedName[id];
    if (id >= 0 && id < DDH_AN_COUNT) return kDdhAttrNativeName[id];
    return "?";
}

static uint32_t      g_ddhAttrNative[DDH_AN_COUNT];
static volatile LONG g_ddhAttrNativeTries[DDH_AN_COUNT];
static volatile LONG g_ddhAttrNativeLogged[DDH_AN_COUNT];

static volatile LONG g_ddhAttrNoHandleLogged  = 0;
static volatile LONG g_ddhAttrLocustLogged    = 0;   /* v14：属性响应里的蝗虫判定日志，最�?10 �?*/
static volatile LONG g_ddhAttrAlocMissLogged = 0;   /* Aloc 未命中诊断日志计数 */
static volatile LONG g_ddhTypeAlocLogged = 0;
static volatile LONG g_ddhTypeAlocMissLogged = 0;
static volatile LONG g_ddhMemAlocMissLogged = 0;
static volatile LONG g_ddhObjLookupLogged = 0;
static volatile LONG g_ddhTypeIdProbe = 0;
static volatile LONG g_ddhVerifyLogged = 0;
static volatile LONG g_ddhSpdProbe = 0;
static volatile LONG g_ddhSelCompare = 0;
static volatile LONG g_ddhHeroOffResolved = 0;
static volatile LONG g_ddhHeroFailLogged = 0;
static uint32_t       g_ddhHeroOffStr = 0, g_ddhHeroOffAgi = 0, g_ddhHeroOffInt = 0;
static volatile LONG g_ddhAttrTitleFailLogged = 0;
static volatile LONG g_ddhAttrTitleDiag = 0;   /* �?8 次称谓诊断日�?*/
static volatile LONG g_ddhAttrSt0Logged       = 0;
static volatile LONG g_ddhAttrUnitLogged      = 0;
static volatile LONG g_ddhAttrRoundLogged     = 0;
static volatile LONG g_ddhAttrFieldLogged[20];   /* v11�?�?�?�?附加�?说明 �?5 个新�?*/

/* 一条日志只记一次（诊断用；计数器只增不减，代价是几�?InterlockedIncrement�?*/
static void DdhAttrLogOnce(volatile LONG* counter, const char* fmt, ...)
{
    if (!counter || InterlockedIncrement(counter) != 1) return;
    char buf[320] = { 0 };
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(buf, sizeof(buf), _TRUNCATE, fmt, ap);
    va_end(ap);
    LogLine("ATTR�?s", buf);
}

/* 按名字懒解析一个属�?native�?*精确名单优先，关键字模糊匹配只作最后兜�?*�?
   真机日志证明“按名字长度排序的自动匹配”会挑到错的 native�?
     · 移速挑�?GetGameSpeed（返�?0，界面显�?0�?
     · 单位附加值挑�?GetItemUserData（物品自定义值）
     · 视野挑到 UnitShareVision（共享视野开关，根本不是视野�?
   所以顺序改成：�?精确名单（kDdhAttrNativeName �?kDdhAttrNativeName2�?
              �?精确名单全都不存在，才看关键字自动候选（排除名单已过滤）
   视野特殊：一�?native 都不用；白天/夜晚�?jass.slk �?sight/nsight（EXExecuteScript），
   slk 取不到才退�?Game.dll+0x3ADF0 的“当前有效视野”（协议 v14，见 DdhSightRead）�?
   成功/放弃各只记一行日志（每种属性只写一次）�?*/
static uint32_t DdhAttrNative(int id)
{
    if (id < 0 || id >= DDH_AN_COUNT) return 0;
    if (g_ddhAttrNative[id]) return g_ddhAttrNative[id];
    const LONG tries = InterlockedIncrement(&g_ddhAttrNativeTries[id]);
    if (tries > 20) return 0;

    uint32_t fn = 0;
    const char* used = NULL;
    int autoHit = 0;

    /* �?精确名单（规范名 -> 第二精确名） */
    if (kDdhAttrNativeName[id][0])
    {
        fn = FindNativeFunc(kDdhAttrNativeName[id]);
        if (fn) used = kDdhAttrNativeName[id];
    }
    if (!fn && kDdhAttrNativeName2[id][0])
    {
        fn = FindNativeFunc(kDdhAttrNativeName2[id]);
        if (fn) used = kDdhAttrNativeName2[id];
    }

    /* �?最后兜底：关键字自动候选（只在这个字段的精确名单一个都不存在时才会走到�?*/
    for (int i = 0; i < g_ddhAutoCandCount[id] && !fn; ++i)
    {
        if (DdhAttrNameBanned(id, g_ddhAutoCand[id][i])) continue;
        fn = FindNativeFunc(g_ddhAutoCand[id][i]);
        if (fn) { used = g_ddhAutoCand[id][i]; autoHit = 1; }
    }

    if (fn)
    {
        g_ddhAttrNative[id] = fn;
        strncpy_s(g_ddhAttrUsedName[id], 64, used ? used : kDdhAttrNativeName[id], _TRUNCATE);
        if (InterlockedIncrement(&g_ddhAttrNativeLogged[id]) == 1)
            LogLine("ATTR native：%s 已定位（0x%08X，第 %d 次尝试%s）",
                    DdhAttrUsedName(id), fn, (int)tries, autoHit ? "，自动匹配兜底" : "，精确名单");
        return fn;
    }
    if (tries == 20 && InterlockedIncrement(&g_ddhAttrNativeLogged[id]) == 1)
        LogLine("ATTR native：%s 已定位（0x%08X，第 %d 次尝试%s）",
                kDdhAttrNativeName[id]);
    return 0;
}

/* 调一�?native：抓 EAX（JASS 值约定：real = float 位模式），同时抓 ST(0)
   （C 浮点返回约定）。参数固定按 2 �?cdecl �?—�?多传一个栈参数�?cdecl/__fastcall
   都是无害的，而视�?GetHeroStr 正好需要第二参数�?
   注意：被调方如果没往 ST(0) 压东西，fstp 读到的是空栈的“无效值”（NaN 类）�?
   下面只接受有限数，所以不会误用�?*/
static __declspec(naked) void DdhNatCallAsm(uint32_t fn, uint32_t a1, uint32_t a2,
                                           uint32_t* eaxOut, float* st0Out)
{
    __asm
    {
        push ebp
        mov  ebp, esp
        push ebx
        push esi
        mov  ebx, dword ptr [ebp + 20]      /* eaxOut */
        mov  esi, dword ptr [ebp + 24]      /* st0Out */
        push dword ptr [ebp + 16]           /* a2 */
        push dword ptr [ebp + 12]           /* a1 */
        call dword ptr [ebp + 8]            /* fn */
        add  esp, 8
        mov  dword ptr [ebx], eax
        fstp dword ptr [esi]
        pop  esi
        pop  ebx
        pop  ebp
        ret
    }
}

static bool DdhAttrFinite(float v) { return v > -1.0e12f && v < 1.0e12f; }

/* 取一�?real：EAX 位模式优先（与引�?GetUnitState/GetOwningPlayer 同源），
   EAX 不是有限数才退�?ST(0)�?*/
static bool DdhNatCallReal(uint32_t fn, uint32_t handle, uint32_t arg2, float* out)
{
    if (!fn || !out) return false;
    float    st0 = 0.0f;
    uint32_t eax = 0;
    __try { DdhNatCallAsm(fn, handle, arg2, &eax, &st0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    float v = 0.0f;
    memcpy(&v, &eax, 4);
    if (DdhAttrFinite(v)) { *out = v; return true; }
    if (DdhAttrFinite(st0))
    {
        *out = st0;
        DdhAttrLogOnce(&g_ddhAttrSt0Logged,
                       "real 返回值退到 C 浮点约定（ST(0)=%.3f，EAX=0x%08X）：只有 EAX 不是有限数时才会这样",
                       (double)st0, eax);
        return true;
    }
    return false;
}

/* 按候选顺序试，返回命中的候�?id�?1 = 都没拿到值） */
static int DdhAttrTryReals(const int* ids, int n, uint32_t handle, uint32_t arg2, float* out)
{
    for (int i = 0; i < n; i++)
    {
        const uint32_t fn = DdhAttrNative(ids[i]);
        if (!fn) continue;
        float v = 0.0f;
        if (!DdhNatCallReal(fn, handle, arg2, &v)) continue;
        *out = v;
        return ids[i];
    }
    return -1;
}

/* 取一个英雄三�?整数�?native 的数值�?
   GetHeroStr/Agi/Int �?JASS 契约�?integer（EAX=整数），但假魔兽/部分 JAPI �?
   数值按 float 位模式放�?EAX（例�?15.0f = 0x41700000）。这里先按整数认
   �?~1e6），不像数值再�?float 位模式认，最后试 ST(0) —�?两种 ABI 都能拿到值，
   又不会把 15.0f 的位模式当成 10 亿级的巨大力量�?*/
static bool DdhNatCallStatInt(uint32_t fn, uint32_t handle, float* out)
{
    if (!fn || !out) return false;
    float    st0 = 0.0f;
    uint32_t eax = 0;
    __try { DdhNatCallAsm(fn, handle, 1, &eax, &st0); }   /* includeBonuses=1：含绿字加成，和角色面板一致 */
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    const int32_t iv = (int32_t)eax;
    if (iv >= 0 && iv <= 1000000) { *out = (float)iv; return true; }

    float fv = 0.0f;
    memcpy(&fv, &eax, 4);
    if (DdhAttrFinite(fv) && fv >= 0.0f && fv <= 1000000.0f) { *out = fv; return true; }
    if (DdhAttrFinite(st0) && st0 >= 0.0f && st0 <= 1000000.0f) { *out = st0; return true; }
    return false;
}

/* 按候选顺序试英雄三维 native（GetHeroStr/Agi/Int 优先），返回命中 id�?1 = 都没拿到�?*/
static int DdhAttrTryStat(const int* ids, int n, uint32_t handle, float* out)
{
    for (int i = 0; i < n; i++)
    {
        const uint32_t fn = DdhAttrNative(ids[i]);
        if (!fn) continue;
        float v = 0.0f;
        if (!DdhNatCallStatInt(fn, handle, &v)) continue;
        *out = v;
        return ids[i];
    }
    return -1;
}

/* 取一个整�?布尔返回值（EAX）：英雄判定、类型码这类 native 用�?*/
static bool DdhAttrCallU32(int id, uint32_t a1, uint32_t a2, uint32_t* out)
{
    const uint32_t fn = DdhAttrNative(id);
    if (!fn || !out) return false;
    float    st0 = 0.0f;
    uint32_t eax = 0;
    __try { DdhNatCallAsm(fn, a1, a2, &eax, &st0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    *out = eax;
    return true;
}

/* 字段最终解析到的候�?说明：每种字段只写一行日�?*/
static void DdhAttrFieldNote(int slot, const char* text)
{
    if (slot < 0 || slot >= 20) return;
    DdhAttrLogOnce(&g_ddhAttrFieldLogged[slot], "%s", text);
}

/* 4 字符码翻正（内存里反序存�? 只留可显示字�?*/
static void DdhAttrTypeCode(uint32_t code, char* out)
{
    out[0] = out[1] = out[2] = out[3] = out[4] = 0;
    if (!code) return;
    for (int i = 0; i < 4; i++)
    {
        char c = (char)((code >> ((3 - i) * 8)) & 0xFFu);
        if (c < 0x20 || c > 0x7E) c = '?';
        out[i] = c;
    }
}

/* ---- 称谓（英雄专名）----
   优先级（每一级都 __try，失败静默退下一级）�?
     �?DzAPI_UnitType_GetUnitTypeDataString(code, "Propernames")：本图真正的专名数据�?
     �?GetHeroProperName：返�?string id（也可能某些 JAPI 直接返回 char*），两种都试�?
     �?GetUnitName：同样可能是 string id �?char*，两种都试；
     �?都拿不到 �?称谓置空（C# 只显示单位名），绝不再用类型码名字冒充专名�?
   注意：这里只负责“取文本”，是不是英雄由 DdhAttrFillOne �?
   GetUnitTypeId + IsHeroUnitId 判定，避免把商店也当英雄�?*/
#define DDH_RVA_STRING_BY_ID 0x001C2870u
static uint32_t      g_ddhStringById = 0;
static volatile LONG g_ddhStringByIdTries = 0;
static volatile LONG g_ddhStringIdDiag    = 0;   /* �?8 个查表失败的 string id 诊断 */

static uint32_t DdhStringByIdFn(void)
{
    if (g_ddhStringById) return g_ddhStringById;
    if (InterlockedIncrement(&g_ddhStringByIdTries) > 16) return 0;
    g_ddhStringById = HpResolve(DDH_RVA_STRING_BY_ID, NULL);
    if (g_ddhStringById)
        LogLine("ATTR string-id 0x1C2870 = 0x%08X 已定位（称谓反查用）", g_ddhStringById);
    else
        LogLine("ATTR string-id 0x1C2870 没定位到 —— 称谓只能退回“把返回值当 char*”");
    return g_ddhStringById;
}

/* ===========================================================================
   真机字符�?id 反查修复（v18�?
   ---------------------------------------------------------------------------
   真机：GetHeroProperName / GetUnitName 都返回有效的 string id�?x590/0x563 这类），
   但引�?0x1C2870 �?id→char* 反查�?0：它查的�?ctx+0x20 �?UI 字符串表，�?JASS
   字符串实际是�?ctx+8 的另一张表�?intern 的（0x1DA520 �?ctx+8 �?0x7E2D50）�?
   与其继续猜表结构，直接在“字符串入表”函�?0x1DA520 上挂一�?8 字节原子钩子�?
     · 入表前把 char* 文本复制到本地；
     · 调原函数拿到 id�?
     · �?(id �?文本) 存进 128 项环形缓存�?
   这样 ddh 自己�?GetHeroProperName 时，native 内部�?intern 完标题，缓存里就已经�?
   “id �?标题正文”，DdhAttrTextFromIdOrPtr 直接命中，不再依�?0x1C2870�?
   只在游戏线程安装；函数序言不匹配（版本不对/假魔兽）就放弃，不影响原有逻辑�?
   =========================================================================== */
#define DDH_INTERN_RING 128
struct DdhInternEntry
{
    volatile LONG id;
    char          text[64];
};
static DdhInternEntry g_ddhInternRing[DDH_INTERN_RING];
static volatile LONG  g_ddhInternIndex  = 0;
static volatile LONG  g_ddhInternHooked = 0;
static volatile LONG  g_ddhInternTried  = 0;
static uint8_t*       g_ddhInternTramp  = NULL;
static LONG64         g_ddhInternSaved  = 0;

static void DdhInternCachePut(uint32_t id, const char* text)
{
    if (!id || !text || !text[0]) return;
    const LONG slot = InterlockedIncrement(&g_ddhInternIndex) & (DDH_INTERN_RING - 1);
    DdhInternEntry* e = &g_ddhInternRing[slot];
    e->id = 0;
    MemoryBarrier();
    strncpy_s(e->text, sizeof(e->text), text, _TRUNCATE);
    MemoryBarrier();
    e->id = (LONG)id;
}

static int DdhInternCacheFind(uint32_t id, char* out, size_t cap)
{
    if (!id || !out || cap < 2) return 0;
    for (int i = 0; i < DDH_INTERN_RING; ++i)
    {
        DdhInternEntry* e = &g_ddhInternRing[i];
        if (e->id != (LONG)id) continue;
        DdhUtf8SafeCopy(out, cap, e->text, cap - 1);
        if (out[0]) return 1;
    }
    return 0;
}

/* 字符串入表钩子：ECX = char*（原函数 0x1DA520 的非空分支）�?*/
static uint32_t __fastcall DdhInternHook(const char* text)
{
    if (!text) return 0;
    char tmp[64] = { 0 };
    int n = 0;
    __try { for (; n < 63 && text[n]; ++n) tmp[n] = text[n]; }
    __except (EXCEPTION_EXECUTE_HANDLER) { n = 0; }
    tmp[n] = 0;

    uint32_t id = 0;
    __try { id = ((uint32_t (__fastcall*)(const char*))g_ddhInternTramp)(text); }
    __except (EXCEPTION_EXECUTE_HANDLER) { id = 0; }
    if (id && tmp[0]) DdhInternCachePut(id, tmp);
    return id;
}

/* 安装钩子（游戏线程、只一次）。原函数�?8 字节�?
   85 C9 75 03 33 C0 C3 51 (test/jne/xor/ret/push)�?
   8 字节对齐，用 InterlockedExchange64 一次替换成 E9 rel32 + 3×NOP，避免半写指令�?*/
static void DdhInternHookInstall(void)
{
    if (g_ddhInternHooked || !g_modBase) return;
    if (InterlockedCompareExchange(&g_ddhInternTried, 1, 0) != 0) return;

    uint8_t* fn = (uint8_t*)(uintptr_t)(g_modBase + 0x001DA520u);
    const uint8_t sig[8] = { 0x85, 0xC9, 0x75, 0x03, 0x33, 0xC0, 0xC3, 0x51 };
    __try
    {
        if (memcmp(fn, sig, 8) != 0)
        {
            LogLine("ATTR 字符串钩子：0x1DA520 序言不匹配（%02X %02X %02X %02X），不挂",
                    fn[0], fn[1], fn[2], fn[3]);
            return;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return; }

    g_ddhInternTramp = (uint8_t*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!g_ddhInternTramp)
    {
        LogLine("ATTR 字符串钩子：VirtualAlloc 失败 %lu", GetLastError());
        return;
    }

    uint8_t* p = g_ddhInternTramp;
    *p++ = 0x51;                               /* push ecx (char*) */
    *p++ = 0x8B; *p++ = 0x0D;                  /* mov ecx, [ctxGlobal] */
    const uint32_t ctxAddr = g_modBase + 0x00BE4238u;
    memcpy(p, &ctxAddr, 4); p += 4;
    *p++ = 0xE8;                               /* call 0x1BF7C0 */
    const uint32_t target = g_modBase + 0x001BF7C0u;
    const int32_t relCall = (int32_t)(target - ((uint32_t)(uintptr_t)p + 4));
    memcpy(p, &relCall, 4); p += 4;
    *p++ = 0xC3;                               /* ret */
    FlushInstructionCache(GetCurrentProcess(), g_ddhInternTramp, (SIZE_T)(p - g_ddhInternTramp));

    __declspec(align(8)) uint8_t patch[8];
    patch[0] = 0xE9;
    const int32_t relJmp = (int32_t)((uint8_t*)&DdhInternHook - (fn + 5));
    memcpy(patch + 1, &relJmp, 4);
    patch[5] = patch[6] = patch[7] = 0x90;

    DWORD oldProt = 0;
    if (!VirtualProtect(fn, 8, PAGE_EXECUTE_READWRITE, &oldProt))
    {
        LogLine("ATTR 字符串钩子：VirtualProtect 失败 %lu", GetLastError());
        return;
    }
    g_ddhInternSaved = InterlockedExchange64((volatile LONG64*)fn, *(LONG64*)patch);
    VirtualProtect(fn, 8, oldProt, &oldProt);
    FlushInstructionCache(GetCurrentProcess(), fn, 8);
    g_ddhInternHooked = 1;
    LogLine("ATTR 字符串钩子：0x1DA520 已挂（id→文本缓存 %d 项）", DDH_INTERN_RING);
}

/* string id -> char*：先�?intern 钩子缓存，再�?0x1C2870 / �?char*�?*/
static int DdhAttrTextFromIdOrPtr(uint32_t raw, char* out, size_t cap)
{
    out[0] = 0;
    if (!raw) return 0;

    if (DdhInternCacheFind(raw, out, cap))
    {
        if (InterlockedIncrement(&g_ddhStringIdDiag) <= 8)
            LogLine("ATTR string-id：id=0x%X 命中 intern 缓存 text=\"%s\"（不再走 0x1C2870）", raw, out);
        return 1;
    }

    uint32_t ctx = 0;
    const uint32_t byId = DdhStringByIdFn();
    uint32_t p = 0;
    if (byId && PeekU32(g_modBase + DDH_RVA_CTX_GLOBAL, &ctx) && ctx)
    {
        __try { p = ((uint32_t (__fastcall*)(uint32_t, void*, uint32_t))(uintptr_t)byId)(ctx, NULL, raw); }
        __except (EXCEPTION_EXECUTE_HANDLER) { p = 0; }
        if (p && ValidateNameText(p, out, cap) && out[0]) return 1;
    }
    if (ValidateNameText(raw, out, cap) && out[0]) return 1;
    return 0;
}

/* ---- 单位类型数据（UnitStrings / UnitBalance�?---
   平台 native（游戏内 JASS）：
     DzAPI_UnitType_GetUnitTypeDataString(unitTypeId, field)
     DzAPI_UnitType_GetUnitTypeDataInt(unitTypeId, field)
     DzAPI_UnitType_GetUnitTypeDataReal(unitTypeId, field)

   这些是“单位类型”的基础数据（Propernames / spd / sight / nsight / def），
   不在 CUnit 运行期字段里，也不在 unit_property 里；只能在游戏线程调用�?

   v16 关键修正（真机日志：native 已定位，但取�?0/空）�?
     �?字符串参数必须是 **JASS string 句柄** —�?�?DdhMakeJassString �?string_fake
        对象指针（与 DisplayTimedTextToPlayer 同款），绝不能传�?char*�?
     �?实参顺序 / unitTypeId 形态共 2×2=4 种组合，每种只试一次并把结果写日志�?
          DZPROBE order=%d id=%d field=sight -> 0x%08X / int=%d
        选中第一�?sight 落在 100~5000 的组合，写：
          ATTR 单位类型数据：采�?order=%d id形式=%d
        之后所有字段（Propernames/spd/sight/nsight/def/points）都按这个组合调用；
     �?4 种全失败 �?不猜，明确写日志，视�?称谓/基础数据界面一�??�?
   --------------------------------------------------------------------------- */
static uint32_t g_ddhTypeDataStrFn = 0;
static uint32_t g_ddhTypeDataIntFn = 0;
static uint32_t g_ddhTypeDataRealFn = 0;
static volatile LONG g_ddhTypeDataFnLogged = 0;

/* 探测结果：order 0 = (int unitTypeId, string field)�? = (string field, int unitTypeId)
             idForm 0 = 类型�?rawcode（SafeCode）；1 = GetUnitTypeId(handle) 的返回�?*/
static volatile LONG g_ddhTypeDataProbeDone  = 0;
static volatile LONG g_ddhTypeDataProbeTries = 0;
static int g_ddhTypeDataOrder  = 0;
static int g_ddhTypeDataIdForm = 0;
static int g_ddhTypeDataFieldMode = 0;   /* 0 = string_fake 对象指针�? = 引擎 string id */
static int g_ddhTypeDataOk     = 0;

/* 字符串句柄工厂在“结算广播”一节（string_fake 静态池）；这里先用后定义�?*/
static uint32_t DdhMakeJassString(const char* text);

static uint32_t DdhTypeDataFn(const char* name, uint32_t* cache)
{
    if (*cache == 0xFFFFFFFFu) return 0;   /* 已确认找不到，别再反复搜 native �?*/
    if (*cache) return *cache;
    const uint32_t fn = FindNativeFunc(name);
    *cache = fn ? fn : 0xFFFFFFFFu;
    if (InterlockedIncrement(&g_ddhTypeDataFnLogged) <= 6)
        LogLine("ATTR 单位类型数据：%s %s", name, fn ? "命中" : "没找到");
    return fn;
}

/* 调一次类型数�?native：a1 = 第一个实参，a2 = 第二个实参（cdecl 顺序）�?*/
static bool DdhTypeDataCallRaw(uint32_t fn, uint32_t a1, uint32_t a2,
                               uint32_t* eax, float* st0)
{
    if (!fn || !eax || !st0) return false;
    bool ok = false;
    __try
    {
        DdhNatCallAsm(fn, a1, a2, eax, st0);
        ok = true;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { ok = false; }
    return ok;
}

/* 真机 JASS native �?string 实参其实是“字符串 id”（小整数），不�?string_fake 指针�?
   ddh 之前只会�?string_fake，所以假魔兽能过、真�?DzAPI 全返�?0。这里补一条：
   直接用引擎入表函�?0x1DA520 �?"sight"/"nsight" 等造成�?string id�?*/
static uint32_t DdhMakeEngineStringId(const char* text)
{
    if (!g_modBase || !text || !text[0]) return 0;
    typedef uint32_t (__fastcall* fn_make_id)(const char*);
    uint32_t id = 0;
    __try { id = ((fn_make_id)(uintptr_t)(g_modBase + 0x001DA520u))(text); }
    __except (EXCEPTION_EXECUTE_HANDLER) { id = 0; }
    return id;
}

/* 按指�?order / fieldMode 组实参：
   fieldMode 0 = string_fake 对象指针（假魔兽/部分 JAPI 用）�?
   fieldMode 1 = 引擎 string id（真�?JASS native 用）�?*/
static bool DdhTypeDataCallWith(uint32_t fn, int order, int fieldMode, uint32_t unitTypeId,
                                const char* field, uint32_t* eax, float* st0)
{
    if (!fn || !unitTypeId || !field) return false;
    const uint32_t strArg = (fieldMode == 1) ? DdhMakeEngineStringId(field)
                                             : DdhMakeJassString(field);
    if (!strArg) return false;
    if (order == 1) return DdhTypeDataCallRaw(fn, strArg, unitTypeId, eax, st0);
    return DdhTypeDataCallRaw(fn, unitTypeId, strArg, eax, st0);
}

/* 选中组合后，各字段统一按它调用�?*/
static bool DdhTypeDataCallOrdered(uint32_t fn, uint32_t unitTypeId, const char* field,
                                   uint32_t* eax, float* st0)
{
    return DdhTypeDataCallWith(fn, g_ddhTypeDataOrder, g_ddhTypeDataFieldMode,
                               unitTypeId, field, eax, st0);
}

/* unitTypeId 形态：0 = 类型�?rawcode�? = GetUnitTypeId(handle)（拿不到退回码）�?*/
static uint32_t DdhTypeDataUnitId(uint32_t handle, uint32_t code)
{
    if (g_ddhTypeDataIdForm == 1 && handle)
    {
        uint32_t tid = 0;
        if (DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &tid) && tid) return tid;
    }
    return code;
}

/* 取一段“可显示文本”：p 必须可读�? 结尾、无控制字符/0x7F，长�?1..4095�?
   Propernames 可能是一长串（逗号分隔），所以上限放宽，但仍�?out 容量安全截断�?*/
static bool DdhTypeDataTextCopy(uint32_t textPtr, char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    if (textPtr < 0x10000u || textPtr > 0x7FFFFFFFu) return false;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)textPtr;
        if (!p[0]) return false;
        int n = 0;
        for (; n < 4096; ++n)
        {
            const unsigned char c = p[n];
            if (!c) break;
            if (c < 0x20 || c == 0x7F) return false;
        }
        if (n <= 0 || n >= 4096) return false;
        DdhUtf8SafeCopy(out, cap, (const char*)p, cap - 1);
        return out[0] != 0;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { out[0] = 0; return false; }
}

/* String 版返回值三种形态都解（�?DdhAttrTextFromIdOrPtr 同思路）：
     �?string_fake 对象指针：[raw+0x08] -> 对象，[对象+0x1C] -> char*�?
     �?字符串表 id�?x105A 这种小整数）�?0x1C2870 反查�?
     �?�?char*�?
   任何一种解出可显示文本就采用；全程 __try，坏指针只当“没拿到”�?*/
static bool DdhTypeDataText(uint32_t raw, char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    if (!raw) return false;

    /* �?string_fake 对象指针 */
    if (raw >= 0x10000u && raw <= 0x7FFFFFFFu)
    {
        uint32_t obj = 0, txt = 0;
        __try
        {
            obj = *(const uint32_t*)(uintptr_t)(raw + 0x08u);
            if (obj >= 0x10000u && obj <= 0x7FFFFFFFu)
                txt = *(const uint32_t*)(uintptr_t)(obj + 0x1Cu);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { txt = 0; }
        if (txt && DdhTypeDataTextCopy(txt, out, cap)) return true;
    }

    /* �?字符串表 id */
    const uint32_t byId = DdhStringByIdFn();
    if (byId && g_modBase)
    {
        uint32_t ctx = 0;
        if (PeekU32(g_modBase + DDH_RVA_CTX_GLOBAL, &ctx) && ctx)
        {
            uint32_t p = 0;
            __try { p = ((uint32_t (__fastcall*)(uint32_t, void*, uint32_t))(uintptr_t)byId)(ctx, NULL, raw); }
            __except (EXCEPTION_EXECUTE_HANDLER) { p = 0; }
            if (p && DdhTypeDataTextCopy(p, out, cap)) return true;
        }
    }

    /* �?�?char* */
    return DdhTypeDataTextCopy(raw, out, cap);
}

/* 类型数据图标探测：常�?sight 探测失败时，直接�?String �?native �?.blp�?
   有些平台/地图�?sight 字段不可用，�?Art/Icon 字段仍能返回命令卡图标路径�?*/
static bool DdhTypeDataLooksBlp(const char* s)
{
    if (!s) return false;
    const size_t n = strlen(s);
    if (n < 5 || n >= 240) return false;
    for (size_t i = 0; i + 4 <= n; ++i)
        if (s[i] == '.' && _stricmp(s + i, ".blp") == 0) return true;
    return false;
}

static void DdhTypeDataProbeIcon(uint32_t handle, uint32_t code)
{
    if (g_ddhTypeDataOk || !handle || !code) return;
    const uint32_t fn = DdhTypeDataFn("DzAPI_UnitType_GetUnitTypeDataString", &g_ddhTypeDataStrFn);
    if (!fn) return;

    static const char* const fields[] = { "Art", "Icon", "uico", "buttonArt", "ArtIcon" };
    uint32_t tid = 0;
    const bool hasTid = DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &tid) && tid != 0;
    for (int order = 0; order < 2; ++order)
    {
        for (int idForm = 0; idForm < 2; ++idForm)
        {
            if (idForm == 1 && !hasTid) continue;
            const uint32_t idVal = idForm ? tid : code;
            for (int fieldMode = 0; fieldMode < 2; ++fieldMode)
            {
                for (int fi = 0; fi < (int)(sizeof(fields) / sizeof(fields[0])); ++fi)
                {
                    uint32_t eax = 0;
                    float st0 = 0.0f;
                    if (!DdhTypeDataCallWith(fn, order, fieldMode, idVal, fields[fi], &eax, &st0) || !eax)
                        continue;
                    char path[128] = { 0 };
                    if (!DdhTypeDataText(eax, path, sizeof(path))) continue;
                    if (!DdhTypeDataLooksBlp(path)) continue;
                    g_ddhTypeDataOrder = order;
                    g_ddhTypeDataIdForm = idForm;
                    g_ddhTypeDataFieldMode = fieldMode;
                    g_ddhTypeDataOk = 1;
                    LogLine("面板头像：类型数据 String 探测成功 order=%d id=%d fld=%d field=%s path=%s",
                            order, idForm, fieldMode, fields[fi], path);
                    return;
                }
            }
        }
    }
}

/* 4 种实参组合各试一次（field=sight），选中后固定使用。只在拿到句柄的单位上做�?*/
static void DdhTypeDataProbe(uint32_t handle, uint32_t code)
{
    if (g_ddhTypeDataProbeDone) return;
    if (!handle || !code) return;            /* 没句�?没类型码：下一轮再�?*/
    if (InterlockedIncrement(&g_ddhTypeDataProbeTries) > 3) return;

    const uint32_t fnInt = DdhTypeDataFn("DzAPI_UnitType_GetUnitTypeDataInt", &g_ddhTypeDataIntFn);
    if (!fnInt)
    {
        g_ddhTypeDataOk = 0;
        g_ddhTypeDataProbeDone = 1;
        LogLine("ATTR 单位类型数据：Int 版 native 未定位 → 视野/称谓/基础数据只能留 ?（不拿 0 冒充）");
        DdhAttrFieldNote(17, "单位类型数据：Int 版 native 未定位，视野/称谓/基础数据一律 ?");
        return;
    }

    uint32_t tid = 0;
    const bool hasTid = DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &tid) && tid != 0;

    int bestOrder = -1, bestIdForm = -1, bestFieldMode = -1, bestInt = 0;
    /* 2(order) × 2(idForm) × 2(fieldMode) = 8 种组合，每组只调一次；
       选中**第一�?*返回合理值的组合。真机大概率�?fieldMode=1（引�?string id）�?*/
    for (int order = 0; order < 2; ++order)
    {
        for (int idForm = 0; idForm < 2; ++idForm)
        {
            if (idForm == 1 && !hasTid)
            {
                LogLine("DZPROBE order=%d id=%d field=sight -> (GetUnitTypeId 不可用，跳过)",
                        order, idForm);
                continue;
            }
            const uint32_t idVal = (idForm == 1) ? tid : code;
            for (int fieldMode = 0; fieldMode < 2; ++fieldMode)
            {
                uint32_t eax = 0;
                float    st0 = 0.0f;
                const bool okCall = DdhTypeDataCallWith(fnInt, order, fieldMode, idVal, "sight", &eax, &st0);
                const int  iv = okCall ? (int)(int32_t)eax : 0;
                LogLine("DZPROBE order=%d id=%d fld=%d field=sight -> 0x%08X / int=%d",
                        order, idForm, fieldMode, okCall ? eax : 0u, iv);
                if (bestOrder < 0 && okCall && iv >= 100 && iv <= 5000)
                {
                    bestOrder = order;
                    bestIdForm = idForm;
                    bestFieldMode = fieldMode;
                    bestInt = iv;
                }
            }
        }
    }

    if (bestOrder >= 0)
    {
        g_ddhTypeDataOrder = bestOrder;
        g_ddhTypeDataIdForm = bestIdForm;
        g_ddhTypeDataFieldMode = bestFieldMode;
        g_ddhTypeDataOk = 1;
        g_ddhTypeDataProbeDone = 1;
        LogLine("ATTR 单位类型数据：采用 order=%d id形式=%d 字符串形式=%d",
                bestOrder, bestIdForm, bestFieldMode);
        char note[192];
        _snprintf_s(note, sizeof(note), _TRUNCATE,
                    "单位类型数据 ← DzAPI_UnitType_GetUnitTypeData*(order=%d id形式=%d 字符串形式=%d，sight 探测=%d)",
                    bestOrder, bestIdForm, bestFieldMode, bestInt);
        DdhAttrFieldNote(17, note);
        return;
    }

    /* �?0 / 越界：可能第一个单位是建筑或视野为 0，换下一个单位再试（最�?3 个） */
    if (g_ddhTypeDataProbeTries < 3)
    {
        LogLine("ATTR 单位类型数据：第 %d 个单位的 8 种组合都没拿到合理 sight，换下一个单位再试",
                (int)g_ddhTypeDataProbeTries);
        return;
    }

    g_ddhTypeDataOk = 0;
    g_ddhTypeDataProbeDone = 1;
    LogLine("ATTR 单位类型数据�? 种实参组合都取不到合理值（sight 不在 100~5000）→ "
            "退化为只用内存直读 + 现有 native，视�?称谓/基础数据界面显示 ?");
    DdhAttrFieldNote(17, "单位类型数据：8 种组合全部失败（sight 不在 100~5000），视野/称谓/基础数据一律 ?");
}

/* spd / sight / nsight / def / points：优�?Int，拿不到再试 Real�?
   没选中组合（g_ddhTypeDataOk = 0）就一�?native 都不调，直接 false�?*/
static bool DdhTypeDataNumber(uint32_t handle, uint32_t code, const char* field, float* out)
{
    if (!out) return false;
    *out = 0.0f;
    if (!g_ddhTypeDataOk || !field) return false;

    const uint32_t idVal = DdhTypeDataUnitId(handle, code);
    if (!idVal) return false;

    uint32_t eax = 0;
    float    st0 = 0.0f;

    const uint32_t fnInt = DdhTypeDataFn("DzAPI_UnitType_GetUnitTypeDataInt", &g_ddhTypeDataIntFn);
    if (DdhTypeDataCallOrdered(fnInt, idVal, field, &eax, &st0))
    {
        *out = (float)(int32_t)eax;
        return true;
    }

    const uint32_t fnReal = DdhTypeDataFn("DzAPI_UnitType_GetUnitTypeDataReal", &g_ddhTypeDataRealFn);
    if (DdhTypeDataCallOrdered(fnReal, idVal, field, &eax, &st0))
    {
        float v = 0.0f;
        memcpy(&v, &eax, 4);
        if (DdhAttrFinite(v)) { *out = v; return true; }
        if (DdhAttrFinite(st0)) { *out = st0; return true; }
    }
    return false;
}

/* Propernames 文本：返�?true = out 里是可用文本（拿不到/空串返回 false）�?*/
static bool DdhTypeDataString(uint32_t handle, uint32_t code, const char* field,
                              char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    if (!g_ddhTypeDataOk || !field) return false;

    const uint32_t idVal = DdhTypeDataUnitId(handle, code);
    if (!idVal) return false;

    const uint32_t fn = DdhTypeDataFn("DzAPI_UnitType_GetUnitTypeDataString", &g_ddhTypeDataStrFn);
    if (!fn) return false;

    uint32_t eax = 0;
    float    st0 = 0.0f;
    if (!DdhTypeDataCallOrdered(fn, idVal, field, &eax, &st0) || !eax) return false;
    return DdhTypeDataText(eax, out, cap);
}

/* Name-only mode: probe Propernames once without querying combat fields. */
static volatile LONG g_ddhTitleOnlyProbeDone = 0;
static volatile LONG g_ddhTitleOnlyOk = 0;
static int g_ddhTitleOnlyOrder = 0;
static int g_ddhTitleOnlyFieldMode = 0;
static int g_ddhTitleOnlyIdForm = 0;
static int DdhAttrHeroTitle(uint32_t handle, uint32_t code, char* out, size_t cap);

/* Read Propernames directly from CUnit type data. No JASS handle/string ID involved. */
static bool DdhProperNameTextByObject(uint32_t obj, char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    if (!g_modBase || g_imageSize <= 0x0050B550u) return false;
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return false;

    uint32_t typeData = 0;
    __try { typeData = *(const uint32_t*)(uintptr_t)(obj + 0x1F0u); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    if (typeData < 0x10000u || typeData > 0x7FFFFFFFu) return false;

    char text[0x400];
    memset(text, 0, sizeof(text));
    typedef void (__thiscall* fn_proper_name_t)(void*, char*, uint32_t);
    const fn_proper_name_t fn =
        (fn_proper_name_t)(uintptr_t)(g_modBase + 0x0050B550u);
    __try { fn((void*)(uintptr_t)typeData, text, (uint32_t)sizeof(text)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    if (!text[0] || strcmp(text, "The Unknown Hero") == 0) return false;
    DdhUtf8SafeCopy(out, cap, text, cap - 1);
    return out[0] != 0;
}

static bool DdhTypeDataTitleOnly(uint32_t handle, uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    if (!code) return false;

    const uint32_t fn = DdhTypeDataFn("DzAPI_UnitType_GetUnitTypeDataString",
                                      &g_ddhTypeDataStrFn);
    if (!fn) return false;

    if (InterlockedCompareExchange(&g_ddhTitleOnlyProbeDone, 0, 0) == 0)
    {
        uint32_t typeId = 0;
        if (handle)
            DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &typeId);
        const uint32_t ids[2] = { code, typeId };
        for (int idForm = 0; idForm < 2; ++idForm)
        {
            if (!ids[idForm]) continue;
            for (int order = 0; order < 2; ++order)
            {
            for (int fieldMode = 0; fieldMode < 2; ++fieldMode)
            {
                uint32_t eax = 0;
                float st0 = 0.0f;
                if (!DdhTypeDataCallWith(fn, order, fieldMode, ids[idForm],
                                         "Propernames", &eax, &st0) || !eax)
                    continue;
                if (!DdhTypeDataText(eax, out, cap)) continue;

                g_ddhTitleOnlyOrder = order;
                g_ddhTitleOnlyFieldMode = fieldMode;
                g_ddhTitleOnlyIdForm = idForm;
                InterlockedExchange(&g_ddhTitleOnlyOk, 1);
                InterlockedExchange(&g_ddhTitleOnlyProbeDone, 1);
                LogLine("ATTR name-only: Propernames idForm=%d order=%d fieldMode=%d",
                        idForm, order, fieldMode);
                return true;
            }
            }
        }
        InterlockedExchange(&g_ddhTitleOnlyOk, 0);
        InterlockedExchange(&g_ddhTitleOnlyProbeDone, 1);
        LogLine("ATTR name-only: Propernames unavailable");
        return false;
    }

    if (InterlockedCompareExchange(&g_ddhTitleOnlyOk, 0, 0) == 0) return false;
    uint32_t idVal = code;
    if (g_ddhTitleOnlyIdForm == 1)
    {
        idVal = 0;
        if (handle)
            DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &idVal);
        if (!idVal) return false;
    }
    uint32_t eax = 0;
    float st0 = 0.0f;
    if (!DdhTypeDataCallWith(fn, g_ddhTitleOnlyOrder, g_ddhTitleOnlyFieldMode,
                             idVal, "Propernames", &eax, &st0) || !eax)
        return false;
    return DdhTypeDataText(eax, out, cap);
}

struct DdhTitleOnlyCacheEntry
{
    uint32_t code;
    char title[64];
};

static DdhTitleOnlyCacheEntry g_ddhTitleOnlyCache[128];
static int g_ddhTitleOnlyCacheCount = 0;

static bool DdhTitleOnlyCached(uint32_t obj, uint32_t handle, uint32_t code,
                               char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    for (int i = 0; i < g_ddhTitleOnlyCacheCount; ++i)
    {
        if (g_ddhTitleOnlyCache[i].code != code) continue;
        DdhUtf8SafeCopy(out, cap, g_ddhTitleOnlyCache[i].title, cap - 1);
        return out[0] != 0;
    }

    char text[64] = { 0 };
    if (!DdhProperNameTextByObject(obj, text, sizeof(text)))
    {
        if (!DdhTypeDataTitleOnly(handle, code, text, sizeof(text)) || !text[0])
        {
            if (!handle || DdhAttrHeroTitle(handle, code, text, sizeof(text)) <= 0)
                return false;
            LogLine("ATTR name-only: title native fallback code=%s", DdhCodeText(code));
        }
    }
    DdhUtf8SafeCopy(out, cap, text, cap - 1);
    if (g_ddhTitleOnlyCacheCount < 128)
    {
        DdhTitleOnlyCacheEntry* e = &g_ddhTitleOnlyCache[g_ddhTitleOnlyCacheCount++];
        e->code = code;
        DdhUtf8SafeCopy(e->title, sizeof(e->title), text, sizeof(e->title) - 1);
    }
    return out[0] != 0;
}

/* Damage events must capture metadata while the unit is still alive.
   This title path uses only the CUnit-owned type-data pointer we already have. */
static bool DdhCacheTitleByObject(uint32_t obj, uint32_t code)
{
    if (!obj || !code) return false;
    for (int i = 0; i < g_ddhTitleOnlyCacheCount; ++i)
        if (g_ddhTitleOnlyCache[i].code == code && g_ddhTitleOnlyCache[i].title[0])
            return true;

    char title[64] = { 0 };
    if (!DdhProperNameTextByObject(obj, title, sizeof(title)) || !title[0])
        return false;

    if (g_ddhTitleOnlyCacheCount < 128)
    {
        DdhTitleOnlyCacheEntry* e = &g_ddhTitleOnlyCache[g_ddhTitleOnlyCacheCount++];
        e->code = code;
        DdhUtf8SafeCopy(e->title, sizeof(e->title), title, sizeof(e->title) - 1);
    }
    else
    {
        g_ddhTitleOnlyCache[127].code = code;
        DdhUtf8SafeCopy(g_ddhTitleOnlyCache[127].title,
                        sizeof(g_ddhTitleOnlyCache[127].title),
                        title, sizeof(g_ddhTitleOnlyCache[127].title) - 1);
    }
    return true;
}

static bool DdhCachedTitleByCode(uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    if (!code) return false;
    for (int i = 0; i < g_ddhTitleOnlyCacheCount; ++i)
    {
        if (g_ddhTitleOnlyCache[i].code != code) continue;
        DdhUtf8SafeCopy(out, cap, g_ddhTitleOnlyCache[i].title, cap - 1);
        return out[0] != 0;
    }
    return false;
}

/* 类型自带 Aloc？用 DzAPI_UnitType_GetUnitTypeDataString(code, "abilList") 判定并缓存（不依赖句柄）。 */
/* 类型自带 Aloc？逐一尝试几种字段名（不同 DzAPI 版本命名不同），命中即缓存。 */
/* 4 字符类型码 → 可打印文本（日志用，仅游戏线程调用） */

static bool DdhTypeHasAloc(uint32_t code)
{
    static uint32_t hits[512];
    static volatile LONG hitCount = 0;
    const LONG cnt = hitCount;
    for (LONG i = 0; i < cnt && i < 512; ++i) if (hits[i] == code) return true;

    static const char* kFields[] = { "abilList", "abil", "abilities", "AbilityList" };
    char buf[512] = { 0 };
    bool anyOk = false;
    for (int f = 0; f < 4; ++f)
    {
        buf[0] = 0;
        if (!DdhTypeDataString(0, code, kFields[f], buf, sizeof(buf))) continue;
        anyOk = true;
        if (strstr(buf, "Aloc"))
        {
            const LONG slot = InterlockedIncrement(&hitCount) - 1;
            if (slot < 512) hits[slot] = code;
            if (InterlockedIncrement(&g_ddhTypeAlocLogged) <= 10)
                LogLine("ATTR：类型数据命中蝗虫 code=%s 字段=%s 值=%.120s", DdhCodeText(code), kFields[f], buf);
            return true;
        }
    }
    if (InterlockedIncrement(&g_ddhTypeAlocMissLogged) <= 15)
        LogLine("ATTR：类型数据未命中 code=%s 读到了=%d 字段试过 abilList/abil/abilities/AbilityList", DdhCodeText(code), anyOk ? 1 : 0);
    return false;
}



/* 返回 1/2/4 = 文本来源�?=GetHeroProperName 2=GetUnitName 4=Propernames）；0 = 没拿到�?*/
static int DdhAttrHeroTitle(uint32_t handle, uint32_t code, char* out, size_t cap)
{
    out[0] = 0;
    if (!code) return 0;

    /* 诊断：前 8 次把 handle/obj/类型数据状�?每个 native 的原始返回值都写日志�?
       地图自己�?GetHeroProperName 能拿到标题、ddh 直接调却拿不到时，这几行能区�?
       “native 返回 0�?�?“返回了 id 但字符串表反查失败”�?*/
    const bool diag = InterlockedIncrement(&g_ddhAttrTitleDiag) <= 8;
    if (diag)
    {
        char type[8] = { 0 };
        DdhAttrTypeCode(code, type);
        const uint32_t dobj = handle ? HpHandleToUnit(handle) : 0;
        LogLine("ATTR 称谓诊断：handle=0x%08X obj=0x%08X code=%s typeDataOk=%d typeDataOrder=%d",
                handle, dobj, type, (int)g_ddhTypeDataOk, (int)g_ddhTypeDataOrder);
    }

    /* �?平台单位类型数据：Propernames（本图真正的专名来源�?*/
    {
        const bool tdOk = DdhTypeDataString(handle, code, "Propernames", out, cap);
        if (diag) LogLine("ATTR 称谓诊断：Propernames 返回=%d text=\"%s\"", (int)tdOk, out);
        if (tdOk)
        {
            DdhAttrFieldNote(0, "称谓 ← DzAPI_UnitType_GetUnitTypeDataString(\"Propernames\")");
            return 4;
        }
    }

    if (!handle) return 0;

    /* 标题缺失（Propernames 没拿到）才挂字符串入表钩子：
       GetHeroProperName 返回的是 string id，只有抓到入表时�?char* 才能还原标题�?*/
    DdhInternHookInstall();

    /* �?引擎英雄专名 */
    const uint32_t fn = DdhAttrNative(DDH_AN_TITLE);
    if (fn)
    {
        float    st0 = 0.0f;
        uint32_t eax = 0;
        bool     ok = false;
        __try { DdhNatCallAsm(fn, handle, 0, &eax, &st0); ok = true; }
        __except (EXCEPTION_EXECUTE_HANDLER) { ok = false; }
        const int resolved = (ok && eax) ? DdhAttrTextFromIdOrPtr(eax, out, cap) : 0;
        if (diag)
            LogLine("ATTR 称谓诊断：GetHeroProperName(handle=0x%08X) ok=%d eax=0x%08X st0=%.3f resolved=%d text=\"%s\"",
                    handle, (int)ok, eax, (double)st0, resolved, out);
        if (resolved)
        {
            DdhAttrFieldNote(0, "称谓 ← GetUnitName（string id / 指针反查成功）");
            return 1;
        }
        if (ok && eax)
            DdhAttrLogOnce(&g_ddhAttrTitleFailLogged,
                           "GetHeroProperName 返回 0x%08X，但字符串表反查不到文本 → 继续试 GetUnitName",
                           eax);
    }

    /* �?GetUnitName（可能是 string id，也可能直接�?char*�?*/
    const uint32_t fnName = GetUnitNameNative();
    if (fnName)
    {
        float    st0 = 0.0f;
        uint32_t eax = 0;
        bool     ok = false;
        __try { DdhNatCallAsm(fnName, handle, 0, &eax, &st0); ok = true; }
        __except (EXCEPTION_EXECUTE_HANDLER) { ok = false; }
        const int resolvedName = (ok && eax) ? DdhAttrTextFromIdOrPtr(eax, out, cap) : 0;
        if (diag)
            LogLine("ATTR 称谓诊断：GetUnitName(handle=0x%08X) ok=%d eax=0x%08X st0=%.3f resolved=%d text=\"%s\"",
                    handle, (int)ok, eax, (double)st0, resolvedName, out);
        if (resolvedName)
        {
            DdhAttrFieldNote(0, "称谓 ← GetUnitName（string id / 指针反查成功）");
            return 2;
        }
    }

    DdhAttrLogOnce(&g_ddhAttrTitleFailLogged,
                   "称谓：Propernames / GetHeroProperName / GetUnitName 都拿不到文本 → 称谓无效（界面只显示名称）");
    out[0] = 0;
    return 0;
}

/* ===========================================================================
   v15：属性内存直读（YDWE unit_property）—�?优先级高�?native
   ---------------------------------------------------------------------------
   来源：YDWE 源码 `Development\Plugin\Warcraft3\yd_jass_api\UnitState.cpp`�?
     unit_property* ptr = (unit_property*)*(uintptr_t*)(unit_object + 0x1E4 +
                                             (version > version_124c ? 4 : 0));
   我们只打 1.27�? 1.24c），所�?property 指针 = *(uint32_t*)(CUnit + 0x1E8)�?
   unit_property 的类内偏移（同一文件 73 行起注释里的偏移�?.27 口径）：
     +0x88  attack1_damage_dice  (int)     +0x94  attack1_damage_side (int)
     +0xA0  attack1_damage_base  (int)     +0xAC  attack1_damage_bonus(int)
     +0x158 attack1_interval     (float)   +0x244 acquisition_range   (float)
     +0x258 attack1_range        (float)
   护甲不走 prop�?(float*)(CUnit + 0xE0)（YDWE UNIT_STATE_ARMOR 是把位模式透传�?JASS real）�?
   攻击力按 YDWE 的算法：min = base + bonus + dice，max = base + bonus + dice * side�?
   所有读取都�?__try 里；读到的值再做“有�?+ 范围”校验，不过就当无效（界�??）�?
   护甲的真实来源是 CUnit+0xE0（float 位模式，C# 扫描器负责）�?
   本图 ddh 的旧 int32 护甲路径会越界，C# 已不再采用�?
   spd / def �?DzAPI_UnitType_GetUnitTypeData*（类型数据）；协�?v14 起视野改�?jass.slk sight/nsight�?
   slk 取不到时 sightDay 才退�?Game.dll+0x3ADF0�?
   =========================================================================== */
#define DDH_OFF_UNIT_PROP           0x000001E8u  /* CUnit + 0x1E8 = unit_property*�?.27�?*/
#define DDH_OFF_UNIT_ARMOR          0x000000E0u  /* CUnit + 0xE0  = 护甲（float�?*/
#define DDH_OFF_PROP_DMG_DICE       0x00000088u
#define DDH_OFF_PROP_DMG_SIDE       0x00000094u
#define DDH_OFF_PROP_DMG_BASE       0x000000A0u
#define DDH_OFF_PROP_DMG_BONUS      0x000000ACu
#define DDH_OFF_PROP_INTERVAL       0x00000158u
#define DDH_OFF_PROP_ACQUIRE_RANGE  0x00000244u
#define DDH_OFF_PROP_ATTACK_RANGE   0x00000258u
#define DDH_OFF_PROP_RATE_OF_FIRE   0x000001B0u

/* 合理性边界：不在这条线里的值一律按“没测到”处理（界面 ?），绝不�?0 冒充�?*/
#define DDH_ATTR_RANGE_MAX      5000.0f      /* 攻击范围 / 主动攻击范围�? ~ 5000 */
#define DDH_ATTR_INTERVAL_MIN   0.05f        /* 攻击间隔�?.05 ~ 10 �?*/
#define DDH_ATTR_INTERVAL_MAX   10.0f
#define DDH_ATTR_ARMOR_MIN      (-100.0f)    /* 护甲�?100 ~ 1000 */
#define DDH_ATTR_ARMOR_MAX      1000.0f
#define DDH_ATTR_DAMAGE_MAX     1000000.0f   /* 攻击力：0 ~ 1e6 */
#define DDH_ATTR_DICE_MAX       1000         /* dice / side �?int 上限（超了就是读错内存） */
#define DDH_ATTR_DMG_INT_MAX    1000000      /* base / bonus �?int 上限 */

/* 有限性：_finite 比自己写“v == v”稳�?O2 不会�?NaN 检查优化掉）�?*/
static bool DdhAttrIsFinite(float v) { return _finite((double)v) != 0; }

/* 有限 + 落在 [lo, hi]。内存直读和 native 的结果都要过这一关�?*/
static bool DdhAttrFits(float v, float lo, float hi)
{
    if (!DdhAttrIsFinite(v)) return false;
    return v >= lo && v <= hi;
}

/* CUnit -> unit_property*�?.27�?0x1E8）。读不到 / �?0 / 不像指针 / �?4 字节对齐 �?0�?*/
static uint32_t DdhUnitProp(uint32_t unit)
{
    if (unit < 0x10000u || unit > 0x7FFFFFFFu) return 0;
    uint32_t prop = 0;
    __try { prop = *(const uint32_t*)(uintptr_t)(unit + DDH_OFF_UNIT_PROP); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (prop < 0x10000u || prop > 0x7FFFFFFFu) return 0;
    if (prop & 3u) return 0;
    return prop;
}

/* 指针可读性：unit_property 是一整块结构，首尾各读一�?dword，确认没跨进未映射页�?*/
static bool DdhPropReadable(uint32_t prop)
{
    if (!prop) return false;
    uint32_t head = 0, tail = 0;
    __try
    {
        head = *(const uint32_t*)(uintptr_t)prop;
        tail = *(const uint32_t*)(uintptr_t)(prop + DDH_OFF_PROP_ATTACK_RANGE);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    (void)head;
    (void)tail;
    return true;
}

static bool DdhPropF32(uint32_t prop, uint32_t off, float* out)
{
    if (!prop || !out) return false;
    float v = 0.0f;
    __try { v = *(const float*)(uintptr_t)(prop + off); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    *out = v;
    return true;
}

static bool DdhPropI32(uint32_t prop, uint32_t off, int32_t* out)
{
    if (!prop || !out) return false;
    int32_t v = 0;
    __try { v = *(const int32_t*)(uintptr_t)(prop + off); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    *out = v;
    return true;
}

/* 护甲：CUnit+0xE0 �?**float** 读（YDWE UNIT_STATE_ARMOR �?4 字节位模式透传�?JASS real�?
   真机 E06V �?0x430DADBB = 141.679；按 int 读会得到 1124969915，越界）�?*/
static bool DdhUnitArmor(uint32_t unit, float* out)
{
    if (unit < 0x10000u || unit > 0x7FFFFFFFu || !out) return false;
    float v = 0.0f;
    __try { v = *(const float*)(uintptr_t)(unit + DDH_OFF_UNIT_ARMOR); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    *out = v;
    return true;
}

/* 攻击力公式（YDWE 同款）：min = base + bonus + dice，max = base + bonus + dice * side�?
   全程 64 位算，防 int 溢出；结果越界（<0、max<min�?1e6）就当读错内存�?*/
static bool DdhAttrDamageFromDice(int32_t dice, int32_t side, int32_t base, int32_t bonus,
                                  float* outMin, float* outMax)
{
    if (!outMin || !outMax) return false;
    if (dice < 0 || dice > DDH_ATTR_DICE_MAX) return false;
    if (side < 0 || side > DDH_ATTR_DICE_MAX) return false;
    if (base < -DDH_ATTR_DMG_INT_MAX || base > DDH_ATTR_DMG_INT_MAX) return false;
    if (bonus < -DDH_ATTR_DMG_INT_MAX || bonus > DDH_ATTR_DMG_INT_MAX) return false;

    const int64_t lo = (int64_t)base + (int64_t)bonus + (int64_t)dice;
    const int64_t hi = (int64_t)base + (int64_t)bonus + (int64_t)dice * (int64_t)side;
    if (lo < 0 || hi < lo) return false;
    if ((double)hi > (double)DDH_ATTR_DAMAGE_MAX) return false;

    *outMin = (float)lo;
    *outMax = (float)hi;
    return true;
}

static bool DdhReadCUnitCombat(uint32_t unit, DdhEventUnitCombat* out)
{
    if (!out) return false;
    memset(out, 0, sizeof(*out));
    if (unit < 0x10000u || unit > 0x7FFFFFFFu) return false;

    const uint32_t prop = DdhUnitProp(unit);
    const bool propOk = DdhPropReadable(prop);
    float range = 0.0f, interval = 0.0f, rateOfFire = 0.0f, armor = 0.0f;
    int32_t dice = 0, side = 0, base = 0, bonus = 0;

    if (propOk && DdhPropF32(prop, DDH_OFF_PROP_ATTACK_RANGE, &range) &&
        DdhAttrFits(range, 0.0f, DDH_ATTR_RANGE_MAX))
    {
        out->attackRange = range;
        out->flags |= DDH_AF_ATTACKRANGE;
    }
    if (propOk && DdhPropF32(prop, DDH_OFF_PROP_INTERVAL, &interval) &&
        DdhAttrFits(interval, DDH_ATTR_INTERVAL_MIN, DDH_ATTR_INTERVAL_MAX))
    {
        out->attackInterval = interval;
        out->flags |= DDH_AF_INTERVAL;
    }
    if (propOk && DdhPropF32(prop, DDH_OFF_PROP_RATE_OF_FIRE, &rateOfFire) &&
        DdhAttrFits(rateOfFire, 0.0001f, 10000.0f))
    {
        out->attackSpeed = rateOfFire;
        out->flags |= DDH_AF_ATTACK_SPEED;
    }
    if (propOk &&
        DdhPropI32(prop, DDH_OFF_PROP_DMG_DICE, &dice) &&
        DdhPropI32(prop, DDH_OFF_PROP_DMG_SIDE, &side) &&
        DdhPropI32(prop, DDH_OFF_PROP_DMG_BASE, &base) &&
        DdhPropI32(prop, DDH_OFF_PROP_DMG_BONUS, &bonus) &&
        DdhAttrDamageFromDice(dice, side, base, bonus, &out->damageMin, &out->damageMax))
    {
        out->flags |= DDH_AF_DAMAGE;
    }
    if (DdhUnitArmor(unit, &armor) && DdhAttrFits(armor, DDH_ATTR_ARMOR_MIN, DDH_ATTR_ARMOR_MAX))
    {
        out->armor = armor;
        out->flags |= DDH_AF_ARMOR;
    }
    return out->flags != 0;
}

static volatile LONG g_ddhPropRawLogged = 0;   /* ATTR prop 原始值日志只写前 6 个单�?*/

/* 内存直读一遍：攻击范围 / 攻击�?/ 攻击间隔 / 护甲 / 主动攻击范围�?
   不依�?JASS 句柄，所以在“句柄检查”之前调用；读不到或不合理就什么都不写�?
   由后面的 native 兜底（移�?类型基础数据/英雄判定仍然只能�?native）�?*/
static void DdhAttrFillMemory(uint32_t unit, uint32_t prop, bool propOk, DdhUnitAttr* out)
{
    float   mRange = 0.0f, mInterval = 0.0f, mAcquire = 0.0f, mRateOfFire = 0.0f;
    int32_t mDice = 0, mSide = 0, mBase = 0, mBonus = 0;
    float   mArmor = 0.0f;
    bool okRange = false, okInterval = false, okAcquire = false, okDmg = false, okArmor = false;
    bool okRateOfFire = false;
    uint32_t okMask = 0;

    if (propOk)
    {
        okRange    = DdhPropF32(prop, DDH_OFF_PROP_ATTACK_RANGE, &mRange);
        okInterval = DdhPropF32(prop, DDH_OFF_PROP_INTERVAL, &mInterval);
        okAcquire  = DdhPropF32(prop, DDH_OFF_PROP_ACQUIRE_RANGE, &mAcquire);
        okRateOfFire = DdhPropF32(prop, DDH_OFF_PROP_RATE_OF_FIRE, &mRateOfFire);
        okDmg      = DdhPropI32(prop, DDH_OFF_PROP_DMG_DICE, &mDice) &&
                     DdhPropI32(prop, DDH_OFF_PROP_DMG_SIDE, &mSide) &&
                     DdhPropI32(prop, DDH_OFF_PROP_DMG_BASE, &mBase) &&
                     DdhPropI32(prop, DDH_OFF_PROP_DMG_BONUS, &mBonus);
    }
    okArmor = DdhUnitArmor(unit, &mArmor);
    if (okRange)    okMask |= 0x01u;
    if (okInterval) okMask |= 0x02u;
    if (okAcquire)  okMask |= 0x04u;
    if (okDmg)      okMask |= 0x08u;
    if (okArmor)    okMask |= 0x10u;
    if (okRateOfFire) okMask |= 0x20u;

    /* ---- 攻击范围（prop+0x258�?--- */
    if (okRange && DdhAttrFits(mRange, 0.0f, DDH_ATTR_RANGE_MAX))
    {
        out->attackRange = mRange;
        out->flags |= DDH_AF_ATTACKRANGE;
        DdhAttrFieldNote(1, "攻击范围 ← unit_property+0x258（内存直读）");
    }

    /* ---- 攻击力（dice/side/base/bonus 都是 int�?--- */
    if (okDmg)
    {
        float dmin = 0.0f, dmax = 0.0f;
        if (DdhAttrDamageFromDice(mDice, mSide, mBase, mBonus, &dmin, &dmax))
        {
            out->damageMin = dmin;
            out->damageMax = dmax;
            out->flags |= DDH_AF_DAMAGE;
            char note[224];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "攻击�?�?unit_property（dice=%d side=%d base=%d bonus=%d �?%.0f~%.0f，内存直读）",
                        (int)mDice, (int)mSide, (int)mBase, (int)mBonus, (double)dmin, (double)dmax);
            DdhAttrFieldNote(2, note);
        }
    }

    /* ---- 攻击间隔（prop+0x158，秒�?--- */
    if (okInterval && DdhAttrFits(mInterval, DDH_ATTR_INTERVAL_MIN, DDH_ATTR_INTERVAL_MAX))
    {
        out->attackInterval = mInterval;
        out->flags |= DDH_AF_INTERVAL;
        DdhAttrFieldNote(3, "攻击间隔 ← unit_property+0x158（内存直读，秒）");
    }

    /* YDWE UnitState.cpp: UNIT_STATE_RATE_OF_FIRE (0x51/81) = unit_property + 0x1B0. */
    if (okRateOfFire && DdhAttrFits(mRateOfFire, 0.0001f, 10000.0f))
    {
        out->attackSpeed = mRateOfFire;
        out->flags |= DDH_AF_ATTACK_SPEED;
        char note[160];
        _snprintf_s(note, sizeof(note), _TRUNCATE,
                    "attack speed <- unit_property+0x1B0 (%.4f)", (double)mRateOfFire);
        DdhAttrFieldNote(19, note);
    }

    /* ---- 护甲（CUnit+0xE0，float�?--- */
    if (okArmor && DdhAttrFits(mArmor, DDH_ATTR_ARMOR_MIN, DDH_ATTR_ARMOR_MAX))
    {
        out->armor = mArmor;
        out->flags |= DDH_AF_ARMOR;
        char note[160];
        _snprintf_s(note, sizeof(note), _TRUNCATE,
                    "护甲 ← CUnit+0xE0（float 内存直读，值 %.2f）", (double)mArmor);
        DdhAttrFieldNote(4, note);
    }

    /* ---- 主动攻击范围（prop+0x244�?--- */
    if (okAcquire && DdhAttrFits(mAcquire, 0.0f, DDH_ATTR_RANGE_MAX))
    {
        out->acquireRange = mAcquire;
        out->flags |= DDH_AF_ACQUIRE;
        DdhAttrFieldNote(7, "主动攻击范围 ← unit_property+0x244（内存直读）");
    }

    /* 真机排查：前 6 个单位把 prop 指针和原始字段值打出来（ok �?= 这次读成功的字段�?
       1=范围 2=间隔 4=主动 8=dice/side/base/bonus 16=护甲）�?*/
    if (InterlockedIncrement(&g_ddhPropRawLogged) <= 6)
    {
        if (!propOk)
            LogLine("ATTR prop：addr=0x%08X prop=0x%08X 不可读（CUnit+0x1E8 �?0/坏指�?未对齐）"
                    "�?范围/攻击�?间隔/主动 全部无效（走 native 兜底）；护甲仍试 CUnit+0xE0",
                    unit, prop);
        else
            LogLine("ATTR prop：addr=0x%08X prop=0x%08X ok=0x%02X range=%.2f 间隔=%.3f 主动=%.1f "
                    "dice/side/base/bonus=%d/%d/%d/%d 护甲=%.2f",
                    unit, prop, okMask, (double)mRange, (double)mInterval, (double)mAcquire,
                    (int)mDice, (int)mSide, (int)mBase, (int)mBonus, (double)mArmor);
    }
}

/* ===========================================================================
   v20：视�?= game.dll 的通用字段读取器（WFE 逆向确认�?.27.0.52240 / build 0xCC10�?
   v14 起它只是**兜底**：白�?夜晚优先�?jass.slk �?sight/nsight（DdhExSlkNumber），
   只有 slk sight 取不到时才用这里�?sightDay；sightNight 不读它�?
   ---------------------------------------------------------------------------
   WFE �?Detailed Defense Tip / Draw Sight Radius 调用点（照抄）：
       mov  eax, [game.dll + 0x3ADF0]     ; 通用字段读取函数
       lea  ecx, [unit + 0xFC]            ; ecx = 运行时字段描述符（[+8]=字段 ID、[+C]=类型�?
       lea  edx, [ebp-8]                  ; &out
       push edx                           ; 栈参数：float* out
       xor  edx, edx                      ; 第二参数 = 0
       call eax
       movss xmm0, [ebp-8]                ; �?当前有效视野（float�?
   函数内部 `mov edx,[ecx+0xC]`（字段类型）/ `mov ecx,[ecx+8]`（字�?ID）到全局字段�?
   [game.dll + 0xC296A8] 查字段对象，返回 clamp(基础+加成, min, max)。所�?out 里是
   **当前有效视野**：游戏已按昼夜把 sight/nsight 选好写回，是单值�?
   浮点返回值不可靠（EAX/ST0 都别信）�?*�?out 的值为�?*�?
   =========================================================================== */
#define DDH_RVA_SIGHT_FIELD     0x0003ADF0u   /* 1.27.0.52240：通用字段读取�?*/
#define DDH_OFF_UNIT_FIELD_DESC 0x000000FCu   /* CUnit + 0xFC = 运行时字段描述符 */
#define DDH_ATTR_SIGHT_MIN      100.0f        /* 合理视野下限（低于它按“没测到”处理） */
#define DDH_ATTR_SIGHT_MAX      5000.0f       /* 合理视野上限（高于它按“没测到”处理） */

static uint32_t      g_ddhSightFn        = 0;   /* 解析成功的函数地址�? = 不可用） */
static volatile LONG g_ddhSightTried     = 0;   /* 只解�?校验一�?*/
static volatile LONG g_ddhSightFailShown = 0;   /* “不可用”原因只写一�?*/
static volatile LONG g_ddhSightOkShown   = 0;   /* “视�?�?…”只在首次成功时写一�?*/
static volatile LONG g_ddhSightExcCount  = 0;   /* 调用异常计数（只记前 3 条） */
static volatile LONG g_ddhSightBadCount  = 0;   /* 返回值越界计数（只记�?3 条） */

/* 解析 + 校验 Game.dll+0x3ADF0�?
   �?必须�?game.dll 基址�?
   �?RVA 必须落在 game.dll 的映像大小内（假魔兽/换版本最常见的失败原因）�?
   �?目标页必须是**已提交且可执�?*的（.data / 0 填充页一律不算函数）�?
   �?前几字节不能�?0x00 / 0xCC / 0xFF 这类填充（“非空实现”）�?
   任一条不过：只在日志里写一行原因，之后这个字段一律按无效处理（界�??），不再重试�?*/
static bool DdhSightResolveAt(uint32_t rva, uint32_t* outFn, char* why, size_t whyCap)
{
    if (outFn) *outFn = 0;
    if (why && whyCap) why[0] = 0;
    if (!g_modBase)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE, "game.dll 基址未知（InstallHook 还没跑到）");
        return false;
    }
    if (g_imageSize == 0)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE, "game.dll 映像大小未知（PE 头没读到），不敢按 RVA 调函数");
        return false;
    }

    const uint32_t addr = g_modBase + rva;
    if (rva + 16u > g_imageSize)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE,
                             "RVA 0x%X 超出 game.dll 映像大小 0x%X（这个 game.dll 里没有该函数）",
                             rva, g_imageSize);
        return false;
    }

    /* 可执行页校验�?data / 未提交页 / 0 填充都不算函数，绝不�?call�?*/
    MEMORY_BASIC_INFORMATION mbi;
    memset(&mbi, 0, sizeof(mbi));
    if (VirtualQuery((LPCVOID)(uintptr_t)addr, &mbi, sizeof(mbi)) == 0 || mbi.State != MEM_COMMIT)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE,
                             "0x%08X 不是已提交内存（VirtualQuery 失败 / 页未提交）", addr);
        return false;
    }
    const DWORD prot = mbi.Protect & 0xFFu;
    if (prot != PAGE_EXECUTE && prot != PAGE_EXECUTE_READ &&
        prot != PAGE_EXECUTE_READWRITE && prot != PAGE_EXECUTE_WRITECOPY)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE,
                             "0x%08X 页不可执行（Protect=0x%X，是数据页/空洞，不是函数）",
                             addr, (unsigned)mbi.Protect);
        return false;
    }

    uint32_t head = 0;
    if (!PeekU32(addr, &head))
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE, "0x%08X 读不到前 4 字节", addr);
        return false;
    }
    const uint8_t* p = (const uint8_t*)&head;
    if (p[0] == 0x00 || p[0] == 0xCC || p[0] == 0xFF || head == 0x00000000u || head == 0xCCCCCCCCu)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE,
                             "序言像填充（%02X %02X %02X %02X），不是有效函数",
                             p[0], p[1], p[2], p[3]);
        return false;
    }

    if (outFn) *outFn = addr;
    return true;
}

/* 懒解析一次（成功/失败都只做一次；失败原因只写一行日志） */
static bool DdhSightFnReady(void)
{
    if (InterlockedCompareExchange(&g_ddhSightTried, 1, 0) != 0)
        return g_ddhSightFn != 0;

    uint32_t fn = 0;
    char why[192] = { 0 };
    if (!DdhSightResolveAt(DDH_RVA_SIGHT_FIELD, &fn, why, sizeof(why)))
    {
        DdhAttrLogOnce(&g_ddhSightFailShown,
                       "视野：Game.dll+0x%X 不可用（%s）→ 视野无效（界面 ?）",
                       (unsigned)DDH_RVA_SIGHT_FIELD, why);
        return false;
    }
    g_ddhSightFn = fn;
    LogLine("ATTR 视野：Game.dll+0x%X 通用字段读取器已解析（0x%08X，映像大小 0x%X）",
            (unsigned)DDH_RVA_SIGHT_FIELD, fn, g_imageSize);
    return true;
}

/* 调一次通用字段读取器：ecx = &CUnit+0xFC、edx = 0、栈�?float* out（严格按 WFE 调用点）�?
   收尾�?`mov esp, ebp` 强制恢复自己的帧：被调方到底 ret 还是 ret 4（清栈参数）都不会把
   我们的栈弄坏；也不占用任�?callee-saved 寄存器�?*/
static __declspec(naked) void DdhSightCallAsm(uint32_t fn, uint32_t desc, float* out)
{
    __asm
    {
        push ebp
        mov  ebp, esp
        push dword ptr [ebp + 16]      /* 栈参数：float* out */
        xor  edx, edx                  /* 第二参数 = 0（WFE 调用点同款） */
        mov  ecx, dword ptr [ebp + 12] /* &CUnit+0xFC（运行时字段描述符） */
        call dword ptr [ebp + 8]       /* Game.dll+0x3ADF0 */
        mov  esp, ebp                  /* 不管被调方有没有 ret 4，都按自己的帧恢�?esp */
        pop  ebp
        ret
    }
}

/* 读一个单位的“当前有效视野”：成功 �?true �?*outSight = 值（100~5000）�?
   失败（函数不可用 / 调用异常 / 返回值越界）�?false（视野无效，界面 ?），原因写日志�?
   只认 out，不信浮点返回值（WFE 结论）�?*/
static bool DdhSightRead(uint32_t unit, float* outSight)
{
    if (!outSight) return false;
    *outSight = -1.0f;
    if (unit < 0x10000u || unit > 0x7FFFFFFFu) return false;
    if (!DdhSightFnReady()) return false;

    float v = -1.0f;
    DWORD exc = 0;
    __try { DdhSightCallAsm(g_ddhSightFn, unit + DDH_OFF_UNIT_FIELD_DESC, &v); }
    __except (EXCEPTION_EXECUTE_HANDLER) { exc = GetExceptionCode(); }

    if (exc)
    {
        if (InterlockedIncrement(&g_ddhSightExcCount) <= 3)
            LogLine("ATTR：视野读取异常 code=0x%08X（unit=0x%08X &unit+0xFC=0x%08X）→ 视野无效（界面 ?）",
                    (unsigned)exc, unit, unit + DDH_OFF_UNIT_FIELD_DESC);
        return false;
    }
    if (!DdhAttrFits(v, DDH_ATTR_SIGHT_MIN, DDH_ATTR_SIGHT_MAX))
    {
        if (InterlockedIncrement(&g_ddhSightBadCount) <= 3)
            LogLine("ATTR：视野返回值越界（unit=0x%08X out=%.3f，合理范围 %.0f~%.0f）→ 视野无效（界面 ?）",
                    unit, (double)v, (double)DDH_ATTR_SIGHT_MIN, (double)DDH_ATTR_SIGHT_MAX);
        return false;
    }
    *outSight = v;
    return true;
}

/* ===========================================================================
   v20：jass.slk 交叉核对 / 视野兜底（EXExecuteScript�?
   ---------------------------------------------------------------------------
   本图�?YDWE �?jass.slk Lua 模块，可以用原生 EXExecuteScript 按字段名读任�?slk�?
       EXExecuteScript("(require'jass.slk').unit[<类型 id 十进�?].<字段�?")
   类型 id 就是类型码的十进制（'H038' = 0x48303338 = 1210079032）�?
   实参形式不再写死：v22 �?"1+1" 探针在引�?id / �?char* / string_fake 等形式里选一�?
   （v23 增加 string_fake 三种 + 引擎 id 反查 char*），选中�?sight/nsight/spd/def 统一走它�?
   返回值既可能�?string id 也可能是 string_fake 指针，两种形态都解；
     · 所有调用只在游戏线程（属性请求通道）里做，表达式长�?< 160�?
   v22（真�?ddh-4848.log：四种字�?EX 全返�?eax=0）：先用探针把“实参形式”与
   “表达式/typeId 写法”分开定位（DdhExFormProbe），验证通过的形式才是之�?
   sight/nsight/spd/def 用的那一种；一种都不通就保持现状（引�?id + 数字下标）�?
   本块只做两件事：
     �?每进程一次核�?sight / nsight / spd / def（写日志，不改字段）�?
     �?视野�?*主路**：按类型码读 jass.slk �?sight（白天视野）�?nsight（夜晚视野）�?
        slk 取不到时才退�?Game.dll+0x3ADF0 的“当前有效视野”填 sightDay�?
        sightNight 保持无效（界�??）�?
   EXExecuteScript 是地�?JAPI 注册�?native；没�?jass.slk 模块的图（含假魔兽）找不到，
   只写“未找到”，不影响任何字段�?
   =========================================================================== */
#define DDH_EX_EXPR_MAX     160
#define DDH_EX_TEXT_MAX     128
#define DDH_EX_SLK_CACHE    24       /* 按类型码缓存 sight/nsight 两字�?*/
#define DDH_EX_SLK_CALLS    48       /* 24 类型 × 2 字段：本进程最多查这么多次 */
/* ---- v22/v23：EXExecuteScript 的“实参形�?/ 表达式形式�?------------------------
   真机 ddh-4848.log：sight/nsight/spd/def 四种字段�?EXExecuteScript 全返�?eax=0�?
   说明问题不在解析，而在**调用本身没返�?*。两种可能：
     �?实参形式不对：引�?string id / �?const char* / string_fake 对象指针？要不要第二个参数？
     �?表达�?typeId 不对：unit[十进制] 还是 unit["H038"]�?sight 还是 ["sight"]�?
   探针用一个必然成功的常量表达�?"1+1"（Lua 求�?= 2）区分实参形式：
     A1 = 引擎 string id�? 参，第二�?0，现状）     A2 = �?const char*（同上）
     A3 = 引擎 string id（第二参 1�?               A4 = �?const char*（第二参 1�?
     A5 = 引擎 string id（只�?1 个参数）           A6 = �?const char*（只�?1 个参数）
   真机 ddh-9128.log：A1~A6 全失败（引擎 id �?0xC0000005、裸 char* 返回 0）→ v23 追加�?
     A7  = string_fake 对象指针�?0x08 自指�?0x1C 正文�? 第二�?0
     A8  = string_fake 对象指针 + 第二�?1
     A9  = string_fake 对象指针，只�?1 个参�?
     A10 = 引擎 string id 反查出的 char*（engine-pool，第二参 0；A7~A9 全失败才试）
   再用 slk 表达式区分写法（B 组，全部�?A 组选中的实参形式）�?
     B1 = unit[十进制].sight（现状写法，真实 sight 表达式）
     B2 = 仅当选中引擎 id 时，用裸 char* 再跑一次同一写法（旧日志对照�?
     B3 = unit["H038"].sight   B4 = unit[十进制]["sight"]   B5 = unit["H038"]["sight"]
   每种一�?EXFORM <标签> form=... arg=... -> eax=... text="..." num=...�?
   拿到 2 的那一种就是可用形式，写“采用实参形式”，之后 sight/nsight/spd/def 都用它�?*/
#define DDH_EX_FORM_NONE    0
#define DDH_EX_FORM_ID      1   /* 引擎 string id + 第二�?0（现状） */
#define DDH_EX_FORM_PTR     2   /* �?const char* + 第二�?0 */
#define DDH_EX_FORM_ID_A2   3   /* 引擎 string id + 第二�?1 */
#define DDH_EX_FORM_PTR_A2  4   /* �?const char* + 第二�?1 */
#define DDH_EX_FORM_ID_1    5   /* 引擎 string id，只�?1 个参�?*/
#define DDH_EX_FORM_PTR_1   6   /* �?const char*，只�?1 个参�?*/
#define DDH_EX_FORM_FAKE    7   /* string_fake 对象指针 + 第二�?0 */
#define DDH_EX_FORM_FAKE_A2 8   /* string_fake 对象指针 + 第二�?1 */
#define DDH_EX_FORM_FAKE_1  9   /* string_fake 对象指针，只�?1 个参�?*/
#define DDH_EX_FORM_ENG_PTR 10  /* 引擎 string id 反查出的 char* + 第二�?0 */

#define DDH_EX_EXPR_NUM_DOT 0   /* (require'jass.slk').unit[12345].sight（现状） */
#define DDH_EX_EXPR_STR_DOT 1   /* (require'jass.slk').unit["H038"].sight */
#define DDH_EX_EXPR_NUM_BRK 2   /* (require'jass.slk').unit[12345]["sight"] */
#define DDH_EX_EXPR_STR_BRK 3   /* (require'jass.slk').unit["H038"]["sight"] */

/* �?char* 形式用的静态缓冲（ddh 自己�?.data，保证可读、地址稳定）�?*/
static char          g_ddhExArgText[DDH_EX_EXPR_MAX + 8];
static volatile LONG g_ddhExArgForm       = DDH_EX_FORM_ID;        /* 已验证可用的实参形式 */
static volatile LONG g_ddhExExprForm      = DDH_EX_EXPR_NUM_DOT;   /* 已验证可用的表达式形�?*/
static volatile LONG g_ddhExFormProbeDone = 0;
static volatile LONG g_ddhExLastExc       = 0;

static const char* DdhExFormName(int form)
{
    switch (form)
    {
    case DDH_EX_FORM_ID:     return "引擎id/2参(第二参0)";
    case DDH_EX_FORM_PTR:    return "char*/2参(第二参0)";
    case DDH_EX_FORM_ID_A2:  return "引擎id/2参(第二参1)";
    case DDH_EX_FORM_PTR_A2: return "char*/2参(第二参1)";
    case DDH_EX_FORM_ID_1:   return "引擎id/1参";
    case DDH_EX_FORM_PTR_1:  return "char*/1参";
    case DDH_EX_FORM_FAKE:    return "string_fake/2参(第二参0)";
    case DDH_EX_FORM_FAKE_A2: return "string_fake/2参(第二参1)";
    case DDH_EX_FORM_FAKE_1:  return "string_fake/1参";
    case DDH_EX_FORM_ENG_PTR: return "char*(engine-pool)/2参(第二参0)";
    default:                 return "?";
    }
}

static const char* DdhExExprName(int form)
{
    switch (form)
    {
    case DDH_EX_EXPR_NUM_DOT: return "unit[十进制].字段（现状）";
    case DDH_EX_EXPR_STR_DOT: return "unit[类型码].字段";
    case DDH_EX_EXPR_NUM_BRK: return "unit[十进制][字段]";
    case DDH_EX_EXPR_STR_BRK: return "unit[类型码][字段]";
    default:                  return "膵";
    }
}

/* 1 个参数的 cdecl 调用（只�?1 个参数）：先保存 EBX/ESI，调用后**�?EBP 恢复 ESP**
   （被调方�?stdcall / ret 4 也不会把栈搞乱），再�?EAX �?ST(0)�?*/
static __declspec(naked) void DdhNatCall1Asm(uint32_t fn, uint32_t a1,
                                             uint32_t* eaxOut, float* st0Out)
{
    __asm
    {
        push ebp
        mov  ebp, esp
        push ebx
        push esi
        mov  ebx, dword ptr [ebp + 16]      /* eaxOut */
        mov  esi, dword ptr [ebp + 20]      /* st0Out */
        push dword ptr [ebp + 12]           /* a1 */
        call dword ptr [ebp + 8]            /* fn */
        lea  esp, [ebp - 8]                 /* 不管被调方怎么清栈，都回到自己的帧 */
        mov  dword ptr [ebx], eax
        fstp dword ptr [esi]
        pop  esi
        pop  ebx
        pop  ebp
        ret
    }
}

/* 2 个参数的 cdecl 调用，同样用 EBP 恢复 ESP（探针专用；不动原来�?DdhNatCallAsm）�?*/
static __declspec(naked) void DdhNatCall2SafeAsm(uint32_t fn, uint32_t a1, uint32_t a2,
                                                  uint32_t* eaxOut, float* st0Out)
{
    __asm
    {
        push ebp
        mov  ebp, esp
        push ebx
        push esi
        mov  ebx, dword ptr [ebp + 20]      /* eaxOut */
        mov  esi, dword ptr [ebp + 24]      /* st0Out */
        push dword ptr [ebp + 16]           /* a2 */
        push dword ptr [ebp + 12]           /* a1 */
        call dword ptr [ebp + 8]            /* fn */
        lea  esp, [ebp - 8]                 /* �?DdhNatCall1Asm */
        mov  dword ptr [ebx], eax
        fstp dword ptr [esi]
        pop  esi
        pop  ebx
        pop  ebp
        ret
    }
}

/* 按一种“实参形式”调一�?EXExecuteScript�?
   返回 0 = 实参没造出来（没调）；1 = 调通；2 = 调用异常（eax/st0 清零，code �?g_ddhExLastExc）�?
   argOut 带回真正压进去的第一个实参（探针日志用）�?
   ID 形式�?0x1DA520 造真引擎 string id；PTR 形式�?ddh 自己的静态缓冲�?*/
static int DdhExCallForm(uint32_t fn, int form, const char* expr,
                         uint32_t* argOut, uint32_t* eax, float* st0)
{
    if (argOut) *argOut = 0;
    if (eax) *eax = 0;
    if (st0) *st0 = 0.0f;
    if (!fn || !expr || !expr[0] || !eax || !st0) return 0;

    uint32_t arg = 0;
    if (form == DDH_EX_FORM_ID || form == DDH_EX_FORM_ID_A2 || form == DDH_EX_FORM_ID_1)
    {
        DdhInternHookInstall();          /* 抓到 EX 返回串的 id -> 文本（装过就直接返回�?*/
        arg = DdhMakeEngineStringId(expr);
        if (!arg) return 0;              /* 0x1DA520 没给�?string id */
    }
    else if (form == DDH_EX_FORM_FAKE || form == DDH_EX_FORM_FAKE_A2 ||
             form == DDH_EX_FORM_FAKE_1)
    {
        /* string_fake 对象指针�?0x08 指向自身�?0x1C �?char* 正文�?
           每次调用前重新构造（引擎可能改写这个对象，不能复用上一次的指针）�?*/
        arg = DdhMakeJassString(expr);
        if (!arg) return 0;
    }
    else if (form == DDH_EX_FORM_ENG_PTR)
    {
        /* 引擎 string id -> char*（现有反查；真机 JASS 串可能只命中 intern 缓存副本）�?*/
        DdhInternHookInstall();
        const uint32_t id = DdhMakeEngineStringId(expr);
        if (!id) return 0;
        char tmp[DDH_EX_EXPR_MAX + 8] = { 0 };
        if (!DdhAttrTextFromIdOrPtr(id, tmp, sizeof(tmp))) return 0;
        strncpy_s(g_ddhExArgText, sizeof(g_ddhExArgText), tmp, _TRUNCATE);
        arg = (uint32_t)(uintptr_t)g_ddhExArgText;
    }
    else
    {
        strncpy_s(g_ddhExArgText, sizeof(g_ddhExArgText), expr, _TRUNCATE);
        arg = (uint32_t)(uintptr_t)g_ddhExArgText;
    }
    if (argOut) *argOut = arg;

    int rc = 1;
    __try
    {
        if (form == DDH_EX_FORM_ID_1 || form == DDH_EX_FORM_PTR_1 ||
            form == DDH_EX_FORM_FAKE_1)
            DdhNatCall1Asm(fn, arg, eax, st0);
        else if (form == DDH_EX_FORM_ID_A2 || form == DDH_EX_FORM_PTR_A2 ||
                 form == DDH_EX_FORM_FAKE_A2)
            DdhNatCall2SafeAsm(fn, arg, 1u, eax, st0);
        else
            DdhNatCall2SafeAsm(fn, arg, 0u, eax, st0);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        g_ddhExLastExc = (LONG)GetExceptionCode();
        *eax = 0;
        *st0 = 0.0f;
        rc = 2;
    }
    return rc;
}


static uint32_t      g_ddhExFn        = 0;
static volatile LONG g_ddhExTries     = 0;
static volatile LONG g_ddhExMissLog   = 0;
static volatile LONG g_ddhExFoundLog  = 0;
static volatile LONG g_ddhExExprFailLog = 0;
static volatile LONG g_ddhExProbeDone = 0;
static volatile LONG g_ddhExCodedSeen = 0;
static volatile LONG g_ddhExFallbackExcLog = 0;
static volatile LONG g_ddhExProbeExcLog = 0;
static volatile LONG g_ddhExSlkSightLogged = 0;
static volatile LONG g_ddhExSlkNightLogged = 0;
static volatile LONG g_ddhExSlkFailLogged  = 0;
static uint32_t      g_ddhExLastTryMs = 0;

/* v14：一个类型码一条，sight / nsight 各一份状态与数值�?
   state�? = 还没查；1 = 可用�?1 = 查过但失败（本进程不再重试）�?
   raw 保留查询原文，失败时写日志用�?*/
struct DdhExSlkEntry
{
    uint32_t code;
    int      sightState;
    float    sight;
    int      nightState;
    float    night;
    int      sightSrc;          /* 数值来源：文本 / S2R / S2I（日志用�?*/
    int      nightSrc;
    char     sightRaw[48];
    char     nightRaw[48];
    char     sightWhy[64];      /* 失败原因（S2R/S2I 不可用、越界…） */
    char     nightWhy[64];
};
static DdhExSlkEntry g_ddhExSlkCache[DDH_EX_SLK_CACHE];
static int           g_ddhExSlkCacheCount = 0;
static int           g_ddhExSlkCacheNext  = 0;
static int           g_ddhExSlkCalls      = 0;

/* 懒解�?EXExecuteScript：最�?20 次、每次至少间�?500ms（同一�?96 个单位不会打爆）�?
   失败/成功各只记一行�?*/
static uint32_t DdhExNative(void)
{
    if (g_ddhExFn) return g_ddhExFn;
    const uint32_t now = GetTickCount();
    if (g_ddhExLastTryMs && (uint32_t)(now - g_ddhExLastTryMs) < 500u) return 0;
    g_ddhExLastTryMs = now;

    const LONG tries = InterlockedIncrement(&g_ddhExTries);
    if (tries > 20) return 0;

    const uint32_t fn = FindNativeFunc("EXExecuteScript");
    if (fn)
    {
        g_ddhExFn = fn;
        if (InterlockedIncrement(&g_ddhExFoundLog) == 1)
            LogLine("ATTR EX：EXExecuteScript 已定位（0x%08X）", fn);
        return fn;
    }
    if (tries == 1 && InterlockedIncrement(&g_ddhExMissLog) == 1)
        LogLine("ATTR EX：EXExecuteScript 未找到（已试 20 次）→ 不做 slk 核对，视野保持原逻辑");
    else if (tries == 20)
        LogLine("ATTR EX：EXExecuteScript 未找到（已试 20 次）→ 不做 slk 核对，视野保持原逻辑");
    return 0;
}

/* v21：字符串 id 直接转数值（S2R / S2I）�?
   真机现象：EXExecuteScript 调用成功，但返回�?string id 反查不到文本（raw=""）�?
   不再依赖 id→文本：直接�?id 传给 JASS 原生�?
     S2R(string) -> real    （优先）
     S2I(string) -> integer （兜底）
   各自懒解析：最�?20 次、每次至少间�?500ms（进图前 JASS VM 可能还没好）�?
   已定�?未找到各只写一行日志�?*/
static uint32_t      g_ddhS2RFn = 0;
static uint32_t      g_ddhS2IFn = 0;
static volatile LONG g_ddhS2RTries = 0;
static volatile LONG g_ddhS2ITries = 0;
static volatile LONG g_ddhS2RLogged = 0;
static volatile LONG g_ddhS2ILogged = 0;
static uint32_t      g_ddhS2RLastTryMs = 0;
static uint32_t      g_ddhS2ILastTryMs = 0;

static uint32_t DdhExS2RNative(void)
{
    if (g_ddhS2RFn) return g_ddhS2RFn;
    const uint32_t now = GetTickCount();
    if (g_ddhS2RLastTryMs && (uint32_t)(now - g_ddhS2RLastTryMs) < 500u) return 0;
    g_ddhS2RLastTryMs = now;
    const LONG tries = InterlockedIncrement(&g_ddhS2RTries);
    if (tries > 20) return 0;

    const uint32_t fn = FindNativeFunc("S2R");
    if (fn)
    {
        g_ddhS2RFn = fn;
        if (InterlockedIncrement(&g_ddhS2RLogged) == 1)
            LogLine("ATTR EX：S2R native 已定位（0x%08X）→ 文本为空时把字符串 id 直接转 real", fn);
        return fn;
    }
    if (tries == 20 && InterlockedIncrement(&g_ddhS2RLogged) == 1)
        LogLine("ATTR EX：S2R native 未找到（已试 20 次）→ 文本为空时只试 S2I");
    return 0;
}

static uint32_t DdhExS2INative(void)
{
    if (g_ddhS2IFn) return g_ddhS2IFn;
    const uint32_t now = GetTickCount();
    if (g_ddhS2ILastTryMs && (uint32_t)(now - g_ddhS2ILastTryMs) < 500u) return 0;
    g_ddhS2ILastTryMs = now;
    const LONG tries = InterlockedIncrement(&g_ddhS2ITries);
    if (tries > 20) return 0;

    const uint32_t fn = FindNativeFunc("S2I");
    if (fn)
    {
        g_ddhS2IFn = fn;
        if (InterlockedIncrement(&g_ddhS2ILogged) == 1)
            LogLine("ATTR EX：S2I native 已定位（0x%08X）→ S2R 不可用/不合理时把字符串 id 转整数", fn);
        return fn;
    }
    if (tries == 20 && InterlockedIncrement(&g_ddhS2ILogged) == 1)
        LogLine("ATTR EX：S2I native 未找到（已试 20 次）→ 文本为空且 S2R 不行时 slk 按失败处理");
    return 0;
}

/* 严格数字校验：只接受 [+-]digits[.digits]（允许首尾空格），数值本身仍�?atof�?*/
static bool DdhExParseNumber(const char* raw, float* out)
{
    if (!raw || !out) return false;
    const char* p = raw;
    while (*p == ' ' || *p == '\t') ++p;
    if (*p == '+' || *p == '-') ++p;
    bool digit = false, dot = false;
    while (*p)
    {
        if (*p >= '0' && *p <= '9') { digit = true; ++p; continue; }
        if (*p == '.' && !dot) { dot = true; ++p; continue; }
        break;
    }
    while (*p == ' ' || *p == '\t') ++p;
    if (!digit || *p) return false;
    const double d = atof(raw);
    if (!(d > -1.0e9 && d < 1.0e9)) return false;
    *out = (float)d;
    return true;
}

/* 构�?jass.slk �?Lua 表达式，四种写法（见 DDH_EX_EXPR_*），都是 ASCII�?
     数字下标 = 类型码的十进制（'H038' = 0x48303338 = 1210079032）；
     字符串下�?= 4 字符类型码；字段写法 .sight �?["sight"]�?
   长度检查不通过就放弃（不截断表达式，截断的 Lua 一定解析失败）�?*/
static bool DdhExBuildExprForm(int exprForm, uint32_t typeId, const char* field,
                               char* out, size_t cap)
{
    if (!field || !field[0] || !out || cap < 32) return false;
    out[0] = 0;
    char type[8] = { 0 };
    const bool strIdx  = (exprForm == DDH_EX_EXPR_STR_DOT || exprForm == DDH_EX_EXPR_STR_BRK);
    const bool bracket = (exprForm == DDH_EX_EXPR_NUM_BRK || exprForm == DDH_EX_EXPR_STR_BRK);
    int n = 0;
    if (strIdx)
    {
        DdhAttrTypeCode(typeId, type);
        if (!type[0]) return false;
        n = bracket
            ? _snprintf_s(out, cap, _TRUNCATE, "(require'jass.slk').unit[\"%s\"][\"%s\"]", type, field)
            : _snprintf_s(out, cap, _TRUNCATE, "(require'jass.slk').unit[\"%s\"].%s", type, field);
    }
    else
    {
        n = bracket
            ? _snprintf_s(out, cap, _TRUNCATE, "(require'jass.slk').unit[%u][\"%s\"]", typeId, field)
            : _snprintf_s(out, cap, _TRUNCATE, "(require'jass.slk').unit[%u].%s", typeId, field);
    }
    return n > 0 && (size_t)n < cap;
}

/* 按“已验证可用的表达式形式”构造（探针跑之前就是现状：数字下标 + .字段）�?*/
static bool DdhExBuildExpr(uint32_t typeId, const char* field, char* out, size_t cap)
{
    return DdhExBuildExprForm((int)g_ddhExExprForm, typeId, field, out, cap);
}

/* 取一�?slk 字段的原文：EXExecuteScript(�?string id) -> 返回值按 id/指针两种形态解�?
   返回 false = native 不可�?/ 调用异常 / 没解出文本；raw 里尽量留诊断文本�?
   retId 非空时带�?EX 的原始返回值（字符�?id）：文本解不出来时直接喂�?S2R/S2I�?*/
static bool DdhExQueryRaw(uint32_t typeId, const char* field, char* raw, size_t cap,
                          uint32_t* retId)
{
    if (retId) *retId = 0;
    if (!raw || cap < 2) return false;
    raw[0] = 0;
    if (!typeId || !field || !field[0]) return false;

    const uint32_t fn = DdhExNative();
    if (!fn) return false;

    char expr[DDH_EX_EXPR_MAX];
    if (!DdhExBuildExpr(typeId, field, expr, sizeof(expr)))
    {
        LogLine("ATTR EX：表达式超长/构造失败（类型=%u 字段=%s），本次不查", typeId, field);
        return false;
    }

    /* 实参形式用探针（DdhExFormProbe）验证过的那一种：引擎 id / �?char* /
       string_fake 对象指针 / 引擎 id 反查 char* 都可能；具体�?g_ddhExArgForm�?*/
    const int form = (int)g_ddhExArgForm;
    uint32_t eax = 0;
    float    st0 = 0.0f;
    const int rc = DdhExCallForm(fn, form, expr, NULL, &eax, &st0);
    if (rc == 0)
    {
        if (InterlockedIncrement(&g_ddhExExprFailLog) == 1)
            LogLine("ATTR EX：表达式实参构造失败（形式=%s；0x1DA520 没给出 string id），本次不查",
                    DdhExFormName(form));
        return false;
    }
    if (rc != 1 || !eax) return false;
    if (retId) *retId = eax;   /* 文本解不出来�?S2R/S2I 还要用这�?id */

    int got = DdhAttrTextFromIdOrPtr(eax, raw, cap);
    if (!got) got = DdhTypeDataText(eax, raw, cap) ? 1 : 0;
    return got != 0 && raw[0] != 0;
}

/* jass.slk 的文本字段（Art/Icon）读取；没有 EX/JASS slk 模块时返�?false�?*/
static bool DdhExSlkString(uint32_t code, const char* field, char* out, size_t cap)
{
    if (!out || cap < 8) return false;
    out[0] = 0;
    char raw[DDH_EX_TEXT_MAX] = { 0 };
    uint32_t id = 0;
    if (!DdhExQueryRaw(code, field, raw, sizeof(raw), &id)) return false;
    if (!raw[0]) return false;
    DdhUtf8SafeCopy(out, cap, raw, cap - 1);
    return out[0] != 0;
}

/* slk 数值来源（日志里写清楚走的是哪条）�?*/
#define DDH_EX_NUM_NONE 0
#define DDH_EX_NUM_TEXT 1
#define DDH_EX_NUM_S2R  2
#define DDH_EX_NUM_S2I  3

static const char* DdhExNumSourceName(int src)
{
    switch (src)
    {
    case DDH_EX_NUM_TEXT: return "文本";
    case DDH_EX_NUM_S2R:  return "S2R";
    case DDH_EX_NUM_S2I:  return "S2I";
    default:              return "膵";
    }
}

/* S2R(string id) -> real：按 C 浮点约定�?ST(0)，再�?EAX 里的 float 位模�?
   （部�?JAPI 用后者）。只接受落在 [lo,hi] 的有限数；全�?__try�?*/
static bool DdhExCallS2R(uint32_t strId, float lo, float hi, float* out)
{
    if (!strId || !out) return false;
    const uint32_t fn = DdhExS2RNative();
    if (!fn) return false;

    uint32_t eax = 0;
    float    st0 = 0.0f;
    bool     ok  = false;
    __try { DdhNatCallAsm(fn, strId, 0, &eax, &st0); ok = true; }
    __except (EXCEPTION_EXECUTE_HANDLER) { ok = false; }
    if (!ok) return false;

    if (DdhAttrFits(st0, lo, hi)) { *out = st0; return true; }

    float eaxF = 0.0f;
    memcpy(&eaxF, &eax, 4);
    if (DdhAttrFits(eaxF, lo, hi)) { *out = eaxF; return true; }
    return false;
}

/* S2I(string id) -> integer：先按整�?EAX 认，再认 float 位模�?/ ST(0)�?*/
static bool DdhExCallS2I(uint32_t strId, float lo, float hi, float* out)
{
    if (!strId || !out) return false;
    const uint32_t fn = DdhExS2INative();
    if (!fn) return false;

    uint32_t eax = 0;
    float    st0 = 0.0f;
    bool     ok  = false;
    __try { DdhNatCallAsm(fn, strId, 0, &eax, &st0); ok = true; }
    __except (EXCEPTION_EXECUTE_HANDLER) { ok = false; }
    if (!ok) return false;

    const int32_t iv = (int32_t)eax;
    if (DdhAttrFits((float)iv, lo, hi)) { *out = (float)iv; return true; }

    float eaxF = 0.0f;
    memcpy(&eaxF, &eax, 4);
    if (DdhAttrFits(eaxF, lo, hi)) { *out = eaxF; return true; }
    if (DdhAttrFits(st0, lo, hi)) { *out = st0; return true; }
    return false;
}

/* 取一�?slk 字段的数值：
     �?EX 返回文本 �?现有 atof 解析（DdhExParseNumber）；
     �?文本为空/不是数字/越界 �?S2R(EX 的字符串 id)�?
     �?S2R 不可用或返回不合�?�?S2I(同一�?id)�?
   结果必须通过 [lo,hi] 范围校验；rawOut 回填原始返回值（诊断用）�?
   whyOut 回填失败原因（S2R/S2I 不可用、返回值越界等）�?*/
static int DdhExNumberCore(uint32_t code, const char* field, float lo, float hi,
                           float* out, char* rawOut, size_t rawCap,
                           char* whyOut, size_t whyCap)
{
    if (out) *out = 0.0f;
    if (rawOut && rawCap) rawOut[0] = 0;
    if (whyOut && whyCap) whyOut[0] = 0;
    if (!out || !code || !field || !field[0]) return DDH_EX_NUM_NONE;

    char     raw[DDH_EX_TEXT_MAX] = { 0 };
    uint32_t retId = 0;
    const bool textOk = DdhExQueryRaw(code, field, raw, sizeof(raw), &retId);
    if (rawOut && rawCap && raw[0]) strncpy_s(rawOut, rawCap, raw, _TRUNCATE);

    /* �?文本路（现状�?*/
    float v = 0.0f;
    char  textWhy[64] = { 0 };
    if (textOk && DdhExParseNumber(raw, &v))
    {
        if (DdhAttrFits(v, lo, hi)) { *out = v; return DDH_EX_NUM_TEXT; }
        _snprintf_s(textWhy, sizeof(textWhy), _TRUNCATE,
                    "文本=%.0f 越界（%.0f~%.0f）", (double)v, (double)lo, (double)hi);
    }
    else if (raw[0])
    {
        strncpy_s(textWhy, sizeof(textWhy), "文本不是数字", _TRUNCATE);
    }

    if (!retId)
    {
        if (whyOut && whyCap)
        {
            if (textWhy[0]) _snprintf_s(whyOut, whyCap, _TRUNCATE, "%s，EX 未返回字符串 id", textWhy);
            else            _snprintf_s(whyOut, whyCap, _TRUNCATE, "EX 未返回字符串 id");
        }
        return DDH_EX_NUM_NONE;
    }

    /* 两个 native 一起懒解析（各只记一行“已定位/未找到”）；先�?S2R，不行再 S2I�?*/
    const uint32_t s2r = DdhExS2RNative();
    const uint32_t s2i = DdhExS2INative();

    /* �?S2R（优先） */
    if (s2r)
    {
        float sv = 0.0f;
        if (DdhExCallS2R(retId, lo, hi, &sv)) { *out = sv; return DDH_EX_NUM_S2R; }
    }

    /* �?S2I（兜底） */
    if (s2i)
    {
        float iv = 0.0f;
        if (DdhExCallS2I(retId, lo, hi, &iv)) { *out = iv; return DDH_EX_NUM_S2I; }
    }

    /* 两条 native 都失败：把原因写清楚（raw 由调用方另外打印�?*/
    if (whyOut && whyCap)
    {
        const char* tail = (!s2r && !s2i) ? "S2R/S2I 都不可用"
                         : (!s2r)         ? "S2I 返回值不可用"
                         : (!s2i)         ? "S2R 返回值不可用（S2I 不可用）"
                                          : "S2R/S2I 返回值都不可用";
        if (textWhy[0]) _snprintf_s(whyOut, whyCap, _TRUNCATE, "%s，EX 未返回字符串 id%s", textWhy, tail);
        else            _snprintf_s(whyOut, whyCap, _TRUNCATE, "%s", tail);
    }
    return DDH_EX_NUM_NONE;
}

static DdhExSlkEntry* DdhExSlkFind(uint32_t code)
{
    for (int i = 0; i < g_ddhExSlkCacheCount; ++i)
        if (g_ddhExSlkCache[i].code == code) return &g_ddhExSlkCache[i];
    return NULL;
}

/* 按类型码取缓存条目；满了就环形替换（替换时两字段都清空重查）�?*/
static DdhExSlkEntry* DdhExSlkGet(uint32_t code)
{
    DdhExSlkEntry* e = DdhExSlkFind(code);
    if (e) return e;
    if (g_ddhExSlkCacheCount < DDH_EX_SLK_CACHE)
        e = &g_ddhExSlkCache[g_ddhExSlkCacheCount++];
    else
        e = &g_ddhExSlkCache[g_ddhExSlkCacheNext++ % DDH_EX_SLK_CACHE];
    memset(e, 0, sizeof(*e));
    e->code = code;
    return e;
}

static const char* DdhExSlkFieldName(bool night) { return night ? "nsight" : "sight"; }

/* v14：通用 slk 数值读取（按类型码缓存）�?
   field = "sight" �?白天视野；field = "nsight" �?夜晚视野�?
   同一类型码同一字段只查一次；成功要求 100~5000（与内存路同一口径）�?
   文本解不出来时用 EX 返回的字符串 id 直接�?S2R/S2I（不依赖 id→文�?反查）�?
   本进程最多查 DDH_EX_SLK_CALLS = 24 类型 × 2 字段 次，超了不再查（返回 false）�?*/
static bool DdhExSlkNumber(uint32_t code, const char* field, float* out)
{
    if (out) *out = 0.0f;
    if (!code || !field || !field[0]) return false;
    const bool night = (field[0] == 'n');

    DdhExSlkEntry* e = DdhExSlkGet(code);
    int*   state = night ? &e->nightState : &e->sightState;
    float* value = night ? &e->night : &e->sight;
    char*  raw   = night ? e->nightRaw : e->sightRaw;
    const size_t rawCap = sizeof(e->nightRaw);

    if (*state != 0)
    {
        if (*state == 1 && out) *out = *value;
        return *state == 1;
    }

    if (!DdhExNative()) return false;
    if (g_ddhExSlkCalls >= DDH_EX_SLK_CALLS)
    {
        if (InterlockedIncrement(&g_ddhExSlkFailLogged) == 1)
            LogLine("ATTR EX：slk 查询次数已达上限 %d（24 类型 × 2 字段），之后的新类型不再查 slk（视野退回内存路/无效）",
                    DDH_EX_SLK_CALLS);
        return false;
    }
    ++g_ddhExSlkCalls;

    char why[64] = { 0 };
    float v = 0.0f;
    const int src = DdhExNumberCore(code, field, DDH_ATTR_SIGHT_MIN, DDH_ATTR_SIGHT_MAX,
                                    &v, raw, rawCap, why, sizeof(why));
    const bool ok = (src != DDH_EX_NUM_NONE);

    *state = ok ? 1 : -1;
    *value = ok ? v : 0.0f;
    if (night)
    {
        e->nightSrc = src;
        e->nightWhy[0] = 0;
        if (!ok) strncpy_s(e->nightWhy, sizeof(e->nightWhy), why, _TRUNCATE);
    }
    else
    {
        e->sightSrc = src;
        e->sightWhy[0] = 0;
        if (!ok) strncpy_s(e->sightWhy, sizeof(e->sightWhy), why, _TRUNCATE);
    }
    if (ok && out) *out = v;
    return ok;
}

/* 诊断用：把缓存里的原文复制出来（没有就返回空串）�?*/
static void DdhExSlkRaw(uint32_t code, const char* field, char* out, size_t cap)
{
    if (out && cap) out[0] = 0;
    if (!out || cap < 2 || !code || !field) return;
    DdhExSlkEntry* e = DdhExSlkFind(code);
    if (!e) return;
    const char* raw = (field[0] == 'n') ? e->nightRaw : e->sightRaw;
    if (raw[0]) DdhUtf8SafeCopy(out, cap, raw, cap - 1);
}

/* 诊断用：这一次数值走的是哪条路（文本/S2R/S2I�? = 没拿到）�?*/
static int DdhExSlkSource(uint32_t code, bool night)
{
    DdhExSlkEntry* e = DdhExSlkFind(code);
    return e ? (night ? e->nightSrc : e->sightSrc) : DDH_EX_NUM_NONE;
}

/* 诊断用：失败原因（成功时是空串）�?*/
static const char* DdhExSlkWhy(uint32_t code, bool night)
{
    DdhExSlkEntry* e = DdhExSlkFind(code);
    if (!e) return "";
    return night ? e->nightWhy : e->sightWhy;
}

static bool DdhExSameValue(float a, float b)
{
    float d = a - b;
    if (d < 0.0f) d = -d;
    return d <= 0.5f;
}

/* ===========================================================================
   v22：EXExecuteScript 形式探针（每进程一次；只在第一个英�?第三个有类型码单位时做）
   ---------------------------------------------------------------------------
   真机 eax �?0 �?先把“实参形式”和“表达式/typeId 写法”分开定位�?
     �?常量表达�?"1+1"（Lua 求�?= 2）只验证**实参形式**（A 组）�?
     �?slk 表达式四种写法只验证**表达�?typeId**（B 组）�?
   结论写进 g_ddhExArgForm / g_ddhExExprForm，之�?sight/nsight/spd/def 统一走它�?
   一种都不通就保持现状（引�?id + 数字下标），不改任何字段�?
   全部调用�?__try；探针本身出错也只写一行日志，不影响属性采集�?
   =========================================================================== */

/* 调一种形式，把结果解成“文�?+ 数值”。返�?eax；hasNum 指出是否解出数值�?
   数值口径与正式查询一致：文本 atof �?S2R(eax) �?S2I(eax)�?
   日志格式（每种形式一行）�?
     EXFORM A1 form=... arg=0x%08X -> eax=0x%08X text="%s" num=%s */
static uint32_t DdhExProbeOne(uint32_t fn, const char* tag, int form, const char* expr,
                              bool* hasNum, float* outVal)
{
    if (hasNum) *hasNum = false;
    if (outVal) *outVal = 0.0f;

    uint32_t arg = 0, eax = 0;
    float    st0 = 0.0f;
    char     text[DDH_EX_TEXT_MAX] = { 0 };
    char     num[64] = { 0 };
    char     src[8] = { 0 };
    float    v = 0.0f;
    bool     numOk = false;

    const int rc = DdhExCallForm(fn, form, expr, &arg, &eax, &st0);

    if (rc == 0)
    {
        LogLine("EXFORM %s form=%s arg=0x00000000 -> 实参没造出来（没调用）text=\"\" num=无",
                tag, DdhExFormName(form));
        return 0;
    }
    if (rc == 2)
    {
        LogLine("EXFORM %s form=%s arg=0x%08X -> 调用异常 code=0x%08X text=\"\" num=无",
                tag, DdhExFormName(form), arg, (unsigned)g_ddhExLastExc);
        return 0;
    }

    /* 返回�?�?文本（字符串 id / string_fake 指针 / �?char* 三种形态都试） */
    if (eax)
    {
        if (!DdhAttrTextFromIdOrPtr(eax, text, sizeof(text)))
            DdhTypeDataText(eax, text, sizeof(text));
    }

    /* 文本 �?数字；文本解不出来但 eax 像“小整数 id”时喂给 S2R / S2I（真机同款）�?*/
    if (DdhExParseNumber(text, &v))
    {
        numOk = true;
        strncpy_s(src, sizeof(src), "text", _TRUNCATE);
    }
    else if (eax && eax < 0x10000u)
    {
        if (DdhExCallS2R(eax, -1.0e9f, 1.0e9f, &v)) { numOk = true; strncpy_s(src, sizeof(src), "S2R", _TRUNCATE); }
        else if (DdhExCallS2I(eax, -1.0e9f, 1.0e9f, &v)) { numOk = true; strncpy_s(src, sizeof(src), "S2I", _TRUNCATE); }
    }

    if (numOk) _snprintf_s(num, sizeof(num), _TRUNCATE, "%.0f(%s)", (double)v, src);
    else       strncpy_s(num, sizeof(num), "膵", _TRUNCATE);

    LogLine("EXFORM %s form=%s arg=0x%08X -> eax=0x%08X text=\"%s\" num=%s",
            tag, DdhExFormName(form), arg, eax, text, num);
    if (hasNum) *hasNum = numOk;
    if (outVal) *outVal = v;
    return eax;
}

/* 每进程一次：A 组定“实参形式”，B 组定“表达式/typeId”，然后记进全局�?*/
static void DdhExFormProbe(uint32_t obj, uint32_t code)
{
    const uint32_t fn = DdhExNative();
    if (!fn) return;
    if (InterlockedCompareExchange(&g_ddhExFormProbeDone, 1, 0) != 0) return;

    char type[8] = { 0 };
    DdhAttrTypeCode(code, type);
    LogLine("EXFORM：开始形式探针（obj=0x%08X 类型=%s 十进制=%u；每进程只做一次；"
            "常量 1+1 应得 2，sight 应落在 %.0f~%.0f）",
            obj, type, code, (double)DDH_ATTR_SIGHT_MIN, (double)DDH_ATTR_SIGHT_MAX);

    /* ---------- A 组：常量 "1+1" 只验证实参形�?----------
       A1/A2 = 引擎 id / �?char*�? 参，第二�?0，现状）�?
       A3/A4 = 同上，第二参 1；A5/A6 = 同上，只�?1 个参数；
       A7/A8/A9 = string_fake 对象指针，分别配 第二�?0 / 第二�?1 / 只压 1 个参数；
       A10 = 引擎 id 反查出的 char*（engine-pool），第二�?0�?
       ddh-9128.log 已证�?A1~A6 全失败，所以重点看 A7~A9（全失败再看 A10）�?*/
    const char* kConst = "1+1";
    const int   aForm[2] = { DDH_EX_FORM_ID, DDH_EX_FORM_PTR };
    const char* aTag[2]  = { "A1", "A2" };
    int chosen = DDH_EX_FORM_NONE;

    for (int i = 0; i < 2; ++i)
    {
        bool has = false;
        float v = 0.0f;
        DdhExProbeOne(fn, aTag[i], aForm[i], kConst, &has, &v);
        if (has && DdhExSameValue(v, 2.0f) && chosen == DDH_EX_FORM_NONE) chosen = aForm[i];
    }

    /* A1/A2 都没拿到 2 �?再试第二参数 / 只压一个参数的写法 */
    if (chosen == DDH_EX_FORM_NONE)
    {
        const int   moreForm[4] = { DDH_EX_FORM_ID_A2, DDH_EX_FORM_PTR_A2,
                                    DDH_EX_FORM_ID_1,  DDH_EX_FORM_PTR_1 };
        const char* moreTag[4]  = { "A3", "A4", "A5", "A6" };
        for (int i = 0; i < 4; ++i)
        {
            bool has = false;
            float v = 0.0f;
            DdhExProbeOne(fn, moreTag[i], moreForm[i], kConst, &has, &v);
            if (has && DdhExSameValue(v, 2.0f) && chosen == DDH_EX_FORM_NONE) chosen = moreForm[i];
        }
    }

    /* A7~A9：string_fake 对象指针（DisplayTimedTextToPlayer 同款；每次调用前重建�?*/
    if (chosen == DDH_EX_FORM_NONE)
    {
        const int   fakeForm[3] = { DDH_EX_FORM_FAKE, DDH_EX_FORM_FAKE_A2, DDH_EX_FORM_FAKE_1 };
        const char* fakeTag[3]  = { "A7", "A8", "A9" };
        for (int i = 0; i < 3; ++i)
        {
            bool has = false;
            float v = 0.0f;
            DdhExProbeOne(fn, fakeTag[i], fakeForm[i], kConst, &has, &v);
            if (has && DdhExSameValue(v, 2.0f) && chosen == DDH_EX_FORM_NONE) chosen = fakeForm[i];
        }
    }

    /* A10：最后一种——引�?id 反查出的 char*（engine-pool），第二�?0 */
    if (chosen == DDH_EX_FORM_NONE)
    {
        bool has = false;
        float v = 0.0f;
        DdhExProbeOne(fn, "A10", DDH_EX_FORM_ENG_PTR, kConst, &has, &v);
        if (has && DdhExSameValue(v, 2.0f)) chosen = DDH_EX_FORM_ENG_PTR;
    }

    /* ---------- B 组：真实 sight 表达式（A 组选中的实参形式；四种写法�?----------
       B1 = 选中形式 + unit[十进制].sight（现状写法，必须用真实表达式验证）；
       B2 = 仅当选中引擎 id 时，用裸 char* 再跑一次同一写法（旧日志对照）；
       B3~B5 = 选中形式 + 字符串下�?/ ["字段"] 写法�?*/
    int chosenExpr    = -1;
    int chosenExprAny = -1;      /* 退化用：没落在视野范围、但至少解出了数 */
    if (chosen == DDH_EX_FORM_NONE)
    {
        LogLine("EXFORM：A 组全失败（常量 1+1 十种实参形式都没算出 2）→ 跳过 B 组，保持现状");
    }
    else if (code)
    {
        char expr[DDH_EX_EXPR_MAX] = { 0 };
        if (DdhExBuildExprForm(DDH_EX_EXPR_NUM_DOT, code, "sight", expr, sizeof(expr)))
        {
            bool has = false;
            float v = 0.0f;
            DdhExProbeOne(fn, "B1", chosen, expr, &has, &v);
            if (has && chosenExprAny < 0) chosenExprAny = DDH_EX_EXPR_NUM_DOT;
            if (has && DdhAttrFits(v, DDH_ATTR_SIGHT_MIN, DDH_ATTR_SIGHT_MAX) && chosenExpr < 0)
                chosenExpr = DDH_EX_EXPR_NUM_DOT;
        }

        if (chosen == DDH_EX_FORM_ID)
        {
            char expr2[DDH_EX_EXPR_MAX] = { 0 };
            if (DdhExBuildExprForm(DDH_EX_EXPR_NUM_DOT, code, "sight", expr2, sizeof(expr2)))
            {
                bool has = false;
                float v = 0.0f;
                DdhExProbeOne(fn, "B2", DDH_EX_FORM_PTR, expr2, &has, &v);
                if (has && chosenExprAny < 0) chosenExprAny = DDH_EX_EXPR_NUM_DOT;
                if (has && DdhAttrFits(v, DDH_ATTR_SIGHT_MIN, DDH_ATTR_SIGHT_MAX) && chosenExpr < 0)
                    chosenExpr = DDH_EX_EXPR_NUM_DOT;
            }
        }

        if (chosenExpr < 0)
        {
            const int   varForm[3] = { DDH_EX_EXPR_STR_DOT, DDH_EX_EXPR_NUM_BRK, DDH_EX_EXPR_STR_BRK };
            const char* varTag[3]  = { "B3", "B4", "B5" };
            for (int i = 0; i < 3; ++i)
            {
                char expr3[DDH_EX_EXPR_MAX] = { 0 };
                if (!DdhExBuildExprForm(varForm[i], code, "sight", expr3, sizeof(expr3))) continue;
                bool has = false;
                float v = 0.0f;
                DdhExProbeOne(fn, varTag[i], chosen, expr3, &has, &v);
                if (has && chosenExprAny < 0) chosenExprAny = varForm[i];
                if (has && DdhAttrFits(v, DDH_ATTR_SIGHT_MIN, DDH_ATTR_SIGHT_MAX) && chosenExpr < 0)
                    chosenExpr = varForm[i];
            }
        }
    }

    /* ---------- 结论：写日志 + 记进全局（后�?sight/nsight/spd/def 都用它） ---------- */
    if (chosen != DDH_EX_FORM_NONE)
    {
        InterlockedExchange(&g_ddhExArgForm, (LONG)chosen);
        LogLine("ATTR EX：采用实参形式 %s（1+1 探针拿到 2）", DdhExFormName(chosen));
    }
    else
    {
        LogLine("ATTR EX：所有实参形式均失败（见 EXFORM 各行）");
    }

    if (chosenExpr < 0 && chosenExprAny >= 0) chosenExpr = chosenExprAny;
    if (chosenExpr >= 0)
    {
        InterlockedExchange(&g_ddhExExprForm, (LONG)chosenExpr);
        LogLine("ATTR EX：采用表达式形式 %s", DdhExExprName(chosenExpr));
    }
    else if (chosen != DDH_EX_FORM_NONE)
    {
        LogLine("ATTR EX：表达式/typeId 四种写法都没解出 sight（形状不匹配）→ 保持现状（%s）",
                DdhExExprName(DDH_EX_EXPR_NUM_DOT));
    }

    /* 探针之前�?sight/nsight 已经按旧形式查过并缓存了失败：只把“失败”状态清掉，
       让紧接着的核对（下方 DdhExSlkNumber）按新形式重查一次；成功的不动�?*/
    for (int i = 0; i < g_ddhExSlkCacheCount; ++i)
    {
        if (g_ddhExSlkCache[i].sightState < 0) g_ddhExSlkCache[i].sightState = 0;
        if (g_ddhExSlkCache[i].nightState < 0) g_ddhExSlkCache[i].nightState = 0;
    }
}

/* 每进程一次：对第一个英雄（�?3 个单位里没有英雄就退而用�?3 个有类型码的单位�?
   核对 slk �?ddh 现有读数。只写日志，绝不改字段�?*/
static void DdhExProbeOnce(uint32_t obj, uint32_t code, bool memSightOk, float memSight,
                           const DdhUnitAttr* out)
{
    if (g_ddhExProbeDone || !code || !out) return;
    const bool hero = (out->flags & DDH_AF_HEROKNOWN) != 0 && (out->flags & DDH_AF_HERO) != 0;
    const LONG seen = InterlockedIncrement(&g_ddhExCodedSeen);
    if (!hero && seen < 3) return;
    if (!DdhExNative()) return;
    if (InterlockedCompareExchange(&g_ddhExProbeDone, 1, 0) != 0) return;

    /* v22：先做实�?表达式形式探针（每进程一次；结论�?g_ddhExArgForm/g_ddhExExprForm）�?
       探针内部每种调用�?__try，这里再包一层，保证它出错也不影响下面的核对�?*/
    __try { DdhExFormProbe(obj, code); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        if (InterlockedIncrement(&g_ddhExProbeExcLog) == 1)
            LogLine("EXFORM：探针异常 code=0x%08X（已吞掉，继续按现有形式核对）",
                    (unsigned)GetExceptionCode());
    }

    char type[8] = { 0 };
    DdhAttrTypeCode(code, type);
    LogLine("ATTR EX 核对：单位类型=%s（十进制 %u）obj=0x%08X 英雄=%d（每进程只核对一次）",
            type, code, obj, hero ? 1 : 0);

    /* sight（白天视野）：slk 是主路；内存路只�?slk 失败时才会被�?*/
    {
        char raw[DDH_EX_TEXT_MAX] = { 0 };
        float slk = 0.0f;
        const bool okSlk = DdhExSlkNumber(code, "sight", &slk);
        if (!okSlk)
        {
            DdhExSlkRaw(code, "sight", raw, sizeof(raw));
            LogLine("ATTR EX 核对 sight：slk 解析失败（raw=\"%s\"，%s）→ 白天视野退回 0x3ADF0",
                    raw, DdhExSlkWhy(code, false));
        }
        else if (memSightOk)
            LogLine("ATTR EX 核对 sight：slk=%.0f（%s）内存=%.0f（%s）",
                    (double)slk, DdhExNumSourceName(DdhExSlkSource(code, false)),
                    (double)memSight,
                    DdhExSameValue(slk, memSight) ? "一致" : "不一致");
        else
            LogLine("ATTR EX 核对 sight：slk=%.0f（%s）内存=%.0f（%s）",
                    (double)slk, DdhExNumSourceName(DdhExSlkSource(code, false)));
    }

    /* nsight（夜晚视野）：v14 起是独立一列，slk 取不到就是无效（界面 ?�?*/
    {
        char raw[DDH_EX_TEXT_MAX] = { 0 };
        float slk = 0.0f;
        if (!DdhExSlkNumber(code, "nsight", &slk))
        {
            DdhExSlkRaw(code, "nsight", raw, sizeof(raw));
            LogLine("ATTR EX 核对 nsight：slk 解析失败（raw=\"%s\"，%s）→ 夜晚视野无效（界面 ?）",
                    raw, DdhExSlkWhy(code, true));
        }
        else
            LogLine("ATTR EX 核对 nsight：slk=%.0f（%s，v14 夜晚视野，界面独立一列）",
                    (double)slk, DdhExNumSourceName(DdhExSlkSource(code, true)));
    }

    /* spd：对照现有的 UnitBalance spd（DzAPI 类型数据；内存直读没有这个字段） */
    {
        char raw[DDH_EX_TEXT_MAX] = { 0 };
        char why[64] = { 0 };
        float slk = 0.0f;
        /* 与现�?spd 校验一致：必须 > 0�? 不是有效移速），上�?100000�?*/
        const int src = DdhExNumberCore(code, "spd", 0.0001f, 100000.0f,
                                        &slk, raw, sizeof(raw), why, sizeof(why));
        if (src == DDH_EX_NUM_NONE)
            LogLine("ATTR EX 核对 spd：slk 解析失败（raw=\"%s\"，%s）", raw, why);
        else if ((out->flags & DDH_AF_BASE_SPEED) != 0)
            LogLine("ATTR EX 核对 spd：slk=%.0f（%s）现有=%.0f（%s）",
                    (double)slk, DdhExNumSourceName(src), (double)out->baseSpeed,
                    DdhExSameValue(slk, out->baseSpeed) ? "一致" : "不一致");
        else
            LogLine("ATTR EX 核对 spd：slk=%.0f（%s）现有=%.0f（%s）",
                    (double)slk, DdhExNumSourceName(src));
    }

    /* def：对照现有的 UnitBalance def（同上） */
    {
        char raw[DDH_EX_TEXT_MAX] = { 0 };
        char why[64] = { 0 };
        float slk = 0.0f;
        const int src = DdhExNumberCore(code, "def", DDH_ATTR_ARMOR_MIN, DDH_ATTR_ARMOR_MAX,
                                        &slk, raw, sizeof(raw), why, sizeof(why));
        if (src == DDH_EX_NUM_NONE)
            LogLine("ATTR EX 核对 def：slk 解析失败（raw=\"%s\"，%s）", raw, why);
        else if ((out->flags & DDH_AF_BASE_ARMOR) != 0)
            LogLine("ATTR EX 核对 def：slk=%.0f（%s）现有=%d（%s）",
                    (double)slk, DdhExNumSourceName(src), (int)out->baseArmor,
                    DdhExSameValue(slk, (float)out->baseArmor) ? "一致" : "不一致");
        else
            LogLine("ATTR EX 核对 def：slk=%.0f（%s）现有=%d（%s）",
                    (double)slk, DdhExNumSourceName(src));
    }
}

/* 前几个单位的完整结果写一行日志（真机排查“哪个字段没拿到”）�?
   prop 一起打出来：确�?*(uint32_t*)(CUnit+0x1E8) 到底可不可读�?*/
static void DdhAttrLogUnit(uint32_t obj, const DdhUnitAttr* out, uint32_t prop)
{
    if (InterlockedIncrement(&g_ddhAttrUnitLogged) > 6) return;
    LogLine("ATTR unit：addr=0x%08X prop=0x%08X code=%s name=\"%s\" title=\"%s\" flags=0x%08X "
            "range=%.1f dmg=%.1f~%.1f interval=%.3f atkSpeed=%.4f armor=%.1f move=%.0f sightDay=%.0f sightNight=%.0f acquire=%.0f "
            "基础：�?%.0f �?%d "
            "膵",
            obj, prop, out->typeCode, out->name, out->title, out->flags,
            (double)out->attackRange, (double)out->damageMin, (double)out->damageMax,
            (double)out->attackInterval, (double)out->attackSpeed,
            (double)out->armor, (double)out->moveSpeed,
            (double)out->sightDay, (double)out->sightNight, (double)out->acquireRange,
            (double)out->baseSpeed, (int)out->baseArmor,
            (double)out->strength, (double)out->agility, (double)out->intelligence,
            (int)out->extraValue, (out->flags & DDH_AF_LOCUST) ? 1 : 0);
}

/* 单个单位的属性采集（一次可能调 ~13 �?native；结果交给缓存层�?*/
static void DdhAttrFillOne(uint32_t obj, DdhUnitAttr* out)
{
    memset(out, 0, sizeof(*out));
    out->addr = obj;
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return;
#if !DDH_BATTLEFIELD_UNITS_NAME_ONLY
    /* v21：顺便算一次“本地玩家结盟掩码”（整局只成功一次；失败不重试太多次�?*/
    DdhComputeAllyMask();
#endif


    /* 类型�?+ 单位名：不依�?JASS，先填上（拿不到就只留地址�?*/
    const uint32_t code = SafeCode(obj);
    if (code)
    {
        DdhAttrTypeCode(code, out->typeCode);
        out->flags |= DDH_AF_TYPECODE;
        /* v21：这个类型码以前被实测出�?Aloc �?没句柄也按蝗虫处理（战场单位不显示） */
        }
    {
        char nm[64] = { 0 };
        ResolveName(obj, code, nm, sizeof(nm));
        if (nm[0])
        {
            DdhUtf8SafeCopy(out->name, sizeof(out->name), nm, sizeof(out->name) - 1);
            out->flags |= DDH_AF_NAME;
        }
    }

#if DDH_BATTLEFIELD_UNITS_NAME_ONLY
    const uint32_t handle = HpObjToHandle(obj);

    /* Battlefield locust is instance-only. Never propagate Aloc by type code:
       a mirror may carry Aloc while the original hero with the same code does not. */
    int locustLevel = DdhAbilityInUnitList(obj, 0x416C6F63u);
    if (locustLevel >= 0) out->flags |= DDH_AF_LOCUST_CHECKED;
    if (locustLevel > 0)
    {
        out->flags |= DDH_AF_LOCUST;
    }

    const int illusionState = DdhUnitIllusionStateByObj(obj);
    if (illusionState >= 0)
    {
        out->flags |= DDH_AF_ILLUSION_CHECKED;
        if (illusionState > 0) out->flags |= DDH_AF_ILLUSION;
    }

    /* Direct memory path for attack range/damage/interval/rate-of-fire/armor. */
    {
        const uint32_t prop = DdhUnitProp(obj);
        DdhAttrFillMemory(obj, prop, DdhPropReadable(prop), out);
    }

    {
        char title[64] = { 0 };
        if (code && DdhTitleOnlyCached(obj, handle, code, title, sizeof(title)))
        {
            DdhUtf8SafeCopy(out->title, sizeof(out->title), title, sizeof(out->title) - 1);
            out->flags |= DDH_AF_TITLE;
        }
    }
    if (InterlockedIncrement(&g_ddhAttrUnitLogged) <= 12)
        LogLine("ATTR name-only: addr=0x%08X handle=0x%08X code=%s name=\"%s\" title=\"%s\" "
                "dmg=%.1f~%.1f range=%.1f armor=%.1f interval=%.3f atkSpeed=%.4f locust=%d mirror=%d flags=0x%08X",
                obj, handle, out->typeCode, out->name, out->title,
                (double)out->damageMin, (double)out->damageMax, (double)out->attackRange,
                (double)out->armor, (double)out->attackInterval, (double)out->attackSpeed,
                locustLevel > 0 ? 1 : 0, (out->flags & DDH_AF_ILLUSION) ? 1 : 0, out->flags);
#else
    /* ---- v15：内存直读优先（YDWE unit_property / CUnit+0xE0�?---
       放在“句柄检查”之前：这些字段不需�?JASS 句柄，句柄只影响下面�?native 兜底
       与类型码/英雄判定；假魔兽/句柄表暂时取不到句柄时，这几列照样有值�?*/
    const uint32_t prop = DdhUnitProp(obj);
    const bool propOk = DdhPropReadable(prop);
    DdhAttrFillMemory(obj, prop, propOk, out);

    /* ---- 视野（协�?v14）：白天/夜晚两列，jass.slk 是主�?----
       sight �?sightDay（白天视野），nsight �?sightNight（夜晚视野），各置各的标志位�?
       slk 取不到（没有 jass.slk 模块 / 类型码未�?/ 查询次数用尽）才退�?
       Game.dll+0x3ADF0 的“当前有效视野”填 sightDay；sightNight 保持无效（界�??）�?
       内存路完全不需�?JASS 句柄，没句柄的单位也能兜底�?
       EXExecuteScript 通道�?DdhExSlkNumber（按类型码缓存，24 类型 × 2 字段）�?*/
    float slkDay = 0.0f, slkNight = 0.0f;
    bool  slkDayOk = false, slkNightOk = false;
    float memSight = -1.0f;
    bool  memSightOk = false;

    if (code)
    {
        __try
        {
            slkDayOk   = DdhExSlkNumber(code, "sight", &slkDay);
            slkNightOk = DdhExSlkNumber(code, "nsight", &slkNight);
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            if (InterlockedIncrement(&g_ddhExFallbackExcLog) == 1)
                LogLine("ATTR EX：slk 视野读取异常 code=0x%08X（已吞掉，不影响其它字段）",
                        (unsigned)GetExceptionCode());
        }
    }

    if (slkDayOk)
    {
        out->sightDay = slkDay;
        out->flags |= DDH_AF_SIGHT_DAY;
        DdhAttrLogOnce(&g_ddhExSlkSightLogged,
                       "白天视野 ← jass.slk sight = %.0f（%s）", (double)slkDay,
                       DdhExNumSourceName(DdhExSlkSource(code, false)));
    }
    if (slkNightOk)
    {
        out->sightNight = slkNight;
        out->flags |= DDH_AF_SIGHT_NIGHT;
        DdhAttrLogOnce(&g_ddhExSlkNightLogged,
                       "夜晚视野 ← jass.slk nsight = %.0f（%s）", (double)slkNight,
                       DdhExNumSourceName(DdhExSlkSource(code, true)));
    }
    if (slkDayOk)
    {
        DdhAttrFieldNote(9, "白天/夜晚视野 ← jass.slk sight/nsight（EXExecuteScript；文本解不出时用字符串 id 走 S2R/S2I，按类型码缓存）");
    }
    else
    {
        memSightOk = DdhSightRead(obj, &memSight);
        if (memSightOk)
        {
            out->sightDay = memSight;
            out->flags |= DDH_AF_SIGHT_DAY;
            DdhAttrLogOnce(&g_ddhSightOkShown,
                           "视野 ← Game.dll+0x%X(&unit+0xFC) = %.0f（slk sight 取不到时的兜底）",
                           (unsigned)DDH_RVA_SIGHT_FIELD, (double)memSight);
            DdhAttrFieldNote(9, "白天视野 ← jass.slk sight = %.0f（%s）");
        }
    }

    /* 内存扫 Aloc（最可靠的兜底）：单位结构里带 0x636F6C41 即蝗虫 */
    if (!(out->flags & DDH_AF_LOCUST) && code)
    {
        uint32_t hitOff = 0;
        char alocPath[64] = { 0 };
        uint32_t alocReads = 0;
        if (false && DdhMemHasAlocDeep(obj, alocPath, sizeof(alocPath), &alocReads))
        {
            out->flags |= DDH_AF_LOCUST;
            DdhAlocCodeRemember(code);
            if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 10)
                LogLine("ATTR：蝗虫判定（内存 Aloc）code=%s addr=0x%08X 位置=%s 读取=%u", DdhCodeText(code), obj, alocPath, alocReads);
        }
        else if (InterlockedIncrement(&g_ddhMemAlocMissLogged) <= 5)
            LogLine("ATTR：内存扫描无 Aloc code=%s addr=0x%08X（本体0x8000+一级0x2000+二级0x1000，读取=%u）", DdhCodeText(code), obj, alocReads);
    }

    /* 类型数据判定（先于句柄）：类型 abilList 带 Aloc 即蝗虫；hidespell_* 常拿不到句柄也能定性。 */
    if (!(out->flags & DDH_AF_LOCUST) && code && DdhTypeHasAloc(code))
    {
        out->flags |= DDH_AF_LOCUST;
        DdhAlocCodeRemember(code);
        if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 10)
            LogLine("ATTR：蝗虫判定（类型数据）code=%s → flags |= 0x%X", out->typeCode, DDH_AF_LOCUST);
    }

    /* 后面所有字段都要句柄（JASS native 的参数是句柄，不�?CUnit*）�?
       拿不到句�?�?native 字段无效（内存直读的字段保留），日志限流�?*/
    /* 入口先判蝗虫（不依赖句柄）：马甲常常拿不到句柄，等句柄检查之后就永远没机会了 */
    if (!(out->flags & DDH_AF_LOCUST) && code)
    {
        int lv0 = DdhAbilityLevelByObj(obj, 0x416C6F63u);
        if (lv0 > 0)
        {
            out->flags |= DDH_AF_LOCUST;
            DdhAlocCodeRemember(code);
            if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 15)
                LogLine("ATTR：蝗虫判定（入口直查）code=%s obj=0x%08X level=%d", DdhCodeText(code), obj, lv0);
        }
    }

    /* 入口先判蝗虫（不依赖句柄）：马甲常拿不到句柄，等句柄检查之后就永远没机会 */
    if (!(out->flags & DDH_AF_LOCUST) && code)
    {
        int lv0 = DdhAbilityLevelByObj(obj, 0x416C6F63u);
        if (lv0 > 0)
        {
            out->flags |= DDH_AF_LOCUST;
            DdhAlocCodeRemember(code);
            if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 15)
                LogLine("ATTR：蝗虫判定（入口直查）code=%s obj=0x%08X level=%d", DdhCodeText(code), obj, lv0);
        }
    }

    const uint32_t handle = HpObjToHandle(obj);
    if (!handle)

    {
        if (InterlockedIncrement(&g_ddhAttrNoHandleLogged) <= 5)
            LogLine("ATTR obj->handle 失败（addr=0x%08X prop=0x%08X code=%s）→ native 字段（移速/类型基础数据/英雄判定）无效；内存直读字段保留",
                    obj, prop, out->typeCode);
        DdhAttrLogUnit(obj, out, prop);
        return;
    }

    /* 镜像/幻象：IsUnitIllusion 底层就是 CUnit+0x5C 的 bit 30。 */
    {
        const int illusion = DdhUnitIllusionStateByObj(obj);
        if (illusion >= 0)
        {
            out->flags |= DDH_AF_ILLUSION_CHECKED;
            if (illusion > 0) out->flags |= DDH_AF_ILLUSION;
        }
    }

    /* ① 直接按单位对象查技能（逆向出的底层函数，最可靠） */
    if (!(out->flags & DDH_AF_LOCUST) && code)
    {
        DdhProbeHeroNatives();
        DdhW3ApiTypeLookup();   /* 只探一次：Game.dll 是否导出类型对象查找 */
        if (InterlockedIncrement(&g_ddhTypeIdProbe) <= 12)
        {
            /* code 探针：raw（CUnit+0x30）与 DzAPI 实际收到的 id 对照 */
            uint32_t mapped = DdhTypeDataUnitId(handle, code);
            LogLine("typeid 探针：raw=0x%08X mapped=0x%08X（DzAPI 要求 0x10000~0x1FFFF 或 >=0x20000）", code, mapped);
        }
        int lv = DdhAbilityLevelByObj(obj, 0x416C6F63u);
        if (lv >= 0) out->flags |= DDH_AF_LOCUST_CHECKED;   /* 判定跑完了（0 也要记，C# 才敢信 False） */   // 0x416C6F63 = 'Aloc'（大端四字符）
        if (lv > 0)
        {
            out->flags |= DDH_AF_LOCUST;
            DdhAlocCodeRemember(code);
            if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 15)
                LogLine("ATTR：蝗虫判定（对象直查）code=%s obj=0x%08X level=%d", DdhCodeText(code), obj, lv);
        }
        else if (InterlockedIncrement(&g_ddhObjLookupLogged) <= 20)
            LogLine("ATTR：对象直查 code=%s obj=0x%08X level=%d（0=没有 Aloc；-1=game.dll/调用失败）", DdhCodeText(code), obj, lv);
        else if (lv < 0 && InterlockedIncrement(&g_ddhMemAlocMissLogged) <= 3)
            LogLine("ATTR：对象直查失败 code=%s obj=0x%08X（game.dll 未加载或调用异常）", DdhCodeText(code), obj);
    }

    /* 不再对 GetUnitAbilityLevel 的候选指针盲调：
       旧版把 p / *p / *(p+0x10) / YD 函数都当同签名函数调用，某些单位上会栈损坏，
       表现为 War3.exe 在 ddh.dll+0x4F10 崩溃。Aloc 判定改用上面的对象直查 + 下面的
       已解析 native 指针（同一个 GetUnitAbilityLevelNative）各一次，足够且不会盲调数据指针。 */

    /* ---- v14：蝗虫（Aloc）标�?----
       GetUnitAbilityLevel(handle, 'Aloc') > 0 �?flags |= DDH_AF_LOCUST，C# 据此把该单位
       从【战场单位】里过滤掉。句柄拿不到 / native 没定�?/ 调用异常 �?不置�?
       （C# 按“非蝗虫”处理，宁可漏一个也不误杀正常单位）。与事件 flags bit0 同一判定口径�?*/
    {
        const uint32_t afn = GetUnitAbilityLevelNative();
        if (afn)
        {
            int  level = 0;
            bool ok    = true;
            __try { level = ((int (__cdecl*)(uint32_t, uint32_t))(uintptr_t)afn)(handle, DDH_ABILITY_ALOC); }
            __except (EXCEPTION_EXECUTE_HANDLER) { ok = false; }
            if (ok && level > 0)
            {
                out->flags |= DDH_AF_LOCUST;
                /* v21：记住类型码，后续同码单位即使没有句柄也判定为蝗�?*/
                DdhAlocCodeRemember(code);
                if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 10)
                    LogLine("ATTR：蝗虫判定 code=%s handle=0x%08X level=%d → flags |= 0x%X（战场单位不显示）",
                            out->typeCode, handle, level, DDH_AF_LOCUST);
            }
            else
            {
                /* YDWE 口径：GetUnitAbilityLevel(handle,"Aloc") <= 0 即普通单位；
                   这里把“调用结果”打出来，方便确认 native 是否真的返回 0（而不是没调用/异常）。 */
                if (InterlockedIncrement(&g_ddhAttrAlocMissLogged) <= 30)
                    LogLine("ATTR：Aloc 未命中 code=%s addr=0x%08X handle=0x%08X afn=0x%08X ok=%d level=%d",
                            out->typeCode, obj, handle, (unsigned)afn, ok ? 1 : 0, level);
            }
        }
    }
    /* 单位类型数据实参探测�? 种组合各试一次（只在第一个拿到句柄的单位上做），
       选中结果后面所有字段共用（称谓/基础速度/基础�?附加�?points；视野已不走类型数据）�?
       DZPROBE �?+ "ATTR 单位类型数据：采�?order=.. id形式=.." 都在这里写日志�?*/

    DdhTypeDataProbe(handle, code);

    /* ---- 英雄判定 / 称谓 ----
       称谓先取到本地，等下面判定出“是不是英雄”再决定要不要写�?
       非英雄只显示单位名；GetHeroProperName 真拿到文本的单位视为英雄�?*/
    bool heroKnown = false;
    bool hero = false;
    char title[64] = { 0 };
    const int titleSrc = DdhAttrHeroTitle(handle, code, title, sizeof(title));
    if (titleSrc == 1)
    {
        heroKnown = true;
        hero = true;
    }

    float v = 0.0f;
    int   hit = -1;

    /* ---- 攻击范围：内存直读（prop+0x258）没拿到才问 native ---- */
    if (!(out->flags & DDH_AF_ATTACKRANGE))
    {
        const int ids[] = { DDH_AN_RANGE };
        v = 0.0f;
        hit = DdhAttrTryReals(ids, 1, handle, 0, &v);
        if (hit >= 0 && DdhAttrFits(v, 0.0f, DDH_ATTR_RANGE_MAX))
        {
            out->attackRange = v;
            out->flags |= DDH_AF_ATTACKRANGE;
            char note[160];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "攻击范围 ← %s（native 兜底：内存直读没拿到）", DdhAttrUsedName(DDH_AN_RANGE));
            DdhAttrFieldNote(1, note);
        }
    }

    /* ---- 攻击力：内存直读（unit_property �?dice/side/base/bonus）没拿到才问 native ----
       native 口径：DamageMin/DamageMax 成对，缺一个再退 GetUnitAttack 单值�?*/
    if (!(out->flags & DDH_AF_DAMAGE))
    {
        float dmin = 0.0f, dmax = 0.0f;
        const int idMin[] = { DDH_AN_DMG_MIN };
        const int idMax[] = { DDH_AN_DMG_MAX };
        int hmin = DdhAttrTryReals(idMin, 1, handle, 0, &dmin);
        int hmax = DdhAttrTryReals(idMax, 1, handle, 0, &dmax);
        bool okMin = (hmin >= 0) && DdhAttrFits(dmin, 0.0f, DDH_ATTR_DAMAGE_MAX);
        bool okMax = (hmax >= 0) && DdhAttrFits(dmax, 0.0f, DDH_ATTR_DAMAGE_MAX);
        if (okMin && okMax)
        {
            out->damageMin = dmin;
            out->damageMax = dmax;
            out->flags |= DDH_AF_DAMAGE;
            char note[200];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "攻击�?�?%s + %s（native 兜底：区间）",
                        DdhAttrUsedName(DDH_AN_DMG_MIN), DdhAttrUsedName(DDH_AN_DMG_MAX));
            DdhAttrFieldNote(2, note);
        }
        else
        {
            const int idAtk[] = { DDH_AN_ATTACK };
            float a = 0.0f;
            int ha = DdhAttrTryReals(idAtk, 1, handle, 0, &a);
            if (ha >= 0 && DdhAttrFits(a, 0.0f, DDH_ATTR_DAMAGE_MAX))
            {
                out->damageMin = a;
                out->damageMax = a;
                out->flags |= DDH_AF_DAMAGE;
                char note[200];
                _snprintf_s(note, sizeof(note), _TRUNCATE,
                            "攻击力", DdhAttrUsedName(DDH_AN_ATTACK));
                DdhAttrFieldNote(2, note);
            }
        }
    }

    /* ---- 攻击间隔：内存直读（prop+0x158）优先；native 兜底 ----
       Cooldown 直接是秒；AttackSpeed �?>1 视为“每秒次数”换�?1/值�?*/
    if (!(out->flags & DDH_AF_INTERVAL))
    {
        const int ids[] = { DDH_AN_COOLDOWN, DDH_AN_ATKSPEED };
        v = 0.0f;
        hit = DdhAttrTryReals(ids, 2, handle, 0, &v);
        if (hit >= 0)
        {
            const bool asSpeed = (hit == DDH_AN_ATKSPEED && v > 1.0f);
            const float iv = asSpeed ? (1.0f / v) : v;
            if (DdhAttrFits(iv, DDH_ATTR_INTERVAL_MIN, DDH_ATTR_INTERVAL_MAX))
            {
                char note[224];
                out->attackInterval = iv;
                out->flags |= DDH_AF_INTERVAL;
                if (asSpeed)
                    _snprintf_s(note, sizeof(note), _TRUNCATE,
                                "攻击间隔 ← %s（native 兜底：秒）",
                                DdhAttrUsedName(hit));
                else
                    _snprintf_s(note, sizeof(note), _TRUNCATE,
                                "攻击间隔 ← %s（native 兜底：秒）", DdhAttrUsedName(hit));
                DdhAttrFieldNote(3, note);
            }
        }
    }

    /* ---- 护甲：内存直读（CUnit+0xE0，按 int32 读）优先；native 兜底 ---- */
    if (!(out->flags & DDH_AF_ARMOR))
    {
        const int ids[] = { DDH_AN_ARMOR, DDH_AN_DEFENSE };
        v = 0.0f;
        hit = DdhAttrTryReals(ids, 2, handle, 0, &v);
        if (hit >= 0 && DdhAttrFits(v, DDH_ATTR_ARMOR_MIN, DDH_ATTR_ARMOR_MAX))
        {
            out->armor = v;
            out->flags |= DDH_AF_ARMOR;
            char note[160];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "护甲 ← %s（native 兜底：CUnit+0xE0 没拿到）", DdhAttrUsedName(hit));
            DdhAttrFieldNote(4, note);
        }
    }

    /* ---- 移速：GetUnitMoveSpeed �?GetUnitDefaultMoveSpeed（精确优先）----
       真机日志：自动匹配曾挑到 GetGameSpeed（返�?0），界面就显�?0�?
       现在 0/负数/越界一律视为“没测到”：不置 DDH_AF_MOVESPEED，C# 的【移速】列会退�?
       单位类型数据 spd（界�?? �?spd，绝不显�?0）�?*/
    {
        const int ids[] = { DDH_AN_MOVE, DDH_AN_MOVE_BASE };
        float mv = 0.0f;
        int   mh = -1;
        for (int i = 0; i < 2; ++i)
        {
            const uint32_t fn = DdhAttrNative(ids[i]);
            if (!fn) continue;
            float nv = 0.0f;
            if (!DdhNatCallReal(fn, handle, 0, &nv)) continue;
            if (!(nv > 0.0f) || nv > 100000.0f) continue;    /* 0 视为无效，继续试下一�?*/
            mv = nv;
            mh = ids[i];
            break;
        }
        if (mh >= 0)
        {
            out->moveSpeed = mv;
            out->flags |= DDH_AF_MOVESPEED;
            char note[192];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "移速", DdhAttrUsedName(mh), (double)mv);
            DdhAttrFieldNote(5, note);
        }
        else
        {
            char note[224];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "移速：%s / %s 返回 0/无效 → 视为没测到（界面退回 DzAPI spd，不显示 0）",
                        DdhAttrUsedName(DDH_AN_MOVE), DdhAttrUsedName(DDH_AN_MOVE_BASE));
            DdhAttrFieldNote(18, note);
        }
    }

    /* ---- 主动攻击范围：内存直读（prop+0x244）优先；native 兜底 ---- */
    if (!(out->flags & DDH_AF_ACQUIRE))
    {
        const int ids[] = { DDH_AN_ACQUIRE };
        v = 0.0f;
        hit = DdhAttrTryReals(ids, 1, handle, 0, &v);
        if (hit >= 0 && DdhAttrFits(v, 0.0f, DDH_ATTR_RANGE_MAX))
        {
            out->acquireRange = v;
            out->flags |= DDH_AF_ACQUIRE;
            char note[160];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "主动攻击范围 ← %s（native 兜底：内存直读没拿到）", DdhAttrUsedName(DDH_AN_ACQUIRE));
            DdhAttrFieldNote(7, note);
        }
    }

    /* ---- 英雄判定：优先标�?native GetUnitTypeId + IsHeroUnitId ----
       本图/平台�?GetHeroProperName 当字符串 id 用，反查不到文本时它不能�?
       “是不是英雄”的依据；标�?native 取类型码再问 IsHeroUnitId 最可靠�?*/
    {
        uint32_t typeId = 0, isHeroId = 0;
        if (DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &typeId) && typeId &&
            DdhAttrCallU32(DDH_AN_IS_HERO_ID, typeId, 0, &isHeroId))
        {
            heroKnown = true;
            hero = (isHeroId != 0);
            DdhAttrFieldNote(12, hero ? "英雄判定 ← GetUnitTypeId + IsHeroUnitId：是英雄"
                                      : "英雄判定 ← GetUnitTypeId + IsHeroUnitId：是英雄");
        }
    }

    /* ---- 力量 / 敏捷 / 智力（GetHeroStr/Agi/Int(handle, 0)，仅英雄�?----
       非英雄不�?flags（C# 显示 —）；英雄某一路没调通就不置那一位（C# 显示 ?）�?
       GetUnitTypeId + IsHeroUnitId 会先给出结论；此外“三维任一 > 0”也视为英雄
       （旧版真机同款的安全兜底），三路都调通且�?0 则确定不是英雄�?*/
    {
        const int strIds[] = { DDH_AN_HERO_STR, DDH_AN_STR };
        const int agiIds[] = { DDH_AN_HERO_AGI, DDH_AN_AGI };
        const int intIds[] = { DDH_AN_HERO_INT, DDH_AN_INT };
        float str = 0.0f, agi = 0.0f, intel = 0.0f;
        const int hs = DdhAttrTryStat(strIds, 2, handle, &str);
        const int ha = DdhAttrTryStat(agiIds, 2, handle, &agi);
        const int hi = DdhAttrTryStat(intIds, 2, handle, &intel);
        const bool okS = (hs >= 0);
        const bool okA = (ha >= 0);
        const bool okI = (hi >= 0);

        const bool anyStat = (okS && str > 0.0f) || (okA && agi > 0.0f) || (okI && intel > 0.0f);
        const bool allOk = okS && okA && okI;
        if (anyStat) { heroKnown = true; hero = true; }
        else if (!heroKnown && allOk) { heroKnown = true; hero = false; }

        if (heroKnown)
        {
            out->flags |= DDH_AF_HEROKNOWN;
            if (hero)
            {
                out->flags |= DDH_AF_HERO;
                if (okS)
                {
                    out->strength = str;
                    out->flags |= DDH_AF_STR;
                    char note[160];
                    _snprintf_s(note, sizeof(note), _TRUNCATE,
                                "力量 ← %s(handle, 0)（英雄三维）", DdhAttrUsedName(hs));
                    DdhAttrFieldNote(13, note);
                }
                if (okA)
                {
                    out->agility = agi;
                    out->flags |= DDH_AF_AGI;
                    char note[160];
                    _snprintf_s(note, sizeof(note), _TRUNCATE,
                                "敏捷 ← %s(handle, 0)（英雄三维）", DdhAttrUsedName(ha));
                    DdhAttrFieldNote(14, note);
                }
                if (okI)
                {
                    out->intelligence = intel;
                    out->flags |= DDH_AF_INT;
                    char note[160];
                    _snprintf_s(note, sizeof(note), _TRUNCATE,
                                "智力 ← %s(handle, 0)（英雄三维）", DdhAttrUsedName(hi));
                    DdhAttrFieldNote(15, note);
                }
            }
            else
            {
                /* 非英雄：�?�?智不适用（C# 显示 —）�? 不能当成“测到的数值�?*/
                out->strength = out->agility = out->intelligence = 0.0f;
            }
        }
    }

    /* ---- 单位类型基础数据（UnitBalance）：spd / def ----
       全部走探测选中�?DzAPI_UnitType_GetUnitTypeData* 实参组合（order / id形式 / JASS
       string 句柄）；没选中组合就一个都不填（界�??），绝不�?0 冒充�?
       协议 v14 �?sight/nsight 也不再从这里取：视野�?jass.slk（slk 取不到时 sightDay 退�?
       Game.dll+0x3ADF0）。这里只�?spd / def�?*/
    {
        float bv = 0.0f;

        if (DdhTypeDataNumber(handle, code, "spd", &bv) && bv > 0.0f && bv <= 100000.0f)
        {
            out->baseSpeed = bv;
            out->flags |= DDH_AF_BASE_SPEED;
            DdhAttrFieldNote(8, "基础速度 ← DzAPI_UnitType_GetUnitTypeDataInt(\"spd\")");
        }

        bv = 0.0f;
        if (DdhTypeDataNumber(handle, code, "def", &bv) && bv >= -100.0f && bv <= 1000.0f)
        {
            out->baseArmor = (int32_t)(bv >= 0.0f ? (bv + 0.5f) : (bv - 0.5f));
            out->flags |= DDH_AF_BASE_ARMOR;
            DdhAttrFieldNote(11, "基础护甲 ← DzAPI_UnitType_GetUnitTypeDataInt(\"def\")");
        }
    }

    /* ---- 称谓：Propernames 优先；GetHeroProperName/GetUnitName 作为后备 ---- */
    if (title[0] && (titleSrc == 4 || titleSrc == 1 || (heroKnown && hero)))
    {
        DdhUtf8SafeCopy(out->title, sizeof(out->title), title, sizeof(out->title) - 1);
        out->flags |= DDH_AF_TITLE;
    }

    /* ---- 单位附加值：GetUnitUserData（精确）�?DzAPI_UnitType_GetUnitTypeDataInt("points") ----
       GetUnitUserData �?0 也是合法值（调通就置位）；只有它不可用才退类型数据 points�?
       权威来源�?GetUnitUserData，GetItemUserData 已在排除名单里（真机日志里被选中的就是它）�?*/
    {
        uint32_t raw = 0;
        if (DdhAttrCallU32(DDH_AN_USERDATA, handle, 0, &raw))
        {
            out->extraValue = (int32_t)raw;
            out->flags |= DDH_AF_EXTRA;
            char note[160];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "单位附加值", DdhAttrUsedName(DDH_AN_USERDATA));
            DdhAttrFieldNote(16, note);
        }
        else
        {
            float pv = 0.0f;
            if (DdhTypeDataNumber(handle, code, "points", &pv) && pv >= -1000000.0f && pv <= 1000000.0f)
            {
                out->extraValue = (int32_t)(pv >= 0.0f ? (pv + 0.5f) : (pv - 0.5f));
                out->flags |= DDH_AF_EXTRA;
                DdhAttrFieldNote(19, "单位附加�?�?DzAPI_UnitType_GetUnitTypeDataInt(\"points\")"
                                     "（GetUnitUserData 不可用）");
            }
        }
    }

    /* v20：每进程一�?jass.slk 核对（只写日志；视野兜底已在上面按需生效）�?
       外层再包一�?__try：核对里任何异常都只写日志，不影响其它字�?其它单位�?*/
    __try { DdhExProbeOnce(obj, code, memSightOk, memSight, out); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        if (InterlockedIncrement(&g_ddhExProbeExcLog) == 1)
            LogLine("ATTR EX 核对异常 code=0x%08X（已吞掉，不影响其它字段）",
                    (unsigned)GetExceptionCode());
    }

    /* 第一次请求时把前几个单位的完整结果写进日志（prop 指针也打出来�?*/
    /* 选区单位 vs 钩子单位 对照 */
    if (InterlockedIncrement(&g_ddhSelCompare) <= 8)
    {
        uint32_t selUnit = DdhSelectedUnitPtr();
        LogLine("选区对照 %s obj=0x%08X sel=0x%08X diff=0x%X", DdhCodeText(code), obj, selUnit,
                (selUnit && selUnit > obj) ? (selUnit - obj) : (obj - selUnit));
    }

    /* 英雄块数值转储：只打印 1~500 的整数值 float，用于比对 24/17/16 */
    if (InterlockedIncrement(&g_ddhVerifyLogged) <= 120)
    {
        uint32_t hero = 0;
        __try { hero = *(const uint32_t*)(uintptr_t)(obj + 0x1F0); } __except (EXCEPTION_EXECUTE_HANDLER) { hero = 0; }

    /* 移速确认：同一条日志里打印 float / int / native 三种解释 */
    if (InterlockedIncrement(&g_ddhSpdProbe) <= 10)
    {
        uint32_t sb = 0, sp = 0;
        __try { sb = *(const uint32_t*)(uintptr_t)(obj + 0x1EC); } __except (EXCEPTION_EXECUTE_HANDLER) { sb = 0; }
        if (sb > 0x10000u && sb < 0x7FFFFFFFu)
        {
            __try { sp = *(const uint32_t*)(uintptr_t)(sb + 0x7C); } __except (EXCEPTION_EXECUTE_HANDLER) { sp = 0; }
        }
        float fv = 0.0f; int iv = 0;
        if (sp > 0x10000u && sp < 0x7FFFFFFFu)
        {
            __try { fv = *(const float*)(uintptr_t)sp; } __except (EXCEPTION_EXECUTE_HANDLER) { fv = 0.0f; }
            __try { iv = *(const int*)(uintptr_t)sp; } __except (EXCEPTION_EXECUTE_HANDLER) { iv = 0; }
        }
        LogLine("移速 %s sb=0x%08X sp=0x%08X float=%.2f int=%d native=%.2f",
                DdhCodeText(code), sb, sp, (double)fv, iv, (double)out->moveSpeed);
    }
        if (hero > 0x10000u && hero < 0x7FFFFFFFu)
        {
            for (uint32_t off = 0; off < 0x200; off += 4)
            {
                float fv = 0.0f;
                __try { fv = *(const float*)(uintptr_t)(hero + off); } __except (EXCEPTION_EXECUTE_HANDLER) { break; }
                int iv = (int)fv;
                if (fv == (float)iv && iv >= 1 && iv <= 500)
                    LogLine("英雄块 %s hero+0x%X = %d", DdhCodeText(code), off, iv);
            }
        }
    }
    /* 三围自动定位：在同一块里找 (str, agi, int) 三元组，候选间距 0x10/0x14/0x18/0x1C 都试；
       命中即缓存偏移，之后所有英雄直接用，不再逐次探测。 */
    if (!g_ddhHeroOffResolved && (out->flags & DDH_AF_STR) && (out->flags & DDH_AF_AGI) && (out->flags & DDH_AF_INT))
    {
        uint32_t hro = 0;
        __try { hro = *(const uint32_t*)(uintptr_t)(obj + 0x1EC); } __except (EXCEPTION_EXECUTE_HANDLER) { hro = 0; }
        if (hro > 0x10000u && hro < 0x7FFFFFFFu)
        {
            const int wantS = (int)out->strength, wantA = (int)out->agility, wantI = (int)out->intelligence;
            const uint32_t deltas[4] = { 0x10, 0x14, 0x18, 0x1C };
            for (uint32_t off = 0; off + 0x40 < 0x300 && !g_ddhHeroOffResolved; off += 4)
            {
                int v0 = 0;
                __try { v0 = *(const int*)(uintptr_t)(hro + off); } __except (EXCEPTION_EXECUTE_HANDLER) { break; }
                if (v0 != wantS) continue;
                for (int di = 0; di < 4; ++di)
                {
                    int v1 = 0, v2 = 0;
                    __try { v1 = *(const int*)(uintptr_t)(hro + off + deltas[di]); } __except (EXCEPTION_EXECUTE_HANDLER) { continue; }
                    __try { v2 = *(const int*)(uintptr_t)(hro + off + deltas[di] * 2); } __except (EXCEPTION_EXECUTE_HANDLER) { continue; }
                    if (v1 == wantA && v2 == wantI)
                    {
                        g_ddhHeroOffStr = off;
                        g_ddhHeroOffAgi = off + deltas[di];
                        g_ddhHeroOffInt = off + deltas[di] * 2;
                        g_ddhHeroOffResolved = 1;
                        LogLine("三围定位成功：str=+0x%X agi=+0x%X int=+0x%X（code=%s，%d/%d/%d）",
                                g_ddhHeroOffStr, g_ddhHeroOffAgi, g_ddhHeroOffInt, DdhCodeText(code), wantS, wantA, wantI);
                        break;
                    }
                }
            }
            if (!g_ddhHeroOffResolved && InterlockedIncrement(&g_ddhHeroFailLogged) <= 3)
                LogLine("三围定位失败：code=%s 块 0x%08X 内未找到 %d/%d/%d 三元组", DdhCodeText(code), hro, wantS, wantA, wantI);
        }
    }
DdhAttrLogUnit(obj, out, prop);
#endif
}

/* ---- �?addr 缓存 3 秒（v12；C# 每秒问一轮，同一单位不会被重复解析多次） ---- */
struct DdhAttrCacheEntry
{
    uint32_t    addr;
    uint32_t    tick;
    DdhUnitAttr attr;
};
static DdhAttrCacheEntry g_ddhAttrCache[DDH_ATTR_MAX];
static int      g_ddhAttrCacheCount = 0;
static uint32_t g_ddhAttrCacheNext  = 0;

static void DdhAttrFillCached(uint32_t obj, DdhUnitAttr* out, uint32_t tick)
{
    for (int i = 0; i < g_ddhAttrCacheCount; i++)
    {
        DdhAttrCacheEntry* c = &g_ddhAttrCache[i];
        if (c->addr != obj) continue;
        if ((uint32_t)(tick - c->tick) < DDH_ATTR_TTL_MS)
        {
            *out = c->attr;          /* 缓存命中：一�?native 都不�?*/
            out->addr = obj;
            return;
        }
        DdhAttrFillOne(obj, &c->attr);
        c->tick = tick;
        *out = c->attr;
        return;
    }

    int slot;
    if (g_ddhAttrCacheCount < DDH_ATTR_MAX) slot = g_ddhAttrCacheCount++;
    else { slot = (int)(g_ddhAttrCacheNext % DDH_ATTR_MAX); g_ddhAttrCacheNext++; }
    g_ddhAttrCache[slot].addr = obj;
    g_ddhAttrCache[slot].tick = tick;
    DdhAttrFillOne(obj, &g_ddhAttrCache[slot].attr);
    *out = g_ddhAttrCache[slot].attr;
}

/* ===========================================================================
   v14 诊断：单位对象数据（RegisterModel -> GetUnitData�?
   ---------------------------------------------------------------------------
   YDWE �?search_get_unit_data 并不是“字符串地址 +4”，而是�?
     �?在可执行/只读段里�?"RegisterModel\0" 的地址�?
     �?�?.text 里找引用该地址�?4 字节立即数（mov/push �?operand），记作 ref�?
     �?ref + 4 正好是那条指令之后，从那里继续找下一�?E8 rel32 调用�?
     �?call 目标 = E8 地址 + 5 + rel32，就�?GetUnitData(code)�?
   本函数每进程只跑一次：自动诊断（视�?称谓缺失）或 DDH_UDATA=dump 时触发；
   对两个单位各 dump idx 0..600（A=第一个英雄，B=类型码不同的单位），写同一个文件�?
   =========================================================================== */
#define DDH_UDATA_LAST_IDX 600   /* v19�?61 -> 601 行（idx 0..600�?*/

struct DdhUdataSection
{
    uint32_t begin;
    uint32_t end;
    uint32_t chars;
};

static volatile LONG g_ddhUdataDone = 0;
static volatile LONG g_ddhUdataForce = 0;   /* 视野/称谓缺失时自�?dump 一�?*/

/* 读一�?dword；坏指针不抛到调用�?*/
static int DdhUdataPoke(uint32_t addr, uint32_t* out)
{
    if (!out || addr < 0x10000u) return 0;
    __try { *out = *(const uint32_t*)(uintptr_t)addr; return 1; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

/* �?game.dll 的已映射段（大小限制�?SizeOfImage 内） */
static int DdhUdataSections(uint32_t base, DdhUdataSection* out, int cap)
{
    if (!base || !out || cap <= 0) return 0;
    const IMAGE_DOS_HEADER* dos = (const IMAGE_DOS_HEADER*)(uintptr_t)base;
    if (dos->e_magic != IMAGE_DOS_SIGNATURE) return 0;
    const IMAGE_NT_HEADERS32* nt =
        (const IMAGE_NT_HEADERS32*)((const uint8_t*)(uintptr_t)base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE ||
        nt->OptionalHeader.Magic != IMAGE_NT_OPTIONAL_HDR32_MAGIC) return 0;

    const uint32_t imageSize = nt->OptionalHeader.SizeOfImage;
    const IMAGE_SECTION_HEADER* sec = IMAGE_FIRST_SECTION(nt);
    int n = 0;
    for (WORD i = 0; i < nt->FileHeader.NumberOfSections && n < cap; ++i)
    {
        uint32_t size = sec[i].Misc.VirtualSize;
        if (!size) size = sec[i].SizeOfRawData;
        if (!size || sec[i].VirtualAddress >= imageSize) continue;
        if (size > imageSize - sec[i].VirtualAddress) size = imageSize - sec[i].VirtualAddress;
        out[n].begin = base + sec[i].VirtualAddress;
        out[n].end   = out[n].begin + size;
        out[n].chars = sec[i].Characteristics;
        ++n;
    }
    return n;
}

static int DdhUdataIsExec(const DdhUdataSection* sec, int n, uint32_t addr)
{
    for (int i = 0; i < n; ++i)
        if ((sec[i].chars & IMAGE_SCN_MEM_EXECUTE) &&
            addr >= sec[i].begin && addr < sec[i].end) return 1;
    return 0;
}

/* "RegisterModel" 含结�?NUL；只扫可读且非可写的段（.text/.rdata�?*/
static uint32_t DdhUdataFindRegisterModel(const DdhUdataSection* sec, int n)
{
    static const char kName[] = "RegisterModel";
    const uint32_t kLen = (uint32_t)sizeof(kName);   /* 13，含 NUL */
    for (int i = 0; i < n; ++i)
    {
        if (!(sec[i].chars & IMAGE_SCN_MEM_READ)) continue;
        if (sec[i].chars & IMAGE_SCN_MEM_WRITE) continue;
        const uint8_t* p = (const uint8_t*)(uintptr_t)sec[i].begin;
        const uint32_t bytes = sec[i].end - sec[i].begin;
        for (uint32_t off = 0; off + kLen <= bytes; ++off)
        {
            if (p[off] != 'R') continue;
            if (memcmp(p + off, kName, kLen) == 0) return sec[i].begin + off;
        }
    }
    return 0;
}

/* 在可执行段里找“谁引用了这个字符串地址”。返回的�?4 字节立即数自身的地址�?*/
static uint32_t DdhUdataFindStringRef(const DdhUdataSection* sec, int n, uint32_t strAddr)
{
    for (int i = 0; i < n; ++i)
    {
        if (!(sec[i].chars & IMAGE_SCN_MEM_EXECUTE)) continue;
        for (uint32_t addr = sec[i].begin; addr + 4u <= sec[i].end; ++addr)
        {
            uint32_t v = 0;
            memcpy(&v, (const void*)(uintptr_t)addr, 4);
            if (v == strAddr) return addr;
        }
    }
    return 0;
}

/* 从字符串引用之后�?4）找下一�?E8 rel32；目标必须落在可执行段且首字节不是填充�?*/
static uint32_t DdhUdataFindCall(const DdhUdataSection* sec, int n, uint32_t ref,
                                 uint32_t* outCallAddr)
{
    const uint32_t start = ref + 4u;
    for (int i = 0; i < n; ++i)
    {
        if (!(sec[i].chars & IMAGE_SCN_MEM_EXECUTE)) continue;
        if (start < sec[i].begin || start + 5u > sec[i].end) continue;

        uint32_t limit = start + 0x200u;
        if (limit > sec[i].end) limit = sec[i].end;
        for (uint32_t p = start; p + 5u <= limit; ++p)
        {
            if (*(const uint8_t*)(uintptr_t)p != 0xE8) continue;
            int32_t rel = 0;
            memcpy(&rel, (const void*)(uintptr_t)(p + 1u), 4);
            const uint32_t target = p + 5u + (uint32_t)rel;
            if (!DdhUdataIsExec(sec, n, target)) continue;

            uint32_t head = 0;
            if (!DdhUdataPoke(target, &head)) continue;
            const uint8_t op = (uint8_t)(head & 0xFFu);
            if (op == 0xCCu || op == 0x00u) continue;   /* int3 / 空白，不像函数入�?*/
            if (outCallAddr) *outCallAddr = p;
            return target;
        }
    }
    return 0;
}

static int DdhUdataWanted(void)
{
    if (g_ddhUdataForce) return 1;
    char buf[32] = { 0 };
    const DWORD n = GetEnvironmentVariableA("DDH_UDATA", buf, (DWORD)sizeof(buf));
    if (n == 0 || n >= (DWORD)sizeof(buf)) return 0;
    return _stricmp(buf, "dump") == 0;
}

static void DdhUdataPath(char* out, size_t cap, DWORD pid)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    char dir[MAX_PATH] = { 0 };
    if (g_logPath[0]) strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) slash[1] = 0;
    else dir[0] = 0;
    DdhSprintf(out, cap, "%sddh-%lu.udata.txt", dir, (unsigned long)pid);
}

/* 只探测，不实现逻辑；每个名字固定一�?*/
static void DdhUdataProbeNatives(void)
{
    static const char* const kNames[] =
    {
        "EXGetUnitReal", "EXGetUnitInteger", "EXGetUnitString",
        "GetUnitTypeId", "IsHeroUnitId", "GetUnitSightRange",
        "GetUnitArmor", "GetUnitDamage", "GetUnitAttackRange"
    };
    for (int i = 0; i < (int)(sizeof(kNames) / sizeof(kNames[0])); ++i)
    {
        const uint32_t fn = FindNativeFunc(kNames[i]);
        LogLine("UDATA native %s=%s", kNames[i], fn ? "已定位" : "未找到");
    }
}

/* ---- v19：dump 标记值（float 误差 0.5，int 精确�?---
   这些值既可能�?sight/nsight，也可能�?spd�?60/315/300/320 与移速重合）�?
   所以只�?<SIGHT?> 作为“候选”提示，不直接当成视野�?*/
static int DdhUdataSightFloat(float f)
{
    static const float kHit[] =
    {
        1400.0f, 1100.0f, 1500.0f, 1200.0f, 900.0f, 800.0f,
        650.0f, 550.0f, 360.0f, 315.0f, 300.0f, 320.0f
    };
    for (int i = 0; i < (int)(sizeof(kHit) / sizeof(kHit[0])); ++i)
    {
        double d = (double)f - (double)kHit[i];
        if (d < 0.0) d = -d;
        if (d <= 0.5) return 1;
    }
    return 0;
}

static int DdhUdataSightInt(int v)
{
    switch (v)
    {
    case 1400: case 1100: case 1500: case 1200:
    case 900:  case 800:  case 650:  case 550:
    case 360:  case 315:  case 300:  case 320:
        return 1;
    default:
        return 0;
    }
}

/* 分隔行里�?name 不能带引�?换行，否则一�?dump 的边界会被写坏�?*/
static void DdhUdataSafeName(const char* src, char* out, size_t cap)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    if (!src) return;
    size_t j = 0;
    for (size_t i = 0; src[i] && j + 1 < cap; ++i)
    {
        char c = src[i];
        if (c == '"' || c == '\r' || c == '\n' || c == '\t') c = ' ';
        out[j++] = c;
    }
    out[j] = 0;
}

struct DdhUdataPick
{
    uint32_t obj;
    uint32_t code;
    int      hero;          /* 1 = 英雄�? = 非英�?未知 */
    char     type[8];
    char     name[64];
};

/* 从属性请求槽 i 取一个候选：addr/code/type/name/hero 都先在这里定型�?*/
static void DdhUdataFillPick(int slot, DdhUdataPick* p)
{
    memset(p, 0, sizeof(*p));
    if (slot < 0 || slot >= DDH_ATTR_MAX) return;
    p->obj = g_shm->attrs.unitAddr[slot];
    if (!p->obj) return;
    p->code = SafeCode(p->obj);
    DdhAttrTypeCode(p->code, p->type);

    const DdhUnitAttr* a = &g_shm->attrs.attr[slot];
    if ((a->flags & DDH_AF_HEROKNOWN) != 0)
    {
        p->hero = (a->flags & DDH_AF_HERO) ? 1 : 0;
    }
    else if (p->code)
    {
        uint32_t isHero = 0;
        if (DdhAttrCallU32(DDH_AN_IS_HERO_ID, p->code, 0, &isHero))
            p->hero = (isHero != 0) ? 1 : 0;
    }
    if ((a->flags & DDH_AF_NAME) != 0 && a->name[0])
        DdhUdataSafeName(a->name, p->name, sizeof(p->name));
}

/* B 的选择顺序：类型码不同的英�?-> 类型码不同的有名单位 -> 类型码不同的任意单位
   -> 同类型码的英�?-> 同类型码的有名单�?-> 同类型码的任意单位�?
   最后三级是假魔�?单类型图（所有单�?code 都一样）的兜底，保证仍有两段�?*/
static int DdhUdataFindB(const DdhUdataPick* p, int n, int ai)
{
    for (int i = 0; i < n; ++i)
        if (i != ai && p[i].code != p[ai].code && p[i].hero) return i;
    for (int i = 0; i < n; ++i)
        if (i != ai && p[i].code != p[ai].code && p[i].name[0]) return i;
    for (int i = 0; i < n; ++i)
        if (i != ai && p[i].code != p[ai].code) return i;
    for (int i = 0; i < n; ++i)
        if (i != ai && p[i].hero) return i;
    for (int i = 0; i < n; ++i)
        if (i != ai && p[i].name[0]) return i;
    for (int i = 0; i < n; ++i)
        if (i != ai) return i;
    return -1;
}

/* �?GetUnitData(code)：__fastcall，code �?ecx。失败返�?0 并给出异常码�?*/
static uintptr_t DdhUdataCallGetUnitData(uint32_t fn, uint32_t code, uint32_t obj,
                                         const char* label, DWORD* outExc)
{
    typedef uintptr_t (__fastcall* fn_udata_t)(uint32_t);
    uintptr_t data = 0;
    DWORD exc = 0;
    __try { data = ((fn_udata_t)(uintptr_t)fn)(code); }
    __except (EXCEPTION_EXECUTE_HANDLER) { exc = GetExceptionCode(); data = 0; }
    if (outExc) *outExc = exc;
    LogLine("UDATA�?s GetUnitData(code=0x%08X obj=0x%08X) = 0x%08X%s",
            label, code, obj, (unsigned)data, exc ? "（调用异常）" : "");
    return data;
}

/* 一个单位一段：BEGIN 分隔�?+ idx 0..600（最�?601 行）+ END。返回实际行数�?*/
static int DdhUdataDumpSection(FILE* fp, uint32_t dataPtr, uint32_t obj,
                               uint32_t code, const char* name)
{
    char type[8] = { 0 };
    char safeName[64] = { 0 };
    DdhAttrTypeCode(code, type);
    DdhUdataSafeName(name, safeName, sizeof(safeName));

    if (fp)
        fprintf(fp, "=== BEGIN unit=%s name=\"%s\" data=0x%08X ===\r\n",
                type, safeName, dataPtr);

    int dumped = 0;
    for (int i = 0; i <= DDH_UDATA_LAST_IDX; ++i)
    {
        uint32_t v = 0;
        if (!DdhUdataPoke(dataPtr + (uint32_t)i * 4u, &v))
        {
            if (fp) fprintf(fp, "UDATA idx=%3d  <unreadable>\r\n", i);
            LogLine("UDATA：unit=%s obj=0x%08X data=0x%08X 读到 idx=%d 失败，本段提前结束",
                    type, obj, dataPtr, i);
            break;
        }
        float fv = 0.0f;
        memcpy(&fv, &v, 4);
        const int mark = DdhUdataSightFloat(fv) || DdhUdataSightInt((int)v);
        if (fp)
            fprintf(fp, "UDATA idx=%3d int=%12d float=%14.4f ptr=%08X%s\r\n",
                    i, (int)v, (double)fv, v, mark ? "  <SIGHT?>" : "");
        ++dumped;
    }

    if (fp)
    {
        fprintf(fp, "=== END ===\r\n");
        fflush(fp);
    }
    return dumped;
}

/* 入口：环境变�?+ 只跑一次；必须在游戏线程（DdhProcessAttrRequest 里）调用�?*/
static void DdhUdataMaybeDumpFirstRequest(void)
{
    if (!DdhUdataWanted()) return;
    if (InterlockedCompareExchange(&g_ddhUdataDone, 1, 0) != 0) return;

    LogLine("UDATA：失败，共享内存未就绪",
            g_ddhUdataForce ? "视野/称谓缺失，自动诊断" : "DDH_UDATA=dump");

    /* �?先探�?native：即使搜不到 GetUnitData 也要有这几行 */
    DdhUdataProbeNatives();

    if (!g_modBase)
    {
        LogLine("UDATA：失败，game.dll 基址为 0，GetUnitData 无法定位");
        return;
    }

    DdhUdataSection sec[32];
    const int n = DdhUdataSections(g_modBase, sec, (int)(sizeof(sec) / sizeof(sec[0])));
    if (n <= 0)
    {
        LogLine("UDATA：失败，game.dll 的 PE 段表读不出来，GetUnitData 无法定位");
        return;
    }

    /* �?字符�?*/
    const uint32_t strAddr = DdhUdataFindRegisterModel(sec, n);
    if (!strAddr)
    {
        LogLine("UDATA：失败，game.dll 可执行/只读段里没有 RegisterModel（含结尾 0），GetUnitData 无法定位");
        return;
    }

    /* �?字符串引用（mov/push �?4 字节立即数） */
    const uint32_t ref = DdhUdataFindStringRef(sec, n, strAddr);
    if (!ref)
    {
        LogLine("UDATA：失败，找到 RegisterModel 字符串=0x%08X，但 .text 里没有引用它的立即数", strAddr);
        return;
    }

    /* �?ref+4 后找 E8，算 call 目标 */
    uint32_t callAddr = 0;
    const uint32_t fn = DdhUdataFindCall(sec, n, ref, &callAddr);
    if (!fn)
    {
        LogLine("UDATA：失败，RegisterModel 字符串=0x%08X 引用=0x%08X，但 +4 后 0x200 字节内没有有效 E8 rel32",
                strAddr, ref);
        return;
    }

    LogLine("UDATA：RegisterModel 字符串=0x%08X，E8@0x%08X，GetUnitData=0x%08X（RVA 0x%X）",
            strAddr, callAddr, fn, fn - g_modBase);
    LogLine("UDATA：RegisterModel 引用=0x%08X（YDWE 口径：引用立即数 +4 后找 E8；字符串地址本身 +4 不是指令边界）",
            ref);

    if (!g_shm)
    {
        LogLine("UDATA：失败，共享内存未就绪");
        return;
    }

    /* ---- 选两个单位：A = 第一个英雄；B = 类型码不同的单位 ----
       英雄判定优先�?ATTR 已算好的 flags（GetUnitTypeId+IsHeroUnitId 或三�?0），
       没有 flags 时再问一�?IsHeroUnitId；名字优先用 ATTR 里的，空才调 ResolveName�?*/
    DdhUdataPick cands[DDH_ATTR_MAX];
    int ncand = 0;
    for (int i = 0; i < DDH_ATTR_MAX; ++i)
    {
        if (!g_shm->attrs.unitAddr[i]) continue;
        DdhUdataPick one;
        DdhUdataFillPick(i, &one);
        if (!one.obj || !one.code) continue;
        int dup = 0;
        for (int k = 0; k < ncand; ++k)
            if (cands[k].obj == one.obj) { dup = 1; break; }
        if (dup) continue;
        cands[ncand++] = one;
    }
    if (ncand == 0)
    {
        LogLine("UDATA：第一次属性请求没有可用单位（addr/类型码为 0），本次不 dump");
        return;
    }

    int ai = -1;
    for (int i = 0; i < ncand; ++i)
        if (cands[i].hero) { ai = i; break; }
    if (ai < 0) ai = 0;

    const int bi = DdhUdataFindB(cands, ncand, ai);

    LogLine("UDATA：选单位 A=%s name=\"%s\" obj=0x%08X hero=%d；B=%s name=\"%s\" obj=0x%08X hero=%d（候选=%d）",

            cands[ai].type, cands[ai].name, cands[ai].obj, cands[ai].hero,
            bi >= 0 ? cands[bi].type : "-", bi >= 0 ? cands[bi].name : "",
            bi >= 0 ? cands[bi].obj : 0, bi >= 0 ? cands[bi].hero : 0, ncand);

    if (!cands[ai].name[0])
    {
        char nm[64] = { 0 };
        ResolveName(cands[ai].obj, cands[ai].code, nm, sizeof(nm));
        DdhUdataSafeName(nm, cands[ai].name, sizeof(cands[ai].name));
    }
    if (bi >= 0 && !cands[bi].name[0])
    {
        char nm[64] = { 0 };
        ResolveName(cands[bi].obj, cands[bi].code, nm, sizeof(nm));
        DdhUdataSafeName(nm, cands[bi].name, sizeof(cands[bi].name));
    }

    /* ---- 同一个文件，两段；先�?A 再写 B ---- */
    const DWORD pid = GetCurrentProcessId();
    char path[MAX_PATH] = { 0 };
    DdhUdataPath(path, sizeof(path), pid);
    FILE* fp = NULL;
    if (path[0]) fopen_s(&fp, path, "wb");
    if (fp)
    {
        fprintf(fp, "# ddh unit data dump\r\n");
        fprintf(fp, "# pid=%lu idx=0..%d marker={1400,1100,1500,1200,900,800,650,550,360,315,300,320}\r\n",
                (unsigned long)pid, DDH_UDATA_LAST_IDX);
        fflush(fp);
    }
    else
    {
        LogLine("UDATA：警告，dump 文件打不开：%s", path[0] ? path : "(空路径)");
    }

    DWORD excA = 0;
    const uintptr_t dataA = DdhUdataCallGetUnitData(fn, cands[ai].code, cands[ai].obj, "A", &excA);
    int linesA = 0;
    if (dataA)
        linesA = DdhUdataDumpSection(fp, (uint32_t)dataA, cands[ai].obj,
                                     cands[ai].code, cands[ai].name);
    else
        LogLine("UDATA：A 失败，GetUnitData 返回 0 或异常=%08X", (unsigned)excA);

    uintptr_t dataB = 0;
    DWORD excB = 0;
    int linesB = 0;
    if (bi >= 0)
    {
        dataB = DdhUdataCallGetUnitData(fn, cands[bi].code, cands[bi].obj, "B", &excB);
        if (dataB)
            linesB = DdhUdataDumpSection(fp, (uint32_t)dataB, cands[bi].obj,
                                         cands[bi].code, cands[bi].name);
        else
            LogLine("UDATA：B 失败，GetUnitData 返回 0 或异常=%08X", (unsigned)excB);
    }
    else
    {
        LogLine("UDATA：B 未找到（只有一个可用单位），本次只 dump A");
    }

    if (fp) fclose(fp);
    LogLine("UDATA：dump A=%s data=0x%08X 行数=%d；B=%s data=0x%08X 行数=%d",
            cands[ai].type, (unsigned)dataA, linesA,
            bi >= 0 ? cands[bi].type : "-", (unsigned)dataB, linesB);
    if (path[0])
        LogLine("UDATA：dump 文件=%s", path);
}


/* ===========================================================================
   v16 诊断：DDH_UPROBE=1 —�?视野（sight�? 英雄称谓（Propernames）反�?
   ---------------------------------------------------------------------------
   只在第一次属性请求（游戏线程）对第一个单位跑一次：
     �?单位基本信息：addr / typeCode / name / prop 指针�?
     �?unit_property +0x00..+0x300 �?dword；float 命中已知值（sight/nsight/
        spd/acquire/HP/STR/AGI/INT 等）时额外写一行候选字段名�?
     �?GetUnitData(code) +0x00..+0x300 �?dword；像指针�?dword �?char* �?
        最�?64 字节，可打印（ASCII/UTF-8/GBK）就追加 str="..."，含 野王/安东
        的项�?<<< 标出（UTF-8 �?GBK 两种编码都试）；
     �?在进程可读、非映像内存里找 安东 �?UTF-8（E5 AE 89 E4 B8 9C）与
        GBK（B0 B2 B6 AB），最�?8 处，打印每处前后�?8 �?dword�?
        NUL 结尾的合法文本优先，随机字节命中也保留（�?text=no）�?
   限额：每段最�?200 行；扫描最�?512MB / 2500ms；全�?__try，失败只写日志�?
   实现顺序：先�?④（避免 dump 日志里的“安东”被自己扫到），再打�?①②③�?
   未设�?DDH_UPROBE �?g_ddhUprobeOn=0，一个字节都不读、一行都不写�?
   =========================================================================== */

#define DDH_UPROBE_MAX_HITS        8
#define DDH_UPROBE_SCAN_MAX_BYTES  (512u * 1024u * 1024u)
#define DDH_UPROBE_SCAN_TIMEOUT_MS 2500u
#define DDH_UPROBE_MAX_KNOWN_LINES 6

static int           g_ddhUprobeOn    = 0;   /* DllMain 里读一次环境变�?*/
static volatile LONG g_ddhUprobeDone  = 0;
static volatile LONG g_ddhUprobeTries = 0;
static FILE*         g_ddhUprobeFp   = NULL;

static int DdhUprobeReadEnv(void)
{
    char buf[32] = { 0 };
    const DWORD n = GetEnvironmentVariableA("DDH_UPROBE", buf, (DWORD)sizeof(buf));
    if (n == 0 || n >= (DWORD)sizeof(buf)) return 0;
    return _stricmp(buf, "1") == 0 || _stricmp(buf, "true") == 0 ||
           _stricmp(buf, "yes") == 0 || _stricmp(buf, "on") == 0;
}

static void DdhUprobePath(char* out, size_t cap)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    char dir[MAX_PATH] = { 0 };
    if (g_logPath[0]) strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) slash[1] = 0;
    else dir[0] = 0;
    DdhSprintf(out, cap, "%sddh-%lu.uprobe.txt", dir, (unsigned long)GetCurrentProcessId());
}

/* 每行同时�?ddh-<pid>.log �?ddh-<pid>.uprobe.txt；文件每�?flush�?
   真机中途崩了也能留下已�?dump 的部分�?*/
static void DdhUprobeLine(const char* fmt, ...)
{
    char buf[2048];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(buf, sizeof(buf), _TRUNCATE, fmt, ap);
    va_end(ap);

    LogLine("%s", buf);
    if (g_ddhUprobeFp)
    {
        fprintf(g_ddhUprobeFp, "%s\r\n", buf);
        fflush(g_ddhUprobeFp);
    }
}

static void DdhUprobeEscape(char* dst, size_t cap, const char* src, size_t n)
{
    if (!dst || cap == 0) return;
    dst[0] = 0;
    if (!src) return;
    size_t pos = 0;
    for (size_t i = 0; i < n && src[i] && pos + 2 < cap; ++i)
    {
        const unsigned char c = (unsigned char)src[i];
        if (c == '"' || c == '\\') { dst[pos++] = '\\'; dst[pos++] = (char)c; }
        else if (c >= 0x20 && c != 0x7F) dst[pos++] = (char)c;
        else dst[pos++] = '?';
    }
    dst[pos] = 0;
}

/* 16 进制串：�?东（UTF-8 / GBK）、野 王（UTF-8 / GBK）�?*/
static const unsigned char kDdhUprobeAntonUtf8[6]  = { 0xE5, 0xAE, 0x89, 0xE4, 0xB8, 0x9C };
static const unsigned char kDdhUprobeAntonGbk[4]   = { 0xB0, 0xB2, 0xB6, 0xAB };
static const unsigned char kDdhUprobeYewangUtf8[6] = { 0xE9, 0x87, 0x8E, 0xE7, 0x8E, 0x8B };
static const unsigned char kDdhUprobeYewangGbk[4]  = { 0xD2, 0xB0, 0xCD, 0xF5 };

/* 读一�?0 结尾字符串，最�?cap-1 字节；读不到 / 没有 NUL 都算失败�?*/
static int DdhUprobeReadCString(uint32_t addr, char* out, size_t cap)
{
    if (!out || cap < 2 || addr < 0x10000u) return 0;
    out[0] = 0;
    int n = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)addr;
        for (; n < (int)cap - 1; ++n)
        {
            const unsigned char c = p[n];
            if (!c) break;
            out[n] = (char)c;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { out[0] = 0; return 0; }
    if (n <= 0) { out[0] = 0; return 0; }   /* 没有 NUL 也算读到 cap-1 字节，下面标 (截断) */
    out[n] = 0;
    return n;
}

static int DdhUprobeAscii(const unsigned char* p, int n)
{
    for (int i = 0; i < n; ++i)
        if (p[i] < 0x20 || p[i] > 0x7E) return 0;
    return 1;
}

/* 严格一点的 UTF-8：拒绝截断、孤立续字节、过长编码�?*/
static int DdhUprobeUtf8(const unsigned char* p, int n)
{
    int i = 0;
    while (i < n)
    {
        const unsigned char c = p[i];
        if (c < 0x80)
        {
            if (c < 0x20 || c == 0x7F) return 0;
            ++i;
            continue;
        }
        int need;
        unsigned int cp;
        if ((c & 0xE0) == 0xC0)      { need = 1; cp = c & 0x1Fu; }
        else if ((c & 0xF0) == 0xE0) { need = 2; cp = c & 0x0Fu; }
        else if ((c & 0xF8) == 0xF0) { need = 3; cp = c & 0x07u; }
        else return 0;
        if (i + need >= n) return 0;
        for (int k = 1; k <= need; ++k)
        {
            const unsigned char t = p[i + k];
            if ((t & 0xC0) != 0x80) return 0;
            cp = (cp << 6) | (t & 0x3Fu);
        }
        if ((need == 1 && cp < 0x80u) || (need == 2 && cp < 0x800u) ||
            (need == 3 && cp < 0x10000u) || cp > 0x10FFFFu) return 0;
        i += need + 1;
    }
    return 1;
}

/* GBK：ASCII 单字�?+ 0x81..0xFE 双字节（尾字�?0x40..0xFE，去�?0x7F）�?*/
static int DdhUprobeGbk(const unsigned char* p, int n)
{
    int i = 0;
    while (i < n)
    {
        const unsigned char c = p[i];
        if (c < 0x80)
        {
            if (c < 0x20 || c == 0x7F) return 0;
            ++i;
            continue;
        }
        if (c == 0x80) { ++i; continue; }   /* GBK 的欧元符�?*/
        if (c < 0x81 || c > 0xFE) return 0;
        if (i + 1 >= n) return 0;
        const unsigned char t = p[i + 1];
        if (t < 0x40 || t > 0xFE || t == 0x7F) return 0;
        i += 2;
    }
    return 1;
}

/* 1 = ASCII�? = UTF-8�? = GBK�? = 不像文本。UTF-8 先试（GBK 双字�?
   也能“碰巧”通过 GBK 校验，所以不能先�?GBK）�?*/
static int DdhUprobeTextKind(const unsigned char* p, int n)
{
    if (!p || n <= 0) return 0;
    if (DdhUprobeAscii(p, n)) return 1;
    if (DdhUprobeUtf8(p, n))  return 2;
    if (DdhUprobeGbk(p, n))   return 3;
    return 0;
}

static int DdhUprobeHas(const unsigned char* p, int n, const unsigned char* pat, int plen)
{
    if (!p || !pat || n < plen || plen <= 0) return 0;
    for (int i = 0; i + plen <= n; ++i)
        if (memcmp(p + i, pat, (size_t)plen) == 0) return 1;
    return 0;
}

static const char* DdhUprobeMark(const unsigned char* p, int n)
{
    const int a8 = DdhUprobeHas(p, n, kDdhUprobeAntonUtf8, 6);
    const int a9 = DdhUprobeHas(p, n, kDdhUprobeAntonGbk, 4);
    const int y8 = DdhUprobeHas(p, n, kDdhUprobeYewangUtf8, 6);
    const int y9 = DdhUprobeHas(p, n, kDdhUprobeYewangGbk, 4);
    if ((a8 || a9) && (y8 || y9)) return "命中 野王+安东";
    if (a8) return "命中 安东(UTF-8)";
    if (a9) return "命中 安东(GBK)";
    if (y8) return "命中 野王(UTF-8)";
    if (y9) return "命中 野王(GBK)";
    return NULL;
}

/* 真机 unit.ini �?H037 样本值。已知字段按表映射，未确定的先写“待确认”�?*/
struct DdhUprobeKnownValue { float value; const char* name; };
static const DdhUprobeKnownValue kDdhUprobeKnownValues[] =
{
    { 1500.0f, "sight" },
    { 1100.0f, "nsight" },
    {  300.0f, "spd" },
    {  650.0f, "acquire" },
    {  250.0f, "待确认(250)" },
    {  140.0f, "待确认(140)" },
    {   1.93f, "攻击间隔/冷却(推测)" },
    {   36.0f, "待确认(36)" },
    {    6.0f, "待确认(6)" },
    {    5.0f, "待确认(5)" },
    {   31.0f, "STR" },
    {   19.0f, "AGI" },
    {   15.0f, "INT" },
    {  175.0f, "HP" }
};

static const char* DdhUprobeKnownName(float f)
{
    const int cnt = (int)(sizeof(kDdhUprobeKnownValues) / sizeof(kDdhUprobeKnownValues[0]));
    for (int i = 0; i < cnt; ++i)
    {
        double d = (double)f - (double)kDdhUprobeKnownValues[i].value;
        if (d < 0.0) d = -d;
        if (d <= 0.01) return kDdhUprobeKnownValues[i].name;
    }
    return NULL;
}

/* 有些字段�?int 存（UnitBalance �?sight/nsight 就是）：只认 >=100 的特征整数，
   避免 5/6/15 这种到处都有的值刷屏；单独�?(int)，不占已知值命中行�?*/
static const char* DdhUprobeKnownIntName(uint32_t v)
{
    switch (v)
    {
    case 1500u: return "sight";
    case 1100u: return "nsight";
    case 650u:  return "acquire";
    case 300u:  return "spd";
    case 250u:  return "待确认(250)";
    case 175u:  return "HP";
    case 140u:  return "待确认(140)";
    default:    return NULL;
    }
}

/* �?dword 打一段内存：tag +0x000..+0x300�?93 行）�?
   scanStrings=1 时把指针 dword �?char* 读（最�?64 字节），可打印就追加 str="..."�?
   已知值匹配最�?6 行，保证 193 + 6 + 段首 1 �?= 200 行上限�?*/
static void DdhUprobeDumpDwords(const char* tag, uint32_t base, int scanStrings)
{
    int knownLines = 0;
    for (uint32_t off = 0; off <= 0x300u; off += 4u)
    {
        uint32_t v = 0;
        if (!DdhUdataPoke(base + off, &v))
        {
            DdhUprobeLine("%s +0x%03X  <读取失败>", tag, off);
            return;
        }
        float f = 0.0f;
        memcpy(&f, &v, 4);

        char extra[768];
        extra[0] = 0;
        if (scanStrings && v >= 0x01000000u && v <= 0x7FFFFFFFu)
        {
            char s[65] = { 0 };
            const int sn = DdhUprobeReadCString(v, s, sizeof(s));
            if (sn > 0)
            {
                const int kind = DdhUprobeTextKind((const unsigned char*)s, sn);
                if (kind)
                {
                    char esc[192] = { 0 };
                    DdhUprobeEscape(esc, sizeof(esc), s, (size_t)sn);
                    const char* mark = DdhUprobeMark((const unsigned char*)s, sn);
                    const char* kindName = (kind == 1) ? "ASCII" : (kind == 2 ? "UTF-8" : "GBK");
                    const char* cut = (sn >= (int)sizeof(s) - 1) ? " (截断)" : "";
                    if (mark)
                    {
                        char hex[64] = { 0 };
                        FormatHex((const unsigned char*)s, sn < 16 ? sn : 16, hex, sizeof(hex));
                        _snprintf_s(extra, sizeof(extra), _TRUNCATE,
                                    "  -> str=\"%s\" [%s]  <<< %s hex=%s%s",
                                    esc, kindName, mark, hex, cut);
                    }
                    else
                    {
                        _snprintf_s(extra, sizeof(extra), _TRUNCATE,
                                    "  -> str=\"%s\" [%s]%s", esc, kindName, cut);
                    }
                }
            }
        }

        const char* known = DdhUprobeKnownName(f);
        char knownTag[80];
        knownTag[0] = 0;
        if (known)
            _snprintf_s(knownTag, sizeof(knownTag), _TRUNCATE, "  <已知值:%s>", known);
        else
        {
            const char* intName = DdhUprobeKnownIntName(v);
            if (intName)
                _snprintf_s(knownTag, sizeof(knownTag), _TRUNCATE, "  <已知值(int):%s>", intName);
        }

        DdhUprobeLine("%s +0x%03X  dword=%08X  int=%d  float=%.4f%s%s",
                      tag, off, v, (int)v, (double)f, extra, knownTag);

        if (known && knownLines < DDH_UPROBE_MAX_KNOWN_LINES)
        {
            DdhUprobeLine("%s 命中已知值：+0x%03X = %.4f（%s）",
                          tag, off, (double)f, known);
            ++knownLines;
        }
    }
}

static void DdhUprobeDumpProp(uint32_t prop)
{
    if (!prop || !DdhPropReadable(prop))
    {
        DdhUprobeLine("PROP 不可读（CUnit+0x1E8=0x%08X：为 0 / 坏指针 / 未对齐 / 跨页），跳过 prop dump", prop);
        return;
    }
    DdhUprobeLine("PROP base=0x%08X（CUnit+0x1E8），范围 +0x000..+0x300", prop);
    DdhUprobeDumpDwords("PROP", prop, 0);
}

/* RegisterModel -> GetUnitData 的定位（�?DDH_UDATA=dump 同一套口径）�?*/
static uint32_t DdhUprobeFindGetUnitData(void)
{
    if (!g_modBase)
    {
        DdhUprobeLine("DATA 跳过：game.dll 基址为 0");
        return 0;
    }
    DdhUdataSection sec[32];
    const int n = DdhUdataSections(g_modBase, sec, (int)(sizeof(sec) / sizeof(sec[0])));
    if (n <= 0)
    {
        DdhUprobeLine("DATA 跳过：game.dll 的 PE 段表读不出来");
        return 0;
    }
    const uint32_t strAddr = DdhUdataFindRegisterModel(sec, n);
    if (!strAddr)
    {
        DdhUprobeLine("DATA 跳过：game.dll 只读段里没有 RegisterModel 字符串（假 game.dll 就是这样）");
        return 0;
    }
    const uint32_t ref = DdhUdataFindStringRef(sec, n, strAddr);
    if (!ref)
    {
        DdhUprobeLine("DATA 跳过：RegisterModel=0x%08X 但 .text 里没有引用它的立即数", strAddr);
        return 0;
    }
    uint32_t callAddr = 0;
    const uint32_t fn = DdhUdataFindCall(sec, n, ref, &callAddr);
    if (!fn)
    {
        DdhUprobeLine("DATA 跳过：RegisterModel 引用=0x%08X，+4 后没有有效 E8 rel32", ref);
        return 0;
    }
    DdhUprobeLine("DATA GetUnitData 已定位：RegisterModel=0x%08X ref=0x%08X E8@0x%08X fn=0x%08X（RVA 0x%X）",
                  strAddr, ref, callAddr, fn, fn - g_modBase);
    return fn;
}

/* ---------------- 字符串扫描：�?Propernames 的存放处 ---------------- */

struct DdhUprobeHit
{
    uint32_t addr;
    uint32_t region;
    uint32_t regionSize;
    uint32_t protect;
    int      enc;        /* 0 = UTF-8�? = GBK */
    int      textOk;     /* 1 = 命中点前后能组成一�?NUL 结尾的合法文�?*/
};

static int DdhUprobeProtReadable(DWORD prot)
{
    if (prot & (PAGE_NOACCESS | PAGE_GUARD)) return 0;   /* 保护�?guard 一读就 AV */
    switch (prot & 0xFFu)
    {
    case PAGE_READONLY:
    case PAGE_READWRITE:
    case PAGE_WRITECOPY:
    case PAGE_EXECUTE_READ:
    case PAGE_EXECUTE_READWRITE:
    case PAGE_EXECUTE_WRITECOPY:
        return 1;
    default:
        return 0;
    }
}

/* 命中点是否落在一�?NUL 结尾的合法文本里�?
     向前最�?256 字节�?NUL 当串首（找不到就从命中点本身开始）�?
     向后最�?511 字节�?NUL；整条串按对应编码校验�?
   随机二进制里的四字节巧合通常在这里被刷掉（text=no），
   �?Propernames�?安东,..."）会得到 text=yes�?*/
static int DdhUprobeHitTextOk(uint32_t addr, int enc)
{
    if (addr < 0x10000u) return 0;
    unsigned char buf[512];

    int back = 0;
    __try
    {
        for (int k = 1; k <= 256; ++k)
        {
            if (addr < (uint32_t)k) break;
            if (*(const unsigned char*)(uintptr_t)(addr - (uint32_t)k) == 0) { back = k; break; }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }

    const uint32_t start = back ? (addr - (uint32_t)back + 1u) : addr;
    int n = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)start;
        for (; n < 511; ++n)
        {
            const unsigned char c = p[n];
            if (!c) break;
            buf[n] = c;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }

    if (n <= 0 || n >= 511) return 0;
    if (!DdhUprobeHas(buf, n, enc ? kDdhUprobeAntonGbk : kDdhUprobeAntonUtf8,
                      enc ? 4 : 6)) return 0;
    return enc ? DdhUprobeGbk(buf, n) : DdhUprobeUtf8(buf, n);
}

/* 扫一个区域；文本命中（text=yes）单独收集，原始字节命中也留（text=no）�?
   文本命中�?8 处就停；原始命中只收�?8 个�?*/
static int DdhUprobeScanRegion(uint32_t base, uint32_t size, DWORD protect, DWORD deadline,
                               DdhUprobeHit* textHits, int* textCount, int textCap,
                               DdhUprobeHit* rawHits, int* rawCount, int rawCap)
{
    if (!size || !textHits || !textCount || !rawHits || !rawCount) return 0;
    int fault = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)base;
        uint32_t i = 0;
        while (i + 4u <= size)
        {
            if (*textCount >= textCap) break;
            if ((i & 0xFFFFFu) == 0 && (int32_t)(GetTickCount() - deadline) >= 0) break;

            const unsigned char* e5 = (const unsigned char*)memchr(p + i, 0xE5, (size_t)(size - i));
            const unsigned char* b0 = (const unsigned char*)memchr(p + i, 0xB0, (size_t)(size - i));
            const uint32_t o5 = e5 ? (uint32_t)(e5 - p) : 0xFFFFFFFFu;
            const uint32_t o0 = b0 ? (uint32_t)(b0 - p) : 0xFFFFFFFFu;
            if (o5 == 0xFFFFFFFFu && o0 == 0xFFFFFFFFu) break;

            uint32_t off;
            int enc;
            if (o5 <= o0) { off = o5; enc = 0; }
            else          { off = o0; enc = 1; }

            int matched = 0;
            if (enc == 0 && off + 6u <= size && memcmp(p + off, kDdhUprobeAntonUtf8, 6) == 0)
            {
                matched = 1;
                i = off + 6u;
            }
            else if (enc == 1 && off + 4u <= size && memcmp(p + off, kDdhUprobeAntonGbk, 4) == 0)
            {
                matched = 1;
                i = off + 4u;
            }
            else
            {
                i = off + 1u;
            }

            if (!matched) continue;

            DdhUprobeHit h;
            h.addr       = base + off;
            h.region     = base;
            h.regionSize = size;
            h.protect    = protect;
            h.enc        = enc;
            h.textOk     = DdhUprobeHitTextOk(h.addr, enc);

            if (h.textOk)
            {
                if (*textCount < textCap) textHits[(*textCount)++] = h;
            }
            else if (*rawCount < rawCap)
            {
                rawHits[(*rawCount)++] = h;
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        fault = 1;
    }
    return fault;
}

static void DdhUprobePrintHit(const DdhUprobeHit* h)
{
    if (!h) return;

    char ctx[640];
    ctx[0] = 0;
    for (int k = 0; k < 16; ++k)
    {
        int32_t delta;
        char label[8];
        if (k < 8)
        {
            delta = -(int32_t)(8 - k) * 4;            /* -0x20 .. -0x04 */
            DdhSprintf(label, sizeof(label), "-%02X", (unsigned)(-delta));
        }
        else
        {
            delta = (int32_t)(k - 8) * 4;             /* +0x00 .. +0x1C */
            DdhSprintf(label, sizeof(label), "+%02X", (unsigned)delta);
        }
        const uint32_t at = (uint32_t)((int64_t)h->addr + (int64_t)delta);
        uint32_t v = 0;
        char tmp[32];
        if (DdhUdataPoke(at, &v))
            DdhSprintf(tmp, sizeof(tmp), " %s=%08X", label, v);
        else
            DdhSprintf(tmp, sizeof(tmp), " %s=????????", label);
        strncat_s(ctx, sizeof(ctx), tmp, _TRUNCATE);
    }
    DdhUprobeLine("STRSCAN @0x%08X ctx:%s  [%s] text=%s region=0x%08X+0x%X prot=0x%X",
                  h->addr, ctx, h->enc ? "GBK" : "UTF-8", h->textOk ? "yes" : "no",
                  h->region, h->regionSize, h->protect);

    char s[129] = { 0 };
    const int sn = DdhUprobeReadCString(h->addr, s, sizeof(s));
    if (sn > 0)
    {
        const int kind = DdhUprobeTextKind((const unsigned char*)s, sn);
        if (kind)
        {
            char esc[320] = { 0 };
            DdhUprobeEscape(esc, sizeof(esc), s, (size_t)sn);
            DdhUprobeLine("STRSCAN 文本 @0x%08X: \"%s\" [%s]", h->addr, esc,
                          kind == 1 ? "ASCII" : (kind == 2 ? "UTF-8" : "GBK"));
        }
    }
}

static void DdhUprobeScan(void)
{
    DdhUprobeHit textHits[DDH_UPROBE_MAX_HITS];
    DdhUprobeHit rawHits[DDH_UPROBE_MAX_HITS];
    memset(textHits, 0, sizeof(textHits));
    memset(rawHits, 0, sizeof(rawHits));
    int textCount = 0, rawCount = 0, regions = 0, faults = 0, timedOut = 0, budgetStop = 0;
    uint64_t scanned = 0;
    const DWORD started  = GetTickCount();
    const DWORD deadline = started + DDH_UPROBE_SCAN_TIMEOUT_MS;

    DdhUprobeLine("STRSCAN 开始：找 ANTON UTF-8=E5 AE 89 E4 B8 9C / GBK=B0 B2 B6 AB；上限 %d 处 / %u MB / %u ms（NUL 结尾文本优先）",

                  DDH_UPROBE_MAX_HITS,
                  (unsigned)(DDH_UPROBE_SCAN_MAX_BYTES / (1024u * 1024u)),
                  (unsigned)DDH_UPROBE_SCAN_TIMEOUT_MS);

    uint32_t addr = 0x10000u;
    while (addr < 0x7FFFFFFFu && textCount < DDH_UPROBE_MAX_HITS)
    {
        if ((int32_t)(GetTickCount() - deadline) >= 0) { timedOut = 1; break; }
        if (scanned >= (uint64_t)DDH_UPROBE_SCAN_MAX_BYTES) { budgetStop = 1; break; }

        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)(uintptr_t)addr, &mbi, sizeof(mbi)) != sizeof(mbi)) break;

        const uint32_t base  = (uint32_t)(uintptr_t)mbi.BaseAddress;
        const uint32_t rsize = (uint32_t)mbi.RegionSize;
        if (!base || !rsize) { addr += 0x1000u; continue; }

        const uint64_t next64 = (uint64_t)base + (uint64_t)rsize;
        uint32_t next = (next64 > 0x7FFFFFFFu) ? 0x7FFFFFFFu : (uint32_t)next64;
        if (next <= addr) next = addr + 0x1000u;

        if (mbi.State == MEM_COMMIT && mbi.Type != MEM_IMAGE &&
            DdhUprobeProtReadable(mbi.Protect))
        {
            const uint64_t remain = (uint64_t)DDH_UPROBE_SCAN_MAX_BYTES - scanned;
            uint32_t chunk = rsize;
            if ((uint64_t)chunk > remain)
            {
                chunk = (uint32_t)remain;
                budgetStop = 1;
            }
            if (DdhUprobeScanRegion(base, chunk, mbi.Protect, deadline,
                                    textHits, &textCount, DDH_UPROBE_MAX_HITS,
                                    rawHits, &rawCount, DDH_UPROBE_MAX_HITS))
            {
                ++faults;
                DdhUprobeLine("STRSCAN 读异常 @0x%08X+0x%X prot=0x%X（该区域跳过）",
                              base, chunk, mbi.Protect);
            }
            scanned += chunk;
            ++regions;
        }
        addr = next;
    }

    int shown = 0;
    for (int i = 0; i < textCount && shown < DDH_UPROBE_MAX_HITS; ++i, ++shown)
        DdhUprobePrintHit(&textHits[i]);
    for (int i = 0; i < rawCount && shown < DDH_UPROBE_MAX_HITS; ++i, ++shown)
        DdhUprobePrintHit(&rawHits[i]);

    DdhUprobeLine("STRSCAN 完成：区�?%d 扫描=%.1f MB 文本命中=%d 原始命中=%d 打印=%d "
                  "读异�?%d 用时=%lu ms%s%s",
                  regions, (double)scanned / (1024.0 * 1024.0), textCount, rawCount, shown,
                  faults, (unsigned long)(GetTickCount() - started),
                  timedOut ? "（超时停止）" : "", budgetStop ? "（到 512MB 预算停止）" : "");
}

/* 入口：只在第一次属性请求里跑一次；没单位就等下一轮（最�?20 轮）�?*/
static void DdhUprobeEntry(void)
{
    if (!g_ddhUprobeOn) return;
    if (g_ddhUprobeDone) return;
    if (!g_shm) return;

    uint32_t obj = 0;
    for (int i = 0; i < DDH_ATTR_MAX; ++i)
        if (g_shm->attrs.unitAddr[i]) { obj = g_shm->attrs.unitAddr[i]; break; }
    if (!obj)
    {
        const LONG n = InterlockedIncrement(&g_ddhUprobeTries);
        if (n == 1 || n == 20)
            LogLine("UPROBE：第 %d 次属性请求没有单位%s", (int)n,
                    n == 20 ? "，放弃（不再等）" : "，等下一轮再试");
        if (n >= 20) InterlockedExchange(&g_ddhUprobeDone, 1);
        return;
    }
    if (InterlockedCompareExchange(&g_ddhUprobeDone, 1, 0) != 0) return;

    char path[MAX_PATH] = { 0 };
    DdhUprobePath(path, sizeof(path));
    fopen_s(&g_ddhUprobeFp, path, "wb");
    if (!g_ddhUprobeFp)
        LogLine("UPROBE：警告，dump 文件打不开：%s", path[0] ? path : "(空路径)");

    const uint32_t code = SafeCode(obj);
    char type[5] = { 0 };
    DdhAttrTypeCode(code, type);
    char name[64] = { 0 };
    ResolveName(obj, code, name, sizeof(name));
    const uint32_t prop = DdhUnitProp(obj);

    DdhUprobeLine("# ddh uprobe pid=%lu obj=0x%08X code=0x%08X",
                  (unsigned long)GetCurrentProcessId(), obj, code);

    /* 先扫字符串再 dump：prop/data 里打印出来的“安东”会留在本进程的
       日志/stdio 缓冲里，放到后面扫会把自己刚写的日志当成命中�?*/
    DdhUprobeScan();

    DdhUprobeLine("UNIT addr=0x%08X typeCode=%s code=0x%08X name=\"%s\" prop=0x%08X",
                  obj, type, code, name, prop);

    DdhUprobeDumpProp(prop);

    const uint32_t fn = DdhUprobeFindGetUnitData();
    if (!fn)
    {
        DdhUprobeLine("DATA 跳过：GetUnitData 未定位（prop 与字符串扫描继续）");
    }
    else
    {
        typedef uintptr_t (__fastcall* DdhUprobeUdataCall)(uint32_t);
        uintptr_t data = 0;
        DWORD exc = 0;
        __try { data = ((DdhUprobeUdataCall)(uintptr_t)fn)(code); }
        __except (EXCEPTION_EXECUTE_HANDLER) { exc = GetExceptionCode(); data = 0; }
        if (exc || !data)
        {
            DdhUprobeLine("DATA 跳过：GetUnitData(code=0x%08X type=%s) 返回=0x%08X 异常=%08X",
                          code, type, (unsigned)(uintptr_t)data, (unsigned)exc);
        }
        else
        {
            DdhUprobeLine("DATA base=0x%08X（GetUnitData），范围 +0x000..+0x300",
                          (unsigned)(uintptr_t)data);
            DdhUprobeDumpDwords("DATA", (uint32_t)(uintptr_t)data, 1);
        }
    }

    if (g_ddhUprobeFp) { fflush(g_ddhUprobeFp); fclose(g_ddhUprobeFp); g_ddhUprobeFp = NULL; }
    LogLine("UPROBE：完成，文件=%s", path[0] ? path : "(未写)");
}

/* ===========================================================================
   v17：SEEDPROBE —�?用单位名字符串在内存里反查“单位类型数据块�?
   ---------------------------------------------------------------------------
   为什么做（真�?ddh-6076.log）：
     · 攻击范围/攻击�?间隔/护甲/移�?三维/附加值都对，但白�?夜晚视野仍是 ?�?
       英雄称谓为空�?
     · DzAPI_UnitType_GetUnitTypeDataInt/String 已定位，4 种实参组合却全部返回
       0/�?—�?这个平台在无签名地图里就是空实现，不能再靠它�?
     · 单位名字节（UTF-8，如 野王 = E9 87 8E E7 8E 8B）在内存里是真的�?
   所以不猜偏移，用已知字符串当种子：
     �?在进程内存里搜名字原字节 �?字符串地址 S（最�?4 个；要求命中点是一�?
        NUL 结尾、整串等于名字的合法 UTF-8 文本，避免随机字节巧合）�?
     �?再搜“哪�?dword == S�?�?持有�?H（最�?8 个）�?
     �?对每�?H dump H-0x200..H+0x200，每 4 字节一行：dword / int / float�?
        �?dword 像指针时再当 char* 读最�?96 字节，合法文本就�?str="..." + hex�?
     �?�?H-0x400..H+0x400 里按 float 匹配视野常见�?
        {1500,1100,1400,900,1800,800,1200,1600}（误�?0.5）；
     �?一个持有者都没有时（名字可能以内�?char[] 放在块里，没有指针）�?
        退化为 dump S 本身（SELFDUMP）—�?内嵌布局也能看到周围字段�?
   触发：现有属性请求通道里第一次遇到“英�?+ 名字非空”的单位，整个进程只做一次；
         判据�?ATTR 的英雄位同源（GetUnitTypeId+IsHeroUnitId �?GetHeroStr 成功
         �?DDH_AF_HEROKNOWN|DDH_AF_HERO，且 DDH_AF_NAME 非空）�?
   输出：ddh-<pid>.seed.txt（UTF-8 文本，行内字符串保留原字�?+ hex；最�?2000 行）
         + ddh-<pid>.log 的摘要行�?
   扫描：只碰已提交、可读、非 guard 的区域；跳过本线程栈、共享内存、ddh.dll 自己�?
         先扫非映像区（真实堆），没找到再补扫映像区（假魔兽的静态字符串就在映像里）�?
   限额：种�?256MB / 2s；反向指�?512MB / 2.5s（含映像补扫）�?
   全程 __try，失败只写日志，不影响属性读取和伤害钩子�?
   =========================================================================== */

#define DDH_SEED_MAX_SEEDS          4
#define DDH_SEED_MAX_HOLDERS        8
#define DDH_SEED_SEED_BYTES   (256u * 1024u * 1024u)   /* 种子搜索总字节预�?*/
#define DDH_SEED_SEED_MS      2000u                    /* 种子搜索总时间预�?*/
#define DDH_SEED_PTR_BYTES    (512u * 1024u * 1024u)   /* 反向指针总字节预�?*/
#define DDH_SEED_PTR_MS       2500u                    /* 反向指针总时间预�?*/
#define DDH_SEED_IMG_BYTES    (128u * 1024u * 1024u)   /* 映像区补扫字节上�?*/
#define DDH_SEED_MAX_LINES    2000
#define DDH_SEED_STR_MAX      96                       /* dump 里字符串最多读 96 字节 */
#define DDH_SEED_DUMP_SPAN    0x200
#define DDH_SEED_FLOAT_SPAN   0x400

struct DdhSeedHit
{
    uint32_t addr;
    uint32_t region;
    uint32_t regionSize;
    uint32_t protect;
    int      image;
    int      textOk;
};

struct DdhSeedHolder
{
    uint32_t addr;
    int      seedIndex;
    int      score;
};

struct DdhSeedSkip
{
    uint32_t lo;
    uint32_t hi;
};

struct DdhSeedWalkStat
{
    uint64_t scanned;
    int      regions;
    int      faults;
    int      timedOut;
    int      budgetStop;
    int      stoppedEarly;
};

struct DdhSeedRunInfo
{
    int      seedHits;
    int      holderCount;
    int      dumped;
    int      floatHits;
    uint64_t seedScanned;
    uint64_t ptrScanned;
    DWORD    elapsed;
};

static volatile LONG  g_ddhSeedArmed   = 0;   /* 已发现英雄候选，等本轮请求处理完再跑 */
static volatile LONG  g_ddhSeedDone    = 0;   /* 本进程只跑一�?*/
static char           g_ddhSeedName[64] = { 0 };
static uint32_t       g_ddhSeedCode    = 0;
static uint32_t       g_ddhSeedUnit    = 0;
static uint32_t       g_ddhSeedShmAlloc = 0;
static FILE*          g_ddhSeedFp      = NULL;
static int            g_ddhSeedLines   = 0;
static int            g_ddhSeedTruncated = 0;
static int            g_ddhSeedFloatLogged = 0;
static char           g_ddhSeedPath[MAX_PATH] = { 0 };
static DdhSeedRunInfo g_ddhSeedInfo;

/* 本文件后面（v9 UTF-8/GBK 文本工具段）才定义；这里先声明�?*/
static bool DdhUtf8ToGbk(const char* src, char* dst, size_t cap);

static void DdhSeedPath(char* out, size_t cap)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    char dir[MAX_PATH] = { 0 };
    if (g_logPath[0]) strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) slash[1] = 0;
    else dir[0] = 0;
    DdhSprintf(out, cap, "%sddh-%lu.seed.txt", dir, (unsigned long)GetCurrentProcessId());
}

/* 文件每行 flush：真机中途崩了也能留下已�?dump 的部分�?
   �?2000 行时最后一行写 (截断)，之后一个字节都不写�?*/
static void DdhSeedLine(const char* fmt, ...)
{
    if (!g_ddhSeedFp || g_ddhSeedTruncated) return;
    if (g_ddhSeedLines >= DDH_SEED_MAX_LINES - 1)
    {
        g_ddhSeedTruncated = 1;
        fprintf(g_ddhSeedFp, "SEEDPROBE TRUNCATED (limit %d lines)\r\n", DDH_SEED_MAX_LINES);
        ++g_ddhSeedLines;
        fflush(g_ddhSeedFp);
        return;
    }
    char buf[1024];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(buf, sizeof(buf), _TRUNCATE, fmt, ap);
    va_end(ap);
    fprintf(g_ddhSeedFp, "%s\r\n", buf);
    ++g_ddhSeedLines;
    if ((g_ddhSeedLines & 15) == 0) fflush(g_ddhSeedFp);
}

static int DdhSeedRangeOverlap(uint32_t base, uint32_t size,
                               const DdhSeedSkip* skips, int n)
{
    const uint64_t lo = (uint64_t)base;
    const uint64_t hi = (uint64_t)base + (uint64_t)size;
    for (int i = 0; i < n; ++i)
    {
        const uint64_t slo = (uint64_t)skips[i].lo;
        const uint64_t shi = (uint64_t)skips[i].hi;
        if (lo < shi && slo < hi) return 1;
    }
    return 0;
}

/* 本线程栈 + 共享内存视图。栈里一定有名字的副本（nameUtf8/out->name 的中间拷贝）�?
   共享内存里也有属性块里的 out->name —�?不排除的话，种子会先命中我们自己的拷贝�?*/
static int DdhSeedCollectSkips(DdhSeedSkip* out, int cap)
{
    int n = 0;
    if (!out || cap <= 0) return 0;

    __try
    {
        const NT_TIB* tib = (const NT_TIB*)NtCurrentTeb();
        if (tib)
        {
            uint32_t sb = (uint32_t)(uintptr_t)tib->StackBase;
            uint32_t sl = (uint32_t)(uintptr_t)tib->StackLimit;
            if (sl >= 0x10000u && sb > sl && sb <= 0x7FFFFFFFu && n < cap)
            {
                out[n].lo = sl & ~0xFFFu;
                out[n].hi = (sb + 0xFFFu) & ~0xFFFu;
                if (out[n].hi <= out[n].lo) out[n].hi = out[n].lo + 0x1000u;
                ++n;
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }

    g_ddhSeedShmAlloc = 0;
    if (g_shm)
    {
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)g_shm, &mbi, sizeof(mbi)) == sizeof(mbi) && n < cap)
        {
            g_ddhSeedShmAlloc = (uint32_t)(uintptr_t)mbi.AllocationBase;
            out[n].lo = (uint32_t)(uintptr_t)mbi.BaseAddress;
            out[n].hi = out[n].lo + (uint32_t)mbi.RegionSize;
            if (out[n].hi > out[n].lo) ++n;
        }
    }
    return n;
}

typedef int (*DdhSeedRegionFn)(uint32_t base, uint32_t size, uint32_t protect, void* ctx);

/* 遍历地址空间：includeImages=0 只扫非映像区（真实堆），1 只扫映像区（静态字符串）�?
   fn 返回 1 = 提前结束�? = 本区域读异常（跳过继续）�?*/
static void DdhSeedWalk(int includeImages, uint64_t maxBytes, DWORD deadline,
                        DdhSeedRegionFn fn, void* ctx, DdhSeedWalkStat* st,
                        const DdhSeedSkip* skips, int nskips)
{
    if (!st) return;
    uint32_t addr = 0x10000u;
    while (addr < 0x7FFFFFFFu)
    {
        if ((int32_t)(GetTickCount() - deadline) >= 0) { st->timedOut = 1; break; }
        if (st->scanned >= maxBytes) { st->budgetStop = 1; break; }

        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)(uintptr_t)addr, &mbi, sizeof(mbi)) != sizeof(mbi)) break;

        const uint32_t base  = (uint32_t)(uintptr_t)mbi.BaseAddress;
        const uint32_t rsize = (uint32_t)mbi.RegionSize;
        if (!base || !rsize) { addr += 0x1000u; continue; }

        const uint64_t next64 = (uint64_t)base + (uint64_t)rsize;
        uint32_t next = (next64 > 0x7FFFFFFFu) ? 0x7FFFFFFFu : (uint32_t)next64;
        if (next <= addr) next = addr + 0x1000u;

        const int isImage = (mbi.Type == MEM_IMAGE) ? 1 : 0;
        int ok = (mbi.State == MEM_COMMIT) && DdhUprobeProtReadable(mbi.Protect) &&
                 (isImage == (includeImages ? 1 : 0));

        if (ok && g_self && (uint32_t)(uintptr_t)mbi.AllocationBase == (uint32_t)(uintptr_t)g_self)
            ok = 0;   /* ddh.dll 自己�?.data 里有 g_ddhSeedName 副本 */
        if (ok && g_ddhSeedShmAlloc &&
            (uint32_t)(uintptr_t)mbi.AllocationBase == g_ddhSeedShmAlloc)
            ok = 0;
        if (ok && skips && nskips > 0 && DdhSeedRangeOverlap(base, rsize, skips, nskips))
            ok = 0;

        if (ok)
        {
            uint32_t chunk = rsize;
            const uint64_t remain = maxBytes - st->scanned;
            if ((uint64_t)chunk > remain)
            {
                chunk = (uint32_t)remain;
                st->budgetStop = 1;
            }
            if (chunk)
            {
                const int rc = fn(base, chunk, mbi.Protect, ctx);
                if (rc == 2) ++st->faults;
                st->scanned += chunk;
                ++st->regions;
                if (rc == 1) { st->stoppedEarly = 1; break; }
                if (st->budgetStop && st->scanned >= maxBytes) break;
            }
        }
        addr = next;
    }
}

/* 命中点是不是一条“整串等于名字”的合法 UTF-8 C 字符串：
     · �?S �?96 字节内必须有 NUL（引擎名字最�?63 字节 + NUL）；
     · 长度必须等于种子长度（种子被截断�?63 字节时允许前缀匹配）；
     · 命中点必须在字符边界（前一字节不能�?0x80..0xBF 续字节）�?
   这条规则把日志缓冲里 name="野王" title=... 那种“名字在长串中间”的假命中刷掉�?*/
static int DdhSeedTextOk(uint32_t addr, const unsigned char* seed, int seedLen)
{
    if (addr < 0x10000u || !seed || seedLen <= 0) return 0;

    unsigned char buf[DDH_SEED_STR_MAX + 1];
    int n = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)addr;
        for (; n < DDH_SEED_STR_MAX; ++n)
        {
            const unsigned char c = p[n];
            if (!c) break;
            buf[n] = c;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }

    if (n < seedLen || n >= DDH_SEED_STR_MAX) return 0;
    if (memcmp(buf, seed, (size_t)seedLen) != 0) return 0;
    if (seedLen < 32 && n != seedLen) return 0;   /* 短名字必须整串相等；长名字允许被截断 */

    __try
    {
        const unsigned char prev = *(const unsigned char*)(uintptr_t)(addr - 1u);
        if ((prev & 0xC0u) == 0x80u) return 0;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }

    return DdhUprobeUtf8(buf, n) ? 1 : 0;
}

struct DdhSeedScanCtx
{
    const unsigned char* seed;
    int      seedLen;
    int      image;
    DdhSeedHit* hits;
    int*     count;
    int      cap;
    DWORD    deadline;
};

static int DdhSeedSeedRegionCb(uint32_t base, uint32_t size, uint32_t protect, void* vctx)
{
    DdhSeedScanCtx* c = (DdhSeedScanCtx*)vctx;
    if (!c || !c->seed || c->seedLen <= 0) return 1;
    int fault = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)base;
        uint32_t i = 0;
        while (i + (uint32_t)c->seedLen <= size)
        {
            if (*c->count >= c->cap) return 1;
            if ((i & 0xFFFFFu) == 0 && (int32_t)(GetTickCount() - c->deadline) >= 0) return 1;

            const unsigned char* q = (const unsigned char*)memchr(p + i, c->seed[0],
                                                                 (size_t)(size - i));
            if (!q) break;
            const uint32_t off = (uint32_t)(q - p);
            if (off + (uint32_t)c->seedLen > size) break;

            if (memcmp(p + off, c->seed, (size_t)c->seedLen) == 0)
            {
                const uint32_t at = base + off;
                if (DdhSeedTextOk(at, c->seed, c->seedLen))
                {
                    DdhSeedHit* h = &c->hits[*c->count];
                    h->addr = at;
                    h->region = base;
                    h->regionSize = size;
                    h->protect = protect;
                    h->image = c->image;
                    h->textOk = 1;
                    ++(*c->count);
                }
                i = off + (uint32_t)c->seedLen;
            }
            else
            {
                i = off + 1u;
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { fault = 1; }
    return fault ? 2 : 0;
}

struct DdhSeedPtrCtx
{
    const uint32_t* seeds;
    int      nseeds;
    DdhSeedHolder* holders;
    int*     count;
    int      cap;
    DWORD    deadline;
};

static int DdhSeedPtrRegionCb(uint32_t base, uint32_t size, uint32_t protect, void* vctx)
{
    (void)protect;
    DdhSeedPtrCtx* c = (DdhSeedPtrCtx*)vctx;
    if (!c || !c->seeds || c->nseeds <= 0) return 1;
    int fault = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)base;
        for (uint32_t off = 0; off + 4u <= size; off += 4u)
        {
            if ((off & 0xFFFFFu) == 0 && (int32_t)(GetTickCount() - c->deadline) >= 0) return 1;
            if (*c->count >= c->cap) return 1;

            uint32_t v = 0;
            memcpy(&v, p + off, 4);
            if (v < 0x10000u || v > 0x7FFFFFFFu) continue;

            int hit = -1;
            for (int k = 0; k < c->nseeds; ++k)
                if (v == c->seeds[k]) { hit = k; break; }
            if (hit < 0) continue;

            DdhSeedHolder* h = &c->holders[*c->count];
            h->addr = base + off;
            h->seedIndex = hit;
            h->score = 0;
            ++(*c->count);
            if (*c->count >= c->cap) return 1;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { fault = 1; }
    return fault ? 2 : 0;
}

/* 有的布局�?sight/nsight 存成 int（不�?float）：dump 里标 <SIGHT? int>�?
   不写独立�?FLOAT HIT 行（那个只认 float）�?*/
static int DdhSeedSightIntMatch(uint32_t v)
{
    return v == 1500u || v == 1100u || v == 1400u || v == 900u ||
           v == 1800u || v == 800u  || v == 1200u || v == 1600u;
}

/* 视野常见值（float）。误�?0.5�?*/
static int DdhSeedSightMatch(float f)
{
    static const float kSight[] =
    {
        1500.0f, 1100.0f, 1400.0f, 900.0f, 1800.0f, 800.0f, 1200.0f, 1600.0f
    };
    for (int i = 0; i < (int)(sizeof(kSight) / sizeof(kSight[0])); ++i)
    {
        double d = (double)f - (double)kSight[i];
        if (d < 0.0) d = -d;
        if (d <= 0.5) return 1;
    }
    return 0;
}

/* 持有者评分：附近“指向合法文本的指针”越多越像类型数据块；再给视野浮点加权�?
   只用来决�?dump 顺序�?000 行装不下 8 个持有者时，先 dump 最像的）�?*/
static int DdhSeedHolderScore(uint32_t H)
{
    int score = 0;
    for (int32_t off = -0x100; off <= 0x100; off += 4)
    {
        uint32_t v = 0;
        if (!DdhUdataPoke((uint32_t)((int64_t)H + off), &v)) continue;

        float f = 0.0f;
        memcpy(&f, &v, 4);
        if (DdhSeedSightMatch(f) || DdhSeedSightIntMatch(v)) score += 3;

        if (v >= 0x10000u && v <= 0x7FFFFFFFu)
        {
            char s[DDH_SEED_STR_MAX + 1];
            s[0] = 0;
            const int sn = DdhUprobeReadCString(v, s, sizeof(s));
            if (sn > 0 && sn < DDH_SEED_STR_MAX && s[0] &&
                DdhUprobeTextKind((const unsigned char*)s, sn))
                ++score;
        }
    }
    return score;
}

/* 视野浮点扫描：H-0x400 .. H+0x400，命中写文件；日志里最多留 12 条（防刷屏）�?*/
static int DdhSeedFloatScan(uint32_t H, int holderIndex)
{
    int hits = 0;
    for (int32_t off = -DDH_SEED_FLOAT_SPAN; off <= DDH_SEED_FLOAT_SPAN; off += 4)
    {
        uint32_t v = 0;
        if (!DdhUdataPoke((uint32_t)((int64_t)H + off), &v)) continue;
        float f = 0.0f;
        memcpy(&f, &v, 4);
        if (!DdhSeedSightMatch(f)) continue;

        DdhSeedLine("SEEDPROBE FLOAT HIT H%+d = %.2f (sight?) holder=%d",
                    off, (double)f, holderIndex);
        if (g_ddhSeedFloatLogged < 12)
        {
            ++g_ddhSeedFloatLogged;
            LogLine("SEEDPROBE FLOAT HIT H%+d = %.2f（疑似视野）holder=%d base=0x%08X",
                    off, (double)f, holderIndex, H);
        }
        ++hits;
    }
    return hits;
}

/* dump 字符串转义：UTF-8/ASCII 原样保留可打印字节（中文可读），控制字符�?'?'�?
   被判�?GBK 的多半是“指针恰好指到二进制”的巧合，非 ASCII 字节一律写�?\xNN�?
   这样文件仍是合法 UTF-8，噪声行也不会出现一堆替换符�?*/
static void DdhSeedEscapeStr(const char* src, int n, int kind, char* out, size_t cap)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    if (!src || n <= 0) return;
    static const char hexc[] = "0123456789ABCDEF";
    size_t pos = 0;
    for (int i = 0; i < n && src[i]; ++i)
    {
        const unsigned char c = (unsigned char)src[i];
        if (kind == 3 && c >= 0x80)
        {
            if (pos + 5 >= cap) break;
            out[pos++] = '\\'; out[pos++] = 'x';
            out[pos++] = hexc[c >> 4]; out[pos++] = hexc[c & 15];
        }
        else if (c == '"' || c == '\\')
        {
            if (pos + 2 >= cap) break;
            out[pos++] = '\\'; out[pos++] = (char)c;
        }
        else if (c >= 0x20 && c != 0x7F)
        {
            if (pos + 1 >= cap) break;
            out[pos++] = (char)c;
        }
        else
        {
            if (pos + 1 >= cap) break;
            out[pos++] = '?';
        }
    }
    out[pos] = 0;
}

/* dump 里的 float 显示：普通�?4 位小数；极大/极小的位模式用科学计数，
   避免 5.3e41 这种“指针当 float”的值写�?50 多位数字把行撑爆�?*/
static void DdhSeedFloatText(float f, char* out, size_t cap)
{
    if (!out || cap == 0) return;
    const double a = (f < 0.0f) ? -(double)f : (double)f;
    if (f == 0.0f) _snprintf_s(out, cap, _TRUNCATE, "0.0000");
    else if (a >= 1.0e7 || a < 1.0e-4) _snprintf_s(out, cap, _TRUNCATE, "%.3e", (double)f);
    else _snprintf_s(out, cap, _TRUNCATE, "%.4f", (double)f);
}

/* H-0x200 .. H+0x200 �?dword dump�?
     dword=XXXXXXXX int=... float=...  [str="..." hex=...]  [<<< NAME seed=n] */
static void DdhSeedDump(uint32_t H, int holderIndex, const uint32_t* seeds, int nseeds)
{
    DdhSeedLine("SEEDPROBE DUMP H-0x200..H+0x200 holder=%d base=0x%08X", holderIndex, H);
    for (int32_t off = -DDH_SEED_DUMP_SPAN; off <= DDH_SEED_DUMP_SPAN; off += 4)
    {
        const uint32_t at = (uint32_t)((int64_t)H + off);
        uint32_t v = 0;
        if (!DdhUdataPoke(at, &v))
        {
            DdhSeedLine("H%+d <unreadable>", off);
            continue;
        }

        float f = 0.0f;
        memcpy(&f, &v, 4);

        char extra[800];
        extra[0] = 0;

        int seedHit = -1;
        for (int k = 0; k < nseeds; ++k)
            if (v == seeds[k]) { seedHit = k; break; }

        if (seedHit >= 0)
        {
            _snprintf_s(extra, sizeof(extra), _TRUNCATE, "  <<< NAME seed=%d", seedHit);
        }
        else if (v >= 0x10000u && v <= 0x7FFFFFFFu)
        {
            char s[DDH_SEED_STR_MAX + 1];
            s[0] = 0;
            const int sn = DdhUprobeReadCString(v, s, sizeof(s));
            if (sn > 0 && sn < DDH_SEED_STR_MAX && s[0])
            {
                const int kind = DdhUprobeTextKind((const unsigned char*)s, sn);
                if (kind)
                {
                    char esc[560];
                    DdhSeedEscapeStr(s, sn, kind, esc, sizeof(esc));
                    char hex[64];
                    FormatHex((const unsigned char*)s, sn < 16 ? sn : 16, hex, sizeof(hex));
                    _snprintf_s(extra, sizeof(extra), _TRUNCATE,
                                "  str=\"%s\" hex=%s [%s]", esc, hex,
                                kind == 1 ? "ASCII" : (kind == 2 ? "UTF-8" : "GBK"));
                }
            }
        }

        char sightTag[48];
        sightTag[0] = 0;
        if (DdhSeedSightMatch(f))
            _snprintf_s(sightTag, sizeof(sightTag), _TRUNCATE, "  <SIGHT? float>");
        else if (DdhSeedSightIntMatch(v))
            _snprintf_s(sightTag, sizeof(sightTag), _TRUNCATE, "  <SIGHT? int>");

        char fbuf[40];
        DdhSeedFloatText(f, fbuf, sizeof(fbuf));

        DdhSeedLine("H%+d dword=%08X int=%d float=%s%s%s",
                    off, v, (int)v, fbuf, extra, sightTag);
    }
}

/* 触发候选：ATTR 已判定“是英雄”（GetUnitTypeId+IsHeroUnitId 或三�?> 0�?
   �?DDH_AF_HERO 同源），且名字非空（种子必须有字节）�?*/
static int DdhSeedIsHeroCandidate(const DdhUnitAttr* a)
{
    if (!a) return 0;
    if (a->addr < 0x10000u || a->addr > 0x7FFFFFFFu) return 0;
    if ((a->flags & DDH_AF_HEROKNOWN) == 0) return 0;
    if ((a->flags & DDH_AF_HERO) == 0) return 0;
    if ((a->flags & DDH_AF_NAME) == 0) return 0;
    if (a->name[0] == 0) return 0;
    return 1;
}

/* 在属性请求循环里调用：只做“记住候选”，真正扫描放到本轮 doneSeq 写回之后�?
   这样 C# 先拿到这一轮属性，不会因为扫描卡住而超时�?*/
static void DdhSeedProbeNote(uint32_t obj, const DdhUnitAttr* a)
{
    if (g_ddhSeedArmed) return;
    if (!DdhSeedIsHeroCandidate(a)) return;
    if (InterlockedCompareExchange(&g_ddhSeedArmed, 1, 0) != 0) return;

    g_ddhSeedUnit = obj;
    g_ddhSeedCode = SafeCode(obj);
    DdhUtf8SafeCopy(g_ddhSeedName, sizeof(g_ddhSeedName), a->name, sizeof(g_ddhSeedName) - 1);
    LogLine("SEEDPROBE：已锁定第一个英雄候选 addr=0x%08X code=0x%08X（本轮属性写回后开始扫描）",
            obj, g_ddhSeedCode);
}

static void DdhSeedProbeRunInner(DWORD started)
{
    char nameUtf8[64] = { 0 };
    DdhUtf8SafeCopy(nameUtf8, sizeof(nameUtf8), g_ddhSeedName, sizeof(nameUtf8) - 1);
    const int nameLen = (int)strlen(nameUtf8);

    char type[5] = { 0 };
    DdhAttrTypeCode(g_ddhSeedCode, type);

    char nameHex[256] = { 0 };
    FormatHex((const unsigned char*)nameUtf8, nameLen, nameHex, sizeof(nameHex));

    LogLine("SEEDPROBE：开始（单位 code=%s name=\"%s\"）addr=0x%08X 名字=%d 字节 hex=%s",
            type, nameUtf8, g_ddhSeedUnit, nameLen, nameHex);
    if (nameLen <= 0)
    {
        LogLine("SEEDPROBE：名字为空，没有种子，本次不扫");
        return;
    }

    DdhSeedPath(g_ddhSeedPath, sizeof(g_ddhSeedPath));
    if (fopen_s(&g_ddhSeedFp, g_ddhSeedPath, "wb") != 0 || !g_ddhSeedFp)
    {
        g_ddhSeedFp = NULL;
        LogLine("SEEDPROBE：警告，文件打不开：%s", g_ddhSeedPath[0] ? g_ddhSeedPath : "(空路径)");
        return;
    }

    /* 打开文件后先只写不含名字原字节的 ASCII 头：文件�?CRT 缓冲也在堆上�?
       如果�?"野王" 写进去再扫，就会先命中自己的文件缓冲�?*/
    DdhSeedLine("# ddh SEEDPROBE pid=%lu started_ms=%lu", (unsigned long)GetCurrentProcessId(),
                (unsigned long)started);
    DdhSeedLine("# unit=0x%08X code=%s name_len=%d name_hex=%s",
                g_ddhSeedUnit, type, nameLen, nameHex);
    DdhSeedLine("# tags: NAME=pointer to seed string; str/hex=dword read as C string (<=96B,"
                " GBK-ish bytes escaped as \\xNN); SIGHT?=float near 1500/1100/1400/900/1800/800/1200/1600");

    DdhSeedSkip skips[4];
    const int nskips = DdhSeedCollectSkips(skips, 4);
    LogLine("SEEDPROBE：排除区 %d 个（本线程栈 + 共享内存），名字种子=%d 字节",
            nskips, nameLen);

    DdhSeedHit hits[DDH_SEED_MAX_SEEDS];
    memset(hits, 0, sizeof(hits));
    int hitCount = 0;
    DdhSeedScanCtx sctx;
    memset(&sctx, 0, sizeof(sctx));
    sctx.seed = (const unsigned char*)nameUtf8;
    sctx.seedLen = nameLen;
    sctx.hits = hits;
    sctx.count = &hitCount;
    sctx.cap = DDH_SEED_MAX_SEEDS;

    const DWORD seedDeadline = started + DDH_SEED_SEED_MS;
    sctx.deadline = seedDeadline;
    sctx.image = 0;

    DdhSeedWalkStat stSeed;
    memset(&stSeed, 0, sizeof(stSeed));
    DdhSeedWalk(0, DDH_SEED_SEED_BYTES, seedDeadline, DdhSeedSeedRegionCb, &sctx, &stSeed,
                skips, nskips);

    if (hitCount == 0 && !stSeed.timedOut && !stSeed.budgetStop &&
        stSeed.scanned < (uint64_t)DDH_SEED_SEED_BYTES)
    {
        DdhSeedWalkStat stImg;
        memset(&stImg, 0, sizeof(stImg));
        sctx.image = 1;
        DdhSeedWalk(1, (uint64_t)DDH_SEED_SEED_BYTES - stSeed.scanned, seedDeadline,
                    DdhSeedSeedRegionCb, &sctx, &stImg, skips, nskips);
        stSeed.scanned += stImg.scanned;
        stSeed.regions += stImg.regions;
        stSeed.faults  += stImg.faults;
        stSeed.timedOut |= stImg.timedOut;
        stSeed.budgetStop |= stImg.budgetStop;
    }
    g_ddhSeedInfo.seedHits = hitCount;
    g_ddhSeedInfo.seedScanned = stSeed.scanned;

    LogLine("SEEDPROBE：名字种子扫描 完成：命中=%d 区域=%d 扫描=%.1f MB 读异常=%d 用时=%lu ms%s%s",
            hitCount, stSeed.regions, (double)stSeed.scanned / (1024.0 * 1024.0),
            stSeed.faults, (unsigned long)(GetTickCount() - started),
            stSeed.timedOut ? "（超时停止）" : "", stSeed.budgetStop ? "（到 256MB 预算停止）" : "");

    /* 扫描完成后再把名字原字节写进文件（此时不会再扫到它）�?*/
    char nameEsc[420] = { 0 };
    DdhUprobeEscape(nameEsc, sizeof(nameEsc), nameUtf8, (size_t)nameLen);
    DdhSeedLine("SEEDPROBE START unit=0x%08X code=%s name_len=%d", g_ddhSeedUnit, type, nameLen);
    DdhSeedLine("SEEDPROBE NAME text=\"%s\" hex=%s", nameEsc, nameHex);

    for (int i = 0; i < hitCount; ++i)
    {
        DdhSeedLine("SEEDPROBE SEED[%d] addr=0x%08X region=0x%08X+0x%X prot=0x%X (%s)",
                    i, hits[i].addr, hits[i].region, hits[i].regionSize, hits[i].protect,
                    hits[i].image ? "image" : "heap");
        LogLine("SEEDPROBE：S[%d]=0x%08X（%s 区 0x%08X+0x%X prot=0x%X）",
                i, hits[i].addr, hits[i].image ? "映像" : "堆",
                hits[i].region, hits[i].regionSize, hits[i].protect);
    }

    if (hitCount <= 0)
    {
        DdhSeedLine("SEEDPROBE RESULT seeds=0 (name bytes not found)");
        LogLine("SEEDPROBE：内存里没找到名字原字节（%d 字节）——没有 S，无法反查持有者；"
                "文件只留头（可用 DDH_UPROBE=1 的全量 STRSCAN 交叉核对）", nameLen);
        return;
    }

    uint32_t seeds[DDH_SEED_MAX_SEEDS];
    memset(seeds, 0, sizeof(seeds));
    for (int i = 0; i < hitCount; ++i) seeds[i] = hits[i].addr;

    /* �?反向指针：一次扫完整地址空间，同时匹配所�?S（不�?S 各扫一遍）�?*/
    DdhSeedHolder holders[DDH_SEED_MAX_HOLDERS];
    memset(holders, 0, sizeof(holders));
    int holderCount = 0;

    DdhSeedPtrCtx pctx;
    memset(&pctx, 0, sizeof(pctx));
    pctx.seeds = seeds;
    pctx.nseeds = hitCount;
    pctx.holders = holders;
    pctx.count = &holderCount;
    pctx.cap = DDH_SEED_MAX_HOLDERS;

    const DWORD ptrDeadline = GetTickCount() + DDH_SEED_PTR_MS;
    pctx.deadline = ptrDeadline;

    DdhSeedWalkStat stPtr;
    memset(&stPtr, 0, sizeof(stPtr));
    DdhSeedWalk(0, DDH_SEED_PTR_BYTES, ptrDeadline, DdhSeedPtrRegionCb, &pctx, &stPtr,
                skips, nskips);

    if (holderCount == 0 && !stPtr.timedOut && !stPtr.budgetStop)
    {
        DdhSeedWalkStat stPtrImg;
        memset(&stPtrImg, 0, sizeof(stPtrImg));
        DdhSeedWalk(1, DDH_SEED_IMG_BYTES, ptrDeadline, DdhSeedPtrRegionCb, &pctx, &stPtrImg,
                    skips, nskips);
        stPtr.scanned += stPtrImg.scanned;
        stPtr.regions += stPtrImg.regions;
        stPtr.faults  += stPtrImg.faults;
        stPtr.timedOut |= stPtrImg.timedOut;
        stPtr.budgetStop |= stPtrImg.budgetStop;
    }
    g_ddhSeedInfo.holderCount = holderCount;
    g_ddhSeedInfo.ptrScanned = stPtr.scanned;

    LogLine("SEEDPROBE：反向指针 完成：持有者=%d 区域=%d 扫描=%.1f MB 读异常=%d 用时=%lu ms%s%s",
            holderCount, stPtr.regions, (double)stPtr.scanned / (1024.0 * 1024.0),
            stPtr.faults, (unsigned long)(GetTickCount() - started),
            stPtr.timedOut ? "（超时停止）" : "", stPtr.budgetStop ? "（到预算停止）" : "");

    if (holderCount <= 0)
    {
        LogLine("SEEDPROBE：没有 dword 指向种子地址（名字可能是内嵌 char[]）→ 改为 dump 种子自身");
        DdhSeedLine("SEEDPROBE HOLDER none -> SELFDUMP seed=0x%08X", seeds[0]);
        g_ddhSeedInfo.floatHits += DdhSeedFloatScan(seeds[0], -1);
        DdhSeedDump(seeds[0], -1, seeds, hitCount);
        ++g_ddhSeedInfo.dumped;
        DdhSeedLine("SEEDPROBE RESULT seeds=%d holders=0 dumped=1 float_hits=%d lines=%d%s",
                    hitCount, g_ddhSeedInfo.floatHits, g_ddhSeedLines,
                    g_ddhSeedTruncated ? " (truncated)" : "");
        return;
    }

    /* 评分只决�?dump 顺序�?000 行装不下 8 个持有者时�?dump 最像类型数据块的�?*/
    for (int i = 0; i < holderCount; ++i)
        holders[i].score = DdhSeedHolderScore(holders[i].addr);

    for (int i = 1; i < holderCount; ++i)
    {
        DdhSeedHolder key = holders[i];
        int j = i - 1;
        while (j >= 0 && holders[j].score < key.score)
        {
            holders[j + 1] = holders[j];
            --j;
        }
        holders[j + 1] = key;
    }

    for (int i = 0; i < holderCount; ++i)
    {
        DdhSeedLine("SEEDPROBE HOLDER[%d] addr=0x%08X seed=%d score=%d(%s)",
                    i, holders[i].addr, holders[i].seedIndex, holders[i].score,
                    holders[i].score > 0 ? "looks-like-type-data" : "no-nearby-strings");
        LogLine("SEEDPROBE：持有者[%d]=0x%08X 指向 S[%d]=0x%08X score=%d",
                i, holders[i].addr, holders[i].seedIndex, seeds[holders[i].seedIndex],
                holders[i].score);
    }

    for (int i = 0; i < holderCount; ++i)
    {
        if (g_ddhSeedTruncated) break;
        const uint32_t H = holders[i].addr;
        /* 先做视野浮点扫描�?dump：行数被截断时，视野命中一定已经写进文件�?*/
        g_ddhSeedInfo.floatHits += DdhSeedFloatScan(H, i);
        DdhSeedDump(H, i, seeds, hitCount);
        ++g_ddhSeedInfo.dumped;
    }

    DdhSeedLine("SEEDPROBE RESULT seeds=%d holders=%d dumped=%d float_hits=%d lines=%d%s",
                hitCount, holderCount, g_ddhSeedInfo.dumped, g_ddhSeedInfo.floatHits,
                g_ddhSeedLines, g_ddhSeedTruncated ? " (truncated)" : "");
}

/* 入口：属性请求处理完（doneSeq 已写回）后在游戏线程调用，整个进程只跑一次�?*/
static void DdhSeedProbeRun(void)
{
    const DWORD started = GetTickCount();
    memset(&g_ddhSeedInfo, 0, sizeof(g_ddhSeedInfo));
    BOOL exc = FALSE;

    __try
    {
        DdhSeedProbeRunInner(started);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        exc = TRUE;
        LogLine("SEEDPROBE：采集异常 code=0x%08X（已吞掉，不影响属性读取/伤害钩子）",
                (unsigned)GetExceptionCode());
    }

    if (g_ddhSeedFp)
    {
        fflush(g_ddhSeedFp);
        fclose(g_ddhSeedFp);
        g_ddhSeedFp = NULL;
    }

    g_ddhSeedInfo.elapsed = GetTickCount() - started;
    LogLine("SEEDPROBE：完成%s，文件=%s 行数=%d%s 种子=%d 持有者=%d dump=%d 浮点命中=%d 用时=%lu ms",
            exc ? "（有异常）" : "",
            g_ddhSeedPath[0] ? g_ddhSeedPath : "(未写)",
            g_ddhSeedLines, g_ddhSeedTruncated ? "（已截断）" : "",
            g_ddhSeedInfo.seedHits, g_ddhSeedInfo.holderCount, g_ddhSeedInfo.dumped,
            g_ddhSeedInfo.floatHits, (unsigned long)g_ddhSeedInfo.elapsed);
}

/* 每轮属性请求结束后调用：已锁定英雄候选就开跑（只一次）�?*/
static void DdhSeedProbeTick(void)
{
    if (!g_ddhSeedArmed) return;
    if (InterlockedCompareExchange(&g_ddhSeedDone, 1, 0) != 0) return;
    DdhSeedProbeRun();
}

/* ===========================================================================
   v18 诊断：DDH_UNITDUMP=1 —�?直接 dump 第一个英雄的 CUnit 自身
   ---------------------------------------------------------------------------
   上一�?SEEDPROBE 用名字字节在内存里反查“类型数据块”，真机结论是名字在大字符串池里�?
   没有任何 dword 指向种子地址（引擎用池内偏移/string id，不�?char*），那条路走不通�?
   CUnit 本来就在我们手里（属性请求的 addr），所以改成直�?dump unit+0x00..+0x400�?
     · �?4 字节一行：UNIT +0x%03X dword=%08X int=%d float=%.3f
     · float 命中 {1500,1100,1400,900,1800,800,1200,1600,650,550}（误�?0.5）标 <SIGHT?>
     · 每个像指针的 dword�?x10000..0x7FFFFFFF）尝试当 char* �?96 字节，可读文本就�?str="..."
       （UTF-8/GBK/ASCII 都试；文本内容原样输出，中文里可能就有英雄称谓）
   触发方式（一次进程只做一次；输出 ddh-<pid>.unit.txt，最�?1200 行；日志只写摘要）：
     · 默认 AUTO：第一个英雄的“称�?白天视野/夜晚视野”有缺失时自�?dump（正常图不写文件）；
     · 强制：DDH_UNITDUMP=1，或 ddh.dll 同目录放一�?ddh_unitdump.on 文件�?
     · 关闭：DDH_UNITDUMP=0�?
   =========================================================================== */
#define DDH_UNITDUMP_MAX_LINES 1200
#define DDH_UNITDUMP_SPAN      0x400
#define DDH_UNITDUMP_STR_MAX   96

static int           g_ddhUnitDumpMode      = 1;   /* 0=off 1=auto 2=force（DllMain 定型�?*/
static volatile LONG g_ddhUnitDumpArmed     = 0;
static volatile LONG g_ddhUnitDumpDone      = 0;
static uint32_t      g_ddhUnitDumpUnit      = 0;
static uint32_t      g_ddhUnitDumpCode      = 0;
static char          g_ddhUnitDumpName[64]  = { 0 };
static FILE*         g_ddhUnitDumpFp        = NULL;
static int           g_ddhUnitDumpLines     = 0;
static int           g_ddhUnitDumpTruncated = 0;
static int           g_ddhUnitDumpStrHits   = 0;
static int           g_ddhUnitDumpSightHits = 0;

/* 返回 0 = 明确关闭�? = 明确强制�?1 = 没设置（�?AUTO）�?*/
static int DdhUnitDumpEnvMode(void)
{
    char buf[32] = { 0 };
    const DWORD n = GetEnvironmentVariableA("DDH_UNITDUMP", buf, (DWORD)sizeof(buf));
    if (n == 0 || n >= (DWORD)sizeof(buf)) return -1;
    if (_stricmp(buf, "0") == 0 || _stricmp(buf, "false") == 0 ||
        _stricmp(buf, "no") == 0 || _stricmp(buf, "off") == 0) return 0;
    if (_stricmp(buf, "1") == 0 || _stricmp(buf, "true") == 0 ||
        _stricmp(buf, "yes") == 0 || _stricmp(buf, "on") == 0) return 2;
    return -1;
}

/* 文件开关：ddh.dll / ddh-<pid>.log 同目录下�?ddh_unitdump.on�?
   启动器不继承环境变量时，用户放一个空文件即可强制 dump�?*/
static int DdhUnitDumpFlagFile(void)
{
    char dir[MAX_PATH] = { 0 };
    if (g_logPath[0]) strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) slash[1] = 0;
    else dir[0] = 0;
    char path[MAX_PATH] = { 0 };
    DdhSprintf(path, sizeof(path), "%sddh_unitdump.on", dir);
    const DWORD attr = GetFileAttributesA(path);
    return attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

static void DdhUnitDumpPath(char* out, size_t cap)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    char dir[MAX_PATH] = { 0 };
    if (g_logPath[0]) strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) slash[1] = 0;
    else dir[0] = 0;
    DdhSprintf(out, cap, "%sddh-%lu.unit.txt", dir, (unsigned long)GetCurrentProcessId());
}

/* 只写 unit.txt（不逐行刷日志，日志最后只写摘要）。最�?1200 行�?*/
static void DdhUnitDumpLine(const char* fmt, ...)
{
    if (!g_ddhUnitDumpFp || g_ddhUnitDumpTruncated) return;
    if (g_ddhUnitDumpLines >= DDH_UNITDUMP_MAX_LINES - 1)
    {
        g_ddhUnitDumpTruncated = 1;
        fprintf(g_ddhUnitDumpFp, "UNITDUMP TRUNCATED (limit %d lines)\r\n", DDH_UNITDUMP_MAX_LINES);
        ++g_ddhUnitDumpLines;
        fflush(g_ddhUnitDumpFp);
        return;
    }
    char buf[2048];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(buf, sizeof(buf), _TRUNCATE, fmt, ap);
    va_end(ap);
    fprintf(g_ddhUnitDumpFp, "%s\r\n", buf);
    ++g_ddhUnitDumpLines;
    if ((g_ddhUnitDumpLines & 15) == 0) fflush(g_ddhUnitDumpFp);
}

static int DdhUnitDumpSightHit(float f)
{
    static const float kSight[] =
    {
        1500.0f, 1100.0f, 1400.0f, 900.0f, 1800.0f,
        800.0f, 1200.0f, 1600.0f, 650.0f, 550.0f
    };
    for (int i = 0; i < (int)(sizeof(kSight) / sizeof(kSight[0])); ++i)
    {
        double d = (double)f - (double)kSight[i];
        if (d < 0.0) d = -d;
        if (d <= 0.5) return 1;
    }
    return 0;
}

static void DdhUnitDumpNote(uint32_t obj, const DdhUnitAttr* a)
{
    if (g_ddhUnitDumpMode == 0) return;
    if (!a || !obj) return;
    if (g_ddhUnitDumpArmed) return;
    if (!DdhSeedIsHeroCandidate(a)) return;   /* 判据�?SEEDPROBE 完全一�?*/
    if (g_ddhUnitDumpMode == 1)
    {
        /* AUTO：只有称�?白天视野缺失�?dump —�?正常图一个文件都不写�?
           v14 夜晚视野（nsight）允许合法缺失（有些 slk 没有 nsight），不触发诊断�?*/
        const uint32_t need = DDH_AF_TITLE | DDH_AF_SIGHT_DAY;
        if ((a->flags & need) == need) return;
        g_ddhUdataForce = 1;   /* 同一次自动诊断里顺带 dump GetUnitData 单位数据�?*/
    }
    if (InterlockedCompareExchange(&g_ddhUnitDumpArmed, 1, 0) != 0) return;

    g_ddhUnitDumpUnit = obj;
    g_ddhUnitDumpCode = SafeCode(obj);
    DdhUtf8SafeCopy(g_ddhUnitDumpName, sizeof(g_ddhUnitDumpName),
                    a->name, sizeof(g_ddhUnitDumpName) - 1);

    char type[8] = { 0 };
    DdhAttrTypeCode(g_ddhUnitDumpCode, type);
    LogLine("UNITDUMP：已锁定第一个英雄 addr=0x%08X code=%s name=\"%s\"（%s，本轮属性写回后 dump unit+0x000..+0x%03X）",
            obj, type, g_ddhUnitDumpName,
            g_ddhUnitDumpMode == 1 ? "自动：称谓/视野缺失" : "强制开启",
            (unsigned)DDH_UNITDUMP_SPAN);
}

static int DdhUnitDumpSightInt(uint32_t v)
{
    switch (v)
    {
    case 1500u: case 1100u: case 1400u: case 900u: case 1800u:
    case 800u:  case 1200u: case 1600u: case 650u: case 550u:
        return 1;
    default:
        return 0;
    }
}

/* �?4 字节 dump 一段内存：UNIT / TYPE / PROP 共用�?*/
static void DdhUnitDumpBlock(const char* tag, uint32_t base, uint32_t span)
{
    for (uint32_t off = 0; off <= span; off += 4u)
    {
        uint32_t v = 0;
        if (!DdhUdataPoke(base + off, &v))
        {
            DdhUnitDumpLine("%s +0x%03X dword=-------- int=- float=nan  <读取失败>", tag, off);
            continue;
        }

        float f = 0.0f;
        memcpy(&f, &v, 4);
        const int sightHit = DdhUnitDumpSightHit(f) || DdhUnitDumpSightInt(v);
        if (sightHit) ++g_ddhUnitDumpSightHits;

        char extra[768];
        extra[0] = 0;
        if (v >= 0x10000u && v <= 0x7FFFFFFFu)
        {
            char str[DDH_UNITDUMP_STR_MAX + 1] = { 0 };
            const int sn = DdhUprobeReadCString(v, str, sizeof(str));
            if (sn > 0)
            {
                const int kind = DdhUprobeTextKind((const unsigned char*)str, sn);
                if (kind)
                {
                    char esc[512] = { 0 };
                    DdhUprobeEscape(esc, sizeof(esc), str, (size_t)sn);
                    const char* kindName = (kind == 1) ? "ASCII" : (kind == 2 ? "UTF-8" : "GBK");
                    const char* cut = (sn >= (int)sizeof(str) - 1) ? " (截断)" : "";
                    _snprintf_s(extra, sizeof(extra), _TRUNCATE,
                                "  str=\"%s\" [%s]%s", esc, kindName, cut);
                    ++g_ddhUnitDumpStrHits;
                }
            }
        }

        DdhUnitDumpLine("%s +0x%03X dword=%08X int=%d float=%.3f%s%s",
                        tag, off, v, (int)v, (double)f,
                        sightHit ? "  <SIGHT?>" : "", extra);
    }
}

static void DdhUnitDumpRun(void)
{
    const DWORD started = GetTickCount();
    char path[MAX_PATH] = { 0 };
    DdhUnitDumpPath(path, sizeof(path));
    if (fopen_s(&g_ddhUnitDumpFp, path, "wb") != 0 || !g_ddhUnitDumpFp)
    {
        g_ddhUnitDumpFp = NULL;
        LogLine("UNITDUMP：警告，文件打不开：%s（本次不 dump）");
        return;
    }

    char type[8] = { 0 };
    DdhAttrTypeCode(g_ddhUnitDumpCode, type);
    DdhUnitDumpLine("# ddh UNITDUMP pid=%lu started_ms=%lu", (unsigned long)GetCurrentProcessId(),
                    (unsigned long)started);
    DdhUnitDumpLine("# unit=0x%08X code=%s name=\"%s\"", g_ddhUnitDumpUnit, type, g_ddhUnitDumpName);
    DdhUnitDumpLine("# CUnit/TYPE/BALANCE/PROP 每 4 字节一行；<SIGHT?> = float 或 int 命中视野候选值；str=指针 dword 当 char* 读到的文本");

    DdhUnitDumpBlock("UNIT", g_ddhUnitDumpUnit, DDH_UNITDUMP_SPAN);

    /* CUnit+0x1F0：GetHeroProperName 内部就是 mov ecx,[ecx+1F0] 后取数据�?
       说明它是“单位类型数据”对象；Propernames/sight/nsight/spd/def 很可能都在这里�?*/
    uint32_t typePtr = 0;
    if (DdhUdataPoke(g_ddhUnitDumpUnit + 0x1F0u, &typePtr) &&
        typePtr >= 0x10000u && typePtr <= 0x7FFFFFFFu)
    {
        DdhUnitDumpLine("# TYPE base=0x%08X（*(unit+0x1F0)，单位类型数据）", typePtr);
        DdhUnitDumpBlock("TYPE", typePtr, DDH_UNITDUMP_SPAN);
    }
    else
    {
        DdhUnitDumpLine("# TYPE 跳过：*(unit+0x1F0)=0x%08X 不可读", typePtr);
    }

    /* CUnit+0x1EC：WFE 的详细防御提示（移�?+ 视野）就是从这块对象读的�?
       游戏 0x6F3B6FAD �?mov edi,[edi+1EC]，随后用 edi �?0x6F5DF1E0 取移速；
       sight/nsight 很可能也在这块里，优先看这里而不是只�?GetUnitData�?*/
    uint32_t balancePtr = 0;
    if (DdhUdataPoke(g_ddhUnitDumpUnit + 0x1ECu, &balancePtr) &&
        balancePtr >= 0x10000u && balancePtr <= 0x7FFFFFFFu)
    {
        DdhUnitDumpLine("# BALANCE base=0x%08X（*(unit+0x1EC)，WFE 防御提示的移速/视野对象）", balancePtr);
        DdhUnitDumpBlock("BALANCE", balancePtr, DDH_UNITDUMP_SPAN);
    }
    else
    {
        DdhUnitDumpLine("# BALANCE 跳过：*(unit+0x1EC)=0x%08X 不可读", balancePtr);
    }

    /* CUnit+0x1E8：unit_property（攻击范�?攻击�?护甲等内存直读源）�?*/
    uint32_t propPtr = 0;
    if (DdhUdataPoke(g_ddhUnitDumpUnit + 0x1E8u, &propPtr) &&
        propPtr >= 0x10000u && propPtr <= 0x7FFFFFFFu)
    {
        DdhUnitDumpLine("# PROP base=0x%08X（*(unit+0x1E8)，unit_property）", propPtr);
        DdhUnitDumpBlock("PROP", propPtr, 0x300u);
    }
    else
    {
        DdhUnitDumpLine("# PROP 跳过：*(unit+0x1E8)=0x%08X 不可读", propPtr);
    }

    if (g_ddhUnitDumpFp)
    {
        fflush(g_ddhUnitDumpFp);
        fclose(g_ddhUnitDumpFp);
        g_ddhUnitDumpFp = NULL;
    }
    LogLine("UNITDUMP：完成，文件=%s 行数=%d%s 指针文本=%d 视野命中=%d 用时=%lu ms",
            path[0] ? path : "(未写)", g_ddhUnitDumpLines,
            g_ddhUnitDumpTruncated ? "（已截断）" : "",
            g_ddhUnitDumpStrHits, g_ddhUnitDumpSightHits,
            (unsigned long)(GetTickCount() - started));

    /* 视图/称谓缺失触发的自动诊断：顺带 dump 一�?GetUnitData（UnitBalance 原始块）�?
       写到 ddh-<pid>.udata.txt。环境变�?DDH_UDATA=dump 时原本也会走这里�?*/
    if (g_ddhUnitDumpMode == 1) DdhUdataMaybeDumpFirstRequest();
}

static void DdhUnitDumpTick(void)
{
    if (g_ddhUnitDumpMode == 0) return;
    if (!g_ddhUnitDumpArmed) return;
    if (InterlockedCompareExchange(&g_ddhUnitDumpDone, 1, 0) != 0) return;
    DdhUnitDumpRun();
}

/* ---- 请求处理（只在游戏线程）---- */
static volatile LONG g_ddhAttrBusy     = 0;
static uint32_t      g_ddhAttrLastSeq  = 0;
static uint32_t      g_ddhAttrPostedSeq = 0;   /* 热键线程用：已经投递过的请求序�?*/
static volatile LONG g_ddhAttrRounds   = 0;

static void DdhProcessAttrRequest(void)
{
#if DDH_ENABLE_BATTLEFIELD_UNITS
    if (!g_shm) return;
    const uint32_t req = g_shm->attrs.requestSeq;
    if (req == 0 || req == g_ddhAttrLastSeq) return;
    if (InterlockedCompareExchange(&g_ddhAttrBusy, 1, 0) != 0) return;

    /* v16 诊断：DDH_UPROBE=1 时，第一次属性请求做一次全量反�?dump�?*/
    DdhUprobeEntry();

    /* v14 诊断：DDH_UDATA=dump 时，只在第一次属性请求里 dump 一次单位数据块�?*/
    DdhUdataMaybeDumpFirstRequest();

    /* 第一次请求时�?native 表全�?dump 一次，并按关键字建自动匹配候选�?
       放在 __try 之外也没关系：DdhAttrDumpNativesOnce 自己全程 __try�?*/
    DdhAttrDumpNativesOnce();

    const uint32_t tick = GetTickCount();
    int units = 0;
    int invalid = 0;
    __try
    {
        for (int i = 0; i < DDH_ATTR_MAX; i++)
        {
            const uint32_t addr = g_shm->attrs.unitAddr[i];
            DdhUnitAttr* out = &g_shm->attrs.attr[i];
            if (!addr)
            {
                memset(out, 0, sizeof(*out));
                continue;
            }
            DdhAttrFillCached(addr, out, tick);
            DdhSeedProbeNote(addr, out);
            DdhUnitDumpNote(addr, out);   /* v18：DDH_UNITDUMP=1 时锁定第一个英�?*/
            units++;
            if (out->flags == 0) invalid++;
        }
        MemoryBarrier();
        g_shm->attrs.doneSeq = req;      /* 最后写：C# �?doneSeq == requestSeq 判定这一轮完�?*/
        g_ddhAttrLastSeq = req;

        const LONG round = InterlockedIncrement(&g_ddhAttrRounds);
        if (round <= 6 || (round % 300) == 0)
            LogLine("ATTR round %d：seq=%u units=%d invalid=%d（单位属性请求已回写 doneSeq）", (int)round, req, units, invalid);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("ATTR round 异常 code=%08X（已吞掉，doneSeq 仍然写回，避免界面一直等）",
                (unsigned)GetExceptionCode());
        g_shm->attrs.doneSeq = req;
        g_ddhAttrLastSeq = req;
    }
    InterlockedExchange(&g_ddhAttrBusy, 0);

    /* v17：英雄候选已锁定就开�?SEEDPROBE（doneSeq 已写回，C# 不会等它）�?*/
    DdhSeedProbeTick();

    /* v18：DDH_UNITDUMP=1 时，在同一游戏线程直接 dump 第一个英雄的 CUnit 自身
       （不走名字种�?指针反查；只�?unit+0x00..+0x400）�?*/
    DdhUnitDumpTick();
#endif
}

static uint32_t RecordDamage(uint32_t victim, uint32_t infoPtr, uint32_t isPhysical,
                             uint32_t stackSource, uint32_t depth, uint32_t hpOk, float hpBefore,
                             uint32_t* outSeq)
{
    if (!g_shm) return 0;

    uint32_t source = 0, flag = 0, amountBits = 0, attackType = 0, mask = 0, weapon = 0;
    if (infoPtr > 0x10000 && infoPtr < 0x7FFFFFFF)
    {
        __try
        {
            const uint32_t* p = (const uint32_t*)(uintptr_t)infoPtr;
            source     = p[0];              /* +0x00 */
            weapon     = p[1];              /* +0x04 */
            flag       = p[3];              /* +0x0C */
            amountBits = p[4];              /* +0x10 */
            mask       = p[5];              /* +0x14 */
            attackType = p[8];              /* +0x20 */
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    }

    uint32_t seq = InterlockedIncrement((volatile LONG*)&g_shm->hdr.count);
    uint32_t slot = (seq - 1) % DDH_MAX_EVENTS;
    DdhEvent* e = &g_shm->ev[slot];
    InterlockedExchange(&g_evReady[slot], 0);
    e->seq        = seq;
    e->tickMs     = GetTickCount();
    e->victim     = victim;
    e->victimCode = SafeCode(victim);
    e->source     = source;
    e->sourceCode = SafeCode(source);
    /* Capture everything before the original damage function can kill or free the unit.
       Name is type-code based; title/owner/hero state come from the live CUnit*. */
    if (e->victimCode)
        ResolveName(victim, e->victimCode, e->victimName, sizeof(e->victimName));
    if (e->sourceCode)
        ResolveName(source, e->sourceCode, e->sourceName, sizeof(e->sourceName));
    DdhCacheTitleByObject(victim, e->victimCode);
    DdhCacheTitleByObject(source, e->sourceCode);
    e->victimOwner = ResolveOwnerPid(victim);
    e->sourceOwner = ResolveOwnerPid(source);
    memcpy(&e->amount, &amountBits, 4);
    e->flag       = flag;
    e->attackType = attackType;
    e->damageMask = mask;
    e->weaponType = weapon;
    e->isPhysical = isPhysical;
    e->stackSource = stackSource;
    /* v3：先�?enter 侧的血；after 由返回跳板补 */
    e->hpBefore   = hpBefore;
    e->hpAfter    = 0.0f;
    e->actual     = 0.0f;
    e->hpValid    = 0;
    e->depth      = depth;
    e->engineDamage = 0.0f;
    e->engineValid  = 0;
    e->setDamage    = 0.0f;
    e->setCalls     = 0;
    /* v20：出口三读的最终伤害，�?DdhDamageFunc 在原函数返回后补 */
    e->finalDamage  = 0.0f;
    e->finalFlags   = 0;
#if 0
    /* v7：目标单位蝗虫（马甲）标记。GetUnitAbilityLevel(handle, 'Aloc') > 0 �?bit0�?
       �?YDWE 同口径（YDWETriggerEvent.j：Aloc <= 0 = 普通单位，> 0 = 马甲），只看技能�?
       取不到（native 没定�?/ 句柄失败 / 异常）就�?0，绝不误杀正常单位�?
       v13 诊断：前 5 次无条件写日志（level<=0、handle==0 都写），用来区分
       “obj→handle 失败”“native 没定位”“查到了�?level=0”三种情况�?*/
    e->flags = 0;
    {
        const uint32_t vh = HpObjToHandle(victim);
        uint32_t fn = 0;
        int level = -1;                         /* -1 = 没查成（句柄�?native 缺失�?*/
        if (vh)
        {
            fn = GetUnitAbilityLevelNative();
            if (fn)
            {
                level = 0;
                __try { level = ((int (__cdecl*)(uint32_t, uint32_t))(uintptr_t)fn)(vh, DDH_ABILITY_ALOC); }
                __except (EXCEPTION_EXECUTE_HANDLER) { level = 0; }
                if (level > 0)
                {
                    e->flags |= 1u;   /* bit0 = 目标带蝗�?是马�?*/
                    /* v21：记住类型码，后续同码单位即使没有句柄也判定为蝗�?*/
                }
            }
        }
        /* v21：句柄拿不到，但同类型码已被实测为蝗�?�?仍按马甲处理 */
        if (InterlockedIncrement(&g_locustLogCount) <= 5)
        {
            char codeTxt[8] = { 0 };
            DdhCodeText(e->victimCode, codeTxt, sizeof(codeTxt));
            if (!vh)
                LogLine("蝗虫判定：unit=0x%08X code=%s handle=0x%08X level=%d（obj→handle 失败，未查技能）",
                        victim, codeTxt, vh, level);
            else if (!fn)
                LogLine("蝗虫判定：unit=0x%08X code=%s handle=0x%08X level=%d（GetUnitAbilityLevel native 未定位，未查技能）",
                        victim, codeTxt, vh, level);
            else
                LogLine("蝗虫判定：unit=0x%08X code=%s handle=0x%08X level=%d",
                        victim, codeTxt, vh, level);
        }
    }
#endif
    /* owner slots are filled from CUnit+0x58 after the damage callback. */
    /* Aloc by type data only; never by handle/memory of a neighboring dummy. */
    /* Event slots are reused by the 512-entry ring. Always start from zero so
       illusion bits from a previous event cannot survive in this slot. */
    e->flags = 0;
    if (DdhIsHeroCode(e->victimCode))
        e->flags |= DDH_EVENT_FLAG_VICTIM_HERO;
    if (DdhIsHeroCode(e->sourceCode))
        e->flags |= DDH_EVENT_FLAG_SOURCE_HERO;
    if (DdhUnitIllusionStateByObj(victim) > 0)
        e->flags |= DDH_EVENT_FLAG_VICTIM_ILLUSION;
    if (source && DdhUnitIllusionStateByObj(source) > 0)
        e->flags |= DDH_EVENT_FLAG_SOURCE_ILLUSION;
    /* Instance-only Aloc check while the victim CUnit pointer is still valid.
       Check both sides: attack-only spell dummies commonly appear as source. */
    if (DdhAbilityInUnitList(victim, 0x416C6F63u) > 0)
        e->flags |= 1u;
    if (source && DdhAbilityInUnitList(source, 0x416C6F63u) > 0)
        e->flags |= DDH_EVENT_FLAG_SOURCE_LOCUST;
#if 0
    if (e->victimCode && DdhTypeHasAloc(e->victimCode)) e->flags |= 1u;
#endif
    DdhDbUpdateEventUnits(e);
#if 0
    e->victimOwner = ResolveOwnerPid(victim);
    e->sourceOwner = ResolveOwnerPid(source);
    {
        const LONG n = InterlockedIncrement(&g_ownerLogCount);
        if (n <= 5)
            LogLine("玩家号：victim=0x%08X→Player %d，source=0x%08X→Player %d（-1=未知，0 基）",
                    victim, (int)e->victimOwner, source, (int)e->sourceOwner);
    }
    if (g_namesEnabled)
    {
        ResolveName(victim, e->victimCode, e->victimName, sizeof(e->victimName));
        ResolveName(source, e->sourceCode, e->sourceName, sizeof(e->sourceName));
    }
    else
    {
        e->victimName[0] = 0;
        e->sourceName[0] = 0;
    }
#endif
    g_shm->hdr.lastTick = e->tickMs;
    MemoryBarrier();
    if (outSeq) *outSeq = seq;
    return slot;
}

/* ===========================================================================
   v9：热键（Ctrl+Alt+R / S / Q�? 记录单位 + 死亡结算广播
   ---------------------------------------------------------------------------
   线程模型（和插件 UDamageWatcherHook.cpp 的“热键线�?-> 游戏线程执行”同思路）：
      * 热键线程 DdhHotkeyThreadProc 只做三件事：RegisterHotKey、GetMessage�?
        把待办标志位�?1，然�?PostMessage 给游戏窗口。不读游戏内存、不调引擎函数�?
      * v12（用户反馈“按了热键要等挨打才出提示，延迟不可接受”）：动�?*立刻**�?
        游戏线程执行 —�?子类化游戏窗口（SetWindowLongPtrW），热键线程
        PostMessage(WM_APP+0xDD)，游戏窗口过程里当场�?DdhProcessPending()�?
        以前只把待办挂在“下一次伤害事件”上，所以没伤害就一直不响应�?
      * 死亡结算仍然�?DdhProcessDeferred() 在【最外层】伤害函数退出后发�?—�?
        那条必须在引擎扣血过程之外跑，跟热键无关�?
      * 伤害事件路径里也保留一�?DdhProcessPending()：窗口没找到 / PostMessage 失败
        时退化成旧行为，不至于完全没反应�?
      * 热键线程第一次被拉起也是�?DdhDamageFunc 里（进图后才可能有伤害）�?
        不在 DllMain �?CreateThread，避免加载器锁期间起线程�?

   选区链（�?C# �?Core/Probe.cs、Core/Wc3Game.cs 完全一致，照抄偏移）：
     ctx    = *(game.dll + 0xBE4238)
     pid    = *(u16*)(ctx + 0x28)                  本地玩家�?
     player = *(u32*)(ctx + 0x58 + 4*pid)          本地玩家对象
     sel    = *(u32*)(player + 0x34)               选区容器
     node   = *(u32*)(sel + 0x1F0)                 首个选中节点（备用链 sel + 0x08�?
     unit   = *(u32*)(node + 8)                    单位对象
   每一跳都先做地址区间检查，整段再包 __try/__except；取不到只写日志�?

   消息口径（v11：聊天里**只发来源占比**，主段按用户要求不再显示）：
     死亡结算   �?【伤害】雪�?0.0% 狼人20.0%
     Ctrl+Alt+Q �?【当前伤害】雪�?0.0% 狼人20.0%
      占比 = 该来源净掉血 ÷ Σ净掉血（Σ净�?0 时退回原始伤害口径，与主界面一致）
   名字/时间/受击次数/净掉血/最大单�?只留在界面和日志里（日志会原样打整条消息）�?
   Ctrl+Alt+R / S 的反馈只在本机消息区（【已选中】�?/ 【已取消】…），不进公共聊天�?
   =========================================================================== */

/* ---- 热键 ID：外部测试脚�?PostThreadMessage(WM_HOTKEY, 这个 id) 也能触发 ---- */
#define DDH_HK_ID_R   0xD0D1u
#define DDH_HK_ID_S   0xD0D2u
#define DDH_HK_ID_Q   0xD0D3u
#define DDH_HK_ID_C   0xD0D4u
#define DDH_HK_ID_D   0xD0D5u
#define DDH_HK_ID_E   0xD0D6u   /* Ctrl+Alt+D：mock 数据演示图表（调样式用） */
#ifndef MOD_NOREPEAT
#define MOD_NOREPEAT  0x4000u
#endif

/* ---- 直投聊天（无框直投）用到�?6 �?game.dll �?RVA ----
   与插�?v1.4.1/v1.4.21 的“直投聊天”完全相同（那边已实机验证过整套）：
     0x34F3A0  get_unit(idx,0)        __fastcall(0,0)，[obj+0x3FC] = 聊天 UI 对象
     0x392060  clear_chat(obj, idx)   __thiscall
     0x3B2DE0  set_recipient(obj,sel) __thiscall�?=全部 1=盟友 2=观察�?
     0x3B3B80  SetText(obj, utf8)     __thiscall
     0x14D670  get_game_wnd(idx)      __fastcall(0,0) -> HWND
     0x153710  游戏窗口过程(hwnd,msg,wp,lp)
   为什么主路用这套、而不是直接调 InGameChatWhat�?x355CF0）：
     InGameChatWhat 只是“把一行聊天画到聊天区”的显示函数，本地调用只在本机可见�?
     不会发给其他玩家；插件仓库《WFE喊话机制与聊天管线逆向.md》�? 实测也证�?
     本地玩家自己发的消息根本不经过投递器 0x562E0。真正能让别人看到的�?
     “把文本塞进游戏聊天输入�?+ 让游戏自己的窗口过程收到一次回车”，
     也就是下面这套已经实机跑通的直投法�?*/
#define DDH_RVA_CHAT_GET_UNIT   0x34F3A0u
#define DDH_RVA_CHAT_CLEARCHAT  0x392060u
#define DDH_RVA_CHAT_SETRECIP   0x3B2DE0u
#define DDH_RVA_CHAT_SETTEXT    0x3B3B80u
#define DDH_RVA_CHAT_GAMEWND    0x14D670u
#define DDH_RVA_CHAT_GAMEPROC   0x153710u
#define DDH_OFF_CHAT_UI         0x3FCu

typedef uint32_t (__fastcall *fn_ddh_getunit_t)(uint32_t, uint32_t);
typedef void     (__fastcall *fn_ddh_thiscall1_t)(void* self, void* edx_dummy, uint32_t a);
typedef uint32_t (__fastcall *fn_ddh_getwnd_t)(uint32_t, uint32_t);
typedef intptr_t (__fastcall *fn_ddh_wndproc_t)(void* hwnd, uint32_t msg, uintptr_t wp, intptr_t lp);
typedef void     (__fastcall *fn_ddh_settext_t)(void* self, void* edx_dummy, const char* utf8);

static uint32_t       g_ddhChatGetUnit  = 0;
static uint32_t       g_ddhChatClear    = 0;
static uint32_t       g_ddhChatSetRecip = 0;
static uint32_t       g_ddhChatSetText  = 0;
static uint32_t       g_ddhChatGetWnd   = 0;
static uint32_t       g_ddhChatWndProc  = 0;
static volatile LONG  g_ddhChatInitDone = 0;
static int            g_ddhChatOk       = 0;   /* 1 = 6 个地址序言全部通过 */

/* ---- 热键线程状态（热键线程只写“待办”这 3 个标志，其余都归游戏线程�?---- */
static volatile LONG  g_ddhHkStarted   = 0;
static volatile LONG  g_ddhHkStop      = 0;
static DWORD          g_ddhHkThreadId  = 0;
static HANDLE         g_ddhHkThread    = NULL;
static volatile LONG  g_ddhPendR       = 0;
static volatile LONG  g_ddhPendS       = 0;
static volatile LONG  g_ddhPendQ       = 0;
static volatile LONG  g_ddhPendC       = 0;   /* Ctrl+Alt+C：用最近受击单位开一次承伤图表（调试/自测�?*/
static volatile LONG  g_ddhPendD       = 0;
static DWORD          g_ddhDllTick = 0;   /* DLL 加载时刻 ≈ 进图时刻（图表时间标签基准） */
static volatile LONG  g_ddhPendE       = 0;   /* Ctrl+Alt+D：mock 数据演示图表（调样式�?*/
static volatile LONG  g_ddhAutoSend    = 1;    /* 默认开；S 切换 */
static volatile LONG  g_ddhHkPressLogged  = 0;
static volatile LONG  g_ddhHkActionLogged = 0;
static volatile LONG  g_ddhHkFailLogged   = 0;
static volatile LONG  g_ddhHkToggleLogged = 0;
static volatile LONG  g_ddhHkQueryLogged  = 0;
static volatile LONG  g_ddhHkPanelLogged  = 0;

/* v17：鼠标整块点击面板展开/收起（不再有快捷键）。命中矩形是归一化坐标�?*/
static volatile LONG  g_ddhPanelClickOk   = 0;
static volatile LONG  g_ddhPanelMouseDown = 0;
static float          g_ddhPanelHitL = 0.0f;
static float          g_ddhPanelHitT = 0.0f;
static float          g_ddhPanelHitW = 0.0f;
static float          g_ddhPanelHitH = 0.0f;
static int      g_ddhChartMode = 0;
static int      g_ddhChartCollapsed = 1;   /* 默认收缩 */
static float    g_ddhChartW = 0.34f, g_ddhChartH = 0.32f;
static float    g_ddhChartWantX = 0.60f, g_ddhChartWantY = -0.10f;
static float    g_ddhChartX = 0.60f, g_ddhChartY = -0.24f, g_ddhChartFh = 0.0135f;
static volatile LONG  g_ddhPanelLastToggle = 0;
static volatile LONG  g_ddhPanelClickLogged = 0;
static volatile LONG  g_ddhMouseMsgLogged = 0;
static volatile LONG  g_ddhPanelFrameRectOk = 0;
static float          g_ddhPanelFrameL = 0.0f;
static float          g_ddhPanelFrameT = 0.0f;
static float          g_ddhPanelFrameR = 0.0f;
static float          g_ddhPanelFrameB = 0.0f;

/* v28：游戏内【死亡结算】按钮（常驻小按钮，点一下唤出/收起阵亡总结面板）。
   几何同样是 UI 坐标（0.8 x 0.6），左上锚点、y 向下为负。 */
#define DDH_BTN_X       0.008f
#define DDH_BTN_Y       (-0.040f)
#define DDH_BTN_W       0.064f
#define DDH_BTN_H       0.021f
static uint32_t        g_ddhBtnUi       = 0;
static uint32_t        g_ddhBtnBg       = 0;
static uint32_t        g_ddhBtnText     = 0;
static volatile LONG   g_ddhBtnReady    = 0;
static volatile LONG   g_ddhBtnMouseDown = 0;
static volatile LONG   g_ddhBtnRectOk   = 0;
static float           g_ddhBtnL = 0.0f, g_ddhBtnT = 0.0f, g_ddhBtnR = 0.0f, g_ddhBtnB = 0.0f;
static volatile LONG   g_ddhBtnLogged   = 0;
static volatile LONG   g_ddhBtnClickLogged = 0;
static volatile LONG   g_ddhBtnLastGameCheck = 0;
static volatile LONG   g_ddhBtnInGame   = 0;
static int             g_ddhBtnDisabled = 0;
static int             g_ddhBtnEnvRead  = 0;
static uint32_t        g_ddhHiddenCursorUi = 0;
static uint32_t        g_ddhHiddenCursorFrame = 0;
static int             g_ddhCursorOver = 0;
static volatile LONG   g_ddhCursorLogged = 0;
static uint32_t        g_ddhHtmlFrame = 0;
static uint32_t        g_ddhHtmlUi = 0;
static int             g_ddhHtmlShown = 0;
static int             g_ddhHtmlFailed = 0;
static volatile LONG   g_ddhHtmlLogged = 0;
static uint32_t        g_ddhCursorRaisedUi = 0;
static uint32_t        g_ddhCursorRaisedFrame = 0;
static int32_t         g_ddhCursorRaisedLevel = 0;

/* ---- 记录单位 + 它自己的统计（只在游戏线程读写，不需要锁�?---- */
#define DDH_SRC_MAX 32

struct DdhSrcStat
{
    uint32_t source;    /* 来源单位对象指针（码相同就合并，指针只留第一个） */
    uint32_t code;      /* 来源类型�?*/
    uint32_t hits;
    float    maxHit;
    double   raw, engine, map, net;
    char     label[96]; /* 第一次见到它时查好的“名�?�?”——发送时不再碰可能已释放的指�?*/
};

struct DdhTrack
{
    uint32_t   unit;        /* 0 = 还没记录单位 */
    uint32_t   code;
    uint32_t   hits;
    uint32_t   startMs;
    uint32_t   srcCount;
    uint32_t   dead;        /* 1 = 已经广播过死亡，等它复活再重新统�?*/
    float      maxHit;
    double     raw, engine, map, net;
    char       label[96];   /* �?R 时查好的“名�?�?�?*/
    DdhSrcStat src[DDH_SRC_MAX];
};

static DdhTrack g_ddhTrack;

/* ---- 全局“每个受击单位”的累计：Q 在没有记录单位时发它�?Top5 ---- */
#define DDH_GLOBAL_MAX 128

struct DdhVictimStat
{
    uint32_t unit;
    uint32_t code;
    uint32_t hits;
    float    maxHit;
    double   net, raw;
    char     label[96]; /* 第一次见到它时查好的“名�?�?�?*/
};

static DdhVictimStat g_ddhGlobal[DDH_GLOBAL_MAX];
static int           g_ddhGlobalCount = 0;

/* ---- 待发送的结算（游戏线程内填写、游戏线程内发送） ---- */
static char          g_ddhDeferText[768];
static volatile LONG g_ddhDeferKind   = 0;     /* 1 = 有一条死亡结算等着�?*/
static volatile LONG g_ddhSendOkCount = 0;
static volatile LONG g_ddhSendFailCnt = 0;
static volatile LONG g_ddhSendSkipLogged = 0;
static volatile LONG g_ddhMsgLogCount  = 0;   /* “组好的消息”日志限流（�?60 条） */

/* ---- 兜底显示（DisplayTimedTextToPlayer）的状�?---- */
static uint32_t      g_ddhNatDtttp      = 0;
static uint32_t      g_ddhNatPlayer     = 0;
static uint32_t      g_ddhNatGetPlayers = 0;
static volatile LONG g_ddhDtttpTries    = 0;
static volatile LONG g_ddhPlayerTries   = 0;
static volatile LONG g_ddhPlayersTries  = 0;
static volatile LONG g_ddhDtttpFailLogged = 0;

/* ---------------------------------------------------------------------------
   几个小工�?
   --------------------------------------------------------------------------- */

/* 4 字节类型�?-> 可读文本。内存里是反序存的（�?SafeCode 注释），
   所以按 dword 的高字节到低字节打印就是显示顺序�?hfoo"/"opeo"…）�?*/
static void DdhCodeText(uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 5) { if (out && cap) out[0] = 0; return; }
    out[0] = (char)((code >> 24) & 0xFF);
    out[1] = (char)((code >> 16) & 0xFF);
    out[2] = (char)((code >>  8) & 0xFF);
    out[3] = (char)((code      ) & 0xFF);
    for (int i = 0; i < 4; i++)
        if ((unsigned char)out[i] < 0x20 || (unsigned char)out[i] > 0x7E) out[i] = '.';
    out[4] = 0;
}

/* v11：消息里不再带时间（主段已去掉），函数留着备用 */
static void DdhFormatHms(char* out, size_t cap)
{
    SYSTEMTIME st;
    GetLocalTime(&st);
    DdhSprintf(out, cap, "%02d:%02d:%02d", (int)st.wHour, (int)st.wMinute, (int)st.wSecond);
}

static void DdhTruncateUtf8(char* s, size_t cap, size_t maxBytes);   /* 定义在后�?*/

/* �?“名�?类型�?�?拼进固定大小�?out�?*不越界、不切坏 UTF-8、不触发无效参数**�?
   名字先按 UTF-8 边界截到“放得下 �?�?�?+ 结束符”的长度，再�?_snprintf_s(...,_TRUNCATE)�?
   （sprintf_s 放不下会 _invoke_watson �?__fastfail(0xC0000409)：真�?2026-10-31 20:22:52
     就是长名�?“……【辅助单位�?e009)�?写进 64 字节标签把游戏带走的。） */
static void DdhCleanName(const char* src, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    if (!src) return;
    size_t o = 0;
    for (size_t i = 0; src[i] && o + 1 < cap; )
    {
        if (src[i] == '|' && (src[i + 1] == 'c' || src[i + 1] == 'C'))
        {
            int j = 2;
            bool hex = true;
            for (; j < 10; j++)
            {
                const char c = src[i + j];
                if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')))
                { hex = false; break; }
            }
            if (hex) { i += 10; continue; }
        }
        if (src[i] == '|' && (src[i + 1] == 'r' || src[i + 1] == 'R'))
        {
            i += 2;
            continue;
        }
        out[o++] = src[i++];
    }
    out[o] = 0;
}

static void DdhComposeLabel(const char* name, const char* codeTxt, char* out, size_t cap)
{
    if (!out || cap < 2) { if (out && cap) out[0] = 0; return; }
    out[0] = 0;

    const bool hasName = (name && name[0]);
    const bool hasCode = (codeTxt && codeTxt[0]);

    if (hasName && hasCode)
    {
        char fitted[128] = { 0 };
        strncpy_s(fitted, sizeof(fitted), name, _TRUNCATE);
        const size_t reserve = strlen(codeTxt) + 3;          /* '(' + �?+ ')' + 结束�?*/
        const size_t room    = (cap > reserve + 1) ? cap - reserve : 1;
        DdhTruncateUtf8(fitted, sizeof(fitted), room);        /* �?UTF-8 边界截断并补 “…�?*/
        DdhSprintf(out, cap, "%s(%s)", fitted, codeTxt);
    }
    else if (hasName) DdhSprintf(out, cap, "%s", name);
    else if (hasCode) DdhSprintf(out, cap, "%s", codeTxt);
    else              DdhSprintf(out, cap, "?");
}

/* 单位显示名：优先引擎查到的名字，查不到退回类型码，再不行退回对象指针�?
   ResolveName 内部有“类型码→名字”缓存与日志限流；这里在游戏线程调用�?*/
static void DdhUnitLabel(uint32_t unit, uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    char name[96] = { 0 };
    char codeTxt[8] = { 0 };
    if (code) DdhCodeText(code, codeTxt, sizeof(codeTxt));

    if (unit >= 0x10000u && unit <= 0x7FFFFFFFu)
        ResolveName(unit, code, name, sizeof(name));

    /* 引擎名字带 |cAARRGGBB / |r 颜色码，面板/聊天里要清掉 */
    if (name[0])
    {
        char clean[96];
        DdhCleanName(name, clean, sizeof(clean));
        strcpy_s(name, sizeof(name), clean);
    }

    if (!name[0] && !codeTxt[0] && unit)
    {
        DdhSprintf(out, cap, "0x%08X", unit);
        return;
    }
    DdhComposeLabel(name, codeTxt, out, cap);
}

/* Damage hooks must not call engine/JASS name resolvers. Use only the cache
   already populated by deferred attribute requests, otherwise the type code. */
static void DdhUnitLabelSafe(uint32_t, uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    if (code)
    {
        for (int i = 0; i < g_nameCacheCount; i++)
        {
            if (g_nameCache[i].code == code && g_nameCache[i].name[0])
            {
                DdhUtf8SafeCopy(out, cap, g_nameCache[i].name, cap - 1);
                return;
            }
        }
        DdhCodeText(code, out, cap);
        return;
    }
    strcpy_s(out, cap, "?");
}

/* 发送时用的标签：优先用早就查好的缓存，绝不再去碰可能已经释放的单位指针 */
static void DdhLabelOf(const char* label, uint32_t code, uint32_t unit, char* out, size_t cap)
{
    if (label && label[0]) { strncpy_s(out, cap, label, _TRUNCATE); return; }
    char codeTxt[8] = { 0 };
    if (code) DdhCodeText(code, codeTxt, sizeof(codeTxt));
    if (codeTxt[0])      DdhSprintf(out, cap, "%s", codeTxt);
    else if (unit)       DdhSprintf(out, cap, "0x%08X", unit);
    else                 DdhSprintf(out, cap, "?");
}

/* 追加�?0 结尾的字符串（自动截断，不会越界�?*/
static void DdhAppendFmt(char* dst, size_t cap, const char* fmt, ...)
{
    const size_t used = strlen(dst);
    if (used + 1 >= cap) return;
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(dst + used, cap - used, _TRUNCATE, fmt, ap);
    va_end(ap);
}

/* 地图伤害（生效值）：与 C# �?HookEvent.EffectiveDamage 同口�?*/
static double DdhEventEffective(const DdhEvent* e)
{
    /* v20：最终值（出口 *out）优�?—�?它就是引擎真正扣下去的那个数，且已含地图改写�?
       bit0 只在"确实掉了血"时才置位，所以这里不用再�?>0.005�?*/
    if (e->finalFlags & 1u) return (double)e->finalDamage;
    if (e->setCalls > 0) return (double)e->setDamage;
    return e->hpValid ? (double)e->actual : 0.0;
}

/* ---------------------------------------------------------------------------
   v10/v11 文本拼装：修“名字乱码”，消息只发来源占比（主段不发了�?
   ---------------------------------------------------------------------------
   编码事实（真机日�?ddh-17256.log 实证）：
     · 引擎 0x326BA0 返回的单位名**本身就是 UTF-8 字节**
       （“雪狼�?= E9 9B AA E7 8B BC，“梦幻伯爵�?= E6 A2 A6 E5 B9 BB E4 BC AF E7 88 B5）；
       ResolveName 只是把这些字节原样拷�?victimName/sourceName，没有转码�?
     · 本文件自己的中文标签�?GBK 字面量（源码本身�?GBK）�?
   所以一条消息天然是“两种编码混排”，**绝不能整段再�?GBK 转一�?* —�?
   那等于把已经�?UTF-8 的名字又�?GBK 解一遍，聊天里就成了“妖”加怪符号那种乱码�?
   组消息的规矩（本文件所有发出去的消息都走这套）�?
     �?中文标签：GBK 字面�?�?UTF-8 ................ DdhAppendLabel
     �?单位�? ：原始字节直接拼、不再转�?.......... DdhAppendUnitName
     �?名字里若没有合法 UTF-8（例�?GBK 名字的孤立高位字节），只�?*这个名字**
        整体�?GBK→UTF-8 转一次当回退，并在日志里写明本条走了哪条路�?
   --------------------------------------------------------------------------- */

/* 一条聊天消息的 UTF-8 字节上限。旧�?240 太短，字段一多就被截成“…来…�?
   （真机那条就是被截断的），放�?420 够放完整【伤害】段�?*/
#define DDH_MSG_MAX_BYTES   420
/* 【伤害】段默认列几个来源（按净掉血占比降序�?*/
#define DDH_SHARE_TOP       3

/* 本条消息里的名字走了哪条路（每次组消息前清零，发送时写进日志�?*/
static int  g_msgNameRawUtf8     = 0;    /* �?合法 UTF-8 �?原字节拼�?*/
static int  g_msgNameGbkFallback = 0;    /* �?非法 UTF-8 �?整体�?GBK 转一�?*/
static volatile LONG g_msgNameFallbackLogged = 0;

/* 一段字节是不是合法 UTF-8：拒绝孤立续字节 0x80~0xBF�?xF8~0xFF、过长编码�?
   代理区、超 0x10FFFF。空串按“不合法”返回（调用方当“没名字”处理）�?*/
static bool DdhUtf8Valid(const char* s)
{
    if (!s || !s[0]) return false;
    const unsigned char* p = (const unsigned char*)s;
    const int n = (int)strlen(s);
    for (int i = 0; i < n; )
    {
        const unsigned char c = p[i];
        int need = 0;
        uint32_t cp = 0;
        if (c < 0x80) { i++; continue; }
        else if ((c & 0xE0) == 0xC0) { need = 1; cp = (uint32_t)(c & 0x1F); }
        else if ((c & 0xF0) == 0xE0) { need = 2; cp = (uint32_t)(c & 0x0F); }
        else if ((c & 0xF8) == 0xF0) { need = 3; cp = (uint32_t)(c & 0x07); }
        else return false;                                  /* 0x80~0xBF 孤立 / 0xF8~0xFF */
        if (i + need >= n) return false;                    /* 尾巴被截�?*/
        for (int k = 1; k <= need; k++)
        {
            if ((p[i + k] & 0xC0) != 0x80) return false;
            cp = (cp << 6) | (uint32_t)(p[i + k] & 0x3F);
        }
        if ((need == 1 && cp < 0x80u) || (need == 2 && cp < 0x800u) ||
            (need == 3 && cp < 0x10000u)) return false;      /* 过长编码 */
        if (cp >= 0xD800u && cp <= 0xDFFFu) return false;    /* 代理�?*/
        if (cp > 0x10FFFFu) return false;
        i += need + 1;
    }
    return true;
}

/* GBK -> UTF-8：给“本文件的中文标签”和“名字不�?UTF-8 时的回退”用�?
   转换失败就按原字节拷贝（宁可乱码也不丢字），返回 false�?*/
static bool DdhGbkToUtf8(const char* src, char* dst, size_t cap)
{
    if (!dst || cap < 2) return false;
    dst[0] = 0;
    if (!src || !src[0]) return true;

    const int need = MultiByteToWideChar(936, 0, src, -1, NULL, 0);
    if (need <= 0) { strncpy_s(dst, cap, src, _TRUNCATE); return false; }

    wchar_t* w = (wchar_t*)malloc((size_t)need * sizeof(wchar_t));
    if (!w) { strncpy_s(dst, cap, src, _TRUNCATE); return false; }

    bool ok = false;
    if (MultiByteToWideChar(936, 0, src, -1, w, need) > 0)
        ok = WideCharToMultiByte(CP_UTF8, 0, w, -1, dst, (int)cap, NULL, NULL) > 0;
    free(w);

    if (!ok) { strncpy_s(dst, cap, src, _TRUNCATE); return false; }
    return true;
}

/* UTF-8 -> GBK�?*只给写日志用**（日志文件是 GBK，直接写 UTF-8 在记事本里是乱码）�?*/
static bool DdhUtf8ToGbk(const char* src, char* dst, size_t cap)
{
    if (!dst || cap < 2) return false;
    dst[0] = 0;
    if (!src || !src[0]) return true;

    const int need = MultiByteToWideChar(CP_UTF8, 0, src, -1, NULL, 0);
    if (need <= 0) return false;

    wchar_t* w = (wchar_t*)malloc((size_t)need * sizeof(wchar_t));
    if (!w) return false;

    bool ok = false;
    if (MultiByteToWideChar(CP_UTF8, 0, src, -1, w, need) > 0)
        ok = WideCharToMultiByte(936, 0, w, -1, dst, (int)cap, NULL, NULL) > 0;
    free(w);

    if (!ok) dst[0] = 0;
    return ok;
}

/* 追加一�?ASCII 或已确认�?UTF-8 的字节（越界自动截断，永�?0 结尾�?*/
static void DdhAppendRaw(char* dst, size_t cap, const char* s)
{
    if (!dst || cap < 2 || !s || !s[0]) return;
    const size_t used = strlen(dst);
    if (used + 1 >= cap) return;
    size_t room = cap - used - 1;                 /* 留一个字节给 NUL */
    size_t n = strlen(s);
    if (n > room) n = room;
    if (n == 0) return;
    memcpy(dst + used, s, n);
    dst[used + n] = 0;
}

/* 追加中文标签：源码本身就�?UTF-8（ddh.cpp 已统一 UTF-8 编码），原样拼即可�?
   （老版本源码是 GBK，那时才需�?GBK→UTF-8；现在再转一次反而会变乱码。） */
static void DdhAppendLabel(char* dst, size_t cap, const char* labelUtf8)
{
    if (!dst || cap < 2 || !labelUtf8 || !labelUtf8[0]) return;
    DdhAppendRaw(dst, cap, labelUtf8);
}

/* 追加单位名：**引擎给的原字节直接拼**（它就是 UTF-8，再转一次才会乱）�?
   只有不是合法 UTF-8 时才退回“整个名字按 GBK→UTF-8 转一次”，并记日志说明走了哪条路�?*/
static void DdhAppendUnitName(char* dst, size_t cap, const char* raw)
{
    if (!dst || cap < 2 || !raw || !raw[0]) return;

    if (DdhUtf8Valid(raw))                        /* �?真机就是这条路：原样�?*/
    {
        g_msgNameRawUtf8++;
        DdhAppendRaw(dst, cap, raw);
        return;
    }

    char utf8[256] = { 0 };
    if (DdhGbkToUtf8(raw, utf8, sizeof(utf8)) && utf8[0] && DdhUtf8Valid(utf8))
    {
        g_msgNameGbkFallback++;
        const LONG n = InterlockedIncrement(&g_msgNameFallbackLogged);
        if (n <= 5)
        {
            char hex[96] = { 0 };
            int nb = (int)strlen(raw);
            if (nb > 24) nb = 24;
            FormatHex((const unsigned char*)raw, nb, hex, sizeof(hex));
            LogLine("消息编码：单位名不是合法 UTF-8，本条按 GBK→UTF-8 回退（原字节 hex=%s）", hex);
        }
        DdhAppendRaw(dst, cap, utf8);
        return;
    }

    /* 两条路都不通：按原字节拼，不丢内容、不�?*/
    g_msgNameGbkFallback++;
    DdhAppendRaw(dst, cap, raw);
}

/* 硬截断到 maxBytes 字节：不切坏汉字，末尾补 “…”（UTF-8 = E2 80 A6）�?
   cap 是缓冲区总容量；maxBytes 会被夹到 cap-1 以内�?*/
static void DdhTruncateUtf8(char* s, size_t cap, size_t maxBytes)
{
    if (!s || cap < 2) return;
    if (maxBytes + 1 > cap) maxBytes = cap - 1;
    if (strlen(s) <= maxBytes) return;

    size_t cut = maxBytes > 3 ? maxBytes - 3 : maxBytes;   /* �?3 字节给尾�?“…�?*/
    while (cut > 0 && ((unsigned char)s[cut] & 0xC0) == 0x80) cut--;   /* 别切在汉字中�?*/
    s[cut] = 0;
    if (maxBytes >= cut + 3)
    {
        memcpy(s + cut, "\xE2\x80\xA6", 3);
        s[cut + 3] = 0;
    }
}

/* "雪狼(hfoo)" -> "雪狼"：【伤害】段里只要名字（或类型码），不带类型码后缀�?*/
static void DdhStripCodeSuffix(const char* label, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    if (!label || !label[0]) return;

    const size_t n = strlen(label);
    if (n >= 7 && label[n - 1] == ')')
    {
        const char* lp = strrchr(label, '(');
        if (lp && (size_t)(label + n - 1 - lp) == 5)       /* "(XXXX)" 正好 6 个字�?*/
        {
            size_t keep = (size_t)(lp - label);
            if (keep > cap - 1) keep = cap - 1;
            memcpy(out, label, keep);
            out[keep] = 0;
            return;
        }
    }
    strncpy_s(out, cap, label, _TRUNCATE);
}

/* ---------------------------------------------------------------------------
   消息（死亡结�?/ Ctrl+Alt+Q 实时统计�?
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   【伤害】段：来�?Top N（默�?3），�?*净掉血占比**降序，每�?“名字或类型�?+ 一位小数百分比”�?
   ---------------------------------------------------------------------------
   口径与主界面（C# Core/HookBreakdown.cs �?PercentOf）完全一致：
     占比 = 该来源净掉血 ÷ 整条 Σ净掉血�?
     Σ净掉血 <= 0（这条结算没有可信血量）时退回“原始伤害”口径，免得整段�?0%�?
   只拼“项”的部分（不含【伤害】标签），项之间一个空格�?
   返回写进去的项数�? = 没有可显示的来源，调用方就别打【伤害】段了）�?*/
static int DdhBuildShareItems(const DdhSrcStat* src, uint32_t n, double totalNet, double totalRaw,
                              int maxItems, char* out, size_t outCap)
{
    if (!out || outCap < 2) return 0;
    out[0] = 0;
    if (!src || n == 0 || maxItems <= 0) return 0;
    if (n > DDH_SRC_MAX) n = DDH_SRC_MAX;

    const bool   useNet = totalNet > 0.01;
    const double denom  = useNet ? totalNet : totalRaw;
    if (!(denom > 0.01)) return 0;

    /* 按占比口径排序（净掉血优先；Σ净�?0 时按原始伤害�?*/
    int idx[DDH_SRC_MAX];
    for (uint32_t i = 0; i < n; i++) idx[i] = (int)i;
    for (uint32_t i = 0; i < n; i++)
    {
        for (uint32_t j = i + 1; j < n; j++)
        {
            const double a = useNet ? src[idx[j]].net : src[idx[j]].raw;
            const double b = useNet ? src[idx[i]].net : src[idx[i]].raw;
            if (a > b) { const int t = idx[i]; idx[i] = idx[j]; idx[j] = t; }
        }
    }

    int used = 0;
    for (uint32_t k = 0; k < n && used < maxItems; k++)
    {
        const DdhSrcStat* s = &src[idx[k]];
        const double v = useNet ? s->net : s->raw;
        if (v <= 0.01) continue;                       /* 0% 的来源不浪费聊天长度 */
        double pct = v * 100.0 / denom;
        pct = floor(pct * 10.0 + 0.5) / 10.0;          /* 四舍五入�?0.1 */
        if (pct < 0.1) pct = 0.1;                      /* 有伤害就别显示成 0.0% */
        if (pct > 100.0) pct = 100.0;

        char label[96]    = { 0 };
        char nameOnly[96] = { 0 };
        char num[16]      = { 0 };
        DdhLabelOf(s->label, s->code, s->source, label, sizeof(label));
        DdhStripCodeSuffix(label, nameOnly, sizeof(nameOnly));
        DdhSprintf(num, sizeof(num), "%.1f%%", pct);

        if (used) DdhAppendRaw(out, outCap, " ");
        DdhAppendUnitName(out, outCap, nameOnly);      /* 名字：引擎原字节直接�?*/
        DdhAppendRaw(out, outCap, num);
        used++;
    }
    return used;
}

/* 组一条“来源占比”文本（死亡结算 �?Ctrl+Alt+Q 共用同一套拼法）�?
     isDeath=1 �?【伤害】雪�?0.0% 狼人20.0%          �?死亡结算就发这一条，不再带主�?
     isDeath=0 �?【当前伤害】雪�?0.0% 狼人20.0%      �?Ctrl+Alt+Q
   按用户要求，主段（【死亡结算】名�?时间 受击N�?净X 最大Y�?*不再�?*�?
   名字/时间/重击数字只留在界面和日志里，聊天里只有来源占比�?
   没有来源（还没打中过 / 读不到伤害）时返回空串，由调用方决定发不发�?
   截断策略（DDH_MSG_MAX_BYTES = 420 UTF-8 字节）：
     先砍靠后的来源（3 �?2 �?1）→ 最后才�?420 硬截断并在末尾补 “…”（不切坏汉字）�?*/
static void DdhBuildTrackText(char* out, size_t cap, int isDeath)
{
    if (!out || cap < 2) return;
    out[0] = 0;

    int maxSrc = (int)g_ddhTrack.srcCount;
    if (maxSrc > DDH_SHARE_TOP) maxSrc = DDH_SHARE_TOP;

    char items[320] = { 0 };
    char tmp[512]   = { 0 };
    for (int src = maxSrc; src >= 1; src--)
    {
        /* 每试一版都重算“名字走了哪条路”，让日志里的数字只反映最终这一�?*/
        g_msgNameRawUtf8 = 0;
        g_msgNameGbkFallback = 0;

        const int used = DdhBuildShareItems(g_ddhTrack.src, g_ddhTrack.srcCount,
                                            g_ddhTrack.net, g_ddhTrack.raw,
                                            src, items, sizeof(items));
        if (used <= 0) { tmp[0] = 0; continue; }

        tmp[0] = 0;
        DdhAppendLabel(tmp, sizeof(tmp), isDeath ? "【伤害】" : "【当前伤害】");
        DdhAppendRaw(tmp, sizeof(tmp), items);
        if (strlen(tmp) <= DDH_MSG_MAX_BYTES)
        {
            strncpy_s(out, cap, tmp, _TRUNCATE);
            return;
        }
    }

    /* �?1 个来源都放不下（名字特别长）：硬截断 + “…�?*/
    if (tmp[0])
    {
        DdhTruncateUtf8(tmp, sizeof(tmp), DDH_MSG_MAX_BYTES);
        strncpy_s(out, cap, tmp, _TRUNCATE);
    }
}

static double DdhVictimKey(const DdhVictimStat* v)
{
    return v->net > 0.01 ? v->net : v->raw;
}

/* 没有记录单位�?Q 用的全局 Top5 受击单位（同样是 UTF-8：中文标签转、名字原样拼�?*/
static void DdhBuildGlobalTop5(char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    g_msgNameRawUtf8 = 0;
    g_msgNameGbkFallback = 0;

    int idx[DDH_GLOBAL_MAX];
    int n = 0;
    for (int i = 0; i < g_ddhGlobalCount; i++)
        if (g_ddhGlobal[i].hits > 0) idx[n++] = i;

    for (int i = 0; i < n; i++)
    {
        for (int j = i + 1; j < n; j++)
        {
            if (DdhVictimKey(&g_ddhGlobal[idx[j]]) > DdhVictimKey(&g_ddhGlobal[idx[i]]))
            { const int t = idx[i]; idx[i] = idx[j]; idx[j] = t; }
        }
    }

    DdhAppendLabel(out, cap, "【全局Top5受击】");
    if (n == 0)
    {
        DdhAppendLabel(out, cap, "还没统计到任何伤害事件（先打起来再按 Q）");
        return;
    }

    const int top = n < 5 ? n : 5;
    for (int k = 0; k < top; k++)
    {
        const DdhVictimStat* v = &g_ddhGlobal[idx[k]];
        char label[96] = { 0 };
        char num[48]   = { 0 };
        DdhLabelOf(v->label, v->code, v->unit, label, sizeof(label));
        DdhSprintf(num, sizeof(num), " %.2f/%u", DdhVictimKey(v), (unsigned)v->hits);
        DdhAppendRaw(out, cap, " ");
        DdhAppendUnitName(out, cap, label);
        DdhAppendRaw(out, cap, num);
        DdhAppendLabel(out, cap, "膵");
    }

    /* 同一�?420 字节上限（这里只硬截断，不逐级降级�?*/
    DdhTruncateUtf8(out, cap, DDH_MSG_MAX_BYTES);
}

/* ---------------------------------------------------------------------------
   广播：直投聊天（游戏自己的输入框 + 回车），失败再退兜底
   --------------------------------------------------------------------------- */

/* 判断一个入口像不像插件里验证过的那些函数：
   55 8B EC（标准序言�? 83 E9（sub ecx,0�? 6A FF（push -1 �?SEH 序言），
   或者被别的插件挂钩后的 E9（跳转目标可执行即算合法 —�?插件实机日志证实
   WFE �?0x153710 改成�?E9，照样能正常调）�?*/
static bool DdhChatEntryOk(uint32_t fn)
{
    if (fn < 0x10000u) return false;
    uint8_t b[6] = { 0 };
    __try
    {
        for (int i = 0; i < 6; i++) b[i] = *(const uint8_t*)(uintptr_t)(fn + (uint32_t)i);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    if ((b[0] == 0x55 && b[1] == 0x8B && b[2] == 0xEC) ||
        (b[0] == 0x83 && b[1] == 0xE9) ||
        (b[0] == 0x6A && b[1] == 0xFF))
        return true;

    if (b[0] == 0xE9)
    {
        uint32_t tgt = 0;
        __try { tgt = fn + 5u + *(const int32_t*)(uintptr_t)(fn + 1u); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)(uintptr_t)tgt, &mbi, sizeof(mbi)) &&
            mbi.State == MEM_COMMIT &&
            (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                            PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)))
            return true;
    }
    return false;
}

/* 懒校�?6 个地址。只在游戏线程调用（DdhDeliverText 里）�?*/
static void DdhInitChatDirect(void)
{
    if (InterlockedCompareExchange(&g_ddhChatInitDone, 1, 0) != 0) return;
    if (!g_modBase)
    {
        LogLine("结算广播：没有 game.dll 基址，直投聊天不可用");
        return;
    }

    struct Item { uint32_t rva; const char* name; uint32_t* slot; };
    Item items[6] = {
        { DDH_RVA_CHAT_GET_UNIT,  "get_unit",      &g_ddhChatGetUnit  },
        { DDH_RVA_CHAT_CLEARCHAT, "clear_chat",    &g_ddhChatClear    },
        { DDH_RVA_CHAT_SETRECIP,  "set_recipient", &g_ddhChatSetRecip },
        { DDH_RVA_CHAT_SETTEXT,   "SetText",       &g_ddhChatSetText  },
        { DDH_RVA_CHAT_GAMEWND,   "get_game_wnd",  &g_ddhChatGetWnd   },
        { DDH_RVA_CHAT_GAMEPROC,  "game_wndproc",  &g_ddhChatWndProc  },
    };

    for (int i = 0; i < 6; i++)
    {
        const uint32_t fn = g_modBase + items[i].rva;
        if (!DdhChatEntryOk(fn))
        {
            uint8_t b[4] = { 0 };
            __try { for (int k = 0; k < 4; k++) b[k] = *(const uint8_t*)(uintptr_t)(fn + (uint32_t)k); }
            __except (EXCEPTION_EXECUTE_HANDLER) { b[0] = 0; }
            LogLine("结算广播：直投聊天不可用 —�?%s(Game.dll+0x%X) 入口 %02X %02X %02X %02X 不符"
                    "（Game.dll 版本不匹配/被别的插件改过），只能用兜底显示（仅本机可见）",
                    items[i].name, items[i].rva, b[0], b[1], b[2], b[3]);
            return;
        }
    }

    for (int i = 0; i < 6; i++) *items[i].slot = g_modBase + items[i].rva;
    g_ddhChatOk = 1;
    LogLine("结算广播：直投聊天已就绪（6 个地址序言全部通过；收件人=全部；由游戏自己发送）");
}

/* 直投：取聊天 UI 对象 -> clear_chat / set_recipient(全部) -> SetText(UTF-8)
   -> 让游戏窗口过程收到一次回车。成功返�?1�?*/
static int DdhChatDirectSend(const char* utf8, char* why, size_t whyCap)
{
    if (!g_ddhChatOk)
    {
        DdhSprintf(why, whyCap, "直投聊天地址未就绪（见上一条日志）");
        return 0;
    }

    int ok = 0;
    __try
    {
        const uint32_t obj = ((fn_ddh_getunit_t)(uintptr_t)g_ddhChatGetUnit)(1, 0);
        uint32_t ui = 0;
        if (obj >= 0x10000u && obj <= 0x7FFFFFFFu)
            ui = *(const uint32_t*)(uintptr_t)(obj + DDH_OFF_CHAT_UI);

        HWND hwnd = (HWND)(uintptr_t)((fn_ddh_getwnd_t)(uintptr_t)g_ddhChatGetWnd)(0, 0);
        if (!hwnd) hwnd = FindWindowA("Warcraft III", NULL);
        if (!hwnd) hwnd = FindWindowA(NULL, "Warcraft III");

        if (!ui || !hwnd)
        {
            DdhSprintf(why, whyCap, "拿不到聊天 UI 对象(%08X)或游戏窗口(%p)", ui, (void*)hwnd);
            ok = 0;
        }
        else
        {
            ((fn_ddh_thiscall1_t)(uintptr_t)g_ddhChatClear)((void*)(uintptr_t)ui, NULL, 0);
            ((fn_ddh_thiscall1_t)(uintptr_t)g_ddhChatClear)((void*)(uintptr_t)ui, NULL, 1);
            ((fn_ddh_thiscall1_t)(uintptr_t)g_ddhChatSetRecip)((void*)(uintptr_t)ui, NULL, 0);
            ((fn_ddh_settext_t)(uintptr_t)g_ddhChatSetText)((void*)(uintptr_t)ui, NULL, utf8);
            ((fn_ddh_wndproc_t)(uintptr_t)g_ddhChatWndProc)((void*)hwnd, WM_KEYDOWN, (uintptr_t)VK_RETURN, 0);
            ((fn_ddh_wndproc_t)(uintptr_t)g_ddhChatWndProc)((void*)hwnd, WM_KEYUP,   (uintptr_t)VK_RETURN, 0);
            ok = 1;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        DdhSprintf(why, whyCap, "调用直投聊天异常 code=%08X", (unsigned)GetExceptionCode());
        ok = 0;
    }
    return ok;
}

/* ---------------------------------------------------------------------------
   兜底显示：DisplayTimedTextToPlayer（native 表按名字找）
   JASS native 的字符串参数要的�?YDWE string_fake 形态的【对象指针�?
   �?0x08 指向自身�?0x1C �?char* 正文），不是字符�?id —�?照插�?
   MakeJassString 的做法造一个常驻对象；传裸 char* 会让引擎解引用小整数而崩�?
   --------------------------------------------------------------------------- */
struct DdhFakeString { uint32_t m[8]; };
static DdhFakeString g_ddhStrObj[16];
static char          g_ddhStrBuf[16][512];
static unsigned      g_ddhStrIdx = 0;

static uint32_t DdhMakeJassString(const char* text)
{
    const unsigned i = g_ddhStrIdx++ % 16u;
    strncpy_s(g_ddhStrBuf[i], sizeof(g_ddhStrBuf[i]), text ? text : "", _TRUNCATE);
    memset(g_ddhStrObj[i].m, 0, sizeof(g_ddhStrObj[i].m));
    g_ddhStrObj[i].m[2] = (uint32_t)(uintptr_t)&g_ddhStrObj[i].m[0];   /* +0x08 指向自身 */
    g_ddhStrObj[i].m[7] = (uint32_t)(uintptr_t)g_ddhStrBuf[i];         /* +0x1C 正文 */
    return (uint32_t)(uintptr_t)&g_ddhStrObj[i];
}

static uint32_t DdhGetDtttp(void)
{
    if (g_ddhNatDtttp) return g_ddhNatDtttp;
    if (InterlockedIncrement(&g_ddhDtttpTries) > 16) return 0;
    g_ddhNatDtttp = FindNativeFunc("DisplayTimedTextToPlayer");
    if (g_ddhNatDtttp)
        LogLine("结算兜底：DisplayTimedTextToPlayer native 已定位（0x%08X）", g_ddhNatDtttp);
    else if (InterlockedIncrement(&g_ddhDtttpFailLogged) <= 3)
        LogLine("结算兜底：native 表里暂时找不到 DisplayTimedTextToPlayer（没有 JASS/还没进图），本次只能用日志");
    return g_ddhNatDtttp;
}

static uint32_t DdhGetPlayerNative(void)
{
    if (g_ddhNatPlayer) return g_ddhNatPlayer;
    if (InterlockedIncrement(&g_ddhPlayerTries) > 16) return 0;
    g_ddhNatPlayer = FindNativeFunc("Player");
    if (g_ddhNatPlayer)
        LogLine("结算兜底：Player native 已定位（0x%08X）", g_ddhNatPlayer);
    return g_ddhNatPlayer;
}

static uint32_t DdhGetPlayersNative(void)
{
    if (g_ddhNatGetPlayers) return g_ddhNatGetPlayers;
    if (InterlockedIncrement(&g_ddhPlayersTries) > 16) return 0;
    g_ddhNatGetPlayers = FindNativeFunc("GetPlayers");
    if (g_ddhNatGetPlayers)
        LogLine("结算兜底：GetPlayers native 已定位（0x%08X）", g_ddhNatGetPlayers);
    return g_ddhNatGetPlayers;
}

/* 发给每个玩家句柄（拿不到句柄就传 0）。返回成功调用的次数�? = 不可用�?
   注意：DisplayTimedTextToPlayer 是【本地显示】函数，即使传别人的句柄也不会上别人的屏�?
   所以日志里必须写明“仅本机可见”�?*/
static int DdhShowLocalText(const char* utf8)
{
    const uint32_t dt = DdhGetDtttp();
    if (!dt) return 0;

    const uint32_t s = DdhMakeJassString(utf8);
    if (!s) return 0;

    float x = 0.0f, y = 0.0f, dur = 10.0f;
    int shown = 0;

    __try
    {
        const uint32_t pn = DdhGetPlayerNative();

        int total = 12;
        const uint32_t gp = DdhGetPlayersNative();
        if (gp)
        {
            int t = 0;
            __try { t = (int)((uint32_t (__cdecl*)(void))(uintptr_t)gp)(); }
            __except (EXCEPTION_EXECUTE_HANDLER) { t = 0; }
            if (t > 0 && t <= 24) total = t;
        }

        if (!pn)
        {
            ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)dt)
                (0, &x, &y, &dur, s);
            shown = 1;
        }
        else
        {
            uint32_t seen[24];
            for (int i = 0; i < total; i++)
            {
                uint32_t h = 0;
                __try { h = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)pn)((uint32_t)i); }
                __except (EXCEPTION_EXECUTE_HANDLER) { h = 0; }

                if (!h) continue;
                bool dup = false;
                for (int k = 0; k < shown; k++) if (seen[k] == h) { dup = true; break; }
                if (dup) continue;

                ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)dt)
                    (h, &x, &y, &dur, s);
                seen[shown++] = h;
            }
            if (shown == 0)
            {
                ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)dt)
                    (0, &x, &y, &dur, s);
                shown = 1;
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("结算广播失败：兜底显示抛异常 code=%08X", (unsigned)GetExceptionCode());
        shown = 0;
    }
    return shown;
}

/* ---------------------------------------------------------------------------
   本机提示（热键反馈）：只调一�?DisplayTimedTextToPlayer，别的玩家看不到�?
   v11：Ctrl+Alt+R 选中 / Ctrl+Alt+S 开关都在这里给一句提示�?
   为什么不�?DdhDeliverText：那条路�?*直投公共聊天**（收件人=全部），
   热键反馈要是也广播出去，等于每按一�?R 就跟全房间喊一声，太吵�?
   --------------------------------------------------------------------------- */
static volatile LONG g_toastLogCount = 0;

static void DdhToast(const char* utf8)
{
    if (!utf8 || !utf8[0]) return;

    if (InterlockedIncrement(&g_toastLogCount) <= 20)
    {
        LogLine("热键提示（仅本机）：%s", utf8);
    }

    const uint32_t dt = DdhGetDtttp();
    if (!dt)
    {
        /* 屏幕提示不可用（native 还没就绪）：只留日志，绝不影响统�?*/
        return;
    }

    const uint32_t s = DdhMakeJassString(utf8);
    if (!s) return;

    /* 尽量只发给本机玩家：ctx+0x28 是本地玩家号�? 基），拿不到就传 0 */
    uint32_t player = 0;
    const uint32_t pn = DdhGetPlayerNative();
    if (pn && g_modBase)
    {
        const uint32_t ctx = SafeU32(g_modBase, DDH_RVA_CTX_GLOBAL);
        if (ctx >= 0x10000u && ctx <= 0x7FFFFFFFu)
        {
            const uint32_t pid = SafeU32(ctx, 0x28u) & 0xFFFFu;
            if (pid < 24u)
            {
                __try { player = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)pn)(pid); }
                __except (EXCEPTION_EXECUTE_HANDLER) { player = 0; }
            }
        }
    }

    float x = 0.0f, y = 0.05f, dur = 6.0f;
    __try
    {
        ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)dt)
            (player, &x, &y, &dur, s);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("热键提示：上屏抛异常 code=%08X（已吞掉，不影响统计）", (unsigned)GetExceptionCode());
    }
}

/* 发送一�?*已经�?UTF-8** 的消息：先直投广播，失败再兜底本机显示。只在游戏线程调用�?
   v10：这里不再做“整�?GBK→UTF-8”（那正是名字乱码的根源）——中文标签在组消息时
   已经转成 UTF-8，单位名是引擎给的原字节，见 DdhAppendLabel / DdhAppendUnitName�?*/
static void DdhDeliverText(const char* textUtf8)
{
    if (!textUtf8 || !textUtf8[0]) return;

    char utf8[1024] = { 0 };
    strncpy_s(utf8, sizeof(utf8), textUtf8, _TRUNCATE);

    /* 最后一道保险：超过 420 字节就按 UTF-8 边界截断并补 “…”（调用方理应已降级过） */
    DdhTruncateUtf8(utf8, sizeof(utf8), DDH_MSG_MAX_BYTES);
    const unsigned len = (unsigned)strlen(utf8);

    /* 把“组好的消息”写进日志（日志也是 UTF-8，直接写，肉眼就能核对）�?
       顺带写下本条名字走的是哪条路（原�?UTF-8 几个 / GBK 回退几个）�?*/
    if (InterlockedIncrement(&g_ddhMsgLogCount) <= 60)
    {
        LogLine("结算广播：消息（UTF-8 %u 字节；名字 原样UTF-8 %d 个 / GBK回退 %d 个）=%s",
                len, g_msgNameRawUtf8, g_msgNameGbkFallback, utf8);
    }

    DdhInitChatDirect();

    char why[192] = { 0 };
    if (DdhChatDirectSend(utf8, why, sizeof(why)))
    {
        if (InterlockedIncrement(&g_ddhSendOkCount) <= 100)
            LogLine("结算广播：已发送（长度 %u）", len);
        return;
    }

    if (InterlockedIncrement(&g_ddhSendFailCnt) <= 3)
        LogLine("结算广播失败：兜底显示抛异常 code=%08X", why);

    const int shown = DdhShowLocalText(utf8);
    if (shown > 0)
    {
        if (InterlockedIncrement(&g_ddhSendOkCount) <= 100)
            LogLine("结算广播：已发送（长度 %u，兜底本机显示 %d 个玩家句柄；仅本机可见）", len, shown);
    }
    else if (g_ddhSendFailCnt <= 3)
    {
        LogLine("结算广播失败：直投与兜底都不可用（长度 %u，本次不发；统计与日志不受影响）", len);
    }
}

/* ---------------------------------------------------------------------------
   统计：全局受击�?+ 记录单位
   --------------------------------------------------------------------------- */
static void DdhGlobalAdd(const DdhEvent* e)
{
    /* 只统计“真读到血差”的事件：单位死后假伤害不再刷次�?*/
    if (!e->hpValid) return;

    int idx = -1;
    for (int i = 0; i < g_ddhGlobalCount; i++)
        if (g_ddhGlobal[i].unit == e->victim) { idx = i; break; }

    if (idx < 0)
    {
        if (g_ddhGlobalCount >= DDH_GLOBAL_MAX) return;
        idx = g_ddhGlobalCount++;
        g_ddhGlobal[idx].unit   = e->victim;
        g_ddhGlobal[idx].code   = e->victimCode;
        g_ddhGlobal[idx].hits   = 0;
        g_ddhGlobal[idx].maxHit = 0.0f;
        g_ddhGlobal[idx].net    = 0.0;
        g_ddhGlobal[idx].raw    = 0.0;
        DdhUnitLabelSafe(e->victim, e->victimCode, g_ddhGlobal[idx].label, sizeof(g_ddhGlobal[idx].label));
    }

    DdhVictimStat* v = &g_ddhGlobal[idx];
    v->hits++;
    v->net += (double)e->actual;
    v->raw += (double)e->amount;
    if (e->actual > v->maxHit) v->maxHit = e->actual;
}

static void DdhSelfSettleEvent(const DdhEvent* e);

static void DdhTrackEvent(const DdhEvent* e)
{
    DdhSelfSettleEvent(e);
    DdhGlobalAdd(e);

    if (!e->victim || e->victim != g_ddhTrack.unit) return;

    if (g_ddhTrack.dead)
    {
        /* 已经广播过死亡：等它复活（后血回到 > 0）再重新开一份统�?*/
        if (e->hpValid && e->hpAfter > 0.0f)
        {
            const uint32_t unit = e->victim;
            const uint32_t code = e->victimCode;
            memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
            g_ddhTrack.unit    = unit;
            g_ddhTrack.code    = code;
            g_ddhTrack.startMs = GetTickCount();
            DdhUnitLabelSafe(unit, code, g_ddhTrack.label, sizeof(g_ddhTrack.label));
            LogLine("热键：记录单位复活（0x%08X），统计已重置，继续跟踪", unit);
        }
        return;
    }

    const double eff = DdhEventEffective(e);
    const double net = e->hpValid ? (double)e->actual : 0.0;
    const double hit = e->hpValid ? net : eff;

    g_ddhTrack.hits++;
    g_ddhTrack.raw += (double)e->amount;
    if (e->engineValid) g_ddhTrack.engine += (double)e->engineDamage;
    g_ddhTrack.map += eff;
    g_ddhTrack.net += net;
    if (hit > (double)g_ddhTrack.maxHit) g_ddhTrack.maxHit = (float)hit;

    /* 来源累计：按类型码合并（同码不同单位算一条，显示按“名�?�?”）；没码就按指针分 */
    const uint32_t key = e->sourceCode ? e->sourceCode : e->source;
    DdhSrcStat* s = NULL;
    for (uint32_t i = 0; i < g_ddhTrack.srcCount; i++)
    {
        const DdhSrcStat* cur = &g_ddhTrack.src[i];
        const uint32_t curKey = cur->code ? cur->code : cur->source;
        if (curKey == key) { s = &g_ddhTrack.src[i]; break; }
    }
    if (!s && g_ddhTrack.srcCount < DDH_SRC_MAX)
    {
        s = &g_ddhTrack.src[g_ddhTrack.srcCount++];
        s->source  = e->source;
        s->code    = e->sourceCode;
        s->hits    = 0;
        s->maxHit  = 0.0f;
        s->raw     = 0.0;
        s->engine  = 0.0;
        s->map     = 0.0;
        s->net     = 0.0;
        DdhUnitLabelSafe(e->source, e->sourceCode, s->label, sizeof(s->label));
    }
    if (s)
    {
        s->hits++;
        s->raw += (double)e->amount;
        if (e->engineValid) s->engine += (double)e->engineDamage;
        s->map += eff;
        s->net += net;
        if (hit > (double)s->maxHit) s->maxHit = (float)hit;
    }

    /* 死亡：后血 <= 0 且本层前血 > 0（hpValid 就是这么定义的）。只排一次，发送在
       最外层伤害函数退出后（DdhProcessDeferred），避免在引擎扣血过程中调聊天函数�?
       v11：消息只发【伤害】来源占比（主段按用户要求不再发）。没有来源构成就干脆不发�?
       别在公共聊天里刷一条空消息�?*/
    if (e->hpValid && e->hpAfter <= 0.0f)
    {
        g_ddhTrack.dead = 1;
        DdhBuildTrackText(g_ddhDeferText, sizeof(g_ddhDeferText), 1);
        if (g_ddhDeferText[0])
        {
            g_ddhDeferKind = 1;
            LogLine("热键：记录单位 0x%08X 死亡（后血 %.2f），【伤害】已排队（本层伤害函数退出后发送）",
                    e->victim, (double)e->hpAfter);
        }
        else
        {
            LogLine("热键：记录单位当前血量 %.2f（开始累计它的受击）",
                    e->victim, (double)e->hpAfter);
        }
    }
}

/* v12：热键动作要**立刻**在游戏线程执�?—�?窗口消息通道（实现见 DdhProcessPending 之后�?*/
/* ===========================================================================
   v22：dll 自己出“阵亡总结”（不依赖 War3DeathSettlement.exe）
   ---------------------------------------------------------------------------
   只统计“本地玩家的英雄”（victimOwner == 本地玩家号 且 IsHeroUnitId(victimCode)）：
     · 从英雄出现/复活开始累计：承受伤害、笔数、最大一击、最惨 1 秒、战斗时长、来源 Top4；
     · 死亡事件（前血 > 0、后血 <= 0）时拼面板，交给 DdhProcessDeferred 在伤害函数
       最外层退出后显示（避免在引擎扣血过程中调游戏显示函数）。
   C# 端只要写过 panel（seq 变化且不是 dll 自己写的）就认为“外部面板接管”，dll 不再抢。
   =========================================================================== */
static uint32_t g_selfHero = 0;
static uint32_t g_selfHeroCode = 0;
static int      g_selfLife = 1;
static int      g_selfDead = 0;
static uint32_t g_selfLifeStartSeq = 0;
static uint32_t g_selfHits = 0;
static double   g_selfNet = 0.0, g_selfRaw = 0.0, g_selfMax = 0.0;
static uint32_t g_selfFirstTick = 0, g_selfLastTick = 0;
static uint32_t g_selfCurSec = 0;
static double   g_selfCurSum = 0.0, g_selfPeak = 0.0;
static int      g_selfSecInit = 0;
static DdhSrcStat g_selfSrc[DDH_SRC_MAX];
static uint32_t g_selfSrcCount = 0;
static uint32_t g_selfFatalSource = 0, g_selfFatalCode = 0, g_selfFatalFlag = 0;
static uint32_t g_selfFatalPhysical = 0;
static double   g_selfFatalNet = 0.0;
static char     g_selfFatalName[64];
static uint32_t g_selfPanelSeq = 0;
static int      g_selfPanelPending = 0;
static int      g_selfCsPanel = 0;

static void DdhSelfPanelShow(void);

static int DdhLocalPid(void)
{
    /* 不在伤害钩子里调 JASS native（GetLocalPlayer/GetPlayerId 在引擎扣血过程中
       会动 JASS 栈，实测会把 Storm.dll 写崩）。
       本地玩家号由游戏线程的 DdhComputeAllyMask 解析并缓存；没解析到才退回 0。 */
    if (g_localPlayerId >= 0 && g_localPlayerId < 24) return g_localPlayerId;
    return 0;
}

static int DdhIsHeroCode(uint32_t code)
{
    if (!code) return 0;
    /* 英雄类型码首字母大写（O00X/Hpal…），普通单位/creep 小写（e007/n05P…）。
       这样不需要在钩子里调 IsHeroUnitId。 */
    const char c = (char)((code >> 24) & 0xFF);
    return (c >= 'A' && c <= 'Z') ? 1 : 0;
}

static void DdhNumFmt(double v, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    if (!(v == v)) v = 0.0;
    if (v < 0.0) v = 0.0;
    char raw[40];
    DdhSprintf(raw, sizeof(raw), "%.0f", v);
    size_t n = strlen(raw), pos = 0;
    for (size_t i = 0; i < n && pos + 2 < cap; i++)
    {
        if (i > 0 && ((n - i) % 3) == 0) out[pos++] = ',';
        out[pos++] = raw[i];
    }
    out[pos] = 0;
}

static void DdhSelfReset(uint32_t hero, uint32_t code, uint32_t seq)
{
    g_selfHero = hero;
    g_selfHeroCode = code;
    g_selfLifeStartSeq = seq;
    g_selfHits = 0; g_selfNet = 0.0; g_selfRaw = 0.0; g_selfMax = 0.0;
    g_selfFirstTick = 0; g_selfLastTick = 0;
    g_selfCurSec = 0; g_selfCurSum = 0.0; g_selfPeak = 0.0; g_selfSecInit = 0;
    g_selfSrcCount = 0;
    memset(g_selfSrc, 0, sizeof(g_selfSrc));
    g_selfFatalSource = 0; g_selfFatalCode = 0; g_selfFatalFlag = 0;
    g_selfFatalPhysical = 0; g_selfFatalNet = 0.0; g_selfFatalName[0] = 0;
}

static DdhSrcStat* DdhSelfSrcGet(const DdhEvent* e)
{
    const uint32_t key = e->sourceCode ? e->sourceCode : e->source;
    for (uint32_t i = 0; i < g_selfSrcCount; i++)
    {
        DdhSrcStat* s = &g_selfSrc[i];
        if ((s->code ? s->code : s->source) == key) return s;
    }
    if (g_selfSrcCount >= DDH_SRC_MAX) return NULL;
    DdhSrcStat* s = &g_selfSrc[g_selfSrcCount++];
    memset(s, 0, sizeof(*s));
    s->source = e->source;
    s->code = e->sourceCode;
    DdhUnitLabelSafe(e->source, e->sourceCode, s->label, sizeof(s->label));
    return s;
}

static void DdhSelfSettleEvent(const DdhEvent* e)
{
    if (!g_shm || !e || !e->victim) return;

    /* 外部（C#）写过面板：说明有人接管显示，dll 不抢。 */
    if (g_shm->panel.seq != 0 && g_shm->panel.seq != g_selfPanelSeq)
        g_selfCsPanel = 1;
    if (g_selfCsPanel) return;

    const int lp = DdhLocalPid();
    if (lp < 0) return;

    /* 还没锁定英雄：找“本地玩家拥有的英雄”。 */
    if (g_selfHero == 0 || e->victim != g_selfHero)
    {
        if (e->victimOwner != lp || !DdhIsHeroCode(e->victimCode)) return;
        DdhSelfReset(e->victim, e->victimCode, e->seq);
        g_selfDead = 0;
        g_selfLife = 1;
        LogLine("v22 阵亡总结：锁定本地英雄 0x%08X（%s），开始累计", e->victim,
                DdhCodeText(e->victimCode));
    }
    if (e->victim != g_selfHero) return;

    /* 复活/新一条命：后血回到正数。 */
    if (g_selfDead && e->hpValid && e->hpAfter > 0.0f)
    {
        DdhSelfReset(g_selfHero, e->victimCode, e->seq);
        g_selfDead = 0;
    }
    if (!e->hpValid || e->seq < g_selfLifeStartSeq) return;

    const double net = (double)e->actual;
    const double hit = net > 0.0 ? net : 0.0;
    if (g_selfFirstTick == 0) g_selfFirstTick = e->tickMs;
    g_selfLastTick = e->tickMs;

    if (hit > 0.005)
    {
        g_selfHits++;
        g_selfNet += hit;
        g_selfRaw += (double)e->amount;
        if (hit > g_selfMax) g_selfMax = hit;

        const uint32_t sec = e->tickMs / 1000u;
        if (!g_selfSecInit) { g_selfSecInit = 1; g_selfCurSec = sec; g_selfCurSum = 0.0; }
        if (sec != g_selfCurSec)
        {
            if (g_selfCurSum > g_selfPeak) g_selfPeak = g_selfCurSum;
            g_selfCurSec = sec;
            g_selfCurSum = 0.0;
        }
        g_selfCurSum += hit;

        DdhSrcStat* s = DdhSelfSrcGet(e);
        if (s)
        {
            s->hits++;
            s->net += net;
            s->raw += (double)e->amount;
            if (hit > (double)s->maxHit) s->maxHit = (float)hit;
        }
    }

    /* 死亡：前血 > 0、后血 <= 0。 */
    if (e->hpBefore > 0.0f && e->hpAfter <= 0.0f)
    {
        if (g_selfCurSum > g_selfPeak) g_selfPeak = g_selfCurSum;
        g_selfFatalSource = e->source;
        g_selfFatalCode = e->sourceCode;
        g_selfFatalFlag = e->flag;
        g_selfFatalPhysical = e->isPhysical;
        g_selfFatalNet = net;
        DdhUnitLabelSafe(e->source, e->sourceCode, g_selfFatalName, sizeof(g_selfFatalName));
        g_selfDead = 1;
        g_selfPanelPending = 1;
        g_selfLife++;
    }
}

static void DdhSelfPanelShow(void)
{
    if (!g_shm || g_selfCsPanel) return;
    if (g_selfHero == 0) return;

    /* 与 C# 端“承伤图表”同一套渲染：只发 ChartReq{magic, victim}，
       5 秒分桶、四类（物理/法术/纯粹/移除）、来源分段全部由 DdhChartBuild 现算。 */
    {
        DdhPanelBlock cp;
        memset(&cp, 0, sizeof(cp));
        cp.flags = DDH_PANEL_FLAG_SHOW | DDH_PANEL_FLAG_BG | DDH_PANEL_FLAG_CHART |
                   ((uint32_t)3u << DDH_PANEL_COLLAPSED_SHIFT);
        cp.ttlMs = 20000;
        cp.anchor = 0;
        cp.x = 0.60f;
        cp.y = -0.24f;
        cp.lineHeight = 0.0175f;
        cp.fontHeight = 0.0135f;
        strcpy_s(cp.fontName, sizeof(cp.fontName), "MasterFont");
        uint32_t payload[2] = { DDH_CHART_MAGIC, g_selfHero };
        memcpy(cp.lines, payload, sizeof(payload));
        cp.seq = (uint32_t)InterlockedIncrement((volatile LONG*)&g_selfPanelSeq);
        memcpy(&g_shm->panel, &cp, sizeof(cp));
        MemoryBarrier();
        LogLine("v22 阵亡总结：已推送承伤图表（victim=0x%08X）", g_selfHero);
        return;
    }

    DdhPanelBlock p;
    memset(&p, 0, sizeof(p));
    p.flags = DDH_PANEL_FLAG_SHOW | DDH_PANEL_FLAG_BG |
              ((uint32_t)3u << DDH_PANEL_COLLAPSED_SHIFT);
    p.ttlMs = 20000;
    p.anchor = 0;
    p.x = 0.60f;
    p.y = -0.24f;
    p.lineHeight = 0.0175f;
    p.fontHeight = 0.0135f;
    strcpy_s(p.fontName, sizeof(p.fontName), "MasterFont");

    int n = 0;
    char buf[240];
    char num1[40], num2[40], num3[40], num4[40];
    DdhNumFmt(g_selfNet, num1, sizeof(num1));
    DdhNumFmt(g_selfMax, num2, sizeof(num2));
    DdhNumFmt(g_selfPeak, num3, sizeof(num3));

    p.lines[n].color = 0xFFFFD700u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, "阵亡总结");

    char label[96] = "";
    DdhUnitLabel(g_selfHero, g_selfHeroCode, label, sizeof(label));
    char codeTxt[8] = { 0 };
    DdhCodeText(g_selfHeroCode, codeTxt, sizeof(codeTxt));
    if (label[0] && codeTxt[0] && strstr(label, codeTxt))
        DdhSprintf(buf, sizeof(buf), "%s", label);
    else
        DdhSprintf(buf, sizeof(buf), "%s · %s", label[0] ? label : "?", codeTxt);
    p.lines[n].color = 0xFFFFFFFFu;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    SYSTEMTIME st;
    GetLocalTime(&st);
    DdhSprintf(buf, sizeof(buf), "玩家 %d · 第 %d 条命 · 死亡 %02u:%02u:%02u",
               DdhLocalPid() + 1, g_selfLife - 1, st.wHour, st.wMinute, st.wSecond);
    p.lines[n].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    DdhSprintf(buf, sizeof(buf), "承受伤害 %s", num1);
    p.lines[n].color = 0xFFFFFFFFu;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    DdhSprintf(buf, sizeof(buf), "%u 笔 · 最大 %s · 最惨 1 秒 %s",
               g_selfHits, num2, num3);
    p.lines[n].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    double secs = (g_selfFirstTick && g_selfLastTick > g_selfFirstTick)
                  ? (double)(g_selfLastTick - g_selfFirstTick) / 1000.0 : 0.0;
    DdhSprintf(buf, sizeof(buf), "战斗 %.1f 秒 · 秒伤 %.0f",
               secs, secs > 0.05 ? g_selfNet / secs : 0.0);
    p.lines[n].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    DdhNumFmt(g_selfFatalNet, num4, sizeof(num4));
    DdhSprintf(buf, sizeof(buf), "致命一击 %s %s（%s · %s）",
               g_selfFatalName[0] ? g_selfFatalName : "?",
               num4,
               (g_selfFatalFlag & 0x100u) ? "普攻" : "技能",
               g_selfFatalPhysical ? "物理" : "法术");
    p.lines[n].color = 0xFFFF6666u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    p.lines[n].color = 0xFFFFD700u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, "伤害来源");

    int used[DDH_SRC_MAX];
    memset(used, 0, sizeof(used));
    for (int k = 0; k < 4 && k < (int)g_selfSrcCount; k++)
    {
        int best = -1;
        for (uint32_t i = 0; i < g_selfSrcCount; i++)
        {
            if (used[i]) continue;
            if (best < 0 || g_selfSrc[i].net > g_selfSrc[best].net) best = (int)i;
        }
        if (best < 0) break;
        used[best] = 1;
        DdhSrcStat* s = &g_selfSrc[best];
        DdhNumFmt(s->net, num2, sizeof(num2));
        double pct = g_selfNet > 0.01 ? (s->net * 100.0 / g_selfNet) : 0.0;
        DdhSprintf(buf, sizeof(buf), "%s %.1f%%  %s  %u笔",
                   s->label[0] ? s->label : (s->code ? DdhCodeText(s->code) : "?"),
                   pct, num2, s->hits);
        p.lines[n].color = 0xFFFFFFFFu;
        strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);
        if (n >= DDH_PANEL_MAX_LINES - 1) break;
    }

    DdhSprintf(buf, sizeof(buf), "0x%08X · ddh v%d", g_selfHero, DDH_VERSION);
    p.lines[n].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    p.lineCount = (uint32_t)n;
    p.seq = (uint32_t)InterlockedIncrement((volatile LONG*)&g_selfPanelSeq);
    memcpy(&g_shm->panel, &p, sizeof(p));
    MemoryBarrier();
    LogLine("v22 阵亡总结：已推送（%d 行，承伤 %.0f，%u 笔，来源 %u）",
            n, g_selfNet, g_selfHits, g_selfSrcCount);
}

static int  DdhEnsureGameWnd(void);
static void DdhPostHotkeyToGame(void);

/* ---------------------------------------------------------------------------
   热键线程：只注册热键、收 WM_HOTKEY、置待办标志位，并立�?PostMessage 给游戏窗�?
   --------------------------------------------------------------------------- */
/* v10：属性请求投递（实现在窗口过程那一�?—�?那里 g_gameWnd / DDH_WM_ATTR 已就绪） */
static void DdhMaybePostAttrRequest(void);

/* v15：游戏内阵亡面板 / 英雄查询（实现在 DdhProcessDeferred 之后；这里只前置声明�?*/
static void DdhProcessPanelRequest(void);
static void DdhProcessHeroRequest(void);
static void DdhPanelTick(void);
static void DdhMaybePostPanelAndHero(void);
static void DdhPanelDemoOnce(void);
static void DdhDoTogglePanel(void);
/* `~` 显隐：键�?`~`（VK_OEM_3）显�?隐藏面板。返�?1 = 这次按键被面板消�?*/
static int  DdhDoToggleVisible(void);
/* 承伤图表（flags bit4）：渲染/隐藏/点击。实现见 DdhDoToggleVisible 之后�?*/
static int  DdhChartApply(uint32_t ui, const DdhPanelBlock* p, uint32_t victim,
                          float x, float y, float fh, const char* font);
static void DdhChartHide(void);
static void DdhChartClick(int x, int y);
static void DdhChartDebugShow(void);
static void DdhChartDemoShow(void);
static void DdhChartToggleView(void);
static void DdhChartReflow(void);
static void DdhChartToggleCollapsed(void);
static int  DdhChartEscCollapse(void);
static void DdhChartReviveCheck(void);

static void DdhPanelClickAt(int x, int y);
static volatile LONG g_ddhPanelPostErrLogged = 0;

/* v28：游戏内按钮（实现在 DdhPanelHide 之后；窗口过程/面板 tick 里用） */
static int  DdhButtonEnsure(void);
static int  DdhButtonHitTest(int x, int y);
static void DdhButtonClick(void);
static void DdhButtonSetTextColor(uint32_t argb);
static int  DdhPanelApply(const DdhPanelBlock* p);
static void DdhFrameShowHide(void* frame, int show);
static void DdhApplyCursorOver(int over, int useSystemCursor);
static int  DdhHtmlPanelEnsure(uint32_t ui);
static void DdhRaiseGameCursor(uint32_t ui);

static DWORD WINAPI DdhHotkeyThreadProc(LPVOID)
{
    g_ddhHkThreadId = GetCurrentThreadId();

    const UINT mod = MOD_CONTROL | MOD_ALT | MOD_NOREPEAT;
    const BOOL rR = RegisterHotKey(NULL, DDH_HK_ID_R, mod, 'R');
    const BOOL rS = RegisterHotKey(NULL, DDH_HK_ID_S, mod, 'S');
    const BOOL rQ = RegisterHotKey(NULL, DDH_HK_ID_Q, mod, 'Q');
    const BOOL rC = RegisterHotKey(NULL, DDH_HK_ID_C, mod, 'C');
    const BOOL rD = RegisterHotKey(NULL, DDH_HK_ID_D, mod, 'D');
    const BOOL rE = RegisterHotKey(NULL, DDH_HK_ID_E, mod, 'E');

    LogLine("热键：线程已启动 tid=%lu，Ctrl+Alt+R=%s S=%s Q=%s C=%s D=%s（注册失败一般是被别的软件占用）",
            (unsigned long)g_ddhHkThreadId,
            rR ? "成功" : "失败", rS ? "成功" : "失败", rQ ? "成功" : "失败",
            rC ? "成功" : "失败", rD ? "成功" : "失败");

    if (!rR && !rS && !rQ)
    {
        LogLine("热键：三个组合键一个都没注册上，本次热键不可用（伤害钩子/统计/面板 TTL 不受影响）");
        /* �?return：仍要托管游戏窗口，面板 TTL tick / 属性投递还要靠这条线程�?*/
    }

    /* v12：先把游戏窗口挂上，之后每个热键都能立刻在游戏线程执行（毫秒级，不等伤害事件�?*/
    if (!DdhEnsureGameWnd())
        LogLine("热键：暂时没找到游戏窗口，动作会退化为“下一次伤害事件时处理”（有延迟）");

    /* v10：用 MsgWaitForMultipleObjects(100ms) 取代阻塞�?GetMessage —�?既收热键�?
       又每 100ms 看一眼“C# 有没有新的属性请求”，有就投给游戏窗口�?
       不引入额外线程，热键行为一个字节没变�?*/
    bool quit = false;
    while (!quit && InterlockedCompareExchange(&g_ddhHkStop, 0, 0) == 0)
    {
        const DWORD wait = MsgWaitForMultipleObjects(0, NULL, FALSE, 100, QS_ALLINPUT);
        if (wait == WAIT_OBJECT_0)
        {
            MSG msg;
            while (PeekMessageA(&msg, NULL, 0, 0, PM_REMOVE))
            {
                if (msg.message == WM_QUIT) { quit = true; break; }

                if (msg.message == WM_HOTKEY)
                {
                    /* 注意：WM_HOTKEY �?wParam 是【注册时给的 id】，不是按键码；
                       按键字母�?id 反查（以前这里直�?(char)wParam，日志里打出来是乱码）�?*/
                    char keyName = '?';
                    switch ((uint32_t)msg.wParam)
                    {
                    case DDH_HK_ID_R: InterlockedExchange(&g_ddhPendR, 1); keyName = 'R'; break;
                    case DDH_HK_ID_S: InterlockedExchange(&g_ddhPendS, 1); keyName = 'S'; break;
                    case DDH_HK_ID_Q: InterlockedExchange(&g_ddhPendQ, 1); keyName = 'Q'; break;
                    case DDH_HK_ID_C: InterlockedExchange(&g_ddhPendC, 1); keyName = 'C'; break;
                    case DDH_HK_ID_D: InterlockedExchange(&g_ddhPendD, 1); keyName = 'D'; break;
                    case DDH_HK_ID_E: InterlockedExchange(&g_ddhPendE, 1); keyName = 'E'; break;
                    default: break;
                    }
                    /* 热键按下本身记一条（限流），真机排查“热键到底有没有被系统发给游戏”用 */
                    if (InterlockedIncrement(&g_ddhHkPressLogged) <= 30)
                        LogLine("热键：收到 Ctrl+Alt+%c（立刻投给游戏线程执行）", keyName);

                    /* v12：立刻让游戏线程执行，不再等下一次伤害事件�?
                       窗口不可用时待办标志已经置位，仍会走旧的伤害事件路径兜底�?*/
                    if (keyName != '?') DdhPostHotkeyToGame();
                }

                TranslateMessage(&msg);
                DispatchMessageA(&msg);
            }
        }
        /* v10：属性请求（100ms 节流；没有新请求时什么都不做�?*/
        __try { DdhMaybePostAttrRequest(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            if (InterlockedIncrement(&g_ddhAttrNoHandleLogged) <= 5)
                LogLine("ATTR post 投递请求异常 code=%08X（已吞掉，等下一条伤害事件兜底）",
                        (unsigned)GetExceptionCode());
        }
        /* v15：面�?/ 英雄查询请求（同�?100ms 节流，只投消息、不碰引擎） */
        __try { DdhMaybePostPanelAndHero(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            if (InterlockedIncrement(&g_ddhPanelPostErrLogged) <= 5)
                LogLine("面板 post 投递请求异常 code=%08X（已吞掉，等下一条伤害事件兜底）",
                        (unsigned)GetExceptionCode());
        }
    }

    UnregisterHotKey(NULL, DDH_HK_ID_R);
    UnregisterHotKey(NULL, DDH_HK_ID_S);
    UnregisterHotKey(NULL, DDH_HK_ID_Q);
    UnregisterHotKey(NULL, DDH_HK_ID_C);
    UnregisterHotKey(NULL, DDH_HK_ID_D);
    UnregisterHotKey(NULL, DDH_HK_ID_E);
    LogLine("热键：线程退出（tid=%lu）", (unsigned long)g_ddhHkThreadId);
    return 0;
}

/* 第一次进伤害函数（游戏已经跑起来、DLL 也不在加载器锁里）时把热键线程拉起来 */
static void DdhEnsureHotkeyThread(void)
{
    if (InterlockedCompareExchange(&g_ddhHkStarted, 1, 0) != 0) return;

    LogLine("热键：游戏线程 tid=%lu，启动热键线程（Ctrl+Alt+R 记录选中单位 / S 自动发送 / Q 看统计）",
            (unsigned long)GetCurrentThreadId());

    g_ddhHkThread = CreateThread(NULL, 0, DdhHotkeyThreadProc, NULL, 0, NULL);
    if (!g_ddhHkThread)
        LogLine("热键：CreateThread 失败 err=%lu（本次热键不可用，伤害钩子不受影响）", GetLastError());
}

/* 读选区链。usedAlt 回传是否走了备用�?sel+0x08�?
   全程 __try；任何一跳不合法都返�?0，由调用方写日志�?*/
static uint32_t DdhReadSelection(int* usedAlt)
{
    if (usedAlt) *usedAlt = 0;
    if (!g_modBase) return 0;

    uint32_t unit = 0;
    __try
    {
        const uint32_t ctx = SafeU32(g_modBase, DDH_RVA_CTX_GLOBAL);
        if (ctx < 0x10000u || ctx > 0x7FFFFFFFu) return 0;

        const uint32_t pid = SafeU32(ctx, 0x28u) & 0xFFFFu;
        if (pid >= 24u) return 0;

        const uint32_t player = SafeU32(ctx, 0x58u + 4u * pid);
        if (player < 0x10000u || player > 0x7FFFFFFFu) return 0;

        const uint32_t sel = SafeU32(player, 0x34u);
        if (sel < 0x10000u || sel > 0x7FFFFFFFu) return 0;

        uint32_t node = SafeU32(sel, 0x1F0u);
        if (node >= 0x10000u && node <= 0x7FFFFFFFu)
        {
            unit = SafeU32(node, 8u);
            if (unit >= 0x10000u && unit <= 0x7FFFFFFFu) return unit;
        }

        node = SafeU32(sel, 0x08u);
        if (node >= 0x10000u && node <= 0x7FFFFFFFu)
        {
            unit = SafeU32(node, 8u);
            if (unit >= 0x10000u && unit <= 0x7FFFFFFFu)
            {
                if (usedAlt) *usedAlt = 1;
                return unit;
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        unit = 0;
    }
    return unit;
}

/* ---- R：记录当前选中的单位（统计清零，之后一直跟它） ----
   v11：选中/选不中都�?*本机消息�?*给一句提示（DdhToast，只本机可见，不进公共聊天）�?*/
static void DdhDoRecord(void)
{
    int usedAlt = 0;
    const uint32_t unit = DdhReadSelection(&usedAlt);
    if (!unit)
    {
        if (InterlockedIncrement(&g_ddhHkFailLogged) <= 10)
            LogLine("热键：Ctrl+Alt+R 没取到选中单位（选区链为空：先左键点一个单位再按）");

        char msg[256] = { 0 };
        DdhAppendLabel(msg, sizeof(msg), "【未选中】先左键点一个单位，再按 Ctrl+Alt+R");
        DdhToast(msg);
        return;
    }

    const uint32_t code = SafeCode(unit);
    const uint32_t oldUnit = g_ddhTrack.unit;
    const uint32_t oldHits = g_ddhTrack.hits;

    memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
    g_ddhTrack.unit    = unit;
    g_ddhTrack.code    = code;
    g_ddhTrack.startMs = GetTickCount();

    char label[96] = { 0 };
    DdhUnitLabel(unit, code, label, sizeof(label));
    strncpy_s(g_ddhTrack.label, sizeof(g_ddhTrack.label), label, _TRUNCATE);

    if (InterlockedIncrement(&g_ddhHkActionLogged) <= 40)
        LogLine("热键：Ctrl+Alt+R 已记录 %s 0x%08X（%s链；%s）",
                label, unit,
                usedAlt ? "备用 sel+0x08" : "sel+0x1F0",
                oldUnit ? "旧的记录已替换、统计清零" : "新记录");

    /* 本机消息区提示（名字按原字节拼，别再转码�?*/
    {
        char msg[256] = { 0 };
        DdhAppendLabel(msg, sizeof(msg), "【已选中】");
        DdhAppendUnitName(msg, sizeof(msg), label);
        DdhToast(msg);
    }

    float hp = 0.0f;
    if (ReadUnitHp(unit, &hp))
    {
        if (hp <= 0.0f)
            LogLine("热键：记录单位当前血量 %.2f（已死亡/空壳），统计要等它复活后才有数据", (double)hp);
        else
            LogLine("热键：记录单位当前血量 %.2f（开始累计它的受击）", (double)hp);
    }
    else
    {
        LogLine("热键：记录单位当前血量读不到（句柄管理器/引擎访问器都没通过），统计可能全 0");
    }

    if (oldUnit && oldUnit != unit && oldHits > 0)
        LogLine("热键：上一个记录单位 0x%08X 的 %u 次受击统计已丢弃", oldUnit, (unsigned)oldHits);
}

/* ---- S：自动发送开关（统计照旧，只是不再发�?----
   v11：开/关都在本机消息区提示一句（只本机可见，不进公共聊天）�?*/
static void DdhDoToggle(void)
{
    const LONG cur = InterlockedCompareExchange(&g_ddhAutoSend, 0, 0);
    const LONG now = cur ? 0 : 1;
    InterlockedExchange(&g_ddhAutoSend, now);

    if (InterlockedIncrement(&g_ddhHkToggleLogged) <= 40)
        LogLine("热键：自动发送=%s（统计照常，%s）", now ? "开" : "关", now ? "死亡时会发结算" : "死亡时不再发");

    char msg[256] = { 0 };
    if (now) DdhAppendLabel(msg, sizeof(msg), "【已开启】死亡结算会自动发送");
    else     DdhAppendLabel(msg, sizeof(msg), "【已取消】死亡结算不再自动发送");
    DdhToast(msg);
}

/* ---- Q：立即发一条当前来源占比（【当前伤害】…） ---- */
static void DdhDoQuery(void)
{
    char text[768] = { 0 };
    g_msgNameRawUtf8 = 0;
    g_msgNameGbkFallback = 0;
    if (g_ddhTrack.unit)
    {
        DdhBuildTrackText(text, sizeof(text), 0);
        /* 刚记上还没打中过：给一句短的，别让 Q 看起来像没反�?*/
        if (!text[0]) DdhAppendLabel(text, sizeof(text), "【当前伤害】暂无");
    }
    else
    {
        DdhBuildGlobalTop5(text, sizeof(text));
    }

    if (!text[0])
    {
        LogLine("Q 统计：没有可发的统计（既没有记录单位，也还没统计到伤害）");
        return;
    }

    if (InterlockedIncrement(&g_ddhHkQueryLogged) <= 40)
    {
        LogLine("Q 统计：%s", text);
    }

    DdhDeliverText(text);
}

/* 待办热键（只在游戏线程调用） */
static void DdhProcessPending(void)
{
    if (InterlockedExchange(&g_ddhPendR, 0)) DdhDoRecord();
    if (InterlockedExchange(&g_ddhPendS, 0)) DdhDoToggle();
    if (InterlockedExchange(&g_ddhPendQ, 0)) DdhDoQuery();
    if (InterlockedExchange(&g_ddhPendC, 0)) DdhChartDebugShow();
    if (InterlockedExchange(&g_ddhPendD, 0)) DdhChartDemoShow();
    if (InterlockedExchange(&g_ddhPendE, 0)) DdhChartToggleView();
    /* v10：顺手处理单位属性请�?—�?DdhDamageFunc 最外层返回时会走这里，
       所以没有游戏窗�?/ 热键线程没起来时属性也能刷新（假魔兽冒烟就靠它）�?*/
    DdhProcessAttrRequest();
    /* v15：游戏内阵亡面板 / 英雄查询同样只在游戏线程处理；TTL 兜底也在这里跑�?*/
    __try { DdhProcessPanelRequest(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("面板：处理请求异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
    }
    __try { DdhProcessHeroRequest(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("面板：处理英雄查询异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
    }
    __try { DdhPanelTick(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("面板：TTL 处理异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
    }
}

/* ---------------------------------------------------------------------------
   v12：热�?-> 游戏线程 的“窗口消息通道�?
   ---------------------------------------------------------------------------
   为什么要有它：热键动作必须调引擎（读选区内存、ResolveName、DisplayTimedTextToPlayer�?
   直投聊天），这些都只能在游戏线程上跑；而热键是注册在一个独立线程上的�?
   以前只能借“下一次伤害事件”当执行�?—�?没人挨打就一直不响应（用户反馈的延迟）�?
   现在照插�?UDamageWatcherHook.cpp 的同款做法：
     · 热键线程 PostMessage(游戏窗口, WM_APP+0xDD)�?
     · 窗口过程被我们子类化（SetWindowLongPtrW），消息就在**游戏线程**的消息循环里
       派发，当场执�?DdhProcessPending() —�?按完即出提示（毫秒级）�?
   · 游戏切分辨率/全屏/重开窗口时会把窗口过程改回去 �?每次投递前校验并自动重挂�?
   · DLL 卸载（DllMain DETACH）必须把窗口过程还回去，否则窗口还指着已卸载的代码�?
   --------------------------------------------------------------------------- */
#define DDH_WM_HOTKEY (WM_APP + 0xDD)
/* v10：属性请求通道。热键线程每 100ms 看一眼请求序号，有新请求就投这条消息�?
   游戏窗口过程在游戏线程里当场处理（和热键同一条通道，绝不跨线程�?JASS）�?*/
#define DDH_WM_ATTR   (WM_APP + 0xDE)
/* v15：游戏内面板 / 英雄查询通道（同样由热键线程 100ms 轮询序号后投递）�?*/
#define DDH_WM_PANEL  (WM_APP + 0xDF)
#define DDH_WM_HERO   (WM_APP + 0xE0)
#define DDH_WM_PANEL_TICK (WM_APP + 0xE1)
#define DDH_WM_SELF_PANEL (WM_APP + 0xE2)
#define DDH_WM_OVERLAY_CLICK (WM_APP + 0xE3)
#define DDH_WM_CURSOR_STATE  (WM_APP + 0xE4)
#define DDH_WM_DAMAGE_DEFERRED (WM_APP + 0xE5)
static void DdhProcessDeferred(void);

static WNDPROC g_prevWndProc = NULL;
static volatile LONG g_wndLogCount = 0;
static volatile LONG g_wndCand     = 0;   /* 上次枚举到几个“本进程的可见窗口”（诊断用） */
static char    g_wndClass[64] = { 0 };    /* 选中的窗口类名（诊断用） */
static char    g_wndTitle[96] = { 0 };    /* 选中的窗口标题（诊断用） */
static int     g_wndUnicode  = 0;         /* 1 = 这个窗口�?Unicode（W 版）�? = ANSI（A 版） */

/* 覆盖层窗口在它自己的窗口过程里只投递请求；HTML 窗口和游戏帧操作都由
   游戏窗口线程执行。 */
extern "C" void DdhOverlayRequestButtonClick(void)
{
    if (g_gameWnd && IsWindow(g_gameWnd))
        PostMessageA(g_gameWnd, DDH_WM_OVERLAY_CLICK, 0, 0);
}

extern "C" void DdhOverlayRequestCursor(int over)
{
    if (g_gameWnd && IsWindow(g_gameWnd))
        PostMessageA(g_gameWnd, DDH_WM_CURSOR_STATE, over ? 1u : 0u, 0);
}

struct DdhWndPick { int score; long area; };

/* 枚举本进程可见窗口挑游戏窗口。规则（真机踩过的坑都写在这）：
     · 跳过 conhost 的控制台窗口（ConsoleWindowClass）—�?它的窗口过程改不�?
       （SetWindowLongPtr 返回 0 + err=5），早期版本就是挑中它才“挂不上窗口”；
     · 优先 类名 == "Warcraft III"（真魔兽）；其次标题里带 Warcraft/魔兽�?
     · 同档里取面积最大的（全屏时就是游戏窗口）�?*/
static BOOL CALLBACK DdhEnumWndProc(HWND hwnd, LPARAM lp)
{
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid != GetCurrentProcessId() || !IsWindowVisible(hwnd)) return TRUE;
    InterlockedIncrement(&g_wndCand);

    char cls[64] = { 0 };
    char title[128] = { 0 };
    GetClassNameA(hwnd, cls, sizeof(cls));
    GetWindowTextA(hwnd, title, sizeof(title));
    if (_stricmp(cls, "ConsoleWindowClass") == 0) return TRUE;

    RECT r = { 0, 0, 0, 0 };
    if (!GetWindowRect(hwnd, &r)) return TRUE;
    const long area = (long)(r.right - r.left) * (long)(r.bottom - r.top);

    int score = 0;
    if (_stricmp(cls, "Warcraft III") == 0)             score = 3;
    else if (strstr(title, "Warcraft") || strstr(title, "魔兽")) score = 2;

    DdhWndPick* pick = (DdhWndPick*)lp;
    if (score > pick->score || (score == pick->score && area > pick->area))
    {
        pick->score = score;
        pick->area  = area;
        g_gameWnd   = hwnd;
        strncpy_s(g_wndClass, sizeof(g_wndClass), cls, _TRUNCATE);
        strncpy_s(g_wndTitle, sizeof(g_wndTitle), title, _TRUNCATE);
    }
    return TRUE;
}

/* 图表右上角伸缩按钮。按钮的绘制坐标仍使用 UI 坐标（0.8 x 0.6），
   但鼠标点击必须按背景帧布局后的真实像素矩形换算，不能再假设客户区正好
   等于虚拟 UI 画布。窗口非 4:3、带黑边或 UI 缩放时，旧换算会把按钮点偏。 */
static int DdhChartToggleHitTest(int x, int y)
{
    if (!g_ddhChartMode) return 0;

    const float uiL = g_ddhChartX + g_ddhChartW - 0.055f;
    const float uiR = g_ddhChartX + g_ddhChartW + 0.012f;
    const float uiT = g_ddhChartY + 0.020f;
    const float uiB = g_ddhChartY - 0.042f;

    int l = 0, r = 0, t = 0, b = 0;
    if (g_ddhPanelFrameRectOk && g_ddhPanelHitW > 0.0f && g_ddhPanelHitH > 0.0f)
    {
        const float fw = g_ddhPanelFrameR - g_ddhPanelFrameL;
        const float fh = g_ddhPanelFrameB - g_ddhPanelFrameT;
        l = (int)(g_ddhPanelFrameL + (uiL - g_ddhPanelHitL) / g_ddhPanelHitW * fw);
        r = (int)(g_ddhPanelFrameL + (uiR - g_ddhPanelHitL) / g_ddhPanelHitW * fw);
        t = (int)(g_ddhPanelFrameT + (g_ddhPanelHitT - uiT) / g_ddhPanelHitH * fh);
        b = (int)(g_ddhPanelFrameT + (g_ddhPanelHitT - uiB) / g_ddhPanelHitH * fh);
    }
    else
    {
        RECT rc = { 0 };
        if (!g_gameWnd || !GetClientRect(g_gameWnd, &rc) ||
            rc.right <= rc.left || rc.bottom <= rc.top)
            return 0;
        const float cw = (float)(rc.right - rc.left);
        const float ch = (float)(rc.bottom - rc.top);
        /* 魔兽 UI 坐标是左上原点：横向 0..0.8，纵向 0..-0.6。
           不能按屏幕中心原点换算，否则整个命中区会向右下偏。 */
        l = (int)(uiL * 1.25f * cw);
        r = (int)(uiR * 1.25f * cw);
        t = (int)(-uiT * (1.0f / 0.6f) * ch);
        b = (int)(-uiB * (1.0f / 0.6f) * ch);
    }

    /* 按钮本身约 50x40 像素；再向外放 4 像素，照顾贴近图标边缘的点击。 */
    return x >= l - 4 && x < r + 4 && y >= t - 4 && y < b + 4;
}

/* v17：鼠标命中测试。优先用背景帧布局后的实际矩形（若可读），否则用归一化矩形（默认左上锚点）�?*/
static int DdhPanelHitTest(int x, int y)
{
    if (!g_ddhPanelClickOk) return 0;
    RECT rc = { 0 };
    if (!g_gameWnd || !GetClientRect(g_gameWnd, &rc)) return 0;
    const int cw = rc.right - rc.left;
    const int ch = rc.bottom - rc.top;
    if (cw <= 0 || ch <= 0) return 0;

    /* 按钮优先于面板背景命中：收缩/展开后背景帧被重排，按钮区域在重排后的
       第一帧就可能已经可点，不能等背景矩形缓存更新后才生效。 */
    if (DdhChartToggleHitTest(x, y)) return 1;

    if (g_ddhPanelFrameRectOk)
    {
        const int l = max(0, min(cw - 1, (int)g_ddhPanelFrameL));
        const int t = max(0, min(ch - 1, (int)g_ddhPanelFrameT));
        const int r = max(l + 1, min(cw, (int)g_ddhPanelFrameR));
        const int b = max(t + 1, min(ch, (int)g_ddhPanelFrameB));
        if (InterlockedIncrement(&g_ddhPanelClickLogged) <= 12)
            LogLine("图表点击：帧矩形(裁到客户区) (%d,%d)-(%d,%d) 鼠标(%d,%d)",
                    l, t, r, b, x, y);
        return x >= l && x < r && y >= t && y < b;
    }

    if (g_ddhChartMode)
    {
        const int l2 = (int)((g_ddhChartX - 0.012f) * 1.25f * (float)cw);
        const int t2 = (int)(-(g_ddhChartY + 0.012f) * (1.0f / 0.6f) * (float)ch);
        const int r2 = (int)((g_ddhChartX - 0.012f + g_ddhChartW + 0.024f) * 1.25f * (float)cw);
        const int b2 = (int)((-(g_ddhChartY + 0.012f) + g_ddhChartH + 0.024f) * (1.0f / 0.6f) * (float)ch);
        return x >= l2 && x < r2 && y >= t2 && y < b2;
    }
    if (!(g_ddhPanelHitW > 0.0f && g_ddhPanelHitH > 0.0f)) return 0;
    const int l = (int)(g_ddhPanelHitL * (float)cw);
    const int t = (int)(-g_ddhPanelHitT * (float)ch);
    const int r = (int)((g_ddhPanelHitL + g_ddhPanelHitW) * (float)cw);
    const int b = (int)((-g_ddhPanelHitT + g_ddhPanelHitH) * (float)ch);
    if (InterlockedIncrement(&g_ddhPanelClickLogged) <= 8)
        LogLine("面板点击：归一化命中区 (%d,%d)-(%d,%d) 鼠标(%d,%d) 客户区 %dx%d", l, t, r, b, x, y, cw, ch);
    return x >= l && x < r && y >= t && y < b;
}

static LRESULT CALLBACK DdhGameWndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
    if (msg == WM_LBUTTONDOWN && g_ddhChartMode &&
        InterlockedIncrement(&g_ddhMouseMsgLogged) <= 16)
    {
        LogLine("图表鼠标：窗口收到左键 (%d,%d) 覆盖层打开=%d",
                (int)(short)LOWORD(lp), (int)(short)HIWORD(lp),
                DdhImGuiActive());
    }

    __try
    {
        if (DdhImGuiWndProc(hwnd, msg, wp, lp)) return 0;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }

    if (msg == DDH_WM_DAMAGE_DEFERRED)
    {
        __try { DdhProcessDeferred(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("Damage deferred processing failed: %08X", (unsigned)GetExceptionCode());
        }
        return 0;
    }

    if (msg == DDH_WM_HOTKEY)
    {
        /* 这个回调就在游戏线程上，引擎调用是安全的（和插件 OnHotkeyGameThread 同款�?*/
        __try { DdhProcessPending(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("热键：处理待办异常 code=%08X（已吞掉，不影响伤害钩子）", (unsigned)GetExceptionCode());
        }
        return 0;
    }

    if (msg == DDH_WM_OVERLAY_CLICK)
    {
        __try { DdhButtonClick(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("覆盖层按钮：处理点击异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
        }
        return 0;
    }

    if (msg == DDH_WM_CURSOR_STATE)
    {
        DdhApplyCursorOver((int)(wp & 1u), 1);
        return 0;
    }

    /* v10：C# 的【战场单位】页有新请求 —�?就在游戏线程上解析属性（JASS 只能在这里调�?*/
    if (msg == DDH_WM_ATTR)
    {
        __try { DdhProcessAttrRequest(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("ATTR wnd 处理请求异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
        }
        return 0;
    }

    /* v15：C# 的阵亡面�?/ 英雄查询请求 —�?同样只在游戏线程动引�?UI / JASS�?*/
    if (msg == DDH_WM_SELF_PANEL)
    {
        /* 自建阵亡总结：在窗口线程写块并应用，绝不在伤害钩子里建 UI 帧。 */
        __try { DdhSelfPanelShow(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("阵亡总结 wnd 异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
        }
        __try { DdhProcessPanelRequest(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        return 0;
    }

    if (msg == DDH_WM_PANEL)
    {
        __try { DdhProcessPanelRequest(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("面板 wnd 处理请求异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
        }
        __try { DdhPanelTick(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        return 0;
    }
    if (msg == DDH_WM_HERO)
    {
        __try { DdhProcessHeroRequest(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("面板 wnd 处理英雄查询异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
        }
        return 0;
    }
    if (msg == DDH_WM_PANEL_TICK)
    {
        __try { DdhPanelTick(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        return 0;
    }

    /* `~` 显隐：键�?`~`（VK_OEM_3）显�?隐藏面板。只有“真的有面板可切”时才吞键，
       其余情况原样转发，避免抢掉用户给 `~` 绑的其他功能�?
       注意：本函数在游戏线程；TranslateMessage 已经跑过，吞 WM_KEYDOWN 不会影响聊天字符�?*/
    if (msg == WM_KEYDOWN && (UINT)wp == VK_OEM_3 && (lp & 0x40000000L) == 0)
    {
        int handled = 0;
        __try { handled = DdhDoToggleVisible(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("面板：~ 切换异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
        }
        if (handled) return 0;
    }

    /* ESC：展开态下直接收缩面板（收缩态不拦截，保留游戏菜单） */
    if (msg == WM_KEYDOWN && (UINT)wp == VK_ESCAPE && DdhChartEscCollapse())
        return 0;

    const int imguiActive = DdhImGuiActive();

    /* v17：鼠标左键点整块面板展开/收起；命中时吞掉消息，避免选中地面/移动�?
       面板隐藏/点在面板外时完全不动，原样转发�?*/
    /* 覆盖层 S1：命中优先于引擎帧按钮 */
    if (!imguiActive && msg == WM_LBUTTONDOWN)
    {
        const int ox = (int)(short)LOWORD(lp), oy = (int)(short)HIWORD(lp);
        if (DdhOverlayHitTest(ox, oy)) { DdhOverlaySetMouseDown(1); return 0; }
    }
    else if (!imguiActive && msg == WM_LBUTTONUP)
    {
        if (DdhOverlayMouseDown())
        {
            const int ox = (int)(short)LOWORD(lp), oy = (int)(short)HIWORD(lp);
            const int inside = DdhOverlayHitTest(ox, oy);
            DdhOverlaySetMouseDown(0);
            if (inside)
            {
                __try { DdhOverlayToggle(); }
                __except (EXCEPTION_EXECUTE_HANDLER) { }
            }
            return 0;
        }
    }

    /* v28：游戏内【死亡结算】按钮的点击。按钮很小，先判它再判面板；
       命中就吞掉，避免同一次点击又落到地面/技能上。 */
    if (!imguiActive && msg == WM_LBUTTONDOWN)
    {
        const int bx = (int)(short)LOWORD(lp);
        const int by = (int)(short)HIWORD(lp);
        if (DdhButtonHitTest(bx, by))
        {
            g_ddhBtnMouseDown = 1;
            DdhButtonSetTextColor(0xFFFFFFFFu);   /* 按下变白，松手恢复金色 */
            return 0;
        }
    }
    else if (!imguiActive && msg == WM_LBUTTONUP)
    {
        if (g_ddhBtnMouseDown)
        {
            const int bx = (int)(short)LOWORD(lp);
            const int by = (int)(short)HIWORD(lp);
            const int inside = DdhButtonHitTest(bx, by);
            g_ddhBtnMouseDown = 0;
            if (inside) DdhButtonClick();
            else DdhButtonSetTextColor(0xFFFFCC66u);
            return 0;
        }
    }
    else if (!imguiActive && msg == WM_LBUTTONDBLCLK)
    {
        const int bx = (int)(short)LOWORD(lp);
        const int by = (int)(short)HIWORD(lp);
        if (DdhButtonHitTest(bx, by))
        {
            g_ddhBtnMouseDown = 1;   /* 让随后的 up 也被吞掉 */
            return 0;
        }
    }

    /* 阵亡面板保留魔兽自己的软件鼠标，不切换成 Windows 系统箭头。
       只有真正的 ImGui/HTML 覆盖层需要系统光标时才接管。 */
    if (!imguiActive && msg == WM_MOUSEMOVE)
    {
        int overlayOver = 0;
        __try { overlayOver = DdhOverlayCursorOver(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { overlayOver = 0; }
        if (overlayOver)
        {
            DdhApplyCursorOver(1, 1);
            SetCursor(LoadCursorW(NULL, (LPCWSTR)IDC_ARROW));
            return 0;
        }
        if (g_ddhCursorOver) DdhApplyCursorOver(0, 1);
    }

    /* WM_SETCURSOR：只有覆盖层区域接管系统光标；阵亡面板完全交给游戏。 */
    if (!imguiActive && msg == WM_SETCURSOR)
    {
        int overlayOver = 0;
        __try
        {
            POINT p = { 0, 0 };
            if (GetCursorPos(&p) && ScreenToClient(hwnd, &p))
                overlayOver = DdhOverlayCursorOver();
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { overlayOver = 0; }
        if (overlayOver)
        {
            DdhApplyCursorOver(1, 1);
            SetCursor(LoadCursorW(NULL, (LPCWSTR)IDC_ARROW));
            return TRUE;
        }
        if (g_ddhCursorOver) DdhApplyCursorOver(0, 1);
    }

    /* 分层覆盖层不是游戏子窗口，拖动/缩放魔兽时不会自动跟随。
       在窗口位置变化消息里立刻重算屏幕坐标，而不是等下一次 swap。 */
    if (msg == WM_MOVE || msg == WM_SIZE || msg == WM_WINDOWPOSCHANGED)
    {
        __try { DdhOverlaySyncPosition(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
    if (!imguiActive && msg == WM_LBUTTONDOWN)
    {
        const int x = (int)(short)LOWORD(lp);
        const int y = (int)(short)HIWORD(lp);
        if (DdhPanelHitTest(x, y))
        {
            g_ddhPanelMouseDown = 1;
            return 0;
        }
    }
    else if (!imguiActive && msg == WM_LBUTTONUP)
    {
        if (g_ddhPanelMouseDown)
        {
            const int x = (int)(short)LOWORD(lp);
            const int y = (int)(short)HIWORD(lp);
            const int inside = DdhPanelHitTest(x, y);
            g_ddhPanelMouseDown = 0;
            if (inside)
            {
                const DWORD now = GetTickCount();
                if ((DWORD)(now - (DWORD)g_ddhPanelLastToggle) >= 80)
                {
                    g_ddhPanelLastToggle = (LONG)now;
                    DdhPanelClickAt(x, y);   /* 图表模式：点柱子下钻/返回；文本模式：展开/收起 */
                }
            }
            return 0;
        }
    }
    else if (!imguiActive && msg == WM_LBUTTONDBLCLK)
    {
        const int x = (int)(short)LOWORD(lp);
        const int y = (int)(short)HIWORD(lp);
        if (DdhPanelHitTest(x, y))
        {
            g_ddhPanelMouseDown = 1;   /* 让随后的 up 也被吞掉（去抖阻止二次切换） */
            return 0;
        }
    }

    /* 其它消息一律原样转给游戏自己的窗口过程，绝不吞�?
       注意 A/W 必须配对：魔�?1.27 的窗口是 ANSI 类（RegisterClassA），�?CallWindowProcW
       转发会把 WM_CHAR / WM_SETTEXT 之类�?Unicode 解释，轻则聊天输入错乱、重则崩游戏�?*/
    if (g_prevWndProc)
        return g_wndUnicode ? CallWindowProcW(g_prevWndProc, hwnd, msg, wp, lp)
                            : CallWindowProcA(g_prevWndProc, hwnd, msg, wp, lp);
    return g_wndUnicode ? DefWindowProcW(hwnd, msg, wp, lp)
                        : DefWindowProcA(hwnd, msg, wp, lp);
}

/* 找到（或重新找到）游戏窗口并挂上我们的窗口过程。返�?1 = 可用�?*/
static int DdhEnsureGameWnd(void)
{
    if (g_gameWnd && IsWindow(g_gameWnd))
    {
        if (g_prevWndProc &&
            GetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC) != (LONG_PTR)DdhGameWndProc)
        {
            /* 游戏自己把窗口过程改回去了（切分辨率/全屏/重开窗口）→ 重新挂上 */
            g_wndUnicode = IsWindowUnicode(g_gameWnd) ? 1 : 0;
            g_prevWndProc = g_wndUnicode
                ? (WNDPROC)SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc)
                : (WNDPROC)SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc);
            if (InterlockedIncrement(&g_wndLogCount) <= 8)
                LogLine("热键：窗口过程被游戏改回，已重新挂上（窗口 %p）", (void*)g_gameWnd);
        }
        return g_prevWndProc ? 1 : 0;
    }

    g_gameWnd = NULL;
    g_prevWndProc = NULL;
    g_wndCand = 0;
    DdhWndPick pick;
    pick.score = -1;          /* -1 保证第一个候选（哪�?score=0）一定被选中 */
    pick.area  = -1;
    EnumWindows(DdhEnumWndProc, (LPARAM)&pick);
    if (!g_gameWnd)
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("热键：没找到可挂的游戏窗口（本进程可见窗口 %d 个，最后一个 %s「%s」；控制台窗口会被跳过）",
                    (int)g_wndCand, g_wndClass, g_wndTitle);
        return 0;
    }

    g_wndUnicode = IsWindowUnicode(g_gameWnd) ? 1 : 0;
    g_prevWndProc = g_wndUnicode
        ? (WNDPROC)SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc)
        : (WNDPROC)SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc);
    if (g_gameWnd && InterlockedExchange(&g_ddhOverlayInitTried, 1) == 0)
    {
        __try { DdhImGuiInit(g_gameWnd); }
        __except (EXCEPTION_EXECUTE_HANDLER) { LogLine("ImGui init exception (swallowed)"); }
    }
    if (!g_prevWndProc)
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("热键：SetWindowLongPtrW 失败（窗口 %p 类=%s「%s」err=%lu），热键只能等伤害事件",
                    (void*)g_gameWnd, g_wndClass, g_wndTitle, GetLastError());
        g_gameWnd = NULL;
        return 0;
    }

    if (InterlockedIncrement(&g_wndLogCount) <= 8)
        LogLine("热键：已挂到游戏窗口 %p（类=%s「%s」，%s 版），动作会立刻在游戏线程执行（不再等伤害事件）",
                (void*)g_gameWnd, g_wndClass, g_wndTitle, g_wndUnicode ? "Unicode/W" : "ANSI/A");
    return 1;
}

/* 热键线程用：把“该处理待办了”立刻投给游戏线程；失败就退回旧的伤害事件路径�?*/
static void DdhPostHotkeyToGame(void)
{
    if (!DdhEnsureGameWnd())
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("热键：没找到游戏窗口，本次动作退化为“下一次伤害事件时处理”（有延迟）");
        return;
    }
    if (!PostMessageW(g_gameWnd, DDH_WM_HOTKEY, 0, 0))
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("热键：PostMessage 失败 err=%lu（退回伤害事件处理，有延迟）", GetLastError());
    }
}

/* 热键线程�?100ms 调一次：C# 那边有新的属性请求就 PostMessage 给游戏窗口，
   由窗口过程在游戏线程上处理（JASS native 只能在这里调）�?*/
static void DdhMaybePostAttrRequest(void)
{
#if DDH_ENABLE_BATTLEFIELD_UNITS
    if (!g_shm) return;
    const uint32_t req = g_shm->attrs.requestSeq;
    if (!req || req == g_ddhAttrPostedSeq) return;
    if (!DdhEnsureGameWnd()) return;                 /* 没窗口：等伤害事件兜�?*/
    if (PostMessageW(g_gameWnd, DDH_WM_ATTR, 0, 0)) g_ddhAttrPostedSeq = req;
#endif
}

/* DLL 卸载时把窗口过程还回去；游戏还活着的窗口不还，就会“跳到已卸载的模块”崩溃�?*/
static void DdhRestoreGameWnd(void)
{
    if (g_gameWnd && g_prevWndProc && IsWindow(g_gameWnd) &&
        GetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC) == (LONG_PTR)DdhGameWndProc)
    {
        if (g_wndUnicode) SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)g_prevWndProc);
        else              SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)g_prevWndProc);
        LogLine("热键：窗口过程已还原（DLL 卸载）");
    }
    g_gameWnd = NULL;
    g_prevWndProc = NULL;
}

/* 最外层伤害函数退出后执行：先发排队中的死亡结算，再处理热键待办�?
   全程 __try —�?任何一步抛异常都只写日志，绝不影响伤害钩子本身�?*/
static void DdhProcessDeferred(void)
{
    /* GetLocalPlayer/GetPlayerId 只能在游戏线程调用。即使单位属性扫描已关闭，
       阵亡总结仍需要这个真实本地玩家号，因此每次最外层伤害退出时尝试一次，
       成功以后 g_allyMaskDone 会把后续调用短路。 */
    __try { DdhComputeAllyMask(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("本地玩家探测异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
    }

    __try
    {
        if (InterlockedExchange(&g_ddhDeferKind, 0) != 0)
        {
            if (InterlockedCompareExchange(&g_ddhAutoSend, 0, 0) == 0)
            {
                if (InterlockedIncrement(&g_ddhSendSkipLogged) <= 10)
                    LogLine("结算广播：自动发送=关，本次不发送（长度 %u；统计仍在继续）",
                            (unsigned)strlen(g_ddhDeferText));
            }
            else
            {
                DdhDeliverText(g_ddhDeferText);
            }
            g_ddhDeferText[0] = 0;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("结算广播失败：处理待发结算异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
    }

    __try
    {
        DdhProcessPending();
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("热键：处理待办异常 code=%08X（已吞掉，不影响伤害钩子）", (unsigned)GetExceptionCode());
    }

    /* v15：首次最外层伤害退出后（游戏线程）显示 demo 面板，便于真机验证字�?坐标�?*/
    if (g_selfPanelPending)
    {
        g_selfPanelPending = 0;
        /* 不能在伤害钩子里直接建图表帧：交给游戏窗口线程（WndProc）去写/应用。 */
        if (g_gameWnd) PostMessageW(g_gameWnd, (UINT)(WM_APP + 0xE2), 0, 0);
    }

    __try { DdhPanelDemoOnce(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("面板 demo 异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
    }
}

/* ===========================================================================
   v15：游戏内阵亡面板（WFE 方案：借引�?CTextFrame 显示�?
   ---------------------------------------------------------------------------
   只在**游戏线程**动引擎。共享内存只负责�?C# 组好的行搬进来：
     PanelBlock.seq 变化 -> 拷出内容 -> appliedSeq -> 游戏线程�?复用文字�?
     -> SetFont / SetText / SetTextColor / SetPoint / Show -> TTL 到点 Hide�?
   失败链：入口校验失败 -> DisplayTimedTextToPlayer 兜底 -> 只写日志�?
   1.27 RVA 已用 capstone �?C:\3rd\war5\game.dll 逐条复核（见 WFE-UI-修改原理.md）�?
   =========================================================================== */

#define DDH_RVA_UI_GET_GAME   0x34F3A0u   /* CGameUI* GetGameUI(recreate, release) */
#define DDH_RVA_UI_CREATE_TEXT 0xA9560u   /* CTextFrame* (parent, 0, 0) */
#define DDH_RVA_UI_SET_FONT   0x9CE60u    /* (frame, name, float height, flags) */
#define DDH_RVA_UI_SET_FONTFLAGS 0xA93E0u /* (frame, uint32 fontFlags)：引擎建文字帧后�?0x3008 */
#define DDH_RVA_UI_SET_TEXT   0xAA130u    /* (frame, const char* utf8) */
#define DDH_RVA_UI_SET_COLOR  0xAA210u    /* (frame, const uint32_t* argb) */
#define DDH_RVA_UI_SET_POINT  0xBD8A0u    /* (layout, anchor, rel, relAnchor, x, y, flag) */
#define DDH_RVA_UI_CREATE_BACKDROP 0x8E700u /* CBackdropFrame* (parent, 0, 0)；CBackdropFrame 构�?0xA4700 */
#define DDH_RVA_UI_SET_BACKDROP   0xA62A0u  /* (frame, bgPath, blend, texFlag, edgePath, mirror) */
#define DDH_OFF_UI_LAYOUT_SUB 0xB4u       /* CFrame 的布局子对象偏�?*/
#define DDH_OFF_GAME_CURSOR_FRAME 0x16Cu  /* CGameUI 持有的 CCursorFrame 指针 */

#define DDH_PANEL_BG_DEFAULT      "UI\\widgets\\BattleNet\\bnet-tooltip-background.blp"
#define DDH_PANEL_BG_EDGE_DEFAULT "UI\\widgets\\BattleNet\\bnet-tooltip-border.blp"

typedef uint32_t (__fastcall *fn_ui_getgame_t)(uint32_t, uint32_t);
typedef uint32_t (__fastcall *fn_ui_create_text_t)(uint32_t, uint32_t, uint32_t);
typedef uint32_t (__fastcall *fn_ui_create_backdrop_t)(uint32_t, uint32_t, uint32_t);
typedef void     (__fastcall *fn_ui_set_font_t)(void*, void*, const char*, float, uint32_t);
typedef void     (__fastcall *fn_ui_set_fontflags_t)(void*, void*, uint32_t);
typedef void     (__fastcall *fn_ui_set_text_t)(void*, void*, const char*);
typedef void     (__fastcall *fn_ui_set_color_t)(void*, void*, const uint32_t*);
typedef void     (__fastcall *fn_ui_setpoint_t)(void*, void*, uint32_t, uint32_t, uint32_t, float, float, uint32_t);
typedef void     (__fastcall *fn_ui_setbackdrop_t)(void*, void*, const char*, uint32_t, uint32_t, const char*, uint32_t);

static uint32_t       g_ddhUiGetGame   = 0;
static uint32_t       g_ddhUiCreateText= 0;
static uint32_t       g_ddhUiCreateBackdrop = 0;
static uint32_t       g_ddhUiSetFont   = 0;
static uint32_t       g_ddhUiSetFontFlags = 0;
static uint32_t       g_ddhUiSetText   = 0;
static uint32_t       g_ddhUiSetColor  = 0;
static uint32_t       g_ddhUiSetPoint  = 0;
static uint32_t       g_ddhUiSetBackdrop = 0;
static volatile LONG  g_ddhUiInitDone  = 0;
static volatile LONG  g_ddhUiBroken    = 0;
static volatile LONG  g_ddhUiBrokenLogged = 0;

static uint32_t       g_ddhPanelUi     = 0;
static uint32_t       g_ddhPanelFrames[DDH_PANEL_MAX_LINES];
static int            g_ddhPanelFrameCount = 0;
static uint32_t       g_ddhPanelBgFrame = 0;
static uint32_t       g_ddhPanelIconFrames[DDH_ICON_MAX];
static uint32_t       g_ddhPanelIconCodes[DDH_ICON_MAX];
static uint32_t       g_ddhPanelIconAddrs[DDH_ICON_MAX];
static uint32_t       g_ddhPanelIconLines[DDH_ICON_MAX];
static char           g_ddhPanelIconPaths[DDH_ICON_MAX][128];
static int            g_ddhPanelIconCount = 0;
static volatile LONG  g_ddhPanelIconLogged = 0;
static volatile LONG  g_ddhPanelIconReqLogged = 0;
static volatile LONG  g_ddhAvatarSummaryLogged = 0;
static volatile LONG  g_ddhPanelIconFramesFailed = 0;
static volatile LONG  g_ddhPanelBgTextured = 0;
struct DdhIconCacheEntry
{
    uint32_t code;
    int      state;         /* 0=未查 1=有路�?-1=无路�?*/
    char     path[128];
};
static DdhIconCacheEntry g_ddhIconCache[32];
static int g_ddhIconCacheCount = 0;
static volatile LONG  g_ddhPanelShown  = 0;
static volatile LONG  g_ddhPanelHideAt = 0;
static volatile LONG  g_ddhPanelAppliedSeq = 0;
static volatile LONG  g_ddhPanelPostedSeq  = 0;
static volatile LONG  g_ddhHeroAppliedSeq  = 0;
static volatile LONG  g_ddhHeroPostedSeq   = 0;
static volatile LONG  g_ddhPanelLogCount = 0;
static volatile LONG  g_ddhPanelGeomLogged = 0;
static volatile LONG  g_ddhHeroLogCount  = 0;
static volatile LONG  g_ddhPanelNoUiLogged = 0;
static volatile LONG  g_ddhPanelBgFailed = 0;
static volatile LONG  g_ddhPanelBgLogged = 0;
static volatile LONG  g_ddhPanelCollapsed = 0;
static volatile LONG  g_ddhPanelCollapsedLines = 3;
static volatile LONG  g_ddhSuppressPanel = 0;   /* v18：本地死亡是镜像/幻象时，面板直接不显�?*/
static volatile LONG  g_ddhPanelTickPost = 0;

static DdhPanelBlock  g_ddhPendingPanel;
/* `~` 显隐：`~` 重新显示用的“上一次面板内容”（C# 发过 SHOW 才有；HIDE/TTL 不清它） */
static DdhPanelBlock  g_ddhLastPanel;
static volatile LONG  g_ddhHaveLastPanel = 0;
static volatile LONG  g_ddhPanelPinned   = 0;   /* 1 = `~` 手动唤出，不�?TTL 自动隐藏 */
static volatile LONG  g_ddhPendingValid = 0;
static volatile LONG  g_ddhPendingTick  = 0;
static volatile LONG  g_ddhPendingPostTick = 0;

static int            g_ddhPanelEnvRead = 0;
static int            g_ddhPanelDisabled = 0;      /* DDH_NO_PANEL=1 */
static int            g_ddhPanelNoSub    = 0;      /* DDH_PANEL_LAYOUT_NO_SUB=1 */
static int            g_ddhPanelNoBg     = 0;      /* DDH_NO_PANEL_BG=1 */
static int            g_ddhPanelNoIcons  = 0;      /* DDH_NO_PANEL_ICONS=1 */
static char           g_ddhPanelFontOverride[DDH_PANEL_FONT_NAME] = { 0 };
static char           g_ddhPanelBgPath[128] = { 0 };
static char           g_ddhPanelBgEdge[128] = { 0 };
static float          g_ddhPanelBgWidth = 0.37f;
static volatile LONG  g_ddhPanelDemoDone = 0;


static int DdhEnvTruthy(const char* name)
{
    char buf[16] = { 0 };
    const DWORD n = GetEnvironmentVariableA(name, buf, (DWORD)sizeof(buf));
    if (n == 0 || n >= (DWORD)sizeof(buf)) return 0;
    return !(_stricmp(buf, "0") == 0 || _stricmp(buf, "false") == 0 ||
             _stricmp(buf, "no") == 0 || _stricmp(buf, "off") == 0);
}

static void DdhPanelReadEnvOnce(void)
{
    if (g_ddhPanelEnvRead) return;
    g_ddhPanelEnvRead = 1;
    g_ddhPanelDisabled = DdhEnvTruthy("DDH_NO_PANEL");
    g_ddhPanelNoSub    = DdhEnvTruthy("DDH_PANEL_LAYOUT_NO_SUB");
    g_ddhPanelNoBg     = DdhEnvTruthy("DDH_NO_PANEL_BG");
    g_ddhPanelNoIcons  = DdhEnvTruthy("DDH_NO_PANEL_ICONS");
    char font[DDH_PANEL_FONT_NAME] = { 0 };
    const DWORD nf = GetEnvironmentVariableA("DDH_PANEL_FONT", font, (DWORD)sizeof(font));
    if (nf > 0 && nf < (DWORD)sizeof(font))
        strncpy_s(g_ddhPanelFontOverride, sizeof(g_ddhPanelFontOverride), font, _TRUNCATE);

    strcpy_s(g_ddhPanelBgPath, sizeof(g_ddhPanelBgPath), DDH_PANEL_BG_DEFAULT);
    strcpy_s(g_ddhPanelBgEdge, sizeof(g_ddhPanelBgEdge), DDH_PANEL_BG_EDGE_DEFAULT);
    char bg[sizeof(g_ddhPanelBgPath)] = { 0 };
    const DWORD nb = GetEnvironmentVariableA("DDH_PANEL_BG", bg, (DWORD)sizeof(bg));
    if (nb > 0 && nb < (DWORD)sizeof(bg))
        strncpy_s(g_ddhPanelBgPath, sizeof(g_ddhPanelBgPath), bg, _TRUNCATE);
    char edge[sizeof(g_ddhPanelBgEdge)] = { 0 };
    const DWORD ne = GetEnvironmentVariableA("DDH_PANEL_BG_EDGE", edge, (DWORD)sizeof(edge));
    if (ne > 0 && ne < (DWORD)sizeof(edge))
        strncpy_s(g_ddhPanelBgEdge, sizeof(g_ddhPanelBgEdge), edge, _TRUNCATE);

    char width[32] = { 0 };
    const DWORD nw = GetEnvironmentVariableA("DDH_PANEL_BG_WIDTH", width, (DWORD)sizeof(width));
    if (nw > 0 && nw < (DWORD)sizeof(width))
    {
        const float w = (float)atof(width);
        if (w > 0.12f && w < 0.65f) g_ddhPanelBgWidth = w;
    }
}

/* �?DdhChatEntryOk 同款：接受标准序言 / 被别的插件改�?E9 的情况�?*/
static int DdhUiEntryOk(uint32_t fn)
{
    if (fn < 0x10000u) return 0;
    uint8_t b[8] = { 0 };
    __try
    {
        for (int i = 0; i < 8; i++) b[i] = *(const uint8_t*)(uintptr_t)(fn + (uint32_t)i);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }

    if ((b[0] == 0x55 && b[1] == 0x8B && b[2] == 0xEC) ||
        (b[0] == 0x83 && b[1] == 0xE9) ||
        (b[0] == 0x6A && b[1] == 0xFF))
        return 1;

    if (b[0] == 0xE9)
    {
        uint32_t tgt = 0;
        __try { tgt = fn + 5u + *(const int32_t*)(uintptr_t)(fn + 1u); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)(uintptr_t)tgt, &mbi, sizeof(mbi)) &&
            mbi.State == MEM_COMMIT &&
            (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                            PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)))
            return 1;
    }
    return 0;
}

/* 懒校�?7 个核�?UI 入口 + 2 个可选背景入口。只在游戏线程调用。返�?1 = 文字面板可用�?*/
static int DdhInitUiFuncs(void)
{
    if (InterlockedCompareExchange(&g_ddhUiInitDone, 1, 0) != 0)
        return g_ddhUiGetGame != 0;
    if (!g_modBase)
    {
        LogLine("面板：没有 game.dll 基址，游戏内面板不可用");
        return 0;
    }

    struct Item { uint32_t rva; const char* name; uint32_t* slot; };
    Item core[7] = {
        { DDH_RVA_UI_GET_GAME,    "GetGameUI",   &g_ddhUiGetGame    },
        { DDH_RVA_UI_CREATE_TEXT, "CreateText",  &g_ddhUiCreateText },
        { DDH_RVA_UI_SET_FONT,    "SetFont",     &g_ddhUiSetFont    },
        { DDH_RVA_UI_SET_FONTFLAGS,"SetFontFlags",&g_ddhUiSetFontFlags },
        { DDH_RVA_UI_SET_TEXT,    "SetText",     &g_ddhUiSetText    },
        { DDH_RVA_UI_SET_COLOR,   "SetTextColor",&g_ddhUiSetColor   },
        { DDH_RVA_UI_SET_POINT,   "SetPoint",    &g_ddhUiSetPoint   },
    };
    Item bgItems[2] = {
        { DDH_RVA_UI_CREATE_BACKDROP, "CreateBackdrop", &g_ddhUiCreateBackdrop },
        { DDH_RVA_UI_SET_BACKDROP,    "SetBackdrop",    &g_ddhUiSetBackdrop    },
    };

    for (int i = 0; i < 7; i++)
    {
        const uint32_t fn = g_modBase + core[i].rva;
        if (!DdhUiEntryOk(fn))
        {
            uint8_t b[4] = { 0 };
            __try { for (int k = 0; k < 4; k++) b[k] = *(const uint8_t*)(uintptr_t)(fn + (uint32_t)k); }
            __except (EXCEPTION_EXECUTE_HANDLER) { b[0] = 0; }
            LogLine("面板：游戏内 UI 不可�?—�?%s(Game.dll+0x%X) 入口 %02X %02X %02X %02X 不符"
                    "（Game.dll 版本不匹�?被别的插件改过）",
                    core[i].name, core[i].rva, b[0], b[1], b[2], b[3]);
            return 0;
        }
    }
    for (int i = 0; i < 7; i++) *core[i].slot = g_modBase + core[i].rva;

    /* 背景是可选项：入口不符时只关背景，文字面板照常�?*/
    for (int i = 0; i < 2; i++)
    {
        const uint32_t fn = g_modBase + bgItems[i].rva;
        if (DdhUiEntryOk(fn))
            *bgItems[i].slot = g_modBase + bgItems[i].rva;
        else
        {
            *bgItems[i].slot = 0;
            LogLine("面板：背景接口 %s(Game.dll+0x%X) 入口不符，本次只显示文字面板",
                    bgItems[i].name, bgItems[i].rva);
        }
    }
    LogLine("面板：引擎 UI 接口已就绪（文字 7 项；背景 %s）",
            (g_ddhUiCreateBackdrop && g_ddhUiSetBackdrop) ? "2 项已就绪" : "不可用（只显示文字）");
    return 1;
}

static uint32_t DdhGetGameUi(void)
{
    if (!g_ddhUiGetGame) return 0;
    uint32_t ui = 0;
    __try { ui = ((fn_ui_getgame_t)(uintptr_t)g_ddhUiGetGame)(0, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { ui = 0; }
    if (ui < 0x10000u || ui > 0x7FFFFFFFu) return 0;
    return ui;
}

static int DdhReadableU32(uint32_t addr, uint32_t* out)
{
    if (out) *out = 0;
    if (addr < 0x10000u || addr > 0x7FFFFFFFu) return 0;
    __try { uint32_t v = *(const uint32_t*)(uintptr_t)addr; if (out) *out = v; return 1; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

static int DdhUiLooksReady(uint32_t ui)
{
    uint32_t v = 0;
    if (!DdhReadableU32(ui, &v) || !v) return 0;
    if (!DdhReadableU32(ui + DDH_OFF_UI_LAYOUT_SUB, &v) || !v) return 0;
    return 1;
}

static void DdhFrameShowHide(void* frame, int show)
{
    if (!frame) return;
    void** vt = NULL;
    __try { vt = *(void***)frame; } __except (EXCEPTION_EXECUTE_HANDLER) { vt = NULL; }
    if (!vt) return;
    void* fn = NULL;
    __try { fn = vt[(show ? 0xD4 : 0xD0) / 4]; } __except (EXCEPTION_EXECUTE_HANDLER) { fn = NULL; }
    if (!fn) return;
    __try { ((void (__fastcall*)(void*, void*))fn)(frame, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
}

/* 魔兽把软件鼠标画成 CGameUI+0x16C 的 CCursorFrame。窗口覆盖层出现后
   Windows 系统光标负责可见性，因此进入自有 UI 时必须把游戏软件光标临时
   藏掉；离开后恢复，避免出现两个箭头。 */
static void DdhApplyCursorOver(int over, int useSystemCursor)
{
    over = over ? 1 : 0;
    DdhOverlayCursorSet(useSystemCursor ? over : 0);

    const uint32_t ui = DdhGetGameUi();
    uint32_t cursor = 0;
    const int cursorOk = ui && DdhReadableU32(ui + DDH_OFF_GAME_CURSOR_FRAME, &cursor) && cursor;

    if (over)
    {
        if (cursorOk)
        {
            const int wasHidden =
                (g_ddhHiddenCursorUi == ui && g_ddhHiddenCursorFrame == cursor);
            g_ddhHiddenCursorUi = ui;
            g_ddhHiddenCursorFrame = cursor;
            DdhFrameShowHide((void*)(uintptr_t)cursor, 0);
            if (!wasHidden && InterlockedIncrement(&g_ddhCursorLogged) <= 6)
                LogLine("光标：已隐藏游戏软件鼠标 CGameUI=0x%08X cursor=0x%08X",
                        ui, cursor);
        }
        else if (InterlockedIncrement(&g_ddhCursorLogged) <= 6)
        {
            LogLine("光标：读不到 CGameUI+0x%X 的 CCursorFrame，可能出现双鼠标",
                    DDH_OFF_GAME_CURSOR_FRAME);
        }
    }
    else if (g_ddhHiddenCursorFrame && g_ddhHiddenCursorUi)
    {
        if (ui && ui == g_ddhHiddenCursorUi)
            DdhFrameShowHide((void*)(uintptr_t)g_ddhHiddenCursorFrame, 1);
        if (InterlockedIncrement(&g_ddhCursorLogged) <= 6)
            LogLine("光标：已恢复游戏软件鼠标 CGameUI=0x%08X cursor=0x%08X",
                    g_ddhHiddenCursorUi, g_ddhHiddenCursorFrame);
        g_ddhHiddenCursorUi = 0;
        g_ddhHiddenCursorFrame = 0;
    }
    g_ddhCursorOver = over;
}

static void DdhPanelHide(void)
{
    /* 图表模式：把图表�?文字/头像一起藏掉（帧对象保留，下次重建�?*/
    DdhChartHide();

    /* 换图/UI 重建后旧帧对象可能已经释放：只有确认还是同一�?CGameUI 才碰它们�?
       不是同一�?UI 就把指针丢掉（不 free），等下次显示时按新 UI 重建�?*/
    if (g_ddhPanelFrameCount > 0 || g_ddhPanelBgFrame ||
        g_ddhPanelIconFrames[0] || g_ddhPanelIconFrames[1] ||
        g_ddhPanelIconFrames[2] || g_ddhPanelIconFrames[3])
    {
        const uint32_t ui = DdhGetGameUi();
        if (ui && ui == g_ddhPanelUi)
        {
            for (int i = 0; i < g_ddhPanelFrameCount; i++)
                if (g_ddhPanelFrames[i]) DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelFrames[i], 0);
            for (int i = 0; i < DDH_ICON_MAX; ++i)
                if (g_ddhPanelIconFrames[i]) DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelIconFrames[i], 0);
            if (g_ddhPanelBgFrame) DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelBgFrame, 0);
        }
        else if (ui && ui != g_ddhPanelUi)
        {
            g_ddhPanelFrameCount = 0;
            memset(g_ddhPanelFrames, 0, sizeof(g_ddhPanelFrames));
            g_ddhPanelBgFrame = 0;
            g_ddhPanelBgTextured = 0;
            g_ddhPanelBgFailed = 0;   /* �?UI 允许重试背景 */
            memset(g_ddhPanelIconFrames, 0, sizeof(g_ddhPanelIconFrames));
            memset(g_ddhPanelIconPaths, 0, sizeof(g_ddhPanelIconPaths));
            g_ddhPanelIconCount = 0;
            g_ddhPanelIconFramesFailed = 0;
            g_ddhIconCacheCount = 0;
            g_ddhPanelUi = ui;
        }
        else if (!ui)
        {
            /* 已退�?UI 暂时不可用：只丢指针，不碰旧帧（避免 UAF）；下次进图重建�?*/
            g_ddhPanelFrameCount = 0;
            memset(g_ddhPanelFrames, 0, sizeof(g_ddhPanelFrames));
            g_ddhPanelBgFrame = 0;
            g_ddhPanelBgTextured = 0;
            g_ddhPanelBgFailed = 0;
            memset(g_ddhPanelIconFrames, 0, sizeof(g_ddhPanelIconFrames));
            memset(g_ddhPanelIconPaths, 0, sizeof(g_ddhPanelIconPaths));
            g_ddhPanelIconCount = 0;
            g_ddhPanelIconFramesFailed = 0;
            g_ddhIconCacheCount = 0;
        }
        /* ui == 0（不在图里）：不碰旧帧，避免 UAF；下次显示会重新校验�?*/
    }
    g_ddhPanelShown = 0;
    g_ddhPanelPinned = 0;
    g_ddhPanelClickOk = 0;
    g_ddhPanelMouseDown = 0;
    g_ddhPanelFrameRectOk = 0;
}

/* 背景帧：先创建，保证绘制顺序在文字帧下面。创建失败只影响背景，不影响文字�?
   setTexture=0 时只建空帧占位（背景关掉时也不让以后启用盖住文字）�?*/
/* ===========================================================================
   v28：游戏内【死亡结算】按钮
   ---------------------------------------------------------------------------
   参考 KK 平台游戏内按钮的形态（常驻屏幕上的小按钮，点一下就开面板），但实现
   不跟它一样去 hook 渲染层：KK 是 ImGui 覆盖层（War3Plugin.dll 自带 imgui+
   opengl32），我们直接用引擎自己的帧（CBackdropFrame + CTextFrame）——
   不用管图形后端、分辨率或 UI 缩放，也不会和引擎抢输入。

   · 位置：左上菜单栏下方（UI 坐标 0.8 x 0.6，左上锚点）
   · 显示：只在“进图后”显示（主菜单/载入界面不显示）
   · 点击：面板没开 -> 唤出上一次阵亡总结（和 `~` 同一条路径）；已开 -> 收起
           还没有任何结算数据时 -> 弹一条提示，告诉用户打完一仗再来
   · 关闭：环境变量 DDH_NO_BUTTON=1（调试用）
   =========================================================================== */
static bool DdhWebDirectoryValid(const char* dir)
{
    if (!dir || !dir[0]) return false;
    const DWORD attrs = GetFileAttributesA(dir);
    if (attrs == INVALID_FILE_ATTRIBUTES || !(attrs & FILE_ATTRIBUTE_DIRECTORY)) return false;

    char path[MAX_PATH] = { 0 };
    DdhSprintf(path, sizeof(path), "%s\\ddh_web.exe", dir);
    const DWORD exe = GetFileAttributesA(path);
    if (exe == INVALID_FILE_ATTRIBUTES || (exe & FILE_ATTRIBUTE_DIRECTORY)) return false;

    DdhSprintf(path, sizeof(path), "%s\\dss.html", dir);
    const DWORD html = GetFileAttributesA(path);
    return html != INVALID_FILE_ATTRIBUTES && !(html & FILE_ATTRIBUTE_DIRECTORY);
}

extern "C" int DdhWebUiAvailable(void)
{
    static volatile LONG lastCheckTick = 0;
    static volatile LONG available = 0;
    const DWORD now = GetTickCount();
    const LONG last = InterlockedCompareExchange(&lastCheckTick, 0, 0);
    if (last && (DWORD)(now - (DWORD)last) < 1000)
        return InterlockedCompareExchange(&available, 0, 0);

    bool ok = false;
    char envDir[MAX_PATH] = { 0 };
    const DWORD envLen = GetEnvironmentVariableA("DDH_WEB_DIR", envDir, (DWORD)sizeof(envDir));
    if (envLen > 0 && envLen < (DWORD)sizeof(envDir))
        ok = DdhWebDirectoryValid(envDir);

    if (!ok) ok = DdhWebDirectoryValid("C:\\launch\\ddh_web");

    if (!ok && g_self)
    {
        char modulePath[MAX_PATH] = { 0 };
        if (GetModuleFileNameA(g_self, modulePath, (DWORD)sizeof(modulePath)) > 0)
        {
            char* slash = strrchr(modulePath, '\\');
            if (slash)
            {
                slash[1] = 0;
                char candidate[MAX_PATH] = { 0 };
                const char* relatives[] =
                {
                    "ddh_web",
                    "..\\ddh_web",
                    "..\\Game\\ddh_web",
                    "..\\..\\Game\\ddh_web"
                };
                for (const char* relative : relatives)
                {
                    DdhSprintf(candidate, sizeof(candidate), "%s%s", modulePath, relative);
                    if (DdhWebDirectoryValid(candidate)) { ok = true; break; }
                }
            }
        }
    }

    InterlockedExchange(&available, ok ? 1 : 0);
    InterlockedExchange(&lastCheckTick, (LONG)now);
    return ok ? 1 : 0;
}

static void DdhButtonReadEnvOnce(void)
{
    if (g_ddhBtnEnvRead) return;
    g_ddhBtnEnvRead = 1;
    /* master：Dear ImGui 光标层拥有唯一的 KK 风格按钮。 */
    g_ddhBtnDisabled = 1;
}

/* 丢帧指针（不 free：引擎的帧归 UI 所有，换图后旧帧自然析构） */
static void DdhButtonDropFrames(void)
{
    g_ddhBtnBg = 0;
    g_ddhBtnText = 0;
    g_ddhBtnUi = 0;
    g_ddhBtnReady = 0;
    g_ddhBtnRectOk = 0;
    g_ddhBtnMouseDown = 0;
}

/* 进图判定：地图名读得到 = 在图中。每 2 秒最多查一次，避免频繁 ReadProcessMemory。 */
static int DdhButtonInGame(void)
{
    const DWORD now = GetTickCount();
    if ((DWORD)(now - (DWORD)g_ddhBtnLastGameCheck) < 2000)
        return (int)g_ddhBtnInGame;
    g_ddhBtnLastGameCheck = (LONG)now;

    char map[128] = { 0 };
    int inGame = 0;
    __try { inGame = DdhReadMapName(map, sizeof(map)) ? 1 : 0; }
    __except (EXCEPTION_EXECUTE_HANDLER) { inGame = 0; }
    InterlockedExchange(&g_ddhBtnInGame, inGame);
    return inGame;
}

static void DdhButtonSetTextColor(uint32_t argb)
{
    if (!g_ddhBtnText || !g_ddhUiSetColor) return;
    __try { ((fn_ui_set_color_t)(uintptr_t)g_ddhUiSetColor)((void*)(uintptr_t)g_ddhBtnText, 0, &argb); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
}

/* 读背景帧布局矩形（布局坐标，引擎下一帧才写；读不到就返回 0，用归一化兜底） */
static int DdhButtonReadRect(void)
{
    if (!g_ddhBtnBg) return 0;
    int ok = 0;
    __try
    {
        const uint32_t bgl = g_ddhBtnBg + DDH_OFF_UI_LAYOUT_SUB;
        const float l = *(const float*)(uintptr_t)(bgl + 0x174);
        const float t = *(const float*)(uintptr_t)(bgl + 0x178);
        const float r = *(const float*)(uintptr_t)(bgl + 0x17C);
        const float b = *(const float*)(uintptr_t)(bgl + 0x180);
        if (r > l + 2.0f && b > t + 2.0f &&
            l > -100.0f && t > -100.0f && r < 10000.0f && b < 10000.0f)
        {
            g_ddhBtnL = l; g_ddhBtnT = t; g_ddhBtnR = r; g_ddhBtnB = b;
            ok = 1;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { ok = 0; }
    g_ddhBtnRectOk = ok;
    return ok;
}

/* 游戏线程：确保按钮帧存在并在当前 CGameUI 上。返回 1 = 现在应当可见。 */
static int DdhButtonEnsure(void)
{
    DdhButtonReadEnvOnce();
    if (g_ddhBtnDisabled || g_ddhPanelDisabled || g_ddhUiBroken) return 0;
    if (!DdhWebUiAvailable()) return 0;

    if (DdhImGuiActive())
    {
        if (g_ddhBtnReady)
        {
            if (g_ddhBtnBg)   DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnBg, 0);
            if (g_ddhBtnText) DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnText, 0);
            g_ddhBtnReady = 0;
        }
        if (g_ddhHtmlFrame && g_ddhHtmlShown)
            DdhFrameShowHide((void*)(uintptr_t)g_ddhHtmlFrame, 0);
        g_ddhHtmlShown = 0;
        return 0;
    }

    if (DdhOverlayReady())
    {
        if (g_ddhBtnReady)
        {
            if (g_ddhBtnBg)   DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnBg, 0);
            if (g_ddhBtnText) DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnText, 0);
            g_ddhBtnReady = 0;
        }
        return 0;
    }

    if (!DdhInitUiFuncs()) { g_ddhUiBroken = 1; return 0; }

    const uint32_t ui = DdhGetGameUi();

    if (!DdhButtonInGame())
    {
        /* 主菜单/已退图：能确认还是同一套 CGameUI 才去碰旧帧（否则旧帧可能已经
           被引擎析构，ShowHide 就是 UAF）。帧不动，回图里可复用。 */
        if (g_ddhBtnReady)
        {
            if (ui && ui == g_ddhBtnUi)
            {
                if (g_ddhBtnBg)   DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnBg, 0);
                if (g_ddhBtnText) DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnText, 0);
            }
            else
            {
                DdhButtonDropFrames();
            }
            g_ddhBtnReady = 0;
        }
        return 0;
    }
    if (!ui || !DdhUiLooksReady(ui))
    {
        if (g_ddhBtnUi && g_ddhBtnUi != ui) DdhButtonDropFrames();
        return 0;
    }

    if (ui == g_ddhBtnUi && g_ddhBtnText)
    {
        /* 同一套 CGameUI（主菜单 <-> 游戏来回切也是同一套）：帧还在，直接显示复用，
           不要重建——否则每次回主菜单再进图都会多留一套引擎帧。 */
        if (g_ddhBtnBg) DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnBg, 1);
        DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnText, 1);
        g_ddhBtnReady = 1;
        if (g_ddhHtmlShown)
        {
            DdhHtmlPanelEnsure(ui);
            DdhRaiseGameCursor(ui);
        }
        DdhButtonReadRect();          /* 布局矩形下一帧才有，每个 tick 补读 */
        return 1;
    }

    /* UI 重建/换图：旧指针丢掉，按新 UI 重建 */
    DdhButtonDropFrames();
    if (g_ddhHtmlUi != ui)
    {
        g_ddhHtmlFrame = 0;
        g_ddhHtmlUi = 0;
        g_ddhHtmlShown = 0;
        g_ddhHtmlFailed = 0;
        g_ddhCursorRaisedUi = 0;
        g_ddhCursorRaisedFrame = 0;
        g_ddhCursorRaisedLevel = 0;
    }
    g_ddhBtnUi = ui;
    const uint32_t root = ui + DDH_OFF_UI_LAYOUT_SUB;

    if (g_ddhUiCreateBackdrop && g_ddhUiSetBackdrop)
    {
        uint32_t frame = 0;
        __try { frame = ((fn_ui_create_backdrop_t)(uintptr_t)g_ddhUiCreateBackdrop)(ui, 0, 0); }
        __except (EXCEPTION_EXECUTE_HANDLER) { frame = 0; }
        if (frame)
        {
            g_ddhBtnBg = frame;
            __try
            {
                uint8_t* q = (uint8_t*)(uintptr_t)frame;
                q[0xAC] = 0xC0;                                /* 半透明，别挡视野 */
                *(float*)(uintptr_t)(frame + 0x1B8) = 0.008f;  /* 边框亮一点 */
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
            __try
            {
                ((fn_ui_setbackdrop_t)(uintptr_t)g_ddhUiSetBackdrop)(
                    (void*)(uintptr_t)frame, 0, DDH_PANEL_BG_DEFAULT, 0xFFu, 1u,
                    DDH_PANEL_BG_EDGE_DEFAULT, 1u);
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { g_ddhBtnBg = 0; }
        }
    }

    uint32_t txt = 0;
    __try { txt = ((fn_ui_create_text_t)(uintptr_t)g_ddhUiCreateText)(ui, 0, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { txt = 0; }
    if (!txt)
    {
        DdhButtonDropFrames();
        if (InterlockedIncrement(&g_ddhBtnLogged) <= 3)
            LogLine("按钮：创建文字帧失败，本次进图没有游戏内按钮（面板/热键不受影响）");
        return 0;
    }
    g_ddhBtnText = txt;
    __try
    {
        uint32_t* q = (uint32_t*)(uintptr_t)txt;
        q[0x0C / 4] |= q[0x10 / 4] | 2u;   /* 照引擎建文字帧后的初始化 */
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }

    __try { ((fn_ui_set_font_t)(uintptr_t)g_ddhUiSetFont)((void*)(uintptr_t)txt, 0, "MasterFont", 0.0115f, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try { ((fn_ui_set_fontflags_t)(uintptr_t)g_ddhUiSetFontFlags)((void*)(uintptr_t)txt, 0, 0x3008u); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    DdhButtonSetTextColor(0xFFFFCC66u);
    const char* buttonLabel = DdhOverlayMarkerText();
    __try { ((fn_ui_set_text_t)(uintptr_t)g_ddhUiSetText)((void*)(uintptr_t)txt, 0, buttonLabel); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }

    if (g_ddhBtnBg)
    {
        uint32_t bl = g_ddhBtnBg + DDH_OFF_UI_LAYOUT_SUB;
        __try
        {
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)bl, 0, 0u, root, 0u, DDH_BTN_X, DDH_BTN_Y, 1);
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)bl, 0, 8u, root, 0u, DDH_BTN_X + DDH_BTN_W, DDH_BTN_Y - DDH_BTN_H, 1);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }

    uint32_t tl = txt;
    if (!g_ddhPanelNoSub) tl = txt + DDH_OFF_UI_LAYOUT_SUB;
    __try
    {
        ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
            (void*)(uintptr_t)tl, 0, 0u, root, 0u, DDH_BTN_X + 0.007f, DDH_BTN_Y - 0.0035f, 1);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }

    if (g_ddhBtnBg)   DdhFrameShowHide((void*)(uintptr_t)g_ddhBtnBg, 1);
    DdhFrameShowHide((void*)(uintptr_t)txt, 1);

    g_ddhBtnReady = 1;
    DdhButtonReadRect();
    if (InterlockedIncrement(&g_ddhBtnLogged) <= 3)
        LogLine("按钮：游戏内【%s】按钮已就绪（UI 0x%08X，背景 %s）",
                buttonLabel, ui, g_ddhBtnBg ? "有" : "无（只有文字）");
    return 1;
}

/* 鼠标命中按钮（客户区像素）。优先用帧矩形，读不到时按归一化坐标兜底。 */
static int DdhButtonHitTest(int x, int y)
{
    if (!g_ddhBtnReady) return 0;
    RECT rc = { 0 };
    if (!g_gameWnd || !GetClientRect(g_gameWnd, &rc)) return 0;
    const int cw = rc.right - rc.left;
    const int ch = rc.bottom - rc.top;
    if (cw <= 0 || ch <= 0) return 0;

    if (g_ddhBtnRectOk)
    {
        const int l = max(0, min(cw - 1, (int)g_ddhBtnL));
        const int t = max(0, min(ch - 1, (int)g_ddhBtnT));
        const int r = max(l + 1, min(cw, (int)g_ddhBtnR));
        const int b = max(t + 1, min(ch, (int)g_ddhBtnB));
        return x >= l && x < r && y >= t && y < b;
    }

    const int l = (int)(DDH_BTN_X * 1.25f * (float)cw);
    const int t = (int)(-DDH_BTN_Y * (float)ch);
    const int r = (int)((DDH_BTN_X + DDH_BTN_W) * 1.25f * (float)cw);
    const int b = (int)((-DDH_BTN_Y + DDH_BTN_H) * (float)ch);
    return x >= l && x < r && y >= t && y < b;
}

/* 没有任何结算数据时点按钮：弹一条提示，别让玩家以为按钮坏了。 */
static void DdhButtonShowHint(void)
{
    DdhPanelBlock p;
    memset(&p, 0, sizeof(p));
    p.seq = 1;
    p.flags = DDH_PANEL_FLAG_SHOW | DDH_PANEL_FLAG_BG;
    p.ttlMs = 4000;
    p.anchor = 0;
    p.x = 0.60f;
    p.y = -0.24f;
    p.lineHeight = 0.0175f;
    p.fontHeight = 0.0135f;
    strcpy_s(p.fontName, sizeof(p.fontName), "MasterFont");
    p.lineCount = 2;
    p.lines[0].color = 0xFFFFCC66u;
    strcpy_s(p.lines[0].text, sizeof(p.lines[0].text), "死亡结算");
    p.lines[1].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[1].text, sizeof(p.lines[1].text),
             "本局还没有阵亡记录（本地英雄阵亡后自动记录，再看这里）");

    g_ddhPanelCollapsed = 0;
    g_ddhPanelIconCount = 0;
    const int r = DdhPanelApply(&p);
    if (r > 0)
    {
        g_ddhPanelPinned = 0;
        g_ddhPanelHideAt = (LONG)(GetTickCount() + 4000);
    }
    if (InterlockedIncrement(&g_ddhBtnClickLogged) <= 10)
        LogLine("按钮：点击（还没有结算数据）r=%d", r);
}

/* 游戏线程：点按钮 = 唤出/收起阵亡总结（和 `~` 一条路径）。 */
static void DdhButtonClick(void)
{
    if (DdhImGuiActive()) return;
    const uint32_t ui = DdhGetGameUi();
    if (!DdhHtmlPanelEnsure(ui))
    {
        DdhButtonShowHint();
        return;
    }

    g_ddhHtmlShown = !g_ddhHtmlShown;
    DdhFrameShowHide((void*)(uintptr_t)g_ddhHtmlFrame, g_ddhHtmlShown);
    if (g_ddhHtmlShown) DdhRaiseGameCursor(ui);
    DdhButtonSetTextColor(0xFFFFCC66u);
    if (InterlockedIncrement(&g_ddhBtnClickLogged) <= 10)
        LogLine("按钮：点击 -> %s HTML 快照面板", g_ddhHtmlShown ? "打开" : "关闭");
}

static int DdhHtmlPanelEnsure(uint32_t ui)
{
    if (g_ddhHtmlFailed || !ui || !DdhUiLooksReady(ui)) return 0;
    if (!g_ddhUiCreateBackdrop || !g_ddhUiSetBackdrop) return 0;
    if (g_ddhHtmlFrame && g_ddhHtmlUi == ui) return 1;

    g_ddhHtmlFrame = 0;
    g_ddhHtmlUi = ui;
    uint32_t frame = 0;
    __try { frame = ((fn_ui_create_backdrop_t)(uintptr_t)g_ddhUiCreateBackdrop)(ui, 0, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { frame = 0; }
    if (!frame)
    {
        g_ddhHtmlFailed = 1;
        LogLine("HTML：创建背面帧失败");
        return 0;
    }

    __try { ((uint8_t*)(uintptr_t)frame)[0xAC] = 0xFF; }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try
    {
        ((fn_ui_setbackdrop_t)(uintptr_t)g_ddhUiSetBackdrop)(
            (void*)(uintptr_t)frame, 0, "UI\\ddh_panel.blp", 0u, 0u, NULL, 1u);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        g_ddhHtmlFailed = 1;
        LogLine("HTML：SetBackdrop(UI\\ddh_panel.blp) 异常");
        return 0;
    }

    const uint32_t root = ui + DDH_OFF_UI_LAYOUT_SUB;
    const uint32_t layout = frame + DDH_OFF_UI_LAYOUT_SUB;
    __try
    {
        ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
            (void*)(uintptr_t)layout, 0, 0u, root, 0u, 0.532f, -0.060f, 1);
        ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
            (void*)(uintptr_t)layout, 0, 8u, root, 0u, 0.791f, -0.417f, 1);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }

    DdhFrameShowHide((void*)(uintptr_t)frame, 0);
    g_ddhHtmlFrame = frame;
    if (InterlockedIncrement(&g_ddhHtmlLogged) <= 3)
        LogLine("HTML：引擎面板已创建 frame=0x%08X tex=UI\\ddh_panel.blp", frame);
    return 1;
}

static void DdhRaiseGameCursor(uint32_t ui)
{
    DdhApplyCursorOver(0, 1);
    uint32_t cursor = 0;
    if (!ui || !DdhReadableU32(ui + DDH_OFF_GAME_CURSOR_FRAME, &cursor) || !cursor) return;

    int32_t maxLevel = 32;
    for (int i = 0; i < 2; ++i)
    {
        uint32_t frame = i == 0 ? g_ddhHtmlFrame : g_ddhBtnBg;
        uint32_t value = 0;
        if (frame && DdhReadableU32(frame + 0x64, &value) && (int32_t)value > maxLevel)
            maxLevel = (int32_t)value;
    }
    uint32_t cursorValue = 0;
    if (DdhReadableU32(cursor + 0x64, &cursorValue) && (int32_t)cursorValue > maxLevel)
        maxLevel = (int32_t)cursorValue;
    const int32_t desired = maxLevel + 10;
    if (g_ddhCursorRaisedUi == ui && g_ddhCursorRaisedFrame == cursor &&
        g_ddhCursorRaisedLevel == desired)
        return;

    typedef void (__thiscall* fn_ui_setlevel_t)(void*, int32_t);
    __try
    {
        ((fn_ui_setlevel_t)(uintptr_t)(g_modBase + 0xBC8D0u))((void*)(uintptr_t)cursor, desired);
        g_ddhCursorRaisedUi = ui;
        g_ddhCursorRaisedFrame = cursor;
        g_ddhCursorRaisedLevel = desired;
        if (InterlockedIncrement(&g_ddhCursorLogged) <= 10)
            LogLine("光标：真实 CCursorFrame=0x%08X 层级提高到 %d", cursor, desired);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("光标：提高 CCursorFrame 层级异常 code=%08X", (unsigned)GetExceptionCode());
    }
}

static void DdhPanelEnsureBackdrop(uint32_t ui, int setTexture)
{
    if (g_ddhPanelBgFailed || g_ddhPanelNoBg) return;
    if (!g_ddhUiCreateBackdrop || !g_ddhUiSetBackdrop) { g_ddhPanelBgFailed = 1; return; }

    if (!g_ddhPanelBgFrame)
    {
        uint32_t frame = 0;
        __try { frame = ((fn_ui_create_backdrop_t)(uintptr_t)g_ddhUiCreateBackdrop)(ui, 0, 0); }
        __except (EXCEPTION_EXECUTE_HANDLER) { frame = 0; }
        if (!frame)
        {
            g_ddhPanelBgFailed = 1;
            if (InterlockedIncrement(&g_ddhPanelBgLogged) <= 3)
                LogLine("面板：创建背景帧失败，本次/本局只用文字面板");
            return;
        }
        g_ddhPanelBgFrame = frame;
        g_ddhPanelBgTextured = 0;
        __try
        {
            uint8_t* q = (uint8_t*)(uintptr_t)frame;
            q[0xAC] = 0xFF;                             /* �?alpha = 不透明 */
            *(float*)(uintptr_t)(frame + 0x1B8) = 0.012f; /* 边框更明�?*/
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        DdhFrameShowHide((void*)(uintptr_t)frame, 0);   /* 建好先藏起来，等 Apply 决定 */
    }

    if (!setTexture || g_ddhPanelBgTextured) return;
    const int useEdge = g_ddhPanelBgEdge[0] != 0;
    __try
    {
        if (useEdge)
            ((fn_ui_setbackdrop_t)(uintptr_t)g_ddhUiSetBackdrop)(
                (void*)(uintptr_t)g_ddhPanelBgFrame, 0, g_ddhPanelBgPath, 0xFFu, 1u, g_ddhPanelBgEdge, 1u);
        else
            ((fn_ui_setbackdrop_t)(uintptr_t)g_ddhUiSetBackdrop)(
                (void*)(uintptr_t)g_ddhPanelBgFrame, 0, g_ddhPanelBgPath, 0u, 0u, NULL, 1u);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        g_ddhPanelBgFailed = 1;
        if (InterlockedIncrement(&g_ddhPanelBgLogged) <= 3)
            LogLine("面板：SetBackdrop 异常，本次/本局只用文字面板");
        return;
    }
    g_ddhPanelBgTextured = 1;
    if (InterlockedIncrement(&g_ddhPanelBgLogged) <= 3)
        LogLine("面板：背景已就绪（bg=%s edge=%s width=%.3f）",
                g_ddhPanelBgPath, useEdge ? g_ddhPanelBgEdge : "(无)", g_ddhPanelBgWidth);
}

/* 头像占位帧：先于文字创建，保证绘制层级在背景上、文字下；无头像时隐藏�?*/
static void DdhPanelEnsureIconFrames(uint32_t ui)
{
    if (g_ddhPanelIconFramesFailed) return;
    if (!g_ddhUiCreateBackdrop || !g_ddhUiSetBackdrop) { g_ddhPanelIconFramesFailed = 1; return; }
    for (int i = 0; i < DDH_ICON_MAX; ++i)
    {
        if (g_ddhPanelIconFrames[i]) continue;
        uint32_t frame = 0;
        __try { frame = ((fn_ui_create_backdrop_t)(uintptr_t)g_ddhUiCreateBackdrop)(ui, 0, 0); }
        __except (EXCEPTION_EXECUTE_HANDLER) { frame = 0; }
        if (!frame)
        {
            g_ddhPanelIconFramesFailed = 1;
            if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 3)
                LogLine("面板：创建头像帧失败（不影响文字/点击）");
            return;
        }
        g_ddhPanelIconFrames[i] = frame;
        g_ddhPanelIconPaths[i][0] = 0;
        __try
        {
            uint8_t* q = (uint8_t*)(uintptr_t)frame;
            q[0xAC] = 0xFF;
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        DdhFrameShowHide((void*)(uintptr_t)frame, 0);
    }
}

static uint32_t g_ddhIconGetUnitDataFn = 0;
static volatile LONG g_ddhIconGetUnitDataLogged = 0;
static volatile LONG g_ddhIconResolveLogged = 0;

static int DdhIconHasBlp(const char* s)
{
    if (!s) return 0;
    const size_t n = strlen(s);
    if (n < 5 || n >= 240) return 0;
    for (size_t i = 0; i + 4 <= n; ++i)
    {
        if (s[i] == '.' && _stricmp(s + i, ".blp") == 0) return 1;
    }
    return 0;
}

static int DdhIconContains(const char* s, const char* needle)
{
    if (!s || !needle) return 0;
    const size_t nl = strlen(needle);
    for (const char* p = s; *p; ++p)
        if (_strnicmp(p, needle, nl) == 0) return 1;
    return 0;
}

/* 从一个可读指针取 .blp 路径；成功返�?1�?*/
static int DdhIconPathAt(uint32_t ptr, char* out, size_t cap)
{
    if (!out || cap < 8 || ptr < 0x10000u || ptr > 0x7FFFFFFFu) return 0;
    out[0] = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)ptr;
        int n = 0;
        for (; n < 240; ++n)
        {
            const unsigned char c = p[n];
            if (!c) break;
            if (c < 0x20 || c == 0x7F) return 0;
        }
        if (n < 5 || n >= 240) return 0;
        if (p[n] != 0) return 0;
        char tmp[240] = { 0 };
        memcpy(tmp, p, (size_t)n);
        if (!DdhIconHasBlp(tmp)) return 0;
        strncpy_s(out, cap, tmp, _TRUNCATE);
        for (char* q = out; *q; ++q) if (*q == '/') *q = '\\';
        return 1;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

/* 复用 UDATA �?RegisterModel -> GetUnitData 发现步骤，只做一次�?*/
static uint32_t DdhIconGetUnitData(void)
{
    if (g_ddhIconGetUnitDataFn) return g_ddhIconGetUnitDataFn;
    if (!g_modBase) return 0;

    DdhUdataSection sec[32];
    const int n = DdhUdataSections(g_modBase, sec, (int)(sizeof(sec) / sizeof(sec[0])));
    if (n <= 0) return 0;
    const uint32_t strAddr = DdhUdataFindRegisterModel(sec, n);
    if (!strAddr) return 0;
    const uint32_t ref = DdhUdataFindStringRef(sec, n, strAddr);
    if (!ref) return 0;
    uint32_t callAddr = 0;
    const uint32_t fn = DdhUdataFindCall(sec, n, ref, &callAddr);
    if (!fn) return 0;
    g_ddhIconGetUnitDataFn = fn;
    if (InterlockedIncrement(&g_ddhIconGetUnitDataLogged) <= 2)
        LogLine("面板头像：GetUnitData=0x%08X（RVA 0x%X，RegisterModel 引用 @0x%08X）",
                fn, fn - g_modBase, ref);
    return fn;
}

static const char* DdhIconCacheGet(uint32_t code)
{
    for (int i = 0; i < g_ddhIconCacheCount; ++i)
        if (g_ddhIconCache[i].code == code)
            return g_ddhIconCache[i].state > 0 ? g_ddhIconCache[i].path : "";
    return NULL;
}

static void DdhIconCachePut(uint32_t code, const char* path)
{
    if (!code) return;
    int idx = -1;
    for (int i = 0; i < g_ddhIconCacheCount; ++i)
        if (g_ddhIconCache[i].code == code) { idx = i; break; }
    if (idx < 0)
    {
        if (g_ddhIconCacheCount >= (int)(sizeof(g_ddhIconCache) / sizeof(g_ddhIconCache[0]))) return;
        idx = g_ddhIconCacheCount++;
    }
    g_ddhIconCache[idx].code = code;
    g_ddhIconCache[idx].state = (path && path[0]) ? 1 : -1;
    g_ddhIconCache[idx].path[0] = 0;
    if (path && path[0]) strncpy_s(g_ddhIconCache[idx].path, sizeof(g_ddhIconCache[idx].path), path, _TRUNCATE);
}

static bool DdhIconResolve(uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 8 || !code) return false;
    out[0] = 0;
    if (InterlockedIncrement(&g_ddhIconResolveLogged) <= 8)
        LogLine("面板头像：resolve code=0x%08X typeDataOk=%d", code, (int)g_ddhTypeDataOk);
    const char* cached = DdhIconCacheGet(code);
    if (cached)
    {
        if (!cached[0]) return false;
        strncpy_s(out, cap, cached, _TRUNCATE);
        return true;
    }

    char path[128] = { 0 };
    if (g_ddhTypeDataOk)
    {
        static const char* const fields[] = { "Art", "Icon", "uico", "buttonArt" };
        for (int i = 0; i < (int)(sizeof(fields) / sizeof(fields[0])); ++i)
        {
            char tmp[128] = { 0 };
            if (DdhTypeDataString(0, code, fields[i], tmp, sizeof(tmp)) &&
                DdhIconHasBlp(tmp))
            {
                strncpy_s(path, sizeof(path), tmp, _TRUNCATE);
                for (char* q = path; *q; ++q) if (*q == '/') *q = '\\';
                break;
            }
        }
    }

    if (!path[0])
    {
        static const char* const exFields[] = { "Art", "Icon", "uico", "buttonArt", "ArtIcon" };
        for (int i = 0; i < (int)(sizeof(exFields) / sizeof(exFields[0])); ++i)
        {
            char tmp[128] = { 0 };
            if (DdhExSlkString(code, exFields[i], tmp, sizeof(tmp)) && DdhIconHasBlp(tmp))
            {
                strncpy_s(path, sizeof(path), tmp, _TRUNCATE);
                for (char* q = path; *q; ++q) if (*q == '/') *q = '\\';
                if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
                    LogLine("面板头像：jass.slk %s 解析成功 code=0x%08X path=%s",
                            exFields[i], code, path);
                break;
            }
        }
    }

    if (!path[0])
    {
        const uint32_t fn = DdhIconGetUnitData();
        if (fn)
        {
            uintptr_t data = 0;
            __try { data = ((uintptr_t(__fastcall*)(uint32_t))(uintptr_t)fn)(code); }
            __except (EXCEPTION_EXECUTE_HANDLER) { data = 0; }
            if (data)
            {
                char first[128] = { 0 };
                for (uint32_t i = 0; i < 0x300; ++i)
                {
                    uint32_t p = 0;
                    if (!DdhUdataPoke((uint32_t)data + i * 4u, &p)) break;
                    char tmp[128] = { 0 };
                    if (!DdhIconPathAt(p, tmp, sizeof(tmp))) continue;
                    if (!first[0]) strncpy_s(first, sizeof(first), tmp, _TRUNCATE);
                    if (DdhIconContains(tmp, "CommandButtons") || DdhIconContains(tmp, "BTN"))
                    {
                        strncpy_s(first, sizeof(first), tmp, _TRUNCATE);
                        break;
                    }
                }
                /* 普通单位的命令卡图标不�?UnitData 顶层：顶层只是嵌套对象指针�?
                   对前 0x300 个指针再做一层浅扫描，找 CommandButtons/BTN .blp�?*/
                if (!first[0])
                {
                    for (uint32_t i = 0; i < 0x300 && !first[0]; ++i)
                    {
                        uint32_t obj = 0;
                        if (!DdhUdataPoke((uint32_t)data + i * 4u, &obj)) break;
                        if (obj < 0x10000u || obj > 0x7FFFFFFFu) continue;
                        for (uint32_t j = 0; j < 0x40; ++j)
                        {
                            uint32_t q = 0;
                            if (!DdhUdataPoke(obj + j * 4u, &q)) break;
                            char tmp[128] = { 0 };
                            if (!DdhIconPathAt(q, tmp, sizeof(tmp))) continue;
                            if (DdhIconContains(tmp, "CommandButtons") || DdhIconContains(tmp, "BTN"))
                            {
                                strncpy_s(first, sizeof(first), tmp, _TRUNCATE);
                                break;
                            }
                            if (!first[0]) strncpy_s(first, sizeof(first), tmp, _TRUNCATE);
                        }
                    }
                }
                if (first[0]) strncpy_s(path, sizeof(path), first, _TRUNCATE);
            }
        }
    }

    DdhIconCachePut(code, path);
    if (!path[0])
    {
        /* 类型数据/GetUnitData 都还没就绪时不要缓存“无路径”，否则本图永久没头像�?*/
        if (!g_ddhTypeDataOk && !g_ddhIconGetUnitDataFn)
        {
            for (int i = 0; i < g_ddhIconCacheCount; ++i)
                if (g_ddhIconCache[i].code == code) { g_ddhIconCache[i].state = 0; break; }
            return false;
        }
        if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
            LogLine("面板头像：来源类型码 0x%08X 未解析到 .blp 图标（只显示文字）", code);
        return false;
    }
    strncpy_s(out, cap, path, _TRUNCATE);
    return true;
}

/* 帧渲染不可用时的兜底：拼成一条带 |n 的本机消息，DisplayTimedTextToPlayer 显示�?*/
static void DdhPanelFallback(const DdhPanelBlock* p)
{
    if (!p) return;
    char text[4096] = { 0 };
    int n = (int)p->lineCount;
    if (n < 1) n = 1;
    if (n > DDH_PANEL_MAX_LINES) n = DDH_PANEL_MAX_LINES;
    for (int i = 0; i < n; i++)
    {
        if (i) DdhAppendRaw(text, sizeof(text), "|n");
        char line[DDH_PANEL_LINE_TEXT + 1] = { 0 };
        memcpy(line, p->lines[i].text, DDH_PANEL_LINE_TEXT - 1);
        line[DDH_PANEL_LINE_TEXT - 1] = 0;
        DdhAppendRaw(text, sizeof(text), line);
    }
    LogLine("面板：帧渲染不可用，改用 DisplayTimedTextToPlayer 兜底（%d 行，仅本机可见）", n);
    DdhShowLocalText(text);
}

/* 真正�?更新面板。返�?1 = 已显示，0 = UI 还没就绪（可重试），-1 = 已判死（走兜底）�?*/
static int DdhPanelApply(const DdhPanelBlock* p)
{
    if (!p) return -1;
    DdhPanelReadEnvOnce();
    if (g_ddhPanelDisabled) return -1;
    if (g_ddhSuppressPanel)
    {
        DdhPanelHide();
        LogLine("面板：镜像/幻象单位，跳过显示");
        return 1;
    }
    if (g_ddhUiBroken) return -1;
    if (!DdhInitUiFuncs()) { g_ddhUiBroken = 1; return -1; }

    const uint32_t ui = DdhGetGameUi();
    if (!ui)
    {
        if (InterlockedIncrement(&g_ddhPanelNoUiLogged) <= 3)
            LogLine("面板：GetGameUI 为空（未进图/UI 还没建好），稍后重试");
        return 0;
    }
    if (!DdhUiLooksReady(ui))
    {
        if (InterlockedIncrement(&g_ddhPanelNoUiLogged) <= 3)
            LogLine("面板：CGameUI 0x%08X 的根帧不可读，稍后重试", ui);
        return 0;
    }

    if (g_ddhPanelUi != ui)
    {
        /* UI 重建/换图：旧帧指针全部丢弃（�?free，避免引擎析构风险；每张图最�?20 个，进程内有界）�?*/
        g_ddhPanelUi = ui;
        g_ddhPanelFrameCount = 0;
        memset(g_ddhPanelFrames, 0, sizeof(g_ddhPanelFrames));
        g_ddhPanelBgFrame = 0;
        g_ddhPanelBgTextured = 0;
        g_ddhPanelBgFailed = 0;
        memset(g_ddhPanelIconFrames, 0, sizeof(g_ddhPanelIconFrames));
        memset(g_ddhPanelIconPaths, 0, sizeof(g_ddhPanelIconPaths));
        g_ddhPanelIconFramesFailed = 0;
        g_ddhIconCacheCount = 0;
        g_ddhPanelShown = 0;
        LogLine("面板：绑定到新的 CGameUI 0x%08X（根帧 0x%08X）", ui, ui + DDH_OFF_UI_LAYOUT_SUB);
    }

    int n = (int)p->lineCount;
    if (n < 1) n = 1;
    if (n > DDH_PANEL_MAX_LINES) n = DDH_PANEL_MAX_LINES;

    int collapsedLines = (int)g_ddhPanelCollapsedLines;
    if (collapsedLines < 1) collapsedLines = 3;
    if (collapsedLines > 3) collapsedLines = 3;
    if (collapsedLines > n) collapsedLines = n;
    const int shown = (g_ddhPanelCollapsed != 0) ? collapsedLines : n;

    uint32_t anchor = p->anchor;
    if (anchor > 8) anchor = 0;
    float x = p->x, y = p->y, fh = p->fontHeight, lh = p->lineHeight;
    if (!(x > -2.0f && x < 2.0f)) x = 0.60f;
    if (!(y > -2.0f && y < 2.0f)) y = -0.24f;
    if (!(fh > 0.005f && fh < 0.05f)) fh = 0.0135f;
    if (!(lh > 0.005f && lh < 0.08f)) lh = 0.0175f;

    char font[DDH_PANEL_FONT_NAME] = { 0 };
    if (g_ddhPanelFontOverride[0])
        strncpy_s(font, sizeof(font), g_ddhPanelFontOverride, _TRUNCATE);
    else if (p->fontName[0])
    {
        memcpy(font, p->fontName, DDH_PANEL_FONT_NAME - 1);
        font[DDH_PANEL_FONT_NAME - 1] = 0;
    }
    else
        strcpy_s(font, sizeof(font), "MasterFont");

    /* flags bit4：承伤图表模式。C# 不再发文本行，而是�?lines 区放 DdhChartReq{victim}�?
       具体 5 秒分�?四类分段/来源聚合全部�?ddh 从自己的事件环算（C# 不用再算一遍）�?*/
    if ((p->flags & DDH_PANEL_FLAG_CHART) != 0)
    {
        uint32_t victim = 0;
        const uint8_t* payload = (const uint8_t*)p->lines;
        if (payload)
        {
            uint32_t magic = 0, v = 0;
            memcpy(&magic, payload, 4);
            memcpy(&v, payload + 4, 4);
            if (magic == DDH_CHART_MAGIC) victim = v;
        }
        return DdhChartApply(ui, p, victim, x, y, fh, font);
    }

    const uint32_t root = ui + DDH_OFF_UI_LAYOUT_SUB;
    const uint32_t relFrame = root;

    /* 背景帧总是在文字帧之前创建（背景关掉时也建空帧占位），保证以后启用时不会盖住文字�?*/
    const bool wantBg = ((p->flags & DDH_PANEL_FLAG_BG) != 0) && !g_ddhPanelNoBg;
    DdhPanelEnsureBackdrop(ui, wantBg ? 1 : 0);
    DdhPanelEnsureIconFrames(ui);
    const bool bgOn = wantBg && (g_ddhPanelBgTextured != 0) && !g_ddhPanelBgFailed;

    /* 头像先解析，来源行文字要按“头像宽度”缩进；头像放在来源行左侧，避免面板
       在宽�?缩放后把右侧头像推到屏幕外�?*/
    float iconAspect = 9.0f / 16.0f;
    {
        RECT rc = { 0 };
        if (g_gameWnd && GetClientRect(g_gameWnd, &rc))
        {
            const int cw = rc.right - rc.left;
            const int ch = rc.bottom - rc.top;
            if (cw > 0 && ch > 0) iconAspect = (float)ch / (float)cw;
        }
    }
    const float iconH = lh * 1.1f;
    const float iconW = iconH * iconAspect;
    char iconPath[DDH_ICON_MAX][128] = { { 0 } };
    int  iconActive[DDH_ICON_MAX] = { 0 };
    if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
        LogLine("面板头像：准备 count=%d line0=%u code0=0x%08X shown=%d noIcons=%d",
                g_ddhPanelIconCount, g_ddhPanelIconLines[0], g_ddhPanelIconCodes[0],
                shown, (int)g_ddhPanelNoIcons);
    if (!g_ddhPanelNoIcons)
    {
        for (int i = 0; i < DDH_ICON_MAX; ++i)
        {
            const uint32_t line = g_ddhPanelIconLines[i];
            if (i >= g_ddhPanelIconCount) continue;
            if ((int)line >= shown)
            {
                if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
                    LogLine("面板头像：跳过 line=%u（shown=%d）", line, shown);
                continue;
            }
            if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
                LogLine("面板头像：尝试 i=%d count=%d line=%u code=0x%08X shown=%d",
                        i, g_ddhPanelIconCount, line, g_ddhPanelIconCodes[i], shown);
            if (!DdhIconResolve(g_ddhPanelIconCodes[i], iconPath[i], sizeof(iconPath[i])))
            {
                if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
                    LogLine("面板头像：解析失败 line=%u code=0x%08X", line, g_ddhPanelIconCodes[i]);
                continue;
            }
            iconActive[i] = 1;
            if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
                LogLine("面板头像：line=%u code=0x%08X path=%s",
                        line, g_ddhPanelIconCodes[i], iconPath[i]);
        }
    }
    else if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
    {
        LogLine("面板头像：DDH_NO_PANEL_ICONS=1，跳过头像");
    }

    int iconResolved = 0;
    for (int i = 0; i < DDH_ICON_MAX; ++i) if (iconActive[i]) ++iconResolved;
    if (g_ddhPanelIconCount > 0 && InterlockedIncrement(&g_ddhAvatarSummaryLogged) <= 20)
        LogLine("AVATAR_SUMMARY expected=%d resolved=%d shown=%d",
                g_ddhPanelIconCount, iconResolved, shown);

    for (int i = 0; i < shown; i++)
    {
        if (!g_ddhPanelFrames[i])
        {
            uint32_t frame = 0;
            __try { frame = ((fn_ui_create_text_t)(uintptr_t)g_ddhUiCreateText)(ui, 0, 0); }
            __except (EXCEPTION_EXECUTE_HANDLER) { frame = 0; }
            if (!frame)
            {
                g_ddhUiBroken = 1;
                if (InterlockedIncrement(&g_ddhUiBrokenLogged) <= 3)
                    LogLine("面板：创建文字帧失败（第 %d 行），本局改用兜底显示", i + 1);
                return -1;
            }
            g_ddhPanelFrames[i] = frame;
            g_ddhPanelFrameCount = i + 1;
            /* 照引擎内部建文字帧后的初始化：frame+0xC |= (frame+0x10 | 2)�?*/
            __try
            {
                uint32_t* q = (uint32_t*)(uintptr_t)frame;
                q[0x0C / 4] |= q[0x10 / 4] | 2u;
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
        }

        const uint32_t frame = g_ddhPanelFrames[i];
        __try { ((fn_ui_set_font_t)(uintptr_t)g_ddhUiSetFont)((void*)(uintptr_t)frame, 0, font, fh, 0); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        /* 引擎建文字帧后固定传 0x3008（阴�?描边一类字�?flags）�?*/
        __try { ((fn_ui_set_fontflags_t)(uintptr_t)g_ddhUiSetFontFlags)((void*)(uintptr_t)frame, 0, 0x3008u); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }

        uint32_t color = p->lines[i].color;
        __try { ((fn_ui_set_color_t)(uintptr_t)g_ddhUiSetColor)((void*)(uintptr_t)frame, 0, &color); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }

        char line[DDH_PANEL_LINE_TEXT + 1] = { 0 };
        memcpy(line, p->lines[i].text, DDH_PANEL_LINE_TEXT - 1);
        line[DDH_PANEL_LINE_TEXT - 1] = 0;
        if (!line[0]) strcpy_s(line, sizeof(line), " ");
        __try { ((fn_ui_set_text_t)(uintptr_t)g_ddhUiSetText)((void*)(uintptr_t)frame, 0, line); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }

        uint32_t layout = frame;
        if (!g_ddhPanelNoSub) layout = frame + DDH_OFF_UI_LAYOUT_SUB;
        float lineX = x;
        for (int k = 0; k < DDH_ICON_MAX; ++k)
        {
            if (iconActive[k] && (int)g_ddhPanelIconLines[k] == i)
            {
                lineX = x + iconW + 0.006f;
                break;
            }
        }
        __try
        {
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)layout, 0, anchor, relFrame, anchor, lineX, y - (float)i * lh, 1);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        DdhFrameShowHide((void*)(uintptr_t)frame, 1);
    }

    for (int i = shown; i < g_ddhPanelFrameCount; i++)
        if (g_ddhPanelFrames[i]) DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelFrames[i], 0);

    /* 面板几何：点击命中区和背景共用；即使背景关闭也要有命中区�?*/
    float bgW = g_ddhPanelBgWidth;
    if (!(bgW > 0.12f && bgW < 0.65f)) bgW = 0.37f;
    float bgX = x - 0.012f;
    float bgY = y + 0.012f;
    float bgH = (float)shown * lh + 0.026f;
    if (bgX + bgW > 0.995f) bgX = 0.995f - bgW;
    if (bgX < -0.995f) bgX = -0.995f;
    if (bgY - bgH < -0.995f) bgY = -0.995f + bgH;

    g_ddhPanelHitL = bgX;
    g_ddhPanelHitT = bgY;
    g_ddhPanelHitW = bgW;
    g_ddhPanelHitH = bgH;
    g_ddhPanelMouseDown = 0;

    /* 背景尺寸：正�?shown �?+ 上下留白；两个点定义矩形（右下点相对根左上，绝对坐标）�?*/
    if (bgOn && g_ddhPanelBgFrame)
    {
        uint32_t bl = g_ddhPanelBgFrame;
        if (!g_ddhPanelNoSub) bl = g_ddhPanelBgFrame + DDH_OFF_UI_LAYOUT_SUB;
        __try
        {
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)bl, 0, 0u, relFrame, 0u, bgX, bgY, 1);
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)bl, 0, 8u, relFrame, 0u, bgX + bgW, bgY - bgH, 1);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelBgFrame, 1);
    }
    else if (g_ddhPanelBgFrame)
    {
        DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelBgFrame, 0);
    }

    /* 设置点后再读一次背景帧矩形；布局�?UI 坐标，可能超出客户区，命中测试会裁到客户区�?*/
    g_ddhPanelFrameRectOk = 0;
    if (g_ddhPanelBgFrame)
    {
        __try
        {
            const uint32_t bgl = g_ddhPanelBgFrame + DDH_OFF_UI_LAYOUT_SUB;
            const float l = *(const float*)(uintptr_t)(bgl + 0x174);
            const float t = *(const float*)(uintptr_t)(bgl + 0x178);
            const float r = *(const float*)(uintptr_t)(bgl + 0x17C);
            const float b = *(const float*)(uintptr_t)(bgl + 0x180);
            if (r > l + 2.0f && b > t + 2.0f &&
                l > -100.0f && t > -100.0f && r < 10000.0f && b < 10000.0f)
            {
                g_ddhPanelFrameL = l;
                g_ddhPanelFrameT = t;
                g_ddhPanelFrameR = r;
                g_ddhPanelFrameB = b;
                g_ddhPanelFrameRectOk = 1;
            }
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { g_ddhPanelFrameRectOk = 0; }
    }
    g_ddhPanelClickOk = (anchor == 0 || g_ddhPanelFrameRectOk) ? 1 : 0;
    if (InterlockedIncrement(&g_ddhPanelGeomLogged) <= 12)
        LogLine("面板几何：shown=%d bgH=%.4f rectOk=%d rect=(%.0f,%.0f)-(%.0f,%.0f) clickOk=%d",
                shown, bgH, (int)g_ddhPanelFrameRectOk,
                g_ddhPanelFrameL, g_ddhPanelFrameT, g_ddhPanelFrameR, g_ddhPanelFrameB,
                (int)g_ddhPanelClickOk);

    /* 头像：来源行左侧�?.1 行高；收起时来源行不�?shown 内则隐藏�?*/
    for (int i = 0; i < DDH_ICON_MAX; ++i)
    {
        const uint32_t frame = g_ddhPanelIconFrames[i];
        if (!frame) continue;
        const uint32_t line = g_ddhPanelIconLines[i];
        if (!iconActive[i] || (int)line >= shown || !iconPath[i][0])
        {
            DdhFrameShowHide((void*)(uintptr_t)frame, 0);
            continue;
        }

        if (_stricmp(g_ddhPanelIconPaths[i], iconPath[i]) != 0)
        {
            __try
            {
                ((fn_ui_setbackdrop_t)(uintptr_t)g_ddhUiSetBackdrop)(
                    (void*)(uintptr_t)frame, 0, iconPath[i], 0u, 0u, NULL, 1u);
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
            strncpy_s(g_ddhPanelIconPaths[i], sizeof(g_ddhPanelIconPaths[i]), iconPath[i], _TRUNCATE);
        }

        uint32_t layout = frame;
        if (!g_ddhPanelNoSub) layout = frame + DDH_OFF_UI_LAYOUT_SUB;
        __try
        {
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)layout, 0, 0u, relFrame, 0u, x,
                y - (float)line * lh, 1);
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)layout, 0, 8u, relFrame, 0u, x + iconW,
                y - (float)line * lh - iconH, 1);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        DdhFrameShowHide((void*)(uintptr_t)frame, 1);
    }

    int iconVisible = 0;
    for (int i = 0; i < DDH_ICON_MAX; ++i)
        if (iconActive[i] && g_ddhPanelIconFrames[i] &&
            (int)g_ddhPanelIconLines[i] < shown && iconPath[i][0]) ++iconVisible;
    if (g_ddhPanelIconCount > 0 && InterlockedIncrement(&g_ddhAvatarSummaryLogged) <= 40)
        LogLine("AVATAR_VISIBLE expected=%d resolved=%d visible=%d shown=%d",
                g_ddhPanelIconCount, iconResolved, iconVisible, shown);

    uint32_t ttl = p->ttlMs;
    if (ttl == 0) ttl = 20000;
    if (ttl < 1000) ttl = 1000;
    if (ttl > 600000) ttl = 600000;
    g_ddhPanelHideAt = (LONG)(GetTickCount() + ttl);
    g_ddhPanelShown = 1;

    if (InterlockedIncrement(&g_ddhPanelLogCount) <= 10)
        LogLine("面板：已显示 %d/%d 行（%s，背景=%s，CGameUI=0x%08X，字体=%s %.4f，坐标 %.3f/%.3f，行距 %.4f，ttl=%u）",
                shown, n, g_ddhPanelCollapsed ? "收起" : "展开", bgOn ? "开" : "关",
                ui, font, fh, x, y, lh, ttl);
    return 1;
}

static void DdhPanelTryPending(void)
{
    if (!g_ddhPendingValid) return;
    const int r = DdhPanelApply(&g_ddhPendingPanel);
    if (r != 0)
    {
        if (r < 0) DdhPanelFallback(&g_ddhPendingPanel);
        g_ddhPendingValid = 0;
    }
    else
    {
        g_ddhPendingTick = (LONG)GetTickCount();
    }
}

/* 游戏线程：C# �?IconBlock 有新序号就拷出来（v17）�?*/
static void DdhProcessIconRequest(void)
{
    g_ddhPanelIconCount = 0;
    if (!g_shm || g_shm->hdr.version < 17) return;
    const uint32_t seq = g_shm->icons.seq;
    if (!seq) return;

    DdhIconBlock local;
    memset(&local, 0, sizeof(local));
    memcpy(&local, &g_shm->icons, sizeof(local));
    MemoryBarrier();
    g_shm->icons.appliedSeq = seq;
    MemoryBarrier();

    int n = (int)local.count;
    if (n < 0) n = 0;
    if (n > DDH_ICON_MAX) n = DDH_ICON_MAX;
    g_ddhPanelIconCount = n;
    for (int i = 0; i < n; ++i)
    {
        g_ddhPanelIconCodes[i] = local.slots[i].rawcode;
        g_ddhPanelIconAddrs[i] = local.slots[i].sourceAddr;
        uint32_t line = local.slots[i].lineIndex;
        if (line >= DDH_PANEL_MAX_LINES) line = 0;
        g_ddhPanelIconLines[i] = line;
    }
    for (int i = n; i < DDH_ICON_MAX; ++i)
    {
        g_ddhPanelIconCodes[i] = 0;
        g_ddhPanelIconAddrs[i] = 0;
        g_ddhPanelIconLines[i] = 0;
    }
    if (InterlockedIncrement(&g_ddhPanelIconReqLogged) <= 6)
        LogLine("面板：收到头像请求 seq=%u count=%d noIcons=%d line0=%u code0=0x%08X line1=%u code1=0x%08X",
                seq, n, (int)g_ddhPanelNoIcons,
                n > 0 ? local.slots[0].lineIndex : 0, n > 0 ? local.slots[0].rawcode : 0,
                n > 1 ? local.slots[1].lineIndex : 0, n > 1 ? local.slots[1].rawcode : 0);
}

/* 游戏线程：C# �?PanelBlock 有新序号就拷出来�?*/
static void DdhProcessPanelRequest(void)
{
    if (!g_shm) return;
    const uint32_t seq = g_shm->panel.seq;
    if (!seq || seq == (uint32_t)g_ddhPanelAppliedSeq) return;

    DdhPanelBlock local;
    memset(&local, 0, sizeof(local));
    memcpy(&local, &g_shm->panel, sizeof(local));
    MemoryBarrier();

    g_ddhPanelAppliedSeq = (LONG)seq;
    g_shm->panel.appliedSeq = seq;
    MemoryBarrier();

    if (local.flags & DDH_PANEL_FLAG_HIDE)
    {
        g_ddhPendingValid = 0;
        g_ddhPanelPinned = 0;   /* `~` 显隐：C# 主动隐藏，取消“手动固定�?*/
        DdhPanelHide();
        LogLine("面板：收到隐藏请求（seq=%u）", seq);
        return;
    }

    g_ddhPanelCollapsed = ((local.flags & DDH_PANEL_FLAG_COLLAPSED) != 0) ? 1 : 0;
    int cl = (int)((local.flags >> DDH_PANEL_COLLAPSED_SHIFT) & DDH_PANEL_COLLAPSED_MASK);
    if (cl <= 0) cl = 3;
    if (cl > 3) cl = 3;
    g_ddhPanelCollapsedLines = cl;

    memcpy(&g_ddhPendingPanel, &local, sizeof(g_ddhPendingPanel));
    /* `~` 显隐：留一份给 `~` 重新显示；新结算重新�?TTL，不吃上次的“手动固定�?*/
    memcpy(&g_ddhLastPanel, &local, sizeof(g_ddhLastPanel));
    g_ddhHaveLastPanel = 1;
    g_ddhPanelPinned = 0;
    g_ddhPendingValid = 1;
    g_ddhPendingTick = (LONG)GetTickCount();
    g_ddhPendingPostTick = (LONG)GetTickCount();
    g_ddhPanelTickPost = 0;
    DdhProcessIconRequest();
    DdhPanelTryPending();
}

/* 游戏线程：TTL 兜底（C# 也会主动�?hide；这条防 C# 卡住/关闭）�?*/
static void DdhPanelTick(void)
{
    /* v28：每 500ms 一次（热键线程投递）——顺便把游戏内按钮建好/更新。
       只在游戏线程动帧，和面板完全同一条线程。 */
    __try { DdhButtonEnsure(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        if (InterlockedIncrement(&g_ddhBtnLogged) <= 3)
            LogLine("按钮：tick 异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
    }

    if (g_ddhPendingValid && (LONG)GetTickCount() - g_ddhPendingTick >= 250)
        DdhPanelTryPending();

    /* 布局矩形通常在下一帧才写入；每 500ms �?tick 里补读一次，修正手型/点击区�?*/
    if (g_ddhPanelShown && g_ddhPanelBgFrame)
    {
        __try
        {
            const uint32_t bgl = g_ddhPanelBgFrame + DDH_OFF_UI_LAYOUT_SUB;
            const float l = *(const float*)(uintptr_t)(bgl + 0x174);
            const float t = *(const float*)(uintptr_t)(bgl + 0x178);
            const float r = *(const float*)(uintptr_t)(bgl + 0x17C);
            const float b = *(const float*)(uintptr_t)(bgl + 0x180);
            if (r > l + 2.0f && b > t + 2.0f &&
                l > -100.0f && t > -100.0f && r < 10000.0f && b < 10000.0f)
            {
                g_ddhPanelFrameL = l;
                g_ddhPanelFrameT = t;
                g_ddhPanelFrameR = r;
                g_ddhPanelFrameB = b;
                g_ddhPanelFrameRectOk = 1;
                g_ddhPanelClickOk = 1;
            }
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }

    DdhChartReviveCheck();   /* 收缩态下英雄复活 3 秒清除 */

    /* `~` 显隐：`~` 手动唤出的面板不自动消失（再按一�?`~` 才隐藏） */
    if (g_ddhPanelShown && !g_ddhPanelPinned && (LONG)GetTickCount() >= g_ddhPanelHideAt)
    {
        DdhPanelHide();
        LogLine("面板：TTL 到点，已自动隐藏");
    }
}

/* v16：鼠标点击面板展开/收起（不再提供快捷键）。只在游戏线程调用�?*/
static void DdhDoTogglePanel(void)
{
    if (!g_ddhPanelShown)
    {
        LogLine("面板：点击时没有可切换的面板");
        return;
    }

    g_ddhPanelCollapsed = g_ddhPanelCollapsed ? 0 : 1;
    const int r = DdhPanelApply(&g_ddhPendingPanel);
    if (r > 0)
    {
        uint32_t ttl = g_ddhPendingPanel.ttlMs;
        if (ttl == 0) ttl = 20000;
        if (ttl < 1000) ttl = 1000;
        if (ttl > 600000) ttl = 600000;
        g_ddhPanelHideAt = (LONG)(GetTickCount() + ttl);

        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("面板：点击切换为%s（%d 行）",
                    g_ddhPanelCollapsed ? "收起" : "展开",
                    g_ddhPanelCollapsed ? (int)g_ddhPanelCollapsedLines
                                        : (int)g_ddhPendingPanel.lineCount);
    }
    else
    {
        g_ddhPanelCollapsed = g_ddhPanelCollapsed ? 0 : 1;   // 失败回退状�?
        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("面板：点击切换失败（返回 %d）", r);
    }
}

/* `~` 显隐：键�?`~`（VK_OEM_3）显�?隐藏（不是展开/收起；展开/收起仍是鼠标点击）�?
   返回值：1 = 这次按键被面板消费（窗口过程要吞�?WM_KEYDOWN）；0 = 没有面板，原样转发�?
   只在游戏线程调用（窗口过程里）�?*/
static int DdhDoToggleVisible(void)
{
    if (g_ddhPanelDisabled) return 0;

    /* 正在显示 �?隐藏（pinned �?DdhPanelHide 里一起清掉） */
    if (g_ddhPanelShown)
    {
        DdhPanelHide();
        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("面板：~ 隐藏");
        return 1;
    }

    /* 已隐�?�?用上一份内容重新显示；没有内容就什么都不做（把键让给游戏） */
    if (!g_ddhHaveLastPanel)
    {
        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("面板：~ 没有可显示的面板（等一次本地英雄阵亡结算）");
        return 0;
    }

    g_ddhPanelCollapsed = 0;   /* 手动唤出时一律展开 */
    const int r = DdhPanelApply(&g_ddhLastPanel);
    if (r > 0)
    {
        g_ddhPanelPinned = 1;
        g_ddhPanelHideAt = 0;
        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("面板：~ 重新显示（%d 行，已固定不自动隐藏）", (int)g_ddhLastPanel.lineCount);
        return 1;
    }

    if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
        LogLine("面板：~ 重新显示失败（返回 %d；UI 没就绪/已退图，稍后再按）", r);
    return 1;   /* 有面板数据但这次 UI 没就绪：仍吞键，避免漏到游戏里 */
}

/* ===========================================================================
   承伤图表（flags bit4）：最�?5 秒柱状图 + 点柱子下钻的四类伤害条形�?
   ---------------------------------------------------------------------------
   · C# 只发 DdhChartReq{victim}�? 秒分桶、四类归类、按来源分段全部�?ddh 里用
     自己的事件环（g_shm->ev）算，不扩共享内存�?
   · 绘制只用引擎帧：CBackdropFrame 当柱�?色块（两�?SetPoint 定矩形）�?
     CTextFrame 当文字，来源头像�?CBackdropFrame + BLP 贴图�?
   · 点击复用现成的命中矩形通道；图表模式下滑到 DdhChartClick�?
   · 颜色：引擎帧没有可靠的顶点色接口，A 版统一用暗色贴�?+ 文字标签区分四类�?
   =========================================================================== */
#define DDH_CHART_SECONDS    10
#define DDH_CHART_TYPES      4
#define DDH_CHART_MAX_SRC    8
#define DDH_CHART_MAX_SEG    16
#define DDH_CHART_FRAME_MAX  64
#define DDH_CHART_TEXT_MAX   40
#define DDH_CHART_ICON_MAX   12

struct DdhChartSeg { uint8_t type; uint8_t src; uint16_t pad; float amount; };
struct DdhChartSrc { uint32_t addr; uint32_t code; float total; };

static struct {
    int      valid;
    uint32_t victim;
    uint32_t endTick;
    uint32_t fatalSource;
    uint32_t fatalCode;
    float    total[DDH_CHART_SECONDS];
    float    maxTotal;
    int      srcCount;
    DdhChartSrc src[DDH_CHART_MAX_SRC];
    int      segCount[DDH_CHART_SECONDS];
    DdhChartSeg seg[DDH_CHART_SECONDS][DDH_CHART_MAX_SEG];
} g_ddhChart;

static int      g_ddhChartView = 0;          /* 0 = 5 秒总览�?..5 = �?1..5 个桶下钻 */
static int      g_ddhChartDemo = 0;          /* 1 = 下一�?Apply �?mock 数据（调样式�?*/
static uint32_t g_ddhChartUi = 0;
static DWORD    g_ddhChartBaseTick = 0;
static char     g_ddhChartFont[DDH_PANEL_FONT_NAME] = { 0 };
static uint32_t g_ddhChartFrames[DDH_CHART_FRAME_MAX];
static char     g_ddhChartFrameTex[DDH_CHART_FRAME_MAX][64];
static uint32_t g_ddhChartTexts[DDH_CHART_TEXT_MAX];
static uint32_t g_ddhChartIcons[DDH_CHART_ICON_MAX];
static char     g_ddhChartIconPath[DDH_CHART_ICON_MAX][128];
static float    g_ddhChartBar[DDH_CHART_SECONDS][4];   /* x0, x1, yTop, yBot（UI 归一化） */
static int      g_ddhChartBarOk = 0;
static volatile LONG g_ddhChartLogCount = 0;

static int g_ddhChartUnitMode = 0;   /* 0=原值 1=万 2=亿（由总伤害决定，全表统一） */
static void DdhChartFormatScaled(char* out, size_t cap, float v)
{
    if (g_ddhChartUnitMode == 2)      _snprintf_s(out, cap, _TRUNCATE, "%.2f亿", (double)(v / 100000000.0f));
    else if (g_ddhChartUnitMode == 1) _snprintf_s(out, cap, _TRUNCATE, "%.1f万", (double)(v / 10000.0f));
    else                              _snprintf_s(out, cap, _TRUNCATE, "%.0f", (double)v);
}

static void DdhChartFormatBar(char* out, size_t cap, float v)
{
    if (g_ddhChartUnitMode == 2)      _snprintf_s(out, cap, _TRUNCATE, "%.1f亿", (double)(v / 100000000.0f));
    else if (g_ddhChartUnitMode == 1) _snprintf_s(out, cap, _TRUNCATE, "%.0f万", (double)(v / 10000.0f));
    else                              _snprintf_s(out, cap, _TRUNCATE, "%.0f", (double)v);
}

static void DdhChartFormatAmount(char* out, size_t cap, float v)
{
    if (v >= 100000000.0f)      _snprintf_s(out, cap, _TRUNCATE, "%.2f亿", (double)(v / 100000000.0f));
    else if (v >= 10000.0f)     _snprintf_s(out, cap, _TRUNCATE, "%.1f万", (double)(v / 10000.0f));
    else                        _snprintf_s(out, cap, _TRUNCATE, "%.0f", (double)v);
}

/* 事件 �?四类�?=物理 1=法术 2=纯粹 3=生命移除（按 ddh 记录�?isPhysical/伤害类型掩码推） */
/* 四类口径：物理 = 伤害类型 4；法术 = 攻击类型 0；
   纯粹 = 攻击类型 != 0 且 伤害类型 != 4；移除 = 净掉血 - 地图伤害（Build 里按残差入账）。 */
static int DdhChartKind(const DdhEvent* e)
{
    uint32_t m = e->damageMask;
    int dt = -1;
    if (m)
    {
        int b = 0;
        while (b < 31 && (m & (1u << b)) == 0) ++b;
        dt = b;                            /* 伤害类型 = log2(mask)（0x10 -> 4） */
    }
    if (e->attackType != 0 && dt != 4) return 2;   /* 纯粹（先判）：攻击类型 != 0 且 伤害类型 != 4 */
    if (dt == 4) return 0;                        /* 物理：伤害类型 4 */
    if (e->attackType == 0) return 1;             /* 法术：攻击类型 0 */
    return 1;
}

static int DdhChartSrcSlot(uint32_t addr, uint32_t code)
{
    for (int i = 0; i < g_ddhChart.srcCount; ++i)
        if (code ? (g_ddhChart.src[i].code == code) : (g_ddhChart.src[i].addr == addr)) return i;   /* 按单位类型合并 */
    if (g_ddhChart.srcCount >= DDH_CHART_MAX_SRC) return -1;
    int i = g_ddhChart.srcCount++;
    g_ddhChart.src[i].addr = addr;
    g_ddhChart.src[i].code = code;
    g_ddhChart.src[i].total = 0.0f;
    return i;
}

static void DdhChartAdd(int bucket, int type, uint32_t addr, uint32_t code, float amount)
{
    if (bucket < 0 || bucket >= DDH_CHART_SECONDS) return;
    int src = DdhChartSrcSlot(addr, code);
    if (src < 0) return;
    g_ddhChart.src[src].total += amount;
    g_ddhChart.total[bucket] += amount;

    int n = g_ddhChart.segCount[bucket];
    for (int i = 0; i < n; ++i)
    {
        if (g_ddhChart.seg[bucket][i].type == (uint8_t)type &&
            g_ddhChart.seg[bucket][i].src == (uint8_t)src)
        {
            g_ddhChart.seg[bucket][i].amount += amount;
            return;
        }
    }
    if (n >= DDH_CHART_MAX_SEG) return;
    g_ddhChart.seg[bucket][n].type = (uint8_t)type;
    g_ddhChart.seg[bucket][n].src = (uint8_t)src;
    g_ddhChart.seg[bucket][n].pad = 0;
    g_ddhChart.seg[bucket][n].amount = amount;
    g_ddhChart.segCount[bucket] = n + 1;
}

/* 从事件环里找 victim 最近一次事件的 tick */
static int DdhChartFindEnd(uint32_t victim, uint32_t* outTick)
{
    if (!g_shm || !victim) return 0;
    uint32_t count = g_shm->hdr.count;
    uint32_t cap = g_shm->hdr.capacity ? g_shm->hdr.capacity : DDH_MAX_EVENTS;
    uint32_t n = count < cap ? count : cap;
    for (uint32_t k = 0; k < n; ++k)
    {
        uint32_t seq = count - k;
        if (seq == 0) break;
        const DdhEvent* e = &g_shm->ev[(seq - 1) % cap];
        if (e->seq != seq) continue;
        if (e->victim == victim) { *outTick = e->tickMs; return 1; }
    }
    return 0;
}

static int DdhChartBuild(uint32_t victim)
{
    memset(&g_ddhChart, 0, sizeof(g_ddhChart));
    if (!g_shm || !victim) return 0;
    uint32_t endTick = 0;
    if (!DdhChartFindEnd(victim, &endTick)) return 0;

    g_ddhChart.victim = victim;
    g_ddhChart.endTick = endTick;

    uint32_t count = g_shm->hdr.count;
    uint32_t cap = g_shm->hdr.capacity ? g_shm->hdr.capacity : DDH_MAX_EVENTS;
    uint32_t n = count < cap ? count : cap;
    for (uint32_t k = 0; k < n; ++k)
    {
        uint32_t seq = count - k;
        if (seq == 0) break;
        const DdhEvent* e = &g_shm->ev[(seq - 1) % cap];
        if (e->seq != seq) continue;
        if (e->victim != victim) continue;
        if ((int32_t)(endTick - e->tickMs) < 0) continue;
        if (e->hpValid && e->hpBefore > 0.0f && e->hpAfter <= 0.0f &&
            !g_ddhChart.fatalCode)
        {
            g_ddhChart.fatalSource = e->source;
            g_ddhChart.fatalCode = e->sourceCode;
        }
        uint32_t dt = endTick - e->tickMs;
        if (dt >= (uint32_t)(DDH_CHART_SECONDS * 1000)) continue;   /* 与桶数一致的窗口 */
        int bucket = DDH_CHART_SECONDS - 1 - (int)(dt / 1000u);

        const float net = (e->hpValid && e->actual > 0.01f) ? e->actual : 0.0f;
        /* 只认地图伤害（出口 *out，v20 在“确实掉血”时置 bit0 可信）。
           没有可信地图伤害的事件直接跳过，不再退回 engineDamage / amount / 净掉血。 */
        if (!((e->finalFlags & 1u) && e->finalDamage > 0.01f)) continue;
        const float eff = e->finalDamage;
        const int kind = DdhChartKind(e);
        DdhChartAdd(bucket, kind, e->source, e->sourceCode, eff);
        const float removal = net - eff;                                     /* 移除 = 净掉血 - 地图伤害 */
        if (removal > 0.01f) DdhChartAdd(bucket, 3, e->source, e->sourceCode, removal);
    }

    for (int i = 0; i < DDH_CHART_SECONDS; ++i)
        if (g_ddhChart.total[i] > g_ddhChart.maxTotal) g_ddhChart.maxTotal = g_ddhChart.total[i];
    if (!g_ddhChart.fatalCode)
    {
        int best = -1;
        float bestTotal = 0.0f;
        for (int i = 0; i < g_ddhChart.srcCount; ++i)
        {
            if (g_ddhChart.src[i].total <= bestTotal) continue;
            best = i;
            bestTotal = g_ddhChart.src[i].total;
        }
        if (best >= 0)
        {
            g_ddhChart.fatalSource = g_ddhChart.src[best].addr;
            g_ddhChart.fatalCode = g_ddhChart.src[best].code;
        }
    }
    g_ddhChart.valid = (g_ddhChart.maxTotal > 0.01f) ? 1 : 0;

    /* 每桶内按金额降序（渲�?头像挑大头用�?*/
    for (int b = 0; b < DDH_CHART_SECONDS; ++b)
    {
        for (int i = 1; i < g_ddhChart.segCount[b]; ++i)
        {
            DdhChartSeg t = g_ddhChart.seg[b][i];
            int j = i - 1;
            while (j >= 0 && g_ddhChart.seg[b][j].amount < t.amount)
            {
                g_ddhChart.seg[b][j + 1] = g_ddhChart.seg[b][j];
                --j;
            }
            g_ddhChart.seg[b][j + 1] = t;
        }
    }
    return 1;
}

/* ---- �?文字/头像 ---- */
static uint32_t DdhChartFrame(int idx)
{
    if (idx < 0 || idx >= DDH_CHART_FRAME_MAX) return 0;
    if (g_ddhChartFrames[idx]) return g_ddhChartFrames[idx];
    if (!g_ddhUiCreateBackdrop || !g_ddhChartUi) return 0;
    uint32_t f = 0;
    __try { f = ((fn_ui_create_backdrop_t)(uintptr_t)g_ddhUiCreateBackdrop)(g_ddhChartUi, 0, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { f = 0; }
    if (!f) return 0;
    g_ddhChartFrames[idx] = f;
    g_ddhChartFrameTex[idx][0] = 0;
    __try { ((uint8_t*)(uintptr_t)f)[0xAC] = 0xFF; }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    DdhFrameShowHide((void*)(uintptr_t)f, 0);
    return f;
}

static int DdhChartFrameTexSet(int idx)
{
    uint32_t f = DdhChartFrame(idx);
    if (!f) return 0;
    static const char* kChartBarTex = "UI\\Widgets\\Glues\\LoadingBar\\Loading-BarFill.blp";
    const char* tex = kChartBarTex;
    if (_stricmp(g_ddhChartFrameTex[idx], tex) != 0)
    {
        __try
        {
            ((fn_ui_setbackdrop_t)(uintptr_t)g_ddhUiSetBackdrop)(
                (void*)(uintptr_t)f, 0, tex, 0u, 0u, NULL, 1u);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        strncpy_s(g_ddhChartFrameTex[idx], sizeof(g_ddhChartFrameTex[idx]), tex, _TRUNCATE);
    }
    return 1;
}

/* 指定贴图（TeamColor 纯色）设置到某个槽位；同一槽位贴图变了才重设。 */
static int DdhChartTexSetEx(int idx, const char* tex)
{
    uint32_t f = DdhChartFrame(idx);
    if (!f) return 0;
    if (_stricmp(g_ddhChartFrameTex[idx], tex) != 0)
    {
        __try
        {
            ((fn_ui_setbackdrop_t)(uintptr_t)g_ddhUiSetBackdrop)(
                (void*)(uintptr_t)f, 0, tex, 0u, 0u, NULL, 1u);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        strncpy_s(g_ddhChartFrameTex[idx], sizeof(g_ddhChartFrameTex[idx]), tex, _TRUNCATE);
    }
    return 1;
}

static void DdhChartTint(uint32_t frame, uint32_t argb)
{
    (void)argb;   /* 引擎帧没有可靠的顶点色字段：0xB0 不是颜色，写 float 会把帧打崩。只保留 alpha。 */
    if (!frame) return;
    __try { ((uint8_t*)(uintptr_t)frame)[0xAC] = 0xFF; }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
}

static void DdhChartRect(uint32_t frame, float x0, float yTop, float x1, float yBot)
{
    if (!frame) return;
    uint32_t layout = g_ddhPanelNoSub ? frame : frame + DDH_OFF_UI_LAYOUT_SUB;
    const uint32_t rel = g_ddhChartUi + DDH_OFF_UI_LAYOUT_SUB;
    __try
    {
        ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)((void*)(uintptr_t)layout, 0, 0u, rel, 0u, x0, yTop, 1);
        ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)((void*)(uintptr_t)layout, 0, 8u, rel, 0u, x1, yBot, 1);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
}

static uint32_t DdhChartTextFrame(int slot)
{
    if (slot < 0 || slot >= DDH_CHART_TEXT_MAX) return 0;
    if (g_ddhChartTexts[slot]) return g_ddhChartTexts[slot];
    if (!g_ddhUiCreateText || !g_ddhChartUi) return 0;
    uint32_t f = 0;
    __try { f = ((fn_ui_create_text_t)(uintptr_t)g_ddhUiCreateText)(g_ddhChartUi, 0, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { f = 0; }
    if (!f) return 0;
    g_ddhChartTexts[slot] = f;
    __try
    {
        uint32_t* q = (uint32_t*)(uintptr_t)f;
        q[0x0C / 4] |= q[0x10 / 4] | 2u;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    DdhFrameShowHide((void*)(uintptr_t)f, 0);
    return f;
}

static void DdhChartText(int slot, const char* text, float x, float y, float fh, uint32_t argb)
{
    uint32_t frame = DdhChartTextFrame(slot);
    if (!frame) return;
    const char* font = g_ddhChartFont[0] ? g_ddhChartFont : "MasterFont";
    uint32_t color = argb;
    __try { ((fn_ui_set_font_t)(uintptr_t)g_ddhUiSetFont)((void*)(uintptr_t)frame, 0, font, fh, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try { ((fn_ui_set_fontflags_t)(uintptr_t)g_ddhUiSetFontFlags)((void*)(uintptr_t)frame, 0, 0x3008u); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try { ((fn_ui_set_color_t)(uintptr_t)g_ddhUiSetColor)((void*)(uintptr_t)frame, 0, &color); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try { ((fn_ui_set_text_t)(uintptr_t)g_ddhUiSetText)((void*)(uintptr_t)frame, 0, text); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }

    uint32_t layout = g_ddhPanelNoSub ? frame : frame + DDH_OFF_UI_LAYOUT_SUB;
    const uint32_t rel = g_ddhChartUi + DDH_OFF_UI_LAYOUT_SUB;
    __try { ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)((void*)(uintptr_t)layout, 0, 0u, rel, 0u, x, y, 1); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    DdhFrameShowHide((void*)(uintptr_t)frame, 1);
}

static int DdhChartIconPathOf(uint32_t code, char* out, size_t cap)
{
    if (!code) return 0;
    if (DdhIconResolve(code, out, cap)) return 1;
    uint32_t sw = (code >> 24) | ((code >> 8) & 0x0000FF00u) |
                  ((code << 8) & 0x00FF0000u) | (code << 24);
    if (sw != code && DdhIconResolve(sw, out, cap)) return 1;
    return 0;
}

static void DdhChartIcon(int slot, uint32_t code, float x, float yTop, float size)
{
    if (slot < 0 || slot >= DDH_CHART_ICON_MAX) return;
    char path[128] = { 0 };
    if (!DdhChartIconPathOf(code, path, sizeof(path))) return;

    uint32_t f = g_ddhChartIcons[slot];
    if (!f)
    {
        if (!g_ddhUiCreateBackdrop || !g_ddhChartUi) return;
        __try { f = ((fn_ui_create_backdrop_t)(uintptr_t)g_ddhUiCreateBackdrop)(g_ddhChartUi, 0, 0); }
        __except (EXCEPTION_EXECUTE_HANDLER) { f = 0; }
        if (!f) return;
        g_ddhChartIcons[slot] = f;
        g_ddhChartIconPath[slot][0] = 0;
        __try { ((uint8_t*)(uintptr_t)f)[0xAC] = 0xFF; }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
    if (_stricmp(g_ddhChartIconPath[slot], path) != 0)
    {
        __try
        {
            ((fn_ui_setbackdrop_t)(uintptr_t)g_ddhUiSetBackdrop)(
                (void*)(uintptr_t)f, 0, path, 0u, 0u, NULL, 1u);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        strncpy_s(g_ddhChartIconPath[slot], sizeof(g_ddhChartIconPath[slot]), path, _TRUNCATE);
    }
    float aspect = 1.5f;
    RECT rc = { 0 };
    if (g_gameWnd && GetClientRect(g_gameWnd, &rc) && rc.right > 0 && rc.bottom > 0)
        aspect = (float)rc.right / (float)rc.bottom;
    const float h = size * 0.75f * aspect;   /* x/y 单位比例不同：按客户区宽高比换成像素正方形 */
    DdhChartRect(f, x, yTop, x + size, yTop - h);
    DdhFrameShowHide((void*)(uintptr_t)f, 1);
}

static void DdhChartHideAll(void)
{
    /* 只有还停在同一�?CGameUI 上才碰旧帧；换图/退图后引擎可能已经释放它们�?
       这时只丢指针（不 free），避免 UAF�?*/
    const uint32_t curUi = DdhGetGameUi();
    const int sameUi = (g_ddhChartUi != 0 && curUi == g_ddhChartUi);
    if (sameUi)
    {
        for (int i = 0; i < DDH_CHART_FRAME_MAX; ++i)
            if (g_ddhChartFrames[i]) DdhFrameShowHide((void*)(uintptr_t)g_ddhChartFrames[i], 0);
        for (int i = 0; i < DDH_CHART_TEXT_MAX; ++i)
            if (g_ddhChartTexts[i]) DdhFrameShowHide((void*)(uintptr_t)g_ddhChartTexts[i], 0);
        for (int i = 0; i < DDH_CHART_ICON_MAX; ++i)
            if (g_ddhChartIcons[i]) DdhFrameShowHide((void*)(uintptr_t)g_ddhChartIcons[i], 0);
        return;
    }
    memset(g_ddhChartFrames, 0, sizeof(g_ddhChartFrames));
    memset(g_ddhChartFrameTex, 0, sizeof(g_ddhChartFrameTex));
    memset(g_ddhChartTexts, 0, sizeof(g_ddhChartTexts));
    memset(g_ddhChartIcons, 0, sizeof(g_ddhChartIcons));
    memset(g_ddhChartIconPath, 0, sizeof(g_ddhChartIconPath));
    g_ddhChartUi = 0;
}

static void DdhChartRenderOverview(void)
{
    char buf[96];
    const float base = g_ddhChartY - 0.250f;
    const float top  = g_ddhChartY - 0.050f;
    const float maxH = top - base;
    const float bw = 0.026f, gap = 0.012f;
    const float x0 = g_ddhChartX + 0.02f;
    const float mx = g_ddhChart.maxTotal > 0.01f ? g_ddhChart.maxTotal : 1.0f;
    const int nowSec = g_ddhDllTick ? (int)((GetTickCount() - g_ddhDllTick) / 1000u) : 0;

    DdhChartText(0, "承伤 · 最近 5 秒", g_ddhChartX,
                 g_ddhChartY, g_ddhChartFh * 1.05f, 0xFFF0E0C0u);
    g_ddhChartBarOk = 1;

    for (int i = 0; i < DDH_CHART_SECONDS; ++i)
    {
        const float t = g_ddhChart.total[i];
        float h = (t > 0.0f ? t / mx : 0.0f) * maxH;
        const float bx0 = x0 + (float)i * (bw + gap);
        const float bx1 = bx0 + bw;
        const float yTop = base + (h > 0.012f ? h : 0.012f);

        if (DdhChartFrameTexSet(i))
        {
            DdhChartRect(g_ddhChartFrames[i], bx0, yTop, bx1, base);
            DdhFrameShowHide((void*)(uintptr_t)g_ddhChartFrames[i], 1);
        }
        g_ddhChartBar[i][0] = bx0;
        g_ddhChartBar[i][1] = bx1;
        g_ddhChartBar[i][2] = yTop;
        g_ddhChartBar[i][3] = base;

        DdhChartFormatAmount(buf, sizeof(buf), t);
        DdhChartText(1 + i, buf, bx0 - 0.004f, yTop + 0.006f, g_ddhChartFh * 0.85f, 0xFFFFD080u);
        {
            int sec = nowSec - (DDH_CHART_SECONDS - 1 - i);
            if (sec < 0) sec = 0;
            _snprintf_s(buf, sizeof(buf), _TRUNCATE, "%02d:%02d", sec / 60, sec % 60);
        }
        DdhChartText(24 + i, buf, bx0 + 0.003f, base - g_ddhChartFh * 1.05f, g_ddhChartFh * 0.62f, 0xFFB0B0B0u);
    }
}

static void DdhChartRenderDetail(int bucket)
{
    static const char* kNames[DDH_CHART_TYPES] = { "物理", "法术", "纯粹", "移除" };
    static const uint32_t kColors[DDH_CHART_TYPES] = {
        0xFFFF8888u, 0xFF88AAFFu, 0xFFFFFFFFu, 0xFFCC99FFu
    };
    char buf[96];
    float typeTotal[DDH_CHART_TYPES] = { 0, 0, 0, 0 };
    float typeMax = 0.0f;

    const int nseg = g_ddhChart.segCount[bucket];
    for (int i = 0; i < nseg; ++i)
        typeTotal[g_ddhChart.seg[bucket][i].type] += g_ddhChart.seg[bucket][i].amount;
    for (int t = 0; t < DDH_CHART_TYPES; ++t)
        if (typeTotal[t] > typeMax) typeMax = typeTotal[t];

    DdhChartFormatAmount(buf, sizeof(buf), g_ddhChart.total[bucket]);
    {
        char title[96];
        _snprintf_s(title, sizeof(title), _TRUNCATE, "第 -%d 秒 · 承伤构成  %s",
                    DDH_CHART_SECONDS - bucket, buf);
        DdhChartText(0, title, g_ddhChartX,
                     g_ddhChartY, g_ddhChartFh * 1.05f, 0xFFF0E0C0u);
    }

    const float barX0 = g_ddhChartX + 0.075f;
    const float barMaxW = 0.150f;
    const float barH = 0.016f;
    int iconSlot = 0;

    for (int t = 0; t < DDH_CHART_TYPES; ++t)
    {
        const float rowY = g_ddhChartY - 0.050f - (float)t * 0.058f;
        const float rowBot = rowY - barH;

        DdhChartText(1 + t * 2, kNames[t], g_ddhChartX + 0.004f, rowY - barH * 0.15f,
                     g_ddhChartFh * 0.92f, kColors[t]);

        DdhChartFormatAmount(buf, sizeof(buf), typeTotal[t]);
        {
            char vbuf[96];
            const float pct = g_ddhChart.total[bucket] > 0.01f
                ? typeTotal[t] * 100.0f / g_ddhChart.total[bucket] : 0.0f;
            _snprintf_s(vbuf, sizeof(vbuf), _TRUNCATE, "%s (%.0f%%)", buf, (double)pct);
            DdhChartText(2 + t * 2, vbuf, g_ddhChartX + 0.300f, rowY - barH * 0.15f,
                         g_ddhChartFh * 0.85f, 0xFFC8C8C8u);
        }

        if (typeTotal[t] <= 0.01f) continue;

        const float fullW = (typeTotal[t] / (typeMax > 0.01f ? typeMax : 1.0f)) * barMaxW;
        float cx = barX0;
        for (int i = 0; i < nseg && cx < barX0 + fullW - 0.001f; ++i)
        {
            const DdhChartSeg* sg = &g_ddhChart.seg[bucket][i];
            if (sg->type != (uint8_t)t) continue;
            float w = sg->amount / typeTotal[t] * fullW;
            if (w < 0.003f) w = 0.003f;
            const float segEnd = (cx + w > barX0 + fullW) ? barX0 + fullW : cx + w;
            const int slot = 8 + t * 6 + (i % 6);
            if (DdhChartFrameTexSet(slot))
            {
                DdhChartRect(g_ddhChartFrames[slot], cx, rowY, segEnd, rowBot);
                DdhFrameShowHide((void*)(uintptr_t)g_ddhChartFrames[slot], 1);
            }
            /* 断点上方显示该来源头像（每个类型最�?3 个，避免糊成一片） */
            if (iconSlot < DDH_CHART_ICON_MAX && (i % 3) == 0)
            {
                const uint32_t code = g_ddhChart.src[sg->src].code;
                DdhChartIcon(iconSlot++, code, cx, rowY + 0.030f, 0.021f);
            }
            cx = segEnd + 0.0015f;
        }
    }

    g_ddhChartBarOk = 0;
    g_ddhChartBar[0][0] = g_ddhChartBar[0][1] = 0.0f;
}

/* Dota2 式单屏：左上伤害类型、右上来源（头像+伤害）、底部最近 5 秒柱状图；不再下钻。 */
static void DdhChartRenderCombined(void)
{
    static const char* kNames[DDH_CHART_TYPES] = { "物理", "法术", "纯粹", "移除" };
    static const uint32_t kLabel[DDH_CHART_TYPES] = { 0xFFFF7070u, 0xFF70B0FFu, 0xFFFFFFFFu, 0xFFC080FFu };
    static const char* kTeam[DDH_CHART_TYPES] = {
        "ReplaceableTextures\\TeamColor\\TeamColor00.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor01.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor08.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor03.blp" };
    char buf[96];
    float typeTotal[DDH_CHART_TYPES] = { 0, 0, 0, 0 };
    float srcType[DDH_CHART_MAX_SRC][DDH_CHART_TYPES];
    float srcTotal[DDH_CHART_MAX_SRC] = { 0 };
    memset(srcType, 0, sizeof(srcType));
    for (int b = 0; b < DDH_CHART_SECONDS; ++b)
    {
        for (int i = 0; i < g_ddhChart.segCount[b]; ++i)
        {
            const int ty = g_ddhChart.seg[b][i].type;
            const int sr = g_ddhChart.seg[b][i].src;
            const float am = g_ddhChart.seg[b][i].amount;
            typeTotal[ty] += am;
            srcType[sr][ty] += am;
            srcTotal[sr] += am;
        }
    }
    float grand = 0.0f, typeMax = 0.0f, srcMax = 0.0f;
    for (int b = 0; b < DDH_CHART_SECONDS; ++b) grand += g_ddhChart.total[b];
    for (int t = 0; t < DDH_CHART_TYPES; ++t) if (typeTotal[t] > typeMax) typeMax = typeTotal[t];
    for (int s = 0; s < g_ddhChart.srcCount; ++s) if (srcTotal[s] > srcMax) srcMax = srcTotal[s];
    g_ddhChartUnitMode = (grand > 10000000000.0f) ? 2 : (grand > 1000000.0f ? 1 : 0);

    if (g_ddhChart.fatalCode)
    {
        DdhChartIcon(10, g_ddhChart.fatalCode,
                     g_ddhChartX + 0.005f, g_ddhChartY + 0.001f, 0.024f);
    }
    DdhChartText(0, "阵亡总结", g_ddhChartX + 0.035f, g_ddhChartY,
                 g_ddhChartFh * 1.08f, 0xFFF0E0C0u);
    {
        char tb[64]; DdhChartFormatScaled(tb, sizeof(tb), grand);
        char tot[96]; _snprintf_s(tot, sizeof(tot), _TRUNCATE, "总伤害 %s", tb);
        DdhChartText(23, tot, g_ddhChartX + 0.238f, g_ddhChartY, g_ddhChartFh * (strlen(tot) > 10 ? 0.80f : 0.95f), 0xFFFFD080u);
    }

    for (int t = 0; t < DDH_CHART_TYPES; ++t)
    {
        const float rowY = g_ddhChartY - 0.042f - (float)t * 0.028f;
        DdhChartText(1 + t, kNames[t], g_ddhChartX + 0.004f, rowY + 0.0012f, g_ddhChartFh * 0.9f, kLabel[t]);
        const int slot = 20 + t;
        if (typeTotal[t] > 0.01f && DdhChartTexSetEx(slot, kTeam[t]))
        {
            float w = (typeTotal[t] / (typeMax > 0.01f ? typeMax : 1.0f)) * 0.085f;
            if (w < 0.004f) w = 0.004f;
            DdhChartRect(g_ddhChartFrames[slot], g_ddhChartX + 0.040f, rowY, g_ddhChartX + 0.040f + w, rowY - 0.012f);
            DdhFrameShowHide((void*)(uintptr_t)g_ddhChartFrames[slot], 1);
        }
        {
            char ab[64]; DdhChartFormatScaled(ab, sizeof(ab), typeTotal[t]);
            float pct = (typeTotal[t] > 0.01f && grand > 0.01f) ? typeTotal[t] * 100.0f / grand : 0.0f;
            _snprintf_s(buf, sizeof(buf), _TRUNCATE, "%.0f%%", (double)pct);
        }
        DdhChartText(5 + t, buf, g_ddhChartX + 0.134f, rowY + 0.0003f, g_ddhChartFh * (strlen(buf) > 9 ? 0.66f : 0.78f), 0xFFE0E0E0u);
    }

    int order[DDH_CHART_MAX_SRC]; int n = 0;
    for (int s = 0; s < g_ddhChart.srcCount; ++s) order[n++] = s;
    for (int i = 1; i < n; ++i) { int v = order[i], j = i - 1; while (j >= 0 && srcTotal[order[j]] < srcTotal[v]) { order[j + 1] = order[j]; --j; } order[j + 1] = v; }
    for (int k = 0; k < 4 && k < n; ++k)
    {
        const int s = order[k];
        const float rowY = g_ddhChartY - 0.042f - (float)k * 0.028f;
        DdhChartIcon(k, g_ddhChart.src[s].code, g_ddhChartX + 0.212f, rowY + 0.0012f, 0.011f);
        float cur = g_ddhChartX + 0.230f;
        for (int t = 0; t < DDH_CHART_TYPES; ++t)
        {
            if (srcType[s][t] <= 0.01f) continue;
            const int slot = 30 + k * DDH_CHART_TYPES + t;
            if (!DdhChartTexSetEx(slot, kTeam[t])) continue;
            float w = (srcType[s][t] / (srcMax > 0.01f ? srcMax : 1.0f)) * 0.055f;
            if (w < 0.003f) w = 0.003f;
            DdhChartRect(g_ddhChartFrames[slot], cur, rowY, cur + w, rowY - 0.012f);
            DdhFrameShowHide((void*)(uintptr_t)g_ddhChartFrames[slot], 1);
            cur += w;
        }
        {
            char ab[64]; DdhChartFormatScaled(ab, sizeof(ab), srcTotal[s]);
            float pct = (srcTotal[s] > 0.01f && grand > 0.01f) ? srcTotal[s] * 100.0f / grand : 0.0f;
            _snprintf_s(buf, sizeof(buf), _TRUNCATE, "%.0f%%", (double)pct);
        }
        DdhChartText(9 + k, buf, g_ddhChartX + 0.298f, rowY + 0.0003f, g_ddhChartFh * (strlen(buf) > 9 ? 0.64f : 0.76f), 0xFFE0E0E0u);
    }

    const float base = g_ddhChartY - 0.262f;
    const float top = g_ddhChartY - 0.196f;
    const float maxH = top - base;
    const float bw = 0.024f, gap = 0.0092f;
    const float x0 = g_ddhChartX + 0.004f;
    const float mx = g_ddhChart.maxTotal > 0.01f ? g_ddhChart.maxTotal : 1.0f;
    const int nowSec = g_ddhDllTick ? (int)((GetTickCount() - g_ddhDllTick) / 1000u) : 0;
    for (int i = 0; i < DDH_CHART_SECONDS; ++i)
    {
        const float tv = g_ddhChart.total[i];
        float h = (tv > 0.0f ? tv / mx : 0.0f) * maxH;
        const float bx0 = x0 + (float)i * (bw + gap);
        const float yTop = base + h;
        if (tv > 0.01f && DdhChartTexSetEx(i, "UI\\Widgets\\Glues\\LoadingBar\\Loading-BarFill.blp"))
        {
            DdhChartRect(g_ddhChartFrames[i], bx0, yTop, bx0 + bw, base);
            DdhFrameShowHide((void*)(uintptr_t)g_ddhChartFrames[i], 1);
        }
        DdhChartFormatAmount(buf, sizeof(buf), tv);
        DdhChartFormatBar(buf, sizeof(buf), tv);
        if (tv > 0.01f)
        DdhChartText(13 + i, buf, bx0 - 0.002f, yTop + 0.006f,
            g_ddhChartFh * (g_ddhChartUnitMode ? 0.46f : 0.55f), 0xFFFFD080u);
        {
            int sec = nowSec - (DDH_CHART_SECONDS - 1 - i);
            if (sec < 0) sec = 0;
            _snprintf_s(buf, sizeof(buf), _TRUNCATE, "%02d:%02d", sec / 60, sec % 60);
        }
        DdhChartText(24 + i, buf, bx0 + 0.003f, base - g_ddhChartFh * 1.05f, g_ddhChartFh * 0.62f, 0xFFB0B0B0u);
    }
}


static void DdhChartRender(void);
static void DdhChartToggleCollapsed(void);
static void DdhChartReviveCheck(void);

/* ---------- 收缩 / 展开 ---------- */
static float g_ddhChartIconL = 0.0f, g_ddhChartIconT = 0.0f;
static float g_ddhChartIconW = 0.026f, g_ddhChartIconH = 0.014f;
static DWORD g_ddhReviveAliveSince = 0;

static void DdhChartIconRect(void)
{
    g_ddhChartIconW = 0.026f;
    g_ddhChartIconH = 0.014f;
    g_ddhChartIconL = g_ddhChartX + g_ddhChartW - 0.030f;
    g_ddhChartIconT = g_ddhChartY - 0.003f;
}

static void DdhChartDrawToggle(void)
{
    DdhChartIconRect();
    const int slot = 44;
    if (DdhChartTexSetEx(slot, "UI\\Widgets\\BattleNet\\bnet-tooltip-background.blp"))
    {
        DdhChartRect(g_ddhChartFrames[slot],
                     g_ddhChartIconL - 0.005f, g_ddhChartIconT + 0.003f,
                     g_ddhChartIconL + g_ddhChartIconW + 0.003f, g_ddhChartIconT - g_ddhChartIconH - 0.004f);
        DdhFrameShowHide((void*)(uintptr_t)g_ddhChartFrames[slot], 1);
    }
    DdhChartText(38, g_ddhChartCollapsed ? "<<<" : ">>>",
                 g_ddhChartIconL, g_ddhChartIconT,
                 g_ddhChartFh * 0.85f, 0xFFFFD080u);
}

/* 收缩态：小面板（标题 + 总伤害 + 彩色条） */
static void DdhChartRenderCollapsed(void)
{
    static const char* kTeam[DDH_CHART_TYPES] = {
        "ReplaceableTextures\\TeamColor\\TeamColor00.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor01.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor08.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor03.blp" };
    float tt[DDH_CHART_TYPES] = { 0, 0, 0, 0 };
    float grand = 0.0f;
    for (int b = 0; b < DDH_CHART_SECONDS; ++b)
        for (int i = 0; i < g_ddhChart.segCount[b]; ++i)
        {
            const int ty = g_ddhChart.seg[b][i].type;
            tt[ty] += g_ddhChart.seg[b][i].amount;
            grand += g_ddhChart.seg[b][i].amount;
        }
    const float iconX = g_ddhChartX + 0.005f;
    const float textX = g_ddhChartX + 0.035f;
    if (g_ddhChart.fatalCode)
    {
        DdhChartIcon(10, g_ddhChart.fatalCode,
                     iconX, g_ddhChartY + 0.001f, 0.024f);
    }
    DdhChartText(0, "阵亡总结", textX,
                 g_ddhChartY - 0.002f, g_ddhChartFh * 0.72f, 0xFFF0E0C0u);
    {
        char tb[64]; DdhChartFormatScaled(tb, sizeof(tb), grand);
        char tot[96]; _snprintf_s(tot, sizeof(tot), _TRUNCATE, "总伤害 %s", tb);
        DdhChartText(39, tot, textX,
                     g_ddhChartY - 0.024f, g_ddhChartFh * 0.58f, 0xFFFFD080u);
    }
    const float barL = g_ddhChartX + 0.004f;
    const float barR = g_ddhChartX + g_ddhChartW - 0.006f;
    const float barW = (barR > barL) ? (barR - barL) : 0.0f;
    const float y0 = g_ddhChartY - 0.050f;
    const float y1 = g_ddhChartY - 0.070f;
    float cur = barL;
    const float den = (grand > 0.01f) ? grand : 1.0f;
    for (int t = 0; t < DDH_CHART_TYPES; ++t)
    {
        if (tt[t] <= 0.01f) continue;
        float w = tt[t] / den * barW;
        if (w < 0.002f) w = 0.002f;
        const int slot = 40 + t;
        if (!DdhChartTexSetEx(slot, kTeam[t])) continue;
        DdhChartRect(g_ddhChartFrames[slot], cur, y0, cur + w, y1);
        DdhFrameShowHide((void*)(uintptr_t)g_ddhChartFrames[slot], 1);
        cur += w;
    }
}

static void DdhChartToggleCollapsed(void)
{
    g_ddhChartCollapsed = g_ddhChartCollapsed ? 0 : 1;
    DdhChartReflow();
    DdhChartRender();
    g_ddhPanelHideAt = (LONG)(GetTickCount() + 60000);
    LogLine("图表：%s", g_ddhChartCollapsed ? "已收缩" : "已展开");
}

/* 收缩态下英雄复活：满 3 秒清掉面板 */
static int DdhChartEscCollapse(void)
{
    if (!(g_ddhPanelShown && g_ddhChartMode && !g_ddhChartCollapsed)) return 0;
    DdhChartToggleCollapsed();
    return 1;
}

static void DdhChartReviveCheck(void)
{
    if (!(g_ddhPanelShown && g_ddhChartMode && g_ddhChartCollapsed && g_ddhChart.victim)) return;
    float hp = 0.0f;
    if (!(ReadUnitHp(g_ddhChart.victim, &hp) && hp > 0.5f)) { g_ddhReviveAliveSince = 0; return; }
    const DWORD now = GetTickCount();
    if (!g_ddhReviveAliveSince) { g_ddhReviveAliveSince = now; return; }
    if (now - g_ddhReviveAliveSince >= 3000)
    {
        g_ddhReviveAliveSince = 0;
        LogLine("面板：英雄已复活，收缩态面板 3 秒到，清除");
        DdhPanelHide();
    }
}

static void DdhChartReflow(void)
{
    const float fullW = 0.34f, fullH = 0.32f;
    const float w = g_ddhChartCollapsed ? 0.1433f : fullW;
    const float h = g_ddhChartCollapsed ? 0.070f : fullH;
    float cx = g_ddhChartCollapsed ? (g_ddhChartWantX + fullW - w) : g_ddhChartWantX;
    float cy = g_ddhChartWantY;
    if (cx < 0.005f) cx = 0.005f;
    if (cx + w > 0.795f) cx = 0.795f - w;
    if (cy > -0.005f) cy = -0.005f;
    if (cy - h < -0.595f) cy = -0.595f + h;
    g_ddhChartX = cx; g_ddhChartY = cy; g_ddhChartW = w; g_ddhChartH = h;
    float hitL = cx - 0.012f, hitT = cy + 0.012f;
    float hitW = w + 0.024f, hitH = h + 0.024f;
    if (hitL + hitW > 0.995f) hitL = 0.995f - hitW;
    if (hitL < -0.995f) hitL = -0.995f;
    if (hitT - hitH < -0.995f) hitT = -0.995f + hitH;
    g_ddhPanelHitL = hitL; g_ddhPanelHitT = hitT;
    g_ddhPanelHitW = hitW; g_ddhPanelHitH = hitH;
    if (!g_ddhPanelBgFrame) return;
    uint32_t bl = g_ddhPanelNoSub ? g_ddhPanelBgFrame : g_ddhPanelBgFrame + DDH_OFF_UI_LAYOUT_SUB;
    const uint32_t rel = g_ddhChartUi + DDH_OFF_UI_LAYOUT_SUB;
    __try
    {
        ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)((void*)(uintptr_t)bl, 0, 0u, rel, 0u, hitL, hitT, 1);
        ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)((void*)(uintptr_t)bl, 0, 8u, rel, 0u, hitL + hitW, hitT - hitH, 1);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelBgFrame, 1);
}


static void DdhChartRender(void)
{
    if (!g_ddhChartMode) return;
    DdhChartHideAll();
    if (g_ddhChartCollapsed) DdhChartRenderCollapsed();
    else DdhChartRenderCombined();
    DdhChartDrawToggle();
}

static void DdhChartHide(void)
{
    if (g_ddhPanelBgFrame) DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelBgFrame, 0);
    DdhChartHideAll();
    g_ddhChartMode = 0;
    g_ddhChartView = 0;
    g_ddhChartBarOk = 0;
}

/* 图表点击：总览点柱�?�?下钻该秒；下钻任意位�?�?回总览�?*/
static void DdhChartClick(int px, int py)
{
    static DWORD lastClick = 0;
    const DWORD nowClick = GetTickCount();
    if (nowClick - lastClick < 120u) return;   /* 一次点击会来两条 UP，防抖只作用于点击 */
    lastClick = nowClick;
    const int toggleHit = DdhChartToggleHitTest(px, py);
    if (InterlockedIncrement(&g_ddhPanelClickLogged) <= 12)
        LogLine("图表点击：进入 (%d,%d) 伸缩按钮=%d 帧矩形=%d",
                px, py, toggleHit, (int)g_ddhPanelFrameRectOk);
    if (toggleHit)
    {
        DdhChartToggleCollapsed();
        return;
    }
    if (!g_ddhChartMode) return;
    RECT rc = { 0 };
    if (!g_gameWnd || !GetClientRect(g_gameWnd, &rc)) return;
    const int cw = rc.right - rc.left;
    const int ch = rc.bottom - rc.top;
    if (cw <= 0 || ch <= 0) return;

    const float u = (float)px / (float)cw;
    const float v = -(float)py / (float)ch;

    int changed = 0;
    if (g_ddhChartView == 0)
    {
        for (int i = 0; i < DDH_CHART_SECONDS && g_ddhChartBarOk; ++i)
        {
            if (u >= g_ddhChartBar[i][0] && u <= g_ddhChartBar[i][1] &&
                v <= g_ddhChartBar[i][2] && v >= g_ddhChartBar[i][3])
            {
                g_ddhChartView = i + 1;
                changed = 1;
                break;
            }
        }
        if (!changed) return;                     /* 点空白：保持总览 */
    }
    else
    {
        g_ddhChartView = 0;                       /* 下钻里点任何位置都回总览 */
        changed = 1;
    }

    if (changed)
    {
        DdhChartRender();
        uint32_t ttl = g_ddhPendingPanel.ttlMs;
        if (ttl == 0) ttl = 20000;
        if (ttl < 1000) ttl = 1000;
        if (ttl > 600000) ttl = 600000;
        g_ddhPanelHideAt = (LONG)(GetTickCount() + ttl);
        if (InterlockedIncrement(&g_ddhChartLogCount) <= 40)
            LogLine("图表：点击 -> %s", g_ddhChartView ? "下钻" : "总览");
    }
}

/* mock 数据�? 个桶�? 个来源�? 类伤害都有，专门用来调样式（不需要真的挨�?死亡）�?*/
static void DdhChartDemoFill(void)
{
    memset(&g_ddhChart, 0, sizeof(g_ddhChart));
    static const uint32_t kCodes[4] = { 0x4870616Cu, 0x68666F6Fu, 0x6E776C74u, 0x486D6B67u };
    static const uint32_t kAddrs[4] = { 0x10001000u, 0x10002000u, 0x10003000u, 0x10004000u };
    for (int i = 0; i < 4; ++i)
    {
        g_ddhChart.src[i].addr = kAddrs[i];
        g_ddhChart.src[i].code = kCodes[i];
        g_ddhChart.src[i].total = 0.0f;
    }
    g_ddhChart.srcCount = 4;

    struct { int b, t, s; float a; } demo[] = {
        { 0, 0, 0,  140.0f }, { 0, 2, 1,   60.0f },
        { 1, 0, 1,  220.0f }, { 1, 1, 2,   90.0f },
        { 2, 0, 0,  300.0f }, { 2, 3, 3,   80.0f },
        { 3, 0, 2,  260.0f }, { 3, 1, 0,  120.0f },
        { 4, 0, 1,  180.0f }, { 4, 2, 3,   70.0f },
        { 5, 0, 0,  320.0f }, { 5, 1, 1,  140.0f },
        { 6, 0, 1,  820.0f }, { 6, 2, 3,  260.0f }, { 6, 1, 0, 160.0f },
        { 7, 0, 0,   90.0f }, { 7, 3, 2,  110.0f },
        { 8, 0, 0, 1450.0f }, { 8, 1, 3,  920.0f }, { 8, 2, 1, 700.0f }, { 8, 3, 2, 640.0f },
        { 9, 0, 1,  980.0f }, { 9, 1, 0,  860.0f }, { 9, 0, 3, 520.0f }
    };
    for (int i = 0; i < (int)(sizeof(demo) / sizeof(demo[0])); ++i)
        DdhChartAdd(demo[i].b, demo[i].t, kAddrs[demo[i].s], kCodes[demo[i].s], demo[i].a * 105.374f);   /* mock 总伤害 ≈ 999999 */

    for (int i = 0; i < DDH_CHART_SECONDS; ++i)
        if (g_ddhChart.total[i] > g_ddhChart.maxTotal) g_ddhChart.maxTotal = g_ddhChart.total[i];

    for (int b = 0; b < DDH_CHART_SECONDS; ++b)
    {
        for (int i = 1; i < g_ddhChart.segCount[b]; ++i)
        {
            DdhChartSeg t = g_ddhChart.seg[b][i];
            int j = i - 1;
            while (j >= 0 && g_ddhChart.seg[b][j].amount < t.amount)
            {
                g_ddhChart.seg[b][j + 1] = g_ddhChart.seg[b][j];
                --j;
            }
            g_ddhChart.seg[b][j + 1] = t;
        }
    }
    g_ddhChart.valid = 1;
    g_ddhChart.victim = 0xC0FFEE00u;
    int usedAlt = 0;
    const uint32_t selected = DdhReadSelection(&usedAlt);
    const uint32_t selectedCode = SafeCode(selected);
    g_ddhChart.fatalSource = selected;
    g_ddhChart.fatalCode = selectedCode;
    if (!selected || !selectedCode)
    {
        g_ddhChart.fatalSource = 0x10004000u;
        g_ddhChart.fatalCode = 0x486D6B67u;
    }
}

static int DdhChartApply(uint32_t ui, const DdhPanelBlock* p, uint32_t victim,
                         float x, float y, float fh, const char* font)
{
    if (g_ddhPanelDisabled) return -1;
    if (!g_ddhUiCreateBackdrop || !g_ddhUiSetBackdrop || !g_ddhUiCreateText)
        return -1;

    /* 换图/UI 重建：旧帧对象可能已被引擎释放，只丢指针�?free，按�?UI 重建（与面板同策略）�?*/
    if (g_ddhChartBaseTick == 0) g_ddhChartBaseTick = GetTickCount();
    if (g_ddhChartUi != ui)
    {
        memset(g_ddhChartFrames, 0, sizeof(g_ddhChartFrames));
        memset(g_ddhChartFrameTex, 0, sizeof(g_ddhChartFrameTex));
        memset(g_ddhChartTexts, 0, sizeof(g_ddhChartTexts));
        memset(g_ddhChartIcons, 0, sizeof(g_ddhChartIcons));
        memset(g_ddhChartIconPath, 0, sizeof(g_ddhChartIconPath));
    }

    /* 屏幕内钳制：图表总宽/高固定，先把左上角拉�?[-0.99, 0.99]�?
       否则 x 偏右时会像之前那样被窗口右边缘裁掉一半�?*/
    const float fullW = 0.34f, fullH = 0.32f;
    const float chartW = g_ddhChartCollapsed ? 0.1433f : fullW;
    const float chartH = g_ddhChartCollapsed ? 0.070f : fullH;
    float cx = g_ddhChartCollapsed ? (x + fullW - chartW) : x;
    float cy = -0.10f;
    if (cx < 0.005f) cx = 0.005f;
    if (cx + chartW > 0.795f) cx = 0.795f - chartW;
    if (cy > -0.005f) cy = -0.005f;
    if (cy - chartH < -0.595f) cy = -0.595f + chartH;

    g_ddhChartUi = ui;
    g_ddhPanelUi = ui;
    g_ddhChartX = cx;
    g_ddhChartY = cy;
    g_ddhChartFh = fh;
    g_ddhChartW = chartW;
    g_ddhChartH = chartH;
    g_ddhChartWantX = x;
    g_ddhChartWantY = cy;

    g_ddhChartUi = ui;
    g_ddhPanelUi = ui;
    g_ddhChartX = cx;
    g_ddhChartY = cy;
    g_ddhChartFh = fh;
    strncpy_s(g_ddhChartFont, sizeof(g_ddhChartFont), font, _TRUNCATE);
    g_ddhChartView = 0;
    g_ddhChartMode = 1;

    int ok = 1;
    if (g_ddhChartDemo)
    {
        g_ddhChartDemo = 0;
        DdhChartDemoFill();
    }
    else
    {
        ok = DdhChartBuild(victim);
        if (!ok && InterlockedIncrement(&g_ddhChartLogCount) <= 10)
            LogLine("图表：victim 0x%08X 最近 5 秒没有可用伤害事件（victim=%d）", victim, victim ? 1 : 0);
    }

    /* 面板命中区：整个图表区域（点柱子再细分） */
    float hitL = cx - 0.012f, hitT = cy + 0.012f;
    float hitW = chartW + 0.024f, hitH = chartH + 0.024f;
    if (hitL + hitW > 0.995f) hitL = 0.995f - hitW;
    if (hitL < -0.995f) hitL = -0.995f;
    if (hitT - hitH < -0.995f) hitT = -0.995f + hitH;
    g_ddhPanelHitL = hitL;
    g_ddhPanelHitT = hitT;
    g_ddhPanelHitW = hitW;
    g_ddhPanelHitH = hitH;
    g_ddhPanelFrameRectOk = 0;
    g_ddhPanelClickOk = 1;
    g_ddhPanelMouseDown = 0;

    /* 背景：图表模式没走文本面板那条路，这里单独建/摆一次面板背景帧（暗�?+ 边框），
       否则亮地形上根本看不清柱子和文字�?*/
    DdhPanelEnsureBackdrop(ui, 1);
    if (g_ddhPanelBgFrame)
    {
        uint32_t bl = g_ddhPanelNoSub ? g_ddhPanelBgFrame : g_ddhPanelBgFrame + DDH_OFF_UI_LAYOUT_SUB;
        const uint32_t rel = ui + DDH_OFF_UI_LAYOUT_SUB;
        __try
        {
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)bl, 0, 0u, rel, 0u, hitL, hitT, 1);
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)bl, 0, 8u, rel, 0u, hitL + hitW, hitT - hitH, 1);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        DdhFrameShowHide((void*)(uintptr_t)g_ddhPanelBgFrame, 1);
    }

    DdhChartRender();

    uint32_t ttl = p->ttlMs;
    if (ttl == 0) ttl = 20000;
    if (ttl < 1000) ttl = 1000;
    if (ttl > 600000) ttl = 600000;
    g_ddhPanelHideAt = (LONG)(GetTickCount() + ttl);
    g_ddhPanelShown = 1;

    if (InterlockedIncrement(&g_ddhChartLogCount) <= 10)
        LogLine("图表：已显示（victim=0x%08X，5 秒总伤 %.0f，最大桶 %.0f，来源 %d 个，ui=0x%08X，ttl=%u）",
                victim, (double)g_ddhChart.total[0] + g_ddhChart.total[1] + g_ddhChart.total[2] +
                g_ddhChart.total[3] + g_ddhChart.total[4],
                (double)g_ddhChart.maxTotal, g_ddhChart.srcCount, ui, ttl);
    return 1;
}

static void DdhChartToggleView(void)
{
    if (!g_ddhChartMode) { LogLine("图表：Ctrl+Alt+E 但没有图表"); return; }
    g_ddhChartView = (g_ddhChartView == 0) ? 4 : 0;
    DdhChartRender();
    g_ddhPanelHideAt = (LONG)(GetTickCount() + 60000);
    LogLine("图表：Ctrl+Alt+E -> %s", g_ddhChartView ? "下钻（第 -2 秒）" : "总览");
}

static void DdhPanelClickAt(int x, int y)
{
    if (g_ddhChartMode) { DdhChartClick(x, y); return; }
    DdhDoTogglePanel();
}

/* Ctrl+Alt+C：调�?自测——用事件环里“最近一次受击的单位”直接开一张承伤图表，
   不需要英雄死亡、也不需�?C# 参与；伤害数据照样来�?ddh 自己的事件环�?*/
static void DdhChartDebugShow(void)
{
    if (!DdhInitUiFuncs()) { LogLine("图表调试：UI 函数未就绪"); return; }
    uint32_t ui = DdhGetGameUi();
    if (!ui) { LogLine("图表调试：GetGameUI 为空（还没进图？）"); return; }

    uint32_t victim = 0;
    if (g_shm && g_shm->hdr.count)
    {
        const uint32_t cap = g_shm->hdr.capacity ? g_shm->hdr.capacity : DDH_MAX_EVENTS;
        const uint32_t count = g_shm->hdr.count;
        for (uint32_t k = 0; k < cap && k < count; ++k)
        {
        uint32_t seq = count - k;
        if (seq == 0) break;
            const DdhEvent* e = &g_shm->ev[(seq - 1) % cap];
            if (e->seq != seq) continue;
            victim = e->victim;
            break;
        }
    }
    if (!victim)
    {
        LogLine("图表调试：事件环里还没有伤害事件（先让任意单位挨一下）");
        return;
    }

    DdhPanelReadEnvOnce();
    DdhPanelBlock blk;
    memset(&blk, 0, sizeof(blk));
    blk.flags = DDH_PANEL_FLAG_SHOW | DDH_PANEL_FLAG_BG | DDH_PANEL_FLAG_CHART;
    blk.ttlMs = 20000;
    blk.anchor = 0;
    blk.x = 0.60f;
    blk.y = -0.10f;
    blk.fontHeight = 0.0135f;
    blk.lineHeight = 0.0175f;
    strcpy_s(blk.fontName, sizeof(blk.fontName), "MasterFont");

    /* 存一份：~ 隐藏后再按还能出来；点击重置 TTL 也用同一�?*/
    memcpy(&g_ddhLastPanel, &blk, sizeof(g_ddhLastPanel));
    g_ddhHaveLastPanel = 1;
    g_ddhPanelPinned = 0;

    DdhChartApply(ui, &blk, victim, blk.x, blk.y, blk.fontHeight, blk.fontName);
    if (InterlockedIncrement(&g_ddhChartLogCount) <= 40)
        LogLine("图表调试：Ctrl+Alt+C -> victim 0x%08X", victim);
}

/* Ctrl+Alt+D：mock 数据演示（调样式用；不依赖伤害事件、不依赖死亡、不依赖 C#）�?*/
static void DdhChartDemoShow(void)
{
    if (!DdhInitUiFuncs()) { LogLine("图表演示：UI 函数未就绪"); return; }
    uint32_t ui = DdhGetGameUi();
    if (!ui) { LogLine("图表演示：GetGameUI 为空（还没进图？）"); return; }
    DdhPanelReadEnvOnce();

    DdhPanelBlock blk;
    memset(&blk, 0, sizeof(blk));
    blk.flags = DDH_PANEL_FLAG_SHOW | DDH_PANEL_FLAG_BG | DDH_PANEL_FLAG_CHART;
    blk.ttlMs = 60000;
    blk.anchor = 0;
    blk.x = 0.60f;
    blk.y = -0.10f;
    blk.fontHeight = 0.0135f;
    blk.lineHeight = 0.0175f;
    strcpy_s(blk.fontName, sizeof(blk.fontName), "MasterFont");

    memcpy(&g_ddhLastPanel, &blk, sizeof(g_ddhLastPanel));
    g_ddhHaveLastPanel = 1;
    g_ddhPanelPinned = 0;

    g_ddhChartDemo = 1;
    DdhChartApply(ui, &blk, 0, blk.x, blk.y, blk.fontHeight, blk.fontName);
    LogLine("图表演示：Ctrl+Alt+D（mock 数据，60 秒 TTL）");
}

/* ---- 英雄查询�?6 槽，�?rawcode 缓存�?---- */
static uint32_t   g_ddhHeroCacheCode[64];
static int8_t     g_ddhHeroCacheVal[64];
static int        g_ddhHeroCacheCount = 0;

static int DdhIsHeroRaw(uint32_t rawcode)
{
    if (!rawcode) return -1;
    for (int i = 0; i < g_ddhHeroCacheCount; i++)
        if (g_ddhHeroCacheCode[i] == rawcode) return (int)g_ddhHeroCacheVal[i];

    uint32_t out = 0;
    if (!DdhAttrCallU32(DDH_AN_IS_HERO_ID, rawcode, 0, &out))
        return -1;

    const int val = out ? 1 : 0;
    if (g_ddhHeroCacheCount < (int)(sizeof(g_ddhHeroCacheCode) / sizeof(g_ddhHeroCacheCode[0])))
    {
        g_ddhHeroCacheCode[g_ddhHeroCacheCount] = rawcode;
        g_ddhHeroCacheVal[g_ddhHeroCacheCount] = (int8_t)val;
        g_ddhHeroCacheCount++;
    }
    return val;
}

static void DdhProcessHeroRequest(void)
{
    if (!g_shm) return;
    const uint32_t seq = g_shm->hero.seq;
    if (!seq || seq == (uint32_t)g_ddhHeroAppliedSeq) return;

    DdhHeroBlock local;
    memset(&local, 0, sizeof(local));
    memcpy(&local, &g_shm->hero, sizeof(local));

    int n = (int)local.count;
    if (n < 0) n = 0;
    if (n > DDH_HERO_SLOTS) n = DDH_HERO_SLOTS;

    /* 头像需�?DzAPI 类型数据；如果本次进程还没有 ATTR 请求，先用英雄查询里�?
       真实单位句柄做一次探测，否则 typeDataOk 一直是 0，头像路径只能靠 GetUnitData 猜�?*/
    if (n > 0 && local.req[0].addr)
    {
        const uint32_t probeHandle = HpObjToHandle(local.req[0].addr);
        if (probeHandle)
        {
            if (!g_ddhTypeDataProbeDone)
                DdhTypeDataProbe(probeHandle, local.req[0].rawcode);
            if (!g_ddhTypeDataOk)
                DdhTypeDataProbeIcon(probeHandle, local.req[0].rawcode);
        }
    }

    for (int i = 0; i < DDH_HERO_SLOTS; i++)
    {
        if (i < n)
        {
            local.res[i].addr = local.req[i].addr;
            local.res[i].rawcode = local.req[i].rawcode;
            local.res[i].isHero = DdhIsHeroRaw(local.req[i].rawcode);
            local.res[i].pad = 0xFFFFFFFFu;   /* 幻象判定�?=�?0=�?0xFFFFFFFF=未知 */
            const int illusion = DdhUnitIllusionStateByObj(local.req[i].addr);
            if (illusion >= 0)
            {
                local.res[i].pad = illusion ? 1u : 0u;
            }
        }
        else
        {
            memset(&local.res[i], 0, sizeof(local.res[i]));
        }
    }

    if (n > 0)
        g_ddhSuppressPanel = (local.res[0].pad == 1u) ? 1 : 0;

    memcpy(&g_shm->hero, &local, sizeof(local));
    MemoryBarrier();
    g_ddhHeroAppliedSeq = (LONG)seq;
    g_shm->hero.appliedSeq = seq;
    MemoryBarrier();

    if (InterlockedIncrement(&g_ddhHeroLogCount) <= 10)
        LogLine("面板：英雄查询 seq=%u 共 %d 项，首项 rawcode=0x%08X isHero=%d isIllusion=%d（缓存 %d）",
                seq, n, n > 0 ? local.req[0].rawcode : 0,
                n > 0 ? local.res[0].isHero : -9,
                n > 0 ? (int)local.res[0].pad : -9, g_ddhHeroCacheCount);
}

/* 热键线程：只投消息，不碰引擎�?*/
static void DdhMaybePostPanelAndHero(void)
{
    if (!g_shm) return;
    if (!DdhEnsureGameWnd()) return;

    const uint32_t ps = g_shm->panel.seq;
    if (ps && ps != (uint32_t)g_ddhPanelPostedSeq)
    {
        if (PostMessageW(g_gameWnd, DDH_WM_PANEL, 0, 0))
            g_ddhPanelPostedSeq = (LONG)ps;
    }
    const uint32_t hs = g_shm->hero.seq;
    if (hs && hs != (uint32_t)g_ddhHeroPostedSeq)
    {
        if (PostMessageW(g_gameWnd, DDH_WM_HERO, 0, 0))
            g_ddhHeroPostedSeq = (LONG)hs;
    }

    /* 面板已收到但 UI 还没就绪（未进图/主菜单）时，�?500ms 再叫一次游戏线程重试；
       这样不用等下一次伤害事件也能在进图后补显示�?*/
    if (g_ddhPendingValid && GetTickCount() - (DWORD)g_ddhPendingPostTick >= 500)
    {
        if (PostMessageW(g_gameWnd, DDH_WM_PANEL, 0, 0))
            g_ddhPendingPostTick = (LONG)GetTickCount();
    }

    /* v16：面板显示期间每 500ms 让游戏线程跑一�?TTL 检查（C# 关闭/卡住也能自动隐藏�?
       鼠标点击切换后重置的 TTL 也靠它生效）�?*/
    if (GetTickCount() - (DWORD)g_ddhPanelTickPost >= 500)
    {
        if (PostMessageW(g_gameWnd, DDH_WM_PANEL_TICK, 0, 0))
            g_ddhPanelTickPost = (LONG)GetTickCount();
    }
}

/* ---- demo：不依赖 C#，第一次最外层伤害退出后显示一屏示例，方便真机验证字体/坐标 ---- */
static int DdhPanelDemoOn(void)
{
    if (DdhEnvTruthy("DDH_PANEL_DEMO")) return 1;
    char dir[MAX_PATH] = { 0 };
    if (g_logPath[0]) strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) slash[1] = 0; else dir[0] = 0;
    char path[MAX_PATH] = { 0 };
    DdhSprintf(path, sizeof(path), "%sddh_paneldemo.on", dir);
    const DWORD attr = GetFileAttributesA(path);
    return attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

static void DdhPanelDemoOnce(void)
{
    if (InterlockedCompareExchange(&g_ddhPanelDemoDone, 1, 0) != 0) return;
    if (!DdhPanelDemoOn()) return;

    DdhPanelBlock p;
    memset(&p, 0, sizeof(p));
    p.seq = 1;
    p.flags = DDH_PANEL_FLAG_SHOW | DDH_PANEL_FLAG_BG |
              ((uint32_t)3u << DDH_PANEL_COLLAPSED_SHIFT);
    p.ttlMs = 60000;
    p.anchor = 0;
    p.x = 0.60f;
    p.y = -0.24f;
    p.lineHeight = 0.0175f;
    p.fontHeight = 0.0135f;
    strcpy_s(p.fontName, sizeof(p.fontName), "MasterFont");

    static const char* demo[] = {
        "\xE3\x80\x90\xE9\x98\xB5\xE4\xBA\xA1\xE6\x80\xBB\xE7\xBB\x93\xE3\x80\x91",              /* 【阵亡总结�?*/
        "\xE5\x89\x91\xE5\x9C\xA3\xEF\xBC\x88Hmkg\xEF\xBC\x89",                                    /* 剑圣（Hmkg�?*/
        "\xE7\x8E\xA9\xE5\xAE\xB6 1 \xC2\xB7 \xE7\xAC\xAC 2 \xE6\x9D\xA1\xE5\x91\xBD",            /* 玩家 1 · �?2 条命 */
        "\xE6\x89\xBF\xE5\x8F\x97\xE4\xBC\xA4\xE5\xAE\xB3 3,200",                                  /* 承受伤害 3,200 */
        "\xE6\x9C\x80\xE6\x83\xA8 1 \xE7\xA7\x92 1,746",                                            /* 最�?1 �?1,746 */
        "\xE5\xB1\xB1\xE4\xB8\x98\xE4\xB9\x8B\xE7\x8E\x8B(Hmkg) 45.9% 1,468",                      /* 山丘之王(Hmkg) ... */
        "\xE8\xBF\x91\xE6\x88\x98 1,668 / \xE8\xBF\x9C\xE7\xA8\x8B 1,532",                          /* 近战 / 远程 */
        "\xE8\x87\xAA\xE6\xB5\x8B\xE9\x9D\xA2\xE6\x9D\xBF demo\xEF\xBC\x9A\xE5\xAD\x97\xE4\xBD\x93\xE4\xB8\x8E\xE5\x9D\x90\xE6\xA0\x87", /* 自测面板 demo：字体与坐标 */
    };
    const int n = (int)(sizeof(demo) / sizeof(demo[0]));
    p.lineCount = (uint32_t)n;
    const uint32_t colors[8] = {
        0xFFFFCC66u, 0xFFFFFFFFu, 0xFFB0B0B0u, 0xFFFFFFFFu,
        0xFFB0B0B0u, 0xFFFF6666u, 0xFFFFFFFFu, 0xFF88DD88u,
    };
    for (int i = 0; i < n; i++)
    {
        p.lines[i].color = colors[i % 8];
        strncpy_s(p.lines[i].text, sizeof(p.lines[i].text), demo[i], _TRUNCATE);
    }
    g_ddhPanelCollapsed = ((p.flags & DDH_PANEL_FLAG_COLLAPSED) != 0) ? 1 : 0;
    g_ddhPanelCollapsedLines = 3;
    g_ddhPanelIconCount = 0;   /* demo 不带图标，避免沿用上一条面�?*/
    memcpy(&g_ddhPendingPanel, &p, sizeof(g_ddhPendingPanel));   /* 让鼠标点击也能切�?demo */
    const int r = DdhPanelApply(&p);
    if (r < 0) DdhPanelFallback(&p);
    LogLine("面板 demo 异常 code=%08X（已吞掉）",
            r > 0 ? "已显示" : "不可用，已走兜底", n);
}

/* ===========================================================================
   DDH_ENGINE_PROBE —�?探针：地图不�?GetEventDamage 时，能不能自己拿到“引擎伤害”？
   ---------------------------------------------------------------------------
   背景�?026-11-01）：GetEventDamage 的实现就�?`mov eax,[eax+0x30]; ret`
   （game.dll+0x1E21D0 �?0x1E5D70 取当前事件对�?�?+0x30 就是“引擎伤害”）�?
   所以这个值本身一直存在，缺的只是**采样时机**：引擎在伤害函数内部、护甲算�?
   之后才写 +0x30，而我们的钩子在函数入口；等原函数返回，事件对象已经出栈�?

   本探针不改任何统计，只在每次伤害事件�?*入口**�?*出口**各调一�?
   GetEventDamage 的原实现（地址在手、__try 保护），把结果和“地图真读到的首值�?
   （g_engineCap/g_engineFirstSet）和“原始伤害”（info+0x10）摆在同一行日志里�?
     · 入口就相�?    �?现有钩子直接补，不用加新钩子（最省事）；
     · 出口才相�?    �?也能用；
     · 两边都不�?    �?另找采样点（钩“写 +0x30”的指令 / 钩触发器派发）�?

   开关（默认关，两种都认）：
     · 环境变量 DDH_ENGINE_PROBE=1�?
     · 或�?ddh.dll/日志同目录放一个空文件 ddh_engineprobe.on
       （启动器不继承环境变量时用这个）�?
   日志形如�?
     引擎探针[12] depth=1 原始=548.00 入口+0x30=438.40 出口+0x30=438.40 地图首�?438.40 取次=44
   =========================================================================== */
static int            g_engineProbe       = 0;    /* 0=未定�?1=开 -1=�?*/
static volatile LONG  g_engineProbeLogged = 0;
static volatile LONG  g_engineProbeNoCall = 0;
static uint32_t       g_probeEntryOk[DDH_MAXDEPTH];
static float          g_probeEntryVal[DDH_MAXDEPTH];
static uint32_t       g_probeInfo[DDH_MAXDEPTH];      /* 本层伤害结构�?info 指针（出口时用来 dump 字段�?*/

/* 文件开关：日志目录下的 ddh_engineprobe.on（同 DDH_UNITDUMP 的套路） */
static int DdhEngineProbeFlagFile(void)
{
    char dir[MAX_PATH] = { 0 };
    if (g_logPath[0]) strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) slash[1] = 0;
    else dir[0] = 0;
    char path[MAX_PATH] = { 0 };
    DdhSprintf(path, sizeof(path), "%sddh_engineprobe.on", dir);
    const DWORD attr = GetFileAttributesA(path);
    return attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

static int DdhEngineProbeOn(void)
{
    if (g_engineProbe != 0) return g_engineProbe > 0;

    int on = 0;
    char buf[32] = { 0 };
    const DWORD n = GetEnvironmentVariableA("DDH_ENGINE_PROBE", buf, (DWORD)sizeof(buf));
    if (n > 0 && n < (DWORD)sizeof(buf))
        on = !(_stricmp(buf, "0") == 0 || _stricmp(buf, "false") == 0 ||
               _stricmp(buf, "no") == 0 || _stricmp(buf, "off") == 0);
    else
        on = DdhEngineProbeFlagFile() ? 1 : 0;

    g_engineProbe = on ? 1 : -1;
    if (on)
        LogLine("引擎探针：已开启（%s）——每次伤害只多读两次内存，不改统计；"
                "日志形如“引擎探针[n] depth=.. 原始=.. 入口+0x30=.. 出口+0x30=.. 地图首值=.. 取次=..”",
                (n > 0 && n < (DWORD)sizeof(buf)) ? "DDH_ENGINE_PROBE" : "ddh_engineprobe.on");
    return on;
}

/* 调一�?GetEventDamage 的原实现�? 读当前事件对�?+0x30）。读不到/不在事件�?ok=0�?*/
static void DdhEngineProbeSample(uint32_t* ok, float* val)
{
    if (ok) *ok = 0;
    if (val) *val = 0.0f;
    if (!g_realGetEventDamage) return;

    uint32_t r = 0;
    __try { r = ((uint32_t (__cdecl*)(void))(uintptr_t)g_realGetEventDamage)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return; }

    float f = 0.0f;
    memcpy(&f, &r, 4);
    if (!(f > -1.0e12f && f < 1.0e12f)) return;
    if (ok) *ok = 1;
    if (val) *val = f;
}

/* 取“当�?JASS 事件对象”指针：�?GetEventDamage 的实现里把访问器地址抠出�?
   �?x1E21D0 �?+0x0C 处是 `E8 rel32` �?0x1E5D70），比写�?RVA 稳一点�?
   不在事件�?取不到就返回 0�?*/
static uint32_t DdhEngineEventObj(void)
{
    if (!g_realGetEventDamage) return 0;
    const uint8_t* p = (const uint8_t*)(uintptr_t)g_realGetEventDamage;
    if (p[0x0C] != 0xE8) return 0;

    int32_t rel = 0;
    memcpy(&rel, p + 0x0D, 4);
    const uint32_t fn = (uint32_t)(uintptr_t)(p + 0x11) + (uint32_t)rel;

    uint32_t obj = 0;
    __try { obj = ((uint32_t (__cdecl*)(void))(uintptr_t)fn)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { obj = 0; }
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return 0;
    return obj;
}

static void DdhEngineProbeEntry(uint32_t level, uint32_t infoPtr)
{
    if (level >= DDH_MAXDEPTH) return;
    g_probeInfo[level]     = infoPtr;
    g_probeEntryOk[level]  = 0;
    g_probeEntryVal[level] = 0.0f;

    /* 只在“还会写日志”的�?220 条事件里采样：探针最怕的是对每一发伤害都去调
       引擎访问器（一局几万次），那样出事也说不清是谁弄的�?*/
    if (InterlockedCompareExchange(&g_engineProbeLogged, 0, 0) < 220)
        DdhEngineProbeSample(&g_probeEntryOk[level], &g_probeEntryVal[level]);
}

static void DdhEngineProbeExit(uint32_t level, const DdhEvent* e, uint32_t seq)
{
    if (level >= DDH_MAXDEPTH) return;

    /* 先算“这条要不要记”，不记就直接走 —�?采样本身就是要额外调引擎函数，越少越�?*/
    const uint32_t calls = (uint32_t)g_engineCalls[level];
    const LONG total = InterlockedIncrement(&g_engineProbeLogged);
    bool want = (total <= 80);
    if (!want && calls == 0 && InterlockedIncrement(&g_engineProbeNoCall) <= 40) want = true;
    if (!want || total > 160) return;

    uint32_t ok = 0;
    float v = 0.0f;
    DdhEngineProbeSample(&ok, &v);

    float raw = 0.0f;
    if (e && e->seq == seq) raw = e->amount;

    char ent[24] = { 0 }, ext[24] = { 0 }, mapFirst[24] = { 0 };
    if (g_probeEntryOk[level]) DdhSprintf(ent, sizeof(ent), "%.2f", (double)g_probeEntryVal[level]);
    else                       strcpy_s(ent, sizeof(ent), "?");
    if (ok)                    DdhSprintf(ext, sizeof(ext), "%.2f", (double)v);
    else                       strcpy_s(ext, sizeof(ext), "?");
    if (g_engineFirstSet[level])
    {
        float f = 0.0f;
        memcpy(&f, &g_engineCap[level], 4);
        DdhSprintf(mapFirst, sizeof(mapFirst), "%.2f", (double)f);
    }
    else strcpy_s(mapFirst, sizeof(mapFirst), "?");

    /* info 结构体出口快照：看“护甲后的引擎伤害”有没有被引擎写回某个字�?
       （有 �?不用再加 hook；没�?�?只能在事件派发期间另开采样点） */
    char dump[160] = { 0 };
    char hit[24] = { 0 };
    const uint32_t ip = g_probeInfo[level];
    uint32_t d[10] = { 0 };
    bool dumpOk = false;
    if (ip > 0x10000 && ip < 0x7FFFFFFF)
    {
        __try
        {
            const uint32_t* p = (const uint32_t*)(uintptr_t)ip;
            for (int i = 0; i < 10; i++) d[i] = p[i];
            dumpOk = true;
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { dumpOk = false; }
    }
    if (dumpOk)
    {
        DdhSprintf(dump, sizeof(dump), "%08X %08X %08X %08X %08X %08X %08X %08X %08X %08X",
                   d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9]);
        if (g_engineFirstSet[level])
        {
            float mv = 0.0f;
            memcpy(&mv, &g_engineCap[level], 4);
            for (int i = 0; i < 10; i++)
            {
                float f = 0.0f;
                memcpy(&f, &d[i], 4);
                if (d[i] != 0 && fabs((double)f - (double)mv) <= 0.011)
                {
                    DdhSprintf(hit, sizeof(hit), "+0x%02X", i * 4);
                    break;
                }
            }
        }
        if (!hit[0]) strcpy_s(hit, sizeof(hit), g_engineFirstSet[level] ? "膵" : "?");
    }
    else
    {
        strcpy_s(dump, sizeof(dump), "?");
        strcpy_s(hit, sizeof(hit), "?");
    }

    char objTxt[24] = { 0 };
    const uint32_t eobj = DdhEngineEventObj();
    if (eobj)
    {
        float ov = 0.0f;
        __try { memcpy(&ov, (const void*)(uintptr_t)(eobj + 0x30), 4); }
        __except (EXCEPTION_EXECUTE_HANDLER) { ov = 0.0f; }
        DdhSprintf(objTxt, sizeof(objTxt), "%.2f", (double)ov);
    }
    else strcpy_s(objTxt, sizeof(objTxt), "无对象");

    LogLine("引擎探针[%ld] depth=%u 原始=%.2f 入口+0x30=%s 出口+0x30=%s 对象+0x30=%s 地图首值=%s 取次=%u 命中=%s 结构=%s",
            (long)total, level + 1, (double)raw, ent, ext, objTxt, mapFirst, (unsigned)calls, hit, dump);
}
/* ---- 替换函数：与 UDamageWatcherHook.cpp �?OurDamageFunc 同款 ----
   安装时把 0x67DC40 �?6 字节改成 jmp 到这里（__fastcall：ecx=_this, edx=_edx,
   栈上 4 个参�?a2/info/is_physical/source_unit）。函数里�?
     �?深度 +1、本层状态清零；�?懒挂 GetEventDamage/SetEventDamage�?
     �?读前血；④ RecordDamage 写事件（原始伤害 info+0x10 原样保留）；
     �?自己 call 原函数（跳板 �?原函数体 �?ret 0x10 回到这里），返回值原样带回；
     �?读后血、算 gross/own、补 hpAfter/actual/hpValid、给同目标父帧累计；
     �?写引擎伤�?设定值、诊断日志；�?记录单位的统�?死亡排队（v9）；
     �?深度 -1，回到最外层时处理热键待办和待发结算（v9）；�?return retval�?
   收尾�?ret 0x10（callee �?4 个栈参），与引擎原函数一致，�?build 后的反汇编校验�?*/
static uint32_t __fastcall DdhDamageFunc(uint32_t _this, uint32_t _edx, uint32_t a2,
                                         void* info, uint32_t is_physical, uint32_t source_unit)
{
    /* v9：第一次进伤害函数时把热键线程拉起来（此时游戏已就绪，也不在加载器锁里�?*/
    DdhEnsureHotkeyThread();

    /* 深度 +1；超过上限就不加（否则收尾的深度 -1 会对不上，深度永久泄漏）�?
       这一层仍然要跑原函数、把返回值原样带回去 —�?只是不再单独�?after�?*/
    LONG d = InterlockedIncrement(&g_depth);
    if (d > DDH_MAXDEPTH)
    {
        InterlockedDecrement(&g_depth);
        if (InterlockedIncrement(&g_depthOverflowLogged) == 1)
            LogLine("嵌套溢出：深度超过 %u 层，已退化为不记账（本进程只提示这一次）",
                    (uint32_t)DDH_MAXDEPTH);
        RecordDamage(_this, (uint32_t)(uintptr_t)info, is_physical, source_unit,
                     (uint32_t)DDH_MAXDEPTH + 1, 0, 0.0f, NULL);
        InterlockedExchange(&g_evReady[g_shm ? (((g_shm->hdr.count - 1) % DDH_MAX_EVENTS)) : 0], 1);
        uint32_t rv = 0;
        if (g_original_damage)
        {
            __try { rv = ((fn_damage_t)(uintptr_t)g_original_damage)(_this, _edx, a2, info, is_physical, source_unit); }
            __except (EXCEPTION_EXECUTE_HANDLER) { rv = 0; }
        }
        return rv;
    }

    uint32_t level = (uint32_t)(d - 1);
    const uint32_t now = GetTickCount();

    /* 防漏：SEH 展开/异常会让某一层永远不返回，深度会一路涨上去�?
       父层入口距今超过 2 �?�?认为之前那几层已经丢了，重新�?0 算�?*/
    if (level > 0 && (now - g_levelTick[level - 1]) > 2000)
    {
        InterlockedExchange(&g_depth, 1);
        level = 0;
    }

    /* 每层状态清零（引擎伤害/设定�?子层累计/前血等） */
    g_engineCap[level] = 0;
    g_engineFirstSet[level] = 0;
    g_engineLast[level] = 0;
    g_engineCalls[level] = 0;
    g_setCap[level] = 0;
    g_setSet[level] = 0;
    g_setCalls[level] = 0;

    if (NativeDamageHooksOn())        /* v20：默认不挂，出口三读就够 */
    {
        TryHookGetEventDamage();      /* 只在诊断模式下拿"地图读了几次" */
        TryHookSetEventDamage();      /* 只在诊断模式下拿"地图改了几次" */
    }
    /* 探针（默认关）：入口先采一次“引擎伤害”，出口再采一次，和地图首值对�?*/
    if (DdhEngineProbeOn()) DdhEngineProbeEntry(level, (uint32_t)(uintptr_t)info);

    float hp = 0.0f;
    const bool ok = ReadUnitHp(_this, &hp);

    uint32_t seq = 0;
    g_slot[level] = RecordDamage(_this, (uint32_t)(uintptr_t)info, is_physical, source_unit,
                                 level + 1, ok ? 1u : 0u, hp, &seq);
    g_seq[level] = seq;
    /* v13：压�?—�?本帧�?victim / 前血 / 同目标子帧累计起点都记在帧里 */
    DdhFrame* frame    = DdhFramePush(level, _this, hp, ok ? 1u : 0u);
    g_levelTick[level] = now;
    QueryPerformanceCounter(&g_qpcStart[level]);

    /* 自己 call 原函数（跳板 �?原函数体 �?ret 0x10 回到这里）。返回值原样带回�?*/
    uint32_t retval = 0;
    if (g_original_damage)
    {
        __try
        {
            retval = ((fn_damage_t)(uintptr_t)g_original_damage)(_this, _edx, a2, info, is_physical, source_unit);
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("E 原伤害函数抛出异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
            retval = 0;
        }
    }

    /* ---- v20：出口三读（全部来自这一个钩子）---------------------------------
       �?引擎伤害 = 出口 info+0x10。护�?0x6F64FBF0 / 攻防类型 0x6F64D7F0 /
          攻击类型�?0x6FBEC34C 的结果都�?0x6F6971C0 原地写回 info+0x10
          （`mov [ebx+0x10],eax`），所以出口值就是引擎算完的数。伤害事�?
          （id 0x80234）在乘算**之后**才发，地�?SetEventDamage 只改 *out /
          game+0xBB81D4，不回写 info+0x10 —�?这就�?引擎�?地图�?能分开的原因�?
       �?最终伤�?= 出口 *a2。a2 是调用方�?out 指针（原函数 [ebp+8]），也就�?
          WFE 读来画伤害数字的那块内存�? 个出口里 4 个抄 game+0xBB81D4，主路径
          按主管道重算，两者都已含地图改写�?
       �?净掉血 = 前后血差（下面 DdhFramePop 算，口径不变）�?*/
    float    exitEngine   = 0.0f;
    uint32_t exitEngineOk = 0;
    float    finalRaw     = 0.0f;
    uint32_t finalReadOk  = 0;
    {
        const uint32_t ip = (uint32_t)(uintptr_t)info;
        if (ip > 0x10000u && ip < 0x7FFFFFFFu)
        {
            __try
            {
                memcpy(&exitEngine, (const void*)(uintptr_t)(ip + 0x10u), 4);
                exitEngineOk = 1;
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { exitEngineOk = 0; }
            if (exitEngineOk && !(exitEngine > -1.0e12f && exitEngine < 1.0e12f))
            {
                exitEngine = 0.0f;
                exitEngineOk = 0;
            }
        }
        const uint32_t op = a2;                       /* 调用�?out（float*�?*/
        if (op > 0x10000u && op < 0x7FFFFFFFu)
        {
            __try
            {
                memcpy(&finalRaw, (const void*)(uintptr_t)op, 4);
                finalReadOk = 1;
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { finalReadOk = 0; }
            if (finalReadOk && !(finalRaw > -1.0e12f && finalRaw < 1.0e12f))
            {
                finalRaw = 0.0f;
                finalReadOk = 0;
            }
        }
    }

    /* 读后血：就�?call 返回后的第一件事（和插件同款时机�?*/
    float hpAfter = 0.0f;
    const bool hpAfterOk = ReadUnitHp(_this, &hpAfter);

    DdhEvent* e = NULL;
    if (g_shm) e = &g_shm->ev[g_slot[level] % DDH_MAX_EVENTS];

    /* 引擎伤害：默认由下面�?出口 info+0x10"给；开�?DDH_NATIVE_DAMAGE_HOOKS
       并且地图真读�?GetEventDamage 时，用钩子抓到的首值（两者相等，钩子那份还能
       顺带�?取次"）。没抓到�?engineValid=0 �?界面显示 ? */
    if (e && e->seq == g_seq[level])
    {
        float eng = 0.0f;
        uint32_t engOk = g_engineFirstSet[level] ? 1u : 0u;   /* 首值可能是合法�?0.0，所以看标志�?*/
        if (engOk)
        {
            memcpy(&eng, &g_engineCap[level], 4);
            if (!(eng > -1.0e12f && eng < 1.0e12f)) { eng = 0.0f; engOk = 0; }
        }
        e->engineDamage = eng;
        e->engineValid  = engOk;
        float setVal = 0.0f;
        if (g_setSet[level])
        {
            memcpy(&setVal, &g_setCap[level], 4);
            if (!(setVal > -1.0e12f && setVal < 1.0e12f)) setVal = 0.0f;
        }
        e->setDamage = setVal;
        e->setCalls  = (uint32_t)g_setCalls[level];
    }

    /* v20：引擎伤�?= 出口 info+0x10（见上面"出口三读"①）�?
       老实现要求三道闸门（没读�?/ 没改�?/ 来源匹配）才肯用回读值，是因为当�?
       只有�?地图完全不碰伤害事件"时才敢断定出口值等�?GetEventDamage。现�?
       从这里能看清：事件改写根本不回写 info+0x10，所以出口�?*永远**是引擎值，
       地图改没改都不影响。真机两例仍然吻合：
         原始 5.00  �?出口 info+0x10 = 4.46（地图读�?4.46；护�?2 = 10.71% 减伤�?
         原始 16.00 �?出口 info+0x10 = 14.29（地图读�?14.29，同一护甲�?
       只有打开�?DDH_NATIVE_DAMAGE_HOOKS 且地图真读过 GetEventDamage 时，
       才优先用钩子抓到的首值（两者本就相等，钩子那份还能顺带�?取次"）�?*/
    if (e && e->seq == g_seq[level] && !g_engineFirstSet[level] && exitEngineOk && e->source)
    {
        if (exitEngine > 0.005f && exitEngine < 1.0e9f)
        {
            e->engineDamage = exitEngine;
            e->engineValid  = 1;
            /* engineCalls 的槽 v20 已改�?finalFlags，这里不再写 */
        }
    }

    /* 前血 <= 0 说明这一刻目标已经死�?读的是空�?—�?这种�?�?”没有意义，按“没测到”处理，
       界面显示 ?，不要拿 0 冒充“实际伤害”�?
       v13：own 交给帧栈算（整段 - 同目标子帧合计），退帧时顺手�?gross 报给同目标父帧�?*/
    float gross = 0.0f, own = 0.0f;
    const float fallback = (e && e->engineValid && e->engineDamage > 0.0f)
                           ? (float)e->engineDamage : 0.0f;
    const bool measured = DdhFramePop(frame, (e && e->seq == g_seq[level]) ? 1u : 0u,
                                      hpAfter, hpAfterOk ? 1u : 0u, fallback, &gross, &own);
    if (!measured)
    {
        LogLine("HP失败: level=%u seq=%u eSeq=%u slot=%u hpOk=%u rowOk=%u afterOk=%u before=%.2f after=%.2f victim=0x%08X",
                level, g_seq[level], e ? e->seq : 0u, g_slot[level],
                frame ? frame->hpOk : 0u,
                (e && e->seq == g_seq[level]) ? 1u : 0u,
                hpAfterOk ? 1u : 0u, hp, hpAfter, _this);
    }
    /* 探针（默认关）：出口再采一次，日志里和入口�?/ 地图首值并排对�?*/
    if (g_engineProbe > 0) DdhEngineProbeExit(level, e, g_seq[level]);
    if (e)
    {
        if (measured)
        {
            /* 前血/后血都在，actual = 本帧自己的净掉血（已经扣掉同目标子帧�?*/
            e->hpAfter = hpAfter;
            e->actual  = own;
            e->hpValid = 1;
            InterlockedIncrement((volatile LONG*)&g_hpCount);
        }
        else
        {
            e->hpValid = 0;
            e->hpAfter  = 0.0f;
            e->actual   = 0.0f;
        }
    }

    /* ---- v20：最终伤�?= 出口 *out�?出口三读"②）---------------------------
       这就�?WFE 画伤害数字时读的那块内存，含地图 SetEventDamage 的改写�?
       只在**确实掉了血**（本�?own > 0.005）时才认�?
         无敌 [unit+0x5C]&0x100、免�?[unit+0x158]/[+0x15C]>0、flags&4 这些早退
         分支根本不计算，直接把上一跳残留在 game+0xBB81D4 的值抄�?*out；那种情�?
         �?own = 0，这里一律不认，避免把旧数字当成这次的地图伤害�?
       finalFlags bit0 = 可信，bit1 = 与引擎值不同（= 地图改过伤害）�?*/
    if (e && e->seq == g_seq[level])
    {
        const bool finalOk = finalReadOk && e->engineValid;
        /* 溢出钳制：引擎在落地前会把伤害钳�?目标剩余血�?
           �?x6F67F340 �?`min(*out, vtbl[0x12c]())`，那一路读的就是当前生命）�?
           所以击杀那一刀 *out = 前血，而不是地图改写值。真机实测：
             引擎 387.12 / 前血 219.52 �?地图 219.52、净掉血 219.52
             引擎 170.29 / 前血  79.82 �?地图  79.82、净掉血  79.82
           这种行如果按"最�?�?引擎"去算倍数会得�?0.57×/0.47×，看着像地图减伤，
           其实是溢出。所以单独置 bit2，并且这种情况下不置 bit1（不算地图改过）�?*/
        bool clamped = false;
        if (finalOk && frame && frame->hpBefore > 0.0f && finalRaw < e->engineDamage - 0.005f)
        {
            float dh = finalRaw - frame->hpBefore;
            if (dh < 0.0f) dh = -dh;
            clamped = dh <= 0.02f;
        }
        float d = finalRaw - e->engineDamage;
        if (d < 0.0f) d = -d;
        const bool over = finalOk && !clamped && d > 0.005f;
        e->finalDamage = finalOk ? finalRaw : 0.0f;
        e->finalFlags  = (finalOk ? 1u : 0u) | (over ? 2u : 0u) | (clamped ? 4u : 0u);
    }

    /* ---- 诊断：地图伤�?�?引擎伤害时记一行（带伤害函数耗时�?--- */
    if (e)
    {
        float diff = e->actual - e->engineDamage;
        if (diff < 0.0f) diff = -diff;
        if (e->hpValid && e->engineValid && diff > 0.05f &&
            InterlockedIncrement(&g_hpLogCount) <= 300)
        {
            LARGE_INTEGER qpcNow;
            QueryPerformanceCounter(&qpcNow);
            double us = (g_qpcFreq.QuadPart > 0)
                ? (double)(qpcNow.QuadPart - g_qpcStart[level].QuadPart) * 1000000.0 / (double)g_qpcFreq.QuadPart
                : 0.0;
            float setVal = 0.0f;
            if (g_setSet[level])
            {
                memcpy(&setVal, &g_setCap[level], 4);
                if (!(setVal > -1.0e12f && setVal < 1.0e12f)) setVal = 0.0f;
            }
            LogLine("HP差 depth=%u 原始=%.2f 引擎=%.2f 最终=%.2f 改过=%u 取次=%u 设定=%.2f 设次=%u 前血=%.3f 后血=%.3f 整段=%.2f 本层=%.2f 子层=%.2f 耗时=%.0fus",
                    e->depth, e->amount, e->engineDamage, e->finalDamage,
                    (uint32_t)((e->finalFlags >> 1) & 1u), (uint32_t)g_engineCalls[level],
                    setVal, (uint32_t)g_setCalls[level],
                    frame->hpBefore, hpAfter, gross, own, frame->childSumSameVictim, us);
        }
    }

    /* v9：如果这一层的事件还是我们刚才写的那条（没被环覆盖），拿它更新记录单位�?
       统计；目标后血 <= 0 时把死亡结算排到“本层退出后”再发�?*/
    if (e && e->seq == g_seq[level])
    {
        /* Metadata was captured at event start while both CUnit objects were alive. */
        DdhTrackEvent(e);
        InterlockedExchange(&g_evReady[g_slot[level] % DDH_MAX_EVENTS], 1);
    }

    MemoryBarrier();

    /* 深度 -1；回�?0 说明最外层伤害函数要返回了 —�?这时才处理热键待办和待发结算�?
       避免在引擎扣血过程中调游戏自己的聊�?显示函数�?*/
    const LONG left = InterlockedDecrement(&g_depth);
    if (left == 0)
    {
        /* Keep all JASS/UI work out of the engine damage call stack. */
        if (!g_gameWnd || !IsWindow(g_gameWnd) ||
            !PostMessageA(g_gameWnd, DDH_WM_DAMAGE_DEFERRED, 0, 0))
            DdhProcessDeferred();
    }

    return retval;
}

/* 跳板 = 被搬走的�?6 字节 + E9 跳回原函数体�?x67DC40+6）�?
   DdhDamageFunc �?call 这个跳板，原函数结尾 ret 0x10 时回到我们�?*/

static const int STEAL = 6;

static bool MakeTrampoline(uint8_t* at, uint8_t* tramp)
{
    /* 55 8B EC 83 EC 2C : push ebp; mov ebp,esp; sub esp,0x2C */
    const uint8_t stolen[STEAL] = { 0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C };
    if (memcmp(at, stolen, STEAL) != 0) return false;

    memcpy(tramp, stolen, STEAL);
    uint8_t* p = tramp + STEAL;
    p[0] = 0xE9;
    int32_t rel = (int32_t)((at + STEAL) - (p + 5));
    memcpy(p + 1, &rel, 4);
    return true;
}

/* ---------------------------------------------------------------------------
   在已经加载的 game.dll 里找伤害函数。写�?RVA 不够用：平台联机/观战加载的是
   13,467,648 字节的镜像（磁盘那份�?13,187,048），镜像被改过，RVA 可能整体偏移�?
   特征（来自仓�?`WFE伤害机制分析.md`�?.27.0.52240 上验证过）：
     开�?55 8B EC 83 EC 2C 56 57 8B F9，且函数�?~0x300 内同时出�?
     立即�?0x04000000 �?0x00400000（伤害类型掩码分支的魔法值）�?
--------------------------------------------------------------------------- */
static void DdhFormatHexBytes(char* out, size_t cap, const uint8_t* data, size_t count)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    size_t used = 0;
    for (size_t i = 0; i < count && used + 4 < cap; ++i)
    {
        const int n = DdhSprintf(out + used, cap - used, "%02X ", data[i]);
        if (n <= 0) break;
        used += (size_t)n;
    }
}

/* Some platform/plugin damage hooks replace the function entry with jmp.
   Their detour library keeps a trampoline containing the original six-byte
   prologue followed by a jump back to entry+6. Hooking that trampoline lets
   ddh observe the same calls without overwriting the other plugin's entry. */
static uint8_t* FindExistingDamageTrampoline(uint8_t* gameBase)
{
    static const uint8_t pro[STEAL] = { 0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C };
    uint8_t* expectedReturn = gameBase + HOOK_RVA + STEAL;

    uintptr_t address = 0x10000;
    const uintptr_t limit = 0x7FFF0000u;
    while (address < limit)
    {
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)address, &mbi, sizeof(mbi)) == 0)
        {
            address += 0x1000;
            continue;
        }

        uintptr_t regionBase = (uintptr_t)mbi.BaseAddress;
        uintptr_t regionEnd = regionBase + mbi.RegionSize;
        if (regionEnd <= regionBase) break;

        const DWORD prot = mbi.Protect & 0xFFu;
        const bool readableExecutable =
            mbi.State == MEM_COMMIT &&
            !(mbi.Protect & (PAGE_GUARD | PAGE_NOACCESS)) &&
            (prot == PAGE_EXECUTE || prot == PAGE_EXECUTE_READ ||
             prot == PAGE_EXECUTE_READWRITE || prot == PAGE_EXECUTE_WRITECOPY);
        if (readableExecutable && mbi.RegionSize > STEAL + 5)
        {
            __try
            {
                const uint8_t* begin = (const uint8_t*)regionBase;
                const uint8_t* end = (const uint8_t*)regionEnd;
                for (const uint8_t* p = begin; p + STEAL + 5 <= end; ++p)
                {
                    if (memcmp(p, pro, STEAL) != 0 || p[STEAL] != 0xE9) continue;
                    int32_t rel = 0;
                    memcpy(&rel, p + STEAL + 1, sizeof(rel));
                    const uint8_t* target = p + STEAL + 5 + rel;
                    if (target != expectedReturn) continue;
                    LogLine("检测到已有伤害钩子的原始跳板：%p（原入口 0x%08X）",
                            (const void*)p, (unsigned)(uintptr_t)(gameBase + HOOK_RVA));
                    return (uint8_t*)p;
                }
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
        }
        address = regionEnd;
    }
    return NULL;
}

static bool MatchPrologue(const uint8_t* p)
{
    static const uint8_t pro[10] = { 0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C, 0x56, 0x57, 0x8B, 0xF9 };
    return memcmp(p, pro, 10) == 0;
}

static bool HasImm(const uint8_t* p, size_t window, uint32_t imm)
{
    for (size_t i = 0; i + 4 <= window; i++)
    {
        uint32_t v; memcpy(&v, p + i, 4);
        if (v == imm) return true;
    }
    return false;
}

static uint8_t* FindDamageFunc(uint8_t* base, size_t imageSize)
{
    /* 1) 先看已知 RVA 对不�?*/
    uint8_t* known = base + HOOK_RVA;
    if (MatchPrologue(known)) { LogLine("伤害函数就在已知 RVA 0x%X", HOOK_RVA); return known; }
    DdhFormatHexBytes(g_hookKnownBytes, sizeof(g_hookKnownBytes), known, 16);
    LogLine("已知 RVA 0x%X 开头不是预期字节（%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X），改特征扫描",
            HOOK_RVA, known[0], known[1], known[2], known[3], known[4], known[5], known[6], known[7], known[8], known[9]);

    /* 2) 已被其它插件挂钩时，优先串接它保存的原始跳板。 */
    uint8_t* existingTrampoline = FindExistingDamageTrampoline(base);
    if (existingTrampoline) return existingTrampoline;

    /* 3) 特征扫描 */
    const size_t window = 0x300;
    size_t limit = imageSize > 10 + window ? imageSize - 10 - window : 0;
    for (size_t i = 0; i < limit; i++)
    {
        if (!MatchPrologue(base + i)) continue;
        const uint8_t* p = base + i;
        if (!HasImm(p, window, 0x04000000u)) continue;
        if (!HasImm(p, window, 0x00400000u)) continue;
        LogLine("特征扫描命中：RVA 0x%X", (unsigned)i);
        return base + i;
    }
    LogLine("特征扫描也没找到伤害函数 —— 这个构建和已知版本差异太大");
    return NULL;
}

static bool InstallHook()
{
    if (g_hooked) return true;
    if (GetFileAttributesA("C:\\launch\\ddh_disable_damage_hook.flag") != INVALID_FILE_ATTRIBUTES)
    {
        LogLine("Damage hook disabled by C:\\launch\\ddh_disable_damage_hook.flag");
        strncpy_s(g_hookLastError, sizeof(g_hookLastError),
                  "disabled by C:\\launch\\ddh_disable_damage_hook.flag", _TRUNCATE);
        return false;
    }

    HMODULE game = NULL;
    for (int i = 0; i < 60 && !game; i++) { game = GetModuleHandleA("game.dll"); if (!game) Sleep(100); }
    if (!game)
    {
        LogLine("找不到 game.dll（游戏还没起来？）");
        strncpy_s(g_hookLastError, sizeof(g_hookLastError), "game.dll not loaded", _TRUNCATE);
        return false;
    }

    size_t imageSize = 0;
    bool validPe = false;
    {
        IMAGE_DOS_HEADER* dos = (IMAGE_DOS_HEADER*)game;
        IMAGE_NT_HEADERS32* nt = (IMAGE_NT_HEADERS32*)((uint8_t*)game + dos->e_lfanew);
        if (dos->e_magic == IMAGE_DOS_SIGNATURE && nt->Signature == IMAGE_NT_SIGNATURE)
        {
            imageSize = nt->OptionalHeader.SizeOfImage;
            validPe = imageSize > HOOK_RVA + 16;
        }
    }
    if (!validPe)
    {
        strncpy_s(g_hookLastError, sizeof(g_hookLastError), "invalid game.dll PE image", _TRUNCATE);
        return false;
    }
    g_modBase = (uint32_t)(uintptr_t)game;
    g_imageSize = (uint32_t)imageSize;   /* 协议 v13：视�?RVA 越界校验用（PE SizeOfImage�?*/
    LogLine("game.dll base=0x%08X 映像大小=0x%X", (unsigned)(uintptr_t)game, (unsigned)imageSize);

    g_hookAt = FindDamageFunc((uint8_t*)game, imageSize);
    if (!g_hookAt)
    {
        strncpy_s(g_hookLastError, sizeof(g_hookLastError),
                  "damage function signature not found", _TRUNCATE);
        return false;
    }
    {
        const uintptr_t gameAddress = (uintptr_t)game;
        const uintptr_t targetAddress = (uintptr_t)g_hookAt;
        g_foundRva = targetAddress >= gameAddress && targetAddress < gameAddress + imageSize
            ? (uint32_t)(targetAddress - gameAddress)
            : HOOK_RVA;
    }
    const bool hookedExistingTrampoline =
        (uintptr_t)g_hookAt < (uintptr_t)game ||
        (uintptr_t)g_hookAt >= (uintptr_t)game + imageSize;
    LogLine("挂钩目标：RVA 0x%X（地址 0x%08X；已有跳板=%d）",
            g_foundRva, (unsigned)(uintptr_t)g_hookAt,
            hookedExistingTrampoline ? 1 : 0);

    /* 新挂载方式：入口直接 jmp �?DdhDamageFunc（__fastcall，收�?ret 0x10），
       函数里先记前血 �?call 原函数（跳板）→ 返回后立刻记后血 �?算本层掉血�?
       不再改栈上返回地址，也就不再需要“函数体里有没有 ret 0x10”这道门禁�?*/
    LogLine("实际伤害采集：开（call 原函数后读血，与插件同款）");

    g_tramp = (uint8_t*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!g_tramp)
    {
        LogLine("VirtualAlloc(tramp) 失败 %lu", GetLastError());
        DdhSprintf(g_hookLastError, sizeof(g_hookLastError),
                   "VirtualAlloc failed: %lu", GetLastError());
        return false;
    }

    memcpy(g_saved, g_hookAt, 8);
    if (!MakeTrampoline(g_hookAt, g_tramp))
    {
        LogLine("函数开头不是预期的 55 8B EC 83 EC 2C（实际 %02X %02X %02X %02X %02X %02X）—— 不挂钩",
                g_saved[0], g_saved[1], g_saved[2], g_saved[3], g_saved[4], g_saved[5]);
        VirtualFree(g_tramp, 0, MEM_RELEASE);
        g_tramp = NULL;
        strncpy_s(g_hookLastError, sizeof(g_hookLastError),
                  "damage function prologue changed", _TRUNCATE);
        return false;
    }

    DWORD old = 0;
    if (!VirtualProtect(g_hookAt, 16, PAGE_EXECUTE_READWRITE, &old))
    {
        LogLine("VirtualProtect 失败 %lu", GetLastError());
        DdhSprintf(g_hookLastError, sizeof(g_hookLastError),
                   "VirtualProtect failed: %lu", GetLastError());
        VirtualFree(g_tramp, 0, MEM_RELEASE);
        g_tramp = NULL;
        return false;
    }

    /* 先把跳板地址填进 g_original_damage：DdhDamageFunc �?call �?= 跑原函数体�?
       （跳�?= 搬走�?6 字节 + E9 跳回 0x67DC40+6，原函数结尾 ret 0x10 回到我们�?*/
    g_original_damage = (LONG)(uintptr_t)g_tramp;

    /* E9 rel32 + NOP �?DdhDamageFunc（共 6 字节，正好盖�?3 条完整指令） */
    g_hookAt[0] = 0xE9;
    int32_t rel = (int32_t)((uint8_t*)&DdhDamageFunc - (g_hookAt + 5));
    memcpy(g_hookAt + 1, &rel, 4);
    g_hookAt[5] = 0x90;
    FlushInstructionCache(GetCurrentProcess(), g_hookAt, 8);
    VirtualProtect(g_hookAt, 16, old, &old);
    g_hooked = true;
    strncpy_s(g_hookLastError, sizeof(g_hookLastError), "hook installed", _TRUNCATE);
    LogLine("挂钩成功：0x%08X 前 6 字节已改成 jmp DdhDamageFunc（rel=0x%X，跳板=0x%08X）",
            (unsigned)(uintptr_t)g_hookAt, rel, (unsigned)(uintptr_t)g_tramp);
    return true;
}

static bool DdhDamageHookDisabledByFlag()
{
    return GetFileAttributesA("C:\\launch\\ddh_disable_damage_hook.flag") != INVALID_FILE_ATTRIBUTES;
}

static void DdhWriteHookStatus(uint32_t attempt, bool ok)
{
    char base[MAX_PATH] = { 0 };
    if (GetEnvironmentVariableA("LOCALAPPDATA", base, (DWORD)sizeof(base)) == 0 || !base[0])
        GetTempPathA((DWORD)sizeof(base), base);

    char dir[MAX_PATH] = { 0 };
    DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement", base);
    CreateDirectoryA(dir, NULL);
    DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement\\logs", base);
    CreateDirectoryA(dir, NULL);

    char path[MAX_PATH] = { 0 };
    DdhSprintf(path, sizeof(path), "%s\\ddh-hook-%lu.log", dir, GetCurrentProcessId());
    FILE* f = NULL;
    if (fopen_s(&f, path, "w") != 0 || !f) return;
    fprintf(f, "pid=%lu\nattempt=%lu\nok=%d\nlast_error=%s\ngame_dll_base=0x%08X\nhook_rva=0x%X\nknown_rva_bytes=%s\n",
            GetCurrentProcessId(), attempt, ok ? 1 : 0, g_hookLastError,
            (unsigned)g_modBase, g_foundRva, g_hookKnownBytes);
    fclose(f);
}

static DWORD WINAPI DdhHookInstallThread(LPVOID)
{
    uint32_t attempt = 0;
    for (;;)
    {
        ++attempt;
        if (g_shm) g_shm->hdr.reserved[4] = attempt;
        if (InstallHook())
        {
            if (g_shm)
            {
                g_shm->hdr.reserved[0] = 1u;
                g_shm->hdr.hookOk = 1;
                g_shm->hdr.gameDllBase = g_modBase;
                g_shm->hdr.hookRva = g_foundRva;
                MemoryBarrier();
            }
            DdhWriteHookStatus(attempt, true);
            LogLine("伤害钩子：第 %lu 次尝试安装成功", attempt);
            return 0;
        }
        if (attempt <= 3 || (attempt % 20) == 0)
            DdhWriteHookStatus(attempt, false);
        const DWORD retryDelay = attempt <= 3 ? 500 : (attempt <= 10 ? 1000 : 5000);
        Sleep(retryDelay);
    }
}

/* 删除超过 days 天的 ddh 日志（统一日志目录用） */
static void DdhCleanupOldLogs(const char* dir, int days)
{
    char pattern[MAX_PATH] = { 0 };
    DdhSprintf(pattern, sizeof(pattern), "%s\\ddh-*.log", dir);
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(pattern, &fd);
    if (h == INVALID_HANDLE_VALUE) return;
    const ULONGLONG now = (ULONGLONG)time(NULL);
    do
    {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        ULONGLONG mt = ((ULONGLONG)fd.ftLastWriteTime.dwHighDateTime << 32) | fd.ftLastWriteTime.dwLowDateTime;
        mt = mt / 10000000ULL - 11644473600ULL;
        if (mt + (ULONGLONG)days * 86400ULL < now)
        {
            char full[MAX_PATH] = { 0 };
            DdhSprintf(full, sizeof(full), "%s\\%s", dir, fd.cFileName);
            DeleteFileA(full);
        }
    } while (FindNextFileA(h, &fd));
    FindClose(h);
}

static void SetupShared()
{
    DWORD pid = GetCurrentProcessId();
    DdhSprintf(g_mapName, sizeof(g_mapName), "Local\\DdhRing_%lu", pid);
    /* 日志放哪：① �?ddh.dll 同目录（最常见、肯定可写、也最好找�?
                 �?C:\ddh-<pid>.log（老版本位置，兼容既有说明/习惯�?
                 �?%TEMP%\ddh-<pid>.log（兜底）
       选第一�?*真的能写**的。注意别只写�?C:\：普通权限的游戏写不了根目录�?
       以前就是静默失败 �?日志凭空消失�?*/
    {
        char dllPath[MAX_PATH] = { 0 };
        if (g_self && GetModuleFileNameA(g_self, dllPath, MAX_PATH) > 0)
        {
            char* slash = strrchr(dllPath, '\\');
            if (slash) { slash[1] = 0; strcat_s(dllPath, "ddh_log.on"); g_logEnabled = (GetFileAttributesA(dllPath) != INVALID_FILE_ATTRIBUTES) ? 1 : 0; }
        }
    }

    bool logOk = false;
    if (!g_logEnabled) { g_logPath[0] = 0; logOk = true; }   /* 发布包：不建日志文件 */
    /* 统一日志目录：%LOCALAPPDATA%\War3DeathSettlement\logs（C# 前端同目录） */
    {
        char appdata[MAX_PATH] = { 0 };
        if (GetEnvironmentVariableA("LOCALAPPDATA", appdata, MAX_PATH) > 0)
        {
            char dir[MAX_PATH] = { 0 };
            DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement", appdata);
            CreateDirectoryA(dir, NULL);
            DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement\\logs", appdata);
            CreateDirectoryA(dir, NULL);
            DdhSprintf(g_logPath, sizeof(g_logPath), "%s\\ddh-%lu.log", dir, pid);
            FILE* t = NULL;
            if (fopen_s(&t, g_logPath, "a") == 0 && t) { fclose(t); logOk = true; }
            if (logOk) DdhCleanupOldLogs(dir, 2);
        }
    }
    if (!logOk)
    {
        DdhSprintf(g_logPath, sizeof(g_logPath), "C:\\ddh-%lu.log", pid);
        FILE* t = NULL;
        if (fopen_s(&t, g_logPath, "a") == 0 && t) { fclose(t); logOk = true; }
    }
    if (!logOk)
    {
        char tmp[MAX_PATH] = { 0 };
        if (GetTempPathA(sizeof(tmp), tmp) > 0)
        {
            DdhSprintf(g_logPath, sizeof(g_logPath), "%sddh-%lu.log", tmp, pid);
            FILE* t = NULL;
            if (fopen_s(&t, g_logPath, "a") == 0 && t) { fclose(t); logOk = true; }
        }
    }

    QueryPerformanceFrequency(&g_qpcFreq);
    g_map = CreateFileMappingA(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, DDH_SHM_SIZE, g_mapName);
    if (!g_map) { LogLine("CreateFileMapping 失败 %lu", GetLastError()); return; }
    g_shm = (DdhShared*)MapViewOfFile(g_map, FILE_MAP_ALL_ACCESS, 0, 0, DDH_SHM_SIZE);
    if (!g_shm) { LogLine("MapViewOfFile 失败 %lu", GetLastError()); return; }

    memset(g_shm, 0, sizeof(DdhShared));
    g_shm->hdr.magic = DDH_MAGIC;
    g_shm->hdr.version = DDH_VERSION;
    g_shm->hdr.pid = pid;
    g_shm->hdr.capacity = DDH_MAX_EVENTS;
    g_shm->hdr.hookRva = HOOK_RVA;
    g_shm->hdr.selfTest = 1;
    g_shm->hdr.reserved[0] = 0;        /* v3：先占位，InstallHook 确认能力后再�?1 */
    g_shm->hdr.reserved[2] = DDH_CHART_MAGIC;   /* 能力标记：支持承伤图表（flags bit4�?*/
    LogLine("共享内存 %s 就绪（%u 字节）", g_mapName, DDH_SHM_SIZE);
    LogLine("ddh 版本 v%d：事件记录 %u 字节/条，名字字段各 %u 字节（UTF-8 安全截断，最多 63 字节+NUL）",
            DDH_VERSION, (unsigned)sizeof(DdhEvent), (unsigned)sizeof(((DdhEvent*)0)->victimName));
    LogLine("ddh 协议 v35 单位属性块（单元 208 字节；请求槽 96）：块偏移=%u（= %u 头 + %u 事件），请求槽 %u 个，响应槽偏移=%u，单元 %u 字节，块长 %u，共享内存结构总长 %u；v35 +165=unit_property+0x1B0 攻击速度；flags 0x%X=蝗虫（Aloc）",
            (unsigned)DDH_ATTR_BLOCK_OFFSET, (unsigned)sizeof(DdhHeader),
            (unsigned)(DDH_MAX_EVENTS * sizeof(DdhEvent)), (unsigned)DDH_ATTR_MAX,
            (unsigned)DDH_ATTR_RESP_OFFSET, (unsigned)sizeof(DdhUnitAttr),
            (unsigned)DDH_ATTR_BLOCK_SIZE, (unsigned)sizeof(DdhShared),
            DDH_AF_LOCUST);
    LogLine("ddh 协议 v18 游戏内面板/英雄/头像：面板块偏移=%u（%u 字节，%d 行 × %d 字节），英雄块偏移=%u（%u 字节，%d 槽），头像块偏移=%u（%u 字节，%d 槽）；鼠标点击展开收起，键盘 ~ 显示/隐藏",
            (unsigned)DDH_PANEL_BLOCK_OFFSET, (unsigned)sizeof(DdhPanelBlock),
            DDH_PANEL_MAX_LINES, DDH_PANEL_LINE_TEXT,
            (unsigned)DDH_HERO_BLOCK_OFFSET, (unsigned)sizeof(DdhHeroBlock), DDH_HERO_SLOTS,
            (unsigned)DDH_ICON_BLOCK_OFFSET, (unsigned)sizeof(DdhIconBlock), DDH_ICON_MAX);
}

/* 面板预览/头像测试可能在“第一次受伤”之前就发出；不能等伤害事件才启动热键线程�?
   DllMain 里不能直接做引擎操作，起一个短线程等窗口就绪后再启动消息线程�?*/
/* ---- v21：kkapi_local_plugin.dll �?RequestExtraStringData ----
   静态证据（Ghidra 12.1.4，kkapi_local_plugin.dll sha256 ab19b961…）�?
   注册函数 0x10059A80 用一�?{名字,签名,函数指针} 三元组表把所�?native 注册�?JASS�?
       RequestExtraIntegerData (IHplayer;SSBIII)I -> 0x1005A110
       RequestExtraBooleanData (IHplayer;SSBIII)B -> 0x1005A350
       RequestExtraStringData  (IHplayer;SSBIII)S -> 0x1005A290   <-- �?hook 目标
       RequestExtraRealData    (IHplayer;SSBIII)R
   �?RVA 0x5A290 就是 RequestExtraStringData 本体，不是猜的�?
   0x5A290 反编译结构：�?{opcode=0xE, id, player, str1, str2, bool, i1, i2, i3} 装进局�?
   结构体，调用 0x10029C60(singleton, &req, 4)，成功时返回它填好的那个串指针——也就是
   key 由平台侧给出，只能运行期抓返回值�?

   真正签名�?8 个参数（v20 �?7 参数版本是错的）�?
       (int id, Hplayer, S, S, bool, int, int, int) -> const char*
   JASS �?S 不是 char*，而是一个句柄：h->[8] -> obj，obj+0x1C 才是 char*�?*/
typedef const char* (__cdecl* fn_kk_req_t)(
    int id, void* player, void* s1, void* s2, int flag, int a, int b, int c);
static volatile LONG g_kkHookDone = 0;
static volatile LONG g_kkLogged = 0;
static volatile LONG g_kkCallLogged = 0;
static uint8_t* g_kkTramp = NULL;
static fn_kk_req_t g_kkTrampFn = NULL;

/* JASS 字符串句�?-> char*；结构非�?为空时返�?NULL，全�?__try 保护�?*/
static const char* DdhJassStr(const void* h)
{
    __try
    {
        if (!h) return NULL;
        const uint8_t* inner = *(const uint8_t* const*)((const uint8_t*)h + 8);
        if (!inner) return NULL;
        const char* s = *(const char* const*)(inner + 0x1C);
        if (!s) return NULL;
        /* 只接受可读的短串，避免把野指针当字符�?*/
        return s;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return NULL; }
}

static const char* __cdecl DdhKkRequestExtraString(
    int id, void* player, void* s1, void* s2, int flag, int a, int b, int c)
{
    const char* ret = g_kkTrampFn ? g_kkTrampFn(id, player, s1, s2, flag, a, b, c) : NULL;
    __try
    {
        const char* p1 = DdhJassStr(s1);
        const char* p2 = DdhJassStr(s2);
        if (InterlockedIncrement(&g_kkCallLogged) <= 40)
        {
            char b1[80] = { 0 };
            char b2[80] = { 0 };
            char br[128] = { 0 };
            if (p1) strncpy_s(b1, sizeof(b1), p1, _TRUNCATE);
            if (p2) strncpy_s(b2, sizeof(b2), p2, _TRUNCATE);
            if (ret) strncpy_s(br, sizeof(br), ret, _TRUNCATE);
            LogLine("JAPI req[%ld] id=%d flag=%d a=%d b=%d c=%d s1=\"%s\" s2=\"%s\" ret=\"%s\"",
                    (long)g_kkCallLogged, id, flag, a, b, c, b1, b2, br);
        }
        if ((p1 && (strstr(p1, "secretKey") || strstr(p1, "Key"))) ||
            (p2 && (strstr(p2, "secretKey") || strstr(p2, "Key"))))
        {
            if (InterlockedIncrement(&g_kkLogged) <= 8)
                LogLine("JAPI KEY：s1=\"%s\" s2=\"%s\" ret=\"%s\"",
                        p1 ? p1 : "", p2 ? p2 : "", ret ? ret : "(null)");
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    return ret;
}

static void DdhTryInstallKkHook(void)
{
    if (InterlockedCompareExchange(&g_kkHookDone, 0, 0) != 0) return;
    HMODULE m = GetModuleHandleA("kkapi_local_plugin.dll");
    if (!m) return;
    uint8_t* fn = (uint8_t*)m + 0x5A290u;
    __try
    {
        if (!(fn[0] == 0x83 && fn[1] == 0xEC && fn[2] == 0x2C))
        {
            LogLine("JAPI KEY hook：函数入口不匹配（%02X %02X %02X），跳过", fn[0], fn[1], fn[2]);
            InterlockedExchange(&g_kkHookDone, 1);
            return;
        }
        g_kkTramp = (uint8_t*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
        if (!g_kkTramp) return;
        memcpy(g_kkTramp, fn, 7);                 /* sub esp,2c + mov eax,[esp+30] */
        uint8_t* p = g_kkTramp + 7;
        p[0] = 0xE9;
        *(int32_t*)(p + 1) = (int32_t)((fn + 7) - (p + 5));
        g_kkTrampFn = (fn_kk_req_t)(uintptr_t)g_kkTramp;

        DWORD old = 0;
        if (!VirtualProtect(fn, 7, PAGE_EXECUTE_READWRITE, &old)) return;
        uint8_t patch[7] = { 0xE9, 0, 0, 0, 0, 0x90, 0x90 };
        *(int32_t*)(patch + 1) = (int32_t)((uint8_t*)&DdhKkRequestExtraString - (fn + 5));
        memcpy(fn, patch, sizeof(patch));
        VirtualProtect(fn, 7, old, &old);
        FlushInstructionCache(GetCurrentProcess(), fn, 7);
        InterlockedExchange(&g_kkHookDone, 1);
        LogLine("JAPI KEY hook：已按 DDH_JAPI_KEY=0 关闭");
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("JAPI KEY hook：安装异常 code=0x%08X", (unsigned)GetExceptionCode());
        InterlockedExchange(&g_kkHookDone, 1);
    }
}

/* ---- v23：运行期 key 候选扫描（文件触发，诊断用�?---
   平台�?JAPI 不在 kkapi_local_plugin.dll 里（平台�?War3Plugin.dll，且注册时不带函数指针）�?
   所以改走“从进程内存里找 key”这条路：地图脚本拿�?key 后它作为 Lua 字符串常驻堆里�?
   触发方式：在 ddh 日志同目录放一�?ddh_scan.flag；本线程发现后扫一遍并输出
   keys-<pid>.txt（每行一�?16..24 字节可打�?ASCII 串），再�?flag 删掉�?
   外部�?ts_main 的密文做 XOR 自校验，即可挑出真正�?key�?*/
static void DdhScanKeysOnce(void)
{
    char dir[MAX_PATH] = { 0 };
    strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) return;
    slash[1] = 0;

    char out[MAX_PATH];
    DdhSprintf(out, sizeof(out), "%skeys-%lu.txt", dir, (unsigned long)GetCurrentProcessId());
    FILE* f = NULL;
    if (fopen_s(&f, out, "w") != 0 || !f) { LogLine("key扫描：无法写 %s", out); return; }

    SYSTEM_INFO si;
    GetSystemInfo(&si);
    const uint8_t* p = (const uint8_t*)si.lpMinimumApplicationAddress;
    const uint8_t* end = (const uint8_t*)si.lpMaximumApplicationAddress;
    long written = 0;
    long regions = 0;

    while (p < end && written < 200000)
    {
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery(p, &mbi, sizeof(mbi)) != sizeof(mbi)) break;
        const uint8_t* base = (const uint8_t*)mbi.BaseAddress;
        SIZE_T size = mbi.RegionSize;
        if (size == 0) break;

        bool readable = (mbi.State == MEM_COMMIT) &&
                        !(mbi.Protect & PAGE_GUARD) &&
                        !(mbi.Protect & PAGE_NOACCESS) &&
                        (mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                                        PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY));
        if (readable)
        {
            ++regions;
            __try
            {
                const uint8_t* q = base;
                const uint8_t* qe = base + size;
                while (q < qe)
                {
                    uint8_t c = *q;
                    if (c >= 0x20 && c < 0x7F)
                    {
                        const uint8_t* s = q;
                        while (q < qe && *q >= 0x20 && *q < 0x7F) ++q;
                        size_t len = (size_t)(q - s);
                        if (len >= 16 && len <= 24)
                        {
                            fwrite(s, 1, len, f);
                            fputc('\n', f);
                            if (++written >= 200000) break;
                        }
                        continue;
                    }
                    ++q;
                }
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
        }
        p = base + size;
    }

    fclose(f);
    LogLine("key扫描：完成，%ld 个候选串、%ld 个可读区 -> %s", written, regions, out);
}

static DWORD WINAPI DdhScanWatchThread(LPVOID)
{
    char dir[MAX_PATH] = { 0 };
    strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) return 0;
    slash[1] = 0;
    char flag[MAX_PATH];
    DdhSprintf(flag, sizeof(flag), "%sddh_scan.flag", dir);
    for (;;)
    {
        Sleep(2000);
        if (GetFileAttributesA(flag) == INVALID_FILE_ATTRIBUTES) continue;
        LogLine("key扫描：收到触发文件，开始扫描本进程内存");
        DeleteFileA(flag);
        DdhScanKeysOnce();
    }
    return 0;
}

static DWORD WINAPI DdhStartupThread(LPVOID)
{
    Sleep(200);
    DdhDbStart();
    DdhEnsureHotkeyThread();
    /* v22：默认开启（只读日志、原样透传，风险极低）。要关掉就设 DDH_JAPI_KEY=0�?*/
    char jk[8] = { 0 };
    if (GetEnvironmentVariableA("DDH_JAPI_KEY", jk, (DWORD)sizeof(jk)) == 0 || jk[0] != '1')
    {
        LogLine("JAPI KEY hook disabled by default; set DDH_JAPI_KEY=1 for diagnostics");
        return 0;
    }
    LogLine("JAPI KEY hook enabled for diagnostics");
    /* �?JAPI 插件加载；key 在地图脚本初始化时读取，必须赶在它之前�?*/
    for (int i = 0; i < 2400 && InterlockedCompareExchange(&g_kkHookDone, 0, 0) == 0; ++i)
    {
        DdhTryInstallKkHook();
        if (InterlockedCompareExchange(&g_kkHookDone, 0, 0) != 0) break;
        Sleep(50);
    }
    if (InterlockedCompareExchange(&g_kkHookDone, 0, 0) == 0)
        LogLine("JAPI KEY hook：等待超时（120s），kkapi_local_plugin.dll 始终未加载");
    return 0;
}

/* Keep the original three-second bootstrap delay now that the full hook is
   linked directly into ddh.dll. This lets WFE finish enumerating additional
   libraries before shared memory and game.dll patching begin. */
static DWORD WINAPI DdhCoreAttachThread(LPVOID)
{
    Sleep(3000);
    SetupShared();
    g_ddhUprobeOn = DdhUprobeReadEnv();
    {
        const int envMode = DdhUnitDumpEnvMode();
        if (envMode == 0) g_ddhUnitDumpMode = 0;
        else if (envMode == 2) g_ddhUnitDumpMode = 2;
        else g_ddhUnitDumpMode = DdhUnitDumpFlagFile() ? 2 : 1;
    }
    if (g_shm)
    {
        g_shm->hdr.gameDllBase = 0;
        g_shm->hdr.hookOk = 0;
        g_shm->hdr.reserved[0] = 0;
        g_shm->hdr.reserved[4] = 0;
        if (DdhDamageHookDisabledByFlag())
        {
            strncpy_s(g_hookLastError, sizeof(g_hookLastError),
                      "disabled by C:\\launch\\ddh_disable_damage_hook.flag", _TRUNCATE);
            DdhWriteHookStatus(0, false);
        }
        else
        {
            HANDLE hookThread = CreateThread(NULL, 0, DdhHookInstallThread, NULL, 0, NULL);
            if (hookThread) CloseHandle(hookThread);
        }
        HANDLE startupThread = CreateThread(NULL, 0, DdhStartupThread, NULL, 0, NULL);
        if (startupThread) CloseHandle(startupThread);
        HANDLE scanThread = CreateThread(NULL, 0, DdhScanWatchThread, NULL, 0, NULL);
        if (scanThread) CloseHandle(scanThread);
    }
    return 0;
}

BOOL APIENTRY DllMain(HMODULE mod, DWORD reason, LPVOID)
{
    if (g_ddhDllTick == 0) g_ddhDllTick = GetTickCount();
    if (reason == DLL_PROCESS_ATTACH)
    {
        g_self = mod;
        DisableThreadLibraryCalls(mod);

        char mutexName[96] = { 0 };
        DdhSprintf(mutexName, sizeof(mutexName),
                   "Local\\War3DeathSettlement.ddh.instance.%lu", GetCurrentProcessId());
        SetLastError(ERROR_SUCCESS);
        g_instanceMutex = CreateMutexA(NULL, FALSE, mutexName);
        if (g_instanceMutex && GetLastError() == ERROR_ALREADY_EXISTS)
        {
            CloseHandle(g_instanceMutex);
            g_instanceMutex = NULL;
            g_duplicateInstance = true;
            return TRUE;
        }

        HANDLE thread = CreateThread(NULL, 0, DdhCoreAttachThread, NULL, 0, NULL);
        if (thread) CloseHandle(thread);
    }
    else if (reason == DLL_PROCESS_DETACH)
    {
        /* v9：先让热键线程退出并注销热键（否则组合键会一直粘在本进程上） */
        if (InterlockedCompareExchange(&g_ddhHkStarted, 0, 0) != 0)
        {
            InterlockedExchange(&g_ddhHkStop, 1);
            if (g_ddhHkThreadId) PostThreadMessageA(g_ddhHkThreadId, WM_QUIT, 0, 0);
            if (g_ddhHkThread)
            {
                WaitForSingleObject(g_ddhHkThread, 300);
                CloseHandle(g_ddhHkThread);
                g_ddhHkThread = NULL;
            }
        }

        /* v12：先还原窗口过程（否则窗口还指着我们的代码，卸载后再有任何消息就崩） */
        DdhRestoreGameWnd();

        /* 卸钩：把原来�?6 字节写回�?*/
        if (g_hooked && g_hookAt)
        {
            DWORD old = 0;
            if (VirtualProtect(g_hookAt, 8, PAGE_EXECUTE_READWRITE, &old))
            {
                memcpy(g_hookAt, g_saved, STEAL);
                FlushInstructionCache(GetCurrentProcess(), g_hookAt, 8);
                VirtualProtect(g_hookAt, 16, old, &old);
                LogLine("已卸钩");
            }
        }
        if (g_shm) { UnmapViewOfFile(g_shm); g_shm = NULL; }
        if (g_map) { CloseHandle(g_map); g_map = NULL; }
        if (g_instanceMutex) { CloseHandle(g_instanceMutex); g_instanceMutex = NULL; }
    }
    return TRUE;
}
#ifdef DDH_MSG_TEST
/* ===========================================================================
   消息编码 / 格式自检（只�?`cl /DDDH_MSG_TEST ddh.cpp` 这种临时构建才编进来�?
   build_hook.ps1 不定�?DDH_MSG_TEST，所以发布用�?ddh.dll �?*没有**这一段）�?
   ---------------------------------------------------------------------------
   断言用的都是真机日志里的真实字节：名字“雪狼�?= E9 9B AA E7 8B BC�?
   跑法：msgtest.exe �?退出码 0 = 全过，非 0 = 失败条数；明细同时写 _msgtest_result.txt�?
   =========================================================================== */
static int   g_testFail = 0;
static FILE* g_testFile = NULL;

/* 期望�?UTF-8 前缀（真机字节，不是源码里的 GBK 字面量） */
static const char kSharePrefix[] = "\xE3\x80\x90\xE4\xBC\xA4\xE5\xAE\xB3\xE3\x80\x91";                              /* 【伤害�?*/
static const char kLivePrefix[]  = "\xE3\x80\x90\xE5\xBD\x93\xE5\x89\x8D\xE4\xBC\xA4\xE5\xAE\xB3\xE3\x80\x91";      /* 【当前伤害�?*/
static const char kPickPrefix[]  = "\xE3\x80\x90\xE5\xB7\xB2\xE9\x80\x89\xE4\xB8\xAD\xE3\x80\x91";                  /* 【已选中�?*/
static const char kOffPrefix[]   = "\xE3\x80\x90\xE5\xB7\xB2\xE5\x8F\x96\xE6\xB6\x88\xE3\x80\x91";                  /* 【已取消�?*/
static const char kOnPrefix[]    = "\xE3\x80\x90\xE5\xB7\xB2\xE5\xBC\x80\xE5\x90\xAF\xE3\x80\x91";                  /* 【已开启�?*/

static void DdhTestOut(const char* fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    if (g_testFile) vfprintf(g_testFile, fmt, ap);
    va_end(ap);
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
}

static void DdhTestCheck(bool ok, const char* what)
{
    DdhTestOut("[%s] %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) g_testFail++;
}

/* 打印一�?UTF-8 文本：hex（前 120 字节�? GBK 回显（GBK 才能在控制台/GBK 文件里看懂） */
static void DdhTestDump(const char* tag, const char* s)
{
    char hex[768] = { 0 };
    int n = (int)strlen(s);
    if (n > 120) n = 120;
    FormatHex((const unsigned char*)s, n, hex, sizeof(hex));
    DdhTestOut("  %s 长度=%u hex=%s\n", tag, (unsigned)strlen(s), hex);
    DdhTestOut("  %s 文本=%s\n", tag, s);
}

/* 造一份“记录单�?+ 两个来源�?0.0% / 20.0%）”的统计 */
static void DdhTestMakeTrack(double net0, double net1, double raw0, double raw1)
{
    memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
    g_ddhTrack.unit = 0x12345000u;
    g_ddhTrack.code = 0x6870666Fu;                        /* hfoo（内存里反序，这里不影响�?*/
    strcpy_s(g_ddhTrack.label, sizeof(g_ddhTrack.label), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");
    g_ddhTrack.hits   = 9;
    g_ddhTrack.raw    = 589.00;
    g_ddhTrack.engine = 328.80;
    g_ddhTrack.map    = 328.80;
    g_ddhTrack.net    = 304.34;
    g_ddhTrack.maxHit = 37.40f;
    g_ddhTrack.srcCount = 2;
    g_ddhTrack.src[0].source = 0x22220000u;
    g_ddhTrack.src[0].code   = 0x6870666Fu;
    strcpy_s(g_ddhTrack.src[0].label, sizeof(g_ddhTrack.src[0].label), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");
    g_ddhTrack.src[0].net = net0;
    g_ddhTrack.src[0].raw = raw0;
    g_ddhTrack.src[1].source = 0x33330000u;
    g_ddhTrack.src[1].code   = 0x6C777268u;
    strcpy_s(g_ddhTrack.src[1].label, sizeof(g_ddhTrack.src[1].label), "\xE7\x8B\xBC\xE4\xBA\xBA(hwol)");
    g_ddhTrack.src[1].net = net1;
    g_ddhTrack.src[1].raw = raw1;
}

static int DdhMsgSelfTest(void)
{
    const char* outPath = getenv("DDH_MSG_TEST_OUT");
    g_testFile = fopen((outPath && outPath[0]) ? outPath : "_msgtest_result.txt", "wb");

    char msg[1024] = { 0 };

    /* ---- 1) 死亡结算：只发【伤害】，主段不出�?---- */
    DdhTestOut("== 1) 死亡结算：只发【伤害】（名字 UTF-8 = E9 9B AA E7 8B BC 雪狼�?=\n");
    DdhTestMakeTrack(243.472, 60.868, 471.20, 117.80);     /* 304.34 �?80.0% / 20.0% */
    DdhBuildTrackText(msg, sizeof(msg), 1);
    DdhTestDump("死亡结算", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "输出整体是合�?UTF-8");
    DdhTestCheck(strncmp(msg, kSharePrefix, sizeof(kSharePrefix) - 1) == 0,
                 "以【伤害】开头（不再有【死亡结算】主段）");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL,
                 "名字“雪狼”的原字�?E9 9B AA E7 8B BC 原样出现（没有被再转一次）");
    DdhTestCheck(strstr(msg, "\xE5\xA6\x96") == NULL,
                 "不含双转码乱�?E5 A6 96（旧版就是这么坏的）");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL,
                 "含“雪�?0.0%”（名字直接接一位小数的占比�?);
    DdhTestCheck(strstr(msg, "\xE7\x8B\xBC\xE4\xBA\xBA" "20.0%") != NULL, "含“狼�?0.0%�?);
    DdhTestCheck(strstr(msg, "hfoo") == NULL && strstr(msg, "hwol") == NULL,
                 "不含类型码后缀（来源项只要名字/码）");
    DdhTestCheck(strstr(msg, "\xE5\x8F\x97") == NULL && strstr(msg, "\xE5\x87\x80") == NULL &&
                 strstr(msg, "\xE6\x9C\x80") == NULL && strstr(msg, ":") == NULL,
                 "不含 受击/净/最�?时间（主段已按要求去掉）");
    DdhTestCheck(strlen(msg) <= DDH_MSG_MAX_BYTES, "长度没超�?420 字节");
    DdhTestCheck(g_msgNameRawUtf8 == 2 && g_msgNameGbkFallback == 0,
                 "本条 2 个来源名字全部走“原�?UTF-8”那条路");

    /* ---- 2) Ctrl+Alt+Q：标题改成【当前伤害�?---- */
    DdhTestOut("\n== 2) Ctrl+Alt+Q：【当前伤害�? 同样的占�?==\n");
    DdhBuildTrackText(msg, sizeof(msg), 0);
    DdhTestDump("当前伤害", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "实时统计是合�?UTF-8");
    DdhTestCheck(strncmp(msg, kLivePrefix, sizeof(kLivePrefix) - 1) == 0, "以【当前伤害】开�?);
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL &&
                 strstr(msg, "\xE7\x8B\xBC\xE4\xBA\xBA" "20.0%") != NULL, "同样�?80.0% / 20.0%");

    /* ---- 3) 【伤害】段自身：Top N 截断（先砍靠后的来源�?--- */
    DdhTestOut("\n== 3) 【伤害】段：Top N 截断 ==\n");
    char items[320] = { 0 };
    int used = DdhBuildShareItems(g_ddhTrack.src, g_ddhTrack.srcCount,
                                  g_ddhTrack.net, g_ddhTrack.raw, 1, items, sizeof(items));
    DdhTestDump("Top1", items);
    DdhTestCheck(used == 1, "只留 1 项时返回 1");
    DdhTestCheck(DdhUtf8Valid(items), "Top1 是合�?UTF-8");
    DdhTestCheck(strstr(items, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL, "Top1 = 雪狼80.0%（留占比最大的�?);

    /* ---- 4) GBK 名字回退：D1 A9 C0 C7（GBK 的“雪狼”）---- */
    DdhTestOut("\n== 4) GBK 名字回退：D1 A9 C0 C7（GBK 的雪狼）==\n");
    memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
    g_ddhTrack.unit = 0x12345000u;
    g_ddhTrack.raw  = 10.0;
    g_ddhTrack.net  = 10.0;
    g_ddhTrack.srcCount = 1;
    g_ddhTrack.src[0].source = 0x22220000u;
    strcpy_s(g_ddhTrack.src[0].label, sizeof(g_ddhTrack.src[0].label), "\xD1\xA9\xC0\xC7(hfoo)");
    g_ddhTrack.src[0].net = 10.0;
    g_ddhTrack.src[0].raw = 10.0;
    DdhBuildTrackText(msg, sizeof(msg), 1);
    DdhTestDump("GBK名字", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "回退后整体仍是合�?UTF-8");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL,
                 "GBK 名字 D1 A9 C0 C7 被转�?UTF-8 的“雪狼”（E9 9B AA E7 8B BC�?);
    DdhTestCheck(g_msgNameGbkFallback == 1 && g_msgNameRawUtf8 == 0, "本条走的�?GBK 回退那条�?);

    /* ---- 5) R 选中 / S 开�?的本机提示文�?---- */
    DdhTestOut("\n== 5) Ctrl+Alt+R / S 的本机提�?==\n");
    char toast[256] = { 0 };
    DdhAppendLabel(toast, sizeof(toast), "【已选中�?);
    DdhAppendUnitName(toast, sizeof(toast), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");
    DdhTestDump("已选中", toast);
    DdhTestCheck(DdhUtf8Valid(toast), "【已选中】提示是合法 UTF-8");
    DdhTestCheck(strncmp(toast, kPickPrefix, sizeof(kPickPrefix) - 1) == 0, "以【已选中】开�?);
    DdhTestCheck(strstr(toast, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL, "【已选中】里带名字“雪狼�?);

    char off[256] = { 0 };
    char on[256]  = { 0 };
    DdhAppendLabel(off, sizeof(off), "【已取消】死亡结算不再自动发�?);
    DdhAppendLabel(on,  sizeof(on),  "【已开启】死亡结算会自动发�?);
    DdhTestDump("已取�?, off);
    DdhTestCheck(DdhUtf8Valid(off) && strncmp(off, kOffPrefix, sizeof(kOffPrefix) - 1) == 0,
                 "【已取消】提示正�?);
    DdhTestCheck(DdhUtf8Valid(on) && strncmp(on, kOnPrefix, sizeof(kOnPrefix) - 1) == 0,
                 "【已开启】提示正�?);

    /* ---- 6) 硬截断：420 字节、末尾“…”、不切坏汉字 ---- */
    DdhTestOut("\n== 6) 硬截断：<=420 字节、末尾“…”、不切坏汉字 ==\n");
    char longText[1024] = { 0 };
    for (int i = 0; i < 200; i++) memcpy(longText + i * 3, "\xE9\x9B\xAA", 3);   /* 200 个“雪�? 600 字节 */
    DdhTruncateUtf8(longText, sizeof(longText), DDH_MSG_MAX_BYTES);
    const size_t longLen = strlen(longText);
    char tail[4] = { 0 };
    char tailHex[32] = { 0 };
    if (longLen >= 3) memcpy(tail, longText + longLen - 3, 3);
    FormatHex((const unsigned char*)tail, 3, tailHex, sizeof(tailHex));
    DdhTestOut("  截断后长�?%u 末尾3字节=%s（应�?E2 80 A6）\n", (unsigned)longLen, tailHex);
    DdhTestCheck(longLen <= DDH_MSG_MAX_BYTES, "截断�?<= 420 字节");
    DdhTestCheck(DdhUtf8Valid(longText), "截断后仍是合�?UTF-8（没切出半个汉字�?);
    DdhTestCheck(memcmp(tail, "\xE2\x80\xA6", 3) == 0, "末尾补了“…”（E2 80 A6�?);
    DdhTestCheck(longLen == DDH_MSG_MAX_BYTES, "截断正好用满 420 字节");

    /* ---- 7) 占比格式：一位小�?/ 0.1% 下限 / 100.0% 上限 ---- */
    DdhTestOut("\n== 7) share format: one decimal / 0.1%% floor / 100.0%% cap ==\n");
    DdhSrcStat bs[2];
    memset(bs, 0, sizeof(bs));
    char bshare[320] = { 0 };
    strcpy_s(bs[0].label, sizeof(bs[0].label), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");   /* 雪狼 */
    strcpy_s(bs[1].label, sizeof(bs[1].label), "\xE7\x8B\xBC\xE4\xBA\xBA(hwol)");   /* 狼人 */
    bs[0].net = 100.0; bs[1].net = 0.02;
    DdhBuildShareItems(bs, 2, 100.02, 100.02, DDH_SHARE_TOP, bshare, sizeof(bshare));
    DdhTestDump("边界占比", bshare);
    DdhTestCheck(strstr(bshare, "100.0%") != NULL, "99.98% 四舍五入�?100.0%（上限）");
    DdhTestCheck(strstr(bshare, "0.1%") != NULL, "0.02% 抬到 0.1% 下限（不显示 0.0%�?);
    DdhTestCheck(strstr(bshare, " 0.0%") == NULL, "没有 0.0% 这种写法�?00.0% 是上限，不算�?);
    bs[0].net = 31.13; bs[1].net = 68.87;
    DdhBuildShareItems(bs, 2, 100.0, 100.0, DDH_SHARE_TOP, bshare, sizeof(bshare));
    DdhTestDump("一位小�?, bshare);
    DdhTestCheck(strstr(bshare, "31.1%") != NULL && strstr(bshare, "68.9%") != NULL,
                 "31.13�?1.1% / 68.87�?8.9%（四舍五入到 0.1�?);
    DdhTestCheck(strstr(bshare, "31%") == NULL, "不再出现整数写法 31%");

    /* 8) 长名字标签：64/96 字节都装不下时只能“安全截断�?
          真机 2026-10-31 20:22:52 崩在 sprintf_s 的无效参数上�?
          长中文名 “……【辅助单位�?e009)�?写进 64 字节标签 �?_invoke_watson �?0xC0000409�?*/
    {
        char longName[160] = { 0 };
        for (int i = 0; i < 24; i++) strcat_s(longName, sizeof(longName), "\xE6\x88\x98");
        char lab64[64] = { 0 };
        DdhComposeLabel(longName, "e009", lab64, sizeof(lab64));
        DdhTestDump("长名字→64 字节标签", lab64);
        DdhTestCheck(strlen(lab64) < sizeof(lab64), "长名字→64 字节标签不越�?);
        DdhTestCheck(DdhUtf8Valid(lab64), "长名字→64 字节标签仍是合法 UTF-8");
        DdhTestCheck(lab64[0] && lab64[strlen(lab64) - 1] == ')', "长名字截断后仍保�?�?�?�?后缀");
        DdhTestCheck(strstr(lab64, "(e009") != NULL, "后缀�?(e009");

        char lab96[96] = { 0 };
        DdhComposeLabel(longName, "e009", lab96, sizeof(lab96));
        DdhTestCheck(strlen(lab96) < sizeof(lab96) && DdhUtf8Valid(lab96), "长名字→96 字节标签同样安全");
        DdhTestCheck(strlen(lab96) > strlen(lab64), "96 字节�?64 字节装得下更多名�?);

        char lab8[8] = { 0 };
        DdhComposeLabel(longName, "e009", lab8, sizeof(lab8));
        DdhTestCheck(DdhUtf8Valid(lab8) && strlen(lab8) < sizeof(lab8), "极小缓冲(8 字节)也安�?);

        char labNone[8] = { 0 };
        DdhComposeLabel("", "", labNone, sizeof(labNone));
        DdhTestCheck(strcmp(labNone, "?") == 0, "没名字也没码时写 ?");
    }

    /* ---- v15：面�?/ 英雄查询块布局 ----
       �?C# InGamePanelWire 必须逐项一致；任何一项对不上，C# 会读错偏移�?*/
    DdhTestOut("\n== v15) panel/hero protocol layout ==\n");
    DdhTestCheck(sizeof(DdhPanelLine) == 244, "DdhPanelLine = 244 字节（color 4 + text 240�?);
    DdhTestCheck(sizeof(DdhPanelBlock) == 4952, "DdhPanelBlock = 4952 字节");
    DdhTestCheck(sizeof(DdhHeroReq) == 8 && sizeof(DdhHeroRes) == 16, "Hero Req/Res = 8/16 字节");
    DdhTestCheck(sizeof(DdhHeroBlock) == 400, "DdhHeroBlock = 400 字节");
    DdhTestCheck(DDH_PANEL_BLOCK_OFFSET == 141256u, "面板块偏�?= 141256（头 64 + 事件 120832 + 属�?20360�?);
    DdhTestCheck(DDH_HERO_BLOCK_OFFSET == 146208u, "英雄块偏�?= 146208�? 141256 + 4952�?);
    DdhTestCheck(sizeof(DdhIconSlot) == 16 && sizeof(DdhIconBlock) == 80,
                 "DdhIconSlot/Block = 16/80 字节");
    DdhTestCheck(DDH_ICON_BLOCK_OFFSET == 146608u, "头像块偏�?= 146608�? 146208 + 400�?);
    DdhTestCheck(offsetof(DdhIconBlock, slots) == 16, "IconBlock.slots 偏移 = 16");
    DdhTestCheck(offsetof(DdhPanelBlock, lines) == 72, "PanelBlock.lines 偏移 = 72");
    DdhTestCheck(offsetof(DdhPanelBlock, fontName) == 40, "PanelBlock.fontName 偏移 = 40");
    DdhTestCheck(offsetof(DdhPanelBlock, lineCount) == 16, "PanelBlock.lineCount 偏移 = 16");
    DdhTestCheck(offsetof(DdhHeroBlock, req) == 16 && offsetof(DdhHeroBlock, res) == 144,
                 "HeroBlock req/res 偏移 = 16/144");
    DdhTestCheck(sizeof(DdhShared) == 146688u, "DdhShared = 146688 字节�? MB 共享内存富余�?);
    DdhTestCheck(DDH_PANEL_MAX_LINES == 20 && DDH_PANEL_LINE_TEXT == 240 && DDH_HERO_SLOTS == 16,
                 "面板 20 �?× 240 字节 / 英雄 16 �?);
    DdhTestCheck(DDH_PANEL_FLAG_SHOW == 1 && DDH_PANEL_FLAG_HIDE == 2 &&
                 DDH_PANEL_FLAG_BG == 4 && DDH_PANEL_FLAG_COLLAPSED == 8,
                 "v16 flags：显�?隐藏/背景/默认收起 = 1/2/4/8");
    DdhTestCheck(DDH_PANEL_COLLAPSED_SHIFT == 8 && DDH_PANEL_COLLAPSED_MASK == 0xFF,
                 "v16 收起行数�?flags bit8..15�? = 默认 6�?);

    DdhTestOut("\n%s（失�?%d 项）\n", g_testFail == 0 ? "== 自检通过 ==" : "== 自检失败 ==", g_testFail);
    return g_testFail;
}

int main(void)
{
    const int fails = DdhMsgSelfTest();
    if (g_testFile) { fclose(g_testFile); g_testFile = NULL; }
    return fails == 0 ? 0 : (fails > 100 ? 100 : fails);
}
#endif /* DDH_MSG_TEST */
#ifdef DDH_CHILDSUM_TEST
/* ===========================================================================
   v13 子伤害记账自检（只�?`cl /DDH_CHILDSUM_TEST ddh.cpp` 这种临时构建才编进来�?
   build_hook.ps1 不定�?DDH_CHILDSUM_TEST，发布用�?ddh.dll �?*没有**这一段）�?
   ---------------------------------------------------------------------------
   直接驱动 DdhFramePush / DdhFramePop，覆盖真机上的多目标 AoE�?
     父帧打张�?A�?01.20 �?73.07（整�?28.13�?
     内层子帧：A 5.63 / 典韦 B 5.63 / 步兵 C 7.50 / 步兵 C 7.50（子合计 26.26�?
   旧版�?26.26 全扣到父�?�?own=1.87；正确只扣同目标�?5.63 �?own=22.50�?
   跑法：childsumtest.exe �?退出码 0 = 全过，非 0 = 失败条数；明细同时写
         _childsum_result.txt，嵌套扣减日志写 _childsum_test.log�?
   =========================================================================== */
static int   g_csFail = 0;
static FILE* g_csFile = NULL;

static void CsOut(const char* fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    if (g_csFile) vfprintf(g_csFile, fmt, ap);
    va_end(ap);
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
}

static void CsCheck(bool ok, const char* what)
{
    CsOut("[%s] %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) g_csFail++;
}

static void CsNear(float got, float want, const char* what)
{
    char buf[512];
    const bool ok = (got - want) <= 0.01f && (want - got) <= 0.01f;
    DdhSprintf(buf, sizeof(buf), "%s（实�?%.2f，期�?%.2f ±0.01�?, what, got, want);
    CsCheck(ok, buf);
}

#define CS_A 0xA0001000u
#define CS_B 0xB0002000u
#define CS_C 0xC0003000u

/* 压一个子帧、按给定掉血退栈，返回子帧自己�?own */
static float CsChild(uint32_t level, uint32_t victim, float hp0, float dmg)
{
    DdhFrame* c = DdhFramePush(level, victim, hp0, 1);
    float g = 0.0f, o = 0.0f;
    DdhFramePop(c, 1, hp0 - dmg, 1, 0.0f, &g, &o);
    return o;
}

static int DdhChildSumSelfTest(void)
{
    const char* outPath = getenv("DDH_CHILDSUM_TEST_OUT");
    g_csFile = fopen((outPath && outPath[0]) ? outPath : "_childsum_result.txt", "wb");
    strcpy_s(g_logPath, sizeof(g_logPath), "_childsum_test.log");
    remove(g_logPath);
    g_nestedLogCount = 0;

    /* ---- 1) 多目�?AoE：父 A 28.13，子 A 5.63 / B 5.63 / C 7.50 / C 7.50 ---- */
    CsOut("== 1) 多目�?AoE：父=张飞A 101.20�?3.07�?8.13），内层 A 5.63 / 典韦B 5.63 / 步兵C 7.50 ×2 ==\n");
    memset(g_frames, 0, sizeof(g_frames));
    DdhFrame* p = DdhFramePush(0, CS_A, 101.20f, 1);
    CsCheck(p != NULL && p->depth == 1, "父帧压栈成功（depth=1�?);
    const float ownA  = CsChild(1, CS_A, 50.00f, 5.63f);
    const float ownB  = CsChild(1, CS_B, 50.00f, 5.63f);
    const float ownC1 = CsChild(1, CS_C, 50.00f, 7.50f);
    const float ownC2 = CsChild(1, CS_C, 50.00f, 7.50f);
    CsCheck(p->childCountSame == 1, "父帧只收�?1 笔同目标子帧（A�?);
    CsNear(p->childSumSameVictim, 5.63f, "父帧同目标子合计（B/C 不扣父帧�?);
    float gross = 0.0f, own = 0.0f;
    const bool measured = DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsCheck(measured, "父帧前后血有效，own 可测");
    CsOut("  父帧�?01.20�?3.07 整段=%.2f 同目标子合计=%.2f�?u 笔） own=%.2f\n",
          gross, p->childSumSameVictim, p->childCountSame, own);
    CsNear(gross, 28.13f, "父帧整段 gross");
    CsNear(own, 22.50f, "父帧 own（旧版按 26.26 扣会错成 1.87�?);
    CsNear(ownA, 5.63f, "子帧 A �?own");
    CsNear(ownB, 5.63f, "子帧 B（典韦）�?own");
    CsNear(ownC1, 7.50f, "子帧 C �?1 笔的 own");
    CsNear(ownC2, 7.50f, "子帧 C �?2 笔的 own");

    /* ---- 2) 再嵌一层：孙帧�?A 1.00（在子帧 A �?5.63 内） ---- */
    CsOut("\n== 2) 再嵌一层：孙帧�?A 1.00（在子帧 A �?5.63 内）==\n");
    memset(g_frames, 0, sizeof(g_frames));
    p = DdhFramePush(0, CS_A, 101.20f, 1);
    DdhFrame* childA = DdhFramePush(1, CS_A, 50.00f, 1);
    DdhFrame* grand  = DdhFramePush(2, CS_A, 30.00f, 1);
    float gGrand = 0.0f, oGrand = 0.0f;
    DdhFramePop(grand, 1, 29.00f, 1, 0.0f, &gGrand, &oGrand);
    CsNear(gGrand, 1.00f, "孙帧整段 gross");
    CsNear(oGrand, 1.00f, "孙帧 own");
    CsNear(childA->childSumSameVictim, 1.00f, "子帧 A 收到孙帧 1.00（同目标�?);
    float gChild = 0.0f, oChild = 0.0f;
    DdhFramePop(childA, 1, 44.37f, 1, 0.0f, &gChild, &oChild);
    CsNear(gChild, 5.63f, "子帧 A 整段（含孙帧 1.00�?);
    CsNear(oChild, 4.63f, "子帧 A own = 5.63 - 1.00");
    CsChild(1, CS_B, 50.00f, 5.63f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsNear(p->childSumSameVictim, 5.63f, "父帧同目标子合计仍是 5.63（孙帧不重复扣）");
    DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsNear(own, 22.50f, "父帧 own �?= 22.50（扣减已包含孙帧�?1.00�?);

    /* ---- 3) 只有异目标子帧：父帧一分不�?---- */
    CsOut("\n== 3) 只有异目标子帧：父帧 own 不被�?==\n");
    memset(g_frames, 0, sizeof(g_frames));
    p = DdhFramePush(0, CS_A, 101.20f, 1);
    CsChild(1, CS_B, 50.00f, 5.63f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsCheck(p->childCountSame == 0, "异目标子帧不记入父帧");
    DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsNear(own, 28.13f, "父帧 own = 整段 28.13（没有同目标子帧可扣�?);

    /* ---- 4) 栈上限保�?---- */
    CsOut("\n== 4) 栈上限保护（帧栈�?= DDH_MAXDEPTH = %u�?=\n", (unsigned)DDH_MAXDEPTH);
    CsCheck(DdhFramePush(DDH_MAXDEPTH, CS_A, 1.0f, 1) == NULL, "越界层压栈返�?NULL（不越界写）");
    float gSafe = 1.0f, oSafe = 1.0f;
    CsCheck(!DdhFramePop(NULL, 1, 0.0f, 1, 0.0f, &gSafe, &oSafe) && gSafe == 0.0f && oSafe == 0.0f,
            "�?越界帧退栈安全（不崩、输出清零）");

    /* ---- 5) 嵌套扣减日志 ---- */
    CsOut("\n== 5) 嵌套扣减日志（前 3 次）==\n");
    FILE* lf = NULL;
    char logText[4096] = { 0 };
    bool logOk = false;
    if (fopen_s(&lf, g_logPath, "rb") == 0 && lf)
    {
        size_t n = fread(logText, 1, sizeof(logText) - 1, lf);
        logText[n] = 0;
        fclose(lf);
        logOk = true;
    }
    CsCheck(logOk, "能读到嵌套扣减日志文�?);
    CsCheck(strstr(logText, "own=22.50") != NULL, "日志�?own=22.50（父帧扣减后的净掉血�?);
    CsCheck(strstr(logText, "0xA0001000") != NULL, "日志含父帧地址 0xA0001000");
    CsOut("  日志内容（GBK）：\n%s\n", logText);

    CsOut("\n%s（失�?%d 项）\n", g_csFail == 0 ? "== 自检通过 ==" : "== 自检失败 ==", g_csFail);
    return g_csFail;
}

int main(void)
{
    const int fails = DdhChildSumSelfTest();
    if (g_csFile) { fclose(g_csFile); g_csFile = NULL; }
    return fails == 0 ? 0 : (fails > 100 ? 100 : fails);
}
#endif /* DDH_CHILDSUM_TEST */

#ifdef DDH_NAMETEST
/* ===========================================================================
   v9 名字截断自检（只�?`cl /DDDH_NAMETEST ddh.cpp` 的临时验证用，build_hook.ps1
   不定义这个宏，发�?ddh.dll 里没有这一段）�?
   验证 DdhUtf8SafeCopy�?9/63 字节切在汉字中间时回退到完整字符边界，
   源串自己以半个汉字结尾时也丢掉残字符�?
   =========================================================================== */
static int g_ntFail = 0;
static void NtCheck(bool ok, const char* what)
{
    printf("[%s] %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) g_ntFail++;
}

int main(void)
{
    char out[64] = { 0 };
    char text[128] = { 0 };
    for (int i = 0; i < 20; i++) memcpy(text + i * 3, "\xE9\x9B\xAA", 3);   /* 20 个雪 = 60 字节 */
    memcpy(text + 60, "ab", 2);
    memcpy(text + 62, "\xE9\x9B\xAA", 3);                                   /* 再一个雪 = 65 字节 */

    size_t n29 = DdhUtf8SafeCopy(out, sizeof(out), text, 29);
    NtCheck(n29 == 27, "29 边界回退�?27 字节�? 个完整汉字）");
    NtCheck(DdhUtf8Valid(out), "29 边界输出是合�?UTF-8");

    size_t n63 = DdhUtf8SafeCopy(out, sizeof(out), text, 63);
    NtCheck(n63 == 62, "63 边界回退�?62 字节�?0 汉字 + ab�?);
    NtCheck(DdhUtf8Valid(out), "63 边界输出是合�?UTF-8");

    const char* half = "bbbb\xE6\x8A\x80\xE4\xBD";   /* 末尾「位」只有前 2 字节 */
    size_t nh = DdhUtf8SafeCopy(out, sizeof(out), half, 63);
    NtCheck(nh == 7 && strcmp(out, "bbbb\xE6\x8A\x80") == 0, "源串末尾半个汉字被丢掉（bbbb技�?);
    NtCheck(DdhUtf8Valid(out), "源串截断输出是合�?UTF-8");

    printf("== %s（失�?%d 项）==\n", g_ntFail == 0 ? "NAMETEST PASS" : "NAMETEST FAIL", g_ntFail);
    return g_ntFail;
}
#endif /* DDH_NAMETEST */
