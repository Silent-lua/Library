<!DOCTYPE html>
<html lang="es">

<head>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>SilentHub Dashboard</title>

<link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">

</head>


<body>


<div class="container">


<h1>SilentHub</h1>

<p>
Dashboard
</p>


<div class="card">

<h2>Estado</h2>

<p class="online">
● {{ datos.estado }}
</p>

</div>



<div class="card">

<h2>Información</h2>

<p>
Nombre: {{ datos.nombre }}
</p>

<p>
Versión: {{ datos.version }}
</p>

<p>
Activo: {{ datos.tiempo }}
</p>

</div>



<button>
Settings
</button>


</div>


</body>

</html>
