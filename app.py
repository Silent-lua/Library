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
import uuid

app = Flask(__name__)

app.secret_key = os.environ.get(
    "SECRET_KEY",
    "silenthub-change-this-secret"
)

database_url = os.environ.get("DATABASE_URL")

if database_url:
    database_url = database_url.replace("postgres://", "postgresql://", 1)
    app.config["SQLALCHEMY_DATABASE_URI"] = database_url
else:
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///silenthub.db"

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["REMEMBER_COOKIE_DURATION"] = timedelta(days=30)
app.config["REMEMBER_COOKIE_HTTPONLY"] = True
app.config["REMEMBER_COOKIE_SECURE"] = False

inicio_servidor = datetime.now()
db = SQLAlchemy(app)

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

class Licencia(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    clave = db.Column(db.String(100), unique=True, nullable=False)
    tipo = db.Column(db.String(20))
    duracion = db.Column(db.String(20))
    estado = db.Column(db.String(20), default="Activa")
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

@login_manager.user_loader
def load_user(user_id):
    return Usuario.query.get(int(user_id))

def inicializar_sistema():
    if not Usuario.query.filter_by(username="admin").first():
        hash_pass = hashlib.sha256("admin123".encode()).hexdigest()
        admin = Usuario(username="admin", password_hash=hash_pass)
        db.session.add(admin)
        db.session.commit()
        
    if not Licencia.query.first():
        licencia_prueba = Licencia(clave="AllForOne", tipo="Whitelist", duracion="Permanent", estado="Activa")
        db.session.add(licencia_prueba)
        db.session.commit()
        
    if not os.path.exists('scripts'):
        os.makedirs('scripts')

with app.app_context():
    db.create_all()
    inicializar_sistema()

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
            log = RegistroSeguridad(ip_address=ip_address, user_agent=user_agent, attempted_username=username, status="SUCCESS")
            db.session.add(log)
            db.session.commit()
            return redirect(url_for('panel'))
        else:
            log = RegistroSeguridad(ip_address=ip_address, user_agent=user_agent, attempted_username=username, status="FAILED")
            db.session.add(log)
            db.session.commit()
            flash("ACCESO DENEGADO - CREDENCIALES INVÁLIDAS")

    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/panel')
@login_required
def panel():
    tiempo_activo = datetime.now() - inicio_servidor
    horas, rem = divmod(tiempo_activo.seconds, 3600)
    minutos, _ = divmod(rem, 60)
    uptime_str = f"{tiempo_activo.days}d {horas}h {minutos}m"

    datos_servidor = {
        "usuario": current_user.username,
        "tiempo": uptime_str
    }
    
    now = datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=now.weekday())
    month_start = today_start.replace(day=1)
    year_start = today_start.replace(month=1, day=1)

    stats_telemetria = {
        'diario': EjecucionScript.query.filter(EjecucionScript.timestamp >= today_start).count(),
        'semanal': EjecucionScript.query.filter(EjecucionScript.timestamp >= week_start).count(),
        'mensual': EjecucionScript.query.filter(EjecucionScript.timestamp >= month_start).count(),
        'anual': EjecucionScript.query.filter(EjecucionScript.timestamp >= year_start).count()
    }

    stats_seguridad = {
        'diario': RegistroSeguridad.query.filter(RegistroSeguridad.timestamp >= today_start, RegistroSeguridad.status == 'FAILED').count(),
        'semanal': RegistroSeguridad.query.filter(RegistroSeguridad.timestamp >= week_start, RegistroSeguridad.status == 'FAILED').count(),
        'mensual': RegistroSeguridad.query.filter(RegistroSeguridad.timestamp >= month_start, RegistroSeguridad.status == 'FAILED').count(),
        'anual': RegistroSeguridad.query.filter(RegistroSeguridad.timestamp >= year_start, RegistroSeguridad.status == 'FAILED').count()
    }

    licencias_recientes = Licencia.query.order_by(Licencia.fecha_creacion.desc()).all()
    ejecuciones_recientes = EjecucionScript.query.order_by(EjecucionScript.timestamp.desc()).limit(15).all()
    registros_seguridad = RegistroSeguridad.query.order_by(RegistroSeguridad.timestamp.desc()).limit(15).all()
    
    return render_template(
        'panel.html', 
        datos=datos_servidor, 
        licencias=licencias_recientes,
        ejecuciones=ejecuciones_recientes, 
        seguridad=registros_seguridad,
        stats_telemetria=stats_telemetria,
        stats_seguridad=stats_seguridad
    )

@app.route('/licencias/crear', methods=['POST'])
@login_required
def crear_licencia():
    clave = request.form.get('clave', '').strip()
    tipo = request.form.get('tipo', 'KeySystem')
    duracion = request.form.get('duracion', 'Permanent')
    
    if tipo == 'KeySystem' and not clave:
        clave = f"SILENT-{uuid.uuid4().hex[:8].upper()}"
    elif not clave:
        flash("Debe ingresar un identificador para Whitelist.")
        return redirect(url_for('panel'))
        
    existe = Licencia.query.filter_by(clave=clave).first()
    if existe:
        flash("La licencia o identificador ya existe.")
        return redirect(url_for('panel'))
        
    nueva = Licencia(clave=clave, tipo=tipo, duracion=duracion, estado="Activa")
    db.session.add(nueva)
    db.session.commit()
    return redirect(url_for('panel'))

@app.route('/licencias/revocar/<int:id>', methods=['POST'])
@login_required
def revocar_licencia(id):
    lic = Licencia.query.get_or_404(id)
    lic.estado = "Revocada" if lic.estado == "Activa" else "Activa"
    db.session.commit()
    return redirect(url_for('panel'))

@app.route('/api/load', methods=['GET'])
def load_script():
    uid = request.args.get('uid')
    user = request.args.get('user')
    key = request.args.get('key')
    ip_address = request.remote_addr
    
    if uid and user:
        nueva_ejecucion = EjecucionScript(roblox_username=user, universe_id=uid, ip_address=ip_address)
        db.session.add(nueva_ejecucion)
        db.session.commit()
        
    acceso_permitido = False
    
    if user:
        lic_whitelist = Licencia.query.filter_by(clave=user, tipo="Whitelist", estado="Activa").first()
        if lic_whitelist:
            acceso_permitido = True
            
    if not acceso_permitido and key:
        lic_key = Licencia.query.filter_by(clave=key, tipo="KeySystem", estado="Activa").first()
        if lic_key:
            acceso_permitido = True
            
    if not acceso_permitido:
        return 'warn("SilentHub: ACCESO DENEGADO - Licencia invalida o expirada.")', 403
        
    ruta_script = os.path.join(os.path.dirname(__file__), 'scripts', 'main.lua')
    
    if os.path.exists(ruta_script):
        with open(ruta_script, 'r', encoding='utf-8') as archivo:
            codigo_lua = archivo.read()
        return codigo_lua, 200, {'Content-Type': 'text/plain'}
    else:
        return 'print("SilentHub: El archivo main.lua no se encuentra en el servidor.")', 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
