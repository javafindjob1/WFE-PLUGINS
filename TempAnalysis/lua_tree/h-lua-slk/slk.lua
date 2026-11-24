--- cli 构造的数据
local hslk_cli_ids = {'stel','ANcl','AOcr','R000','BTtw','CTtr','DTes','ITw0','ITw1','ITw2','ITw3','LT00','LT01','LT03','LTbr','LTbs','LTw0','LTw1','LTw2','LTw3','Volc','XOkt','XTmp','YTce','YTcx','ZTg1','ZTtw','ZTw0','ZTw1','ZTw2','ZTw3','B000','B001','B002','B003','B004','B005','B006','B007','B008','B009','B00A','B00B','B00C','B00D','bush','bush','B00E','B00F','B00G','B00H','B00I','B00J','B00K','B00L','B00M','B00N','B00O','B00P','B00Q','B00R','B00S','B00T','B00U','B00V','B00W','B00X','B00Y','B00Z','B010','B011','Rock','Rock','B012','B013','B014','B015','B016','B017','B018','B019','B01A','B01B','B01C','B01D','B01E','B01F','B01G','B01H','B01I','B01J','B01K','B01L','B01M','B01N','B01O','B01P','B01Q','B01R','B01S','B01T','B01U','B01V','B01W','B01X','B01Y','B01Z','B020','B021','B022','B023','B024','B025','B026','B027','B028','B029','B02A','B02B','B02C','B02D','B02E','B02F','B02G','B02H','B02I','B02J','B02K','B02L','B02M','B02N','B02O','B02P','B02Q','B02R','B02S','B02T','B02U','B02V','B02W','B02X','B02Y','B02Z','B030','B031','B032','B033','B034','B035','B036','B037','B038','APms','ASpr','AZrf','BObo','BOth','BPca','BRrk','BRrp','CPbs','CPms','DOas','DObk','DOkb','DOtt','GOob','GSp0','IOpr','IOsl','IOsm','IOss','IRic','IWie','JSco','JScx','KOst','LOh1','LOhb','LOrb','LOsk','LOsm','LOsp','LOwp','LSin','LSwm','LWw0','NObc','NObo','NOfg','NOfp','NPth','NRwr','NWsd','OOsk','VOfs','XOcl','YObs','YOfn','YOfr','YOks','YOst','YPbs','YSc2','YSc3','YSc4','YSca','YScr','YScs','YSls','ZCv2','ZOls','ZOob','ZOrp','ZOsh','ZOss','ZOvr','ZPfw','ZPlp','ZPms','ZPtw','ZPvp','ZSas','ZWcl','ZWsf','ZWsw','D000','D001','D002','D003','D004','D005','D006','D007','D008','D009','D00A','D00B','D00C','D00D','D00E','D00F','D00G','D00H','D00I','D00J','D00K','D00L','D00M','D00N','D00O','D00P','D00Q','D00R','D00S','Rock','D00T','D00U','D00V','D00W','D00X','D00Y','D00Z','D010','D011','D012','D013','D014','D015','D016','D017','D018','D019','D01A','D01B','D01C','D01D','D01E','D01F','D01G','D01H','D01I','D01J','D01K','D01L','D01M','D01N','D01O','D01P','D01Q','D01R','D01S','D01T','D01U','D01V','D01W','D01X','D01Y','D01Z','D020','D021','D022','D023','D024','D025','D026','D027','D028','D029','D02A','D02B','D02C','D02D','D02E','D02F','D02G','D02H','D02I','D02J','D02K','D02L','D02M','D02N','D02O','D02P','D02Q','D02R','D02S','D02T','D02U','D02V','D02W','D02X','D02Y','D02Z','D030','D031','D032','D033','D034','D035','D036','D037','D038','D039','D03A','D03B','D03C','D03D','D03E','D03F','D03G','D03H','D03I','D03J','D03K','D03L','D03M','D03N','D03O','D03P','D03Q','D03R','D03S','D03T','D03U','D03V','D03W','D03X','Rock','D03Y','D03Z','D040','D041','Rock','D042','D043','D044','Rock','D045','D046','D047','D048','D049','D04A','D04B','D04C','D04D','D04E','D04F','D04G','D04H','D04I','D04J','D04K','D04L','D04M','D04N','D04O','D04P','D04Q','D04R','D04S','D04T','D04U','D04V','D04W','D04X','D04Y','D04Z','D050','D051','D052','D053','D054','D055','D056','D057','D058','D059','D05A','D05B','D05C','D05D','D05E','D05F','D05G','D05H','D05I','D05J','D05K','D05L','D05M','D05N','D05O','D05P','D05Q','D05R','D05S','D05T','D05U','D05V','D05W','D05X','D05Y','D05Z','D060','D061','D062','D063','D064','D065','D066','D067','D068','D069','D06A','D06B','D06C','D06D','D06E','D06F','D06G','D06H','D06I','D06J','D06K','D06L','D06M','D06N','D06O','D06P','D06Q','D06R','D06S','D06T','D06U','D06V','D06W','D06X','D06Y','D06Z','D070','D071','D072','D073','D074','D075','Rock','D076','D077','D078','D079','D07A','D07B','D07C','D07D','D07E','D07F','D07G','D07H','D07I','D07J','D07K','D07L','D07M','D07N','D07O','D07P','D07Q','D07R','D07S','D07T','D07U','D07V','D07W','D07X','D07Y','D07Z','D080','D081','D082','D083','D084','D085','D086','D087','Rock','D088','D089','D08A','D08B','D08C','D08D','D08E','D08F','D08G','D08H','D08I','D08J','D08K','D08L','D08M','D08N','D08O','D08P','D08Q','D08R','D08S','D08T','D08U','D08V','D08W','D08X','D08Y','D08Z','D090','D091','D092','D093','D094','D095','D096','D097','D098','D099','D09A','D09B','D09C','D09D','D09E','D09F','D09G','D09H','D09I','D09J','D09K','D09L','D09M','D09N','D09O','D09P','D09Q','D09R','D09S','D09T','D09U','D09V','D09W','D09X','D09Y','D09Z','D0A0','D0A1','D0A2','D0A3','D0A4','D0A5','D0A6','D0A7','D0A8','D0A9','D0AA','D0AB'}
HSLK_CLI_H_IDI = 1
HSLK_CLI_H_IDS = {'v000','v001','v002','K000','v003','v004','v005','K001','K002','K003','K004','K005','K006','K007','K008','K009','K00A','K00B','K00C','K00D','K00E','K00F','K00G','K00H','K00I','K00J','K00K','K00L','K00M','K00N','K00O','K00P','K00Q','K00R','K00S','K00T','K00U','K00V','K00W','K00X','K00Y','K00Z','K010','K011','K012','K013','K014','K015','K016','K017','K018','K019','K01A','K01B','K01C','K01D','K01E','K01F','K01G','K01H','K01I','K01J','K01K','K01L','K01M','K01N','K01O','K01P','K01Q','K01R','K01S','K01T','K01U','K01V','K01W','K01X','K01Y','K01Z','K020','K021','K022','K023','K024','K025','K026','K027','K028','K029','K02A','K02B','K02C','K02D','K02E','K02F','K02G','K02H','K02I','K02J','K02K','K02L','K02M','K02N','K02O','K02P','K02Q','K02R','K02S','K02T','K02U','K02V','K02W','K02X','K02Y','K02Z','K030','K031','K032','V006','K033','K034','K035','K036','K037','K038','K039','K03A','K03B','K03C','K03D','K03E','K03F','K03G','K03H','K03I','K03J','K03K','V007','K03L','K03M','K03N','K03O','K03P','K03Q','K03R','K03S','K03T','K03U','K03V','K03W','K03X','K03Y','K03Z','K040','K041','K042','V008','K043','K044','K045','K046','K047','K048','K049','K04A','K04B','K04C','K04D','K04E','K04F','K04G','K04H','K04I','K04J','K04K','K04L','V009','K04M','K04N','K04O','K04P','K04Q','K04R','K04S','K04T','K04U','K04V','K04W','K04X','I001','I002','I003','I004','I005','I006','I007','I008','I009','I00A','I00B','I00C','I00D','I00E','I00F','I00H','I00I','I00J','I00K','I00L','I00M','I00N','I00U','I00V','I00W','I00X','I00Y','I00Z','I00O','I00P','I00Q','I00R','I00S','I00T','I010','I011','I012','I013','I014','I015','I016','I017','I018','I019','I01A','I01B','I01C','I01D','I01E','I01F','I01G','I01H','I01I','I01J','I01K','I01L','I01M','I01N','I01O','I01P','I01Q','I01R','I01S','I01T','I01U','I01V','I01W','I01X','I01Y','I01Z','I020','I021','I022','I023','I024','I025','I03V','I026','I027','I028','I029','I02A','I02B','I02C','I02D','I02E','I040','I02G','I02H','I02I','I02J','I02K','I02L','I02M','I02N','I02O','I02P','I02Q','I02R','I02S','I02T','I02U','I02V','I02W','I02X','I02Y','I02Z','I03A','I03B','I03C','I03D','I03E','I03F','I03G','I03H','I03I','I03J','I03K','I03L','I03U','I03M','I03N','I03O','I03P','I03Q','I03R','I03S','I03T','I03W','I03X','I03Y','I03Z','I041','I042','I043','I044','I045','I046','I047','I048','I049','I04A','I04B','I04C','I04D','I04E','I02F','I04G','I04H','I04I','I04J','I04K','I04L','I04M','I04N','I04O','I04P','I04Q','I04R','I04S','I04T','I04U','I04V','I04W','I04X','I04Y','I04Z','I051','I052','I053','I054','I055','I056','I057','I058','I059','I05A','I05B','I05C','I05D','I05E','I05F','I05G','I05H','I05I','I05J','I05K','I05L','I05M','I05N','I05O','I05P','I05Q','I05R','I05S','I05T','I05U','I05V','I05W','I05X','I05Y','I05Z','I060','I061','I062','I063','I064','I065','I066','I067','I068','I069','I06A','I06B','I06C','I06D','I06E','I06F','I06G','I06H','I06I','I06J','I06K','I06R','I06S','I06T','I06U','I06V','I06W','I06X','I06Y','I06Z','I070','I071','I072','I073','I074','I075','I076','I077','I078','I079','I07A','I07B','I07C','I07D','I07E','I07F','I07G','I07H','I07I','I07J','I07K','I07L','I07M','I07N','I07O','I07P','I07Q','I07R','I07S','I07T','I07U','I07V','I07W','I07X','I07Y','I07Z','I080','I081','I082','I083','I084','I085','I086','I087','I088','I089','I08A','I08B','I08C','I08D','I08E','I08F','I08G','I08H','I08I','I08J','I08K','I08L','I08M','I08N','I08O','I08P','I08Q','I08R','I08S','I08T','I08U','I08V','I08W','I08X','I08Y','I08Z','I090','I091','I092','I093','I094','I095','I096','I097','I098','I099','I09A','I09B','I09C','I09D','I09E','I09F','I09G','I09H','I09I','I09J','I09K','I09L','I09M','I09N','I09O','I09P','I09Q','I09R','I09S','I09T','I09U','I09V','I09W','I09X','I09Y','I09Z','I0A1','I0A2','I0A3','I0A4','I0A5','I0A6','I0A7','I0A8','I0A9','I0AA','I0AB','I0AC','I0AD','I0AE','I0AF','I0AG','I0AH','I0AI','I0AJ','I0AK','I0AL','I0AM','I0AN','I0AO','I0AP','I0AQ','I0AR','I0AS','I0AT','I0AU','I0AV','I0AW','I0AX','I0AY','I0AZ','I0B1','I0B2','I0B3','I0B4','I0B5','I0B6','I0B7','I0B8','I0B9','I0BA','I0BB','I0BC','I0BD','I0BE','I0BF','I0BG','I0BH','I0BI','I0BJ','I0BK','I0BL','I0BM','I0BN','I0BO','I0BP','I0BQ','I0BR','I0BS','I0BT','I0BU','I0BV','I0BW','I0BX','I0BY','I0BZ','I0C1','I0C2','I0C3','I0C4','I0C5','I0C6','I0C7','I0C8','I0C9','I0CA','I0CB','I0CC','I0CD','I0CE','I0CF','I0CG','I0CH','I0CI','I0CJ','I0CK','I0CL','I0CM','I0CN','I0CO','I0CP','I0CQ','I0CR','I0CS','I0CT','I0CU','I0CV','I0CW','I0CX','I0CY','I0CZ','I0D1','I0D2','I0D3','I0D4','I0D5','I0D6','I0D7','I0D8','I0D9','I0DA','I0DB','I0DC','I0DD','I0DE','I0DF','I0DG','I0DH','I0DI','I0DJ','I0DK','I0DL','I0DM','I0DN','I0DO','I0DP','I0DQ','I0DR','I0DS','I0DT','I0DU','I0DV','I0DW','I0DX','I0DY','I0DZ','I0E1','I0E2','I0E3','I0E4','I0E5','I0E6','I0E7','I0E8','I0E9','I0EA','I0EB','I0EC','I0ED','I0EF','I0EG','I0EH','I0EI','I0EJ','I0EK','I0EL','I0EM','I0EN','I0EO','I0EP','I0EQ','I0ER','I0ES','I0ET','I0EU','I0EV','I0EW','I0EX','I0EY','I0EZ','I0F0','I0F1','I0F2','I0F3','I0F4','I0F5','I0F6','I0F7','I0F8','I0F9','I0FA','I0FB','I0FC','I0FD','I0FE','I0FF','I0FG','I0FH','I0FI','I0FJ','I0FK','I0FL','I0FM','I0FN','I0FO','I0FP','I0FQ','I0FR','I0FS','I0FT','I0FU','I0FV','I0FW','I0FX','I0FY','I0FZ','I0G0','I0G1','I0G2','I0G3','I0G4','I0G5','I0G6','I0G7','I0G8','I0G9','I0GA','I0GB','I0GC','I0GD','I0GE','I0GF','I0GG','I0GH','I0GI','I0GJ','I0GK','I0GL','I0GM','I0GN','I0GO','I0GP','I0GQ','I0GR','I0GS','I0GT','I0GU','I0GV','I0GW','I0GX','I0GY','I0GZ','I0H0','I0H1','I0H2','I0H3','I0H4','I0H5','I0H6','I0H7','I0H8','I0H9','I0HA','I0HB','I0HC','I0HD','I0HE','I0HF','I0HG','I0HH','I0HI','I0HJ','I0HK','I0HL','I0HM','I0HN','I0HO','I0HP','I0HQ','I0HR','I0HS','I0HT','I0HU','I0HV','I0HW','I0HX','I0HY','I0HZ','I0I0','I0I1','I0I2','K04Y','K04Z','K050','K051','K052','K053','K054','K055','K056','K057','K058','K059','K05A','K05B','K05C','K05D','K05E','K05F','V00A','K05G','v00b','I100','I105','v00c','I101','I102','I106','I000','v00d','v00e','v00f','I103','v00g','v00h','v00i','v00j','v00k','I104','v00l','v00m','v00n','v00o','v00p','v00q','v00r','v00s','v00t','v00u','v00v','v00w','v00x','v00y','V00Z','v010','v011','v012','v013','v014','v015','v016','v017','v018','v019','v01a','v01b','v01c','v01d','v01e','v01f','v01g','v01h','v01i','v01j','v01k','v01l','v01m','v01n','v01o','v01p','v01q','v01r','v01s','v01t','v01u','v01v','v01w','v01x','v01y','v01z','K05H','K05I','K05J','K05K','K05L','K05M','K05N','K05O','K05P','K05Q','K05R','K05S','K05T','K05U','K05V','K05W','K05X','K05Y','V020','K05Z','K060','K061','K062','K063','K064','K065','K066','K067','K068','K069','K06A','K06B','K06C','K06D','K06E','K06F','K06G','K06H','K06I','K06J','K06K','K06L','K06M','K06N','K06O','K06P','K06Q','K06R','K06S','V021','K06T','K06U','K06V','K06W','v022','K06X','K06Y','K06Z','K070','K071','K072','K073','K074','K075','K076','K077','K078','K079','K07A','K07B','K07C','K07D','K07E','V023','K07F','K07G','K07H','K07I','K07J','K07K','K07L','K07M','K07N','K07O','K07P','K07Q','K07R','K07S','K07T','K07U','K07V','K07W','V024','K07X','v025','v026','v027','v028','v029','v02a','v02b','v02c','v02d','v02e','v02f','v02g','v02h','v02i','v02j','v02k','v02l','v02m','v02n','v02o','v02p','v02q','v02r','v02s','v02t','v02u','v02v','v02w','v02x','v02y','v02z','v030','v031','v032','v033','v034','v035','v036','v037','v038','v039','v03a','v03b','v03c','v03d','v03e','v03f','v03g','v03h','v03i','v03j','v03k','v03l','v03m','v03n','v03o','v03p','v03q','v03r','v03s','v03t','v03u','v03v','v03w','v03x','v03y','v03z','v040','v041','v042','v043','v044','v045','v046','v047','v048','v049','v04a','v04b','v04c','v04d','v04e','v04f','v04g','v04h','v04i','v04j','v04k','v04l','v04m','v04n','v04o','v04p','v04q','v04r','v04s','v04t','v04u','v04v','v04w','v04x','v04y','v04z','v050','v051','v052','v053','v054','v055','v056','v057','v058','v059','v05a','v05b','v05c','v05d','v05e','v05f','v05g','v05h','v05i','v05j','v05k','v05l','v05m','v05n','v05o','v05p','v05q','v05r','v05s','v05t','v05u','v05v','v05w','v05x','v05y','v05z','v060','v061','v062','v063','v064','v065','v066','v067','v068','v069','v06a','v06b','v06c','v06d','v06e','v06f','v06g','v06h','v06i','v06j','v06k','v06l','v06m','v06n','v06o','v06p','v06q','v06r','v06s','v06t','v06u','v06v','v06w','v06x','v06y','v06z','v070','v071','v072','v073','v074','v075','K07Y','K07Z','K080','K081','K082','K083','K084','K085','K086','K087','K088','K089','K08A','K08B','K08C','K08D','K08E','K08F','V076'}
HSLK_CLI_DATA = {}
HSLK_I2V = {}
HSLK_N2V = {}
HSLK_N2I = {}
HSLK_ICD = {}
HSLK_CLASS_IDS = {}
HSLK_TYPE_IDS = {}
HSLK_MISC = {}
HSLK_TAOZHUANG = {}

-- 用于反向补充slk优化造成的数据丢失问题
-- 如你遇到slk优化后（dist后）地图忽然报错问题，则有可能是优化丢失
HSLK_FIX = {
    unit = {"sight", "nsight"} -- 视野设“0”会被w2l优化干掉
}

function hslk_init()
    -- 载入平衡常数数据
    HSLK_MISC = JassSlk.misc
    -- 处理物编数据
    hslk_cli_ids = table.merge(hslk_cli_ids, HSLK_CLI_H_IDS)
    if (#hslk_cli_ids > 0) then
        for _, id in ipairs(hslk_cli_ids) do
            HSLK_I2V[id] = HSLK_CLI_DATA[id] or {}
            HSLK_I2V[id]._type = HSLK_I2V[id]._type or "slk"
            if (JassSlk.item[id] ~= nil) then
                HSLK_I2V[id]._class = HSLK_I2V[id]._class or "item"
                HSLK_I2V[id].slk = JassSlk.item[id]
                if (HSLK_I2V[id].slk.cooldownID) then
                    HSLK_ICD[HSLK_I2V[id].slk.cooldownID] = HSLK_I2V[id]._id
                end
            elseif (JassSlk.unit[id] ~= nil) then
                HSLK_I2V[id]._class = HSLK_I2V[id]._class or "unit"
                HSLK_I2V[id].slk = setmetatable({}, {__index = JassSlk.unit[id]})
                for _, f in ipairs(HSLK_FIX.unit) do
                    if (HSLK_I2V[id].slk[f] == nil) then
                        HSLK_I2V[id].slk[f] = HSLK_I2V[id][f] or 0
                    end
                end
            elseif (JassSlk.ability[id] ~= nil) then
                HSLK_I2V[id]._class = HSLK_I2V[id]._class or "ability"
                HSLK_I2V[id].slk = JassSlk.ability[id]
            elseif (JassSlk.buff[id] ~= nil) then
                HSLK_I2V[id]._class = HSLK_I2V[id]._class or "buff"
                HSLK_I2V[id].slk = JassSlk.buff[id]
            elseif (JassSlk.upgrade[id] ~= nil) then
                HSLK_I2V[id]._class = HSLK_I2V[id]._class or "upgrade"
                HSLK_I2V[id].slk = JassSlk.upgrade[id]
            elseif (JassSlk.destructable[id] ~= nil) then
                HSLK_I2V[id]._class = HSLK_I2V[id]._class or "destructable"
                HSLK_I2V[id].slk = JassSlk.destructable[id]
            elseif (JassSlk.doodad[id] ~= nil) then
                HSLK_I2V[id]._class = HSLK_I2V[id]._class or "doodad"
                HSLK_I2V[id].slk = JassSlk.doodad[id]
            end
            -- 处理_class
            if (HSLK_I2V[id]._class) then
                if (HSLK_CLASS_IDS[HSLK_I2V[id]._class] == nil) then
                    HSLK_CLASS_IDS[HSLK_I2V[id]._class] = {}
                end
                table.insert(HSLK_CLASS_IDS[HSLK_I2V[id]._class], id)
            end
            -- 处理_type
            if (HSLK_I2V[id]._type) then
                if (HSLK_TYPE_IDS[HSLK_I2V[id]._type] == nil) then
                    HSLK_TYPE_IDS[HSLK_I2V[id]._type] = {}
                end
                table.insert(HSLK_TYPE_IDS[HSLK_I2V[id]._type], id)
            end
            -- 处理N2V
            if (HSLK_I2V[id].slk) then
                local n
                if (HSLK_I2V[id]._class == "buff") then
                    n = HSLK_I2V[id].slk.EditorName
                else
                    n = HSLK_I2V[id].slk.Name
                end
                if (n ~= nil) then
                    if (HSLK_N2V[n] == nil) then
                        HSLK_N2I[n] = {}
                        HSLK_N2V[n] = {}
                    end
                    table.insert(HSLK_N2I[n], id)
                    table.insert(HSLK_N2V[n], HSLK_I2V[id])
                end
            end
            -- 处理套装
            if (HSLK_I2V[id] ~= nil and HSLK_I2V[id].taozhuang ~= nil) then
                for _, setName in ipairs(HSLK_I2V[id].taozhuang) do
                    if HSLK_TAOZHUANG[setName] == nil then
                        HSLK_TAOZHUANG[setName] = {}
                    end
                    if (HSLK_I2V[id].slk.Name == nil) then
                        err("name is nil")
                    end
                    table.insert(HSLK_TAOZHUANG[setName], HSLK_I2V[id].slk.Name)
                end
            end
        end
    end
    hslk_cli_ids = nil
    HL_ID_INIT()
end

local function hslk_cli_set(_v)
    _v._id = HSLK_CLI_H_IDS[HSLK_CLI_H_IDI]
    HSLK_CLI_DATA[_v._id] = _v
    HSLK_CLI_H_IDI = HSLK_CLI_H_IDI + 1
    return _v
end

---@param _v note_Ability
---@return {_id}
function hslk_ability(_v)
    return hslk_cli_set(F6V_A(_v))
end

---@param _v note_Ability
---@return {_id}
function hslk_ability_empty(_v)
    _v._parent = "Aamk"
    _v._type = "empty"
    return hslk_cli_set(F6V_A(_v))
end

---@param _v note_Unit
---@return {_id}
function hslk_unit(_v)
    return hslk_cli_set(F6V_U(_v))
end

-- 简易英雄
---@param _v note_Unit
---@return {_id}
function hslk_hero(_v)
    if _v._parent == nil then
        _v._parent = "Hpal"
    end
    _v._type = "hero"
    return hslk_cli_set(F6V_U(_v))
end

---@param _v note_Item
---@return {_id}
function hslk_item(_v)
    _v = F6V_I(_v)
    return hslk_cli_set(_v)
end

---@param _v note_Buff
---@return {_id}
function hslk_buff(_v)
    return hslk_cli_set(F6V_B(_v))
end

---@param _v note_Upgrade
---@return {_id}
function hslk_upgrade(_v)
    return hslk_cli_set(F6V_UP(_v))
end

---@param _v note_Destructable
---@return {_id}
function hslk_destructable(_v)
    return hslk_cli_set(F6V_DE(_v))
end

---@param _v note_Doodad
---@return {_id}
function hslk_doodad(_v)
    return hslk_cli_set(F6V_DO(_v))
end
