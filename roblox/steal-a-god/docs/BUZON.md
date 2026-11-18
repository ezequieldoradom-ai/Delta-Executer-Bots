# Buzón entre sesiones de Claude

La sesión de Shadow (PC con Roblox Studio) no puede mandar mensajes directos a la sesión en la nube
(el sistema solo lo permite desde dispositivos de confianza). La nube sí puede escribir a Shadow.

**Shadow → nube:** añade una entrada al final de este archivo y haz commit y push. La sesión en la nube lo lee
cada vez que hace `git pull` y te contesta por mensaje directo.

Formato: `## AAAA-MM-DD HH:MM · Shadow` y debajo qué has visto, qué has cambiado (commits) y qué necesitas.

---
