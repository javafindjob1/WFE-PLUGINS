﻿//----------------------------------------------------------------------------
// ddh.cpp -- Damage Event Hook (32-bit DLL, injected into war3.exe)
//
// 鐩爣锛氭妸寮曟搸鐨勪激瀹冲嚱锟?game.dll+0x67DC40 鐨勫叆鍙ｆ敼锟?6 瀛楄妭鐨勮烦杞ˉ涓侊紙jmp + NOP锛夛紝
//       璺冲埌鎴戜滑鑷繁锟?__fastcall 鏇挎崲鍑芥暟 DdhDamageFunc锛涘嚱鏁伴噷鍏堣鍓嶈 锟?鑷繁 call
//       鍘熷嚱鏁帮紙璺虫澘锛夆啋 杩斿洖鍚庣珛鍒昏鍚庤 锟?绠楁湰灞傛帀琛€锛岃繑鍥炲€煎師鏍峰甫鍥烇紙锟?UDamageWatcherHook.cpp 鍚屾锛夛拷?
//
// 濂戠害锛堟潵鑷湰浠撳簱 `浼ゅ鐩戣璇存槑.md` 搂2锛屽凡婧愮爜 + 浜岃繘鍒跺弻鍚戝鏍革級锟?
//   uint32_t __fastcall DdhDamageFunc(uint32_t _this /*ecx=鍙椾激鍗曚綅*/,
//                                     uint32_t _edx,
//                                     uint32_t a2,        /* 锟? 璋冪敤鏂圭殑 out锛坒loat*锛夛紝鍑哄彛鍐欐渶缁堜激锟?*/
//                                     war3_event_damage_data* info,
//                                     uint32_t is_physical,
//                                     uint32_t source_unit);   // ret 10h
//   v20 璧凤紝寮曟搸浼ゅ / 鏈€缁堜激锟?/ 鍑€鎺夎鍏ㄩ儴鐢辫繖涓€涓挬瀛愮殑"鍑哄彛涓夎"缁欏嚭锟?
//     鍑哄彛 info+0x10 = 寮曟搸绠楀畬鐨勫€硷紙鎶ょ敳/鏀婚槻绫诲瀷/鍔犳垚涔嬪悗锟?
//     鍑哄彛 *a2       = 鏈€缁堣惤鍦板€硷紙鍚湴锟?SetEventDamage 鐨勬敼鍐欙紱WFE 璇荤殑灏辨槸瀹冿級
//     鍓嶅悗琛€锟?       = 鍑€鎺夎
//   struct war3_event_damage_data {
//       uint32 source_unit;  // +0x00  鏉ユ簮鍗曚綅銆愬璞℃寚閽堬拷?
//       uint32 weapon_type;  // +0x04
//       uint32 unk2;         // +0x08
//       uint32 flag;         // +0x0C  bit0=鏄惁杩滅▼, bit8=鏄惁鏀诲嚮
//       uint32 amount;       // +0x10  浼ゅ鍊硷紙jass real 锟?锟?float 瑙ｉ噴锟?
//       uint32 damage_type;  // +0x14  浼ゅ绫诲瀷浣嶆帺鐮侊紙log2 - 1 = 绫诲瀷鍙凤級
//       uint32 unk6, unk7;   // +0x18/+0x1C
//       uint32 attack_type;  // +0x20  鏀诲嚮绫诲瀷
//   };
//
// 鍘熷嚱鏁板紑澶达紙`WFE浼ゅ鏈哄埗鍒嗘瀽.md` 搂3.4 瀹炴満瀛楄妭锛夛細
//   55 8B EC 83 EC 2C 56 57 8B F9  锟?push ebp; mov ebp,esp; sub esp,0x2C; push esi; push edi; mov edi,ecx
// 锟?6 瀛楄妭姝ｅソ锟?3 鏉″畬鏁存寚浠わ紝鎵€浠ユ惉璧板畠浠槸瀹夊叏鐨勶拷?
//
// 浜嬩欢閫氳繃**鍛藉悕鍏变韩鍐呭瓨**浜ょ粰澶栭潰锟?64 浣嶄富绋嬪簭锛堜笉鍐欑洏銆佷笉鍋氭枃锟?IO锛夛拷?
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

/* v9锛氱儹閿紙RegisterHotKey/GetMessage锛夊拰鎵炬父鎴忕獥鍙ｏ紙FindWindow锛夎锟?user32锟?
   build_hook.ps1 涓嶉澶栦紶 lib锛屾墍浠ュ湪杩欓噷锟?pragma 甯︿笂锟?*/
#pragma comment(lib, "user32.lib")

/* 缁熶竴锟?_snprintf_s + _TRUNCATE 缁勮瀛楃涓诧紝鍙栦唬 sprintf_s 鍙婂悇锟?_s 鍙樹綋锟?
   缂撳啿鍖轰笉澶熸椂鍙€滄埅鏂€濓紝缁濅笉璋冩棤鏁堝弬鏁板鐞嗗櫒锟?
   涓轰粈涔堬細UCRT 锟?sprintf_s 鍦ㄢ€滄斁涓嶄笅鈥濇椂锟?_invoke_watson 锟?__fastfail(FAST_FAIL_INVALID_ARG)锟?
   瀹夸富杩涚▼锛坵ar3.exe锛夊綋锟?0xC0000409 宕╂帀 鈥旓拷?2026-10-31 20:22:52 鐪熸満灏辨槸杩欎箞宕╃殑锟?
   闀夸腑鏂囧悕 鈥溾€︹€︺€愯緟鍔╁崟浣嶏拷?e009)锟?琚啓锟?64 瀛楄妭鐨勨€滃悕锟?锟?鈥濇爣绛撅拷?*/
#define DdhSprintf(buf, cap, ...) _snprintf_s((buf), (cap), _TRUNCATE, __VA_ARGS__)

#define DDH_MAGIC     0x31484444u   /* "DDH1" */
/* v20锛氫笁涓彛寰勫叏閮ㄦ敼锟?0x67DC40 鍗曚釜閽╁瓙锟?鍑哄彛涓夎"缁欏嚭锛屼笉鍐嶆寕 GetEventDamage / SetEventDamage锟?
   v20 鐨勮褰曞湪 v8 涔嬪悗杩藉姞 8 瀛楄妭锛歠inalDamage(float) + finalFlags(uint32)锟?
     寮曟搸浼ゅ = 鍘熷嚱鏁伴€€鍑烘椂锟?info+0x10锛堟姢锟?鏀婚槻绫诲瀷/鍔犳垚涔嬪悗锛屼簨浠舵敼鍐欎笉鍥炲啓瀹冿級
     鏈€缁堜激锟?= 鍘熷嚱鏁伴€€鍑烘椂锟?*out锟? 璋冪敤锟?out 鎸囬拡锛屼篃灏辨槸 WFE 璇荤殑閭ｄ釜鏁帮級
     鍑€鎺夎   = 鍓嶅悗琛€宸紙涓嶅彉锟?
   锟?JASS native 閽╁瓙淇濈暀锛屼絾榛樿鍏抽棴锛涜璇婃柇"鍦板浘璇讳簡鍑犳/鏀逛簡鍑犳"灏辫
   鐜鍙橀噺 DDH_NATIVE_DAMAGE_HOOKS=1锟?*/
#define DDH_VERSION   22
#define DDH_SHM_SIZE  (1u << 20)     /* 1 MB */
#define DDH_MAX_EVENTS 512
#define DDH_MAXDEPTH  16      /* 浼ゅ浜嬩欢鏈€澶у祵濂楀眰鏁帮紙鍦板浘锟?DOT/杩藉姞浼ゅ浼氬杩涙潵锟?*/

/* 锟?C# 绔竴涓€瀵瑰簲锛宲ack(1) */
#pragma pack(push,1)
struct DdhHeader
{
    uint32_t magic;
    uint32_t version;
    uint32_t pid;
    uint32_t capacity;      /* 鐜閲忥紙浜嬩欢鏁帮級 */
    uint32_t count;         /* 宸插啓浜嬩欢鎬绘暟锛堥€掑锟?*/
    uint32_t hookOk;        /* 1 = 鎸傞挬鎴愬姛 */
    uint32_t slotCount;     /* 鎵撹繃锟?vtbl 妲戒綅鏁帮紙澶囩敤鏂规鐢級 */
    uint32_t gameDllBase;
    uint32_t hookRva;
    uint32_t selfTest;      /* 1 = 娉ㄥ叆鎴愬姛浣嗚繕娌＄湅鍒颁激瀹充簨锟?*/
    uint32_t lastTick;
    uint32_t reserved[5];
};

struct DdhEvent
{
    uint32_t seq;
    uint32_t tickMs;
    uint32_t victim;        /* 鍙椾激鍗曚綅瀵硅薄鎸囬拡 */
    uint32_t victimCode;    /* +0x30 锟?4 瀛楄妭锛屽師鏍凤紙涓嶇炕杞紝澶栭潰缁熶竴澶勭悊锟?*/
    uint32_t source;        /* info+0x00 鏉ユ簮鍗曚綅瀵硅薄鎸囬拡 */
    uint32_t sourceCode;
    float    amount;        /* info+0x10 */
    uint32_t flag;          /* info+0x0C */
    uint32_t attackType;    /* info+0x20 */
    uint32_t damageMask;    /* info+0x14 */
    uint32_t weaponType;    /* info+0x04 */
    uint32_t isPhysical;
    uint32_t stackSource;   /* 鏍堝弬锟?source_unit锛堣繖涓瀯寤洪噷閫氬父 0锟?*/
    /* 鍚嶅瓧瀛楁锛氬紩鎿庡師鍚嶆槸 **UTF-8** 瀛楄妭涓诧紝0 缁撳熬锛堢湡鏈烘棩锟?hex=E9 9B AA = 闆嫾锛夛拷?
       v9 璧峰悇 64 瀛楄妭锛坴8 锟?32 瀛楄妭浼氫粠姹夊瓧涓棿鎴柇锛氭湯灏惧墿 E4 BD锛孋# 涓ユ牸 UTF-8
       瑙ｄ笉寮€銆佸洖閫€ GBK 灏辨垚浜嗐€岄幎鈥﹂懗鈥︺€嶄贡鐮侊級銆傚啓鍚嶅瓧涓€寰嬭蛋 DdhUtf8SafeCopy锛氭渶锟?
       63 瀛楄妭 + NUL锛涙埅鏂偣钀藉湪澶氬瓧鑺傚瓧绗︿腑闂存椂鍥為€€鍒拌瀛楃璧峰锛岀粷涓嶅啓鍗婁釜姹夊瓧锟?*/
    char     victimName[64];
    char     sourceName[64];
    /* ---- v3锛氳閲忥紙杩涚▼鍐呯洿鎺ヨ CUnit 鐨勭敓鍛介摼锛屼笉璋冧换锟?JASS锟?---- */
    float    hpBefore;      /* 杩涘叆浼ゅ鍑芥暟鏃剁殑琛€锛堝湴鍥捐Е鍙戣繕娌¤窇锟?*/
    float    hpAfter;       /* 鍘熷嚱鏁拌繑鍥炰箣鍚庯紙鍦板浘澧炰激/鍑忎激宸茬粡璺戝畬锟?*/
    float    actual;        /* 鏈眰鑷繁鐨勬帀琛€ = (hpBefore-hpAfter) - 鍐呭眰瀛愭晥鏋滐紝涓嬮檺 0 */
    uint32_t hpValid;       /* 1 = 鍓嶅悗琛€閮借鍒颁簡锛宎ctual 鍙俊 */
    uint32_t depth;         /* 宓屽灞傚彿锛屼粠 1 寮€锟?*/
    /* ---- v4锛氬紩鎿庝激瀹筹紙鍦板浘绗竴娆¤皟锟?GetEventDamage() 鏃剁殑杩斿洖鍊硷級 ---- */
    float    engineDamage;
    uint32_t engineValid;   /* 1 = 杩欐浜嬩欢鍦板浘纭疄闂繃 GetEventDamage */
    /* ---- v20锛氬師 v5 鐨勪袱涓Ы锛坋ngineLast / engineCalls锛夋敼锟?鏈€缁堜激锟?锟?----
       锟?甯冨眬涓€涓瓧鑺傞兘娌″彉锛堣繕锟?236 瀛楄妭锛夛紝鍙槸璇箟鎹簡锟?
       鏉ユ簮 = `*a2`锛堣皟鐢ㄦ柟 out 鎸囬拡锛屽師鍑芥暟 [ebp+8]锛夈€傚畠灏辨槸 WFE 璇绘潵鐢讳激锟?
       鏁板瓧鐨勯偅鍧楀唴瀛橈細寮曟搸锟?+ 鍦板浘 SetEventDamage 鐨勬敼鍐欙拷?
       finalFlags锟?
         bit0 = 1 锟?鏈纭疄鎺変簡琛€锛坥wn > 0锛夛紝鍊煎彲锟?
         bit1 = 1 锟?涓庡紩鎿庡€间笉锟?锟?鍦板浘鏀硅繃浼ゅ
         bit2 = 1 锟?锟?鍓╀綑琛€锟?閽冲埗锛堝嚮鏉€婧㈠嚭锟?out = 鍓嶈锛屼笉鏄湴鍥炬敼浼ゅ锟?
       鍙湪鐪熸帀琛€鏃舵墠锟?bit0锛氭棤锟?[unit+0x5C]&0x100銆佸厤锟?[+0x158]/[+0x15C]>0锟?
       flags&4 杩欎簺鏃╅€€鍒嗘敮鏍规湰涓嶈绠楋紝鐩存帴鎶婁笂涓€璺虫畫鐣欏湪 game+0xBB81D4 鐨勫€兼妱锟?
       *out锛涢偅绉嶆儏鍐典笅 own = 0锛屼竴寰嬩笉璁わ紝閬垮厤鎶婃棫鏁板瓧褰撴垚杩欐鐨勫湴鍥句激瀹筹拷?
       锛堬拷?DLL 锟?engineLast/engineCalls 璇箟锟?v20 鍙栨秷锛氶粯璁や笉鍐嶆寕
         GetEventDamage锛孋# 绔悓鏃舵寜 v20 鏀硅娉曘€傦級 */
    float    finalDamage;   /* 锟?engineLast 鐨勬Ы */
    uint32_t finalFlags;    /* 锟?engineCalls 鐨勬Ы */
    /* ---- v6锛歋etEventDamage 鏈€鍚庝竴娆¤鐨勶拷?+ 璋冪敤娆℃暟锛堝湴鍥炬敼浼ゅ锟?---
       璁捐繃 0.00 涔熺畻璁捐繃锛堣锟?0 鍗虫湁鏁堬級锛屾病璁捐繃锟?0/0锟?*/
    float    setDamage;
    uint32_t setCalls;
    /* ---- v7锛氱洰鏍囧崟浣嶈潡铏紙椹敳锛夋爣锟?---- */
    uint32_t flags;         /* bit0 = 鐩爣甯﹁潡锟?Aloc锛堥┈鐢诧紝涓嶈繘姝讳骸缁撶畻锟?*/
    /* ---- v8锛氭簮/鐩爣鎵€灞炵帺瀹跺彿锛圝ASS GetOwningPlayer/GetPlayerId锟?1=鏈煡锟?---- */
    int32_t  victimOwner;
    int32_t  sourceOwner;
};
#pragma pack(pop)

/* ===========================================================================
   v11/v12锛氬崟浣嶅睘鎬ц锟?/ 鍝嶅簲锛堛€愭垬鍦哄崟浣嶃€戦〉鐢級
   ---------------------------------------------------------------------------
   鏀惧湪鐜版湁浜嬩欢 ring **涔嬪悗**鐨勭嫭绔嬪尯鍩燂紝v9 鍙婁互鍓嶇殑浜嬩欢甯冨眬涓€涓瓧鑺傞兘涓嶅姩锟?
   C# 鍏堣 hdr.version锟?= 10 鎵嶆寜涓嬮潰鐨勫亸绉诲幓纰板睘鎬у潡锛堬拷?DLL 灏辨暣鍧楄烦杩囷級锟?
   seq 涔熷湪鍧楅锛屼笉濉炶繘 DdhHeader锛岃繖锟?DdhEvent 鐨勫亸绉绘案杩滄槸 64锟?

   DdhShared 甯冨眬锛圕# UnitAttrWire 涓ユ牸鎸夊悓涓€缁勫亸绉昏В鏋愶級锟?
     +0       DdhHeader  hdr                         64 瀛楄妭
     +64      DdhEvent   ev[512]                     512 * 236 = 120832 瀛楄妭
     +120896  DdhAttrBlock attrs                     20360 瀛楄妭
     鍚堣 141256 瀛楄妭锛堝叡浜唴锟?1 MB锛岀话缁版湁浣欙級
     锟?v20 鍙敼 engineLast/engineCalls 涓や釜妲界殑璇箟锛堚啋 finalDamage/finalFlags锛夛紝
       璁板綍闀垮害浠嶆槸 236锛屼笂闈㈣繖浜涘亸绉讳竴涓兘娌″姩锟?

   DdhAttrBlock 甯冨眬锟?
     +0      uint32_t     requestSeq                 C# 閫掑锛堝厛锟?96 锟?unitAddr 鍐欏ソ鍚庯級
     +4      uint32_t     doneSeq                    ddh 澶勭悊瀹屽啓 = requestSeq
     +8      uint32_t     unitAddr[96]               璇锋眰妲斤紙C# 濉紱0 = 绌烘Ы锟?
     +392    DdhUnitAttr  attr[96]                   鍝嶅簲妲斤紙姣忎釜 208 瀛楄妭锟?

   DdhUnitAttr 甯冨眬锛坧ack(1)锟?08 瀛楄妭锛夛細
     +0      uint32_t addr
     +4      uint32_t flags                          DDH_AF_*锟? = 璇ュ瓧娈垫湁锟?
     +8      char     typeCode[5]                    4 瀛楃锟?+ NUL锛堝凡缈绘锛屽彲鐩存帴鏄剧ず锟?
     +13     char     name[64]                       鍗曚綅鍚嶏紙UTF-8锟? 缁撳熬锟?
     +77     char     title[64]                      Propernames 涓撳悕锛圲TF-8锛涚┖ = 鏃犱笓鍚嶏級
     +141    float    attackRange                    鏀诲嚮鑼冨洿
     +145    float    damageMin                      鏀诲嚮鍔涗笅锟?
     +149    float    damageMax                      鏀诲嚮鍔涗笂锟?
     +153    float    attackInterval                 鏀诲嚮闂撮殧锛堢锟?
     +157    float    armor                          鎶ょ敳
     +161    float    moveSpeed                      绉伙拷?
     +165    float    sight                        鏃у瓧娈碉紙v14 璧蜂笉鍐嶄娇锟?涓嶇疆浣嶏紝锟?+177/+181锟?
     +169    float    acquireRange                 涓诲姩鏀诲嚮鑼冨洿
     +173    float    baseSpeed                    UnitBalance spd锛堝熀纭€閫熷害锟?
     +177    float    sightDay                      锟?鍗忚 v14锛氱櫧澶╄锟?= jass.slk 锟?sight
     +181    float    sightNight                    锟?鍗忚 v14锛氬鏅氳锟?= jass.slk 锟?nsight
     +185    int32_t  baseArmor                      UnitBalance def锛堝熀纭€鎶ょ敳锟?
     +189    uint8_t  pad[3]                         瀵归綈锟?192
     +192    float    strength                      鍔涢噺锛圙etHeroStr锛屼粎鑻遍泟锟?
     +196    float    agility                       鏁忔嵎锛圙etHeroAgi锛屼粎鑻遍泟锟?
     +200    float    intelligence                  鏅哄姏锛圙etHeroInt锛屼粎鑻遍泟锟?
     +204    int32_t  extraValue                    鍗曚綅闄勫姞鍊硷紙GetUnitUserData锟?
     鏈熬 = 208锛坴11 锟?v10 锟?192 瀛楄妭鍚庨潰杩藉姞 16 瀛楄妭锛涘墠 192 瀛楄妭鍋忕Щ鍏ㄤ笉鍙橈級
   =========================================================================== */

#define DDH_ATTR_MAX        96       /* v12锟?4 锟?96锛堝叡浜唴瀛樺瘜浣欙紱C# 杞鍏ㄩ儴鍗曚綅锟?*/
#define DDH_ATTR_TTL_MS     3000u    /* v12锛氭瘡鍗曚綅瑙ｆ瀽缁撴灉缂撳瓨 3 绉掞紙C# 锟?1 绉掗棶涓€杞紝閬垮厤鍒氭嬁鍒板氨琚噸绠楋級 */

#define DDH_AF_TYPECODE     0x00000001u
#define DDH_AF_NAME         0x00000002u
#define DDH_AF_TITLE        0x00000004u
#define DDH_AF_ATTACKRANGE  0x00000008u
#define DDH_AF_DAMAGE       0x00000010u   /* damageMin / damageMax 涓€锟?*/
#define DDH_AF_INTERVAL     0x00000020u
#define DDH_AF_ARMOR        0x00000040u
#define DDH_AF_MOVESPEED    0x00000080u
#define DDH_AF_SIGHT        0x00000100u   /* 锟?sight 瀛楁锛坴14 璧蜂笉鍐嶇疆浣嶏紝淇濈暀瀹氫箟鍏煎锟?*/
#define DDH_AF_ACQUIRE      0x00000200u
#define DDH_AF_BASE_SPEED   0x00000400u   /* +173 float锛歎nitBalance spd锛堝熀纭€閫熷害锟?*/
#define DDH_AF_SIGHT_DAY    0x00000800u   /* 鍗忚 v14锟?177 float = jass.slk sight锛堢櫧澶╄閲庯級 */
#define DDH_AF_SIGHT_NIGHT  0x00001000u   /* 鍗忚 v14锟?181 float = jass.slk nsight锛堝鏅氳閲庯級 */
#define DDH_AF_BASE_ARMOR   0x00002000u   /* +185 int32锛歎nitBalance def锛堝熀纭€鎶ょ敳锟?*/
#define DDH_AF_HEROKNOWN    0x00004000u   /* 鑻遍泟鍒ゅ畾鍙俊 */
#define DDH_AF_HERO         0x00008000u   /* 1 = 鑻遍泟锟? = 闈炶嫳锟?*/
/* v11 杩藉姞瀛楁锟?192 璧凤級锟?x4000/0x8000 宸茶鑻遍泟浣嶅崰鐢紝鎵€浠ヤ粠 0x10000 锟?*/
#define DDH_AF_STR          0x00010000u   /* +192 float锛氬姏閲忥紙GetHeroStr锛屼粎鑻遍泟锟?*/
#define DDH_AF_AGI          0x00020000u   /* +196 float锛氭晱鎹凤紙GetHeroAgi锛屼粎鑻遍泟锟?*/
#define DDH_AF_INT          0x00040000u   /* +200 float锛氭櫤鍔涳紙GetHeroInt锛屼粎鑻遍泟锟?*/
#define DDH_AF_EXTRA        0x00080000u   /* +204 int32锛氬崟浣嶉檮鍔犲€硷紙GetUnitUserData锛涚晫闈㈠凡涓嶆樉绀猴級 */
#define DDH_AF_LOCUST       0x00100000u   /* 鍗忚 v14锛氳鍗曚綅锟?Aloc锛堣潡铏級锟?鎴樺満鍗曚綅涓嶆樉锟?*/

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
    float    sight;           /* 鏃у瓧娈碉紙v14 璧蜂笉鍐嶄娇锟?涓嶇疆浣嶏紱鐧藉ぉ/澶滄櫄锟?sightDay/sightNight锟?*/
    float    acquireRange;
    float    baseSpeed;       /* spd    */
    float    sightDay;        /* 鍗忚 v14锛氱櫧澶╄锟?= jass.slk sight锛坰lk 鍙栦笉鍒版椂閫€锟?0x3ADF0锟?*/
    float    sightNight;      /* 鍗忚 v14锛氬鏅氳锟?= jass.slk nsight锛堝彇涓嶅埌 锟?鏃犳晥锛岀晫锟??锟?*/
    int32_t  baseArmor;       /* def    */
    uint8_t  pad[3];
    /* ---- v11 杩藉姞锛堝墠 192 瀛楄妭鍋忕Щ涓€涓兘涓嶅姩锟?--- */
    float    strength;        /* GetHeroStr(handle, 0)锛氫粎鑻遍泟 */
    float    agility;         /* GetHeroAgi(handle, 0)锛氫粎鑻遍泟 */
    float    intelligence;    /* GetHeroInt(handle, 0)锛氫粎鑻遍泟 */
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

/* v12 鍗忚闀垮害閽夋锛氬崟锟?= 192 + 4*4 = 208锛涘潡 = 8 + 96*4 + 96*208 = 20360锟?
   鏀圭粨鏋勫繕浜嗗悓姝ュ父閲忔椂锛岃繖閲屼細鐩存帴缂栬瘧澶辫触锛岃€屼笉鏄瓑 C# 鏁村垪鏄剧ず ?锟?*/
typedef char DdhUnitAttrSizeIs208[(sizeof(DdhUnitAttr) == 208) ? 1 : -1];
typedef char DdhAttrBlockSizeIs20360[(sizeof(DdhAttrBlock) == 20360) ? 1 : -1];

#define DDH_ATTR_BLOCK_OFFSET ((uint32_t)(sizeof(DdhHeader) + DDH_MAX_EVENTS * sizeof(DdhEvent)))
#define DDH_ATTR_RESP_OFFSET  (8u + DDH_ATTR_MAX * 4u)
#define DDH_ATTR_BLOCK_SIZE   (DDH_ATTR_RESP_OFFSET + DDH_ATTR_MAX * (uint32_t)sizeof(DdhUnitAttr))

/* ===========================================================================
   v15锛氭父鎴忓唴闃典骸闈㈡澘 / 鑻遍泟鏌ヨ锛堣拷鍔犲湪灞炴€у潡涔嬪悗锟?
   ---------------------------------------------------------------------------
   甯冨眬锛圕# InGamePanelWire 涓ユ牸鎸夊悓涓€缁勫亸绉昏В鏋愶級锟?
     +0        DdhHeader      hdr                       64
     +64       DdhEvent       ev[512]                  120832
     +120896   DdhAttrBlock   attrs                     20360
     +141256   DdhPanelBlock  panel                      4952
     +146208   DdhHeroBlock   hero                        400
     鍚堣 146608 瀛楄妭锛堝叡浜唴锟?1 MB锛夛拷?
   =========================================================================== */
#define DDH_PANEL_MAX_LINES   20
#define DDH_PANEL_LINE_TEXT   240
#define DDH_PANEL_FONT_NAME   32
#define DDH_HERO_SLOTS        16
#define DDH_ICON_MAX          4

/* v16锛歅anelBlock.flags 鏂板浣嶏紙bit0/1 浠嶆槸鏄剧ず/闅愯棌锟?*/
#define DDH_PANEL_FLAG_SHOW       0x1u
#define DDH_PANEL_FLAG_HIDE       0x2u
#define DDH_PANEL_FLAG_BG         0x4u   /* bit2锛氬惎鐢ㄨ儗锟?*/
#define DDH_PANEL_FLAG_COLLAPSED  0x8u   /* bit3锛氶粯璁ゆ敹锟?*/
#define DDH_PANEL_FLAG_CHART     0x10u   /* bit4锛氶潰鏉垮潡鏀逛綔鈥滄壙浼ゅ浘琛ㄨ姹傗€濓紝payload 锟?lines 锟?*/
#define DDH_CHART_MAGIC          0x31544843u   /* 'CHT1' */
#define DDH_PANEL_COLLAPSED_SHIFT 8      /* bit8..15锛氭敹璧锋椂鏄剧ず鐨勮鏁帮紙0 => 3锟?*/
#define DDH_PANEL_COLLAPSED_MASK  0xFFu

#pragma pack(push,1)
struct DdhPanelLine
{
    uint32_t color;                         /* 0xAARRGGBB锛堝紩锟?SetTextColor 鍙ｅ緞锟?*/
    char     text[DDH_PANEL_LINE_TEXT];     /* UTF-8锟? 缁撳熬锛汣# 淇濊瘉涓嶅垏鍧忔眽锟?*/
};

struct DdhPanelBlock
{
    uint32_t    seq;            /* C# 姣忔鏂板唴锟?+1锛堟渶鍚庡啓锟?*/
    uint32_t    appliedSeq;     /* ddh 鎷峰嚭鍐呭鍚庡啓 = seq */
    uint32_t    flags;          /* bit0=鏄剧ず锛宐it1=闅愯棌锛坔ide 鏃朵笉璇绘枃鏈級 */
    uint32_t    ttlMs;          /* 鑷姩闅愯棌姣锟? => 榛樿 20000 */
    uint32_t    lineCount;      /* 1..DDH_PANEL_MAX_LINES */
    uint32_t    anchor;         /* 0..8锛圵C3 閿氱偣鏋氫妇锛岄粯锟?0=TOPLEFT锟?*/
    float       x;              /* 灞忓箷姣斾緥锛堢浉瀵规牴甯э紝榛樿 0.60锟?*/
    float       y;              /* 榛樿 -0.24 */
    float       lineHeight;     /* 榛樿 0.0175 */
    float       fontHeight;     /* 榛樿 0.0135 */
    char        fontName[DDH_PANEL_FONT_NAME];   /* 榛樿 MasterFont */
    DdhPanelLine lines[DDH_PANEL_MAX_LINES];
};

struct DdhHeroReq
{
    uint32_t addr;          /* 缁撶畻鍗曚綅鍦板潃锛堜粎鍥炰紶鐢紝鍙负 0锟?*/
    uint32_t rawcode;       /* JASS 椤哄簭锟?4 瀛楃绫诲瀷鐮侊細'Hpal' = 0x4870616C */
};

struct DdhHeroRes
{
    uint32_t addr;
    uint32_t rawcode;
    int32_t  isHero;        /* 1=锟?0=锟?-1=native 鏆傛椂涓嶅彲锟?*/
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
    uint32_t lineIndex;     /* 0 鍩洪潰鏉胯锟?*/
    uint32_t rawcode;       /* JASS 椤哄簭绫诲瀷锟?*/
    uint32_t sourceAddr;    /* v19锛氫激瀹虫潵锟?CUnit*锟?D 鑲栧儚锟?*/
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

typedef char DdhEventSizeIs236[(sizeof(DdhEvent) == 236) ? 1 : -1];   /* v20 澶嶇敤 engineLast/engineCalls 涓や釜妲斤紝闀垮害涓嶅彉 */
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
    DdhAttrBlock attrs;          /* v10锛氬睘鎬ц锟?鍝嶅簲锛堜簨锟?ring 涔嬪悗鐨勭嫭绔嬪尯鍩燂級 */
    DdhPanelBlock panel;         /* v15锛氭父鎴忓唴闃典骸闈㈡澘锛堝睘鎬у潡涔嬪悗锟?*/
    DdhHeroBlock  hero;          /* v15锛氳嫳闆勬煡璇紙闈㈡澘鍧椾箣鍚庯級 */
    DdhIconBlock  icons;         /* v17锛氫激瀹虫潵婧愬ご鍍忥紙鑻遍泟鍧椾箣鍚庯級 */
};

static HANDLE         g_map = NULL;
static DdhShared*     g_shm = NULL;
static HMODULE        g_self = NULL;

static uint8_t*       g_hookAt = NULL;      /* game.dll + 0x67DC40 */
static uint8_t*       g_tramp = NULL;       /* 鎼蛋鐨勫墠 6 瀛楄妭 + jmp 鍥炲幓 */
static const uint32_t HOOK_RVA = 0x67DC40;
static uint8_t        g_saved[8];
static bool           g_hooked = false;
static uint32_t       g_foundRva = 0;

/* ---- v3锛氬祵濂楀眰娆＄殑鐘舵€侊紙浼ゅ鍙湪娓告垙绾跨▼涓婂彂鐢燂紝鐢ㄦ爤寮忔暟缁勫嵆鍙級 ---- */
static volatile LONG  g_depth = 0;                    /* 褰撳墠宓屽娣卞害锟? = 涓嶅湪浼ゅ鍑芥暟閲岋級 */
static uint32_t       g_slot[DDH_MAXDEPTH];            /* 鏈眰浜嬩欢鍦ㄧ幆閲岀殑涓嬫爣 */
static uint32_t       g_seq[DDH_MAXDEPTH];             /* 鏈眰浜嬩欢搴忓彿锛堥槻鐜鐩栧啓閿欒锟?*/
static uint32_t       g_levelTick[DDH_MAXDEPTH];       /* 鏈眰鍏ュ彛鏃堕棿锛堥槻 SEH 灞曞紑鎶婃繁搴︽紡鎺夛級 */
static uint32_t       g_hpCount = 0;                   /* 鎴愬姛璇诲埌鍓嶅悗琛€鐨勪簨浠舵暟锛堣瘖鏂敤锟?*/

/* ---- v13锛氬瓙浼ゅ锟?*璋冪敤锟?*绱锛屼笖鍙墸鍚屼竴涓洰鏍囷紙victim锟?---
   鏃х増姣忓眰鍙湁涓€锟?g_childSum锛氬鐩爣 AoE 鏃讹紝鍐呭眰鎵撳埆浜猴紙鍏搁煢/姝ュ叺锛夌殑鎺夎
   涔熻鎵ｅ埌鏈眰澶翠笂 鈥旓拷?澶栧眰鎵撳紶椋炴帀 28.13锛屾樉绀烘垚 1.87锛涙纭槸 22.50锟?
   鐜板湪姣忚繘涓€娆′激瀹冲嚱鏁板帇涓€甯э紝閫€甯ф椂锟?
       own = (hpBefore - hpAfter) - childSumSameVictim
   childSumSameVictim 鍙疮璁♀€渧ictim 鍦板潃涓庢湰甯х浉鍚屸€濈殑瀛愬抚閫€甯ф椂涓婃姤锟?gross
   锛坔pBefore - hpAfter锛夛紱涓嶅悓鐩爣鐨勫瓙甯у彧璁拌嚜宸辩殑浜嬩欢锛屼笉鎵ｆ湰甯э拷?
   甯ф爤锟?= 浜嬩欢灞傛繁 DDH_MAXDEPTH锛涜秺鐣岀敱 DdhDamageFunc 锟?d > DDH_MAXDEPTH
   鐨勬棫閫€鍖栧垎鏀厹浣忥紙鍙彁绀轰竴娆℃棩蹇楋級锟?*/
typedef struct DdhFrame
{
    uint32_t victim;              /* 鏈抚鐩爣鍗曚綅鍦板潃锛圕Unit*锟?*/
    uint32_t depth;               /* 1 鍩哄眰鍙凤紙= level + 1锛屼笌浜嬩欢 depth 瀛楁鍚屼箟锟?*/
    uint32_t hpOk;                /* 鍓嶈鏄惁璇诲埌锟? = 娌℃祴鍒帮紝鏈抚涓嶇畻 own锟?*/
    uint32_t active;              /* 甯ф槸鍚﹁繕鍦ㄦ爤涓婏紙閫€甯у悗锟?0锛岄槻璇敤锟?*/
    float    hpBefore;            /* 杩涘叆浼ゅ鍑芥暟鏃惰鍒扮殑琛€ */
    float    hpAfter;             /* 鍘熷嚱鏁拌繑鍥炲悗璇诲埌鐨勮 */
    float    childSumSameVictim;  /* 宸查€€鏍堛€乿ictim 涓庢湰甯х浉鍚岀殑瀛愬抚 gross 鍚堣 */
    uint32_t childCountSame;      /* 鍚岀洰鏍囧瓙甯х瑪鏁帮紙鏃ュ織鐢級 */
} DdhFrame;
static DdhFrame       g_frames[DDH_MAXDEPTH];          /* 甯ф爤锛氫笅锟?= 灞傚彿 */
static volatile LONG  g_nestedLogCount = 0;            /* 鈥滃祵濂楁墸鍑忊€濇棩蹇楀彧鍐欏墠 3 锟?*/
static volatile LONG  g_depthOverflowLogged = 0;       /* 鏍堟繁婧㈠嚭鍙彁绀轰竴锟?*/

/* ---- 鍘熶激瀹冲嚱鏁拌烦鏉匡細锟?UDamageWatcherHook.cpp 锟?ORIG_DAMAGE 鍚屾 ----
   瀹夎鏃舵妸 0x67DC40 锟?6 瀛楄妭鎼繘鍙墽琛屽唴锟?+ E9 璺冲洖锛岃烦鏉垮湴鍧€瀛樿繖閲岋紱
   DdhDamageFunc 锟?call 杩欎釜璺虫澘 = 璺戝師鍑芥暟浣擄紝鍘熷嚱鏁扮粨锟?ret 0x10 鍥炲埌鎴戜滑锟?*/
typedef uint32_t (__fastcall *fn_damage_t)(uint32_t _this, uint32_t _edx, uint32_t a2,
                                           void* info, uint32_t is_physical, uint32_t source_unit);
static volatile LONG  g_original_damage = 0;


/* ---- v4锛氬紩鎿庝激瀹筹紙GetEventDamage 棣栨璋冪敤锟?---- */
static uint32_t g_engineCap[DDH_MAXDEPTH];            /* 姣忓眰绗竴娆℃姄鍒扮殑寮曟搸浼ゅ锛坒loat 浣嶆ā寮忥級 */
static uint32_t g_engineFirstSet[DDH_MAXDEPTH];       /* 姣忓眰棣栨鍊兼槸鍚﹀凡鎶撳埌锟? 涔熸槸鍚堟硶鍊硷紝涓嶈兘锟?0 褰撳摠鍏碉級 */
static uint32_t g_engineLast[DDH_MAXDEPTH];           /* 姣忓眰**鏈€鍚庝竴锟?*鎶撳埌鐨勶拷?*/
static uint32_t g_engineCalls[DDH_MAXDEPTH];          /* 姣忓眰 GetEventDamage 琚皟鐢ㄤ簡鍑犳 */
static volatile LONG g_gedTries = 0;
static volatile LONG g_gedHooked = 0;
static uint32_t g_realGetEventDamage = 0;
/* ---- SetEventDamage锛堝湴鍥炬敼浼ゅ锟?--- */
static uint32_t g_setCap[DDH_MAXDEPTH];            /* 姣忓眰**鏈€鍚庝竴锟?* SetEventDamage 璁剧殑鍊硷紙float 浣嶆ā寮忥級 */
static uint32_t g_setSet[DDH_MAXDEPTH];            /* 姣忓眰鏄惁璁捐繃锟? 涔熸槸鍚堟硶 SetEventDamage(0)锛屼笉鑳芥嬁 0 褰撳摠鍏碉級 */
static uint32_t g_setCalls[DDH_MAXDEPTH];          /* 姣忓眰 SetEventDamage 琚皟鐢ㄤ簡鍑犳 */
static volatile LONG g_sedTries = 0;
static volatile LONG g_sedHooked = 0;
static uint32_t g_realSetEventDamage = 0;
/* v20锛欽ASS native 閽╁瓙锛圙etEventDamage / SetEventDamage锛夐粯锟?*涓嶅啀瀹夎**锟?
   0x67DC40 锟?鍑哄彛涓夎"宸茬粡鑳藉悓鏃剁粰锟?寮曟搸浼ゅ锛堝嚭锟?info+0x10锛夛拷?
   鏈€缁堜激瀹筹紙鍑哄彛 *out锛夊拰 鍑€鎺夎锛堝墠鍚庤宸級锛屼笉闇€瑕佸啀鍘婚亶锟?JASS 鍝堝笇琛拷?
   涔熶笉鐢ㄨ祵 JAPI 鍦ㄨ繘鍥惧墠鏄惁灏辩华锛堥偅姝ｆ槸鑰佸疄鐜版渶鑴嗗急鐨勪竴鐜級锟?
   鍙湁鎯宠瘖锟?鍦板浘璇讳簡鍑犳銆佹敼浜嗗嚑锟?鏃舵墠鐢ㄧ幆澧冨彉閲忔墦寮€锟?
       set DDH_NATIVE_DAMAGE_HOOKS=1 */
static int g_nativeHooks = -1;                        /* -1 = 杩樻病璇荤幆澧冨彉锟?*/
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
static LARGE_INTEGER g_qpcFreq;                       /* 浼ゅ鍑芥暟鑰楁椂锛堣瘖鏂敤锟?*/
static LARGE_INTEGER g_qpcStart[DDH_MAXDEPTH];
static volatile LONG g_hpLogCount = 0;
static bool           g_namesEnabled = true;   /* 鏌ュ崟浣嶅悕锛堝け璐ヤ細鑷姩閫€鍥炵被鍨嬬爜锟?*/

static char           g_mapName[128];
static int            g_logEnabled = 0;   /* 1 = 鍐欐棩蹇楋紙鍙戝竷鍖呴粯璁ゅ叧闂紝鏀?ddh_log.on 鎵撳紑锛?*/
static char           g_logPath[MAX_PATH];

static void LogLine(const char* fmt, ...)
{
    if (!g_logEnabled) return;
    if (g_logPath[0] == 0) return;
    /* 鐢?CreateFile 鏄惧紡甯?FILE_SHARE_READ|WRITE锛氬閮ㄥ伐鍏峰彲鍦ㄦ父鎴忚繍琛屾椂璇诲彇鏃ュ織锛?
       鍚﹀垯 fopen 鐨勭嫭鍗犲彞鏌勪細璁?PowerShell 璇讳笉鍒帮紙涔嬪墠灏辨槸杩欎釜闂锛夈€?*/
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


/* ---- v13锛氬抚鏍堝帇锟?/ 閫€鏍堬紙瀛愪激瀹冲彧鎵ｅ悓涓€涓洰鏍囷級----
   Push锛氳繘鍏ヤ激瀹冲嚱鏁般€佽鍒板墠琛€涔嬪悗璋冪敤锛汸ush 浼氭妸璇ュ眰鐨勫抚鐘舵€佹暣涓噸缃拷?
   Pop 锛氬師鍑芥暟杩斿洖銆佽鍒板悗琛€涔嬪悗璋冪敤锛屽仛涓変欢浜嬶細
     锟?own = (hpBefore - hpAfter) - childSumSameVictim锛堝彧鍑忓悓鐩爣瀛愬抚锛夛紱
     锟?鎶婃湰锟?gross 鍔犲埌鐖跺抚锟?childSumSameVictim锟?*浠呭綋鐖跺抚 victim == 鏈抚 victim**锟?
     锟?杩斿洖鈥滄湰甯ф槸鍚︽祴鍒拌鈥濓紙浜嬩欢 hpValid/actual 鐢級锟?
   fallback 淇濈暀鏃ц涔夛細鏈抚璇讳笉鍒拌鏃剁敤寮曟搸浼ゅ浼颁竴涓氦缁欑埗甯э紝閬垮厤鐖跺抚 over-count锟?
   瀹冨悓鏍峰彧鍦ㄢ€滅埗锟?victim == 鏈抚 victim鈥濇椂鎵嶅姞锟?*/
static DdhFrame* DdhFramePush(uint32_t level, uint32_t victim, float hpBefore, uint32_t hpOk)
{
    if (level >= DDH_MAXDEPTH) return NULL;      /* 鏍堜笂闄愪繚鎶わ細缁濅笉瓒婄晫锟?*/
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
        gross = f->hpBefore - hpAfter;             /* 鏈抚鏁存鎺夎锛堝惈鏇存繁鐨勫悓鐩爣瀛愬抚锟?*/
        if (gross < 0.0f) gross = 0.0f;
        own = gross - f->childSumSameVictim;       /* 鑷繁锟?= 鏁存 - 鍚岀洰鏍囧瓙锟?*/
        if (own < 0.0f) own = 0.0f;
        f->hpAfter = hpAfter;
        measured = true;
    }

    /* 鎶ョ粰鐖跺抚锛氭甯哥敤鏁存 gross锛涙湰甯ц涓嶅埌琛€鏃堕€€鍥炲紩鎿庝激瀹充及涓€涓紙鏃ц涔夛級锟?
       鍏抽敭锛氬彧鏈夌埗锟?victim 涓庢湰甯х浉鍚屾椂鎵嶆墸 鈥旓拷?澶氱洰锟?AoE 閲屾墦鍏搁煢/姝ュ叺锟?
       瀛愪簨浠朵笉浼氭妸寮犻锛堢埗甯э級锟?net 鎵ｆ帀锟?*/
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

    /* 锟?3 娆♀€滄湁鍚岀洰鏍囧瓙浼ゅ鈥濈殑浜嬩欢鐣欎竴琛岋紝鏂逛究鐪熸満鏍稿鐖跺抚鍑€鎺夎 */
    if (measured && f->childCountSame > 0 &&
        InterlockedIncrement(&g_nestedLogCount) <= 3)
    {
        LogLine("宓屽鎵ｅ噺锛氱埗=0x%08X 瀛愬悎璁?%.2f锛堝悓鐩爣 %u 绗旓級own=%.2f",
                f->victim, f->childSumSameVictim, f->childCountSame, own);
    }

    if (outGross) *outGross = gross;
    if (outOwn)   *outOwn   = own;
    return measured;
}

/* 璇讳竴涓崟浣嶅璞＄殑 4 瀛楃绫诲瀷鐮侊紙+0x30 鐨勫師锟?4 瀛楄妭锛夛拷?
   娉ㄦ剰锛氬唴瀛橀噷锟?*鍙嶅簭**瀛樼殑锛堟樉绀烘椂鎵嶇炕杞級锛岃繖閲屼繚鎸佸師鏍蜂氦鍑哄幓锛岀敱澶栭潰缁熶竴缈昏浆锟?*/
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
   璇讳竴涓崟浣嶅墠鍚庤閲忓€硷拷?
   杩欐潯閾句笌鎻掍欢 UDamageWatcherHook.cpp 瀹屽叏涓€鑷达紝鍙蛋寮曟搸 GetUnitState锟?
       ctx    = *(game.dll + 0x00BE4238)
       mgr    = *(ctx + 0x1C)锛堝彛锟?锟?锟?0x001C3200(ctx)锛堝彛锟?锟?
       handle = 0x002651D0(mgr, 0, obj, 0)锛堣皟鐢ㄦ硶锟?锟?鍙ユ焺琛ㄥ唴瀛樻壂鎻忥紙鍐呭瓨鎵硶锟?
       鍥炵▼鏍￠獙 = 0x001D1550(handle) == obj锛圚unit -> CUnit*锟?
       hpBits = 0x001E6600(handle, 0)锛坃_cdecl锛宻tate 0 = LIFE锛夋寜 float 浣嶆ā寮忚В锟?
   棣栨璋冪敤鏃跺湪 __try 閲岃В鏋愬嚱鏁板湴鍧€锛堝甫搴忚█鏍￠獙锛夛紝鐢ㄢ€滆皟鐢ㄦ硶/鍐呭瓨鎵硶 脳 涓ょ绠＄悊鍣ㄥ彛寰勶拷?
   鍥涚缁勫悎鍋氬洖绋嬫牎楠屽畾鍨嬶紝閫氳繃鍗崇紦瀛樼粍鍚堬紙瀵归綈鎻掍欢锟?g_nativeUseMemory/g_nativeMgrWhich锛夛拷?
   鍥涚缁勫悎閮芥病杩囷細鏃ュ織鍐欎竴娆★紝涔嬪悗浠嶅彲閲嶈瘯浣嗘渶锟?16 娆★紝闄愭鍚庤繑锟?0锛岃浆鍐呭瓨鍥為€€锟?
   涓昏矾浠讳綍涓€姝ュけ璐ワ紙鍙ユ焺 0 / native 娌″畾锟?/ 杩斿洖鍊奸潪鏈夐檺锛夐兘鍥為€€鍒板唴瀛橀摼锟?
       idx   = *(u32*)(CUnit + 0xA0)
       table = *(u32*)(*(u32*)(game.dll + 0xBE40A8) + 0x0C)
       obj   = *(u32*)(table + idx*8 + 4)
       hp    = *(float*)(obj + 0x78)
   涓庢彃浠惰琛€涓昏矾淇濇寔涓€鑷达紱鍐呭瓨閾惧彧鍋氬厹搴曪紝鍙栦笉鍒版墠鎸夎涓嶅埌澶勭悊锛堢晫闈㈡樉锟??锛夛拷?
   鍏ㄧ▼ __try 鍖呬綇锛宧p 鍋氭湁闄愭€ц嚜妫€锟?1e6 < hp < 1e7锛孨aN 鏃犳晥锛夛拷?
   --------------------------------------------------------------------------- */
#define DDH_RVA_CTX_GLOBAL         0x00BE4238u  /* ctx = *(game.dll + RVA) */
#define DDH_RVA_OBJ_TO_HANDLE      0x002651D0u  /* __fastcall(mgr,0,obj,0) -> 鍙ユ焺 */
#define DDH_RVA_HANDLE_TO_UNIT     0x001D1550u  /* __fastcall(handle,0) -> CUnit* */
#define DDH_RVA_HANDLEMGR_FROM_CTX 0x001C3200u  /* __fastcall(ctx,0) -> 鍙ユ焺绠＄悊锟?*/
#define DDH_RVA_GET_UNIT_STATE     0x001E6600u  /* __cdecl(handle,state) -> float 浣嶆ā锟?*/
#define DDH_OFF_CTX_HANDLEMGR      0x0000001Cu  /* ctx+0x1C = 鍙ユ焺绠＄悊鍣ㄦ寚锟?*/
#define DDH_OFF_MGR_COUNT          0x00000198u  /* mgr+0x198 = 鏉＄洰锟?3 */
#define DDH_OFF_MGR_TABLE          0x0000019Cu  /* mgr+0x19C = 鍙ユ焺琛ㄥ熀鍧€ */
#define DDH_HANDLE_BASE            0x00100000u
#define DDH_HANDLE_LIMIT           0x00200000u

/* ---- 涓昏矾澶辫触鏃剁殑鍐呭瓨鍥為€€閾撅紙War3Trainer 鍚屾簮锟?.27 宸插疄鏈洪獙璇侊級---- */
#define DDH_RVA_THISGAME_GLOBAL    0x00BE40A8u  /* ThisGame = *(game.dll + RVA) */
#define DDH_OFF_UNIT_HP_INDEX      0x000000A0u  /* CUnit + 0xA0 = 鐢熷懡鐘舵€佺储锟?*/
#define DDH_OFF_THISGAME_TABLE     0x0000000Cu  /* ThisGame + 0x0C = 娓告垙鍐呭瓨琛紙8 瀛楄妭涓€椤癸級 */
#define DDH_OFF_TABLE_OBJECT       0x00000004u  /* table[idx*8+4] = 鐢熷懡鐘舵€佸锟?*/
#define DDH_OFF_STATE_CUR_HP       0x00000078u  /* 鐘舵€佸锟?+ 0x78 = 褰撳墠 HP锛坒loat锟?*/
#define DDH_HP_INDEX_LIMIT         0x00200000u  /* 绱㈠紩涓婇檺锛屾尅鈥滃噾宸у儚鍗曚綅鈥濈殑鍐呭瓨 */

static uint32_t g_modBase = 0;                 /* game.dll 鍩哄潃锛圛nstallHook 鏃跺～锟?*/
static uint32_t g_imageSize = 0;               /* game.dll 鏄犲儚澶у皬锛圥E SizeOfImage锛涘崗锟?v13 瑙嗛噹 RVA 鏍￠獙鐢級 */

/* ---- GetUnitState 璇昏鐨勫畾鍨嬬姸鎬侊紙瀵归綈鎻掍欢 g_nativeMgrWhich/g_nativeUseMemory锟?--- */
static int           g_hpMgrWhich  = -1;   /* -1=鏈畾 0=绾唴锟?(ctx+0x1C) 1=寮曟搸璁块棶锟?x1C3200 2=鏀惧純 */
static int           g_hpUseMemory = 0;    /* 0=璋冪敤 0x2651D0 1=绾唴瀛樻壂鎻忥紙瀹氬瀷鍚庝笌鍙ｅ緞缁戝畾缂撳瓨锟?*/
static volatile LONG g_hpObj2HTries = 0;   /* 鍥涚缁勫悎閮藉け璐ョ殑绱娆℃暟锛堟渶锟?16 娆★級 */
static volatile LONG g_hpTypeFailLogged = 0; /* 鈥滃畾鍨嬪け璐モ€濇棩蹇楀彧鍐欎竴锟?*/
static volatile LONG g_hpSrcLogCount = 0;  /* 鈥滆閲忔潵婧愨€濇棩蹇楀彧鍐欏墠 3 锟?*/

/* ---- 鍐呭瓨鍥為€€璇婃柇锛氬墠 5 鏉¤缁嗘棩锟?+ 绱璁℃暟鍣紙鍙鏁帮紝涓嶉€愭潯鍒峰睆锟?--- */
static volatile LONG g_hpFallbackOkLogged = 0;   /* 宸插啓鈥滀富璺け璐ャ€佸洖閫€鎴愬姛鈥濇潯锟?*/
static volatile LONG g_hpBothFailLogged   = 0;   /* 宸插啓鈥滀袱鏉¤矾閮藉け璐モ€濇潯锟?*/
static volatile LONG g_hpFallbackOkCount  = 0;   /* 鍥為€€鎴愬姛绱 */
static volatile LONG g_hpBothFailCount    = 0;   /* 涓ゆ潯閮藉け璐ョ疮锟?*/

static int PeekU32(uint32_t addr, uint32_t* out);   /* 瀹炵幇鍦ㄦ湰鏂囦欢鍚庨潰锛圝ASS 鍝堝笇閭ｆ锟?*/

typedef uint32_t (__fastcall* fn_hp_handle_to_unit)(uint32_t handle, void* unused);
typedef uint32_t (__fastcall* fn_hp_obj_to_handle)(uint32_t mgr, void* unused, uint32_t obj, uint32_t unused2);
typedef uint32_t (__fastcall* fn_hp_mgr_from_ctx)(uint32_t ctx, void* unused);
typedef uint32_t (__cdecl*    fn_hp_get_unit_state)(uint32_t handle, uint32_t state);

static uint32_t g_natHandleToUnit = 0;
static uint32_t g_natObjToHandle  = 0;
static uint32_t g_natMgrFromCtx   = 0;
static uint32_t g_natGetUnitState = 0;

/* 锟?RVA 瑙ｆ瀽涓€涓紩鎿庡嚱鏁板苟鍋氬簭瑷€鏍￠獙锛堝彲锟?+ 闈炵┖瀹炵幇 + 鍙拷?3 瀛楄妭搴忚█锛夛紝澶辫触杩斿洖 0锛岀敱涓婂眰鎸夎涓嶅埌澶勭悊 */
static uint32_t HpResolve(uint32_t rva, const uint8_t* pro3)
{
    if (!g_modBase) return 0;
    const uint32_t addr = g_modBase + rva;
    uint32_t head = 0;
    if (!PeekU32(addr, &head)) return 0;
    const uint8_t* p = (const uint8_t*)&head;
    if (p[0] == 0x33 && p[1] == 0xC0 && p[2] == 0xC3) return 0;  /* xor eax,eax; ret 绌哄疄锟?*/
    if (pro3 && (p[0] != pro3[0] || p[1] != pro3[1] || p[2] != pro3[2])) return 0;
    return addr;
}

static const uint8_t kPro3HandleToUnit[3] = { 0x55, 0x8B, 0xEC };  /* push ebp; mov ebp,esp */
static const uint8_t kPro3ObjToHandle[3]  = { 0x55, 0x8B, 0xEC };
static const uint8_t kPro3MgrFromCtx[3]   = { 0x83, 0x79, 0x1C };  /* cmp dword [ecx+0x1C],0 */
static const uint8_t kPro3GetUnitState[3] = { 0x55, 0x8B, 0xEC };

/* 鍙ユ焺绠＄悊鍣ㄤ袱绉嶅彛寰勶細鍙ｅ緞0 = 绾唴锟?*(ctx+0x1C)锛涘彛锟? = 寮曟搸璁块棶锟?0x1C3200(ctx) */
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

/* JASS Hunit -> CUnit*锛屽洖绋嬫牎楠岀敤锛宊_fastcall ecx=handle */
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

/* 瀵硅薄 -> JASS 鍙ユ焺锛堣皟鐢ㄦ硶锛宊_fastcall ecx=mgr锛屾爤锟?obj锛屼笌鎻掍欢鍚屾锟?*/
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

/* 瀵硅薄 -> JASS 鍙ユ焺锛堝唴瀛樻壂娉曪紝涓庢彃锟?Wc3Obj2HMem 鍚屾锛夛細
   T=*(mgr+0x19C)锛宑nt=*(mgr+0x198)锛宖or (i=0,k=0; i<min(cnt,0x9000); i+=3,++k)
   锟?*(u32*)(T+4+i*4)==obj 锟?handle=0x100000+k锟?*/
static uint32_t HpObj2HMem(uint32_t mgr, uint32_t obj)
{
    if (!mgr || !obj) return 0;
    uint32_t T = 0, cnt3 = 0;
    if (!PeekU32(mgr + DDH_OFF_MGR_TABLE, &T)) return 0;
    if (!PeekU32(mgr + DDH_OFF_MGR_COUNT, &cnt3)) return 0;
    if (!T || !cnt3 || cnt3 > 0x30000u) return 0;
    const uint32_t limit = (cnt3 < 0x9000u) ? cnt3 : 0x9000u;  /* 浼ゅ鍥炶皟閲屽埆鍋氶暱鎵弿 */
    uint32_t h = 0;
    __try {
        for (uint32_t i = 0, k = 0; i < limit; i += 3, ++k)
            if (*(const uint32_t*)(uintptr_t)(T + 4u + i * 4u) == obj) { h = DDH_HANDLE_BASE + k; break; }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return h;
}

/* 瀵硅薄 -> JASS 鍙ユ焺锛堝畾鍨嬪叆鍙ｏ級锛氳皟鐢ㄦ硶/鍐呭瓨鎵硶 脳 涓ょ绠＄悊鍣ㄥ彛寰勶紝鍥涚缁勫悎閮界敤
   鍙ユ焺鍥炵▼鏍￠獙锟?x1D1550(handle)==obj锛夋寫绗竴涓€氳繃鑰呭苟瀹氬瀷缂撳瓨锛屼箣鍚庣洿鎺ヨ蛋缂撳瓨璺嚎锟?
   鍥涚缁勫悎閮藉け璐ワ細鏃ュ織鍐欎竴娆★紝涔嬪悗浠嶅彲閲嶈瘯浣嗘渶锟?16 娆★紝闄愭鍚庤繑锟?0锛岀敱 ReadUnitHp 杞唴瀛樺洖閫€锟?*/
static uint32_t HpObjToHandle(uint32_t obj)
{
    if (!obj) return 0;
    if (g_hpMgrWhich == 2) return 0;               /* 宸插垽瀹氱敤涓嶄簡锛岀洿鎺ヨ繑锟?0 */
    if (!g_modBase) return 0;

    uint32_t ctx = 0;
    if (!PeekU32(g_modBase + DDH_RVA_CTX_GLOBAL, &ctx) || !ctx) return 0;

    /* 宸插畾鍨嬶細鐩存帴璧版棦瀹氳矾绾匡紙姣忔浼ゅ鍙姳涓€娆¤皟鐢紝涓嶅啀鍋氬洓绉嶅皾锟?鍥炵▼鏍￠獙锟?*/
    if (g_hpMgrWhich >= 0)
    {
        const uint32_t mgr = HpMgrFromCtx(ctx, g_hpMgrWhich);
        return g_hpUseMemory ? HpObj2HMem(mgr, obj) : HpObj2HCall(mgr, obj);
    }

    /* 棣栨瀹氬瀷锛氳皟鐢ㄦ硶/鍐呭瓨鎵硶 脳 涓ょ绠＄悊鍣ㄥ彛寰勶紝鍏ㄩ儴鐢ㄥ彞鏌勫洖绋嬫牎楠岄獙璇佸悗瀹氬瀷 */
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
                LogLine("native obj->handle 瀹氬瀷锛氳矾寰?%s 绠＄悊鍣ㄥ彛寰?%s 棣栨 obj=%08X -> handle=%08X锛堝洖绋嬫牎楠屼竴鑷达級",
                        mem ? "绾唴瀛樻壂鎻? : "璋冪敤 0x2651D0",
                        which ? "寮曟搸璁块棶锟?x1C3200" : "绾唴瀛?(ctx+0x1C)", obj, h);
                return h;
            }
        }
    }

    /* 鍥涚缁勫悎閮芥病閫氳繃鍥炵▼鏍￠獙锛氭棩蹇楀啓涓€娆★紝涔嬪悗浠嶅彲閲嶈瘯浣嗛檺娆★紝闄愭鍚庢案涔呰繑锟?0 */
    if (InterlockedExchange(&g_hpTypeFailLogged, 1) == 0)
        LogLine("native obj->handle 瀹氬瀷澶辫触锛氬洓绉嶇粍鍚堝洖绋嬫牎楠岄兘娌¤繃锛屽悗缁蛋鍐呭瓨鍥為€€锛堜袱鏉￠兘澶辫触鎵嶆樉绀??锛?);
    const LONG tries = InterlockedIncrement(&g_hpObj2HTries);
    if (tries >= 16)
        g_hpMgrWhich = 2;
    return 0;
}

/* GetUnitState锛歊VA 0x1E6600锛宊_cdecl(handle, state) -> float 浣嶆ā寮忥紝state 0 = LIFE */
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
    if (!(hp > -1.0e6f && hp < 1.0e7f)) return false;   /* NaN/Inf/鍨冨溇 -> 鏃犳晥 */
    *hpOut = hp;
    return true;
}

/* 涓昏矾澶辫触鍘熷洜锛堝彧鐢ㄤ簬璇婃柇鏃ュ織锛屼笉鏀瑰彉涓昏矾琛屼负锛夛細
   鍙ユ焺 0 涔熷垎涓ょ 鈥旓拷?鍥涗釜 native 鏈変竴涓病瀹氫綅锛岃繕鏄畾浣嶄簡浣嗘崲绠楀け璐ワ拷?*/
static const char* HpMainFailReason(uint32_t handle)
{
    if (!g_modBase || !g_natGetUnitState || !g_natObjToHandle ||
        !g_natHandleToUnit || !g_natMgrFromCtx)
        return "native鏈畾浣?;
    if (!handle) return "handle=0";
    return "杩斿洖鏃犳晥";
}

/* 鍐呭瓨鍥為€€锛堜富璺け璐ユ墠璧帮級锟?
      idx   = *(u32*)(CUnit + 0xA0)
      table = *(u32*)(*(u32*)(game.dll + 0xBE40A8) + 0x0C)
      obj   = *(u32*)(table + idx*8 + 4)
      hp    = *(float*)(obj + 0x78)
   锟?C# 锟?/ War3Trainer 鍚屾簮锛涘彧鍋氬厹搴曪紝涓嶅弬涓庝富璺畾鍨嬶拷?*/
static bool ReadUnitHpMem(uint32_t unit, float* hpOut)
{
    if (unit < 0x10000u || unit > 0x7FFFFFFFu || !hpOut) return false;
    if (!g_modBase) return false;

    uint32_t idx = 0;
    if (!PeekU32(unit + DDH_OFF_UNIT_HP_INDEX, &idx)) return false;
    if (idx == 0 || idx > DDH_HP_INDEX_LIMIT) return false;

    uint32_t thisGame = 0;
    if (!PeekU32(g_modBase + DDH_RVA_THISGAME_GLOBAL, &thisGame)) return false;
    if (thisGame < 0x10000u || thisGame > 0x7FFFFFFFu) return false;

    uint32_t table = 0;
    if (!PeekU32(thisGame + DDH_OFF_THISGAME_TABLE, &table)) return false;
    if (table < 0x10000u || table > 0x7FFFFFFFu) return false;
    if ((uint64_t)table + (uint64_t)idx * 8u + DDH_OFF_TABLE_OBJECT > 0x7FFFFFFFull)
        return false;   /* 锟?table + idx*8 + 4 鍥炵粫鍒颁綆鍦板潃 */

    uint32_t obj = 0;
    if (!PeekU32(table + idx * 8u + DDH_OFF_TABLE_OBJECT, &obj)) return false;
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return false;

    __try
    {
        const float hp = *(const float*)(uintptr_t)(obj + DDH_OFF_STATE_CUR_HP);
        if (!(hp > -1.0e6f && hp < 1.0e7f)) return false;   /* NaN/Inf/鍨冨溇 -> 鏃犳晥 */
        *hpOut = hp;
        return true;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
}

/* 璇昏鍏ュ彛锛氫富璺粛鐒舵槸瀵硅薄 -> 鍙ユ焺锛圚pObjToHandle锟?> GetUnitState锛堜笌鎻掍欢涓€鑷达級锟?
   涓昏矾澶辫触锛堝彞锟?0 / native 娌″畾锟?/ 杩斿洖鍊奸潪鏈夐檺锛夋墠鍥為€€ ReadUnitHpMem锟?
   涓ゆ潯閮藉け璐ヨ繑锟?false锛堢晫闈㈡樉锟??锛夛拷?*/
static bool ReadUnitHp(uint32_t unit, float* hpOut)
{
    if (unit < 0x10000 || unit > 0x7FFFFFFF) return false;
    if (!hpOut) return false;

    uint32_t handle = 0;
    float hp = 0.0f;

    /* 涓昏矾锛欸etUnitState锛堟彃浠跺悓娆撅紝鍙ｅ緞涓嶅彉锟?*/
    handle = HpObjToHandle(unit);
    if (handle && HpGetUnitState(handle, &hp))
    {
        if (InterlockedIncrement(&g_hpSrcLogCount) <= 3)
            LogLine("琛€閲忔潵婧愶細GetUnitState锛堝紩鎿庯紝鍙ユ焺=%08X锛?, handle);
        *hpOut = hp;
        return true;
    }

    /* 鍥為€€锛氬悓涓€鏉＄敓鍛藉瓧娈电殑鍐呭瓨锟?*/
    const char* reason = HpMainFailReason(handle);
    if (ReadUnitHpMem(unit, &hp))
    {
        InterlockedIncrement(&g_hpFallbackOkCount);
        if (InterlockedIncrement(&g_hpFallbackOkLogged) <= 5)
            LogLine("琛€閲忓洖閫€鍐呭瓨璇伙細unit=0x%08X hp=%.2f锛圙etUnitState 澶辫触锛?s锛?,
                    unit, (double)hp, reason);
        *hpOut = hp;
        return true;
    }

    /* 涓ゆ潯璺兘澶辫触锛氳缁嗘棩蹇楀彧鍐欏墠 5 鏉★紝绱璁℃暟涓嶅埛锟?*/
    InterlockedIncrement(&g_hpBothFailCount);
    if (InterlockedIncrement(&g_hpBothFailLogged) <= 5)
        LogLine("琛€閲忚鍙栧け璐ワ細unit=0x%08X锛坔andle=0x%08X 鍘熷洜=%s锛屽唴瀛橀摼涔熷け璐ワ級",
                unit, handle, reason);
    return false;
}

/* ---------------------------------------------------------------------------
   寮曟搸浼ゅ = 鍦板浘绗竴娆¤皟锟?GetEventDamage() 鐨勮繑鍥炲€硷紙鍦板浘澧炰激/鍑忎激涔嬪墠锛夛拷?
   鍋氭硶锟?UDamageWatcherHook.cpp 瀹屽叏涓€鑷达細閬嶅巻 JASS native 鍑芥暟鍝堝笇琛紝锟?
   "GetEventDamage" 鑺傜偣锟?func_address_ 鎹㈡垚鎴戜滑鐨勫嚱鏁帮紝鍏堣皟鍘熷疄鐜般€佸啀鎶勮繑鍥炲€硷拷?
     get_instance(5)        = game.dll RVA 0x4EFB0锛坃_fastcall锛宔cx=index锟?
     native 鍝堝笇锟?         = instance + 0x18锛宐uckets(+0x1C) / mask(+0x24)锛屾瘡锟?12 瀛楄妭
     鑺傜偣                   = +0x0C prev_ / +0x04 hash / +0x18 key(鍚嶅瓧) / +0x1C func
   鍙湁绗竴娆¤皟鐢ㄨ璁板綍锛堜箣鍚庡湴鍥惧彲锟?SetEventDamage 鏀硅繃鍊硷級锟?
   鍏ㄧ▼ __try 淇濇姢锛汮ASS 娌″氨锟?鎵句笉鍒拌妭鐐瑰氨浠€涔堥兘涓嶅仛锛堢晫闈笂鏄剧ず ?锛夛拷?
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

/* 鍦板浘姣忔锟?GetEventDamage锛氬厛鎷垮紩鎿庣湡鍊硷紝鍐嶆妱涓€浠斤紙鍙妱绗竴娆★級 */
static uint32_t __cdecl OurFakeGetEventDamage(void)
{
    uint32_t r = 0;
    if (g_realGetEventDamage)
    {
        __try { r = ((uint32_t (__cdecl*)(void))(uintptr_t)g_realGetEventDamage)(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    }
    const LONG d = g_depth;                       /* 1 锟?*/
    if (d >= 1 && d <= DDH_MAXDEPTH)
    {
        float f;
        memcpy(&f, &r, 4);
        if (f > -1.0e12f && f < 1.0e12f)
        {
            if (!g_engineFirstSet[d - 1]) { g_engineCap[d - 1] = r; g_engineFirstSet[d - 1] = 1; }  /* 棣栨 = 澧炰激锟?*/
            g_engineLast[d - 1] = r;                                                               /* 鏈 = 鍦板浘鏀瑰畬涔嬪悗 */
            InterlockedIncrement((volatile LONG*)&g_engineCalls[d - 1]);
        }
    }
    return r;
}

/* 鎳掑畨瑁咃細姣忔浼ゅ浜嬩欢璇曚竴娆★紝鏈€锟?64 娆★紙杩涘浘锟?JASS 瀹炰緥鍙兘杩樻病濂斤級 */
static void TryHookGetEventDamage(void)
{
    if (g_gedHooked) return;
    if (InterlockedIncrement(&g_gedTries) > 16) return;      /* 杩涘浘锟?VM 鍙兘娌″ソ锛涜瘯 16 娆″氨鏀惧純 */
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
                        LogLine("寮曟搸浼ゅ閲囬泦锛欸etEventDamage 閽╁瓙宸叉寕锛堣妭鐐?%08X锛屽師瀹炵幇 %08X锛?, node, cur);
                    }
                    else LogLine("寮曟搸浼ゅ閲囬泦锛歏irtualProtect 澶辫触 err=%lu", GetLastError());
                    return;
                }
            }
            uint32_t prev = 0;
            if (!PeekU32(node + 0x0Cu, &prev)) return;
            node = prev;
        }
        LogLine("寮曟搸浼ゅ閲囬泦锛氭病鎵惧埌 GetEventDamage 鑺傜偣锛坔ash=%08X mask=%08X buckets=%08X锛?, hash, mask, buckets);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        /* JASS 杩樻病灏辩华锟?get_instance 浼氳俯锟?鈥旓拷?鍙锟?3 娆★紝鍒埛锟?*/
        if (g_gedTries <= 3) LogLine("寮曟搸浼ゅ閲囬泦锛氳閽╁瓙鏃跺紓甯?code=%08X", GetExceptionCode());
    }
}

/* ---------------------------------------------------------------------------
   鍦板浘浼ゅ = SetEventDamage 鏈€鍚庝竴娆¤缃殑鍊硷拷?
   鍋氭硶锟?GetEventDamage 瀹屽叏涓€鑷达細閬嶅巻 JASS native 鍝堝笇琛紝锟?"SetEventDamage"
   鑺傜偣锟?func_address_锟?0x1C锛夋崲鎴愭垜浠殑鍑芥暟锛屽厛鎶勫弬鏁般€佸啀鍘熸牱璋冨師瀹炵幇锟?
   璋冪敤绾﹀畾锛堜緷鎹粨搴撱€婃棤JAPI鍚庣瀹炶璇存槑.md銆嬶拷?.2 涓庛€婁激瀹崇洃瑙嗚锟?md銆嬶拷? 瀹炴祴锛夛細
     榄斿吔 native 锟?real 鍙傛暟 = **鎸囧悜 float 鐨勬寚锟?*锛圝ASS VM 浼犲畠鑷繁 real 妲界殑鍦板潃锛夛紝
     涓嶆槸 float 浣嶆ā寮忔湰锟?鈥旓拷?DisplayTimedTextToPlayer 锟?x/y/dur 鍙嶆眹缂栭噷閮芥槸
     `mov eax,[ebp+0xC] ; movss xmm,[eax]`锛堝厛鍙栨寚閽堛€佸啀瑙ｅ紩鐢級锟?
     GetEventDamage 鏃犲弬鏁般€佽繑鍥炲€兼墠锟?float 浣嶆ā寮忥紙eax 鐩翠紶锛夛紝浜岃€呬笉瑕佹贩锟?
     鎵€锟?SetEventDamage 鐨勭鍚嶆槸 void __cdecl (float*)锛屽疄锟?= 鎸囧悜 4 瀛楄妭 float 鐨勬寚閽堬拷?
     鍏ㄩ儴 __try 淇濇姢锛汮ASS 娌″氨锟?鎵句笉鍒拌妭鐐瑰氨浠€涔堥兘涓嶅仛锛堜紭闆呴€€鍖栵級锟?
---------------------------------------------------------------------------- */
static void __cdecl OurFakeSetEventDamage(float* damage);

static void __cdecl OurFakeSetEventDamage(float* damage)
{
    /* 鍏堣褰曪紙鍙鏈眰銆佸彧璁板悎鐞嗗€硷級锛屽啀鍘熸牱璋冨師鍑芥暟 鈥旓拷?缁濅笉鍚炴帀璋冪敤 */
    const LONG d = g_depth;                       /* 1 锟?*/
    if (d >= 1 && d <= DDH_MAXDEPTH && damage)
    {
        float v = 0.0f;
        int ok = 0;
        __try { v = *damage; ok = 1; }
        __except (EXCEPTION_EXECUTE_HANDLER) { ok = 0; }
        if (ok && v > -1.0e12f && v < 1.0e12f)
        {
            const uint32_t lv = (uint32_t)(d - 1);

            /* 锟?SetEventDamage銆佷粠锟?GetEventDamage 鐨勫浘锛圖ota 灏辨槸杩欑锛夛細
               鍦ㄥ湴锟?*绗竴锟?*鏀逛激瀹充箣鍓嶏紝鍏堟妸鈥滃紩鎿庡€尖€濇妱涓嬫潵 鈥旓拷?姝ゅ埢杩樺湪浜嬩欢閲屻€佸€艰繕娌¤鏀癸紝
               GetEventDamage 鎷垮埌鐨勫氨鏄€滃湴鍥捐嫢璇讳細璇诲埌鐨勯鍊尖€濄€傛妱鍒颁箣鍚庣収甯歌鍦板浘鏀癸拷?
               杩欓噷涓嶅锟?g_engineCalls锛堝彇娆′粛濡傚疄鍙嶆槧鈥滃湴鍥炬病璇昏繃鈥濓級锟?*/
            if (!g_engineFirstSet[lv] && g_realGetEventDamage)
            {
                uint32_t r0 = 0;
                __try { r0 = ((uint32_t (__cdecl*)(void))(uintptr_t)g_realGetEventDamage)(); }
                __except (EXCEPTION_EXECUTE_HANDLER) { r0 = 0; }

                float f0 = 0.0f;
                memcpy(&f0, &r0, 4);
                if (f0 > 0.005f && f0 < 1.0e9f)      /* 0 澶氬崐鏄€滆繕娌＄畻/鎷夸笉鍒扳€濓紝鍒嬁瀹冨啋锟?*/
                {
                    g_engineCap[lv]      = r0;
                    g_engineFirstSet[lv] = 1;
                }
            }

            uint32_t bits = 0;
            memcpy(&bits, &v, 4);
            g_setCap[d - 1] = bits;                                        /* 鏈 = 鍦板浘鏈€鍚庢敼鎴愮殑锟?*/
            g_setSet[d - 1] = 1;                                           /* 0 涔熸槸鍚堟硶鍊硷紝鐢ㄧ嫭绔嬫爣锟?*/
            InterlockedIncrement((volatile LONG*)&g_setCalls[d - 1]);
        }
    }
    if (g_realSetEventDamage)
    {
        __try { ((void (__cdecl*)(float*))(uintptr_t)g_realSetEventDamage)(damage); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
}

/* 鎳掑畨瑁咃細姣忔浼ゅ浜嬩欢璇曚竴娆★紝鏈€锟?16 娆★紙杩涘浘锟?JASS 瀹炰緥鍙兘杩樻病濂斤級 */
static void TryHookSetEventDamage(void)
{
    if (g_sedHooked) return;
    const LONG sedTries = InterlockedIncrement(&g_sedTries);
    if (sedTries > 64)      /* 杩涘浘锟?VM 鍙兘娌″ソ锛涚粰锟?64 娆★紝涓斿け璐ュ師鍥犺鐪嬪緱锟?*/
    {
        if (sedTries == 65)
            LogLine("寮曟搸浼ゅ閲囬泦锛歋etEventDamage 鏀惧純瀹夎锛堣瘯浜?64 娆￠兘娌℃垚鍔燂紱澶辫触鍘熷洜瑙佷笂闈?SetEventDamage 瀹夎澶辫触 琛岋級");
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
                LogLine("寮曟搸浼ゅ閲囬泦锛歋etEventDamage 瀹夎澶辫触锛圝ASS 瀹炰緥杩樻病濂?inst=%08X锛岀 %d 娆★級", inst, (int)sedTries);
            return;
        }

        const uint32_t tbl = inst + 0x18u;
        uint32_t buckets = 0, mask = 0;
        if (!PeekU32(tbl + 0x1Cu, &buckets) || !PeekU32(tbl + 0x24u, &mask))
        {
            if (sedTries <= 3)
                LogLine("寮曟搸浼ゅ閲囬泦锛歋etEventDamage 瀹夎澶辫触锛坣ative 琛ㄨ涓嶅埌 tbl=%08X锛岀 %d 娆★級", tbl, (int)sedTries);
            return;
        }
        if (!buckets || mask == 0xFFFFFFFFu)
        {
            if (sedTries <= 3)
                LogLine("寮曟搸浼ゅ閲囬泦锛歋etEventDamage 瀹夎澶辫触锛坆uckets=%08X mask=%08X锛岀 %d 娆★級", buckets, mask, (int)sedTries);
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
                        LogLine("寮曟搸浼ゅ閲囬泦锛歋etEventDamage 閽╁瓙宸叉寕锛堣妭鐐?%08X锛屽師瀹炵幇 %08X锛?, node, cur);
                    }
                    else LogLine("寮曟搸浼ゅ閲囬泦锛歏irtualProtect(SetEventDamage) 澶辫触 err=%lu", GetLastError());
                    return;
                }
            }
            uint32_t prev = 0;
            if (!PeekU32(node + 0x0Cu, &prev)) return;
            node = prev;
        }
        LogLine("寮曟搸浼ゅ閲囬泦锛氭病鎵惧埌 SetEventDamage 鑺傜偣锛坔ash=%08X mask=%08X buckets=%08X锛?, hash, mask, buckets);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        /* JASS 杩樻病灏辩华锟?get_instance 浼氳俯锟?鈥旓拷?鍙锟?3 娆★紝鍒埛锟?*/
        if (g_sedTries <= 3) LogLine("寮曟搸浼ゅ閲囬泦锛歋etEventDamage 瑁呴挬瀛愭椂寮傚父 code=%08X", GetExceptionCode());
    }
}

/* ---- 鐪熸鐨勨€滆褰曚竴娆′激瀹筹拷?--- */
/* ---------------------------------------------------------------------------
   鍗曚綅鍚嶈В鏋愶紙鍦ㄦ父鎴忚繘绋嬮噷鐩存帴闂紩鎿庤锛屼笉渚濊禆浠讳綍鎻掍欢锛夛拷?
   涓ょ骇闄嶇骇閾撅紝鍏ㄩ儴 __try銆佸け璐ラ潤榛橀€€涓嬩竴绾э細
     锟?涓昏矾锟?x326BA0(code, 0) 鐩存帴杩斿洖銆愬悕瀛楁锟?char*銆戯紙鎻掍欢 UDamageWatcherHook.cpp 瀹炴祴缁撹锛夛紝
        鐢ㄦ彃浠跺悓娆炬牎楠岋紙鍙锟? 缁撳熬銆佹棤鎺у埗瀛楃/0x7F銆侀暱锟?1..63锛夛紱
     锟?娆￠€夛細JASS native GetUnitName锛團indNativeFunc 鍔ㄦ€佸畾浣嶏紝锟?RVA 0x1E6340锛夆€旓拷?
        瀹冨唴閮ㄥ氨锟?call 0x326BA0 鍐嶈浆銆愬瓧绗︿覆 id銆戯紝杩斿洖鍊兼槸 id 涓嶆槸 char*锟?
        鏈満鍙嶆煡涓嶉€氾紝鎵€浠ュ彧鐣欒繑鍥炲€煎仛璇婃柇銆佷笉鍐嶅綋 char* 璇伙紱
     锟?閮芥嬁涓嶅埌灏遍€€锟?4 瀛楃绫诲瀷鐮侊紙C# 绔€€鍥炵爜锛夛拷?
   缁撴灉锟?绫诲瀷鐮佲啋鍚嶅瓧 缂撳瓨锛堟瘡涓爜鍙В鏋愪竴娆★級锛涘け璐ヤ篃鍙涓€娆℃棩蹇楋紝鍒埛灞忥拷?
--------------------------------------------------------------------------- */
struct NameCacheEntry { uint32_t code; char name[64]; };
static NameCacheEntry g_nameCache[128];
static int  g_nameCacheCount = 0;
static volatile LONG g_nameFailLogged = 0;    /* 鈥滃悕瀛楄В鏋愬け璐モ€濇棩蹇楁€讳笂闄愶紝闃插埛锟?*/

/* GetUnitName native 鍑芥暟鍦板潃鐨勬噿瑙ｆ瀽缂撳瓨锛堟渶澶氭壘 16 娆★紝杩涘浘锟?JASS VM 鍙兘娌″ソ锟?*/
static uint32_t g_natGetUnitName = 0;
static volatile LONG g_gunTries = 0;

typedef const char* (__fastcall *fn_326BA0)(uint32_t code, uint32_t edxZero);

/* 锟?JASS native 鍝堝笇琛ㄩ噷鎸夊悕瀛楁壘鍑芥暟鍦板潃锛堜笌 TryHookGetEventDamage 鍚屼竴濂楅亶鍘嗭級锟?
   杩斿洖 0 琛ㄧず娌℃壘锟?娌″氨缁€傚叏锟?__try 鍖呯潃锟?*/
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
    if (InterlockedIncrement(&g_gunTries) > 16) return 0;   /* 鍙壘 16 娆″氨鏀惧純锛屽埆姣忕瑪閮借俯 */
    g_natGetUnitName = FindNativeFunc("GetUnitName");
    if (g_natGetUnitName)
        LogLine("鍚嶅瓧瑙ｆ瀽锛欸etUnitName native 宸插畾浣嶏紙0x%08X锛?, g_natGetUnitName);
    return g_natGetUnitName;
}

/* 0x326BA0锟? 瀛楃锟?-> 鍚嶅瓧姝ｆ枃 char*锛堟彃锟?UDamageWatcherHook.cpp L1123-1175 瀹炴祴缁撹锛夛拷?
   搴忚█ 56 8B F2 = push esi; mov esi,edx銆傜湡 game.dll 0x326BA0 = 56 8B F2 BA F8 AC 98 6F ... */
#define DDH_RVA_CODE_TO_NAME   0x00326BA0u
static const uint8_t kPro3CodeToName[3] = { 0x56, 0x8B, 0xF2 };
static uint32_t g_natCodeToName = 0;

static uint32_t ResolveCodeToName(void)
{
    if (g_natCodeToName) return g_natCodeToName;
    g_natCodeToName = HpResolve(DDH_RVA_CODE_TO_NAME, kPro3CodeToName);
    return g_natCodeToName;
}

/* GetUnitAbilityLevel native锛氭寜鍚嶅瓧锟?JASS native 琛ㄩ噷鎵撅紙锟?GetUnitName 鍚屼竴锟?FindNativeFunc锛夛拷?
   鏈€澶氭壘 16 娆★紙杩涘浘锟?JASS VM 鍙兘娌″ソ锛夛紱鎵惧埌璁颁竴鏉★紝16 娆″悗杩樻病鎵惧埌涔熷彧璁颁竴鏉★拷?*/
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
            LogLine("铦楄櫕鍒ゅ畾锛欸etUnitAbilityLevel native 鏈壘鍒帮紙宸茶瘯 16 娆★級锛宖lags 鎸?0 澶勭悊");
        return 0;
    }
    g_natGetUnitAbilityLevel = FindNativeFunc("GetUnitAbilityLevel");
    if (g_natGetUnitAbilityLevel)
        LogLine("铦楄櫕鍒ゅ畾锛欸etUnitAbilityLevel native 宸插畾浣嶏紙0x%08X锛?, g_natGetUnitAbilityLevel);
    return g_natGetUnitAbilityLevel;
}

/* 鐩存帴鎸夐€嗗悜缁撴灉鏌ユ妧鑳界瓑绾э細
   game.dll RVA 0x46F440 = 鍗曚綅瀵硅薄涓婄殑鈥滄寜 ID 鎵炬妧鑳解€濓紝杩斿洖鎶€鑳藉璞★紱绛夌骇鍦?+0x50锛? 鍩猴級銆?
   涓嶇粡杩?handle锛岄伩鍏?GetUnitAbilityLevel 鍓嶄袱閬撴牎楠屽け璐ャ€?*/
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


/* 閫氳繃 ydbase 鐨?jass_func(name) 鎷?func_value*锛屽啀鍙?+0x10锛坹dbase 鍙嶇紪璇戠粨璁猴級寰楀埌鐪熷嚱鏁板湴鍧€銆?
   ydbase 娌″姞杞芥椂杩斿洖 0銆?*/
/* 涓€娆℃€ф帰閽堬細Game.dll 鏄惁瀵煎嚭 WAR3API_GetTypeMemoryAddressByTypeId锛堝钩鍙版彃浠跺氨鏄皟瀹冨彇绫诲瀷瀵硅薄锛夈€?*/
/* War3Trainer 鐨勯€夊尯閾撅細module+BE4238 鈫?unitList 鈫?a2 鈫?player 鈫?+0x34 selection 鈫?+0x1F0 閾捐〃 鈫?+8 鍗曚綅鎸囬拡 */
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

/* 涓€娆℃€э細鎸夊悕瀛楁煡 JASS native锛屾墦鍗板湴鍧€涓?RVA锛岀敤浜庨潤鎬侀€嗗悜 GetHeroStr/绉婚€?getter銆?*/
static void DdhProbeHeroNatives(void)
{
    static volatile LONG done = 0;
    if (InterlockedCompareExchange(&done, 1, 0) != 0) return;
    const char* names[] = { "GetHeroStr", "GetHeroAgi", "GetHeroInt", "GetHeroLevel", "GetUnitMoveSpeed" };
    for (int i = 0; i < 5; ++i)
    {
        uint32_t fn = FindNativeFunc(names[i]);
        LogLine("native 鎺㈤拡锛?s = 0x%08X rva=0x%X", names[i], fn, fn ? (unsigned)(fn - g_modBase) : 0u);
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
    LogLine("WAR3API 鎺㈤拡锛欸ame.dll=0x%08X 瀵煎嚭 WAR3API_GetTypeMemoryAddressByTypeId=0x%08X",
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


/* 'Aloc'锛堣潡铏妧鑳斤級锟?dword锛氬瓧锟?A,l,o,c = 0x41 0x6C 0x6F 0x63锟?
   鍐呭瓨鎸夊皬绔瓨锟?dword 0x636F6C41銆侴etUnitAbilityLevel(handle, 0x636F6C41) > 0 = 椹敳锟?
   鍒ゅ畾鍙ｅ緞锟?YDWE 涓€鑷达紙YDWE-master/Development/Component/ui/ydwe/jass/YDWETriggerEvent.j:47锟?
   GetUnitAbilityLevel(GetFilterUnit(), 'Aloc') <= 0 鏄櫘閫氬崟浣嶏紝> 0 鎵嶆槸椹敳/铦楄櫕鍗曚綅锛夛拷?
   鍙寜鎶€鑳藉垽瀹氾紝涓嶆寜鍚嶅瓧/绫诲瀷鐮佸啓姝伙拷?*/
#define DDH_ABILITY_ALOC   0x636F6C41u
#define DDH_AF_LOCUST_CHECKED 0x00200000u   /* 鐪熺殑鎵ц杩?Aloc 鍒ゅ畾锛堢粨鏋滃彲涓哄惁锛夛紝C# 鎹鍐冲畾鏄惁鑳界紦瀛樿礋缁撹 */

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

/* 鍐呭瓨鎵?Aloc锛氬崟浣嶇粨鏋勯噷鎶€鑳介」鍚?4 瀛楄妭鎶€鑳界爜锛屾壘鍒?0x636F6C41 鍗宠潡铏€?
   涓嶄緷璧?JASS native锛堝疄娴?native 璋冧笉鍑虹粨鏋滐級锛屼篃涓嶄緷璧栫被鍨嬫暟鎹瓧娈靛悕銆?*/
/* 鍒ゆ柇涓€涓?dword 鏄笉鏄?Aloc 鐨勪袱绉嶅瓧鑺傚簭 */
static bool DdhIsAlocDword(uint32_t v) { return v == 0x636F6C41u || v == 0x416C6F63u; }

/* 鍦?[base, base+len) 閲屾壘 Aloc锛? 瀛楄妭姝ラ暱锛夈€傝繑鍥炲亸绉伙紝鎵句笉鍒拌繑鍥?-1銆?*/
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

/* 鍏ㄦ柟浣嶆壘 Aloc锛氭湰浣?0x8000 鈫?涓€绾ф寚閽堝瓙鍧?0x2000 鈫?浜岀骇鎸囬拡瀛愬潡 0x1000锛?
   澶栧姞 ASCII "Aloc"銆傝繑鍥?true 骞剁粰鍑轰粠鍝噷鍛戒腑锛坧ath 鏂囨湰锛夛紝涓嶄緷璧?native/绫诲瀷鏁版嵁銆?*/
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
        if (path && cap) _snprintf_s(path, cap, _TRUNCATE, "鏈綋+0x%X", (unsigned)off);
        if (readsOut) *readsOut = reads;
        return true;
    }

    /* 涓€绾ф寚閽?*/
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

    /* 浜岀骇鎸囬拡锛堟妧鑳介摼琛細鑺傜偣->next锛?*/
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






/* 铦楄櫕鍒ゅ畾璇婃柇鏃ュ織闄愭祦锛氬墠 5 娆℃棤鏉′欢鍐欙紙锟?level<=0 / handle==0锛夛拷?*/
static volatile LONG g_locustLogCount = 0;

/* ---- v21锛氳潡铏被鍨嬬爜缂撳瓨 ----
   鍙ユ焺鎷夸笉鍒帮紙灏镐綋 / 鍒氬垱锟?/ 鍙ユ焺琛ㄦ殏鏃跺け鏁堬級鏃舵棤娉曡皟 GetUnitAbilityLevel锟?
   浣嗗悓涓€绫诲瀷鐮佸彧瑕佹湁浠讳綍涓€鍙瀹炴祴锟?Aloc锛屽氨鏁寸被鎸夎潡铏锟?鈥旓拷?C# 鐨勩€愭垬鍦哄崟浣嶃€戠敤瀹冭繃婊わ拷?
   鍙紦瀛樼被鍨嬬爜锛堜笉鎸夊悕锟?鍦板潃鍐欐锛夛紝鍙ｅ緞浠嶆槸 Aloc锟?*/
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

/* DdhCodeText 瀹氫箟鍦ㄥ悗闈紙绫诲瀷锟?-> 鍙鏂囨湰锛夛紱RecordDamage 閲屽厛鐢紝琛ュ墠缃０鏄庯拷?*/
static void DdhCodeText(uint32_t code, char* out, size_t cap);

/* ---- v8锛氬崟浣嶆墍灞炵帺瀹跺彿銆傚弬锟?YDWE锛氫笉锟?CUnit+0x1C锛堢湡鏈轰笉鎴愮珛锛夛紝
   锟?JASS 鍘熺敓 GetOwningPlayer(unitHandle) -> playerHandle锟?
   锟?GetPlayerId(playerHandle) -> 鐜╁鍙凤紙0 鍩猴級锟?
   涓や釜閮芥槸 __cdecl锟? 涓弬鏁般€佽繑锟?uint32锛涙噿瑙ｆ瀽 + 鍙ユ焺缂撳瓨锛坔andle->pid锛屾渶锟?256 鏉★級锟?---- */
static uint32_t g_natGetOwningPlayer = 0;
static uint32_t g_natGetPlayerId = 0;
static volatile LONG g_gopTries = 0;
static volatile LONG g_gpidTries = 0;

struct OwnerCacheEntry { uint32_t handle; int32_t pid; };
static OwnerCacheEntry g_ownerCache[256];
static int g_ownerCacheCount = 0;
static volatile LONG g_ownerLogCount = 0;

static uint32_t GetOwningPlayerNative(void)
{
    if (g_natGetOwningPlayer) return g_natGetOwningPlayer;
    if (InterlockedIncrement(&g_gopTries) > 16) return 0;
    g_natGetOwningPlayer = FindNativeFunc("GetOwningPlayer");
    if (g_natGetOwningPlayer)
        LogLine("v8锛欸etOwningPlayer native 宸插畾浣?0x%08X", g_natGetOwningPlayer);
    return g_natGetOwningPlayer;
}

static uint32_t GetPlayerIdNative(void)
{
    if (g_natGetPlayerId) return g_natGetPlayerId;
    if (InterlockedIncrement(&g_gpidTries) > 16) return 0;
    g_natGetPlayerId = FindNativeFunc("GetPlayerId");
    if (g_natGetPlayerId)
        LogLine("v8锛欸etPlayerId native 宸插畾浣?0x%08X", g_natGetPlayerId);
    return g_natGetPlayerId;
}

/* obj(CUnit*) -> 鎵€灞炵帺瀹跺彿锟? 鍩猴級锛屽け璐ヨ繑锟?-1銆備笉鐚溿€佷笉宕╋拷?*/
static int32_t ResolveOwnerPid(uint32_t obj)
{
    if (obj < 0x10000 || obj > 0x7FFFFFFF) return -1;
    const uint32_t handle = HpObjToHandle(obj);
    if (!handle) return -1;

    for (int i = 0; i < g_ownerCacheCount; i++)
        if (g_ownerCache[i].handle == handle) return g_ownerCache[i].pid;

    int32_t pid = -1;
    const uint32_t gop = GetOwningPlayerNative();
    const uint32_t gpid = GetPlayerIdNative();
    if (gop && gpid)
    {
        uint32_t playerHandle = 0;
        __try { playerHandle = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)gop)(handle); }
        __except (EXCEPTION_EXECUTE_HANDLER) { playerHandle = 0; }
        if (playerHandle)
        {
            int32_t id = -1;
            __try { id = (int32_t)((uint32_t (__cdecl*)(uint32_t))(uintptr_t)gpid)(playerHandle); }
            __except (EXCEPTION_EXECUTE_HANDLER) { id = -1; }
            if (id >= 0 && id < 24) pid = id;
        }
    }

    if (g_ownerCacheCount < 256)
    {
        g_ownerCache[g_ownerCacheCount].handle = handle;
        g_ownerCache[g_ownerCacheCount].pid = pid;
        g_ownerCacheCount++;
    }
    else
    {
        g_ownerCache[255].handle = handle;
        g_ownerCache[255].pid = pid;
    }
    return pid;
}

/* ---- v21锛氱帺瀹剁粨鐩熸帺鐮侊紙鏈湴鐜╁瑙嗚锟?---
   锟?i 锟?= 鐜╁ i锟? 鍩猴級鏄惁涓庢湰鍦扮帺瀹剁粨鐩燂紙鍚湰鍦扮帺瀹惰嚜宸憋級锟?
   JASS 鍘熺敓锛欸etLocalPlayer() / Player(index) / IsPlayerAlly(a,b)锛岄兘锟?__cdecl锟?
   鍙湪娓告垙绾跨▼锛堝睘鎬у～锟?/ 浼ゅ閽╁瓙锛夎皟鐢紱鏁村眬鍙畻鎴愬姛涓€娆★紝澶辫触鏈€澶氶噸锟?64 娆★拷?
   鍐欒繘 hdr.reserved[1]锛孋# 鍙湪 hdr.version >= 21 鏃惰锟?*/
static uint32_t      g_allyMask = 0;
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
    if (!fnPlayer || !fnLocal || !fnAlly) return;

    uint32_t local = 0;
    __try { local = ((uint32_t (__cdecl*)(void))(uintptr_t)fnLocal)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { local = 0; }
    if (!local) return;

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

    /* 鏈湴鐜╁鑷繁閭ｄ竴浣嶇疆 1锛堟湁浜涘湴锟?IsPlayerAlly(p,p) 杩斿洖 false锟?*/
    uint32_t localId = 0xFFFFFFFFu;
    const uint32_t gpid = GetPlayerIdNative();
    if (gpid)
    {
        __try { localId = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)gpid)(local); }
        __except (EXCEPTION_EXECUTE_HANDLER) { localId = 0xFFFFFFFFu; }
        if (localId < 24) mask |= (1u << (int)localId);
    }

    g_allyMask = mask;
    g_shm->hdr.reserved[1] = mask;   /* reserved[0] 锟?hpSupported锛沎1] 鐣欑粰 v21 缁撶洘鎺╃爜 */
    InterlockedExchange(&g_allyMaskDone, 1);
    LogLine("v21锛氱粨鐩熸帺鐮?= 0x%06X锛堟湰鍦扮帺瀹?%d锛汸layer/GetLocalPlayer/IsPlayerAlly 宸插畾浣?%d/%d/%d锛?,
            mask, (localId < 24) ? (int)localId : -1, fnPlayer ? 1 : 0, fnLocal ? 1 : 0, fnAlly ? 1 : 0);
}

static volatile LONG g_nameOkLogged = 0;    /* 鈥滃悕瀛楄В鏋愭垚鍔熲€濇棩蹇楁€讳笂锟?*/

/* 瀹夊叏鍦版妸涓€娈靛唴瀛樻寜瀛楄妭璇昏繘 buf锛堟渶锟?n 瀛楄妭锛夛紝杩斿洖瀹為檯璇诲埌鐨勫瓧鑺傛暟锟?
   鍏ㄧ▼ __try锛涜涓嶅姩灏卞仠锛岃繑鍥炲凡璇诲埌鐨勯儴鍒嗭拷?*/
static int SafeHexDump(uint32_t addr, int n, unsigned char* buf)
{
    if (addr < 0x10000 || n <= 0) return 0;
    int got = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)addr;
        for (int i = 0; i < n; i++) { buf[i] = p[i]; got = i + 1; }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { /* got 鍋滃湪宸茶鍒扮殑閮ㄥ垎 */ }
    return got;
}

/* 锟?n 涓瓧鑺傛牸寮忓寲锟?"AA BB CC ..."锛堝ぇ鍐欍€佺┖鏍煎垎闅旓級锛宱ut 宸叉竻绌猴拷?*/
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

/* UTF-8 瀹夊叏鎴柇锛坴9锛夛細锟?src 鏈€锟?maxBytes 涓瓧鑺傚鍒跺埌 dst锛堝锟?cap锛夛紝
   缁濅笉鎶婂瀛楄妭瀛楃鍒囨垚涓ゅ崐锟?
     路 锟?maxBytes 瀛楄妭钀藉湪瀛楃涓棿锛堝悗涓€瀛楄妭鏄画瀛楄妭 10xxxxxx锛夆啋 鍥為€€鍒拌瀛楃
       璧峰澶勶紝鏁翠釜瀛楃閮戒笉鍐欙紱
     路 婧愪覆鏈韩灏变互鍗婁釜瀛楃缁撳熬锛圢UL 鍓嶇己缁瓧鑺傦級锟?鍚屾牱涓㈡帀鏈熬娈嬬己瀛楃锟?
   杩斿洖瀹為檯鍐欏叆瀛楄妭鏁帮紙涓嶅惈缁撳熬 NUL锛夛拷?*/
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
        /* 鎴柇鐐瑰悗闈㈣繕鏈夌画瀛楄妭 锟?鍒囧湪瀛楃涓棿锛岄€€鍒拌瀛楃棣栧瓧鑺傦紙涓嶅啓瀹冿級 */
        while (n > 0 && ((unsigned char)src[n] & 0xC0) == 0x80) n--;
    }
    else
    {
        /* 婧愪覆鑷繁缁撳熬涓嶅畬鏁存椂锛屼篃鎶婃湯灏鹃偅涓畫缂哄瓧绗﹀幓锟?*/
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

/* 鍚嶅瓧鍘熸牱鏍￠獙锛歱 蹇呴』鍙锟? 缁撳熬銆佹棤鎺у埗瀛楃/0x7F銆侀暱锟?1..63锟?
   鎷峰嚭鏃惰蛋 DdhUtf8SafeCopy锛岄暱搴︿笉澶熶篃浠庡畬鏁村瓧绗﹁竟鐣屾埅鏂拷?
   鍏ㄥ湪 __try 閲岋紝璇诲潖/鏍￠獙涓嶈繃杩斿洖 false锟?*/
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
        if (n == 0 || n >= 64) return false;   /* 绌轰覆/娌＄粨锟?-> 鏀惧純 */
        const int copy = n < (int)outSize - 1 ? n : (int)outSize - 1;
        DdhUtf8SafeCopy(out, outSize, (const char*)p, (size_t)copy);
        return true;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { out[0] = 0; return false; }
}

/* ---- v24 璇婃柇锟?x326BA0 鍙彇琛ㄩ噷锟?[0] 椤癸紝鍙栦笉鍒板氨杩斿洖绌轰覆/0锟?
   杩欓噷鐩存帴鎶婃敞鍐岃〃瀵硅薄鍙栧嚭鏉ワ紙0x327020(desc, key=code)锛夛紝锟?count 锟?array[0..7]
   鍒板簳鏄粈涔堬紝鐢ㄦ潵鍒ゆ柇 Dota 鑷畾涔夊崟浣嶇爜鍒板簳鏄€滆〃涓嶅瓨鍦ㄢ€濃€滆〃瀛樺湪浣嗗悕瀛椾负绌衡€濓紝
   杩樻槸鈥滃悕瀛楀湪鍒殑妲戒綅鈥濄€傚彧鍦ㄥ墠鍑犳澶辫触鏃惰褰曪拷?*/
#define DDH_RVA_REGISTRY_GET   0x00327020u
static const uint8_t kPro3RegistryGet[3] = { 0x55, 0x8B, 0xEC };
static uint32_t g_natRegistryGet = 0;

static uint32_t ResolveRegistryGet(void)
{
    if (g_natRegistryGet) return g_natRegistryGet;
    g_natRegistryGet = HpResolve(DDH_RVA_REGISTRY_GET, kPro3RegistryGet);
    if (g_natRegistryGet)
        LogLine("鍚嶅瓧琛ㄦ帰閽堬細0x327020 宸插畾浣嶏紙0x%08X锛?, g_natRegistryGet);
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
        if (!obj) { LogLine("鍚嶅瓧琛ㄦ帰閽堬細code=0x%08X 娉ㄥ唽琛ㄨ繑鍥?0", code); return; }
        const int count = *(const int*)(obj + 0x28);
        const uint32_t* arr = *(const uint32_t* const*)(obj + 0x2C);
        LogLine("鍚嶅瓧琛ㄦ帰閽堬細code=0x%08X obj=%08X count=%d arr=%08X",
                code, obj, count, (unsigned)(uintptr_t)arr);
        for (int i = 0; i < count && i < 8; ++i)
        {
            if (!arr) break;
            const uint32_t p = arr[i];
            char buf[64] = { 0 };
            const bool ok = p && ValidateNameText(p, buf, sizeof(buf)) && buf[0];
            LogLine("鍚嶅瓧琛ㄦ帰閽圼%d] ptr=%08X%s%s", i, p, ok ? " name=" : "", ok ? buf : "");
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("鍚嶅瓧琛ㄦ帰閽堬細code=0x%08X 寮傚父 0x%08X", code, (unsigned)GetExceptionCode());
    }
}

/* v25锛氱洿鎺ユ煡銆愮被鍨嬬爜 锟?鍚嶅瓧琛ㄣ€戝苟鍙栫涓€涓潪绌烘Ы浣嶏拷?
   锟?0x326BA0 璧板悓涓€涓敞鍐岃〃锛坉esc=g_modBase+0x98ACF8锛夛紝浣嗕笉渚濊禆瀹冮偅涓繑锟?0 鐨勫疄鐜帮拷?*/
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
    out[0] = 0;
    if (g_modBase == 0) return;

    for (int i = 0; i < g_nameCacheCount; i++)
        if (g_nameCache[i].code == code) { DdhUtf8SafeCopy(out, outSize, g_nameCache[i].name, outSize - 1); return; }

    char tmp[64] = { 0 };
    uint32_t handle = 0;
    uint32_t ret1 = 0, sval = 0;            /* 涓ょ骇璋冪敤鐨勫師濮嬭繑鍥烇拷?*/
    uint32_t exc1 = 0, exc2 = 0;            /* 寮傚父鐮侊紙0 = 娌℃姏锟?*/
    char hex1[64] = { 0 };                  /* 0x326BA0 杩斿洖鍊艰捣 16 瀛楄妭 */
    char hex2[80] = { 0 };                  /* GetUnitName 杩斿洖鍊肩殑 24 瀛楄妭 */
    char hexOut[100] = { 0 };               /* 浜嬩欢瀛楁鏈€缁堝瓧鑺傦紙锟?32锟?*/

    /* 锟?涓昏矾 v25锛氱洿鎺ユ煡銆愮被鍨嬬爜 锟?鍚嶅瓧琛ㄣ€戯拷?
       瀹炴祴锟?026-11-04 01:32 Dota 鐪熸満锛宑ode=eL00/uL00锛夛細寮曟搸琛ㄩ噷 count=1锟?
       array[0] 鍒嗗埆鎸囧悜銆岀寷绂藉痉椴佷紛銆嶃€屼骸鐏垫硶甯堛€嶏紝锟?0x326BA0 杩欐潯鑰佽矾杩斿洖 0
       锛堝钩鍙版敞鍏ョ殑 War3Plugin 寰堝彲锟?hook 杩囧畠锛夈€傛墍浠ュ厛璧版敞鍐岃〃鐩村彇锛屾垚鍔熷嵆姝拷?*/
    int nameSrc = 0;                        /* 1=绫诲瀷琛ㄧ洿锟? 2=锟?0x326BA0 锟?0=澶辫触 */
    if (code != 0)
    {
        if (DdhNameFromTypeTable(code, tmp, sizeof(tmp)))
        {
            nameSrc = 1;
        }
        else
        {
            const uint32_t fn = ResolveCodeToName();
            if (fn)
            {
                __try
                {
                    const char* p = ((fn_326BA0)(uintptr_t)fn)(code, 0);
                    ret1 = (uint32_t)(uintptr_t)p;
                    if (ValidateNameText(ret1, tmp, sizeof(tmp))) nameSrc = 2;
                }
                __except (EXCEPTION_EXECUTE_HANDLER) { exc1 = GetExceptionCode(); ret1 = 0; tmp[0] = 0; }
            }
        }
        {
            unsigned char b[16];
            int n = SafeHexDump(ret1, 16, b);
            FormatHex(b, n, hex1, sizeof(hex1));
        }
    }

    /* 锟?娆￠€夛細GetUnitName native锟?x1E6340锛孎indNativeFunc 鍔ㄦ€佸畾浣嶏級锟?
       瀹冨唴閮ㄥ氨锟?call 0x326BA0 鍐嶈浆銆愬瓧绗︿覆 id銆戯紝杩斿洖鍊兼槸 id 涓嶆槸 char*锟?
       鏈満鍙嶆煡涓嶏拷?锟?鍙暀杩斿洖鍊煎仛璇婃柇锛屼笉鍐嶆妸瀹冨綋 char* 璇伙拷?*/
    if (tmp[0] == 0 && obj >= 0x10000 && obj <= 0x7FFFFFFF)
    {
        handle = HpObjToHandle(obj);
        if (handle)
        {
            const uint32_t fn = GetUnitNameNative();
            if (fn)
            {
                __try { sval = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)fn)(handle); }
                __except (EXCEPTION_EXECUTE_HANDLER) { exc2 = GetExceptionCode(); sval = 0; }
            }
        }
        {
            unsigned char b[24];
            int n = SafeHexDump(sval, 24, b);
            FormatHex(b, n, hex2, sizeof(hex2));
        }
    }

    DdhUtf8SafeCopy(out, outSize, tmp, outSize - 1);

    {
        int nb = (int)strlen(out);
        if (nb > 32) nb = 32;
        FormatHex((const unsigned char*)out, nb, hexOut, sizeof(hexOut));
    }

    if (tmp[0] != 0)
    {
        /* 鎴愬姛锛氬啓杩涗簨浠跺瓧娈碉紙澶栭潰璇伙級锛屾棩蹇楁渶锟?5 锟?*/
        const LONG n = InterlockedIncrement(&g_nameOkLogged);
        if (n <= 5)
            LogLine("鍚嶅瓧瑙ｆ瀽鎴愬姛锛歝ode=0x%08X 鍚嶅瓧=%s src=%d hex=%s 瀛楁hex=%s", code, tmp, nameSrc, hex1, hexOut);
    }
    else
    {
        /* 澶辫触锛氭妸涓ょ骇璋冪敤鐨勮繑鍥烇拷?+ 寮傚父锟?+ hex 閮芥墦鍑烘潵锛堟渶锟?3 娆★級锟?
           涓€娆＄湡鏈哄氨鑳界湅娓呮槸鈥滆繑锟?0 / 杩斿洖 char* 浣嗗唴瀹逛笉锟?/ 璋冪敤锟?AV锟?*/
        const LONG n = InterlockedIncrement(&g_nameFailLogged);
        if (n <= 3)
        {
            LogLine("鍚嶅瓧瑙ｆ瀽澶辫触锛歰bj=%08X handle=%08X code=0x%08X | 0x326BA0杩斿洖=%08X exc=%08X hex=%s | GetUnitName杩斿洖=%08X exc=%08X hex=%s",
                    obj, handle, code, ret1, exc1, hex1, sval, exc2, hex2);
            DdhNameTableProbe(code);   /* v24锛氱湅鐪嬪紩鎿庨噷杩欎釜鐮佺殑鍚嶅瓧琛ㄥ埌搴曢暱浠€涔堟牱 */
        }
        else if (n == 4)
            LogLine("鍚嶅瓧瑙ｆ瀽澶辫触锛氳繕鏈夋洿澶氱被鍨嬬爜瑙ｆ瀽涓嶅埌锛屽悗闈笉鍐嶉€愭潯璁板綍");
    }

    /* v24锛氬け璐ヤ笉鍐嶅啓杩涚紦瀛樸€傚師鏉ュけ璐ヤ細缂撳瓨鎴愮┖涓诧紝瀵艰嚧鈥滃悗鏉ヨ兘瑙ｆ瀽浜嗕篃姘歌繙鎷夸笉鍒扳€濓拷?*/
    if (!tmp[0]) return;

    if (g_nameCacheCount < 128)
    {
        g_nameCache[g_nameCacheCount].code = code;
        DdhUtf8SafeCopy(g_nameCache[g_nameCacheCount].name, sizeof(g_nameCache[0].name), tmp, sizeof(g_nameCache[0].name) - 1);
        g_nameCacheCount++;
    }
    else
    {
        /* 缂撳瓨婊′簡锛氳鐩栨渶鍚庝竴涓Ы浣嶏紙鍙紦瀛樻垚鍔熺粨鏋滐級 */
        g_nameCache[127].code = code;
        DdhUtf8SafeCopy(g_nameCache[127].name, sizeof(g_nameCache[0].name), tmp, sizeof(g_nameCache[0].name) - 1);
    }
}

/* ===========================================================================
   v10锛氬崟浣嶅睘鎬х殑閲囬泦瀹炵幇
   ---------------------------------------------------------------------------
   涓轰粈涔堣鈥滆锟?鍝嶅簲鈥濓細C# 锟?64 浣嶈繘绋嬶紝璇讳笉锟?32 浣嶆父鎴忕殑鍐呭瓨锛屾洿娌℃硶鏇挎父鎴忚皟
   JASS锛涳拷?JASS native **鍙兘鍦ㄦ父鎴忕嚎绋嬭皟**銆傛墍锟?C# 锟?~1 绉掓妸鏈€锟?96 锟?CUnit*
   鍐欒繘璇锋眰妲藉苟锟?requestSeq +1锛宒dh 鍦ㄦ父鎴忕嚎绋嬩笂鐪嬪埌搴忓彿鍙樹簡鎵嶅紑濮嬫煡灞炴€э紝
   鍐欏畬鍝嶅簲妲芥渶鍚庢墠锟?doneSeq = requestSeq锛圕# 锟?doneSeq == 鑷繁鍐欑殑搴忓彿鍒ゅ畾瀹屾垚锛夛拷?

   瑙﹀彂鐐癸紙閮藉彧鍦ㄦ父鎴忕嚎绋嬶級锟?
     锟?绐楀彛杩囩▼鏀跺埌 WM_APP+0xDE锛堢儹閿嚎绋嬫瘡 100ms 鍙戠幇鏂拌姹傚氨 PostMessage 涓€娆★級锟?
     锟?DdhDamageFunc 鏈€澶栧眰杩斿洖鏃讹紙DdhProcessPending 锟?DdhProcessAttrRequest锛夛紝
        娌℃湁绐楀彛 / 娌＄儹閿嚎绋嬫椂涔熻兘宸ヤ綔锛堝亣榄斿吔鍐掔儫灏遍潬杩欐潯锛夛拷?

   native 瑙ｆ瀽锛欶indNativeFunc 鎸夊悕瀛楀湪 JASS native 鍝堝笇琛ㄩ噷鎵撅紝**姣忎釜鍊欓€夊彧锟?鍙
   涓€娆℃棩锟?*锛涜皟鐢ㄧ害瀹氭寜寮曟搸鑷繁鐨勯偅涓€濂楋紙32 锟?JASS 鍊硷細real 锟?float 浣嶆ā寮忔斁 EAX锛夛紝
   鍚屾椂锟?ST(0) 鍏滀綇鈥滄寜 C 娴偣绾﹀畾杩斿洖鈥濈殑 JAPI 瀹炵幇锟?
   姣忓瓧娈典竴锟?flags 浣嶏細瑙ｆ瀽涓嶅埌锟?invalid锛圕# 鏄剧ず ?锛夛紝缁濅笉锟?0 鍐掑厖锟?
   v15锛氭敾鍑昏寖锟?/ 鏀诲嚮锟?/ 鏀诲嚮闂撮殧 / 鎶ょ敳 / 涓诲姩鏀诲嚮鑼冨洿 鏀规垚**鍐呭瓨鐩磋浼樺厛**
   锛圷DWE unit_property / CUnit+0xE0锛岃涓嬮潰 DdhAttrFillMemory 鐨勮鏄庯級锛宯ative 鍙仛鍏滃簳锟?
    绉婚€熺敤 native锛涜锟?鍩虹閫熷害/鍩虹鎶ょ敳/绉拌皳锟?DzAPI_UnitType_GetUnitTypeData*锛堢被鍨嬫暟鎹級锟?
    v16锛堢湡鏈烘棩蹇楅┍鍔級锟?
      路 姣忎釜瀛楁鏀规垚**绮剧‘鍚嶅崟浼樺厛锛屽叧閿瓧妯＄硦鍖归厤鍙綔鏈€鍚庡厹锟?* 鈥旓拷?鏃х増鎸夆€滃悕瀛楁渶鐭€濇帓搴忥紝
        缁撴灉绉婚€熸寫锟?GetGameSpeed锛堣繑锟?0锛夈€佸崟浣嶉檮鍔犲€兼寫锟?GetItemUserData銆佽閲庢寫锟?
        UnitShareVision锛屽叏鏄敊锟?native锟?
      路 鎺掗櫎鍚嶅崟锛欸etGameSpeed / GetRandomInt / GetUnitTurnSpeed / GetUnitDefaultTurnSpeed /
        GetItemUserData / UnitShareVision(锟?BJ) 浠讳綍瀛楁閮戒笉閲囩敤锟?
      路 DzAPI_UnitType_GetUnitTypeData* 鐨勫瓧绗︿覆瀹炲弬鏀规垚 JASS string 鍙ユ焺锛圖dhMakeJassString
        閫犵殑 string_fake 瀵硅薄鎸囬拡锛夛紝瀹炲弬椤哄簭 / unitTypeId 褰㈡€佺敤 DZPROBE 4 绉嶇粍鍚堟帰娴嬩竴娆″悗鍥哄畾锟?
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
    DDH_AN_TYPEID,        /* GetUnitTypeId锛氬彞锟?-> 4 瀛楃绫诲瀷鐮侊紙鏍囧噯 native锟?*/
    DDH_AN_IS_HERO_ID,    /* IsHeroUnitId锛氱被鍨嬬爜 -> 鏄惁鑻遍泟锛堟爣锟?native锟?*/
    DDH_AN_IS_ILLUSION,   /* IsUnitIllusion锛氬彞锟?-> 鏄惁闀滃儚/骞昏薄 */
    DDH_AN_COUNT
};

static const char* const kDdhAttrNativeName[DDH_AN_COUNT] =
{
    "GetHeroProperName",      /* 绉拌皳锛堣嫳闆勪笓鍚嶏級 */
    "GetUnitAttackRange",     /* 鏀诲嚮鑼冨洿 */
    "GetUnitDamageMin",       /* 鏀诲嚮鍔涗笅锟?*/
    "GetUnitDamageMax",       /* 鏀诲嚮鍔涗笂锟?*/
    "GetUnitAttack",          /* 鏀诲嚮鍔涳紙鍗曞€煎€欓€夛級 */
    "GetUnitAttackCooldown",  /* 鏀诲嚮闂撮殧锛堢锟?*/
    "GetUnitAttackSpeed",     /* 姣忕鏀诲嚮娆℃暟锟?1 鏃舵寜 1/锟?鎹㈡垚闂撮殧锟?*/
    "GetUnitArmor",           /* 鎶ょ敳 */
    "GetUnitDefense",         /* 鎶ょ敳锛堝€欙拷?2锟?*/
    "GetUnitMoveSpeed",       /* 绉婚€燂細绮剧‘浼樺厛锟?1 鍚嶏紙鐪熸満鏃ュ織锟?GetGameSpeed 鏄敊鐨勶級 */
    "GetUnitDefaultMoveSpeed",/* 绉婚€燂細绮剧‘浼樺厛锟?2 锟?*/
    "GetUnitSightRange",      /* 瑙嗛噹锛堢浜屽弬鏁帮細0 = 鐧藉ぉ锟? = 澶滄櫄锟?*/
    "GetUnitAcquireRange",    /* 涓诲姩鏀诲嚮鑼冨洿 */
    "GetUnitStrength",        /* 鍔涢噺 */
    "GetHeroStr",             /* 鍔涢噺锛堝師锟?native锛岀浜屽弬锟?0 = 涓嶅惈鍔犳垚锟?*/
    "GetUnitAgility",         /* 鏁忔嵎 */
    "GetHeroAgi",
    "GetUnitIntelligence",    /* 鏅哄姏 */
    "GetHeroInt",
    "GetUnitUserData",        /* 鍗曚綅闄勫姞鍊硷紙鑷畾涔夊€硷級 */
    "GetUnitTypeId",          /* 鍗曚綅绫诲瀷鐮侊紙鑻遍泟鍒ゅ畾鐢級 */
    "IsHeroUnitId",           /* 绫诲瀷鐮佹槸鍚﹁嫳闆勶紙鑻遍泟鍒ゅ畾鐢級 */
    "IsUnitIllusion"          /* 鏄惁闀滃儚/骞昏薄鍗曚綅 */
};

/* 姣忎釜瀛楁鐨勨€滅簿纭紭鍏堝垪琛ㄧ 2 鍚嶁€濓紙绌轰覆 = 娌℃湁锟?2 鍚嶏級锟?
   绉婚€燂細GetUnitMoveSpeed 锟?GetUnitDefaultMoveSpeed锛堢湡鏈烘棩蹇楅噷鑷姩鍖归厤鎸戝埌 GetGameSpeed
   杩斿洖 0锛岀晫闈㈠氨鏄剧ず 0锛涙墍浠ョ簿纭悕鍗曞繀椤绘帓鍦ㄦ渶鍓嶏級銆傚叾浣欏瓧娈垫湁瑙勮寖鍚嶅氨澶燂紝锟?2 鍚嶇暀绌猴拷?*/
static const char* const kDdhAttrNativeName2[DDH_AN_COUNT] =
{
    "", "", "", "", "", "", "", "", "",                  /* 绉拌皳 ~ 鎶ょ敳(Defense) */
    "GetUnitDefaultMoveSpeed",                            /* 绉伙拷?*/
    "GetUnitDefaultMoveSpeed",                            /* 鍩虹绉伙拷?*/
    "", "", "", "", "", "", "", "", "", "", "", ""            /* 瑙嗛噹 ~ 骞昏薄鍒ゅ畾 */
};


/* ===========================================================================
   v10 璇婃柇锛歯ative 琛ㄥ叏锟?dump锛堝彧鍐欎竴娆★級+ 鍏抽敭瀛楄嚜鍔ㄥ尮锟?
   ---------------------------------------------------------------------------
   琛ㄧ粨鏋勪笌 FindNativeFunc 瀹屽叏涓€鑷达細
     inst = get_instance(5)锛泃bl = inst + 0x18
     tbl+0x1C = buckets锛宼bl+0x24 = mask锛涙瘡锟?12 瀛楄妭锟?8 = 鑺傜偣锟?
     鑺傜偣 +0x04 hash锟?0x0C 閾句笂涓嬩竴涓拷?0x18 鍚嶅瓧鎸囬拡锟?0x1C 鍑芥暟鎸囬拡
   鍚嶅瓧鏈€锟?2000 涓紙瓒呬簡鎴柇锛夛紝鎸夊瓧姣嶅簭锛堝ぇ灏忓啓涓嶆晱鎰燂級杈撳嚭锟?
   鍚叧閿瓧鐨勫€欓€夊湪 dump 琛岄噷鍚嶅瓧鍓嶅姞 '*'锛屽苟缁熻鍛戒腑鏁帮拷?
    鑷姩鍖归厤鍙 Get / Is 寮€澶寸殑璇诲彇鍨嬪悕瀛楋紙鎺掗櫎 Set 寮€锟?+ 鎺掗櫎鍚嶅崟锛夛紝鎸夆€滃悕瀛楄秺鐭秺锟?
    瑙勮寖鍚嶁€濇帓搴忥紱v16 锟?*鍥哄畾绮剧‘鍚嶅崟浼樺厛**锛岃嚜鍔ㄥ€欓€夊彧鍦ㄧ簿纭悕鍗曞叏閮戒笉瀛樺湪鏃跺厹搴曪拷?
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
    "绉拌皳", "鏀诲嚮鑼冨洿", "鏀诲嚮鍔涗笅闄?, "鏀诲嚮鍔涗笂闄?, "鏀诲嚮鍔?, "鏀诲嚮闂撮殧", "鏀诲嚮閫熷害",
    "鎶ょ敳", "鎶ょ敳(Defense)", "绉婚€?, "鍩虹绉婚€?, "瑙嗛噹", "涓诲姩鏀诲嚮鑼冨洿",
    "鍔涢噺", "鍔涢噺(鑻遍泟)", "鏁忔嵎", "鏁忔嵎(鑻遍泟)", "鏅哄姏", "鏅哄姏(鑻遍泟)", "鍗曚綅闄勫姞鍊?,
    "鍗曚綅绫诲瀷ID", "鑻遍泟ID鍒ゅ畾", "骞昏薄鍒ゅ畾"
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

/* camelCase 璇嶅厓鍖归厤锛歋tr / Agi / Int 鍙 "GetHeroStr" 杩欑鐙珛璇嶏紝
   涓嶆妸 String / Integer / Magic 閲岀殑瀛愪覆褰撹瘝鍏冿拷?*/
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

/* 鑷姩鍖归厤鍙帴鍙楄鍙栧瀷鍚嶅瓧锛岀粷涓嶆妸 Set* 锟?provider锟?*/
static int DdhNameCallable(const char* n)
{
    if (!n || !n[0]) return 0;
    if (DdhNameHas(n, "set")) return 0;
    return DdhNameHas(n, "get") || DdhNameHas(n, "is");
}

/* ---------------------------------------------------------------------------
   鎺掗櫎鍚嶅崟锛氳繖锟?native 鍚嶅瓧**浠讳綍瀛楁閮戒笉浼氶噰锟?*锛堢湡鏈烘棩蹇楅€愭潯璇佹槑浼氭寫閿欙級锟?
     GetGameSpeed             娓告垙閫熷害锛屼笉鏄崟浣嶇Щ閫燂紱鐪熸満杩斿洖 0 锟?鐣岄潰鏄剧ず 0
     GetRandomInt             闅忔満鏁存暟锛堟棫鐗堜笁锟?绉婚€熼兘鍙兘琚畠鍛戒腑锟?
     GetUnitTurnSpeed         杞悜閫熷害锛屼笉鏄Щ锟?
     GetUnitDefaultTurnSpeed  榛樿杞悜閫熷害
     GetItemUserData          鐗╁搧鑷畾涔夊€硷紝涓嶆槸鈥滃崟浣嶉檮鍔犲€硷拷?
     UnitShareVision          鍏变韩瑙嗛噹寮€鍏筹紙UnitShareVisionBJ 鍚屽墠缂€锛夛紝涓嶆槸瑙嗛噹鑼冨洿
   v16锛氭ā绯婂尮閰嶏紙鍏抽敭瀛楄嚜鍔ㄥ€欓€夛級涔熻杩囪繖涓€鍏筹紝閬垮厤鈥滃悕瀛楃煭浼樺厛鈥濆張鎶婇敊鐨勬寫鍥炴潵锟?
   --------------------------------------------------------------------------- */
static const char* const kDdhAttrBannedGlobal[] =
{
    "GetGameSpeed", "GetRandomInt", "GetUnitTurnSpeed", "GetUnitDefaultTurnSpeed",
    "GetItemUserData", "UnitShareVision"
};

/* 1 = 杩欎釜鍚嶅瓧鍦ㄨ瀛楁涓绂佹锛圖dhAttrNative 姘歌繙涓嶄細閲囩敤锛夛拷?*/
static int DdhAttrNameBanned(int id, const char* n)
{
    if (!n || !n[0]) return 1;
    for (int i = 0; i < (int)(sizeof(kDdhAttrBannedGlobal) / sizeof(kDdhAttrBannedGlobal[0])); ++i)
        if (DdhNameHas(n, kDdhAttrBannedGlobal[i])) return 1;
    /* 骞冲彴绫诲瀷鏁版嵁 native锛圖zAPI_*锛夛細绗竴涓疄鍙傛槸鈥滃崟浣嶇被锟?id鈥濓紝涓嶆槸鍗曚綅鍙ユ焺锟?
       缁濅笉鑳藉綋 get-unit-xxx 鐢紙鏃х増鑷姩鍖归厤锟?DzAPI_UnitType_GetUnitTypeDataInt
       褰撴垚鈥滄櫤鍔涒€濆€欓€夎繃锛屽氨鍥犱负鍚嶅瓧閲屾湁 Int 璇嶅厓锛夛拷?*/
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

/* 瀛楁 -> 鍏抽敭瀛楄鍒欙紙鍖呭惈鍖归厤锛夈€傚懡涓悗浠嶈鐪熻皟鍒版湁闄愭暟鎵嶉噰鐢拷?
   v16锛氬懡涓帓闄ゅ悕鍗曠殑鐩存帴涓嶇畻鍊欓€夛紙妯＄硦鍖归厤鍙槸鏈€鍚庡厹搴曪級锟?*/
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
    LogLine("ATTR 鎺掗櫎鍚嶅崟锛堜换浣曞瓧娈甸兘涓嶄細閲囩敤锛夛細GetGameSpeed, GetRandomInt, GetUnitTurnSpeed, "
            "GetUnitDefaultTurnSpeed, GetItemUserData, UnitShareVision(锟?BJ)锛涜閲庡畬鍏ㄤ笉锟?native");
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
        LogLine("ATTR 鑷姩鍖归厤锛?s 鍊欓€?%s", kDdhAttrFieldName[id], list);
    }
    LogLine("ATTR 鑷姩鍖归厤锛氬叡 %d / %d 涓瓧娈垫湁鍏抽敭瀛楀€欓€夛紙鍥哄畾鍚嶅崟缁х画浣滀负鍚庡锛?,
            fields, (int)DDH_AN_COUNT);
}

static int __cdecl DdhNativeNameCmp(const void* a, const void* b)
{
    return _stricmp((const char*)a, (const char*)b);
}

/* 绗竴娆″鐞嗗睘鎬ц姹傛椂璋冪敤锛涜〃娌″氨缁紙杩涘浘鍓嶏級浼氬湪涓嬩竴杞啀璇曪紝鏈€锟?20 杞拷?*/
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
        LogLine("ATTR dump锛氶亶鍘?native 琛ㄥ紓甯?code=%08X", (unsigned)GetExceptionCode());
    }

    if (count <= 0)
    {
        if (g_ddhNativeDumpTries <= 3)
            LogLine("ATTR dump锛歯ative 琛ㄨ繕娌″氨缁紙绗?%d 娆★級锛屼笅涓€杞睘鎬ц姹傚啀璇?, (int)g_ddhNativeDumpTries);
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
        LogLine("ATTR dump[%d/%d]锟?s", line + 1, lines, buf);
    }
    LogLine("ATTR dump锛氬叡 %d 涓?native锛屽懡涓叧閿瓧 %d 涓?, count, hit);

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
static volatile LONG g_ddhAttrLocustLogged    = 0;   /* v14锛氬睘鎬у搷搴旈噷鐨勮潡铏垽瀹氭棩蹇楋紝鏈€锟?10 锟?*/
static volatile LONG g_ddhAttrAlocMissLogged = 0;   /* Aloc 鏈懡涓瘖鏂棩蹇楄鏁?*/
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
static volatile LONG g_ddhAttrTitleDiag = 0;   /* 锟?8 娆＄О璋撹瘖鏂棩锟?*/
static volatile LONG g_ddhAttrSt0Logged       = 0;
static volatile LONG g_ddhAttrUnitLogged      = 0;
static volatile LONG g_ddhAttrRoundLogged     = 0;
static volatile LONG g_ddhAttrFieldLogged[20];   /* v11锟?锟?锟?锟?闄勫姞锟?璇存槑 锟?5 涓柊锟?*/

/* 涓€鏉℃棩蹇楀彧璁颁竴娆★紙璇婃柇鐢紱璁℃暟鍣ㄥ彧澧炰笉鍑忥紝浠ｄ环鏄嚑锟?InterlockedIncrement锟?*/
static void DdhAttrLogOnce(volatile LONG* counter, const char* fmt, ...)
{
    if (!counter || InterlockedIncrement(counter) != 1) return;
    char buf[320] = { 0 };
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(buf, sizeof(buf), _TRUNCATE, fmt, ap);
    va_end(ap);
    LogLine("ATTR锟?s", buf);
}

/* 鎸夊悕瀛楁噿瑙ｆ瀽涓€涓睘锟?native锟?*绮剧‘鍚嶅崟浼樺厛锛屽叧閿瓧妯＄硦鍖归厤鍙綔鏈€鍚庡厹锟?*锟?
   鐪熸満鏃ュ織璇佹槑鈥滄寜鍚嶅瓧闀垮害鎺掑簭鐨勮嚜鍔ㄥ尮閰嶁€濅細鎸戝埌閿欑殑 native锟?
     路 绉婚€熸寫锟?GetGameSpeed锛堣繑锟?0锛岀晫闈㈡樉锟?0锟?
     路 鍗曚綅闄勫姞鍊兼寫锟?GetItemUserData锛堢墿鍝佽嚜瀹氫箟鍊硷級
     路 瑙嗛噹鎸戝埌 UnitShareVision锛堝叡浜閲庡紑鍏筹紝鏍规湰涓嶆槸瑙嗛噹锟?
   鎵€浠ラ『搴忔敼鎴愶細锟?绮剧‘鍚嶅崟锛坘DdhAttrNativeName 锟?kDdhAttrNativeName2锟?
              锟?绮剧‘鍚嶅崟鍏ㄩ兘涓嶅瓨鍦紝鎵嶇湅鍏抽敭瀛楄嚜鍔ㄥ€欓€夛紙鎺掗櫎鍚嶅崟宸茶繃婊わ級
   瑙嗛噹鐗规畩锛氫竴锟?native 閮戒笉鐢紱鐧藉ぉ/澶滄櫄锟?jass.slk 锟?sight/nsight锛圗XExecuteScript锛夛紝
   slk 鍙栦笉鍒版墠閫€锟?Game.dll+0x3ADF0 鐨勨€滃綋鍓嶆湁鏁堣閲庘€濓紙鍗忚 v14锛岃 DdhSightRead锛夛拷?
   鎴愬姛/鏀惧純鍚勫彧璁颁竴琛屾棩蹇楋紙姣忕灞炴€у彧鍐欎竴娆★級锟?*/
static uint32_t DdhAttrNative(int id)
{
    if (id < 0 || id >= DDH_AN_COUNT) return 0;
    if (g_ddhAttrNative[id]) return g_ddhAttrNative[id];
    const LONG tries = InterlockedIncrement(&g_ddhAttrNativeTries[id]);
    if (tries > 20) return 0;

    uint32_t fn = 0;
    const char* used = NULL;
    int autoHit = 0;

    /* 锟?绮剧‘鍚嶅崟锛堣鑼冨悕 -> 绗簩绮剧‘鍚嶏級 */
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

    /* 锟?鏈€鍚庡厹搴曪細鍏抽敭瀛楄嚜鍔ㄥ€欓€夛紙鍙湪杩欎釜瀛楁鐨勭簿纭悕鍗曚竴涓兘涓嶅瓨鍦ㄦ椂鎵嶄細璧板埌锟?*/
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
            LogLine("ATTR native锛?s 宸插畾浣嶏紙0x%08X锛岀 %d 娆″皾璇?s锛?,
                    DdhAttrUsedName(id), fn, (int)tries, autoHit ? "锛岃嚜鍔ㄥ尮閰嶅厹搴? : "锛岀簿纭悕鍗?);
        return fn;
    }
    if (tries == 20 && InterlockedIncrement(&g_ddhAttrNativeLogged[id]) == 1)
        LogLine("ATTR native锛?s 宸插畾浣嶏紙0x%08X锛岀 %d 娆″皾璇?s锛?,
                kDdhAttrNativeName[id]);
    return 0;
}

/* 璋冧竴锟?native锛氭姄 EAX锛圝ASS 鍊肩害瀹氾細real = float 浣嶆ā寮忥級锛屽悓鏃舵姄 ST(0)
   锛圕 娴偣杩斿洖绾﹀畾锛夈€傚弬鏁板浐瀹氭寜 2 锟?cdecl 锟?鈥旓拷?澶氫紶涓€涓爤鍙傛暟锟?cdecl/__fastcall
   閮芥槸鏃犲鐨勶紝鑰岃锟?GetHeroStr 姝ｅソ闇€瑕佺浜屽弬鏁帮拷?
   娉ㄦ剰锛氳璋冩柟濡傛灉娌″線 ST(0) 鍘嬩笢瑗匡紝fstp 璇诲埌鐨勬槸绌烘爤鐨勨€滄棤鏁堝€尖€濓紙NaN 绫伙級锟?
   涓嬮潰鍙帴鍙楁湁闄愭暟锛屾墍浠ヤ笉浼氳鐢拷?*/
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

/* 鍙栦竴锟?real锛欵AX 浣嶆ā寮忎紭鍏堬紙涓庡紩锟?GetUnitState/GetOwningPlayer 鍚屾簮锛夛紝
   EAX 涓嶆槸鏈夐檺鏁版墠閫€锟?ST(0)锟?*/
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
                       "real 杩斿洖鍊奸€€鍒?C 娴偣绾﹀畾锛圫T(0)=%.3f锛孍AX=0x%08X锛夛細鍙湁 EAX 涓嶆槸鏈夐檺鏁版椂鎵嶄細杩欐牱",
                       (double)st0, eax);
        return true;
    }
    return false;
}

/* 鎸夊€欓€夐『搴忚瘯锛岃繑鍥炲懡涓殑鍊欙拷?id锟?1 = 閮芥病鎷垮埌鍊硷級 */
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

/* 鍙栦竴涓嫳闆勪笁锟?鏁存暟锟?native 鐨勬暟鍊硷拷?
   GetHeroStr/Agi/Int 锟?JASS 濂戠害锟?integer锛圗AX=鏁存暟锛夛紝浣嗗亣榄斿吔/閮ㄥ垎 JAPI 锟?
   鏁板€兼寜 float 浣嶆ā寮忔斁锟?EAX锛堜緥锟?15.0f = 0x41700000锛夈€傝繖閲屽厛鎸夋暣鏁拌
   锟?~1e6锛夛紝涓嶅儚鏁板€煎啀锟?float 浣嶆ā寮忚锛屾渶鍚庤瘯 ST(0) 鈥旓拷?涓ょ ABI 閮借兘鎷垮埌鍊硷紝
   鍙堜笉浼氭妸 15.0f 鐨勪綅妯″紡褰撴垚 10 浜跨骇鐨勫法澶у姏閲忥拷?*/
static bool DdhNatCallStatInt(uint32_t fn, uint32_t handle, float* out)
{
    if (!fn || !out) return false;
    float    st0 = 0.0f;
    uint32_t eax = 0;
    __try { DdhNatCallAsm(fn, handle, 1, &eax, &st0); }   /* includeBonuses=1锛氬惈缁垮瓧鍔犳垚锛屽拰瑙掕壊闈㈡澘涓€鑷?*/
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    const int32_t iv = (int32_t)eax;
    if (iv >= 0 && iv <= 1000000) { *out = (float)iv; return true; }

    float fv = 0.0f;
    memcpy(&fv, &eax, 4);
    if (DdhAttrFinite(fv) && fv >= 0.0f && fv <= 1000000.0f) { *out = fv; return true; }
    if (DdhAttrFinite(st0) && st0 >= 0.0f && st0 <= 1000000.0f) { *out = st0; return true; }
    return false;
}

/* 鎸夊€欓€夐『搴忚瘯鑻遍泟涓夌淮 native锛圙etHeroStr/Agi/Int 浼樺厛锛夛紝杩斿洖鍛戒腑 id锟?1 = 閮芥病鎷垮埌锟?*/
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

/* 鍙栦竴涓暣锟?甯冨皵杩斿洖鍊硷紙EAX锛夛細鑻遍泟鍒ゅ畾銆佺被鍨嬬爜杩欑被 native 鐢拷?*/
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

/* 瀛楁鏈€缁堣В鏋愬埌鐨勫€欙拷?璇存槑锛氭瘡绉嶅瓧娈靛彧鍐欎竴琛屾棩锟?*/
static void DdhAttrFieldNote(int slot, const char* text)
{
    if (slot < 0 || slot >= 20) return;
    DdhAttrLogOnce(&g_ddhAttrFieldLogged[slot], "%s", text);
}

/* 4 瀛楃鐮佺炕姝ｏ紙鍐呭瓨閲屽弽搴忓瓨锟? 鍙暀鍙樉绀哄瓧锟?*/
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

/* ---- 绉拌皳锛堣嫳闆勪笓鍚嶏級----
   浼樺厛绾э紙姣忎竴绾ч兘 __try锛屽け璐ラ潤榛橀€€涓嬩竴绾э級锟?
     锟?DzAPI_UnitType_GetUnitTypeDataString(code, "Propernames")锛氭湰鍥剧湡姝ｇ殑涓撳悕鏁版嵁锟?
     锟?GetHeroProperName锛氳繑锟?string id锛堜篃鍙兘鏌愪簺 JAPI 鐩存帴杩斿洖 char*锛夛紝涓ょ閮借瘯锟?
     锟?GetUnitName锛氬悓鏍峰彲鑳芥槸 string id 锟?char*锛屼袱绉嶉兘璇曪紱
     锟?閮芥嬁涓嶅埌 锟?绉拌皳缃┖锛圕# 鍙樉绀哄崟浣嶅悕锛夛紝缁濅笉鍐嶇敤绫诲瀷鐮佸悕瀛楀啋鍏呬笓鍚嶏拷?
   娉ㄦ剰锛氳繖閲屽彧璐熻矗鈥滃彇鏂囨湰鈥濓紝鏄笉鏄嫳闆勭敱 DdhAttrFillOne 锟?
   GetUnitTypeId + IsHeroUnitId 鍒ゅ畾锛岄伩鍏嶆妸鍟嗗簵涔熷綋鑻遍泟锟?*/
#define DDH_RVA_STRING_BY_ID 0x001C2870u
static uint32_t      g_ddhStringById = 0;
static volatile LONG g_ddhStringByIdTries = 0;
static volatile LONG g_ddhStringIdDiag    = 0;   /* 锟?8 涓煡琛ㄥけ璐ョ殑 string id 璇婃柇 */

static uint32_t DdhStringByIdFn(void)
{
    if (g_ddhStringById) return g_ddhStringById;
    if (InterlockedIncrement(&g_ddhStringByIdTries) > 16) return 0;
    g_ddhStringById = HpResolve(DDH_RVA_STRING_BY_ID, NULL);
    if (g_ddhStringById)
        LogLine("ATTR string-id 0x1C2870 = 0x%08X 宸插畾浣嶏紙绉拌皳鍙嶆煡鐢級", g_ddhStringById);
    else
        LogLine("ATTR string-id 0x1C2870 娌″畾浣嶅埌 鈥斺€?绉拌皳鍙兘閫€鍥炩€滄妸杩斿洖鍊煎綋 char*鈥?);
    return g_ddhStringById;
}

/* ===========================================================================
   鐪熸満瀛楃锟?id 鍙嶆煡淇锛坴18锟?
   ---------------------------------------------------------------------------
   鐪熸満锛欸etHeroProperName / GetUnitName 閮借繑鍥炴湁鏁堢殑 string id锟?x590/0x563 杩欑被锛夛紝
   浣嗗紩锟?0x1C2870 锟?id鈫抍har* 鍙嶆煡锟?0锛氬畠鏌ョ殑锟?ctx+0x20 锟?UI 瀛楃涓茶〃锛岋拷?JASS
   瀛楃涓插疄闄呮槸锟?ctx+8 鐨勫彟涓€寮犺〃锟?intern 鐨勶紙0x1DA520 锟?ctx+8 锟?0x7E2D50锛夛拷?
   涓庡叾缁х画鐚滆〃缁撴瀯锛岀洿鎺ュ湪鈥滃瓧绗︿覆鍏ヨ〃鈥濆嚱锟?0x1DA520 涓婃寕涓€锟?8 瀛楄妭鍘熷瓙閽╁瓙锟?
     路 鍏ヨ〃鍓嶆妸 char* 鏂囨湰澶嶅埗鍒版湰鍦帮紱
     路 璋冨師鍑芥暟鎷垮埌 id锟?
     路 锟?(id 锟?鏂囨湰) 瀛樿繘 128 椤圭幆褰㈢紦瀛橈拷?
   杩欐牱 ddh 鑷繁锟?GetHeroProperName 鏃讹紝native 鍐呴儴锟?intern 瀹屾爣棰橈紝缂撳瓨閲屽氨宸茬粡锟?
   鈥渋d 锟?鏍囬姝ｆ枃鈥濓紝DdhAttrTextFromIdOrPtr 鐩存帴鍛戒腑锛屼笉鍐嶄緷锟?0x1C2870锟?
   鍙湪娓告垙绾跨▼瀹夎锛涘嚱鏁板簭瑷€涓嶅尮閰嶏紙鐗堟湰涓嶅/鍋囬瓟鍏斤級灏辨斁寮冿紝涓嶅奖鍝嶅師鏈夐€昏緫锟?
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

/* 瀛楃涓插叆琛ㄩ挬瀛愶細ECX = char*锛堝師鍑芥暟 0x1DA520 鐨勯潪绌哄垎鏀級锟?*/
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

/* 瀹夎閽╁瓙锛堟父鎴忕嚎绋嬨€佸彧涓€娆★級銆傚師鍑芥暟锟?8 瀛楄妭锟?
   85 C9 75 03 33 C0 C3 51 (test/jne/xor/ret/push)锟?
   8 瀛楄妭瀵归綈锛岀敤 InterlockedExchange64 涓€娆℃浛鎹㈡垚 E9 rel32 + 3脳NOP锛岄伩鍏嶅崐鍐欐寚浠わ拷?*/
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
            LogLine("ATTR 瀛楃涓查挬瀛愶細0x1DA520 搴忚█涓嶅尮閰嶏紙%02X %02X %02X %02X锛夛紝涓嶆寕",
                    fn[0], fn[1], fn[2], fn[3]);
            return;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return; }

    g_ddhInternTramp = (uint8_t*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!g_ddhInternTramp)
    {
        LogLine("ATTR 瀛楃涓查挬瀛愶細VirtualAlloc 澶辫触 %lu", GetLastError());
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
        LogLine("ATTR 瀛楃涓查挬瀛愶細VirtualProtect 澶辫触 %lu", GetLastError());
        return;
    }
    g_ddhInternSaved = InterlockedExchange64((volatile LONG64*)fn, *(LONG64*)patch);
    VirtualProtect(fn, 8, oldProt, &oldProt);
    FlushInstructionCache(GetCurrentProcess(), fn, 8);
    g_ddhInternHooked = 1;
    LogLine("ATTR 瀛楃涓查挬瀛愶細0x1DA520 宸叉寕锛坕d鈫掓枃鏈紦瀛?%d 椤癸級", DDH_INTERN_RING);
}

/* string id -> char*锛氬厛锟?intern 閽╁瓙缂撳瓨锛屽啀锟?0x1C2870 / 锟?char*锟?*/
static int DdhAttrTextFromIdOrPtr(uint32_t raw, char* out, size_t cap)
{
    out[0] = 0;
    if (!raw) return 0;

    if (DdhInternCacheFind(raw, out, cap))
    {
        if (InterlockedIncrement(&g_ddhStringIdDiag) <= 8)
            LogLine("ATTR string-id锛歩d=0x%X 鍛戒腑 intern 缂撳瓨 text=\"%s\"锛堜笉鍐嶈蛋 0x1C2870锛?, raw, out);
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

/* ---- 鍗曚綅绫诲瀷鏁版嵁锛圲nitStrings / UnitBalance锟?---
   骞冲彴 native锛堟父鎴忓唴 JASS锛夛細
     DzAPI_UnitType_GetUnitTypeDataString(unitTypeId, field)
     DzAPI_UnitType_GetUnitTypeDataInt(unitTypeId, field)
     DzAPI_UnitType_GetUnitTypeDataReal(unitTypeId, field)

   杩欎簺鏄€滃崟浣嶇被鍨嬧€濈殑鍩虹鏁版嵁锛圥ropernames / spd / sight / nsight / def锛夛紝
   涓嶅湪 CUnit 杩愯鏈熷瓧娈甸噷锛屼篃涓嶅湪 unit_property 閲岋紱鍙兘鍦ㄦ父鎴忕嚎绋嬭皟鐢拷?

   v16 鍏抽敭淇锛堢湡鏈烘棩蹇楋細native 宸插畾浣嶏紝浣嗗彇锟?0/绌猴級锟?
     锟?瀛楃涓插弬鏁板繀椤绘槸 **JASS string 鍙ユ焺** 鈥旓拷?锟?DdhMakeJassString 锟?string_fake
        瀵硅薄鎸囬拡锛堜笌 DisplayTimedTextToPlayer 鍚屾锛夛紝缁濅笉鑳戒紶锟?char*锟?
     锟?瀹炲弬椤哄簭 / unitTypeId 褰㈡€佸叡 2脳2=4 绉嶇粍鍚堬紝姣忕鍙瘯涓€娆″苟鎶婄粨鏋滃啓鏃ュ織锟?
          DZPROBE order=%d id=%d field=sight -> 0x%08X / int=%d
        閫変腑绗竴锟?sight 钀藉湪 100~5000 鐨勭粍鍚堬紝鍐欙細
          ATTR 鍗曚綅绫诲瀷鏁版嵁锛氶噰锟?order=%d id褰㈠紡=%d
        涔嬪悗鎵€鏈夊瓧娈碉紙Propernames/spd/sight/nsight/def/points锛夐兘鎸夎繖涓粍鍚堣皟鐢紱
     锟?4 绉嶅叏澶辫触 锟?涓嶇寽锛屾槑纭啓鏃ュ織锛岃锟?绉拌皳/鍩虹鏁版嵁鐣岄潰涓€锟??锟?
   --------------------------------------------------------------------------- */
static uint32_t g_ddhTypeDataStrFn = 0;
static uint32_t g_ddhTypeDataIntFn = 0;
static uint32_t g_ddhTypeDataRealFn = 0;
static volatile LONG g_ddhTypeDataFnLogged = 0;

/* 鎺㈡祴缁撴灉锛歰rder 0 = (int unitTypeId, string field)锟? = (string field, int unitTypeId)
             idForm 0 = 绫诲瀷锟?rawcode锛圫afeCode锛夛紱1 = GetUnitTypeId(handle) 鐨勮繑鍥烇拷?*/
static volatile LONG g_ddhTypeDataProbeDone  = 0;
static volatile LONG g_ddhTypeDataProbeTries = 0;
static int g_ddhTypeDataOrder  = 0;
static int g_ddhTypeDataIdForm = 0;
static int g_ddhTypeDataFieldMode = 0;   /* 0 = string_fake 瀵硅薄鎸囬拡锟? = 寮曟搸 string id */
static int g_ddhTypeDataOk     = 0;

/* 瀛楃涓插彞鏌勫伐鍘傚湪鈥滅粨绠楀箍鎾€濅竴鑺傦紙string_fake 闈欐€佹睜锛夛紱杩欓噷鍏堢敤鍚庡畾涔夛拷?*/
static uint32_t DdhMakeJassString(const char* text);

static uint32_t DdhTypeDataFn(const char* name, uint32_t* cache)
{
    if (*cache == 0xFFFFFFFFu) return 0;   /* 宸茬‘璁ゆ壘涓嶅埌锛屽埆鍐嶅弽澶嶆悳 native 锟?*/
    if (*cache) return *cache;
    const uint32_t fn = FindNativeFunc(name);
    *cache = fn ? fn : 0xFFFFFFFFu;
    if (InterlockedIncrement(&g_ddhTypeDataFnLogged) <= 6)
        LogLine("ATTR 鍗曚綅绫诲瀷鏁版嵁锛?s %s", name, fn ? "鍛戒腑" : "娌℃壘鍒?);
    return fn;
}

/* 璋冧竴娆＄被鍨嬫暟锟?native锛歛1 = 绗竴涓疄鍙傦紝a2 = 绗簩涓疄鍙傦紙cdecl 椤哄簭锛夛拷?*/
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

/* 鐪熸満 JASS native 锟?string 瀹炲弬鍏跺疄鏄€滃瓧绗︿覆 id鈥濓紙灏忔暣鏁帮級锛屼笉锟?string_fake 鎸囬拡锟?
   ddh 涔嬪墠鍙細锟?string_fake锛屾墍浠ュ亣榄斿吔鑳借繃銆佺湡锟?DzAPI 鍏ㄨ繑锟?0銆傝繖閲岃ˉ涓€鏉★細
   鐩存帴鐢ㄥ紩鎿庡叆琛ㄥ嚱锟?0x1DA520 锟?"sight"/"nsight" 绛夐€犳垚锟?string id锟?*/
static uint32_t DdhMakeEngineStringId(const char* text)
{
    if (!g_modBase || !text || !text[0]) return 0;
    typedef uint32_t (__fastcall* fn_make_id)(const char*);
    uint32_t id = 0;
    __try { id = ((fn_make_id)(uintptr_t)(g_modBase + 0x001DA520u))(text); }
    __except (EXCEPTION_EXECUTE_HANDLER) { id = 0; }
    return id;
}

/* 鎸夋寚锟?order / fieldMode 缁勫疄鍙傦細
   fieldMode 0 = string_fake 瀵硅薄鎸囬拡锛堝亣榄斿吔/閮ㄥ垎 JAPI 鐢級锟?
   fieldMode 1 = 寮曟搸 string id锛堢湡锟?JASS native 鐢級锟?*/
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

/* 閫変腑缁勫悎鍚庯紝鍚勫瓧娈电粺涓€鎸夊畠璋冪敤锟?*/
static bool DdhTypeDataCallOrdered(uint32_t fn, uint32_t unitTypeId, const char* field,
                                   uint32_t* eax, float* st0)
{
    return DdhTypeDataCallWith(fn, g_ddhTypeDataOrder, g_ddhTypeDataFieldMode,
                               unitTypeId, field, eax, st0);
}

/* unitTypeId 褰㈡€侊細0 = 绫诲瀷锟?rawcode锟? = GetUnitTypeId(handle)锛堟嬁涓嶅埌閫€鍥炵爜锛夛拷?*/
static uint32_t DdhTypeDataUnitId(uint32_t handle, uint32_t code)
{
    if (g_ddhTypeDataIdForm == 1 && handle)
    {
        uint32_t tid = 0;
        if (DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &tid) && tid) return tid;
    }
    return code;
}

/* 鍙栦竴娈碘€滃彲鏄剧ず鏂囨湰鈥濓細p 蹇呴』鍙锟? 缁撳熬銆佹棤鎺у埗瀛楃/0x7F锛岄暱锟?1..4095锟?
   Propernames 鍙兘鏄竴闀夸覆锛堥€楀彿鍒嗛殧锛夛紝鎵€浠ヤ笂闄愭斁瀹斤紝浣嗕粛锟?out 瀹归噺瀹夊叏鎴柇锟?*/
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

/* String 鐗堣繑鍥炲€间笁绉嶅舰鎬侀兘瑙ｏ紙锟?DdhAttrTextFromIdOrPtr 鍚屾€濊矾锛夛細
     锟?string_fake 瀵硅薄鎸囬拡锛歔raw+0x08] -> 瀵硅薄锛孾瀵硅薄+0x1C] -> char*锟?
     锟?瀛楃涓茶〃 id锟?x105A 杩欑灏忔暣鏁帮級锟?0x1C2870 鍙嶆煡锟?
     锟?锟?char*锟?
   浠讳綍涓€绉嶈В鍑哄彲鏄剧ず鏂囨湰灏遍噰鐢紱鍏ㄧ▼ __try锛屽潖鎸囬拡鍙綋鈥滄病鎷垮埌鈥濓拷?*/
static bool DdhTypeDataText(uint32_t raw, char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    if (!raw) return false;

    /* 锟?string_fake 瀵硅薄鎸囬拡 */
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

    /* 锟?瀛楃涓茶〃 id */
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

    /* 锟?锟?char* */
    return DdhTypeDataTextCopy(raw, out, cap);
}

/* 绫诲瀷鏁版嵁鍥炬爣鎺㈡祴锛氬父锟?sight 鎺㈡祴澶辫触鏃讹紝鐩存帴锟?String 锟?native 锟?.blp锟?
   鏈変簺骞冲彴/鍦板浘锟?sight 瀛楁涓嶅彲鐢紝锟?Art/Icon 瀛楁浠嶈兘杩斿洖鍛戒护鍗″浘鏍囪矾寰勶拷?*/
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
                    LogLine("闈㈡澘澶村儚锛氱被鍨嬫暟鎹?String 鎺㈡祴鎴愬姛 order=%d id=%d fld=%d field=%s path=%s",
                            order, idForm, fieldMode, fields[fi], path);
                    return;
                }
            }
        }
    }
}

/* 4 绉嶅疄鍙傜粍鍚堝悇璇曚竴娆★紙field=sight锛夛紝閫変腑鍚庡浐瀹氫娇鐢ㄣ€傚彧鍦ㄦ嬁鍒板彞鏌勭殑鍗曚綅涓婂仛锟?*/
static void DdhTypeDataProbe(uint32_t handle, uint32_t code)
{
    if (g_ddhTypeDataProbeDone) return;
    if (!handle || !code) return;            /* 娌″彞锟?娌＄被鍨嬬爜锛氫笅涓€杞啀锟?*/
    if (InterlockedIncrement(&g_ddhTypeDataProbeTries) > 3) return;

    const uint32_t fnInt = DdhTypeDataFn("DzAPI_UnitType_GetUnitTypeDataInt", &g_ddhTypeDataIntFn);
    if (!fnInt)
    {
        g_ddhTypeDataOk = 0;
        g_ddhTypeDataProbeDone = 1;
        LogLine("ATTR 鍗曚綅绫诲瀷鏁版嵁锛欼nt 鐗?native 鏈畾浣?鈫?瑙嗛噹/绉拌皳/鍩虹鏁版嵁鍙兘鐣??锛堜笉鎷?0 鍐掑厖锛?);
        DdhAttrFieldNote(17, "鍗曚綅绫诲瀷鏁版嵁锛欼nt 鐗?native 鏈畾浣嶏紝瑙嗛噹/绉拌皳/鍩虹鏁版嵁涓€寰??");
        return;
    }

    uint32_t tid = 0;
    const bool hasTid = DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &tid) && tid != 0;

    int bestOrder = -1, bestIdForm = -1, bestFieldMode = -1, bestInt = 0;
    /* 2(order) 脳 2(idForm) 脳 2(fieldMode) = 8 绉嶇粍鍚堬紝姣忕粍鍙皟涓€娆★紱
       閫変腑**绗竴锟?*杩斿洖鍚堢悊鍊肩殑缁勫悎銆傜湡鏈哄ぇ姒傜巼锟?fieldMode=1锛堝紩锟?string id锛夛拷?*/
    for (int order = 0; order < 2; ++order)
    {
        for (int idForm = 0; idForm < 2; ++idForm)
        {
            if (idForm == 1 && !hasTid)
            {
                LogLine("DZPROBE order=%d id=%d field=sight -> (GetUnitTypeId 涓嶅彲鐢紝璺宠繃)",
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
        LogLine("ATTR 鍗曚綅绫诲瀷鏁版嵁锛氶噰鐢?order=%d id褰㈠紡=%d 瀛楃涓插舰寮?%d",
                bestOrder, bestIdForm, bestFieldMode);
        char note[192];
        _snprintf_s(note, sizeof(note), _TRUNCATE,
                    "鍗曚綅绫诲瀷鏁版嵁 鈫?DzAPI_UnitType_GetUnitTypeData*(order=%d id褰㈠紡=%d 瀛楃涓插舰寮?%d锛宻ight 鎺㈡祴=%d)",
                    bestOrder, bestIdForm, bestFieldMode, bestInt);
        DdhAttrFieldNote(17, note);
        return;
    }

    /* 锟?0 / 瓒婄晫锛氬彲鑳界涓€涓崟浣嶆槸寤虹瓚鎴栬閲庝负 0锛屾崲涓嬩竴涓崟浣嶅啀璇曪紙鏈€锟?3 涓級 */
    if (g_ddhTypeDataProbeTries < 3)
    {
        LogLine("ATTR 鍗曚綅绫诲瀷鏁版嵁锛氱 %d 涓崟浣嶇殑 8 绉嶇粍鍚堥兘娌℃嬁鍒板悎鐞?sight锛屾崲涓嬩竴涓崟浣嶅啀璇?,
                (int)g_ddhTypeDataProbeTries);
        return;
    }

    g_ddhTypeDataOk = 0;
    g_ddhTypeDataProbeDone = 1;
    LogLine("ATTR 鍗曚綅绫诲瀷鏁版嵁锟? 绉嶅疄鍙傜粍鍚堥兘鍙栦笉鍒板悎鐞嗗€硷紙sight 涓嶅湪 100~5000锛夆啋 "
            "閫€鍖栦负鍙敤鍐呭瓨鐩磋 + 鐜版湁 native锛岃锟?绉拌皳/鍩虹鏁版嵁鐣岄潰鏄剧ず ?");
    DdhAttrFieldNote(17, "鍗曚綅绫诲瀷鏁版嵁锛? 绉嶇粍鍚堝叏閮ㄥけ璐ワ紙sight 涓嶅湪 100~5000锛夛紝瑙嗛噹/绉拌皳/鍩虹鏁版嵁涓€寰??");
}

/* spd / sight / nsight / def / points锛氫紭锟?Int锛屾嬁涓嶅埌鍐嶈瘯 Real锟?
   娌￠€変腑缁勫悎锛坓_ddhTypeDataOk = 0锛夊氨涓€锟?native 閮戒笉璋冿紝鐩存帴 false锟?*/
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

/* Propernames 鏂囨湰锛氳繑锟?true = out 閲屾槸鍙敤鏂囨湰锛堟嬁涓嶅埌/绌轰覆杩斿洖 false锛夛拷?*/
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

/* 绫诲瀷鑷甫 Aloc锛熺敤 DzAPI_UnitType_GetUnitTypeDataString(code, "abilList") 鍒ゅ畾骞剁紦瀛橈紙涓嶄緷璧栧彞鏌勶級銆?*/
/* 绫诲瀷鑷甫 Aloc锛熼€愪竴灏濊瘯鍑犵瀛楁鍚嶏紙涓嶅悓 DzAPI 鐗堟湰鍛藉悕涓嶅悓锛夛紝鍛戒腑鍗崇紦瀛樸€?*/
/* 4 瀛楃绫诲瀷鐮?鈫?鍙墦鍗版枃鏈紙鏃ュ織鐢紝浠呮父鎴忕嚎绋嬭皟鐢級 */

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
                LogLine("ATTR锛氱被鍨嬫暟鎹懡涓潡铏?code=%s 瀛楁=%s 鍊?%.120s", DdhCodeText(code), kFields[f], buf);
            return true;
        }
    }
    if (InterlockedIncrement(&g_ddhTypeAlocMissLogged) <= 15)
        LogLine("ATTR锛氱被鍨嬫暟鎹湭鍛戒腑 code=%s 璇诲埌浜?%d 瀛楁璇曡繃 abilList/abil/abilities/AbilityList", DdhCodeText(code), anyOk ? 1 : 0);
    return false;
}



/* 杩斿洖 1/2/4 = 鏂囨湰鏉ユ簮锟?=GetHeroProperName 2=GetUnitName 4=Propernames锛夛紱0 = 娌℃嬁鍒帮拷?*/
static int DdhAttrHeroTitle(uint32_t handle, uint32_t code, char* out, size_t cap)
{
    out[0] = 0;
    if (!code) return 0;

    /* 璇婃柇锛氬墠 8 娆℃妸 handle/obj/绫诲瀷鏁版嵁鐘讹拷?姣忎釜 native 鐨勫師濮嬭繑鍥炲€奸兘鍐欐棩蹇楋拷?
       鍦板浘鑷繁锟?GetHeroProperName 鑳芥嬁鍒版爣棰樸€乨dh 鐩存帴璋冨嵈鎷夸笉鍒版椂锛岃繖鍑犺鑳藉尯锟?
       鈥渘ative 杩斿洖 0锟?锟?鈥滆繑鍥炰簡 id 浣嗗瓧绗︿覆琛ㄥ弽鏌ュけ璐モ€濓拷?*/
    const bool diag = InterlockedIncrement(&g_ddhAttrTitleDiag) <= 8;
    if (diag)
    {
        char type[8] = { 0 };
        DdhAttrTypeCode(code, type);
        const uint32_t dobj = handle ? HpHandleToUnit(handle) : 0;
        LogLine("ATTR 绉拌皳璇婃柇锛歨andle=0x%08X obj=0x%08X code=%s typeDataOk=%d typeDataOrder=%d",
                handle, dobj, type, (int)g_ddhTypeDataOk, (int)g_ddhTypeDataOrder);
    }

    /* 锟?骞冲彴鍗曚綅绫诲瀷鏁版嵁锛歅ropernames锛堟湰鍥剧湡姝ｇ殑涓撳悕鏉ユ簮锟?*/
    {
        const bool tdOk = DdhTypeDataString(handle, code, "Propernames", out, cap);
        if (diag) LogLine("ATTR 绉拌皳璇婃柇锛歅ropernames 杩斿洖=%d text=\"%s\"", (int)tdOk, out);
        if (tdOk)
        {
            DdhAttrFieldNote(0, "绉拌皳 鈫?DzAPI_UnitType_GetUnitTypeDataString(\"Propernames\")");
            return 4;
        }
    }

    if (!handle) return 0;

    /* 鏍囬缂哄け锛圥ropernames 娌℃嬁鍒帮級鎵嶆寕瀛楃涓插叆琛ㄩ挬瀛愶細
       GetHeroProperName 杩斿洖鐨勬槸 string id锛屽彧鏈夋姄鍒板叆琛ㄦ椂锟?char* 鎵嶈兘杩樺師鏍囬锟?*/
    DdhInternHookInstall();

    /* 锟?寮曟搸鑻遍泟涓撳悕 */
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
            LogLine("ATTR 绉拌皳璇婃柇锛欸etHeroProperName(handle=0x%08X) ok=%d eax=0x%08X st0=%.3f resolved=%d text=\"%s\"",
                    handle, (int)ok, eax, (double)st0, resolved, out);
        if (resolved)
        {
            DdhAttrFieldNote(0, "绉拌皳 鈫?GetUnitName锛坰tring id / 鎸囬拡鍙嶆煡鎴愬姛锛?);
            return 1;
        }
        if (ok && eax)
            DdhAttrLogOnce(&g_ddhAttrTitleFailLogged,
                           "GetHeroProperName 杩斿洖 0x%08X锛屼絾瀛楃涓茶〃鍙嶆煡涓嶅埌鏂囨湰 鈫?缁х画璇?GetUnitName",
                           eax);
    }

    /* 锟?GetUnitName锛堝彲鑳芥槸 string id锛屼篃鍙兘鐩存帴锟?char*锟?*/
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
            LogLine("ATTR 绉拌皳璇婃柇锛欸etUnitName(handle=0x%08X) ok=%d eax=0x%08X st0=%.3f resolved=%d text=\"%s\"",
                    handle, (int)ok, eax, (double)st0, resolvedName, out);
        if (resolvedName)
        {
            DdhAttrFieldNote(0, "绉拌皳 鈫?GetUnitName锛坰tring id / 鎸囬拡鍙嶆煡鎴愬姛锛?);
            return 2;
        }
    }

    DdhAttrLogOnce(&g_ddhAttrTitleFailLogged,
                   "绉拌皳锛歅ropernames / GetHeroProperName / GetUnitName 閮芥嬁涓嶅埌鏂囨湰 鈫?绉拌皳鏃犳晥锛堢晫闈㈠彧鏄剧ず鍚嶇О锛?);
    out[0] = 0;
    return 0;
}

/* ===========================================================================
   v15锛氬睘鎬у唴瀛樼洿璇伙紙YDWE unit_property锛夆€旓拷?浼樺厛绾ч珮锟?native
   ---------------------------------------------------------------------------
   鏉ユ簮锛歒DWE 婧愮爜 `Development\Plugin\Warcraft3\yd_jass_api\UnitState.cpp`锟?
     unit_property* ptr = (unit_property*)*(uintptr_t*)(unit_object + 0x1E4 +
                                             (version > version_124c ? 4 : 0));
   鎴戜滑鍙墦 1.27锟? 1.24c锛夛紝鎵€锟?property 鎸囬拡 = *(uint32_t*)(CUnit + 0x1E8)锟?
   unit_property 鐨勭被鍐呭亸绉伙紙鍚屼竴鏂囦欢 73 琛岃捣娉ㄩ噴閲岀殑鍋忕Щ锟?.27 鍙ｅ緞锛夛細
     +0x88  attack1_damage_dice  (int)     +0x94  attack1_damage_side (int)
     +0xA0  attack1_damage_base  (int)     +0xAC  attack1_damage_bonus(int)
     +0x158 attack1_interval     (float)   +0x244 acquisition_range   (float)
     +0x258 attack1_range        (float)
   鎶ょ敳涓嶈蛋 prop锟?(float*)(CUnit + 0xE0)锛圷DWE UNIT_STATE_ARMOR 鏄妸浣嶆ā寮忛€忎紶锟?JASS real锛夛拷?
   鏀诲嚮鍔涙寜 YDWE 鐨勭畻娉曪細min = base + bonus + dice锛宮ax = base + bonus + dice * side锟?
   鎵€鏈夎鍙栭兘锟?__try 閲岋紱璇诲埌鐨勫€煎啀鍋氣€滄湁锟?+ 鑼冨洿鈥濇牎楠岋紝涓嶈繃灏卞綋鏃犳晥锛堢晫锟??锛夛拷?
   鎶ょ敳鐨勭湡瀹炴潵婧愭槸 CUnit+0xE0锛坒loat 浣嶆ā寮忥紝C# 鎵弿鍣ㄨ礋璐ｏ級锟?
   鏈浘 ddh 鐨勬棫 int32 鎶ょ敳璺緞浼氳秺鐣岋紝C# 宸蹭笉鍐嶉噰鐢拷?
   spd / def 锟?DzAPI_UnitType_GetUnitTypeData*锛堢被鍨嬫暟鎹級锛涘崗锟?v14 璧疯閲庢敼锟?jass.slk sight/nsight锟?
   slk 鍙栦笉鍒版椂 sightDay 鎵嶉€€锟?Game.dll+0x3ADF0锟?
   =========================================================================== */
#define DDH_OFF_UNIT_PROP           0x000001E8u  /* CUnit + 0x1E8 = unit_property*锟?.27锟?*/
#define DDH_OFF_UNIT_ARMOR          0x000000E0u  /* CUnit + 0xE0  = 鎶ょ敳锛坒loat锟?*/
#define DDH_OFF_PROP_DMG_DICE       0x00000088u
#define DDH_OFF_PROP_DMG_SIDE       0x00000094u
#define DDH_OFF_PROP_DMG_BASE       0x000000A0u
#define DDH_OFF_PROP_DMG_BONUS      0x000000ACu
#define DDH_OFF_PROP_INTERVAL       0x00000158u
#define DDH_OFF_PROP_ACQUIRE_RANGE  0x00000244u
#define DDH_OFF_PROP_ATTACK_RANGE   0x00000258u

/* 鍚堢悊鎬ц竟鐣岋細涓嶅湪杩欐潯绾块噷鐨勫€间竴寰嬫寜鈥滄病娴嬪埌鈥濆鐞嗭紙鐣岄潰 ?锛夛紝缁濅笉锟?0 鍐掑厖锟?*/
#define DDH_ATTR_RANGE_MAX      5000.0f      /* 鏀诲嚮鑼冨洿 / 涓诲姩鏀诲嚮鑼冨洿锟? ~ 5000 */
#define DDH_ATTR_INTERVAL_MIN   0.05f        /* 鏀诲嚮闂撮殧锟?.05 ~ 10 锟?*/
#define DDH_ATTR_INTERVAL_MAX   10.0f
#define DDH_ATTR_ARMOR_MIN      (-100.0f)    /* 鎶ょ敳锟?100 ~ 1000 */
#define DDH_ATTR_ARMOR_MAX      1000.0f
#define DDH_ATTR_DAMAGE_MAX     1000000.0f   /* 鏀诲嚮鍔涳細0 ~ 1e6 */
#define DDH_ATTR_DICE_MAX       1000         /* dice / side 锟?int 涓婇檺锛堣秴浜嗗氨鏄閿欏唴瀛橈級 */
#define DDH_ATTR_DMG_INT_MAX    1000000      /* base / bonus 锟?int 涓婇檺 */

/* 鏈夐檺鎬э細_finite 姣旇嚜宸卞啓鈥渧 == v鈥濈ǔ锟?O2 涓嶄細锟?NaN 妫€鏌ヤ紭鍖栨帀锛夛拷?*/
static bool DdhAttrIsFinite(float v) { return _finite((double)v) != 0; }

/* 鏈夐檺 + 钀藉湪 [lo, hi]銆傚唴瀛樼洿璇诲拰 native 鐨勭粨鏋滈兘瑕佽繃杩欎竴鍏筹拷?*/
static bool DdhAttrFits(float v, float lo, float hi)
{
    if (!DdhAttrIsFinite(v)) return false;
    return v >= lo && v <= hi;
}

/* CUnit -> unit_property*锟?.27锟?0x1E8锛夈€傝涓嶅埌 / 锟?0 / 涓嶅儚鎸囬拡 / 锟?4 瀛楄妭瀵归綈 锟?0锟?*/
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

/* 鎸囬拡鍙鎬э細unit_property 鏄竴鏁村潡缁撴瀯锛岄灏惧悇璇讳竴锟?dword锛岀‘璁ゆ病璺ㄨ繘鏈槧灏勯〉锟?*/
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

/* 鎶ょ敳锛欳Unit+0xE0 锟?**float** 璇伙紙YDWE UNIT_STATE_ARMOR 锟?4 瀛楄妭浣嶆ā寮忛€忎紶锟?JASS real锟?
   鐪熸満 E06V 锟?0x430DADBB = 141.679锛涙寜 int 璇讳細寰楀埌 1124969915锛岃秺鐣岋級锟?*/
static bool DdhUnitArmor(uint32_t unit, float* out)
{
    if (unit < 0x10000u || unit > 0x7FFFFFFFu || !out) return false;
    float v = 0.0f;
    __try { v = *(const float*)(uintptr_t)(unit + DDH_OFF_UNIT_ARMOR); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    *out = v;
    return true;
}

/* 鏀诲嚮鍔涘叕寮忥紙YDWE 鍚屾锛夛細min = base + bonus + dice锛宮ax = base + bonus + dice * side锟?
   鍏ㄧ▼ 64 浣嶇畻锛岄槻 int 婧㈠嚭锛涚粨鏋滆秺鐣岋紙<0銆乵ax<min锟?1e6锛夊氨褰撹閿欏唴瀛橈拷?*/
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

static volatile LONG g_ddhPropRawLogged = 0;   /* ATTR prop 鍘熷鍊兼棩蹇楀彧鍐欏墠 6 涓崟锟?*/

/* 鍐呭瓨鐩磋涓€閬嶏細鏀诲嚮鑼冨洿 / 鏀诲嚮锟?/ 鏀诲嚮闂撮殧 / 鎶ょ敳 / 涓诲姩鏀诲嚮鑼冨洿锟?
   涓嶄緷锟?JASS 鍙ユ焺锛屾墍浠ュ湪鈥滃彞鏌勬鏌モ€濅箣鍓嶈皟鐢紱璇讳笉鍒版垨涓嶅悎鐞嗗氨浠€涔堥兘涓嶅啓锟?
   鐢卞悗闈㈢殑 native 鍏滃簳锛堢Щ锟?绫诲瀷鍩虹鏁版嵁/鑻遍泟鍒ゅ畾浠嶇劧鍙兘锟?native锛夛拷?*/
static void DdhAttrFillMemory(uint32_t unit, uint32_t prop, bool propOk, DdhUnitAttr* out)
{
    float   mRange = 0.0f, mInterval = 0.0f, mAcquire = 0.0f;
    int32_t mDice = 0, mSide = 0, mBase = 0, mBonus = 0;
    float   mArmor = 0.0f;
    bool okRange = false, okInterval = false, okAcquire = false, okDmg = false, okArmor = false;
    uint32_t okMask = 0;

    if (propOk)
    {
        okRange    = DdhPropF32(prop, DDH_OFF_PROP_ATTACK_RANGE, &mRange);
        okInterval = DdhPropF32(prop, DDH_OFF_PROP_INTERVAL, &mInterval);
        okAcquire  = DdhPropF32(prop, DDH_OFF_PROP_ACQUIRE_RANGE, &mAcquire);
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

    /* ---- 鏀诲嚮鑼冨洿锛坧rop+0x258锟?--- */
    if (okRange && DdhAttrFits(mRange, 0.0f, DDH_ATTR_RANGE_MAX))
    {
        out->attackRange = mRange;
        out->flags |= DDH_AF_ATTACKRANGE;
        DdhAttrFieldNote(1, "鏀诲嚮鑼冨洿 鈫?unit_property+0x258锛堝唴瀛樼洿璇伙級");
    }

    /* ---- 鏀诲嚮鍔涳紙dice/side/base/bonus 閮芥槸 int锟?--- */
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
                        "鏀诲嚮锟?锟?unit_property锛坉ice=%d side=%d base=%d bonus=%d 锟?%.0f~%.0f锛屽唴瀛樼洿璇伙級",
                        (int)mDice, (int)mSide, (int)mBase, (int)mBonus, (double)dmin, (double)dmax);
            DdhAttrFieldNote(2, note);
        }
    }

    /* ---- 鏀诲嚮闂撮殧锛坧rop+0x158锛岀锟?--- */
    if (okInterval && DdhAttrFits(mInterval, DDH_ATTR_INTERVAL_MIN, DDH_ATTR_INTERVAL_MAX))
    {
        out->attackInterval = mInterval;
        out->flags |= DDH_AF_INTERVAL;
        DdhAttrFieldNote(3, "鏀诲嚮闂撮殧 鈫?unit_property+0x158锛堝唴瀛樼洿璇伙紝绉掞級");
    }

    /* ---- 鎶ょ敳锛圕Unit+0xE0锛宖loat锟?--- */
    if (okArmor && DdhAttrFits(mArmor, DDH_ATTR_ARMOR_MIN, DDH_ATTR_ARMOR_MAX))
    {
        out->armor = mArmor;
        out->flags |= DDH_AF_ARMOR;
        char note[160];
        _snprintf_s(note, sizeof(note), _TRUNCATE,
                    "鎶ょ敳 鈫?CUnit+0xE0锛坒loat 鍐呭瓨鐩磋锛屽€?%.2f锛?, (double)mArmor);
        DdhAttrFieldNote(4, note);
    }

    /* ---- 涓诲姩鏀诲嚮鑼冨洿锛坧rop+0x244锟?--- */
    if (okAcquire && DdhAttrFits(mAcquire, 0.0f, DDH_ATTR_RANGE_MAX))
    {
        out->acquireRange = mAcquire;
        out->flags |= DDH_AF_ACQUIRE;
        DdhAttrFieldNote(7, "涓诲姩鏀诲嚮鑼冨洿 鈫?unit_property+0x244锛堝唴瀛樼洿璇伙級");
    }

    /* 鐪熸満鎺掓煡锛氬墠 6 涓崟浣嶆妸 prop 鎸囬拡鍜屽師濮嬪瓧娈靛€兼墦鍑烘潵锛坥k 锟?= 杩欐璇绘垚鍔熺殑瀛楁锟?
       1=鑼冨洿 2=闂撮殧 4=涓诲姩 8=dice/side/base/bonus 16=鎶ょ敳锛夛拷?*/
    if (InterlockedIncrement(&g_ddhPropRawLogged) <= 6)
    {
        if (!propOk)
            LogLine("ATTR prop锛歛ddr=0x%08X prop=0x%08X 涓嶅彲璇伙紙CUnit+0x1E8 锟?0/鍧忔寚锟?鏈榻愶級"
                    "锟?鑼冨洿/鏀诲嚮锟?闂撮殧/涓诲姩 鍏ㄩ儴鏃犳晥锛堣蛋 native 鍏滃簳锛夛紱鎶ょ敳浠嶈瘯 CUnit+0xE0",
                    unit, prop);
        else
            LogLine("ATTR prop锛歛ddr=0x%08X prop=0x%08X ok=0x%02X range=%.2f 闂撮殧=%.3f 涓诲姩=%.1f "
                    "dice/side/base/bonus=%d/%d/%d/%d 鎶ょ敳=%.2f",
                    unit, prop, okMask, (double)mRange, (double)mInterval, (double)mAcquire,
                    (int)mDice, (int)mSide, (int)mBase, (int)mBonus, (double)mArmor);
    }
}

/* ===========================================================================
   v20锛氳锟?= game.dll 鐨勯€氱敤瀛楁璇诲彇鍣紙WFE 閫嗗悜纭锟?.27.0.52240 / build 0xCC10锟?
   v14 璧峰畠鍙槸**鍏滃簳**锛氱櫧锟?澶滄櫄浼樺厛锟?jass.slk 锟?sight/nsight锛圖dhExSlkNumber锛夛紝
   鍙湁 slk sight 鍙栦笉鍒版椂鎵嶇敤杩欓噷锟?sightDay锛泂ightNight 涓嶈瀹冿拷?
   ---------------------------------------------------------------------------
   WFE 锟?Detailed Defense Tip / Draw Sight Radius 璋冪敤鐐癸紙鐓ф妱锛夛細
       mov  eax, [game.dll + 0x3ADF0]     ; 閫氱敤瀛楁璇诲彇鍑芥暟
       lea  ecx, [unit + 0xFC]            ; ecx = 杩愯鏃跺瓧娈垫弿杩扮锛圼+8]=瀛楁 ID銆乕+C]=绫诲瀷锟?
       lea  edx, [ebp-8]                  ; &out
       push edx                           ; 鏍堝弬鏁帮細float* out
       xor  edx, edx                      ; 绗簩鍙傛暟 = 0
       call eax
       movss xmm0, [ebp-8]                ; 锟?褰撳墠鏈夋晥瑙嗛噹锛坒loat锟?
   鍑芥暟鍐呴儴 `mov edx,[ecx+0xC]`锛堝瓧娈电被鍨嬶級/ `mov ecx,[ecx+8]`锛堝瓧锟?ID锛夊埌鍏ㄥ眬瀛楁锟?
   [game.dll + 0xC296A8] 鏌ュ瓧娈靛璞★紝杩斿洖 clamp(鍩虹+鍔犳垚, min, max)銆傛墍锟?out 閲屾槸
   **褰撳墠鏈夋晥瑙嗛噹**锛氭父鎴忓凡鎸夋樇澶滄妸 sight/nsight 閫夊ソ鍐欏洖锛屾槸鍗曞€硷拷?
   娴偣杩斿洖鍊间笉鍙潬锛圗AX/ST0 閮藉埆淇★級锟?*锟?out 鐨勫€间负锟?*锟?
   =========================================================================== */
#define DDH_RVA_SIGHT_FIELD     0x0003ADF0u   /* 1.27.0.52240锛氶€氱敤瀛楁璇诲彇锟?*/
#define DDH_OFF_UNIT_FIELD_DESC 0x000000FCu   /* CUnit + 0xFC = 杩愯鏃跺瓧娈垫弿杩扮 */
#define DDH_ATTR_SIGHT_MIN      100.0f        /* 鍚堢悊瑙嗛噹涓嬮檺锛堜綆浜庡畠鎸夆€滄病娴嬪埌鈥濆鐞嗭級 */
#define DDH_ATTR_SIGHT_MAX      5000.0f       /* 鍚堢悊瑙嗛噹涓婇檺锛堥珮浜庡畠鎸夆€滄病娴嬪埌鈥濆鐞嗭級 */

static uint32_t      g_ddhSightFn        = 0;   /* 瑙ｆ瀽鎴愬姛鐨勫嚱鏁板湴鍧€锟? = 涓嶅彲鐢級 */
static volatile LONG g_ddhSightTried     = 0;   /* 鍙В锟?鏍￠獙涓€锟?*/
static volatile LONG g_ddhSightFailShown = 0;   /* 鈥滀笉鍙敤鈥濆師鍥犲彧鍐欎竴锟?*/
static volatile LONG g_ddhSightOkShown   = 0;   /* 鈥滆锟?锟?鈥︹€濆彧鍦ㄩ娆℃垚鍔熸椂鍐欎竴锟?*/
static volatile LONG g_ddhSightExcCount  = 0;   /* 璋冪敤寮傚父璁℃暟锛堝彧璁板墠 3 鏉★級 */
static volatile LONG g_ddhSightBadCount  = 0;   /* 杩斿洖鍊艰秺鐣岃鏁帮紙鍙锟?3 鏉★級 */

/* 瑙ｆ瀽 + 鏍￠獙 Game.dll+0x3ADF0锟?
   锟?蹇呴』锟?game.dll 鍩哄潃锟?
   锟?RVA 蹇呴』钀藉湪 game.dll 鐨勬槧鍍忓ぇ灏忓唴锛堝亣榄斿吔/鎹㈢増鏈渶甯歌鐨勫け璐ュ師鍥狅級锟?
   锟?鐩爣椤靛繀椤绘槸**宸叉彁浜や笖鍙墽锟?*鐨勶紙.data / 0 濉厖椤典竴寰嬩笉绠楀嚱鏁帮級锟?
   锟?鍓嶅嚑瀛楄妭涓嶈兘锟?0x00 / 0xCC / 0xFF 杩欑被濉厖锛堚€滈潪绌哄疄鐜扳€濓級锟?
   浠讳竴鏉′笉杩囷細鍙湪鏃ュ織閲屽啓涓€琛屽師鍥狅紝涔嬪悗杩欎釜瀛楁涓€寰嬫寜鏃犳晥澶勭悊锛堢晫锟??锛夛紝涓嶅啀閲嶈瘯锟?*/
static bool DdhSightResolveAt(uint32_t rva, uint32_t* outFn, char* why, size_t whyCap)
{
    if (outFn) *outFn = 0;
    if (why && whyCap) why[0] = 0;
    if (!g_modBase)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE, "game.dll 鍩哄潃鏈煡锛圛nstallHook 杩樻病璺戝埌锛?);
        return false;
    }
    if (g_imageSize == 0)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE, "game.dll 鏄犲儚澶у皬鏈煡锛圥E 澶存病璇诲埌锛夛紝涓嶆暍鎸?RVA 璋冨嚱鏁?);
        return false;
    }

    const uint32_t addr = g_modBase + rva;
    if (rva + 16u > g_imageSize)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE,
                             "RVA 0x%X 瓒呭嚭 game.dll 鏄犲儚澶у皬 0x%X锛堣繖涓?game.dll 閲屾病鏈夎鍑芥暟锛?,
                             rva, g_imageSize);
        return false;
    }

    /* 鍙墽琛岄〉鏍￠獙锟?data / 鏈彁浜ら〉 / 0 濉厖閮戒笉绠楀嚱鏁帮紝缁濅笉锟?call锟?*/
    MEMORY_BASIC_INFORMATION mbi;
    memset(&mbi, 0, sizeof(mbi));
    if (VirtualQuery((LPCVOID)(uintptr_t)addr, &mbi, sizeof(mbi)) == 0 || mbi.State != MEM_COMMIT)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE,
                             "0x%08X 涓嶆槸宸叉彁浜ゅ唴瀛橈紙VirtualQuery 澶辫触 / 椤垫湭鎻愪氦锛?, addr);
        return false;
    }
    const DWORD prot = mbi.Protect & 0xFFu;
    if (prot != PAGE_EXECUTE && prot != PAGE_EXECUTE_READ &&
        prot != PAGE_EXECUTE_READWRITE && prot != PAGE_EXECUTE_WRITECOPY)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE,
                             "0x%08X 椤典笉鍙墽琛岋紙Protect=0x%X锛屾槸鏁版嵁椤?绌烘礊锛屼笉鏄嚱鏁帮級",
                             addr, (unsigned)mbi.Protect);
        return false;
    }

    uint32_t head = 0;
    if (!PeekU32(addr, &head))
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE, "0x%08X 璇讳笉鍒板墠 4 瀛楄妭", addr);
        return false;
    }
    const uint8_t* p = (const uint8_t*)&head;
    if (p[0] == 0x00 || p[0] == 0xCC || p[0] == 0xFF || head == 0x00000000u || head == 0xCCCCCCCCu)
    {
        if (why) _snprintf_s(why, whyCap, _TRUNCATE,
                             "搴忚█鍍忓～鍏咃紙%02X %02X %02X %02X锛夛紝涓嶆槸鏈夋晥鍑芥暟",
                             p[0], p[1], p[2], p[3]);
        return false;
    }

    if (outFn) *outFn = addr;
    return true;
}

/* 鎳掕В鏋愪竴娆★紙鎴愬姛/澶辫触閮藉彧鍋氫竴娆★紱澶辫触鍘熷洜鍙啓涓€琛屾棩蹇楋級 */
static bool DdhSightFnReady(void)
{
    if (InterlockedCompareExchange(&g_ddhSightTried, 1, 0) != 0)
        return g_ddhSightFn != 0;

    uint32_t fn = 0;
    char why[192] = { 0 };
    if (!DdhSightResolveAt(DDH_RVA_SIGHT_FIELD, &fn, why, sizeof(why)))
    {
        DdhAttrLogOnce(&g_ddhSightFailShown,
                       "瑙嗛噹锛欸ame.dll+0x%X 涓嶅彲鐢紙%s锛夆啋 瑙嗛噹鏃犳晥锛堢晫闈??锛?,
                       (unsigned)DDH_RVA_SIGHT_FIELD, why);
        return false;
    }
    g_ddhSightFn = fn;
    LogLine("ATTR 瑙嗛噹锛欸ame.dll+0x%X 閫氱敤瀛楁璇诲彇鍣ㄥ凡瑙ｆ瀽锛?x%08X锛屾槧鍍忓ぇ灏?0x%X锛?,
            (unsigned)DDH_RVA_SIGHT_FIELD, fn, g_imageSize);
    return true;
}

/* 璋冧竴娆￠€氱敤瀛楁璇诲彇鍣細ecx = &CUnit+0xFC銆乪dx = 0銆佹爤锟?float* out锛堜弗鏍兼寜 WFE 璋冪敤鐐癸級锟?
   鏀跺熬锟?`mov esp, ebp` 寮哄埗鎭㈠鑷繁鐨勫抚锛氳璋冩柟鍒板簳 ret 杩樻槸 ret 4锛堟竻鏍堝弬鏁帮級閮戒笉浼氭妸
   鎴戜滑鐨勬爤寮勫潖锛涗篃涓嶅崰鐢ㄤ换锟?callee-saved 瀵勫瓨鍣拷?*/
static __declspec(naked) void DdhSightCallAsm(uint32_t fn, uint32_t desc, float* out)
{
    __asm
    {
        push ebp
        mov  ebp, esp
        push dword ptr [ebp + 16]      /* 鏍堝弬鏁帮細float* out */
        xor  edx, edx                  /* 绗簩鍙傛暟 = 0锛圵FE 璋冪敤鐐瑰悓娆撅級 */
        mov  ecx, dword ptr [ebp + 12] /* &CUnit+0xFC锛堣繍琛屾椂瀛楁鎻忚堪绗︼級 */
        call dword ptr [ebp + 8]       /* Game.dll+0x3ADF0 */
        mov  esp, ebp                  /* 涓嶇琚皟鏂规湁娌℃湁 ret 4锛岄兘鎸夎嚜宸辩殑甯ф仮锟?esp */
        pop  ebp
        ret
    }
}

/* 璇讳竴涓崟浣嶇殑鈥滃綋鍓嶆湁鏁堣閲庘€濓細鎴愬姛 锟?true 锟?*outSight = 鍊硷紙100~5000锛夛拷?
   澶辫触锛堝嚱鏁颁笉鍙敤 / 璋冪敤寮傚父 / 杩斿洖鍊艰秺鐣岋級锟?false锛堣閲庢棤鏁堬紝鐣岄潰 ?锛夛紝鍘熷洜鍐欐棩蹇楋拷?
   鍙 out锛屼笉淇℃诞鐐硅繑鍥炲€硷紙WFE 缁撹锛夛拷?*/
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
            LogLine("ATTR锛氳閲庤鍙栧紓甯?code=0x%08X锛坲nit=0x%08X &unit+0xFC=0x%08X锛夆啋 瑙嗛噹鏃犳晥锛堢晫闈??锛?,
                    (unsigned)exc, unit, unit + DDH_OFF_UNIT_FIELD_DESC);
        return false;
    }
    if (!DdhAttrFits(v, DDH_ATTR_SIGHT_MIN, DDH_ATTR_SIGHT_MAX))
    {
        if (InterlockedIncrement(&g_ddhSightBadCount) <= 3)
            LogLine("ATTR锛氳閲庤繑鍥炲€艰秺鐣岋紙unit=0x%08X out=%.3f锛屽悎鐞嗚寖鍥?%.0f~%.0f锛夆啋 瑙嗛噹鏃犳晥锛堢晫闈??锛?,
                    unit, (double)v, (double)DDH_ATTR_SIGHT_MIN, (double)DDH_ATTR_SIGHT_MAX);
        return false;
    }
    *outSight = v;
    return true;
}

/* ===========================================================================
   v20锛歫ass.slk 浜ゅ弶鏍稿 / 瑙嗛噹鍏滃簳锛圗XExecuteScript锟?
   ---------------------------------------------------------------------------
   鏈浘锟?YDWE 锟?jass.slk Lua 妯″潡锛屽彲浠ョ敤鍘熺敓 EXExecuteScript 鎸夊瓧娈靛悕璇讳换锟?slk锟?
       EXExecuteScript("(require'jass.slk').unit[<绫诲瀷 id 鍗佽繘锟?].<瀛楁锟?")
   绫诲瀷 id 灏辨槸绫诲瀷鐮佺殑鍗佽繘鍒讹紙'H038' = 0x48303338 = 1210079032锛夛拷?
   瀹炲弬褰㈠紡涓嶅啀鍐欐锛歷22 锟?"1+1" 鎺㈤拡鍦ㄥ紩锟?id / 锟?char* / string_fake 绛夊舰寮忛噷閫変竴锟?
   锛坴23 澧炲姞 string_fake 涓夌 + 寮曟搸 id 鍙嶆煡 char*锛夛紝閫変腑锟?sight/nsight/spd/def 缁熶竴璧板畠锟?
   杩斿洖鍊兼棦鍙兘锟?string id 涔熷彲鑳芥槸 string_fake 鎸囬拡锛屼袱绉嶅舰鎬侀兘瑙ｏ紱
     路 鎵€鏈夎皟鐢ㄥ彧鍦ㄦ父鎴忕嚎绋嬶紙灞炴€ц姹傞€氶亾锛夐噷鍋氾紝琛ㄨ揪寮忛暱锟?< 160锟?
   v22锛堢湡锟?ddh-4848.log锛氬洓绉嶅瓧锟?EX 鍏ㄨ繑锟?eax=0锛夛細鍏堢敤鎺㈤拡鎶娾€滃疄鍙傚舰寮忊€濅笌
   鈥滆〃杈惧紡/typeId 鍐欐硶鈥濆垎寮€瀹氫綅锛圖dhExFormProbe锛夛紝楠岃瘉閫氳繃鐨勫舰寮忔墠鏄箣锟?
   sight/nsight/spd/def 鐢ㄧ殑閭ｄ竴绉嶏紱涓€绉嶉兘涓嶉€氬氨淇濇寔鐜扮姸锛堝紩锟?id + 鏁板瓧涓嬫爣锛夛拷?
   鏈潡鍙仛涓や欢浜嬶細
     锟?姣忚繘绋嬩竴娆℃牳锟?sight / nsight / spd / def锛堝啓鏃ュ織锛屼笉鏀瑰瓧娈碉級锟?
     锟?瑙嗛噹锟?*涓昏矾**锛氭寜绫诲瀷鐮佽 jass.slk 锟?sight锛堢櫧澶╄閲庯級锟?nsight锛堝鏅氳閲庯級锟?
        slk 鍙栦笉鍒版椂鎵嶉€€锟?Game.dll+0x3ADF0 鐨勨€滃綋鍓嶆湁鏁堣閲庘€濆～ sightDay锟?
        sightNight 淇濇寔鏃犳晥锛堢晫锟??锛夛拷?
   EXExecuteScript 鏄湴锟?JAPI 娉ㄥ唽锟?native锛涙病锟?jass.slk 妯″潡鐨勫浘锛堝惈鍋囬瓟鍏斤級鎵句笉鍒帮紝
   鍙啓鈥滄湭鎵惧埌鈥濓紝涓嶅奖鍝嶄换浣曞瓧娈碉拷?
   =========================================================================== */
#define DDH_EX_EXPR_MAX     160
#define DDH_EX_TEXT_MAX     128
#define DDH_EX_SLK_CACHE    24       /* 鎸夌被鍨嬬爜缂撳瓨 sight/nsight 涓ゅ瓧锟?*/
#define DDH_EX_SLK_CALLS    48       /* 24 绫诲瀷 脳 2 瀛楁锛氭湰杩涚▼鏈€澶氭煡杩欎箞澶氭 */
/* ---- v22/v23锛欵XExecuteScript 鐨勨€滃疄鍙傚舰锟?/ 琛ㄨ揪寮忓舰寮忥拷?------------------------
   鐪熸満 ddh-4848.log锛歴ight/nsight/spd/def 鍥涚瀛楁锟?EXExecuteScript 鍏ㄨ繑锟?eax=0锟?
   璇存槑闂涓嶅湪瑙ｆ瀽锛岃€屽湪**璋冪敤鏈韩娌¤繑锟?*銆備袱绉嶅彲鑳斤細
     锟?瀹炲弬褰㈠紡涓嶅锛氬紩锟?string id / 锟?const char* / string_fake 瀵硅薄鎸囬拡锛熻涓嶈绗簩涓弬鏁帮紵
     锟?琛ㄨ揪锟?typeId 涓嶅锛歶nit[鍗佽繘鍒禲 杩樻槸 unit["H038"]锟?sight 杩樻槸 ["sight"]锟?
   鎺㈤拡鐢ㄤ竴涓繀鐒舵垚鍔熺殑甯搁噺琛ㄨ揪锟?"1+1"锛圠ua 姹傦拷?= 2锛夊尯鍒嗗疄鍙傚舰寮忥細
     A1 = 寮曟搸 string id锟? 鍙傦紝绗簩锟?0锛岀幇鐘讹級     A2 = 锟?const char*锛堝悓涓婏級
     A3 = 寮曟搸 string id锛堢浜屽弬 1锟?               A4 = 锟?const char*锛堢浜屽弬 1锟?
     A5 = 寮曟搸 string id锛堝彧锟?1 涓弬鏁帮級           A6 = 锟?const char*锛堝彧锟?1 涓弬鏁帮級
   鐪熸満 ddh-9128.log锛欰1~A6 鍏ㄥけ璐ワ紙寮曟搸 id 锟?0xC0000005銆佽８ char* 杩斿洖 0锛夆啋 v23 杩藉姞锟?
     A7  = string_fake 瀵硅薄鎸囬拡锟?0x08 鑷寚锟?0x1C 姝ｆ枃锟? 绗簩锟?0
     A8  = string_fake 瀵硅薄鎸囬拡 + 绗簩锟?1
     A9  = string_fake 瀵硅薄鎸囬拡锛屽彧锟?1 涓弬锟?
     A10 = 寮曟搸 string id 鍙嶆煡鍑虹殑 char*锛坋ngine-pool锛岀浜屽弬 0锛汚7~A9 鍏ㄥけ璐ユ墠璇曪級
   鍐嶇敤 slk 琛ㄨ揪寮忓尯鍒嗗啓娉曪紙B 缁勶紝鍏ㄩ儴锟?A 缁勯€変腑鐨勫疄鍙傚舰寮忥級锟?
     B1 = unit[鍗佽繘鍒禲.sight锛堢幇鐘跺啓娉曪紝鐪熷疄 sight 琛ㄨ揪寮忥級
     B2 = 浠呭綋閫変腑寮曟搸 id 鏃讹紝鐢ㄨ８ char* 鍐嶈窇涓€娆″悓涓€鍐欐硶锛堟棫鏃ュ織瀵圭収锟?
     B3 = unit["H038"].sight   B4 = unit[鍗佽繘鍒禲["sight"]   B5 = unit["H038"]["sight"]
   姣忕涓€锟?EXFORM <鏍囩> form=... arg=... -> eax=... text="..." num=...锟?
   鎷垮埌 2 鐨勯偅涓€绉嶅氨鏄彲鐢ㄥ舰寮忥紝鍐欌€滈噰鐢ㄥ疄鍙傚舰寮忊€濓紝涔嬪悗 sight/nsight/spd/def 閮界敤瀹冿拷?*/
#define DDH_EX_FORM_NONE    0
#define DDH_EX_FORM_ID      1   /* 寮曟搸 string id + 绗簩锟?0锛堢幇鐘讹級 */
#define DDH_EX_FORM_PTR     2   /* 锟?const char* + 绗簩锟?0 */
#define DDH_EX_FORM_ID_A2   3   /* 寮曟搸 string id + 绗簩锟?1 */
#define DDH_EX_FORM_PTR_A2  4   /* 锟?const char* + 绗簩锟?1 */
#define DDH_EX_FORM_ID_1    5   /* 寮曟搸 string id锛屽彧锟?1 涓弬锟?*/
#define DDH_EX_FORM_PTR_1   6   /* 锟?const char*锛屽彧锟?1 涓弬锟?*/
#define DDH_EX_FORM_FAKE    7   /* string_fake 瀵硅薄鎸囬拡 + 绗簩锟?0 */
#define DDH_EX_FORM_FAKE_A2 8   /* string_fake 瀵硅薄鎸囬拡 + 绗簩锟?1 */
#define DDH_EX_FORM_FAKE_1  9   /* string_fake 瀵硅薄鎸囬拡锛屽彧锟?1 涓弬锟?*/
#define DDH_EX_FORM_ENG_PTR 10  /* 寮曟搸 string id 鍙嶆煡鍑虹殑 char* + 绗簩锟?0 */

#define DDH_EX_EXPR_NUM_DOT 0   /* (require'jass.slk').unit[12345].sight锛堢幇鐘讹級 */
#define DDH_EX_EXPR_STR_DOT 1   /* (require'jass.slk').unit["H038"].sight */
#define DDH_EX_EXPR_NUM_BRK 2   /* (require'jass.slk').unit[12345]["sight"] */
#define DDH_EX_EXPR_STR_BRK 3   /* (require'jass.slk').unit["H038"]["sight"] */

/* 锟?char* 褰㈠紡鐢ㄧ殑闈欐€佺紦鍐诧紙ddh 鑷繁锟?.data锛屼繚璇佸彲璇汇€佸湴鍧€绋冲畾锛夛拷?*/
static char          g_ddhExArgText[DDH_EX_EXPR_MAX + 8];
static volatile LONG g_ddhExArgForm       = DDH_EX_FORM_ID;        /* 宸查獙璇佸彲鐢ㄧ殑瀹炲弬褰㈠紡 */
static volatile LONG g_ddhExExprForm      = DDH_EX_EXPR_NUM_DOT;   /* 宸查獙璇佸彲鐢ㄧ殑琛ㄨ揪寮忓舰锟?*/
static volatile LONG g_ddhExFormProbeDone = 0;
static volatile LONG g_ddhExLastExc       = 0;

static const char* DdhExFormName(int form)
{
    switch (form)
    {
    case DDH_EX_FORM_ID:     return "寮曟搸id/2鍙?绗簩鍙?)";
    case DDH_EX_FORM_PTR:    return "char*/2鍙?绗簩鍙?)";
    case DDH_EX_FORM_ID_A2:  return "寮曟搸id/2鍙?绗簩鍙?)";
    case DDH_EX_FORM_PTR_A2: return "char*/2鍙?绗簩鍙?)";
    case DDH_EX_FORM_ID_1:   return "寮曟搸id/1鍙?;
    case DDH_EX_FORM_PTR_1:  return "char*/1鍙?;
    case DDH_EX_FORM_FAKE:    return "string_fake/2鍙?绗簩鍙?)";
    case DDH_EX_FORM_FAKE_A2: return "string_fake/2鍙?绗簩鍙?)";
    case DDH_EX_FORM_FAKE_1:  return "string_fake/1鍙?;
    case DDH_EX_FORM_ENG_PTR: return "char*(engine-pool)/2鍙?绗簩鍙?)";
    default:                 return "?";
    }
}

static const char* DdhExExprName(int form)
{
    switch (form)
    {
    case DDH_EX_EXPR_NUM_DOT: return "unit[鍗佽繘鍒禲.瀛楁锛堢幇鐘讹級";
    case DDH_EX_EXPR_STR_DOT: return "unit[绫诲瀷鐮乚.瀛楁";
    case DDH_EX_EXPR_NUM_BRK: return "unit[鍗佽繘鍒禲[瀛楁]";
    case DDH_EX_EXPR_STR_BRK: return "unit[绫诲瀷鐮乚[瀛楁]";
    default:                  return "鑶?;
    }
}

/* 1 涓弬鏁扮殑 cdecl 璋冪敤锛堝彧锟?1 涓弬鏁帮級锛氬厛淇濆瓨 EBX/ESI锛岃皟鐢ㄥ悗**锟?EBP 鎭㈠ ESP**
   锛堣璋冩柟锟?stdcall / ret 4 涔熶笉浼氭妸鏍堟悶涔憋級锛屽啀锟?EAX 锟?ST(0)锟?*/
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
        lea  esp, [ebp - 8]                 /* 涓嶇琚皟鏂规€庝箞娓呮爤锛岄兘鍥炲埌鑷繁鐨勫抚 */
        mov  dword ptr [ebx], eax
        fstp dword ptr [esi]
        pop  esi
        pop  ebx
        pop  ebp
        ret
    }
}

/* 2 涓弬鏁扮殑 cdecl 璋冪敤锛屽悓鏍风敤 EBP 鎭㈠ ESP锛堟帰閽堜笓鐢紱涓嶅姩鍘熸潵锟?DdhNatCallAsm锛夛拷?*/
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
        lea  esp, [ebp - 8]                 /* 锟?DdhNatCall1Asm */
        mov  dword ptr [ebx], eax
        fstp dword ptr [esi]
        pop  esi
        pop  ebx
        pop  ebp
        ret
    }
}

/* 鎸変竴绉嶁€滃疄鍙傚舰寮忊€濊皟涓€锟?EXExecuteScript锟?
   杩斿洖 0 = 瀹炲弬娌￠€犲嚭鏉ワ紙娌¤皟锛夛紱1 = 璋冮€氾紱2 = 璋冪敤寮傚父锛坋ax/st0 娓呴浂锛宑ode 锟?g_ddhExLastExc锛夛拷?
   argOut 甯﹀洖鐪熸鍘嬭繘鍘荤殑绗竴涓疄鍙傦紙鎺㈤拡鏃ュ織鐢級锟?
   ID 褰㈠紡锟?0x1DA520 閫犵湡寮曟搸 string id锛汸TR 褰㈠紡锟?ddh 鑷繁鐨勯潤鎬佺紦鍐诧拷?*/
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
        DdhInternHookInstall();          /* 鎶撳埌 EX 杩斿洖涓茬殑 id -> 鏂囨湰锛堣杩囧氨鐩存帴杩斿洖锟?*/
        arg = DdhMakeEngineStringId(expr);
        if (!arg) return 0;              /* 0x1DA520 娌＄粰锟?string id */
    }
    else if (form == DDH_EX_FORM_FAKE || form == DDH_EX_FORM_FAKE_A2 ||
             form == DDH_EX_FORM_FAKE_1)
    {
        /* string_fake 瀵硅薄鎸囬拡锟?0x08 鎸囧悜鑷韩锟?0x1C 锟?char* 姝ｆ枃锟?
           姣忔璋冪敤鍓嶉噸鏂版瀯閫狅紙寮曟搸鍙兘鏀瑰啓杩欎釜瀵硅薄锛屼笉鑳藉鐢ㄤ笂涓€娆＄殑鎸囬拡锛夛拷?*/
        arg = DdhMakeJassString(expr);
        if (!arg) return 0;
    }
    else if (form == DDH_EX_FORM_ENG_PTR)
    {
        /* 寮曟搸 string id -> char*锛堢幇鏈夊弽鏌ワ紱鐪熸満 JASS 涓插彲鑳藉彧鍛戒腑 intern 缂撳瓨鍓湰锛夛拷?*/
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

/* v14锛氫竴涓被鍨嬬爜涓€鏉★紝sight / nsight 鍚勪竴浠界姸鎬佷笌鏁板€硷拷?
   state锟? = 杩樻病鏌ワ紱1 = 鍙敤锟?1 = 鏌ヨ繃浣嗗け璐ワ紙鏈繘绋嬩笉鍐嶉噸璇曪級锟?
   raw 淇濈暀鏌ヨ鍘熸枃锛屽け璐ユ椂鍐欐棩蹇楃敤锟?*/
struct DdhExSlkEntry
{
    uint32_t code;
    int      sightState;
    float    sight;
    int      nightState;
    float    night;
    int      sightSrc;          /* 鏁板€兼潵婧愶細鏂囨湰 / S2R / S2I锛堟棩蹇楃敤锟?*/
    int      nightSrc;
    char     sightRaw[48];
    char     nightRaw[48];
    char     sightWhy[64];      /* 澶辫触鍘熷洜锛圫2R/S2I 涓嶅彲鐢ㄣ€佽秺鐣屸€︼級 */
    char     nightWhy[64];
};
static DdhExSlkEntry g_ddhExSlkCache[DDH_EX_SLK_CACHE];
static int           g_ddhExSlkCacheCount = 0;
static int           g_ddhExSlkCacheNext  = 0;
static int           g_ddhExSlkCalls      = 0;

/* 鎳掕В锟?EXExecuteScript锛氭渶锟?20 娆°€佹瘡娆¤嚦灏戦棿锟?500ms锛堝悓涓€锟?96 涓崟浣嶄笉浼氭墦鐖嗭級锟?
   澶辫触/鎴愬姛鍚勫彧璁颁竴琛岋拷?*/
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
            LogLine("ATTR EX锛欵XExecuteScript 宸插畾浣嶏紙0x%08X锛?, fn);
        return fn;
    }
    if (tries == 1 && InterlockedIncrement(&g_ddhExMissLog) == 1)
        LogLine("ATTR EX锛欵XExecuteScript 鏈壘鍒帮紙宸茶瘯 20 娆★級鈫?涓嶅仛 slk 鏍稿锛岃閲庝繚鎸佸師閫昏緫");
    else if (tries == 20)
        LogLine("ATTR EX锛欵XExecuteScript 鏈壘鍒帮紙宸茶瘯 20 娆★級鈫?涓嶅仛 slk 鏍稿锛岃閲庝繚鎸佸師閫昏緫");
    return 0;
}

/* v21锛氬瓧绗︿覆 id 鐩存帴杞暟鍊硷紙S2R / S2I锛夛拷?
   鐪熸満鐜拌薄锛欵XExecuteScript 璋冪敤鎴愬姛锛屼絾杩斿洖锟?string id 鍙嶆煡涓嶅埌鏂囨湰锛坮aw=""锛夛拷?
   涓嶅啀渚濊禆 id鈫掓枃鏈細鐩存帴锟?id 浼犵粰 JASS 鍘熺敓锟?
     S2R(string) -> real    锛堜紭鍏堬級
     S2I(string) -> integer 锛堝厹搴曪級
   鍚勮嚜鎳掕В鏋愶細鏈€锟?20 娆°€佹瘡娆¤嚦灏戦棿锟?500ms锛堣繘鍥惧墠 JASS VM 鍙兘杩樻病濂斤級锟?
   宸插畾锟?鏈壘鍒板悇鍙啓涓€琛屾棩蹇楋拷?*/
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
            LogLine("ATTR EX锛歋2R native 宸插畾浣嶏紙0x%08X锛夆啋 鏂囨湰涓虹┖鏃舵妸瀛楃涓?id 鐩存帴杞?real", fn);
        return fn;
    }
    if (tries == 20 && InterlockedIncrement(&g_ddhS2RLogged) == 1)
        LogLine("ATTR EX锛歋2R native 鏈壘鍒帮紙宸茶瘯 20 娆★級鈫?鏂囨湰涓虹┖鏃跺彧璇?S2I");
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
            LogLine("ATTR EX锛歋2I native 宸插畾浣嶏紙0x%08X锛夆啋 S2R 涓嶅彲鐢?涓嶅悎鐞嗘椂鎶婂瓧绗︿覆 id 杞暣鏁?, fn);
        return fn;
    }
    if (tries == 20 && InterlockedIncrement(&g_ddhS2ILogged) == 1)
        LogLine("ATTR EX锛歋2I native 鏈壘鍒帮紙宸茶瘯 20 娆★級鈫?鏂囨湰涓虹┖涓?S2R 涓嶈鏃?slk 鎸夊け璐ュ鐞?);
    return 0;
}

/* 涓ユ牸鏁板瓧鏍￠獙锛氬彧鎺ュ彈 [+-]digits[.digits]锛堝厑璁搁灏剧┖鏍硷級锛屾暟鍊兼湰韬粛锟?atof锟?*/
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

/* 鏋勶拷?jass.slk 锟?Lua 琛ㄨ揪寮忥紝鍥涚鍐欐硶锛堣 DDH_EX_EXPR_*锛夛紝閮芥槸 ASCII锟?
     鏁板瓧涓嬫爣 = 绫诲瀷鐮佺殑鍗佽繘鍒讹紙'H038' = 0x48303338 = 1210079032锛夛紱
     瀛楃涓蹭笅锟?= 4 瀛楃绫诲瀷鐮侊紱瀛楁鍐欐硶 .sight 锟?["sight"]锟?
   闀垮害妫€鏌ヤ笉閫氳繃灏辨斁寮冿紙涓嶆埅鏂〃杈惧紡锛屾埅鏂殑 Lua 涓€瀹氳В鏋愬け璐ワ級锟?*/
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

/* 鎸夆€滃凡楠岃瘉鍙敤鐨勮〃杈惧紡褰㈠紡鈥濇瀯閫狅紙鎺㈤拡璺戜箣鍓嶅氨鏄幇鐘讹細鏁板瓧涓嬫爣 + .瀛楁锛夛拷?*/
static bool DdhExBuildExpr(uint32_t typeId, const char* field, char* out, size_t cap)
{
    return DdhExBuildExprForm((int)g_ddhExExprForm, typeId, field, out, cap);
}

/* 鍙栦竴锟?slk 瀛楁鐨勫師鏂囷細EXExecuteScript(锟?string id) -> 杩斿洖鍊兼寜 id/鎸囬拡涓ょ褰㈡€佽В锟?
   杩斿洖 false = native 涓嶅彲锟?/ 璋冪敤寮傚父 / 娌¤В鍑烘枃鏈紱raw 閲屽敖閲忕暀璇婃柇鏂囨湰锟?
   retId 闈炵┖鏃跺甫锟?EX 鐨勫師濮嬭繑鍥炲€硷紙瀛楃锟?id锛夛細鏂囨湰瑙ｄ笉鍑烘潵鏃剁洿鎺ュ杺锟?S2R/S2I锟?*/
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
        LogLine("ATTR EX锛氳〃杈惧紡瓒呴暱/鏋勯€犲け璐ワ紙绫诲瀷=%u 瀛楁=%s锛夛紝鏈涓嶆煡", typeId, field);
        return false;
    }

    /* 瀹炲弬褰㈠紡鐢ㄦ帰閽堬紙DdhExFormProbe锛夐獙璇佽繃鐨勯偅涓€绉嶏細寮曟搸 id / 锟?char* /
       string_fake 瀵硅薄鎸囬拡 / 寮曟搸 id 鍙嶆煡 char* 閮藉彲鑳斤紱鍏蜂綋锟?g_ddhExArgForm锟?*/
    const int form = (int)g_ddhExArgForm;
    uint32_t eax = 0;
    float    st0 = 0.0f;
    const int rc = DdhExCallForm(fn, form, expr, NULL, &eax, &st0);
    if (rc == 0)
    {
        if (InterlockedIncrement(&g_ddhExExprFailLog) == 1)
            LogLine("ATTR EX锛氳〃杈惧紡瀹炲弬鏋勯€犲け璐ワ紙褰㈠紡=%s锛?x1DA520 娌＄粰鍑?string id锛夛紝鏈涓嶆煡",
                    DdhExFormName(form));
        return false;
    }
    if (rc != 1 || !eax) return false;
    if (retId) *retId = eax;   /* 鏂囨湰瑙ｄ笉鍑烘潵锟?S2R/S2I 杩樿鐢ㄨ繖锟?id */

    int got = DdhAttrTextFromIdOrPtr(eax, raw, cap);
    if (!got) got = DdhTypeDataText(eax, raw, cap) ? 1 : 0;
    return got != 0 && raw[0] != 0;
}

/* jass.slk 鐨勬枃鏈瓧娈碉紙Art/Icon锛夎鍙栵紱娌℃湁 EX/JASS slk 妯″潡鏃惰繑锟?false锟?*/
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

/* slk 鏁板€兼潵婧愶紙鏃ュ織閲屽啓娓呮璧扮殑鏄摢鏉★級锟?*/
#define DDH_EX_NUM_NONE 0
#define DDH_EX_NUM_TEXT 1
#define DDH_EX_NUM_S2R  2
#define DDH_EX_NUM_S2I  3

static const char* DdhExNumSourceName(int src)
{
    switch (src)
    {
    case DDH_EX_NUM_TEXT: return "鏂囨湰";
    case DDH_EX_NUM_S2R:  return "S2R";
    case DDH_EX_NUM_S2I:  return "S2I";
    default:              return "鑶?;
    }
}

/* S2R(string id) -> real锛氭寜 C 娴偣绾﹀畾锟?ST(0)锛屽啀锟?EAX 閲岀殑 float 浣嶆ā锟?
   锛堥儴锟?JAPI 鐢ㄥ悗鑰咃級銆傚彧鎺ュ彈钀藉湪 [lo,hi] 鐨勬湁闄愭暟锛涘叏锟?__try锟?*/
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

/* S2I(string id) -> integer锛氬厛鎸夋暣锟?EAX 璁わ紝鍐嶈 float 浣嶆ā锟?/ ST(0)锟?*/
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

/* 鍙栦竴锟?slk 瀛楁鐨勬暟鍊硷細
     锟?EX 杩斿洖鏂囨湰 锟?鐜版湁 atof 瑙ｆ瀽锛圖dhExParseNumber锛夛紱
     锟?鏂囨湰涓虹┖/涓嶆槸鏁板瓧/瓒婄晫 锟?S2R(EX 鐨勫瓧绗︿覆 id)锟?
     锟?S2R 涓嶅彲鐢ㄦ垨杩斿洖涓嶅悎锟?锟?S2I(鍚屼竴锟?id)锟?
   缁撴灉蹇呴』閫氳繃 [lo,hi] 鑼冨洿鏍￠獙锛況awOut 鍥炲～鍘熷杩斿洖鍊硷紙璇婃柇鐢級锟?
   whyOut 鍥炲～澶辫触鍘熷洜锛圫2R/S2I 涓嶅彲鐢ㄣ€佽繑鍥炲€艰秺鐣岀瓑锛夛拷?*/
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

    /* 锟?鏂囨湰璺紙鐜扮姸锟?*/
    float v = 0.0f;
    char  textWhy[64] = { 0 };
    if (textOk && DdhExParseNumber(raw, &v))
    {
        if (DdhAttrFits(v, lo, hi)) { *out = v; return DDH_EX_NUM_TEXT; }
        _snprintf_s(textWhy, sizeof(textWhy), _TRUNCATE,
                    "鏂囨湰=%.0f 瓒婄晫锛?.0f~%.0f锛?, (double)v, (double)lo, (double)hi);
    }
    else if (raw[0])
    {
        strncpy_s(textWhy, sizeof(textWhy), "鏂囨湰涓嶆槸鏁板瓧", _TRUNCATE);
    }

    if (!retId)
    {
        if (whyOut && whyCap)
        {
            if (textWhy[0]) _snprintf_s(whyOut, whyCap, _TRUNCATE, "%s锛孍X 鏈繑鍥炲瓧绗︿覆 id", textWhy);
            else            _snprintf_s(whyOut, whyCap, _TRUNCATE, "EX 鏈繑鍥炲瓧绗︿覆 id");
        }
        return DDH_EX_NUM_NONE;
    }

    /* 涓や釜 native 涓€璧锋噿瑙ｆ瀽锛堝悇鍙涓€琛屸€滃凡瀹氫綅/鏈壘鍒扳€濓級锛涘厛锟?S2R锛屼笉琛屽啀 S2I锟?*/
    const uint32_t s2r = DdhExS2RNative();
    const uint32_t s2i = DdhExS2INative();

    /* 锟?S2R锛堜紭鍏堬級 */
    if (s2r)
    {
        float sv = 0.0f;
        if (DdhExCallS2R(retId, lo, hi, &sv)) { *out = sv; return DDH_EX_NUM_S2R; }
    }

    /* 锟?S2I锛堝厹搴曪級 */
    if (s2i)
    {
        float iv = 0.0f;
        if (DdhExCallS2I(retId, lo, hi, &iv)) { *out = iv; return DDH_EX_NUM_S2I; }
    }

    /* 涓ゆ潯 native 閮藉け璐ワ細鎶婂師鍥犲啓娓呮锛坮aw 鐢辫皟鐢ㄦ柟鍙﹀鎵撳嵃锟?*/
    if (whyOut && whyCap)
    {
        const char* tail = (!s2r && !s2i) ? "S2R/S2I 閮戒笉鍙敤"
                         : (!s2r)         ? "S2I 杩斿洖鍊间笉鍙敤"
                         : (!s2i)         ? "S2R 杩斿洖鍊间笉鍙敤锛圫2I 涓嶅彲鐢級"
                                          : "S2R/S2I 杩斿洖鍊奸兘涓嶅彲鐢?;
        if (textWhy[0]) _snprintf_s(whyOut, whyCap, _TRUNCATE, "%s锛孍X 鏈繑鍥炲瓧绗︿覆 id%s", textWhy, tail);
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

/* 鎸夌被鍨嬬爜鍙栫紦瀛樻潯鐩紱婊′簡灏辩幆褰㈡浛鎹紙鏇挎崲鏃朵袱瀛楁閮芥竻绌洪噸鏌ワ級锟?*/
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

/* v14锛氶€氱敤 slk 鏁板€艰鍙栵紙鎸夌被鍨嬬爜缂撳瓨锛夛拷?
   field = "sight" 锟?鐧藉ぉ瑙嗛噹锛沠ield = "nsight" 锟?澶滄櫄瑙嗛噹锟?
   鍚屼竴绫诲瀷鐮佸悓涓€瀛楁鍙煡涓€娆★紱鎴愬姛瑕佹眰 100~5000锛堜笌鍐呭瓨璺悓涓€鍙ｅ緞锛夛拷?
   鏂囨湰瑙ｄ笉鍑烘潵鏃剁敤 EX 杩斿洖鐨勫瓧绗︿覆 id 鐩存帴锟?S2R/S2I锛堜笉渚濊禆 id鈫掓枃锟?鍙嶆煡锛夛拷?
   鏈繘绋嬫渶澶氭煡 DDH_EX_SLK_CALLS = 24 绫诲瀷 脳 2 瀛楁 娆★紝瓒呬簡涓嶅啀鏌ワ紙杩斿洖 false锛夛拷?*/
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
            LogLine("ATTR EX锛歴lk 鏌ヨ娆℃暟宸茶揪涓婇檺 %d锛?4 绫诲瀷 脳 2 瀛楁锛夛紝涔嬪悗鐨勬柊绫诲瀷涓嶅啀鏌?slk锛堣閲庨€€鍥炲唴瀛樿矾/鏃犳晥锛?,
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

/* 璇婃柇鐢細鎶婄紦瀛橀噷鐨勫師鏂囧鍒跺嚭鏉ワ紙娌℃湁灏辫繑鍥炵┖涓诧級锟?*/
static void DdhExSlkRaw(uint32_t code, const char* field, char* out, size_t cap)
{
    if (out && cap) out[0] = 0;
    if (!out || cap < 2 || !code || !field) return;
    DdhExSlkEntry* e = DdhExSlkFind(code);
    if (!e) return;
    const char* raw = (field[0] == 'n') ? e->nightRaw : e->sightRaw;
    if (raw[0]) DdhUtf8SafeCopy(out, cap, raw, cap - 1);
}

/* 璇婃柇鐢細杩欎竴娆℃暟鍊艰蛋鐨勬槸鍝潯璺紙鏂囨湰/S2R/S2I锟? = 娌℃嬁鍒帮級锟?*/
static int DdhExSlkSource(uint32_t code, bool night)
{
    DdhExSlkEntry* e = DdhExSlkFind(code);
    return e ? (night ? e->nightSrc : e->sightSrc) : DDH_EX_NUM_NONE;
}

/* 璇婃柇鐢細澶辫触鍘熷洜锛堟垚鍔熸椂鏄┖涓诧級锟?*/
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
   v22锛欵XExecuteScript 褰㈠紡鎺㈤拡锛堟瘡杩涚▼涓€娆★紱鍙湪绗竴涓嫳锟?绗笁涓湁绫诲瀷鐮佸崟浣嶆椂鍋氾級
   ---------------------------------------------------------------------------
   鐪熸満 eax 锟?0 锟?鍏堟妸鈥滃疄鍙傚舰寮忊€濆拰鈥滆〃杈惧紡/typeId 鍐欐硶鈥濆垎寮€瀹氫綅锟?
     锟?甯搁噺琛ㄨ揪锟?"1+1"锛圠ua 姹傦拷?= 2锛夊彧楠岃瘉**瀹炲弬褰㈠紡**锛圓 缁勶級锟?
     锟?slk 琛ㄨ揪寮忓洓绉嶅啓娉曞彧楠岃瘉**琛ㄨ揪锟?typeId**锛圔 缁勶級锟?
   缁撹鍐欒繘 g_ddhExArgForm / g_ddhExExprForm锛屼箣锟?sight/nsight/spd/def 缁熶竴璧板畠锟?
   涓€绉嶉兘涓嶉€氬氨淇濇寔鐜扮姸锛堝紩锟?id + 鏁板瓧涓嬫爣锛夛紝涓嶆敼浠讳綍瀛楁锟?
   鍏ㄩ儴璋冪敤锟?__try锛涙帰閽堟湰韬嚭閿欎篃鍙啓涓€琛屾棩蹇楋紝涓嶅奖鍝嶅睘鎬ч噰闆嗭拷?
   =========================================================================== */

/* 璋冧竴绉嶅舰寮忥紝鎶婄粨鏋滆В鎴愨€滄枃锟?+ 鏁板€尖€濄€傝繑锟?eax锛沨asNum 鎸囧嚭鏄惁瑙ｅ嚭鏁板€硷拷?
   鏁板€煎彛寰勪笌姝ｅ紡鏌ヨ涓€鑷达細鏂囨湰 atof 锟?S2R(eax) 锟?S2I(eax)锟?
   鏃ュ織鏍煎紡锛堟瘡绉嶅舰寮忎竴琛岋級锟?
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
        LogLine("EXFORM %s form=%s arg=0x00000000 -> 瀹炲弬娌￠€犲嚭鏉ワ紙娌¤皟鐢級text=\"\" num=鏃?,
                tag, DdhExFormName(form));
        return 0;
    }
    if (rc == 2)
    {
        LogLine("EXFORM %s form=%s arg=0x%08X -> 璋冪敤寮傚父 code=0x%08X text=\"\" num=鏃?,
                tag, DdhExFormName(form), arg, (unsigned)g_ddhExLastExc);
        return 0;
    }

    /* 杩斿洖锟?锟?鏂囨湰锛堝瓧绗︿覆 id / string_fake 鎸囬拡 / 锟?char* 涓夌褰㈡€侀兘璇曪級 */
    if (eax)
    {
        if (!DdhAttrTextFromIdOrPtr(eax, text, sizeof(text)))
            DdhTypeDataText(eax, text, sizeof(text));
    }

    /* 鏂囨湰 锟?鏁板瓧锛涙枃鏈В涓嶅嚭鏉ヤ絾 eax 鍍忊€滃皬鏁存暟 id鈥濇椂鍠傜粰 S2R / S2I锛堢湡鏈哄悓娆撅級锟?*/
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
    else       strncpy_s(num, sizeof(num), "鑶?, _TRUNCATE);

    LogLine("EXFORM %s form=%s arg=0x%08X -> eax=0x%08X text=\"%s\" num=%s",
            tag, DdhExFormName(form), arg, eax, text, num);
    if (hasNum) *hasNum = numOk;
    if (outVal) *outVal = v;
    return eax;
}

/* 姣忚繘绋嬩竴娆★細A 缁勫畾鈥滃疄鍙傚舰寮忊€濓紝B 缁勫畾鈥滆〃杈惧紡/typeId鈥濓紝鐒跺悗璁拌繘鍏ㄥ眬锟?*/
static void DdhExFormProbe(uint32_t obj, uint32_t code)
{
    const uint32_t fn = DdhExNative();
    if (!fn) return;
    if (InterlockedCompareExchange(&g_ddhExFormProbeDone, 1, 0) != 0) return;

    char type[8] = { 0 };
    DdhAttrTypeCode(code, type);
    LogLine("EXFORM锛氬紑濮嬪舰寮忔帰閽堬紙obj=0x%08X 绫诲瀷=%s 鍗佽繘鍒?%u锛涙瘡杩涚▼鍙仛涓€娆★紱"
            "甯搁噺 1+1 搴斿緱 2锛宻ight 搴旇惤鍦?%.0f~%.0f锛?,
            obj, type, code, (double)DDH_ATTR_SIGHT_MIN, (double)DDH_ATTR_SIGHT_MAX);

    /* ---------- A 缁勶細甯搁噺 "1+1" 鍙獙璇佸疄鍙傚舰锟?----------
       A1/A2 = 寮曟搸 id / 锟?char*锟? 鍙傦紝绗簩锟?0锛岀幇鐘讹級锟?
       A3/A4 = 鍚屼笂锛岀浜屽弬 1锛汚5/A6 = 鍚屼笂锛屽彧锟?1 涓弬鏁帮紱
       A7/A8/A9 = string_fake 瀵硅薄鎸囬拡锛屽垎鍒厤 绗簩锟?0 / 绗簩锟?1 / 鍙帇 1 涓弬鏁帮紱
       A10 = 寮曟搸 id 鍙嶆煡鍑虹殑 char*锛坋ngine-pool锛夛紝绗簩锟?0锟?
       ddh-9128.log 宸茶瘉锟?A1~A6 鍏ㄥけ璐ワ紝鎵€浠ラ噸鐐圭湅 A7~A9锛堝叏澶辫触鍐嶇湅 A10锛夛拷?*/
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

    /* A1/A2 閮芥病鎷垮埌 2 锟?鍐嶈瘯绗簩鍙傛暟 / 鍙帇涓€涓弬鏁扮殑鍐欐硶 */
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

    /* A7~A9锛歴tring_fake 瀵硅薄鎸囬拡锛圖isplayTimedTextToPlayer 鍚屾锛涙瘡娆¤皟鐢ㄥ墠閲嶅缓锟?*/
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

    /* A10锛氭渶鍚庝竴绉嶁€斺€斿紩锟?id 鍙嶆煡鍑虹殑 char*锛坋ngine-pool锛夛紝绗簩锟?0 */
    if (chosen == DDH_EX_FORM_NONE)
    {
        bool has = false;
        float v = 0.0f;
        DdhExProbeOne(fn, "A10", DDH_EX_FORM_ENG_PTR, kConst, &has, &v);
        if (has && DdhExSameValue(v, 2.0f)) chosen = DDH_EX_FORM_ENG_PTR;
    }

    /* ---------- B 缁勶細鐪熷疄 sight 琛ㄨ揪寮忥紙A 缁勯€変腑鐨勫疄鍙傚舰寮忥紱鍥涚鍐欐硶锟?----------
       B1 = 閫変腑褰㈠紡 + unit[鍗佽繘鍒禲.sight锛堢幇鐘跺啓娉曪紝蹇呴』鐢ㄧ湡瀹炶〃杈惧紡楠岃瘉锛夛紱
       B2 = 浠呭綋閫変腑寮曟搸 id 鏃讹紝鐢ㄨ８ char* 鍐嶈窇涓€娆″悓涓€鍐欐硶锛堟棫鏃ュ織瀵圭収锛夛紱
       B3~B5 = 閫変腑褰㈠紡 + 瀛楃涓蹭笅锟?/ ["瀛楁"] 鍐欐硶锟?*/
    int chosenExpr    = -1;
    int chosenExprAny = -1;      /* 閫€鍖栫敤锛氭病钀藉湪瑙嗛噹鑼冨洿銆佷絾鑷冲皯瑙ｅ嚭浜嗘暟 */
    if (chosen == DDH_EX_FORM_NONE)
    {
        LogLine("EXFORM锛欰 缁勫叏澶辫触锛堝父閲?1+1 鍗佺瀹炲弬褰㈠紡閮芥病绠楀嚭 2锛夆啋 璺宠繃 B 缁勶紝淇濇寔鐜扮姸");
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

    /* ---------- 缁撹锛氬啓鏃ュ織 + 璁拌繘鍏ㄥ眬锛堝悗锟?sight/nsight/spd/def 閮界敤瀹冿級 ---------- */
    if (chosen != DDH_EX_FORM_NONE)
    {
        InterlockedExchange(&g_ddhExArgForm, (LONG)chosen);
        LogLine("ATTR EX锛氶噰鐢ㄥ疄鍙傚舰寮?%s锛?+1 鎺㈤拡鎷垮埌 2锛?, DdhExFormName(chosen));
    }
    else
    {
        LogLine("ATTR EX锛氭墍鏈夊疄鍙傚舰寮忓潎澶辫触锛堣 EXFORM 鍚勮锛?);
    }

    if (chosenExpr < 0 && chosenExprAny >= 0) chosenExpr = chosenExprAny;
    if (chosenExpr >= 0)
    {
        InterlockedExchange(&g_ddhExExprForm, (LONG)chosenExpr);
        LogLine("ATTR EX锛氶噰鐢ㄨ〃杈惧紡褰㈠紡 %s", DdhExExprName(chosenExpr));
    }
    else if (chosen != DDH_EX_FORM_NONE)
    {
        LogLine("ATTR EX锛氳〃杈惧紡/typeId 鍥涚鍐欐硶閮芥病瑙ｅ嚭 sight锛堝舰鐘朵笉鍖归厤锛夆啋 淇濇寔鐜扮姸锛?s锛?,
                DdhExExprName(DDH_EX_EXPR_NUM_DOT));
    }

    /* 鎺㈤拡涔嬪墠锟?sight/nsight 宸茬粡鎸夋棫褰㈠紡鏌ヨ繃骞剁紦瀛樹簡澶辫触锛氬彧鎶娾€滃け璐モ€濈姸鎬佹竻鎺夛紝
       璁╃揣鎺ョ潃鐨勬牳瀵癸紙涓嬫柟 DdhExSlkNumber锛夋寜鏂板舰寮忛噸鏌ヤ竴娆★紱鎴愬姛鐨勪笉鍔拷?*/
    for (int i = 0; i < g_ddhExSlkCacheCount; ++i)
    {
        if (g_ddhExSlkCache[i].sightState < 0) g_ddhExSlkCache[i].sightState = 0;
        if (g_ddhExSlkCache[i].nightState < 0) g_ddhExSlkCache[i].nightState = 0;
    }
}

/* 姣忚繘绋嬩竴娆★細瀵圭涓€涓嫳闆勶紙锟?3 涓崟浣嶉噷娌℃湁鑻遍泟灏遍€€鑰岀敤锟?3 涓湁绫诲瀷鐮佺殑鍗曚綅锟?
   鏍稿 slk 锟?ddh 鐜版湁璇绘暟銆傚彧鍐欐棩蹇楋紝缁濅笉鏀瑰瓧娈碉拷?*/
static void DdhExProbeOnce(uint32_t obj, uint32_t code, bool memSightOk, float memSight,
                           const DdhUnitAttr* out)
{
    if (g_ddhExProbeDone || !code || !out) return;
    const bool hero = (out->flags & DDH_AF_HEROKNOWN) != 0 && (out->flags & DDH_AF_HERO) != 0;
    const LONG seen = InterlockedIncrement(&g_ddhExCodedSeen);
    if (!hero && seen < 3) return;
    if (!DdhExNative()) return;
    if (InterlockedCompareExchange(&g_ddhExProbeDone, 1, 0) != 0) return;

    /* v22锛氬厛鍋氬疄锟?琛ㄨ揪寮忓舰寮忔帰閽堬紙姣忚繘绋嬩竴娆★紱缁撹锟?g_ddhExArgForm/g_ddhExExprForm锛夛拷?
       鎺㈤拡鍐呴儴姣忕璋冪敤锟?__try锛岃繖閲屽啀鍖呬竴灞傦紝淇濊瘉瀹冨嚭閿欎篃涓嶅奖鍝嶄笅闈㈢殑鏍稿锟?*/
    __try { DdhExFormProbe(obj, code); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        if (InterlockedIncrement(&g_ddhExProbeExcLog) == 1)
            LogLine("EXFORM锛氭帰閽堝紓甯?code=0x%08X锛堝凡鍚炴帀锛岀户缁寜鐜版湁褰㈠紡鏍稿锛?,
                    (unsigned)GetExceptionCode());
    }

    char type[8] = { 0 };
    DdhAttrTypeCode(code, type);
    LogLine("ATTR EX 鏍稿锛氬崟浣嶇被鍨?%s锛堝崄杩涘埗 %u锛塷bj=0x%08X 鑻遍泟=%d锛堟瘡杩涚▼鍙牳瀵逛竴娆★級",
            type, code, obj, hero ? 1 : 0);

    /* sight锛堢櫧澶╄閲庯級锛歴lk 鏄富璺紱鍐呭瓨璺彧锟?slk 澶辫触鏃舵墠浼氳锟?*/
    {
        char raw[DDH_EX_TEXT_MAX] = { 0 };
        float slk = 0.0f;
        const bool okSlk = DdhExSlkNumber(code, "sight", &slk);
        if (!okSlk)
        {
            DdhExSlkRaw(code, "sight", raw, sizeof(raw));
            LogLine("ATTR EX 鏍稿 sight锛歴lk 瑙ｆ瀽澶辫触锛坮aw=\"%s\"锛?s锛夆啋 鐧藉ぉ瑙嗛噹閫€鍥?0x3ADF0",
                    raw, DdhExSlkWhy(code, false));
        }
        else if (memSightOk)
            LogLine("ATTR EX 鏍稿 sight锛歴lk=%.0f锛?s锛夊唴瀛?%.0f锛?s锛?,
                    (double)slk, DdhExNumSourceName(DdhExSlkSource(code, false)),
                    (double)memSight,
                    DdhExSameValue(slk, memSight) ? "涓€鑷? : "涓嶄竴鑷?);
        else
            LogLine("ATTR EX 鏍稿 sight锛歴lk=%.0f锛?s锛夊唴瀛?%.0f锛?s锛?,
                    (double)slk, DdhExNumSourceName(DdhExSlkSource(code, false)));
    }

    /* nsight锛堝鏅氳閲庯級锛歷14 璧锋槸鐙珛涓€鍒楋紝slk 鍙栦笉鍒板氨鏄棤鏁堬紙鐣岄潰 ?锟?*/
    {
        char raw[DDH_EX_TEXT_MAX] = { 0 };
        float slk = 0.0f;
        if (!DdhExSlkNumber(code, "nsight", &slk))
        {
            DdhExSlkRaw(code, "nsight", raw, sizeof(raw));
            LogLine("ATTR EX 鏍稿 nsight锛歴lk 瑙ｆ瀽澶辫触锛坮aw=\"%s\"锛?s锛夆啋 澶滄櫄瑙嗛噹鏃犳晥锛堢晫闈??锛?,
                    raw, DdhExSlkWhy(code, true));
        }
        else
            LogLine("ATTR EX 鏍稿 nsight锛歴lk=%.0f锛?s锛寁14 澶滄櫄瑙嗛噹锛岀晫闈㈢嫭绔嬩竴鍒楋級",
                    (double)slk, DdhExNumSourceName(DdhExSlkSource(code, true)));
    }

    /* spd锛氬鐓х幇鏈夌殑 UnitBalance spd锛圖zAPI 绫诲瀷鏁版嵁锛涘唴瀛樼洿璇绘病鏈夎繖涓瓧娈碉級 */
    {
        char raw[DDH_EX_TEXT_MAX] = { 0 };
        char why[64] = { 0 };
        float slk = 0.0f;
        /* 涓庣幇锟?spd 鏍￠獙涓€鑷达細蹇呴』 > 0锟? 涓嶆槸鏈夋晥绉婚€燂級锛屼笂锟?100000锟?*/
        const int src = DdhExNumberCore(code, "spd", 0.0001f, 100000.0f,
                                        &slk, raw, sizeof(raw), why, sizeof(why));
        if (src == DDH_EX_NUM_NONE)
            LogLine("ATTR EX 鏍稿 spd锛歴lk 瑙ｆ瀽澶辫触锛坮aw=\"%s\"锛?s锛?, raw, why);
        else if ((out->flags & DDH_AF_BASE_SPEED) != 0)
            LogLine("ATTR EX 鏍稿 spd锛歴lk=%.0f锛?s锛夌幇鏈?%.0f锛?s锛?,
                    (double)slk, DdhExNumSourceName(src), (double)out->baseSpeed,
                    DdhExSameValue(slk, out->baseSpeed) ? "涓€鑷? : "涓嶄竴鑷?);
        else
            LogLine("ATTR EX 鏍稿 spd锛歴lk=%.0f锛?s锛夌幇鏈?%.0f锛?s锛?,
                    (double)slk, DdhExNumSourceName(src));
    }

    /* def锛氬鐓х幇鏈夌殑 UnitBalance def锛堝悓涓婏級 */
    {
        char raw[DDH_EX_TEXT_MAX] = { 0 };
        char why[64] = { 0 };
        float slk = 0.0f;
        const int src = DdhExNumberCore(code, "def", DDH_ATTR_ARMOR_MIN, DDH_ATTR_ARMOR_MAX,
                                        &slk, raw, sizeof(raw), why, sizeof(why));
        if (src == DDH_EX_NUM_NONE)
            LogLine("ATTR EX 鏍稿 def锛歴lk 瑙ｆ瀽澶辫触锛坮aw=\"%s\"锛?s锛?, raw, why);
        else if ((out->flags & DDH_AF_BASE_ARMOR) != 0)
            LogLine("ATTR EX 鏍稿 def锛歴lk=%.0f锛?s锛夌幇鏈?%d锛?s锛?,
                    (double)slk, DdhExNumSourceName(src), (int)out->baseArmor,
                    DdhExSameValue(slk, (float)out->baseArmor) ? "涓€鑷? : "涓嶄竴鑷?);
        else
            LogLine("ATTR EX 鏍稿 def锛歴lk=%.0f锛?s锛夌幇鏈?%d锛?s锛?,
                    (double)slk, DdhExNumSourceName(src));
    }
}

/* 鍓嶅嚑涓崟浣嶇殑瀹屾暣缁撴灉鍐欎竴琛屾棩蹇楋紙鐪熸満鎺掓煡鈥滃摢涓瓧娈垫病鎷垮埌鈥濓級锟?
   prop 涓€璧锋墦鍑烘潵锛氱‘锟?*(uint32_t*)(CUnit+0x1E8) 鍒板簳鍙笉鍙锟?*/
static void DdhAttrLogUnit(uint32_t obj, const DdhUnitAttr* out, uint32_t prop)
{
    if (InterlockedIncrement(&g_ddhAttrUnitLogged) > 6) return;
    LogLine("ATTR unit锛歛ddr=0x%08X prop=0x%08X code=%s name=\"%s\" title=\"%s\" flags=0x%08X "
            "range=%.1f dmg=%.1f~%.1f 闂撮殧=%.2f 锟?%.1f 锟?%.0f 鐧藉ぉ瑙嗛噹=%.0f 澶滄櫄瑙嗛噹=%.0f 涓诲姩=%.0f "
            "鍩虹锛氾拷?%.0f 锟?%d "
            "鑶?,
            obj, prop, out->typeCode, out->name, out->title, out->flags,
            (double)out->attackRange, (double)out->damageMin, (double)out->damageMax,
            (double)out->attackInterval, (double)out->armor, (double)out->moveSpeed,
            (double)out->sightDay, (double)out->sightNight, (double)out->acquireRange,
            (double)out->baseSpeed, (int)out->baseArmor,
            (double)out->strength, (double)out->agility, (double)out->intelligence,
            (int)out->extraValue, (out->flags & DDH_AF_LOCUST) ? 1 : 0);
}

/* 鍗曚釜鍗曚綅鐨勫睘鎬ч噰闆嗭紙涓€娆″彲鑳借皟 ~13 锟?native锛涚粨鏋滀氦缁欑紦瀛樺眰锟?*/
static void DdhAttrFillOne(uint32_t obj, DdhUnitAttr* out)
{
    memset(out, 0, sizeof(*out));
    out->addr = obj;
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return;
    /* v21锛氶『渚跨畻涓€娆♀€滄湰鍦扮帺瀹剁粨鐩熸帺鐮佲€濓紙鏁村眬鍙垚鍔熶竴娆★紱澶辫触涓嶉噸璇曞お澶氭锟?*/
    DdhComputeAllyMask();


    /* 绫诲瀷锟?+ 鍗曚綅鍚嶏細涓嶄緷锟?JASS锛屽厛濉笂锛堟嬁涓嶅埌灏卞彧鐣欏湴鍧€锟?*/
    const uint32_t code = SafeCode(obj);
    if (code)
    {
        DdhAttrTypeCode(code, out->typeCode);
        out->flags |= DDH_AF_TYPECODE;
        /* v21锛氳繖涓被鍨嬬爜浠ュ墠琚疄娴嬪嚭锟?Aloc 锟?娌″彞鏌勪篃鎸夎潡铏鐞嗭紙鎴樺満鍗曚綅涓嶆樉绀猴級 */
        if (DdhAlocCodeKnown(code)) out->flags |= DDH_AF_LOCUST;
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

    /* ---- v15锛氬唴瀛樼洿璇讳紭鍏堬紙YDWE unit_property / CUnit+0xE0锟?---
       鏀惧湪鈥滃彞鏌勬鏌モ€濅箣鍓嶏細杩欎簺瀛楁涓嶉渶锟?JASS 鍙ユ焺锛屽彞鏌勫彧褰卞搷涓嬮潰锟?native 鍏滃簳
       涓庣被鍨嬬爜/鑻遍泟鍒ゅ畾锛涘亣榄斿吔/鍙ユ焺琛ㄦ殏鏃跺彇涓嶅埌鍙ユ焺鏃讹紝杩欏嚑鍒楃収鏍锋湁鍊硷拷?*/
    const uint32_t prop = DdhUnitProp(obj);
    const bool propOk = DdhPropReadable(prop);
    DdhAttrFillMemory(obj, prop, propOk, out);

    /* ---- 瑙嗛噹锛堝崗锟?v14锛夛細鐧藉ぉ/澶滄櫄涓ゅ垪锛宩ass.slk 鏄富锟?----
       sight 锟?sightDay锛堢櫧澶╄閲庯級锛宯sight 锟?sightNight锛堝鏅氳閲庯級锛屽悇缃悇鐨勬爣蹇椾綅锟?
       slk 鍙栦笉鍒帮紙娌℃湁 jass.slk 妯″潡 / 绫诲瀷鐮佹湭锟?/ 鏌ヨ娆℃暟鐢ㄥ敖锛夋墠閫€锟?
       Game.dll+0x3ADF0 鐨勨€滃綋鍓嶆湁鏁堣閲庘€濆～ sightDay锛泂ightNight 淇濇寔鏃犳晥锛堢晫锟??锛夛拷?
       鍐呭瓨璺畬鍏ㄤ笉闇€锟?JASS 鍙ユ焺锛屾病鍙ユ焺鐨勫崟浣嶄篃鑳藉厹搴曪拷?
       EXExecuteScript 閫氶亾锟?DdhExSlkNumber锛堟寜绫诲瀷鐮佺紦瀛橈紝24 绫诲瀷 脳 2 瀛楁锛夛拷?*/
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
                LogLine("ATTR EX锛歴lk 瑙嗛噹璇诲彇寮傚父 code=0x%08X锛堝凡鍚炴帀锛屼笉褰卞搷鍏跺畠瀛楁锛?,
                        (unsigned)GetExceptionCode());
        }
    }

    if (slkDayOk)
    {
        out->sightDay = slkDay;
        out->sight    = slkDay;        /* 鏃у瓧娈靛悓姝ワ紙涓嶇疆浣嶏紝浠呬负鎺掗殰鐪嬫棩蹇楋級 */
        out->flags |= DDH_AF_SIGHT_DAY;
        DdhAttrLogOnce(&g_ddhExSlkSightLogged,
                       "鐧藉ぉ瑙嗛噹 鈫?jass.slk sight = %.0f锛?s锛?, (double)slkDay,
                       DdhExNumSourceName(DdhExSlkSource(code, false)));
    }
    if (slkNightOk)
    {
        out->sightNight = slkNight;
        out->flags |= DDH_AF_SIGHT_NIGHT;
        DdhAttrLogOnce(&g_ddhExSlkNightLogged,
                       "澶滄櫄瑙嗛噹 鈫?jass.slk nsight = %.0f锛?s锛?, (double)slkNight,
                       DdhExNumSourceName(DdhExSlkSource(code, true)));
    }
    if (slkDayOk)
    {
        DdhAttrFieldNote(9, "鐧藉ぉ/澶滄櫄瑙嗛噹 鈫?jass.slk sight/nsight锛圗XExecuteScript锛涙枃鏈В涓嶅嚭鏃剁敤瀛楃涓?id 璧?S2R/S2I锛屾寜绫诲瀷鐮佺紦瀛橈級");
    }
    else
    {
        memSightOk = DdhSightRead(obj, &memSight);
        if (memSightOk)
        {
            out->sightDay = memSight;
            out->sight    = memSight;
            out->flags |= DDH_AF_SIGHT_DAY;
            DdhAttrLogOnce(&g_ddhSightOkShown,
                           "瑙嗛噹 鈫?Game.dll+0x%X(&unit+0xFC) = %.0f锛坰lk sight 鍙栦笉鍒版椂鐨勫厹搴曪級",
                           (unsigned)DDH_RVA_SIGHT_FIELD, (double)memSight);
            DdhAttrFieldNote(9, "鐧藉ぉ瑙嗛噹 鈫?jass.slk sight = %.0f锛?s锛?);
        }
    }

    /* 鍐呭瓨鎵?Aloc锛堟渶鍙潬鐨勫厹搴曪級锛氬崟浣嶇粨鏋勯噷甯?0x636F6C41 鍗宠潡铏?*/
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
                LogLine("ATTR锛氳潡铏垽瀹氾紙鍐呭瓨 Aloc锛塩ode=%s addr=0x%08X 浣嶇疆=%s 璇诲彇=%u", DdhCodeText(code), obj, alocPath, alocReads);
        }
        else if (InterlockedIncrement(&g_ddhMemAlocMissLogged) <= 5)
            LogLine("ATTR锛氬唴瀛樻壂鎻忔棤 Aloc code=%s addr=0x%08X锛堟湰浣?x8000+涓€绾?x2000+浜岀骇0x1000锛岃鍙?%u锛?, DdhCodeText(code), obj, alocReads);
    }

    /* 绫诲瀷鏁版嵁鍒ゅ畾锛堝厛浜庡彞鏌勶級锛氱被鍨?abilList 甯?Aloc 鍗宠潡铏紱hidespell_* 甯告嬁涓嶅埌鍙ユ焺涔熻兘瀹氭€с€?*/
    if (!(out->flags & DDH_AF_LOCUST) && code && DdhTypeHasAloc(code))
    {
        out->flags |= DDH_AF_LOCUST;
        DdhAlocCodeRemember(code);
        if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 10)
            LogLine("ATTR锛氳潡铏垽瀹氾紙绫诲瀷鏁版嵁锛塩ode=%s 鈫?flags |= 0x%X", out->typeCode, DDH_AF_LOCUST);
    }

    /* 鍚庨潰鎵€鏈夊瓧娈甸兘瑕佸彞鏌勶紙JASS native 鐨勫弬鏁版槸鍙ユ焺锛屼笉锟?CUnit*锛夛拷?
       鎷夸笉鍒板彞锟?锟?native 瀛楁鏃犳晥锛堝唴瀛樼洿璇荤殑瀛楁淇濈暀锛夛紝鏃ュ織闄愭祦锟?*/
    /* 鍏ュ彛鍏堝垽铦楄櫕锛堜笉渚濊禆鍙ユ焺锛夛細椹敳甯稿父鎷夸笉鍒板彞鏌勶紝绛夊彞鏌勬鏌ヤ箣鍚庡氨姘歌繙娌℃満浼氫簡 */
    if (!(out->flags & DDH_AF_LOCUST) && code)
    {
        int lv0 = DdhAbilityLevelByObj(obj, 0x416C6F63u);
        if (lv0 > 0)
        {
            out->flags |= DDH_AF_LOCUST;
            DdhAlocCodeRemember(code);
            if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 15)
                LogLine("ATTR锛氳潡铏垽瀹氾紙鍏ュ彛鐩存煡锛塩ode=%s obj=0x%08X level=%d", DdhCodeText(code), obj, lv0);
        }
    }

    /* 鍏ュ彛鍏堝垽铦楄櫕锛堜笉渚濊禆鍙ユ焺锛夛細椹敳甯告嬁涓嶅埌鍙ユ焺锛岀瓑鍙ユ焺妫€鏌ヤ箣鍚庡氨姘歌繙娌℃満浼?*/
    if (!(out->flags & DDH_AF_LOCUST) && code)
    {
        int lv0 = DdhAbilityLevelByObj(obj, 0x416C6F63u);
        if (lv0 > 0)
        {
            out->flags |= DDH_AF_LOCUST;
            DdhAlocCodeRemember(code);
            if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 15)
                LogLine("ATTR锛氳潡铏垽瀹氾紙鍏ュ彛鐩存煡锛塩ode=%s obj=0x%08X level=%d", DdhCodeText(code), obj, lv0);
        }
    }

    const uint32_t handle = HpObjToHandle(obj);
    if (!handle)

    {
        if (InterlockedIncrement(&g_ddhAttrNoHandleLogged) <= 5)
            LogLine("ATTR obj->handle 澶辫触锛坅ddr=0x%08X prop=0x%08X code=%s锛夆啋 native 瀛楁锛堢Щ閫?绫诲瀷鍩虹鏁版嵁/鑻遍泟鍒ゅ畾锛夋棤鏁堬紱鍐呭瓨鐩磋瀛楁淇濈暀",
                    obj, prop, out->typeCode);
        DdhAttrLogUnit(obj, out, prop);
        return;
    }

    /* 鈶?鐩存帴鎸夊崟浣嶅璞℃煡鎶€鑳斤紙閫嗗悜鍑虹殑搴曞眰鍑芥暟锛屾渶鍙潬锛?*/
    if (!(out->flags & DDH_AF_LOCUST) && code)
    {
        DdhProbeHeroNatives();
        DdhW3ApiTypeLookup();   /* 鍙帰涓€娆★細Game.dll 鏄惁瀵煎嚭绫诲瀷瀵硅薄鏌ユ壘 */
        if (InterlockedIncrement(&g_ddhTypeIdProbe) <= 12)
        {
            /* code 鎺㈤拡锛歳aw锛圕Unit+0x30锛変笌 DzAPI 瀹為檯鏀跺埌鐨?id 瀵圭収 */
            uint32_t mapped = DdhTypeDataUnitId(handle, code);
            LogLine("typeid 鎺㈤拡锛歳aw=0x%08X mapped=0x%08X锛圖zAPI 瑕佹眰 0x10000~0x1FFFF 鎴?>=0x20000锛?, code, mapped);
        }
        int lv = DdhAbilityLevelByObj(obj, 0x416C6F63u);
        if (lv >= 0) out->flags |= DDH_AF_LOCUST_CHECKED;   /* 鍒ゅ畾璺戝畬浜嗭紙0 涔熻璁帮紝C# 鎵嶆暍淇?False锛?*/   // 0x416C6F63 = 'Aloc'锛堝ぇ绔洓瀛楃锛?
        if (lv > 0)
        {
            out->flags |= DDH_AF_LOCUST;
            DdhAlocCodeRemember(code);
            if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 15)
                LogLine("ATTR锛氳潡铏垽瀹氾紙瀵硅薄鐩存煡锛塩ode=%s obj=0x%08X level=%d", DdhCodeText(code), obj, lv);
        }
        else if (InterlockedIncrement(&g_ddhObjLookupLogged) <= 20)
            LogLine("ATTR锛氬璞＄洿鏌?code=%s obj=0x%08X level=%d锛?=娌℃湁 Aloc锛?1=game.dll/璋冪敤澶辫触锛?, DdhCodeText(code), obj, lv);
        else if (lv < 0 && InterlockedIncrement(&g_ddhMemAlocMissLogged) <= 3)
            LogLine("ATTR锛氬璞＄洿鏌ュけ璐?code=%s obj=0x%08X锛坓ame.dll 鏈姞杞芥垨璋冪敤寮傚父锛?, DdhCodeText(code), obj);
    }

    /* ydbase 鐨勫疄鐜帮細func_value* 鐨?+0x10 鎵嶆槸鐪熸鍑芥暟鎸囬拡锛涙妧鑳?ID 鐢?WFE 鐨?0x416C6F63銆?
       鍊欓€?p / *p / *(p+0x10)锛屼袱绉?ID 鍚勮瘯涓€娆★紝浠讳竴杩斿洖 >0 鍗宠潡铏€?*/
    if (!(out->flags & DDH_AF_LOCUST))
    {
        uint32_t p = GetUnitAbilityLevelNative();
        uint32_t cands[4] = { p, 0, 0, DdhYdJassFunc("GetUnitAbilityLevel") };
        __try { if (p) cands[1] = *(const uint32_t*)(uintptr_t)p; } __except (EXCEPTION_EXECUTE_HANDLER) { }
        __try { if (p) cands[2] = *(const uint32_t*)(uintptr_t)(p + 0x10); } __except (EXCEPTION_EXECUTE_HANDLER) { }
        const uint32_t ids[2] = { 0x416C6F63u, 0x636F6C41u };
        for (int ci2 = 0; ci2 < 4 && !(out->flags & DDH_AF_LOCUST); ++ci2)
        {
            if (!cands[ci2]) continue;
            for (int ii = 0; ii < 2; ++ii)
            {
                int lv = -1;
                __try { lv = ((int (__cdecl*)(uint32_t, uint32_t))(uintptr_t)cands[ci2])(handle, ids[ii]); }
                __except (EXCEPTION_EXECUTE_HANDLER) { lv = -1; }
                if (lv > 0)
                {
                    out->flags |= DDH_AF_LOCUST;
                    DdhAlocCodeRemember(code);
                    if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 15)
                        LogLine("ATTR锛欰loc(func_value) code=%s cand=%d fn=0x%08X id=0x%08X level=%d", DdhCodeText(code), ci2, ids[ii], lv);
                    break;
                }
            }
        }
    }


    /* ---- v14锛氳潡铏紙Aloc锛夋爣锟?----
       GetUnitAbilityLevel(handle, 'Aloc') > 0 锟?flags |= DDH_AF_LOCUST锛孋# 鎹鎶婅鍗曚綅
       浠庛€愭垬鍦哄崟浣嶃€戦噷杩囨护鎺夈€傚彞鏌勬嬁涓嶅埌 / native 娌″畾锟?/ 璋冪敤寮傚父 锟?涓嶇疆锟?
       锛圕# 鎸夆€滈潪铦楄櫕鈥濆鐞嗭紝瀹佸彲婕忎竴涓篃涓嶈鏉€姝ｅ父鍗曚綅锛夈€備笌浜嬩欢 flags bit0 鍚屼竴鍒ゅ畾鍙ｅ緞锟?*/
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
                /* v21锛氳浣忕被鍨嬬爜锛屽悗缁悓鐮佸崟浣嶅嵆浣挎病鏈夊彞鏌勪篃鍒ゅ畾涓鸿潡锟?*/
                DdhAlocCodeRemember(code);
                if (InterlockedIncrement(&g_ddhAttrLocustLogged) <= 10)
                    LogLine("ATTR锛氳潡铏垽瀹?code=%s handle=0x%08X level=%d 鈫?flags |= 0x%X锛堟垬鍦哄崟浣嶄笉鏄剧ず锛?,
                            out->typeCode, handle, level, DDH_AF_LOCUST);
            }
            else
            {
                /* YDWE 鍙ｅ緞锛欸etUnitAbilityLevel(handle,"Aloc") <= 0 鍗虫櫘閫氬崟浣嶏紱
                   杩欓噷鎶娾€滆皟鐢ㄧ粨鏋溾€濇墦鍑烘潵锛屾柟渚跨‘璁?native 鏄惁鐪熺殑杩斿洖 0锛堣€屼笉鏄病璋冪敤/寮傚父锛夈€?*/
                if (InterlockedIncrement(&g_ddhAttrAlocMissLogged) <= 30)
                    LogLine("ATTR锛欰loc 鏈懡涓?code=%s addr=0x%08X handle=0x%08X afn=0x%08X ok=%d level=%d",
                            out->typeCode, obj, handle, (unsigned)afn, ok ? 1 : 0, level);
            }
        }
    }
    /* 鍗曚綅绫诲瀷鏁版嵁瀹炲弬鎺㈡祴锟? 绉嶇粍鍚堝悇璇曚竴娆★紙鍙湪绗竴涓嬁鍒板彞鏌勭殑鍗曚綅涓婂仛锛夛紝
       閫変腑缁撴灉鍚庨潰鎵€鏈夊瓧娈靛叡鐢紙绉拌皳/鍩虹閫熷害/鍩虹锟?闄勫姞锟?points锛涜閲庡凡涓嶈蛋绫诲瀷鏁版嵁锛夛拷?
       DZPROBE 锟?+ "ATTR 鍗曚綅绫诲瀷鏁版嵁锛氶噰锟?order=.. id褰㈠紡=.." 閮藉湪杩欓噷鍐欐棩蹇楋拷?*/

    DdhTypeDataProbe(handle, code);

    /* ---- 鑻遍泟鍒ゅ畾 / 绉拌皳 ----
       绉拌皳鍏堝彇鍒版湰鍦帮紝绛変笅闈㈠垽瀹氬嚭鈥滄槸涓嶆槸鑻遍泟鈥濆啀鍐冲畾瑕佷笉瑕佸啓锟?
       闈炶嫳闆勫彧鏄剧ず鍗曚綅鍚嶏紱GetHeroProperName 鐪熸嬁鍒版枃鏈殑鍗曚綅瑙嗕负鑻遍泟锟?*/
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

    /* ---- 鏀诲嚮鑼冨洿锛氬唴瀛樼洿璇伙紙prop+0x258锛夋病鎷垮埌鎵嶉棶 native ---- */
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
                        "鏀诲嚮鑼冨洿 鈫?%s锛坣ative 鍏滃簳锛氬唴瀛樼洿璇绘病鎷垮埌锛?, DdhAttrUsedName(DDH_AN_RANGE));
            DdhAttrFieldNote(1, note);
        }
    }

    /* ---- 鏀诲嚮鍔涳細鍐呭瓨鐩磋锛坲nit_property 锟?dice/side/base/bonus锛夋病鎷垮埌鎵嶉棶 native ----
       native 鍙ｅ緞锛欴amageMin/DamageMax 鎴愬锛岀己涓€涓啀閫€ GetUnitAttack 鍗曞€硷拷?*/
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
                        "鏀诲嚮锟?锟?%s + %s锛坣ative 鍏滃簳锛氬尯闂达級",
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
                            "鏀诲嚮鍔?, DdhAttrUsedName(DDH_AN_ATTACK));
                DdhAttrFieldNote(2, note);
            }
        }
    }

    /* ---- 鏀诲嚮闂撮殧锛氬唴瀛樼洿璇伙紙prop+0x158锛変紭鍏堬紱native 鍏滃簳 ----
       Cooldown 鐩存帴鏄锛汚ttackSpeed 锟?>1 瑙嗕负鈥滄瘡绉掓鏁扳€濇崲锟?1/鍊硷拷?*/
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
                                "鏀诲嚮闂撮殧 鈫?%s锛坣ative 鍏滃簳锛氱锛?,
                                DdhAttrUsedName(hit));
                else
                    _snprintf_s(note, sizeof(note), _TRUNCATE,
                                "鏀诲嚮闂撮殧 鈫?%s锛坣ative 鍏滃簳锛氱锛?, DdhAttrUsedName(hit));
                DdhAttrFieldNote(3, note);
            }
        }
    }

    /* ---- 鎶ょ敳锛氬唴瀛樼洿璇伙紙CUnit+0xE0锛屾寜 int32 璇伙級浼樺厛锛沶ative 鍏滃簳 ---- */
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
                        "鎶ょ敳 鈫?%s锛坣ative 鍏滃簳锛欳Unit+0xE0 娌℃嬁鍒帮級", DdhAttrUsedName(hit));
            DdhAttrFieldNote(4, note);
        }
    }

    /* ---- 绉婚€燂細GetUnitMoveSpeed 锟?GetUnitDefaultMoveSpeed锛堢簿纭紭鍏堬級----
       鐪熸満鏃ュ織锛氳嚜鍔ㄥ尮閰嶆浘鎸戝埌 GetGameSpeed锛堣繑锟?0锛夛紝鐣岄潰灏辨樉锟?0锟?
       鐜板湪 0/璐熸暟/瓒婄晫涓€寰嬭涓衡€滄病娴嬪埌鈥濓細涓嶇疆 DDH_AF_MOVESPEED锛孋# 鐨勩€愮Щ閫熴€戝垪浼氶€€锟?
       鍗曚綅绫诲瀷鏁版嵁 spd锛堢晫锟?? 锟?spd锛岀粷涓嶆樉锟?0锛夛拷?*/
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
            if (!(nv > 0.0f) || nv > 100000.0f) continue;    /* 0 瑙嗕负鏃犳晥锛岀户缁瘯涓嬩竴锟?*/
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
                        "绉婚€?, DdhAttrUsedName(mh), (double)mv);
            DdhAttrFieldNote(5, note);
        }
        else
        {
            char note[224];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "绉婚€燂細%s / %s 杩斿洖 0/鏃犳晥 鈫?瑙嗕负娌℃祴鍒帮紙鐣岄潰閫€鍥?DzAPI spd锛屼笉鏄剧ず 0锛?,
                        DdhAttrUsedName(DDH_AN_MOVE), DdhAttrUsedName(DDH_AN_MOVE_BASE));
            DdhAttrFieldNote(18, note);
        }
    }

    /* ---- 涓诲姩鏀诲嚮鑼冨洿锛氬唴瀛樼洿璇伙紙prop+0x244锛変紭鍏堬紱native 鍏滃簳 ---- */
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
                        "涓诲姩鏀诲嚮鑼冨洿 鈫?%s锛坣ative 鍏滃簳锛氬唴瀛樼洿璇绘病鎷垮埌锛?, DdhAttrUsedName(DDH_AN_ACQUIRE));
            DdhAttrFieldNote(7, note);
        }
    }

    /* ---- 鑻遍泟鍒ゅ畾锛氫紭鍏堟爣锟?native GetUnitTypeId + IsHeroUnitId ----
       鏈浘/骞冲彴锟?GetHeroProperName 褰撳瓧绗︿覆 id 鐢紝鍙嶆煡涓嶅埌鏂囨湰鏃跺畠涓嶈兘锟?
       鈥滄槸涓嶆槸鑻遍泟鈥濈殑渚濇嵁锛涙爣锟?native 鍙栫被鍨嬬爜鍐嶉棶 IsHeroUnitId 鏈€鍙潬锟?*/
    {
        uint32_t typeId = 0, isHeroId = 0;
        if (DdhAttrCallU32(DDH_AN_TYPEID, handle, 0, &typeId) && typeId &&
            DdhAttrCallU32(DDH_AN_IS_HERO_ID, typeId, 0, &isHeroId))
        {
            heroKnown = true;
            hero = (isHeroId != 0);
            DdhAttrFieldNote(12, hero ? "鑻遍泟鍒ゅ畾 鈫?GetUnitTypeId + IsHeroUnitId锛氭槸鑻遍泟"
                                      : "鑻遍泟鍒ゅ畾 鈫?GetUnitTypeId + IsHeroUnitId锛氭槸鑻遍泟");
        }
    }

    /* ---- 鍔涢噺 / 鏁忔嵎 / 鏅哄姏锛圙etHeroStr/Agi/Int(handle, 0)锛屼粎鑻遍泟锟?----
       闈炶嫳闆勪笉锟?flags锛圕# 鏄剧ず 鈥旓級锛涜嫳闆勬煇涓€璺病璋冮€氬氨涓嶇疆閭ｄ竴浣嶏紙C# 鏄剧ず ?锛夛拷?
       GetUnitTypeId + IsHeroUnitId 浼氬厛缁欏嚭缁撹锛涙澶栤€滀笁缁翠换涓€ > 0鈥濅篃瑙嗕负鑻遍泟
       锛堟棫鐗堢湡鏈哄悓娆剧殑瀹夊叏鍏滃簳锛夛紝涓夎矾閮借皟閫氫笖锟?0 鍒欑‘瀹氫笉鏄嫳闆勶拷?*/
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
                                "鍔涢噺 鈫?%s(handle, 0)锛堣嫳闆勪笁缁达級", DdhAttrUsedName(hs));
                    DdhAttrFieldNote(13, note);
                }
                if (okA)
                {
                    out->agility = agi;
                    out->flags |= DDH_AF_AGI;
                    char note[160];
                    _snprintf_s(note, sizeof(note), _TRUNCATE,
                                "鏁忔嵎 鈫?%s(handle, 0)锛堣嫳闆勪笁缁达級", DdhAttrUsedName(ha));
                    DdhAttrFieldNote(14, note);
                }
                if (okI)
                {
                    out->intelligence = intel;
                    out->flags |= DDH_AF_INT;
                    char note[160];
                    _snprintf_s(note, sizeof(note), _TRUNCATE,
                                "鏅哄姏 鈫?%s(handle, 0)锛堣嫳闆勪笁缁达級", DdhAttrUsedName(hi));
                    DdhAttrFieldNote(15, note);
                }
            }
            else
            {
                /* 闈炶嫳闆勶細锟?锟?鏅轰笉閫傜敤锛圕# 鏄剧ず 鈥旓級锟? 涓嶈兘褰撴垚鈥滄祴鍒扮殑鏁板€硷拷?*/
                out->strength = out->agility = out->intelligence = 0.0f;
            }
        }
    }

    /* ---- 鍗曚綅绫诲瀷鍩虹鏁版嵁锛圲nitBalance锛夛細spd / def ----
       鍏ㄩ儴璧版帰娴嬮€変腑锟?DzAPI_UnitType_GetUnitTypeData* 瀹炲弬缁勫悎锛坥rder / id褰㈠紡 / JASS
       string 鍙ユ焺锛夛紱娌￠€変腑缁勫悎灏变竴涓兘涓嶅～锛堢晫锟??锛夛紝缁濅笉锟?0 鍐掑厖锟?
       鍗忚 v14 锟?sight/nsight 涔熶笉鍐嶄粠杩欓噷鍙栵細瑙嗛噹锟?jass.slk锛坰lk 鍙栦笉鍒版椂 sightDay 閫€锟?
       Game.dll+0x3ADF0锛夈€傝繖閲屽彧锟?spd / def锟?*/
    {
        float bv = 0.0f;

        if (DdhTypeDataNumber(handle, code, "spd", &bv) && bv > 0.0f && bv <= 100000.0f)
        {
            out->baseSpeed = bv;
            out->flags |= DDH_AF_BASE_SPEED;
            DdhAttrFieldNote(8, "鍩虹閫熷害 鈫?DzAPI_UnitType_GetUnitTypeDataInt(\"spd\")");
        }

        bv = 0.0f;
        if (DdhTypeDataNumber(handle, code, "def", &bv) && bv >= -100.0f && bv <= 1000.0f)
        {
            out->baseArmor = (int32_t)(bv >= 0.0f ? (bv + 0.5f) : (bv - 0.5f));
            out->flags |= DDH_AF_BASE_ARMOR;
            DdhAttrFieldNote(11, "鍩虹鎶ょ敳 鈫?DzAPI_UnitType_GetUnitTypeDataInt(\"def\")");
        }
    }

    /* ---- 绉拌皳锛歅ropernames 浼樺厛锛汫etHeroProperName/GetUnitName 浣滀负鍚庡 ---- */
    if (title[0] && (titleSrc == 4 || titleSrc == 1 || (heroKnown && hero)))
    {
        DdhUtf8SafeCopy(out->title, sizeof(out->title), title, sizeof(out->title) - 1);
        out->flags |= DDH_AF_TITLE;
    }

    /* ---- 鍗曚綅闄勫姞鍊硷細GetUnitUserData锛堢簿纭級锟?DzAPI_UnitType_GetUnitTypeDataInt("points") ----
       GetUnitUserData 锟?0 涔熸槸鍚堟硶鍊硷紙璋冮€氬氨缃綅锛夛紱鍙湁瀹冧笉鍙敤鎵嶉€€绫诲瀷鏁版嵁 points锟?
       鏉冨▉鏉ユ簮锟?GetUnitUserData锛孏etItemUserData 宸插湪鎺掗櫎鍚嶅崟閲岋紙鐪熸満鏃ュ織閲岃閫変腑鐨勫氨鏄畠锛夛拷?*/
    {
        uint32_t raw = 0;
        if (DdhAttrCallU32(DDH_AN_USERDATA, handle, 0, &raw))
        {
            out->extraValue = (int32_t)raw;
            out->flags |= DDH_AF_EXTRA;
            char note[160];
            _snprintf_s(note, sizeof(note), _TRUNCATE,
                        "鍗曚綅闄勫姞鍊?, DdhAttrUsedName(DDH_AN_USERDATA));
            DdhAttrFieldNote(16, note);
        }
        else
        {
            float pv = 0.0f;
            if (DdhTypeDataNumber(handle, code, "points", &pv) && pv >= -1000000.0f && pv <= 1000000.0f)
            {
                out->extraValue = (int32_t)(pv >= 0.0f ? (pv + 0.5f) : (pv - 0.5f));
                out->flags |= DDH_AF_EXTRA;
                DdhAttrFieldNote(19, "鍗曚綅闄勫姞锟?锟?DzAPI_UnitType_GetUnitTypeDataInt(\"points\")"
                                     "锛圙etUnitUserData 涓嶅彲鐢級");
            }
        }
    }

    /* v20锛氭瘡杩涚▼涓€锟?jass.slk 鏍稿锛堝彧鍐欐棩蹇楋紱瑙嗛噹鍏滃簳宸插湪涓婇潰鎸夐渶鐢熸晥锛夛拷?
       澶栧眰鍐嶅寘涓€锟?__try锛氭牳瀵归噷浠讳綍寮傚父閮藉彧鍐欐棩蹇楋紝涓嶅奖鍝嶅叾瀹冨瓧锟?鍏跺畠鍗曚綅锟?*/
    __try { DdhExProbeOnce(obj, code, memSightOk, memSight, out); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        if (InterlockedIncrement(&g_ddhExProbeExcLog) == 1)
            LogLine("ATTR EX 鏍稿寮傚父 code=0x%08X锛堝凡鍚炴帀锛屼笉褰卞搷鍏跺畠瀛楁锛?,
                    (unsigned)GetExceptionCode());
    }

    /* 绗竴娆¤姹傛椂鎶婂墠鍑犱釜鍗曚綅鐨勫畬鏁寸粨鏋滃啓杩涙棩蹇楋紙prop 鎸囬拡涔熸墦鍑烘潵锟?*/
    /* 閫夊尯鍗曚綅 vs 閽╁瓙鍗曚綅 瀵圭収 */
    if (InterlockedIncrement(&g_ddhSelCompare) <= 8)
    {
        uint32_t selUnit = DdhSelectedUnitPtr();
        LogLine("閫夊尯瀵圭収 %s obj=0x%08X sel=0x%08X diff=0x%X", DdhCodeText(code), obj, selUnit,
                (selUnit && selUnit > obj) ? (selUnit - obj) : (obj - selUnit));
    }

    /* 鑻遍泟鍧楁暟鍊艰浆鍌細鍙墦鍗?1~500 鐨勬暣鏁板€?float锛岀敤浜庢瘮瀵?24/17/16 */
    if (InterlockedIncrement(&g_ddhVerifyLogged) <= 120)
    {
        uint32_t hero = 0;
        __try { hero = *(const uint32_t*)(uintptr_t)(obj + 0x1F0); } __except (EXCEPTION_EXECUTE_HANDLER) { hero = 0; }

    /* 绉婚€熺‘璁わ細鍚屼竴鏉℃棩蹇楅噷鎵撳嵃 float / int / native 涓夌瑙ｉ噴 */
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
        LogLine("绉婚€?%s sb=0x%08X sp=0x%08X float=%.2f int=%d native=%.2f",
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
                    LogLine("鑻遍泟鍧?%s hero+0x%X = %d", DdhCodeText(code), off, iv);
            }
        }
    }
    /* 涓夊洿鑷姩瀹氫綅锛氬湪鍚屼竴鍧楅噷鎵?(str, agi, int) 涓夊厓缁勶紝鍊欓€夐棿璺?0x10/0x14/0x18/0x1C 閮借瘯锛?
       鍛戒腑鍗崇紦瀛樺亸绉伙紝涔嬪悗鎵€鏈夎嫳闆勭洿鎺ョ敤锛屼笉鍐嶉€愭鎺㈡祴銆?*/
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
                        LogLine("涓夊洿瀹氫綅鎴愬姛锛歴tr=+0x%X agi=+0x%X int=+0x%X锛坈ode=%s锛?d/%d/%d锛?,
                                g_ddhHeroOffStr, g_ddhHeroOffAgi, g_ddhHeroOffInt, DdhCodeText(code), wantS, wantA, wantI);
                        break;
                    }
                }
            }
            if (!g_ddhHeroOffResolved && InterlockedIncrement(&g_ddhHeroFailLogged) <= 3)
                LogLine("涓夊洿瀹氫綅澶辫触锛歝ode=%s 鍧?0x%08X 鍐呮湭鎵惧埌 %d/%d/%d 涓夊厓缁?, DdhCodeText(code), hro, wantS, wantA, wantI);
        }
    }
DdhAttrLogUnit(obj, out, prop);
}

/* ---- 锟?addr 缂撳瓨 3 绉掞紙v12锛汣# 姣忕闂竴杞紝鍚屼竴鍗曚綅涓嶄細琚噸澶嶈В鏋愬娆★級 ---- */
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
            *out = c->attr;          /* 缂撳瓨鍛戒腑锛氫竴锟?native 閮戒笉锟?*/
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
   v14 璇婃柇锛氬崟浣嶅璞℃暟鎹紙RegisterModel -> GetUnitData锟?
   ---------------------------------------------------------------------------
   YDWE 锟?search_get_unit_data 骞朵笉鏄€滃瓧绗︿覆鍦板潃 +4鈥濓紝鑰屾槸锟?
     锟?鍦ㄥ彲鎵ц/鍙娈甸噷锟?"RegisterModel\0" 鐨勫湴鍧€锟?
     锟?锟?.text 閲屾壘寮曠敤璇ュ湴鍧€锟?4 瀛楄妭绔嬪嵆鏁帮紙mov/push 锟?operand锛夛紝璁颁綔 ref锟?
     锟?ref + 4 姝ｅソ鏄偅鏉℃寚浠や箣鍚庯紝浠庨偅閲岀户缁壘涓嬩竴锟?E8 rel32 璋冪敤锟?
     锟?call 鐩爣 = E8 鍦板潃 + 5 + rel32锛屽氨锟?GetUnitData(code)锟?
   鏈嚱鏁版瘡杩涚▼鍙窇涓€娆★細鑷姩璇婃柇锛堣锟?绉拌皳缂哄け锛夋垨 DDH_UDATA=dump 鏃惰Е鍙戯紱
   瀵逛袱涓崟浣嶅悇 dump idx 0..600锛圓=绗竴涓嫳闆勶紝B=绫诲瀷鐮佷笉鍚岀殑鍗曚綅锛夛紝鍐欏悓涓€涓枃浠讹拷?
   =========================================================================== */
#define DDH_UDATA_LAST_IDX 600   /* v19锟?61 -> 601 琛岋紙idx 0..600锟?*/

struct DdhUdataSection
{
    uint32_t begin;
    uint32_t end;
    uint32_t chars;
};

static volatile LONG g_ddhUdataDone = 0;
static volatile LONG g_ddhUdataForce = 0;   /* 瑙嗛噹/绉拌皳缂哄け鏃惰嚜锟?dump 涓€锟?*/

/* 璇讳竴锟?dword锛涘潖鎸囬拡涓嶆姏鍒拌皟鐢拷?*/
static int DdhUdataPoke(uint32_t addr, uint32_t* out)
{
    if (!out || addr < 0x10000u) return 0;
    __try { *out = *(const uint32_t*)(uintptr_t)addr; return 1; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

/* 锟?game.dll 鐨勫凡鏄犲皠娈碉紙澶у皬闄愬埗锟?SizeOfImage 鍐咃級 */
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

/* "RegisterModel" 鍚粨锟?NUL锛涘彧鎵彲璇讳笖闈炲彲鍐欑殑娈碉紙.text/.rdata锟?*/
static uint32_t DdhUdataFindRegisterModel(const DdhUdataSection* sec, int n)
{
    static const char kName[] = "RegisterModel";
    const uint32_t kLen = (uint32_t)sizeof(kName);   /* 13锛屽惈 NUL */
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

/* 鍦ㄥ彲鎵ц娈甸噷鎵锯€滆皝寮曠敤浜嗚繖涓瓧绗︿覆鍦板潃鈥濄€傝繑鍥炵殑锟?4 瀛楄妭绔嬪嵆鏁拌嚜韬殑鍦板潃锟?*/
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

/* 浠庡瓧绗︿覆寮曠敤涔嬪悗锟?4锛夋壘涓嬩竴锟?E8 rel32锛涚洰鏍囧繀椤昏惤鍦ㄥ彲鎵ц娈典笖棣栧瓧鑺備笉鏄～鍏咃拷?*/
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
            if (op == 0xCCu || op == 0x00u) continue;   /* int3 / 绌虹櫧锛屼笉鍍忓嚱鏁板叆锟?*/
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

/* 鍙帰娴嬶紝涓嶅疄鐜伴€昏緫锛涙瘡涓悕瀛楀浐瀹氫竴锟?*/
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
        LogLine("UDATA native %s=%s", kNames[i], fn ? "宸插畾浣? : "鏈壘鍒?);
    }
}

/* ---- v19锛歞ump 鏍囪鍊硷紙float 璇樊 0.5锛宨nt 绮剧‘锟?---
   杩欎簺鍊兼棦鍙兘锟?sight/nsight锛屼篃鍙兘锟?spd锟?60/315/300/320 涓庣Щ閫熼噸鍚堬級锟?
   鎵€浠ュ彧锟?<SIGHT?> 浣滀负鈥滃€欓€夆€濇彁绀猴紝涓嶇洿鎺ュ綋鎴愯閲庯拷?*/
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

/* 鍒嗛殧琛岄噷锟?name 涓嶈兘甯﹀紩锟?鎹㈣锛屽惁鍒欎竴锟?dump 鐨勮竟鐣屼細琚啓鍧忥拷?*/
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
    int      hero;          /* 1 = 鑻遍泟锟? = 闈炶嫳锟?鏈煡 */
    char     type[8];
    char     name[64];
};

/* 浠庡睘鎬ц姹傛Ы i 鍙栦竴涓€欓€夛細addr/code/type/name/hero 閮藉厛鍦ㄨ繖閲屽畾鍨嬶拷?*/
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

/* B 鐨勯€夋嫨椤哄簭锛氱被鍨嬬爜涓嶅悓鐨勮嫳锟?-> 绫诲瀷鐮佷笉鍚岀殑鏈夊悕鍗曚綅 -> 绫诲瀷鐮佷笉鍚岀殑浠绘剰鍗曚綅
   -> 鍚岀被鍨嬬爜鐨勮嫳锟?-> 鍚岀被鍨嬬爜鐨勬湁鍚嶅崟锟?-> 鍚岀被鍨嬬爜鐨勪换鎰忓崟浣嶏拷?
   鏈€鍚庝笁绾ф槸鍋囬瓟锟?鍗曠被鍨嬪浘锛堟墍鏈夊崟锟?code 閮戒竴鏍凤級鐨勫厹搴曪紝淇濊瘉浠嶆湁涓ゆ锟?*/
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

/* 锟?GetUnitData(code)锛歘_fastcall锛宑ode 锟?ecx銆傚け璐ヨ繑锟?0 骞剁粰鍑哄紓甯哥爜锟?*/
static uintptr_t DdhUdataCallGetUnitData(uint32_t fn, uint32_t code, uint32_t obj,
                                         const char* label, DWORD* outExc)
{
    typedef uintptr_t (__fastcall* fn_udata_t)(uint32_t);
    uintptr_t data = 0;
    DWORD exc = 0;
    __try { data = ((fn_udata_t)(uintptr_t)fn)(code); }
    __except (EXCEPTION_EXECUTE_HANDLER) { exc = GetExceptionCode(); data = 0; }
    if (outExc) *outExc = exc;
    LogLine("UDATA锟?s GetUnitData(code=0x%08X obj=0x%08X) = 0x%08X%s",
            label, code, obj, (unsigned)data, exc ? "锛堣皟鐢ㄥ紓甯革級" : "");
    return data;
}

/* 涓€涓崟浣嶄竴娈碉細BEGIN 鍒嗛殧锟?+ idx 0..600锛堟渶锟?601 琛岋級+ END銆傝繑鍥炲疄闄呰鏁帮拷?*/
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
            LogLine("UDATA锛歶nit=%s obj=0x%08X data=0x%08X 璇诲埌 idx=%d 澶辫触锛屾湰娈垫彁鍓嶇粨鏉?,
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

/* 鍏ュ彛锛氱幆澧冨彉锟?+ 鍙窇涓€娆★紱蹇呴』鍦ㄦ父鎴忕嚎绋嬶紙DdhProcessAttrRequest 閲岋級璋冪敤锟?*/
static void DdhUdataMaybeDumpFirstRequest(void)
{
    if (!DdhUdataWanted()) return;
    if (InterlockedCompareExchange(&g_ddhUdataDone, 1, 0) != 0) return;

    LogLine("UDATA锛氬け璐ワ紝鍏变韩鍐呭瓨鏈氨缁?,
            g_ddhUdataForce ? "瑙嗛噹/绉拌皳缂哄け锛岃嚜鍔ㄨ瘖鏂? : "DDH_UDATA=dump");

    /* 锟?鍏堟帰锟?native锛氬嵆浣挎悳涓嶅埌 GetUnitData 涔熻鏈夎繖鍑犺 */
    DdhUdataProbeNatives();

    if (!g_modBase)
    {
        LogLine("UDATA锛氬け璐ワ紝game.dll 鍩哄潃涓?0锛孏etUnitData 鏃犳硶瀹氫綅");
        return;
    }

    DdhUdataSection sec[32];
    const int n = DdhUdataSections(g_modBase, sec, (int)(sizeof(sec) / sizeof(sec[0])));
    if (n <= 0)
    {
        LogLine("UDATA锛氬け璐ワ紝game.dll 鐨?PE 娈佃〃璇讳笉鍑烘潵锛孏etUnitData 鏃犳硶瀹氫綅");
        return;
    }

    /* 锟?瀛楃锟?*/
    const uint32_t strAddr = DdhUdataFindRegisterModel(sec, n);
    if (!strAddr)
    {
        LogLine("UDATA锛氬け璐ワ紝game.dll 鍙墽琛?鍙娈甸噷娌℃湁 RegisterModel锛堝惈缁撳熬 0锛夛紝GetUnitData 鏃犳硶瀹氫綅");
        return;
    }

    /* 锟?瀛楃涓插紩鐢紙mov/push 锟?4 瀛楄妭绔嬪嵆鏁帮級 */
    const uint32_t ref = DdhUdataFindStringRef(sec, n, strAddr);
    if (!ref)
    {
        LogLine("UDATA锛氬け璐ワ紝鎵惧埌 RegisterModel 瀛楃涓?0x%08X锛屼絾 .text 閲屾病鏈夊紩鐢ㄥ畠鐨勭珛鍗虫暟", strAddr);
        return;
    }

    /* 锟?ref+4 鍚庢壘 E8锛岀畻 call 鐩爣 */
    uint32_t callAddr = 0;
    const uint32_t fn = DdhUdataFindCall(sec, n, ref, &callAddr);
    if (!fn)
    {
        LogLine("UDATA锛氬け璐ワ紝RegisterModel 瀛楃涓?0x%08X 寮曠敤=0x%08X锛屼絾 +4 鍚?0x200 瀛楄妭鍐呮病鏈夋湁鏁?E8 rel32",
                strAddr, ref);
        return;
    }

    LogLine("UDATA锛歊egisterModel 瀛楃涓?0x%08X锛孍8@0x%08X锛孏etUnitData=0x%08X锛圧VA 0x%X锛?,
            strAddr, callAddr, fn, fn - g_modBase);
    LogLine("UDATA锛歊egisterModel 寮曠敤=0x%08X锛圷DWE 鍙ｅ緞锛氬紩鐢ㄧ珛鍗虫暟 +4 鍚庢壘 E8锛涘瓧绗︿覆鍦板潃鏈韩 +4 涓嶆槸鎸囦护杈圭晫锛?,
            ref);

    if (!g_shm)
    {
        LogLine("UDATA锛氬け璐ワ紝鍏变韩鍐呭瓨鏈氨缁?);
        return;
    }

    /* ---- 閫変袱涓崟浣嶏細A = 绗竴涓嫳闆勶紱B = 绫诲瀷鐮佷笉鍚岀殑鍗曚綅 ----
       鑻遍泟鍒ゅ畾浼樺厛锟?ATTR 宸茬畻濂界殑 flags锛圙etUnitTypeId+IsHeroUnitId 鎴栦笁锟?0锛夛紝
       娌℃湁 flags 鏃跺啀闂竴锟?IsHeroUnitId锛涘悕瀛椾紭鍏堢敤 ATTR 閲岀殑锛岀┖鎵嶈皟 ResolveName锟?*/
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
        LogLine("UDATA锛氱涓€娆″睘鎬ц姹傛病鏈夊彲鐢ㄥ崟浣嶏紙addr/绫诲瀷鐮佷负 0锛夛紝鏈涓?dump");
        return;
    }

    int ai = -1;
    for (int i = 0; i < ncand; ++i)
        if (cands[i].hero) { ai = i; break; }
    if (ai < 0) ai = 0;

    const int bi = DdhUdataFindB(cands, ncand, ai);

    LogLine("UDATA锛氶€夊崟浣?A=%s name=\"%s\" obj=0x%08X hero=%d锛汢=%s name=\"%s\" obj=0x%08X hero=%d锛堝€欓€?%d锛?,

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

    /* ---- 鍚屼竴涓枃浠讹紝涓ゆ锛涘厛锟?A 鍐嶅啓 B ---- */
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
        LogLine("UDATA锛氳鍛婏紝dump 鏂囦欢鎵撲笉寮€锛?s", path[0] ? path : "(绌鸿矾寰?");
    }

    DWORD excA = 0;
    const uintptr_t dataA = DdhUdataCallGetUnitData(fn, cands[ai].code, cands[ai].obj, "A", &excA);
    int linesA = 0;
    if (dataA)
        linesA = DdhUdataDumpSection(fp, (uint32_t)dataA, cands[ai].obj,
                                     cands[ai].code, cands[ai].name);
    else
        LogLine("UDATA锛欰 澶辫触锛孏etUnitData 杩斿洖 0 鎴栧紓甯?%08X", (unsigned)excA);

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
            LogLine("UDATA锛欱 澶辫触锛孏etUnitData 杩斿洖 0 鎴栧紓甯?%08X", (unsigned)excB);
    }
    else
    {
        LogLine("UDATA锛欱 鏈壘鍒帮紙鍙湁涓€涓彲鐢ㄥ崟浣嶏級锛屾湰娆″彧 dump A");
    }

    if (fp) fclose(fp);
    LogLine("UDATA锛歞ump A=%s data=0x%08X 琛屾暟=%d锛汢=%s data=0x%08X 琛屾暟=%d",
            cands[ai].type, (unsigned)dataA, linesA,
            bi >= 0 ? cands[bi].type : "-", (unsigned)dataB, linesB);
    if (path[0])
        LogLine("UDATA锛歞ump 鏂囦欢=%s", path);
}


/* ===========================================================================
   v16 璇婃柇锛欴DH_UPROBE=1 鈥旓拷?瑙嗛噹锛坰ight锟? 鑻遍泟绉拌皳锛圥ropernames锛夊弽锟?
   ---------------------------------------------------------------------------
   鍙湪绗竴娆″睘鎬ц姹傦紙娓告垙绾跨▼锛夊绗竴涓崟浣嶈窇涓€娆★細
     锟?鍗曚綅鍩烘湰淇℃伅锛歛ddr / typeCode / name / prop 鎸囬拡锟?
     锟?unit_property +0x00..+0x300 锟?dword锛沠loat 鍛戒腑宸茬煡鍊硷紙sight/nsight/
        spd/acquire/HP/STR/AGI/INT 绛夛級鏃堕澶栧啓涓€琛屽€欓€夊瓧娈靛悕锟?
     锟?GetUnitData(code) +0x00..+0x300 锟?dword锛涘儚鎸囬拡锟?dword 锟?char* 锟?
        鏈€锟?64 瀛楄妭锛屽彲鎵撳嵃锛圓SCII/UTF-8/GBK锛夊氨杩藉姞 str="..."锛屽惈 閲庣帇/瀹変笢
        鐨勯」锟?<<< 鏍囧嚭锛圲TF-8 锟?GBK 涓ょ缂栫爜閮借瘯锛夛紱
     锟?鍦ㄨ繘绋嬪彲璇汇€侀潪鏄犲儚鍐呭瓨閲屾壘 瀹変笢 锟?UTF-8锛圗5 AE 89 E4 B8 9C锛変笌
        GBK锛圔0 B2 B6 AB锛夛紝鏈€锟?8 澶勶紝鎵撳嵃姣忓鍓嶅悗锟?8 锟?dword锟?
        NUL 缁撳熬鐨勫悎娉曟枃鏈紭鍏堬紝闅忔満瀛楄妭鍛戒腑涔熶繚鐣欙紙锟?text=no锛夛拷?
   闄愰锛氭瘡娈垫渶锟?200 琛岋紱鎵弿鏈€锟?512MB / 2500ms锛涘叏锟?__try锛屽け璐ュ彧鍐欐棩蹇楋拷?
   瀹炵幇椤哄簭锛氬厛锟?鈶ｏ紙閬垮厤 dump 鏃ュ織閲岀殑鈥滃畨涓溾€濊鑷繁鎵埌锛夛紝鍐嶆墦锟?鈶犫憽鈶拷?
   鏈锟?DDH_UPROBE 锟?g_ddhUprobeOn=0锛屼竴涓瓧鑺傞兘涓嶈銆佷竴琛岄兘涓嶅啓锟?
   =========================================================================== */

#define DDH_UPROBE_MAX_HITS        8
#define DDH_UPROBE_SCAN_MAX_BYTES  (512u * 1024u * 1024u)
#define DDH_UPROBE_SCAN_TIMEOUT_MS 2500u
#define DDH_UPROBE_MAX_KNOWN_LINES 6

static int           g_ddhUprobeOn    = 0;   /* DllMain 閲岃涓€娆＄幆澧冨彉锟?*/
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

/* 姣忚鍚屾椂锟?ddh-<pid>.log 锟?ddh-<pid>.uprobe.txt锛涙枃浠舵瘡锟?flush锟?
   鐪熸満涓€斿穿浜嗕篃鑳界暀涓嬪凡锟?dump 鐨勯儴鍒嗭拷?*/
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

/* 16 杩涘埗涓诧細锟?涓滐紙UTF-8 / GBK锛夈€侀噹 鐜嬶紙UTF-8 / GBK锛夛拷?*/
static const unsigned char kDdhUprobeAntonUtf8[6]  = { 0xE5, 0xAE, 0x89, 0xE4, 0xB8, 0x9C };
static const unsigned char kDdhUprobeAntonGbk[4]   = { 0xB0, 0xB2, 0xB6, 0xAB };
static const unsigned char kDdhUprobeYewangUtf8[6] = { 0xE9, 0x87, 0x8E, 0xE7, 0x8E, 0x8B };
static const unsigned char kDdhUprobeYewangGbk[4]  = { 0xD2, 0xB0, 0xCD, 0xF5 };

/* 璇讳竴锟?0 缁撳熬瀛楃涓诧紝鏈€锟?cap-1 瀛楄妭锛涜涓嶅埌 / 娌℃湁 NUL 閮界畻澶辫触锟?*/
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
    if (n <= 0) { out[0] = 0; return 0; }   /* 娌℃湁 NUL 涔熺畻璇诲埌 cap-1 瀛楄妭锛屼笅闈㈡爣 (鎴柇) */
    out[n] = 0;
    return n;
}

static int DdhUprobeAscii(const unsigned char* p, int n)
{
    for (int i = 0; i < n; ++i)
        if (p[i] < 0x20 || p[i] > 0x7E) return 0;
    return 1;
}

/* 涓ユ牸涓€鐐圭殑 UTF-8锛氭嫆缁濇埅鏂€佸绔嬬画瀛楄妭銆佽繃闀跨紪鐮侊拷?*/
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

/* GBK锛欰SCII 鍗曞瓧锟?+ 0x81..0xFE 鍙屽瓧鑺傦紙灏惧瓧锟?0x40..0xFE锛屽幓锟?0x7F锛夛拷?*/
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
        if (c == 0x80) { ++i; continue; }   /* GBK 鐨勬鍏冪锟?*/
        if (c < 0x81 || c > 0xFE) return 0;
        if (i + 1 >= n) return 0;
        const unsigned char t = p[i + 1];
        if (t < 0x40 || t > 0xFE || t == 0x7F) return 0;
        i += 2;
    }
    return 1;
}

/* 1 = ASCII锟? = UTF-8锟? = GBK锟? = 涓嶅儚鏂囨湰銆俇TF-8 鍏堣瘯锛圙BK 鍙屽瓧锟?
   涔熻兘鈥滅宸р€濋€氳繃 GBK 鏍￠獙锛屾墍浠ヤ笉鑳藉厛锟?GBK锛夛拷?*/
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
    if ((a8 || a9) && (y8 || y9)) return "鍛戒腑 閲庣帇+瀹変笢";
    if (a8) return "鍛戒腑 瀹変笢(UTF-8)";
    if (a9) return "鍛戒腑 瀹変笢(GBK)";
    if (y8) return "鍛戒腑 閲庣帇(UTF-8)";
    if (y9) return "鍛戒腑 閲庣帇(GBK)";
    return NULL;
}

/* 鐪熸満 unit.ini 锟?H037 鏍锋湰鍊笺€傚凡鐭ュ瓧娈垫寜琛ㄦ槧灏勶紝鏈‘瀹氱殑鍏堝啓鈥滃緟纭鈥濓拷?*/
struct DdhUprobeKnownValue { float value; const char* name; };
static const DdhUprobeKnownValue kDdhUprobeKnownValues[] =
{
    { 1500.0f, "sight" },
    { 1100.0f, "nsight" },
    {  300.0f, "spd" },
    {  650.0f, "acquire" },
    {  250.0f, "寰呯‘璁?250)" },
    {  140.0f, "寰呯‘璁?140)" },
    {   1.93f, "鏀诲嚮闂撮殧/鍐峰嵈(鎺ㄦ祴)" },
    {   36.0f, "寰呯‘璁?36)" },
    {    6.0f, "寰呯‘璁?6)" },
    {    5.0f, "寰呯‘璁?5)" },
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

/* 鏈変簺瀛楁锟?int 瀛橈紙UnitBalance 锟?sight/nsight 灏辨槸锛夛細鍙 >=100 鐨勭壒寰佹暣鏁帮紝
   閬垮厤 5/6/15 杩欑鍒板閮芥湁鐨勫€煎埛灞忥紱鍗曠嫭锟?(int)锛屼笉鍗犲凡鐭ュ€煎懡涓锟?*/
static const char* DdhUprobeKnownIntName(uint32_t v)
{
    switch (v)
    {
    case 1500u: return "sight";
    case 1100u: return "nsight";
    case 650u:  return "acquire";
    case 300u:  return "spd";
    case 250u:  return "寰呯‘璁?250)";
    case 175u:  return "HP";
    case 140u:  return "寰呯‘璁?140)";
    default:    return NULL;
    }
}

/* 锟?dword 鎵撲竴娈靛唴瀛橈細tag +0x000..+0x300锟?93 琛岋級锟?
   scanStrings=1 鏃舵妸鎸囬拡 dword 锟?char* 璇伙紙鏈€锟?64 瀛楄妭锛夛紝鍙墦鍗板氨杩藉姞 str="..."锟?
   宸茬煡鍊煎尮閰嶆渶锟?6 琛岋紝淇濊瘉 193 + 6 + 娈甸 1 锟?= 200 琛屼笂闄愶拷?*/
static void DdhUprobeDumpDwords(const char* tag, uint32_t base, int scanStrings)
{
    int knownLines = 0;
    for (uint32_t off = 0; off <= 0x300u; off += 4u)
    {
        uint32_t v = 0;
        if (!DdhUdataPoke(base + off, &v))
        {
            DdhUprobeLine("%s +0x%03X  <璇诲彇澶辫触>", tag, off);
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
                    const char* cut = (sn >= (int)sizeof(s) - 1) ? " (鎴柇)" : "";
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
            _snprintf_s(knownTag, sizeof(knownTag), _TRUNCATE, "  <宸茬煡鍊?%s>", known);
        else
        {
            const char* intName = DdhUprobeKnownIntName(v);
            if (intName)
                _snprintf_s(knownTag, sizeof(knownTag), _TRUNCATE, "  <宸茬煡鍊?int):%s>", intName);
        }

        DdhUprobeLine("%s +0x%03X  dword=%08X  int=%d  float=%.4f%s%s",
                      tag, off, v, (int)v, (double)f, extra, knownTag);

        if (known && knownLines < DDH_UPROBE_MAX_KNOWN_LINES)
        {
            DdhUprobeLine("%s 鍛戒腑宸茬煡鍊硷細+0x%03X = %.4f锛?s锛?,
                          tag, off, (double)f, known);
            ++knownLines;
        }
    }
}

static void DdhUprobeDumpProp(uint32_t prop)
{
    if (!prop || !DdhPropReadable(prop))
    {
        DdhUprobeLine("PROP 涓嶅彲璇伙紙CUnit+0x1E8=0x%08X锛氫负 0 / 鍧忔寚閽?/ 鏈榻?/ 璺ㄩ〉锛夛紝璺宠繃 prop dump", prop);
        return;
    }
    DdhUprobeLine("PROP base=0x%08X锛圕Unit+0x1E8锛夛紝鑼冨洿 +0x000..+0x300", prop);
    DdhUprobeDumpDwords("PROP", prop, 0);
}

/* RegisterModel -> GetUnitData 鐨勫畾浣嶏紙锟?DDH_UDATA=dump 鍚屼竴濂楀彛寰勶級锟?*/
static uint32_t DdhUprobeFindGetUnitData(void)
{
    if (!g_modBase)
    {
        DdhUprobeLine("DATA 璺宠繃锛歡ame.dll 鍩哄潃涓?0");
        return 0;
    }
    DdhUdataSection sec[32];
    const int n = DdhUdataSections(g_modBase, sec, (int)(sizeof(sec) / sizeof(sec[0])));
    if (n <= 0)
    {
        DdhUprobeLine("DATA 璺宠繃锛歡ame.dll 鐨?PE 娈佃〃璇讳笉鍑烘潵");
        return 0;
    }
    const uint32_t strAddr = DdhUdataFindRegisterModel(sec, n);
    if (!strAddr)
    {
        DdhUprobeLine("DATA 璺宠繃锛歡ame.dll 鍙娈甸噷娌℃湁 RegisterModel 瀛楃涓诧紙鍋?game.dll 灏辨槸杩欐牱锛?);
        return 0;
    }
    const uint32_t ref = DdhUdataFindStringRef(sec, n, strAddr);
    if (!ref)
    {
        DdhUprobeLine("DATA 璺宠繃锛歊egisterModel=0x%08X 浣?.text 閲屾病鏈夊紩鐢ㄥ畠鐨勭珛鍗虫暟", strAddr);
        return 0;
    }
    uint32_t callAddr = 0;
    const uint32_t fn = DdhUdataFindCall(sec, n, ref, &callAddr);
    if (!fn)
    {
        DdhUprobeLine("DATA 璺宠繃锛歊egisterModel 寮曠敤=0x%08X锛?4 鍚庢病鏈夋湁鏁?E8 rel32", ref);
        return 0;
    }
    DdhUprobeLine("DATA GetUnitData 宸插畾浣嶏細RegisterModel=0x%08X ref=0x%08X E8@0x%08X fn=0x%08X锛圧VA 0x%X锛?,
                  strAddr, ref, callAddr, fn, fn - g_modBase);
    return fn;
}

/* ---------------- 瀛楃涓叉壂鎻忥細锟?Propernames 鐨勫瓨鏀惧 ---------------- */

struct DdhUprobeHit
{
    uint32_t addr;
    uint32_t region;
    uint32_t regionSize;
    uint32_t protect;
    int      enc;        /* 0 = UTF-8锟? = GBK */
    int      textOk;     /* 1 = 鍛戒腑鐐瑰墠鍚庤兘缁勬垚涓€锟?NUL 缁撳熬鐨勫悎娉曟枃锟?*/
};

static int DdhUprobeProtReadable(DWORD prot)
{
    if (prot & (PAGE_NOACCESS | PAGE_GUARD)) return 0;   /* 淇濇姢锟?guard 涓€璇诲氨 AV */
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

/* 鍛戒腑鐐规槸鍚﹁惤鍦ㄤ竴锟?NUL 缁撳熬鐨勫悎娉曟枃鏈噷锟?
     鍚戝墠鏈€锟?256 瀛楄妭锟?NUL 褰撲覆棣栵紙鎵句笉鍒板氨浠庡懡涓偣鏈韩寮€濮嬶級锟?
     鍚戝悗鏈€锟?511 瀛楄妭锟?NUL锛涙暣鏉′覆鎸夊搴旂紪鐮佹牎楠岋拷?
   闅忔満浜岃繘鍒堕噷鐨勫洓瀛楄妭宸у悎閫氬父鍦ㄨ繖閲岃鍒锋帀锛坱ext=no锛夛紝
   锟?Propernames锟?瀹変笢,..."锛変細寰楀埌 text=yes锟?*/
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

/* 鎵竴涓尯鍩燂紱鏂囨湰鍛戒腑锛坱ext=yes锛夊崟鐙敹闆嗭紝鍘熷瀛楄妭鍛戒腑涔熺暀锛坱ext=no锛夛拷?
   鏂囨湰鍛戒腑锟?8 澶勫氨鍋滐紱鍘熷鍛戒腑鍙敹锟?8 涓拷?*/
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
            DdhUprobeLine("STRSCAN 鏂囨湰 @0x%08X: \"%s\" [%s]", h->addr, esc,
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

    DdhUprobeLine("STRSCAN 寮€濮嬶細鎵?ANTON UTF-8=E5 AE 89 E4 B8 9C / GBK=B0 B2 B6 AB锛涗笂闄?%d 澶?/ %u MB / %u ms锛圢UL 缁撳熬鏂囨湰浼樺厛锛?,

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
                DdhUprobeLine("STRSCAN 璇诲紓甯?@0x%08X+0x%X prot=0x%X锛堣鍖哄煙璺宠繃锛?,
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

    DdhUprobeLine("STRSCAN 瀹屾垚锛氬尯锟?%d 鎵弿=%.1f MB 鏂囨湰鍛戒腑=%d 鍘熷鍛戒腑=%d 鎵撳嵃=%d "
                  "璇诲紓锟?%d 鐢ㄦ椂=%lu ms%s%s",
                  regions, (double)scanned / (1024.0 * 1024.0), textCount, rawCount, shown,
                  faults, (unsigned long)(GetTickCount() - started),
                  timedOut ? "锛堣秴鏃跺仠姝級" : "", budgetStop ? "锛堝埌 512MB 棰勭畻鍋滄锛? : "");
}

/* 鍏ュ彛锛氬彧鍦ㄧ涓€娆″睘鎬ц姹傞噷璺戜竴娆★紱娌″崟浣嶅氨绛変笅涓€杞紙鏈€锟?20 杞級锟?*/
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
            LogLine("UPROBE锛氱 %d 娆″睘鎬ц姹傛病鏈夊崟浣?s", (int)n,
                    n == 20 ? "锛屾斁寮冿紙涓嶅啀绛夛級" : "锛岀瓑涓嬩竴杞啀璇?);
        if (n >= 20) InterlockedExchange(&g_ddhUprobeDone, 1);
        return;
    }
    if (InterlockedCompareExchange(&g_ddhUprobeDone, 1, 0) != 0) return;

    char path[MAX_PATH] = { 0 };
    DdhUprobePath(path, sizeof(path));
    fopen_s(&g_ddhUprobeFp, path, "wb");
    if (!g_ddhUprobeFp)
        LogLine("UPROBE锛氳鍛婏紝dump 鏂囦欢鎵撲笉寮€锛?s", path[0] ? path : "(绌鸿矾寰?");

    const uint32_t code = SafeCode(obj);
    char type[5] = { 0 };
    DdhAttrTypeCode(code, type);
    char name[64] = { 0 };
    ResolveName(obj, code, name, sizeof(name));
    const uint32_t prop = DdhUnitProp(obj);

    DdhUprobeLine("# ddh uprobe pid=%lu obj=0x%08X code=0x%08X",
                  (unsigned long)GetCurrentProcessId(), obj, code);

    /* 鍏堟壂瀛楃涓插啀 dump锛歱rop/data 閲屾墦鍗板嚭鏉ョ殑鈥滃畨涓溾€濅細鐣欏湪鏈繘绋嬬殑
       鏃ュ織/stdio 缂撳啿閲岋紝鏀惧埌鍚庨潰鎵細鎶婅嚜宸卞垰鍐欑殑鏃ュ織褰撴垚鍛戒腑锟?*/
    DdhUprobeScan();

    DdhUprobeLine("UNIT addr=0x%08X typeCode=%s code=0x%08X name=\"%s\" prop=0x%08X",
                  obj, type, code, name, prop);

    DdhUprobeDumpProp(prop);

    const uint32_t fn = DdhUprobeFindGetUnitData();
    if (!fn)
    {
        DdhUprobeLine("DATA 璺宠繃锛欸etUnitData 鏈畾浣嶏紙prop 涓庡瓧绗︿覆鎵弿缁х画锛?);
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
            DdhUprobeLine("DATA 璺宠繃锛欸etUnitData(code=0x%08X type=%s) 杩斿洖=0x%08X 寮傚父=%08X",
                          code, type, (unsigned)(uintptr_t)data, (unsigned)exc);
        }
        else
        {
            DdhUprobeLine("DATA base=0x%08X锛圙etUnitData锛夛紝鑼冨洿 +0x000..+0x300",
                          (unsigned)(uintptr_t)data);
            DdhUprobeDumpDwords("DATA", (uint32_t)(uintptr_t)data, 1);
        }
    }

    if (g_ddhUprobeFp) { fflush(g_ddhUprobeFp); fclose(g_ddhUprobeFp); g_ddhUprobeFp = NULL; }
    LogLine("UPROBE锛氬畬鎴愶紝鏂囦欢=%s", path[0] ? path : "(鏈啓)");
}

/* ===========================================================================
   v17锛歋EEDPROBE 鈥旓拷?鐢ㄥ崟浣嶅悕瀛楃涓插湪鍐呭瓨閲屽弽鏌モ€滃崟浣嶇被鍨嬫暟鎹潡锟?
   ---------------------------------------------------------------------------
   涓轰粈涔堝仛锛堢湡锟?ddh-6076.log锛夛細
     路 鏀诲嚮鑼冨洿/鏀诲嚮锟?闂撮殧/鎶ょ敳/绉伙拷?涓夌淮/闄勫姞鍊奸兘瀵癸紝浣嗙櫧锟?澶滄櫄瑙嗛噹浠嶆槸 ?锟?
       鑻遍泟绉拌皳涓虹┖锟?
     路 DzAPI_UnitType_GetUnitTypeDataInt/String 宸插畾浣嶏紝4 绉嶅疄鍙傜粍鍚堝嵈鍏ㄩ儴杩斿洖
       0/锟?鈥旓拷?杩欎釜骞冲彴鍦ㄦ棤绛惧悕鍦板浘閲屽氨鏄┖瀹炵幇锛屼笉鑳藉啀闈犲畠锟?
     路 鍗曚綅鍚嶅瓧鑺傦紙UTF-8锛屽 閲庣帇 = E9 87 8E E7 8E 8B锛夊湪鍐呭瓨閲屾槸鐪熺殑锟?
   鎵€浠ヤ笉鐚滃亸绉伙紝鐢ㄥ凡鐭ュ瓧绗︿覆褰撶瀛愶細
     锟?鍦ㄨ繘绋嬪唴瀛橀噷鎼滃悕瀛楀師瀛楄妭 锟?瀛楃涓插湴鍧€ S锛堟渶锟?4 涓紱瑕佹眰鍛戒腑鐐规槸涓€锟?
        NUL 缁撳熬銆佹暣涓茬瓑浜庡悕瀛楃殑鍚堟硶 UTF-8 鏂囨湰锛岄伩鍏嶉殢鏈哄瓧鑺傚阀鍚堬級锟?
     锟?鍐嶆悳鈥滃摢锟?dword == S锟?锟?鎸佹湁锟?H锛堟渶锟?8 涓級锟?
     锟?瀵规瘡锟?H dump H-0x200..H+0x200锛屾瘡 4 瀛楄妭涓€琛岋細dword / int / float锟?
        锟?dword 鍍忔寚閽堟椂鍐嶅綋 char* 璇绘渶锟?96 瀛楄妭锛屽悎娉曟枃鏈氨锟?str="..." + hex锟?
     锟?锟?H-0x400..H+0x400 閲屾寜 float 鍖归厤瑙嗛噹甯歌锟?
        {1500,1100,1400,900,1800,800,1200,1600}锛堣锟?0.5锛夛紱
     锟?涓€涓寔鏈夎€呴兘娌℃湁鏃讹紙鍚嶅瓧鍙兘浠ュ唴锟?char[] 鏀惧湪鍧楅噷锛屾病鏈夋寚閽堬級锟?
        閫€鍖栦负 dump S 鏈韩锛圫ELFDUMP锛夆€旓拷?鍐呭祵甯冨眬涔熻兘鐪嬪埌鍛ㄥ洿瀛楁锟?
   瑙﹀彂锛氱幇鏈夊睘鎬ц姹傞€氶亾閲岀涓€娆￠亣鍒扳€滆嫳锟?+ 鍚嶅瓧闈炵┖鈥濈殑鍗曚綅锛屾暣涓繘绋嬪彧鍋氫竴娆★紱
         鍒ゆ嵁锟?ATTR 鐨勮嫳闆勪綅鍚屾簮锛圙etUnitTypeId+IsHeroUnitId 锟?GetHeroStr 鎴愬姛
         锟?DDH_AF_HEROKNOWN|DDH_AF_HERO锛屼笖 DDH_AF_NAME 闈炵┖锛夛拷?
   杈撳嚭锛歞dh-<pid>.seed.txt锛圲TF-8 鏂囨湰锛岃鍐呭瓧绗︿覆淇濈暀鍘熷瓧锟?+ hex锛涙渶锟?2000 琛岋級
         + ddh-<pid>.log 鐨勬憳瑕佽锟?
   鎵弿锛氬彧纰板凡鎻愪氦銆佸彲璇汇€侀潪 guard 鐨勫尯鍩燂紱璺宠繃鏈嚎绋嬫爤銆佸叡浜唴瀛樸€乨dh.dll 鑷繁锟?
         鍏堟壂闈炴槧鍍忓尯锛堢湡瀹炲爢锛夛紝娌℃壘鍒板啀琛ユ壂鏄犲儚鍖猴紙鍋囬瓟鍏界殑闈欐€佸瓧绗︿覆灏卞湪鏄犲儚閲岋級锟?
   闄愰锛氱锟?256MB / 2s锛涘弽鍚戞寚锟?512MB / 2.5s锛堝惈鏄犲儚琛ユ壂锛夛拷?
   鍏ㄧ▼ __try锛屽け璐ュ彧鍐欐棩蹇楋紝涓嶅奖鍝嶅睘鎬ц鍙栧拰浼ゅ閽╁瓙锟?
   =========================================================================== */

#define DDH_SEED_MAX_SEEDS          4
#define DDH_SEED_MAX_HOLDERS        8
#define DDH_SEED_SEED_BYTES   (256u * 1024u * 1024u)   /* 绉嶅瓙鎼滅储鎬诲瓧鑺傞锟?*/
#define DDH_SEED_SEED_MS      2000u                    /* 绉嶅瓙鎼滅储鎬绘椂闂撮锟?*/
#define DDH_SEED_PTR_BYTES    (512u * 1024u * 1024u)   /* 鍙嶅悜鎸囬拡鎬诲瓧鑺傞锟?*/
#define DDH_SEED_PTR_MS       2500u                    /* 鍙嶅悜鎸囬拡鎬绘椂闂撮锟?*/
#define DDH_SEED_IMG_BYTES    (128u * 1024u * 1024u)   /* 鏄犲儚鍖鸿ˉ鎵瓧鑺備笂锟?*/
#define DDH_SEED_MAX_LINES    2000
#define DDH_SEED_STR_MAX      96                       /* dump 閲屽瓧绗︿覆鏈€澶氳 96 瀛楄妭 */
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

static volatile LONG  g_ddhSeedArmed   = 0;   /* 宸插彂鐜拌嫳闆勫€欓€夛紝绛夋湰杞姹傚鐞嗗畬鍐嶈窇 */
static volatile LONG  g_ddhSeedDone    = 0;   /* 鏈繘绋嬪彧璺戜竴锟?*/
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

/* 鏈枃浠跺悗闈紙v9 UTF-8/GBK 鏂囨湰宸ュ叿娈碉級鎵嶅畾涔夛紱杩欓噷鍏堝０鏄庯拷?*/
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

/* 鏂囦欢姣忚 flush锛氱湡鏈轰腑閫斿穿浜嗕篃鑳界暀涓嬪凡锟?dump 鐨勯儴鍒嗭拷?
   锟?2000 琛屾椂鏈€鍚庝竴琛屽啓 (鎴柇)锛屼箣鍚庝竴涓瓧鑺傞兘涓嶅啓锟?*/
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

/* 鏈嚎绋嬫爤 + 鍏变韩鍐呭瓨瑙嗗浘銆傛爤閲屼竴瀹氭湁鍚嶅瓧鐨勫壇鏈紙nameUtf8/out->name 鐨勪腑闂存嫹璐濓級锟?
   鍏变韩鍐呭瓨閲屼篃鏈夊睘鎬у潡閲岀殑 out->name 鈥旓拷?涓嶆帓闄ょ殑璇濓紝绉嶅瓙浼氬厛鍛戒腑鎴戜滑鑷繁鐨勬嫹璐濓拷?*/
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

/* 閬嶅巻鍦板潃绌洪棿锛歩ncludeImages=0 鍙壂闈炴槧鍍忓尯锛堢湡瀹炲爢锛夛紝1 鍙壂鏄犲儚鍖猴紙闈欐€佸瓧绗︿覆锛夛拷?
   fn 杩斿洖 1 = 鎻愬墠缁撴潫锟? = 鏈尯鍩熻寮傚父锛堣烦杩囩户缁級锟?*/
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
            ok = 0;   /* ddh.dll 鑷繁锟?.data 閲屾湁 g_ddhSeedName 鍓湰 */
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

/* 鍛戒腑鐐规槸涓嶆槸涓€鏉♀€滄暣涓茬瓑浜庡悕瀛椻€濈殑鍚堟硶 UTF-8 C 瀛楃涓诧細
     路 锟?S 锟?96 瀛楄妭鍐呭繀椤绘湁 NUL锛堝紩鎿庡悕瀛楁渶锟?63 瀛楄妭 + NUL锛夛紱
     路 闀垮害蹇呴』绛変簬绉嶅瓙闀垮害锛堢瀛愯鎴柇锟?63 瀛楄妭鏃跺厑璁稿墠缂€鍖归厤锛夛紱
     路 鍛戒腑鐐瑰繀椤诲湪瀛楃杈圭晫锛堝墠涓€瀛楄妭涓嶈兘锟?0x80..0xBF 缁瓧鑺傦級锟?
   杩欐潯瑙勫垯鎶婃棩蹇楃紦鍐查噷 name="閲庣帇" title=... 閭ｇ鈥滃悕瀛楀湪闀夸覆涓棿鈥濈殑鍋囧懡涓埛鎺夛拷?*/
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
    if (seedLen < 32 && n != seedLen) return 0;   /* 鐭悕瀛楀繀椤绘暣涓茬浉绛夛紱闀垮悕瀛楀厑璁歌鎴柇 */

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

/* 鏈夌殑甯冨眬锟?sight/nsight 瀛樻垚 int锛堜笉锟?float锛夛細dump 閲屾爣 <SIGHT? int>锟?
   涓嶅啓鐙珛锟?FLOAT HIT 琛岋紙閭ｄ釜鍙 float锛夛拷?*/
static int DdhSeedSightIntMatch(uint32_t v)
{
    return v == 1500u || v == 1100u || v == 1400u || v == 900u ||
           v == 1800u || v == 800u  || v == 1200u || v == 1600u;
}

/* 瑙嗛噹甯歌鍊硷紙float锛夈€傝锟?0.5锟?*/
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

/* 鎸佹湁鑰呰瘎鍒嗭細闄勮繎鈥滄寚鍚戝悎娉曟枃鏈殑鎸囬拡鈥濊秺澶氳秺鍍忕被鍨嬫暟鎹潡锛涘啀缁欒閲庢诞鐐瑰姞鏉冿拷?
   鍙敤鏉ュ喅锟?dump 椤哄簭锟?000 琛岃涓嶄笅 8 涓寔鏈夎€呮椂锛屽厛 dump 鏈€鍍忕殑锛夛拷?*/
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

/* 瑙嗛噹娴偣鎵弿锛欻-0x400 .. H+0x400锛屽懡涓啓鏂囦欢锛涙棩蹇楅噷鏈€澶氱暀 12 鏉★紙闃插埛灞忥級锟?*/
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
            LogLine("SEEDPROBE FLOAT HIT H%+d = %.2f锛堢枒浼艰閲庯級holder=%d base=0x%08X",
                    off, (double)f, holderIndex, H);
        }
        ++hits;
    }
    return hits;
}

/* dump 瀛楃涓茶浆涔夛細UTF-8/ASCII 鍘熸牱淇濈暀鍙墦鍗板瓧鑺傦紙涓枃鍙锛夛紝鎺у埗瀛楃锟?'?'锟?
   琚垽锟?GBK 鐨勫鍗婃槸鈥滄寚閽堟伆濂芥寚鍒颁簩杩涘埗鈥濈殑宸у悎锛岄潪 ASCII 瀛楄妭涓€寰嬪啓锟?\xNN锟?
   杩欐牱鏂囦欢浠嶆槸鍚堟硶 UTF-8锛屽櫔澹拌涔熶笉浼氬嚭鐜颁竴鍫嗘浛鎹㈢锟?*/
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

/* dump 閲岀殑 float 鏄剧ず锛氭櫘閫氾拷?4 浣嶅皬鏁帮紱鏋佸ぇ/鏋佸皬鐨勪綅妯″紡鐢ㄧ瀛﹁鏁帮紝
   閬垮厤 5.3e41 杩欑鈥滄寚閽堝綋 float鈥濈殑鍊煎啓锟?50 澶氫綅鏁板瓧鎶婅鎾戠垎锟?*/
static void DdhSeedFloatText(float f, char* out, size_t cap)
{
    if (!out || cap == 0) return;
    const double a = (f < 0.0f) ? -(double)f : (double)f;
    if (f == 0.0f) _snprintf_s(out, cap, _TRUNCATE, "0.0000");
    else if (a >= 1.0e7 || a < 1.0e-4) _snprintf_s(out, cap, _TRUNCATE, "%.3e", (double)f);
    else _snprintf_s(out, cap, _TRUNCATE, "%.4f", (double)f);
}

/* H-0x200 .. H+0x200 锟?dword dump锟?
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

/* 瑙﹀彂鍊欓€夛細ATTR 宸插垽瀹氣€滄槸鑻遍泟鈥濓紙GetUnitTypeId+IsHeroUnitId 鎴栦笁锟?> 0锟?
   锟?DDH_AF_HERO 鍚屾簮锛夛紝涓斿悕瀛楅潪绌猴紙绉嶅瓙蹇呴』鏈夊瓧鑺傦級锟?*/
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

/* 鍦ㄥ睘鎬ц姹傚惊鐜噷璋冪敤锛氬彧鍋氣€滆浣忓€欓€夆€濓紝鐪熸鎵弿鏀惧埌鏈疆 doneSeq 鍐欏洖涔嬪悗锟?
   杩欐牱 C# 鍏堟嬁鍒拌繖涓€杞睘鎬э紝涓嶄細鍥犱负鎵弿鍗′綇鑰岃秴鏃讹拷?*/
static void DdhSeedProbeNote(uint32_t obj, const DdhUnitAttr* a)
{
    if (g_ddhSeedArmed) return;
    if (!DdhSeedIsHeroCandidate(a)) return;
    if (InterlockedCompareExchange(&g_ddhSeedArmed, 1, 0) != 0) return;

    g_ddhSeedUnit = obj;
    g_ddhSeedCode = SafeCode(obj);
    DdhUtf8SafeCopy(g_ddhSeedName, sizeof(g_ddhSeedName), a->name, sizeof(g_ddhSeedName) - 1);
    LogLine("SEEDPROBE锛氬凡閿佸畾绗竴涓嫳闆勫€欓€?addr=0x%08X code=0x%08X锛堟湰杞睘鎬у啓鍥炲悗寮€濮嬫壂鎻忥級",
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

    LogLine("SEEDPROBE锛氬紑濮嬶紙鍗曚綅 code=%s name=\"%s\"锛塧ddr=0x%08X 鍚嶅瓧=%d 瀛楄妭 hex=%s",
            type, nameUtf8, g_ddhSeedUnit, nameLen, nameHex);
    if (nameLen <= 0)
    {
        LogLine("SEEDPROBE锛氬悕瀛椾负绌猴紝娌℃湁绉嶅瓙锛屾湰娆′笉鎵?);
        return;
    }

    DdhSeedPath(g_ddhSeedPath, sizeof(g_ddhSeedPath));
    if (fopen_s(&g_ddhSeedFp, g_ddhSeedPath, "wb") != 0 || !g_ddhSeedFp)
    {
        g_ddhSeedFp = NULL;
        LogLine("SEEDPROBE锛氳鍛婏紝鏂囦欢鎵撲笉寮€锛?s", g_ddhSeedPath[0] ? g_ddhSeedPath : "(绌鸿矾寰?");
        return;
    }

    /* 鎵撳紑鏂囦欢鍚庡厛鍙啓涓嶅惈鍚嶅瓧鍘熷瓧鑺傜殑 ASCII 澶达細鏂囦欢锟?CRT 缂撳啿涔熷湪鍫嗕笂锟?
       濡傛灉锟?"閲庣帇" 鍐欒繘鍘诲啀鎵紝灏变細鍏堝懡涓嚜宸辩殑鏂囦欢缂撳啿锟?*/
    DdhSeedLine("# ddh SEEDPROBE pid=%lu started_ms=%lu", (unsigned long)GetCurrentProcessId(),
                (unsigned long)started);
    DdhSeedLine("# unit=0x%08X code=%s name_len=%d name_hex=%s",
                g_ddhSeedUnit, type, nameLen, nameHex);
    DdhSeedLine("# tags: NAME=pointer to seed string; str/hex=dword read as C string (<=96B,"
                " GBK-ish bytes escaped as \\xNN); SIGHT?=float near 1500/1100/1400/900/1800/800/1200/1600");

    DdhSeedSkip skips[4];
    const int nskips = DdhSeedCollectSkips(skips, 4);
    LogLine("SEEDPROBE锛氭帓闄ゅ尯 %d 涓紙鏈嚎绋嬫爤 + 鍏变韩鍐呭瓨锛夛紝鍚嶅瓧绉嶅瓙=%d 瀛楄妭",
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

    LogLine("SEEDPROBE锛氬悕瀛楃瀛愭壂鎻?瀹屾垚锛氬懡涓?%d 鍖哄煙=%d 鎵弿=%.1f MB 璇诲紓甯?%d 鐢ㄦ椂=%lu ms%s%s",
            hitCount, stSeed.regions, (double)stSeed.scanned / (1024.0 * 1024.0),
            stSeed.faults, (unsigned long)(GetTickCount() - started),
            stSeed.timedOut ? "锛堣秴鏃跺仠姝級" : "", stSeed.budgetStop ? "锛堝埌 256MB 棰勭畻鍋滄锛? : "");

    /* 鎵弿瀹屾垚鍚庡啀鎶婂悕瀛楀師瀛楄妭鍐欒繘鏂囦欢锛堟鏃朵笉浼氬啀鎵埌瀹冿級锟?*/
    char nameEsc[420] = { 0 };
    DdhUprobeEscape(nameEsc, sizeof(nameEsc), nameUtf8, (size_t)nameLen);
    DdhSeedLine("SEEDPROBE START unit=0x%08X code=%s name_len=%d", g_ddhSeedUnit, type, nameLen);
    DdhSeedLine("SEEDPROBE NAME text=\"%s\" hex=%s", nameEsc, nameHex);

    for (int i = 0; i < hitCount; ++i)
    {
        DdhSeedLine("SEEDPROBE SEED[%d] addr=0x%08X region=0x%08X+0x%X prot=0x%X (%s)",
                    i, hits[i].addr, hits[i].region, hits[i].regionSize, hits[i].protect,
                    hits[i].image ? "image" : "heap");
        LogLine("SEEDPROBE锛歋[%d]=0x%08X锛?s 鍖?0x%08X+0x%X prot=0x%X锛?,
                i, hits[i].addr, hits[i].image ? "鏄犲儚" : "鍫?,
                hits[i].region, hits[i].regionSize, hits[i].protect);
    }

    if (hitCount <= 0)
    {
        DdhSeedLine("SEEDPROBE RESULT seeds=0 (name bytes not found)");
        LogLine("SEEDPROBE锛氬唴瀛橀噷娌℃壘鍒板悕瀛楀師瀛楄妭锛?d 瀛楄妭锛夆€斺€旀病鏈?S锛屾棤娉曞弽鏌ユ寔鏈夎€咃紱"
                "鏂囦欢鍙暀澶达紙鍙敤 DDH_UPROBE=1 鐨勫叏閲?STRSCAN 浜ゅ弶鏍稿锛?, nameLen);
        return;
    }

    uint32_t seeds[DDH_SEED_MAX_SEEDS];
    memset(seeds, 0, sizeof(seeds));
    for (int i = 0; i < hitCount; ++i) seeds[i] = hits[i].addr;

    /* 锟?鍙嶅悜鎸囬拡锛氫竴娆℃壂瀹屾暣鍦板潃绌洪棿锛屽悓鏃跺尮閰嶆墍锟?S锛堜笉锟?S 鍚勬壂涓€閬嶏級锟?*/
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

    LogLine("SEEDPROBE锛氬弽鍚戞寚閽?瀹屾垚锛氭寔鏈夎€?%d 鍖哄煙=%d 鎵弿=%.1f MB 璇诲紓甯?%d 鐢ㄦ椂=%lu ms%s%s",
            holderCount, stPtr.regions, (double)stPtr.scanned / (1024.0 * 1024.0),
            stPtr.faults, (unsigned long)(GetTickCount() - started),
            stPtr.timedOut ? "锛堣秴鏃跺仠姝級" : "", stPtr.budgetStop ? "锛堝埌棰勭畻鍋滄锛? : "");

    if (holderCount <= 0)
    {
        LogLine("SEEDPROBE锛氭病鏈?dword 鎸囧悜绉嶅瓙鍦板潃锛堝悕瀛楀彲鑳芥槸鍐呭祵 char[]锛夆啋 鏀逛负 dump 绉嶅瓙鑷韩");
        DdhSeedLine("SEEDPROBE HOLDER none -> SELFDUMP seed=0x%08X", seeds[0]);
        g_ddhSeedInfo.floatHits += DdhSeedFloatScan(seeds[0], -1);
        DdhSeedDump(seeds[0], -1, seeds, hitCount);
        ++g_ddhSeedInfo.dumped;
        DdhSeedLine("SEEDPROBE RESULT seeds=%d holders=0 dumped=1 float_hits=%d lines=%d%s",
                    hitCount, g_ddhSeedInfo.floatHits, g_ddhSeedLines,
                    g_ddhSeedTruncated ? " (truncated)" : "");
        return;
    }

    /* 璇勫垎鍙喅锟?dump 椤哄簭锟?000 琛岃涓嶄笅 8 涓寔鏈夎€呮椂锟?dump 鏈€鍍忕被鍨嬫暟鎹潡鐨勶拷?*/
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
        LogLine("SEEDPROBE锛氭寔鏈夎€匸%d]=0x%08X 鎸囧悜 S[%d]=0x%08X score=%d",
                i, holders[i].addr, holders[i].seedIndex, seeds[holders[i].seedIndex],
                holders[i].score);
    }

    for (int i = 0; i < holderCount; ++i)
    {
        if (g_ddhSeedTruncated) break;
        const uint32_t H = holders[i].addr;
        /* 鍏堝仛瑙嗛噹娴偣鎵弿锟?dump锛氳鏁拌鎴柇鏃讹紝瑙嗛噹鍛戒腑涓€瀹氬凡缁忓啓杩涙枃浠讹拷?*/
        g_ddhSeedInfo.floatHits += DdhSeedFloatScan(H, i);
        DdhSeedDump(H, i, seeds, hitCount);
        ++g_ddhSeedInfo.dumped;
    }

    DdhSeedLine("SEEDPROBE RESULT seeds=%d holders=%d dumped=%d float_hits=%d lines=%d%s",
                hitCount, holderCount, g_ddhSeedInfo.dumped, g_ddhSeedInfo.floatHits,
                g_ddhSeedLines, g_ddhSeedTruncated ? " (truncated)" : "");
}

/* 鍏ュ彛锛氬睘鎬ц姹傚鐞嗗畬锛坉oneSeq 宸插啓鍥烇級鍚庡湪娓告垙绾跨▼璋冪敤锛屾暣涓繘绋嬪彧璺戜竴娆★拷?*/
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
        LogLine("SEEDPROBE锛氶噰闆嗗紓甯?code=0x%08X锛堝凡鍚炴帀锛屼笉褰卞搷灞炴€ц鍙?浼ゅ閽╁瓙锛?,
                (unsigned)GetExceptionCode());
    }

    if (g_ddhSeedFp)
    {
        fflush(g_ddhSeedFp);
        fclose(g_ddhSeedFp);
        g_ddhSeedFp = NULL;
    }

    g_ddhSeedInfo.elapsed = GetTickCount() - started;
    LogLine("SEEDPROBE锛氬畬鎴?s锛屾枃浠?%s 琛屾暟=%d%s 绉嶅瓙=%d 鎸佹湁鑰?%d dump=%d 娴偣鍛戒腑=%d 鐢ㄦ椂=%lu ms",
            exc ? "锛堟湁寮傚父锛? : "",
            g_ddhSeedPath[0] ? g_ddhSeedPath : "(鏈啓)",
            g_ddhSeedLines, g_ddhSeedTruncated ? "锛堝凡鎴柇锛? : "",
            g_ddhSeedInfo.seedHits, g_ddhSeedInfo.holderCount, g_ddhSeedInfo.dumped,
            g_ddhSeedInfo.floatHits, (unsigned long)g_ddhSeedInfo.elapsed);
}

/* 姣忚疆灞炴€ц姹傜粨鏉熷悗璋冪敤锛氬凡閿佸畾鑻遍泟鍊欓€夊氨寮€璺戯紙鍙竴娆★級锟?*/
static void DdhSeedProbeTick(void)
{
    if (!g_ddhSeedArmed) return;
    if (InterlockedCompareExchange(&g_ddhSeedDone, 1, 0) != 0) return;
    DdhSeedProbeRun();
}

/* ===========================================================================
   v18 璇婃柇锛欴DH_UNITDUMP=1 鈥旓拷?鐩存帴 dump 绗竴涓嫳闆勭殑 CUnit 鑷韩
   ---------------------------------------------------------------------------
   涓婁竴锟?SEEDPROBE 鐢ㄥ悕瀛楀瓧鑺傚湪鍐呭瓨閲屽弽鏌モ€滅被鍨嬫暟鎹潡鈥濓紝鐪熸満缁撹鏄悕瀛楀湪澶у瓧绗︿覆姹犻噷锟?
   娌℃湁浠讳綍 dword 鎸囧悜绉嶅瓙鍦板潃锛堝紩鎿庣敤姹犲唴鍋忕Щ/string id锛屼笉锟?char*锛夛紝閭ｆ潯璺蛋涓嶉€氾拷?
   CUnit 鏈潵灏卞湪鎴戜滑鎵嬮噷锛堝睘鎬ц姹傜殑 addr锛夛紝鎵€浠ユ敼鎴愮洿锟?dump unit+0x00..+0x400锟?
     路 锟?4 瀛楄妭涓€琛岋細UNIT +0x%03X dword=%08X int=%d float=%.3f
     路 float 鍛戒腑 {1500,1100,1400,900,1800,800,1200,1600,650,550}锛堣锟?0.5锛夋爣 <SIGHT?>
     路 姣忎釜鍍忔寚閽堢殑 dword锟?x10000..0x7FFFFFFF锛夊皾璇曞綋 char* 锟?96 瀛楄妭锛屽彲璇绘枃鏈氨锟?str="..."
       锛圲TF-8/GBK/ASCII 閮借瘯锛涙枃鏈唴瀹瑰師鏍疯緭鍑猴紝涓枃閲屽彲鑳藉氨鏈夎嫳闆勭О璋擄級
   瑙﹀彂鏂瑰紡锛堜竴娆¤繘绋嬪彧鍋氫竴娆★紱杈撳嚭 ddh-<pid>.unit.txt锛屾渶锟?1200 琛岋紱鏃ュ織鍙啓鎽樿锛夛細
     路 榛樿 AUTO锛氱涓€涓嫳闆勭殑鈥滅О锟?鐧藉ぉ瑙嗛噹/澶滄櫄瑙嗛噹鈥濇湁缂哄け鏃惰嚜锟?dump锛堟甯稿浘涓嶅啓鏂囦欢锛夛紱
     路 寮哄埗锛欴DH_UNITDUMP=1锛屾垨 ddh.dll 鍚岀洰褰曟斁涓€锟?ddh_unitdump.on 鏂囦欢锟?
     路 鍏抽棴锛欴DH_UNITDUMP=0锟?
   =========================================================================== */
#define DDH_UNITDUMP_MAX_LINES 1200
#define DDH_UNITDUMP_SPAN      0x400
#define DDH_UNITDUMP_STR_MAX   96

static int           g_ddhUnitDumpMode      = 1;   /* 0=off 1=auto 2=force锛圖llMain 瀹氬瀷锟?*/
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

/* 杩斿洖 0 = 鏄庣‘鍏抽棴锟? = 鏄庣‘寮哄埗锟?1 = 娌¤缃紙锟?AUTO锛夛拷?*/
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

/* 鏂囦欢寮€鍏筹細ddh.dll / ddh-<pid>.log 鍚岀洰褰曚笅锟?ddh_unitdump.on锟?
   鍚姩鍣ㄤ笉缁ф壙鐜鍙橀噺鏃讹紝鐢ㄦ埛鏀句竴涓┖鏂囦欢鍗冲彲寮哄埗 dump锟?*/
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

/* 鍙啓 unit.txt锛堜笉閫愯鍒锋棩蹇楋紝鏃ュ織鏈€鍚庡彧鍐欐憳瑕侊級銆傛渶锟?1200 琛岋拷?*/
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
    if (!DdhSeedIsHeroCandidate(a)) return;   /* 鍒ゆ嵁锟?SEEDPROBE 瀹屽叏涓€锟?*/
    if (g_ddhUnitDumpMode == 1)
    {
        /* AUTO锛氬彧鏈夌О锟?鐧藉ぉ瑙嗛噹缂哄け锟?dump 鈥旓拷?姝ｅ父鍥句竴涓枃浠堕兘涓嶅啓锟?
           v14 澶滄櫄瑙嗛噹锛坣sight锛夊厑璁稿悎娉曠己澶憋紙鏈変簺 slk 娌℃湁 nsight锛夛紝涓嶈Е鍙戣瘖鏂拷?*/
        const uint32_t need = DDH_AF_TITLE | DDH_AF_SIGHT_DAY;
        if ((a->flags & need) == need) return;
        g_ddhUdataForce = 1;   /* 鍚屼竴娆¤嚜鍔ㄨ瘖鏂噷椤哄甫 dump GetUnitData 鍗曚綅鏁版嵁锟?*/
    }
    if (InterlockedCompareExchange(&g_ddhUnitDumpArmed, 1, 0) != 0) return;

    g_ddhUnitDumpUnit = obj;
    g_ddhUnitDumpCode = SafeCode(obj);
    DdhUtf8SafeCopy(g_ddhUnitDumpName, sizeof(g_ddhUnitDumpName),
                    a->name, sizeof(g_ddhUnitDumpName) - 1);

    char type[8] = { 0 };
    DdhAttrTypeCode(g_ddhUnitDumpCode, type);
    LogLine("UNITDUMP锛氬凡閿佸畾绗竴涓嫳闆?addr=0x%08X code=%s name=\"%s\"锛?s锛屾湰杞睘鎬у啓鍥炲悗 dump unit+0x000..+0x%03X锛?,
            obj, type, g_ddhUnitDumpName,
            g_ddhUnitDumpMode == 1 ? "鑷姩锛氱О璋?瑙嗛噹缂哄け" : "寮哄埗寮€鍚?,
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

/* 锟?4 瀛楄妭 dump 涓€娈靛唴瀛橈細UNIT / TYPE / PROP 鍏辩敤锟?*/
static void DdhUnitDumpBlock(const char* tag, uint32_t base, uint32_t span)
{
    for (uint32_t off = 0; off <= span; off += 4u)
    {
        uint32_t v = 0;
        if (!DdhUdataPoke(base + off, &v))
        {
            DdhUnitDumpLine("%s +0x%03X dword=-------- int=- float=nan  <璇诲彇澶辫触>", tag, off);
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
                    const char* cut = (sn >= (int)sizeof(str) - 1) ? " (鎴柇)" : "";
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
        LogLine("UNITDUMP锛氳鍛婏紝鏂囦欢鎵撲笉寮€锛?s锛堟湰娆′笉 dump锛?);
        return;
    }

    char type[8] = { 0 };
    DdhAttrTypeCode(g_ddhUnitDumpCode, type);
    DdhUnitDumpLine("# ddh UNITDUMP pid=%lu started_ms=%lu", (unsigned long)GetCurrentProcessId(),
                    (unsigned long)started);
    DdhUnitDumpLine("# unit=0x%08X code=%s name=\"%s\"", g_ddhUnitDumpUnit, type, g_ddhUnitDumpName);
    DdhUnitDumpLine("# CUnit/TYPE/BALANCE/PROP 姣?4 瀛楄妭涓€琛岋紱<SIGHT?> = float 鎴?int 鍛戒腑瑙嗛噹鍊欓€夊€硷紱str=鎸囬拡 dword 褰?char* 璇诲埌鐨勬枃鏈?);

    DdhUnitDumpBlock("UNIT", g_ddhUnitDumpUnit, DDH_UNITDUMP_SPAN);

    /* CUnit+0x1F0锛欸etHeroProperName 鍐呴儴灏辨槸 mov ecx,[ecx+1F0] 鍚庡彇鏁版嵁锟?
       璇存槑瀹冩槸鈥滃崟浣嶇被鍨嬫暟鎹€濆璞★紱Propernames/sight/nsight/spd/def 寰堝彲鑳介兘鍦ㄨ繖閲岋拷?*/
    uint32_t typePtr = 0;
    if (DdhUdataPoke(g_ddhUnitDumpUnit + 0x1F0u, &typePtr) &&
        typePtr >= 0x10000u && typePtr <= 0x7FFFFFFFu)
    {
        DdhUnitDumpLine("# TYPE base=0x%08X锛?(unit+0x1F0)锛屽崟浣嶇被鍨嬫暟鎹級", typePtr);
        DdhUnitDumpBlock("TYPE", typePtr, DDH_UNITDUMP_SPAN);
    }
    else
    {
        DdhUnitDumpLine("# TYPE 璺宠繃锛?(unit+0x1F0)=0x%08X 涓嶅彲璇?, typePtr);
    }

    /* CUnit+0x1EC锛歐FE 鐨勮缁嗛槻寰℃彁绀猴紙绉伙拷?+ 瑙嗛噹锛夊氨鏄粠杩欏潡瀵硅薄璇荤殑锟?
       娓告垙 0x6F3B6FAD 锟?mov edi,[edi+1EC]锛岄殢鍚庣敤 edi 锟?0x6F5DF1E0 鍙栫Щ閫燂紱
       sight/nsight 寰堝彲鑳戒篃鍦ㄨ繖鍧楅噷锛屼紭鍏堢湅杩欓噷鑰屼笉鏄彧锟?GetUnitData锟?*/
    uint32_t balancePtr = 0;
    if (DdhUdataPoke(g_ddhUnitDumpUnit + 0x1ECu, &balancePtr) &&
        balancePtr >= 0x10000u && balancePtr <= 0x7FFFFFFFu)
    {
        DdhUnitDumpLine("# BALANCE base=0x%08X锛?(unit+0x1EC)锛學FE 闃插尽鎻愮ず鐨勭Щ閫?瑙嗛噹瀵硅薄锛?, balancePtr);
        DdhUnitDumpBlock("BALANCE", balancePtr, DDH_UNITDUMP_SPAN);
    }
    else
    {
        DdhUnitDumpLine("# BALANCE 璺宠繃锛?(unit+0x1EC)=0x%08X 涓嶅彲璇?, balancePtr);
    }

    /* CUnit+0x1E8锛歶nit_property锛堟敾鍑昏寖锟?鏀诲嚮锟?鎶ょ敳绛夊唴瀛樼洿璇绘簮锛夛拷?*/
    uint32_t propPtr = 0;
    if (DdhUdataPoke(g_ddhUnitDumpUnit + 0x1E8u, &propPtr) &&
        propPtr >= 0x10000u && propPtr <= 0x7FFFFFFFu)
    {
        DdhUnitDumpLine("# PROP base=0x%08X锛?(unit+0x1E8)锛寀nit_property锛?, propPtr);
        DdhUnitDumpBlock("PROP", propPtr, 0x300u);
    }
    else
    {
        DdhUnitDumpLine("# PROP 璺宠繃锛?(unit+0x1E8)=0x%08X 涓嶅彲璇?, propPtr);
    }

    if (g_ddhUnitDumpFp)
    {
        fflush(g_ddhUnitDumpFp);
        fclose(g_ddhUnitDumpFp);
        g_ddhUnitDumpFp = NULL;
    }
    LogLine("UNITDUMP锛氬畬鎴愶紝鏂囦欢=%s 琛屾暟=%d%s 鎸囬拡鏂囨湰=%d 瑙嗛噹鍛戒腑=%d 鐢ㄦ椂=%lu ms",
            path[0] ? path : "(鏈啓)", g_ddhUnitDumpLines,
            g_ddhUnitDumpTruncated ? "锛堝凡鎴柇锛? : "",
            g_ddhUnitDumpStrHits, g_ddhUnitDumpSightHits,
            (unsigned long)(GetTickCount() - started));

    /* 瑙嗗浘/绉拌皳缂哄け瑙﹀彂鐨勮嚜鍔ㄨ瘖鏂細椤哄甫 dump 涓€锟?GetUnitData锛圲nitBalance 鍘熷鍧楋級锟?
       鍐欏埌 ddh-<pid>.udata.txt銆傜幆澧冨彉锟?DDH_UDATA=dump 鏃跺師鏈篃浼氳蛋杩欓噷锟?*/
    if (g_ddhUnitDumpMode == 1) DdhUdataMaybeDumpFirstRequest();
}

static void DdhUnitDumpTick(void)
{
    if (g_ddhUnitDumpMode == 0) return;
    if (!g_ddhUnitDumpArmed) return;
    if (InterlockedCompareExchange(&g_ddhUnitDumpDone, 1, 0) != 0) return;
    DdhUnitDumpRun();
}

/* ---- 璇锋眰澶勭悊锛堝彧鍦ㄦ父鎴忕嚎绋嬶級---- */
static volatile LONG g_ddhAttrBusy     = 0;
static uint32_t      g_ddhAttrLastSeq  = 0;
static uint32_t      g_ddhAttrPostedSeq = 0;   /* 鐑敭绾跨▼鐢細宸茬粡鎶曢€掕繃鐨勮姹傚簭锟?*/
static volatile LONG g_ddhAttrRounds   = 0;

static void DdhProcessAttrRequest(void)
{
    if (!g_shm) return;
    const uint32_t req = g_shm->attrs.requestSeq;
    if (req == 0 || req == g_ddhAttrLastSeq) return;
    if (InterlockedCompareExchange(&g_ddhAttrBusy, 1, 0) != 0) return;

    /* v16 璇婃柇锛欴DH_UPROBE=1 鏃讹紝绗竴娆″睘鎬ц姹傚仛涓€娆″叏閲忓弽锟?dump锟?*/
    DdhUprobeEntry();

    /* v14 璇婃柇锛欴DH_UDATA=dump 鏃讹紝鍙湪绗竴娆″睘鎬ц姹傞噷 dump 涓€娆″崟浣嶆暟鎹潡锟?*/
    DdhUdataMaybeDumpFirstRequest();

    /* 绗竴娆¤姹傛椂锟?native 琛ㄥ叏锟?dump 涓€娆★紝骞舵寜鍏抽敭瀛楀缓鑷姩鍖归厤鍊欓€夛拷?
       鏀惧湪 __try 涔嬪涔熸病鍏崇郴锛欴dhAttrDumpNativesOnce 鑷繁鍏ㄧ▼ __try锟?*/
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
            DdhUnitDumpNote(addr, out);   /* v18锛欴DH_UNITDUMP=1 鏃堕攣瀹氱涓€涓嫳锟?*/
            units++;
            if (out->flags == 0) invalid++;
        }
        MemoryBarrier();
        g_shm->attrs.doneSeq = req;      /* 鏈€鍚庡啓锛欳# 锟?doneSeq == requestSeq 鍒ゅ畾杩欎竴杞畬锟?*/
        g_ddhAttrLastSeq = req;

        const LONG round = InterlockedIncrement(&g_ddhAttrRounds);
        if (round <= 6 || (round % 300) == 0)
            LogLine("ATTR round %d锛歴eq=%u units=%d invalid=%d锛堝崟浣嶅睘鎬ц姹傚凡鍥炲啓 doneSeq锛?, (int)round, req, units, invalid);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("ATTR round 寮傚父 code=%08X锛堝凡鍚炴帀锛宒oneSeq 浠嶇劧鍐欏洖锛岄伩鍏嶇晫闈竴鐩寸瓑锛?,
                (unsigned)GetExceptionCode());
        g_shm->attrs.doneSeq = req;
        g_ddhAttrLastSeq = req;
    }
    InterlockedExchange(&g_ddhAttrBusy, 0);

    /* v17锛氳嫳闆勫€欓€夊凡閿佸畾灏卞紑锟?SEEDPROBE锛坉oneSeq 宸插啓鍥烇紝C# 涓嶄細绛夊畠锛夛拷?*/
    DdhSeedProbeTick();

    /* v18锛欴DH_UNITDUMP=1 鏃讹紝鍦ㄥ悓涓€娓告垙绾跨▼鐩存帴 dump 绗竴涓嫳闆勭殑 CUnit 鑷韩
       锛堜笉璧板悕瀛楃锟?鎸囬拡鍙嶆煡锛涘彧锟?unit+0x00..+0x400锛夛拷?*/
    DdhUnitDumpTick();
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
    e->seq        = seq;
    e->tickMs     = GetTickCount();
    e->victim     = victim;
    e->victimCode = SafeCode(victim);
    e->source     = source;
    e->sourceCode = SafeCode(source);
    memcpy(&e->amount, &amountBits, 4);
    e->flag       = flag;
    e->attackType = attackType;
    e->damageMask = mask;
    e->weaponType = weapon;
    e->isPhysical = isPhysical;
    e->stackSource = stackSource;
    /* v3锛氬厛锟?enter 渚х殑琛€锛沘fter 鐢辫繑鍥炶烦鏉胯ˉ */
    e->hpBefore   = hpBefore;
    e->hpAfter    = 0.0f;
    e->actual     = 0.0f;
    e->hpValid    = 0;
    e->depth      = depth;
    e->engineDamage = 0.0f;
    e->engineValid  = 0;
    e->setDamage    = 0.0f;
    e->setCalls     = 0;
    /* v20锛氬嚭鍙ｄ笁璇荤殑鏈€缁堜激瀹筹紝锟?DdhDamageFunc 鍦ㄥ師鍑芥暟杩斿洖鍚庤ˉ */
    e->finalDamage  = 0.0f;
    e->finalFlags   = 0;
    /* v7锛氱洰鏍囧崟浣嶈潡铏紙椹敳锛夋爣璁般€侴etUnitAbilityLevel(handle, 'Aloc') > 0 锟?bit0锟?
       锟?YDWE 鍚屽彛寰勶紙YDWETriggerEvent.j锛欰loc <= 0 = 鏅€氬崟浣嶏紝> 0 = 椹敳锛夛紝鍙湅鎶€鑳斤拷?
       鍙栦笉鍒帮紙native 娌″畾锟?/ 鍙ユ焺澶辫触 / 寮傚父锛夊氨锟?0锛岀粷涓嶈鏉€姝ｅ父鍗曚綅锟?
       v13 璇婃柇锛氬墠 5 娆℃棤鏉′欢鍐欐棩蹇楋紙level<=0銆乭andle==0 閮藉啓锛夛紝鐢ㄦ潵鍖哄垎
       鈥渙bj鈫抙andle 澶辫触鈥濃€渘ative 娌″畾浣嶁€濃€滄煡鍒颁簡锟?level=0鈥濅笁绉嶆儏鍐碉拷?*/
    e->flags = 0;
    {
        const uint32_t vh = HpObjToHandle(victim);
        uint32_t fn = 0;
        int level = -1;                         /* -1 = 娌℃煡鎴愶紙鍙ユ焺锟?native 缂哄け锟?*/
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
                    e->flags |= 1u;   /* bit0 = 鐩爣甯﹁潡锟?鏄┈锟?*/
                    /* v21锛氳浣忕被鍨嬬爜锛屽悗缁悓鐮佸崟浣嶅嵆浣挎病鏈夊彞鏌勪篃鍒ゅ畾涓鸿潡锟?*/
                    DdhAlocCodeRemember(e->victimCode);
                }
            }
        }
        /* v21锛氬彞鏌勬嬁涓嶅埌锛屼絾鍚岀被鍨嬬爜宸茶瀹炴祴涓鸿潡锟?锟?浠嶆寜椹敳澶勭悊 */
        if (!vh && e->victimCode && DdhAlocCodeKnown(e->victimCode)) e->flags |= 1u;
        if (InterlockedIncrement(&g_locustLogCount) <= 5)
        {
            char codeTxt[8] = { 0 };
            DdhCodeText(e->victimCode, codeTxt, sizeof(codeTxt));
            if (!vh)
                LogLine("铦楄櫕鍒ゅ畾锛歶nit=0x%08X code=%s handle=0x%08X level=%d锛坥bj鈫抙andle 澶辫触锛屾湭鏌ユ妧鑳斤級",
                        victim, codeTxt, vh, level);
            else if (!fn)
                LogLine("铦楄櫕鍒ゅ畾锛歶nit=0x%08X code=%s handle=0x%08X level=%d锛圙etUnitAbilityLevel native 鏈畾浣嶏紝鏈煡鎶€鑳斤級",
                        victim, codeTxt, vh, level);
            else
                LogLine("铦楄櫕鍒ゅ畾锛歶nit=0x%08X code=%s handle=0x%08X level=%d",
                        victim, codeTxt, vh, level);
        }
    }
    /* v8锛氭簮/鐩爣鎵€灞炵帺瀹跺彿锛圝ASS GetOwningPlayer/GetPlayerId锛涘け锟?-1锛屼笉鐚溿€佷笉宕╋級 */
    e->victimOwner = ResolveOwnerPid(victim);
    e->sourceOwner = ResolveOwnerPid(source);
    {
        const LONG n = InterlockedIncrement(&g_ownerLogCount);
        if (n <= 5)
            LogLine("鐜╁鍙凤細victim=0x%08X鈫扨layer %d锛宻ource=0x%08X鈫扨layer %d锛?1=鏈煡锛? 鍩猴級",
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
    g_shm->hdr.lastTick = e->tickMs;
    MemoryBarrier();
    if (outSeq) *outSeq = seq;
    return slot;
}

/* ===========================================================================
   v9锛氱儹閿紙Ctrl+Alt+R / S / Q锟? 璁板綍鍗曚綅 + 姝讳骸缁撶畻骞挎挱
   ---------------------------------------------------------------------------
   绾跨▼妯″瀷锛堝拰鎻掍欢 UDamageWatcherHook.cpp 鐨勨€滅儹閿嚎锟?-> 娓告垙绾跨▼鎵ц鈥濆悓鎬濊矾锛夛細
      * 鐑敭绾跨▼ DdhHotkeyThreadProc 鍙仛涓変欢浜嬶細RegisterHotKey銆丟etMessage锟?
        鎶婂緟鍔炴爣蹇椾綅锟?1锛岀劧锟?PostMessage 缁欐父鎴忕獥鍙ｃ€備笉璇绘父鎴忓唴瀛樸€佷笉璋冨紩鎿庡嚱鏁帮拷?
      * v12锛堢敤鎴峰弽棣堚€滄寜浜嗙儹閿绛夋尐鎵撴墠鍑烘彁绀猴紝寤惰繜涓嶅彲鎺ュ彈鈥濓級锛氬姩锟?*绔嬪埢**锟?
        娓告垙绾跨▼鎵ц 鈥旓拷?瀛愮被鍖栨父鎴忕獥鍙ｏ紙SetWindowLongPtrW锛夛紝鐑敭绾跨▼
        PostMessage(WM_APP+0xDD)锛屾父鎴忕獥鍙ｈ繃绋嬮噷褰撳満锟?DdhProcessPending()锟?
        浠ュ墠鍙妸寰呭姙鎸傚湪鈥滀笅涓€娆′激瀹充簨浠垛€濅笂锛屾墍浠ユ病浼ゅ灏变竴鐩翠笉鍝嶅簲锟?
      * 姝讳骸缁撶畻浠嶇劧锟?DdhProcessDeferred() 鍦ㄣ€愭渶澶栧眰銆戜激瀹冲嚱鏁伴€€鍑哄悗鍙戯拷?鈥旓拷?
        閭ｆ潯蹇呴』鍦ㄥ紩鎿庢墸琛€杩囩▼涔嬪璺戯紝璺熺儹閿棤鍏筹拷?
      * 浼ゅ浜嬩欢璺緞閲屼篃淇濈暀涓€锟?DdhProcessPending()锛氱獥鍙ｆ病鎵惧埌 / PostMessage 澶辫触
        鏃堕€€鍖栨垚鏃ц涓猴紝涓嶈嚦浜庡畬鍏ㄦ病鍙嶅簲锟?
      * 鐑敭绾跨▼绗竴娆¤鎷夎捣涔熸槸锟?DdhDamageFunc 閲岋紙杩涘浘鍚庢墠鍙兘鏈変激瀹筹級锟?
        涓嶅湪 DllMain 锟?CreateThread锛岄伩鍏嶅姞杞藉櫒閿佹湡闂磋捣绾跨▼锟?

   閫夊尯閾撅紙锟?C# 锟?Core/Probe.cs銆丆ore/Wc3Game.cs 瀹屽叏涓€鑷达紝鐓ф妱鍋忕Щ锛夛細
     ctx    = *(game.dll + 0xBE4238)
     pid    = *(u16*)(ctx + 0x28)                  鏈湴鐜╁锟?
     player = *(u32*)(ctx + 0x58 + 4*pid)          鏈湴鐜╁瀵硅薄
     sel    = *(u32*)(player + 0x34)               閫夊尯瀹瑰櫒
     node   = *(u32*)(sel + 0x1F0)                 棣栦釜閫変腑鑺傜偣锛堝鐢ㄩ摼 sel + 0x08锟?
     unit   = *(u32*)(node + 8)                    鍗曚綅瀵硅薄
   姣忎竴璺抽兘鍏堝仛鍦板潃鍖洪棿妫€鏌ワ紝鏁存鍐嶅寘 __try/__except锛涘彇涓嶅埌鍙啓鏃ュ織锟?

   娑堟伅鍙ｅ緞锛坴11锛氳亰澶╅噷**鍙彂鏉ユ簮鍗犳瘮**锛屼富娈垫寜鐢ㄦ埛瑕佹眰涓嶅啀鏄剧ず锛夛細
     姝讳骸缁撶畻   锟?銆愪激瀹炽€戦洩锟?0.0% 鐙间汉20.0%
     Ctrl+Alt+Q 锟?銆愬綋鍓嶄激瀹炽€戦洩锟?0.0% 鐙间汉20.0%
      鍗犳瘮 = 璇ユ潵婧愬噣鎺夎 梅 危鍑€鎺夎锛埼ｅ噣锟?0 鏃堕€€鍥炲師濮嬩激瀹冲彛寰勶紝涓庝富鐣岄潰涓€鑷达級
   鍚嶅瓧/鏃堕棿/鍙楀嚮娆℃暟/鍑€鎺夎/鏈€澶у崟锟?鍙暀鍦ㄧ晫闈㈠拰鏃ュ織閲岋紙鏃ュ織浼氬師鏍锋墦鏁存潯娑堟伅锛夛拷?
   Ctrl+Alt+R / S 鐨勫弽棣堝彧鍦ㄦ湰鏈烘秷鎭尯锛堛€愬凡閫変腑銆戯拷?/ 銆愬凡鍙栨秷銆戔€︼級锛屼笉杩涘叕鍏辫亰澶╋拷?
   =========================================================================== */

/* ---- 鐑敭 ID锛氬閮ㄦ祴璇曡剼锟?PostThreadMessage(WM_HOTKEY, 杩欎釜 id) 涔熻兘瑙﹀彂 ---- */
#define DDH_HK_ID_R   0xD0D1u
#define DDH_HK_ID_S   0xD0D2u
#define DDH_HK_ID_Q   0xD0D3u
#define DDH_HK_ID_C   0xD0D4u
#define DDH_HK_ID_D   0xD0D5u
#define DDH_HK_ID_E   0xD0D6u   /* Ctrl+Alt+D锛歮ock 鏁版嵁婕旂ず鍥捐〃锛堣皟鏍峰紡鐢級 */
#ifndef MOD_NOREPEAT
#define MOD_NOREPEAT  0x4000u
#endif

/* ---- 鐩存姇鑱婂ぉ锛堟棤妗嗙洿鎶曪級鐢ㄥ埌锟?6 锟?game.dll 锟?RVA ----
   涓庢彃锟?v1.4.1/v1.4.21 鐨勨€滅洿鎶曡亰澶┾€濆畬鍏ㄧ浉鍚岋紙閭ｈ竟宸插疄鏈洪獙璇佽繃鏁村锛夛細
     0x34F3A0  get_unit(idx,0)        __fastcall(0,0)锛孾obj+0x3FC] = 鑱婂ぉ UI 瀵硅薄
     0x392060  clear_chat(obj, idx)   __thiscall
     0x3B2DE0  set_recipient(obj,sel) __thiscall锟?=鍏ㄩ儴 1=鐩熷弸 2=瑙傚療锟?
     0x3B3B80  SetText(obj, utf8)     __thiscall
     0x14D670  get_game_wnd(idx)      __fastcall(0,0) -> HWND
     0x153710  娓告垙绐楀彛杩囩▼(hwnd,msg,wp,lp)
   涓轰粈涔堜富璺敤杩欏銆佽€屼笉鏄洿鎺ヨ皟 InGameChatWhat锟?x355CF0锛夛細
     InGameChatWhat 鍙槸鈥滄妸涓€琛岃亰澶╃敾鍒拌亰澶╁尯鈥濈殑鏄剧ず鍑芥暟锛屾湰鍦拌皟鐢ㄥ彧鍦ㄦ湰鏈哄彲瑙侊拷?
     涓嶄細鍙戠粰鍏朵粬鐜╁锛涙彃浠朵粨搴撱€奧FE鍠婅瘽鏈哄埗涓庤亰澶╃绾块€嗗悜.md銆嬶拷? 瀹炴祴涔熻瘉锟?
     鏈湴鐜╁鑷繁鍙戠殑娑堟伅鏍规湰涓嶇粡杩囨姇閫掑櫒 0x562E0銆傜湡姝ｈ兘璁╁埆浜虹湅鍒扮殑锟?
     鈥滄妸鏂囨湰濉炶繘娓告垙鑱婂ぉ杈撳叆锟?+ 璁╂父鎴忚嚜宸辩殑绐楀彛杩囩▼鏀跺埌涓€娆″洖杞︹€濓紝
     涔熷氨鏄笅闈㈣繖濂楀凡缁忓疄鏈鸿窇閫氱殑鐩存姇娉曪拷?*/
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
static int            g_ddhChatOk       = 0;   /* 1 = 6 涓湴鍧€搴忚█鍏ㄩ儴閫氳繃 */

/* ---- 鐑敭绾跨▼鐘舵€侊紙鐑敭绾跨▼鍙啓鈥滃緟鍔炩€濊繖 3 涓爣蹇楋紝鍏朵綑閮藉綊娓告垙绾跨▼锟?---- */
static volatile LONG  g_ddhHkStarted   = 0;
static volatile LONG  g_ddhHkStop      = 0;
static DWORD          g_ddhHkThreadId  = 0;
static HANDLE         g_ddhHkThread    = NULL;
static volatile LONG  g_ddhPendR       = 0;
static volatile LONG  g_ddhPendS       = 0;
static volatile LONG  g_ddhPendQ       = 0;
static volatile LONG  g_ddhPendC       = 0;   /* Ctrl+Alt+C锛氱敤鏈€杩戝彈鍑诲崟浣嶅紑涓€娆℃壙浼ゅ浘琛紙璋冭瘯/鑷祴锟?*/
static volatile LONG  g_ddhPendD       = 0;
static DWORD          g_ddhDllTick = 0;   /* DLL 鍔犺浇鏃跺埢 鈮?杩涘浘鏃跺埢锛堝浘琛ㄦ椂闂存爣绛惧熀鍑嗭級 */
static volatile LONG  g_ddhPendE       = 0;   /* Ctrl+Alt+D锛歮ock 鏁版嵁婕旂ず鍥捐〃锛堣皟鏍峰紡锟?*/
static volatile LONG  g_ddhAutoSend    = 1;    /* 榛樿寮€锛汼 鍒囨崲 */
static volatile LONG  g_ddhHkPressLogged  = 0;
static volatile LONG  g_ddhHkActionLogged = 0;
static volatile LONG  g_ddhHkFailLogged   = 0;
static volatile LONG  g_ddhHkToggleLogged = 0;
static volatile LONG  g_ddhHkQueryLogged  = 0;
static volatile LONG  g_ddhHkPanelLogged  = 0;

/* v17锛氶紶鏍囨暣鍧楃偣鍑婚潰鏉垮睍寮€/鏀惰捣锛堜笉鍐嶆湁蹇嵎閿級銆傚懡涓煩褰㈡槸褰掍竴鍖栧潗鏍囷拷?*/
static volatile LONG  g_ddhPanelClickOk   = 0;
static volatile LONG  g_ddhPanelMouseDown = 0;
static float          g_ddhPanelHitL = 0.0f;
static float          g_ddhPanelHitT = 0.0f;
static float          g_ddhPanelHitW = 0.0f;
static float          g_ddhPanelHitH = 0.0f;
static int      g_ddhChartMode = 0;
static int      g_ddhChartCollapsed = 1;   /* 榛樿鏀剁缉 */
static float    g_ddhChartW = 0.34f, g_ddhChartH = 0.32f;
static float    g_ddhChartWantX = 0.60f, g_ddhChartWantY = -0.10f;
static float    g_ddhChartX = 0.60f, g_ddhChartY = -0.24f, g_ddhChartFh = 0.0135f;
static volatile LONG  g_ddhPanelLastToggle = 0;
static volatile LONG  g_ddhPanelClickLogged = 0;
static volatile LONG  g_ddhPanelFrameRectOk = 0;
static float          g_ddhPanelFrameL = 0.0f;
static float          g_ddhPanelFrameT = 0.0f;
static float          g_ddhPanelFrameR = 0.0f;
static float          g_ddhPanelFrameB = 0.0f;

/* ---- 璁板綍鍗曚綅 + 瀹冭嚜宸辩殑缁熻锛堝彧鍦ㄦ父鎴忕嚎绋嬭鍐欙紝涓嶉渶瑕侀攣锟?---- */
#define DDH_SRC_MAX 32

struct DdhSrcStat
{
    uint32_t source;    /* 鏉ユ簮鍗曚綅瀵硅薄鎸囬拡锛堢爜鐩稿悓灏卞悎骞讹紝鎸囬拡鍙暀绗竴涓級 */
    uint32_t code;      /* 鏉ユ簮绫诲瀷锟?*/
    uint32_t hits;
    float    maxHit;
    double   raw, engine, map, net;
    char     label[96]; /* 绗竴娆¤鍒板畠鏃舵煡濂界殑鈥滃悕锟?锟?鈥濃€斺€斿彂閫佹椂涓嶅啀纰板彲鑳藉凡閲婃斁鐨勬寚锟?*/
};

struct DdhTrack
{
    uint32_t   unit;        /* 0 = 杩樻病璁板綍鍗曚綅 */
    uint32_t   code;
    uint32_t   hits;
    uint32_t   startMs;
    uint32_t   srcCount;
    uint32_t   dead;        /* 1 = 宸茬粡骞挎挱杩囨浜★紝绛夊畠澶嶆椿鍐嶉噸鏂扮粺锟?*/
    float      maxHit;
    double     raw, engine, map, net;
    char       label[96];   /* 锟?R 鏃舵煡濂界殑鈥滃悕锟?锟?锟?*/
    DdhSrcStat src[DDH_SRC_MAX];
};

static DdhTrack g_ddhTrack;

/* ---- 鍏ㄥ眬鈥滄瘡涓彈鍑诲崟浣嶁€濈殑绱锛歈 鍦ㄦ病鏈夎褰曞崟浣嶆椂鍙戝畠锟?Top5 ---- */
#define DDH_GLOBAL_MAX 128

struct DdhVictimStat
{
    uint32_t unit;
    uint32_t code;
    uint32_t hits;
    float    maxHit;
    double   net, raw;
    char     label[96]; /* 绗竴娆¤鍒板畠鏃舵煡濂界殑鈥滃悕锟?锟?锟?*/
};

static DdhVictimStat g_ddhGlobal[DDH_GLOBAL_MAX];
static int           g_ddhGlobalCount = 0;

/* ---- 寰呭彂閫佺殑缁撶畻锛堟父鎴忕嚎绋嬪唴濉啓銆佹父鎴忕嚎绋嬪唴鍙戦€侊級 ---- */
static char          g_ddhDeferText[768];
static volatile LONG g_ddhDeferKind   = 0;     /* 1 = 鏈変竴鏉℃浜＄粨绠楃瓑鐫€锟?*/
static volatile LONG g_ddhSendOkCount = 0;
static volatile LONG g_ddhSendFailCnt = 0;
static volatile LONG g_ddhSendSkipLogged = 0;
static volatile LONG g_ddhMsgLogCount  = 0;   /* 鈥滅粍濂界殑娑堟伅鈥濇棩蹇楅檺娴侊紙锟?60 鏉★級 */

/* ---- 鍏滃簳鏄剧ず锛圖isplayTimedTextToPlayer锛夌殑鐘讹拷?---- */
static uint32_t      g_ddhNatDtttp      = 0;
static uint32_t      g_ddhNatPlayer     = 0;
static uint32_t      g_ddhNatGetPlayers = 0;
static volatile LONG g_ddhDtttpTries    = 0;
static volatile LONG g_ddhPlayerTries   = 0;
static volatile LONG g_ddhPlayersTries  = 0;
static volatile LONG g_ddhDtttpFailLogged = 0;

/* ---------------------------------------------------------------------------
   鍑犱釜灏忓伐锟?
   --------------------------------------------------------------------------- */

/* 4 瀛楄妭绫诲瀷锟?-> 鍙鏂囨湰銆傚唴瀛橀噷鏄弽搴忓瓨鐨勶紙锟?SafeCode 娉ㄩ噴锛夛紝
   鎵€浠ユ寜 dword 鐨勯珮瀛楄妭鍒颁綆瀛楄妭鎵撳嵃灏辨槸鏄剧ず椤哄簭锟?hfoo"/"opeo"鈥︼級锟?*/
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

/* v11锛氭秷鎭噷涓嶅啀甯︽椂闂达紙涓绘宸插幓鎺夛級锛屽嚱鏁扮暀鐫€澶囩敤 */
static void DdhFormatHms(char* out, size_t cap)
{
    SYSTEMTIME st;
    GetLocalTime(&st);
    DdhSprintf(out, cap, "%02d:%02d:%02d", (int)st.wHour, (int)st.wMinute, (int)st.wSecond);
}

static void DdhTruncateUtf8(char* s, size_t cap, size_t maxBytes);   /* 瀹氫箟鍦ㄥ悗锟?*/

/* 锟?鈥滃悕锟?绫诲瀷锟?锟?鎷艰繘鍥哄畾澶у皬锟?out锟?*涓嶈秺鐣屻€佷笉鍒囧潖 UTF-8銆佷笉瑙﹀彂鏃犳晥鍙傛暟**锟?
   鍚嶅瓧鍏堟寜 UTF-8 杈圭晫鎴埌鈥滄斁寰椾笅 锟?锟?锟?+ 缁撴潫绗︹€濈殑闀垮害锛屽啀锟?_snprintf_s(...,_TRUNCATE)锟?
   锛坰printf_s 鏀句笉涓嬩細 _invoke_watson 锟?__fastfail(0xC0000409)锛氱湡锟?2026-10-31 20:22:52
     灏辨槸闀垮悕锟?鈥溾€︹€︺€愯緟鍔╁崟浣嶏拷?e009)锟?鍐欒繘 64 瀛楄妭鏍囩鎶婃父鎴忓甫璧扮殑銆傦級 */
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
        const size_t reserve = strlen(codeTxt) + 3;          /* '(' + 锟?+ ')' + 缁撴潫锟?*/
        const size_t room    = (cap > reserve + 1) ? cap - reserve : 1;
        DdhTruncateUtf8(fitted, sizeof(fitted), room);        /* 锟?UTF-8 杈圭晫鎴柇骞惰ˉ 鈥溾€︼拷?*/
        DdhSprintf(out, cap, "%s(%s)", fitted, codeTxt);
    }
    else if (hasName) DdhSprintf(out, cap, "%s", name);
    else if (hasCode) DdhSprintf(out, cap, "%s", codeTxt);
    else              DdhSprintf(out, cap, "?");
}

/* 鍗曚綅鏄剧ず鍚嶏細浼樺厛寮曟搸鏌ュ埌鐨勫悕瀛楋紝鏌ヤ笉鍒伴€€鍥炵被鍨嬬爜锛屽啀涓嶈閫€鍥炲璞℃寚閽堬拷?
   ResolveName 鍐呴儴鏈夆€滅被鍨嬬爜鈫掑悕瀛椻€濈紦瀛樹笌鏃ュ織闄愭祦锛涜繖閲屽湪娓告垙绾跨▼璋冪敤锟?*/
static void DdhUnitLabel(uint32_t unit, uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    char name[96] = { 0 };
    char codeTxt[8] = { 0 };
    if (code) DdhCodeText(code, codeTxt, sizeof(codeTxt));

    if (unit >= 0x10000u && unit <= 0x7FFFFFFFu)
        ResolveName(unit, code, name, sizeof(name));

    if (!name[0] && !codeTxt[0] && unit)
    {
        DdhSprintf(out, cap, "0x%08X", unit);
        return;
    }
    DdhComposeLabel(name, codeTxt, out, cap);
}

/* 鍙戦€佹椂鐢ㄧ殑鏍囩锛氫紭鍏堢敤鏃╁氨鏌ュソ鐨勭紦瀛橈紝缁濅笉鍐嶅幓纰板彲鑳藉凡缁忛噴鏀剧殑鍗曚綅鎸囬拡 */
static void DdhLabelOf(const char* label, uint32_t code, uint32_t unit, char* out, size_t cap)
{
    if (label && label[0]) { strncpy_s(out, cap, label, _TRUNCATE); return; }
    char codeTxt[8] = { 0 };
    if (code) DdhCodeText(code, codeTxt, sizeof(codeTxt));
    if (codeTxt[0])      DdhSprintf(out, cap, "%s", codeTxt);
    else if (unit)       DdhSprintf(out, cap, "0x%08X", unit);
    else                 DdhSprintf(out, cap, "?");
}

/* 杩藉姞锟?0 缁撳熬鐨勫瓧绗︿覆锛堣嚜鍔ㄦ埅鏂紝涓嶄細瓒婄晫锟?*/
static void DdhAppendFmt(char* dst, size_t cap, const char* fmt, ...)
{
    const size_t used = strlen(dst);
    if (used + 1 >= cap) return;
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(dst + used, cap - used, _TRUNCATE, fmt, ap);
    va_end(ap);
}

/* 鍦板浘浼ゅ锛堢敓鏁堝€硷級锛氫笌 C# 锟?HookEvent.EffectiveDamage 鍚屽彛锟?*/
static double DdhEventEffective(const DdhEvent* e)
{
    /* v20锛氭渶缁堝€硷紙鍑哄彛 *out锛変紭锟?鈥旓拷?瀹冨氨鏄紩鎿庣湡姝ｆ墸涓嬪幓鐨勯偅涓暟锛屼笖宸插惈鍦板浘鏀瑰啓锟?
       bit0 鍙湪"纭疄鎺変簡琛€"鏃舵墠缃綅锛屾墍浠ヨ繖閲屼笉鐢ㄥ啀锟?>0.005锟?*/
    if (e->finalFlags & 1u) return (double)e->finalDamage;
    if (e->setCalls > 0) return (double)e->setDamage;
    return e->hpValid ? (double)e->actual : 0.0;
}

/* ---------------------------------------------------------------------------
   v10/v11 鏂囨湰鎷艰锛氫慨鈥滃悕瀛椾贡鐮佲€濓紝娑堟伅鍙彂鏉ユ簮鍗犳瘮锛堜富娈典笉鍙戜簡锟?
   ---------------------------------------------------------------------------
   缂栫爜浜嬪疄锛堢湡鏈烘棩锟?ddh-17256.log 瀹炶瘉锛夛細
     路 寮曟搸 0x326BA0 杩斿洖鐨勫崟浣嶅悕**鏈韩灏辨槸 UTF-8 瀛楄妭**
       锛堚€滈洩鐙硷拷?= E9 9B AA E7 8B BC锛屸€滄ⅵ骞讳集鐖碉拷?= E6 A2 A6 E5 B9 BB E4 BC AF E7 88 B5锛夛紱
       ResolveName 鍙槸鎶婅繖浜涘瓧鑺傚師鏍锋嫹锟?victimName/sourceName锛屾病鏈夎浆鐮侊拷?
     路 鏈枃浠惰嚜宸辩殑涓枃鏍囩锟?GBK 瀛楅潰閲忥紙婧愮爜鏈韩锟?GBK锛夛拷?
   鎵€浠ヤ竴鏉℃秷鎭ぉ鐒舵槸鈥滀袱绉嶇紪鐮佹贩鎺掆€濓紝**缁濅笉鑳芥暣娈靛啀锟?GBK 杞竴锟?* 鈥旓拷?
   閭ｇ瓑浜庢妸宸茬粡锟?UTF-8 鐨勫悕瀛楀張锟?GBK 瑙ｄ竴閬嶏紝鑱婂ぉ閲屽氨鎴愪簡鈥滃鈥濆姞鎬鍙烽偅绉嶄贡鐮侊拷?
   缁勬秷鎭殑瑙勭煩锛堟湰鏂囦欢鎵€鏈夊彂鍑哄幓鐨勬秷鎭兘璧拌繖濂楋級锟?
     锟?涓枃鏍囩锛欸BK 瀛楅潰锟?锟?UTF-8 ................ DdhAppendLabel
     锟?鍗曚綅锟? 锛氬師濮嬪瓧鑺傜洿鎺ユ嫾銆佷笉鍐嶈浆锟?.......... DdhAppendUnitName
     锟?鍚嶅瓧閲岃嫢娌℃湁鍚堟硶 UTF-8锛堜緥锟?GBK 鍚嶅瓧鐨勫绔嬮珮浣嶅瓧鑺傦級锛屽彧锟?*杩欎釜鍚嶅瓧**
        鏁翠綋锟?GBK鈫扷TF-8 杞竴娆″綋鍥為€€锛屽苟鍦ㄦ棩蹇楅噷鍐欐槑鏈潯璧颁簡鍝潯璺拷?
   --------------------------------------------------------------------------- */

/* 涓€鏉¤亰澶╂秷鎭殑 UTF-8 瀛楄妭涓婇檺銆傛棫锟?240 澶煭锛屽瓧娈典竴澶氬氨琚埅鎴愨€溾€︽潵鈥︼拷?
   锛堢湡鏈洪偅鏉″氨鏄鎴柇鐨勶級锛屾斁锟?420 澶熸斁瀹屾暣銆愪激瀹炽€戞锟?*/
#define DDH_MSG_MAX_BYTES   420
/* 銆愪激瀹炽€戞榛樿鍒楀嚑涓潵婧愶紙鎸夊噣鎺夎鍗犳瘮闄嶅簭锟?*/
#define DDH_SHARE_TOP       3

/* 鏈潯娑堟伅閲岀殑鍚嶅瓧璧颁簡鍝潯璺紙姣忔缁勬秷鎭墠娓呴浂锛屽彂閫佹椂鍐欒繘鏃ュ織锟?*/
static int  g_msgNameRawUtf8     = 0;    /* 锟?鍚堟硶 UTF-8 锟?鍘熷瓧鑺傛嫾锟?*/
static int  g_msgNameGbkFallback = 0;    /* 锟?闈炴硶 UTF-8 锟?鏁翠綋锟?GBK 杞竴锟?*/
static volatile LONG g_msgNameFallbackLogged = 0;

/* 涓€娈靛瓧鑺傛槸涓嶆槸鍚堟硶 UTF-8锛氭嫆缁濆绔嬬画瀛楄妭 0x80~0xBF锟?xF8~0xFF銆佽繃闀跨紪鐮侊拷?
   浠ｇ悊鍖恒€佽秴 0x10FFFF銆傜┖涓叉寜鈥滀笉鍚堟硶鈥濊繑鍥烇紙璋冪敤鏂瑰綋鈥滄病鍚嶅瓧鈥濆鐞嗭級锟?*/
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
        else return false;                                  /* 0x80~0xBF 瀛ょ珛 / 0xF8~0xFF */
        if (i + need >= n) return false;                    /* 灏惧反琚埅锟?*/
        for (int k = 1; k <= need; k++)
        {
            if ((p[i + k] & 0xC0) != 0x80) return false;
            cp = (cp << 6) | (uint32_t)(p[i + k] & 0x3F);
        }
        if ((need == 1 && cp < 0x80u) || (need == 2 && cp < 0x800u) ||
            (need == 3 && cp < 0x10000u)) return false;      /* 杩囬暱缂栫爜 */
        if (cp >= 0xD800u && cp <= 0xDFFFu) return false;    /* 浠ｇ悊锟?*/
        if (cp > 0x10FFFFu) return false;
        i += need + 1;
    }
    return true;
}

/* GBK -> UTF-8锛氱粰鈥滄湰鏂囦欢鐨勪腑鏂囨爣绛锯€濆拰鈥滃悕瀛椾笉锟?UTF-8 鏃剁殑鍥為€€鈥濈敤锟?
   杞崲澶辫触灏辨寜鍘熷瓧鑺傛嫹璐濓紙瀹佸彲涔辩爜涔熶笉涓㈠瓧锛夛紝杩斿洖 false锟?*/
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

/* UTF-8 -> GBK锟?*鍙粰鍐欐棩蹇楃敤**锛堟棩蹇楁枃浠舵槸 GBK锛岀洿鎺ュ啓 UTF-8 鍦ㄨ浜嬫湰閲屾槸涔辩爜锛夛拷?*/
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

/* 杩藉姞涓€锟?ASCII 鎴栧凡纭锟?UTF-8 鐨勫瓧鑺傦紙瓒婄晫鑷姩鎴柇锛屾案锟?0 缁撳熬锟?*/
static void DdhAppendRaw(char* dst, size_t cap, const char* s)
{
    if (!dst || cap < 2 || !s || !s[0]) return;
    const size_t used = strlen(dst);
    if (used + 1 >= cap) return;
    size_t room = cap - used - 1;                 /* 鐣欎竴涓瓧鑺傜粰 NUL */
    size_t n = strlen(s);
    if (n > room) n = room;
    if (n == 0) return;
    memcpy(dst + used, s, n);
    dst[used + n] = 0;
}

/* 杩藉姞涓枃鏍囩锛氭簮鐮佹湰韬氨锟?UTF-8锛坉dh.cpp 宸茬粺涓€ UTF-8 缂栫爜锛夛紝鍘熸牱鎷煎嵆鍙拷?
   锛堣€佺増鏈簮鐮佹槸 GBK锛岄偅鏃舵墠闇€锟?GBK鈫扷TF-8锛涚幇鍦ㄥ啀杞竴娆″弽鑰屼細鍙樹贡鐮併€傦級 */
static void DdhAppendLabel(char* dst, size_t cap, const char* labelUtf8)
{
    if (!dst || cap < 2 || !labelUtf8 || !labelUtf8[0]) return;
    DdhAppendRaw(dst, cap, labelUtf8);
}

/* 杩藉姞鍗曚綅鍚嶏細**寮曟搸缁欑殑鍘熷瓧鑺傜洿鎺ユ嫾**锛堝畠灏辨槸 UTF-8锛屽啀杞竴娆℃墠浼氫贡锛夛拷?
   鍙湁涓嶆槸鍚堟硶 UTF-8 鏃舵墠閫€鍥炩€滄暣涓悕瀛楁寜 GBK鈫扷TF-8 杞竴娆♀€濓紝骞惰鏃ュ織璇存槑璧颁簡鍝潯璺拷?*/
static void DdhAppendUnitName(char* dst, size_t cap, const char* raw)
{
    if (!dst || cap < 2 || !raw || !raw[0]) return;

    if (DdhUtf8Valid(raw))                        /* 锟?鐪熸満灏辨槸杩欐潯璺細鍘熸牱锟?*/
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
            LogLine("娑堟伅缂栫爜锛氬崟浣嶅悕涓嶆槸鍚堟硶 UTF-8锛屾湰鏉℃寜 GBK鈫扷TF-8 鍥為€€锛堝師瀛楄妭 hex=%s锛?, hex);
        }
        DdhAppendRaw(dst, cap, utf8);
        return;
    }

    /* 涓ゆ潯璺兘涓嶉€氾細鎸夊師瀛楄妭鎷硷紝涓嶄涪鍐呭銆佷笉锟?*/
    g_msgNameGbkFallback++;
    DdhAppendRaw(dst, cap, raw);
}

/* 纭埅鏂埌 maxBytes 瀛楄妭锛氫笉鍒囧潖姹夊瓧锛屾湯灏捐ˉ 鈥溾€︹€濓紙UTF-8 = E2 80 A6锛夛拷?
   cap 鏄紦鍐插尯鎬诲閲忥紱maxBytes 浼氳澶瑰埌 cap-1 浠ュ唴锟?*/
static void DdhTruncateUtf8(char* s, size_t cap, size_t maxBytes)
{
    if (!s || cap < 2) return;
    if (maxBytes + 1 > cap) maxBytes = cap - 1;
    if (strlen(s) <= maxBytes) return;

    size_t cut = maxBytes > 3 ? maxBytes - 3 : maxBytes;   /* 锟?3 瀛楄妭缁欏熬锟?鈥溾€︼拷?*/
    while (cut > 0 && ((unsigned char)s[cut] & 0xC0) == 0x80) cut--;   /* 鍒垏鍦ㄦ眽瀛椾腑锟?*/
    s[cut] = 0;
    if (maxBytes >= cut + 3)
    {
        memcpy(s + cut, "\xE2\x80\xA6", 3);
        s[cut + 3] = 0;
    }
}

/* "闆嫾(hfoo)" -> "闆嫾"锛氥€愪激瀹炽€戞閲屽彧瑕佸悕瀛楋紙鎴栫被鍨嬬爜锛夛紝涓嶅甫绫诲瀷鐮佸悗缂€锟?*/
static void DdhStripCodeSuffix(const char* label, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    if (!label || !label[0]) return;

    const size_t n = strlen(label);
    if (n >= 7 && label[n - 1] == ')')
    {
        const char* lp = strrchr(label, '(');
        if (lp && (size_t)(label + n - 1 - lp) == 5)       /* "(XXXX)" 姝ｅソ 6 涓瓧锟?*/
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
   娑堟伅锛堟浜＄粨锟?/ Ctrl+Alt+Q 瀹炴椂缁熻锟?
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   銆愪激瀹炽€戞锛氭潵锟?Top N锛堥粯锟?3锛夛紝锟?*鍑€鎺夎鍗犳瘮**闄嶅簭锛屾瘡锟?鈥滃悕瀛楁垨绫诲瀷锟?+ 涓€浣嶅皬鏁扮櫨鍒嗘瘮鈥濓拷?
   ---------------------------------------------------------------------------
   鍙ｅ緞涓庝富鐣岄潰锛圕# Core/HookBreakdown.cs 锟?PercentOf锛夊畬鍏ㄤ竴鑷达細
     鍗犳瘮 = 璇ユ潵婧愬噣鎺夎 梅 鏁存潯 危鍑€鎺夎锟?
     危鍑€鎺夎 <= 0锛堣繖鏉＄粨绠楁病鏈夊彲淇¤閲忥級鏃堕€€鍥炩€滃師濮嬩激瀹斥€濆彛寰勶紝鍏嶅緱鏁存锟?0%锟?
   鍙嫾鈥滈」鈥濈殑閮ㄥ垎锛堜笉鍚€愪激瀹炽€戞爣绛撅級锛岄」涔嬮棿涓€涓┖鏍硷拷?
   杩斿洖鍐欒繘鍘荤殑椤规暟锟? = 娌℃湁鍙樉绀虹殑鏉ユ簮锛岃皟鐢ㄦ柟灏卞埆鎵撱€愪激瀹炽€戞浜嗭級锟?*/
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

    /* 鎸夊崰姣斿彛寰勬帓搴忥紙鍑€鎺夎浼樺厛锛浳ｅ噣锟?0 鏃舵寜鍘熷浼ゅ锟?*/
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
        if (v <= 0.01) continue;                       /* 0% 鐨勬潵婧愪笉娴垂鑱婂ぉ闀垮害 */
        double pct = v * 100.0 / denom;
        pct = floor(pct * 10.0 + 0.5) / 10.0;          /* 鍥涜垗浜斿叆锟?0.1 */
        if (pct < 0.1) pct = 0.1;                      /* 鏈変激瀹冲氨鍒樉绀烘垚 0.0% */
        if (pct > 100.0) pct = 100.0;

        char label[96]    = { 0 };
        char nameOnly[96] = { 0 };
        char num[16]      = { 0 };
        DdhLabelOf(s->label, s->code, s->source, label, sizeof(label));
        DdhStripCodeSuffix(label, nameOnly, sizeof(nameOnly));
        DdhSprintf(num, sizeof(num), "%.1f%%", pct);

        if (used) DdhAppendRaw(out, outCap, " ");
        DdhAppendUnitName(out, outCap, nameOnly);      /* 鍚嶅瓧锛氬紩鎿庡師瀛楄妭鐩存帴锟?*/
        DdhAppendRaw(out, outCap, num);
        used++;
    }
    return used;
}

/* 缁勪竴鏉♀€滄潵婧愬崰姣斺€濇枃鏈紙姝讳骸缁撶畻 锟?Ctrl+Alt+Q 鍏辩敤鍚屼竴濂楁嫾娉曪級锟?
     isDeath=1 锟?銆愪激瀹炽€戦洩锟?0.0% 鐙间汉20.0%          锟?姝讳骸缁撶畻灏卞彂杩欎竴鏉★紝涓嶅啀甯︿富锟?
     isDeath=0 锟?銆愬綋鍓嶄激瀹炽€戦洩锟?0.0% 鐙间汉20.0%      锟?Ctrl+Alt+Q
   鎸夌敤鎴疯姹傦紝涓绘锛堛€愭浜＄粨绠椼€戝悕锟?鏃堕棿 鍙楀嚮N锟?鍑€X 鏈€澶锟?*涓嶅啀锟?*锟?
   鍚嶅瓧/鏃堕棿/閲嶅嚮鏁板瓧鍙暀鍦ㄧ晫闈㈠拰鏃ュ織閲岋紝鑱婂ぉ閲屽彧鏈夋潵婧愬崰姣旓拷?
   娌℃湁鏉ユ簮锛堣繕娌℃墦涓繃 / 璇讳笉鍒颁激瀹筹級鏃惰繑鍥炵┖涓诧紝鐢辫皟鐢ㄦ柟鍐冲畾鍙戜笉鍙戯拷?
   鎴柇绛栫暐锛圖DH_MSG_MAX_BYTES = 420 UTF-8 瀛楄妭锛夛細
     鍏堢爫闈犲悗鐨勬潵婧愶紙3 锟?2 锟?1锛夆啋 鏈€鍚庢墠锟?420 纭埅鏂苟鍦ㄦ湯灏捐ˉ 鈥溾€︹€濓紙涓嶅垏鍧忔眽瀛楋級锟?*/
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
        /* 姣忚瘯涓€鐗堥兘閲嶇畻鈥滃悕瀛楄蛋浜嗗摢鏉¤矾鈥濓紝璁╂棩蹇楅噷鐨勬暟瀛楀彧鍙嶆槧鏈€缁堣繖涓€锟?*/
        g_msgNameRawUtf8 = 0;
        g_msgNameGbkFallback = 0;

        const int used = DdhBuildShareItems(g_ddhTrack.src, g_ddhTrack.srcCount,
                                            g_ddhTrack.net, g_ddhTrack.raw,
                                            src, items, sizeof(items));
        if (used <= 0) { tmp[0] = 0; continue; }

        tmp[0] = 0;
        DdhAppendLabel(tmp, sizeof(tmp), isDeath ? "銆愪激瀹炽€? : "銆愬綋鍓嶄激瀹炽€?);
        DdhAppendRaw(tmp, sizeof(tmp), items);
        if (strlen(tmp) <= DDH_MSG_MAX_BYTES)
        {
            strncpy_s(out, cap, tmp, _TRUNCATE);
            return;
        }
    }

    /* 锟?1 涓潵婧愰兘鏀句笉涓嬶紙鍚嶅瓧鐗瑰埆闀匡級锛氱‖鎴柇 + 鈥溾€︼拷?*/
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

/* 娌℃湁璁板綍鍗曚綅锟?Q 鐢ㄧ殑鍏ㄥ眬 Top5 鍙楀嚮鍗曚綅锛堝悓鏍锋槸 UTF-8锛氫腑鏂囨爣绛捐浆銆佸悕瀛楀師鏍锋嫾锟?*/
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

    DdhAppendLabel(out, cap, "銆愬叏灞€Top5鍙楀嚮銆?);
    if (n == 0)
    {
        DdhAppendLabel(out, cap, "杩樻病缁熻鍒颁换浣曚激瀹充簨浠讹紙鍏堟墦璧锋潵鍐嶆寜 Q锛?);
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
        DdhAppendLabel(out, cap, "鑶?);
    }

    /* 鍚屼竴锟?420 瀛楄妭涓婇檺锛堣繖閲屽彧纭埅鏂紝涓嶉€愮骇闄嶇骇锟?*/
    DdhTruncateUtf8(out, cap, DDH_MSG_MAX_BYTES);
}

/* ---------------------------------------------------------------------------
   骞挎挱锛氱洿鎶曡亰澶╋紙娓告垙鑷繁鐨勮緭鍏ユ + 鍥炶溅锛夛紝澶辫触鍐嶉€€鍏滃簳
   --------------------------------------------------------------------------- */

/* 鍒ゆ柇涓€涓叆鍙ｅ儚涓嶅儚鎻掍欢閲岄獙璇佽繃鐨勯偅浜涘嚱鏁帮細
   55 8B EC锛堟爣鍑嗗簭瑷€锟? 83 E9锛坰ub ecx,0锟? 6A FF锛坧ush -1 锟?SEH 搴忚█锛夛紝
   鎴栬€呰鍒殑鎻掍欢鎸傞挬鍚庣殑 E9锛堣烦杞洰鏍囧彲鎵ц鍗崇畻鍚堟硶 鈥旓拷?鎻掍欢瀹炴満鏃ュ織璇佸疄
   WFE 锟?0x153710 鏀规垚锟?E9锛岀収鏍疯兘姝ｅ父璋冿級锟?*/
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

/* 鎳掓牎锟?6 涓湴鍧€銆傚彧鍦ㄦ父鎴忕嚎绋嬭皟鐢紙DdhDeliverText 閲岋級锟?*/
static void DdhInitChatDirect(void)
{
    if (InterlockedCompareExchange(&g_ddhChatInitDone, 1, 0) != 0) return;
    if (!g_modBase)
    {
        LogLine("缁撶畻骞挎挱锛氭病鏈?game.dll 鍩哄潃锛岀洿鎶曡亰澶╀笉鍙敤");
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
            LogLine("缁撶畻骞挎挱锛氱洿鎶曡亰澶╀笉鍙敤 鈥旓拷?%s(Game.dll+0x%X) 鍏ュ彛 %02X %02X %02X %02X 涓嶇"
                    "锛圙ame.dll 鐗堟湰涓嶅尮閰?琚埆鐨勬彃浠舵敼杩囷級锛屽彧鑳界敤鍏滃簳鏄剧ず锛堜粎鏈満鍙锛?,
                    items[i].name, items[i].rva, b[0], b[1], b[2], b[3]);
            return;
        }
    }

    for (int i = 0; i < 6; i++) *items[i].slot = g_modBase + items[i].rva;
    g_ddhChatOk = 1;
    LogLine("缁撶畻骞挎挱锛氱洿鎶曡亰澶╁凡灏辩华锛? 涓湴鍧€搴忚█鍏ㄩ儴閫氳繃锛涙敹浠朵汉=鍏ㄩ儴锛涚敱娓告垙鑷繁鍙戦€侊級");
}

/* 鐩存姇锛氬彇鑱婂ぉ UI 瀵硅薄 -> clear_chat / set_recipient(鍏ㄩ儴) -> SetText(UTF-8)
   -> 璁╂父鎴忕獥鍙ｈ繃绋嬫敹鍒颁竴娆″洖杞︺€傛垚鍔熻繑锟?1锟?*/
static int DdhChatDirectSend(const char* utf8, char* why, size_t whyCap)
{
    if (!g_ddhChatOk)
    {
        DdhSprintf(why, whyCap, "鐩存姇鑱婂ぉ鍦板潃鏈氨缁紙瑙佷笂涓€鏉℃棩蹇楋級");
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
            DdhSprintf(why, whyCap, "鎷夸笉鍒拌亰澶?UI 瀵硅薄(%08X)鎴栨父鎴忕獥鍙?%p)", ui, (void*)hwnd);
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
        DdhSprintf(why, whyCap, "璋冪敤鐩存姇鑱婂ぉ寮傚父 code=%08X", (unsigned)GetExceptionCode());
        ok = 0;
    }
    return ok;
}

/* ---------------------------------------------------------------------------
   鍏滃簳鏄剧ず锛欴isplayTimedTextToPlayer锛坣ative 琛ㄦ寜鍚嶅瓧鎵撅級
   JASS native 鐨勫瓧绗︿覆鍙傛暟瑕佺殑锟?YDWE string_fake 褰㈡€佺殑銆愬璞℃寚閽堬拷?
   锟?0x08 鎸囧悜鑷韩锟?0x1C 锟?char* 姝ｆ枃锛夛紝涓嶆槸瀛楃锟?id 鈥旓拷?鐓ф彃锟?
   MakeJassString 鐨勫仛娉曢€犱竴涓父椹诲璞★紱浼犺８ char* 浼氳寮曟搸瑙ｅ紩鐢ㄥ皬鏁存暟鑰屽穿锟?
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
    g_ddhStrObj[i].m[2] = (uint32_t)(uintptr_t)&g_ddhStrObj[i].m[0];   /* +0x08 鎸囧悜鑷韩 */
    g_ddhStrObj[i].m[7] = (uint32_t)(uintptr_t)g_ddhStrBuf[i];         /* +0x1C 姝ｆ枃 */
    return (uint32_t)(uintptr_t)&g_ddhStrObj[i];
}

static uint32_t DdhGetDtttp(void)
{
    if (g_ddhNatDtttp) return g_ddhNatDtttp;
    if (InterlockedIncrement(&g_ddhDtttpTries) > 16) return 0;
    g_ddhNatDtttp = FindNativeFunc("DisplayTimedTextToPlayer");
    if (g_ddhNatDtttp)
        LogLine("缁撶畻鍏滃簳锛欴isplayTimedTextToPlayer native 宸插畾浣嶏紙0x%08X锛?, g_ddhNatDtttp);
    else if (InterlockedIncrement(&g_ddhDtttpFailLogged) <= 3)
        LogLine("缁撶畻鍏滃簳锛歯ative 琛ㄩ噷鏆傛椂鎵句笉鍒?DisplayTimedTextToPlayer锛堟病鏈?JASS/杩樻病杩涘浘锛夛紝鏈鍙兘鐢ㄦ棩蹇?);
    return g_ddhNatDtttp;
}

static uint32_t DdhGetPlayerNative(void)
{
    if (g_ddhNatPlayer) return g_ddhNatPlayer;
    if (InterlockedIncrement(&g_ddhPlayerTries) > 16) return 0;
    g_ddhNatPlayer = FindNativeFunc("Player");
    if (g_ddhNatPlayer)
        LogLine("缁撶畻鍏滃簳锛歅layer native 宸插畾浣嶏紙0x%08X锛?, g_ddhNatPlayer);
    return g_ddhNatPlayer;
}

static uint32_t DdhGetPlayersNative(void)
{
    if (g_ddhNatGetPlayers) return g_ddhNatGetPlayers;
    if (InterlockedIncrement(&g_ddhPlayersTries) > 16) return 0;
    g_ddhNatGetPlayers = FindNativeFunc("GetPlayers");
    if (g_ddhNatGetPlayers)
        LogLine("缁撶畻鍏滃簳锛欸etPlayers native 宸插畾浣嶏紙0x%08X锛?, g_ddhNatGetPlayers);
    return g_ddhNatGetPlayers;
}

/* 鍙戠粰姣忎釜鐜╁鍙ユ焺锛堟嬁涓嶅埌鍙ユ焺灏变紶 0锛夈€傝繑鍥炴垚鍔熻皟鐢ㄧ殑娆℃暟锟? = 涓嶅彲鐢拷?
   娉ㄦ剰锛欴isplayTimedTextToPlayer 鏄€愭湰鍦版樉绀恒€戝嚱鏁帮紝鍗充娇浼犲埆浜虹殑鍙ユ焺涔熶笉浼氫笂鍒汉鐨勫睆锟?
   鎵€浠ユ棩蹇楅噷蹇呴』鍐欐槑鈥滀粎鏈満鍙鈥濓拷?*/
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
        LogLine("缁撶畻骞挎挱澶辫触锛氬厹搴曟樉绀烘姏寮傚父 code=%08X", (unsigned)GetExceptionCode());
        shown = 0;
    }
    return shown;
}

/* ---------------------------------------------------------------------------
   鏈満鎻愮ず锛堢儹閿弽棣堬級锛氬彧璋冧竴锟?DisplayTimedTextToPlayer锛屽埆鐨勭帺瀹剁湅涓嶅埌锟?
   v11锛欳trl+Alt+R 閫変腑 / Ctrl+Alt+S 寮€鍏抽兘鍦ㄨ繖閲岀粰涓€鍙ユ彁绀猴拷?
   涓轰粈涔堜笉锟?DdhDeliverText锛氶偅鏉¤矾锟?*鐩存姇鍏叡鑱婂ぉ**锛堟敹浠朵汉=鍏ㄩ儴锛夛紝
   鐑敭鍙嶉瑕佹槸涔熷箍鎾嚭鍘伙紝绛変簬姣忔寜涓€锟?R 灏辫窡鍏ㄦ埧闂村枈涓€澹帮紝澶惖锟?
   --------------------------------------------------------------------------- */
static volatile LONG g_toastLogCount = 0;

static void DdhToast(const char* utf8)
{
    if (!utf8 || !utf8[0]) return;

    if (InterlockedIncrement(&g_toastLogCount) <= 20)
    {
        LogLine("鐑敭鎻愮ず锛堜粎鏈満锛夛細%s", utf8);
    }

    const uint32_t dt = DdhGetDtttp();
    if (!dt)
    {
        /* 灞忓箷鎻愮ず涓嶅彲鐢紙native 杩樻病灏辩华锛夛細鍙暀鏃ュ織锛岀粷涓嶅奖鍝嶇粺锟?*/
        return;
    }

    const uint32_t s = DdhMakeJassString(utf8);
    if (!s) return;

    /* 灏介噺鍙彂缁欐湰鏈虹帺瀹讹細ctx+0x28 鏄湰鍦扮帺瀹跺彿锟? 鍩猴級锛屾嬁涓嶅埌灏变紶 0 */
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
        LogLine("鐑敭鎻愮ず锛氫笂灞忔姏寮傚父 code=%08X锛堝凡鍚炴帀锛屼笉褰卞搷缁熻锛?, (unsigned)GetExceptionCode());
    }
}

/* 鍙戦€佷竴锟?*宸茬粡锟?UTF-8** 鐨勬秷鎭細鍏堢洿鎶曞箍鎾紝澶辫触鍐嶅厹搴曟湰鏈烘樉绀恒€傚彧鍦ㄦ父鎴忕嚎绋嬭皟鐢拷?
   v10锛氳繖閲屼笉鍐嶅仛鈥滄暣锟?GBK鈫扷TF-8鈥濓紙閭ｆ鏄悕瀛椾贡鐮佺殑鏍规簮锛夆€斺€斾腑鏂囨爣绛惧湪缁勬秷鎭椂
   宸茬粡杞垚 UTF-8锛屽崟浣嶅悕鏄紩鎿庣粰鐨勫師瀛楄妭锛岃 DdhAppendLabel / DdhAppendUnitName锟?*/
static void DdhDeliverText(const char* textUtf8)
{
    if (!textUtf8 || !textUtf8[0]) return;

    char utf8[1024] = { 0 };
    strncpy_s(utf8, sizeof(utf8), textUtf8, _TRUNCATE);

    /* 鏈€鍚庝竴閬撲繚闄╋細瓒呰繃 420 瀛楄妭灏辨寜 UTF-8 杈圭晫鎴柇骞惰ˉ 鈥溾€︹€濓紙璋冪敤鏂圭悊搴斿凡闄嶇骇杩囷級 */
    DdhTruncateUtf8(utf8, sizeof(utf8), DDH_MSG_MAX_BYTES);
    const unsigned len = (unsigned)strlen(utf8);

    /* 鎶娾€滅粍濂界殑娑堟伅鈥濆啓杩涙棩蹇楋紙鏃ュ織涔熸槸 UTF-8锛岀洿鎺ュ啓锛岃倝鐪煎氨鑳芥牳瀵癸級锟?
       椤哄甫鍐欎笅鏈潯鍚嶅瓧璧扮殑鏄摢鏉¤矾锛堝師锟?UTF-8 鍑犱釜 / GBK 鍥為€€鍑犱釜锛夛拷?*/
    if (InterlockedIncrement(&g_ddhMsgLogCount) <= 60)
    {
        LogLine("缁撶畻骞挎挱锛氭秷鎭紙UTF-8 %u 瀛楄妭锛涘悕瀛?鍘熸牱UTF-8 %d 涓?/ GBK鍥為€€ %d 涓級=%s",
                len, g_msgNameRawUtf8, g_msgNameGbkFallback, utf8);
    }

    DdhInitChatDirect();

    char why[192] = { 0 };
    if (DdhChatDirectSend(utf8, why, sizeof(why)))
    {
        if (InterlockedIncrement(&g_ddhSendOkCount) <= 100)
            LogLine("缁撶畻骞挎挱锛氬凡鍙戦€侊紙闀垮害 %u锛?, len);
        return;
    }

    if (InterlockedIncrement(&g_ddhSendFailCnt) <= 3)
        LogLine("缁撶畻骞挎挱澶辫触锛氬厹搴曟樉绀烘姏寮傚父 code=%08X", why);

    const int shown = DdhShowLocalText(utf8);
    if (shown > 0)
    {
        if (InterlockedIncrement(&g_ddhSendOkCount) <= 100)
            LogLine("缁撶畻骞挎挱锛氬凡鍙戦€侊紙闀垮害 %u锛屽厹搴曟湰鏈烘樉绀?%d 涓帺瀹跺彞鏌勶紱浠呮湰鏈哄彲瑙侊級", len, shown);
    }
    else if (g_ddhSendFailCnt <= 3)
    {
        LogLine("缁撶畻骞挎挱澶辫触锛氱洿鎶曚笌鍏滃簳閮戒笉鍙敤锛堥暱搴?%u锛屾湰娆′笉鍙戯紱缁熻涓庢棩蹇椾笉鍙楀奖鍝嶏級", len);
    }
}

/* ---------------------------------------------------------------------------
   缁熻锛氬叏灞€鍙楀嚮锟?+ 璁板綍鍗曚綅
   --------------------------------------------------------------------------- */
static void DdhGlobalAdd(const DdhEvent* e)
{
    /* 鍙粺璁♀€滅湡璇诲埌琛€宸€濈殑浜嬩欢锛氬崟浣嶆鍚庡亣浼ゅ涓嶅啀鍒锋锟?*/
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
        DdhUnitLabel(e->victim, e->victimCode, g_ddhGlobal[idx].label, sizeof(g_ddhGlobal[idx].label));
    }

    DdhVictimStat* v = &g_ddhGlobal[idx];
    v->hits++;
    v->net += (double)e->actual;
    v->raw += (double)e->amount;
    if (e->actual > v->maxHit) v->maxHit = e->actual;
}

/* 姣忎釜浜嬩欢璋冪敤涓€娆★紙鍙湪娓告垙绾跨▼锛夈€傝褰曞崟浣嶆浜℃椂鎶婄粨绠楁帓鍒版湰灞傞€€鍑哄悗鍙戯拷?*/
static void DdhSelfSettleEvent(const DdhEvent* e);

static void DdhTrackEvent(const DdhEvent* e)
{
    DdhSelfSettleEvent(e);
    DdhGlobalAdd(e);

    if (!e->victim || e->victim != g_ddhTrack.unit) return;

    if (g_ddhTrack.dead)
    {
        /* 宸茬粡骞挎挱杩囨浜★細绛夊畠澶嶆椿锛堝悗琛€鍥炲埌 > 0锛夊啀閲嶆柊寮€涓€浠界粺锟?*/
        if (e->hpValid && e->hpAfter > 0.0f)
        {
            const uint32_t unit = e->victim;
            const uint32_t code = e->victimCode;
            memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
            g_ddhTrack.unit    = unit;
            g_ddhTrack.code    = code;
            g_ddhTrack.startMs = GetTickCount();
            DdhUnitLabel(unit, code, g_ddhTrack.label, sizeof(g_ddhTrack.label));
            LogLine("鐑敭锛氳褰曞崟浣嶅娲伙紙0x%08X锛夛紝缁熻宸查噸缃紝缁х画璺熻釜", unit);
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

    /* 鏉ユ簮绱锛氭寜绫诲瀷鐮佸悎骞讹紙鍚岀爜涓嶅悓鍗曚綅绠椾竴鏉★紝鏄剧ず鎸夆€滃悕锟?锟?鈥濓級锛涙病鐮佸氨鎸夋寚閽堝垎 */
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
        DdhUnitLabel(e->source, e->sourceCode, s->label, sizeof(s->label));
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

    /* 姝讳骸锛氬悗琛€ <= 0 涓旀湰灞傚墠琛€ > 0锛坔pValid 灏辨槸杩欎箞瀹氫箟鐨勶級銆傚彧鎺掍竴娆★紝鍙戦€佸湪
       鏈€澶栧眰浼ゅ鍑芥暟閫€鍑哄悗锛圖dhProcessDeferred锛夛紝閬垮厤鍦ㄥ紩鎿庢墸琛€杩囩▼涓皟鑱婂ぉ鍑芥暟锟?
       v11锛氭秷鎭彧鍙戙€愪激瀹炽€戞潵婧愬崰姣旓紙涓绘鎸夌敤鎴疯姹備笉鍐嶅彂锛夈€傛病鏈夋潵婧愭瀯鎴愬氨骞茶剢涓嶅彂锟?
       鍒湪鍏叡鑱婂ぉ閲屽埛涓€鏉＄┖娑堟伅锟?*/
    if (e->hpValid && e->hpAfter <= 0.0f)
    {
        g_ddhTrack.dead = 1;
        DdhBuildTrackText(g_ddhDeferText, sizeof(g_ddhDeferText), 1);
        if (g_ddhDeferText[0])
        {
            g_ddhDeferKind = 1;
            LogLine("鐑敭锛氳褰曞崟浣?0x%08X 姝讳骸锛堝悗琛€ %.2f锛夛紝銆愪激瀹炽€戝凡鎺掗槦锛堟湰灞備激瀹冲嚱鏁伴€€鍑哄悗鍙戦€侊級",
                    e->victim, (double)e->hpAfter);
        }
        else
        {
            LogLine("鐑敭锛氳褰曞崟浣嶅綋鍓嶈閲?%.2f锛堝紑濮嬬疮璁″畠鐨勫彈鍑伙級",
                    e->victim, (double)e->hpAfter);
        }
    }
}

/* v12锛氱儹閿姩浣滆**绔嬪埢**鍦ㄦ父鎴忕嚎绋嬫墽锟?鈥旓拷?绐楀彛娑堟伅閫氶亾锛堝疄鐜拌 DdhProcessPending 涔嬪悗锟?*/
/* ===========================================================================
   v22锛歞ll 鑷繁鍑衡€滈樀浜℃€荤粨鈥濓紙涓嶄緷璧?War3DeathSettlement.exe锛?
   ---------------------------------------------------------------------------
   鍙粺璁♀€滄湰鍦扮帺瀹剁殑鑻遍泟鈥濓紙victimOwner == 鏈湴鐜╁鍙?涓?IsHeroUnitId(victimCode)锛夛細
     路 浠庤嫳闆勫嚭鐜?澶嶆椿寮€濮嬬疮璁★細鎵垮彈浼ゅ銆佺瑪鏁般€佹渶澶т竴鍑汇€佹渶鎯?1 绉掋€佹垬鏂楁椂闀裤€佹潵婧?Top4锛?
     路 姝讳骸浜嬩欢锛堝墠琛€ > 0銆佸悗琛€ <= 0锛夋椂鎷奸潰鏉匡紝浜ょ粰 DdhProcessDeferred 鍦ㄤ激瀹冲嚱鏁?
       鏈€澶栧眰閫€鍑哄悗鏄剧ず锛堥伩鍏嶅湪寮曟搸鎵ｈ杩囩▼涓皟娓告垙鏄剧ず鍑芥暟锛夈€?
   C# 绔彧瑕佸啓杩?panel锛坰eq 鍙樺寲涓斾笉鏄?dll 鑷繁鍐欑殑锛夊氨璁や负鈥滃閮ㄩ潰鏉挎帴绠♀€濓紝dll 涓嶅啀鎶€?
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
    static int cached = -1;
    if (cached >= 0) return cached;
    const uint32_t fnLocal = DdhLocalPlayerNative();
    const uint32_t fnId = GetPlayerIdNative();
    if (!fnLocal || !fnId) return -1;
    uint32_t h = 0;
    __try { h = ((uint32_t (__cdecl*)(void))(uintptr_t)fnLocal)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { h = 0; }
    if (!h) return -1;
    uint32_t id = 0xFFFFFFFFu;
    __try { id = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)fnId)(h); }
    __except (EXCEPTION_EXECUTE_HANDLER) { id = 0xFFFFFFFFu; }
    if (id < 24) cached = (int)id;
    return cached;
}

static int DdhIsHeroCode(uint32_t code)
{
    if (!code) return 0;
    const uint32_t fn = DdhAttrNative(DDH_AN_IS_HERO_ID);
    if (!fn) return 0;
    uint32_t eax = 0;
    float st0 = 0.0f;
    __try { DdhNatCallAsm(fn, code, 0, &eax, &st0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return (int)eax;
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
    DdhUnitLabel(e->source, e->sourceCode, s->label, sizeof(s->label));
    return s;
}

static void DdhSelfSettleEvent(const DdhEvent* e)
{
    if (!g_shm || !e || !e->victim) return;

    /* 澶栭儴锛圕#锛夊啓杩囬潰鏉匡細璇存槑鏈変汉鎺ョ鏄剧ず锛宒ll 涓嶆姠銆?*/
    if (g_shm->panel.seq != 0 && g_shm->panel.seq != g_selfPanelSeq)
        g_selfCsPanel = 1;
    if (g_selfCsPanel) return;

    const int lp = DdhLocalPid();
    if (lp < 0) return;

    /* 杩樻病閿佸畾鑻遍泟锛氭壘鈥滄湰鍦扮帺瀹舵嫢鏈夌殑鑻遍泟鈥濄€?*/
    if (g_selfHero == 0 || e->victim != g_selfHero)
    {
        if (e->victimOwner != lp || !DdhIsHeroCode(e->victimCode)) return;
        DdhSelfReset(e->victim, e->victimCode, e->seq);
        g_selfDead = 0;
        g_selfLife = 1;
        LogLine("v22 闃典骸鎬荤粨锛氶攣瀹氭湰鍦拌嫳闆?0x%08X锛?s锛夛紝寮€濮嬬疮璁?, e->victim,
                DdhCodeText(e->victimCode));
    }
    if (e->victim != g_selfHero) return;

    /* 澶嶆椿/鏂颁竴鏉″懡锛氬悗琛€鍥炲埌姝ｆ暟銆?*/
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

    /* 姝讳骸锛氬墠琛€ > 0銆佸悗琛€ <= 0銆?*/
    if (e->hpBefore > 0.0f && e->hpAfter <= 0.0f)
    {
        if (g_selfCurSum > g_selfPeak) g_selfPeak = g_selfCurSum;
        g_selfFatalSource = e->source;
        g_selfFatalCode = e->sourceCode;
        g_selfFatalFlag = e->flag;
        g_selfFatalPhysical = e->isPhysical;
        g_selfFatalNet = net;
        DdhUnitLabel(e->source, e->sourceCode, g_selfFatalName, sizeof(g_selfFatalName));
        g_selfDead = 1;
        g_selfPanelPending = 1;
        g_selfLife++;
    }
}

static void DdhSelfPanelShow(void)
{
    if (!g_shm || g_selfCsPanel) return;
    if (g_selfHero == 0) return;

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
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, "闃典骸鎬荤粨");

    char label[96] = "";
    DdhUnitLabel(g_selfHero, g_selfHeroCode, label, sizeof(label));
    DdhSprintf(buf, sizeof(buf), "%s 路 %s", label[0] ? label : "?", DdhCodeText(g_selfHeroCode));
    p.lines[n].color = 0xFFFFFFFFu;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    SYSTEMTIME st;
    GetLocalTime(&st);
    DdhSprintf(buf, sizeof(buf), "鐜╁ %d 路 绗?%d 鏉″懡 路 姝讳骸 %02u:%02u:%02u",
               DdhLocalPid() + 1, g_selfLife - 1, st.wHour, st.wMinute, st.wSecond);
    p.lines[n].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    DdhSprintf(buf, sizeof(buf), "鎵垮彈浼ゅ %s", num1);
    p.lines[n].color = 0xFFFFFFFFu;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    DdhSprintf(buf, sizeof(buf), "%u 绗?路 鏈€澶?%s 路 鏈€鎯?1 绉?%s",
               g_selfHits, num2, num3);
    p.lines[n].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    double secs = (g_selfFirstTick && g_selfLastTick > g_selfFirstTick)
                  ? (double)(g_selfLastTick - g_selfFirstTick) / 1000.0 : 0.0;
    DdhSprintf(buf, sizeof(buf), "鎴樻枟 %.1f 绉?路 绉掍激 %.0f",
               secs, secs > 0.05 ? g_selfNet / secs : 0.0);
    p.lines[n].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    DdhNumFmt(g_selfFatalNet, num4, sizeof(num4));
    DdhSprintf(buf, sizeof(buf), "鑷村懡涓€鍑?%s %s锛?s 路 %s锛?,
               g_selfFatalName[0] ? g_selfFatalName : "?",
               num4,
               (g_selfFatalFlag & 0x100u) ? "鏅敾" : "鎶€鑳?,
               g_selfFatalPhysical ? "鐗╃悊" : "娉曟湳");
    p.lines[n].color = 0xFFFF6666u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    p.lines[n].color = 0xFFFFD700u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, "浼ゅ鏉ユ簮");

    /* Top 4锛堟寜鍑€鎺夎闄嶅簭锛夈€?*/
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
        DdhSprintf(buf, sizeof(buf), "%s %.1f%%  %s  %u绗?,
                   s->label[0] ? s->label : (s->code ? DdhCodeText(s->code) : "?"),
                   pct, num2, s->hits);
        p.lines[n].color = 0xFFFFFFFFu;
        strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);
        if (n >= DDH_PANEL_MAX_LINES - 1) break;
    }

    DdhSprintf(buf, sizeof(buf), "0x%08X 路 ddh v%d", g_selfHero, DDH_VERSION);
    p.lines[n].color = 0xFFB0B0B0u;
    strcpy_s(p.lines[n++].text, DDH_PANEL_LINE_TEXT, buf);

    p.lineCount = (uint32_t)n;
    p.seq = (uint32_t)InterlockedIncrement((volatile LONG*)&g_selfPanelSeq);
    memcpy(&g_shm->panel, &p, sizeof(p));
    MemoryBarrier();
    LogLine("v22 闃典骸鎬荤粨锛氬凡鎺ㄩ€侊紙%d 琛岋紝鎵夸激 %.0f锛?u 绗旓紝鏉ユ簮 %u锛?,
            n, g_selfNet, g_selfHits, g_selfSrcCount);
}

static int  DdhEnsureGameWnd(void);
static void DdhPostHotkeyToGame(void);

/* ---------------------------------------------------------------------------
   鐑敭绾跨▼锛氬彧娉ㄥ唽鐑敭銆佹敹 WM_HOTKEY銆佺疆寰呭姙鏍囧織浣嶏紝骞剁珛锟?PostMessage 缁欐父鎴忕獥锟?
   --------------------------------------------------------------------------- */
/* v10锛氬睘鎬ц姹傛姇閫掞紙瀹炵幇鍦ㄧ獥鍙ｈ繃绋嬮偅涓€锟?鈥旓拷?閭ｉ噷 g_gameWnd / DDH_WM_ATTR 宸插氨缁級 */
static void DdhMaybePostAttrRequest(void);

/* v15锛氭父鎴忓唴闃典骸闈㈡澘 / 鑻遍泟鏌ヨ锛堝疄鐜板湪 DdhProcessDeferred 涔嬪悗锛涜繖閲屽彧鍓嶇疆澹版槑锟?*/
static void DdhProcessPanelRequest(void);
static void DdhProcessHeroRequest(void);
static void DdhPanelTick(void);
static void DdhMaybePostPanelAndHero(void);
static void DdhPanelDemoOnce(void);
static void DdhDoTogglePanel(void);
/* `~` 鏄鹃殣锛氶敭锟?`~`锛圴K_OEM_3锛夋樉锟?闅愯棌闈㈡澘銆傝繑锟?1 = 杩欐鎸夐敭琚潰鏉挎秷锟?*/
static int  DdhDoToggleVisible(void);
/* 鎵夸激鍥捐〃锛坒lags bit4锛夛細娓叉煋/闅愯棌/鐐瑰嚮銆傚疄鐜拌 DdhDoToggleVisible 涔嬪悗锟?*/
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

    LogLine("鐑敭锛氱嚎绋嬪凡鍚姩 tid=%lu锛孋trl+Alt+R=%s S=%s Q=%s C=%s D=%s锛堟敞鍐屽け璐ヤ竴鑸槸琚埆鐨勮蒋浠跺崰鐢級",
            (unsigned long)g_ddhHkThreadId,
            rR ? "鎴愬姛" : "澶辫触", rS ? "鎴愬姛" : "澶辫触", rQ ? "鎴愬姛" : "澶辫触",
            rC ? "鎴愬姛" : "澶辫触", rD ? "鎴愬姛" : "澶辫触");

    if (!rR && !rS && !rQ)
    {
        LogLine("鐑敭锛氫笁涓粍鍚堥敭涓€涓兘娌℃敞鍐屼笂锛屾湰娆＄儹閿笉鍙敤锛堜激瀹抽挬瀛?缁熻/闈㈡澘 TTL 涓嶅彈褰卞搷锛?);
        /* 锟?return锛氫粛瑕佹墭绠℃父鎴忕獥鍙ｏ紝闈㈡澘 TTL tick / 灞炴€ф姇閫掕繕瑕侀潬杩欐潯绾跨▼锟?*/
    }

    /* v12锛氬厛鎶婃父鎴忕獥鍙ｆ寕涓婏紝涔嬪悗姣忎釜鐑敭閮借兘绔嬪埢鍦ㄦ父鎴忕嚎绋嬫墽琛岋紙姣绾э紝涓嶇瓑浼ゅ浜嬩欢锟?*/
    if (!DdhEnsureGameWnd())
        LogLine("鐑敭锛氭殏鏃舵病鎵惧埌娓告垙绐楀彛锛屽姩浣滀細閫€鍖栦负鈥滀笅涓€娆′激瀹充簨浠舵椂澶勭悊鈥濓紙鏈夊欢杩燂級");

    /* v10锛氱敤 MsgWaitForMultipleObjects(100ms) 鍙栦唬闃诲锟?GetMessage 鈥旓拷?鏃㈡敹鐑敭锟?
       鍙堟瘡 100ms 鐪嬩竴鐪尖€淐# 鏈夋病鏈夋柊鐨勫睘鎬ц姹傗€濓紝鏈夊氨鎶曠粰娓告垙绐楀彛锟?
       涓嶅紩鍏ラ澶栫嚎绋嬶紝鐑敭琛屼负涓€涓瓧鑺傛病鍙橈拷?*/
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
                    /* 娉ㄦ剰锛歐M_HOTKEY 锟?wParam 鏄€愭敞鍐屾椂缁欑殑 id銆戯紝涓嶆槸鎸夐敭鐮侊紱
                       鎸夐敭瀛楁瘝锟?id 鍙嶆煡锛堜互鍓嶈繖閲岀洿锟?(char)wParam锛屾棩蹇楅噷鎵撳嚭鏉ユ槸涔辩爜锛夛拷?*/
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
                    /* 鐑敭鎸変笅鏈韩璁颁竴鏉★紙闄愭祦锛夛紝鐪熸満鎺掓煡鈥滅儹閿埌搴曟湁娌℃湁琚郴缁熷彂缁欐父鎴忊€濈敤 */
                    if (InterlockedIncrement(&g_ddhHkPressLogged) <= 30)
                        LogLine("鐑敭锛氭敹鍒?Ctrl+Alt+%c锛堢珛鍒绘姇缁欐父鎴忕嚎绋嬫墽琛岋級", keyName);

                    /* v12锛氱珛鍒昏娓告垙绾跨▼鎵ц锛屼笉鍐嶇瓑涓嬩竴娆′激瀹充簨浠讹拷?
                       绐楀彛涓嶅彲鐢ㄦ椂寰呭姙鏍囧織宸茬粡缃綅锛屼粛浼氳蛋鏃х殑浼ゅ浜嬩欢璺緞鍏滃簳锟?*/
                    if (keyName != '?') DdhPostHotkeyToGame();
                }

                TranslateMessage(&msg);
                DispatchMessageA(&msg);
            }
        }
        /* v10锛氬睘鎬ц姹傦紙100ms 鑺傛祦锛涙病鏈夋柊璇锋眰鏃朵粈涔堥兘涓嶅仛锟?*/
        __try { DdhMaybePostAttrRequest(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            if (InterlockedIncrement(&g_ddhAttrNoHandleLogged) <= 5)
                LogLine("ATTR post 鎶曢€掕姹傚紓甯?code=%08X锛堝凡鍚炴帀锛岀瓑涓嬩竴鏉′激瀹充簨浠跺厹搴曪級",
                        (unsigned)GetExceptionCode());
        }
        /* v15锛氶潰锟?/ 鑻遍泟鏌ヨ璇锋眰锛堝悓锟?100ms 鑺傛祦锛屽彧鎶曟秷鎭€佷笉纰板紩鎿庯級 */
        __try { DdhMaybePostPanelAndHero(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            if (InterlockedIncrement(&g_ddhPanelPostErrLogged) <= 5)
                LogLine("闈㈡澘 post 鎶曢€掕姹傚紓甯?code=%08X锛堝凡鍚炴帀锛岀瓑涓嬩竴鏉′激瀹充簨浠跺厹搴曪級",
                        (unsigned)GetExceptionCode());
        }
    }

    UnregisterHotKey(NULL, DDH_HK_ID_R);
    UnregisterHotKey(NULL, DDH_HK_ID_S);
    UnregisterHotKey(NULL, DDH_HK_ID_Q);
    UnregisterHotKey(NULL, DDH_HK_ID_C);
    UnregisterHotKey(NULL, DDH_HK_ID_D);
    UnregisterHotKey(NULL, DDH_HK_ID_E);
    LogLine("鐑敭锛氱嚎绋嬮€€鍑猴紙tid=%lu锛?, (unsigned long)g_ddhHkThreadId);
    return 0;
}

/* 绗竴娆¤繘浼ゅ鍑芥暟锛堟父鎴忓凡缁忚窇璧锋潵銆丏LL 涔熶笉鍦ㄥ姞杞藉櫒閿侀噷锛夋椂鎶婄儹閿嚎绋嬫媺璧锋潵 */
static void DdhEnsureHotkeyThread(void)
{
    if (InterlockedCompareExchange(&g_ddhHkStarted, 1, 0) != 0) return;

    LogLine("鐑敭锛氭父鎴忕嚎绋?tid=%lu锛屽惎鍔ㄧ儹閿嚎绋嬶紙Ctrl+Alt+R 璁板綍閫変腑鍗曚綅 / S 鑷姩鍙戦€?/ Q 鐪嬬粺璁★級",
            (unsigned long)GetCurrentThreadId());

    g_ddhHkThread = CreateThread(NULL, 0, DdhHotkeyThreadProc, NULL, 0, NULL);
    if (!g_ddhHkThread)
        LogLine("鐑敭锛欳reateThread 澶辫触 err=%lu锛堟湰娆＄儹閿笉鍙敤锛屼激瀹抽挬瀛愪笉鍙楀奖鍝嶏級", GetLastError());
}

/* 璇婚€夊尯閾俱€倁sedAlt 鍥炰紶鏄惁璧颁簡澶囩敤锟?sel+0x08锟?
   鍏ㄧ▼ __try锛涗换浣曚竴璺充笉鍚堟硶閮借繑锟?0锛岀敱璋冪敤鏂瑰啓鏃ュ織锟?*/
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

/* ---- R锛氳褰曞綋鍓嶉€変腑鐨勫崟浣嶏紙缁熻娓呴浂锛屼箣鍚庝竴鐩磋窡瀹冿級 ----
   v11锛氶€変腑/閫変笉涓兘锟?*鏈満娑堟伅锟?*缁欎竴鍙ユ彁绀猴紙DdhToast锛屽彧鏈満鍙锛屼笉杩涘叕鍏辫亰澶╋級锟?*/
static void DdhDoRecord(void)
{
    int usedAlt = 0;
    const uint32_t unit = DdhReadSelection(&usedAlt);
    if (!unit)
    {
        if (InterlockedIncrement(&g_ddhHkFailLogged) <= 10)
            LogLine("鐑敭锛欳trl+Alt+R 娌″彇鍒伴€変腑鍗曚綅锛堥€夊尯閾句负绌猴細鍏堝乏閿偣涓€涓崟浣嶅啀鎸夛級");

        char msg[256] = { 0 };
        DdhAppendLabel(msg, sizeof(msg), "銆愭湭閫変腑銆戝厛宸﹂敭鐐逛竴涓崟浣嶏紝鍐嶆寜 Ctrl+Alt+R");
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
        LogLine("鐑敭锛欳trl+Alt+R 宸茶褰?%s 0x%08X锛?s閾撅紱%s锛?,
                label, unit,
                usedAlt ? "澶囩敤 sel+0x08" : "sel+0x1F0",
                oldUnit ? "鏃х殑璁板綍宸叉浛鎹€佺粺璁℃竻闆? : "鏂拌褰?);

    /* 鏈満娑堟伅鍖烘彁绀猴紙鍚嶅瓧鎸夊師瀛楄妭鎷硷紝鍒啀杞爜锟?*/
    {
        char msg[256] = { 0 };
        DdhAppendLabel(msg, sizeof(msg), "銆愬凡閫変腑銆?);
        DdhAppendUnitName(msg, sizeof(msg), label);
        DdhToast(msg);
    }

    float hp = 0.0f;
    if (ReadUnitHp(unit, &hp))
    {
        if (hp <= 0.0f)
            LogLine("鐑敭锛氳褰曞崟浣嶅綋鍓嶈閲?%.2f锛堝凡姝讳骸/绌哄３锛夛紝缁熻瑕佺瓑瀹冨娲诲悗鎵嶆湁鏁版嵁", (double)hp);
        else
            LogLine("鐑敭锛氳褰曞崟浣嶅綋鍓嶈閲?%.2f锛堝紑濮嬬疮璁″畠鐨勫彈鍑伙級", (double)hp);
    }
    else
    {
        LogLine("鐑敭锛氳褰曞崟浣嶅綋鍓嶈閲忚涓嶅埌锛堝彞鏌勭鐞嗗櫒/寮曟搸璁块棶鍣ㄩ兘娌￠€氳繃锛夛紝缁熻鍙兘鍏?0");
    }

    if (oldUnit && oldUnit != unit && oldHits > 0)
        LogLine("鐑敭锛氫笂涓€涓褰曞崟浣?0x%08X 鐨?%u 娆″彈鍑荤粺璁″凡涓㈠純", oldUnit, (unsigned)oldHits);
}

/* ---- S锛氳嚜鍔ㄥ彂閫佸紑鍏筹紙缁熻鐓ф棫锛屽彧鏄笉鍐嶅彂锟?----
   v11锛氬紑/鍏抽兘鍦ㄦ湰鏈烘秷鎭尯鎻愮ず涓€鍙ワ紙鍙湰鏈哄彲瑙侊紝涓嶈繘鍏叡鑱婂ぉ锛夛拷?*/
static void DdhDoToggle(void)
{
    const LONG cur = InterlockedCompareExchange(&g_ddhAutoSend, 0, 0);
    const LONG now = cur ? 0 : 1;
    InterlockedExchange(&g_ddhAutoSend, now);

    if (InterlockedIncrement(&g_ddhHkToggleLogged) <= 40)
        LogLine("鐑敭锛氳嚜鍔ㄥ彂閫?%s锛堢粺璁＄収甯革紝%s锛?, now ? "寮€" : "鍏?, now ? "姝讳骸鏃朵細鍙戠粨绠? : "姝讳骸鏃朵笉鍐嶅彂");

    char msg[256] = { 0 };
    if (now) DdhAppendLabel(msg, sizeof(msg), "銆愬凡寮€鍚€戞浜＄粨绠椾細鑷姩鍙戦€?);
    else     DdhAppendLabel(msg, sizeof(msg), "銆愬凡鍙栨秷銆戞浜＄粨绠椾笉鍐嶈嚜鍔ㄥ彂閫?);
    DdhToast(msg);
}

/* ---- Q锛氱珛鍗冲彂涓€鏉″綋鍓嶆潵婧愬崰姣旓紙銆愬綋鍓嶄激瀹炽€戔€︼級 ---- */
static void DdhDoQuery(void)
{
    char text[768] = { 0 };
    g_msgNameRawUtf8 = 0;
    g_msgNameGbkFallback = 0;
    if (g_ddhTrack.unit)
    {
        DdhBuildTrackText(text, sizeof(text), 0);
        /* 鍒氳涓婅繕娌℃墦涓繃锛氱粰涓€鍙ョ煭鐨勶紝鍒 Q 鐪嬭捣鏉ュ儚娌″弽锟?*/
        if (!text[0]) DdhAppendLabel(text, sizeof(text), "銆愬綋鍓嶄激瀹炽€戞殏鏃?);
    }
    else
    {
        DdhBuildGlobalTop5(text, sizeof(text));
    }

    if (!text[0])
    {
        LogLine("Q 缁熻锛氭病鏈夊彲鍙戠殑缁熻锛堟棦娌℃湁璁板綍鍗曚綅锛屼篃杩樻病缁熻鍒颁激瀹筹級");
        return;
    }

    if (InterlockedIncrement(&g_ddhHkQueryLogged) <= 40)
    {
        LogLine("Q 缁熻锛?s", text);
    }

    DdhDeliverText(text);
}

/* 寰呭姙鐑敭锛堝彧鍦ㄦ父鎴忕嚎绋嬭皟鐢級 */
static void DdhProcessPending(void)
{
    if (InterlockedExchange(&g_ddhPendR, 0)) DdhDoRecord();
    if (InterlockedExchange(&g_ddhPendS, 0)) DdhDoToggle();
    if (InterlockedExchange(&g_ddhPendQ, 0)) DdhDoQuery();
    if (InterlockedExchange(&g_ddhPendC, 0)) DdhChartDebugShow();
    if (InterlockedExchange(&g_ddhPendD, 0)) DdhChartDemoShow();
    if (InterlockedExchange(&g_ddhPendE, 0)) DdhChartToggleView();
    /* v10锛氶『鎵嬪鐞嗗崟浣嶅睘鎬ц锟?鈥旓拷?DdhDamageFunc 鏈€澶栧眰杩斿洖鏃朵細璧拌繖閲岋紝
       鎵€浠ユ病鏈夋父鎴忕獥锟?/ 鐑敭绾跨▼娌¤捣鏉ユ椂灞炴€т篃鑳藉埛鏂帮紙鍋囬瓟鍏藉啋鐑熷氨闈犲畠锛夛拷?*/
    DdhProcessAttrRequest();
    /* v15锛氭父鎴忓唴闃典骸闈㈡澘 / 鑻遍泟鏌ヨ鍚屾牱鍙湪娓告垙绾跨▼澶勭悊锛汿TL 鍏滃簳涔熷湪杩欓噷璺戯拷?*/
    __try { DdhProcessPanelRequest(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("闈㈡澘锛氬鐞嗚姹傚紓甯?code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
    }
    __try { DdhProcessHeroRequest(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("闈㈡澘锛氬鐞嗚嫳闆勬煡璇㈠紓甯?code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
    }
    __try { DdhPanelTick(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("闈㈡澘锛歍TL 澶勭悊寮傚父 code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
    }
}

/* ---------------------------------------------------------------------------
   v12锛氱儹锟?-> 娓告垙绾跨▼ 鐨勨€滅獥鍙ｆ秷鎭€氶亾锟?
   ---------------------------------------------------------------------------
   涓轰粈涔堣鏈夊畠锛氱儹閿姩浣滃繀椤昏皟寮曟搸锛堣閫夊尯鍐呭瓨銆丷esolveName銆丏isplayTimedTextToPlayer锟?
   鐩存姇鑱婂ぉ锛夛紝杩欎簺閮藉彧鑳藉湪娓告垙绾跨▼涓婅窇锛涜€岀儹閿槸娉ㄥ唽鍦ㄤ竴涓嫭绔嬬嚎绋嬩笂鐨勶拷?
   浠ュ墠鍙兘鍊熲€滀笅涓€娆′激瀹充簨浠垛€濆綋鎵ц锟?鈥旓拷?娌′汉鎸ㄦ墦灏变竴鐩翠笉鍝嶅簲锛堢敤鎴峰弽棣堢殑寤惰繜锛夛拷?
   鐜板湪鐓ф彃锟?UDamageWatcherHook.cpp 鐨勫悓娆惧仛娉曪細
     路 鐑敭绾跨▼ PostMessage(娓告垙绐楀彛, WM_APP+0xDD)锟?
     路 绐楀彛杩囩▼琚垜浠瓙绫诲寲锛圫etWindowLongPtrW锛夛紝娑堟伅灏卞湪**娓告垙绾跨▼**鐨勬秷鎭惊鐜噷
       娲惧彂锛屽綋鍦烘墽锟?DdhProcessPending() 鈥旓拷?鎸夊畬鍗冲嚭鎻愮ず锛堟绉掔骇锛夛拷?
   路 娓告垙鍒囧垎杈ㄧ巼/鍏ㄥ睆/閲嶅紑绐楀彛鏃朵細鎶婄獥鍙ｈ繃绋嬫敼鍥炲幓 锟?姣忔鎶曢€掑墠鏍￠獙骞惰嚜鍔ㄩ噸鎸傦拷?
   路 DLL 鍗歌浇锛圖llMain DETACH锛夊繀椤绘妸绐楀彛杩囩▼杩樺洖鍘伙紝鍚﹀垯绐楀彛杩樻寚鐫€宸插嵏杞界殑浠ｇ爜锟?
   --------------------------------------------------------------------------- */
#define DDH_WM_HOTKEY (WM_APP + 0xDD)
/* v10锛氬睘鎬ц姹傞€氶亾銆傜儹閿嚎绋嬫瘡 100ms 鐪嬩竴鐪艰姹傚簭鍙凤紝鏈夋柊璇锋眰灏辨姇杩欐潯娑堟伅锟?
   娓告垙绐楀彛杩囩▼鍦ㄦ父鎴忕嚎绋嬮噷褰撳満澶勭悊锛堝拰鐑敭鍚屼竴鏉￠€氶亾锛岀粷涓嶈法绾跨▼锟?JASS锛夛拷?*/
#define DDH_WM_ATTR   (WM_APP + 0xDE)
/* v15锛氭父鎴忓唴闈㈡澘 / 鑻遍泟鏌ヨ閫氶亾锛堝悓鏍风敱鐑敭绾跨▼ 100ms 杞搴忓彿鍚庢姇閫掞級锟?*/
#define DDH_WM_PANEL  (WM_APP + 0xDF)
#define DDH_WM_HERO   (WM_APP + 0xE0)
#define DDH_WM_PANEL_TICK (WM_APP + 0xE1)

static HWND    g_gameWnd     = NULL;
static WNDPROC g_prevWndProc = NULL;
static volatile LONG g_wndLogCount = 0;
static volatile LONG g_wndCand     = 0;   /* 涓婃鏋氫妇鍒板嚑涓€滄湰杩涚▼鐨勫彲瑙佺獥鍙ｂ€濓紙璇婃柇鐢級 */
static char    g_wndClass[64] = { 0 };    /* 閫変腑鐨勭獥鍙ｇ被鍚嶏紙璇婃柇鐢級 */
static char    g_wndTitle[96] = { 0 };    /* 閫変腑鐨勭獥鍙ｆ爣棰橈紙璇婃柇鐢級 */
static int     g_wndUnicode  = 0;         /* 1 = 杩欎釜绐楀彛锟?Unicode锛圵 鐗堬級锟? = ANSI锛圓 鐗堬級 */

struct DdhWndPick { int score; long area; };

/* 鏋氫妇鏈繘绋嬪彲瑙佺獥鍙ｆ寫娓告垙绐楀彛銆傝鍒欙紙鐪熸満韪╄繃鐨勫潙閮藉啓鍦ㄨ繖锛夛細
     路 璺宠繃 conhost 鐨勬帶鍒跺彴绐楀彛锛圕onsoleWindowClass锛夆€旓拷?瀹冪殑绐楀彛杩囩▼鏀逛笉锟?
       锛圫etWindowLongPtr 杩斿洖 0 + err=5锛夛紝鏃╂湡鐗堟湰灏辨槸鎸戜腑瀹冩墠鈥滄寕涓嶄笂绐楀彛鈥濓紱
     路 浼樺厛 绫诲悕 == "Warcraft III"锛堢湡榄斿吔锛夛紱鍏舵鏍囬閲屽甫 Warcraft/榄斿吔锟?
     路 鍚屾。閲屽彇闈㈢Н鏈€澶х殑锛堝叏灞忔椂灏辨槸娓告垙绐楀彛锛夛拷?*/
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
    else if (strstr(title, "Warcraft") || strstr(title, "榄斿吔")) score = 2;

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

/* v17锛氶紶鏍囧懡涓祴璇曘€備紭鍏堢敤鑳屾櫙甯у竷灞€鍚庣殑瀹為檯鐭╁舰锛堣嫢鍙锛夛紝鍚﹀垯鐢ㄥ綊涓€鍖栫煩褰紙榛樿宸︿笂閿氱偣锛夛拷?*/
static int DdhPanelHitTest(int x, int y)
{
    if (!g_ddhPanelClickOk) return 0;
    RECT rc = { 0 };
    if (!g_gameWnd || !GetClientRect(g_gameWnd, &rc)) return 0;
    const int cw = rc.right - rc.left;
    const int ch = rc.bottom - rc.top;
    if (cw <= 0 || ch <= 0) return 0;

    if (g_ddhChartMode)
    {
        const int l2 = (int)((g_ddhChartX - 0.012f) * 1.25f * (float)cw);
        const int t2 = (int)(-(g_ddhChartY + 0.012f) * (1.0f / 0.6f) * (float)ch);
        const int r2 = (int)((g_ddhChartX - 0.012f + g_ddhChartW + 0.024f) * 1.25f * (float)cw);
        const int b2 = (int)((-(g_ddhChartY + 0.012f) + g_ddhChartH + 0.024f) * (1.0f / 0.6f) * (float)ch);
        return x >= l2 && x < r2 && y >= t2 && y < b2;
    }
    if (g_ddhPanelFrameRectOk)
    {
        const int l = max(0, min(cw - 1, (int)g_ddhPanelFrameL));
        const int t = max(0, min(ch - 1, (int)g_ddhPanelFrameT));
        const int r = max(l + 1, min(cw, (int)g_ddhPanelFrameR));
        const int b = max(t + 1, min(ch, (int)g_ddhPanelFrameB));
        if (InterlockedIncrement(&g_ddhPanelClickLogged) <= 8)
            LogLine("闈㈡澘鐐瑰嚮锛氬抚鐭╁舰(瑁佸埌瀹㈡埛鍖? (%d,%d)-(%d,%d) 榧犳爣(%d,%d)", l, t, r, b, x, y);
        return x >= l && x < r && y >= t && y < b;
    }

    if (!(g_ddhPanelHitW > 0.0f && g_ddhPanelHitH > 0.0f)) return 0;
    const int l = (int)(g_ddhPanelHitL * (float)cw);
    const int t = (int)(-g_ddhPanelHitT * (float)ch);
    const int r = (int)((g_ddhPanelHitL + g_ddhPanelHitW) * (float)cw);
    const int b = (int)((-g_ddhPanelHitT + g_ddhPanelHitH) * (float)ch);
    if (InterlockedIncrement(&g_ddhPanelClickLogged) <= 8)
        LogLine("闈㈡澘鐐瑰嚮锛氬綊涓€鍖栧懡涓尯 (%d,%d)-(%d,%d) 榧犳爣(%d,%d) 瀹㈡埛鍖?%dx%d", l, t, r, b, x, y, cw, ch);
    return x >= l && x < r && y >= t && y < b;
}

static LRESULT CALLBACK DdhGameWndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
    if (msg == DDH_WM_HOTKEY)
    {
        /* 杩欎釜鍥炶皟灏卞湪娓告垙绾跨▼涓婏紝寮曟搸璋冪敤鏄畨鍏ㄧ殑锛堝拰鎻掍欢 OnHotkeyGameThread 鍚屾锟?*/
        __try { DdhProcessPending(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("鐑敭锛氬鐞嗗緟鍔炲紓甯?code=%08X锛堝凡鍚炴帀锛屼笉褰卞搷浼ゅ閽╁瓙锛?, (unsigned)GetExceptionCode());
        }
        return 0;
    }

    /* v10锛欳# 鐨勩€愭垬鍦哄崟浣嶃€戦〉鏈夋柊璇锋眰 鈥旓拷?灏卞湪娓告垙绾跨▼涓婅В鏋愬睘鎬э紙JASS 鍙兘鍦ㄨ繖閲岃皟锟?*/
    if (msg == DDH_WM_ATTR)
    {
        __try { DdhProcessAttrRequest(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("ATTR wnd 澶勭悊璇锋眰寮傚父 code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
        }
        return 0;
    }

    /* v15锛欳# 鐨勯樀浜￠潰锟?/ 鑻遍泟鏌ヨ璇锋眰 鈥旓拷?鍚屾牱鍙湪娓告垙绾跨▼鍔ㄥ紩锟?UI / JASS锟?*/
    if (msg == DDH_WM_PANEL)
    {
        __try { DdhProcessPanelRequest(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("闈㈡澘 wnd 澶勭悊璇锋眰寮傚父 code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
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
            LogLine("闈㈡澘 wnd 澶勭悊鑻遍泟鏌ヨ寮傚父 code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
        }
        return 0;
    }
    if (msg == DDH_WM_PANEL_TICK)
    {
        __try { DdhPanelTick(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        return 0;
    }

    /* `~` 鏄鹃殣锛氶敭锟?`~`锛圴K_OEM_3锛夋樉锟?闅愯棌闈㈡澘銆傚彧鏈夆€滅湡鐨勬湁闈㈡澘鍙垏鈥濇椂鎵嶅悶閿紝
       鍏朵綑鎯呭喌鍘熸牱杞彂锛岄伩鍏嶆姠鎺夌敤鎴风粰 `~` 缁戠殑鍏朵粬鍔熻兘锟?
       娉ㄦ剰锛氭湰鍑芥暟鍦ㄦ父鎴忕嚎绋嬶紱TranslateMessage 宸茬粡璺戣繃锛屽悶 WM_KEYDOWN 涓嶄細褰卞搷鑱婂ぉ瀛楃锟?*/
    if (msg == WM_KEYDOWN && (UINT)wp == VK_OEM_3 && (lp & 0x40000000L) == 0)
    {
        int handled = 0;
        __try { handled = DdhDoToggleVisible(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("闈㈡澘锛殈 鍒囨崲寮傚父 code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
        }
        if (handled) return 0;
    }

    /* ESC锛氬睍寮€鎬佷笅鐩存帴鏀剁缉闈㈡澘锛堟敹缂╂€佷笉鎷︽埅锛屼繚鐣欐父鎴忚彍鍗曪級 */
    if (msg == WM_KEYDOWN && (UINT)wp == VK_ESCAPE && DdhChartEscCollapse())
        return 0;

    /* v17锛氶紶鏍囧乏閿偣鏁村潡闈㈡澘灞曞紑/鏀惰捣锛涘懡涓椂鍚炴帀娑堟伅锛岄伩鍏嶉€変腑鍦伴潰/绉诲姩锟?
       闈㈡澘闅愯棌/鐐瑰湪闈㈡澘澶栨椂瀹屽叏涓嶅姩锛屽師鏍疯浆鍙戯拷?*/
    if (msg == WM_SETCURSOR)
    {
    }
    if (msg == WM_LBUTTONDOWN)
    {
        const int x = (int)(short)LOWORD(lp);
        const int y = (int)(short)HIWORD(lp);
        if (DdhPanelHitTest(x, y))
        {
            g_ddhPanelMouseDown = 1;
            return 0;
        }
    }
    else if (msg == WM_LBUTTONUP)
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
                    DdhPanelClickAt(x, y);   /* 鍥捐〃妯″紡锛氱偣鏌卞瓙涓嬮捇/杩斿洖锛涙枃鏈ā寮忥細灞曞紑/鏀惰捣 */
                }
            }
            return 0;
        }
    }
    else if (msg == WM_LBUTTONDBLCLK)
    {
        const int x = (int)(short)LOWORD(lp);
        const int y = (int)(short)HIWORD(lp);
        if (DdhPanelHitTest(x, y))
        {
            g_ddhPanelMouseDown = 1;   /* 璁╅殢鍚庣殑 up 涔熻鍚炴帀锛堝幓鎶栭樆姝簩娆″垏鎹級 */
            return 0;
        }
    }

    /* 鍏跺畠娑堟伅涓€寰嬪師鏍疯浆缁欐父鎴忚嚜宸辩殑绐楀彛杩囩▼锛岀粷涓嶅悶锟?
       娉ㄦ剰 A/W 蹇呴』閰嶅锛氶瓟锟?1.27 鐨勭獥鍙ｆ槸 ANSI 绫伙紙RegisterClassA锛夛紝锟?CallWindowProcW
       杞彂浼氭妸 WM_CHAR / WM_SETTEXT 涔嬬被锟?Unicode 瑙ｉ噴锛岃交鍒欒亰澶╄緭鍏ラ敊涔便€侀噸鍒欏穿娓告垙锟?*/
    if (g_prevWndProc)
        return g_wndUnicode ? CallWindowProcW(g_prevWndProc, hwnd, msg, wp, lp)
                            : CallWindowProcA(g_prevWndProc, hwnd, msg, wp, lp);
    return g_wndUnicode ? DefWindowProcW(hwnd, msg, wp, lp)
                        : DefWindowProcA(hwnd, msg, wp, lp);
}

/* 鎵惧埌锛堟垨閲嶆柊鎵惧埌锛夋父鎴忕獥鍙ｅ苟鎸備笂鎴戜滑鐨勭獥鍙ｈ繃绋嬨€傝繑锟?1 = 鍙敤锟?*/
static int DdhEnsureGameWnd(void)
{
    if (g_gameWnd && IsWindow(g_gameWnd))
    {
        if (g_prevWndProc &&
            GetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC) != (LONG_PTR)DdhGameWndProc)
        {
            /* 娓告垙鑷繁鎶婄獥鍙ｈ繃绋嬫敼鍥炲幓浜嗭紙鍒囧垎杈ㄧ巼/鍏ㄥ睆/閲嶅紑绐楀彛锛夆啋 閲嶆柊鎸備笂 */
            g_wndUnicode = IsWindowUnicode(g_gameWnd) ? 1 : 0;
            g_prevWndProc = g_wndUnicode
                ? (WNDPROC)SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc)
                : (WNDPROC)SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc);
            if (InterlockedIncrement(&g_wndLogCount) <= 8)
                LogLine("鐑敭锛氱獥鍙ｈ繃绋嬭娓告垙鏀瑰洖锛屽凡閲嶆柊鎸備笂锛堢獥鍙?%p锛?, (void*)g_gameWnd);
        }
        return g_prevWndProc ? 1 : 0;
    }

    g_gameWnd = NULL;
    g_prevWndProc = NULL;
    g_wndCand = 0;
    DdhWndPick pick;
    pick.score = -1;          /* -1 淇濊瘉绗竴涓€欓€夛紙鍝拷?score=0锛変竴瀹氳閫変腑 */
    pick.area  = -1;
    EnumWindows(DdhEnumWndProc, (LPARAM)&pick);
    if (!g_gameWnd)
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("鐑敭锛氭病鎵惧埌鍙寕鐨勬父鎴忕獥鍙ｏ紙鏈繘绋嬪彲瑙佺獥鍙?%d 涓紝鏈€鍚庝竴涓?%s銆?s銆嶏紱鎺у埗鍙扮獥鍙ｄ細琚烦杩囷級",
                    (int)g_wndCand, g_wndClass, g_wndTitle);
        return 0;
    }

    g_wndUnicode = IsWindowUnicode(g_gameWnd) ? 1 : 0;
    g_prevWndProc = g_wndUnicode
        ? (WNDPROC)SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc)
        : (WNDPROC)SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc);
    if (!g_prevWndProc)
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("鐑敭锛歋etWindowLongPtrW 澶辫触锛堢獥鍙?%p 绫?%s銆?s銆峞rr=%lu锛夛紝鐑敭鍙兘绛変激瀹充簨浠?,
                    (void*)g_gameWnd, g_wndClass, g_wndTitle, GetLastError());
        g_gameWnd = NULL;
        return 0;
    }

    if (InterlockedIncrement(&g_wndLogCount) <= 8)
        LogLine("鐑敭锛氬凡鎸傚埌娓告垙绐楀彛 %p锛堢被=%s銆?s銆嶏紝%s 鐗堬級锛屽姩浣滀細绔嬪埢鍦ㄦ父鎴忕嚎绋嬫墽琛岋紙涓嶅啀绛変激瀹充簨浠讹級",
                (void*)g_gameWnd, g_wndClass, g_wndTitle, g_wndUnicode ? "Unicode/W" : "ANSI/A");
    return 1;
}

/* 鐑敭绾跨▼鐢細鎶娾€滆澶勭悊寰呭姙浜嗏€濈珛鍒绘姇缁欐父鎴忕嚎绋嬶紱澶辫触灏遍€€鍥炴棫鐨勪激瀹充簨浠惰矾寰勶拷?*/
static void DdhPostHotkeyToGame(void)
{
    if (!DdhEnsureGameWnd())
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("鐑敭锛氭病鎵惧埌娓告垙绐楀彛锛屾湰娆″姩浣滈€€鍖栦负鈥滀笅涓€娆′激瀹充簨浠舵椂澶勭悊鈥濓紙鏈夊欢杩燂級");
        return;
    }
    if (!PostMessageW(g_gameWnd, DDH_WM_HOTKEY, 0, 0))
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("鐑敭锛歅ostMessage 澶辫触 err=%lu锛堥€€鍥炰激瀹充簨浠跺鐞嗭紝鏈夊欢杩燂級", GetLastError());
    }
}

/* 鐑敭绾跨▼锟?100ms 璋冧竴娆★細C# 閭ｈ竟鏈夋柊鐨勫睘鎬ц姹傚氨 PostMessage 缁欐父鎴忕獥鍙ｏ紝
   鐢辩獥鍙ｈ繃绋嬪湪娓告垙绾跨▼涓婂鐞嗭紙JASS native 鍙兘鍦ㄨ繖閲岃皟锛夛拷?*/
static void DdhMaybePostAttrRequest(void)
{
    if (!g_shm) return;
    const uint32_t req = g_shm->attrs.requestSeq;
    if (!req || req == g_ddhAttrPostedSeq) return;
    if (!DdhEnsureGameWnd()) return;                 /* 娌＄獥鍙ｏ細绛変激瀹充簨浠跺厹锟?*/
    if (PostMessageW(g_gameWnd, DDH_WM_ATTR, 0, 0)) g_ddhAttrPostedSeq = req;
}

/* DLL 鍗歌浇鏃舵妸绐楀彛杩囩▼杩樺洖鍘伙紱娓告垙杩樻椿鐫€鐨勭獥鍙ｄ笉杩橈紝灏变細鈥滆烦鍒板凡鍗歌浇鐨勬ā鍧椻€濆穿婧冿拷?*/
static void DdhRestoreGameWnd(void)
{
    if (g_gameWnd && g_prevWndProc && IsWindow(g_gameWnd) &&
        GetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC) == (LONG_PTR)DdhGameWndProc)
    {
        if (g_wndUnicode) SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)g_prevWndProc);
        else              SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)g_prevWndProc);
        LogLine("鐑敭锛氱獥鍙ｈ繃绋嬪凡杩樺師锛圖LL 鍗歌浇锛?);
    }
    g_gameWnd = NULL;
    g_prevWndProc = NULL;
}

/* 鏈€澶栧眰浼ゅ鍑芥暟閫€鍑哄悗鎵ц锛氬厛鍙戞帓闃熶腑鐨勬浜＄粨绠楋紝鍐嶅鐞嗙儹閿緟鍔烇拷?
   鍏ㄧ▼ __try 鈥旓拷?浠讳綍涓€姝ユ姏寮傚父閮藉彧鍐欐棩蹇楋紝缁濅笉褰卞搷浼ゅ閽╁瓙鏈韩锟?*/
static void DdhProcessDeferred(void)
{
    __try
    {
        if (InterlockedExchange(&g_ddhDeferKind, 0) != 0)
        {
            if (InterlockedCompareExchange(&g_ddhAutoSend, 0, 0) == 0)
            {
                if (InterlockedIncrement(&g_ddhSendSkipLogged) <= 10)
                    LogLine("缁撶畻骞挎挱锛氳嚜鍔ㄥ彂閫?鍏筹紝鏈涓嶅彂閫侊紙闀垮害 %u锛涚粺璁′粛鍦ㄧ户缁級",
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
        LogLine("缁撶畻骞挎挱澶辫触锛氬鐞嗗緟鍙戠粨绠楀紓甯?code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
    }

    __try
    {
        DdhProcessPending();
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("鐑敭锛氬鐞嗗緟鍔炲紓甯?code=%08X锛堝凡鍚炴帀锛屼笉褰卞搷浼ゅ閽╁瓙锛?, (unsigned)GetExceptionCode());
    }

    /* v15锛氶娆℃渶澶栧眰浼ゅ閫€鍑哄悗锛堟父鎴忕嚎绋嬶級鏄剧ず demo 闈㈡澘锛屼究浜庣湡鏈洪獙璇佸瓧锟?鍧愭爣锟?*/
    if (g_selfPanelPending)
    {
        g_selfPanelPending = 0;
        __try { DdhSelfPanelShow(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }

    __try { DdhPanelDemoOnce(); }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("闈㈡澘 demo 寮傚父 code=%08X锛堝凡鍚炴帀锛?, (unsigned)GetExceptionCode());
    }
}

/* ===========================================================================
   v15锛氭父鎴忓唴闃典骸闈㈡澘锛圵FE 鏂规锛氬€熷紩锟?CTextFrame 鏄剧ず锟?
   ---------------------------------------------------------------------------
   鍙湪**娓告垙绾跨▼**鍔ㄥ紩鎿庛€傚叡浜唴瀛樺彧璐熻矗锟?C# 缁勫ソ鐨勮鎼繘鏉ワ細
     PanelBlock.seq 鍙樺寲 -> 鎷峰嚭鍐呭 -> appliedSeq -> 娓告垙绾跨▼锟?澶嶇敤鏂囧瓧锟?
     -> SetFont / SetText / SetTextColor / SetPoint / Show -> TTL 鍒扮偣 Hide锟?
   澶辫触閾撅細鍏ュ彛鏍￠獙澶辫触 -> DisplayTimedTextToPlayer 鍏滃簳 -> 鍙啓鏃ュ織锟?
   1.27 RVA 宸茬敤 capstone 锟?C:\3rd\war5\game.dll 閫愭潯澶嶆牳锛堣 WFE-UI-淇敼鍘熺悊.md锛夛拷?
   =========================================================================== */

#define DDH_RVA_UI_GET_GAME   0x34F3A0u   /* CGameUI* GetGameUI(recreate, release) */
#define DDH_RVA_UI_CREATE_TEXT 0xA9560u   /* CTextFrame* (parent, 0, 0) */
#define DDH_RVA_UI_SET_FONT   0x9CE60u    /* (frame, name, float height, flags) */
#define DDH_RVA_UI_SET_FONTFLAGS 0xA93E0u /* (frame, uint32 fontFlags)锛氬紩鎿庡缓鏂囧瓧甯у悗锟?0x3008 */
#define DDH_RVA_UI_SET_TEXT   0xAA130u    /* (frame, const char* utf8) */
#define DDH_RVA_UI_SET_COLOR  0xAA210u    /* (frame, const uint32_t* argb) */
#define DDH_RVA_UI_SET_POINT  0xBD8A0u    /* (layout, anchor, rel, relAnchor, x, y, flag) */
#define DDH_RVA_UI_CREATE_BACKDROP 0x8E700u /* CBackdropFrame* (parent, 0, 0)锛汣BackdropFrame 鏋勶拷?0xA4700 */
#define DDH_RVA_UI_SET_BACKDROP   0xA62A0u  /* (frame, bgPath, blend, texFlag, edgePath, mirror) */
#define DDH_OFF_UI_LAYOUT_SUB 0xB4u       /* CFrame 鐨勫竷灞€瀛愬璞″亸锟?*/

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
static uint32_t       g_ddh3DFrames[DDH_ICON_MAX] = { 0 };
static volatile LONG  g_ddh3DEnabled = -1;   /* -1 鏈鐜锟? 鍏筹紱1 寮€ */
static volatile LONG  g_ddh3DLogged = 0;
static volatile LONG  g_ddh3DExceptAddr = 0;
static volatile LONG  g_ddh3DExceptCode = 0;

static int Ddh3DRecordExcept(EXCEPTION_POINTERS* ep)
{
    if (ep && ep->ExceptionRecord)
    {
        InterlockedExchange(&g_ddh3DExceptCode, (LONG)ep->ExceptionRecord->ExceptionCode);
        InterlockedExchange(&g_ddh3DExceptAddr, (LONG)(uintptr_t)ep->ExceptionRecord->ExceptionAddress);
    }
    return EXCEPTION_EXECUTE_HANDLER;
}

struct DdhIconCacheEntry
{
    uint32_t code;
    int      state;         /* 0=鏈煡 1=鏈夎矾锟?-1=鏃犺矾锟?*/
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
static volatile LONG  g_ddhSuppressPanel = 0;   /* v18锛氭湰鍦版浜℃槸闀滃儚/骞昏薄鏃讹紝闈㈡澘鐩存帴涓嶆樉锟?*/
static volatile LONG  g_ddhPanelTickPost = 0;

static DdhPanelBlock  g_ddhPendingPanel;
/* `~` 鏄鹃殣锛歚~` 閲嶆柊鏄剧ず鐢ㄧ殑鈥滀笂涓€娆￠潰鏉垮唴瀹光€濓紙C# 鍙戣繃 SHOW 鎵嶆湁锛汬IDE/TTL 涓嶆竻瀹冿級 */
static DdhPanelBlock  g_ddhLastPanel;
static volatile LONG  g_ddhHaveLastPanel = 0;
static volatile LONG  g_ddhPanelPinned   = 0;   /* 1 = `~` 鎵嬪姩鍞ゅ嚭锛屼笉锟?TTL 鑷姩闅愯棌 */
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

/* 锟?DdhChatEntryOk 鍚屾锛氭帴鍙楁爣鍑嗗簭瑷€ / 琚埆鐨勬彃浠舵敼锟?E9 鐨勬儏鍐碉拷?*/
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

/* 鎳掓牎锟?7 涓牳锟?UI 鍏ュ彛 + 2 涓彲閫夎儗鏅叆鍙ｃ€傚彧鍦ㄦ父鎴忕嚎绋嬭皟鐢ㄣ€傝繑锟?1 = 鏂囧瓧闈㈡澘鍙敤锟?*/
static int DdhInitUiFuncs(void)
{
    if (InterlockedCompareExchange(&g_ddhUiInitDone, 1, 0) != 0)
        return g_ddhUiGetGame != 0;
    if (!g_modBase)
    {
        LogLine("闈㈡澘锛氭病鏈?game.dll 鍩哄潃锛屾父鎴忓唴闈㈡澘涓嶅彲鐢?);
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
            LogLine("闈㈡澘锛氭父鎴忓唴 UI 涓嶅彲锟?鈥旓拷?%s(Game.dll+0x%X) 鍏ュ彛 %02X %02X %02X %02X 涓嶇"
                    "锛圙ame.dll 鐗堟湰涓嶅尮锟?琚埆鐨勬彃浠舵敼杩囷級",
                    core[i].name, core[i].rva, b[0], b[1], b[2], b[3]);
            return 0;
        }
    }
    for (int i = 0; i < 7; i++) *core[i].slot = g_modBase + core[i].rva;

    /* 鑳屾櫙鏄彲閫夐」锛氬叆鍙ｄ笉绗︽椂鍙叧鑳屾櫙锛屾枃瀛楅潰鏉跨収甯革拷?*/
    for (int i = 0; i < 2; i++)
    {
        const uint32_t fn = g_modBase + bgItems[i].rva;
        if (DdhUiEntryOk(fn))
            *bgItems[i].slot = g_modBase + bgItems[i].rva;
        else
        {
            *bgItems[i].slot = 0;
            LogLine("闈㈡澘锛氳儗鏅帴鍙?%s(Game.dll+0x%X) 鍏ュ彛涓嶇锛屾湰娆″彧鏄剧ず鏂囧瓧闈㈡澘",
                    bgItems[i].name, bgItems[i].rva);
        }
    }
    LogLine("闈㈡澘锛氬紩鎿?UI 鎺ュ彛宸插氨缁紙鏂囧瓧 7 椤癸紱鑳屾櫙 %s锛?,
            (g_ddhUiCreateBackdrop && g_ddhUiSetBackdrop) ? "2 椤瑰凡灏辩华" : "涓嶅彲鐢紙鍙樉绀烘枃瀛楋級");
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

static void DdhPanelHide(void)
{
    /* 鍥捐〃妯″紡锛氭妸鍥捐〃锟?鏂囧瓧/澶村儚涓€璧疯棌鎺夛紙甯у璞′繚鐣欙紝涓嬫閲嶅缓锟?*/
    DdhChartHide();

    /* 鎹㈠浘/UI 閲嶅缓鍚庢棫甯у璞″彲鑳藉凡缁忛噴鏀撅細鍙湁纭杩樻槸鍚屼竴锟?CGameUI 鎵嶇瀹冧滑锟?
       涓嶆槸鍚屼竴锟?UI 灏辨妸鎸囬拡涓㈡帀锛堜笉 free锛夛紝绛変笅娆℃樉绀烘椂鎸夋柊 UI 閲嶅缓锟?*/
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
            g_ddhPanelBgFailed = 0;   /* 锟?UI 鍏佽閲嶈瘯鑳屾櫙 */
            memset(g_ddhPanelIconFrames, 0, sizeof(g_ddhPanelIconFrames));
            memset(g_ddhPanelIconPaths, 0, sizeof(g_ddhPanelIconPaths));
            g_ddhPanelIconCount = 0;
            g_ddhPanelIconFramesFailed = 0;
            g_ddhIconCacheCount = 0;
            g_ddhPanelUi = ui;
        }
        else if (!ui)
        {
            /* 宸查€€锟?UI 鏆傛椂涓嶅彲鐢細鍙涪鎸囬拡锛屼笉纰版棫甯э紙閬垮厤 UAF锛夛紱涓嬫杩涘浘閲嶅缓锟?*/
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
        /* ui == 0锛堜笉鍦ㄥ浘閲岋級锛氫笉纰版棫甯э紝閬垮厤 UAF锛涗笅娆℃樉绀轰細閲嶆柊鏍￠獙锟?*/
    }
    g_ddhPanelShown = 0;
    g_ddhPanelPinned = 0;
    g_ddhPanelClickOk = 0;
    g_ddhPanelMouseDown = 0;
    g_ddhPanelFrameRectOk = 0;
}

/* 鑳屾櫙甯э細鍏堝垱寤猴紝淇濊瘉缁樺埗椤哄簭鍦ㄦ枃瀛楀抚涓嬮潰銆傚垱寤哄け璐ュ彧褰卞搷鑳屾櫙锛屼笉褰卞搷鏂囧瓧锟?
   setTexture=0 鏃跺彧寤虹┖甯у崰浣嶏紙鑳屾櫙鍏虫帀鏃朵篃涓嶈浠ュ悗鍚敤鐩栦綇鏂囧瓧锛夛拷?*/
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
                LogLine("闈㈡澘锛氬垱寤鸿儗鏅抚澶辫触锛屾湰娆?鏈眬鍙敤鏂囧瓧闈㈡澘");
            return;
        }
        g_ddhPanelBgFrame = frame;
        g_ddhPanelBgTextured = 0;
        __try
        {
            uint8_t* q = (uint8_t*)(uintptr_t)frame;
            q[0xAC] = 0xFF;                             /* 锟?alpha = 涓嶉€忔槑 */
            *(float*)(uintptr_t)(frame + 0x1B8) = 0.012f; /* 杈规鏇存槑锟?*/
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        DdhFrameShowHide((void*)(uintptr_t)frame, 0);   /* 寤哄ソ鍏堣棌璧锋潵锛岀瓑 Apply 鍐冲畾 */
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
            LogLine("闈㈡澘锛歋etBackdrop 寮傚父锛屾湰娆?鏈眬鍙敤鏂囧瓧闈㈡澘");
        return;
    }
    g_ddhPanelBgTextured = 1;
    if (InterlockedIncrement(&g_ddhPanelBgLogged) <= 3)
        LogLine("闈㈡澘锛氳儗鏅凡灏辩华锛坆g=%s edge=%s width=%.3f锛?,
                g_ddhPanelBgPath, useEdge ? g_ddhPanelBgEdge : "(鏃?", g_ddhPanelBgWidth);
}

/* 澶村儚鍗犱綅甯э細鍏堜簬鏂囧瓧鍒涘缓锛屼繚璇佺粯鍒跺眰绾у湪鑳屾櫙涓娿€佹枃瀛椾笅锛涙棤澶村儚鏃堕殣钘忥拷?*/
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
                LogLine("闈㈡澘锛氬垱寤哄ご鍍忓抚澶辫触锛堜笉褰卞搷鏂囧瓧/鐐瑰嚮锛?);
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

/* ---- 瀹為獙锛氫激瀹虫潵锟?3D 妯″瀷鑲栧儚锛圕PortraitButton锟?----
   WFE 璇佹槑 1.27 锟?CPortraitButton 鏋勯€犲嚱鏁板湪 0x6F3835C0锛屽弬鏁版槸锟?frame锟?
   vtable +0x28 锟?SetUnit(CUnit*)锟?D 鍛戒护鍗″浘鏍囩户缁繚鐣欙紝3D 鍙鐩栧湪
   鍚屼竴浣嶇疆锛涙壘涓嶅埌/澶辫触鏃惰浣嶇疆浠嶇敱 2D 鍥炬爣鏄剧ず锟?*/
static int Ddh3DReadEnv(void)
{
    LONG v = InterlockedCompareExchange(&g_ddh3DEnabled, -1, -1);
    if (v != -1) return v;
    char buf[16] = { 0 };
    const DWORD n = GetEnvironmentVariableA("DDH_3D_PORTRAIT", buf, (DWORD)sizeof(buf));
    int on = 1;
    if (n > 0 && (_stricmp(buf, "0") == 0 || _stricmp(buf, "off") == 0 ||
                  _stricmp(buf, "false") == 0 || _stricmp(buf, "no") == 0))
        on = 0;
    InterlockedExchange(&g_ddh3DEnabled, on ? 1 : 0);
    return on;
}

static uint32_t Ddh3DFindUnit(uint32_t code)
{
    if (!g_shm || !code) return 0;
    uint32_t first = 0;
    for (int i = 0; i < DDH_ATTR_MAX; ++i)
    {
        const uint32_t u = g_shm->attrs.unitAddr[i];
        if (u < 0x10000u || u > 0x7FFFFFFFu) continue;
        uint32_t got = 0;
        __try { got = *(const uint32_t*)(uintptr_t)(u + 0x30u); }
        __except (EXCEPTION_EXECUTE_HANDLER) { got = 0; }
        if (!first && got) first = u;
        if (got == code) return u;
    }
    return first;   /* 棰勮/棣栨闈㈡澘鏃跺睘鎬ц〃鍙兘杩樻病鎸夋潵婧愮爜濉弧锛屽厛鐢ㄤ竴涓湡瀹炲崟浣嶉獙锟?3D 锟?*/
}

static uint32_t Ddh3DEnsureFrame(int i, uint32_t ui)
{
    if (i < 0 || i >= DDH_ICON_MAX) return 0;
    if (g_ddh3DFrames[i]) return g_ddh3DFrames[i];
    void* mem = VirtualAlloc(NULL, 0x400, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!mem) return 0;
    __try
    {
        typedef void (__thiscall* fn_portrait_ctor_t)(void*, void*);
        const uint32_t ctor = g_modBase + 0x3835C0u;   /* CPortraitButton 鏋勯€狅紙RVA锟?*/
        ((fn_portrait_ctor_t)(uintptr_t)ctor)(mem, (void*)(uintptr_t)ui);
        g_ddh3DFrames[i] = (uint32_t)(uintptr_t)mem;
        if (InterlockedIncrement(&g_ddh3DLogged) <= 8)
            LogLine("闈㈡澘3D锛氬垱寤?CPortraitButton[%d] = 0x%08X锛堢埗 CGameUI=0x%08X锛?,
                    i, (unsigned)(uintptr_t)mem, ui);
        return g_ddh3DFrames[i];
    }
    __except (Ddh3DRecordExcept(GetExceptionInformation()))
    {
        const DWORD code = GetExceptionCode();
        if (InterlockedIncrement(&g_ddh3DLogged) <= 8)
            LogLine("闈㈡澘3D锛欳PortraitButton 鏋勯€犲紓甯?code=0x%08X addr=0x%08X锛屽凡闄嶇骇涓?2D",
                    (unsigned)code, (unsigned)g_ddh3DExceptAddr);
        return 0;
    }
}

static void Ddh3DApply(uint32_t ui, int shown, const uint32_t* codes,
                       const uint32_t* lines, const uint32_t* addrs,
                       float x, float y, float lh)
{
    const int enabled = Ddh3DReadEnv();
    if (InterlockedIncrement(&g_ddh3DLogged) <= 1)
        LogLine("闈㈡澘3D锛?s锛圖DH_3D_PORTRAIT 榛樿寮€锛涜 0 鍙叧闂級", enabled ? "鍚敤" : "鍏抽棴");
    if (!enabled)
    {
        for (int i = 0; i < DDH_ICON_MAX; ++i)
            if (g_ddh3DFrames[i]) DdhFrameShowHide((void*)(uintptr_t)g_ddh3DFrames[i], 0);
        return;
    }
    const float h = lh * 1.1f;
    const float w = h * 0.78f;
    for (int i = 0; i < DDH_ICON_MAX; ++i)
    {
        const uint32_t line = lines[i];
        const uint32_t unit = (i < g_ddhPanelIconCount && (int)line < shown)
            ? (addrs[i] ? addrs[i] : Ddh3DFindUnit(codes[i])) : 0;
        if (!unit)
        {
            if (g_ddh3DFrames[i]) DdhFrameShowHide((void*)(uintptr_t)g_ddh3DFrames[i], 0);
            continue;
        }
        const uint32_t frame = Ddh3DEnsureFrame(i, ui);
        if (!frame) continue;
        uint32_t layout = frame + DDH_OFF_UI_LAYOUT_SUB;
        __try
        {
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)layout, 0, 0u, ui + DDH_OFF_UI_LAYOUT_SUB, 0u,
                x, y - (float)line * lh, 1);
            ((fn_ui_setpoint_t)(uintptr_t)g_ddhUiSetPoint)(
                (void*)(uintptr_t)layout, 0, 8u, ui + DDH_OFF_UI_LAYOUT_SUB, 0u,
                x + w, y - (float)line * lh - h, 1);
            const uint32_t vt = *(const uint32_t*)(uintptr_t)frame;
            if (vt)
            {
                typedef void (__thiscall* fn_set_unit_t)(void*, uint32_t);
                const uint32_t fn = *(const uint32_t*)(uintptr_t)(vt + 0x28u);
                if (fn) ((fn_set_unit_t)(uintptr_t)fn)((void*)(uintptr_t)frame, unit);
            }
            DdhFrameShowHide((void*)(uintptr_t)frame, 1);
            if (InterlockedIncrement(&g_ddh3DLogged) <= 16)
                LogLine("闈㈡澘3D锛歭ine=%u code=0x%08X unit=0x%08X frame=0x%08X",
                        line, codes[i], unit, frame);
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            DdhFrameShowHide((void*)(uintptr_t)frame, 0);
        }
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

/* 浠庝竴涓彲璇绘寚閽堝彇 .blp 璺緞锛涙垚鍔熻繑锟?1锟?*/
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

/* 澶嶇敤 UDATA 锟?RegisterModel -> GetUnitData 鍙戠幇姝ラ锛屽彧鍋氫竴娆★拷?*/
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
        LogLine("闈㈡澘澶村儚锛欸etUnitData=0x%08X锛圧VA 0x%X锛孯egisterModel 寮曠敤 @0x%08X锛?,
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
        LogLine("闈㈡澘澶村儚锛歳esolve code=0x%08X typeDataOk=%d", code, (int)g_ddhTypeDataOk);
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
                    LogLine("闈㈡澘澶村儚锛歫ass.slk %s 瑙ｆ瀽鎴愬姛 code=0x%08X path=%s",
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
                /* 鏅€氬崟浣嶇殑鍛戒护鍗″浘鏍囦笉锟?UnitData 椤跺眰锛氶《灞傚彧鏄祵濂楀璞℃寚閽堬拷?
                   瀵瑰墠 0x300 涓寚閽堝啀鍋氫竴灞傛祬鎵弿锛屾壘 CommandButtons/BTN .blp锟?*/
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
        /* 绫诲瀷鏁版嵁/GetUnitData 閮借繕娌″氨缁椂涓嶈缂撳瓨鈥滄棤璺緞鈥濓紝鍚﹀垯鏈浘姘镐箙娌″ご鍍忥拷?*/
        if (!g_ddhTypeDataOk && !g_ddhIconGetUnitDataFn)
        {
            for (int i = 0; i < g_ddhIconCacheCount; ++i)
                if (g_ddhIconCache[i].code == code) { g_ddhIconCache[i].state = 0; break; }
            return false;
        }
        if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
            LogLine("闈㈡澘澶村儚锛氭潵婧愮被鍨嬬爜 0x%08X 鏈В鏋愬埌 .blp 鍥炬爣锛堝彧鏄剧ず鏂囧瓧锛?, code);
        return false;
    }
    strncpy_s(out, cap, path, _TRUNCATE);
    return true;
}

/* 甯ф覆鏌撲笉鍙敤鏃剁殑鍏滃簳锛氭嫾鎴愪竴鏉″甫 |n 鐨勬湰鏈烘秷鎭紝DisplayTimedTextToPlayer 鏄剧ず锟?*/
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
    LogLine("闈㈡澘锛氬抚娓叉煋涓嶅彲鐢紝鏀圭敤 DisplayTimedTextToPlayer 鍏滃簳锛?d 琛岋紝浠呮湰鏈哄彲瑙侊級", n);
    DdhShowLocalText(text);
}

/* 鐪熸锟?鏇存柊闈㈡澘銆傝繑锟?1 = 宸叉樉绀猴紝0 = UI 杩樻病灏辩华锛堝彲閲嶈瘯锛夛紝-1 = 宸插垽姝伙紙璧板厹搴曪級锟?*/
static int DdhPanelApply(const DdhPanelBlock* p)
{
    if (!p) return -1;
    DdhPanelReadEnvOnce();
    if (g_ddhPanelDisabled) return -1;
    if (g_ddhSuppressPanel)
    {
        DdhPanelHide();
        LogLine("闈㈡澘锛氶暅鍍?骞昏薄鍗曚綅锛岃烦杩囨樉绀?);
        return 1;
    }
    if (g_ddhUiBroken) return -1;
    if (!DdhInitUiFuncs()) { g_ddhUiBroken = 1; return -1; }

    const uint32_t ui = DdhGetGameUi();
    if (!ui)
    {
        if (InterlockedIncrement(&g_ddhPanelNoUiLogged) <= 3)
            LogLine("闈㈡澘锛欸etGameUI 涓虹┖锛堟湭杩涘浘/UI 杩樻病寤哄ソ锛夛紝绋嶅悗閲嶈瘯");
        return 0;
    }
    if (!DdhUiLooksReady(ui))
    {
        if (InterlockedIncrement(&g_ddhPanelNoUiLogged) <= 3)
            LogLine("闈㈡澘锛欳GameUI 0x%08X 鐨勬牴甯т笉鍙锛岀◢鍚庨噸璇?, ui);
        return 0;
    }

    if (g_ddhPanelUi != ui)
    {
        /* UI 閲嶅缓/鎹㈠浘锛氭棫甯ф寚閽堝叏閮ㄤ涪寮冿紙锟?free锛岄伩鍏嶅紩鎿庢瀽鏋勯闄╋紱姣忓紶鍥炬渶锟?20 涓紝杩涚▼鍐呮湁鐣岋級锟?*/
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
        LogLine("闈㈡澘锛氱粦瀹氬埌鏂扮殑 CGameUI 0x%08X锛堟牴甯?0x%08X锛?, ui, ui + DDH_OFF_UI_LAYOUT_SUB);
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

    /* flags bit4锛氭壙浼ゅ浘琛ㄦā寮忋€侰# 涓嶅啀鍙戞枃鏈锛岃€屾槸锟?lines 鍖烘斁 DdhChartReq{victim}锟?
       鍏蜂綋 5 绉掑垎锟?鍥涚被鍒嗘/鏉ユ簮鑱氬悎鍏ㄩ儴锟?ddh 浠庤嚜宸辩殑浜嬩欢鐜畻锛圕# 涓嶇敤鍐嶇畻涓€閬嶏級锟?*/
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

    /* 鑳屾櫙甯ф€绘槸鍦ㄦ枃瀛楀抚涔嬪墠鍒涘缓锛堣儗鏅叧鎺夋椂涔熷缓绌哄抚鍗犱綅锛夛紝淇濊瘉浠ュ悗鍚敤鏃朵笉浼氱洊浣忔枃瀛楋拷?*/
    const bool wantBg = ((p->flags & DDH_PANEL_FLAG_BG) != 0) && !g_ddhPanelNoBg;
    DdhPanelEnsureBackdrop(ui, wantBg ? 1 : 0);
    DdhPanelEnsureIconFrames(ui);
    const bool bgOn = wantBg && (g_ddhPanelBgTextured != 0) && !g_ddhPanelBgFailed;

    /* 澶村儚鍏堣В鏋愶紝鏉ユ簮琛屾枃瀛楄鎸夆€滃ご鍍忓搴︹€濈缉杩涳紱澶村儚鏀惧湪鏉ユ簮琛屽乏渚э紝閬垮厤闈㈡澘
       鍦ㄥ锟?缂╂斁鍚庢妸鍙充晶澶村儚鎺ㄥ埌灞忓箷澶栵拷?*/
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
        LogLine("闈㈡澘澶村儚锛氬噯澶?count=%d line0=%u code0=0x%08X shown=%d noIcons=%d",
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
                    LogLine("闈㈡澘澶村儚锛氳烦杩?line=%u锛坰hown=%d锛?, line, shown);
                continue;
            }
            if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
                LogLine("闈㈡澘澶村儚锛氬皾璇?i=%d count=%d line=%u code=0x%08X shown=%d",
                        i, g_ddhPanelIconCount, line, g_ddhPanelIconCodes[i], shown);
            if (!DdhIconResolve(g_ddhPanelIconCodes[i], iconPath[i], sizeof(iconPath[i])))
            {
                if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
                    LogLine("闈㈡澘澶村儚锛氳В鏋愬け璐?line=%u code=0x%08X", line, g_ddhPanelIconCodes[i]);
                continue;
            }
            iconActive[i] = 1;
            if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
                LogLine("闈㈡澘澶村儚锛歭ine=%u code=0x%08X path=%s",
                        line, g_ddhPanelIconCodes[i], iconPath[i]);
        }
    }
    else if (InterlockedIncrement(&g_ddhPanelIconLogged) <= 12)
    {
        LogLine("闈㈡澘澶村儚锛欴DH_NO_PANEL_ICONS=1锛岃烦杩囧ご鍍?);
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
                    LogLine("闈㈡澘锛氬垱寤烘枃瀛楀抚澶辫触锛堢 %d 琛岋級锛屾湰灞€鏀圭敤鍏滃簳鏄剧ず", i + 1);
                return -1;
            }
            g_ddhPanelFrames[i] = frame;
            g_ddhPanelFrameCount = i + 1;
            /* 鐓у紩鎿庡唴閮ㄥ缓鏂囧瓧甯у悗鐨勫垵濮嬪寲锛歠rame+0xC |= (frame+0x10 | 2)锟?*/
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
        /* 寮曟搸寤烘枃瀛楀抚鍚庡浐瀹氫紶 0x3008锛堥槾锟?鎻忚竟涓€绫诲瓧锟?flags锛夛拷?*/
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

    /* 闈㈡澘鍑犱綍锛氱偣鍑诲懡涓尯鍜岃儗鏅叡鐢紱鍗充娇鑳屾櫙鍏抽棴涔熻鏈夊懡涓尯锟?*/
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

    /* 鑳屾櫙灏哄锛氭锟?shown 锟?+ 涓婁笅鐣欑櫧锛涗袱涓偣瀹氫箟鐭╁舰锛堝彸涓嬬偣鐩稿鏍瑰乏涓婏紝缁濆鍧愭爣锛夛拷?*/
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

    /* 璁剧疆鐐瑰悗鍐嶈涓€娆¤儗鏅抚鐭╁舰锛涘竷灞€锟?UI 鍧愭爣锛屽彲鑳借秴鍑哄鎴峰尯锛屽懡涓祴璇曚細瑁佸埌瀹㈡埛鍖猴拷?*/
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
        LogLine("闈㈡澘鍑犱綍锛歴hown=%d bgH=%.4f rectOk=%d rect=(%.0f,%.0f)-(%.0f,%.0f) clickOk=%d",
                shown, bgH, (int)g_ddhPanelFrameRectOk,
                g_ddhPanelFrameL, g_ddhPanelFrameT, g_ddhPanelFrameR, g_ddhPanelFrameB,
                (int)g_ddhPanelClickOk);

    /* 澶村儚锛氭潵婧愯宸︿晶锟?.1 琛岄珮锛涙敹璧锋椂鏉ユ簮琛屼笉锟?shown 鍐呭垯闅愯棌锟?*/
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
    Ddh3DApply(ui, shown, g_ddhPanelIconCodes, g_ddhPanelIconLines, g_ddhPanelIconAddrs, x, y, lh);
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
        LogLine("闈㈡澘锛氬凡鏄剧ず %d/%d 琛岋紙%s锛岃儗鏅?%s锛孋GameUI=0x%08X锛屽瓧浣?%s %.4f锛屽潗鏍?%.3f/%.3f锛岃璺?%.4f锛宼tl=%u锛?,
                shown, n, g_ddhPanelCollapsed ? "鏀惰捣" : "灞曞紑", bgOn ? "寮€" : "鍏?,
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

/* 娓告垙绾跨▼锛欳# 锟?IconBlock 鏈夋柊搴忓彿灏辨嫹鍑烘潵锛坴17锛夛拷?*/
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
        LogLine("闈㈡澘锛氭敹鍒板ご鍍忚姹?seq=%u count=%d noIcons=%d line0=%u code0=0x%08X line1=%u code1=0x%08X",
                seq, n, (int)g_ddhPanelNoIcons,
                n > 0 ? local.slots[0].lineIndex : 0, n > 0 ? local.slots[0].rawcode : 0,
                n > 1 ? local.slots[1].lineIndex : 0, n > 1 ? local.slots[1].rawcode : 0);
}

/* 娓告垙绾跨▼锛欳# 锟?PanelBlock 鏈夋柊搴忓彿灏辨嫹鍑烘潵锟?*/
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
        g_ddhPanelPinned = 0;   /* `~` 鏄鹃殣锛欳# 涓诲姩闅愯棌锛屽彇娑堚€滄墜鍔ㄥ浐瀹氾拷?*/
        DdhPanelHide();
        LogLine("闈㈡澘锛氭敹鍒伴殣钘忚姹傦紙seq=%u锛?, seq);
        return;
    }

    g_ddhPanelCollapsed = ((local.flags & DDH_PANEL_FLAG_COLLAPSED) != 0) ? 1 : 0;
    int cl = (int)((local.flags >> DDH_PANEL_COLLAPSED_SHIFT) & DDH_PANEL_COLLAPSED_MASK);
    if (cl <= 0) cl = 3;
    if (cl > 3) cl = 3;
    g_ddhPanelCollapsedLines = cl;

    memcpy(&g_ddhPendingPanel, &local, sizeof(g_ddhPendingPanel));
    /* `~` 鏄鹃殣锛氱暀涓€浠界粰 `~` 閲嶆柊鏄剧ず锛涙柊缁撶畻閲嶆柊锟?TTL锛屼笉鍚冧笂娆＄殑鈥滄墜鍔ㄥ浐瀹氾拷?*/
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

/* 娓告垙绾跨▼锛歍TL 鍏滃簳锛圕# 涔熶細涓诲姩锟?hide锛涜繖鏉￠槻 C# 鍗′綇/鍏抽棴锛夛拷?*/
static void DdhPanelTick(void)
{
    if (g_ddhPendingValid && (LONG)GetTickCount() - g_ddhPendingTick >= 250)
        DdhPanelTryPending();

    /* 甯冨眬鐭╁舰閫氬父鍦ㄤ笅涓€甯ф墠鍐欏叆锛涙瘡 500ms 锟?tick 閲岃ˉ璇讳竴娆★紝淇鎵嬪瀷/鐐瑰嚮鍖猴拷?*/
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

    DdhChartReviveCheck();   /* 鏀剁缉鎬佷笅鑻遍泟澶嶆椿 3 绉掓竻闄?*/

    /* `~` 鏄鹃殣锛歚~` 鎵嬪姩鍞ゅ嚭鐨勯潰鏉夸笉鑷姩娑堝け锛堝啀鎸変竴锟?`~` 鎵嶉殣钘忥級 */
    if (g_ddhPanelShown && !g_ddhPanelPinned && (LONG)GetTickCount() >= g_ddhPanelHideAt)
    {
        DdhPanelHide();
        LogLine("闈㈡澘锛歍TL 鍒扮偣锛屽凡鑷姩闅愯棌");
    }
}

/* v16锛氶紶鏍囩偣鍑婚潰鏉垮睍寮€/鏀惰捣锛堜笉鍐嶆彁渚涘揩鎹烽敭锛夈€傚彧鍦ㄦ父鎴忕嚎绋嬭皟鐢拷?*/
static void DdhDoTogglePanel(void)
{
    if (!g_ddhPanelShown)
    {
        LogLine("闈㈡澘锛氱偣鍑绘椂娌℃湁鍙垏鎹㈢殑闈㈡澘");
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
            LogLine("闈㈡澘锛氱偣鍑诲垏鎹负%s锛?d 琛岋級",
                    g_ddhPanelCollapsed ? "鏀惰捣" : "灞曞紑",
                    g_ddhPanelCollapsed ? (int)g_ddhPanelCollapsedLines
                                        : (int)g_ddhPendingPanel.lineCount);
    }
    else
    {
        g_ddhPanelCollapsed = g_ddhPanelCollapsed ? 0 : 1;   // 澶辫触鍥為€€鐘讹拷?
        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("闈㈡澘锛氱偣鍑诲垏鎹㈠け璐ワ紙杩斿洖 %d锛?, r);
    }
}

/* `~` 鏄鹃殣锛氶敭锟?`~`锛圴K_OEM_3锛夋樉锟?闅愯棌锛堜笉鏄睍寮€/鏀惰捣锛涘睍寮€/鏀惰捣浠嶆槸榧犳爣鐐瑰嚮锛夛拷?
   杩斿洖鍊硷細1 = 杩欐鎸夐敭琚潰鏉挎秷璐癸紙绐楀彛杩囩▼瑕佸悶锟?WM_KEYDOWN锛夛紱0 = 娌℃湁闈㈡澘锛屽師鏍疯浆鍙戯拷?
   鍙湪娓告垙绾跨▼璋冪敤锛堢獥鍙ｈ繃绋嬮噷锛夛拷?*/
static int DdhDoToggleVisible(void)
{
    if (g_ddhPanelDisabled) return 0;

    /* 姝ｅ湪鏄剧ず 锟?闅愯棌锛坧inned 锟?DdhPanelHide 閲屼竴璧锋竻鎺夛級 */
    if (g_ddhPanelShown)
    {
        if (g_ddhChartMode)   /* 鍥捐〃妯″紡锛殈 = 鏀剁缉/灞曞紑 */
        {
            DdhChartToggleCollapsed();
            return 1;
        }
        DdhPanelHide();
        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("闈㈡澘锛殈 闅愯棌");
        return 1;
    }

    /* 宸查殣锟?锟?鐢ㄤ笂涓€浠藉唴瀹归噸鏂版樉绀猴紱娌℃湁鍐呭灏变粈涔堥兘涓嶅仛锛堟妸閿缁欐父鎴忥級 */
    if (!g_ddhHaveLastPanel)
    {
        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("闈㈡澘锛殈 娌℃湁鍙樉绀虹殑闈㈡澘锛堢瓑涓€娆℃湰鍦拌嫳闆勯樀浜＄粨绠楋級");
        return 0;
    }

    g_ddhPanelCollapsed = 0;   /* 鎵嬪姩鍞ゅ嚭鏃朵竴寰嬪睍寮€ */
    const int r = DdhPanelApply(&g_ddhLastPanel);
    if (r > 0)
    {
        g_ddhPanelPinned = 0;   /* 鎵嬪姩鍞ゅ嚭涓嶅啀姘镐箙鍥哄畾 */
        g_ddhPanelHideAt = (LONG)(GetTickCount() + 60000);   /* 60 绉掑悗鑷姩闅愯棌 */
        if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
            LogLine("闈㈡澘锛殈 閲嶆柊鏄剧ず锛?d 琛岋紝宸插浐瀹氫笉鑷姩闅愯棌锛?, (int)g_ddhLastPanel.lineCount);
        return 1;
    }

    if (InterlockedIncrement(&g_ddhHkPanelLogged) <= 30)
        LogLine("闈㈡澘锛殈 閲嶆柊鏄剧ず澶辫触锛堣繑鍥?%d锛沀I 娌″氨缁?宸查€€鍥撅紝绋嶅悗鍐嶆寜锛?, r);
    return 1;   /* 鏈夐潰鏉挎暟鎹絾杩欐 UI 娌″氨缁細浠嶅悶閿紝閬垮厤婕忓埌娓告垙閲?*/
}

/* ===========================================================================
   鎵夸激鍥捐〃锛坒lags bit4锛夛細鏈€锟?5 绉掓煴鐘跺浘 + 鐐规煴瀛愪笅閽荤殑鍥涚被浼ゅ鏉″舰锟?
   ---------------------------------------------------------------------------
   路 C# 鍙彂 DdhChartReq{victim}锟? 绉掑垎妗躲€佸洓绫诲綊绫汇€佹寜鏉ユ簮鍒嗘鍏ㄩ儴锟?ddh 閲岀敤
     鑷繁鐨勪簨浠剁幆锛坓_shm->ev锛夌畻锛屼笉鎵╁叡浜唴瀛橈拷?
   路 缁樺埗鍙敤寮曟搸甯э細CBackdropFrame 褰撴煴锟?鑹插潡锛堜袱锟?SetPoint 瀹氱煩褰級锟?
     CTextFrame 褰撴枃瀛楋紝鏉ユ簮澶村儚锟?CBackdropFrame + BLP 璐村浘锟?
   路 鐐瑰嚮澶嶇敤鐜版垚鐨勫懡涓煩褰㈤€氶亾锛涘浘琛ㄦā寮忎笅婊戝埌 DdhChartClick锟?
   路 棰滆壊锛氬紩鎿庡抚娌℃湁鍙潬鐨勯《鐐硅壊鎺ュ彛锛孉 鐗堢粺涓€鐢ㄦ殫鑹茶创锟?+ 鏂囧瓧鏍囩鍖哄垎鍥涚被锟?
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
    float    total[DDH_CHART_SECONDS];
    float    maxTotal;
    int      srcCount;
    DdhChartSrc src[DDH_CHART_MAX_SRC];
    int      segCount[DDH_CHART_SECONDS];
    DdhChartSeg seg[DDH_CHART_SECONDS][DDH_CHART_MAX_SEG];
} g_ddhChart;

static int      g_ddhChartView = 0;          /* 0 = 5 绉掓€昏锟?..5 = 锟?1..5 涓《涓嬮捇 */
static int      g_ddhChartDemo = 0;          /* 1 = 涓嬩竴锟?Apply 锟?mock 鏁版嵁锛堣皟鏍峰紡锟?*/
static uint32_t g_ddhChartUi = 0;
static DWORD    g_ddhChartBaseTick = 0;
static char     g_ddhChartFont[DDH_PANEL_FONT_NAME] = { 0 };
static uint32_t g_ddhChartFrames[DDH_CHART_FRAME_MAX];
static char     g_ddhChartFrameTex[DDH_CHART_FRAME_MAX][64];
static uint32_t g_ddhChartTexts[DDH_CHART_TEXT_MAX];
static uint32_t g_ddhChartIcons[DDH_CHART_ICON_MAX];
static char     g_ddhChartIconPath[DDH_CHART_ICON_MAX][128];
static float    g_ddhChartBar[DDH_CHART_SECONDS][4];   /* x0, x1, yTop, yBot锛圲I 褰掍竴鍖栵級 */
static int      g_ddhChartBarOk = 0;
static volatile LONG g_ddhChartLogCount = 0;

static int g_ddhChartUnitMode = 0;   /* 0=鍘熷€?1=涓?2=浜匡紙鐢辨€讳激瀹冲喅瀹氾紝鍏ㄨ〃缁熶竴锛?*/
static void DdhChartFormatScaled(char* out, size_t cap, float v)
{
    if (g_ddhChartUnitMode == 2)      _snprintf_s(out, cap, _TRUNCATE, "%.2f浜?, (double)(v / 100000000.0f));
    else if (g_ddhChartUnitMode == 1) _snprintf_s(out, cap, _TRUNCATE, "%.1f涓?, (double)(v / 10000.0f));
    else                              _snprintf_s(out, cap, _TRUNCATE, "%.0f", (double)v);
}

static void DdhChartFormatBar(char* out, size_t cap, float v)
{
    if (g_ddhChartUnitMode == 2)      _snprintf_s(out, cap, _TRUNCATE, "%.1f浜?, (double)(v / 100000000.0f));
    else if (g_ddhChartUnitMode == 1) _snprintf_s(out, cap, _TRUNCATE, "%.0f涓?, (double)(v / 10000.0f));
    else                              _snprintf_s(out, cap, _TRUNCATE, "%.0f", (double)v);
}

static void DdhChartFormatAmount(char* out, size_t cap, float v)
{
    if (v >= 100000000.0f)      _snprintf_s(out, cap, _TRUNCATE, "%.2f浜?, (double)(v / 100000000.0f));
    else if (v >= 10000.0f)     _snprintf_s(out, cap, _TRUNCATE, "%.1f涓?, (double)(v / 10000.0f));
    else                        _snprintf_s(out, cap, _TRUNCATE, "%.0f", (double)v);
}

/* 浜嬩欢 锟?鍥涚被锟?=鐗╃悊 1=娉曟湳 2=绾补 3=鐢熷懡绉婚櫎锛堟寜 ddh 璁板綍锟?isPhysical/浼ゅ绫诲瀷鎺╃爜鎺級 */
/* 鍥涚被鍙ｅ緞锛氱墿鐞?= 浼ゅ绫诲瀷 4锛涙硶鏈?= 鏀诲嚮绫诲瀷 0锛?
   绾补 = 鏀诲嚮绫诲瀷 != 0 涓?浼ゅ绫诲瀷 != 4锛涚Щ闄?= 鍑€鎺夎 - 鍦板浘浼ゅ锛圔uild 閲屾寜娈嬪樊鍏ヨ处锛夈€?*/
static int DdhChartKind(const DdhEvent* e)
{
    uint32_t m = e->damageMask;
    int dt = -1;
    if (m)
    {
        int b = 0;
        while (b < 31 && (m & (1u << b)) == 0) ++b;
        dt = b;                            /* 浼ゅ绫诲瀷 = log2(mask)锛?x10 -> 4锛?*/
    }
    if (e->attackType != 0 && dt != 4) return 2;   /* 绾补锛堝厛鍒わ級锛氭敾鍑荤被鍨?!= 0 涓?浼ゅ绫诲瀷 != 4 */
    if (dt == 4) return 0;                        /* 鐗╃悊锛氫激瀹崇被鍨?4 */
    if (e->attackType == 0) return 1;             /* 娉曟湳锛氭敾鍑荤被鍨?0 */
    return 1;
}

static int DdhChartSrcSlot(uint32_t addr, uint32_t code)
{
    for (int i = 0; i < g_ddhChart.srcCount; ++i)
        if (code ? (g_ddhChart.src[i].code == code) : (g_ddhChart.src[i].addr == addr)) return i;   /* 鎸夊崟浣嶇被鍨嬪悎骞?*/
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

/* 浠庝簨浠剁幆閲屾壘 victim 鏈€杩戜竴娆′簨浠剁殑 tick */
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
        uint32_t dt = endTick - e->tickMs;
        if (dt >= (uint32_t)(DDH_CHART_SECONDS * 1000)) continue;   /* 涓庢《鏁颁竴鑷寸殑绐楀彛 */
        int bucket = DDH_CHART_SECONDS - 1 - (int)(dt / 1000u);

        const float net = (e->hpValid && e->actual > 0.01f) ? e->actual : 0.0f;
        /* 鍙鍦板浘浼ゅ锛堝嚭鍙?*out锛寁20 鍦ㄢ€滅‘瀹炴帀琛€鈥濇椂缃?bit0 鍙俊锛夈€?
           娌℃湁鍙俊鍦板浘浼ゅ鐨勪簨浠剁洿鎺ヨ烦杩囷紝涓嶅啀閫€鍥?engineDamage / amount / 鍑€鎺夎锛?
           engineDamage 鏄噺浼ゅ墠鐨勫€硷紝浼氭妸 99% 鎶楁€у悗鐨?1% 鎵夸激鐢绘垚 100%銆?*/
        if (!((e->finalFlags & 1u) && e->finalDamage > 0.01f)) continue;
        const float eff = e->finalDamage;
        const int kind = DdhChartKind(e);
        DdhChartAdd(bucket, kind, e->source, e->sourceCode, eff);
        const float removal = net - eff;                                     /* 绉婚櫎 = 鍑€鎺夎 - 鍦板浘浼ゅ */
        if (removal > 0.01f) DdhChartAdd(bucket, 3, e->source, e->sourceCode, removal);
    }

    for (int i = 0; i < DDH_CHART_SECONDS; ++i)
        if (g_ddhChart.total[i] > g_ddhChart.maxTotal) g_ddhChart.maxTotal = g_ddhChart.total[i];
    g_ddhChart.valid = (g_ddhChart.maxTotal > 0.01f) ? 1 : 0;

    /* 姣忔《鍐呮寜閲戦闄嶅簭锛堟覆锟?澶村儚鎸戝ぇ澶寸敤锟?*/
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

/* ---- 锟?鏂囧瓧/澶村儚 ---- */
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

/* 鎸囧畾璐村浘锛圱eamColor 绾壊锛夎缃埌鏌愪釜妲戒綅锛涘悓涓€妲戒綅璐村浘鍙樹簡鎵嶉噸璁俱€?*/
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
    (void)argb;   /* 寮曟搸甯ф病鏈夊彲闈犵殑椤剁偣鑹插瓧娈碉細0xB0 涓嶆槸棰滆壊锛屽啓 float 浼氭妸甯ф墦宕┿€傚彧淇濈暀 alpha銆?*/
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
    const float h = size * 0.75f * aspect;   /* x/y 鍗曚綅姣斾緥涓嶅悓锛氭寜瀹㈡埛鍖哄楂樻瘮鎹㈡垚鍍忕礌姝ｆ柟褰?*/
    DdhChartRect(f, x, yTop, x + size, yTop - h);
    DdhFrameShowHide((void*)(uintptr_t)f, 1);
}

static void DdhChartHideAll(void)
{
    /* 鍙湁杩樺仠鍦ㄥ悓涓€锟?CGameUI 涓婃墠纰版棫甯э紱鎹㈠浘/閫€鍥惧悗寮曟搸鍙兘宸茬粡閲婃斁瀹冧滑锟?
       杩欐椂鍙涪鎸囬拡锛堜笉 free锛夛紝閬垮厤 UAF锟?*/
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

    DdhChartText(0, "鎵夸激 路 鏈€杩?5 绉?, g_ddhChartX, g_ddhChartY, g_ddhChartFh * 1.05f, 0xFFF0E0C0u);
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
        if ((i % 2) == 0) DdhChartText(24 + i, buf, bx0 + 0.003f, base - g_ddhChartFh * 1.05f, g_ddhChartFh * 0.62f, 0xFFB0B0B0u);
    }
}

static void DdhChartRenderDetail(int bucket)
{
    static const char* kNames[DDH_CHART_TYPES] = { "鐗╃悊", "娉曟湳", "绾补", "绉婚櫎" };
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
        _snprintf_s(title, sizeof(title), _TRUNCATE, "绗?-%d 绉?路 鎵夸激鏋勬垚  %s",
                    DDH_CHART_SECONDS - bucket, buf);
        DdhChartText(0, title, g_ddhChartX, g_ddhChartY, g_ddhChartFh * 1.05f, 0xFFF0E0C0u);
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
            /* 鏂偣涓婃柟鏄剧ず璇ユ潵婧愬ご鍍忥紙姣忎釜绫诲瀷鏈€锟?3 涓紝閬垮厤绯婃垚涓€鐗囷級 */
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

/* Dota2 寮忓崟灞忥細宸︿笂浼ゅ绫诲瀷銆佸彸涓婃潵婧愶紙澶村儚+浼ゅ锛夈€佸簳閮ㄦ渶杩?5 绉掓煴鐘跺浘锛涗笉鍐嶄笅閽汇€?*/
static void DdhChartRenderCombined(void)
{
    static const char* kNames[DDH_CHART_TYPES] = { "鐗╃悊", "娉曟湳", "绾补", "绉婚櫎" };
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

    DdhChartText(0, "闃典骸鎬荤粨", g_ddhChartX, g_ddhChartY, g_ddhChartFh * 1.08f, 0xFFF0E0C0u);
    {
        char tb[64]; DdhChartFormatScaled(tb, sizeof(tb), grand);
        char tot[96]; _snprintf_s(tot, sizeof(tot), _TRUNCATE, "鎬讳激瀹?%s", tb);
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
        if ((i % 2) == 0) DdhChartText(24 + i, buf, bx0 + 0.003f, base - g_ddhChartFh * 1.05f, g_ddhChartFh * 0.62f, 0xFFB0B0B0u);
    }
}


static void DdhChartRender(void);
static void DdhChartToggleCollapsed(void);
static void DdhChartReviveCheck(void);

/* ---------- 鏀剁缉 / 灞曞紑 ---------- */
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

/* 鏀剁缉鎬侊細灏忛潰鏉匡紙鏍囬 + 鎬讳激瀹?+ 褰╄壊鏉★級 */
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
    DdhChartText(0, "闃典骸鎬荤粨", g_ddhChartX + 0.004f, g_ddhChartY - 0.002f, g_ddhChartFh * 0.8f, 0xFFF0E0C0u);
    {
        char tb[64]; DdhChartFormatScaled(tb, sizeof(tb), grand);
        char tot[96]; _snprintf_s(tot, sizeof(tot), _TRUNCATE, "鎬讳激瀹?%s", tb);
        DdhChartText(39, tot, g_ddhChartX + 0.046f, g_ddhChartY - 0.002f, g_ddhChartFh * 0.62f, 0xFFFFD080u);
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
    LogLine("鍥捐〃锛?s", g_ddhChartCollapsed ? "宸叉敹缂? : "宸插睍寮€");
}

/* 鏀剁缉鎬佷笅鑻遍泟澶嶆椿锛氭弧 3 绉掓竻鎺夐潰鏉?*/
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
        LogLine("闈㈡澘锛氳嫳闆勫凡澶嶆椿锛屾敹缂╂€侀潰鏉?3 绉掑埌锛屾竻闄?);
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

/* 鍥捐〃鐐瑰嚮锛氭€昏鐐规煴锟?锟?涓嬮捇璇ョ锛涗笅閽讳换鎰忎綅锟?锟?鍥炴€昏锟?*/
static void DdhChartClick(int px, int py)
{
    static DWORD lastClick = 0;
    const DWORD nowClick = GetTickCount();
    if (nowClick - lastClick < 500u) return;   /* 涓€娆＄偣鍑讳細鏉ヤ袱鏉?UP锛岄槻鎶栧彧浣滅敤浜庣偣鍑?*/
    lastClick = nowClick;
    {
        RECT irc = { 0 };
        if (g_gameWnd && GetClientRect(g_gameWnd, &irc) && irc.right > 0 && irc.bottom > 0)
        {
            const float u = (float)px / (float)irc.right * 0.8f;
            const float v = -(float)py / (float)irc.bottom * 0.6f;
            if (u >= g_ddhChartIconL - 0.006f && u <= g_ddhChartIconL + g_ddhChartIconW + 0.006f &&
                v <= g_ddhChartIconT + 0.006f && v >= g_ddhChartIconT - g_ddhChartIconH - 0.008f)
            { DdhChartToggleCollapsed(); return; }
        }
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
        if (!changed) return;                     /* 鐐圭┖鐧斤細淇濇寔鎬昏 */
    }
    else
    {
        g_ddhChartView = 0;                       /* 涓嬮捇閲岀偣浠讳綍浣嶇疆閮藉洖鎬昏 */
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
            LogLine("鍥捐〃锛氱偣鍑?-> %s", g_ddhChartView ? "涓嬮捇" : "鎬昏");
    }
}

/* mock 鏁版嵁锟? 涓《锟? 涓潵婧愶拷? 绫讳激瀹抽兘鏈夛紝涓撻棬鐢ㄦ潵璋冩牱寮忥紙涓嶉渶瑕佺湡鐨勬尐锟?姝讳骸锛夛拷?*/
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
        DdhChartAdd(demo[i].b, demo[i].t, kAddrs[demo[i].s], kCodes[demo[i].s], demo[i].a * 105.374f);   /* mock 鎬讳激瀹?鈮?999999 */

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
}

static int DdhChartApply(uint32_t ui, const DdhPanelBlock* p, uint32_t victim,
                         float x, float y, float fh, const char* font)
{
    if (g_ddhPanelDisabled) return -1;
    if (!g_ddhUiCreateBackdrop || !g_ddhUiSetBackdrop || !g_ddhUiCreateText)
        return -1;

    /* 鎹㈠浘/UI 閲嶅缓锛氭棫甯у璞″彲鑳藉凡琚紩鎿庨噴鏀撅紝鍙涪鎸囬拡锟?free锛屾寜锟?UI 閲嶅缓锛堜笌闈㈡澘鍚岀瓥鐣ワ級锟?*/
    if (g_ddhChartBaseTick == 0) g_ddhChartBaseTick = GetTickCount();
    if (g_ddhChartUi != ui)
    {
        memset(g_ddhChartFrames, 0, sizeof(g_ddhChartFrames));
        memset(g_ddhChartFrameTex, 0, sizeof(g_ddhChartFrameTex));
        memset(g_ddhChartTexts, 0, sizeof(g_ddhChartTexts));
        memset(g_ddhChartIcons, 0, sizeof(g_ddhChartIcons));
        memset(g_ddhChartIconPath, 0, sizeof(g_ddhChartIconPath));
    }

    /* 灞忓箷鍐呴挸鍒讹細鍥捐〃鎬诲/楂樺浐瀹氾紝鍏堟妸宸︿笂瑙掓媺锟?[-0.99, 0.99]锟?
       鍚﹀垯 x 鍋忓彸鏃朵細鍍忎箣鍓嶉偅鏍疯绐楀彛鍙宠竟缂樿鎺変竴鍗婏拷?*/
    const float fullW = 0.34f, fullH = 0.32f;
    const float chartW = g_ddhChartCollapsed ? 0.1433f : fullW;
    const float chartH = g_ddhChartCollapsed ? 0.070f : fullH;
    float cx = g_ddhChartCollapsed ? (x + fullW - chartW) : x;
    float cy = -0.10f;   /* 缁熶竴鐢ㄦ紨绀洪珮搴?*/
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
            LogLine("鍥捐〃锛歷ictim 0x%08X 鏈€杩?5 绉掓病鏈夊彲鐢ㄤ激瀹充簨浠讹紙victim=%d锛?, victim, victim ? 1 : 0);
    }

    /* 闈㈡澘鍛戒腑鍖猴細鏁翠釜鍥捐〃鍖哄煙锛堢偣鏌卞瓙鍐嶇粏鍒嗭級 */
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

    /* 鑳屾櫙锛氬浘琛ㄦā寮忔病璧版枃鏈潰鏉块偅鏉¤矾锛岃繖閲屽崟鐙缓/鎽嗕竴娆￠潰鏉胯儗鏅抚锛堟殫锟?+ 杈规锛夛紝
       鍚﹀垯浜湴褰笂鏍规湰鐪嬩笉娓呮煴瀛愬拰鏂囧瓧锟?*/
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
        LogLine("鍥捐〃锛氬凡鏄剧ず锛坴ictim=0x%08X锛? 绉掓€讳激 %.0f锛屾渶澶ф《 %.0f锛屾潵婧?%d 涓紝ui=0x%08X锛宼tl=%u锛?,
                victim, (double)g_ddhChart.total[0] + g_ddhChart.total[1] + g_ddhChart.total[2] +
                g_ddhChart.total[3] + g_ddhChart.total[4],
                (double)g_ddhChart.maxTotal, g_ddhChart.srcCount, ui, ttl);
    return 1;
}

static void DdhChartToggleView(void)
{
    if (!g_ddhChartMode) { LogLine("鍥捐〃锛欳trl+Alt+E 浣嗘病鏈夊浘琛?); return; }
    g_ddhChartView = (g_ddhChartView == 0) ? 4 : 0;
    DdhChartRender();
    g_ddhPanelHideAt = (LONG)(GetTickCount() + 60000);
    LogLine("鍥捐〃锛欳trl+Alt+E -> %s", g_ddhChartView ? "涓嬮捇锛堢 -2 绉掞級" : "鎬昏");
}

static void DdhPanelClickAt(int x, int y)
{
    if (g_ddhChartMode) { DdhChartClick(x, y); return; }
    DdhDoTogglePanel();
}

/* Ctrl+Alt+C锛氳皟锟?鑷祴鈥斺€旂敤浜嬩欢鐜噷鈥滄渶杩戜竴娆″彈鍑荤殑鍗曚綅鈥濈洿鎺ュ紑涓€寮犳壙浼ゅ浘琛紝
   涓嶉渶瑕佽嫳闆勬浜°€佷篃涓嶉渶锟?C# 鍙備笌锛涗激瀹虫暟鎹収鏍锋潵锟?ddh 鑷繁鐨勪簨浠剁幆锟?*/
static void DdhChartDebugShow(void)
{
    if (!DdhInitUiFuncs()) { LogLine("鍥捐〃璋冭瘯锛歎I 鍑芥暟鏈氨缁?); return; }
    uint32_t ui = DdhGetGameUi();
    if (!ui) { LogLine("鍥捐〃璋冭瘯锛欸etGameUI 涓虹┖锛堣繕娌¤繘鍥撅紵锛?); return; }

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
        LogLine("鍥捐〃璋冭瘯锛氫簨浠剁幆閲岃繕娌℃湁浼ゅ浜嬩欢锛堝厛璁╀换鎰忓崟浣嶆尐涓€涓嬶級");
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

    /* 瀛樹竴浠斤細~ 闅愯棌鍚庡啀鎸夎繕鑳藉嚭鏉ワ紱鐐瑰嚮閲嶇疆 TTL 涔熺敤鍚屼竴锟?*/
    memcpy(&g_ddhLastPanel, &blk, sizeof(g_ddhLastPanel));
    g_ddhHaveLastPanel = 1;
    g_ddhPanelPinned = 0;

    DdhChartApply(ui, &blk, victim, blk.x, blk.y, blk.fontHeight, blk.fontName);
    if (InterlockedIncrement(&g_ddhChartLogCount) <= 40)
        LogLine("鍥捐〃璋冭瘯锛欳trl+Alt+C -> victim 0x%08X", victim);
}

/* Ctrl+Alt+D锛歮ock 鏁版嵁婕旂ず锛堣皟鏍峰紡鐢紱涓嶄緷璧栦激瀹充簨浠躲€佷笉渚濊禆姝讳骸銆佷笉渚濊禆 C#锛夛拷?*/
static void DdhChartDemoShow(void)
{
    if (!DdhInitUiFuncs()) { LogLine("鍥捐〃婕旂ず锛歎I 鍑芥暟鏈氨缁?); return; }
    uint32_t ui = DdhGetGameUi();
    if (!ui) { LogLine("鍥捐〃婕旂ず锛欸etGameUI 涓虹┖锛堣繕娌¤繘鍥撅紵锛?); return; }
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
    LogLine("鍥捐〃婕旂ず锛欳trl+Alt+D锛坢ock 鏁版嵁锛?0 绉?TTL锛?);
}

/* ---- 鑻遍泟鏌ヨ锟?6 妲斤紝锟?rawcode 缂撳瓨锟?---- */
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

    /* 澶村儚闇€锟?DzAPI 绫诲瀷鏁版嵁锛涘鏋滄湰娆¤繘绋嬭繕娌℃湁 ATTR 璇锋眰锛屽厛鐢ㄨ嫳闆勬煡璇㈤噷锟?
       鐪熷疄鍗曚綅鍙ユ焺鍋氫竴娆℃帰娴嬶紝鍚﹀垯 typeDataOk 涓€鐩存槸 0锛屽ご鍍忚矾寰勫彧鑳介潬 GetUnitData 鐚滐拷?*/
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
            local.res[i].pad = 0xFFFFFFFFu;   /* 骞昏薄鍒ゅ畾锟?=锟?0=锟?0xFFFFFFFF=鏈煡 */
            const uint32_t handle = HpObjToHandle(local.req[i].addr);
            if (handle)
            {
                uint32_t illusion = 0;
                if (DdhAttrCallU32(DDH_AN_IS_ILLUSION, handle, 0, &illusion))
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
        LogLine("闈㈡澘锛氳嫳闆勬煡璇?seq=%u 鍏?%d 椤癸紝棣栭」 rawcode=0x%08X isHero=%d isIllusion=%d锛堢紦瀛?%d锛?,
                seq, n, n > 0 ? local.req[0].rawcode : 0,
                n > 0 ? local.res[0].isHero : -9,
                n > 0 ? (int)local.res[0].pad : -9, g_ddhHeroCacheCount);
}

/* 鐑敭绾跨▼锛氬彧鎶曟秷鎭紝涓嶇寮曟搸锟?*/
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

    /* 闈㈡澘宸叉敹鍒颁絾 UI 杩樻病灏辩华锛堟湭杩涘浘/涓昏彍鍗曪級鏃讹紝锟?500ms 鍐嶅彨涓€娆℃父鎴忕嚎绋嬮噸璇曪紱
       杩欐牱涓嶇敤绛変笅涓€娆′激瀹充簨浠朵篃鑳藉湪杩涘浘鍚庤ˉ鏄剧ず锟?*/
    if (g_ddhPendingValid && GetTickCount() - (DWORD)g_ddhPendingPostTick >= 500)
    {
        if (PostMessageW(g_gameWnd, DDH_WM_PANEL, 0, 0))
            g_ddhPendingPostTick = (LONG)GetTickCount();
    }

    /* v16锛氶潰鏉挎樉绀烘湡闂存瘡 500ms 璁╂父鎴忕嚎绋嬭窇涓€锟?TTL 妫€鏌ワ紙C# 鍏抽棴/鍗′綇涔熻兘鑷姩闅愯棌锟?
       榧犳爣鐐瑰嚮鍒囨崲鍚庨噸缃殑 TTL 涔熼潬瀹冪敓鏁堬級锟?*/
    if (g_ddhPanelShown && GetTickCount() - (DWORD)g_ddhPanelTickPost >= 500)
    {
        if (PostMessageW(g_gameWnd, DDH_WM_PANEL_TICK, 0, 0))
            g_ddhPanelTickPost = (LONG)GetTickCount();
    }
}

/* ---- demo锛氫笉渚濊禆 C#锛岀涓€娆℃渶澶栧眰浼ゅ閫€鍑哄悗鏄剧ず涓€灞忕ず渚嬶紝鏂逛究鐪熸満楠岃瘉瀛椾綋/鍧愭爣 ---- */
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
        "\xE3\x80\x90\xE9\x98\xB5\xE4\xBA\xA1\xE6\x80\xBB\xE7\xBB\x93\xE3\x80\x91",              /* 銆愰樀浜℃€荤粨锟?*/
        "\xE5\x89\x91\xE5\x9C\xA3\xEF\xBC\x88Hmkg\xEF\xBC\x89",                                    /* 鍓戝湥锛圚mkg锟?*/
        "\xE7\x8E\xA9\xE5\xAE\xB6 1 \xC2\xB7 \xE7\xAC\xAC 2 \xE6\x9D\xA1\xE5\x91\xBD",            /* 鐜╁ 1 路 锟?2 鏉″懡 */
        "\xE6\x89\xBF\xE5\x8F\x97\xE4\xBC\xA4\xE5\xAE\xB3 3,200",                                  /* 鎵垮彈浼ゅ 3,200 */
        "\xE6\x9C\x80\xE6\x83\xA8 1 \xE7\xA7\x92 1,746",                                            /* 鏈€锟?1 锟?1,746 */
        "\xE5\xB1\xB1\xE4\xB8\x98\xE4\xB9\x8B\xE7\x8E\x8B(Hmkg) 45.9% 1,468",                      /* 灞变笜涔嬬帇(Hmkg) ... */
        "\xE8\xBF\x91\xE6\x88\x98 1,668 / \xE8\xBF\x9C\xE7\xA8\x8B 1,532",                          /* 杩戞垬 / 杩滅▼ */
        "\xE8\x87\xAA\xE6\xB5\x8B\xE9\x9D\xA2\xE6\x9D\xBF demo\xEF\xBC\x9A\xE5\xAD\x97\xE4\xBD\x93\xE4\xB8\x8E\xE5\x9D\x90\xE6\xA0\x87", /* 鑷祴闈㈡澘 demo锛氬瓧浣撲笌鍧愭爣 */
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
    g_ddhPanelIconCount = 0;   /* demo 涓嶅甫鍥炬爣锛岄伩鍏嶆部鐢ㄤ笂涓€鏉￠潰锟?*/
    memcpy(&g_ddhPendingPanel, &p, sizeof(g_ddhPendingPanel));   /* 璁╅紶鏍囩偣鍑讳篃鑳藉垏锟?demo */
    const int r = DdhPanelApply(&p);
    if (r < 0) DdhPanelFallback(&p);
    LogLine("闈㈡澘 demo 寮傚父 code=%08X锛堝凡鍚炴帀锛?,
            r > 0 ? "宸叉樉绀? : "涓嶅彲鐢紝宸茶蛋鍏滃簳", n);
}

/* ===========================================================================
   DDH_ENGINE_PROBE 鈥旓拷?鎺㈤拡锛氬湴鍥句笉锟?GetEventDamage 鏃讹紝鑳戒笉鑳借嚜宸辨嬁鍒扳€滃紩鎿庝激瀹斥€濓紵
   ---------------------------------------------------------------------------
   鑳屾櫙锟?026-11-01锛夛細GetEventDamage 鐨勫疄鐜板氨锟?`mov eax,[eax+0x30]; ret`
   锛坓ame.dll+0x1E21D0 锟?0x1E5D70 鍙栧綋鍓嶄簨浠跺锟?锟?+0x30 灏辨槸鈥滃紩鎿庝激瀹斥€濓級锟?
   鎵€浠ヨ繖涓€兼湰韬竴鐩村瓨鍦紝缂虹殑鍙槸**閲囨牱鏃舵満**锛氬紩鎿庡湪浼ゅ鍑芥暟鍐呴儴銆佹姢鐢茬畻锟?
   涔嬪悗鎵嶅啓 +0x30锛岃€屾垜浠殑閽╁瓙鍦ㄥ嚱鏁板叆鍙ｏ紱绛夊師鍑芥暟杩斿洖锛屼簨浠跺璞″凡缁忓嚭鏍堬拷?

   鏈帰閽堜笉鏀逛换浣曠粺璁★紝鍙湪姣忔浼ゅ浜嬩欢锟?*鍏ュ彛**锟?*鍑哄彛**鍚勮皟涓€锟?
   GetEventDamage 鐨勫師瀹炵幇锛堝湴鍧€鍦ㄦ墜銆乢_try 淇濇姢锛夛紝鎶婄粨鏋滃拰鈥滃湴鍥剧湡璇诲埌鐨勯鍊硷拷?
   锛坓_engineCap/g_engineFirstSet锛夊拰鈥滃師濮嬩激瀹斥€濓紙info+0x10锛夋憜鍦ㄥ悓涓€琛屾棩蹇楅噷锟?
     路 鍏ュ彛灏辩浉锟?    锟?鐜版湁閽╁瓙鐩存帴琛ワ紝涓嶇敤鍔犳柊閽╁瓙锛堟渶鐪佷簨锛夛紱
     路 鍑哄彛鎵嶇浉锟?    锟?涔熻兘鐢紱
     路 涓よ竟閮戒笉锟?    锟?鍙︽壘閲囨牱鐐癸紙閽┾€滃啓 +0x30鈥濈殑鎸囦护 / 閽╄Е鍙戝櫒娲惧彂锛夛拷?

   寮€鍏筹紙榛樿鍏筹紝涓ょ閮借锛夛細
     路 鐜鍙橀噺 DDH_ENGINE_PROBE=1锟?
     路 鎴栵拷?ddh.dll/鏃ュ織鍚岀洰褰曟斁涓€涓┖鏂囦欢 ddh_engineprobe.on
       锛堝惎鍔ㄥ櫒涓嶇户鎵跨幆澧冨彉閲忔椂鐢ㄨ繖涓級锟?
   鏃ュ織褰㈠锟?
     寮曟搸鎺㈤拡[12] depth=1 鍘熷=548.00 鍏ュ彛+0x30=438.40 鍑哄彛+0x30=438.40 鍦板浘棣栵拷?438.40 鍙栨=44
   =========================================================================== */
static int            g_engineProbe       = 0;    /* 0=鏈畾锟?1=寮€ -1=锟?*/
static volatile LONG  g_engineProbeLogged = 0;
static volatile LONG  g_engineProbeNoCall = 0;
static uint32_t       g_probeEntryOk[DDH_MAXDEPTH];
static float          g_probeEntryVal[DDH_MAXDEPTH];
static uint32_t       g_probeInfo[DDH_MAXDEPTH];      /* 鏈眰浼ゅ缁撴瀯锟?info 鎸囬拡锛堝嚭鍙ｆ椂鐢ㄦ潵 dump 瀛楁锟?*/

/* 鏂囦欢寮€鍏筹細鏃ュ織鐩綍涓嬬殑 ddh_engineprobe.on锛堝悓 DDH_UNITDUMP 鐨勫璺級 */
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
        LogLine("寮曟搸鎺㈤拡锛氬凡寮€鍚紙%s锛夆€斺€旀瘡娆′激瀹冲彧澶氳涓ゆ鍐呭瓨锛屼笉鏀圭粺璁★紱"
                "鏃ュ織褰㈠鈥滃紩鎿庢帰閽圼n] depth=.. 鍘熷=.. 鍏ュ彛+0x30=.. 鍑哄彛+0x30=.. 鍦板浘棣栧€?.. 鍙栨=..鈥?,
                (n > 0 && n < (DWORD)sizeof(buf)) ? "DDH_ENGINE_PROBE" : "ddh_engineprobe.on");
    return on;
}

/* 璋冧竴锟?GetEventDamage 鐨勫師瀹炵幇锟? 璇诲綋鍓嶄簨浠跺锟?+0x30锛夈€傝涓嶅埌/涓嶅湪浜嬩欢锟?ok=0锟?*/
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

/* 鍙栤€滃綋锟?JASS 浜嬩欢瀵硅薄鈥濇寚閽堬細锟?GetEventDamage 鐨勫疄鐜伴噷鎶婅闂櫒鍦板潃鎶犲嚭锟?
   锟?x1E21D0 锟?+0x0C 澶勬槸 `E8 rel32` 锟?0x1E5D70锛夛紝姣斿啓锟?RVA 绋充竴鐐癸拷?
   涓嶅湪浜嬩欢锟?鍙栦笉鍒板氨杩斿洖 0锟?*/
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

    /* 鍙湪鈥滆繕浼氬啓鏃ュ織鈥濈殑锟?220 鏉′簨浠堕噷閲囨牱锛氭帰閽堟渶鎬曠殑鏄姣忎竴鍙戜激瀹抽兘鍘昏皟
       寮曟搸璁块棶鍣紙涓€灞€鍑犱竾娆★級锛岄偅鏍峰嚭浜嬩篃璇翠笉娓呮槸璋佸紕鐨勶拷?*/
    if (InterlockedCompareExchange(&g_engineProbeLogged, 0, 0) < 220)
        DdhEngineProbeSample(&g_probeEntryOk[level], &g_probeEntryVal[level]);
}

static void DdhEngineProbeExit(uint32_t level, const DdhEvent* e, uint32_t seq)
{
    if (level >= DDH_MAXDEPTH) return;

    /* 鍏堢畻鈥滆繖鏉¤涓嶈璁扳€濓紝涓嶈灏辩洿鎺ヨ蛋 鈥旓拷?閲囨牱鏈韩灏辨槸瑕侀澶栬皟寮曟搸鍑芥暟锛岃秺灏戣秺锟?*/
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

    /* info 缁撴瀯浣撳嚭鍙ｅ揩鐓э細鐪嬧€滄姢鐢插悗鐨勫紩鎿庝激瀹斥€濇湁娌℃湁琚紩鎿庡啓鍥炴煇涓瓧锟?
       锛堟湁 锟?涓嶇敤鍐嶅姞 hook锛涙病锟?锟?鍙兘鍦ㄤ簨浠舵淳鍙戞湡闂村彟寮€閲囨牱鐐癸級 */
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
        if (!hit[0]) strcpy_s(hit, sizeof(hit), g_engineFirstSet[level] ? "鑶? : "?");
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
    else strcpy_s(objTxt, sizeof(objTxt), "鏃犲璞?);

    LogLine("寮曟搸鎺㈤拡[%ld] depth=%u 鍘熷=%.2f 鍏ュ彛+0x30=%s 鍑哄彛+0x30=%s 瀵硅薄+0x30=%s 鍦板浘棣栧€?%s 鍙栨=%u 鍛戒腑=%s 缁撴瀯=%s",
            (long)total, level + 1, (double)raw, ent, ext, objTxt, mapFirst, (unsigned)calls, hit, dump);
}
/* ---- 鏇挎崲鍑芥暟锛氫笌 UDamageWatcherHook.cpp 锟?OurDamageFunc 鍚屾 ----
   瀹夎鏃舵妸 0x67DC40 锟?6 瀛楄妭鏀规垚 jmp 鍒拌繖閲岋紙__fastcall锛歟cx=_this, edx=_edx,
   鏍堜笂 4 涓弬锟?a2/info/is_physical/source_unit锛夈€傚嚱鏁伴噷锟?
     锟?娣卞害 +1銆佹湰灞傜姸鎬佹竻闆讹紱锟?鎳掓寕 GetEventDamage/SetEventDamage锟?
     锟?璇诲墠琛€锛涒懀 RecordDamage 鍐欎簨浠讹紙鍘熷浼ゅ info+0x10 鍘熸牱淇濈暀锛夛紱
     锟?鑷繁 call 鍘熷嚱鏁帮紙璺虫澘 锟?鍘熷嚱鏁颁綋 锟?ret 0x10 鍥炲埌杩欓噷锛夛紝杩斿洖鍊煎師鏍峰甫鍥烇紱
     锟?璇诲悗琛€銆佺畻 gross/own銆佽ˉ hpAfter/actual/hpValid銆佺粰鍚岀洰鏍囩埗甯х疮璁★紱
     锟?鍐欏紩鎿庝激锟?璁惧畾鍊笺€佽瘖鏂棩蹇楋紱锟?璁板綍鍗曚綅鐨勭粺锟?姝讳骸鎺掗槦锛坴9锛夛紱
     锟?娣卞害 -1锛屽洖鍒版渶澶栧眰鏃跺鐞嗙儹閿緟鍔炲拰寰呭彂缁撶畻锛坴9锛夛紱锟?return retval锟?
   鏀跺熬锟?ret 0x10锛坈allee 锟?4 涓爤鍙傦級锛屼笌寮曟搸鍘熷嚱鏁颁竴鑷达紝锟?build 鍚庣殑鍙嶆眹缂栨牎楠岋拷?*/
static uint32_t __fastcall DdhDamageFunc(uint32_t _this, uint32_t _edx, uint32_t a2,
                                         void* info, uint32_t is_physical, uint32_t source_unit)
{
    /* v9锛氱涓€娆¤繘浼ゅ鍑芥暟鏃舵妸鐑敭绾跨▼鎷夎捣鏉ワ紙姝ゆ椂娓告垙宸插氨缁紝涔熶笉鍦ㄥ姞杞藉櫒閿侀噷锟?*/
    DdhEnsureHotkeyThread();

    /* 娣卞害 +1锛涜秴杩囦笂闄愬氨涓嶅姞锛堝惁鍒欐敹灏剧殑娣卞害 -1 浼氬涓嶄笂锛屾繁搴︽案涔呮硠婕忥級锟?
       杩欎竴灞備粛鐒惰璺戝師鍑芥暟銆佹妸杩斿洖鍊煎師鏍峰甫鍥炲幓 鈥旓拷?鍙槸涓嶅啀鍗曠嫭锟?after锟?*/
    LONG d = InterlockedIncrement(&g_depth);
    if (d > DDH_MAXDEPTH)
    {
        InterlockedDecrement(&g_depth);
        if (InterlockedIncrement(&g_depthOverflowLogged) == 1)
            LogLine("宓屽婧㈠嚭锛氭繁搴﹁秴杩?%u 灞傦紝宸查€€鍖栦负涓嶈璐︼紙鏈繘绋嬪彧鎻愮ず杩欎竴娆★級",
                    (uint32_t)DDH_MAXDEPTH);
        RecordDamage(_this, (uint32_t)(uintptr_t)info, is_physical, source_unit,
                     (uint32_t)DDH_MAXDEPTH + 1, 0, 0.0f, NULL);
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

    /* 闃叉紡锛歋EH 灞曞紑/寮傚父浼氳鏌愪竴灞傛案杩滀笉杩斿洖锛屾繁搴︿細涓€璺定涓婂幓锟?
       鐖跺眰鍏ュ彛璺濅粖瓒呰繃 2 锟?锟?璁や负涔嬪墠閭ｅ嚑灞傚凡缁忎涪浜嗭紝閲嶆柊锟?0 绠楋拷?*/
    if (level > 0 && (now - g_levelTick[level - 1]) > 2000)
    {
        InterlockedExchange(&g_depth, 1);
        level = 0;
    }

    /* 姣忓眰鐘舵€佹竻闆讹紙寮曟搸浼ゅ/璁惧畾锟?瀛愬眰绱/鍓嶈绛夛級 */
    g_engineCap[level] = 0;
    g_engineFirstSet[level] = 0;
    g_engineLast[level] = 0;
    g_engineCalls[level] = 0;
    g_setCap[level] = 0;
    g_setSet[level] = 0;
    g_setCalls[level] = 0;

    if (NativeDamageHooksOn())        /* v20锛氶粯璁や笉鎸傦紝鍑哄彛涓夎灏卞 */
    {
        TryHookGetEventDamage();      /* 鍙湪璇婃柇妯″紡涓嬫嬁"鍦板浘璇讳簡鍑犳" */
        TryHookSetEventDamage();      /* 鍙湪璇婃柇妯″紡涓嬫嬁"鍦板浘鏀逛簡鍑犳" */
    }
    /* 鎺㈤拡锛堥粯璁ゅ叧锛夛細鍏ュ彛鍏堥噰涓€娆♀€滃紩鎿庝激瀹斥€濓紝鍑哄彛鍐嶉噰涓€娆★紝鍜屽湴鍥鹃鍊煎锟?*/
    if (DdhEngineProbeOn()) DdhEngineProbeEntry(level, (uint32_t)(uintptr_t)info);

    float hp = 0.0f;
    const bool ok = ReadUnitHp(_this, &hp);

    uint32_t seq = 0;
    g_slot[level]      = RecordDamage(_this, (uint32_t)(uintptr_t)info, is_physical, source_unit,
                                      level + 1, ok ? 1u : 0u, hp, &seq);
    g_seq[level]       = seq;
    /* v13锛氬帇锟?鈥旓拷?鏈抚锟?victim / 鍓嶈 / 鍚岀洰鏍囧瓙甯х疮璁¤捣鐐归兘璁板湪甯ч噷 */
    DdhFrame* frame    = DdhFramePush(level, _this, hp, ok ? 1u : 0u);
    g_levelTick[level] = now;
    QueryPerformanceCounter(&g_qpcStart[level]);

    /* 鑷繁 call 鍘熷嚱鏁帮紙璺虫澘 锟?鍘熷嚱鏁颁綋 锟?ret 0x10 鍥炲埌杩欓噷锛夈€傝繑鍥炲€煎師鏍峰甫鍥烇拷?*/
    uint32_t retval = 0;
    if (g_original_damage)
    {
        __try
        {
            retval = ((fn_damage_t)(uintptr_t)g_original_damage)(_this, _edx, a2, info, is_physical, source_unit);
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("E 鍘熶激瀹冲嚱鏁版姏鍑哄紓甯革紝宸插悶鎺夛紙code=%08X锛?, (uint32_t)GetExceptionCode());
            retval = 0;
        }
    }

    /* ---- v20锛氬嚭鍙ｄ笁璇伙紙鍏ㄩ儴鏉ヨ嚜杩欎竴涓挬瀛愶級---------------------------------
       锟?寮曟搸浼ゅ = 鍑哄彛 info+0x10銆傛姢锟?0x6F64FBF0 / 鏀婚槻绫诲瀷 0x6F64D7F0 /
          鏀诲嚮绫诲瀷锟?0x6FBEC34C 鐨勭粨鏋滈兘锟?0x6F6971C0 鍘熷湴鍐欏洖 info+0x10
          锛坄mov [ebx+0x10],eax`锛夛紝鎵€浠ュ嚭鍙ｅ€煎氨鏄紩鎿庣畻瀹岀殑鏁般€備激瀹充簨锟?
          锛坕d 0x80234锛夊湪涔樼畻**涔嬪悗**鎵嶅彂锛屽湴锟?SetEventDamage 鍙敼 *out /
          game+0xBB81D4锛屼笉鍥炲啓 info+0x10 鈥旓拷?杩欏氨锟?寮曟搸锟?鍦板浘锟?鑳藉垎寮€鐨勫師鍥狅拷?
       锟?鏈€缁堜激锟?= 鍑哄彛 *a2銆俛2 鏄皟鐢ㄦ柟锟?out 鎸囬拡锛堝師鍑芥暟 [ebp+8]锛夛紝涔熷氨锟?
          WFE 璇绘潵鐢讳激瀹虫暟瀛楃殑閭ｅ潡鍐呭瓨锟? 涓嚭鍙ｉ噷 4 涓妱 game+0xBB81D4锛屼富璺緞
          鎸変富绠￠亾閲嶇畻锛屼袱鑰呴兘宸插惈鍦板浘鏀瑰啓锟?
       锟?鍑€鎺夎 = 鍓嶅悗琛€宸紙涓嬮潰 DdhFramePop 绠楋紝鍙ｅ緞涓嶅彉锛夛拷?*/
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
        const uint32_t op = a2;                       /* 璋冪敤锟?out锛坒loat*锟?*/
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

    /* 璇诲悗琛€锛氬氨锟?call 杩斿洖鍚庣殑绗竴浠朵簨锛堝拰鎻掍欢鍚屾鏃舵満锟?*/
    float hpAfter = 0.0f;
    const bool hpAfterOk = ReadUnitHp(_this, &hpAfter);

    DdhEvent* e = NULL;
    if (g_shm) e = &g_shm->ev[g_slot[level] % DDH_MAX_EVENTS];

    /* 寮曟搸浼ゅ锛氶粯璁ょ敱涓嬮潰锟?鍑哄彛 info+0x10"缁欙紱寮€锟?DDH_NATIVE_DAMAGE_HOOKS
       骞朵笖鍦板浘鐪熻锟?GetEventDamage 鏃讹紝鐢ㄩ挬瀛愭姄鍒扮殑棣栧€硷紙涓よ€呯浉绛夛紝閽╁瓙閭ｄ唤杩樿兘
       椤哄甫锟?鍙栨"锛夈€傛病鎶撳埌锟?engineValid=0 锟?鐣岄潰鏄剧ず ? */
    if (e && e->seq == g_seq[level])
    {
        float eng = 0.0f;
        uint32_t engOk = g_engineFirstSet[level] ? 1u : 0u;   /* 棣栧€煎彲鑳芥槸鍚堟硶锟?0.0锛屾墍浠ョ湅鏍囧織锟?*/
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

    /* v20锛氬紩鎿庝激锟?= 鍑哄彛 info+0x10锛堣涓婇潰"鍑哄彛涓夎"鈶狅級锟?
       鑰佸疄鐜拌姹備笁閬撻椄闂紙娌¤锟?/ 娌℃敼锟?/ 鏉ユ簮鍖归厤锛夋墠鑲敤鍥炶鍊硷紝鏄洜涓哄綋锟?
       鍙湁锟?鍦板浘瀹屽叏涓嶇浼ゅ浜嬩欢"鏃舵墠鏁㈡柇瀹氬嚭鍙ｅ€肩瓑锟?GetEventDamage銆傜幇锟?
       浠庤繖閲岃兘鐪嬫竻锛氫簨浠舵敼鍐欐牴鏈笉鍥炲啓 info+0x10锛屾墍浠ュ嚭鍙ｏ拷?*姘歌繙**鏄紩鎿庡€硷紝
       鍦板浘鏀规病鏀归兘涓嶅奖鍝嶃€傜湡鏈轰袱渚嬩粛鐒跺惢鍚堬細
         鍘熷 5.00  锟?鍑哄彛 info+0x10 = 4.46锛堝湴鍥捐锟?4.46锛涙姢锟?2 = 10.71% 鍑忎激锟?
         鍘熷 16.00 锟?鍑哄彛 info+0x10 = 14.29锛堝湴鍥捐锟?14.29锛屽悓涓€鎶ょ敳锟?
       鍙湁鎵撳紑锟?DDH_NATIVE_DAMAGE_HOOKS 涓斿湴鍥剧湡璇昏繃 GetEventDamage 鏃讹紝
       鎵嶄紭鍏堢敤閽╁瓙鎶撳埌鐨勯鍊硷紙涓よ€呮湰灏辩浉绛夛紝閽╁瓙閭ｄ唤杩樿兘椤哄甫锟?鍙栨"锛夛拷?*/
    if (e && e->seq == g_seq[level] && !g_engineFirstSet[level] && exitEngineOk && e->source)
    {
        if (exitEngine > 0.005f && exitEngine < 1.0e9f)
        {
            e->engineDamage = exitEngine;
            e->engineValid  = 1;
            /* engineCalls 鐨勬Ы v20 宸叉敼锟?finalFlags锛岃繖閲屼笉鍐嶅啓 */
        }
    }

    /* 鍓嶈 <= 0 璇存槑杩欎竴鍒荤洰鏍囧凡缁忔锟?璇荤殑鏄┖锟?鈥旓拷?杩欑锟?锟?鈥濇病鏈夋剰涔夛紝鎸夆€滄病娴嬪埌鈥濆鐞嗭紝
       鐣岄潰鏄剧ず ?锛屼笉瑕佹嬁 0 鍐掑厖鈥滃疄闄呬激瀹斥€濓拷?
       v13锛歰wn 浜ょ粰甯ф爤绠楋紙鏁存 - 鍚岀洰鏍囧瓙甯у悎璁★級锛岄€€甯ф椂椤烘墜锟?gross 鎶ョ粰鍚岀洰鏍囩埗甯э拷?*/
    float gross = 0.0f, own = 0.0f;
    const float fallback = (e && e->engineValid && e->engineDamage > 0.0f)
                           ? (float)e->engineDamage : 0.0f;
    const bool measured = DdhFramePop(frame, (e && e->seq == g_seq[level]) ? 1u : 0u,
                                      hpAfter, hpAfterOk ? 1u : 0u, fallback, &gross, &own);
    /* 鎺㈤拡锛堥粯璁ゅ叧锛夛細鍑哄彛鍐嶉噰涓€娆★紝鏃ュ織閲屽拰鍏ュ彛锟?/ 鍦板浘棣栧€煎苟鎺掑锟?*/
    if (g_engineProbe > 0) DdhEngineProbeExit(level, e, g_seq[level]);
    if (e)
    {
        if (measured)
        {
            /* 鍓嶈/鍚庤閮藉湪锛宎ctual = 鏈抚鑷繁鐨勫噣鎺夎锛堝凡缁忔墸鎺夊悓鐩爣瀛愬抚锟?*/
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

    /* ---- v20锛氭渶缁堜激锟?= 鍑哄彛 *out锟?鍑哄彛涓夎"鈶★級---------------------------
       杩欏氨锟?WFE 鐢讳激瀹虫暟瀛楁椂璇荤殑閭ｅ潡鍐呭瓨锛屽惈鍦板浘 SetEventDamage 鐨勬敼鍐欙拷?
       鍙湪**纭疄鎺変簡琛€**锛堟湰锟?own > 0.005锛夋椂鎵嶈锟?
         鏃犳晫 [unit+0x5C]&0x100銆佸厤锟?[unit+0x158]/[+0x15C]>0銆乫lags&4 杩欎簺鏃╅€€
         鍒嗘敮鏍规湰涓嶈绠楋紝鐩存帴鎶婁笂涓€璺虫畫鐣欏湪 game+0xBB81D4 鐨勫€兼妱锟?*out锛涢偅绉嶆儏锟?
         锟?own = 0锛岃繖閲屼竴寰嬩笉璁わ紝閬垮厤鎶婃棫鏁板瓧褰撴垚杩欐鐨勫湴鍥句激瀹筹拷?
       finalFlags bit0 = 鍙俊锛宐it1 = 涓庡紩鎿庡€间笉鍚岋紙= 鍦板浘鏀硅繃浼ゅ锛夛拷?*/
    if (e && e->seq == g_seq[level])
    {
        const bool finalOk = finalReadOk && e->engineValid && own > 0.005f;
        /* 婧㈠嚭閽冲埗锛氬紩鎿庡湪钀藉湴鍓嶄細鎶婁激瀹抽挸锟?鐩爣鍓╀綑琛€锟?
           锟?x6F67F340 锟?`min(*out, vtbl[0x12c]())`锛岄偅涓€璺鐨勫氨鏄綋鍓嶇敓鍛斤級锟?
           鎵€浠ュ嚮鏉€閭ｄ竴鍒€ *out = 鍓嶈锛岃€屼笉鏄湴鍥炬敼鍐欏€笺€傜湡鏈哄疄娴嬶細
             寮曟搸 387.12 / 鍓嶈 219.52 锟?鍦板浘 219.52銆佸噣鎺夎 219.52
             寮曟搸 170.29 / 鍓嶈  79.82 锟?鍦板浘  79.82銆佸噣鎺夎  79.82
           杩欑琛屽鏋滄寜"鏈€锟?锟?寮曟搸"鍘荤畻鍊嶆暟浼氬緱锟?0.57脳/0.47脳锛岀湅鐫€鍍忓湴鍥惧噺浼わ紝
           鍏跺疄鏄孩鍑恒€傛墍浠ュ崟鐙疆 bit2锛屽苟涓旇繖绉嶆儏鍐典笅涓嶇疆 bit1锛堜笉绠楀湴鍥炬敼杩囷級锟?*/
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

    /* ---- 璇婃柇锛氬湴鍥句激锟?锟?寮曟搸浼ゅ鏃惰涓€琛岋紙甯︿激瀹冲嚱鏁拌€楁椂锟?--- */
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
            LogLine("HP宸?depth=%u 鍘熷=%.2f 寮曟搸=%.2f 鏈€缁?%.2f 鏀硅繃=%u 鍙栨=%u 璁惧畾=%.2f 璁炬=%u 鍓嶈=%.3f 鍚庤=%.3f 鏁存=%.2f 鏈眰=%.2f 瀛愬眰=%.2f 鑰楁椂=%.0fus",
                    e->depth, e->amount, e->engineDamage, e->finalDamage,
                    (uint32_t)((e->finalFlags >> 1) & 1u), (uint32_t)g_engineCalls[level],
                    setVal, (uint32_t)g_setCalls[level],
                    frame->hpBefore, hpAfter, gross, own, frame->childSumSameVictim, us);
        }
    }

    /* v9锛氬鏋滆繖涓€灞傜殑浜嬩欢杩樻槸鎴戜滑鍒氭墠鍐欑殑閭ｆ潯锛堟病琚幆瑕嗙洊锛夛紝鎷垮畠鏇存柊璁板綍鍗曚綅锟?
       缁熻锛涚洰鏍囧悗琛€ <= 0 鏃舵妸姝讳骸缁撶畻鎺掑埌鈥滄湰灞傞€€鍑哄悗鈥濆啀鍙戯拷?*/
    if (e && e->seq == g_seq[level]) DdhTrackEvent(e);

    MemoryBarrier();

    /* 娣卞害 -1锛涘洖锟?0 璇存槑鏈€澶栧眰浼ゅ鍑芥暟瑕佽繑鍥炰簡 鈥旓拷?杩欐椂鎵嶅鐞嗙儹閿緟鍔炲拰寰呭彂缁撶畻锟?
       閬垮厤鍦ㄥ紩鎿庢墸琛€杩囩▼涓皟娓告垙鑷繁鐨勮亰锟?鏄剧ず鍑芥暟锟?*/
    const LONG left = InterlockedDecrement(&g_depth);
    if (left == 0) DdhProcessDeferred();

    return retval;
}

/* 璺虫澘 = 琚惉璧扮殑锟?6 瀛楄妭 + E9 璺冲洖鍘熷嚱鏁颁綋锟?x67DC40+6锛夛拷?
   DdhDamageFunc 锟?call 杩欎釜璺虫澘锛屽師鍑芥暟缁撳熬 ret 0x10 鏃跺洖鍒版垜浠拷?*/

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
   鍦ㄥ凡缁忓姞杞界殑 game.dll 閲屾壘浼ゅ鍑芥暟銆傚啓锟?RVA 涓嶅鐢細骞冲彴鑱旀満/瑙傛垬鍔犺浇鐨勬槸
   13,467,648 瀛楄妭鐨勯暅鍍忥紙纾佺洏閭ｄ唤锟?13,187,048锛夛紝闀滃儚琚敼杩囷紝RVA 鍙兘鏁翠綋鍋忕Щ锟?
   鐗瑰緛锛堟潵鑷粨锟?`WFE浼ゅ鏈哄埗鍒嗘瀽.md`锟?.27.0.52240 涓婇獙璇佽繃锛夛細
     寮€锟?55 8B EC 83 EC 2C 56 57 8B F9锛屼笖鍑芥暟锟?~0x300 鍐呭悓鏃跺嚭锟?
     绔嬪嵆锟?0x04000000 锟?0x00400000锛堜激瀹崇被鍨嬫帺鐮佸垎鏀殑榄旀硶鍊硷級锟?
--------------------------------------------------------------------------- */
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
    /* 1) 鍏堢湅宸茬煡 RVA 瀵逛笉锟?*/
    uint8_t* known = base + HOOK_RVA;
    if (MatchPrologue(known)) { LogLine("浼ゅ鍑芥暟灏卞湪宸茬煡 RVA 0x%X", HOOK_RVA); return known; }
    LogLine("宸茬煡 RVA 0x%X 寮€澶翠笉鏄鏈熷瓧鑺傦紙%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X锛夛紝鏀圭壒寰佹壂鎻?,
            HOOK_RVA, known[0], known[1], known[2], known[3], known[4], known[5], known[6], known[7], known[8], known[9]);

    /* 2) 鐗瑰緛鎵弿 */
    const size_t window = 0x300;
    size_t limit = imageSize > 10 + window ? imageSize - 10 - window : 0;
    for (size_t i = 0; i < limit; i++)
    {
        if (!MatchPrologue(base + i)) continue;
        const uint8_t* p = base + i;
        if (!HasImm(p, window, 0x04000000u)) continue;
        if (!HasImm(p, window, 0x00400000u)) continue;
        LogLine("鐗瑰緛鎵弿鍛戒腑锛歊VA 0x%X", (unsigned)i);
        return base + i;
    }
    LogLine("鐗瑰緛鎵弿涔熸病鎵惧埌浼ゅ鍑芥暟 鈥斺€?杩欎釜鏋勫缓鍜屽凡鐭ョ増鏈樊寮傚お澶?);
    return NULL;
}

static bool InstallHook()
{
    HMODULE game = NULL;
    for (int i = 0; i < 60 && !game; i++) { game = GetModuleHandleA("game.dll"); if (!game) Sleep(100); }
    if (!game) { LogLine("鎵句笉鍒?game.dll锛堟父鎴忚繕娌¤捣鏉ワ紵锛?); return false; }

    size_t imageSize = 0;
    {
        IMAGE_DOS_HEADER* dos = (IMAGE_DOS_HEADER*)game;
        IMAGE_NT_HEADERS32* nt = (IMAGE_NT_HEADERS32*)((uint8_t*)game + dos->e_lfanew);
        if (dos->e_magic == IMAGE_DOS_SIGNATURE && nt->Signature == IMAGE_NT_SIGNATURE)
            imageSize = nt->OptionalHeader.SizeOfImage;
    }
    g_modBase = (uint32_t)(uintptr_t)game;
    g_imageSize = (uint32_t)imageSize;   /* 鍗忚 v13锛氳锟?RVA 瓒婄晫鏍￠獙鐢紙PE SizeOfImage锟?*/
    LogLine("game.dll base=0x%08X 鏄犲儚澶у皬=0x%X", (unsigned)(uintptr_t)game, (unsigned)imageSize);

    g_hookAt = FindDamageFunc((uint8_t*)game, imageSize);
    if (!g_hookAt) return false;
    g_foundRva = (uint32_t)((uintptr_t)g_hookAt - (uintptr_t)game);
    LogLine("鎸傞挬鐩爣锛歊VA 0x%X锛堝湴鍧€ 0x%08X锛?, g_foundRva, (unsigned)(uintptr_t)g_hookAt);

    /* 鏂版寕杞芥柟寮忥細鍏ュ彛鐩存帴 jmp 锟?DdhDamageFunc锛坃_fastcall锛屾敹锟?ret 0x10锛夛紝
       鍑芥暟閲屽厛璁板墠琛€ 锟?call 鍘熷嚱鏁帮紙璺虫澘锛夆啋 杩斿洖鍚庣珛鍒昏鍚庤 锟?绠楁湰灞傛帀琛€锟?
       涓嶅啀鏀规爤涓婅繑鍥炲湴鍧€锛屼篃灏变笉鍐嶉渶瑕佲€滃嚱鏁颁綋閲屾湁娌℃湁 ret 0x10鈥濊繖閬撻棬绂侊拷?*/
    LogLine("瀹為檯浼ゅ閲囬泦锛氬紑锛坈all 鍘熷嚱鏁板悗璇昏锛屼笌鎻掍欢鍚屾锛?);

    g_tramp = (uint8_t*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!g_tramp) { LogLine("VirtualAlloc(tramp) 澶辫触 %lu", GetLastError()); return false; }

    memcpy(g_saved, g_hookAt, 8);
    if (!MakeTrampoline(g_hookAt, g_tramp))
    {
        LogLine("鍑芥暟寮€澶翠笉鏄鏈熺殑 55 8B EC 83 EC 2C锛堝疄闄?%02X %02X %02X %02X %02X %02X锛夆€斺€?涓嶆寕閽?,
                g_saved[0], g_saved[1], g_saved[2], g_saved[3], g_saved[4], g_saved[5]);
        return false;
    }

    DWORD old = 0;
    if (!VirtualProtect(g_hookAt, 16, PAGE_EXECUTE_READWRITE, &old)) { LogLine("VirtualProtect 澶辫触 %lu", GetLastError()); return false; }

    /* 鍏堟妸璺虫澘鍦板潃濉繘 g_original_damage锛欴dhDamageFunc 锟?call 锟?= 璺戝師鍑芥暟浣擄拷?
       锛堣烦锟?= 鎼蛋锟?6 瀛楄妭 + E9 璺冲洖 0x67DC40+6锛屽師鍑芥暟缁撳熬 ret 0x10 鍥炲埌鎴戜滑锟?*/
    g_original_damage = (LONG)(uintptr_t)g_tramp;

    /* E9 rel32 + NOP 锟?DdhDamageFunc锛堝叡 6 瀛楄妭锛屾濂界洊锟?3 鏉″畬鏁存寚浠わ級 */
    g_hookAt[0] = 0xE9;
    int32_t rel = (int32_t)((uint8_t*)&DdhDamageFunc - (g_hookAt + 5));
    memcpy(g_hookAt + 1, &rel, 4);
    g_hookAt[5] = 0x90;
    FlushInstructionCache(GetCurrentProcess(), g_hookAt, 8);
    VirtualProtect(g_hookAt, 16, old, &old);
    g_hooked = true;
    LogLine("鎸傞挬鎴愬姛锛?x%08X 鍓?6 瀛楄妭宸叉敼鎴?jmp DdhDamageFunc锛坮el=0x%X锛岃烦鏉?0x%08X锛?,
            (unsigned)(uintptr_t)g_hookAt, rel, (unsigned)(uintptr_t)g_tramp);
    return true;
}

/* 鍒犻櫎瓒呰繃 days 澶╃殑 ddh 鏃ュ織锛堢粺涓€鏃ュ織鐩綍鐢級 */
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
    /* 鏃ュ織鏀惧摢锛氣憼 锟?ddh.dll 鍚岀洰褰曪紙鏈€甯歌銆佽偗瀹氬彲鍐欍€佷篃鏈€濂芥壘锟?
                 锟?C:\ddh-<pid>.log锛堣€佺増鏈綅缃紝鍏煎鏃㈡湁璇存槑/涔犳儻锟?
                 锟?%TEMP%\ddh-<pid>.log锛堝厹搴曪級
       閫夌涓€锟?*鐪熺殑鑳藉啓**鐨勩€傛敞鎰忓埆鍙啓锟?C:\锛氭櫘閫氭潈闄愮殑娓告垙鍐欎笉浜嗘牴鐩綍锟?
       浠ュ墠灏辨槸闈欓粯澶辫触 锟?鏃ュ織鍑┖娑堝け锟?*/
    {
        char dllPath[MAX_PATH] = { 0 };
        if (g_self && GetModuleFileNameA(g_self, dllPath, MAX_PATH) > 0)
        {
            char* slash = strrchr(dllPath, '\\');
            if (slash) { slash[1] = 0; strcat_s(dllPath, "ddh_log.on"); g_logEnabled = (GetFileAttributesA(dllPath) != INVALID_FILE_ATTRIBUTES) ? 1 : 0; }
        }
    }

    bool logOk = false;
    if (!g_logEnabled) { g_logPath[0] = 0; logOk = true; }   /* 鍙戝竷鍖咃細涓嶅缓鏃ュ織鏂囦欢 */
    /* 缁熶竴鏃ュ織鐩綍锛?LOCALAPPDATA%\War3DeathSettlement\logs锛圕# 鍓嶇鍚岀洰褰曪級 */
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
    if (!g_map) { LogLine("CreateFileMapping 澶辫触 %lu", GetLastError()); return; }
    g_shm = (DdhShared*)MapViewOfFile(g_map, FILE_MAP_ALL_ACCESS, 0, 0, DDH_SHM_SIZE);
    if (!g_shm) { LogLine("MapViewOfFile 澶辫触 %lu", GetLastError()); return; }

    memset(g_shm, 0, sizeof(DdhShared));
    g_shm->hdr.magic = DDH_MAGIC;
    g_shm->hdr.version = DDH_VERSION;
    g_shm->hdr.pid = pid;
    g_shm->hdr.capacity = DDH_MAX_EVENTS;
    g_shm->hdr.hookRva = HOOK_RVA;
    g_shm->hdr.selfTest = 1;
    g_shm->hdr.reserved[0] = 0;        /* v3锛氬厛鍗犱綅锛孖nstallHook 纭鑳藉姏鍚庡啀锟?1 */
    g_shm->hdr.reserved[2] = DDH_CHART_MAGIC;   /* 鑳藉姏鏍囪锛氭敮鎸佹壙浼ゅ浘琛紙flags bit4锟?*/
    LogLine("鍏变韩鍐呭瓨 %s 灏辩华锛?u 瀛楄妭锛?, g_mapName, DDH_SHM_SIZE);
    LogLine("ddh 鐗堟湰 v%d锛氫簨浠惰褰?%u 瀛楄妭/鏉★紝鍚嶅瓧瀛楁鍚?%u 瀛楄妭锛圲TF-8 瀹夊叏鎴柇锛屾渶澶?63 瀛楄妭+NUL锛?,
            DDH_VERSION, (unsigned)sizeof(DdhEvent), (unsigned)sizeof(((DdhEvent*)0)->victimName));
    LogLine("ddh 鍗忚 v14/v15 鍗曚綅灞炴€у潡锛堝崟鍏?208 瀛楄妭 = 192 + 鍔?鏁?鏅?闄勫姞鍊硷紱璇锋眰妲?96 涓?v12/v13 鐩稿悓锛夛細鍧楀亸绉?%u锛? %u 澶?+ %u 浜嬩欢锛夛紝璇锋眰妲?%u 涓紝鍝嶅簲妲藉亸绉?%u锛屽崟鍏?%u 瀛楄妭锛屽潡闀?%u锛屽叡浜唴瀛樼粨鏋勬€婚暱 %u锛泇14 瑙嗛噹=jass.slk sight/nsight 涓ゅ垪锛坰ightDay/sightNight锛夛紝slk 鍙栦笉鍒版椂 sightDay 閫€鍥?Game.dll+0x3ADF0锛沠lags 0x%X=铦楄櫕锛圓loc锛?,
            (unsigned)DDH_ATTR_BLOCK_OFFSET, (unsigned)sizeof(DdhHeader),
            (unsigned)(DDH_MAX_EVENTS * sizeof(DdhEvent)), (unsigned)DDH_ATTR_MAX,
            (unsigned)DDH_ATTR_RESP_OFFSET, (unsigned)sizeof(DdhUnitAttr),
            (unsigned)DDH_ATTR_BLOCK_SIZE, (unsigned)sizeof(DdhShared),
            DDH_AF_LOCUST);
    LogLine("ddh 鍗忚 v18 娓告垙鍐呴潰鏉?鑻遍泟/澶村儚锛氶潰鏉垮潡鍋忕Щ=%u锛?u 瀛楄妭锛?d 琛?脳 %d 瀛楄妭锛夛紝鑻遍泟鍧楀亸绉?%u锛?u 瀛楄妭锛?d 妲斤級锛屽ご鍍忓潡鍋忕Щ=%u锛?u 瀛楄妭锛?d 妲斤級锛涢紶鏍囩偣鍑诲睍寮€鏀惰捣锛岄敭鐩?~ 鏄剧ず/闅愯棌",
            (unsigned)DDH_PANEL_BLOCK_OFFSET, (unsigned)sizeof(DdhPanelBlock),
            DDH_PANEL_MAX_LINES, DDH_PANEL_LINE_TEXT,
            (unsigned)DDH_HERO_BLOCK_OFFSET, (unsigned)sizeof(DdhHeroBlock), DDH_HERO_SLOTS,
            (unsigned)DDH_ICON_BLOCK_OFFSET, (unsigned)sizeof(DdhIconBlock), DDH_ICON_MAX);
}

/* 闈㈡澘棰勮/澶村儚娴嬭瘯鍙兘鍦ㄢ€滅涓€娆″彈浼も€濅箣鍓嶅氨鍙戝嚭锛涗笉鑳界瓑浼ゅ浜嬩欢鎵嶅惎鍔ㄧ儹閿嚎绋嬶拷?
   DllMain 閲屼笉鑳界洿鎺ュ仛寮曟搸鎿嶄綔锛岃捣涓€涓煭绾跨▼绛夌獥鍙ｅ氨缁悗鍐嶅惎鍔ㄦ秷鎭嚎绋嬶拷?*/
/* ---- v21锛歬kapi_local_plugin.dll 锟?RequestExtraStringData ----
   闈欐€佽瘉鎹紙Ghidra 12.1.4锛宬kapi_local_plugin.dll sha256 ab19b961鈥︼級锟?
   娉ㄥ唽鍑芥暟 0x10059A80 鐢ㄤ竴锟?{鍚嶅瓧,绛惧悕,鍑芥暟鎸囬拡} 涓夊厓缁勮〃鎶婃墍锟?native 娉ㄥ唽锟?JASS锟?
       RequestExtraIntegerData (IHplayer;SSBIII)I -> 0x1005A110
       RequestExtraBooleanData (IHplayer;SSBIII)B -> 0x1005A350
       RequestExtraStringData  (IHplayer;SSBIII)S -> 0x1005A290   <-- 锟?hook 鐩爣
       RequestExtraRealData    (IHplayer;SSBIII)R
   锟?RVA 0x5A290 灏辨槸 RequestExtraStringData 鏈綋锛屼笉鏄寽鐨勶拷?
   0x5A290 鍙嶇紪璇戠粨鏋勶細锟?{opcode=0xE, id, player, str1, str2, bool, i1, i2, i3} 瑁呰繘灞€锟?
   缁撴瀯浣擄紝璋冪敤 0x10029C60(singleton, &req, 4)锛屾垚鍔熸椂杩斿洖瀹冨～濂界殑閭ｄ釜涓叉寚閽堚€斺€斾篃灏辨槸
   key 鐢卞钩鍙颁晶缁欏嚭锛屽彧鑳借繍琛屾湡鎶撹繑鍥炲€硷拷?

   鐪熸绛惧悕锟?8 涓弬鏁帮紙v20 锟?7 鍙傛暟鐗堟湰鏄敊鐨勶級锟?
       (int id, Hplayer, S, S, bool, int, int, int) -> const char*
   JASS 锟?S 涓嶆槸 char*锛岃€屾槸涓€涓彞鏌勶細h->[8] -> obj锛宱bj+0x1C 鎵嶆槸 char*锟?*/
typedef const char* (__cdecl* fn_kk_req_t)(
    int id, void* player, void* s1, void* s2, int flag, int a, int b, int c);
static volatile LONG g_kkHookDone = 0;
static volatile LONG g_kkLogged = 0;
static volatile LONG g_kkCallLogged = 0;
static uint8_t* g_kkTramp = NULL;
static fn_kk_req_t g_kkTrampFn = NULL;

/* JASS 瀛楃涓插彞锟?-> char*锛涚粨鏋勯潪锟?涓虹┖鏃惰繑锟?NULL锛屽叏锟?__try 淇濇姢锟?*/
static const char* DdhJassStr(const void* h)
{
    __try
    {
        if (!h) return NULL;
        const uint8_t* inner = *(const uint8_t* const*)((const uint8_t*)h + 8);
        if (!inner) return NULL;
        const char* s = *(const char* const*)(inner + 0x1C);
        if (!s) return NULL;
        /* 鍙帴鍙楀彲璇荤殑鐭覆锛岄伩鍏嶆妸閲庢寚閽堝綋瀛楃锟?*/
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
                LogLine("JAPI KEY锛歴1=\"%s\" s2=\"%s\" ret=\"%s\"",
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
            LogLine("JAPI KEY hook锛氬嚱鏁板叆鍙ｄ笉鍖归厤锛?02X %02X %02X锛夛紝璺宠繃", fn[0], fn[1], fn[2]);
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
        LogLine("JAPI KEY hook锛氬凡鎸?DDH_JAPI_KEY=0 鍏抽棴");
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("JAPI KEY hook锛氬畨瑁呭紓甯?code=0x%08X", (unsigned)GetExceptionCode());
        InterlockedExchange(&g_kkHookDone, 1);
    }
}

/* ---- v23锛氳繍琛屾湡 key 鍊欓€夋壂鎻忥紙鏂囦欢瑙﹀彂锛岃瘖鏂敤锟?---
   骞冲彴锟?JAPI 涓嶅湪 kkapi_local_plugin.dll 閲岋紙骞冲彴锟?War3Plugin.dll锛屼笖娉ㄥ唽鏃朵笉甯﹀嚱鏁版寚閽堬級锟?
   鎵€浠ユ敼璧扳€滀粠杩涚▼鍐呭瓨閲屾壘 key鈥濊繖鏉¤矾锛氬湴鍥捐剼鏈嬁锟?key 鍚庡畠浣滀负 Lua 瀛楃涓插父椹诲爢閲岋拷?
   瑙﹀彂鏂瑰紡锛氬湪 ddh 鏃ュ織鍚岀洰褰曟斁涓€锟?ddh_scan.flag锛涙湰绾跨▼鍙戠幇鍚庢壂涓€閬嶅苟杈撳嚭
   keys-<pid>.txt锛堟瘡琛屼竴锟?16..24 瀛楄妭鍙墦锟?ASCII 涓诧級锛屽啀锟?flag 鍒犳帀锟?
   澶栭儴锟?ts_main 鐨勫瘑鏂囧仛 XOR 鑷牎楠岋紝鍗冲彲鎸戝嚭鐪熸锟?key锟?*/
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
    if (fopen_s(&f, out, "w") != 0 || !f) { LogLine("key鎵弿锛氭棤娉曞啓 %s", out); return; }

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
    LogLine("key鎵弿锛氬畬鎴愶紝%ld 涓€欓€変覆銆?ld 涓彲璇诲尯 -> %s", written, regions, out);
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
        LogLine("key鎵弿锛氭敹鍒拌Е鍙戞枃浠讹紝寮€濮嬫壂鎻忔湰杩涚▼鍐呭瓨");
        DeleteFileA(flag);
        DdhScanKeysOnce();
    }
    return 0;
}

static DWORD WINAPI DdhStartupThread(LPVOID)
{
    Sleep(200);
    DdhEnsureHotkeyThread();
    /* v22锛氶粯璁ゅ紑鍚紙鍙鏃ュ織銆佸師鏍烽€忎紶锛岄闄╂瀬浣庯級銆傝鍏虫帀灏辫 DDH_JAPI_KEY=0锟?*/
    char jk[8] = { 0 };
    if (GetEnvironmentVariableA("DDH_JAPI_KEY", jk, (DWORD)sizeof(jk)) != 0 && jk[0] == '0')
    {
        LogLine("JAPI KEY hook锛氬凡鎸?DDH_JAPI_KEY=0 鍏抽棴");
        return 0;
    }
    LogLine("JAPI KEY hook锛氶粯璁ゅ紑鍚紝绛夊緟 kkapi_local_plugin.dll 鍔犺浇");
    /* 锟?JAPI 鎻掍欢鍔犺浇锛沰ey 鍦ㄥ湴鍥捐剼鏈垵濮嬪寲鏃惰鍙栵紝蹇呴』璧跺湪瀹冧箣鍓嶏拷?*/
    for (int i = 0; i < 2400 && InterlockedCompareExchange(&g_kkHookDone, 0, 0) == 0; ++i)
    {
        DdhTryInstallKkHook();
        if (InterlockedCompareExchange(&g_kkHookDone, 0, 0) != 0) break;
        Sleep(50);
    }
    if (InterlockedCompareExchange(&g_kkHookDone, 0, 0) == 0)
        LogLine("JAPI KEY hook锛氱瓑寰呰秴鏃讹紙120s锛夛紝kkapi_local_plugin.dll 濮嬬粓鏈姞杞?);
    return 0;
}

BOOL APIENTRY DllMain(HMODULE mod, DWORD reason, LPVOID)
{
    if (g_ddhDllTick == 0) g_ddhDllTick = GetTickCount();
    if (reason == DLL_PROCESS_ATTACH)
    {
        g_self = mod;
        DisableThreadLibraryCalls(mod);
        SetupShared();
        g_ddhUprobeOn = DdhUprobeReadEnv();   /* DDH_UPROBE=1 鎵嶅仛璇婃柇 dump */
        {
            const int envMode = DdhUnitDumpEnvMode();
            if (envMode == 0) g_ddhUnitDumpMode = 0;
            else if (envMode == 2) g_ddhUnitDumpMode = 2;
            else g_ddhUnitDumpMode = DdhUnitDumpFlagFile() ? 2 : 1;
        }
        if (g_shm)
        {
            g_shm->hdr.gameDllBase = 0;
            if (InstallHook())
            {
                g_shm->hdr.reserved[0] = 1u;   /* 鏂版寕杞芥柟寮忔亽寮€锛歝all 鍘熷嚱鏁板悗璇诲悗琛€ */
                g_shm->hdr.hookOk = 1;
                g_shm->hdr.gameDllBase = (uint32_t)((uintptr_t)g_hookAt - g_foundRva);
                g_shm->hdr.hookRva = g_foundRva;
            }
            /* 涓嶇瓑绗竴娆′激瀹筹細鍏堟媺璧锋秷鎭嚎绋嬶紝C# 鐨勯锟?澶村儚娴嬭瘯鎵嶈兘绔嬪嵆娑堣垂锟?*/
            CreateThread(NULL, 0, DdhStartupThread, NULL, 0, NULL);
            CreateThread(NULL, 0, DdhScanWatchThread, NULL, 0, NULL);
        }
    }
    else if (reason == DLL_PROCESS_DETACH)
    {
        /* v9锛氬厛璁╃儹閿嚎绋嬮€€鍑哄苟娉ㄩ攢鐑敭锛堝惁鍒欑粍鍚堥敭浼氫竴鐩寸矘鍦ㄦ湰杩涚▼涓婏級 */
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

        /* v12锛氬厛杩樺師绐楀彛杩囩▼锛堝惁鍒欑獥鍙ｈ繕鎸囩潃鎴戜滑鐨勪唬鐮侊紝鍗歌浇鍚庡啀鏈変换浣曟秷鎭氨宕╋級 */
        DdhRestoreGameWnd();

        /* 鍗搁挬锛氭妸鍘熸潵锟?6 瀛楄妭鍐欏洖锟?*/
        if (g_hooked && g_hookAt)
        {
            DWORD old = 0;
            if (VirtualProtect(g_hookAt, 8, PAGE_EXECUTE_READWRITE, &old))
            {
                memcpy(g_hookAt, g_saved, STEAL);
                FlushInstructionCache(GetCurrentProcess(), g_hookAt, 8);
                VirtualProtect(g_hookAt, 16, old, &old);
                LogLine("宸插嵏閽?);
            }
        }
        if (g_shm) { UnmapViewOfFile(g_shm); g_shm = NULL; }
        if (g_map) { CloseHandle(g_map); g_map = NULL; }
    }
    return TRUE;
}
#ifdef DDH_MSG_TEST
/* ===========================================================================
   娑堟伅缂栫爜 / 鏍煎紡鑷锛堝彧锟?`cl /DDDH_MSG_TEST ddh.cpp` 杩欑涓存椂鏋勫缓鎵嶇紪杩涙潵锟?
   build_hook.ps1 涓嶅畾锟?DDH_MSG_TEST锛屾墍浠ュ彂甯冪敤锟?ddh.dll 锟?*娌℃湁**杩欎竴娈碉級锟?
   ---------------------------------------------------------------------------
   鏂█鐢ㄧ殑閮芥槸鐪熸満鏃ュ織閲岀殑鐪熷疄瀛楄妭锛氬悕瀛椻€滈洩鐙硷拷?= E9 9B AA E7 8B BC锟?
   璺戞硶锛歮sgtest.exe 锟?閫€鍑虹爜 0 = 鍏ㄨ繃锛岄潪 0 = 澶辫触鏉℃暟锛涙槑缁嗗悓鏃跺啓 _msgtest_result.txt锟?
   =========================================================================== */
static int   g_testFail = 0;
static FILE* g_testFile = NULL;

/* 鏈熸湜锟?UTF-8 鍓嶇紑锛堢湡鏈哄瓧鑺傦紝涓嶆槸婧愮爜閲岀殑 GBK 瀛楅潰閲忥級 */
static const char kSharePrefix[] = "\xE3\x80\x90\xE4\xBC\xA4\xE5\xAE\xB3\xE3\x80\x91";                              /* 銆愪激瀹筹拷?*/
static const char kLivePrefix[]  = "\xE3\x80\x90\xE5\xBD\x93\xE5\x89\x8D\xE4\xBC\xA4\xE5\xAE\xB3\xE3\x80\x91";      /* 銆愬綋鍓嶄激瀹筹拷?*/
static const char kPickPrefix[]  = "\xE3\x80\x90\xE5\xB7\xB2\xE9\x80\x89\xE4\xB8\xAD\xE3\x80\x91";                  /* 銆愬凡閫変腑锟?*/
static const char kOffPrefix[]   = "\xE3\x80\x90\xE5\xB7\xB2\xE5\x8F\x96\xE6\xB6\x88\xE3\x80\x91";                  /* 銆愬凡鍙栨秷锟?*/
static const char kOnPrefix[]    = "\xE3\x80\x90\xE5\xB7\xB2\xE5\xBC\x80\xE5\x90\xAF\xE3\x80\x91";                  /* 銆愬凡寮€鍚拷?*/

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

/* 鎵撳嵃涓€锟?UTF-8 鏂囨湰锛歨ex锛堝墠 120 瀛楄妭锟? GBK 鍥炴樉锛圙BK 鎵嶈兘鍦ㄦ帶鍒跺彴/GBK 鏂囦欢閲岀湅鎳傦級 */
static void DdhTestDump(const char* tag, const char* s)
{
    char hex[768] = { 0 };
    int n = (int)strlen(s);
    if (n > 120) n = 120;
    FormatHex((const unsigned char*)s, n, hex, sizeof(hex));
    DdhTestOut("  %s 闀垮害=%u hex=%s\n", tag, (unsigned)strlen(s), hex);
    DdhTestOut("  %s 鏂囨湰=%s\n", tag, s);
}

/* 閫犱竴浠解€滆褰曞崟锟?+ 涓や釜鏉ユ簮锟?0.0% / 20.0%锛夆€濈殑缁熻 */
static void DdhTestMakeTrack(double net0, double net1, double raw0, double raw1)
{
    memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
    g_ddhTrack.unit = 0x12345000u;
    g_ddhTrack.code = 0x6870666Fu;                        /* hfoo锛堝唴瀛橀噷鍙嶅簭锛岃繖閲屼笉褰卞搷锟?*/
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

    /* ---- 1) 姝讳骸缁撶畻锛氬彧鍙戙€愪激瀹炽€戯紝涓绘涓嶅嚭锟?---- */
    DdhTestOut("== 1) 姝讳骸缁撶畻锛氬彧鍙戙€愪激瀹炽€戯紙鍚嶅瓧 UTF-8 = E9 9B AA E7 8B BC 闆嫾锟?=\n");
    DdhTestMakeTrack(243.472, 60.868, 471.20, 117.80);     /* 304.34 锟?80.0% / 20.0% */
    DdhBuildTrackText(msg, sizeof(msg), 1);
    DdhTestDump("姝讳骸缁撶畻", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "杈撳嚭鏁翠綋鏄悎锟?UTF-8");
    DdhTestCheck(strncmp(msg, kSharePrefix, sizeof(kSharePrefix) - 1) == 0,
                 "浠ャ€愪激瀹炽€戝紑澶达紙涓嶅啀鏈夈€愭浜＄粨绠椼€戜富娈碉級");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL,
                 "鍚嶅瓧鈥滈洩鐙尖€濈殑鍘熷瓧锟?E9 9B AA E7 8B BC 鍘熸牱鍑虹幇锛堟病鏈夎鍐嶈浆涓€娆★級");
    DdhTestCheck(strstr(msg, "\xE5\xA6\x96") == NULL,
                 "涓嶅惈鍙岃浆鐮佷贡锟?E5 A6 96锛堟棫鐗堝氨鏄繖涔堝潖鐨勶級");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL,
                 "鍚€滈洩锟?0.0%鈥濓紙鍚嶅瓧鐩存帴鎺ヤ竴浣嶅皬鏁扮殑鍗犳瘮锟?);
    DdhTestCheck(strstr(msg, "\xE7\x8B\xBC\xE4\xBA\xBA" "20.0%") != NULL, "鍚€滅嫾锟?0.0%锟?);
    DdhTestCheck(strstr(msg, "hfoo") == NULL && strstr(msg, "hwol") == NULL,
                 "涓嶅惈绫诲瀷鐮佸悗缂€锛堟潵婧愰」鍙鍚嶅瓧/鐮侊級");
    DdhTestCheck(strstr(msg, "\xE5\x8F\x97") == NULL && strstr(msg, "\xE5\x87\x80") == NULL &&
                 strstr(msg, "\xE6\x9C\x80") == NULL && strstr(msg, ":") == NULL,
                 "涓嶅惈 鍙楀嚮/鍑€/鏈€锟?鏃堕棿锛堜富娈靛凡鎸夎姹傚幓鎺夛級");
    DdhTestCheck(strlen(msg) <= DDH_MSG_MAX_BYTES, "闀垮害娌¤秴锟?420 瀛楄妭");
    DdhTestCheck(g_msgNameRawUtf8 == 2 && g_msgNameGbkFallback == 0,
                 "鏈潯 2 涓潵婧愬悕瀛楀叏閮ㄨ蛋鈥滃師锟?UTF-8鈥濋偅鏉¤矾");

    /* ---- 2) Ctrl+Alt+Q锛氭爣棰樻敼鎴愩€愬綋鍓嶄激瀹筹拷?---- */
    DdhTestOut("\n== 2) Ctrl+Alt+Q锛氥€愬綋鍓嶄激瀹筹拷? 鍚屾牱鐨勫崰锟?==\n");
    DdhBuildTrackText(msg, sizeof(msg), 0);
    DdhTestDump("褰撳墠浼ゅ", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "瀹炴椂缁熻鏄悎锟?UTF-8");
    DdhTestCheck(strncmp(msg, kLivePrefix, sizeof(kLivePrefix) - 1) == 0, "浠ャ€愬綋鍓嶄激瀹炽€戝紑锟?);
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL &&
                 strstr(msg, "\xE7\x8B\xBC\xE4\xBA\xBA" "20.0%") != NULL, "鍚屾牱锟?80.0% / 20.0%");

    /* ---- 3) 銆愪激瀹炽€戞鑷韩锛歍op N 鎴柇锛堝厛鐮嶉潬鍚庣殑鏉ユ簮锟?--- */
    DdhTestOut("\n== 3) 銆愪激瀹炽€戞锛歍op N 鎴柇 ==\n");
    char items[320] = { 0 };
    int used = DdhBuildShareItems(g_ddhTrack.src, g_ddhTrack.srcCount,
                                  g_ddhTrack.net, g_ddhTrack.raw, 1, items, sizeof(items));
    DdhTestDump("Top1", items);
    DdhTestCheck(used == 1, "鍙暀 1 椤规椂杩斿洖 1");
    DdhTestCheck(DdhUtf8Valid(items), "Top1 鏄悎锟?UTF-8");
    DdhTestCheck(strstr(items, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL, "Top1 = 闆嫾80.0%锛堢暀鍗犳瘮鏈€澶х殑锟?);

    /* ---- 4) GBK 鍚嶅瓧鍥為€€锛欴1 A9 C0 C7锛圙BK 鐨勨€滈洩鐙尖€濓級---- */
    DdhTestOut("\n== 4) GBK 鍚嶅瓧鍥為€€锛欴1 A9 C0 C7锛圙BK 鐨勯洩鐙硷級==\n");
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
    DdhTestDump("GBK鍚嶅瓧", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "鍥為€€鍚庢暣浣撲粛鏄悎锟?UTF-8");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL,
                 "GBK 鍚嶅瓧 D1 A9 C0 C7 琚浆锟?UTF-8 鐨勨€滈洩鐙尖€濓紙E9 9B AA E7 8B BC锟?);
    DdhTestCheck(g_msgNameGbkFallback == 1 && g_msgNameRawUtf8 == 0, "鏈潯璧扮殑锟?GBK 鍥為€€閭ｆ潯锟?);

    /* ---- 5) R 閫変腑 / S 寮€锟?鐨勬湰鏈烘彁绀烘枃锟?---- */
    DdhTestOut("\n== 5) Ctrl+Alt+R / S 鐨勬湰鏈烘彁锟?==\n");
    char toast[256] = { 0 };
    DdhAppendLabel(toast, sizeof(toast), "銆愬凡閫変腑锟?);
    DdhAppendUnitName(toast, sizeof(toast), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");
    DdhTestDump("宸查€変腑", toast);
    DdhTestCheck(DdhUtf8Valid(toast), "銆愬凡閫変腑銆戞彁绀烘槸鍚堟硶 UTF-8");
    DdhTestCheck(strncmp(toast, kPickPrefix, sizeof(kPickPrefix) - 1) == 0, "浠ャ€愬凡閫変腑銆戝紑锟?);
    DdhTestCheck(strstr(toast, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL, "銆愬凡閫変腑銆戦噷甯﹀悕瀛椻€滈洩鐙硷拷?);

    char off[256] = { 0 };
    char on[256]  = { 0 };
    DdhAppendLabel(off, sizeof(off), "銆愬凡鍙栨秷銆戞浜＄粨绠椾笉鍐嶈嚜鍔ㄥ彂锟?);
    DdhAppendLabel(on,  sizeof(on),  "銆愬凡寮€鍚€戞浜＄粨绠椾細鑷姩鍙戯拷?);
    DdhTestDump("宸插彇锟?, off);
    DdhTestCheck(DdhUtf8Valid(off) && strncmp(off, kOffPrefix, sizeof(kOffPrefix) - 1) == 0,
                 "銆愬凡鍙栨秷銆戞彁绀烘锟?);
    DdhTestCheck(DdhUtf8Valid(on) && strncmp(on, kOnPrefix, sizeof(kOnPrefix) - 1) == 0,
                 "銆愬凡寮€鍚€戞彁绀烘锟?);

    /* ---- 6) 纭埅鏂細420 瀛楄妭銆佹湯灏锯€溾€︹€濄€佷笉鍒囧潖姹夊瓧 ---- */
    DdhTestOut("\n== 6) 纭埅鏂細<=420 瀛楄妭銆佹湯灏锯€溾€︹€濄€佷笉鍒囧潖姹夊瓧 ==\n");
    char longText[1024] = { 0 };
    for (int i = 0; i < 200; i++) memcpy(longText + i * 3, "\xE9\x9B\xAA", 3);   /* 200 涓€滈洩锟? 600 瀛楄妭 */
    DdhTruncateUtf8(longText, sizeof(longText), DDH_MSG_MAX_BYTES);
    const size_t longLen = strlen(longText);
    char tail[4] = { 0 };
    char tailHex[32] = { 0 };
    if (longLen >= 3) memcpy(tail, longText + longLen - 3, 3);
    FormatHex((const unsigned char*)tail, 3, tailHex, sizeof(tailHex));
    DdhTestOut("  鎴柇鍚庨暱锟?%u 鏈熬3瀛楄妭=%s锛堝簲锟?E2 80 A6锛塡n", (unsigned)longLen, tailHex);
    DdhTestCheck(longLen <= DDH_MSG_MAX_BYTES, "鎴柇锟?<= 420 瀛楄妭");
    DdhTestCheck(DdhUtf8Valid(longText), "鎴柇鍚庝粛鏄悎锟?UTF-8锛堟病鍒囧嚭鍗婁釜姹夊瓧锟?);
    DdhTestCheck(memcmp(tail, "\xE2\x80\xA6", 3) == 0, "鏈熬琛ヤ簡鈥溾€︹€濓紙E2 80 A6锟?);
    DdhTestCheck(longLen == DDH_MSG_MAX_BYTES, "鎴柇姝ｅソ鐢ㄦ弧 420 瀛楄妭");

    /* ---- 7) 鍗犳瘮鏍煎紡锛氫竴浣嶅皬锟?/ 0.1% 涓嬮檺 / 100.0% 涓婇檺 ---- */
    DdhTestOut("\n== 7) share format: one decimal / 0.1%% floor / 100.0%% cap ==\n");
    DdhSrcStat bs[2];
    memset(bs, 0, sizeof(bs));
    char bshare[320] = { 0 };
    strcpy_s(bs[0].label, sizeof(bs[0].label), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");   /* 闆嫾 */
    strcpy_s(bs[1].label, sizeof(bs[1].label), "\xE7\x8B\xBC\xE4\xBA\xBA(hwol)");   /* 鐙间汉 */
    bs[0].net = 100.0; bs[1].net = 0.02;
    DdhBuildShareItems(bs, 2, 100.02, 100.02, DDH_SHARE_TOP, bshare, sizeof(bshare));
    DdhTestDump("杈圭晫鍗犳瘮", bshare);
    DdhTestCheck(strstr(bshare, "100.0%") != NULL, "99.98% 鍥涜垗浜斿叆锟?100.0%锛堜笂闄愶級");
    DdhTestCheck(strstr(bshare, "0.1%") != NULL, "0.02% 鎶埌 0.1% 涓嬮檺锛堜笉鏄剧ず 0.0%锟?);
    DdhTestCheck(strstr(bshare, " 0.0%") == NULL, "娌℃湁 0.0% 杩欑鍐欐硶锟?00.0% 鏄笂闄愶紝涓嶇畻锟?);
    bs[0].net = 31.13; bs[1].net = 68.87;
    DdhBuildShareItems(bs, 2, 100.0, 100.0, DDH_SHARE_TOP, bshare, sizeof(bshare));
    DdhTestDump("涓€浣嶅皬锟?, bshare);
    DdhTestCheck(strstr(bshare, "31.1%") != NULL && strstr(bshare, "68.9%") != NULL,
                 "31.13锟?1.1% / 68.87锟?8.9%锛堝洓鑸嶄簲鍏ュ埌 0.1锟?);
    DdhTestCheck(strstr(bshare, "31%") == NULL, "涓嶅啀鍑虹幇鏁存暟鍐欐硶 31%");

    /* 8) 闀垮悕瀛楁爣绛撅細64/96 瀛楄妭閮借涓嶄笅鏃跺彧鑳解€滃畨鍏ㄦ埅鏂拷?
          鐪熸満 2026-10-31 20:22:52 宕╁湪 sprintf_s 鐨勬棤鏁堝弬鏁颁笂锟?
          闀夸腑鏂囧悕 鈥溾€︹€︺€愯緟鍔╁崟浣嶏拷?e009)锟?鍐欒繘 64 瀛楄妭鏍囩 锟?_invoke_watson 锟?0xC0000409锟?*/
    {
        char longName[160] = { 0 };
        for (int i = 0; i < 24; i++) strcat_s(longName, sizeof(longName), "\xE6\x88\x98");
        char lab64[64] = { 0 };
        DdhComposeLabel(longName, "e009", lab64, sizeof(lab64));
        DdhTestDump("闀垮悕瀛椻啋64 瀛楄妭鏍囩", lab64);
        DdhTestCheck(strlen(lab64) < sizeof(lab64), "闀垮悕瀛椻啋64 瀛楄妭鏍囩涓嶈秺锟?);
        DdhTestCheck(DdhUtf8Valid(lab64), "闀垮悕瀛椻啋64 瀛楄妭鏍囩浠嶆槸鍚堟硶 UTF-8");
        DdhTestCheck(lab64[0] && lab64[strlen(lab64) - 1] == ')', "闀垮悕瀛楁埅鏂悗浠嶄繚锟?锟?锟?锟?鍚庣紑");
        DdhTestCheck(strstr(lab64, "(e009") != NULL, "鍚庣紑锟?(e009");

        char lab96[96] = { 0 };
        DdhComposeLabel(longName, "e009", lab96, sizeof(lab96));
        DdhTestCheck(strlen(lab96) < sizeof(lab96) && DdhUtf8Valid(lab96), "闀垮悕瀛椻啋96 瀛楄妭鏍囩鍚屾牱瀹夊叏");
        DdhTestCheck(strlen(lab96) > strlen(lab64), "96 瀛楄妭锟?64 瀛楄妭瑁呭緱涓嬫洿澶氬悕锟?);

        char lab8[8] = { 0 };
        DdhComposeLabel(longName, "e009", lab8, sizeof(lab8));
        DdhTestCheck(DdhUtf8Valid(lab8) && strlen(lab8) < sizeof(lab8), "鏋佸皬缂撳啿(8 瀛楄妭)涔熷畨锟?);

        char labNone[8] = { 0 };
        DdhComposeLabel("", "", labNone, sizeof(labNone));
        DdhTestCheck(strcmp(labNone, "?") == 0, "娌″悕瀛椾篃娌＄爜鏃跺啓 ?");
    }

    /* ---- v15锛氶潰锟?/ 鑻遍泟鏌ヨ鍧楀竷灞€ ----
       锟?C# InGamePanelWire 蹇呴』閫愰」涓€鑷达紱浠讳綍涓€椤瑰涓嶄笂锛孋# 浼氳閿欏亸绉伙拷?*/
    DdhTestOut("\n== v15) panel/hero protocol layout ==\n");
    DdhTestCheck(sizeof(DdhPanelLine) == 244, "DdhPanelLine = 244 瀛楄妭锛坈olor 4 + text 240锟?);
    DdhTestCheck(sizeof(DdhPanelBlock) == 4952, "DdhPanelBlock = 4952 瀛楄妭");
    DdhTestCheck(sizeof(DdhHeroReq) == 8 && sizeof(DdhHeroRes) == 16, "Hero Req/Res = 8/16 瀛楄妭");
    DdhTestCheck(sizeof(DdhHeroBlock) == 400, "DdhHeroBlock = 400 瀛楄妭");
    DdhTestCheck(DDH_PANEL_BLOCK_OFFSET == 141256u, "闈㈡澘鍧楀亸锟?= 141256锛堝ご 64 + 浜嬩欢 120832 + 灞烇拷?20360锟?);
    DdhTestCheck(DDH_HERO_BLOCK_OFFSET == 146208u, "鑻遍泟鍧楀亸锟?= 146208锟? 141256 + 4952锟?);
    DdhTestCheck(sizeof(DdhIconSlot) == 16 && sizeof(DdhIconBlock) == 80,
                 "DdhIconSlot/Block = 16/80 瀛楄妭");
    DdhTestCheck(DDH_ICON_BLOCK_OFFSET == 146608u, "澶村儚鍧楀亸锟?= 146608锟? 146208 + 400锟?);
    DdhTestCheck(offsetof(DdhIconBlock, slots) == 16, "IconBlock.slots 鍋忕Щ = 16");
    DdhTestCheck(offsetof(DdhPanelBlock, lines) == 72, "PanelBlock.lines 鍋忕Щ = 72");
    DdhTestCheck(offsetof(DdhPanelBlock, fontName) == 40, "PanelBlock.fontName 鍋忕Щ = 40");
    DdhTestCheck(offsetof(DdhPanelBlock, lineCount) == 16, "PanelBlock.lineCount 鍋忕Щ = 16");
    DdhTestCheck(offsetof(DdhHeroBlock, req) == 16 && offsetof(DdhHeroBlock, res) == 144,
                 "HeroBlock req/res 鍋忕Щ = 16/144");
    DdhTestCheck(sizeof(DdhShared) == 146688u, "DdhShared = 146688 瀛楄妭锟? MB 鍏变韩鍐呭瓨瀵屼綑锟?);
    DdhTestCheck(DDH_PANEL_MAX_LINES == 20 && DDH_PANEL_LINE_TEXT == 240 && DDH_HERO_SLOTS == 16,
                 "闈㈡澘 20 锟?脳 240 瀛楄妭 / 鑻遍泟 16 锟?);
    DdhTestCheck(DDH_PANEL_FLAG_SHOW == 1 && DDH_PANEL_FLAG_HIDE == 2 &&
                 DDH_PANEL_FLAG_BG == 4 && DDH_PANEL_FLAG_COLLAPSED == 8,
                 "v16 flags锛氭樉锟?闅愯棌/鑳屾櫙/榛樿鏀惰捣 = 1/2/4/8");
    DdhTestCheck(DDH_PANEL_COLLAPSED_SHIFT == 8 && DDH_PANEL_COLLAPSED_MASK == 0xFF,
                 "v16 鏀惰捣琛屾暟锟?flags bit8..15锟? = 榛樿 6锟?);

    DdhTestOut("\n%s锛堝け锟?%d 椤癸級\n", g_testFail == 0 ? "== 鑷閫氳繃 ==" : "== 鑷澶辫触 ==", g_testFail);
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
   v13 瀛愪激瀹宠璐﹁嚜妫€锛堝彧锟?`cl /DDH_CHILDSUM_TEST ddh.cpp` 杩欑涓存椂鏋勫缓鎵嶇紪杩涙潵锟?
   build_hook.ps1 涓嶅畾锟?DDH_CHILDSUM_TEST锛屽彂甯冪敤锟?ddh.dll 锟?*娌℃湁**杩欎竴娈碉級锟?
   ---------------------------------------------------------------------------
   鐩存帴椹卞姩 DdhFramePush / DdhFramePop锛岃鐩栫湡鏈轰笂鐨勫鐩爣 AoE锟?
     鐖跺抚鎵撳紶锟?A锟?01.20 锟?73.07锛堟暣锟?28.13锟?
     鍐呭眰瀛愬抚锛欰 5.63 / 鍏搁煢 B 5.63 / 姝ュ叺 C 7.50 / 姝ュ叺 C 7.50锛堝瓙鍚堣 26.26锟?
   鏃х増锟?26.26 鍏ㄦ墸鍒扮埗锟?锟?own=1.87锛涙纭彧鎵ｅ悓鐩爣锟?5.63 锟?own=22.50锟?
   璺戞硶锛歝hildsumtest.exe 锟?閫€鍑虹爜 0 = 鍏ㄨ繃锛岄潪 0 = 澶辫触鏉℃暟锛涙槑缁嗗悓鏃跺啓
         _childsum_result.txt锛屽祵濂楁墸鍑忔棩蹇楀啓 _childsum_test.log锟?
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
    DdhSprintf(buf, sizeof(buf), "%s锛堝疄锟?%.2f锛屾湡锟?%.2f 卤0.01锟?, what, got, want);
    CsCheck(ok, buf);
}

#define CS_A 0xA0001000u
#define CS_B 0xB0002000u
#define CS_C 0xC0003000u

/* 鍘嬩竴涓瓙甯с€佹寜缁欏畾鎺夎閫€鏍堬紝杩斿洖瀛愬抚鑷繁锟?own */
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

    /* ---- 1) 澶氱洰锟?AoE锛氱埗 A 28.13锛屽瓙 A 5.63 / B 5.63 / C 7.50 / C 7.50 ---- */
    CsOut("== 1) 澶氱洰锟?AoE锛氱埗=寮犻A 101.20锟?3.07锟?8.13锛夛紝鍐呭眰 A 5.63 / 鍏搁煢B 5.63 / 姝ュ叺C 7.50 脳2 ==\n");
    memset(g_frames, 0, sizeof(g_frames));
    DdhFrame* p = DdhFramePush(0, CS_A, 101.20f, 1);
    CsCheck(p != NULL && p->depth == 1, "鐖跺抚鍘嬫爤鎴愬姛锛坉epth=1锟?);
    const float ownA  = CsChild(1, CS_A, 50.00f, 5.63f);
    const float ownB  = CsChild(1, CS_B, 50.00f, 5.63f);
    const float ownC1 = CsChild(1, CS_C, 50.00f, 7.50f);
    const float ownC2 = CsChild(1, CS_C, 50.00f, 7.50f);
    CsCheck(p->childCountSame == 1, "鐖跺抚鍙敹锟?1 绗斿悓鐩爣瀛愬抚锛圓锟?);
    CsNear(p->childSumSameVictim, 5.63f, "鐖跺抚鍚岀洰鏍囧瓙鍚堣锛圔/C 涓嶆墸鐖跺抚锟?);
    float gross = 0.0f, own = 0.0f;
    const bool measured = DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsCheck(measured, "鐖跺抚鍓嶅悗琛€鏈夋晥锛宱wn 鍙祴");
    CsOut("  鐖跺抚锟?01.20锟?3.07 鏁存=%.2f 鍚岀洰鏍囧瓙鍚堣=%.2f锟?u 绗旓級 own=%.2f\n",
          gross, p->childSumSameVictim, p->childCountSame, own);
    CsNear(gross, 28.13f, "鐖跺抚鏁存 gross");
    CsNear(own, 22.50f, "鐖跺抚 own锛堟棫鐗堟寜 26.26 鎵ｄ細閿欐垚 1.87锟?);
    CsNear(ownA, 5.63f, "瀛愬抚 A 锟?own");
    CsNear(ownB, 5.63f, "瀛愬抚 B锛堝吀闊︼級锟?own");
    CsNear(ownC1, 7.50f, "瀛愬抚 C 锟?1 绗旂殑 own");
    CsNear(ownC2, 7.50f, "瀛愬抚 C 锟?2 绗旂殑 own");

    /* ---- 2) 鍐嶅祵涓€灞傦細瀛欏抚锟?A 1.00锛堝湪瀛愬抚 A 锟?5.63 鍐咃級 ---- */
    CsOut("\n== 2) 鍐嶅祵涓€灞傦細瀛欏抚锟?A 1.00锛堝湪瀛愬抚 A 锟?5.63 鍐咃級==\n");
    memset(g_frames, 0, sizeof(g_frames));
    p = DdhFramePush(0, CS_A, 101.20f, 1);
    DdhFrame* childA = DdhFramePush(1, CS_A, 50.00f, 1);
    DdhFrame* grand  = DdhFramePush(2, CS_A, 30.00f, 1);
    float gGrand = 0.0f, oGrand = 0.0f;
    DdhFramePop(grand, 1, 29.00f, 1, 0.0f, &gGrand, &oGrand);
    CsNear(gGrand, 1.00f, "瀛欏抚鏁存 gross");
    CsNear(oGrand, 1.00f, "瀛欏抚 own");
    CsNear(childA->childSumSameVictim, 1.00f, "瀛愬抚 A 鏀跺埌瀛欏抚 1.00锛堝悓鐩爣锟?);
    float gChild = 0.0f, oChild = 0.0f;
    DdhFramePop(childA, 1, 44.37f, 1, 0.0f, &gChild, &oChild);
    CsNear(gChild, 5.63f, "瀛愬抚 A 鏁存锛堝惈瀛欏抚 1.00锟?);
    CsNear(oChild, 4.63f, "瀛愬抚 A own = 5.63 - 1.00");
    CsChild(1, CS_B, 50.00f, 5.63f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsNear(p->childSumSameVictim, 5.63f, "鐖跺抚鍚岀洰鏍囧瓙鍚堣浠嶆槸 5.63锛堝瓩甯т笉閲嶅鎵ｏ級");
    DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsNear(own, 22.50f, "鐖跺抚 own 锟?= 22.50锛堟墸鍑忓凡鍖呭惈瀛欏抚锟?1.00锟?);

    /* ---- 3) 鍙湁寮傜洰鏍囧瓙甯э細鐖跺抚涓€鍒嗕笉锟?---- */
    CsOut("\n== 3) 鍙湁寮傜洰鏍囧瓙甯э細鐖跺抚 own 涓嶈锟?==\n");
    memset(g_frames, 0, sizeof(g_frames));
    p = DdhFramePush(0, CS_A, 101.20f, 1);
    CsChild(1, CS_B, 50.00f, 5.63f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsCheck(p->childCountSame == 0, "寮傜洰鏍囧瓙甯т笉璁板叆鐖跺抚");
    DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsNear(own, 28.13f, "鐖跺抚 own = 鏁存 28.13锛堟病鏈夊悓鐩爣瀛愬抚鍙墸锟?);

    /* ---- 4) 鏍堜笂闄愪繚锟?---- */
    CsOut("\n== 4) 鏍堜笂闄愪繚鎶わ紙甯ф爤锟?= DDH_MAXDEPTH = %u锟?=\n", (unsigned)DDH_MAXDEPTH);
    CsCheck(DdhFramePush(DDH_MAXDEPTH, CS_A, 1.0f, 1) == NULL, "瓒婄晫灞傚帇鏍堣繑锟?NULL锛堜笉瓒婄晫鍐欙級");
    float gSafe = 1.0f, oSafe = 1.0f;
    CsCheck(!DdhFramePop(NULL, 1, 0.0f, 1, 0.0f, &gSafe, &oSafe) && gSafe == 0.0f && oSafe == 0.0f,
            "锟?瓒婄晫甯ч€€鏍堝畨鍏紙涓嶅穿銆佽緭鍑烘竻闆讹級");

    /* ---- 5) 宓屽鎵ｅ噺鏃ュ織 ---- */
    CsOut("\n== 5) 宓屽鎵ｅ噺鏃ュ織锛堝墠 3 娆★級==\n");
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
    CsCheck(logOk, "鑳借鍒板祵濂楁墸鍑忔棩蹇楁枃锟?);
    CsCheck(strstr(logText, "own=22.50") != NULL, "鏃ュ織锟?own=22.50锛堢埗甯ф墸鍑忓悗鐨勫噣鎺夎锟?);
    CsCheck(strstr(logText, "0xA0001000") != NULL, "鏃ュ織鍚埗甯у湴鍧€ 0xA0001000");
    CsOut("  鏃ュ織鍐呭锛圙BK锛夛細\n%s\n", logText);

    CsOut("\n%s锛堝け锟?%d 椤癸級\n", g_csFail == 0 ? "== 鑷閫氳繃 ==" : "== 鑷澶辫触 ==", g_csFail);
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
   v9 鍚嶅瓧鎴柇鑷锛堝彧锟?`cl /DDDH_NAMETEST ddh.cpp` 鐨勪复鏃堕獙璇佺敤锛宐uild_hook.ps1
   涓嶅畾涔夎繖涓畯锛屽彂锟?ddh.dll 閲屾病鏈夎繖涓€娈碉級锟?
   楠岃瘉 DdhUtf8SafeCopy锟?9/63 瀛楄妭鍒囧湪姹夊瓧涓棿鏃跺洖閫€鍒板畬鏁村瓧绗﹁竟鐣岋紝
   婧愪覆鑷繁浠ュ崐涓眽瀛楃粨灏炬椂涔熶涪鎺夋畫瀛楃锟?
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
    for (int i = 0; i < 20; i++) memcpy(text + i * 3, "\xE9\x9B\xAA", 3);   /* 20 涓洩 = 60 瀛楄妭 */
    memcpy(text + 60, "ab", 2);
    memcpy(text + 62, "\xE9\x9B\xAA", 3);                                   /* 鍐嶄竴涓洩 = 65 瀛楄妭 */

    size_t n29 = DdhUtf8SafeCopy(out, sizeof(out), text, 29);
    NtCheck(n29 == 27, "29 杈圭晫鍥為€€锟?27 瀛楄妭锟? 涓畬鏁存眽瀛楋級");
    NtCheck(DdhUtf8Valid(out), "29 杈圭晫杈撳嚭鏄悎锟?UTF-8");

    size_t n63 = DdhUtf8SafeCopy(out, sizeof(out), text, 63);
    NtCheck(n63 == 62, "63 杈圭晫鍥為€€锟?62 瀛楄妭锟?0 姹夊瓧 + ab锟?);
    NtCheck(DdhUtf8Valid(out), "63 杈圭晫杈撳嚭鏄悎锟?UTF-8");

    const char* half = "bbbb\xE6\x8A\x80\xE4\xBD";   /* 鏈熬銆屼綅銆嶅彧鏈夊墠 2 瀛楄妭 */
    size_t nh = DdhUtf8SafeCopy(out, sizeof(out), half, 63);
    NtCheck(nh == 7 && strcmp(out, "bbbb\xE6\x8A\x80") == 0, "婧愪覆鏈熬鍗婁釜姹夊瓧琚涪鎺夛紙bbbb鎶€锟?);
    NtCheck(DdhUtf8Valid(out), "婧愪覆鎴柇杈撳嚭鏄悎锟?UTF-8");

    printf("== %s锛堝け锟?%d 椤癸級==\n", g_ntFail == 0 ? "NAMETEST PASS" : "NAMETEST FAIL", g_ntFail);
    return g_ntFail;
}
#endif /* DDH_NAMETEST */
