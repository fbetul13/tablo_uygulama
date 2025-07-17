import streamlit as st
import requests
import pandas as pd
import json
import re

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
            {"name": "role_id", "type": "number"},
            {"name": "name", "type": "text"},
            {"name": "surname", "type": "text"},
            {"name": "password", "type": "text"},
            {"name": "e_mail", "type": "text"},
            {"name": "institution_working", "type": "text"}
        ]
    },
    "Database Info": {
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
    "Data Prepare Modules": {
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
    "Auto Prompt": {
        "endpoint": "auto_prompt",
        "fields": [
            {"name": "question", "type": "text"},
            {"name": "assistant_title", "type": "text"},
            {"name": "trigger_time", "type": "json"},
            {"name": "python_code", "type": "text"},
            {"name": "mcrisactive", "type": "bool"},
            {"name": "receiver_emails", "type": "text"}
        ]
    }
}

st.title("Tablo Yönetim Paneli")
table_name = st.sidebar.selectbox("Tablo Seçin", list(table_options.keys()))
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
                show_cols = ['id', 'role_name', 'name', 'surname', 'e_mail', 'institution_working']
                show_cols = [c for c in show_cols if c in df.columns]
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
                show_cols = [c for c in show_cols if c in df.columns]
                st.dataframe(df[show_cols])
            elif table_name == "Auto Prompt":
                df = pd.DataFrame(data)
                show_cols = ['prompt_id', 'question', 'assistant_title', 'trigger_time', 'python_code', 'mcrisactive', 'receiver_emails']
                show_cols = [c for c in show_cols if c in df.columns]
                st.dataframe(df[show_cols])
            elif table_name == "Data Prepare Modules":
                df = pd.DataFrame(data)
                show_cols = ['module_id', 'query', 'user_id', 'asistan_id', 'database_id', 'csv_database_id', 'query_name', 'working_platform', 'db_schema', 'documents_id', 'csv_db_schema', 'data_prep_code']
                show_cols = [c for c in show_cols if c in df.columns]
                st.dataframe(df[show_cols])
            elif table_name == "Roles":
                df = pd.DataFrame(data)
                show_cols = ['role_id', 'role_name', 'permissions', 'admin_or_not']
                show_cols = [c for c in show_cols if c in df.columns]
                st.dataframe(df[show_cols])
            elif table_name == "Database Info":
                df = pd.DataFrame(data)
                show_cols = ['database_id', 'database_ip', 'database_port', 'database_user', 'database_password', 'database_type', 'database_name', 'user_id']
                show_cols = [c for c in show_cols if c in df.columns]
                st.dataframe(df[show_cols])
            else:
                df = pd.DataFrame(data)
                st.dataframe(df)
        else:
            st.info("Tabloda veri yok.")
    except Exception as e:
        st.error(f"Veri alınamadı: {e}")

# Ekle
with st.expander("Yeni Kayıt Ekle"):
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
            else:
                try:
                    add_data["permissions"] = json.loads(permissions) if permissions else {}
                    resp = requests.post(f"{backend_url}/roles", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state["role_form_key"] += 1  # Formu sıfırla
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
    elif table_name == "Assistants":
        users = get_users()
        user_options = {f"{u['id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['id'] for u in users} if users else {}
        form = st.form(key=f"assistant_form_{st.session_state.get('assistant_form_key', 0)}")
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
            trigger_time_times = form.text_input("times", max_chars=100, key="add_trigger_time_times")
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
            try:
                add_data = {
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
    elif table_name == "Auto Prompt":
        # Assistants tablosundan başlıkları çek
        try:
            assistants = requests.get(f"{backend_url}/assistants").json()
            assistant_titles = [a['title'] for a in assistants] if assistants else []
        except Exception:
            assistant_titles = []
        form = st.form(key=f"auto_prompt_form_{st.session_state.get('auto_prompt_form_key', 0)}")
        question = form.text_area("question", max_chars=255)
        if len(question) > 100:
            form.markdown('<div style="color:red; font-size:12px;">En fazla 100 karakter girebilirsiniz.</div>', unsafe_allow_html=True)
        if assistant_titles:
            assistant_title = form.selectbox("assistant_title (Assistants tablosundan)", assistant_titles)
        else:
            assistant_title = form.text_area("assistant_title", max_chars=100)
            if len(assistant_title) > 100:
                form.markdown('<div style="color:red; font-size:12px;">En fazla 100 karakter girebilirsiniz.</div>', unsafe_allow_html=True)
        form.markdown("**trigger_time:**")
        trigger_time_times = form.text_input("times", max_chars=100, key="add_trigger_time_times")
        # trigger_time sadece 'times' içeren bir JSON olarak gönderilecek
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
            if len(question) > 100 or (not assistant_title or len(assistant_title) > 100) or email_warning:
                form.error("Lütfen alanları doğru ve limitlere uygun doldurun.")
            else:
                try:
                    add_data = {
                        "question": question,
                        "assistant_title": assistant_title,
                        "trigger_time": trigger_time,
                        "python_code": python_code,
                        "mcrisactive": mcrisactive,
                        "receiver_emails": receiver_emails
                    }
                    resp = requests.post(f"{backend_url}/auto_prompt", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
                        st.session_state["auto_prompt_form_key"] = st.session_state.get('auto_prompt_form_key', 0) + 1
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
    elif table_name == "Data Prepare Modules":
        users = get_users()
        assistants = get_assistants()
        databases = get_database_info()
        user_options = {f"{u['id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['id'] for u in users} if users else {}
        assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        database_options = {f"{d['database_id']} - {d['database_name']} ({d['database_ip']}:{d['database_port']})": d['database_id'] for d in databases} if databases else {}
        form = st.form(key=f"dpm_form_{st.session_state.get('dpm_form_key', 0)}")
        module_id = form.number_input("module_id", min_value=0, step=1, format="%d")
        query = form.text_area("query")
        user_id = form.selectbox("user_id (Users tablosundan)", list(user_options.keys())) if user_options else form.text_input("user_id")
        asistan_id = form.selectbox("asistan_id (Assistants tablosundan)", list(assistant_options.keys())) if assistant_options else form.text_input("asistan_id")
        database_id = form.selectbox("database_id (Database Info tablosundan)", list(database_options.keys())) if database_options else form.text_input("database_id")
        csv_database_id = form.text_input("csv_database_id")
        query_name = form.text_area("query_name", max_chars=255)
        working_platform = form.text_area("working_platform", max_chars=100)
        db_schema = form.text_area("db_schema")
        documents_id = form.text_area("documents_id")
        csv_db_schema = form.text_area("csv_db_schema")
        data_prep_code = form.text_area("data_prep_code", height=200, max_chars=1000, help="Buraya Python kodunuzu yazabilirsiniz.")
        # Karakter sayacı kaldırıldı
        submitted = form.form_submit_button("Ekle")
        if submitted:
            if (working_platform and len(working_platform) > 100) or (query_name and len(query_name) > 100):
                form.error("Lütfen alanları doğru ve limitlere uygun doldurun.")
            else:
                try:
                    add_data = {
                        "module_id": module_id,
                        "query": query,
                        "user_id": user_options[user_id] if user_options else user_id,
                        "asistan_id": assistant_options[asistan_id] if assistant_options else asistan_id,
                        "database_id": database_options[database_id] if database_options else database_id,
                        "csv_database_id": csv_database_id,
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
    elif table_name == "Database Info":
        users = get_users()
        user_options = {f"{u['id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['id'] for u in users} if users else {}
        form = st.form(key=f"dbinfo_form_{st.session_state.get('dbinfo_form_key', 0)}")
        database_ip = form.text_area("database_ip", max_chars=100)
        database_port = form.text_area("database_port")
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
        add_data = {}
        for field in fields:
            fname = field["name"]
            ftype = field["type"]
            if fname in ["create_date", "change_date"]:
                continue  # Bu alanları atla
            if table_name == "Users" and fname == "role_id":
                add_data['role_name'] = st.selectbox("Rol", role_names)
            elif ftype == "bool":
                add_data[fname] = st.selectbox(fname, ["Evet", "Hayır"]) == "Evet"
            elif ftype == "json":
                add_data[fname] = st.text_area(fname + " (JSON)", value="{}")
            elif ftype == "number":
                if not (table_name == "Users" and fname == "role_id"):
                    add_data[fname] = st.number_input(fname, step=1, format="%d")
            else:
                max_chars = 100 if fname in ["name", "surname"] else None
                add_data[fname] = st.text_input(fname, max_chars=max_chars)
                if max_chars and add_data[fname] and len(add_data[fname]) > max_chars:
                    st.markdown(f'<div style="color:red; font-size:12px;">En fazla {max_chars} karakter girebilirsiniz.</div>', unsafe_allow_html=True)
                if fname == "e_mail" and add_data[fname] and not is_valid_email(add_data[fname]):
                    st.markdown('<div style="color:red; font-size:12px;">Lütfen geçerli bir e-posta adresi girin (ör: kisi@site.com)</div>', unsafe_allow_html=True)
        if st.button("Ekle"):
            for field in fields:
                if field["name"] in ["create_date", "change_date"]:
                    continue
                if field["type"] == "json":
                    try:
                        add_data[field["name"]] = json.loads(add_data[field["name"]]) if add_data[field["name"]] else {}
                    except Exception:
                        add_data[field["name"]] = {}
            if table_name == "Users":
                add_data['role_id'] = role_name_to_id.get(add_data.pop('role_name'), None)
                email = add_data.get("e_mail", "")
                if not is_valid_email(email):
                    st.error("Lütfen geçerli bir e-posta adresi girin (ör: kisi@site.com)")
                else:
                    try:
                        resp = requests.post(f"{backend_url}/{endpoint}", json=add_data)
                        if resp.status_code == 200:
                            st.session_state["success_message"] = "Kişi eklendi!"
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
                                st.error('Geçersiz giriş, lütfen alanları kontrol edin.')
                    except Exception as e:
                        st.error(str(e))
            else:
                try:
                    resp = requests.post(f"{backend_url}/{endpoint}", json=add_data)
                    if resp.status_code == 200:
                        st.session_state["success_message"] = "Kayıt eklendi!"
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
with st.expander("Kayıt Sil"):
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
                    resp = requests.delete(f"{backend_url}/assistants/{delete_id}")
                    if resp.status_code == 200:
                        st.success("Kayıt silindi!")
                        st.rerun()
                    else:
                        st.error("Kayıt silinemedi: " + resp.text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Auto Prompt":
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
                    resp = requests.delete(f"{backend_url}/auto_prompt/{delete_id}")
                    if resp.status_code == 200:
                        st.success("Kayıt silindi!")
                        st.rerun()
                    else:
                        st.error("Kayıt silinemedi: " + resp.text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Data Prepare Modules":
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
                    resp = requests.delete(f"{backend_url}/data_prepare_modules/{delete_id}")
                    if resp.status_code == 200:
                        st.success("Kayıt silindi!")
                        st.rerun()
                    else:
                        st.error("Kayıt silinemedi: " + resp.text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Database Info":
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
            dbinfo_options = {f"{dbinfo['database_id']} - {dbinfo['database_name']}": dbinfo['database_id'] for dbinfo in dbinfo_entries}
            selected = st.selectbox("Silinecek Database Info", list(dbinfo_options.keys()), key="delete_dbinfo_select")
            delete_id = dbinfo_options[selected]
        else:
            st.success("Silinecek database info yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_dbinfo"):
            if delete_id:
                try:
                    resp = requests.delete(f"{backend_url}/database_info/{delete_id}")
                    if resp.status_code == 200:
                        st.success("Kayıt silindi!")
                        st.rerun()
                    else:
                        st.error("Kayıt silinemedi: " + resp.text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Users":
        users = get_users()
        if users:
            for user in users:
                user['role_name'] = next((r['role_name'] for r in roles if r['role_id'] == user['role_id']), "")
            user_options = {f"{u['id']} - {u['name']} {u['surname']} ({u['e_mail']}) [{u['role_name']}]": u['id'] for u in users}
            selected = st.selectbox("Silinecek Kişi", list(user_options.keys()), key="delete_user_select")
            delete_id = user_options[selected]
        else:
            st.success("Silinecek kullanıcı yok.")
            delete_id = None
        if st.button("Sil", key="delete_button_users"):
            if delete_id:
                try:
                    resp = requests.delete(f"{backend_url}/users/{delete_id}")
                    if resp.status_code == 200:
                        st.success("Kişi silindi!")
                        st.rerun()
                    else:
                        st.error("Kayıt silinemedi: " + resp.text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")
    elif table_name == "Roles":
        roles = get_roles()
        if roles:
            role_names = [r['role_name'] for r in roles]
            selected_role_name = st.selectbox("Silinecek Rol (role_name)", role_names, key="delete_role_name_select")
            selected_role_by_name = next((r for r in roles if r['role_name'] == selected_role_name), None)
        else:
            st.success("Silinecek rol yok.")
            selected_role_by_name = None
        manual_delete_id = st.text_input("Silinecek ID (veya anahtar)", key="delete_role_id_manual")
        if manual_delete_id:
            try:
                delete_id = int(manual_delete_id)
            except Exception:
                st.warning("Geçerli bir ID girin.")
                delete_id = None
        elif selected_role_by_name:
            delete_id = selected_role_by_name['role_id']
        else:
            delete_id = None
        if st.button("Sil", key="delete_button_roles"):
            if delete_id:
                try:
                    resp = requests.delete(f"{backend_url}/roles/{delete_id}")
                    if resp.status_code == 200:
                        st.markdown('<span style="color:green; font-size:16px;">Kayıt silindi.</span>', unsafe_allow_html=True)
                        st.rerun()
                    else:
                        st.error("Kayıt silinemedi: " + resp.text)
                except Exception as e:
                    st.error(f"Kayıt silinemedi: {e}")
            else:
                st.error("Lütfen silinecek ID girin.")

# Güncelle
with st.expander("Kayıt Güncelle"):
    # Tüm tablolar için güncelleme alanı ve butonu görünür olsun
    if table_name == "Assistants":
        assistants = get_assistants()
        users = get_users()
        user_options = {f"{u['id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['id'] for u in users} if users else {}
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
        if users:
            for user in users:
                user['role_name'] = next((r['role_name'] for r in roles if r['role_id'] == user['role_id']), "")
            user_options = {f"{u['id']} - {u['name']} {u['surname']} ({u['e_mail']}) [{u['role_name']}]": u['id'] for u in users}
            selected = st.selectbox("Güncellenecek Kişi", list(user_options.keys()), key="update_user_select")
            update_id = user_options[selected]
            user_row = next((u for u in users if u['id'] == update_id), None)
        else:
            st.success("Güncellenecek kullanıcı yok.")
            update_id = None
            user_row = None
        update_data = {}
        if user_row:
            update_data['role_name'] = st.selectbox("Rol", role_names, index=role_names.index(user_row.get('role_name', role_names[0])) if user_row.get('role_name', None) in role_names else 0, key="update_role_name")
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
                    st.error("Kayıt güncellenemedi. Lütfen geçerli bir e-posta adresi girin.")
                else:
                    update_data['role_id'] = role_name_to_id.get(update_data.pop('role_name'), None)
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
                        st.error(f"Kayıt güncellenemedi. Hata: {e}")
        else:
            pass

    elif table_name == "Roles":
        roles = get_roles()
        if roles:
            role_options = {f"{r['role_id']} - {r['role_name']}": r['role_id'] for r in roles}
            selected = st.selectbox("Güncellenecek Rol", list(role_options.keys()), key="update_role_select")
            update_id = role_options[selected]
            role_row = next((r for r in roles if r['role_id'] == update_id), None)
            # role_name güncelleme için ayrı selectbox (benzersiz key)
            role_names = [r['role_name'] for r in roles]
            update_role_name = st.selectbox("Güncellenecek Rol (role_name)", role_names, key="update_role_name_select")
            # ID seçildiğinde hata mesajını temizle
            if "roles_update_error" in st.session_state:
                st.session_state.pop("roles_update_error")
        else:
            update_id = None
            role_row = None
        update_data = {}
        if role_row:
            update_data['role_name'] = update_role_name
            # role_id'yi de ekle
            update_data['role_id'] = update_id
            # permissions (JSON) alanı
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
            # permissions alanını güvenli şekilde dict olarak ata
            # Teşhis için ekrana yazdırılan satırları kaldırdım
            if st.button("Güncelle", key="update_button_roles"):
                missing_fields = check_required_fields(table_options["Roles"]["fields"], update_data)
                # Zorunlu alan kontrolü fonksiyonunu kullan
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

    elif table_name == "Auto Prompt":
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
            update_data['assistant_title'] = st.text_area("assistant_title", value=auto_prompt_row.get('assistant_title', ''), key="update_ap_assistant_title")
            trigger_time_val = pretty_json(auto_prompt_row.get('trigger_time'))
            st.markdown("**trigger_time (JSON):**")
            trigger_time_input = st.text_area("", value=trigger_time_val, key="update_ap_trigger_time_json")
            valid_trigg, trigg_err = validate_json_input(trigger_time_input)
            if not valid_trigg:
                st.markdown(f'<div style="color:red; font-size:12px;">Hatalı JSON: {trigg_err}</div>', unsafe_allow_html=True)
            update_data['python_code'] = st.text_area("python_code", value=auto_prompt_row.get('python_code', ''), key="update_ap_python_code")
            update_data['mcrisactive'] = st.selectbox("mcrisactive", ["Evet", "Hayır"], index=0 if auto_prompt_row.get('mcrisactive', False) else 1, key="update_ap_mcrisactive") == "Evet"
            update_data['receiver_emails'] = st.text_area("receiver_emails", value=auto_prompt_row.get('receiver_emails', ''), key="update_ap_receiver_emails")
            # Email format kontrolü ve uyarı
            email_warning = False
            if update_data['receiver_emails']:
                emails = [e.strip() for e in update_data['receiver_emails'].split(",") if e.strip()]
                for e in emails:
                    if not is_valid_email(e):
                        st.markdown('<div style="color:red; font-size:12px;">Lütfen geçerli e-posta adres(ler)i girin. (Virgülle ayırabilirsiniz)</div>', unsafe_allow_html=True)
                        email_warning = True
                        break
        if st.button("Güncelle", key="update_button_auto_prompt"):
            if auto_prompt_row and not valid_trigg:
                st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
            elif auto_prompt_row and email_warning:
                st.error("Kayıt güncellenemedi. Lütfen geçerli e-posta adres(ler)i girin.")
            elif auto_prompt_row:
                update_data['trigger_time'] = json.loads(trigger_time_input)
                try:
                    resp = requests.put(f"{backend_url}/auto_prompt/{update_id}", json=update_data)
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

    elif table_name == "Data Prepare Modules":
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
        user_options = {f"{u['id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['id'] for u in users} if users else {}
        assistant_options = {f"{a['asistan_id']} - {a['title']}": a['asistan_id'] for a in assistants} if assistants else {}
        database_options = {f"{d['database_id']} - {d['database_name']} ({d['database_ip']}:{d['database_port']})": d['database_id'] for d in databases} if databases else {}
        if dpm_modules:
            dpm_options = {f"{dpm['module_id']}": dpm['module_id'] for dpm in dpm_modules}
            selected = st.selectbox("Güncellenecek Data Prepare Module", list(dpm_options.keys()), key="update_dpm_select")
            update_id = dpm_options[selected]
            dpm_row = next((d for d in dpm_modules if d['module_id'] == update_id), None)
        else:
            st.success("Güncellenecek data prepare module yok.")
            update_id = None
            dpm_row = None
        update_data = {}
        if dpm_row:
            update_data['query'] = st.text_area("query", value=dpm_row.get('query', ''), key="update_query")
            if user_options:
                user_display = st.selectbox("user_id (Users tablosundan)", list(user_options.keys()), index=list(user_options.values()).index(dpm_row.get('user_id', None)) if dpm_row.get('user_id', None) in user_options.values() else 0, key="update_dpm_user_id")
                update_data['user_id'] = user_options[user_display]
            else:
                update_data['user_id'] = st.text_input("user_id", value=str(dpm_row.get('user_id', '')), key="update_dpm_user_id_text")
            if assistant_options:
                assistant_display = st.selectbox("asistan_id (Assistants tablosundan)", list(assistant_options.keys()), index=list(assistant_options.values()).index(dpm_row.get('asistan_id', None)) if dpm_row.get('asistan_id', None) in assistant_options.values() else 0, key="update_dpm_asistan_id")
                update_data['asistan_id'] = assistant_options[assistant_display]
            else:
                update_data['asistan_id'] = st.text_input("asistan_id", value=str(dpm_row.get('asistan_id', '')), key="update_dpm_asistan_id_text")
            if database_options:
                database_display = st.selectbox("database_id (Database Info tablosundan)", list(database_options.keys()), index=list(database_options.values()).index(dpm_row.get('database_id', None)) if dpm_row.get('database_id', None) in database_options.values() else 0, key="update_dpm_database_id")
                update_data['database_id'] = database_options[database_display]
            else:
                update_data['database_id'] = st.text_input("database_id", value=str(dpm_row.get('database_id', '')), key="update_dpm_database_id_text")
            update_data['csv_database_id'] = st.text_input("csv_database_id", value=str(dpm_row.get('csv_database_id', '')), key="update_csv_database_id")
            update_data['query_name'] = st.text_area("query_name", value=dpm_row.get('query_name', ''), max_chars=255, key="update_query_name")
            update_data['working_platform'] = st.text_area("working_platform", value=dpm_row.get('working_platform', ''), max_chars=100, key="update_working_platform")
            update_data['db_schema'] = st.text_area("db_schema", value=dpm_row.get('db_schema', ''), key="update_db_schema")
            update_data['documents_id'] = st.text_area("documents_id", value=str(dpm_row.get('documents_id', '')), key="update_documents_id")
            update_data['csv_db_schema'] = st.text_area("csv_db_schema", value=dpm_row.get('csv_db_schema', ''), key="update_csv_db_schema")
            update_data['data_prep_code'] = st.text_area("data_prep_code", value=dpm_row.get('data_prep_code', ''), height=200, max_chars=1000, key="update_data_prep_code")
        if st.button("Güncelle", key="update_button_dpm"):
            if dpm_row:
                if (update_data['working_platform'] and len(update_data['working_platform']) > 100) or (update_data['query_name'] and len(update_data['query_name']) > 100):
                    st.error("Kayıt güncellenemedi. Lütfen tüm zorunlu alanları doldurduğunuzdan emin olun.")
                else:
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

    elif table_name == "Database Info":
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
        user_options = {f"{u['id']} - {u['name']} {u['surname']} ({u['e_mail']})": u['id'] for u in users} if users else {}
        if dbinfo_entries:
            dbinfo_options = {f"{dbinfo['database_id']} - {dbinfo['database_name']}": dbinfo['database_id'] for dbinfo in dbinfo_entries}
            selected = st.selectbox("Güncellenecek Database Info", list(dbinfo_options.keys()), key="update_dbinfo_select")
            update_id = dbinfo_options[selected]
            dbinfo_row = next((d for d in dbinfo_entries if d['database_id'] == update_id), None)
        else:
            st.success("Güncellenecek database info yok.")
            update_id = None
            dbinfo_row = None
        update_data = {}
        if dbinfo_row:
            update_data['database_ip'] = st.text_area("database_ip", value=dbinfo_row.get('database_ip', ''), max_chars=100, key="update_database_ip")
            update_data['database_port'] = st.text_area("database_port", value=dbinfo_row.get('database_port', ''), key="update_database_port")
            update_data['database_user'] = st.text_area("database_user", value=dbinfo_row.get('database_user', ''), max_chars=100, key="update_database_user")
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