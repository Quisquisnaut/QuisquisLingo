QuisquisLingo - מדריך עבור Windows
=================================

QuisquisLingo הוא יישום ללימוד שפות עבור לומדים ויוצרי קורסים. הוא משלב שיעורים
מובנים, תרגילים אינטראקטיביים, פעילויות שמע וכלי חזרה, ובמקביל מספק כלים ליצירה
ולעריכה של קורסי שפה.

הוא מיועד הן לאנשים שרוצים ללמוד שפה והן למחברים, למורים ולמשתמשים אחרים שרוצים
לבנות קורסים משלהם.

לקבלת סקירה חזותית מהירה על אופן הפעולה של QuisquisLingo, עיינו בקובץ
QQL infographic.png, המצורף לחבילת היישום.

כדי להפעיל את QuisquisLingo, הריצו את QuisquisLingo.exe.

שימוש בחבילה
------------

חבילה זו מכילה את יישום QQL. חלצו את ארכיון ה-ZIP במלואו לפני ההפעלה, והשאירו
יחד את כל הקבצים שסופקו ואת התיקייה data. אין להפיץ, להעביר, למחוק או לשנות שם
של קובצי EXE או DLL בודדים.

בדיקות בעת ההפעלה
-----------------

לפני ההפעלה QuisquisLingo בודק את קובצי החבילה הנדרשים, את התאימות ל-Windows
ואת Media Foundation. בדיקות אלה לעולם אינן מורידות או מתקינות תוכנה, אינן
מבקשות הרשאות מנהל, אינן משנות את registry ואינן משנות את Windows.

כאשר אפשר להמשיך למרות בעיה, מוצגת הודעה אחת עם Continue anyway ו-Cancel.
Continue anyway מנסה להפעיל את QQL;‏ Cancel סוגר אותו. אם חסר קובץ תוכנה חיוני,
ההודעה מציעה Close מפני שיש להוריד שוב את החבילה ולחלץ אותה במלואה.

התמיכה ב-Wine היא Experimental. העדר Media Foundation תחת Wine עלול למנוע את
ההפעלה או את פעולת תכונות השמע והמדיה.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

החבילה המלאה כוללת את קובצי runtime הבאים של Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

אם אחד מהם חסר, הורידו שוב את חבילת QuisquisLingo המלאה עבור Windows וחלצו
אותה במלואה. עבור runtime installer השתמשו רק במקורות רשמיים של Microsoft,
ולעולם אל תורידו קובצי DLL בודדים מאתרים של צד שלישי.

מידע רשמי של Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

מהדורות Windows N עשויות לדרוש את Microsoft Media Feature Pack עבור תפקודי שמע
ומדיה. Media Feature Pack זמין בדרך כלל תחת Windows Optional Features. בגרסאות
מסוימות של Windows N ייתכן ש-Media Feature Pack לא יהיה זמין ב-Optional Features.
במקרה כזה, הורידו מאתר Microsoft את Media Feature Pack המתאים לגרסת Windows
שברשותכם.

הפעילו מחדש את Windows לאחר התקנת Media Feature Pack. ‏QuisquisLingo אינו מוריד
או מתקין אותו באופן אוטומטי ואינו משנה את הגדרות המערכת.

המרת טקסט לדיבור
----------------

QuisquisLingo משתמש בקולות הדיבור המותקנים ב-Windows. השפות והקולות הזמינים
תלויים ברכיבי השפה והקול של Windows שמותקנים במחשב. אם אין קול תואם, התקינו את
הרכיב המתאים דרך הגדרות Windows.

Audio Settings > Test Voice מקריא רק את הטקסט שהזנתם ומשתמש בשפת הקול שהוגדרה
בקורס שנבחר.

יומנים ואבחון
-------------

ה-crash log הראשי נשמר כאן:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

ה-log של בדיקת ההפעלה נשמר כאן:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug מציג אפשרויות אבחון. קובצי ה-log נשארים במחשב המקומי ואינם
מועלים באופן אוטומטי.

פתרון בעיות
-----------

1. חלצו במלואו את כל ארכיון ה-ZIP.
2. הריצו את QuisquisLingo.exe מתוך החבילה שחולצה.
3. אם דווח שחסר runtime DLL, הורידו וחלצו שוב את החבילה המלאה לפני שתשקלו
   runtime installer רשמי של Microsoft.
4. אם נדרש Media Feature Pack, פעלו לפי ההנחיות לעיל והפעילו מחדש את Windows
   לאחר ההתקנה.
5. אם QQL עדיין אינו מופעל, שמרו את הודעת השגיאה המלאה ואת קובצי ה-log הזמינים
   לצורך תמיכה.
