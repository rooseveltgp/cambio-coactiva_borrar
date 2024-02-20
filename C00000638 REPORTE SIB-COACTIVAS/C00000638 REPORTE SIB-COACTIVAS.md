

### 2024-01-17
- [x] Se actualiza mesa de servicio , pasa a estado en aprobación de comité ✅ 2024-01-30
### 2024-01-17
- [x] Se remite por correo a QA la documentación de versión cerrada ✅ 2024-01-17
- [x] Se remite a QA correos de evidencia de prubas con usuario final Eduardo Manzano ✅ 2024-01-17
- [x] Se Carga en TFS ramal de QA los programas fuentes ✅ 2024-01-17

### 2024-01-16
- [x] Carga de fuentes a TFS, ramal de QA ✅ 2024-01-16
- [x] firma documentos  de versión cerrada y remite a QA mediante correo Angel Garcí 📅 2024-01-16 ✅ 2024-01-16

### 2024-01-03
- Se utiliza ambiente P2 para ejecutar proceso porque al parecer el reporte XLS se genera directamente desde el SP usando alguna funcionalidad de frontend (Polling service) que directamente genera el archivo y lo coloca en el servidor cfnuiosrv33 en la ruta que indica [[People/Eduardo Manzano]] de coactivas
- Se revisa en la maquina de [[People/Eduardo Manzano]] la carpeta donde coactiva consulta los reportes estos es \\cfnuiosrv33\coactiva\PollingService\

### 2024-01-02
- Revision en los manual de operador de Coactiva tomado de la carpeta publica  [[COA_203_MT_Manual del Operador Coactiva.pdf]]
- Se espera revisar con Vinicio Maldonado la generación del reporte
- Se compilan SP y ejecutan sp de batch, no se ve registrado en la carpeta de listados 
- Correo de Jennifer Anaguano se solicitan recuperación de información BDD,  coactiva inicial, cartera intermedio

### 2024-01-01
- Jennifer envía por correo Stored procedure y documentos para proceder con el camnbio
- 

# Tareas Pendientes <% tp.title %>

---
```dataview
task
from [[C00000638 REPORTE SIB-COACTIVAS]]
where !completed 
group by file.link

```

# Tareas Cumplidas
---
```dataview- 
task
from [[C00000638 REPORTE SIB-COACTIVAS]]
where completed 
group by file.link
```


```dataview
TASK
from "100 PROYECTOS - TASK/C00000638 REPORTE SIB-COACTIVAS"
where completed 
group by file.link
```




```dataview
list
from "100 PROYECTOS - TASK"
group by file.link
```


```dataview
TABLE file.link
from "100 PROYECTOS - TASK"
group by file.link
```

```dataview
calendar
```
