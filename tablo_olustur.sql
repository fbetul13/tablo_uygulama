CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL,
    permissions TEXT,
    admin_or_not BOOLEAN DEFAULT FALSE
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    role_id INTEGER REFERENCES Roles(role_id),
    name VARCHAR(100),
    surname VARCHAR(100),
    password VARCHAR(255),
    e_mail VARCHAR(255) UNIQUE,
    institution_working VARCHAR(255),
    status VARCHAR(50),
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE TABLE assistants (
    asistan_id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    explanation TEXT,
    parameters JSONB,
    user_id INTEGER REFERENCES Users(id),
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    working_place VARCHAR(255),
    default_instructions TEXT,
    data_instructions TEXT,
    file_path VARCHAR(255),
    trigger_time JSONB
);

CREATE TABLE database_info (
    database_id SERIAL PRIMARY KEY,
    database_ip VARCHAR(100),
    database_port INTEGER,
    database_user VARCHAR(100),
    database_password VARCHAR(100),
    database_type VARCHAR(50),
    database_name VARCHAR(100),
    user_id INTEGER REFERENCES Users(id)
);

CREATE TABLE auto_prompt (
    prompt_id SERIAL PRIMARY KEY,
    asistan_id INTEGER REFERENCES assistants(asistan_id),
    question TEXT,
    trigger_time JSONB,
    option_code VARCHAR(50),
    mcrisactive BOOLEAN,
    receiver_emails TEXT
);

CREATE TABLE data_prepare_modules (
    module_id SERIAL PRIMARY KEY,  
    user_id INTEGER REFERENCES Users(id),
    asistan_id INTEGER REFERENCES assistants(asistan_id),
    query TEXT,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    working_platform VARCHAR(100),
    query_name VARCHAR(255),
    db_schema TEXT,
    documents_id INTEGER,
    csv_db_schema TEXT,
    csv_database_id INTEGER,
    data_prep_code TEXT
);
