from flask import Flask, render_template, redirect, url_for, request, flash, jsonify
from flask_login import (
    LoginManager,
    UserMixin,
    login_user,
    logout_user,
    login_required,
    current_user
) # [CORRECCIÓN]: Paréntesis de cierre añadido
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import or_
from datetime import datetime, timedelta
import os
import hashlib
import secrets

app = Flask(__name__)
app.secret_key = os.environ.get(
    "SECRET_KEY",
    "silenthub-change-this-secret"
) # [CORRECCIÓN]: Paréntesis de cierre añadido

database_url = os.environ.get("DATABASE_URL")
if database_url:
    database_url = database_url.replace("postgres://", "postgresql://", 1)
    app.config["SQLALCHEMY_DATABASE_URI"] = database_url
else:
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///silenthub.db"

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["REMEMBER_COOKIE_DURATION"] = timedelta(days=30)
app.config["REMEMBER_COOKIE_HTTPONLY"] = True
app.config["REMEMBER_COOKIE_SECURE"] = True

inicio_servidor = datetime.now()
db = SQLAlchemy(app)

# ==========================================
# MODELOS DE BASE DE DATOS
# ==========================================
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
    license_key = db.Column(db.String(64), unique=True, nullable=False)
    owner = db.Column(db.String(100), default="")
    license_type = db.Column(db.String(20), default="Whitelist") # Forzado a Whitelist por defecto
    status = db.Column(db.String(20), default="ACTIVE")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=True)
    last_used = db.Column(db.DateTime, nullable=True)
    last_ip = db.Column(db.String(50), default="")
    total_uses = db.Column(db.Integer, default=0)
    hwid = db.Column(db.String(255), default="")
    revoked_at = db.Column(db.DateTime, nullable=True)
    notes = db.Column(db.Text, default="")

# ==========================================
# FUNCIONES AUXILIARES
# ==========================================
def update_license_status(license_obj):
    """Actualiza automáticamente el estado del acceso basado en su fecha de expiración."""
    if license_obj.status == "REVOKED":
        return
        
    if license_obj.expires_at is None:
        license_obj.status = "ACTIVE"
        return
            
    if datetime.utcnow() >= license_obj.expires_at:
        license_obj.status = "EXPIRED"
    else:
        license_obj.status = "ACTIVE"

def parse_duration(duracion_str, base_date=None):
    """Convierte un string de duración a una fecha de expiración."""
    if base_date is None:
        base_date = datetime.utcnow()
            
    if duracion_str == "1 Day":
        return base_date + timedelta(days=1)
    elif duracion_str == "7 Days":
        return base_date + timedelta(days=7)
    elif duracion_str == "30 Days":
        return base_date + timedelta(days=30)
    elif duracion_str == "90 Days":
        return base_date + timedelta(days=90)
    return None # Permanent

# ==========================================
# INICIALIZACIÓN Y LOGIN
# ==========================================
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
        licencia_prueba = Licencia(
            license_key="TuUsuarioRoblox", 
            license_type="Whitelist", 
            owner="Admin",
            status="ACTIVE"
        )
        db.session.add(licencia_prueba)
        db.session.commit()
            
    if not os.path.exists('scripts'):
        os.makedirs('scripts')

with app.app_context():
    db.create_all()
    inicializar_sistema()

# ==========================================
# RUTAS WEB (AUTH & PANEL)
# ==========================================
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
    for licencia in Licencia.query.all():
        update_license_status(licencia)
    db.session.commit()

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

    stats_licencias = {
        'total': Licencia.query.count(),
        'active': Licencia.query.filter_by(status='ACTIVE').count(),
        'expired': Licencia.query.filter_by(status='EXPIRED').count(),
        'revoked': Licencia.query.filter_by(status='REVOKED').count()
    }

    busqueda = request.args.get("q", "").strip()
    estado = request.args.get("estado", "").strip()
        
    query = Licencia.query
    if busqueda:
        query = query.filter(
            or_(
                Licencia.license_key.ilike(f"%{busqueda}%"),
                Licencia.owner.ilike(f"%{busqueda}%")
            )
        )
    if estado:
        query = query.filter_by(status=estado)

    licencias_recientes = query.order_by(Licencia.created_at.desc()).all()
    ejecuciones_recientes = EjecucionScript.query.order_by(EjecucionScript.timestamp.desc()).limit(15).all()
    registros_seguridad = RegistroSeguridad.query.order_by(RegistroSeguridad.timestamp.desc()).limit(15).all()
        
    return render_template(
        'panel.html', 
        datos=datos_servidor, 
        licencias=licencias_recientes,
        ejecuciones=ejecuciones_recientes, 
        seguridad=registros_seguridad,
        stats_telemetria=stats_telemetria,
        stats_seguridad=stats_seguridad,
        stats_licencias=stats_licencias
    )

# ==========================================
# RUTAS CRUD DE WHITELIST
# ==========================================
@app.route('/licencias/crear', methods=['POST'])
@login_required
def crear_licencia():
    clave = request.form.get('clave', '').strip()
    owner = request.form.get('owner', 'Auto-Añadido').strip()
    duracion = request.form.get('duracion', 'Permanent')
    notas = request.form.get('notes', '').strip()
        
    if not clave:
        flash("Debe ingresar el usuario de Roblox para la Whitelist.")
        return redirect(url_for('panel'))
            
    existe = Licencia.query.filter_by(license_key=clave).first()
    if existe:
        flash("El usuario ya existe en la Whitelist.")
        return redirect(url_for('panel'))
            
    expires_at = parse_duration(duracion)
            
    nueva = Licencia(
        license_key=clave, 
        owner=owner,
        license_type="Whitelist", # Estructurado directamente como Whitelist
        status="ACTIVE",
        expires_at=expires_at,
        notes=notas
    )
    db.session.add(nueva)
    db.session.commit()
    flash("Usuario añadido a la Whitelist correctamente.")
    return redirect(url_for('panel'))

@app.route("/licencias/editar/<int:id>", methods=["POST"])
@login_required
def editar_licencia(id):
    licencia = Licencia.query.get_or_404(id)
    licencia.owner = request.form.get("owner", "").strip()
    licencia.notes = request.form.get("notes", "").strip()
    duracion = request.form.get("duracion", "Permanent")
        
    licencia.expires_at = parse_duration(duracion, base_date=licencia.created_at)
    update_license_status(licencia)
    db.session.commit()
    flash("Whitelist actualizada correctamente.")
    return redirect(url_for("panel"))

@app.route('/licencias/revocar/<int:id>', methods=['POST'])
@login_required
def revocar_licencia(id):
    lic = Licencia.query.get_or_404(id)
    if lic.status == "REVOKED":
        lic.status = "ACTIVE"
        lic.revoked_at = None
        update_license_status(lic) 
    else:
        lic.status = "REVOKED"
        lic.revoked_at = datetime.utcnow()
            
    db.session.commit()
    flash("Estado del acceso actualizado.")
    return redirect(url_for('panel'))

@app.route('/licencias/eliminar/<int:id>', methods=['POST'])
@login_required
def eliminar_licencia(id):
    lic = Licencia.query.get_or_404(id)
    db.session.delete(lic)
    db.session.commit()
    flash("Usuario eliminado de forma permanente.")
    return redirect(url_for('panel'))

# ==========================================
# API DE INYECCIÓN (ROBLOX / LUA)
# ==========================================
@app.route('/api/load', methods=['GET'])
def load_script():
    uid = request.args.get('uid')
    user = request.args.get('user')
    ip_address = request.remote_addr
        
    if uid and user:
        nueva_ejecucion = EjecucionScript(roblox_username=user, universe_id=uid, ip_address=ip_address)
        db.session.add(nueva_ejecucion)
            
    acceso_permitido = False
    licencia_activa = None
        
    # Verificación Exclusiva de Whitelist
    if user:
        lic_whitelist = Licencia.query.filter_by(license_key=user, license_type="Whitelist").first()
        if lic_whitelist:
            update_license_status(lic_whitelist)
            db.session.flush() 
            if lic_whitelist.status == "ACTIVE":
                acceso_permitido = True
                licencia_activa = lic_whitelist
                    
    if not acceso_permitido:
        db.session.commit() 
        return 'warn("SilentHub: ACCESO DENEGADO - El usuario no esta en la Whitelist o el acceso ha expirado.")', 403
            
    if licencia_activa:
        licencia_activa.last_used = datetime.utcnow()
        licencia_activa.last_ip = ip_address
        licencia_activa.total_uses += 1
        
    db.session.commit()
            
    ruta_script = os.path.join(os.path.dirname(__file__), 'scripts', 'main.lua')
        
    if os.path.exists(ruta_script):
        with open(ruta_script, 'r', encoding='utf-8') as archivo:
            codigo_lua = archivo.read()
        return codigo_lua, 200, {'Content-Type': 'text/plain'}
    else:
        return 'print("SilentHub: El archivo main.lua no se encuentra en el servidor.")', 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
