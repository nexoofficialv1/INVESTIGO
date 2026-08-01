# INVESTIGO v1.6.4 — CD Data Flow & Preview Repair

এই আপডেটে Smart Investigation Assistant থেকে তৈরি draft আর generic paragraph হিসেবে CD-তে যাবে না। প্রতিটি approved action-এর সময়, স্থান, synopsis এবং proceedings আলাদা CD row হিসেবে সংরক্ষিত হবে।

## মূল পরিবর্তন

- Pending CD action model-এ `entryTime`, `placeOfEntry`, `synopsis` যোগ করা হয়েছে।
- পুরনো save data backward-compatible থাকবে।
- Investigation Assistant approved draft-এর সময়/স্থান/synopsis সংরক্ষণ করবে।
- CD Builder pending action-গুলো closing entry-এর আগে আলাদা official CD row হিসেবে বসাবে।
- সব entry পুনরায় Roman serial-এ সাজানো হবে।
- PDF renderer আর চারটি column আলাদা আলাদা concatenated text হিসেবে দেখাবে না; প্রতিটি entry একই row-height অনুযায়ী render হবে।
- DOC export-এও প্রতিটি CD entry আলাদা row হিসেবে যাবে।
- Official vertical grid বজায় থাকবে; individual entries-এর মধ্যে horizontal separator যোগ করা হয়নি।
- Version: `1.6.4+164`.

## পরীক্ষার মূল ধাপ

1. Investigation Assistant থেকে PO Visit, Witness Statement এবং Sketch Map draft approve করুন।
2. New CD খুলে pending তিনটি action select করে Generate CD দিন।
3. CD Editor-এ Entry rows দেখা যাচ্ছে কি না যাচাই করুন।
4. Preview PDF এবং DOC-এ একই সময়/স্থান/synopsis/proceedings এসেছে কি না দেখুন।
5. Draft save করে app বন্ধ/খুলে পুনরায় preview পরীক্ষা করুন।
