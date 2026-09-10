QuisquisLingo - Windows নির্দেশিকা
=================================

QuisquisLingo ভাষাশিক্ষার্থী ও কোর্স নির্মাতাদের জন্য একটি ভাষা শেখার
অ্যাপ্লিকেশন। এতে বিন্যস্ত পাঠ, ইন্টার‌্যাক্টিভ অনুশীলন, অডিও কার্যক্রম ও
পুনরালোচনার সরঞ্জামের পাশাপাশি ভাষার কোর্স তৈরি ও সম্পাদনার সরঞ্জামও রয়েছে।

যাঁরা একটি ভাষা শিখতে চান এবং যেসব লেখক, শিক্ষক বা অন্য ব্যবহারকারী নিজেদের
কোর্স তৈরি করতে চান, উভয়ের জন্যই এটি তৈরি করা হয়েছে।

QuisquisLingo কীভাবে কাজ করে তার দ্রুত চিত্রভিত্তিক পরিচিতির জন্য অ্যাপ্লিকেশন
প্যাকেজে অন্তর্ভুক্ত QQL infographic.png দেখুন।

QuisquisLingo চালু করতে QuisquisLingo.exe চালান।

প্যাকেজ ব্যবহার
---------------

এই প্যাকেজে QQL অ্যাপ্লিকেশন রয়েছে। চালু করার আগে সম্পূর্ণ ZIP আর্কাইভটি
extract করুন এবং দেওয়া সব ফাইল ও data ফোল্ডার একসঙ্গে রাখুন। আলাদা EXE বা DLL
ফাইল বিতরণ, সরানো, মুছে ফেলা বা নতুন নাম দেওয়া উচিত নয়।

চালুর আগের পরীক্ষা
------------------

চালু হওয়ার আগে QuisquisLingo প্রয়োজনীয় প্যাকেজ ফাইল, Windows-এর সামঞ্জস্য এবং
Media Foundation পরীক্ষা করে। এসব পরীক্ষা কখনো সফটওয়্যার download বা install
করে না, administrator অনুমতি চায় না, registry বদলায় না বা Windows পরিবর্তন
করে না।

সমস্যাটি উপেক্ষা করে এগোনো সম্ভব হলে Continue anyway ও Cancel-সহ একটি বার্তা
দেখানো হয়। Continue anyway QQL চালু করার চেষ্টা করে; Cancel এটি বন্ধ করে। কোনো
অপরিহার্য program file না থাকলে বার্তায় Close দেওয়া হয়, কারণ প্যাকেজটি আবার
download করে সম্পূর্ণ extract করতে হবে।

Wine সহায়তা Experimental। Wine-এ Media Foundation না থাকলে চালু করা ব্যর্থ
হতে পারে অথবা audio ও media সুবিধা কাজ নাও করতে পারে।

MICROSOFT VISUAL C++ RUNTIME
----------------------------

সম্পূর্ণ প্যাকেজে Microsoft Visual C++ x64-এর এই runtime ফাইলগুলো রয়েছে:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

কোনোটি না থাকলে সম্পূর্ণ QuisquisLingo Windows প্যাকেজটি আবার download করে
সম্পূর্ণ extract করুন। Runtime installer শুধু Microsoft-এর সরকারি উৎস থেকে নিন
এবং তৃতীয় পক্ষের website থেকে আলাদা DLL file কখনো download করবেন না।

Microsoft-এর সরকারি তথ্য:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N edition-এ audio ও media কাজের জন্য Microsoft Media Feature Pack
প্রয়োজন হতে পারে। Media Feature Pack সাধারণত Windows Optional Features-এ
পাওয়া যায়। Windows N-এর কিছু সংস্করণে এটি Optional Features-এ নাও থাকতে পারে।
সে ক্ষেত্রে আপনার Windows সংস্করণের উপযুক্ত Media Feature Pack Microsoft-এর
website থেকে download করুন।

Media Feature Pack install করার পর Windows restart করুন। QuisquisLingo এটি
স্বয়ংক্রিয়ভাবে download বা install করে না এবং system settings পরিবর্তন করে না।

TEXT-TO-SPEECH
--------------

QuisquisLingo Windows-এ install করা speech voice ব্যবহার করে। উপলভ্য ভাষা ও
voice কম্পিউটারে install করা Windows language ও voice component-এর ওপর নির্ভর
করে। সামঞ্জস্যপূর্ণ voice না থাকলে Windows settings থেকে উপযুক্ত component
install করুন।

Audio Settings > Test Voice শুধু আপনার লেখা text উচ্চারণ করে এবং নির্বাচিত
course-এ নির্ধারিত voice language ব্যবহার করে।

LOG ও DIAGNOSTICS
-----------------

প্রধান crash log এখানে থাকে:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

চালুর আগের পরীক্ষার log এখানে থাকে:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug-এ diagnostic option রয়েছে। Log স্থানীয় computer-এই থাকে এবং
স্বয়ংক্রিয়ভাবে upload হয় না।

সমস্যা সমাধান
-------------

1. সম্পূর্ণ ZIP archive পুরোপুরি extract করুন।
2. Extract করা package থেকে QuisquisLingo.exe চালান।
3. Runtime DLL না থাকার বার্তা এলে সরকারি Microsoft runtime installer বিবেচনা
   করার আগে সম্পূর্ণ package আবার download করে extract করুন।
4. Media Feature Pack প্রয়োজন হলে ওপরের নির্দেশনা অনুসরণ করুন এবং install-এর
   পরে Windows restart করুন।
5. QQL তবু চালু না হলে সহায়তার জন্য সম্পূর্ণ error message ও পাওয়া log file
   সংরক্ষণ করুন।
