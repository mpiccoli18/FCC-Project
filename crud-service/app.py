from flask import Flask, request, jsonify
import mysql.connector
import os

app = Flask(__name__)

# Connect to the MySQL database using environment variables
def get_db_connection():
    return mysql.connector.connect(
        host=os.environ.get('DB_HOST', 'mysql'), # 'mysql' is the K8s service name
        user=os.environ.get('DB_USER', 'root'),
        password=os.environ.get('DB_PASSWORD', ''),
        database=os.environ.get('DB_NAME', 'testdb')
    )

# Initialize database
def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("CREATE DATABASE IF NOT EXISTS testdb")
    cursor.execute("USE testdb")
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) NOT NULL
        )
    """)
    conn.commit()
    cursor.close()
    conn.close()

@app.route('/users', methods=['GET'])
def get_users():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("USE testdb")
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(users)

@app.route('/users', methods=['POST'])
def add_user():
    new_user = request.get_json()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("USE testdb")
    cursor.execute("INSERT INTO users (name, email) VALUES (%s, %s)", (new_user['name'], new_user['email']))
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"status": "success", "message": "User added"}), 201

if __name__ == '__main__':
    try:
        init_db()
    except Exception as e:
        print(f"Database init failed: {e}")
    app.run(host='0.0.0.0', port=5000)
