<# Hide PowerShell Console
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)
#>
#====================================================================================================
# Libraries

Add-Type -AssemblyName System.Windows.Forms, System.Drawing, Microsoft.VisualBasic

#====================================================================================================
# Declarations

# Constants
$version = 'v0.24'
$path = "$env:userprofile\Desktop"

[System.Collections.ArrayList]$colorLetters = [char[]]('a'[0]..'p'[0])
[void]$colorLetters.add([char]'z')

[System.Collections.ArrayList]$colorNames = [Enum]::GetValues( [ConsoleColor] )
[void]$colorNames.Add('Transparent')

$colorsArgb = [ordered]@{
    0 = '0, 0, 0'
    1 = '0, 0, 128'
    2 = '0, 128, 0'
    3 = '0, 128, 128'
    4 = '128, 0, 0'
    5 = '128, 0, 128'
    6 = '128, 128, 0'
    7 = '192, 192, 192'
    8 = '128, 128, 128'
    9 = '0, 0, 255'
    10 = '0, 255, 0'
    11 = '0, 255, 255'
    12 = '255, 0, 0'
    13 = '255, 0, 255'
    14 = '255, 255, 0'
    15 = '255, 255, 255'
    16 = '0, 0, 0, 0'
}
#----------------------------------------------------------------------------------------------------
$toolTip = New-Object System.Windows.Forms.ToolTip

[string]$lang = $host.CurrentCulture

$translate = [ordered]@{
    'en-US' = @{
        Pencil = 'Pencil Color'
        Position = 'Position'
        Color = 'Color'
        Background = 'Background'
        Select = 'Select'
        Move = 'Move'
        Clear = 'Clear'
        PrintScreen = 'Print Screen'
        Open = 'Open'
        Save = 'Save'
        SelectMsg = 'Select function not implemented'
        MoveMsg = 'Move function not implemented'
        ClearMsg = 'Do you really want to clear the screen?'
        Error = 'Error'
        ErrorMsg = 'Operation canceled'
        ImageMsg = 'Image not found'
        Image = 'Image'
        ImageName = 'Image Name'
        SaveMsg = 'Please enter the image name to save:'
        Info = 'There are no pixels to save'
        Black = 'Black'; DarkBlue = 'Dark Blue'; DarkGreen = 'Dark Green'; DarkCyan = 'Dark Cyan'; DarkRed = 'Dark Red'; DarkMagenta = 'Dark Magenta'; DarkYellow = 'Dark Yellow'; Gray = 'Gray'; DarkGray = 'Dark Gray'; Blue = 'Blue'; Green = 'Green'; Cyan = 'Cyan'; Red = 'Red'; Magenta = 'Magenta'; Yellow = 'Yellow'; White = 'White'; Transparent = 'Transparent'
    }
    'pt-BR' = @{
        Pencil = 'Cor do Lápis'
        Position = 'Posição'
        Color = 'Cor'
        Background = 'Plano de Fundo'
        Select = 'Selecionar'
        Move = 'Mover'
        Clear = 'Limpar'
        PrintScreen = 'Captura de Tela'
        Open = 'Abrir'
        Save = 'Salvar'
        SelectMsg = 'Função selecionar não implementada'
        MoveMsg = 'Função mover não implementada'
        ClearMsg = 'Você realmente quer limpar a tela?'
        Error = 'Erro'
        ErrorMsg = 'Operação cancelada'
        ImageMsg = 'Imagem não encontrada'
        Image = 'Imagem'
        ImageName = 'Nome da Imagem'
        SaveMsg = 'Por favor, entre com o nome da imagem para salvar:'
        Info = 'Não há pixels para salvar'
        Black = 'Preto'; DarkBlue = 'Azul Escuro'; DarkGreen = 'Verde Escuro'; DarkCyan = 'Ciano Escuro'; DarkRed = 'Vermelho Escuro'; DarkMagenta = 'Roxo'; DarkYellow = 'Amarelo Escuro'; Gray = 'Cinza'; DarkGray = 'Cinza Escuro'; Blue = 'Azul'; Green = 'Verde'; Cyan = 'Ciano'; Red = 'Vermelho'; Magenta = 'Magenta'; Yellow = 'Amarelo'; White = 'Branco'; Transparent = 'Transparente'
    }
}

if ( !$translate.Contains( $lang ) ) { $lang = 'en-US'}

#----------------------------------------------------------------------------------------------------
# Global variables

$Global:pencilColor = 15
$Global:backgroundColor = 0
#----------------------------------------------------------------------------------------------------
$Global:brush = new-object Drawing.SolidBrush $colorsArgb.$Global:pencilColor
$Global:pen = new-object System.Drawing.Pen red, 1
#$Global:pen.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Inset
#----------------------------------------------------------------------------------------------------
$Global:screenPixel = [ordered]@{}
0..49 | ForEach-Object {
    $y = $_

    0..79 | ForEach-Object {
        $x = $_
        $Global:screenPixel["$x,$y"] = 16
    }
}

$Global:rectangle = @{}
#----------------------------------------------------------------------------------------------------
$Global:x = 0
$Global:y = 0
$Global:xPos = 0
$Global:yPos = 0
$Global:cursorPosition = "0"

#====================================================================================================
# Images

$iconBase64        = 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7
                      OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAU1QTFRFAAAAZG
                      RzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZGRzZ
                      GRzZGRzZGRzZGRzZGRzZWNyZWNxX2d5VW+FT3SOVm6DNIauGJvRCqbiBanoNYeuV26DY2V1Pn6gFqTc
                      C7HxAK7xAK3wAK3vAK7wD6LcP3+gNIatGLDrneH6wOv7RMPzAKzvBarqNYatAanqO8H08/v+////3vT
                      9RcPzEKLcE7PwsOb6HbbxtOf6Vm+Fs+f6OsDzAKvvOr/y6vj+gtf3HLbx/v//3/X9PMDzseb64PX9R8
                      TzBK7vEbPwErPwDLHwruX6DLDwkdz40fD8v+r7O8DzSMTzLLvyg9j5DaHcA6rqFLTxoOH5wuv7RsPzD
                      bHwv+v8P73uPX6gBKrqB7DxBq7vEbTyD67rDqHcP36g8b0oJwAAABl0Uk5TAAAl3nsBJBsCC0fcRNiY
                      cbry3ddyDPF6/fzDOWMAAAABYktHRDs5DvRsAAAACXBIWXMAAAsSAAALEgHS3X78AAABoklEQVQ4y4W
                      T51uCUBTGuaG49wRHqWglqC20vGWWZWWZpVa29x7//8e4lyXmE+cb9/1x9iEIzcAESYtGTgBirAFgor
                      GZwCgBzJTFCmx2hwQ47DZgtVBmoP3qdLncHq+Pls3n9bhdLqfiSNT99Bjzy4ROZ2IxZpQAVEBRmXgim
                      UzEGYUJUBiwyAAzOZVKZzLpFJuViYAFA2Y3/spNz8zmOZ7n8oViKYef3LgQAIJYn5tfWFwSeGSFcgUT
                      QSmHkBf5Ly2vVOHqmkRw5RKK4g0B5MAeFvVsjVuvQ5Uo1FAeYbvogoqgIhm2wAsbm0MEi1z4IxRBRlG
                      0eCrP64h8Ko7eoyQhVdhIi/mLxJZIbCOCSzekWiUglsxgx82dXQj3sItMMvYXEFr1fXjQHgNIIYTWIY
                      SdI6xrIbQkZf242+v1h5LUyuydIP30bDAYnF9waplao9pV2LlsXolpQnh9ozZKbfXt3f3Do8A/IQ/PL
                      69qq9VhVd7e+yi9j27v80s3LGXcpSInjZv7/tGNW12YLDt+YQxXzmhpDdfe+HCMT8/4eP87/18/xWtG
                      K3cDlgAAABZ0RVh0Q3JlYXRpb24gVGltZQAwMi8yNS8yMYFtBw8AAAAldEVYdGRhdGU6Y3JlYXRlADI
                      wMjEtMDMtMDJUMTU6Mjg6MTQtMDU6MDAtuz0KAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIxLTAzLTAyVD
                      E1OjI4OjE0LTA1OjAwXOaFtgAAABx0RVh0U29mdHdhcmUAQWRvYmUgRmlyZXdvcmtzIENTNui8sowAA
                      AAASUVORK5CYII='
#----------------------------------------------------------------------------------------------------
$backgroundBase64  = 'iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAA
                      KwwAACsMBNCkkqwAAABZ0RVh0Q3JlYXRpb24gVGltZQAwNS8wNi8yMSy/xQ8AAAAcdEVYdFNvZnR3YX
                      JlAEFkb2JlIEZpcmV3b3JrcyBDUzbovLKMAAAFxklEQVRoge2Zy2sTWxzHf/PIzDSZOySpNmp9RkGQS
                      sFi242W4ra40EIX4soHyKWicIPgUqy4KPRuig+0xhcMlSI+sP4P8W6sttZXaTaWNrGxic0kJPO9C++M
                      mU7SPNqYW/ALBzLn/Oac7+fMOWfOnDAAaC2LrbWBleo3QM0FIG+SZfmcIAgzRIRfnQRBmJFl+Vwhb7n
                      JltHc3CwIgjDEMEyiFuaNxDBMQhCEoebmZqEsAIfDMVRL40uTw+EYWg6Azx1OiqL8mclkjufm8TxPLF
                      t8qjAMQwzDENHPTqlEuq5TJpMxrzOZzHFFUf5ZWFgYzNtubkOiKM6n02m3cd3f3089PT3EcVzBBjmOI
                      0VRiIgomUwSx3FUV1dH379/p2QyWTZANpslVVUpEAiYeYIgxFKplKcoAMMw5oUkSRSJRMjlchVtdGRk
                      hEZGRmhqaoqcTif5fD7q7u6mI0eOlA1ARJRIJGj9+vWkaZqZB4DJG2yZEDljT5ZlRCIRLKf5+Xl0dnY
                      WmoQ4dOgQYrHYsnXkUyQSgSzLlvpKmsS5N7hcLszNzRVsRNd1dHR0FJ2EnZ2dZQPMzc3B5XJVF0BVVZ
                      vZpqYmNDQ02J7E8PBw1QAqfhM/ePDA/M3zPA0PD9PY2BhNTk6SqqrmxAdA9+/fr7SZ4qr0CTQ1NZmxL
                      S0tljJd17Fv3z6zfO/evf+/JyBJkvk7EolYyhiGseTlxq62+OIh+dXW1kavXr0iIqLp6Wk6fPgw9fb2
                      0qdPn2h0dJTC4bAZ29raark3kUjQxMQE6bpOu3fvJrfbTRWr0iE0Pj5e8nZgfHzcvK+vrw8+n88s83g
                      8CAQC0HW9oiFUMQAADAwMFDU/MDBgxt+5c6dgXFdXF7LZLABgdnb21wAAP5bTnTt32gzt2rULqqqacc
                      FgECdPnlwWtqurCwAQj8fhdDqrD5DNZpFOpxGNRhEKhXDv3j08fPgQk5OTlrgTJ07YzJ49exYXL1605
                      Xd3dyMej8PtdlcPIJlM4sKFC/D7/XA6nWhsbMSZM2fybhtOnTplM3n16lWz/Pbt27bygwcPor6+vjoA
                      sVgM+/fvzzsEPB4PQqGQGXv69GlbzJUrV2x13rp1yxbHsixYll1dgG/fvqGlpWXZcawoCkKhEM6fP28
                      r6+vry/tEAeDmzZu2eJ7n8d8OeeUACwsLtp7nOA7Hjh3Dpk2bLPlGo7np8uXLBc0bunHjRl4IjuMqA5
                      idnTXNt7a2Wip2OBx4+fIlACAcDsPv99sgjCFw6dKlouYNXb9+3QZREYDT6cTi4iIWFxfR1tZm6xXDv
                      KFwOIwdO3bYGu/t7S3ZvKHBwUHL+K9oCHm9Xnz58gUHDhyw9cbo6GjehsPhMLZt22aJ9/v9eP36dVkA
                      mqat/EXm8XiwZ88e28rw4sWLZRufnp7G1q1bsbQzyoFY8VaCZVnbRGRZFs+fPy/JwNTUlA2ivr4eY2N
                      j1QdgWRY8z9vMP3v2rNQONCG2bNliqWfdunV48+ZN9QCMJWvpavLkyZOyzBv6/PkzNm/ebIN4+/ZtdQ
                      CWznyGYfD48eOKzBv6+PGj7T3R0NCAiYmJ1QdYuto8evRoReYNffjwwQbh8/kKQqwKgCzL0DRtVQAMi
                      I0bN9og3r17Z4tdlXMhSZKQSCRWDQD4scRu377dYmzDhg14//69JS4ej0OSpJIALN/EoijGU6nUH0RE
                      mqbRtWvXqKenh3i+4k9nixRFoWAwSEePHqVoNEpERDMzM9TR0UFPnz6lxsZGymQypKqq5VhRFMV4oTo
                      tZ6Ner/dcLBbrB2Ce5pZ6Ol2q6urqSNM0SqVSecvS6TRls9mfBhkm63a7//r69evfeStc+khEUbxLS/
                      YztUyiKN4tNHxscwAAtbe3i6IoBlmWrck/NBzHgeM4sCybEEUx2N7eLpYFYCSPxxOQJGmuFhAulyvq9
                      XoDyxk3kmUOrEWt+b9ZfwPUWr8Baq01D/AvxMS1/NyCPQgAAAAASUVORK5CYII='
#----------------------------------------------------------------------------------------------------
$selectBase64      = 'iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAA
                      KwwAACsMBNCkkqwAAABZ0RVh0Q3JlYXRpb24gVGltZQAwNS8wNi8yMSy/xQ8AAAAcdEVYdFNvZnR3YX
                      JlAEFkb2JlIEZpcmV3b3JrcyBDUzbovLKMAAAD7klEQVRoge1ZP28iORR/BvMMIkZ3RCRVPgBISEjbo
                      DQp8iGotthVipXSbBPlehbpEkXKNqtsEe0W1/A1oKI5KToptBRJsYEkF8GMAp4ZfFW84/lDZrPJsOj4
                      SZZsv+eZ92w/v+dnIqWERUZi3gL8LJYKzBuhCnDO3zPGvhFCpLu0Wi0JABIAZL1el156sVhUdACQxWL
                      Rx1Ov1xW91Wr56Iyxb5zz909SoFKpIGPsi2maH4QQ60+alp+EEGLdNM0PjLEvlUoFZ/FSb0e32/1sWd
                      absAHuU2s6nfrojuPMbHvHhZ2CUsqsEOJNt9sFAHgbJo+mQC6X27Vt+7XGQCkkEt8XKplMqnoqlQJEf
                      YLS6bSv7eVJpVLa99z06XQKtm2rtm3br3O53N/D4fBTkALEPQOMsX+FEL89tI+OjqBWq2lCr66uqh8a
                      hgGj0Uj7IKUUCoWCag8GA00gAADOOaysrAAAgBACbm5uFM1xHGg2m7C3t6f6EPFuMpn8/qgChBDVSKf
                      TcH19DdlsNmjci8IwDCgUCjAej1WflJIE8c48Rt0fiBOTyQQICZTXB80G3IMopaEG9tKQUkIymYykhK
                      ZAr9dTdUII5PP555cuAvL5PJyfn0eaQOJh+pUjux+3gUWAtoV2dnZUnTEGBwcH6riLE4ZhwP7+PkwmE
                      9V3enoayBt6jAIAXF1dwdra2guJGY5+vw/r63oU88PHaDab1TxwnEgkEpH9z8LbQKgCpmnO1Q+YphmJ
                      VzPizc1NVc9kMr4gLC4gImxvb8P9/f2jvEs/MG9oW8gb9lLqu+/EhqiyaFtoY2NDNTKZDHQ6nbnEQ7e
                      3t1CtVjUbuLi4CNxCmlqXl5ffCZQGXgfjgOM40Ov1fKsQhFAbYIxFjsmfG4QQYIxF4l14I57pyIKyDn
                      FgOp0+zZEdHh6qeiqVAs7580oWEZxzOD4+BsuyHuVdOrJ5Q9tCrVZL1ROJBFSrVS0JFRcsy4JOp6PZ4
                      NbWViDvzAtNv9/XklRxYTAY+C5S/78LjeM4vjxnXGCMRY4CNBtAxLuH3Oh4PIaTkxOo1WpaIPXSuVHb
                      tqHZbGpZQUS8C9VASqkK53yXEGKB64GCUioRUZV2uy0f0Gg0NBoiynK5LN0ol8s+nkajoejtdlujUUq
                      1BxJCiMU533XL6S7aCgyHw0+I+Mr9PuCdPffSWpYFQgiN7s2njsdjH4/bQTmO46O7QSn9Kyy1DhBgA6
                      VS6R0ifiWEBPpyd4AXZOTuVHxQ2zsuLGAkhJiI+LVUKr0LEx4g4IXm7OxMAMBbzvk/Qog/5vHMhIhXi
                      PjnaDT6+BivN5RYOCx8KLFUYN5YKjBvLLwC/wEKpwqS4D0d6AAAAABJRU5ErkJggg=='
#----------------------------------------------------------------------------------------------------
$moveBase64        = 'iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAA
                      KwwAACsMBNCkkqwAAABZ0RVh0Q3JlYXRpb24gVGltZQAwNS8wNi8yMSy/xQ8AAAAcdEVYdFNvZnR3YX
                      JlAEFkb2JlIEZpcmV3b3JrcyBDUzbovLKMAAADeUlEQVRoge2YT2gUVxzHP7/JzlvXJhuC2JO2h4Lxk
                      EMr2CKCoJRKDwo99SA9JAc9ClpbesglUMifpiClXkQSVIgVPHjpzX8g1qOBlN5UEA9J1MAuJZlNMr8e
                      diLjOjM7b3cmS2G/8GD/vN/7fT/ze+/NvBFV5f8sp9MG2lUXIE4iclpE/hWR23nlAEBVM2/AEeAVoMA
                      68HseeVQ1GQD4HDjaAsCfgflwu7atAMBvoeR3gZ0WALMRAApc3RYA4GBE8kfABykB9gDPYyAyrUScga
                      Mxyf+ygPg4AeJ63gBuMG2ikj8Cei0gnuUJkZS8BDzIoBIfJUBcyg0gJUTaSsRBbAL9uQEEyXdkVIm9w
                      NOG+CVgR64AIYj7MRBnUierQ8wHcW+AE7lOoQiIexEAZ60SQg/wGbC7XfNWAEHyInAnZP4fYFcWRlpt
                      EhhLLRFxgFPBAr+hqpWt//r6+g7XarUva7Va2WrQkIwxFWPMnWq1+jBVQBZXYWhoyLiue0NEotaIdRM
                      RdV335uDgYDHTKRTXjDF/ZGG8sRljrrQ0hUTkEFBV1YVmFezv7/+iWq0+Do/jui6OY3/U8H2f9fX1sI
                      +N3t7es5VK5VJcTKHB+IfAZeBk8H1cVX9KSrq2tvZV2PzY2BgjIyMUCoWEqGhtbGwwMzPD6OgoAKpa8
                      DzvZyAWoHGXWeD9Uk422ZnGt/o6jqOLi4vajpaXl7Wnp+cdD0n5G+u8L4LxgohMJlw4f+uDiOB5XtJF
                      birP86ymX2PP48CLiH4XRGQqzYBRa8pGtvHvAKjqPeBrYCWi7/ciMt26tXz0Xq1U9W/gGNEQ50Tkl9x
                      dWShysqnqE+oQbyL+Pi8i47m6slDsamkC8aOI7M/NlYUSl7uqzhM/nUq5OLJU0/0qBLEU+vkW9ef6ji
                      vV7VJVn4jIAeBb4JWqXs3XVnqlvt+r6kvg1xy9tKTu2+lOK3MAEdnW+CwA3o7h+z7FYrGtwYwxbG5up
                      u5v/9DeoGKxWNl6AlVVJiYmGB4ebvk8MDs7i++/fcDFGLOUENL+kbJcLn+a1Vm4sYmIVy6Xv0s8j7QL
                      oPUz8eU8AIwxF5vlzgRAVcUYM+U4zmvqB5x2jPuO47w2xkzPzc1Js9zW74WSNDAw8M3q6uoPwCet7Ea
                      Bl6elUmlqZWXlVpqYTAE6oe6NrNPqAnRaXYBO6z9ccYLJxmo69wAAAABJRU5ErkJggg=='
#----------------------------------------------------------------------------------------------------
$clearBase64       = 'iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAA
                      KwwAACsMBNCkkqwAAABZ0RVh0Q3JlYXRpb24gVGltZQAwNS8wNi8yMSy/xQ8AAAAcdEVYdFNvZnR3YX
                      JlAEFkb2JlIEZpcmV3b3JrcyBDUzbovLKMAAAEH0lEQVRoge1YvU8bSRR/M7vjXc/a2JJtkAsDgoCSg
                      jsJWRcpBTUt5UlQ3N+BotMpbWqnu7MU6a6IZCsdNd014ITirgG5iRSxUMBqv7x45hrs7LfXXvscS/yk
                      V8zMe29+z7Pz3vMgzjksMvC8CaTFUwDzxlQC2NraWqGUfhBFsYcQ4n4RRbFHKf2wvb29Mo39POCcp5J
                      cLvdKEIQOQugBAHiUIIQeBEHo5HK5V2n3dEsq42Kx+AxjbMYR9wvG2CwWi8++iwAymcx7P0FFUQLi18
                      lkMu/nHkC9XscY4+6A1NraGu90OlxV1YCcn5/z1dVV9yl06/U6nmsAGGMCAF8GpI6OjngcDg8P3afwB
                      WNMphHAxFmIMUYAYJhVEEKx+hh7tlp5tE+NqdUBzuNbklHrkyJNAA4AfJ3Q9uujfWo8VeJ5Y+IAOOcO
                      ALAJzdmjfWqIcYuFQuG5pmk04gKKACBNuK+EEPoJAB78CwghyOfzxt3d3b9JHIUGoCjKz7Ztv2aMvZh
                      R9lgGgL/DFjjnoGkaiKL4jyRJb3Rd/yvOUSAASukvlmX9Pqu0lwScc+j3+y9M0/yTUiobhvFHlK7nDp
                      TL5Ze2bb+dhLymaanWw8A5B9u235bL5ZdROshNNpvNfrIs64fBeH9/Hw4ODoCQ0UVzc3MT9vb2ItdPT
                      0/h8vJypB/HcaDdbsPJyclwTpblz6Zp/hhq4O4rEELDfoUQwlVVje1vZgVVVbkoiu7/Epwn6YXcpyFJ
                      kr9/+d+AMQZZlodjHvNJRzLknANjk6b5dGCMJe6dIgNACEGpVJoaqXFQKpVGdrcDRBayXq8Hx8fHoCj
                      K1Iglha7r0Ov1Eul6stDjJf4uwTkPPZKFb+YiPyGMMezu7iaqAdOG4zhwdnaWKIlEfkKKosD19TVQSm
                      fDMgaGYcDy8jLouj6cm+gTMk1zytSSYZx9YwNImounjXH2jf0/4IaqqtDtdj1zGxsbgVpxcXEBlmUNx
                      7Isw87Ojkfn9vYWrq6uPHPr6+tQqVSS0vkGd18Bvhc2dy/UaDQCL2zNZjPQx9RqNY9OrVYL6DSbzYCv
                      RqPh6YX8L3qJeiE/3NVQFIOHJQhCYE6SpNhxlJ3bP0IocSWODIAx5mmowjYNm/M3gGEN4ShfkiRBv9+
                      Poub17x4QQobX3zRNaLfbYBgGWJbl+a4HGMy7xZ+7GWOhelG+DMOAVqvlyURuXn546kA+n3+t6/pv7p
                      xbqVQAYwymacL9/b3HeGlpCbLZrGfu5ubG8+sJggDlctmjE+eLMQaqqn4jiBBXFOVXTdPehEbgvxSEk
                      BaM8d4/ayGEtKIuMA97na5WqwVCyEeEkD1P4gghmxDysVqtFsYKYCCU0ncYY2ce5DHGDqX0XRzxgXju
                      wCJi4dvppwDmjacA5o2FD+A/ypiWjrETtQIAAAAASUVORK5CYII='
#----------------------------------------------------------------------------------------------------
$printScreenBase64 = 'iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAA
                      KwwAACsMBNCkkqwAAABZ0RVh0Q3JlYXRpb24gVGltZQAwNS8wNi8yMSy/xQ8AAAAcdEVYdFNvZnR3YX
                      JlAEFkb2JlIEZpcmV3b3JrcyBDUzbovLKMAAAEnklEQVRoge1Yz0srVxQ+996ZG5OMQwQTYgVTlEcWL
                      mKeoELBGiH5D4JddmuLIrjousHN23VT7EqEbmwCWcZ/QRdK4JFVYZAu6gvJ8GQyxphfpxvfdCbJJJO8
                      F+MDPzgwN3PmnO+be+69J0MQEb5m0EkT+Fy8Cpg0nkWALMs/uVyufwkh2GmUUpyamvp7ZmZmZ6TgiDg
                      229raEkRR/IMQogEA9rE2pVTlnB8Nm2OsAjjnfw4g3mUulyv1IgTIshwlhFjICYKAnHOLUUotPpTSxu
                      zs7DdO84xtDdRqtbj5jDk6OgJFUeDm5sZiiqLA7u6uuaQFXde/c5xoXDMAAL/C01tljKGqqmiHfD7fW
                      Uo/TnwGAKD96YJSCrVazdax0WjYPjsIz3YOmMtpmHuD8HqQ9YGlDBhjto497jkuIWGQg8fjIQ8PD07j
                      mWFh1Wg0oN3uzatzDTDGHAsgverP7/d/q2naL61W6/tWq+V2GqwDvicDQgjMz8/bzkK9Xofb21tjzBj
                      7hzGWk2X5XalUuumbpXNbmp6efssY+whDnqDjMMbYx+np6beOT+JQKDTLGHs/aeIdIt6HQqFZOwGWEv
                      J6vWfVatXoCv1+P6yvr4MgDFwqFhBCgBBiPtQco9lswuXlJZRKJeM3j8fz1/39/Q89HzCrYYyZexK8v
                      r62PT3HiaurKzT3UYwxtJsBy6tttVrGtdvthsXFxaHe3sXFBWQyGbi6ugJN00CWZVhdXYVkMgkbGxuO
                      4ywtLYHb7YZqtdrFqwtmNWCqPa/Xi6VSydEbU1UVk8lk31pOJpN9+yEzSqUSer1ey/N2M/DZAorFIob
                      DYUcLMhwOY7FYfFkCNjc3u4jOzc1hJBLBYDDYdW9zc/PlCEin05YkHo8HT09PsVqtIiJitVrF09NT9H
                      g8Fr90Ov0yBMRiMUuS8/Pznn65XM7iF4vFJi+gUqmgz+cz/Le3t/uS2traMnx9Ph9WKpUvImDkblRVV
                      dA0zRivra319V9fXzeuNU0DVVVHTW3ByAJEUbQ0Z7qu9/U332eMgSiKo6a2YGQBgUAAgsGgMc7lcn39
                      z8/PjetgMAiBQGDU1BaMLEAQBIjH48ZYURTY39/v6bu3tweKohjjeDw+dH9li1EXMSJioVDo2ucTiQR
                      mMhm8uLjATCaDiUSiy6dQKPSN+6wHWSqVGqo9TqVSA2M+qwBExMPDQ0fkDw8PHcX7IgIkScJyuewoIS
                      JiNpvFaDTak3g0GsVsNus4VrlcRkmSHAmw/KF56sEBAGBqagrK5TJ4vd6h1lShUIB8Pg93d3fg8/lgZ
                      WUFlpeXh4qh6zr4/X7LxzBEJL18LVsB5/yuXq/7AABqtRocHx/Dzs6O4x2DUgoLCwvw5s0boJRCu92G
                      x8dHKBaLtl8kOtFsNuHs7MxCnnN+Z+dvmQFZln/Wdf03RDQYC4IAlD7f9692uw3NZvN/goQ0JUk60DT
                      t954PdNaUKIonMMSuMm4TRfHErv67FjEiQiQS4ZzzE0KIPknihBCdc34SiUT4UAI+mSRJB5zzD5Mgzz
                      n/IEnSQT/iPXehrxGvX6cnjVcBk8argEnjP2Jt493xY30kAAAAAElFTkSuQmCC'
#----------------------------------------------------------------------------------------------------
$openBase64        = 'iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAA
                      KwwAACsMBNCkkqwAAABZ0RVh0Q3JlYXRpb24gVGltZQAwNS8wNi8yMSy/xQ8AAAAcdEVYdFNvZnR3YX
                      JlAEFkb2JlIEZpcmV3b3JrcyBDUzbovLKMAAACvklEQVRoge2ZvU7jQBDHZ9a7ays4LpJUdClOVAhdk
                      Sp1qqOALqKhRHcN3aXKA1DlAaCPXBwPwiNcRZMTKIkORKTEseO55hxlgx1sh2Ph5J80hVf7Mf+d8a53
                      jUQEHxmm24FtKQTophCQBsdxvpmm+QsRKY2ZpnlXLpfP0/SNSavQ7u5u5eHh4fN0Oi3ldZxzDoyxL77
                      vnxBROUtbRJwIIdyDg4OvNzc3fmJFInpmlmV1GGO/EZEAIJchInHOc7ePTEp5GedjZHHOf9/G8cgMw6
                      C4fhhjGy1mIuaO45wlCVBSqFKptB4fH3+EYZgp3GnodrtwenoKnPON9YIggH6/D91ud1kmpRx7nleLq
                      68IsCzrp+d5n6Ln4+NjaLfbIISALDs2IoLruuC6LgAAGIYB9/f3UK1WU7WfTCZQq9XA87xlGRFhbGUl
                      HCsh55zTcDikvFxcXCz7EkLQYDBI3XY0GpFt20oqJaUQWxcTIYSAcjl/JoVhqPS7+vwSyxc0BbEJyRg
                      DIoLDw0MIgiD1wKvc3t6qA72Q+7lRlqS/q4RhGFuvQqu2v79Pi8UidQoNh0Pa2dnJnkKMMUBEWCwWrz
                      pJvV4PGPs3m74SV845+L666dXr9VzhR0TY29uDTqcDzWZzOy83oHgWhqHy8lxfX8PR0REgxq9g7wElr
                      qsvbKlUglar9a6dB9jwNYqIMJvN3tKXXBTnAd0UAnRTCNBNIUA3hQDdFAJ0UwjQzcbPaV1ngSxjJwoI
                      ggAsy3o1p7Jgmuazo20SypFSSjmez+dVAIDZbAa9Xm95M/dW+L4P/X5fuZWTUo4TG6xeUTiOc4aIc8h
                      4Ifuatj72S5e7zwqklJfrnei0zNfrjUZDSCmvEPFJp+OI+CSlvGo0GiKTgMhs2z6XUt5pmvU727bPNz
                      keWeIvpo/C/7uRfRQKAbopBOjmD6ASRrsQ4jPRAAAAAElFTkSuQmCC'
#----------------------------------------------------------------------------------------------------
$saveBase64        = 'iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAA
                      KwwAACsMBNCkkqwAAABZ0RVh0Q3JlYXRpb24gVGltZQAwNS8wNi8yMSy/xQ8AAAAcdEVYdFNvZnR3YX
                      JlAEFkb2JlIEZpcmV3b3JrcyBDUzbovLKMAAADFklEQVRoge2Zz0vjQBTH36SRyY+ik9KeLHrIyoK7I
                      L3J3jx4qmf/g70riPsP7GVhQfDuYZUV/CussHjQs17MTUTZKFqN0NpJ3p4aE23aiU03reQL79CXeW/e
                      Z4Z0MjMEEWGUJaVdQL8aeQBAxI7GGFunlF4DAA7CJElqaZr2e3FxUYuqQcReOSqVikop3ZYk6XFQxbe
                      NENKSZfkPY+xjYgCU0p1BF/7ScrncX8bY574BGGNrhBA3mFxVVdQ0LdGC8/l8JwjbMIzYEC9H3wkm3d
                      zcxKurKzw8PBQubnp6GqvVKlarVVxaWsKZmZnQc0opWpaFx8fHWC6XX0Ewxj69GSCYTFEUdBwHERHPz
                      s6EildVFc/PzzGoer2OhUIhlPfm5gYRES3LioIQnonIv1FZlqHRaAAAQKvVimoWkq7rUCqVQr7x8XFg
                      jIV87XymaUKtVoPJyUn/meu6xYeHh33DMD6J9BkJEJgVYSHiK1hEBM/zImNM04SDg4NOELVCodATYig
                      WsiiI+/v7fcMwPnSLHQoAgGeIcrns+1zXLTmO82tubk6LihsaAIDnd2Jqasr3cc6/WJb1PSomUQBCCB
                      BCevq6yTRN2N3dDfk451+j2icKwDkHXdc7+uNodnYWVFX1fz89PeWj2sqxMvfQ3d0drK6uwsLCgu87O
                      jqCi4uLWHk8z4NcLifWOGoh03UdbdtGRMSTk5PEPiMopXh5eYndZNs26roeiou9kAU1NjYmNhoCajab
                      IMvJTbxQJtM0YWNjA05PT/vucH5+HorFYt952hICkCQJVlZWEus0SQ3VOvAWZQBpKwNIWxlA2soA0lY
                      GkLYygLT1fgHibsaTVJy+IwE456AoSmJFxRGlVPggILShoZQ+NptNHQCg0WjA1tYWLC8vJ7oF7CXOOe
                      zt7fnnsu26otqT4PmnYRhr9Xr9ByL6M6MoivgJQQJyXTdUPCHEm5iY+HZ7e/uzY8Aw3NB0M0rpjvD9A
                      P7nO7JuJknSI6V0u1KpqLEA2jboW8oeo37NGFsXueAIvQOjqPe7kI2KMoC0NfIA/wBLf+7+pJYwMAAA'
#----------------------------------------------------------------------------------------------------
$backgroundImage = New-Object System.Drawing.Bitmap(640, 300)
$graphics = [System.Drawing.Graphics]::FromImage($backgroundImage)

$graphics.FillRectangle((new-object Drawing.SolidBrush 'white'), 0, 0, $backgroundImage.Width, $backgroundImage.Height)

0..24 | ForEach-Object {
    $y=$($_*6)

    0..39 | ForEach-Object {
        $x=$($_*8)
        $graphics.FillRectangle((new-object Drawing.SolidBrush 'gray'), $x*2, $y*2,8,6)
        $graphics.FillRectangle((new-object Drawing.SolidBrush 'gray'), ($x*2)+8, ($y*2)+6,8,6)
    }
}
#----------------------------------------------------------------------------------------------------
$transparentImage = New-Object System.Drawing.Bitmap(32, 32)
$graphics = [System.Drawing.Graphics]::FromImage($transparentImage)

$graphics.FillRectangle((new-object Drawing.SolidBrush 'gray'), 0, 0, 16, 16)
$graphics.FillRectangle((new-object Drawing.SolidBrush 'white'), 16, 0, 16, 16)
$graphics.FillRectangle((new-object Drawing.SolidBrush 'white'), 0, 16, 16, 16)
$graphics.FillRectangle((new-object Drawing.SolidBrush 'gray'), 16, 16, 16, 16)

#====================================================================================================
# Layout

$Form                        = New-Object system.Windows.Forms.Form
$Form.ClientSize             = '640,368'
$Form.text                   = "PowerPaint $version"
$Form.TopMost                = $false
$Form.MaximizeBox            = $false
$Form.FormBorderStyle        = 'Fixed3D'
$Form.StartPosition          = "CenterScreen"
$Form.BackColor              = 'LightGray'
$Form.BackgroundImage        = $backgroundImage
$Form.BackgroundImageLayout  = 'None'

$iconBytes                   = [Convert]::FromBase64String($iconBase64)
$stream                      = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
$Form.Icon                   = [Drawing.Icon]::FromHandle((New-Object Drawing.Bitmap -Argument $stream).GetHIcon())
#----------------------------------------------------------------------------------------------------
$backPanel                   = New-Object System.Windows.Forms.Panel
$backPanel.ClientSize        = '640,300'
$backPanel.BackColor         = $colorsArgb.$Global:backgroundColor
$Form.controls.add($backPanel)
#----------------------------------------------------------------------------------------------------
$paintPanel                  = New-Object System.Windows.Forms.panel
$paintPanel.ClientSize       = '640,300'
$paintPanel.BackColor        = 'Transparent'
$paintPanelGraphics          = $paintPanel.createGraphics()
$backPanel.controls.add($paintPanel)
#----------------------------------------------------------------------------------------------------
$toolPanel                   = New-Object System.Windows.Forms.Panel
$toolPanel.Left              = 0
$toolPanel.Top               = 300
$toolPanel.ClientSize        = '640,68'
$toolPanel.BackColor         = 'LightGray'
$Form.controls.add($toolPanel)

#====================================================================================================
# Functions

Function Test-Base64 {

    param (
        [Parameter(ValueFromPipeline)] 
        [string] $string
    )

    process {
        try { $null = [Convert]::FromBase64String($string); $true } catch { $false }
    }
}
#----------------------------------------------------------------------------------------------------
Function FromBase64Image ($string) {

    $img = $null

    if ( Test-Base64 $string ) {
        try {
            $img = [Drawing.Image]::FromStream([IO.MemoryStream][Convert]::FromBase64String($string))
            #write-host "[Success] FromBase64Image: [base64] $string" -f 'gree'
        }
        catch {
            write-host "[Error] FromBase64Image: [base64] $string" -f 'red'
        }
    }
    else {
        write-host "[Error] FromBase64Image: [value] $string" -f 'red'
    }

    return $img
}
#----------------------------------------------------------------------------------------------------
Function NewButton {

    param (
        [Alias('Fs')]$flatStyle = 'Standard',
        $tip,
        $tag,
        [Alias('F')]$foreColor,
        [Alias('B')]$backColor,
        [Alias('L')]$location,
        [Alias('S')]$size,
        [Alias('T')]$text,
        [Alias('I')]$image,
        [Alias('C')]$click,
        [Alias('A')]$add
    )

    try {
        $button = New-Object System.Windows.Forms.Button -ErrorAction Stop
        $button.FlatStyle = $flatStyle
        $button.FlatAppearance.BorderSize = 0
        $button.Tag = $tag
        $button.ForeColor = $foreColor
        $button.BackColor = $backColor
        $button.Location = $location
        $button.Size = $size
        $button.Text = $text
        $button.Image = $image
        $button.Add_Click( $click )
        $add.Controls.Add( $button )
        
        $toolTip.SetToolTip( $button, $tip )
    } catch {
        Write-Error "Unable to create new button`n$_"
        return
    }
}
#----------------------------------------------------------------------------------------------------
Function ColorButtonClick {

    $Global:pencilColor = $this.Tag
}

Function ColorButton {

    0..15 | ForEach-Object {
        if ($_ -gt 7) {
            $x = $( 10 + ( ($_ - 8) * 24) )
            $y = 34
        } 
        else {
            $x = $( 10 + ($_ * 24) )
            $y = 10
        }
        NewButton -Add $toolPanel -Tip "$($translate.$lang.color): $($colorLetters[$_]) ($($translate.$lang."$($colorNames[$_])"))" -Tag $_ -ForeColor 'black' -BackColor $colorsArgb.$_ -Location "$x,$y" -Size '24,24' -Click {ColorButtonClick}
    }
}
#----------------------------------------------------------------------------------------------------
Function SelectButtonClick {

    [System.Windows.Forms.MessageBox]::Show("$($translate.$lang.SelectMsg)", "$($translate.$lang.Select)", 'Ok', 'Info')
}
#----------------------------------------------------------------------------------------------------
Function MoveButtonClick {

    [System.Windows.Forms.MessageBox]::Show("$($translate.$lang.MoveMsg)", "$($translate.$lang.Move)", 'Ok', 'Info')
}
#----------------------------------------------------------------------------------------------------
Function ClearButtonClick {

    $answer = [System.Windows.Forms.MessageBox]::Show("$($translate.$lang.ClearMsg)", "$($translate.$lang.Clear)", 'YesNo', 'Question', 'Button2')
    
    if ( $answer -eq 'Yes' ) {

        @($Global:screenPixel.GetEnumerator()) | ? {$_.Value -ne 16} | % { $Global:screenPixel[$_.Key]=16}
        $Global:rectangle.clear()
        $paintPanel.Refresh()
    }
}
#----------------------------------------------------------------------------------------------------
Function PrintButtonClick {

    if ( $Global:rectangle.Count -ne 0 ) {

        $bmp = New-Object System.Drawing.Bitmap(640, 300)
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.FillRectangle((new-object Drawing.SolidBrush $colorsArgb.$Global:backgroundColor), 0, 0, $bmp.Width, $bmp.Height)

        $Global:rectangle.Values| ForEach-Object {

            $color = $colorsArgb.[int]$_.split(',')[0]
            $Global:brush = new-object Drawing.SolidBrush $color
            $graphics.FillRectangle($Global:brush, $_.split(',')[1], $_.split(',')[2], 8,6)
        }

        $date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $fileName ="$path\$($translate.$lang.Image) ($date).png"
        $bmp.Save($fileName)
        $bmp.Dispose()
    }
    else {

        [System.Windows.Forms.MessageBox]::Show("$($translate.$lang.Info)", "$($translate.$lang.PrintScreen)", 'Ok', 'Info')
    }
}
#----------------------------------------------------------------------------------------------------
Function OpenButtonClick {

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter = "PowerImage Files (*.img.txt)|*.img.txt|All files (*.*)|*.*"
    }

    if ( $openFileDialog.ShowDialog() -ne 'Cancel' ) {

        $fileName = $openFileDialog.FileName

        $pixels = Get-Content $fileName -TotalCount 2 | Where-Object {$_ -like '$image*'}
        if ( $pixels -ne $null ) {

            $position = Get-Content $fileName -TotalCount 2 | Where-Object {$_ -like '#*'}
            if ( $position -ne $null ) {
                [int]$xPosition = ($position -replace '#','').Split(',')[0]
                [int]$yPosition = ($position -replace '#','').Split(',')[1]
                if ( $xPosition -lt 0 -or $xPosition -gt 79 ) {$xPosition = 0}
                if ( $yPosition -lt 0 -or $yPosition -gt 49 ) {$yPosition = 0}
            }
            else {
                $xPosition = 0
                $yPosition = 0
            }

            $image = @{}
            iex $pixels

            0..($image.Values.height-1) | ForEach-Object {
                $y = $_
                $col = $_ * $image.Values.width

                0..($image.Values.width-1) | ForEach-Object {
                    $x = $_
                    $pixel = ($image.Values.pixels).Substring(($col+$x), 1)
        
                    if ( $pixel -ne 'z' -and $colorLetters.Contains([char]$pixel) ) {
                        $xPos = $xPosition+$x
                        $yPos = $yPosition+$y
                        $xp = $xPos*8
                        $yp = $yPos*6
                        $colorNumber = $colorLetters.IndexOf([char]$pixel)
                        $Global:screenPixel["$xPos,$yPos"] = $colorNumber
                        $Global:rectangle["$xPos,$yPos"] = "$colorNumber,$xp,$yp"
                        $Global:brush.Color = $colorsArgb.$colorNumber
                        $paintPanelGraphics.FillRectangle($Global:brush, $xp, $yp, 8,6)
                    }
                }
            }
            $image.Clear()
        }
        else {
            
            [System.Windows.Forms.MessageBox]::Show("$($translate.$lang.ImageMsg)", "$($translate.$lang.Error)", 'Ok', 'Exclamation')
        }
    }
    else {

        [System.Windows.Forms.MessageBox]::Show("$($translate.$lang.ErrorMsg)", "$($translate.$lang.Error)", 'Ok', 'Exclamation')
    }
}
#----------------------------------------------------------------------------------------------------
Function SaveButtonClick {

    if ( $Global:rectangle.Count -ne 0 ) {

        # Get the image name
        $imageName = [Microsoft.VisualBasic.Interaction]::InputBox("$($translate.$lang.SaveMsg)","$($translate.$lang.ImageName)", "$($translate.$lang.Image)")
        
        if ( $imageName.Length -ne 0) {

            # Loop to get the image height
            0..49 | ForEach-Object {
                $y = $_

                0..79 | ForEach-Object {
                    $x = $_

                    if ( $Global:screenPixel["$x,$y"] -ne 16 ) {
                        if( $topPixel -eq $null ) { $topPixel = $y }
                        $bottomPixel = $y
                    }
                }
            }
            $imageHeight = ($bottomPixel - $topPixel) + 1

            # Loop to get the image width
            0..79 | ForEach-Object {
                $x = $_

                0..49 | ForEach-Object {
                    $y = $_

                    if ( $Global:screenPixel["$x,$y"] -ne 16 ) {
                        if ( $leftPixel -eq $null ) { $leftPixel = $x }
                        $rightPixel = $x
                    }
                }
            }
            $imageWidth = ($rightPixel - $leftPixel) + 1

            # Loop to get the image pixels
            $topPixel..$bottomPixel | ForEach-Object {
                $y = $_

                $leftPixel..$rightPixel | ForEach-Object {
                    $x = $_
                    $imagePixel += $colorLetters[$Global:screenPixel["$x,$y"]]
                }
            }

            $position = "#$leftPixel,$topPixel"
            $image = '$image'+".add('$imageName', @{width=$imageWidth; height=$imageHeight; pixels='$imagePixel'})"

            $date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $fileName ="$path\$imageName ($date).img.txt"
            $position | Add-Content -Path $fileName
            $image | Add-Content -Path $fileName
        }
        else {

            [System.Windows.Forms.MessageBox]::Show("$($translate.$lang.ErrorMsg)", "$($translate.$lang.Error)", 'Ok', 'Exclamation')
        }
    }
    else {

        [System.Windows.Forms.MessageBox]::Show("$($translate.$lang.Info)","$($translate.$lang.Save)", "Ok" , "info" , "Button1")
    }
}
#----------------------------------------------------------------------------------------------------
Function Redraw {

    $Global:rectangle.Values | ForEach-Object {
        $color = $colorsArgb.[int]$_.split(',')[0]
        $Global:brush.Color = $color
        $paintPanelGraphics.FillRectangle($Global:brush, $_.split(',')[1], $_.split(',')[2], 8,6)
    }
}
#----------------------------------------------------------------------------------------------------
Function DrawPixel {

    $Global:screenPixel["$Global:xPos,$Global:yPos"] = $Global:pencilColor
    $Global:brush.Color = $colorsArgb.$Global:pencilColor
    $paintPanelGraphics.FillRectangle($Global:brush, $Global:x, $Global:y, 8,6)
    $Global:rectangle["$Global:xPos,$Global:yPos"] = "$Global:pencilColor,$Global:x,$Global:y"
}
#----------------------------------------------------------------------------------------------------
Function ErasePixel {

    $Global:screenPixel["$Global:xPos,$Global:yPos"] = 16
    $Global:rectangle.Remove("$Global:xPos,$Global:yPos")
    $rect = new-object Drawing.Rectangle $Global:x, $Global:y, 8,6
    $paintPanel.Invalidate($rect)
}
#----------------------------------------------------------------------------------------------------
Function MousePosition {

    param (
        $x,
        $y
    )

    $Global:xPos = [int][Math]::Floor($x/8)
    $Global:yPos = [int][Math]::Floor($y/6)
    if ( $Global:xPos -lt 0 ) { $Global:xPos = 0 }
    if ( $Global:yPos -lt 0 ) { $Global:yPos = 0 }
    if ( $Global:xPos -gt 79 ) { $Global:xPos = 79 }
    if ( $Global:yPos -gt 49 ) { $Global:yPos = 49 }
    $Global:x = $Global:xPos*8
    $Global:y = $Global:yPos*6
}

#====================================================================================================
# Main Block

NewButton -Add $toolPanel -Tip "$($translate.$lang.color): z ($($translate.$lang.transparent))" -Image $transparentImage -ForeColor 'black' -BackColor 'lightgray' -Location '202,10' -Size '48,48' -Click { $Global:pencilColor = 16 }
NewButton -Add $toolPanel -Tip $translate.$lang.background -Image $(FromBase64Image $backgroundBase64) -ForeColor 'black' -BackColor 'lightgray' -Location '260,10' -Size '48,48' -Click { $Global:backgroundColor = $Global:pencilColor; $backPanel.BackColor = $colorsArgb.$Global:pencilColor }
NewButton -Add $toolPanel -Tip $translate.$lang.select -Image $(FromBase64Image $selectBase64) -ForeColor 'black' -BackColor 'lightgray' -Location '308,10' -Size '48,48'  -Click { SelectButtonClick }
NewButton -Add $toolPanel -Tip $translate.$lang.move -Image $(FromBase64Image $moveBase64) -ForeColor 'black' -BackColor 'lightgray' -Location '356,10' -Size '48,48'  -Click { MoveButtonClick }
NewButton -Add $toolPanel -Tip $translate.$lang.clear -Image $(FromBase64Image $clearBase64) -ForeColor 'black' -BackColor 'lightgray' -Location '404,10' -Size '48,48' -Click { ClearButtonClick }
NewButton -Add $toolPanel -Tip $translate.$lang.printscreen -Image $(FromBase64Image $printScreenBase64) -ForeColor 'black' -BackColor 'lightgray' -Location '452,10' -Size '48,48' -Click { PrintButtonClick }
NewButton -Add $toolPanel -Tip $translate.$lang.open -Image $(FromBase64Image $openBase64) -ForeColor 'black' -BackColor 'lightgray' -Location '524,10' -Size '48,48' -Click { OpenButtonClick }
NewButton -Add $toolPanel -Tip $translate.$lang.save -Image $(FromBase64Image $saveBase64) -ForeColor 'black' -BackColor 'lightgray' -Location '582,10' -Size '48,48' -Click { SaveButtonClick }

ColorButton
#----------------------------------------------------------------------------------------------------
$paintPanel.Add_MouseDown({
    
    MousePosition -X $_.Location.x -Y $_.Location.y
    
    if ( $_.Button -eq [System.Windows.Forms.MouseButtons]::Left ) {
        if ( $Global:pencilColor -ne 16 ) { DrawPixel } else { ErasePixel }
    }
    if ( $_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) {
        ErasePixel
    }

    $Form.text = "PowerPaint $version - $($translate.$lang.Pencil): $($translate.$lang."$($colorNames[$Global:pencilColor])") - Pixels: $($Global:rectangle.Count) - $($translate.$lang.Position): $Global:xPos,$Global:yPos"
})
#----------------------------------------------------------------------------------------------------
$paintPanel.Add_MouseMove({

    MousePosition -X $_.Location.x -Y $_.Location.y
    
    if ( $_.Button -ne [System.Windows.Forms.MouseButtons]::Left ) {

        # Erase Cursor
        if ( $Global:cursorPosition -ne "$Global:xPos,$Global:yPos" ) {

            $cursorX = [int]$Global:cursorPosition.Split(',')[0]
            $cursorY = [int]$Global:cursorPosition.Split(',')[1]

            if ( $Global:screenPixel["$cursorX,$cursorY"] -eq 16 ) {
                $rect = new-object Drawing.Rectangle ($cursorX*8), ($cursorY*6), 8,6
                $paintPanel.Invalidate($rect)
            }
            else {
                $Global:brush.Color = $colorsArgb.$($Global:screenPixel["$cursorX,$cursorY"])
                $paintPanelGraphics.FillRectangle($Global:brush, ($cursorX*8), ($cursorY*6), 8,6)
            }
        }

        # Draw Cursor
        if ( $Global:screenPixel["$Global:xPos,$Global:yPos"] -eq 12 -or ($Global:screenPixel["$Global:xPos,$Global:yPos"] -eq 16 -and $Global:backgroundColor -eq 12) ) {
            $Global:pen.Color = 'cyan'
        }
        else {
            $Global:pen.Color = 'red'
        }

        $paintPanelGraphics.DrawRectangle($Global:pen, $Global:x, $Global:y, 7,5)
        $global:cursorPosition = "$Global:xPos,$Global:yPos"
    }

    if ( $_.Button -eq [System.Windows.Forms.MouseButtons]::Left ) {
        if ($Global:pencilColor -ne 16) { DrawPixel } else { ErasePixel }
    }
    if ( $_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) {
        ErasePixel
    }

    $Form.text = "PowerPaint $version - $($translate.$lang.Pencil): $($translate.$lang."$($colorNames[$Global:pencilColor])") - Pixels: $($Global:rectangle.Count) - $($translate.$lang.Position): $Global:xPos,$Global:yPos"
})
#----------------------------------------------------------------------------------------------------
$paintPanel.Add_Paint({
    Redraw
})
#----------------------------------------------------------------------------------------------------
[void]$Form.ShowDialog()
$Form.Dispose()