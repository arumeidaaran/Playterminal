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
    
    $CurrentIndex = ($Global:playlistPlayer | ForEach-Object { $_.FullName }).IndexOf($player.Source.OriginalString)
    $songIndex = $CurrentIndex - 1
    $song = $Global:playlistPlayer[$songIndex].FullName

    return [string] $song
}

function Get-NextSong {
    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    $CurrentIndex = ($Global:playlistPlayer | ForEach-Object { $_.FullName }).IndexOf($player.Source.OriginalString)
    $songIndex = $CurrentIndex + 1
    $song = $Global:playlistPlayer[$songIndex].FullName

    return [string] $song
}

function Get-SongByIndex {
    param (
        [int] $index
    )

    if ($null -eq $Global:player) {
        throw 'Player no definido'
    }

    $song = $Global:playlistPlayer[$index-1].FullName
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

    $Global:displayPlayer.CurrentsongPath = $Global:player.Source.OriginalString
    $Global:displayPlayer.CurrentsongTime = Get-PlaybackTime
    $Global:displayPlayer.CurrentsongTotalTime = $Global:player.NaturalDuration.TimeSpan.TotalSeconds
    $Global:displayPlayer.CurrentsongTrackNumber = ($Global:playlistPlayer | ForEach-Object { $_.FullName }).IndexOf($player.Source.OriginalString) + 1
    $Global:displayPlayer.CurrentsongVolume = $Global:player.Volume
    $Global:displayPlayer.NextsongPath = $Global:playlistPlayer[$Global:displayPlayer.CurrentsongTrackNumber].FullName
    $Global:displayPlayer.PreviewsongPath = $Global:playlistPlayer[$Global:displayPlayer.CurrentsongTrackNumber - 2].FullName
}

function Update-DisplayPlayer {
    Get-DisplayInformation

    Write-Host `n

    Write-Host "Pista actual: $($Global:displayPlayer.CurrentsongPath)"
    Write-Host "Número de la pista: $($Global:displayPlayer.CurrentsongTrackNumber)"
    Write-Host ("Tiempo transcurrido: {0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds([double]$Global:displayPlayer.CurrentsongTime))
    Write-Host ("Tiempo total: {0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds([double]$Global:displayPlayer.CurrentsongTotalTime))
    Write-Host "Volumen actual: $($Global:displayPlayer.CurrentsongVolume * 100)%"

    $Global:displayPlayer.Status = "Parado"
    if ($Global:player.Position.Ticks -ne 0) {
        $Global:displayPlayer.Status = "Reproduciendo"
    }
    Write-Host "Estado actual: $($Global:displayPlayer.Status)"
    Write-Host `n

    Write-Host ('-' * 40)
    Write-Host "Playlist: "
    Show-Playlist
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

    while ($Global:displayPlayer.CurrentsongTime -lt $Global:displayPlayer.CurrentsongTotalTime) {
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
        if ($Global:displayPlayer.NextsongPath) {
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

function Show-Playlist {
    $songIndex = $($Global:displayPlayer.CurrentsongTrackNumber - 1)
    $playlist = Get-Playlist -songIndex $songIndex -offsetsong 10

    $defaultBackgroundColor = [Console]::BackgroundColor
    $defaultForegroundColor = [Console]::ForegroundColor
    $halfOffset = [System.Math]::Round($($songIndex / 2))
    $startIndexsong = $halfOffset
    $internalTotal = $startIndexsong + $offsetsong
    $internalIndex = 0
    while ($startIndexsong -lt $internalTotal) {
        $backgroundColor = $defaultBackgroundColor
        $forekgroundColor = $defaultForegroundColor

        if($startIndexsong -eq $songIndex) {
            $backgroundColor = 'green'
            $forekgroundColor = 'black'
        }

        Write-Host $playlist[$internalIndex].FullName `
            -BackgroundColor $backgroundColor `
            -ForegroundColor $forekgroundColor

        $startIndexsong++
        $internalIndex++
    }
}

function Get-Playlist {
    param(
        [int] $songIndex,
        [int] $offsetsong
    )

    if ($null -eq $Global:playlistPlayer) {
        throw 'Playlist no definido'
    }

    if ($offsetsong -le 0) {
        throw 'El límite no puede ser igual o menos de cero'
    }

    $startIndexsong = 0
    $endIndexsong = $offsetsong
    $halfOffset = [System.Math]::Round($($songIndex / 2))
    $startIndexsong = $halfOffset
    $endIndexsong = $startIndexsong + $offsetsong

    if ($endIndexsong -gt $Global:playlistPlayer.Length) {
        $endIndexsong = $Global:playlistPlayer.Length
    }

    return $Global:playlistPlayer[$startIndexsong..$endIndexsong]
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
    CurrentsongPath = $null
    CurrentsongTime = $null
    CurrentsongTotalTime = $null
    CurrentsongTrackNumber = $null
    CurrentsongVolume = $null
    NextsongPath = $null
    PreviewsongPath = $null
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
    "Show-Playlist",
    "Resize-Volume [[-volume] <double>]"
)

$playlistPlayer = Get-ChildItem -Path "$MusicPath" -Filter $Filter

if (-not $Global:playlistPlayer) {
    throw 'No hay archivos en este camino'
}

Invoke-Player
