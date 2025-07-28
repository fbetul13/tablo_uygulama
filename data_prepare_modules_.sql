INSERT INTO llm_platform.data_prepare_modules (module_id,user_id,asistan_id,query,working_platform,query_name,database_id,db_schema,documents_id,csv_database_id,csv_db_schema,data_prep_code) VALUES
	 (1,1,7,'Select Firma, Yil,SiparisTarihi ,MalzemeHizmetKodu,MalzemeHizmetKodu2,MalzemeHizmet,BrutKarAnaGrubu,BrutKarGrubu from [TIGEREP_DB]..ARS_TBL_Satis_Performans_Tum where Isyeri not in (''900-Endüstri'', ''0-Eliar'') order by Yil desc, ay desc ;','logo_veritabani','satis_siparis_verileri',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (2,1,7,'Select Firma, Yil,SiparisTarihi,StokKodu,StokTanimi,BrutKarAnaGrubu,BrutKarGrubu from  [TIGEREP_DB]..ARS_TBL_Ayrintili_Satis_Tum  where Isyeri not in (''Endüstri'', ''Eliar'')  order by Yil desc, ay desc ;','logo_veritabani','satis_fatura_verileri',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (3,1,9,'select 
--c.companyname,
--m.displayname 
TRIM(REGEXP_REPLACE(c.companyname, ''\s+'', '' '', ''g'')) AS companyname,
TRIM(REGEXP_REPLACE(m.displayname, ''\s+'', '' '', ''g'')) AS displayname
from consolide.msystems m  
left join consolide.company c on m.companyid = c.companyid 
left join consolide.msystemtypes m2 on m.msystemid = m2.msystemtypeid  
where m.isactive =True;','bulut_pc','tanımlı_mekatronik_sistem_listesi',3,'consolide',NULL,1,'llm_asistant_file_info',NULL),
	 (4,1,9,'with consolideLogs as (select jobdate, msystemid ,companyid ,functionname ,issuccess,''etl'' as script  from consolide.logs  WHERE functionname in (''START-ETL'',''FINISH-ETL'') and jobdate >= CURRENT_DATE - INTERVAL ''1 day'' AND jobdate < CURRENT_DATE ),rawLogs as (select jobdate, msystemid ,companyid ,functionname ,issuccess,''raw'' as script from raw.logs  WHERE jobdate >= CURRENT_DATE - INTERVAL ''1 day'' AND jobdate < CURRENT_DATE  AND functionname in (''Etlraw - Start'',''Etlraw - Finish'')),combinedResults as (select * from rawLogs r union all  select * from consolideLogs l) select jobdate as log_date, functionname as log_text, script from combinedResults cr;','bulut_pc','etlraw_etl_log_kayitlari',3,'consolide',NULL,1,'llm_asistant_file_info',NULL),
	 (5,1,7,'select * from [TIGEREP_DB]..ARS_Src_Fatura_İrsaliye_Ekleme_Zamanı where İşyeriNo not in (''0'',''900'') order by İşyeri desc, [Ekleme Tarihi] desc,Ekleyen desc;','logo_veritabani','irsaliye_fatura_gecikmeleri',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (6,1,7,'SELECT 
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
	[TIGEREP_DB]..LG_124_CAPIDIV CAP WITH (nolock) ON /*o.BRANCH = cap.NR AND*/ CAP.NR = L.BRANCH and CAP.FIRMNR = ''124''
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
    o.FICHENO;','logo_veritabani','satin_alma_verileri',2,'dbo',NULL,1,'llm_asistant_file_info',NULL),
	 (7,1,8,'WITH raw_logs AS 
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
SELECT 
    rl.jobdate,
    ct.companyname,
    mt.displayname,
    rl.functionname,
    rl.issuccess,
    rl.script,
    jdt.max_start_date,
    jat.max_jobdate
FROM raw_logs rl
LEFT JOIN company_table ct ON rl.companyid = ct.companyid
LEFT JOIN msystems_table mt ON rl.companyid = mt.companyid AND rl.msystemid = mt.msystemid
LEFT JOIN jobs_detail_table jdt ON rl.companyid = jdt.companyid AND rl.msystemid = jdt.msystemid
LEFT JOIN jobarchive_table jat ON rl.companyid = jat.companyid AND rl.msystemid = jat.msystemid
ORDER BY rl.jobdate DESC;','bulut_pc','raw_log_kayitlari',3,'raw',NULL,1,'llm_asistant_file_info',NULL);
