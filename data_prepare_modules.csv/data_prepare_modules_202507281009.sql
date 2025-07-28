INSERT INTO llm_platform.data_prepare_modules (user_id,asistan_id,query,create_date,change_date,working_platform,query_name,database_id,db_schema,documents_id,csv_database_id,csv_db_schema,data_prep_code) VALUES
	 (1,2,'Select Firma, Yil,SiparisTarihi ,MalzemeHizmetKodu,MalzemeHizmetKodu2,MalzemeHizmet,BrutKarAnaGrubu,BrutKarGrubu from [TIGEREP_DB]..ARS_TBL_Satis_Performans_Tum where Isyeri not in (''900-Endüstri'', ''0-Eliar'') order by Yil desc, ay desc ;
','2024-11-20 11:41:07.911','2025-03-28 14:17:17.28695','logo_veritabani','satis_siparis_verileri',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (1,2,'Select Firma, Yil,SiparisTarihi,StokKodu,StokTanimi,BrutKarAnaGrubu,BrutKarGrubu from  [TIGEREP_DB]..ARS_TBL_Ayrintili_Satis_Tum  where Isyeri not in (''Endüstri'', ''Eliar'')  order by Yil desc, ay desc ;','2024-11-20 11:41:07.911','2025-03-28 14:17:17.300366','logo_veritabani','satis_fatura_verileri',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (1,1,'select 
--c.companyname,
--m.displayname 
TRIM(REGEXP_REPLACE(c.companyname, ''\s+'', '' '', ''g'')) AS companyname,
TRIM(REGEXP_REPLACE(m.displayname, ''\s+'', '' '', ''g'')) AS displayname
from consolide.msystems m  
left join consolide.company c on m.companyid = c.companyid 
left join consolide.msystemtypes m2 on m.msystemid = m2.msystemtypeid  
where m.isactive =True;','2025-01-02 11:23:41.607','2025-03-28 14:17:17.302391','bulut_pc','tanımlı_mekatronik_sistem_listesi',3,'consolide',NULL,1,'llm_asistant_file_info',NULL),
	 (1,1,'with consolideLogs as (select jobdate, msystemid ,companyid ,functionname ,issuccess,''etl'' as script  from consolide.logs  WHERE functionname in (''START-ETL'',''FINISH-ETL'') and jobdate >= CURRENT_DATE - INTERVAL ''1 day'' AND jobdate < CURRENT_DATE ),rawLogs as (select jobdate, msystemid ,companyid ,functionname ,issuccess,''raw'' as script from raw.logs  WHERE jobdate >= CURRENT_DATE - INTERVAL ''1 day'' AND jobdate < CURRENT_DATE  AND functionname in (''Etlraw - Start'',''Etlraw - Finish'')),combinedResults as (select * from rawLogs r union all  select * from consolideLogs l) select jobdate as log_date, functionname as log_text, script from combinedResults cr;','2025-01-03 11:23:41.607','2025-03-28 14:17:17.304624','bulut_pc','etlraw_etl_log_kayitlari',3,'consolide',NULL,1,'llm_asistant_file_info',NULL),
	 (1,2,'select * from [TIGEREP_DB]..ARS_Src_Fatura_İrsaliye_Ekleme_Zamanı where İşyeriNo not in (''0'',''900'') order by İşyeri desc, [Ekleme Tarihi] desc,Ekleyen desc;
','2025-02-14 11:41:07.911','2025-03-28 14:17:17.306625','logo_veritabani','irsaliye_fatura_gecikmeleri',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (1,2,'SELECT 
	distinct ISNULL(zd.SLID,-1) ID,
	O.FICHENO AS SiparisNumarasi,
	O.DATE_ AS SiparisTarihi,
	CAP.NAME AS Isyeri,
	US.NAME AS SiparisiEkleyen,
	ISNULL(I.CODE, SRV.CODE) AS MalzemeHizmetKodu, 
	ISNULL(I.NAME, SRV.CODE) AS MalzemeHizmetKodu2,
	ISNULL(I.NAME3, SRV.DEFINITION_) AS MalzemeHizmet,
	L.AMOUNT AS Miktar,
	L.SHIPPEDAMOUNT AS KarsılananMiktar,
	(CASE WHEN L.SHIPPEDAMOUNT >=L.AMOUNT THEN ''Sipariş Tamamlandı''
	WHEN L.SHIPPEDAMOUNT < L.AMOUNT and L.SHIPPEDAMOUNT <> 0 THEN ''Kısmi Tamamlandı''
	WHEN L.SHIPPEDAMOUNT = 0 THEN ''Sipariş Açık''
	END) AS SevkDurumu,
	ROUND(ISNULL(ZD.FATURA_EURO_FIYATI,0) *STF.REPORTRATE,2) AS BirimFiyatTR,
	ROUND(ISNULL(ZD.FATURA_EURO_FIYATI,0) *STF.REPORTRATE*L.AMOUNT,2)  AS ToplamFiyatTR,
	CL.CODE AS TedarikciKodu,
	CL.DEFINITION_ AS Tedarikci,
	(CASE WHEN  C.CURCODE IS NULL THEN ''TL''
	ELSE C.CURCODE
	END) AS KUR,
	STF.REPORTRATE AS RaporlamaDovizi,
	ISNULL(STF.FICHENO,''BOŞ'') AS IrsaliyeNo,
	ROUND(ISNULL(ZD.FATURA_EURO_FIYATI,0),2) AS IrsEuroBirimFiyat,
	ROUND(ISNULL(ZD.FATURA_EURO_FIYATI,0)*L.AMOUNT,2) AS IrsEuroToplamFiyat,
	INV.DATE_ AS FaturaTarihi,
	ISNULL(INV.FICHENO,''BOŞ'') AS FaturaNo
FROM 
    [TIGEREP_DB]..LG_124_01_ORFLINE L
LEFT OUTER JOIN 
    [TIGEREP_DB]..LG_124_ITEMS I WITH (nolock) ON L.STOCKREF = I.LOGICALREF AND L.LINETYPE IN (0, 7)
LEFT OUTER JOIN 
    [TIGEREP_DB]..LG_124_01_ORFICHE O WITH (nolock) ON L.ORDFICHEREF = O.LOGICALREF
LEFT OUTER JOIN 
    [TIGEREP_DB]..L_CURRENCYLIST C WITH (nolock)ON L.TRCURR = C.LOGICALREF --AND  o.TRCURR = c.LOGICALREF
LEFT OUTER JOIN 
	[TIGEREP_DB]..LG_124_CLCARD CL WITH (nolock) ON  O.CLIENTREF = CL.LOGICALREF AND L.CLIENTREF = CL.LOGICALREF 
LEFT OUTER JOIN 
	[TIGEREP_DB]..L_CAPIDIV CAP WITH (nolock) ON /*o.BRANCH = cap.NR AND*/ CAP.NR = L.BRANCH and CAP.FIRMNR = ''124''
LEFT OUTER JOIN 
	[TIGEREP_DB]..LG_124_SRVCARD SRV WITH (nolock) ON L.STOCKREF = SRV.LOGICALREF AND L.LINETYPE = 4
LEFT OUTER JOIN 
	[TIGEREP_DB]..L_CAPIUSER US WITH (nolock) ON US.NR=O.CAPIBLOCK_CREATEDBY
LEFT OUTER JOIN 
	[TIGEREP_DB]..LG_124_01_STLINE AS STL ON STL.ORDFICHEREF = O.LOGICALREF AND L.STOCKREF=STL.STOCKREF
LEFT OUTER JOIN 
	[TIGEREP_DB].dbo.LG_124_01_STFICHE AS STF WITH (nolock) ON STF.LOGICALREF = STL.STFICHEREF 
LEFT OUTER JOIN  
	[TIGEREP_DB].dbo.LG_124_01_INVOICE INV WITH (nolock) ON INV.LOGICALREF = STL.INVOICEREF
INNER JOIN  
	[TIGEREP_DB].dbo.ARS_SATINALMA_FIYATLARI_124_zd ZD  WITH (nolock) ON ZD.SLID=STL.LOGICALREF 
WHERE 
    O.TRCODE = 2 
	AND L.STATUS <> 2 
	AND L.REPORTRATE <> 0 
	AND L.LINETYPE NOT IN (2, 6)
	AND I.CODE not like ''%PRJ%''
	AND CL.CODE not like ''120%''
	AND CAP.NAME <> ''Endüstri''
	AND I.CODE not like ''SK%''
ORDER BY 
    o.FICHENO;','2024-11-20 11:41:07.911','2025-03-28 14:17:17.298225','logo_veritabani','satin_alma_verileri',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (1,3,'WITH raw_logs AS 
(SELECT * 
FROM raw.logs l2 
WHERE jobdate >= (DATE_TRUNC(''day'', NOW() - INTERVAL ''1 days'')::timestamp without time zone) 
and jobdate <= ((DATE_TRUNC(''day'', NOW() - INTERVAL ''1 days'') + INTERVAL ''23 hours 59 minutes 59 seconds'')::timestamp without time zone))
,company_table AS (
SELECT companyid, companyname
FROM consolide.company
),
msystems_table AS (
SELECT companyid,msystemid,displayname
FROM consolide.msystems
),
jobs_detail_table AS (
SELECT companyid, msystemid, MAX(start_date) AS max_start_date
FROM raw.jobs_detail
GROUP BY companyid, msystemid
),
jobarchive_table AS (
SELECT companyid, msystemid, MAX(CAST(jobdate AS DATE)) AS max_jobdate
FROM raw.jobarchive
GROUP BY companyid, msystemid
)
select
c.companyname,
m.displayname,
r.*,
COALESCE(
CASE
WHEN r.msystemid IN (31, 32, 33, 45, 46,47) THEN jd.max_start_date
WHEN r.msystemid IN (1, 2, 3, 4, 5,11,12,13,14,15,16,17,18,19,20,26,27,28,29,30) THEN ja.max_jobdate
END,
NULL
) AS veri_alma_tarihi
FROM raw_logs r
left JOIN jobs_detail_table jd
ON r.companyid = jd.companyid
AND r.msystemid = jd.msystemid
AND r.msystemid IN (31, 32, 33, 45, 46)
left JOIN jobarchive_table ja
ON r.companyid = ja.companyid
AND r.msystemid = ja.msystemid
AND r.msystemid IN (1, 2, 3, 4, 5,11,12,13,14,15,16,17,18,19,20,26,27,28,29,30)
left join company_table c on r.companyid = c.companyid
left join msystems_table m on r.companyid = m.companyid and r.msystemid = m.msystemid;','2024-08-27 07:15:41.607','2025-03-28 14:17:17.312432','bulut_pc','raw_logs',3,'raw',NULL,1,'llm_asistant_file_info',NULL),
	 (1,2,'Select * From [ManageMind].[dbo].[Recetesi_Satis_Siparisi_Olmayan_Alımlar];','2025-04-02 09:12:54.584323','2025-04-02 09:12:54.584323','logo_veritabani','recete_ve_siparisi_olmayan',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (1,2,'SELECT * FROM [ManageMind].[dbo].[ARS_Girilmemiş_Faturalar_UrunTedarikcileri]
ORDER BY 1,6 DESC','2025-04-18 14:22:40.434593','2025-04-28 17:37:02.396138','logo_veritabani','Girilmemis_Faturalarin_Bildirilmesi',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (1,1,'SELECT 
    TRIM(REGEXP_REPLACE(c.companyname, ''\s+'', '' '', ''g'')) AS companyname,
    TRIM(REGEXP_REPLACE(m.displayname, ''\s+'', '' '', ''g'')) AS displayname,
    a.requestid,
    a.detailid,
    a.alarmid,
    a.alarmcode,
    a.starttime AS alarm_start_time,
    a.finishtime AS alarm_finish_time,
    a.duration AS alarm_duration_time,
    a.weighting_status,
    COALESCE(ad.alarmname, ''boş'') as alarmname,
    j.programno
FROM (
    SELECT 
        al.companyid,
        al.msystemid,
        al.requestid,
        al.detailid,
        al.alarmid,
        al.alarmcode,
        al.starttime,
        al.finishtime,
        al.duration,
        al.durum AS weighting_status
    FROM consolide.alarms al
    WHERE 
        al.detailid IS NOT NULL
        AND al.requestid IS NOT NULL
        AND al.alarmcode NOT IN (1002, 1003, 1005)
        AND al.starttime >= CURRENT_DATE - INTERVAL ''30 days''
) AS a
INNER JOIN (
    SELECT 
        ad.companyid,
        ad.msystemid,
        ad.alarmcode,
        ad.alarmname
    FROM consolide.alarmdim ad
) AS ad ON a.companyid = ad.companyid
        AND a.msystemid = ad.msystemid
        AND a.alarmcode = ad.alarmcode
INNER JOIN (SELECT companyid, companyname FROM consolide.company) c ON c.companyid = a.companyid
INNER JOIN (SELECT companyid, msystemid, displayname FROM consolide.msystems) m ON a.companyid = m.companyid AND a.msystemid = m.msystemid
LEFT JOIN (SELECT companyid, msystemid, requestid, programno FROM consolide.jobs) j ON a.companyid = j.companyid AND a.msystemid = j.msystemid AND a.requestid = j.requestid;
','2024-08-27 07:15:41.607','2025-04-22 23:37:08.47807','bulut_pc','mekatronik_sistem_alarmları',3,'consolide',NULL,1,'llm_asistant_file_info',NULL);
INSERT INTO llm_platform.data_prepare_modules (user_id,asistan_id,query,create_date,change_date,working_platform,query_name,database_id,db_schema,documents_id,csv_database_id,csv_db_schema,data_prep_code) VALUES
	 (1,1,'SELECT
    TRIM(REGEXP_REPLACE(c.companyname, ''\s+'', '' '', ''g'')) AS companyname,
    TRIM(REGEXP_REPLACE(m.displayname, ''\s+'', '' '', ''g'')) AS displayname,
    DATE(jd.starttime)::timestamp AS analysis_date,
    --SUM(jd.duration) AS total_occupancy_duration,
    ROUND((SUM(jd.duration) * 100.0) / 86400, 2)::float8 AS occupancy_rate_percent
FROM consolide.jobdetails jd
INNER JOIN consolide.company c 
    ON jd.companyid = c.companyid
INNER JOIN consolide.msystems m 
    ON jd.companyid = m.companyid AND jd.msystemid = m.msystemid
WHERE
    jd.starttime IS NOT NULL
    AND jd.starttime >= CURRENT_DATE - INTERVAL ''30 days''
    AND jd.isvalid = ''1''
GROUP BY
    c.companyname,
    m.displayname,
    DATE(jd.starttime)
ORDER BY
    analysis_date,
    companyname,
    displayname;','2025-05-03 20:18:47.829669','2025-05-05 11:02:31.499986','bulut_pc','mekatronik_sistem_dolulukları',3,'consolide',NULL,1,'llm_asistant_file_info',NULL),
	 (1,1,'WITH jobs AS (
    SELECT
        companyid,
        msystemid,
        requestid,
        requesttime, -- burada eklendi
        COALESCE("source", ''boş'') AS "source",
        starttime AS requestid_starttime,
        finishtime AS requestid_finishtime,
        COALESCE(quetime, 0) AS quetime,
        COALESCE(batchno, ''boş'') AS batchno,
        COALESCE(machineno, 0) AS machineno,
        COALESCE(programno, 0) AS programno,
        COALESCE(wastewater, 0) AS wastewater
    FROM
        consolide.jobs j
    WHERE
        isvalid = ''1''
        AND starttime >= CURRENT_DATE - INTERVAL ''30 days''
),
jobdetails AS (
    SELECT
        companyid,
        msystemid,
        detailid,
        requestid,
        COALESCE(targetamount, 0) AS targetamount,
        COALESCE(consumedamount, 0) AS consumedamount,
        COALESCE(chemno, 0) AS chemno,
        starttime,
        finishtime,
        COALESCE(duration, 0) AS duration,
        COALESCE(deviation, 0) AS deviation,
        COALESCE(alarmhappened, ''0'') AS alarmhappened,
        COALESCE(isvalid, ''0'') AS isvalid,
        COALESCE(weighthinglimits, 0) AS weighthinglimits,
        COALESCE(successful, ''Unsuccessful'') AS successful
    FROM
        consolide.jobdetails j
    WHERE
        isvalid = ''1''
        AND starttime >= CURRENT_DATE - INTERVAL ''30 days''
),
machinedim AS (
    SELECT
        companyid,
        msystemid,
        machineno,
        COALESCE("name", ''boş'') AS "name",
        COALESCE(capacity, 0) AS capacity
    FROM
        consolide.machinedim m
    WHERE
        isactive = ''1''
),
chemdim AS (
    SELECT
        companyid,
        msystemid,
        chemno,
        COALESCE("name", ''boş'') AS "name"
    FROM
        consolide.chemdim
    WHERE
        isactive = ''1''
),
msystems AS (
    SELECT
        companyid,
        msystemid,
        displayname
    FROM consolide.msystems m
),
company AS (
    SELECT
        companyid,
        companyname
    FROM consolide.company
)
SELECT
    TRIM(REGEXP_REPLACE(cm.companyname, ''\s+'', '' '', ''g'')) AS companyname,
    TRIM(REGEXP_REPLACE(msys.displayname, ''\s+'', '' '', ''g'')) AS displayname,
    j.requestid,
    jd.detailid,
    j."source",
    j.requesttime, 
    j.requestid_starttime,
    j.requestid_finishtime,
    jd.starttime,
    jd.finishtime,
    j.quetime,
    j.batchno,
    j.programno,
    j.wastewater,
    jd.successful,
    jd.weighthinglimits,
    jd.targetamount,
    jd.consumedamount,
    jd.duration,
    jd.deviation,
            ((jd.consumedamount - jd.targetamount) / NULLIF(jd.targetamount, 0)) * 100
     AS deviation_percentage,
    m."name" AS machine_name,
    m.capacity,
    TRIM(REGEXP_REPLACE(c."name", ''\s+'', '' '', ''g'')) AS chemical_name
FROM
    jobs j
    LEFT JOIN jobdetails jd ON j.requestid = jd.requestid AND j.companyid = jd.companyid AND j.msystemid = jd.msystemid
    LEFT JOIN machinedim m ON j.machineno = m.machineno AND j.companyid = m.companyid AND j.msystemid = m.msystemid
    LEFT JOIN chemdim c ON jd.chemno = c.chemno AND jd.companyid = c.companyid AND jd.msystemid = c.msystemid
    INNER JOIN company cm ON jd.companyid = cm.companyid
    INNER JOIN msystems msys ON msys.companyid = jd.companyid AND msys.msystemid = jd.msystemid;','2024-08-27 07:15:41.636','2025-05-14 10:44:53.880534','bulut_pc','mekatronik_sistem_tartımları',3,'consolide',NULL,1,'llm_asistant_file_info',NULL),
	 (1,2,'SELECT * FROM [ManageMind].[dbo].[ARS_Girilmemiş_Faturalar_MüşteriIadeleri]','2025-05-18 18:34:44.544156','2025-05-18 18:34:44.544156','logo_veritabani','erp_ye_girilmemiş_satis_iade',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (1,1,'SELECT
    e.starttime::date AS tarih,
    c.companyname AS fabrika_adi,
    ms.displayname AS sistem_adi,
    e.eventcode,
    ed.eventname AS event_adi,
    COUNT(e.eventid) AS event_sayisi
FROM
    consolide.events e
JOIN
    consolide.msystems ms ON e.companyid = ms.companyid AND e.msystemid = ms.msystemid
JOIN
    consolide.company c ON e.companyid = c.companyid
LEFT JOIN
    consolide.eventdim ed ON e.companyid = ed.companyid AND e.msystemid = ed.msystemid AND e.eventcode = ed.eventcode
WHERE
    e.starttime::date >= CURRENT_DATE - INTERVAL ''30 days''
    AND e.starttime::date <= CURRENT_DATE
    AND e.eventcode NOT IN (7, 10, 16, 36, 37, 40002, 50001, 50002)
GROUP BY
    e.starttime::date,
    c.companyname,
    ms.displayname,
    e.eventcode,
    ed.eventname
ORDER BY
    tarih DESC,
    event_sayisi DESC;
','2025-06-15 13:09:58.618681','2025-06-15 13:09:58.618681','bulut_pc','mekatronik_sistem_event_sayıları',3,'consolide',NULL,1,'llm_asistant_file_info',NULL);
