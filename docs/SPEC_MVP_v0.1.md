# SPEC_MVP_v0.1

> **Vyrax**
>
> Flutter Architecture & Performance Analyzer
>
> **Status:** Draft
>
> **Version:** 0.1.0

---

# 1. Objetivo

El objetivo del MVP es demostrar que Vyrax puede detectar problemas reales de alto impacto en proyectos Flutter con una experiencia de uso simple y una tasa baja de falsos positivos.

El MVP debe ser suficientemente util para que un equipo Flutter pueda instalarlo e integrarlo en su pipeline de CI/CD desde el primer dia.

No buscamos cubrir todos los casos posibles.

Buscamos resolver pocos problemas, pero resolverlos muy bien.

---

# 2. Objetivos del MVP

El MVP debe permitir:

- Analizar un proyecto Flutter.
- Detectar problemas especificos de Flutter.
- Mostrar diagnosticos claros.
- Explicar el problema.
- Explicar el impacto.
- Sugerir una solucion.
- Integrarse facilmente en CI/CD.

No se implementaran Quick Fixes automaticos en esta version.

---

# 3. Alcance

Incluye:

- CLI
- Motor de reglas
- Registro de reglas
- Salida por consola
- Salida JSON
- Configuracion basica

No incluye:

- VS Code Extension
- Android Studio Plugin
- Dashboard
- IA
- Widget Tree Analyzer avanzado
- Quick Fixes

---

# 4. Comando principal

```bash
vyrax analyze
```

Este comando debe:

- Detectar automaticamente un proyecto Flutter.
- Analizar el codigo.
- Ejecutar todas las reglas habilitadas.
- Mostrar un resumen.
- Retornar un Exit Code apropiado.

---

# 5. Exit Codes

| Codigo | Significado |
|---------|-------------|
| 0 | Sin problemas |
| 1 | Warnings encontrados |
| 2 | Errors encontrados |
| 3 | Error interno |

Esto permitira integrarlo facilmente con GitHub Actions, GitLab CI, Azure DevOps, Jenkins, etc.

---

# 6. Flujo

```text
vyrax analyze

↓

Carga configuracion

↓

Detecta Flutter

↓

Registra reglas

↓

Ejecuta reglas

↓

Genera Issues

↓

Renderiza salida

↓

Exit Code
```

---

# 7. Formato de un Issue

Todo Issue debe contener:

```text
ID

Titulo

Categoria

Severidad

Archivo

Linea

Descripcion

Impacto

Recomendacion

Documentacion
```

---

Ejemplo:

```text
VYX001

Future inside build()

Category:
Performance

Severity:
Error

Location:
lib/home_page.dart:34

Description:
FutureBuilder recreates its Future every time build() executes.

Why it matters:
This may execute unnecessary network requests.

Recommendation:
Move the Future outside build() or use state management.
```

---

# 8. Reglas del MVP

## VYX001

Future inside build

Categoria

Performance

Descripcion

Detecta Futures creados directamente dentro de build().

Ejemplo

```dart
FutureBuilder(
  future: repository.getUsers(),
)
```

Resultado

Error

---

## VYX002

Network request inside build

Categoria

Performance

Detecta llamadas HTTP dentro de build().

Ejemplos

dio.get()

http.get()

client.get()

await dio.get()

Resultado

Error

---

## VYX003

Multiple public classes

Categoria

Domain

Detecta multiples clases publicas en un mismo archivo.

Ejemplo

user_model.dart

User

Address

Country

Role

Resultado

Warning

---

## VYX004

Build complexity

Categoria

Architecture

Detecta metodos build() excesivamente complejos.

Metricas iniciales

- demasiados widgets hijos
- demasiadas condiciones
- demasiados builders

Resultado

Warning

---

## VYX005

Large Consumer Scope

Categoria

State Management

Detecta Consumer, BlocBuilder o ValueListenableBuilder envolviendo widgets de alto nivel.

Ejemplo

Consumer

↓

Scaffold

Resultado

Warning

---

# 9. Configuracion

Archivo

vyrax.yaml

Ejemplo

```yaml
rules:

  VYX001:
    severity: error

  VYX003:
    enabled: false

output:

  format: text
```

---

# 10. Formato JSON

```json
{
  "summary": {
    "critical": 0,
    "error": 1,
    "warning": 2,
    "info": 0
  },
  "issues": [
    {
      "id": "VYX001",
      "severity": "error",
      "category": "performance",
      "file": "lib/home_page.dart",
      "line": 42,
      "title": "Future inside build",
      "description": "...",
      "recommendation": "..."
    }
  ]
}
```

---

# 11. Salida por consola

Ejemplo

```text
Analyzing Flutter project...

Flutter: 3.35.2

Architecture:
Unknown

Rules executed:
5

--------------------------------

ERROR VYX001

Future inside build()

lib/home_page.dart:42

FutureBuilder recreates its Future every time build() executes.

Impact

*****

Recommendation

Move the Future to initState() or use state management.

--------------------------------

WARNING VYX003

Multiple public classes

lib/models/user_model.dart

Found 4 public classes in the same file.

Recommendation

Split each model into its own file.

--------------------------------

Summary

Errors:
1

Warnings:
1

Time:
0.8s
```

---

# 12. Criterios de aceptacion

El MVP estara terminado cuando:

- vyrax analyze funcione en un proyecto Flutter.
- Las cinco reglas funcionen correctamente.
- Exista salida en texto.
- Exista salida JSON.
- Todos los Issues tengan explicacion.
- Todos los Issues tengan recomendacion.
- El proyecto tenga pruebas automatizadas.
- La cobertura minima sea del 80%.
- El comando pueda ejecutarse en CI sin configuracion adicional.

---

# 13. Fuera del alcance

No implementar en esta version:

- IA
- Dashboard
- VS Code Extension
- Android Studio Plugin
- Widget Tree Analyzer avanzado
- Quick Fixes
- Auto Refactor
- Project Score
- HTML Reports

---

# 14. Definicion de exito

El MVP sera considerado exitoso si un desarrollador Flutter puede instalar Vyrax, ejecutar:

```bash
vyrax analyze
```

y recibir diagnosticos utiles, claros y accionables en menos de cinco segundos, sin necesidad de configuracion compleja.

---

# 15. Proxima version (v0.2)

Objetivos previstos:

- Widget Tree Analyzer.
- Score del proyecto.
- Quick Fixes.
- vyrax doctor.
- Configuracion avanzada.
- Perfiles de arquitectura.
- Auto deteccion de arquitectura.