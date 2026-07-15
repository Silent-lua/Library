from flask import Flask, render_template, request, jsonify
import sqlite3
import random
import string

app = Flask(__name__)

def get_db_connection():
    conn = sqlite3.connect('database.db')
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    conn.execute('''
        CREATE TABLE IF NOT EXISTS scripts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            universe_id TEXT NOT NULL,
            code TEXT NOT NULL,
            active INTEGER DEFAULT 1
        )
    ''')
    conn.execute('''
        CREATE TABLE IF NOT EXISTS licenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key_string TEXT NOT NULL UNIQUE,
            duration TEXT NOT NULL,
            max_uses INTEGER NOT NULL,
            status TEXT DEFAULT 'Active'
        )
    ''')
    conn.commit()
    conn.close()

init_db()

@app.route('/')
def index():
    return render_template('panel.html')

@app.route('/api/scripts', methods=['GET'])
def get_scripts():
    conn = get_db_connection()
    scripts = conn.execute('SELECT * FROM scripts').fetchall()
    conn.close()
    return jsonify([dict(ix) for ix in scripts])

@app.route('/api/scripts', methods=['POST'])
def add_script():
    data = request.get_json()
    name = data.get('name')
    universe_id = data.get('universe_id')
    code = data.get('code')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        'INSERT INTO scripts (name, universe_id, code, active) VALUES (?, ?, ?, ?)',
        (name, universe_id, code, 1)
    )
    conn.commit()
    script_id = cursor.lastrowid
    conn.close()
    
    return jsonify({"id": script_id, "name": name, "universe_id": universe_id, "active": 1}), 201

@app.route('/api/scripts/<int:id>', methods=['DELETE'])
def delete_script(id):
    conn = get_db_connection()
    conn.execute('DELETE FROM scripts WHERE id = ?', (id,))
    conn.commit()
    conn.close()
    return jsonify({"success": True})

@app.route('/api/scripts/<int:id>/toggle', methods=['PUT'])
def toggle_script(id):
    data = request.get_json()
    active = 1 if data.get('active') else 0
    conn = get_db_connection()
    conn.execute('UPDATE scripts SET active = ? WHERE id = ?', (active, id))
    conn.commit()
    conn.close()
    return jsonify({"success": True})

@app.route('/api/licenses', methods=['GET'])
def get_licenses():
    conn = get_db_connection()
    licenses = conn.execute('SELECT * FROM licenses').fetchall()
    conn.close()
    return jsonify([dict(ix) for ix in licenses])

@app.route('/api/licenses', methods=['POST'])
def generate_license():
    data = request.get_json()
    prefix = data.get('prefix', 'SH_')
    duration = data.get('duration')
    max_uses = data.get('max_uses')
    
    random_part = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
    key = f"{prefix}{random_part}"
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        'INSERT INTO licenses (key_string, duration, max_uses, status) VALUES (?, ?, ?, ?)',
        (key, duration, max_uses, 'Active')
    )
    conn.commit()
    conn.close()
    
    return jsonify({"key": key, "duration": duration, "max_uses": max_uses, "status": "Active"}), 201

@app.route('/api/licenses/<int:id>/revoke', methods=['PUT'])
def revoke_license(id):
    conn = get_db_connection()
    conn.execute('UPDATE licenses SET status = ? WHERE id = ?', ('Revoked', id))
    conn.commit()
    conn.close()
    return jsonify({"success": True})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
