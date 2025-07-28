#!/usr/bin/env python3
import json
import requests
import re

def clean_sql_value(value):
    """Clean SQL value by removing quotes and escaping"""
    if value == 'NULL':
        return None
    # Remove surrounding quotes
    if value.startswith("'") and value.endswith("'"):
        value = value[1:-1]
    # Replace escaped quotes
    value = value.replace("''", "'")
    # Replace escaped backslashes
    value = value.replace("\\\\", "\\")
    return value

def parse_sql_insert(sql_file_path):
    """Parse SQL INSERT statements and extract data"""
    with open(sql_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all INSERT statements
    insert_pattern = r"INSERT INTO.*?VALUES\s*\((.*?)\);"
    matches = re.findall(insert_pattern, content, re.DOTALL | re.IGNORECASE)
    
    records = []
    for match in matches:
        # Split by comma, but be careful with nested quotes
        values = []
        current_value = ""
        in_quotes = False
        paren_count = 0
        
        for char in match:
            if char == "'" and (len(current_value) == 0 or current_value[-1] != '\\'):
                in_quotes = not in_quotes
                current_value += char
            elif char == '(' and not in_quotes:
                paren_count += 1
                current_value += char
            elif char == ')' and not in_quotes:
                paren_count -= 1
                current_value += char
            elif char == ',' and not in_quotes and paren_count == 0:
                values.append(current_value.strip())
                current_value = ""
            else:
                current_value += char
        
        if current_value.strip():
            values.append(current_value.strip())
        
        if len(values) >= 13:  # Expected number of columns
            record = {
                'user_id': int(clean_sql_value(values[0])),
                'asistan_id': int(clean_sql_value(values[1])),
                'query': clean_sql_value(values[2]),
                'create_date': clean_sql_value(values[3]),
                'change_date': clean_sql_value(values[4]),
                'working_platform': clean_sql_value(values[5]),
                'query_name': clean_sql_value(values[6]),
                'database_id': int(clean_sql_value(values[7])) if clean_sql_value(values[7]) else None,
                'db_schema': clean_sql_value(values[8]),
                'documents_id': clean_sql_value(values[9]),
                'csv_database_id': int(clean_sql_value(values[10])) if clean_sql_value(values[10]) else None,
                'csv_db_schema': clean_sql_value(values[11]),
                'data_prep_code': clean_sql_value(values[12])
            }
            records.append(record)
    
    return records

def map_asistan_id(old_asistan_id):
    """Map old asistan_id to new ones"""
    mapping = {
        1: 7,  # Mekatronik ETL Log Asistanı
        2: 8   # Logo Anomali Asistanı
    }
    return mapping.get(old_asistan_id, old_asistan_id)

def import_to_api(records, base_url="http://localhost:8000"):
    """Import records to API"""
    success_count = 0
    error_count = 0
    
    for i, record in enumerate(records, 1):
        # Map asistan_id
        record['asistan_id'] = map_asistan_id(record['asistan_id'])
        
        # Add module_id if not present
        if 'module_id' not in record:
            record['module_id'] = i
        
        # Remove None values
        record = {k: v for k, v in record.items() if v is not None}
        
        try:
            response = requests.post(
                f"{base_url}/data_prepare_modules",
                headers={"Content-Type": "application/json"},
                json=record,
                timeout=30
            )
            
            if response.status_code == 200:
                print(f"✅ Kayıt {i} başarıyla eklendi: {record.get('query_name', 'Unknown')}")
                success_count += 1
            else:
                print(f"❌ Kayıt {i} hatası: {response.status_code} - {response.text}")
                error_count += 1
                
        except Exception as e:
            print(f"❌ Kayıt {i} exception hatası: {str(e)}")
            error_count += 1
    
    return success_count, error_count

def main():
    sql_file = "data_prepare_modules.csv/data_prepare_modules_202507281009.sql"
    
    print("🔍 SQL dosyasından veriler okunuyor...")
    records = parse_sql_insert(sql_file)
    print(f"📊 Toplam {len(records)} kayıt bulundu")
    
    print("\n🚀 Veriler API'ye aktarılıyor...")
    success, error = import_to_api(records)
    
    print(f"\n📈 Sonuç:")
    print(f"✅ Başarılı: {success}")
    print(f"❌ Hatalı: {error}")
    print(f"📊 Toplam: {success + error}")

if __name__ == "__main__":
    main() 