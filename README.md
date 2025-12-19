# Playterminal

Reproductor de audio en PowerShell con control de estado y playback persistente, utilizando MediaPlayer de WPF.

Para iniciar el reproductor en la sesión actual de PowerShell, ejecute el siguiente comando en la terminal:

```PowerShell
. "camino\para\Playterminal.ps1" -MusicPath "camino\para\directorio\con\archivos\mp3"
```

Ejecución del script con el reproductor activo en la consola:

![Ejemplo del terminal PowerShell reproduciendo una pista](./assets/images/DisplayExamplePowerShell.png)

Use Ctrl + C para salir de la visualización actual de la pista y poder interactuar con los recursos disponibles del reproductor.
Por ejemplo, para cambiar el volumen:

Presione Ctrl + C en el teclado y ejecute el siguiente comando:

```PowerShell
Resize-Volume -Volume 0.5
```

Los demás recursos pueden utilizarse de la misma forma.
Después de terminar de ejecutar los comandos, vuelva a la visualización del reproductor con:

```PowerShell
Invoke-Player
```

Si una canción termina y `Invoke-Player` no está en ejecución, el reproductor no avanzará a la siguiente pista.
`Invoke-Player` funciona como el motor de reproducción continua y debe estar activo en el momento en que una pista finaliza para que el cambio de archivo ocurra correctamente.

