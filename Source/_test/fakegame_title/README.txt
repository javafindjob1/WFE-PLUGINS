fakegame_title/ -- TEMP fake-game fixture variant used ONLY by verify_title_search.ps1
=================================================================================

Why it exists
-------------
The stock _test/fakegame fixture answers
  DzAPI_UnitType_GetUnitTypeDataString(..., "Propernames") -> string id 0x6000 -> "ProperNameTest"
for every unit. ddh prefers Propernames, so with the stock fixture every unit gets the SAME title,
which cannot demonstrate a per-hero "search by title" filter.

This variant is a byte-identical copy of the stock fixture sources except one line:

  fake_game_dll.cpp:  if (strcmp(field, "Propernames") == 0) return 0x6000u;
                   -> if (strcmp(field, "Propernames") == 0) return 0;

Returning 0 makes ddh fall back to GetHeroProperName, which the fake already implements per unit
(Hpal -> 乌瑟尔, Hmkg -> 穆拉丁). That is exactly the path a real game uses when a map has no
Propernames data, and it lets verify_title_search.ps1 check that the hero TITLE filters the
death-settlement table and the damage-event table.

Nothing in the application, in ddh.dll or in publish\ is touched. The variant is a test harness
artifact only; the stock fakegame/ fixture is left untouched.

How it was built
----------------
  copy _test/fakegame/{build_fake.ps1,fake_war3.cpp,fake_game_dll.cpp} to this folder
  patch the one line above
  powershell -File .\build_fake.ps1        (MSVC x86 + Windows SDK, same as the stock fixture)
