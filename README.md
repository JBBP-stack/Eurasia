# Eurasia
Videojuego retro sobre finanzas

Para Github:
 - Para actualizar repo si alguien lo ha modificado (imprescindible): git pull
 - Para modificar el repositorio si has hecho algún cambio (sabiendo que no hace conflicto con modificaciones sin actualizar):
        git add .       # Para añadir todo el conjunto modificado
        (git add <<nombre_carpeta/archivo>>) # Para añadir solo la carpeta/archivo modificado

        git commit -m "Modificación: descripción de la modificación"

        git push

- Para instalar requirements necesarios (asegurarse estar en venv):
            pip install -r requirements.txt
- Para actualizar requirements utilizados:
            pip freeze > requirements.txt
