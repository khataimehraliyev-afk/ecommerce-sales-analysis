/*S1 Hər kateqoriya üzrə ümumi satış və orta sifariş məbləği:
Bu skript PRODUCTS və ORDER_ITEMS cədvəllərini birləşdirir (JOIN)
və hər kateqoriya üzrə:
1. Ümumi satış məbləğini
2. Orta sifariş məbləğini hesablamaq üçündür.
Qeyd: Hər kateqoriya üzrə orta sifariş məbləğini tapmaq üçün "COUNT(DISTINCT O.ORDER_ID)"
istifadə edilib.Çünki "ORDERS_İTEMS" cədvəlində bir "ORDER_İD"-ə bağlı bir neçə "PRODUCT_İD" var.
*/
---1(sadə)
SELECT 
    P.CATEGORY,
    ROUND(SUM(O.TOTAL_AMOUNT),0) AS total_amount,
    ROUND(SUM(O.TOTAL_AMOUNT) / COUNT(DISTINCT O.ORDER_ID), 0) AS avg_order_amount
FROM PRODUCTS P
LEFT JOIN ORDER_ITEMS O 
    ON P.PRODUCT_ID = O.PRODUCT_ID
GROUP BY P.CATEGORY;

---2(izahlı)
SELECT 
    -- Məhsul kateqoriyasını götür (Electronics, Home, Books...)
    P.CATEGORY,
    
    -- Hər kateqoriyanın ümumi satışını hesabla, 0 onluğa yuvarlaqlaşdır
    ROUND(SUM(O.TOTAL_AMOUNT), 0) AS TOTAL_AMOUNT,
    
    -- Hər kateqoriyanın orta sifariş məbləğini hesabla:
    -- Ümumi satış / Unikal sifariş sayı
    ROUND(SUM(O.TOTAL_AMOUNT) / COUNT(DISTINCT O.ORDER_ID), 0) AS AVG_ORDER_AMOUNT

FROM PRODUCTS P

    -- PRODUCTS və ORDER_ITEMS-i məhsul ID-si üzrə birləşdir
    -- LEFT JOIN — məhsul satılmasa belə göstər (INNER JOIN-dən fərqi)
    LEFT JOIN ORDER_ITEMS O
        ON P.PRODUCT_ID = O.PRODUCT_ID

-- Hər kateqoriya üçün ayrıca hesabla
GROUP BY P.CATEGORY

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* S2- Aylıq satış trendi (2 il üzrə)
Bu skript 2 il ərzində aylıq cəm satışı tapır.
*/  
---1(sadə)
Select
        TO_CHAR(O.ORDER_DATE, 'YYYY-MM') AS YEAR_MONTH,
        ROUND(SUM(I.TOTAL_AMOUNT), 0) AS TOTAL_SALES
 FROM ORDERS O
 INNER JOIN ORDER_ITEMS I
        ON O.ORDER_ID = I.ORDER_ID

 GROUP BY TO_CHAR(O.ORDER_DATE, 'YYYY-MM')
 ORDER BY YEAR_MONTH


---2(izahlı)
SELECT 
    -- ORDER_DATE-i 'YYYY-MM' formatına çevir (məs: 2023-01)
    TO_CHAR(O.ORDER_DATE, 'YYYY-MM') AS YEAR_MONTH,
    
    -- Həmin aydakı ümumi satışı hesabla, 0 onluğa yuvarlaqlaşdır
    ROUND(SUM(I.TOTAL_AMOUNT), 0) AS TOTAL_SALES

FROM ORDERS O

    -- ORDERS və ORDER_ITEMS cədvəllərini ORDER_ID üzrə birləşdir
    INNER JOIN ORDER_ITEMS I
        ON O.ORDER_ID = I.ORDER_ID

-- Hər ay üçün ayrıca cəmlə
GROUP BY TO_CHAR(O.ORDER_DATE, 'YYYY-MM')

-- Ayları xronoloji ardıcıllıqla sırala
ORDER BY YEAR_MONTH


-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* S3-Top 10 müştəri (satış həcminə görə) Bu skriptdə
satış həcminə görə TOP 10 müştərini tapmaq üçün 3 cədvəl("CUSTOMER_NAME" üçün- "CUSTOMERS"
                                                         "ORDER_İD" üçün-      "ORDERS"
                                                         "TOTAL_AMOUNT" üçün-  "ORDER_İTEMS")
join vasitəsilə birləşdirilib, müştəri adına görə qruplaşdırılıb və order_by
vasitəsilə satış həcminə görə coxdan aza sıralanıb sonra isə "fetch" vasitəsilə ilk 10 müştəri
göstərilib.
*/
---1(sadə)
SELECT C.CUSTOMER_NAME, SUM(I.TOTAL_AMOUNT) AS SUM_AMOUNT
FROM CUSTOMERS C
                INNER JOIN ORDERS O
                ON C.CUSTOMER_ID = O.CUSTOMER_ID
        
                    INNER JOIN ORDER_ITEMS I
                    ON O.ORDER_ID = I.ORDER_ID
    
        GROUP BY C.CUSTOMER_NAME
        ORDER BY SUM_AMOUNT DESC
        FETCH FIRST 10 ROWS ONLY
---2(izahlı)
SELECT 
    -- Müştəri adını götür
    C.CUSTOMER_NAME,
    
    -- Hər müştərinin ümumi xərclədiyini hesabla
    SUM(I.TOTAL_AMOUNT) AS SUM_AMOUNT

FROM CUSTOMERS C

    -- CUSTOMERS və ORDERS-i müştəri ID-si üzrə birləşdir
    INNER JOIN ORDERS O
        ON C.CUSTOMER_ID = O.CUSTOMER_ID

    -- ORDERS və ORDER_ITEMS-i sifariş ID-si üzrə birləşdir
    INNER JOIN ORDER_ITEMS I
        ON O.ORDER_ID = I.ORDER_ID

-- Hər müştəri üçün ayrıca cəmlə
GROUP BY C.CUSTOMER_NAME

-- Ən çox xərcləyəndən ən aza doğru sırala
ORDER BY SUM_AMOUNT DESC

-- Yalnız ilk 10 müştərini göstər
FETCH FIRST 10 ROWS ONLY

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* S4-Region və kateqoriya üzrə cross-tab analiz.
Bu skriptdə Case when və Group by vasitəsilə cross-tab yaradıb hər region 
üzrə məhsul kateqoriyalarına görə cəm satışı göstərmisəm.JOİN vasitəsilə 4 cədvəl
uygun sutunlar vasitəsilə birləşdirilib.
*/
--1(sadə)
select C.REGION,
SUM(CASE WHEN P.CATEGORY='Electronics' THEN I.TOTAL_AMOUNT ELSE 0 END) AS ELECTRONICS,
SUM(CASE WHEN P.CATEGORY='Clothing' THEN I.TOTAL_AMOUNT ELSE 0 END) AS CLOTHING,
SUM(CASE WHEN P.CATEGORY='Home' THEN I.TOTAL_AMOUNT ELSE 0 END) AS HOME,
SUM(CASE WHEN P.CATEGORY='Books' THEN I.TOTAL_AMOUNT ELSE 0 END) AS BOOKS,
SUM(CASE WHEN P.CATEGORY='Sports' THEN I.TOTAL_AMOUNT ELSE 0 END) AS SPORTS
FROM CUSTOMERS C
INNER JOIN ORDERS O ON C.CUSTOMER_ID=O.CUSTOMER_ID
INNER JOIN ORDER_ITEMS I ON O.ORDER_ID=I.ORDER_ID
INNER JOIN PRODUCTS P ON I.PRODUCT_ID=P.PRODUCT_ID
GROUP BY C.REGION

---2(izahlı)
SELECT 
    -- Regionu götür (Bakı, Gəncə, Şirvan...)
    C.REGION,
    
    -- Electronics kateqoriyasının satışını ayrıca sütunda göstər
    -- Əgər məhsul Electronics-dirsə məbləği götür, deyilsə 0 yaz
    SUM(CASE WHEN P.CATEGORY = 'Electronics' 
        THEN I.TOTAL_AMOUNT ELSE 0 END) AS ELECTRONICS,
    
    -- Clothing kateqoriyası üçün eyni əməliyyat
    SUM(CASE WHEN P.CATEGORY = 'Clothing'    
        THEN I.TOTAL_AMOUNT ELSE 0 END) AS CLOTHING,
    
    -- Home kateqoriyası üçün
    SUM(CASE WHEN P.CATEGORY = 'Home'        
        THEN I.TOTAL_AMOUNT ELSE 0 END) AS HOME,
    
    -- Books kateqoriyası üçün
    SUM(CASE WHEN P.CATEGORY = 'Books'       
        THEN I.TOTAL_AMOUNT ELSE 0 END) AS BOOKS,
    
    -- Sports kateqoriyası üçün
    SUM(CASE WHEN P.CATEGORY = 'Sports'      
        THEN I.TOTAL_AMOUNT ELSE 0 END) AS SPORTS

FROM CUSTOMERS C
    -- CUSTOMERS → ORDERS: müştəri ID-si üzrə birləşdir
    INNER JOIN ORDERS O 
        ON C.CUSTOMER_ID = O.CUSTOMER_ID
    -- ORDERS → ORDER_ITEMS: sifariş ID-si üzrə birləşdir
    INNER JOIN ORDER_ITEMS I 
        ON O.ORDER_ID = I.ORDER_ID
    -- ORDER_ITEMS → PRODUCTS: məhsul ID-si üzrə birləşdir
    INNER JOIN PRODUCTS P 
        ON I.PRODUCT_ID = P.PRODUCT_ID

-- Hər region üçün ayrıca hesabla
GROUP BY C.REGION

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* S5-Müştəri seqmenti üzrə orta sifariş dəyəri
*/  
---1(sadə)
SELECT
    C.SEGMENT, ROUND ( AVG ( I.TOTAL_AMOUNT ), 0 )as avg_total_amount FROM CUSTOMERS C
               LEFT JOIN ORDERS O      ON C.CUSTOMER_ID=O.CUSTOMER_ID
               LEFT JOIN ORDER_ITEMS I ON O.ORDER_ID=I.ORDER_ID
GROUP BY C.SEGMENT;

---2(izahlı)
SELECT
    -- Müştəri seqmentini götür (Consumer, Corporate, Home Office)
    C.SEGMENT,
    
    -- Hər seqmentin orta sifariş məbləğini hesabla
    -- AVG — orta dəyər, ROUND — 0 onluğa yuvarlaqlaşdır
    ROUND(AVG(I.TOTAL_AMOUNT), 0) AS AVG_TOTAL_AMOUNT

FROM CUSTOMERS C

    -- CUSTOMERS → ORDERS: müştəri ID-si üzrə birləşdir
    LEFT JOIN ORDERS O
        ON C.CUSTOMER_ID = O.CUSTOMER_ID

    -- ORDERS → ORDER_ITEMS: sifariş ID-si üzrə birləşdir
    LEFT JOIN ORDER_ITEMS I
        ON O.ORDER_ID = I.ORDER_ID

-- Hər seqment üçün ayrıca hesabla
GROUP BY C.SEGMENT

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
                
/* S6-Hər kateqoriyada ən çox satılan məhsul
Bu skriptdə hər kateqoriya və hər product name üzrə satışların cəmi tapılıb sonra isə window function(ROW_NUMBER) vasitəsilə 
hər kateqoriya üzrə product satışları azdan çoxa sıralanıb.Sonda isə where vasitəsilə kateqoriya üzrə ən çox satış olan product filtir
olunaraq tapılıb.
*/

---1(sadə)
select * FROM ( SELECT 
                P.CATEGORY,P.PRODUCT_NAME, sum(quantity) AS SUM_QUANTITY,
                 ROW_NUMBER() OVER (PARTITION BY P.CATEGORY ORDER BY sum(quantity) DESC) AS RN  
                
                from ORDER_ITEMS O LEFT JOIN PRODUCTS P ON  O.PRODUCT_ID=P.PRODUCT_ID
                GROUP BY P.CATEGORY,P.PRODUCT_NAME ORDER BY P.CATEGORY ) 
                                                                        WHERE RN=1 ORDER BY SUM_QUANTITY DESC



---2(izahlı)
-- Xarici sorğu: yalnız hər kateqoriyada 1-ci yeri (RN=1) götür
SELECT * 
FROM (
    -- Daxili sorğu: hər məhsula sıra nömrəsi verir
    SELECT 
        -- Kateqoriya və məhsul adını götür
        P.CATEGORY,
        P.PRODUCT_NAME,
        
        -- Hər məhsulun ümumi satış miqdarını hesabla
        SUM(QUANTITY) AS SUM_QUANTITY,
        
        -- Hər kateqoriya daxilində məhsulları sıralayır
        -- PARTITION BY → hər kateqoriya üçün ayrıca sıralama
        -- ORDER BY DESC → ən çox satılandan başla
        -- ROW_NUMBER() → hər məhsula 1,2,3... nömrəsi verir
        ROW_NUMBER() OVER (
            PARTITION BY P.CATEGORY 
            ORDER BY SUM(QUANTITY) DESC
        ) AS RN

    FROM ORDER_ITEMS O
        -- ORDER_ITEMS → PRODUCTS: məhsul ID-si üzrə birləşdir
        LEFT JOIN PRODUCTS P
            ON O.PRODUCT_ID = P.PRODUCT_ID

    -- Kateqoriya və məhsul üzrə qruplaşdır
    GROUP BY P.CATEGORY, P.PRODUCT_NAME
    
    -- Kateqoriyalar üzrə sırala
    ORDER BY P.CATEGORY
)
-- Yalnız hər kateqoriyanın 1-ci məhsulunu götür
WHERE RN = 1

-- Ən çox satılandan ən aza doğru sırala
ORDER BY SUM_QUANTITY DESC

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* S7-Endirim faizinə görə satış performansı:
 Bu skript endirim faizlərini qruplara bölür (0%, 1–10%, 11–20% və s.)
 Hər qrup üzrə:

 satılan məhsul sayı → SUM(QUANTITY)
 ümumi satış məbləği → SUM(TOTAL_AMOUNT) hesablanır

 GROUP BY həmin endirim qruplarına görə məlumatları birləşdirir
 ORDER BY isə nəticəni sıralayır
*/ 
---1(sadə)
select CASE 
              WHEN DISCOUNT_PCT=0   THEN '0%'
              WHEN DISCOUNT_PCT<=10 THEN '1-10%'
              WHEN DISCOUNT_PCT<=20 THEN '11-20%'
              WHEN DISCOUNT_PCT<=30  THEN '21-30%'
              ELSE '31-40%'
              END AS DISCOUNT_GROUP,
        
        SUM(QUANTITY) as TOTAL_QUANTITY,SUM(TOTAL_AMOUNT) AS TOTAL_AMOUNT  
        FROM ORDER_ITEMS
        
            GROUP BY
            CASE 
              WHEN DISCOUNT_PCT=0 THEN '0%'
              WHEN DISCOUNT_PCT<=10 THEN '1-10%'
              WHEN DISCOUNT_PCT<=20 THEN '11-20%'
              WHEN DISCOUNT_PCT<=30 THEN '21-30%'
              ELSE '31-40%'
              END   
        ORDER BY DISCOUNT_GROUP    
---2(izahlı)
SELECT 
    -- Endirim faizini qruplara böl
    CASE 
        WHEN DISCOUNT_PCT = 0   THEN '0%'      -- Endirimsiz
        WHEN DISCOUNT_PCT <= 10 THEN '1-10%'   -- Aşağı endirim
        WHEN DISCOUNT_PCT <= 20 THEN '11-20%'  -- Orta endirim
        WHEN DISCOUNT_PCT <= 30 THEN '21-30%'  -- Yüksək endirim
        ELSE                         '31-40%'  -- Ən yüksək endirim
    END AS DISCOUNT_GROUP,
    
    -- Hər endirim qrupunda satılan məhsul sayı
    SUM(QUANTITY) AS TOTAL_QUANTITY,
    
    -- Hər endirim qrupunun ümumi satış məbləği
    SUM(TOTAL_AMOUNT) AS TOTAL_AMOUNT

FROM ORDER_ITEMS

-- Eyni CASE ifadəsi ilə qruplaşdır
GROUP BY
    CASE 
        WHEN DISCOUNT_PCT = 0   THEN '0%'
        WHEN DISCOUNT_PCT <= 10 THEN '1-10%'
        WHEN DISCOUNT_PCT <= 20 THEN '11-20%'
        WHEN DISCOUNT_PCT <= 30 THEN '21-30%'
        ELSE                         '31-40%'
    END

-- Endirim qruplarını əlifba sırası ilə sırala
ORDER BY DISCOUNT_GROUP


-------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*S8-İadə (Return) analizi — hansı kateqoriyada ən çox return var
Bu SQL sorğusu returned (geri qaytarılmış) sifarişləri seçir 
və hər məhsul kateqoriyası üzrə neçə return olduğunu hesablayır.
Subquerydə left join vasitəsilə ORDERS,ORDER_ITEMS, PRODUCTS cədvəlləri birləşdirilib və statusu return olanlar seçilib.
Əsas sorguda isə kateqoriyaya görə qruplaşdırma aparılıb və hər kateqoriyada neçə return olduğu göstərilib.
*/
---1(sadə)
SELECT CATEGORY,COUNT(*) AS RETURN_COUNT
                        FROM (select O.ORDER_ID,O.STATUS,P.CATEGORY 
                                          FROM ORDERS O 
                                          LEFT JOIN ORDER_ITEMS I ON O.ORDER_ID=I.ORDER_ID
                                          LEFT JOIN PRODUCTS P ON I.PRODUCT_ID=P.PRODUCT_ID
                                          where o.status='Returned') 
                                          
                                          GROUP BY CATEGORY ORDER BY RETURN_COUNT DESC


---2(izahlı)
-- Xarici sorğu: kateqoriya üzrə iadə sayını hesabla
SELECT 
    -- Kateqoriya adını götür
    CATEGORY,
    
    -- Hər kateqorijadakı iadə sayını say
    COUNT(*) AS RETURN_COUNT

FROM (
    -- Daxili sorğu: yalnız iadə edilmiş sifarişləri götür
    SELECT 
        O.ORDER_ID,    -- Sifariş ID-si
        O.STATUS,      -- Sifariş statusu (Returned)
        P.CATEGORY     -- Məhsul kateqoriyası

    FROM ORDERS O

        -- ORDERS → ORDER_ITEMS: sifariş ID-si üzrə birləşdir
        LEFT JOIN ORDER_ITEMS I
            ON O.ORDER_ID = I.ORDER_ID

        -- ORDER_ITEMS → PRODUCTS: məhsul ID-si üzrə birləşdir
        LEFT JOIN PRODUCTS P
            ON I.PRODUCT_ID = P.PRODUCT_ID

    -- Yalnız iadə edilmiş sifarişləri filtrələ
    WHERE O.STATUS = 'Returned'
)

-- Hər kateqoriya üçün ayrıca hesabla
GROUP BY CATEGORY

-- Ən çox iadə olunan kateqoriyadan başla
ORDER BY RETURN_COUNT DESC

-------------------------------------------------------------------------------------------------------------------------------------------------------------------


/*B1-Running total (kumulyativ satış) hesablama	
*/

---1(sadə)
SELECT O.ORDER_ID,P.PRODUCT_NAME,SUM(O.TOTAL_AMOUNT) OVER(ORDER BY O.ITEM_ID) AS RUNNING_TOTAL FROM ORDER_ITEMS O
                                                                                LEFT JOIN PRODUCTS P
                                                                                ON O.PRODUCT_ID=P.PRODUCT_ID


---2(izahlı)
SELECT 
    -- Sifariş ID-sini götür
    O.ORDER_ID,
    
    -- Məhsul adını götür
    P.PRODUCT_NAME,
    
    -- Kumulyativ (yığımlı) satışı hesabla
    -- OVER(ORDER BY) — Window Function istifadə edir
    -- Hər sətirdə əvvəlki bütün sətirlərin cəmini göstərir
    SUM(O.TOTAL_AMOUNT) OVER (ORDER BY O.ITEM_ID) AS RUNNING_TOTAL

FROM ORDER_ITEMS O

    -- ORDER_ITEMS → PRODUCTS: məhsul ID-si üzrə birləşdir
    LEFT JOIN PRODUCTS P
        ON O.PRODUCT_ID = P.PRODUCT_ID




------------------------------------------------------------------------------------------------------------------------------------------------------------------



/*B2-Müştəri Lifetime Value (CLV) hesablama	
Bu sorguda hər CTE-də müştəri id-si və müştəri adına görə xərcərin cəmi və sifarişlərin sayı qruplaşdırılıb 
və sifariş sayına görə çoxdan aza sıralanıb.Sonra isə əsas selectdə window functiondan istifadə olunaraq sifariş sayına görə kumulyativ
cəm hesablanıb
*/
---1(sadə)
WITH CUSTOMER_SALES AS(
 SELECT C.CUSTOMER_NAME,
        C.CUSTOMER_ID,
        SUM(I.TOTAL_AMOUNT) AS Xerceldiyi_mebleg,COUNT(I.TOTAL_AMOUNT) AS SIFARIS_SAYI 
                                                FROM CUSTOMERS C 
                                                JOIN ORDERS O      ON C.CUSTOMER_ID=O.CUSTOMER_ID
                                                JOIN ORDER_ITEMS I ON O.ORDER_ID=I.ORDER_ID
      GROUP BY C.CUSTOMER_NAME,C.CUSTOMER_ID  
      ORDER BY SIFARIS_SAYI DESC                    
) 

      SELECT CUSTOMER_NAME, 
             CUSTOMER_ID, 
             Xerceldiyi_mebleg,
             SIFARIS_SAYI,
             SUM(SIFARIS_SAYI) OVER(ORDER BY SIFARIS_SAYI DESC) as cumulative_count

             FROM CUSTOMER_SALES

---2(izahlı)
-- CTE (Common Table Expression) — müvəqqəti cədvəl yaradır
-- Əsas sorğuda istifadə etmək üçün hər müştərinin satış məlumatı
WITH CUSTOMER_SALES AS (
    SELECT 
        -- Müştəri adı və ID-sini götür
        C.CUSTOMER_NAME,
        C.CUSTOMER_ID,
        
        -- Müştərinin ümumi xərclədiyini hesabla
        SUM(I.TOTAL_AMOUNT) AS XERCELDIYI_MEBLEG,
        
        -- Müştərinin ümumi sifariş sayını hesabla
        COUNT(I.TOTAL_AMOUNT) AS SIFARIS_SAYI

    FROM CUSTOMERS C
        -- CUSTOMERS → ORDERS: müştəri ID-si üzrə birləşdir
        JOIN ORDERS O
            ON C.CUSTOMER_ID = O.CUSTOMER_ID
        -- ORDERS → ORDER_ITEMS: sifariş ID-si üzrə birləşdir
        JOIN ORDER_ITEMS I
            ON O.ORDER_ID = I.ORDER_ID

    -- Hər müştəri üçün ayrıca hesabla
    GROUP BY C.CUSTOMER_NAME, C.CUSTOMER_ID

    -- Ən çox sifariş verəndən başla
    ORDER BY SIFARIS_SAYI DESC
)

-- Əsas sorğu: CTE-dən istifadə edir
SELECT 
    CUSTOMER_NAME,        -- Müştəri adı
    CUSTOMER_ID,          -- Müştəri ID-si
    XERCELDIYI_MEBLEG,    -- Ümumi xərclənən məbləğ
    SIFARIS_SAYI,         -- Ümumi sifariş sayı
    
    -- Kumulyativ sifariş sayı — hər sətirdə əvvəlkilərin cəmi
    -- Müştəriləri ən çox sifarişdən ən aza doğru toplayır
    SUM(SIFARIS_SAYI) OVER (
        ORDER BY SIFARIS_SAYI DESC
    ) AS CUMULATIVE_COUNT

FROM CUSTOMER_SALES

------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*B3-Məhsulların profit margin analizi	
Bu skriptdə subquery və CASE-dən istifadə olunub,belə ki :
SUBQUERYDƏ:
          JOİN VASİTƏSİLƏ ORDER_İTEMS VƏ PRODUCTS CƏDVƏLLƏRİ BİRLƏŞDİRİLİB, MƏHSUL İD-Sİ, MƏHSUL ADI, SATIŞ DƏYƏRİ,
          MAYA DƏYƏRİ, MƏNFƏƏT MARJASI, HƏR MƏHSUL ÜZRƏ SATIŞ SAYI, HƏR MƏHSUL ÜZRƏ SATIŞ MƏBLƏĞİ GÖSTƏRİLİB.
          PROFİT MARGİNİ HESABLAYARKƏN UNİT PRİCE YOX REAL SATIŞ DƏYƏRİ(ENDİRİMLƏRDƏN SONRA SATIŞ MƏBLƏĞİ) NƏZƏRƏ ALINIB.
          BURADA HƏR MƏHSUL ÜZRƏ REAL SATIŞ MƏBLƏĞİNİN CƏMİNDƏN HƏMİN MƏHSUL ÜZRƏ SATILAN MƏHSULLARIN SAYININ MƏHSULUN MAYA 
          DƏYƏRİNƏ OLAN HASİLİ ÇIXILIB BUNDAN SONRA İSƏ BU FƏRQİN UMUMİ REAL SATIŞ CƏMİNƏ NİSBƏTİ TAPILIB.BU ANLAYIŞ BİR MƏHSULUN 
          SATIŞ DƏYƏRİNİN NEÇƏ FAİZİNİN XƏRCLƏRİMİZ ÇIXILDIQDAN SONRA BİZİM GƏLİRİMİZ OLDUĞUNU MÜƏYYƏN EDİR.

ƏSAS QUERYDƏ İSƏ:
        CASE WHEN-DƏN İSTİFADƏ OLUNARAQ PROFİT MARGİN FAİZİNƏ GÖRƏ AŞAĞI, ORTA, YÜKSƏK VƏ ÇOX YÜKSƏK OLARAQ QRUPLAŞDIRILIB.SONDA İSƏ
        PRODUCT İD-Ə GÖRƏ AZDAN ÇOXA DOĞRU SIRALANIB.
*/

---1(sadə)
SELECT    PRODUCT_ID,
            PRODUCT_NAME,
            PROFIT_MARGIN || ' %' AS MENFEET_MARJASI,
            SATIS_SAYI,
            SATIS_MEBLEGI,
            
            CASE
            WHEN PROFIT_MARGIN <40 THEN 'LOW'
            WHEN PROFIT_MARGIN <50 THEN 'MID'
            WHEN PROFIT_MARGIN <60 THEN 'HIGH'
            ELSE                        'VERY HIGH'
            END as MARGIN_GROUP

        FROM (select    P.PRODUCT_ID,
                        P.PRODUCT_NAME,
                        P.UNIT_PRICE,                    
                        P.COST_PRICE,
                        ROUND((SUM(O.TOTAL_AMOUNT) - SUM(O.QUANTITY * P.COST_PRICE)) / SUM(O.TOTAL_AMOUNT) * 100,2) AS PROFIT_MARGIN, 
                        SUM(O.QUANTITY) AS SATIS_SAYI,
                        SUM(O.TOTAL_AMOUNT) AS SATIS_MEBLEGI
         
                        
                        
         
                                                                                                    from ORDER_ITEMS   O            
                                                                                                    JOIN PRODUCTS      P 
                                                                                                    ON O.PRODUCT_ID=P.PRODUCT_ID 
                                                                   
                                                                  GROUP BY P.PRODUCT_ID,P.PRODUCT_NAME,P.UNIT_PRICE,P.COST_PRICE) ORDER BY PRODUCT_ID

---2(izahlı)
-- Xarici sorğu: profit margin qruplarını təyin edir
SELECT 
    PRODUCT_ID,
    PRODUCT_NAME,
    
    -- Profit margin faizinin yanına '%' işarəsi əlavə edir
    -- || — Oracle-da string birləşdirmə operatoru
    PROFIT_MARGIN || ' %' AS MENFEET_MARJASI,
    
    SATIS_SAYI,
    SATIS_MEBLEGI,
    
    -- Profit margin-ə görə qruplara böl
    CASE
        WHEN PROFIT_MARGIN < 40 THEN 'LOW'       -- 40%-dən aşağı
        WHEN PROFIT_MARGIN < 50 THEN 'MID'       -- 40-50% arası
        WHEN PROFIT_MARGIN < 60 THEN 'HIGH'      -- 50-60% arası
        ELSE                         'VERY HIGH' -- 60%-dən yuxarı
    END AS MARGIN_GROUP

FROM (
    -- Daxili sorğu: hər məhsul üçün profit margin hesablayır
    SELECT 
        P.PRODUCT_ID,
        P.PRODUCT_NAME,
        P.UNIT_PRICE,
        P.COST_PRICE,
        
        -- Profit Margin formulu:
        -- (Satış - Maya) / Satış * 100
        -- SUM(TOTAL_AMOUNT)           → ümumi satış məbləği
        -- SUM(QUANTITY * COST_PRICE)  → ümumi maya dəyəri
        ROUND(
            (SUM(O.TOTAL_AMOUNT) - SUM(O.QUANTITY * P.COST_PRICE)) 
            / SUM(O.TOTAL_AMOUNT) * 100, 2
        ) AS PROFIT_MARGIN,
        
        -- Ümumi satılan miqdar
        SUM(O.QUANTITY) AS SATIS_SAYI,
        
        -- Ümumi satış məbləği
        SUM(O.TOTAL_AMOUNT) AS SATIS_MEBLEGI

    FROM ORDER_ITEMS O
        -- ORDER_ITEMS → PRODUCTS: məhsul ID-si üzrə birləşdir
        JOIN PRODUCTS P
            ON O.PRODUCT_ID = P.PRODUCT_ID

    -- Hər məhsul üçün ayrıca hesabla
    GROUP BY 
        P.PRODUCT_ID, 
        P.PRODUCT_NAME, 
        P.UNIT_PRICE, 
        P.COST_PRICE
)

-- Məhsul ID-sinə görə sırala
ORDER BY PRODUCT_ID




-----------------------------------------------------------------------------------------------------------------------------------------------------------------
        
/* RFM Data — Müştəri Lifetime Value analizi üçün xam data
Bu sorğu hər müştəri üçün:
1. Son sifariş tarixini (Recency üçün)
2. Unikal sifariş sayını (Frequency üçün)
3. Ümumi xərclənən məbləği (Monetary üçün)
*/
SELECT 
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    MAX(O.ORDER_DATE) AS LAST_ORDER_DATE,
    COUNT(DISTINCT O.ORDER_ID) AS FREQUENCY,
    SUM(I.TOTAL_AMOUNT) AS MONETARY
FROM CUSTOMERS C
JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
JOIN ORDER_ITEMS I ON O.ORDER_ID = I.ORDER_ID
GROUP BY C.CUSTOMER_ID, C.CUSTOMER_NAME
ORDER BY C.CUSTOMER_ID
        
                         
                         
                         
                         
                         
                         
                             
                             
                             
                                                

