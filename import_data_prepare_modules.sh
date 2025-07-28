#!/bin/bash

echo "🔍 SQL dosyasından veriler okunuyor..."

# Mevcut kayıtları kontrol et
echo "📊 Mevcut kayıt sayısı:"
curl -s http://localhost:8000/data_prepare_modules | jq length

echo ""
echo "🚀 Kalan veriler ekleniyor..."

# 7. kayıt - Mekatronik sistemlerle ilgili
curl -X POST http://localhost:8000/data_prepare_modules \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 7,
    "user_id": 1,
    "asistan_id": 7,
    "query": "SELECT companyname, displayname, requestid, detailid, source, requestid_starttime, requestid_finishtime, quetime, batchno, programno, wastewater, weighthinglimits, starttime, finishtime, duration, targetamount, consumedamount, deviation, grampersecond, machine_name, capacity, chemical_name FROM mekatronik_sistem_tartimlari WHERE requestid_starttime >= CURRENT_DATE - INTERVAL \"7 days\"",
    "working_platform": "bulut_pc",
    "query_name": "mekatronik_sistem_tartimlari",
    "database_id": 3,
    "db_schema": "consolide",
    "csv_database_id": 1,
    "csv_db_schema": "llm_asistant_file_info",
    "data_prep_code": null
  }'
echo ""

# 8. kayıt - Mekatronik alarmlar
curl -X POST http://localhost:8000/data_prepare_modules \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 8,
    "user_id": 1,
    "asistan_id": 7,
    "query": "SELECT companyname, displayname, requestid, detailid, alarmid, alarmcode, alarm_start_time, alarm_finish_time, alarm_duration_time, alarmname, programno FROM mekatronik_sistem_alarmlari WHERE alarm_start_time >= CURRENT_DATE - INTERVAL \"7 days\"",
    "working_platform": "bulut_pc",
    "query_name": "mekatronik_sistem_alarmlari",
    "database_id": 3,
    "db_schema": "consolide",
    "csv_database_id": 1,
    "csv_db_schema": "llm_asistant_file_info",
    "data_prep_code": null
  }'
echo ""

# 9. kayıt - Satın alma verileri
curl -X POST http://localhost:8000/data_prepare_modules \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 9,
    "user_id": 1,
    "asistan_id": 8,
    "query": "SELECT SiparisNumarasi, SiparisTarihi, Isyeri, SiparisiEkleyen, MalzemeHizmetKodu, MalzemeHizmetKodu2, MalzemeHizmet, Miktar, KarsılananMiktar, SevkDurumu, BirimFiyatTR, ToplamFiyatTR, Tedarikci, KUR, RaporlamaDovizi, IrsEuroBirimFiyat, IrsEuroToplamFiyat, FaturaTarihi, FaturaNo FROM satin_alma_verileri WHERE SiparisTarihi >= CURRENT_DATE - INTERVAL \"30 days\"",
    "working_platform": "logo_veritabani",
    "query_name": "satin_alma_verileri",
    "database_id": 2,
    "db_schema": "dbo",
    "csv_database_id": 1,
    "csv_db_schema": "llm_asistant_file_info",
    "data_prep_code": null
  }'
echo ""

# 10. kayıt - Satış siparişi verileri
curl -X POST http://localhost:8000/data_prepare_modules \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 10,
    "user_id": 1,
    "asistan_id": 8,
    "query": "SELECT Firma, Yil, SiparisTarihi, MalzemeHizmetKodu, MalzemeHizmetKodu2, MalzemeHizmet, BrutKarAnaGrubu, BrutKarGrubu FROM satis_siparisi_verileri WHERE SiparisTarihi >= CURRENT_DATE - INTERVAL \"30 days\"",
    "working_platform": "logo_veritabani",
    "query_name": "satis_siparisi_verileri",
    "database_id": 2,
    "db_schema": "dbo",
    "csv_database_id": 1,
    "csv_db_schema": "llm_asistant_file_info",
    "data_prep_code": null
  }'
echo ""

# 11. kayıt - Satış fatura verileri
curl -X POST http://localhost:8000/data_prepare_modules \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 11,
    "user_id": 1,
    "asistan_id": 8,
    "query": "SELECT Firma, Yil, SiparisTarihi, StokKodu, StokTanimi, BrutKarAnaGrubu, BrutKarGrubu FROM satis_faturasi_verileri WHERE SiparisTarihi >= CURRENT_DATE - INTERVAL \"30 days\"",
    "working_platform": "logo_veritabani",
    "query_name": "satis_faturasi_verileri",
    "database_id": 2,
    "db_schema": "dbo",
    "csv_database_id": 1,
    "csv_db_schema": "llm_asistant_file_info",
    "data_prep_code": null
  }'
echo ""

# 12. kayıt - İrsaliye fatura gecikmeleri
curl -X POST http://localhost:8000/data_prepare_modules \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 12,
    "user_id": 1,
    "asistan_id": 8,
    "query": "SELECT Firma, Tür, İşyeriNo, İşyeri, Ay, Fiş Numarası, Fiş Tarihi, Cari Unvan, Ekleyen, Ekleme Tarihi, Gün Farkı FROM irsaliye_fatura_gecikmeleri WHERE \"Fiş Tarihi\" >= CURRENT_DATE - INTERVAL \"30 days\"",
    "working_platform": "logo_veritabani",
    "query_name": "irsaliye_fatura_gecikmeleri_detay",
    "database_id": 2,
    "db_schema": "dbo",
    "csv_database_id": 1,
    "csv_db_schema": "llm_asistant_file_info",
    "data_prep_code": null
  }'
echo ""

# 13. kayıt - Sipariş detay verileri
curl -X POST http://localhost:8000/data_prepare_modules \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 13,
    "user_id": 1,
    "asistan_id": 8,
    "query": "SELECT ID, SiparisNumarasi, SiparisTarihi, Isyeri, SiparisiEkleyen, MalzemeHizmetKodu, MalzemeHizmetKodu2, MalzemeHizmet, Miktar, KarsılananMiktar, SevkDurumu, BirimFiyatTR, ToplamFiyatTR, TedarikciKodu, Tedarikci, KUR, RaporlamaDovizi, IrsaliyeNo, IrsEuroBirimFiyat, IrsEuroToplamFiyat, FaturaTarihi, FaturaNo FROM siparis_detay_verileri WHERE SiparisTarihi >= CURRENT_DATE - INTERVAL \"30 days\"",
    "working_platform": "logo_veritabani",
    "query_name": "siparis_detay_verileri_detay",
    "database_id": 2,
    "db_schema": "dbo",
    "csv_database_id": 1,
    "csv_db_schema": "llm_asistant_file_info",
    "data_prep_code": null
  }'
echo ""

# 14. kayıt - Mekatronik sistem listesi
curl -X POST http://localhost:8000/data_prepare_modules \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": 14,
    "user_id": 1,
    "asistan_id": 7,
    "query": "SELECT companyname, displayname FROM tanımlı_mekatronik_sistem_listesi ORDER BY companyname, displayname",
    "working_platform": "bulut_pc",
    "query_name": "tanımlı_mekatronik_sistem_listesi_detay",
    "database_id": 3,
    "db_schema": "consolide",
    "csv_database_id": 1,
    "csv_db_schema": "llm_asistant_file_info",
    "data_prep_code": null
  }'
echo ""

echo "📈 Güncel kayıt sayısı:"
curl -s http://localhost:8000/data_prepare_modules | jq length

echo ""
echo "✅ Veri aktarımı tamamlandı!" 