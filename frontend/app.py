import streamlit as st
import requests
import pandas as pd
import json
import re
import time

table_options = {
    "Roles": {
        "endpoint": "roles",
        "fields": [
            {"name": "role_id", "type": "number"},
            {"name": "role_name", "type": "text"},
            {"name": "permissions", "type": "json"},
            {"name": "admin_or_not", "type": "bool"}
        ]
    },
    "Users": {
        "endpoint": "users",
        "fields": [
            {"name": "user_id", "type": "number"},
            {"name": "role_id", "type": "number"},
            {"name": "name", "type": "text"},
            {"name": "surname", "type": "text"},
            {"name": "password", "type": "text"},
            {"name": "e_mail", "type": "text"},
            {"name": "institution_working", "type": "text"}
        ]
    },
    "Database_Info": {
        "endpoint": "database_info",
        "fields": [
            {"name": "database_ip", "type": "text"},
            {"name": "database_port", "type": "text"},
            {"name": "database_user", "type": "text"},
            {"name": "database_password", "type": "text"},
            {"name": "database_type", "type": "text"},
            {"name": "database_name", "type": "text"},
            {"name": "user_id", "type": "number"}
        ]
    },
    "Data_Prepare_Modules": {
        "endpoint": "data_prepare_modules",
        "fields": [
            {"name": "module_id", "type": "number"},
            {"name": "module_name", "type": "text"},
            {"name": "description", "type": "text"},
            {"name": "user_id", "type": "number"},
            {"name": "asistan_id", "type": "number"},
            {"name": "database_id", "type": "number"},
            {"name": "csv_database_id", "type": "number"},
            {"name": "query", "type": "text"},
            {"name": "working_platform", "type": "text"},
            {"name": "query_name", "type": "text"},
            {"name": "db_schema", "type": "text"},
            {"name": "documents_id", "type": "number"},
            {"name": "csv_db_schema", "type": "text"},
            {"name": "data_prep_code", "type": "text"}
        ]
    },
    "Assistants": {
        "endpoint": "assistants",
        "fields": [
            {"name": "title", "type": "text"},
            {"name": "explanation", "type": "text"},
            {"name": "parameters", "type": "json"},
            {"name": "user_id", "type": "number"},
            {"name": "working_place", "type": "json"},
            {"name": "default_instructions", "type": "text"},
            {"name": "data_instructions", "type": "text"},
            {"name": "file_path", "type": "text"},
            {"name": "trigger_time", "type": "json"}
        ]
    },
    "Auto_Prompt": {
        "endpoint": "auto_prompt",
        "fields": [
            {"name": "question", "type": "text"},
            {"name": "assistant_title", "type": "text"},
            {"name": "trigger_time", "type": "json"},
            {"name": "python_code", "type": "text"},
            {"name": "mcrisactive", "type": "bool"},
            {"name": "receiver_emails", "type": "text"}
        ]
    },
    "Documents": {
        "endpoint": "documents",
        "fields": [
            {"name": "user_id", "type": "number"},
            {"name": "asistan_id", "type": "number"},
            {"name": "file_path", "type": "text"},
            {"name": "file_type", "type": "text"},
            {"name": "description", "type": "text"}
        ]
    },
    "Models": {
        "endpoint": "models",
        "fields": [
            {"name": "model_id", "type": "number"},
            {"name": "name", "type": "text"},
            {"name": "provider", "type": "text"},
            {"name": "model_version", "type": "text"},
            {"name": "is_active", "type": "bool"},
            {"name": "default_parameters", "type": "json"}
        ]
    }
}

# Streamlit frontend'de backend'e istek atmak için:
backend_url = "http://tablo_uygulama-backend-1:8000" 

# --- BAŞARI MESAJI BLOĞU ---
if "success_message" in st.session_state:
    st.success(st.session_state["success_message"])
    del st.session_state["success_message"]

if "role_form_key" not in st.session_state:
    st.session_state["role_form_key"] = 0

if "show_table" not in st.session_state:
    st.session_state["show_table"] = False

# Başlangıçta session state'i kontrol et
if "form_states" not in st.session_state:
    st.session_state["form_states"] = {}

# Form durumlarını yönetmek için yardımcı fonksiyon
def should_rerun(table_name, action):
    """Sadece gerekli durumlarda rerun yapar"""
    # Artık kullanılmıyor, direkt st.rerun() kullanıyoruz
    return False

def mark_form_completed(table_name, action):
    """Form işlemini tamamlandı olarak işaretler"""
    if "form_states" not in st.session_state:
        st.session_state["form_states"] = {}
    st.session_state["form_states"][f"{table_name}_{action}"] = True

# --- GERİ AL (UNDO) BLOĞU ---
# table_options değişkeni dosyanın başında tanımlı ve globaldir, burada erişilebilir olmalı
if "last_deleted" in st.session_state:
    deleted = st.session_state["last_deleted"]
    # İlk gösterim zamanı kaydedilmemişse kaydet
    if "last_deleted_time" not in st.session_state:
        st.session_state["last_deleted_time"] = time.time()
    col1, col2 = st.columns([4,1])
    with col1:
        st.warning(f"{deleted['table_name']} tablosundan bir kayıt silindi. Geri almak ister misiniz?")
    with col2:
        if st.button("Geri Al", key="undo_delete"):
            try:
                endpoint = table_options[deleted['table_name']]['endpoint']
                # Şu anki tabloyu kaydet
                st.session_state['last_table'] = st.session_state.get('table_name', deleted['table_name'])
                resp = requests.post(f"{backend_url}/{endpoint}", json=deleted['data'])
                if resp.status_code == 200:
                    st.session_state["success_message"] = "Kayıt başarıyla geri alındı!"
                    del st.session_state["last_deleted"]
                    if "last_deleted_time" in st.session_state:
                        del st.session_state["last_deleted_time"]
                    st.rerun()
                else:
                    st.error("Geri alma başarısız: " + resp.text)
            except Exception as e:
                st.error(f"Geri alma başarısız: {e}")
    # 15 saniye geçtiyse uyarıyı kaldır
    if "last_deleted_time" in st.session_state and time.time() - st.session_state["last_deleted_time"] > 15:
        del st.session_state["last_deleted"]
        del st.session_state["last_deleted_time"]
        # 15 saniye sonra otomatik temizlik için rerun yap
        st.rerun()

# Custom CSS for alert boxes (KALDIRILDI)

def get_users():
    try:
        resp = requests.get(f"{backend_url}/users")
        if resp.status_code == 200:
            return resp.json()
        return []
    except Exception:
        return []

def get_roles():
    try:
        resp = requests.get(f"{backend_url}/roles")
        if resp.status_code == 200:
            return resp.json()
        return []
    except Exception:
        return []

def get_assistants():
    try:
        resp = requests.get(f"{backend_url}/assistants")
        if resp.status_code == 200:
            return resp.json()
        return []
    except Exception:
        return []

def get_database_info():
    try:
        resp = requests.get(f"{backend_url}/database_info")
        if resp.status_code == 200:
            return resp.json()
        return []
    except Exception:
        return []

def get_documents():
    try:
        resp = requests.get(f"{backend_url}/documents")
        if resp.status_code == 200:
            return resp.json()
        return []
    except Exception:
        return []

def get_models():
    try:
        resp = requests.get(f"{backend_url}/models")
        if resp.status_code == 200:
            return resp.json()
        return []
    except Exception:
        return []

def is_valid_email(email):
    return re.match(r"[^@]+@[^@]+\.[^@]+", email) is not None

# --- Güvenli JSON parse fonksiyonu ---
def safe_json_parse(val):
    if isinstance(val, str):
        try:
            val = json.loads(val)
            if isinstance(val, str):
                val = json.loads(val)
        except Exception:
            val = {}
    return val

# --- JSON formatı örneği fonksiyonu ---
def json_example(field_name):
    examples = {
        'parameters': '{"embedding_model": "gpt-3", "llm_model": "gpt-3.5-turbo", "temperature": 0.7}',
        'trigger_time': '{"times": "09:00, 14:00"}',
        'permissions': '{"all": "read,write"}'
    }
    return examples.get(field_name, '{"key": "value"}')

# --- JSON alanı validasyon fonksiyonu ---
def validate_json_input(json_str):
    try:
        json.loads(json_str)
        return True, ""
    except Exception as e:
        return False, str(e)

def pretty_json(val):
    if not val:
        return "{}"
    if isinstance(val, dict):
        return json.dumps(val, ensure_ascii=False, indent=2)
    if isinstance(val, str):
        try:
            obj = json.loads(val)
            return json.dumps(obj, ensure_ascii=False, indent=2)
        except Exception:
            return val
    return str(val)

st.title("Tablo Yönetim Paneli")
# --- TABLO SEÇİMİ ---
if 'table_name' in st.session_state and st.session_state['table_name'] in table_options:
    default_index = list(table_options.keys()).index(st.session_state['table_name'])
else:
    default_index = 0

def on_table_change():
    st.session_state['table_name'] = st.session_state['sidebar_table_select']

table_name = st.sidebar.selectbox(
    "Tablo Seçin",
    list(table_options.keys()),
    index=default_index,
    key="sidebar_table_select",
    on_change=on_table_change
)
st.session_state['table_name'] = table_name

config = table_options[table_name]
endpoint = config["endpoint"]
fields = config["fields"]

st.header(f"{table_name} Tablosu")

if table_name == "Users":
    roles = get_roles()
    role_name_to_id = {r['role_name']: r['role_id'] for r in roles}
    role_names = list(role_name_to_id.keys())

# Listele
if st.button("Verileri Listele"):
    st.session_state["show_table"] = not st.session_state["show_table"]

if st.session_state["show_table"]:
    try:
        resp = requests.get(f"{backend_url}/{endpoint}")
       
        data = resp.json()
        if isinstance(data, list) and data:
            if table_name == "Users":
                for user in data:
                    user['role_name'] = next((r['role_name'] for r in roles if r['role_id'] == user['role_id']), "")
                df = pd.DataFrame(data)
                show_cols = ['user_id', 'role_name', 'name', 'surname', 'e_mail', 'institution_working']
                show_cols = [c for c in show_cols if c in df.columns and c not in ['create_date', 'change_date']]
                st.dataframe(df[show_cols])
            elif table_name == "Assistants":
                # JSON alanlarını düzgün göster (çift stringleşmişse iki kez parse et)
                for row in data:
                    for field in ["parameters", "trigger_time"]:
                        val = row.get(field, "")
                        if isinstance(val, str):
                            try:
                                val = json.loads(val)
                                if isinstance(val, str):
                                    val = json.loads(val)
                            except Exception:
                                pass
                        row[field] = json.dumps(val, ensure_ascii=False, indent=2) if val else ""
                df = pd.DataFrame(data)
                show_cols = ['asistan_id', 'title', 'explanation', 'parameters', 'user_id', 'working_place', 'default_instructions', 'data_instructions', 'file_path', 'trigger_time']
                show_cols = [c for c in show_cols if c in df.columns and c not in ['create_date', 'change_date']]
                st.dataframe(df[show_cols])
            elif table_name == "Auto_Prompt":
                df = pd.DataFrame(data)
                show_cols = ['prompt_id', 'question', 'assistant_title', 'trigger_time', 'python_code', 'mcrisactive', 'receiver_emails']
                show_cols = [c for c in show_cols if c in df.columns and c not in ['create_date', 'change_date']]
                st.dataframe(df[show_cols])
            elif table_name == "Data_Prepare_Modules":
                df = pd.DataFrame(data)
                show_cols = ['module_id', 'query', 'user_id', 'asistan_id', 'database_id', 'csv_database_id', 'query_name', 'working_platform', 'db_schema', 'documents_id', 'csv_db_schema', 'data_prep_code']
                show_cols = [c for c in show_cols if c in df.columns and c not in ['create_date', 'change_date']]
                st.dataframe(df[show_cols])
            elif table_name == "Roles":
                df = pd.DataFrame(data)
                show_cols = ['role_id', 'role_name', 'permissions', 'admin_or_not']
                show_cols = [c for c in show_cols if c in df.columns and c not in ['create_date', 'change_date']]
                st.dataframe(df[show_cols])
            elif table_name == "Database_Info":
                df = pd.DataFrame(data)
                show_cols = ['database_id', 'database_ip', 'database_port', 'database_user', 'database_password', 'database_type', 'database_name', 'user_id']
                show_cols = [c for c in show_cols if c in df.columns and c not in ['create_date', 'change_date']]
                st.dataframe(df[show_cols])
            elif table_name == "Documents":
                # Users ve Assistants tablolarından verileri çek
                try:
                    users = requests.get(f"{backend_url}/users").json()
                    assistants = requests.get(f"{backend_url}/assistants").json()
                except Exception:
                    users = []
                    assistants = []
                
                # user_id ve asistan_id'lerin yanına isim/başlık ekle
                for doc in data:
                    # user_id'nin yanına kullanıcı bilgilerini ekle
                    user_id = doc.get('user_id')
                    if user_id:
                        user = next((u for u in users if u['user_id'] == user_id), None)
                        if user:
                            doc['user_display'] = f"{user_id} - {user['name']} {user['surname']} ({user['e_mail']})"
                        else:
                            doc['user_display'] = f"{user_id} - Kullanıcı Bulunamadı"
                    else:
                        doc['user_display'] = "Belirtilmemiş"
                    
                    # asistan_id'nin yanına asistan başlığını ekle
                    asistan_id = doc.get('asistan_id')
                    if asistan_id:
                        assistant = next((a for a in assistants if a['asistan_id'] == asistan_id), None)
                        if assistant:
                            doc['assistant_display'] = f"{asistan_id} - {assistant['title']}"
                        else:
                            doc['assistant_display'] = f"{asistan_id} - Asistan Bulunamadı"
                    else:
                        doc['assistant_display'] = "Belirtilmemiş"
                
                df = pd.DataFrame(data)
                show_cols = ['document_id', 'user_display', 'assistant_display', 'file_path', 'file_type', 'description']
                show_cols = [c for c in show_cols if c in df.columns]
                st.dataframe(df[show_cols])
            elif table_name == "Models":
                # JSON alanlarını düzgün göster
                for row in data:
                    val = row.get("default_parameters", "")
                    if isinstance(val, str):
                        try:
                            val = json.loads(val)
                            if isinstance(val, str):
                                val = json.loads(val)
                        except Exception:
                            pass
                    row["default_parameters"] = json.dumps(val, ensure_ascii=False, indent=2) if val else ""
                
                df = pd.DataFrame(data)
                show_cols = ['model_id', 'name', 'provider', 'model_version', 'is_active', 'default_parameters']
                show_cols = [c for c in show_cols if c in df.columns and c not in ['create_date', 'change_date']]
                st.dataframe(df[show_cols])
            else:
                df = pd.DataFrame(data)
                st.dataframe(df)
        elif isinstance(data, list) and len(data) == 0:
            st.info("Tablo boş, hiç kayıt yok.")
        else:
            st.info("Tabloda veri yok.")
    except Exception as e:
        st.error(f"Veri alınamadı: {e}")

# Expander state management
if "add_expander_open" not in st.session_state:
    st.session_state["add_expander_open"] = False
if "delete_expander_open" not in st.session_state:
    st.session_state["delete_expander_open"] = False
if "update_expander_open" not in st.session_state:
    st.session_state["update_expander_open"] = False

# Ekle
if "add_expander_open" not in st.session_state:
    st.session_state["add_expander_open"] = False
with st.expander("Yeni Kayıt Ekle", expanded=st.session_state.get("add_expander_open", False)):
    def check_required_fields(field_defs, values_dict):
        missing = []
        for f in field_defs:
            fname = f["name"]
            if fname in ["create_date", "change_date"]:
                continue
            if f["type"] == "bool":
                continue
            if not values_dict.get(fname) and values_dict.get(fname) != False:
                missing.append((fname, f"{fname} alanı zorunludur."))
        return missing

    if table_name == "Roles":
        form = st.form(key=f"role_form_{st.session_state['role_form_key']}")
        role_id = form.number_input("role_id", min_value=0, step=1, format="%d")
        role_name = form.text_input("role_name", max_chars=100)
        # permissions başlığı ve kutucuk
        form.markdown("**permissions (JSON):**")
        permissions = form.text_area("permissions", value="{}", key="add_permissions_json")
        valid_permissions, permissions_err = validate_json_input(permissions)
        if not valid_permissions:
            form.markdown('<div style="color:red; font-size:12px;">Hatalı JSON formatı. Lütfen geçerli bir JSON girin.<br>Örnek: {\"all\": \"read,write\"}</div>', unsafe_allow_html=True)
        admin_or_not = form.selectbox("admin_or_not", ["Evet", "Hayır"]) == "Evet"
        submitted = form.form_submit_button("Ekle")
        add_data = {
            "role_id": role_id,
            "role_name": role_name,
            "permissions": permissions,
            "admin_or_not": admin_or_not
        }
        missing_fields = check_required_fields(table_options["Roles"]["fields"], add_data)
        if submitted:
            if role_id == 0:
                form.error("Role ID 0 olamaz.")
            elif missing_fields:
                for mf, reason in missing_fields:
                    form.markdown(f'<div style="color:red; font-size:12px;">{reason}</div>', unsafe_allow_html=True)
                form.error("Eksik alan(lar): " + ", ".join([mf for mf, _ in missing_fields]))
            elif not valid_permissions:
                form.error("Lütfen permissions alanına geçerli bir JSON girin.")
            else:
                try:
                    add_data["permissions"] = json.loads(permissions) if permissions else {}
                    resp = requests.post(f"{backend_url}/roles", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state["role_form_key"] += 1
                        st.session_state['last_table'] = table_name
                        st.session_state["add_expander_open"] = True
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                if 'e_mail' in error_msg.lower() or 'email' in error_msg.lower():
                                    form.error('Bu e-posta adresiyle zaten bir kullanıcı var.')
                                elif 'id' in error_msg.lower() or 'role_id' in error_msg.lower():
                                    form.error('Bu role_id zaten mevcut, lütfen farklı bir ID girin.')
                                elif 'name' in error_msg.lower():
                                    form.error('Bu isimle bir kayıt zaten eklenmiş.')
                                else:
                                    form.error('Bu kayıt zaten mevcut.')
                            else:
                                form.error(error_msg)
                        except Exception:
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                except Exception as e:
                    form.error(str(e))
    elif table_name == "Assistants":
        users = get_users()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        form = st.form(key=f"assistant_form_{st.session_state.get('assistant_form_key', 0)}")
        # asistan_id alanı title'ın üstünde, sadece rakam girilebilir, boş veya 0 olamaz
        asistan_id_str = form.text_input("asistan_id", value="", max_chars=10, key="add_asistan_id", placeholder="Asistan ID girin (min: 1)")
        # asistan_id kontrolleri
        asistan_id = int(asistan_id_str) if asistan_id_str.isdigit() or (asistan_id_str and asistan_id_str.lstrip('-').isdigit()) else None
        asistan_id_invalid = False
        asistan_id_error_msg = ""
        if not asistan_id_str:
            pass
        elif not (asistan_id_str.lstrip('-').isdigit()):
            asistan_id_invalid = True
            asistan_id_error_msg = "Sadece sayı giriniz (ör: 1234)"
        elif asistan_id is not None and asistan_id == 0:
            asistan_id_invalid = True
            asistan_id_error_msg = "Asistan ID 0 olamaz."
        elif asistan_id is not None and asistan_id < 0:
            asistan_id_invalid = True
            asistan_id_error_msg = "Negatif ID olamaz."
        elif asistan_id is not None and any(a.get('asistan_id') == asistan_id for a in get_assistants()):
            asistan_id_invalid = True
            asistan_id_error_msg = "Bu ID ile zaten bir kayıt mevcut. Lütfen farklı bir ID girin."
        if asistan_id_invalid:
            form.markdown(f'<div style="color:red; font-size:12px;">{asistan_id_error_msg}</div>', unsafe_allow_html=True)
        title = form.text_area("title", max_chars=255)
        explanation = form.text_area("explanation")
        # working_place başlığı ve tek kutucuk
        # (Bu kısmı tamamen kaldırıyorum, sadece diğer working_place alanı kalacak)
        # parameters başlığı ve alt kutucuklar
        form.markdown("**parameters (JSON):**")
        colp1, colp2, colp3 = form.columns(3)
        with colp1:
            parameters_embedding_model = form.text_input("embedding_model", max_chars=100, key="add_parameters_embedding_model")
        with colp2:
            parameters_llm_model = form.text_input("llm_model", max_chars=100, key="add_parameters_llm_model")
        with colp3:
            parameters_temperature = form.text_input("temperature", max_chars=100, key="add_parameters_temperature")
        parameters = {
            "embedding_model": parameters_embedding_model,
            "llm_model": parameters_llm_model,
            "temperature": parameters_temperature
        }
        # trigger_time başlığı ve alt kutucuklar
        form.markdown("**trigger_time(JSON):**")
        col4 = form.columns(1)[0]
        with col4:
            trigger_time_times = form.text_input("times", max_chars=100, key="add_trigger_time_times", help="Örnek: 09:00, 14:00, 18:30")
        # Zaman formatı kontrolü
        trigger_time_invalid = False
        if trigger_time_times:
            import re
            # HH:MM formatında zaman kontrolü (virgülle ayrılmış)
            time_pattern = r'^(\d{1,2}:\d{2})(,\s*\d{1,2}:\d{2})*$'
            if not re.match(time_pattern, trigger_time_times):
                form.markdown('<div style="color:red; font-size:12px;">Lütfen geçerli zaman formatı girin (HH:MM, HH:MM, HH:MM)</div>', unsafe_allow_html=True)
                trigger_time_invalid = True
            else:
                # Saat ve dakika kontrolü
                times = [t.strip() for t in trigger_time_times.split(',')]
                for time_str in times:
                    hour, minute = map(int, time_str.split(':'))
                    if hour < 0 or hour > 23 or minute < 0 or minute > 59:
                        form.markdown('<div style="color:red; font-size:12px;">Saat 0-23, dakika 0-59 arasında olmalıdır</div>', unsafe_allow_html=True)
                        trigger_time_invalid = True
                        break
        trigger_time = {
            "times": trigger_time_times
        }
        # user_id selectbox
        if user_options:
            user_display = form.selectbox("user_id (Users tablosundan)", list(user_options.keys()))
            user_id = user_options[user_display]
        else:
            user_id = form.text_input("user_id")
        # working_place tek kutu
        working_place = form.text_area("working_place", max_chars=255)
        default_instructions = form.text_area("default_instructions")
        data_instructions = form.text_area("data_instructions")
        file_path = form.text_area("file_path", max_chars=255)
        submitted = form.form_submit_button("Ekle")
        if submitted:
            if asistan_id_invalid or trigger_time_invalid:
                form.error(f"Asistan ID: {asistan_id_error_msg}" if asistan_id_invalid else "Lütfen geçerli zaman formatı girin.")
            else:
                try:
                    add_data = {
                        "asistan_id": asistan_id,
                        "title": title,
                        "explanation": explanation,
                        "parameters": parameters,
                        "user_id": user_id,
                        "working_place": working_place,
                        "default_instructions": default_instructions,
                        "data_instructions": data_instructions,
                        "file_path": file_path,
                        "trigger_time": trigger_time
                    }
                    resp = requests.post(f"{backend_url}/assistants", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state["assistant_form_key"] = st.session_state.get('assistant_form_key', 0) + 1
                        st.session_state['last_table'] = table_name
                        st.session_state["add_expander_open"] = True
                        st.session_state["delete_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                if 'e_mail' in error_msg.lower() or 'email' in error_msg.lower():
                                    form.error('Bu e-posta adresiyle zaten bir kullanıcı var.')
                                elif 'id' in error_msg.lower():
                                    form.error('Bu ID ile zaten bir kayıt mevcut.')
                                elif 'name' in error_msg.lower():
                                    form.error('Bu isimle bir kayıt zaten eklenmiş.')
                                else:
                                    form.error('Bu kayıt zaten mevcut.')
                            else:
                                form.error(error_msg)
                        except Exception:
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                except Exception as e:
                    form.error(f"Kayıt eklenemedi: {e}")
    elif table_name == "Auto_Prompt":
        # Assistants tablosundan asistan_id'leri çek
        try:
            assistants = requests.get(f"{backend_url}/assistants").json()
            assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        except Exception:
            assistant_options = {}
        form = st.form(key=f"auto_prompt_form_{st.session_state.get('auto_prompt_form_key', 0)}")
        question = form.text_area("question", max_chars=255)
        if len(question) > 100:
            form.markdown('<div style="color:red; font-size:12px;">En fazla 100 karakter girebilirsiniz.</div>', unsafe_allow_html=True)
        if assistant_options:
            assistant_display = form.selectbox("assistant_id (Assistants tablosundan)", list(assistant_options.keys()))
            assistant_id = assistant_options[assistant_display]
        else:
            assistant_id = form.text_input("assistant_id", max_chars=100)
        form.markdown("**trigger_time (JSON):**")
        trigger_time_times = form.text_input("times", max_chars=100, key="add_trigger_time_times", help="Örnek: 09:00, 14:00, 18:30")
        # Zaman formatı kontrolü
        trigger_time_invalid = False
        if trigger_time_times:
            import re
            # HH:MM formatında zaman kontrolü (virgülle ayrılmış)
            time_pattern = r'^(\d{1,2}:\d{2})(,\s*\d{1,2}:\d{2})*$'
            if not re.match(time_pattern, trigger_time_times):
                form.markdown('<div style="color:red; font-size:12px;">Lütfen geçerli zaman formatı girin (HH:MM, HH:MM, HH:MM)</div>', unsafe_allow_html=True)
                trigger_time_invalid = True
            else:
                # Saat ve dakika kontrolü
                times = [t.strip() for t in trigger_time_times.split(',')]
                for time_str in times:
                    hour, minute = map(int, time_str.split(':'))
                    if hour < 0 or hour > 23 or minute < 0 or minute > 59:
                        form.markdown('<div style="color:red; font-size:12px;">Saat 0-23, dakika 0-59 arasında olmalıdır</div>', unsafe_allow_html=True)
                        trigger_time_invalid = True
                        break
        trigger_time = {"times": trigger_time_times}
        python_code = form.text_area("python_code", height=200, help="Buraya Python kodunuzu yazabilirsiniz.")
        mcrisactive = form.selectbox("mcrisactive", ["Evet", "Hayır"]) == "Evet"
        receiver_emails = form.text_area("receiver_emails")
        email_warning = False
        if receiver_emails:
            emails = [e.strip() for e in receiver_emails.split(",")]
            for e in emails:
                if not is_valid_email(e):
                    form.markdown('<div style="color:red; font-size:12px;">Lütfen geçerli e-posta adres(ler)i girin. (Virgülle ayırabilirsiniz)</div>', unsafe_allow_html=True)
                    email_warning = True
                    break
        submitted = form.form_submit_button("Ekle")
        if submitted:
            if len(question) > 100 or email_warning or trigger_time_invalid:
                form.error("Lütfen alanları doğru ve limitlere uygun doldurun.")
            else:
                try:
                    add_data = {
                        "question": question,
                        "assistant_id": assistant_id,
                        "trigger_time": trigger_time,
                        "python_code": python_code,
                        "mcrisactive": mcrisactive,
                        "receiver_emails": receiver_emails
                    }
                    resp = requests.post(f"{backend_url}/auto_prompt", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state["auto_prompt_form_key"] = st.session_state.get('auto_prompt_form_key', 0) + 1
                        st.session_state['last_table'] = table_name
                        st.session_state["add_expander_open"] = True
                        st.session_state["delete_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                if 'e_mail' in error_msg.lower() or 'email' in error_msg.lower():
                                    form.error('Bu e-posta adresiyle zaten bir kullanıcı var.')
                                elif 'id' in error_msg.lower():
                                    form.error('Bu ID ile zaten bir kayıt mevcut.')
                                elif 'name' in error_msg.lower():
                                    form.error('Bu isimle bir kayıt zaten eklenmiş.')
                                else:
                                    form.error('Bu kayıt zaten mevcut.')
                            else:
                                form.error(error_msg)
                        except Exception:
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                except Exception as e:
                    form.error(str(e))
    elif table_name == "Data_Prepare_Modules":
        users = get_users()
        assistants = get_assistants()
        databases = get_database_info()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        database_options = {f"{d['database_id']} - {d['database_name']} ({d['database_ip']}:{d['database_port']})": d['database_id'] for d in databases} if databases else {}
        # Ekleme formu
        form = st.form(key=f"dpm_form_add_{st.session_state.get('dpm_form_key', 0)}")
        module_id = form.number_input("module_id", min_value=0, step=1, format="%d")
        # module_id 0 kontrolü (güncelleme)
        module_id_zero = module_id == 0
        if module_id_zero:
            form.markdown('<div style="color:red; font-size:12px;">Module ID 0 olamaz.</div>', unsafe_allow_html=True)
        query = form.text_area("query")
        import re
        query_invalid = False
        if query and not re.match(r"^[a-zA-Z0-9 .,;:!?'\"()\[\]{}\-_\/\\\n\r]*$", query):
            query_invalid = True
            form.markdown('<div style="color:red; font-size:12px;">Lütfen sadece metin ve temel noktalama işaretleri girin.</div>', unsafe_allow_html=True)
        user_id = form.selectbox("user_id (Users tablosundan)", list(user_options.keys())) if user_options else form.text_input("user_id")
        asistan_id = form.selectbox("asistan_id (Assistants tablosundan)", list(assistant_options.keys())) if assistant_options else form.text_input("asistan_id")
        database_id = form.selectbox("database_id (Database Info tablosundan)", list(database_options.keys())) if database_options else form.text_input("database_id")
        csv_database_id = form.text_input("csv_database_id")
        # CSV Database ID sadece rakam olmalı
        csv_database_id_invalid = csv_database_id and not csv_database_id.isdigit()
        if csv_database_id_invalid:
            form.markdown('<div style="color:red; font-size:12px;">Sadece sayı giriniz (ör: 1234)</div>', unsafe_allow_html=True)
        query_name = form.text_area("query_name", max_chars=255)
        working_platform = form.text_area("working_platform", max_chars=100)
        db_schema = form.text_area("db_schema")
        documents_id = form.text_input("documents_id")
        csv_db_schema = form.text_area("csv_db_schema")
        data_prep_code = form.text_area("data_prep_code", height=200, max_chars=1000, help="Buraya Python kodunuzu yazabilirsiniz.")
        submitted = form.form_submit_button("Ekle")
        if submitted:
            if module_id_zero:
                form.error("Module ID 0 olamaz. Lütfen 0'dan farklı bir ID girin.")
                st.stop()
            if csv_database_id_invalid:
                form.error("Sayı beklenen alanlara sadece rakam giriniz.")
                st.stop()
            else:
                try:
                    add_data = {
                        "module_id": module_id,
                        "query": query,
                        "user_id": user_options[user_id] if user_options else int(user_id) if user_id.isdigit() else None,
                        "asistan_id": assistant_options[asistan_id] if assistant_options else int(asistan_id) if asistan_id.isdigit() else None,
                        "database_id": database_options[database_id] if database_options else int(database_id) if database_id.isdigit() else None,
                        "csv_database_id": int(csv_database_id) if csv_database_id.isdigit() else None,
                        "query_name": query_name,
                        "working_platform": working_platform,
                        "db_schema": db_schema,
                        "documents_id": documents_id,
                        "csv_db_schema": csv_db_schema,
                        "data_prep_code": data_prep_code
                    }
                    resp = requests.post(f"{backend_url}/data_prepare_modules", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state["dpm_form_key"] = st.session_state.get('dpm_form_key', 0) + 1
                        st.session_state['last_table'] = table_name
                        st.session_state["add_expander_open"] = True
                        st.session_state["delete_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                form.error('Bu kayıt zaten mevcut.')
                            else:
                                form.error(error_msg)
                        except Exception:
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                except Exception as e:
                    form.error(str(e))
    elif table_name == "Documents":
        users = get_users()
        assistants = get_assistants()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        
        form = st.form(key=f"document_form_{st.session_state.get('document_form_key', 0)}")
        
        # user_id selectbox
        if user_options:
            user_display = form.selectbox("user_id (Users tablosundan)", list(user_options.keys()))
            user_id = user_options[user_display]
        else:
            user_id = form.text_input("user_id")
        
        # asistan_id selectbox
        if assistant_options:
            assistant_display = form.selectbox("asistan_id (Assistants tablosundan)", list(assistant_options.keys()))
            asistan_id = assistant_options[assistant_display]
        else:
            asistan_id = form.text_input("asistan_id")
        
        file_path = form.text_input("file_path", max_chars=255)
        file_type = form.text_input("file_type", max_chars=100)
        description = form.text_area("description")
        
        submitted = form.form_submit_button("Ekle")
        
        if submitted:
            if not file_path:
                form.error("file_path alanı zorunludur")
                st.stop()
            try:
                add_data = {
                    "user_id": user_options[user_display] if user_options else int(user_id) if user_id.isdigit() else None,
                    "asistan_id": assistant_options[assistant_display] if assistant_options else int(asistan_id) if asistan_id.isdigit() else None,
                    "file_path": file_path,
                    "file_type": file_type,
                    "description": description
                }
                
                resp = requests.post(f"{backend_url}/documents", json=add_data)
                if resp.status_code == 200:
                    st.session_state["success_message"] = "Kayıt eklendi!"
                    st.session_state["document_form_key"] = st.session_state.get('document_form_key', 0) + 1
                    st.session_state['last_table'] = table_name
                    st.session_state["add_expander_open"] = True
                    st.session_state["delete_expander_open"] = False
                    st.session_state["update_expander_open"] = False
                    st.rerun()
                else:
                    try:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                        elif isinstance(error_msg, str) and (
                            'already exists' in error_msg.lower() or
                            'duplicate' in error_msg.lower() or
                            'unique constraint' in error_msg.lower() or
                            'not unique' in error_msg.lower()
                        ):
                            form.error('Bu kayıt zaten mevcut.')
                        else:
                            form.error(error_msg)
                    except Exception:
                        form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
            except Exception as e:
                form.error(str(e))
    elif table_name == "Models":
        form = st.form(key=f"model_form_{st.session_state.get('model_form_key', 0)}")
        
        model_id = form.number_input("model_id", min_value=0, step=1, format="%d")
        name = form.text_input("name", max_chars=255)
        provider = form.text_input("provider", max_chars=255, help="Örnek: OpenAI, Anthropic, Custom")
        model_version = form.text_input("model_version", max_chars=100)
        is_active = form.selectbox("is_active", ["Evet", "Hayır"]) == "Evet"
        
        # default_parameters başlığı ve kutucuk
        form.markdown("**default_parameters (JSON):**")
        default_parameters = form.text_area("default_parameters", value="{}", key="add_default_parameters_json")
        valid_default_parameters, default_parameters_err = validate_json_input(default_parameters)
        if not valid_default_parameters:
            form.markdown('<div style="color:red; font-size:12px;">Hatalı JSON formatı. Lütfen geçerli bir JSON girin.<br>Örnek: {"temperature": 0.7, "max_tokens": 1000}</div>', unsafe_allow_html=True)
        
        submitted = form.form_submit_button("Ekle")
        
        if submitted:
            if model_id == 0:
                form.error("Model ID 0 olamaz.")
            elif not valid_default_parameters:
                form.error("Lütfen default_parameters alanına geçerli bir JSON girin.")
            else:
                try:
                    add_data = {
                        "model_id": model_id,
                        "name": name,
                        "provider": provider,
                        "model_version": model_version,
                        "is_active": is_active,
                        "default_parameters": json.loads(default_parameters) if default_parameters else {}
                    }
                    
                    resp = requests.post(f"{backend_url}/models", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state["model_form_key"] = st.session_state.get('model_form_key', 0) + 1
                        st.session_state['last_table'] = table_name
                        st.session_state["add_expander_open"] = True
                        st.session_state["delete_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                form.error('Bu kayıt zaten mevcut.')
                            else:
                                form.error(error_msg)
                        except Exception:
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                except Exception as e:
                    form.error(str(e))
    elif table_name == "Database_Info":
        users = get_users()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        form = st.form(key=f"dbinfo_form_{st.session_state.get('dbinfo_form_key', 0)}")
        database_ip = form.text_area("database_ip", max_chars=100)
        database_port = form.text_area("database_port", max_chars=100, key="add_database_port")
        port_invalid = database_port and not database_port.isdigit()
        port_style = "border: 2px solid red;" if port_invalid else ""
        form.markdown(f'<style>textarea[key="add_database_port"] {{{port_style}}}</style>', unsafe_allow_html=True)
        if port_invalid:
            form.markdown('<div style="color:red; font-size:12px;">Lütfen sadece rakam girin (örn: 1234)</div>', unsafe_allow_html=True)
        database_user = form.text_area("database_user", max_chars=100)
        database_password = form.text_area("database_password", max_chars=100)
        database_type = form.text_area("database_type", max_chars=50)
        database_name = form.text_area("database_name", max_chars=100)
        user_id = form.selectbox("user_id (Users tablosundan)", list(user_options.keys())) if user_options else form.text_input("user_id")
        submitted = form.form_submit_button("Ekle")
        if submitted:
            try:
                add_data = {
                    "database_ip": database_ip,
                    "database_port": database_port,
                    "database_user": database_user,
                    "database_password": database_password,
                    "database_type": database_type,
                    "database_name": database_name,
                    "user_id": user_options[user_id] if user_options else user_id
                }
                resp = requests.post(f"{backend_url}/database_info", json=add_data)
                if resp.status_code == 200:
                    st.session_state["success_message"] = "Kayıt eklendi!"
                    st.session_state["dbinfo_form_key"] = st.session_state.get('dbinfo_form_key', 0) + 1
                    st.session_state['last_table'] = table_name
                    mark_form_completed(table_name, "add")
                    if should_rerun(table_name, "add"):
                        st.rerun()
                else:
                    try:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                        elif isinstance(error_msg, str) and (
                            'already exists' in error_msg.lower() or
                            'duplicate' in error_msg.lower() or
                            'unique constraint' in error_msg.lower() or
                            'not unique' in error_msg.lower()
                        ):
                            form.error('Bu kayıt zaten mevcut.')
                        else:
                            form.error(error_msg)
                    except Exception:
                        form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
            except Exception as e:
                form.error(str(e))

    else:
        # Kullanıcı ekleme formunu sıfırlamak için form key'i kullanalım
        if 'user_add_form_key' not in st.session_state:
            st.session_state['user_add_form_key'] = 0
        add_data = {}
        for field in fields:
            fname = field["name"]
            ftype = field["type"]
            if fname in ["create_date", "change_date"]:
                continue  # Bu alanları atla
            if table_name == "Users" and fname == "role_id":
                roles = get_roles()
                role_names = [r['role_name'] for r in roles]
                add_data['role_name'] = st.selectbox("Rol", role_names, key=f"add_role_{st.session_state['user_add_form_key']}")
            elif fname == "user_id":
                add_data[fname] = st.number_input(fname, min_value=1, step=1, format="%d", key=f"add_{fname}_{st.session_state['user_add_form_key']}")
            elif ftype == "bool":
                add_data[fname] = st.selectbox(fname, ["Evet", "Hayır"], key=f"add_{fname}_{st.session_state['user_add_form_key']}") == "Evet"
            elif ftype == "json":
                add_data[fname] = st.text_area(fname + " (JSON)", value="{}", key=f"add_{fname}_{st.session_state['user_add_form_key']}")
            elif ftype == "number":
                if not (table_name == "Users" and fname == "role_id"):
                    add_data[fname] = st.number_input(fname, step=1, format="%d", key=f"add_{fname}_{st.session_state['user_add_form_key']}")
            else:
                max_chars = 100 if fname in ["name", "surname"] else None
                add_data[fname] = st.text_input(fname, max_chars=max_chars, key=f"add_{fname}_{st.session_state['user_add_form_key']}")
                if max_chars and add_data[fname] and len(add_data[fname]) > max_chars:
                    st.markdown(f'<div style="color:red; font-size:12px;">En fazla {max_chars} karakter girebilirsiniz.</div>', unsafe_allow_html=True)
                if fname == "e_mail" and add_data[fname] and not is_valid_email(add_data[fname]):
                    st.markdown('<div style="color:red; font-size:12px;">Lütfen geçerli bir e-posta adresi girin (ör: kisi@site.com)</div>', unsafe_allow_html=True)
        if st.button("Ekle", key=f"add_user_button_{st.session_state['user_add_form_key']}"):
            for field in fields:
                if field["name"] in ["create_date", "change_date"]:
                    continue
                if field["type"] == "json":
                    try:
                        add_data[field["name"]] = json.loads(add_data[field["name"]]) if add_data[field["name"]] else {}
                    except Exception:
                        add_data[field["name"]] = {}
            if table_name == "Users":
                selected_role_name = add_data.pop('role_name')
                roles = get_roles()
                add_data['role_id'] = next((r['role_id'] for r in roles if r['role_name'] == selected_role_name), None)
                email = add_data.get("e_mail", "")
                if not is_valid_email(email):
                    st.error("Lütfen geçerli bir e-posta adresi girin (ör: kisi@site.com)")
                elif not add_data.get("user_id") or add_data.get("user_id") == 0:
                    st.error("user_id alanı zorunludur ve 0 olamaz!")
                else:
                    try:
                        resp = requests.post(f"{backend_url}/{endpoint}", json=add_data)
                        if resp.status_code == 200:
                            st.session_state["success_message"] = "Kişi eklendi!"
                            st.session_state['user_add_form_key'] += 1
                            st.session_state['last_table'] = table_name
                            st.rerun()
                        else:
                            try:
                                error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                                if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                    st.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                                elif isinstance(error_msg, str) and (
                                    'already exists' in error_msg.lower() or
                                    'duplicate' in error_msg.lower() or
                                    'unique constraint' in error_msg.lower() or
                                    'not unique' in error_msg.lower()
                                ):
                                    if 'e_mail' in error_msg.lower() or 'email' in error_msg.lower():
                                        st.error('Bu e-posta adresiyle zaten bir kullanıcı var.')
                                    elif 'id' in error_msg.lower() or 'name' in error_msg.lower():
                                        st.error('Bu bilgilerle zaten bir kullanıcı mevcut. Lütfen farklı bilgilerle tekrar deneyin.')
                                    else:
                                        st.error('Bu kayıt zaten mevcut.')
                                else:
                                    st.error(error_msg)
                            except Exception:
                                st.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                    except Exception as e:
                        st.error(str(e))
            else:
                try:
                    resp = requests.post(f"{backend_url}/{endpoint}", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state['user_add_form_key'] += 1
                        st.session_state['last_table'] = table_name
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                st.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                st.error('Bu kayıt zaten mevcut.')
                            else:
                                st.error(error_msg)
                        except Exception:
                            st.error(resp.text)
                except Exception as e:
                    st.error(str(e))

# Sil
if "delete_expander_open" not in st.session_state:
    st.session_state["delete_expander_open"] = False
with st.expander("Kayıt Sil", expanded=st.session_state.get("delete_expander_open", False)):
    # Tüm tablolar için silme alanı ve butonu görünür olsun
    if table_name == "Assistants":
        assistants = get_assistants()
        if assistants:
            assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants}
            selected = st.selectbox("Silinecek Asistan", list(assistant_options.keys()), key="delete_assistant_select")
            delete_id = assistant_options[selected]
        else:
            st.success("Silinecek asistan yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_assistants"):
            if delete_id:
                try:
                    # Silinecek kaydı bul ve sakla
                    deleted_row = next((a for a in assistants if a['asistan_id'] == delete_id), None)
                    resp = requests.delete(f"{backend_url}/assistants/{delete_id}")
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt silindi!"
                        if deleted_row:
                            st.session_state["last_deleted"] = {"table_name": "Assistants", "data": deleted_row}
                        st.session_state["delete_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        error_text = resp.text
                        if (
                            'foreign key constraint' in error_text.lower() or
                            'is still referenced' in error_text.lower()
                        ):
                            st.error('Bu asistanı silmeden önce, bu asistana bağlı auto prompt ve veri hazırlama modüllerini silmelisiniz.')
                        else:
                            st.error("Kayıt silinemedi: " + error_text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Auto_Prompt":
        try:
            response = requests.get(f"{backend_url}/auto_prompt")
            response.raise_for_status()
            auto_prompts = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            auto_prompts = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            auto_prompts = []
        if auto_prompts:
            auto_prompt_options = {f"{ap['prompt_id']} - {ap['question']}": ap['prompt_id'] for ap in auto_prompts}
            selected = st.selectbox("Silinecek Auto Prompt", list(auto_prompt_options.keys()), key="delete_auto_prompt_select")
            delete_id = auto_prompt_options[selected]
        else:
            st.success("Silinecek auto prompt yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_auto_prompt"):
            if delete_id:
                try:
                    deleted_row = next((ap for ap in auto_prompts if ap['prompt_id'] == delete_id), None)
                    resp = requests.delete(f"{backend_url}/auto_prompt/{delete_id}")
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt silindi!"
                        if deleted_row:
                            st.session_state["last_deleted"] = {"table_name": "Auto_Prompt", "data": deleted_row}
                        st.session_state["delete_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        error_text = resp.text
                        if (
                            'foreign key constraint' in error_text.lower() or
                            'is still referenced' in error_text.lower()
                        ):
                            st.error('Bu auto promptu silmeden önce, bu prompta bağlı asistanı silmelisiniz.')
                        else:
                            st.error("Kayıt silinemedi: " + error_text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Documents":
        try:
            response = requests.get(f"{backend_url}/documents")
            response.raise_for_status()
            documents = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            documents = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            documents = []
        if documents:
            document_options = {f"{d['document_id']} - {d['file_path']}": d['document_id'] for d in documents}
            selected = st.selectbox("Silinecek Doküman", list(document_options.keys()), key="delete_document_select")
            delete_id = document_options[selected]
        else:
            st.success("Silinecek doküman yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_documents"):
            if delete_id:
                try:
                    deleted_row = next((d for d in documents if d['document_id'] == delete_id), None)
                    resp = requests.delete(f"{backend_url}/documents/{delete_id}")
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt silindi!"
                        if deleted_row:
                            st.session_state["last_deleted"] = {"table_name": "Documents", "data": deleted_row}
                        st.session_state["delete_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        error_text = resp.text
                        if (
                            'foreign key constraint' in error_text.lower() or
                            'is still referenced' in error_text.lower()
                        ):
                            st.error('Bu dokümanı silmeden önce, bu dokümana bağlı tüm asistanları ve kullanıcıları silmelisiniz.')
                        else:
                            st.error("Kayıt silinemedi: " + error_text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Models":
        try:
            response = requests.get(f"{backend_url}/models")
            response.raise_for_status()
            models = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            models = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            models = []
        if models:
            model_options = {f"{m['model_id']} - {m['name']} ({m['provider']})": m['model_id'] for m in models}
            selected = st.selectbox("Silinecek Model", list(model_options.keys()), key="delete_model_select")
            delete_id = model_options[selected]
        else:
            st.success("Silinecek model yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_models"):
            if delete_id:
                try:
                    deleted_row = next((m for m in models if m['model_id'] == delete_id), None)
                    resp = requests.delete(f"{backend_url}/models/{delete_id}")
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt silindi!"
                        if deleted_row:
                            st.session_state["last_deleted"] = {"table_name": "Models", "data": deleted_row}
                        st.session_state["delete_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        error_text = resp.text
                        if (
                            'foreign key constraint' in error_text.lower() or
                            'is still referenced' in error_text.lower()
                        ):
                            st.error('Bu modeli silmeden önce, bu modele bağlı tüm asistanları ve kullanıcıları silmelisiniz.')
                        else:
                            st.error("Kayıt silinemedi: " + error_text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Data_Prepare_Modules":
        try:
            response = requests.get(f"{backend_url}/data_prepare_modules")
            response.raise_for_status()
            dpm_modules = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            dpm_modules = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            dpm_modules = []
        if dpm_modules:
            dpm_options = {f"{dpm['module_id']}": dpm['module_id'] for dpm in dpm_modules}
            selected = st.selectbox("Silinecek Data Prepare Module", list(dpm_options.keys()), key="delete_dpm_select")
            delete_id = dpm_options[selected]
        else:
            st.success("Silinecek data prepare module yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_dpm"):
            if delete_id:
                try:
                    deleted_row = next((dpm for dpm in dpm_modules if dpm['module_id'] == delete_id), None)
                    resp = requests.delete(f"{backend_url}/data_prepare_modules/{delete_id}")
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt silindi!"
                        if deleted_row:
                            st.session_state["last_deleted"] = {"table_name": "Data_Prepare_Modules", "data": deleted_row}
                        st.session_state["delete_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        error_text = resp.text
                        if (
                            'foreign key constraint' in error_text.lower() or
                            'is still referenced' in error_text.lower()
                        ):
                            st.error('Bu modülü silmeden önce, bu modüle bağlı tüm asistanları ve kullanıcıları silmelisiniz.')
                        else:
                            st.error("Kayıt silinemedi: " + error_text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Database_Info":
        try:
            response = requests.get(f"{backend_url}/database_info")
            response.raise_for_status()
            dbinfo_entries = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            dbinfo_entries = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            dbinfo_entries = []
        if dbinfo_entries:
            dbinfo_options = {f"{db['database_id']} - {db['database_name']}": db['database_id'] for db in dbinfo_entries}
            selected = st.selectbox("Silinecek Database Info", list(dbinfo_options.keys()), key="delete_dbinfo_select")
            delete_id = dbinfo_options[selected]
        else:
            st.success("Silinecek database info yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_dbinfo"):
            if delete_id:
                try:
                    deleted_row = next((db for db in dbinfo_entries if db['database_id'] == delete_id), None)
                    resp = requests.delete(f"{backend_url}/database_info/{delete_id}")
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt silindi!"
                        if deleted_row:
                            st.session_state["last_deleted"] = {"table_name": "Database_Info", "data": deleted_row}
                        st.session_state["delete_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        error_text = resp.text
                        if (
                            'foreign key constraint' in error_text.lower() or
                            'is still referenced' in error_text.lower()
                        ):
                            st.error('Bu veritabanı bilgisini silmeden önce, bu kayda bağlı kullanıcıyı silmelisiniz.')
                        else:
                            st.error("Kayıt silinemedi: " + error_text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Users":
        users = get_users()
        if users:
            for user in users:
                user['role_name'] = next((r['role_name'] for r in roles if r['role_id'] == user['role_id']), "")
            user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']}) [{u['role_name']}]": u['user_id'] for u in users}
            selected = st.selectbox("Silinecek Kişi", list(user_options.keys()), key="delete_user_select")
            delete_id = user_options[selected]
        else:
            st.success("Silinecek kullanıcı yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_users"):
            if delete_id:
                try:
                    deleted_row = next((u for u in users if u['user_id'] == delete_id), None)
                    resp = requests.delete(f"{backend_url}/users/{delete_id}")
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt silindi!"
                        if deleted_row:
                            st.session_state["last_deleted"] = {"table_name": "Users", "data": deleted_row}
                        st.session_state["delete_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        # Hata mesajını kullanıcı dostu göster
                        error_text = resp.text
                        if (
                            'foreign key constraint' in error_text.lower() or
                            'is still referenced' in error_text.lower()
                        ):
                            st.error('Bu kullanıcıyı silmeden önce, bu kullanıcıya bağlı tüm asistanları, veritabanı bilgilerini, otomatik promptları ve veri hazırlama modüllerini silmelisiniz.')
                        else:
                            st.error("Kayıt silinemedi: " + error_text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Roles":
        roles = get_roles()
        if roles:
            role_names = [r['role_name'] for r in roles]
            selected_role_name = st.selectbox("Silinecek Rol (role_name)", role_names, key="delete_role_name_select")
            # Aynı role_name'e sahip tüm kayıtları bul
            same_name_roles = [r for r in roles if r['role_name'] == selected_role_name]
            if len(same_name_roles) > 1:
                st.warning("Birden fazla aynı isimli rol var, lütfen ID seçin.")
            # ID seçimi/girişi zorunlu
            selected_role_id = st.selectbox("Silinecek ID (role_id)", [r['role_id'] for r in same_name_roles], key="delete_role_id_select") if len(same_name_roles) > 1 else same_name_roles[0]['role_id']
            delete_id = selected_role_id if isinstance(selected_role_id, int) else None
        else:
            st.success("Silinecek rol yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_roles"):
            if not delete_id:
                st.error("Lütfen silinecek ID girin.")
            else:
                try:
                    deleted_row = next((r for r in roles if r['role_id'] == delete_id), None)
                    resp = requests.delete(f"{backend_url}/roles/{delete_id}")
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt silindi!"
                        if deleted_row:
                            st.session_state["last_deleted"] = {"table_name": "Roles", "data": deleted_row}
                        st.session_state["delete_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["update_expander_open"] = False
                        st.rerun()
                    else:
                        # Hata mesajını kullanıcı dostu göster
                        error_text = resp.text
                        if (
                            'foreign key constraint' in error_text.lower() or
                            'is still referenced' in error_text.lower()
                        ):
                            st.error('Bu rolü silmeden önce, bu role bağlı tüm kullanıcıları silmelisiniz.')
                        else:
                            st.error("Kayıt silinemedi: " + error_text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")

# Güncelle
if "update_expander_open" not in st.session_state:
    st.session_state["update_expander_open"] = False
with st.expander("Kayıt Güncelle", expanded=st.session_state.get("update_expander_open", False)):
    # Tüm tablolar için güncelleme alanı ve butonu görünür olsun
    if table_name == "Assistants":
        assistants = get_assistants()
        users = get_users()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        if assistants:
            assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants}
            selected = st.selectbox("Güncellenecek Asistan", list(assistant_options.keys()), key="update_assistant_select")
            update_id = assistant_options[selected]
            assistant_row = next((a for a in assistants if a['asistan_id'] == update_id), None)
        else:
            st.success("Güncellenecek asistan yok.")
            update_id = None
            assistant_row = None
        update_data = {}
        if assistant_row:
            # asistan_id alanı güncelleme formunda gösterilmesin
            update_data['title'] = st.text_area("title", value=assistant_row.get('title', ''), key="update_title")
            update_data['explanation'] = st.text_area("explanation", value=assistant_row.get('explanation', ''), key="update_explanation")
            parameters_val = pretty_json(assistant_row.get('parameters'))
            # parameters (JSON) alanı
            st.markdown("**parameters (JSON):**")
            parameters_input = st.text_area("", value=parameters_val, key="update_parameters_json")
            valid_params, params_err = validate_json_input(parameters_input)
            if not valid_params:
                st.markdown('<div style="color:red; font-size:12px;">Hatalı JSON formatı. Lütfen geçerli bir JSON girin.<br>Örnek: {"embedding_model": "gpt-3", "llm_model": "gpt-3.5-turbo", "temperature": 0.7}</div>', unsafe_allow_html=True)
            # trigger_time (JSON) alanı
            st.markdown("**trigger_time (JSON):**")
            trigger_time_input = st.text_area("", value=pretty_json(assistant_row.get('trigger_time')), key="update_trigger_time_json")
            valid_trigg, trigg_err = validate_json_input(trigger_time_input)
            if not valid_trigg:
                st.markdown('<div style="color:red; font-size:12px;">Hatalı JSON formatı. Lütfen geçerli bir JSON girin.<br>Örnek: {"times": "09:00, 14:00"}</div>', unsafe_allow_html=True)
            if user_options:
                user_display = st.selectbox("user_id (Users tablosundan)", list(user_options.keys()), index=list(user_options.values()).index(assistant_row.get('user_id', None)) if assistant_row.get('user_id', None) in user_options.values() else 0, key="update_assistant_user_id")
                update_data['user_id'] = user_options[user_display]
            else:
                update_data['user_id'] = st.text_input("user_id", value=str(assistant_row.get('user_id', '')), key="update_assistant_user_id_text")
            update_data['working_place'] = st.text_area("working_place", value=assistant_row.get('working_place', ''), key="update_working_place")
            update_data['default_instructions'] = st.text_area("default_instructions", value=assistant_row.get('default_instructions', ''), key="update_default_instructions")
            update_data['data_instructions'] = st.text_area("data_instructions", value=assistant_row.get('data_instructions', ''), key="update_data_instructions")
            update_data['file_path'] = st.text_area("file_path", value=assistant_row.get('file_path', ''), key="update_file_path")
        if st.button("Güncelle", key="update_button_assistants"):
            if assistant_row and (not valid_params or not valid_trigg):
                st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
            elif assistant_row:
                update_data['parameters'] = json.loads(parameters_input)
                update_data['trigger_time'] = json.loads(trigger_time_input)
                try:
                    resp = requests.put(f"{backend_url}/assistants/{update_id}", json=update_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["show_table"] = True
                        st.session_state["update_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["delete_expander_open"] = False
                        st.rerun()
                    else:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                        if error_msg and not (isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype'))):
                            st.error(error_msg)
                except Exception as e:
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
        else:
            pass

    elif table_name == "Users":
        users = get_users()
        roles = get_roles()
        if users:
            # Kullanıcıların rol adını bul
            user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']}) [{next((r['role_name'] for r in roles if r['role_id'] == u['role_id']), '')}]": u['user_id'] for u in users}
            selected = st.selectbox("Güncellenecek Kişi", list(user_options.keys()), key="update_user_select")
            update_id = user_options[selected]
            user_row = next((u for u in users if u['user_id'] == update_id), None)
        else:
            st.success("Güncellenecek kullanıcı yok.")
            update_id = None
            user_row = None
        update_data = {}
        if user_row:
            # Güncelleme formunda sadece rol adı gösterilsin, id gösterilmesin
            roles = get_roles()
            role_names = [r['role_name'] for r in roles]
            current_role_name = next((r['role_name'] for r in roles if r['role_id'] == user_row['role_id']), '')
            update_data['role_name'] = st.selectbox("Rol", role_names, index=role_names.index(current_role_name) if current_role_name in role_names else 0, key="update_role_name")
            update_data['name'] = st.text_input("name", value=user_row.get('name', ''), max_chars=100, key="update_name")
            update_data['surname'] = st.text_input("surname", value=user_row.get('surname', ''), max_chars=100, key="update_surname")
            update_data['password'] = st.text_input("password", value=user_row.get('password', ''), key="update_password")
            update_data['e_mail'] = st.text_input("e_mail", value=user_row.get('e_mail', ''), key="update_e_mail")
            if update_data['e_mail'] and not is_valid_email(update_data['e_mail']):
                st.markdown('<div style="color:red; font-size:12px;">Lütfen geçerli bir e-posta adresi girin (ör: kisi@site.com)</div>', unsafe_allow_html=True)
            update_data['institution_working'] = st.text_input("institution_working", value=user_row.get('institution_working', ''), key="update_institution_working")
        if st.button("Güncelle", key="update_button_users"):
            email = update_data.get("e_mail", "")
            if not is_valid_email(email):
                st.error("Lütfen geçerli bir e-posta adresi girin (ör: kisi@site.com)")
            else:
                try:
                    selected_role_name = update_data.pop('role_name')
                    roles = get_roles()
                    update_data['role_id'] = next((r['role_id'] for r in roles if r['role_name'] == selected_role_name), user_row['role_id'])
                    resp = requests.put(f"{backend_url}/users/{update_id}", json=update_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["show_table"] = True
                        st.session_state["update_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["delete_expander_open"] = False
                        st.rerun()
                    else:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                        if error_msg and not (isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype'))):
                            st.error(error_msg)
                except Exception as e:
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
        else:
            pass

    elif table_name == "Roles":
        roles = get_roles()
        if roles:
            role_options = {f"{r['role_id']} - {r['role_name']}": r['role_id'] for r in roles}
            selected = st.selectbox("Güncellenecek ID (role_id)", list(role_options.keys()), key="update_role_select")
            update_id = role_options[selected]
            role_row = next((r for r in roles if r['role_id'] == update_id), None)
            if "roles_update_error" in st.session_state:
                st.session_state.pop("roles_update_error")
        else:
            update_id = None
            role_row = None
        update_data = {}
        if role_row:
            # Yeni: Rol adı güncelleme kutucuğu
            update_data['role_name'] = st.text_input("role_name", value=role_row['role_name'], key="update_role_name_input")
            update_data['role_id'] = update_id
            st.markdown("**permissions (JSON):**")
            permissions_val = pretty_json(role_row.get('permissions'))
            permissions_input = st.text_area("", value=permissions_val, key="update_permissions_json")
            valid_permissions, permissions_err = validate_json_input(permissions_input)
            if not valid_permissions:
                st.markdown('<div style="color:red; font-size:12px;">Hatalı JSON formatı. Lütfen geçerli bir JSON girin.<br>Örnek: {"permissions": "all"}</div>', unsafe_allow_html=True)
            try:
                update_data['permissions'] = json.loads(permissions_input) if permissions_input else {}
            except Exception:
                update_data['permissions'] = {}
            update_data['admin_or_not'] = st.selectbox("admin_or_not", ["Evet", "Hayır"], index=0 if role_row.get('admin_or_not', False) else 1, key="update_admin_or_not") == "Evet"
            if st.button("Güncelle", key="update_button_roles"):
                missing_fields = check_required_fields(table_options["Roles"]["fields"], update_data)
                if missing_fields:
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                elif not valid_permissions:
                    st.error("Kayıt güncellenemedi. Hatalı JSON formatı.")
                else:
                    try:
                        resp = requests.put(f"{backend_url}/{endpoint}/{update_id}", json=update_data)
                        if resp.status_code == 200:
                            st.session_state["success_message"] = "Kayıt güncellendi!"
                            st.session_state["show_table"] = True
                            st.session_state.pop("roles_update_error", None)
                            st.rerun()
                        else:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if error_msg and not (isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype'))):
                                st.error(error_msg)
                            else:
                                st.error("Kayıt güncellenemedi.")
                    except Exception as e:
                        st.error(f"Kayıt güncellenemedi. Hata: {e}")
        else:
            pass

    elif table_name == "Auto_Prompt":
        try:
            response = requests.get(f"{backend_url}/auto_prompt")
            response.raise_for_status()
            auto_prompts = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            auto_prompts = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            auto_prompts = []
        # Assistants tablosundan asistan_id'leri çek
        try:
            assistants = requests.get(f"{backend_url}/assistants").json()
            assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        except Exception:
            assistant_options = {}
        if auto_prompts:
            auto_prompt_options = {f"{ap['prompt_id']} - {ap['question']}": ap['prompt_id'] for ap in auto_prompts}
            selected = st.selectbox("Güncellenecek Auto Prompt", list(auto_prompt_options.keys()), key="update_auto_prompt_select")
            update_id = auto_prompt_options[selected]
            auto_prompt_row = next((ap for ap in auto_prompts if ap['prompt_id'] == update_id), None)
        else:
            st.success("Güncellenecek auto prompt yok.")
            update_id = None
            auto_prompt_row = None
        update_data = {}
        if auto_prompt_row:
            update_data['question'] = st.text_area("question", value=auto_prompt_row.get('question', ''), key="update_ap_question")
            # assistant_id selectbox
            if assistant_options:
                # Varsayılanı mevcut assistant_id'ye ayarla
                current_assistant_id = str(auto_prompt_row.get('assistant_id', ''))
                assistant_display_list = list(assistant_options.keys())
                default_index = 0
                for i, k in enumerate(assistant_display_list):
                    if str(assistant_options[k]) == current_assistant_id:
                        default_index = i
                        break
                assistant_display = st.selectbox("assistant_id (Assistants tablosundan)", assistant_display_list, index=default_index, key="update_ap_assistant_id")
                update_data['assistant_id'] = assistant_options[assistant_display]
            else:
                update_data['assistant_id'] = st.text_input("assistant_id", value=str(auto_prompt_row.get('assistant_id', '')), key="update_ap_assistant_id_text")
            trigger_time_val = pretty_json(auto_prompt_row.get('trigger_time'))
            st.markdown("**trigger_time (JSON):**")
            trigger_time_input = st.text_area("", value=trigger_time_val, key="update_ap_trigger_time_json")
            valid_trigg, trigg_err = validate_json_input(trigger_time_input)
            if not valid_trigg:
                st.markdown(f'<div style="color:red; font-size:12px;">Hatalı JSON: {trigg_err}</div>', unsafe_allow_html=True)
            update_data['python_code'] = st.text_area("python_code", value=auto_prompt_row.get('python_code', ''), key="update_ap_python_code")
            update_data['mcrisactive'] = st.selectbox("mcrisactive", ["Evet", "Hayır"], index=0 if auto_prompt_row.get('mcrisactive', False) else 1, key="update_ap_mcrisactive") == "Evet"
            update_data['receiver_emails'] = st.text_area("receiver_emails", value=auto_prompt_row.get('receiver_emails', ''), key="update_ap_receiver_emails")
            email_warning = False
            email_error_msg = ""
            if update_data['receiver_emails']:
                emails = [e.strip() for e in update_data['receiver_emails'].split(",") if e.strip()]
                for e in emails:
                    if not is_valid_email(e):
                        email_error_msg = '<div style="color:red; font-size:12px;">Lütfen geçerli e-posta adres(ler)i girin. (Virgülle ayırabilirsiniz)</div>'
                        email_warning = True
                        break
            if email_error_msg:
                st.markdown(email_error_msg, unsafe_allow_html=True)
        if st.button("Güncelle", key="update_button_auto_prompt"):
            if auto_prompt_row and (not valid_trigg or email_warning):
                st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan ve e-posta adreslerinin geçerli olduğundan emin olun.")
            elif auto_prompt_row:
                update_data['trigger_time'] = json.loads(trigger_time_input)
                try:
                    resp = requests.put(f"{backend_url}/auto_prompt/{update_id}", json=update_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["show_table"] = True
                        st.session_state["update_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["delete_expander_open"] = False
                        st.rerun()
                    else:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                        if error_msg and not (isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype'))):
                            st.error(error_msg)
                except Exception as e:
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
        else:
            pass

    elif table_name == "Data_Prepare_Modules":
        try:
            response = requests.get(f"{backend_url}/data_prepare_modules")
            response.raise_for_status()
            dpm_modules = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            dpm_modules = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            dpm_modules = []
        users = get_users()
        assistants = get_assistants()
        databases = get_database_info()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        database_options = {f"{d['database_id']} - {d['database_name']} ({d['database_ip']}:{d['database_port']})": d['database_id'] for d in databases} if databases else {}
        # Güncelleme formu
        form = st.form(key=f"dpm_form_update_{st.session_state.get('dpm_form_key', 0)}")
        module_id = form.number_input("module_id", min_value=0, step=1, format="%d")
        # module_id 0 kontrolü (güncelleme)
        module_id_zero = module_id == 0
        if module_id_zero:
            form.markdown('<div style="color:red; font-size:12px;">Module ID 0 olamaz.</div>', unsafe_allow_html=True)
        query = form.text_area("query")
        import re
        query_invalid = False
        if query and not re.match(r"^[a-zA-Z0-9 .,;:!?'\"()\[\]{}\-_\/\\\n\r]*$", query):
            query_invalid = True
            form.markdown('<div style="color:red; font-size:12px;">Lütfen sadece metin ve temel noktalama işaretleri girin.</div>', unsafe_allow_html=True)
        user_id = form.selectbox("user_id (Users tablosundan)", list(user_options.keys())) if user_options else form.text_input("user_id")
        asistan_id = form.selectbox("asistan_id (Assistants tablosundan)", list(assistant_options.keys())) if assistant_options else form.text_input("asistan_id")
        database_id = form.selectbox("database_id (Database Info tablosundan)", list(database_options.keys())) if database_options else form.text_input("database_id")
        csv_database_id = form.text_input("csv_database_id")
        # CSV Database ID sadece rakam olmalı (güncelleme)
        csv_database_id_invalid = csv_database_id and not csv_database_id.isdigit()
        if csv_database_id_invalid:
            form.markdown('<div style="color:red; font-size:12px;">Sadece sayı giriniz (ör: 1234)</div>', unsafe_allow_html=True)
        query_name = form.text_area("query_name", max_chars=255)
        working_platform = form.text_area("working_platform", max_chars=100)
        db_schema = form.text_area("db_schema")
        documents_id = form.text_input("documents_id")
        documents_id_invalid = documents_id and not documents_id.isdigit()
        if documents_id_invalid:
            form.markdown('<div style="color:red; font-size:12px;">Lütfen sadece sayı giriniz (ör: 1234)</div>', unsafe_allow_html=True)
        csv_db_schema = form.text_area("csv_db_schema")
        data_prep_code = form.text_area("data_prep_code", height=200, max_chars=1000, help="Buraya Python kodunuzu yazabilirsiniz.")
        submitted = form.form_submit_button("Güncelle")
        if submitted:
            if module_id_zero:
                form.error("Module ID 0 olamaz. Lütfen 0'dan farklı bir ID girin.")
                st.stop()
            if csv_database_id_invalid or documents_id_invalid:
                form.error("Sayı beklenen alanlara sadece rakam giriniz. (Örneğin: documents_id alanına harf girilemez)")
                st.stop()
            else:
                try:
                    add_data = {
                        "module_id": module_id,
                        "query": query,
                        "user_id": user_options[user_id] if user_options else int(user_id) if user_id.isdigit() else None,
                        "asistan_id": assistant_options[asistan_id] if assistant_options else int(asistan_id) if asistan_id.isdigit() else None,
                        "database_id": database_options[database_id] if database_options else int(database_id) if database_id.isdigit() else None,
                        "csv_database_id": int(csv_database_id) if csv_database_id.isdigit() else None,
                        "query_name": query_name,
                        "working_platform": working_platform,
                        "db_schema": db_schema,
                        "documents_id": int(documents_id) if documents_id.isdigit() else None,
                        "csv_db_schema": csv_db_schema,
                        "data_prep_code": data_prep_code
                    }
                    resp = requests.post(f"{backend_url}/data_prepare_modules", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["dpm_form_key"] = st.session_state.get('dpm_form_key', 0) + 1
                        st.session_state['last_table'] = table_name
                        st.session_state["update_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["delete_expander_open"] = False
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                form.error('Bu kayıt zaten mevcut.')
                            else:
                                form.error(error_msg)
                        except Exception:
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                except Exception as e:
                    form.error(str(e))

    elif table_name == "Database_Info":
        try:
            response = requests.get(f"{backend_url}/database_info")
            response.raise_for_status()
            dbinfo_entries = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            dbinfo_entries = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            dbinfo_entries = []
        users = get_users()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        if dbinfo_entries:
            dbinfo_options = {f"{dbinfo['database_id']} - {dbinfo['database_name']}": dbinfo['database_id'] for dbinfo in dbinfo_entries}
            selected = st.selectbox("Güncellenecek Database Info", list(dbinfo_options.keys()), key="update_dbinfo_select_5")
            update_id = dbinfo_options[selected]
            dbinfo_row = next((d for d in dbinfo_entries if d['database_id'] == update_id), None)
        else:
            st.success("Güncellenecek database info yok.")
            update_id = None
            dbinfo_row = None
        update_data = {}
        if dbinfo_row:
            update_data['database_ip'] = st.text_area("database_ip", value=dbinfo_row.get('database_ip', ''), max_chars=100, key="update_database_ip_5")
            update_data['database_port'] = st.text_area("database_port", value=dbinfo_row.get('database_port', ''), max_chars=100, key="update_database_port_5")
            port_invalid = update_data['database_port'] and not str(update_data['database_port']).isdigit()
            port_style = "border: 2px solid red;" if port_invalid else ""
            st.markdown(f'<style>textarea[key="update_database_port_5"] {{{port_style}}}</style>', unsafe_allow_html=True)
            if port_invalid:
                st.markdown('<div style="color:red; font-size:12px;">Lütfen sadece rakam girin (örn: 1234)</div>', unsafe_allow_html=True)
            update_data['database_user'] = st.text_area("database_user", value=dbinfo_row.get('database_user', ''), max_chars=100, key="update_database_user_5")
            update_data['database_password'] = st.text_area("database_password", value=dbinfo_row.get('database_password', ''), max_chars=100, key="update_database_password")
            update_data['database_type'] = st.text_area("database_type", value=dbinfo_row.get('database_type', ''), max_chars=50, key="update_database_type")
            update_data['database_name'] = st.text_area("database_name", value=dbinfo_row.get('database_name', ''), max_chars=100, key="update_database_name")
            if user_options:
                user_display = st.selectbox("user_id (Users tablosundan)", list(user_options.keys()), index=list(user_options.values()).index(dbinfo_row.get('user_id', None)) if dbinfo_row.get('user_id', None) in user_options.values() else 0, key="update_dbinfo_user_id")
                update_data['user_id'] = user_options[user_display]
            else:
                update_data['user_id'] = st.text_input("user_id", value=str(dbinfo_row.get('user_id', '')), key="update_dbinfo_user_id_text")
        if st.button("Güncelle", key="update_button_dbinfo"):
            if dbinfo_row:
                try:
                    resp = requests.put(f"{backend_url}/{endpoint}/{update_id}", json=update_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["show_table"] = True
                        st.rerun()
                    else:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                        if error_msg and not (isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype'))):
                            st.error(error_msg)
                except Exception as e:
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
        else:
            pass

    elif table_name == "Database_Info":
        try:
            response = requests.get(f"{backend_url}/database_info")
            response.raise_for_status()
            dbinfo_entries = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            dbinfo_entries = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            dbinfo_entries = []
        users = get_users()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        if dbinfo_entries:
            dbinfo_options = {f"{dbinfo['database_id']} - {dbinfo['database_name']}": dbinfo['database_id'] for dbinfo in dbinfo_entries}
            selected = st.selectbox("Güncellenecek Database Info", list(dbinfo_options.keys()), key="update_dbinfo_select_6")
            update_id = dbinfo_options[selected]
            dbinfo_row = next((d for d in dbinfo_entries if d['database_id'] == update_id), None)
        else:
            st.success("Güncellenecek database info yok.")
            update_id = None
            dbinfo_row = None
        update_data = {}
        if dbinfo_row:
            update_data['database_ip'] = st.text_area("database_ip", value=dbinfo_row.get('database_ip', ''), max_chars=100, key="update_database_ip_6")
            update_data['database_port'] = st.text_area("database_port", value=dbinfo_row.get('database_port', ''), max_chars=100, key="update_database_port_6")
            port_invalid = update_data['database_port'] and not str(update_data['database_port']).isdigit()
            port_style = "border: 2px solid red;" if port_invalid else ""
            st.markdown(f'<style>textarea[key="update_database_port_6"] {{{port_style}}}</style>', unsafe_allow_html=True)
            if port_invalid:
                st.markdown('<div style="color:red; font-size:12px;">Lütfen sadece rakam girin (örn: 1234)</div>', unsafe_allow_html=True)
            update_data['database_user'] = st.text_area("database_user", value=dbinfo_row.get('database_user', ''), max_chars=100, key="update_database_user_6")
            update_data['database_password'] = st.text_area("database_password", value=dbinfo_row.get('database_password', ''), max_chars=100, key="update_database_password")
            update_data['database_type'] = st.text_area("database_type", value=dbinfo_row.get('database_type', ''), max_chars=50, key="update_database_type")
            update_data['database_name'] = st.text_area("database_name", value=dbinfo_row.get('database_name', ''), max_chars=100, key="update_database_name")
            if user_options:
                user_display = st.selectbox("user_id (Users tablosundan)", list(user_options.keys()), index=list(user_options.values()).index(dbinfo_row.get('user_id', None)) if dbinfo_row.get('user_id', None) in user_options.values() else 0, key="update_dbinfo_user_id")
                update_data['user_id'] = user_options[user_display]
            else:
                update_data['user_id'] = st.text_input("user_id", value=str(dbinfo_row.get('user_id', '')), key="update_dbinfo_user_id_text")
        if st.button("Güncelle", key="update_button_dbinfo"):
            if dbinfo_row:
                try:
                    resp = requests.put(f"{backend_url}/{endpoint}/{update_id}", json=update_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["show_table"] = True
                        st.rerun()
                    else:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                        if error_msg and not (isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype'))):
                            st.error(error_msg)
                except Exception as e:
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
        else:
            pass

    elif table_name == "Data_Prepare_Modules":
        try:
            response = requests.get(f"{backend_url}/data_prepare_modules")
            response.raise_for_status()
            dpm_modules = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            dpm_modules = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            dpm_modules = []
        users = get_users()
        assistants = get_assistants()
        databases = get_database_info()
        user_options = {f"{u['user_id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['user_id'] for u in users} if users else {}
        assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        database_options = {f"{d['database_id']} - {d['database_name']} ({d['database_ip']}:{d['database_port']})": d['database_id'] for d in databases} if databases else {}
        # Güncelleme formu
        form = st.form(key=f"dpm_form_update_{st.session_state.get('dpm_form_key', 0)}")
        module_id = form.number_input("module_id", min_value=0, step=1, format="%d")
        # module_id 0 kontrolü (güncelleme)
        module_id_zero = module_id == 0
        if module_id_zero:
            form.markdown('<div style="color:red; font-size:12px;">Module ID 0 olamaz.</div>', unsafe_allow_html=True)
        query = form.text_area("query")
        import re
        query_invalid = False
        if query and not re.match(r"^[a-zA-Z0-9 .,;:!?'\"()\[\]{}\-_\/\\\n\r]*$", query):
            query_invalid = True
            form.markdown('<div style="color:red; font-size:12px;">Lütfen sadece metin ve temel noktalama işaretleri girin.</div>', unsafe_allow_html=True)
        user_id = form.selectbox("user_id (Users tablosundan)", list(user_options.keys())) if user_options else form.text_input("user_id")
        asistan_id = form.selectbox("asistan_id (Assistants tablosundan)", list(assistant_options.keys())) if assistant_options else form.text_input("asistan_id")
        database_id = form.selectbox("database_id (Database Info tablosundan)", list(database_options.keys())) if database_options else form.text_input("database_id")
        csv_database_id = form.text_input("csv_database_id")
        # CSV Database ID sadece rakam olmalı (güncelleme)
        csv_database_id_invalid = csv_database_id and not csv_database_id.isdigit()
        if csv_database_id_invalid:
            form.markdown('<div style="color:red; font-size:12px;">Sadece sayı giriniz (ör: 1234)</div>', unsafe_allow_html=True)
        query_name = form.text_area("query_name", max_chars=255)
        working_platform = form.text_area("working_platform", max_chars=100)
        db_schema = form.text_area("db_schema")
        documents_id = form.text_input("documents_id")
        documents_id_invalid = documents_id and not documents_id.isdigit()
        if documents_id_invalid:
            form.markdown('<div style="color:red; font-size:12px;">Lütfen sadece sayı giriniz (ör: 1234)</div>', unsafe_allow_html=True)
        csv_db_schema = form.text_area("csv_db_schema")
        data_prep_code = form.text_area("data_prep_code", height=200, max_chars=1000, help="Buraya Python kodunuzu yazabilirsiniz.")
        submitted = form.form_submit_button("Güncelle")
        if submitted:
            if module_id_zero:
                form.error("Module ID 0 olamaz. Lütfen 0'dan farklı bir ID girin.")
                st.stop()
            if csv_database_id_invalid or documents_id_invalid:
                form.error("Sayı beklenen alanlara sadece rakam giriniz. (Örneğin: documents_id alanına harf girilemez)")
                st.stop()
            else:
                try:
                    add_data = {
                        "module_id": module_id,
                        "query": query,
                        "user_id": user_options[user_id] if user_options else int(user_id) if user_id.isdigit() else None,
                        "asistan_id": assistant_options[asistan_id] if assistant_options else int(asistan_id) if asistan_id.isdigit() else None,
                        "database_id": database_options[database_id] if database_options else int(database_id) if database_id.isdigit() else None,
                        "csv_database_id": int(csv_database_id) if csv_database_id.isdigit() else None,
                        "query_name": query_name,
                        "working_platform": working_platform,
                        "db_schema": db_schema,
                        "documents_id": int(documents_id) if documents_id.isdigit() else None,
                        "csv_db_schema": csv_db_schema,
                        "data_prep_code": data_prep_code
                    }
                    resp = requests.post(f"{backend_url}/data_prepare_modules", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["dpm_form_key"] = st.session_state.get('dpm_form_key', 0) + 1
                        st.session_state['last_table'] = table_name
                        st.session_state["update_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["delete_expander_open"] = False
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                form.error('Bu kayıt zaten mevcut.')
                            else:
                                form.error(error_msg)
                        except Exception:
                            form.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                except Exception as e:
                    form.error(str(e))

    elif table_name == "Documents":
        try:
            response = requests.get(f"{backend_url}/documents")
            response.raise_for_status()
            documents = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            documents = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            documents = []
        
        try:
            users = requests.get(f"{backend_url}/users").json()
            user_options = {f"{u['user_id']} - {u['name']} {u['surname']}": u['user_id'] for u in users} if users else {}
        except Exception:
            user_options = {}
        
        try:
            assistants = requests.get(f"{backend_url}/assistants").json()
            assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        except Exception:
            assistant_options = {}
        
        if documents:
            document_options = {f"{d['document_id']} - {d['file_path']}": d['document_id'] for d in documents}
            selected = st.selectbox("Güncellenecek Doküman", list(document_options.keys()), key="update_document_select")
            update_id = document_options[selected]
            document_row = next((d for d in documents if d['document_id'] == update_id), None)
        else:
            st.success("Güncellenecek doküman yok.")
            update_id = None
            document_row = None
        
        update_data = {}
        if document_row:
            # user_id selectbox
            if user_options:
                user_display_list = list(user_options.keys())
                user_default_index = 0
                if document_row.get('user_id', None) in user_options.values():
                    user_default_index = list(user_options.values()).index(document_row.get('user_id', None))
                user_display = st.selectbox("user_id (Users tablosundan)", user_display_list, index=user_default_index, key="update_document_user_id")
                update_data['user_id'] = user_options[user_display]
            else:
                update_data['user_id'] = st.text_input("user_id", value=str(document_row.get('user_id', '')), key="update_document_user_id_text")
            
            # asistan_id selectbox
            if assistant_options:
                assistant_display_list = list(assistant_options.keys())
                assistant_default_index = 0
                if document_row.get('asistan_id', None) in assistant_options.values():
                    assistant_default_index = list(assistant_options.values()).index(document_row.get('asistan_id', None))
                assistant_display = st.selectbox("asistan_id (Assistants tablosundan)", assistant_display_list, index=assistant_default_index, key="update_document_asistan_id")
                update_data['asistan_id'] = assistant_options[assistant_display]
            else:
                update_data['asistan_id'] = st.text_input("asistan_id (opsiyonel)", value=str(document_row.get('asistan_id', '')), key="update_document_asistan_id_text")
            
            update_data['file_path'] = st.text_input("file_path", value=document_row.get('file_path', ''), max_chars=500, help="Dosya yolu (zorunlu)")
            update_data['file_type'] = st.text_input("file_type", value=document_row.get('file_type', ''), max_chars=50, help="Dosya türü (örn: pdf, docx, txt)")
            update_data['description'] = st.text_area("description", value=document_row.get('description', ''), max_chars=1000, help="Doküman açıklaması")
        
        if st.button("Güncelle", key="update_button_documents"):
            if document_row and not update_data['file_path']:
                st.error("file_path alanı zorunludur.")
            elif document_row:
                try:
                    resp = requests.put(f"{backend_url}/documents/{update_id}", json=update_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["show_table"] = True
                        st.session_state["update_expander_open"] = True
                        st.session_state["add_expander_open"] = False
                        st.session_state["delete_expander_open"] = False
                        st.rerun()
                    else:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                        if error_msg and not (isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype'))):
                            st.error(error_msg)
                except Exception as e:
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
        else:
            pass

    elif table_name == "Models":
        try:
            response = requests.get(f"{backend_url}/models")
            response.raise_for_status()
            models = response.json()
        except requests.exceptions.JSONDecodeError:
            st.error("Backend'den geçersiz veri geldi (JSONDecodeError).")
            models = []
        except Exception as e:
            st.error(f"Veri alınırken hata oluştu: {e}")
            models = []
        
        if models:
            model_options = {f"{m['model_id']} - {m['name']} ({m['provider']})": m['model_id'] for m in models}
            selected = st.selectbox("Güncellenecek Model", list(model_options.keys()), key="update_model_select")
            update_id = model_options[selected]
            model_row = next((m for m in models if m['model_id'] == update_id), None)
        else:
            st.success("Güncellenecek model yok.")
            update_id = None
            model_row = None
        
        update_data = {}
        if model_row:
            update_data['name'] = st.text_input("name", value=model_row.get('name', ''), max_chars=255, key="update_model_name")
            update_data['provider'] = st.text_input("provider", value=model_row.get('provider', ''), max_chars=255, key="update_model_provider")
            update_data['model_version'] = st.text_input("model_version", value=model_row.get('model_version', ''), max_chars=100, key="update_model_version")
            update_data['is_active'] = st.selectbox("is_active", ["Evet", "Hayır"], index=0 if model_row.get('is_active', True) else 1, key="update_model_is_active") == "Evet"
            
            # default_parameters için mevcut değeri göster
            current_params = model_row.get('default_parameters', {})
            if isinstance(current_params, str):
                try:
                    current_params = json.loads(current_params)
                except:
                    current_params = {}
            current_params_str = json.dumps(current_params, ensure_ascii=False, indent=2) if current_params else "{}"
            
            st.markdown("**default_parameters (JSON):**")
            update_data['default_parameters'] = st.text_area("default_parameters", value=current_params_str, key="update_model_default_parameters")
        
        if st.button("Güncelle", key="update_button_model"):
            if model_row:
                try:
                    # JSON validasyonu
                    try:
                        json.loads(update_data['default_parameters'])
                    except:
                        st.error("default_parameters alanı geçerli bir JSON formatında olmalıdır.")
                        st.stop()
                    
                    resp = requests.put(f"{backend_url}/models/{update_id}", json=update_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt güncellendi!"
                        st.session_state["show_table"] = True
                        st.rerun()
                    else:
                        error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                        st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                        if error_msg and not (isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype'))):
                            st.error(error_msg)
                except Exception as e:
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
        else:
            pass

    else:
        # Kullanıcı ekleme formunu sıfırlamak için form key'i kullanalım
        if 'user_add_form_key' not in st.session_state:
            st.session_state['user_add_form_key'] = 0
        add_data = {}
        for field in fields:
            fname = field["name"]
            ftype = field["type"]
            if fname in ["create_date", "change_date"]:
                continue  # Bu alanları atla
            if table_name == "Users" and fname == "role_id":
                roles = get_roles()
                role_names = [r['role_name'] for r in roles]
                add_data['role_name'] = st.selectbox("Rol", role_names, key=f"add_role_{st.session_state['user_add_form_key']}")
            elif fname == "user_id":
                add_data[fname] = st.number_input(fname, min_value=1, step=1, format="%d", key=f"add_{fname}_{st.session_state['user_add_form_key']}")
            elif ftype == "bool":
                add_data[fname] = st.selectbox(fname, ["Evet", "Hayır"], key=f"add_{fname}_{st.session_state['user_add_form_key']}") == "Evet"
            elif ftype == "json":
                add_data[fname] = st.text_area(fname + " (JSON)", value="{}", key=f"add_{fname}_{st.session_state['user_add_form_key']}")
            elif ftype == "number":
                if not (table_name == "Users" and fname == "role_id"):
                    add_data[fname] = st.number_input(fname, step=1, format="%d", key=f"add_{fname}_{st.session_state['user_add_form_key']}")
            else:
                max_chars = 100 if fname in ["name", "surname"] else None
                add_data[fname] = st.text_input(fname, max_chars=max_chars, key=f"add_{fname}_{st.session_state['user_add_form_key']}")
                if max_chars and add_data[fname] and len(add_data[fname]) > max_chars:
                    st.markdown(f'<div style="color:red; font-size:12px;">En fazla {max_chars} karakter girebilirsiniz.</div>', unsafe_allow_html=True)
                if fname == "e_mail" and add_data[fname] and not is_valid_email(add_data[fname]):
                    st.markdown('<div style="color:red; font-size:12px;">Lütfen geçerli bir e-posta adresi girin (ör: kisi@site.com)</div>', unsafe_allow_html=True)
        if st.button("Ekle", key=f"add_user_button_{st.session_state['user_add_form_key']}"):
            for field in fields:
                if field["name"] in ["create_date", "change_date"]:
                    continue
                if field["type"] == "json":
                    try:
                        add_data[field["name"]] = json.loads(add_data[field["name"]]) if add_data[field["name"]] else {}
                    except Exception:
                        add_data[field["name"]] = {}
            if table_name == "Users":
                selected_role_name = add_data.pop('role_name')
                roles = get_roles()
                add_data['role_id'] = next((r['role_id'] for r in roles if r['role_name'] == selected_role_name), None)
                email = add_data.get("e_mail", "")
                if not is_valid_email(email):
                    st.error("Lütfen geçerli bir e-posta adresi girin (ör: kisi@site.com)")
                elif not add_data.get("user_id") or add_data.get("user_id") == 0:
                    st.error("user_id alanı zorunludur ve 0 olamaz!")
                else:
                    try:
                        resp = requests.post(f"{backend_url}/{endpoint}", json=add_data)
                        if resp.status_code == 200:
                            st.session_state["success_message"] = "Kişi eklendi!"
                            st.session_state['user_add_form_key'] += 1
                            st.session_state['last_table'] = table_name
                            st.rerun()
                        else:
                            try:
                                error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                                if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                    st.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                                elif isinstance(error_msg, str) and (
                                    'already exists' in error_msg.lower() or
                                    'duplicate' in error_msg.lower() or
                                    'unique constraint' in error_msg.lower() or
                                    'not unique' in error_msg.lower()
                                ):
                                    if 'e_mail' in error_msg.lower() or 'email' in error_msg.lower():
                                        st.error('Bu e-posta adresiyle zaten bir kullanıcı var.')
                                    elif 'id' in error_msg.lower() or 'name' in error_msg.lower():
                                        st.error('Bu bilgilerle zaten bir kullanıcı mevcut. Lütfen farklı bilgilerle tekrar deneyin.')
                                    else:
                                        st.error('Bu kayıt zaten mevcut.')
                                else:
                                    st.error(error_msg)
                            except Exception:
                                st.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                    except Exception as e:
                        st.error(str(e))
            else:
                try:
                    resp = requests.post(f"{backend_url}/{endpoint}", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state['user_add_form_key'] += 1
                        st.session_state['last_table'] = table_name
                        st.rerun()
                    else:
                        try:
                            error_msg = resp.json().get('error') if resp.headers.get('Content-Type','').startswith('application/json') else resp.text
                            if isinstance(error_msg, str) and (error_msg.strip().lower().startswith('<html') or error_msg.strip().lower().startswith('<!doctype')):
                                st.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                            elif isinstance(error_msg, str) and (
                                'already exists' in error_msg.lower() or
                                'duplicate' in error_msg.lower() or
                                'unique constraint' in error_msg.lower() or
                                'not unique' in error_msg.lower()
                            ):
                                st.error('Bu kayıt zaten mevcut.')
                            else:
                                st.error(error_msg)
                        except Exception:
                            st.error(resp.text)
                except Exception as e:
                    st.error(str(e))

# Auto Prompt'taki python_code alanı için Courier fontu
st.markdown(
    """
    <style>
    textarea[data-testid="stTextArea-input"] {
        font-family: Courier, monospace !important;
        font-size: 16px !important;
    }
    </style>
    """,
    unsafe_allow_html=True
) 