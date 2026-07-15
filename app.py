from flask import Flask, render_template, redirect, url_for, request, flash
from flask_login import (
    LoginManager,
    UserMixin,
    login_user,
    logout_user,
    login_required,
    current_user
)
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timedelta
import os
import hashlib


app = Flask(__name__)


# ==================================================
# CONFIGURACIÓN
# ==================================================

app.secret_key = os.environ.get(
    "SECRET_KEY",
    "silenthub-change-this-secret"
)

app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///silenthub.db"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

app.config["REMEMBER_COOKIE_DURATION"] = timedelta(days=30)
app.config["REMEMBER_COOKIE_HTTPONLY"] = True
app.config["REMEMBER_COOKIE_SECURE"] = False


inicio_servidor = datetime.now()
db = SQLAlchemy(app)


# ==================================================
# MODELOS DE BASE DE DATOS
# ==================================================

class Usuario(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)

class RegistroSeguridad(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    ip_address = db.Column(db.String(50))
    user_agent = db.Column(db.String(255))
    attempted_username = db.Column(db.String(50))
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    status = db.Column(db.String(20))

class EjecucionScript(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    roblox_username = db.Column(db.String(50))
    universe_id = db.Column(db.String(15))
    ip_address = db.Column(db.String(50))
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)


# ==================================================
# LOGIN SYSTEM
# ==================================================

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

@login_manager.user_loader
def load_user(user_id):
    return Usuario.query.get(int(user_id))

def inicializar_sistema():
    # Crea un usuario administrador por defecto si la tabla está vacía
    if not Usuario.query.filter_by(username="admin").first():
        hash_pass = hashlib.sha256("admin123".encode()).hexdigest()
        admin = Usuario(username="admin", password_hash=hash_pass)
        db.session.add(admin)
        db.session.commit()

with app.app_context():
    db.create_all()
    inicializar_sistema()


# ==================================================
# RUTAS DE INTERFAZ (UI)
# ==================================================

@app.route('/', methods=['GET'])
def index():
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('panel'))

    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        ip_address = request.remote_addr
        user_agent = request.user_agent.string
        
        user = Usuario.query.filter_by(username=username).first()
        pass_hash = hashlib.sha256(password.encode()).hexdigest() if password else ""

        if user and user.password_hash == pass_hash:
            login_user(user, remember=True)
            
            log = RegistroSeguridad(
                ip_address=ip_address, 
                user_agent=user_agent, 
                attempted_username=username, 
                status="SUCCESS"
            )
            db.session.add(log)
            db.session.commit()
            
            return redirect(url_for('panel'))
        else:
            log = RegistroSeguridad(
                ip_address=ip_address, 
                user_agent=user_agent, 
                attempted_username=username, 
                status="FAILED"
            )
            db.session.add(log)
            db.session.commit()
            
            flash("ACCESO DENEGADO")

    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/panel')
@login_required
def panel():
    # Cálculo dinámico del Uptime para renderizar en tu HTML
    tiempo_activo = datetime.now() - inicio_servidor
    horas, rem = divmod(tiempo_activo.seconds, 3600)
    minutos, _ = divmod(rem, 60)
    uptime_str = f"{tiempo_activo.days}d {horas}h {minutos}m"

    # Diccionario exacto que espera tu panel.html
    datos_servidor = {
        "estado": "En línea",
        "version": "SilentHub",
        "tiempo": uptime_str,
        "usuario": current_user.username
    }
    
    return render_template('panel.html', datos=datos_servidor)


# ==================================================
# API DE TELEMETRÍA (CONEXIÓN LUA)
# ==================================================

@app.route('/api/load', methods=['GET'])
def load_script():
    uid = request.args.get('uid')
    user = request.args.get('user')
    ip_address = request.remote_addr
    
    if uid and user:
        nueva_ejecucion = EjecucionScript(
            roblox_username=user,
            universe_id=uid,
            ip_address=ip_address
        )
        db.session.add(nueva_ejecucion)
        db.session.commit()
        
    codigo_respuesta = 'print("SilentHub Conectado. Ejecutando...")'
    
    return codigo_respuesta, 200, {'Content-Type': 'text/plain'}


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
