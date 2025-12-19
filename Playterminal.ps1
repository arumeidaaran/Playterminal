param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$MusicPath,

    [Parameter(Position = 1)]
    [string]$Filter = '*.mp3'
)


Add-Type -AssemblyName PresentationCore

function Get-PreviewSong {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }
    
    $CurrentIndex = ($playlistPlayer | ForEach-Object { $_.FullName }).IndexOf($player.Source.OriginalString)
    $songIndex = $CurrentIndex - 1
    $song = $playlistPlayer[$songIndex].FullName

    return [string] $song
}

function Get-NextSong {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    $CurrentIndex = ($playlistPlayer | ForEach-Object { $_.FullName }).IndexOf($player.Source.OriginalString)
    $songIndex = $CurrentIndex + 1
    $song = $playlistPlayer[$songIndex].FullName

    return [string] $song
}

function Get-SongByIndex {
    param (
        [int] $index
    )

    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    $song = $playlistPlayer[$index-1].FullName
    return [string] $song
}

function Get-PlaybackTime {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Formatear como HH:MM:SS con dos dígitos en cada campo
    $duracionAtual = $Global:player.Position.TotalSeconds

    return $duracionAtual
}

function Open-File {
    param (
        [string] $uri
    )
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }
    
    $Global:player.Open($([Uri]::new($uri)))
}

function Resize-Volume {
    param (
        [double] $volume
    )

    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    $Global:player.Volume = [math]::Min([math]::Max($Volume, 0), 1)
}

function Start-Player {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Reproduzir
    $Global:player.Play()
}

function Wait-StartPlayback {
    $inicio = [DateTime]::UtcNow
    $timeout = [TimeSpan]::FromSeconds(2)

    while (-not (Assert-PlaybackIsStarted)) {
        if ([DateTime]::UtcNow - $inicio -gt $timeout) {
            return $false
        }

        Start-Sleep -Milliseconds 5
    }

    return $true
}

function Stop-Player {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Reproduzir
    $Global:player.Stop()
}

function Suspend-Player {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    # Reproduzir
    $Global:player.Pause()
}

function Assert-PlaybackIsStarted {
    # No hay archivo cargado
    if (-not $Global:player.Source) { 
        return $false
    }

    # La posición ya avanzó
    if ($Global:player.Position.Ticks -ne 0) {
        return $true
    }

    return $false
}

function Start-Song {
    param (
        [string] $song
    )

    Open-File -uri $song

    Start-Player
}

function Start-NextSong {
    $song = Get-NextSong
    Start-Song -song $song
}

function Start-PreviewSong {
    $song = Get-PreviewSong
    Start-Song -song $song
}

function Start-SongByIndex {
    param (
        [int] $index
    )

    $song = Get-SongByIndex -index $index
    Start-Song -song $song
}

function Get-DisplayInformation {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    if ([string]::IsNullOrEmpty($Global:displayPlayer)) {
        throw 'Display no definido'
    }

    $Global:displayPlayer.CurrentSoundPath = $Global:player.Source.OriginalString
    $Global:displayPlayer.CurrentSoundTime = Get-PlaybackTime
    $Global:displayPlayer.CurrentSoundTotalTime = $Global:player.NaturalDuration.TimeSpan.TotalSeconds
    $Global:displayPlayer.CurrentSoundTrackNumber = ($playlistPlayer | ForEach-Object { $_.FullName }).IndexOf($player.Source.OriginalString) + 1
    $Global:displayPlayer.CurrentSoundVolume = $Global:player.Volume
    $Global:displayPlayer.NextSoundPath = $playlistPlayer[$Global:displayPlayer.CurrentSoundTrackNumber].FullName
    $Global:displayPlayer.PreviewSoundPath = $playlistPlayer[$Global:displayPlayer.CurrentSoundTrackNumber - 2].FullName
}

function Update-DisplayPlayer {
    Get-DisplayInformation

    Write-Host `n

    Write-Host "Pista actual: $($Global:displayPlayer.CurrentSoundPath)"
    Write-Host "Número de la pista: $($Global:displayPlayer.CurrentSoundTrackNumber)"
    Write-Host ("Tiempo transcurrido: {0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds([double]$Global:displayPlayer.CurrentSoundTime))
    Write-Host ("Tiempo total: {0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds([double]$Global:displayPlayer.CurrentSoundTotalTime))
    Write-Host "Volumen actual: $($Global:displayPlayer.CurrentSoundVolume * 100)%"

    $Global:displayPlayer.Status = "Parado"
    if ($Global:player.Position.Ticks -ne 0) {
        $Global:displayPlayer.Status = "Reproduciendo"
    }
    Write-Host "Estado actual: $($Global:displayPlayer.Status)"
    
    Write-Host `n
    Write-Host ('-' * 40)
    Write-Host ("Opciones disponibles:`n    " + ($featuresPlayer -join "`n    "))
    Write-Host `n
    Write-Host "Ctrl + C para salir del bucle"

    Write-Host `n
}

function Show-DisplayPlayer {
    $duracion = -1

    Update-DisplayPlayer

    while ($Global:displayPlayer.CurrentSoundTime -lt $Global:displayPlayer.CurrentSoundTotalTime) {
        $duracionAtual = [int][math]::Floor((Get-PlaybackTime))

        if ($duracionAtual -ne $duracion) {
            Clear-Host
            Update-DisplayPlayer
            $duracion = $duracionAtual
        }
    }
}

function Invoke-Player {
    $PlayNext = $true
    while ($PlayNext) {
        Clear-Host

        if (-not $Global:player.naturalDuration.HasTimeSpan) {
            Start-SongByIndex -index 1
        } elseif ($Global:player.Position.Ticks -eq 0) {
            Start-Player
        } else {
            Start-Player
        }

        if (-not (Wait-StartPlayback)) {
            throw 'La reproducción no pudo iniciarse'
        }


        Show-DisplayPlayer

        $PlayNext = $false
        if ($Global:displayPlayer.NextSoundPath) {
            Start-NextSong
            if (-not (Wait-StartPlayback)) {
                throw 'La reproducción no pudo iniciarse'
            }

            $PlayNext = $true
        }
    }
}

function Add-MusicToPlaylist {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$MusicPath,

        [Parameter(Position = 1)]
        [string]$Filter = '*.mp3'
    )

    $Global:playlistPlayer += Get-ChildItem -Path "$MusicPath" -Filter $Filter   
}

if ($player) {
    $Global:player.Close()
    $Global:player = $null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

$player = New-Object System.Windows.Media.MediaPlayer

Resize-Volume -volume 1.0

$displayPlayer = [PSCustomObject]@{
    CurrentSoundPath = $null
    CurrentSoundTime = $null
    CurrentSoundTotalTime = $null
    CurrentSoundTrackNumber = $null
    CurrentSoundVolume = $null
    NextSoundPath = $null
    PreviewSoundPath = $null
    Status = $null
}

$featuresPlayer = @(
    "Invoke-Player",
    "Start-Song [[-song] <string>]",
    "Start-SongByIndex [[-index] <int>]",
    "Start-NextSong",
    "Start-PreviewSong",
    "Start-Player",
    "Suspend-Player",
    "Stop-Player",
    "Add-MusicToPlaylist [-MusicPath] <string> [[-Filter] <string>]",
    "Resize-Volume [[-volume] <double>]"
)

$playlistPlayer = Get-ChildItem -Path "$MusicPath" -Filter $Filter

if (-not $playlistPlayer) {
    throw 'No hay archivos en este camino'
}

Invoke-Player
