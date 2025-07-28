INSERT INTO llm_platform.auto_prompt (assistant_id,question,trigger_time,python_code,receiver_emails,mcrisactive) VALUES
	 (1,'Bir önceki gün için deviation sütununun negatif olduğu tartımları bul. Tartımların sapma %’sini (deviation / targetamount)*100 formülü ile hesapla. Fabrika ve mekatronik sistem bazında toplam detailid sayısını listele [liste1]. Fabrika ve mekatronik sistem bazında ortalama sapma %''sini listele [liste2]. [liste2]''de sapma''nın %-5''ten fazla olduğu satırları filtrele. [liste1] ve [liste2]''yi fabrika ve mekatronik sistem bazında inner join yap. HTML için kullanacağın kullanacağın sütun isimlerini şu şekilde değiştirmelisin: ''Fabrika İsmi'', ''Sistem ismi'', ''%-5 ten Fazla Sapan Toplam Tartım Sayısı'','' Günlük Ortalama Sapma %'' olsun. ''Günlük Ortalama Sapma %'' sütunu virgülden sonra 2 basamak olsun. HTML''de başka hiçbir sütun bilgisi olmamalı. Liste boş değilse mail at, boş ise mail atma.  Mail konusuna ‘Günlük Ortalama Negatif Sapma Oranı Yüksek Olan Mekatronik Sistemler’ yazmalısın. Mail''e, ''Anomali Ölçütü'' adlı 2. başlık ekle. 2. Başlık altında, ''[bir önceki gün tarihi] tarihi için ortalama negatif sapması %-5''ten fazla olan sistemler.'' metnini yaz.','{"times": []}','


import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

from datetime import datetime, timedelta

import smtplib

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

# Verileri yükleyin

tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

# requestid_starttime ve starttime sütunlarını datetime''a çevirin

tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])

tartimlar[''starttime''] = pd.to_datetime(tartimlar[''starttime''])

# Bir önceki gün için verileri filtreleyin

bir_onceki_gun = datetime.now() - timedelta(days=1)

bir_onceki_gun = bir_onceki_gun.replace(hour=0, minute=0, second=0)

tartimlar = tartimlar[(tartimlar[''requestid_starttime''] >= bir_onceki_gun) & (tartimlar[''requestid_starttime''] < bir_onceki_gun + timedelta(days=1))]

# Negatif sapma olan tartımları bul

negatif_sapma_tartimlar = tartimlar[tartimlar[''deviation''] < 0]

# Sapma %''sini hesapla

negatif_sapma_tartimlar[''sapma_yuzde''] = (negatif_sapma_tartimlar[''deviation''] / negatif_sapma_tartimlar[''targetamount'']) * 100

# Fabrika ve mekatronik sistem bazında toplam detailid sayısını listele

liste1 = negatif_sapma_tartimlar.groupby([''companyname'', ''displayname'']).size().reset_index(name=''%5 ten Fazla Sapan Toplam Tartım Sayısı'')

# Fabrika ve mekatronik sistem bazında ortalama sapma %''sini listele

liste2 = negatif_sapma_tartimlar.groupby([''companyname'', ''displayname''])[''sapma_yuzde''].mean().reset_index()

liste2 = liste2[liste2[''sapma_yuzde''] < -5]

# Liste2''de sapma''nın %-5''ten fazla olduğu satırları filtrele

liste2 = liste2[liste2[''sapma_yuzde''] < -5]

# Liste1 ve Liste2''yi fabrika ve mekatronik sistem bazında inner join yap

sonuc = pd.merge(liste1, liste2, on=[''companyname'', ''displayname''])

# Sütun isimlerini değiştir

sonuc = sonuc.rename(columns={''companyname'': ''Fabrika İsmi'', ''displayname'': ''Sistem ismi'', ''sapma_yuzde'': ''Günlük Ortalama Sapma %''})

# Günlük Ortalama Sapma %''sini virgülden sonra 2 basamak olacak şekilde yuvarla

sonuc[''Günlük Ortalama Sapma %''] = sonuc[''Günlük Ortalama Sapma %''].round(2)

# HTML için hazırla

html = sonuc[[''Fabrika İsmi'', ''Sistem ismi'', ''%5 ten Fazla Sapan Toplam Tartım Sayısı'', ''Günlük Ortalama Sapma %'']].to_html(index=False)



if not sonuc.empty:

    try:

        msg = MIMEMultipart()

        msg[''From''] = ''eliar.arge@gmail.com''

        msg[''To''] = '', ''.join([''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''])

        msg[''Subject''] = ''Günlük Ortalama Negatif Sapma Oranı Yüksek Olan Mekatronik Sistemler''

        body = """

        <h2>Anomali Ölçütü</h2>

        <p>{}</p>

        """.format(bir_onceki_gun.strftime(''%Y-%m-%d'') + '' tarihi için ortalama negatif sapması %-5\''ten fazla olan sistemler.'')

        body += html

        msg.attach(MIMEText(body, ''html''))

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(msg[''From''], ''ximjomxcivdluwkv'')

        server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

        server.quit()

    except Exception as e:

        for _ in range(5):

            try:

                msg = MIMEMultipart()

                msg[''From''] = ''eliar.arge@gmail.com''

                msg[''To''] = '', ''.join([''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''])

                msg[''Subject''] = ''Günlük Ortalama Negatif Sapma Oranı Yüksek Olan Mekatronik Sistemler''

                body = """

                <h2>Anomali Ölçütü</h2>

                <p>{}</p>

                """.format(bir_onceki_gun.strftime(''%Y-%m-%d'') + '' tarihi için ortalama negatif sapması %-5\''ten fazla olan sistemler.'')

                body += html

                msg.attach(MIMEText(body, ''html''))

                server = smtplib.SMTP(''smtp.gmail.com'', 587)

                server.starttls()

                server.login(msg[''From''], ''ximjomxcivdluwkv'')

                server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

                server.quit()

                break

            except Exception as e:

                import time

                time.sleep(5)

else:

    print("Liste boş, mail atılmayacak.")


',NULL,false),
	 (2,'''satis_siparis_verileri.csv'' dosyasını oku. ''BrutKarAnaGrubu'' ve ''BrutKarGrubu'' sütununlarında ''-'' veya ''Lütfen Seçiniz'' değerine sahip olan satırları listele. SiparisTarihi sütunu yesterday (yesterday tarihi datetime türüne dönüştürülmelidir) tarihine eşit olanları filtrele. Yesterday karşılaştırması yıl-ay-gün formatında olmalıdır. Listede sadece Firma, Yil, SiparisTarihi, MalzemeHizmetKodu, MalzemeHizmetKodu2, MalzemeHizmet , BrutKarAnaGrubu , BrutKarGrubu sütunları bulunacak. Liste boş değilse listeyi mail at. Mail içeriğine başlık ekleme, sadece listeyi yolla. Mail konu başlığı ''Satış Sipariş Kar Grubu Boş Olan Veriler'' olsun.  Liste boş ise ''Anomali asistanı {(pd.to_datetime(''now'') - pd.Timedelta(days=1)).strftime(''%d.%m.%Y'')}'' daki verilerde anomali bulmamıştır'' metnini mail at. ','{"times": [{"minute": "36", "hour": "07", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

import smtplib

from email.mime.text import MIMEText

from email.mime.multipart import MIMEMultipart

from datetime import datetime, timedelta

import time

# Read the CSV file

df = pd.read_csv(''satis_siparis_verileri.csv'')

# Filter the data

yesterday = (pd.to_datetime(''now'') - pd.Timedelta(days=1)).strftime(''%Y-%m-%d'')

df_filtered = df[(df[''SiparisTarihi''] == yesterday) & ((df[''BrutKarAnaGrubu''] == ''-'') | (df[''BrutKarAnaGrubu''] == ''Lütfen Seçiniz'') | (df[''BrutKarGrubu''] == ''-'') | (df[''BrutKarGrubu''] == ''Lütfen Seçiniz''))]

# Create the email content

if not df_filtered.empty:

    html_content = ''<h2>Satış Sipariş Kar Grubu Boş Olan Veriler</h2>''

    html_content += df_filtered[[''Firma'', ''Yil'', ''SiparisTarihi'', ''MalzemeHizmetKodu'', ''MalzemeHizmetKodu2'', ''MalzemeHizmet'', ''BrutKarAnaGrubu'', ''BrutKarGrubu'']].to_html(index=False)

else:

    html_content = ''<h2>Anomali asistanı</h2>''

    html_content += f''Anomali asistanı {(pd.to_datetime("now") - pd.Timedelta(days=1)).strftime("%d.%m.%Y")} daki verilerde anomali bulmamıştır''

# Send the email

try:

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satış Sipariş Kar Grubu Boş Olan Veriler''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ''sencer.sultanoglu@eliarge.com,zeynep.dundar@eliar.com.tr,mehmet.taygun@eliar.com.tr''

    msg.attach(MIMEText(html_content, ''html''))

    server = smtplib.SMTP(''smtp.gmail.com'', 587)

    server.starttls()

    server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

    server.sendmail(''eliar.arge@gmail.com'', [''sencer.sultanoglu@eliarge.com'',''zeynep.dundar@eliar.com.tr'',''mehmet.taygun@eliar.com.tr''], msg.as_string())

    server.quit()

except Exception as e:

    print(f''Error sending email: {e}'')

    for i in range(5):


        try:

            server.sendmail(''eliar.arge@gmail.com'', [''sencer.sultanoglu@eliarge.com'',''zeynep.dundar@eliar.com.tr'',''mehmet.taygun@eliar.com.tr''], msg.as_string())

            break

        except Exception as e:

            print(f''Retrying to send email: {e}'')

            time.sleep(5)',NULL,false),
	 (1,'17:08 doluluk oranı fazla olan makineler','{"times": [{"minute": "08", "hour": "17", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
from datetime import datetime, timedelta
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# Verileri oku
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

# requestid_starttime sütununu datetime''a çevir
tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])

# Bir önceki gün için verileri filtrele
bir_onceki_gun = datetime.now() - timedelta(days=1)
bir_onceki_gun = bir_onceki_gun.replace(hour=0, minute=0, second=0)

tartimlar_bir_onceki_gun = tartimlar[tartimlar[''requestid_starttime''].dt.date == bir_onceki_gun.date()]

# Fabrika ve mekatronik sistem bazında duration sütununu topla
toplam_sure = tartimlar_bir_onceki_gun.groupby([''companyname'', ''displayname''])[''duration''].sum().reset_index()

# Doluluk oranını hesapla
toplam_sure[''Doluluk Oranı[%]''] = (toplam_sure[''duration''] / 86400) * 100

# Sütun isimlerini değiştir
toplam_sure = toplam_sure.rename(columns={''companyname'': ''Fabrika İsmi'', ''displayname'': ''Sistem ismi''})

# %18''in üstünde olanları listele
doluluk_orani_yuksek = toplam_sure[toplam_sure[''Doluluk Oranı[%]''] > 18]

# E-posta listesi (umut çıkarıldı)
email_list = [
    ''sencer.sultanoglu@eliarge.com'',
    ''ozcan.ozen@eliar.com.tr'',
    ''sshmekatronik@eliar.com.tr'',
    ''mehmet.taygun@eliar.com.tr'',
    ''kursat.akyol@eliar.com.tr''
]

# Liste boş değilse mail at
if not doluluk_orani_yuksek.empty:
    html = doluluk_orani_yuksek[[''Fabrika İsmi'', ''Sistem ismi'', ''Doluluk Oranı[%]'']].round(2).to_html(index=False)

    body = f"""
    <h1>Doluluk Oranı Fazla Olan Mekatronik Sistemler</h1>
    <h2>Anomali Ölçütü</h2>
    <p>{bir_onceki_gun.strftime(''%d.%m.%Y'')} tarihi için doluluk oranı %18''in üstünde olan sistemler</p>
    {html}
    """

    for _ in range(5):
        try:
            msg = MIMEMultipart()
            msg[''From''] = ''eliar.arge@gmail.com''
            msg[''To''] = '', ''.join(email_list)
            msg[''Subject''] = ''Doluluk Oranı Fazla Olan Mekatronik Sistemler''
            msg.attach(MIMEText(body, ''html''))

            server = smtplib.SMTP(''smtp.gmail.com'', 587)
            server.starttls()
            server.login(msg[''From''], ''ximjomxcivdluwkv'')
            server.sendmail(msg[''From''], email_list, msg.as_string())
            server.quit()
            break
        except Exception as e:
            print(f"Mail atma hatası: {e}")
            import time
            time.sleep(5)
',NULL,false),
	 (2,'07:28  -  satın alma fiyat anomalisi - orjinal, 18 ile aynı','{"times": [{"minute": "30", "hour": "07", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','
import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

import numpy as np

from datetime import datetime, timedelta

import smtplib

from email.mime.text import MIMEText

# Load the data

df = pd.read_csv(''satin_alma_verileri.csv'')

# Convert FaturaTarihi column to datetime

df[''FaturaTarihi''] = pd.to_datetime(df[''FaturaTarihi''], errors=''coerce'')

# Remove rows with FaturaNo = ''BOŞ''

df = df[df[''FaturaNo''] != ''BOŞ'']

# Filter data for the last 6 months

today = pd.Timestamp.now()

six_months_ago = today - pd.Timedelta(days=180)

df = df[df[''FaturaTarihi''] >= six_months_ago]

# Calculate the average IrsEuroBirimFiyat for each MalzemeHizmetKodu

avg_irseurobirimfiyat = df.groupby(''MalzemeHizmetKodu'')[''IrsEuroBirimFiyat''].mean()

df[''Ortalama IrsEuroBirimFiyat''] = df[''MalzemeHizmetKodu''].map(avg_irseurobirimfiyat)

# Calculate the percentage deviation from the average IrsEuroBirimFiyat

df[''Euro Birim Fiyat % Sapma''] = ((df[''IrsEuroBirimFiyat''] - df[''Ortalama IrsEuroBirimFiyat'']) / df[''Ortalama IrsEuroBirimFiyat'']) * 100

# Filter rows with Euro Birim Fiyat % Sapma > 20%

anomaly_df = df[df[''Euro Birim Fiyat % Sapma''] > 20]

# Filter rows with FaturaTarihi equal to yesterday

yesterday = today - pd.Timedelta(days=1)

anomaly_df = anomaly_df[anomaly_df[''FaturaTarihi''].dt.date == yesterday.date()]

# Select only the required columns

anomaly_df = anomaly_df[[''FaturaTarihi'', ''FaturaNo'', ''Isyeri'', ''MalzemeHizmetKodu'', ''MalzemeHizmet'', ''SiparisiEkleyen'', ''IrsEuroBirimFiyat'', ''Ortalama IrsEuroBirimFiyat'', ''Euro Birim Fiyat % Sapma'']]

# Format numerical columns to 3 decimal places

for col in anomaly_df.select_dtypes(include=[np.number]):

    anomaly_df[col] = anomaly_df[col].apply(lambda x: ''{:.3f}''.format(x))

# Add ''%'' symbol to Sapma column

anomaly_df[''Euro Birim Fiyat % Sapma''] = anomaly_df[''Euro Birim Fiyat % Sapma''].apply(lambda x: ''{}%''.format(x))

# Convert to HTML

html = anomaly_df.to_html(index=False)

# Send email if anomaly_df is not empty

if not anomaly_df.empty:

    subject = ''Satın Alma Fiyat Anomalisi''

    body = html

else:

    subject = ''Satın Alma Fiyat Anomalisi''

    body = ''Anomali asistanı {} da kapanan faturalarda anomali bulmamıştır''.format((pd.to_datetime(''now'') - pd.Timedelta(days=1)).strftime(''%d.%m.%Y''))


# Send email


msg = MIMEMultipart()

msg[''Subject''] = ''Satın Alma Fiyat Anomalisi''

msg[''From''] = ''eliar.arge@gmail.com''

msg[''To''] = ''sencer.sultanoglu@eliarge.com''

if not anomaly_df.empty:

    msg.attach(MIMEText(html, ''html''))

else:

    msg.attach(MIMEText(f''Anomali asistanı {(pd.to_datetime("now") - pd.Timedelta(days=1)).strftime("%d.%m.%Y")} da kapanan faturalarda anomali bulmamıştır'', ''plain''))

# Send the email

try:

    server = smtplib.SMTP(''smtp.gmail.com'', 587)

    server.starttls()

    server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

    server.sendmail(''eliar.arge@gmail.com'', [''sencer.sultanoglu@eliarge.com''], msg.as_string())

    server.quit()

except Exception as e:

    print(f''Error sending email: {e}'')

    for i in range(5):


        try:

            server = smtplib.SMTP(''smtp.gmail.com'', 587)

            server.starttls()

            server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

            server.sendmail(''eliar.arge@gmail.com'', [''umut.sahin@eliarge.com'', ''zeynep.dundar@eliar.com.tr'', ''sencer.sultanoglu@eliarge.com'', ''mehmet.taygun@eliar.com.tr''], msg.as_string())

            server.quit()

            break

        except Exception as e:

            print(f''Retrying to send email: {e}'')

            time.sleep(5)
',NULL,false),
	 (3,'16:40 veri gelmeyen sistemlerin olası raporu','{"times": [{"minute": "40", "hour": "16", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
import smtplib
import time
import warnings
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# Bir önceki günün tarihini hesaplayın
bugun = datetime.today()
filter_date = (bugun - timedelta(days=2)).strftime(''%Y-%m-%d'')

# CSV dosyasını oku
df = pd.read_csv(''raw_logs.csv'')

# Hataları filtrele
ssh_problems = [
    ''scp ile Veritabani cekilirken zaman asimi oldu'',
    ''Ping atılamıyor. Varsa diğer sisteme geçiliyor. Başka sistem yoksa diğer fabrikaya geçiliyor.'',
    ''Papıtır veya Secomea islemlerinde hata olustu.'',
    ''scp komutu calisirken problem meydana geldi. scp return code: 1'',
    ''MSSQL baglantisi yapilamadi.''
]

# issuccess=0 olan ve SSH Ekibinin çözmesi gereken problemleri filtrele
filtered_df = df[(df[''issuccess''] == 0) & (df[''log_message''].isin(ssh_problems))]

# Gerekli sütunları seç ve isimlerini değiştir
result_df = filtered_df[[''companyname'', ''displayname'', ''msystemid'', ''veri_alma_tarihi'', ''jobdate'']]
result_df[''problem_causes''] = filtered_df[''log_message''].map({
    ''scp ile Veritabani cekilirken zaman asimi oldu'': ''OpenSSH server kurulumu doğru yapılamamış olabilir. Devreye Alım için girilen bilgilerde yanlışlık olabilir.'',
    ''Ping atılamıyor. Varsa diğer sisteme geçiliyor. Başka sistem yoksa diğer fabrikaya geçiliyor.'': ''Cihaz internet bağlantısı zayıf olabilir. IP bilgisi veritabanına yanlış kayıt edilmiş olabilir.'',
    ''Papıtır veya Secomea islemlerinde hata olustu.'': ''Secoma kırmızı bayrak olabilir.'',
    ''scp komutu calisirken problem meydana geldi. scp return code: 1'': ''OpenSSH server kurulumu doğru yapılamamış olabilir. Devreye Alım için girilen bilgilerde yanlışlık olabilir.'',
    ''MSSQL baglantisi yapilamadi.'': ''MSSQL Bağlantı bilgileri yanlış girilmiş olabilir.''
})

result_df.columns = [''Fabrika İsmi'', ''Sistem İsmi'', ''msystemid'', ''Sistemdeki Son Veri Tarihi'', ''Kayıt Tarihi'', ''Olası Sebepler'']

# Listeyi jobdate bazında azalan şekilde sırala ve tekrarlayanları sil
result_df = result_df.sort_values(by=''Kayıt Tarihi'', ascending=False).drop_duplicates(
    subset=[''Fabrika İsmi'', ''msystemid'', ''Sistemdeki Son Veri Tarihi'', ''Olası Sebepler''],
    keep=''first''
)

# Veri tarihi filtrele
result_df[''Sistemdeki Son Veri Tarihi''] = pd.to_datetime(result_df[''Sistemdeki Son Veri Tarihi''])
result_df = result_df[
    result_df[''Sistemdeki Son Veri Tarihi''].isna() |
    (result_df[''Sistemdeki Son Veri Tarihi''].dt.date < pd.to_datetime(filter_date).date())
]

# Tarihi string yap ve boşlara ''Hiç Veri Yok'' yaz
result_df[''Sistemdeki Son Veri Tarihi''] = result_df[''Sistemdeki Son Veri Tarihi''].dt.strftime(''%Y-%m-%d'')
result_df[''Sistemdeki Son Veri Tarihi''] = result_df[''Sistemdeki Son Veri Tarihi''].fillna(''Hiç Veri Yok'')
result_df = result_df.drop(columns=[''Kayıt Tarihi'', ''msystemid''])

# HTML olarak kaydet
result_df.to_html(''output.html'', index=False)

# Mail atma işlemi
if not result_df.empty:
    mail_content = "Son 3 gündür veri alınmayan sistemler raporlanmıştır."

    msg = MIMEMultipart()
    msg[''From''] = ''eliar.arge@gmail.com''
    msg[''To''] = ''sencer.sultanoglu@eliarge.com,ozcan.ozen@eliar.com.tr,sshmekatronik@eliar.com.tr''
#    msg[''To''] = ''sencer.sultanoglu@eliarge.com''
    msg[''Subject''] = ''Veri Gelmeyen Sistemlerin Olası Sebepleri Raporu''

    msg.attach(MIMEText(mail_content + result_df.to_html(index=False) + ''''''
<br><br>
Aşağıda olası problemler ve bu problemler için ne yapılması gerektiği belirtilmiştir:<br>
<b>Problem 1:</b> ''Cihaz internet bağlantısı zayıf olabilir. IP bilgisi veritabanına yanlış kayıt edilmiş olabilir.''<br>
1- Devreye Alım Ekranındaki bilgiler (IP, Layer 1 vs.) kontrol edilmelidir.<br>
2- Cihazda Secomea üzerinden ping testi yapılmalıdır.<br><br>

<b>Problem 2:</b> ''Secoma kırmızı bayrak olabilir.''<br>
1- Fabrika Secome''da kırmızı bayrak mı kontrol edilmelidir.<br>
2- Cihaz açık ise cihaza ping atılmaya çalışılmalıdır.<br><br>

<b>Problem 3:</b> ''OpenSSH server kurulumu doğru yapılamamış olabilir. Devreye Alım için girilen bilgilerde yanlışlık olabilir.''<br>
1- Devreye Alım Ekranındaki devreye alım bilgileri kontrol edilmelidir.<br>
2- test_connection.exe uygulaması kullanılarak bağlantı testi yapılmalıdır.<br>
3- Cihazda OpenSSH kurulumu yapılıp yapılmadığı kontrol edilmelidir.<br><br>

<b>Problem 4:</b> ''MSSQL baglantisi yapilamadi.''<br>
1- Devreye alım ekranında girilen MSSQL bağlantı bilgileri kontrol edilmelidir.<br>
2- test_connection.exe uygulaması kullanılarak bağlantı testi yapılmalıdır.<br>
'''''', ''html''))

    for attempt in range(5):
        try:
            server = smtplib.SMTP(''smtp.gmail.com'', 587)
            server.starttls()
            server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')
            server.send_message(msg)
            server.quit()
            break
        except Exception:
            time.sleep(5)
',NULL,false),
	 (1,'Bir önceki gün için deviation sütununun pozitif olduğu tartımları bul. Tartımların sapma %’sini (deviation / targetamount)*100 formülü ile hesapla. Fabrika ve mekatronik sistem bazında toplam detailid sayısını listele [liste1]. Fabrika ve mekatronik sistem bazında ortalama sapma %''sini listele [liste2]. [liste2]''de sapma''nın %''5''ten büyük olduğu satırları filtrele. [liste1] ve [liste2]''yi fabrika ve mekatronik sistem bazında inner join yap. HTML için kullanacağın kullanacağın sütun isimlerini şu şekilde değiştirmelisin: ''Fabrika İsmi'', ''Sistem ismi'', ''%5 ten Fazla Sapan Toplam Tartım Sayısı'', ''Günlük Ortalama Sapma %'' olsun. ''Günlük Ortalama Sapma %'' sütunu virgülden sonra 2 basamak olsun. HTML''de başka hiçbir sütun bilgisi olmamalı. Liste boş değilse mail at, boş ise mail atma.  Mail konusuna ‘Günlük Ortalama Pozitif Sapma Oranı Yüksek Olan Mekatronik Sistemler’ yazmalısın. Mail''e, ''Anomali Ölçütü'' adlı 2. başlık ekle. 2. Başlık altında, ''[bir önceki gün tarihi] tarihi için ortalama pozitif sapması %5''ten fazla olan sistemler.'' metnini yaz.','{"times": []}','



import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

from datetime import datetime, timedelta

import smtplib

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

# Verileri yükleyin

tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

# Bir önceki günün tarihini hesaplayın

bugun = datetime.today()

dun = bugun - timedelta(days=1)

dun_tarihi = dun.strftime(''%Y-%m-%d'')

# Bir önceki gün için pozitif sapma olan tartımları bul

tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])

pozitif_sapma_tartimlari = tartimlar[(tartimlar[''requestid_starttime''].dt.date == pd.to_datetime(dun_tarihi).date()) & (tartimlar[''deviation''] > 0)]

# Sapma %''sini hesaplayın

pozitif_sapma_tartimlari[''sapma_yuzdesi''] = (pozitif_sapma_tartimlari[''deviation''] / pozitif_sapma_tartimlari[''targetamount'']) * 100

# Fabrika ve mekatronik sistem bazında toplam detailid sayısını listele

liste1 = pozitif_sapma_tartimlari.groupby([''companyname'', ''displayname'']).size().reset_index(name=''Toplam Detailid Sayısı'')

# Fabrika ve mekatronik sistem bazında ortalama sapma %''sini listele

liste2 = pozitif_sapma_tartimlari.groupby([''companyname'', ''displayname''])[''sapma_yuzdesi''].mean().reset_index()

liste2 = liste2[liste2[''sapma_yuzdesi''] > 5]

# Liste1 ve Liste2''yi inner join yap

sonuc = pd.merge(liste1, liste2, on=[''companyname'', ''displayname''])

# Sütun isimlerini değiştir

sonuc = sonuc.rename(columns={''companyname'': ''Fabrika İsmi'', ''displayname'': ''Sistem ismi'', ''Toplam Detailid Sayısı'': ''%5 ten Fazla Sapan Toplam Tartım Sayısı'', ''sapma_yuzdesi'': ''Günlük Ortalama Sapma %''})

# ''Günlük Ortalama Sapma %'' sütununu virgülden sonra 2 basamak olacak şekilde yuvarla

sonuc[''Günlük Ortalama Sapma %''] = sonuc[''Günlük Ortalama Sapma %''].round(2)

# HTML için hazırla

html = sonuc[[''Fabrika İsmi'', ''Sistem ismi'', ''%5 ten Fazla Sapan Toplam Tartım Sayısı'', ''Günlük Ortalama Sapma %'']].to_html(index=False)




if not sonuc.empty:

    try:

        msg = MIMEMultipart()

        msg[''From''] = ''eliar.arge@gmail.com''

        msg[''To''] = '', ''.join([''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''])

        msg[''Subject''] = ''Günlük Ortalama Pozitif Sapma Oranı Yüksek Olan Mekatronik Sistemler''

        

        body = ''<h1>Günlük Ortalama Pozitif Sapma Oranı Yüksek Olan Mekatronik Sistemler</h1>''

        body += ''<h2>Anomali Ölçütü</h2>''

        body += f''<p>{dun_tarihi} tarihi için ortalama pozitif sapması %5\''ten fazla olan sistemler.</p>''

        body += html

        

        msg.attach(MIMEText(body, ''html''))

        

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(msg[''From''], ''ximjomxcivdluwkv'')

        server.sendmail(msg[''From''],[''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Mail atma işlemi başarısız: {e}")

        for _ in range(5):

            try:

                server = smtplib.SMTP(''smtp.gmail.com'', 587)

                server.starttls()

                server.login(msg[''From''], ''ximjomxcivdluwkv'')

                server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

                server.quit()

                break

            except Exception as e:

                print(f"Mail atma işlemi başarısız: {e}")

                import time

                time.sleep(5)

else:

    print("Liste boş, mail atılmayacak.")
',NULL,false),
	 (1,'Bir önceki gün için fabrika ve mekatronik sistem bazında toplam alarm sayısını hesapla. Ardından toplam alarm sayılarını toplam gün sayısına böl ve 5''ten büyük olanları listele. Liste boş değilse mail at, boş ise mail atma. HTML için kullanacağın dataframedeki sütun isimlerini şu şekilde değiştirmelisin: ''Fabrika İsmi'', ''Sistem ismi'', ''Günlük Ortalama Alarm Sayısı'' olsun.HTML''de başka hiçbir sütun bilgisi olmamalı. ''Günlük Ortalama Alarm Sayısı'' değerinin ondalık basamak sayısı 2 olsun.  Mail konusuna ''Fazla Alarm Veren Mekatronik Sistemler'' yazmalısın. Mail''e, ''Anomali Ölçütü'' adlı 2. başlık ekle. 2. Başlık altında, ''[bir önceki gün tarihi] tarihi için günlük ortalama alarm sayısı 5''ten fazla olan sistemler'' metnini yaz.','{"times": []}','

import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

from datetime import datetime, timedelta

import smtplib

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

# Verileri oku

tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

alarmlar = pd.read_csv(''mekatronik_sistem_alarmları.csv'')

# Bir önceki günün tarihini hesapla

bugun = datetime.today()

dun = bugun - timedelta(days=1)

dun_tarihi = dun.strftime(''%Y-%m-%d'')

# Bir önceki gün için fabrika ve mekatronik sistem bazında toplam alarm sayısını hesapla

alarmlar[''alarm_start_time''] = pd.to_datetime(alarmlar[''alarm_start_time''])

alarmlar_dun = alarmlar[(alarmlar[''alarm_start_time''].dt.date == dun.date())]

toplam_alarmlar = alarmlar_dun.groupby([''companyname'', ''displayname'']).size().reset_index(name=''toplam_alarm_sayisi'')

# Toplam alarm sayılarını toplam gün sayısına böl

toplam_gun_sayisi = 1  # Bir önceki gün için

ortalama_alarmlar = toplam_alarmlar.copy()

ortalama_alarmlar[''toplam_alarm_sayisi''] = ortalama_alarmlar[''toplam_alarm_sayisi''] / toplam_gun_sayisi

# 5''ten büyük olanları listele

fazla_alarmlı_sistemler = ortalama_alarmlar[ortalama_alarmlar[''toplam_alarm_sayisi''] > 5]

# Liste boş değilse mail at, boş ise mail atma

if not fazla_alarmlı_sistemler.empty:

    # HTML için kullanacağın dataframedeki sütun isimlerini değiştir

    fazla_alarmlı_sistemler = fazla_alarmlı_sistemler[[''companyname'', ''displayname'', ''toplam_alarm_sayisi'']]

    fazla_alarmlı_sistemler.columns = [''Fabrika İsmi'', ''Sistem ismi'', ''Günlük Ortalama Alarm Sayısı'']

    fazla_alarmlı_sistemler[''Günlük Ortalama Alarm Sayısı''] = fazla_alarmlı_sistemler[''Günlük Ortalama Alarm Sayısı''].round(2)

    # HTML oluştur

    html = fazla_alarmlı_sistemler.to_html(index=False)

    # Mail at

    try:

        msg = MIMEMultipart()

        msg[''From''] = ''eliar.arge@gmail.com''

        msg[''To''] = '', ''.join([''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''])

        msg[''Subject''] = ''Fazla Alarm Veren Mekatronik Sistemler''

        body = f"""

        <h1>Fazla Alarm Veren Mekatronik Sistemler</h1>

        <h2>Anomali Ölçütü</h2>

        <p>{dun_tarihi} tarihi için günlük ortalama alarm sayısı 5''ten fazla olan sistemler</p>

        {html}

        """

        msg.attach(MIMEText(body, ''html''))

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(msg[''From''], ''ximjomxcivdluwkv'')

        server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Mail atma sırasında hata oluştu: {e}")

        for _ in range(5):

            try:

                msg = MIMEMultipart()

                msg[''From''] = ''eliar.arge@gmail.com''

                msg[''To''] = '', ''.join([''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''])

                msg[''Subject''] = ''Fazla Alarm Veren Mekatronik Sistemler''

                body = f"""

                <h1>Fazla Alarm Veren Mekatronik Sistemler</h1>

                <h2>Anomali Ölçütü</h2>

                <p>{dun_tarihi} tarihi için günlük ortalama alarm sayısı 5''ten fazla olan sistemler</p>

                {html}

                """

                msg.attach(MIMEText(body, ''html''))

                server = smtplib.SMTP(''smtp.gmail.com'', 587)

                server.starttls()

                server.login(msg[''From''], ''ximjomxcivdluwkv'')

                server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

                server.quit()

                break

            except Exception as e:

                print(f"Mail atma sırasında hata oluştu: {e}")

                import time

                time.sleep(5)

',NULL,false),
	 (1,'Bir önceki gün için deviation sütununun pozitif olduğu tartımları bul. Tartımların sapma %’sini (deviation / targetamount)*100 formülü ile hesapla.  Tabloda sapma''nın %''5''ten büyük olduğu satırları filtrele. HTML için kullanacağın  tablodaki sütun isimlerini şu şekilde değiştirmelisin: ''Fabrika İsmi'', ''Sistem ismi'', ''Kimyasal İsmi'', ''Hedef Miktar'','' Gerçekleşen Miktar'',''Sapma % '' olsun. HTML''de başka hiçbir sütun bilgisi olmamalı. Tablo boş değilse mail at, boş ise mail atma. Mail konusuna ‘Pozitif Sapma Yüzdesi Yüksek Olan Tartımlar'' yazmalısın. Mail''e, ''Anomali Ölçütü'' adlı 2. başlık ekle. 2. Başlık altında, '' [bir önceki gün tarihi] tarihi için pozitif sapma oranı %5''ten fazla olan tartımların raporu.'' metnini yaz. ','{"times": []}','



import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

from datetime import datetime, timedelta

import matplotlib.pyplot as plt

import smtplib

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

# Verileri yükleyin
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

# requestid_starttime ve starttime sütunlarını datetime''a çevirin
tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])
tartimlar[''starttime''] = pd.to_datetime(tartimlar[''starttime''])

# Bir önceki gün için verileri filtreleyin
bir_onceki_gun = datetime.now() - timedelta(days=1)
bir_onceki_gun = bir_onceki_gun.replace(hour=0, minute=0, second=0, microsecond=0)

tartimlar = tartimlar[(tartimlar[''requestid_starttime''] >= bir_onceki_gun) & 
                      (tartimlar[''requestid_starttime''] < bir_onceki_gun + timedelta(days=1))]

# Pozitif sapma olan tartımları bul
pozitif_sapma_tartimlar = tartimlar[tartimlar[''deviation''] > 0]

# Sapma %''sini hesapla
pozitif_sapma_tartimlar[''sapma_yuzde''] = (pozitif_sapma_tartimlar[''deviation''] / pozitif_sapma_tartimlar[''targetamount'']) * 100

# targetamount değerine göre iki farklı veri kümesi oluştur
greater_500 = pozitif_sapma_tartimlar[pozitif_sapma_tartimlar[''targetamount''] > 500]
less_500 = pozitif_sapma_tartimlar[pozitif_sapma_tartimlar[''targetamount''] <= 500]

# Pivot tabloları oluştur
pivot_greater_500 = greater_500[[''companyname'', ''displayname'', ''chemical_name'', ''targetamount'', ''consumedamount'',''sapma_yuzde'']]
pivot_greater_500_filtered = pivot_greater_500[pivot_greater_500[''sapma_yuzde'']>=5]
pivot_greater_500_filtered[''sapma_yuzde''] = pivot_greater_500_filtered[''sapma_yuzde''].round(2)
pivot_greater_500_filtered[''targetamount''] = pivot_greater_500_filtered[''targetamount''].round(2)
pivot_greater_500_filtered[''consumedamount''] = pivot_greater_500_filtered[''consumedamount''].round(2)
pivot_greater_500_filtered = pivot_greater_500_filtered.sort_values(
    by=[''companyname'',''displayname'',''sapma_yuzde''],
    ascending=[False,False,False]
).reset_index(drop=True)
                                   

pivot_less_500 = less_500[[''companyname'', ''displayname'', ''chemical_name'', ''targetamount'', ''consumedamount'',''sapma_yuzde'']]
pivot_less_500_filtered = pivot_less_500[pivot_less_500[''sapma_yuzde'']>=5]
pivot_less_500_filtered[''sapma_yuzde''] = pivot_less_500_filtered[''sapma_yuzde''].round(2)
pivot_less_500_filtered[''targetamount''] = pivot_less_500_filtered[''targetamount''].round(2)
pivot_less_500_filtered[''consumedamount''] = pivot_less_500_filtered[''consumedamount''].round(2)
pivot_less_500_filtered = pivot_less_500_filtered.sort_values(
    by=[''companyname'',''displayname'',''sapma_yuzde''],
    ascending=[False,False,False]
).reset_index(drop=True)

pivot_greater_500_filtered.rename(columns={
    ''companyname'': ''Fabrika İsmi'',
    ''displayname'': ''Sistem İsmi'',
    ''chemical_name'': ''Kimyasal İsmi'',
    ''targetamount'': ''Hedef Miktar'',
    ''consumedamount'': ''Tartılan Miktar'',
    ''sapma_yuzde'': ''Sapma %\''si''
}, inplace=True)

pivot_less_500_filtered.rename(columns={
    ''companyname'': ''Fabrika İsmi'',
    ''displayname'': ''Sistem İsmi'',
    ''chemical_name'': ''Kimyasal İsmi'',
    ''targetamount'': ''Hedef Miktar'',
    ''consumedamount'': ''Tartılan Miktar'',
    ''sapma_yuzde'': ''Sapma %\''si''
}, inplace=True)


# HTML oluştur
html = """
<h2>Hedef Miktarı 500''den Büyük Olanlar</h2>
"""
html += pivot_greater_500_filtered.to_html() if not pivot_greater_500_filtered.empty else "<p>Anomali tespit edilememiştir.</p>"
html += """
<h2>Hedef Miktarı 500''den Küçük veya Eşit Olanlar</h2>
"""
html += pivot_less_500_filtered.to_html() if not pivot_less_500_filtered.empty else "<p>Anomali tespit edilememiştir.</p>"

# Eğer en az bir tablo doluysa mail gönder
if not pivot_greater_500_filtered.empty or not pivot_less_500_filtered.empty:

    try:

        msg = MIMEMultipart()

        msg[''From''] = ''eliar.arge@gmail.com''

        msg[''To''] = '', ''.join([''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''])

        msg[''Subject''] = ''Pozitif Sapma Yüzdesi Yüksek Olan Tartımlar''

        body = ''<h2>Anomali Ölçütü</h2><p>[{}] tarihi için pozitif sapma oranı %5\''ten fazla olan tartımların raporu.</p>''.format(bir_onceki_gun.strftime(''%d-%m-%Y''))

        body += html

        msg.attach(MIMEText(body, ''html''))

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(msg[''From''], ''ximjomxcivdluwkv'')

        server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

        server.quit()

    except Exception as e:

        for _ in range(5):

            try:

                server = smtplib.SMTP(''smtp.gmail.com'', 587)

                server.starttls()

                server.login(msg[''From''], ''ximjomxcivdluwkv'')

                server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

                server.quit()

                break

            except Exception as e:

                import time

                time.sleep(5)
',NULL,false),
	 (2,'PROJE DEPO','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''PROJE DEPO'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,projedepo@eliar.com.tr,engin.reyhan@eliar.com.tr',false,NULL),
	 (1,'Bir önceki gün için deviation sütununun negatif olduğu tartımları bul. Tartımların sapma %’sini (deviation / targetamount)*100 formülü ile hesapla. Fabrika, mekatronik sistem, kimyasal ismi bazında toplam detailid sayısını ve sapma''nın %-5''ten küçük olduğu toplam detailid sayısını pivot tablo halinde listele. Pivot tabloda sapma''nın %-5''ten küçük olduğu satırları filtrele. HTML için kullanacağın pivot tablodaki sütun isimlerini şu şekilde değiştirmelisin: ''Fabrika İsmi'', ''Sistem ismi'', ''Kimyasal İsmi'', ''Toplam Tartım Sayısı'','' %-5 ten fazla sapan tartım sayısı'' olsun HTML''de başka hiçbir sütun bilgisi olmamalı. Pivot tablo boş değilse mail at, boş ise mail atma. Mail konusuna ‘Kimyasal Bazında Negatif Sapma Anomalisi Sayısı Yüksek Olan Sistemler ’ yazmalısın. Mail''e, ''Anomali Ölçütü'' adlı 2. başlık ekle. 2. Başlık altında, '' [bir önceki gün tarihi] tarihi için negatif sapma oranı %-5''ten fazla olan tartımlBir önceki gün için deviation sütununun negatif olduğu tartımları bul. Tartımların sapma %’sini (deviation / targetamount)*100 formülü ile hesapla.  Tabloda sapma''nın %5''ten küçük olduğu satırları filtrele. HTML için kullanacağın  tablodaki sütun isimlerini şu şekilde değiştirmelisin: ''Fabrika İsmi'', ''Sistem ismi'', ''Kimyasal İsmi'', ''Hedef Miktar'','' Gerçekleşen Miktar'',''Sapma % '' olsun. HTML''de başka hiçbir sütun bilgisi olmamalı. Tablo boş değilse mail at, boş ise mail atma. Mail konusuna ‘Negatif Sapma Yüzdesi Yüksek Olan Tartımlar'' yazmalısın. Mail''e, ''Anomali Ölçütü'' adlı 2. başlık ekle. 2. Başlık altında, '' [bir önceki gün tarihi] tarihi için negatif sapma oranı %-5''ten fazla olan tartımların raporu.'' metnini yaz. arın sayısı raporu.'' metnini yaz. ','{"times": []}','



import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

from datetime import datetime, timedelta

import matplotlib.pyplot as plt

import smtplib

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

# Verileri yükleyin
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

# requestid_starttime ve starttime sütunlarını datetime''a çevirin
tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])
tartimlar[''starttime''] = pd.to_datetime(tartimlar[''starttime''])

# Bir önceki gün için verileri filtreleyin
bir_onceki_gun = datetime.now() - timedelta(days=1)
bir_onceki_gun = bir_onceki_gun.replace(hour=0, minute=0, second=0, microsecond=0)

tartimlar = tartimlar[(tartimlar[''requestid_starttime''] >= bir_onceki_gun) & 
                      (tartimlar[''requestid_starttime''] < bir_onceki_gun + timedelta(days=1))]

# Pozitif sapma olan tartımları bul
pozitif_sapma_tartimlar = tartimlar[tartimlar[''deviation''] < 0]

# Sapma %''sini hesapla
pozitif_sapma_tartimlar[''sapma_yuzde''] = (pozitif_sapma_tartimlar[''deviation''] / pozitif_sapma_tartimlar[''targetamount'']) * 100

# targetamount değerine göre iki farklı veri kümesi oluştur
greater_500 = pozitif_sapma_tartimlar[pozitif_sapma_tartimlar[''targetamount''] > 500]
less_500 = pozitif_sapma_tartimlar[pozitif_sapma_tartimlar[''targetamount''] <= 500]

# Pivot tabloları oluştur
pivot_greater_500 = greater_500[[''companyname'', ''displayname'', ''chemical_name'', ''targetamount'', ''consumedamount'',''sapma_yuzde'']]
pivot_greater_500 = pivot_greater_500[pivot_greater_500[''consumedamount'']>0]
pivot_greater_500_filtered = pivot_greater_500[pivot_greater_500[''sapma_yuzde'']<=-5]
pivot_greater_500_filtered[''sapma_yuzde''] = pivot_greater_500_filtered[''sapma_yuzde''].round(2)
pivot_greater_500_filtered[''targetamount''] = pivot_greater_500_filtered[''targetamount''].round(2)
pivot_greater_500_filtered[''consumedamount''] = pivot_greater_500_filtered[''consumedamount''].round(2)
pivot_greater_500_filtered = pivot_greater_500_filtered.sort_values(
    by=[''companyname'',''displayname'',''sapma_yuzde''],
    ascending=[True,True,True]
).reset_index(drop=True)
                                   

pivot_less_500 = less_500[[''companyname'', ''displayname'', ''chemical_name'', ''targetamount'', ''consumedamount'',''sapma_yuzde'']]
pivot_less_500 = pivot_less_500[pivot_less_500[''consumedamount'']>0]
pivot_less_500_filtered = pivot_less_500[pivot_less_500[''sapma_yuzde'']<=-5]
pivot_less_500_filtered[''sapma_yuzde''] = pivot_less_500_filtered[''sapma_yuzde''].round(2)
pivot_less_500_filtered[''targetamount''] = pivot_less_500_filtered[''targetamount''].round(2)
pivot_less_500_filtered[''consumedamount''] = pivot_less_500_filtered[''consumedamount''].round(2)
pivot_less_500_filtered = pivot_less_500_filtered.sort_values(
    by=[''companyname'',''displayname'',''sapma_yuzde''],
    ascending=[True,True,True]
).reset_index(drop=True)

pivot_greater_500_filtered.rename(columns={
    ''companyname'': ''Fabrika İsmi'',
    ''displayname'': ''Sistem İsmi'',
    ''chemical_name'': ''Kimyasal İsmi'',
    ''targetamount'': ''Hedef Miktar'',
    ''consumedamount'': ''Tartılan Miktar'',
    ''sapma_yuzde'': ''Sapma %\''si''
}, inplace=True)

pivot_less_500_filtered.rename(columns={
    ''companyname'': ''Fabrika İsmi'',
    ''displayname'': ''Sistem İsmi'',
    ''chemical_name'': ''Kimyasal İsmi'',
    ''targetamount'': ''Hedef Miktar'',
    ''consumedamount'': ''Tartılan Miktar'',
    ''sapma_yuzde'': ''Sapma %\''si''
}, inplace=True)


# HTML oluştur
html = """
<h2>Hedef Miktarı 500''den Büyük Olanlar</h2>
"""
html += pivot_greater_500_filtered.to_html() if not pivot_greater_500_filtered.empty else "<p>Anomali tespit edilememiştir.</p>"
html += """
<h2>Hedef Miktarı 500''den Küçük veya Eşit Olanlar</h2>
"""
html += pivot_less_500_filtered.to_html() if not pivot_less_500_filtered.empty else "<p>Anomali tespit edilememiştir.</p>"

# Eğer en az bir tablo doluysa mail gönder
if not pivot_greater_500_filtered.empty or not pivot_less_500_filtered.empty:

    try:

        msg = MIMEMultipart()

        msg[''From''] = ''eliar.arge@gmail.com''

        msg[''To''] = '', ''.join([''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''])
        msg[''Subject''] = ''Negatif Sapma Yüzdesi Yüksek Olan Tartımlar''

        body = ''<h2>Anomali Ölçütü</h2><p>[{}] tarihi için negatif sapma oranı %-5\''ten fazla olan tartımların raporu.</p>''.format(bir_onceki_gun.strftime(''%d-%m-%Y''))

        body += html
        

        msg.attach(MIMEText(body, ''html''))

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(msg[''From''], ''ximjomxcivdluwkv'')

        server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

        server.quit()

    except Exception as e:
        
        

        for _ in range(5):

            try:

                server = smtplib.SMTP(''smtp.gmail.com'', 587)

                server.starttls()

                server.login(msg[''From''], ''ximjomxcivdluwkv'')

                server.sendmail(msg[''From''], [''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr'',''sshmekatronik@eliar.com.tr'',''mehmet.taygun@eliar.com.tr'',''kursat.akyol@eliar.com.tr''], msg.as_string())

                server.quit()

                break

            except Exception as e:

                import time

                time.sleep(5)
',NULL,false);
INSERT INTO llm_platform.auto_prompt (assistant_id,question,trigger_time,python_code,receiver_emails,mcrisactive,case_id) VALUES
	 (1,'17:12 Kuyrukta bekleme','{"times": [{"minute": "12", "hour": "17", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
import smtplib
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import warnings
import time

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# Verileri yükle
df_tartim = pd.read_csv(''mekatronik_sistem_tartımları.csv'')
df_alarmlar = pd.read_csv(''mekatronik_sistem_alarmları.csv'')

# Bir önceki günün tarihini belirle
bugun = datetime.today()
dun = bugun - timedelta(days=1)
dun_tarihi = dun.strftime(''%Y-%m-%d'')

# Bir önceki güne ait verileri filtrele
df_tartim[''requestid_starttime''] = pd.to_datetime(df_tartim[''requestid_starttime''])
df_tartim = df_tartim[df_tartim[''requestid_starttime''].dt.date == pd.to_datetime(dun_tarihi).date()]

# Toplam tartım sayısı
liste1 = df_tartim.groupby([''companyname'', ''displayname'']).size().reset_index(name=''Toplam Tartım Sayısı'')

# Kuyrukta bekleme süresi hesaplama
liste2 = df_tartim.groupby([''companyname'', ''displayname''])[''quetime''].agg([''sum'', ''min'', ''max'']).reset_index()
liste2.columns = [
    ''companyname'', ''displayname'',
    ''Toplam Kuyrukta Bekleme Süresi (saniye)'',
    ''Minimum Kuyrukta Bekleme Süresi (saniye)'',
    ''Maksimum Kuyrukta Bekleme Süresi (saniye)''
]

# İki listeyi birleştir
sonuc = pd.merge(liste1, liste2, on=[''companyname'', ''displayname''])

# 30 dakikadan fazla kuyruk süresi olanları filtrele
sonuc = sonuc[sonuc[''Toplam Kuyrukta Bekleme Süresi (saniye)''] > 1800]

# Süreleri saat:dakika:saniye formatına çevir
def saniyeyi_formatla(saniye):
    return f"{int(saniye//3600):02d}:{int((saniye%3600)//60):02d}:{int(saniye%60):02d}"

sonuc[''Toplam Kuyrukta Bekleme Süresi (saat:dakika:saniye)''] = sonuc[''Toplam Kuyrukta Bekleme Süresi (saniye)''].apply(saniyeyi_formatla)
sonuc[''Minimum Kuyrukta Bekleme Süresi (saat:dakika:saniye)''] = sonuc[''Minimum Kuyrukta Bekleme Süresi (saniye)''].apply(saniyeyi_formatla)
sonuc[''Maksimum Kuyrukta Bekleme Süresi (saat:dakika:saniye)''] = sonuc[''Maksimum Kuyrukta Bekleme Süresi (saniye)''].apply(saniyeyi_formatla)
sonuc[''Tartım Başına Kuyrukta Bekleme Süresi (saat:dakika:saniye)''] = (
    sonuc[''Toplam Kuyrukta Bekleme Süresi (saniye)''] / sonuc[''Toplam Tartım Sayısı'']
).apply(saniyeyi_formatla)

# Sütun isimlerini düzenle
sonuc = sonuc.rename(columns={''companyname'': ''Fabrika İsmi'', ''displayname'': ''Sistem ismi''})
sonuc = sonuc[[
    ''Fabrika İsmi'', ''Sistem ismi'',
    ''Toplam Kuyrukta Bekleme Süresi (saat:dakika:saniye)'',
    ''Minimum Kuyrukta Bekleme Süresi (saat:dakika:saniye)'',
    ''Maksimum Kuyrukta Bekleme Süresi (saat:dakika:saniye)'',
    ''Tartım Başına Kuyrukta Bekleme Süresi (saat:dakika:saniye)'',
    ''Toplam Tartım Sayısı''
]]

# Toplam Tartım Sayısı''na göre büyükten küçüğe sırala
sonuc = sonuc.sort_values(by=''Toplam Tartım Sayısı'', ascending=False)

# E-posta gönderilecek kişiler (umut çıkarıldı)
email_list = [
    ''sencer.sultanoglu@eliarge.com'',
    ''ozcan.ozen@eliar.com.tr'',
    ''sshmekatronik@eliar.com.tr'',
    ''mehmet.taygun@eliar.com.tr'',
    ''kursat.akyol@eliar.com.tr''
]

# Liste boş değilse mail gönder
if not sonuc.empty:
    html = f"""
    <html>
    <body>
        <h1>Kuyrukta Bekleme Süresi Uzun Olan Mekatronik Sistemler</h1>
        <h2>Anomali Ölçütü</h2>
        <p>{dun_tarihi} tarihi için toplam kuyrukta bekleme süresi 30 dakikanın üstünde olan sistemler</p>
        {sonuc.to_html(index=False)}
    </body>
    </html>
    """

    for _ in range(5):
        try:
            msg = MIMEMultipart()
            msg[''From''] = ''eliar.arge@gmail.com''
            msg[''To''] = '', ''.join(email_list)
            msg[''Subject''] = ''Kuyrukta Bekleme Süresi Uzun Olan Mekatronik Sistemler''
            msg.attach(MIMEText(html, ''html''))

            server = smtplib.SMTP(''smtp.gmail.com'', 587)
            server.starttls()
            server.login(msg[''From''], ''ximjomxcivdluwkv'')
            server.sendmail(msg[''From''], email_list, msg.as_string())
            server.quit()
            break
        except Exception as e:
            print(f"Mail atma hatası: {e}")
            time.sleep(5)
else:
    print("Liste boş, mail atılmayacak.")
',NULL,false),
	 (1,'sapma_negatif - 17:42','{"times": [{"minute": "42", "hour": "17", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import time
import warnings
warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

from datetime import datetime, timedelta
import smtplib

# Verileri yükleyin
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')
tartimlar = tartimlar[~((tartimlar[''displayname''].str.contains(''RPD'', na=False)) & (tartimlar[''deviation''].between(-500, 500)))]

# requestid_starttime ve starttime sütunlarını datetime''a çevirin
tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])
tartimlar[''starttime''] = pd.to_datetime(tartimlar[''starttime''])

# Bir önceki gün için verileri filtreleyin
bir_onceki_gun = datetime.now() - timedelta(days=1)
bir_onceki_gun = bir_onceki_gun.replace(hour=0, minute=0, second=0, microsecond=0)

tartimlar = tartimlar[(tartimlar[''requestid_starttime''] >= bir_onceki_gun) & 
                      (tartimlar[''requestid_starttime''] < bir_onceki_gun + timedelta(days=1))]

# Negatif sapma olan tartımları bul
pozitif_sapma_tartimlar = tartimlar[tartimlar[''deviation''] < 0]

# Sapma %''sini hesapla
pozitif_sapma_tartimlar[''sapma_yuzde''] = (pozitif_sapma_tartimlar[''deviation''] / pozitif_sapma_tartimlar[''targetamount'']) * 100

# Successful alanını Türkçeye çevir
pozitif_sapma_tartimlar[''successful''] = pozitif_sapma_tartimlar[''successful''].map({
    ''Successful'': ''Tamamlandı'',
    ''Partly Successful'': ''Kısmen Tamamlandı'',
    ''Unsuccessful'': ''İptal Edildi''
}).fillna(''Bilinmiyor'')

# targetamount değerine göre iki farklı veri kümesi oluştur
greater_500 = pozitif_sapma_tartimlar[pozitif_sapma_tartimlar[''targetamount''] > 500]
less_500 = pozitif_sapma_tartimlar[pozitif_sapma_tartimlar[''targetamount''] <= 500]

# Yeni sütun sıralaması: ''İstek Başlama Zamanı'' sonrası ''oto/man'' ve ''Durum''
columns_order = [''companyname'', ''displayname'', ''chemical_name'', ''batchno'', ''machine_name'',
                 ''requestid_starttime'', ''source'', ''successful'',
                 ''targetamount'', ''consumedamount'', ''sapma_yuzde'']

pivot_greater_500 = greater_500[columns_order]
pivot_greater_500_filtered = pivot_greater_500[pivot_greater_500[''sapma_yuzde''] < -5]
pivot_greater_500_filtered[[''sapma_yuzde'', ''targetamount'', ''consumedamount'']] = pivot_greater_500_filtered[[''sapma_yuzde'', ''targetamount'', ''consumedamount'']].round(2)
pivot_greater_500_filtered = pivot_greater_500_filtered.sort_values(
    by=[''companyname'', ''displayname'', ''sapma_yuzde''],
    ascending=[False, False, False]
).reset_index(drop=True)

pivot_less_500 = less_500[columns_order]
pivot_less_500_filtered = pivot_less_500[pivot_less_500[''sapma_yuzde''] < -5]
pivot_less_500_filtered[[''sapma_yuzde'', ''targetamount'', ''consumedamount'']] = pivot_less_500_filtered[[''sapma_yuzde'', ''targetamount'', ''consumedamount'']].round(2)
pivot_less_500_filtered = pivot_less_500_filtered.sort_values(
    by=[''companyname'', ''displayname'', ''sapma_yuzde''],
    ascending=[False, False, False]
).reset_index(drop=True)

# Zaman sadece saat olarak gösterilsin
pivot_greater_500_filtered[''requestid_starttime''] = pd.to_datetime(pivot_greater_500_filtered[''requestid_starttime'']).dt.strftime(''%H:%M:%S'')
pivot_less_500_filtered[''requestid_starttime''] = pd.to_datetime(pivot_less_500_filtered[''requestid_starttime'']).dt.strftime(''%H:%M:%S'')

# Kolon adlarını yeniden adlandır
rename_dict = {
    ''companyname'': ''Fabrika İsmi'',
    ''displayname'': ''Sistem İsmi'',
    ''chemical_name'': ''Kimyasal İsmi'',
    ''batchno'': ''İş Emri No'',
    ''machine_name'': ''Makine İsmi'',
    ''requestid_starttime'': ''İstek Başlama Zamanı'',
    ''source'': ''oto/man'',
    ''successful'': ''Durum'',
    ''targetamount'': ''Hedef Miktar'',
    ''consumedamount'': ''Tartılan Miktar'',
    ''sapma_yuzde'': ''Sapma %\''si''
}

pivot_greater_500_filtered.rename(columns=rename_dict, inplace=True)
pivot_less_500_filtered.rename(columns=rename_dict, inplace=True)

# HTML oluştur
html = ''''''
<h2>Hedef Miktarı 500''den Büyük Olanlar</h2>
''''''
html += pivot_greater_500_filtered.to_html(index=False) if not pivot_greater_500_filtered.empty else "<p>Anomali tespit edilememiştir.</p>"
html += ''''''
<h2>Hedef Miktarı 500''den Küçük veya Eşit Olanlar</h2>
''''''
html += pivot_less_500_filtered.to_html(index=False) if not pivot_less_500_filtered.empty else "<p>Anomali tespit edilememiştir.</p>"

# Eğer en az bir tablo doluysa mail gönder
if not pivot_greater_500_filtered.empty or not pivot_less_500_filtered.empty:
    try:
        msg = MIMEMultipart()
        msg[''From''] = ''eliar.arge@gmail.com''
        msg[''To''] = '', ''.join([
            ''sencer.sultanoglu@eliarge.com'',
            ''ozcan.ozen@eliar.com.tr'',
            ''sshmekatronik@eliar.com.tr'',
            ''mehmet.taygun@eliar.com.tr'',
            ''kursat.akyol@eliar.com.tr''
        ])
        msg[''Subject''] = ''Negatif Sapma Yüzdesi Yüksek Olan Tartımlar''

        body = ''<h2>Anomali Ölçütü</h2><p>[{}] tarihi için negatif sapma oranı %-5\''ten fazla olan tartımların raporu.</p>''.format(bir_onceki_gun.strftime(''%d-%m-%Y''))
        body += html
        msg.attach(MIMEText(body, ''html''))

        server = smtplib.SMTP(''smtp.gmail.com'', 587)
        server.starttls()
        server.login(msg[''From''], ''ximjomxcivdluwkv'')
        server.sendmail(msg[''From''], msg[''To''].split('', ''), msg.as_string())
        server.quit()

    except Exception as e:
        for _ in range(5):
            try:
                server = smtplib.SMTP(''smtp.gmail.com'', 587)
                server.starttls()
                server.login(msg[''From''], ''ximjomxcivdluwkv'')
                server.sendmail(msg[''From''], msg[''To''].split('', ''), msg.as_string())
                server.quit()
                break
            except:
                time.sleep(5)
',NULL,false),
	 (2,'07:30 -  satın alma fiyat anomalisi (zarar hesaplı) - promtid=2 ile aynı','{"times": [{"minute": "28", "hour": "07", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
import numpy as np
from datetime import datetime
import smtplib
import time
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# === Ekleyen kişi-mail ve yönetici bilgileri ===
ekleyen_mail_dict = {
    "ALİ UFUK": {
        "mail": "aliufuk.parlakci@eliar.com.tr",
        "yoneticiler": ["birol.genc@eliar.com.tr", "aygun.oztorun@eliar.com.tr"]
    },
    "ANIL CAKAL": {
        "mail": "anil.cakal@eliar.com.tr",
        "yoneticiler": ["ismail.terkesli@eliarge.com"]
    },
    "AYGUN": {
        "mail": "nilay.demir@eliar.com.tr",
        "yoneticiler": ["birol.genc@eliar.com.tr", "aygun.oztorun@eliar.com.tr"]
    },
    "BETUL BUSRA TASKIN": {
        "mail": "busra.taskin@eliar.com.tr",
        "yoneticiler": []
    },
    "BUSRA CELIKKOL": {
        "mail": "busra.celikkol@eliar.com.tr",
        "yoneticiler": ["ismail.terkesli@eliarge.com"]
    },
    "METİN YAGCI": {
        "mail": "metin.yagci@eliar.com.tr",
        "yoneticiler": []
    },
    "ONUR BOZKURT": {
        "mail": "onur.bozkurt@eliar.com.tr",
        "yoneticiler": ["engin.reyhan@eliar.com.tr"]
    },
    "PINAR TUZUN": {
        "mail": "pinar.tuzun@eliar.com.tr",
        "yoneticiler": []
    },
    "PROJE DEPO": {
        "mail": "projedepo@eliar.com.tr",
        "yoneticiler": ["engin.reyhan@eliar.com.tr"]
    },
    "SATISDESTEK2": {
        "mail": "satisdestek1@eliar.com.tr",
        "yoneticiler": ["birol.genc@eliar.com.tr", "aygun.oztorun@eliar.com.tr"]
    },
    "SELÇUK GÜL": {
        "mail": "giris.kalite@eliar.com.tr",
        "yoneticiler": ["ismail.terkesli@eliarge.com"]
    },
    "ZEYNEP DUNDAR": {
        "mail": "zeynep.dundar@eliar.com.tr",
        "yoneticiler": []
    },
    "NILAY DEMIR": {
        "mail": "nilay.demir@eliar.com.tr",
        "yoneticiler": ["birol.genc@eliar.com.tr", "aygun.oztorun@eliar.com.tr"]
    }
}

# === Veri Yükleme ve İşleme ===
df = pd.read_csv(''satin_alma_verileri.csv'')
df[''FaturaTarihi''] = pd.to_datetime(df[''FaturaTarihi''], errors=''coerce'')
df = df[df[''FaturaNo''] != ''BOŞ'']

today = pd.Timestamp.now()
six_months_ago = today - pd.Timedelta(days=180)
df = df[df[''FaturaTarihi''] >= six_months_ago]

avg_price = df.groupby(''MalzemeHizmetKodu'')[''IrsEuroBirimFiyat''].mean()
df[''Ortalama IrsEuroBirimFiyat''] = df[''MalzemeHizmetKodu''].map(avg_price)
df[''Euro Birim Fiyat % Sapma''] = ((df[''IrsEuroBirimFiyat''] - df[''Ortalama IrsEuroBirimFiyat'']) / df[''Ortalama IrsEuroBirimFiyat'']) * 100

anomaly_df = df[df[''Euro Birim Fiyat % Sapma''] > 20]

yesterday = today - pd.Timedelta(days=1)
anomaly_df = anomaly_df[anomaly_df[''FaturaTarihi''].dt.date == yesterday.date()]

# Zarar (€) hesapla
anomaly_df[''Zarar (€)''] = (anomaly_df[''IrsEuroBirimFiyat''] - anomaly_df[''Ortalama IrsEuroBirimFiyat'']) * anomaly_df[''Miktar'']

# Kolonları seç
anomaly_df = anomaly_df[[''FaturaTarihi'', ''FaturaNo'', ''Isyeri'', ''MalzemeHizmetKodu'', ''MalzemeHizmet'',
                         ''SiparisiEkleyen'', ''Miktar'', ''IrsEuroBirimFiyat'', ''Ortalama IrsEuroBirimFiyat'',
                         ''Euro Birim Fiyat % Sapma'', ''Zarar (€)'']]

# Formatlar
for col in [''Miktar'', ''IrsEuroBirimFiyat'', ''Ortalama IrsEuroBirimFiyat'', ''Zarar (€)'']:
    anomaly_df[col] = anomaly_df[col].apply(lambda x: ''{:.3f}''.format(x))

anomaly_df[''Euro Birim Fiyat % Sapma''] = anomaly_df[''Euro Birim Fiyat % Sapma''].apply(lambda x: ''{:.2f}%''.format(x))

html = anomaly_df.to_html(index=False, escape=False)

# === Sabit alıcılar (Umut çıkarıldı) ===
base_recipients = [''zeynep.dundar@eliar.com.tr'', ''sencer.sultanoglu@eliarge.com'', ''mehmet.taygun@eliar.com.tr'']

# === Ekleyen ve yöneticilerden ek alıcılar çıkar ===
extra_recipients = []

if not anomaly_df.empty:
    for ekleyen in anomaly_df[''SiparisiEkleyen''].unique():
        ekleyen_upper = ekleyen.strip().upper()
        if ekleyen_upper in ekleyen_mail_dict:
            extra_recipients.append(ekleyen_mail_dict[ekleyen_upper][''mail''])
            extra_recipients.extend(ekleyen_mail_dict[ekleyen_upper][''yoneticiler''])

# Tekrarsız hale getir
final_recipients = list(set(base_recipients + extra_recipients))

# === Mail gönderim ===
subject = ''Satın Alma Fiyat Anomalisi''
msg = MIMEMultipart()
msg[''Subject''] = subject
msg[''From''] = ''eliar.arge@gmail.com''
msg[''To''] = '', ''.join(final_recipients)

if not anomaly_df.empty:
    msg.attach(MIMEText(html, ''html''))
else:
    msg.attach(MIMEText(f''Anomali asistanı {yesterday.strftime("%d.%m.%Y")} tarihinde kapanan faturalarda anomali bulmamıştır'', ''plain''))

try:
    server = smtplib.SMTP(''smtp.gmail.com'', 587)
    server.starttls()
    server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')  # Güvenlik için .env dosyasına taşı!
    server.sendmail(msg[''From''], final_recipients, msg.as_string())
    server.quit()
except Exception as e:
    print(f''Error sending email: {e}'')
    for i in range(5):
        try:
            server = smtplib.SMTP(''smtp.gmail.com'', 587)
            server.starttls()
            server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')
            server.sendmail(msg[''From''], final_recipients, msg.as_string())
            server.quit()
            break
        except Exception as e:
            print(f''Retrying to send email: {e}'')
            time.sleep(5)
',NULL,false),
	 (2,'AYGUN','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''AYGUN'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,birol.genc@eliar.com.tr,aygun.oztorun@eliar.com.tr',false,NULL),
	 (1,'sapma_pozitif - 17:44','{"times": [{"minute": "44", "hour": "17", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
import time
import warnings
warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

from datetime import datetime, timedelta
import smtplib

# Verileri yükleyin
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')
tartimlar = tartimlar[~((tartimlar[''displayname''].str.contains(''RPD'', na=False)) & (tartimlar[''deviation''].between(-500, 500)))]

# requestid_starttime ve starttime sütunlarını datetime''a çevirin
tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])
tartimlar[''starttime''] = pd.to_datetime(tartimlar[''starttime''])

# Bir önceki gün için verileri filtreleyin
bir_onceki_gun = datetime.now() - timedelta(days=1)
bir_onceki_gun = bir_onceki_gun.replace(hour=0, minute=0, second=0, microsecond=0)

tartimlar = tartimlar[(tartimlar[''requestid_starttime''] >= bir_onceki_gun) & 
                      (tartimlar[''requestid_starttime''] < bir_onceki_gun + timedelta(days=1))]

# Pozitif sapma olan tartımları bul
pozitif_sapma_tartimlar = tartimlar[tartimlar[''deviation''] > 0]

# Sapma %''sini hesapla
pozitif_sapma_tartimlar[''sapma_yuzde''] = (pozitif_sapma_tartimlar[''deviation''] / pozitif_sapma_tartimlar[''targetamount'']) * 100

# successful alanını Türkçeye çevir
pozitif_sapma_tartimlar[''successful''] = pozitif_sapma_tartimlar[''successful''].map({
    ''Successful'': ''Tamamlandı'',
    ''Partly Successful'': ''Kısmen Tamamlandı'',
    ''Unsuccessful'': ''İptal Edildi''
}).fillna(''Bilinmiyor'')

# targetamount değerine göre iki farklı veri kümesi oluştur
greater_500 = pozitif_sapma_tartimlar[pozitif_sapma_tartimlar[''targetamount''] > 500]
less_500 = pozitif_sapma_tartimlar[pozitif_sapma_tartimlar[''targetamount''] <= 500]

# Sütun sıralamasını "İstek Başlama Zamanı" sonrası source ve Durum olacak şekilde düzenle
columns_order = [''companyname'', ''displayname'', ''chemical_name'', ''batchno'', ''machine_name'',
                 ''requestid_starttime'', ''source'', ''successful'',
                 ''targetamount'', ''consumedamount'', ''sapma_yuzde'']

pivot_greater_500 = greater_500[columns_order]
pivot_greater_500_filtered = pivot_greater_500[pivot_greater_500[''sapma_yuzde''] >= 5]
pivot_greater_500_filtered[[''sapma_yuzde'', ''targetamount'', ''consumedamount'']] = pivot_greater_500_filtered[[''sapma_yuzde'', ''targetamount'', ''consumedamount'']].round(2)
pivot_greater_500_filtered = pivot_greater_500_filtered.sort_values(
    by=[''companyname'', ''displayname'', ''sapma_yuzde''],
    ascending=[False, False, False]
).reset_index(drop=True)

pivot_less_500 = less_500[columns_order]
pivot_less_500_filtered = pivot_less_500[pivot_less_500[''sapma_yuzde''] >= 5]
pivot_less_500_filtered[[''sapma_yuzde'', ''targetamount'', ''consumedamount'']] = pivot_less_500_filtered[[''sapma_yuzde'', ''targetamount'', ''consumedamount'']].round(2)
pivot_less_500_filtered = pivot_less_500_filtered.sort_values(
    by=[''companyname'', ''displayname'', ''sapma_yuzde''],
    ascending=[False, False, False]
).reset_index(drop=True)

# Zaman sadece saat olarak gösterilsin
pivot_greater_500_filtered[''requestid_starttime''] = pd.to_datetime(pivot_greater_500_filtered[''requestid_starttime'']).dt.strftime(''%H:%M:%S'')
pivot_less_500_filtered[''requestid_starttime''] = pd.to_datetime(pivot_less_500_filtered[''requestid_starttime'']).dt.strftime(''%H:%M:%S'')

# Kolon adlarını yeniden adlandır
rename_dict = {
    ''companyname'': ''Fabrika İsmi'',
    ''displayname'': ''Sistem İsmi'',
    ''chemical_name'': ''Kimyasal İsmi'',
    ''batchno'': ''İş Emri No'',
    ''machine_name'': ''Makine İsmi'',
    ''requestid_starttime'': ''İstek Başlama Zamanı'',
    ''source'': ''oto/man'',
    ''successful'': ''Durum'',
    ''targetamount'': ''Hedef Miktar'',
    ''consumedamount'': ''Tartılan Miktar'',
    ''sapma_yuzde'': ''Sapma %\''si''
}

pivot_greater_500_filtered.rename(columns=rename_dict, inplace=True)
pivot_less_500_filtered.rename(columns=rename_dict, inplace=True)

# HTML oluştur
html = ''''''
<h2>Hedef Miktarı 500''den Büyük Olanlar</h2>
''''''
html += pivot_greater_500_filtered.to_html(index=False) if not pivot_greater_500_filtered.empty else "<p>Anomali tespit edilememiştir.</p>"
html += ''''''
<h2>Hedef Miktarı 500''den Küçük veya Eşit Olanlar</h2>
''''''
html += pivot_less_500_filtered.to_html(index=False) if not pivot_less_500_filtered.empty else "<p>Anomali tespit edilememiştir.</p>"

# Eğer en az bir tablo doluysa mail gönder
if not pivot_greater_500_filtered.empty or not pivot_less_500_filtered.empty:
    try:
        msg = MIMEMultipart()
        msg[''From''] = ''eliar.arge@gmail.com''
        msg[''To''] = '', ''.join([
            ''sencer.sultanoglu@eliarge.com'',
            ''ozcan.ozen@eliar.com.tr'',
            ''sshmekatronik@eliar.com.tr'',
            ''mehmet.taygun@eliar.com.tr'',
            ''kursat.akyol@eliar.com.tr''
        ])
        msg[''Subject''] = ''Pozitif Sapma Yüzdesi Yüksek Olan Tartımlar''

        body = ''<h2>Anomali Ölçütü</h2><p>[{}] tarihi için pozitif sapma oranı %5\''ten fazla olan tartımların raporu.</p>''.format(bir_onceki_gun.strftime(''%d-%m-%Y''))
        body += html
        msg.attach(MIMEText(body, ''html''))

        server = smtplib.SMTP(''smtp.gmail.com'', 587)
        server.starttls()
        server.login(msg[''From''], ''ximjomxcivdluwkv'')
        server.sendmail(msg[''From''], msg[''To''].split('', ''), msg.as_string())
        server.quit()

    except Exception as e:
        for _ in range(5):
            try:
                server = smtplib.SMTP(''smtp.gmail.com'', 587)
                server.starttls()
                server.login(msg[''From''], ''ximjomxcivdluwkv'')
                server.sendmail(msg[''From''], msg[''To''].split('', ''), msg.as_string())
                server.quit()
                break
            except:
                time.sleep(5)
',NULL,false),
	 (2,'ANIL CAKAL','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''ANIL CAKAL'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,anil.cakal@eliar.com.tr,ismail.terkesli@eliarge.com',false,NULL),
	 (1,'GPU bilgisayarda LLM Platformu Çalışıyor''  maili','{"times": [{"minute": "04", "hour": "*", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import smtplib

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

mail_recipients = [''sencer.sultanoglu@eliarge.com'']

mail_sender = ''eliar.arge@gmail.com''

mail_password = ''ximjomxcivdluwkv''

mail_port = 587

msg = MIMEMultipart()

msg[''Subject''] = ''LLM PC hayatta mı''

msg[''From''] = mail_sender

msg[''To''] = '', ''.join(mail_recipients)

body = ''GPU bilgisayarda LLM Platformu Çalışıyor''

msg.attach(MIMEText(body, ''plain''))

server = smtplib.SMTP(''smtp.gmail.com'', mail_port)

server.starttls()

server.login(mail_sender, mail_password)

try:

    server.sendmail(mail_sender, mail_recipients, msg.as_string())

    server.quit()

except Exception as e:

    print(f"Error: {e}")

    for i in range(5):


        try:

            server.sendmail(mail_sender, mail_recipients, msg.as_string())

            server.quit()

            break

        except Exception as e:

            print(f"Error: {e}")

            time.sleep(5)',NULL,false),
	 (2,'irsaliye_fatura_gecikmeleri.csv dosyasını oku. ''Ekleme Tarihi'' sütunu yesterday (yesterday tarihi datetime türüne dönüştürülmelidir) tarihine eşit olanları filtrele. Yesterday karşılaştırması yıl-ay-gün formatında olmalıdır. . Ardından ''Gün Farkı'' sütunu 0''dan küçük ve 2''den büyük olan satırları filtrele. Ardından listeyi ''İşyeriNo'',''Ekleyen'', ''Ekleme Tarihi'' bazında azalan şekilde sırala. Liste boş değilse mail at.','{"times": [{"minute": "39", "hour": "07", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

import datetime

from email.mime.text import MIMEText

from email.mime.multipart import MIMEMultipart

import smtplib

# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''])

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (df_yesterday[''Gün Farkı''] > 7)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_sorted = df_filtered.sort_values(by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ''umut.sahin@eliarge.com,zeynep.dundar@eliar.com.tr,sencer.sultanoglu@eliarge.com,mehmet.taygun@eliar.com.tr''

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'', [''umut.sahin@eliarge.com'',''zeynep.dundar@eliar.com.tr'',''sencer.sultanoglu@eliarge.com'',''mehmet.taygun@eliar.com.tr''], msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'', [''umut.sahin@eliarge.com'',''zeynep.dundar@eliar.com.tr'',''sencer.sultanoglu@eliarge.com'',''mehmet.taygun@eliar.com.tr''], msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times',NULL,false),
	 (2,'BUSRA CELİKKOL','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''BUSRA CELİKKOL'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,busra.celikkol@eliar.com.tr,ismail.terkesli@eliarge.com',false,NULL),
	 (2,'ALİ UFUK','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''ALİ UFUK'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,aliufuk.parlakci@eliar.com.tr,birol.genc@eliar.com.tr,aygun.oztorun@eliar.com.tr',false,NULL);
INSERT INTO llm_platform.auto_prompt (assistant_id,question,trigger_time,python_code,receiver_emails,mcrisactive,case_id) VALUES
	 (2,'METİN YAGCI','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''METİN YAGCI'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,metin.yagci@eliar.com.tr',false,NULL),
	 (2,'ONUR BOZKURT','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''ONUR BOZKURT'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','onur.bozkurt@eliar.com.tr,sencer.sultanoglu@eliarge.com,engin.reyhan@eliar.com.tr',false,NULL),
	 (2,'NİLAY DEMİR','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''NİLAY DEMİR'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,nilay.demir@eliar.com.tr,birol.genc@eliar.com.tr,aygun.oztorun@eliar.com.tr',false,NULL),
	 (2,'SATISDESTEK2','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''SATISDESTEK2'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,satisdestek1@eliar.com.tr,birol.genc@eliar.com.tr,aygun.oztorun@eliar.com.tr',false,NULL),
	 (2,'PINAR TUZUN','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''PINAR TUZUN'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,pinar.tuzun@eliar.com.tr',false,NULL),
	 (2,'SELÇUK GÜL','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''SELÇUK GÜL'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,giris.kalite@eliar.com.tr,ismail.terkesli@eliarge.com',false,NULL),
	 (1,'17:16 Olay (Event) sayısı','{"times": [{"minute": "16", "hour": "17", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
import smtplib
import time
import warnings
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# Alıcı listesi (Tüm ekip)
alici_listesi = [
    ''sencer.sultanoglu@eliarge.com'',
    ''ozcan.ozen@eliar.com.tr'',
    ''sshmekatronik@eliar.com.tr'',
    ''mehmet.taygun@eliar.com.tr'',
    ''kursat.akyol@eliar.com.tr''
]

# CSV dosyasını oku
df = pd.read_csv(''mekatronik_sistem_event_sayıları.csv'')

# tarih sütununu datetime nesnesine çevir
df[''tarih''] = pd.to_datetime(df[''tarih'']).dt.date

# Dün hesapla
bugun = datetime.today().date()
dun = bugun - timedelta(days=1)

# Sadece dünkü verileri al
df_dun = df[df[''tarih''] == dun]

# event_adi boş olanlara varsayılan metni ata
df_dun[''event_adi''] = df_dun[''event_adi''].fillna("Olay adı mekatronik sistemde girilmemiş")

# Eşik değerin üstünde olanlar
df_filtered = df_dun[df_dun[''event_sayisi''] > 5]

# Gönderilecek sütunlar
df_filtered = df_filtered[[''fabrika_adi'', ''sistem_adi'', ''eventcode'', ''event_adi'', ''event_sayisi'']]
df_filtered = df_filtered.sort_values(by=''event_sayisi'', ascending=False)

# Eğer varsa, mail gönder
if not df_filtered.empty:
    df_filtered.columns = [''Fabrika Adı'', ''Sistem Adı'', ''Olay Kodu'', ''Olay Adı'', ''Olay Sayısı'']
    html = df_filtered.to_html(index=False)

    body = f''''''
    <h1>Fazla Olay Oluşturan Mekatronik Sistemler</h1>
    <h2>Anomali Ölçütü</h2>
    <p>{dun} tarihi için günlük olay sayısı 5''ten fazla olan sistemler aşağıda listelenmiştir.</p>
    {html}
    ''''''

    for _ in range(5):  # E-posta gönderimini en fazla 5 kez dene
        try:
            msg = MIMEMultipart()
            msg[''From''] = ''eliar.arge@gmail.com''
            msg[''To''] = '', ''.join(alici_listesi)
            msg[''Subject''] = ''Fazla Olay (Event) Oluşturan Mekatronik Sistemler''
            msg.attach(MIMEText(body, ''html''))

            server = smtplib.SMTP(''smtp.gmail.com'', 587)
            server.starttls()
            server.login(msg[''From''], ''ximjomxcivdluwkv'')  # Gmail uygulama şifresi
            server.sendmail(msg[''From''], alici_listesi, msg.as_string())
            server.quit()
            break
        except Exception as e:
            print(f"Mail atma hatası: {e}")
            time.sleep(5)
else:
    print("Olay sayısı sınırı aşan sistem yok, mail gönderilmedi.")
',NULL,false),
	 (2,'ZEYNEP DUNDAR','{"times": []}','
import smtplib
import datetime
import warnings
import time
from email.mime.image import MIMEImage
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import seaborn as sns
import matplotlib
import pandas as pd
receiver_emails = [''sencer.sultanoglu@eliarge.com'']  # AUTO_CONVERT


warnings.simplefilter(
    action=''ignore'', category=pd.errors.SettingWithCopyWarning)


# Read the irsaliye_fatura_gecikmeleri.csv file

df = pd.read_csv(''irsaliye_fatura_gecikmeleri.csv'')

# Convert ''Ekleme Tarihi'' column to datetime format

df[''Ekleme Tarihi''] = pd.to_datetime(df[''Ekleme Tarihi''], format=''%d.%m.%Y'')

# Get yesterday''s date

yesterday = datetime.date.today() - datetime.timedelta(days=1)

# Filter rows where ''Ekleme Tarihi'' is equal to yesterday

df_yesterday = df[df[''Ekleme Tarihi''].dt.date == yesterday]

# Filter rows where ''Gün Farkı'' is less than 0 or greater than 2

df_filtered = df_yesterday[(df_yesterday[''Gün Farkı''] < 0) | (
    df_yesterday[''Gün Farkı''] > 2)]

# Sort the filtered list by ''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi'' in descending order

df_temp = df_filtered[df_filtered[''Ekleyen''] == ''ZEYNEP DUNDAR'']

df_sorted = df_temp.sort_values(
    by=[''İşyeriNo'', ''Ekleyen'', ''Ekleme Tarihi''], ascending=False)
# Drop the ''create_date'' column from df_sorted
df_sorted = df_sorted.drop(columns=[''create_date''])


# If the list is not empty, send an email

if not df_sorted.empty:

    # Create a HTML table from the sorted list

    html_table = df_sorted.to_html(index=False)

    # Create a text message

    msg = MIMEMultipart()

    msg[''Subject''] = ''Satın Alma Sürecinde İrsaliye ve Fatura Giriş Gecikmeleri''

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ", ".join(receiver_emails)

    # Add the HTML table to the message

    msg.attach(MIMEText(html_table, ''html''))

    # Send the email

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',
                        receiver_emails, msg.as_string())

        server.quit()

    except Exception as e:

        print(f"Error sending email: {e}")

        # Try again after 5 seconds

        time.sleep(5)

        try:

            server.sendmail(''eliar.arge@gmail.com'',
                            receiver_emails, msg.as_string())

            server.quit()

        except Exception as e:

            print(f"Error sending email: {e}")

            # Try again after 5 seconds

            time.sleep(5)

            # ...

            # Try up to 5 times
','sencer.sultanoglu@eliarge.com,zeynep.dundar@eliar.com.tr',false,NULL),
	 (2,'satis_fatura_verileri.csv dosyasını oku. ''BrutKarAnaGrubu'' ve ''BrutKarGrubu'' sütununlarında ''-'' veya ''Lütfen Seçiniz'' değerine sahip olan satırları listele. SiparisTarihi sütunu yesterday (yesterday tarihi datetime türüne dönüştürülmelidir) tarihine eşit olanları filtrele. Yesterday karşılaştırması yıl-ay-gün formatında olmalıdır. Listede sadece Firma, Yil,SiparisTarihi , StokKodu, StokTanimi, BrutKarAnaGrubu	,BrutKarGrubu	 sütunları bulunacak. Liste boş değilse listeyi mail at. Mail içeriğine başlık ekleme, sadece listeyi yolla. Mail konu başlığı ''Satış Fatura Kar Grubu Boş Olan Veriler'' olsun.  Liste boş ise ''Anomali asistanı {(pd.to_datetime(''now'') - pd.Timedelta(days=1)).strftime(''%d.%m.%Y'')}'' daki verilerde anomali bulmamıştır'' metnini mail at. ','{"times": [{"minute": "33", "hour": "07", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd

import matplotlib

import seaborn as sns

from email.mime.multipart import MIMEMultipart

from email.mime.text import MIMEText

from email.mime.image import MIMEImage

import time

import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

import pandas as pd

import smtplib

from email.mime.text import MIMEText

from email.mime.multipart import MIMEMultipart

# Read the satis_fatura_verileri.csv file

df = pd.read_csv(''satis_fatura_verileri.csv'')

df[''SiparisTarihi''] = pd.to_datetime(df[''SiparisTarihi''])

# Filter the rows where BrutKarAnaGrubu or BrutKarGrubu is ''-'' or ''Lütfen Seçiniz''
df_filtered = df[(df[''BrutKarAnaGrubu''] == ''-'') | (df[''BrutKarAnaGrubu''] == ''Lütfen Seçiniz'') | 
                  (df[''BrutKarGrubu''] == ''-'') | (df[''BrutKarGrubu''] == ''Lütfen Seçiniz'')]

# Get yesterday''s date
yesterday = pd.to_datetime(''now'') - pd.Timedelta(days=1)

# Keep only rows where SiparisTarihi is from yesterday (date only, ignoring time)
df_filtered = df_filtered[df_filtered[''SiparisTarihi''].dt.date == yesterday.date()]

# Select only the required columns

df_filtered = df_filtered[[''Firma'', ''Yil'', ''SiparisTarihi'', ''StokKodu'', ''StokTanimi'', ''BrutKarAnaGrubu'', ''BrutKarGrubu'']]

# If the filtered dataframe is not empty, send an email with the list

if not df_filtered.empty:

    html = df_filtered.to_html(index=False)

    subject = ''Satış Fatura Kar Grubu Boş Olan Veriler''

    body = ''<h2>{}</h2><br>{}''.format(subject, html)

    

    msg = MIMEMultipart(''alternative'')

    msg[''Subject''] = subject

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ''umut.sahin@eliarge.com, sencer.sultanoglu@eliarge.com,zeynep.dundar@eliar.com.tr,mehmet.taygun@eliar.com.tr''

    

    msg.attach(MIMEText(body, ''html''))

    

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'',[ ''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'',''zeynep.dundar@eliar.com.tr'',''mehmet.taygun@eliar.com.tr''], msg.as_string())

        server.quit()

    except Exception as e:

        print(''Error sending email:'', e)

        for i in range(5):

            try:

                server = smtplib.SMTP(''smtp.gmail.com'', 587)

                server.starttls()

                server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

                server.sendmail(''eliar.arge@gmail.com'', [ ''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'',''zeynep.dundar@eliar.com.tr'',''mehmet.taygun@eliar.com.tr''], msg.as_string())

                server.quit()

                break

            except Exception as e:

                print(''Error sending email:'', e)

                time.sleep(5)

else:

    subject = ''Satış Fatura Kar Grubu Boş Olan Veriler''

    body = ''Anomali asistanı {} daki verilerde anomali bulmamıştır''.format((pd.to_datetime(''now'') - pd.Timedelta(days=1)).strftime(''%d.%m.%Y''))

    

    msg = MIMEMultipart(''alternative'')

    msg[''Subject''] = subject

    msg[''From''] = ''eliar.arge@gmail.com''

    msg[''To''] = ''umut.sahin@eliarge.com,sencer.sultanoglu@eliarge.com,zeynep.dundar@eliar.com.tr,mehmet.taygun@eliar.com.tr''

    

    msg.attach(MIMEText(body, ''plain''))

    

    try:

        server = smtplib.SMTP(''smtp.gmail.com'', 587)

        server.starttls()

        server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

        server.sendmail(''eliar.arge@gmail.com'', [ ''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'',''zeynep.dundar@eliar.com.tr'',''mehmet.taygun@eliar.com.tr''], msg.as_string())

        server.quit()

    except Exception as e:

        print(''Error sending email:'', e)

        for i in range(5):

            try:

                server = smtplib.SMTP(''smtp.gmail.com'', 587)

                server.starttls()

                server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')

                server.sendmail(''eliar.arge@gmail.com'', [ ''umut.sahin@eliarge.com'',''sencer.sultanoglu@eliarge.com'',''zeynep.dundar@eliar.com.tr'',''mehmet.taygun@eliar.com.tr''], msg.as_string())

                server.quit()

                break

            except Exception as e:

                print(''Error sending email:'', e)

                time.sleep(5)',NULL,false),
	 (1,'kimyasal ismi bos olanlar','{"times": [{"minute": "50", "hour": "17", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
from datetime import datetime, timedelta
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import time

# Uyarıların baskılanması
pd.options.mode.chained_assignment = None

# CSV''den veriyi yükle
df = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

# Tarihleri datetime''a çevir
df[''requestid_starttime''] = pd.to_datetime(df[''requestid_starttime''], errors=''coerce'')

# Bir önceki günün başlangıç-bitiş zamanını tanımla
bir_onceki_gun = datetime.now() - timedelta(days=1)
start_time = bir_onceki_gun.replace(hour=0, minute=0, second=0, microsecond=0)
end_time = start_time + timedelta(days=1)

# Tarih aralığında ve chemical_name alanı boş olanları seç
null_chemical = df[
    (df[''requestid_starttime''] >= start_time) &
    (df[''requestid_starttime''] < end_time) &
    (df[''chemical_name''].isnull())
]

# Rapor HTML
html = "<h2>Chemical Name Alanı Boş Olan Tartımlar</h2>"
if not null_chemical.empty:
    html += null_chemical[[''companyname'', ''displayname'', ''requestid'', ''detailid'', ''targetamount'', ''consumedamount'']].to_html(index=False)
else:
    html += "<p>Boş chemical_name değeri bulunamamıştır.</p>"

# E-posta gönderimi (sadece veri varsa)
if not null_chemical.empty:
    msg = MIMEMultipart()
    msg[''From''] = ''eliar.arge@gmail.com''
    recipients = [
        ''sencer.sultanoglu@eliarge.com''
    ]
    msg[''To''] = '', ''.join(recipients)
    msg[''Subject''] = f''Chemical Name Alanı Boş Tartımlar [{start_time.strftime("%d-%m-%Y")}]''

    body = f"<p>{start_time.strftime(''%d-%m-%Y'')} tarihli chemical_name alanı boş olan tartımlar aşağıdadır.</p>"
    body += html
    msg.attach(MIMEText(body, ''html''))

    for _ in range(5):
        try:
            server = smtplib.SMTP(''smtp.gmail.com'', 587)
            server.starttls()
            server.login(msg[''From''], ''ximjomxcivdluwkv'')
            server.sendmail(msg[''From''], recipients, msg.as_string())
            server.quit()
            break
        except Exception:
            time.sleep(5)
',NULL,false);
INSERT INTO llm_platform.auto_prompt (assistant_id,question,trigger_time,python_code,receiver_emails,mcrisactive,case_id) VALUES
	 (2,'ERP''ye girilmemiş satış-iade faturaları','{"times": [{"minute": "51", "hour": "09", "day_of_month": "*", "month": "*", "day_of_week": "1,4"}]}','#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ERP’ye Girilmemiş Satış/İade Faturalar – Otomatik E-posta Bildirimi
Çalıştırma Günleri:
  • Salı  →  GelişTarih < geçen Cuma
  • Cuma  →  GelişTarih < geçen Salı
"""

import sys, time, smtplib, datetime as dt
import pandas as pd
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# ---------------------------------------------------------------------
# AYARLAR
# ---------------------------------------------------------------------
CSV_FILE  = ''erp_ye_girilmemiş_satis_iade.csv''
DATE_COL  = ''GelişTarih''
BELGE_COL = ''BelgeTarihi''

SMTP_HOST = ''smtp.gmail.com''
SMTP_PORT = 587
SMTP_USER = ''eliar.arge@gmail.com''
SMTP_PASS = ''ximjomxcivdluwkv''

RECIPIENTS = [
    ''sencer.sultanoglu@eliarge.com'',
    ''zeynep.dundar@eliar.com.tr'',
    ''aliufuk.parlakci@eliar.com.tr'',
    ''satisdestek1@eliar.com.tr'',
    ''nilay.demir@eliar.com.tr'',
    ''metin.yagci@eliar.com.tr'',
]

# ---------------------------------------------------------------------
# E-POSTA GÖNDERİCİ
# ---------------------------------------------------------------------
def send_mail(subject: str, html_body: str) -> None:
    msg = MIMEMultipart()
    msg[''Subject''] = subject
    msg[''From'']    = SMTP_USER
    msg[''To'']      = '', ''.join(RECIPIENTS)
    msg.attach(MIMEText(html_body, ''html''))

    for attempt in range(5):
        try:
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as srv:
                srv.starttls()
                srv.login(SMTP_USER, SMTP_PASS)
                srv.sendmail(SMTP_USER, RECIPIENTS, msg.as_string())
            print(f"✔ Mail gönderildi → {len(RECIPIENTS)} alıcı")
            return
        except Exception as e:
            print(f"✖ Gönderim hatası (deneme {attempt+1}/5): {e}")
            time.sleep(5)
    print("✖ Gönderim başarısız.")

# ---------------------------------------------------------------------
# KESİM TARİHİ HESABI
# ---------------------------------------------------------------------
def cutoff_date(today: dt.date) -> dt.date:
    wd = today.weekday()
    if wd == 1:  # Salı
        return today - dt.timedelta(days=4)
    elif wd == 4:  # Cuma
        return today - dt.timedelta(days=3)
    else:
        print("Bu betik yalnız Salı veya Cuma çalıştırılmalıdır.")
        sys.exit(0)

# ---------------------------------------------------------------------
# ANA İŞ AKIŞI
# ---------------------------------------------------------------------
def main() -> None:
    today  = dt.date.today()
    cutoff = cutoff_date(today)

    df = pd.read_csv(CSV_FILE, sep=None, engine=''python'')
    df.columns = df.columns.str.strip()
    df[DATE_COL]  = pd.to_datetime(df[DATE_COL],  errors=''coerce'')
    df[BELGE_COL] = pd.to_datetime(df[BELGE_COL], errors=''coerce'')

    df = df[df[DATE_COL].dt.date < cutoff].copy()
    if df.empty:
        print("Gönderilecek kayıt yok.")
        return

    df[''Gelişten_Geçen_Gün''] = (pd.to_datetime(today) - df[DATE_COL]).dt.days
    df[''Belge_Gecikme_Gün'']  = (pd.to_datetime(today) - df[BELGE_COL]).dt.days

    # 60 günden eski olanlar filtrelenir
    df = df[df[''Gelişten_Geçen_Gün''] < 60]
    if df.empty:
        print("60 günden küçük kayıt yok.")
        return

    df.sort_values(DATE_COL, inplace=True)

    subject   = f"ERP’ye Girilmemiş Satış/İade Faturalar (⩽ {cutoff:%d.%m.%Y})"
    html_body = df.to_html(index=False, border=1, justify=''center'')

    send_mail(subject, html_body)

# ---------------------------------------------------------------------
if __name__ == "__main__":
    main()
',NULL,false),
	 (1,'16:20 veri gelmeyen sistemler','{"times": [{"minute": "20", "hour": "16", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
import smtplib
import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# CSV dosyalarını oku
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')
tanimli_sistemler = pd.read_csv(''tanımlı_mekatronik_sistem_listesi.csv'')

# Tarih formatına çevir
tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])

# Son 10 günü filtrele
today = pd.to_datetime(datetime.date.today())
tartimlar = tartimlar[tartimlar[''requestid_starttime''] >= today - pd.Timedelta(days=10)]

# Tanımlı sistemlerle eşleştir (right join)
tartimlar = pd.merge(tartimlar, tanimli_sistemler, on=[''companyname'', ''displayname''], how=''right'')

# Her sistem için en son veri tarihi
tartimlar[''Veri Gelen Son Tarih''] = tartimlar.groupby([''companyname'', ''displayname''])[''requestid_starttime''].transform(''max'')

# Bugün ile en son veri tarihi farkını hesapla
tartimlar[''Gün Farkı''] = (today - tartimlar[''Veri Gelen Son Tarih'']).dt.days

# Veri gelmeyenleri filtrele
tartimlar = tartimlar[(tartimlar[''Gün Farkı''] > 0) | (tartimlar[''Veri Gelen Son Tarih''].isnull())]

# Tekil kayıtlar al
tartimlar = tartimlar.drop_duplicates(subset=[''companyname'', ''displayname'', ''Veri Gelen Son Tarih''])

# Son veri tarihine göre sırala
tartimlar = tartimlar.sort_values(by=''Veri Gelen Son Tarih'', ascending=False)

# Tarihleri string yap
tartimlar[''Veri Gelen Son Tarih''] = tartimlar[''Veri Gelen Son Tarih''].dt.strftime(''%Y-%m-%d %H:%M:%S'')

# Boş veri tarihlerini doldur
tartimlar.loc[tartimlar[''Veri Gelen Son Tarih''].isnull(), ''Veri Gelen Son Tarih''] = ''10 günden daha uzun süredir veri gelmiyor''

# HTML tablo oluştur
html = tartimlar[[''companyname'', ''displayname'', ''Veri Gelen Son Tarih'']].to_html(index=False)

# Mail gönder
if not tartimlar.empty:
    msg = MIMEMultipart()
    msg[''Subject''] = ''Veri Gelmeyen Sistemler''
    msg[''From''] = ''eliar.arge@gmail.com''
#    msg[''To''] = ''sencer.sultanoglu@eliarge.com,ozcan.ozen@eliar.com.tr''
    msg[''To''] = ''sencer.sultanoglu@eliarge.com''

    # Sistem sayıları ve oranlar
    veri_gelmeyen_sayisi = len(tartimlar)
    veri_gelmesi_gereken_sayisi = len(tanimli_sistemler)
    veri_gelen_sayisi = veri_gelmesi_gereken_sayisi - veri_gelmeyen_sayisi

    veri_gelen_oran = (veri_gelen_sayisi / veri_gelmesi_gereken_sayisi) * 100 if veri_gelmesi_gereken_sayisi > 0 else 0
    veri_gelmeyen_oran = 100 - veri_gelen_oran

    body = ''<html><body>''
    body += ''<h2>Veri gelmeyen sistemler listesi aşağıdaki gibidir.</h2>''
    body += f''''''
        <p><b>Toplam sistem sayısı:</b> {veri_gelmesi_gereken_sayisi}</p>
        <p><b>Veri gelen sistem sayısı:</b> {veri_gelen_sayisi} (%{veri_gelen_oran:.1f})</p>
        <p><b>Veri gelmeyen sistem sayısı:</b> {veri_gelmeyen_sayisi} (%{veri_gelmeyen_oran:.1f})</p>
    ''''''
    body += html
    body += ''</body></html>''

    msg.attach(MIMEText(body, ''html''))

    server = smtplib.SMTP(''smtp.gmail.com'', 587)
    server.starttls()
    server.login(''eliar.arge@gmail.com'', ''ximjomxcivdluwkv'')
#    server.sendmail(''eliar.arge@gmail.com'', [''sencer.sultanoglu@eliarge.com'', ''ozcan.ozen@eliar.com.tr''], msg.as_string())
    server.sendmail(''eliar.arge@gmail.com'', [''sencer.sultanoglu@eliarge.com''], msg.as_string())
    server.quit()
',NULL,false),
	 (1,'17:14 alarm_tartım_detaylı','{"times": [{"minute": "14", "hour": "17", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
import smtplib
import time
import warnings
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import os

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# Alıcı listesi
alici_listesi = [
    ''sencer.sultanoglu@eliarge.com'',
    ''ozcan.ozen@eliar.com.tr'',
    ''sshmekatronik@eliar.com.tr'',
    ''mehmet.taygun@eliar.com.tr'',
    ''kursat.akyol@eliar.com.tr''
]

# Verileri oku
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')
alarmlar = pd.read_csv(''mekatronik_sistem_alarmları.csv'')

# Tarih hesapla (bir önceki gün)
bugun = datetime.today()
dun = bugun - timedelta(days=1)
dun_tarihi = dun.strftime(''%Y-%m-%d'')

# Alarm saatlerini datetime yap
alarmlar[''alarm_start_time''] = pd.to_datetime(alarmlar[''alarm_start_time''])

# Tartım bilgilerinden bazı sütunları alarmlar ile birleştir
alarmlar = alarmlar.merge(
    tartimlar[[''companyname'', ''displayname'', ''requestid'', ''detailid'', ''machine_name'', ''chemical_name'', ''batchno'']],
    on=[''companyname'', ''displayname'', ''requestid'', ''detailid''],
    how=''left''
)

# Sadece dün oluşan alarmları filtrele
alarmlar_dun = alarmlar[alarmlar[''alarm_start_time''].dt.date == dun.date()]

# Her sistemin günlük alarm sayısını hesapla
grouped_counts = alarmlar_dun.groupby([''companyname'', ''displayname'']).size().reset_index(name=''count'')
valid_entries = grouped_counts[grouped_counts[''count''] > 5][[''companyname'', ''displayname'']]

# Alarm sayısı > 5 olan sistemlerin detayları
filtered_df = alarmlar_dun.merge(valid_entries, on=[''companyname'', ''displayname''], how=''inner'')

# Eğer varsa, mail gönder
if not filtered_df.empty:
    # İlgili sütunları seç ve kolon adlarını değiştir
    fazla_alarmlı_sistemler = filtered_df[[
        ''companyname'', ''displayname'', ''batchno'', ''chemical_name'',
        ''alarm_start_time'', ''machine_name'', ''alarmname''
    ]]

    fazla_alarmlı_sistemler[''alarm_start_time''] = pd.to_datetime(fazla_alarmlı_sistemler[''alarm_start_time'']).dt.strftime(''%H:%M:%S'')

    fazla_alarmlı_sistemler_sorted = fazla_alarmlı_sistemler.sort_values(by=[''companyname'', ''displayname''])
    fazla_alarmlı_sistemler_sorted.columns = [
        ''Fabrika İsmi'', ''Sistem İsmi'', ''İş Emri No'', ''Kimyasal İsmi'',
        ''Alarm Başlama Saati'', ''Makine İsmi'', ''Alarm İsmi''
    ]

    # Excel dosyası olarak kaydet
    excel_path = ''alarm_raporu.xlsx''
    fazla_alarmlı_sistemler_sorted.to_excel(excel_path, index=False)

    html = fazla_alarmlı_sistemler_sorted.to_html(index=False)

    body = f''''''
    <h1>Fazla Alarm Veren Mekatronik Sistemler</h1>
    <h2>Anomali Ölçütü</h2>
    <p>{dun_tarihi} tarihi için günlük alarm sayısı 5''ten fazla olan sistemler listelenmiştir.</p>
    {html}
    ''''''

    # Mail gönderme işlemi
    for _ in range(5):
        try:
            msg = MIMEMultipart()
            msg[''From''] = ''eliar.arge@gmail.com''
            msg[''To''] = '', ''.join(alici_listesi)
            msg[''Subject''] = ''Fazla Alarm Veren Mekatronik Sistemler''
            msg.attach(MIMEText(body, ''html''))

            # Excel dosyasını ekle
            with open(excel_path, "rb") as f:
                part = MIMEBase(''application'', ''octet-stream'')
                part.set_payload(f.read())
                encoders.encode_base64(part)
                part.add_header(''Content-Disposition'', f''attachment; filename="{excel_path}"'')
                msg.attach(part)

            server = smtplib.SMTP(''smtp.gmail.com'', 587)
            server.starttls()
            server.login(msg[''From''], ''ximjomxcivdluwkv'')
            server.sendmail(msg[''From''], alici_listesi, msg.as_string())
            server.quit()

            # Geçici dosya silinebilir
            os.remove(excel_path)
            break
        except Exception as e:
            print(f"Mail atma hatası: {e}")
            time.sleep(5)
else:
    print("Alarm sayısı sınırı aşan sistem yok, mail gönderilmedi.")
',NULL,false),
	 (2,'Girilmemiş Faturaların Bildirilmesi (Ürün Tedarikçileri)','{"times": [{"minute": "30", "hour": "08", "day_of_month": "*", "month": "*", "day_of_week": "1,4"}]}','#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ERP’ye Girilmemiş Faturalar – E-posta + Redmine Entegrasyonu
------------------------------------------------------------
• Çalışma zamanı: Salı & Cuma 
• CSV         : Girilmemis_Faturalarin_Bildirilmesi.csv
• E-posta     : Firma bazlı alıcı listeleri, TEST_MODE desteği
• Redmine     : Firma bazlı tek “Anomali” issue’u
"""

import sys, time, smtplib, mimetypes, json, requests, os, datetime as dt
from pathlib import Path
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
import pandas as pd

# ---------------------------------------------------------------------
# GENEL AYARLAR
# ---------------------------------------------------------------------
CSV_FILE   = ''Girilmemis_Faturalarin_Bildirilmesi.csv''
DATE_COL   = ''GelişTarih''
BELGE_COL  = ''BelgeTarihi''
FIRMA_COL  = ''Firma''

SMTP_HOST  = ''smtp.gmail.com''
SMTP_PORT  = 587
SMTP_USER  = ''eliar.arge@gmail.com''
SMTP_PASS  = ''ximjomxcivdluwkv''

TEST_MODE  = False
TEST_RECIPIENTS = [
    ''sencer.sultanoglu@eliarge.com'',
    ''efe.demir@eliarge.com'',
    ''zeynep.dundar@eliar.com.tr'',
]

ELIAR_RECIPIENTS = [
    ''projedepo@eliar.com.tr'',
    ''onur.bozkurt@eliar.com.tr'',
    ''anil.cakal@eliar.com.tr'',
    ''busra.celikkol@eliar.com.tr'',
    ''zeynep.dundar@eliar.com.tr'',
    ''engin.reyhan@eliar.com.tr'',
    ''sencer.sultanoglu@eliarge.com'',
]

ETO_RECIPIENTS = [
    ''projedepo@eliar.com.tr'',
    ''onur.bozkurt@eliar.com.tr'',
    ''zeynep.dundar@eliar.com.tr'',
    ''engin.reyhan@eliar.com.tr'',
    ''sencer.sultanoglu@eliarge.com'',
]

# ---------------------------------------------------------------------
# REDMINE AYARLARI
# ---------------------------------------------------------------------
REDMINE_URL         = ''http://194.5.236.35:3000''
API_KEY             = ''87db127a5d19e91e4be799cbaa497ee3584beb72''
PROJECT_ID          = ''deneme''
TARGET_TRACKER_NAME = ''Anomali''
CLOSED_STATUS_ID    = 3
CACHE_FILE          = Path(''.redmine_issue_cache.json'')

HEADERS_JSON = {
    ''Content-Type'': ''application/json'',
    ''X-Redmine-API-Key'': API_KEY
}

# ---------------------------------------------------------------------
# E-POSTA YARDIMCILARI
# ---------------------------------------------------------------------
def send_mail(subject: str, html_body: str, recipients: list[str]) -> None:
    msg = MIMEMultipart()
    msg[''Subject''] = subject
    msg[''From''] = SMTP_USER
    msg[''To''] = ", ".join(recipients)
    msg.attach(MIMEText(html_body, ''html''))

    for attempt in range(5):
        try:
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
                server.starttls()
                server.login(SMTP_USER, SMTP_PASS)
                server.sendmail(SMTP_USER, recipients, msg.as_string())
            print(f"✔ Mail gönderildi → {len(recipients)} alıcı")
            break
        except Exception as e:
            print(f"✖ Gönderim hatası (deneme {attempt+1}/5): {e}")
            time.sleep(5)

# ---------------------------------------------------------------------
# REDMINE TEMEL FONKSİYONLARI
# ---------------------------------------------------------------------
def api_request(method: str, url: str, data=None, params=None, retry=3):
    for i in range(retry):
        try:
            r = requests.request(method, url, headers=HEADERS_JSON,
                                 data=data, params=params, timeout=30)
            r.raise_for_status()
            return r
        except requests.exceptions.RequestException as e:
            if i < retry - 1:
                time.sleep(2*(i+1))
            else:
                print(f"API hatası: {e}")
    return None

def get_tracker_id(name: str) -> Optional[int]:
    r = api_request(''get'', f"{REDMINE_URL}/trackers.json")
    if not r:
        return None
    for tr in r.json().get(''trackers'', []):
        if tr[''name''].lower() == name.lower():
            return tr[''id'']
    return None

def search_issue(subject: str, tracker_id: int) -> Optional[int]:
    params = {''project_id'': PROJECT_ID, ''tracker_id'': tracker_id,
              ''status_id'': ''*'', ''subject'': f"~{subject}"}
    r = api_request(''get'', f"{REDMINE_URL}/issues.json", params=params)
    if not r:
        return None
    issues = r.json().get(''issues'', [])
    return issues[0][''id''] if issues else None

def add_note(issue_id: int, note_html: str):
    payload = {''issue'': {''notes'': note_html}}
    api_request(''put'', f"{REDMINE_URL}/issues/{issue_id}.json",
                data=json.dumps(payload))

def create_issue(subject: str, description: str, tracker_id: int) -> Optional[int]:
    payload = {''issue'': {
        ''project_id'': PROJECT_ID, ''subject'': subject,
        ''description'': description, ''tracker_id'': tracker_id,
        ''priority_id'': 5}}
    r = api_request(''post'', f"{REDMINE_URL}/issues.json",
                    data=json.dumps(payload))
    if r and r.status_code == 201:
        return r.json()[''issue''][''id'']
    return None

def post_to_redmine(subject: str, df: pd.DataFrame):
    tracker_id = get_tracker_id(TARGET_TRACKER_NAME)
    if not tracker_id:
        print("Tracker ID alınamadı, Redmine işlemi atlandı.")
        return
    html = df.to_html(index=False, border=1)
    issue_id = search_issue(subject, tracker_id)
    if issue_id:
        add_note(issue_id, html)
        print(f"Redmine: not eklendi (issue #{issue_id})")
    else:
        new_id = create_issue(subject, subject, tracker_id)
        if new_id:
            add_note(new_id, html)
            print(f"Redmine: yeni issue oluşturuldu (#{new_id})")

# ---------------------------------------------------------------------
# İŞ MANTIĞI
# ---------------------------------------------------------------------
def main():
    today_ts = pd.Timestamp.today().normalize()

    df = pd.read_csv(CSV_FILE, sep=None, engine=''python'')
    df.columns = df.columns.str.strip()
    df[DATE_COL]  = pd.to_datetime(df[DATE_COL],  errors=''coerce'')
    df[BELGE_COL] = pd.to_datetime(df[BELGE_COL], errors=''coerce'')

    df[''Gelişten_Geçen_Gün''] = (today_ts - df[DATE_COL]).dt.days
    df[''Belge_Gecikme_Gün'']  = (today_ts - df[BELGE_COL]).dt.days

    df.sort_values(DATE_COL, ascending=True, inplace=True)

    # Sadece son 30 gün
    df = df[df[DATE_COL] >= (today_ts - pd.Timedelta(days=30))]

    if df.empty:
        print("Gönderilecek kayıt yok.")
        return

    period_start = df[DATE_COL].min().date()
    period_end   = df[DATE_COL].max().date()

    for firma, group in df.groupby(FIRMA_COL):
        group_sorted = group.sort_values(DATE_COL, ascending=True)
        recipients = TEST_RECIPIENTS if TEST_MODE else (
            ELIAR_RECIPIENTS if firma.upper() == "ELIAR" else ETO_RECIPIENTS
        )
        subject = (f"{firma} – ERP’ye Girilmemiş Faturalar "
                   f"({period_start:%d.%m.%Y}-{period_end:%d.%m.%Y})")
        html = group_sorted.to_html(index=False, border=1)

        send_mail(subject, html, recipients)
#       post_to_redmine(subject, group_sorted)

if __name__ == "__main__":
    main()
','',false,NULL),
	 (1,'17:22 bir önceki günkü tartım sayıları','{"times": [{"minute": "22", "hour": "17", "day_of_month": "*", "month": "*", "day_of_week": "*"}]}','import pandas as pd
from datetime import datetime, timedelta
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# CSV''den veriyi oku
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

# Tarihleri dönüştür
tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])

# Bir gün öncenin tarihi
bugun = datetime.today()
dun = bugun - timedelta(days=1)
dun_tarihi = dun.date()

# Sadece bir gün öncenin verisini filtrele
tartimlar_dun = tartimlar[tartimlar[''requestid_starttime''].dt.date == dun_tarihi]

# Gruplama
gruplu = tartimlar_dun.groupby([''companyname'', ''displayname'']).agg(
    Toplam_Tartim_Sayisi=(''detailid'', ''count''),
    Toplam_Tartim_Suresi=(''duration'', ''sum''),
    Hizmet_Edilen_Makine_Sayisi=(''machine_name'', pd.Series.nunique)
).reset_index()

# Makine başına ortalama tartım sayısı
gruplu[''Makine_Basina_Ortalama_Tartim''] = gruplu[''Toplam_Tartim_Sayisi''] / gruplu[''Hizmet_Edilen_Makine_Sayisi'']

# Süreyi saat:dakika formatına çevir
def format_sure(dk):
    saat = dk // 60
    dakika = dk % 60
    return f"{int(saat):02}:{int(dakika):02}"

gruplu[''Toplam Tartım Süresi''] = gruplu[''Toplam_Tartim_Suresi''].apply(format_sure)

# Sıralama: önce en çok tartım yapanlar
gruplu = gruplu.sort_values(by=''Toplam_Tartim_Sayisi'', ascending=False)

# Sütun adlarını kullanıcı dostu hale getir
gruplu = gruplu.rename(columns={
    ''companyname'': ''Fabrika İsmi'',
    ''displayname'': ''Sistem İsmi'',
    ''Toplam_Tartim_Sayisi'': ''Toplam Tartım Sayısı'',
    ''Hizmet_Edilen_Makine_Sayisi'': ''Hizmet Edilen Makine Sayısı'',
    ''Makine_Basina_Ortalama_Tartim'': ''Makine Başına Ortalama Tartım''
})

# Gereksiz kolonu sil
gruplu = gruplu[[''Fabrika İsmi'', ''Sistem İsmi'', ''Toplam Tartım Sayısı'', ''Toplam Tartım Süresi'', ''Hizmet Edilen Makine Sayısı'', ''Makine Başına Ortalama Tartım'']]

# HTML çıktısı oluştur
html = gruplu.to_html(index=False, float_format="%.2f")

# E-posta gönderilecek adresler
recipients = [
    ''sencer.sultanoglu@eliarge.com'',
    ''mehmet.taygun@eliar.com.tr'',
    ''kursat.akyol@eliar.com.tr'',
    ''ozcan.ozen@eliar.com.tr'',
    ''sshmekatronik@eliar.com.tr''
]

# Eğer sonuç varsa, e-posta gönder
if not gruplu.empty:
    try:
        msg = MIMEMultipart()
        msg[''From''] = ''eliar.arge@gmail.com''
        msg[''To''] = '', ''.join(recipients)
        msg[''Subject''] = ''Dünkü Tartım Sayıları ve Süreleri (Fabrika ve Sistem Bazında)''

        body = f''<h1>{dun_tarihi} Tarihli Tartım Raporu</h1>''
        body += html
        msg.attach(MIMEText(body, ''html''))

        server = smtplib.SMTP(''smtp.gmail.com'', 587)
        server.starttls()
        server.login(msg[''From''], ''ximjomxcivdluwkv'')
        server.sendmail(msg[''From''], recipients, msg.as_string())
        server.quit()
    except Exception as e:
        print(f"Mail gönderim hatası: {e}")
else:
    print("Sonuç boş. Mail gönderilmeyecek.")
',NULL,false,NULL),
	 (1,'TEST İÇİN KULLANILAN AUTOPROMPT','{"times": []}','import pandas as pd
from datetime import datetime, timedelta
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import warnings

warnings.simplefilter(action=''ignore'', category=pd.errors.SettingWithCopyWarning)

# CSV''den veriyi oku
tartimlar = pd.read_csv(''mekatronik_sistem_tartımları.csv'')

# Tarihleri dönüştür
tartimlar[''requestid_starttime''] = pd.to_datetime(tartimlar[''requestid_starttime''])

# Bir gün öncenin tarihi
bugun = datetime.today()
dun = bugun - timedelta(days=1)
dun_tarihi = dun.date()

# Sadece bir gün öncenin verisini filtrele
tartimlar_dun = tartimlar[tartimlar[''requestid_starttime''].dt.date == dun_tarihi]

# Gruplama
gruplu = tartimlar_dun.groupby([''companyname'', ''displayname'']).agg(
    Toplam_Tartim_Sayisi=(''detailid'', ''count''),
    Toplam_Tartim_Suresi=(''duration'', ''sum''),
    Farkli_Makine_Sayisi=(''machine_name'', pd.Series.nunique)
).reset_index()

# Makine başına ortalama tartım sayısı
gruplu[''Makine_Basina_Ortalama_Tartim''] = gruplu[''Toplam_Tartim_Sayisi''] / gruplu[''Farkli_Makine_Sayisi'']

# Süreyi saat:dakika formatına çevir
def format_sure(dk):
    saat = dk // 60
    dakika = dk % 60
    return f"{int(saat):02}:{int(dakika):02}"

gruplu[''Toplam Tartım Süresi''] = gruplu[''Toplam_Tartim_Suresi''].apply(format_sure)

# Sıralama: önce en çok tartım yapanlar
gruplu = gruplu.sort_values(by=''Toplam_Tartim_Sayisi'', ascending=False)

# Sütun adlarını kullanıcı dostu hale getir
gruplu = gruplu.rename(columns={
    ''companyname'': ''Fabrika İsmi'',
    ''displayname'': ''Sistem İsmi'',
    ''Toplam_Tartim_Sayisi'': ''Toplam Tartım Sayısı'',
    ''Farkli_Makine_Sayisi'': ''Farklı Makine Sayısı'',
    ''Makine_Basina_Ortalama_Tartim'': ''Makine Başına Ortalama Tartım''
})

# Gereksiz kolonu sil
gruplu = gruplu[[''Fabrika İsmi'', ''Sistem İsmi'', ''Toplam Tartım Sayısı'', ''Toplam Tartım Süresi'', ''Farklı Makine Sayısı'', ''Makine Başına Ortalama Tartım'']]

# HTML çıktısı oluştur
html = gruplu.to_html(index=False, float_format="%.2f")

# E-posta gönderilecek tek adres
recipients = [''sencer.sultanoglu@eliarge.com'']

# Eğer sonuç varsa, e-posta gönder
if not gruplu.empty:
    try:
        msg = MIMEMultipart()
        msg[''From''] = ''eliar.arge@gmail.com''
        msg[''To''] = '', ''.join(recipients)
        msg[''Subject''] = ''Dünkü Tartım Sayıları ve Süreleri (Fabrika ve Sistem Bazında)''

        body = f''<h1>{dun_tarihi} Tarihli Tartım Raporu</h1>''
        body += html
        msg.attach(MIMEText(body, ''html''))

        server = smtplib.SMTP(''smtp.gmail.com'', 587)
        server.starttls()
        server.login(msg[''From''], ''ximjomxcivdluwkv'')
        server.sendmail(msg[''From''], recipients, msg.as_string())
        server.quit()
    except Exception as e:
        print(f"Mail gönderim hatası: {e}")
else:
    print("Sonuç boş. Mail gönderilmeyecek.")
',NULL,false);
