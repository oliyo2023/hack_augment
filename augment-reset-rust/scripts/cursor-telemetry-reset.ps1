# Cursor 编辑器遥测和 machineId 重置脚本 (PowerShell 版本)
# 用于修改 Cursor 编辑器的遥测设置和 machineId

param(
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Help
)

# 显示帮助信息
if ($Help) {
    Write-Host "Cursor 编辑器遥测和 machineId 重置工具" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "用法: .\cursor-telemetry-reset.ps1 [选项]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "选项:" -ForegroundColor Yellow
    Write-Host "  -DryRun    仅显示将要修改的文件，不实际修改"
    Write-Host "  -Verbose   显示详细输出"
    Write-Host "  -Help      显示此帮助信息"
    Write-Host ""
    Write-Host "功能:" -ForegroundColor Yellow
    Write-Host "  1. 查找 Cursor 编辑器的配置文件"
    Write-Host "  2. 修改所有遥测相关的 ID"
    Write-Host "  3. 查找并修改 machineId 文件"
    Write-Host "  4. 将 machineId 文件设置为只读"
    Write-Host ""
    exit 0
}

# 颜色输出函数
function Write-Info($message) {
    Write-Host "ℹ️  $message" -ForegroundColor Blue
}

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "⚠️  $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

# 生成随机 ID
function Generate-RandomId {
    param([int]$Length = 32)
    
    $chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    $random = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $random += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $random
}

# 生成 UUID 格式的 ID
function Generate-UUID {
    return [System.Guid]::NewGuid().ToString()
}

# 获取 Cursor 配置目录
function Get-CursorConfigPaths {
    $paths = @()
    
    # Windows 路径
    $appdata = $env:APPDATA
    if ($appdata) {
        $cursorPath = Join-Path $appdata "Cursor"
        if (Test-Path $cursorPath) {
            $paths += $cursorPath
        }
    }
    
    # 用户目录下的其他可能路径
    $userProfile = $env:USERPROFILE
    if ($userProfile) {
        $additionalPaths = @(
            Join-Path $userProfile ".cursor",
            Join-Path $userProfile "AppData\Local\Cursor",
            Join-Path $userProfile "AppData\Roaming\Cursor"
        )
        
        foreach ($path in $additionalPaths) {
            if (Test-Path $path) {
                $paths += $path
            }
        }
    }
    
    return $paths
}

# 查找 JSON 文件
function Find-JsonFiles {
    param([string]$BasePath)
    
    if (-not (Test-Path $BasePath)) {
        return @()
    }
    
    return Get-ChildItem -Path $BasePath -Recurse -Filter "*.json" -File | Select-Object -ExpandProperty FullName
}

# 查找 machineId 文件
function Find-MachineIdFiles {
    param([string]$BasePath)
    
    if (-not (Test-Path $BasePath)) {
        return @()
    }
    
    $patterns = @("*machineid*", "*machine-id*", "*machineId*")
    $files = @()
    
    foreach ($pattern in $patterns) {
        $found = Get-ChildItem -Path $BasePath -Recurse -Filter $pattern -File -ErrorAction SilentlyContinue
        $files += $found | Select-Object -ExpandProperty FullName
    }
    
    return $files | Sort-Object | Get-Unique
}

# 修改 JSON 文件中的遥测 ID
function Modify-TelemetryIds {
    param(
        [string]$JsonPath,
        [switch]$DryRun
    )
    
    try {
        $content = Get-Content -Path $JsonPath -Raw -Encoding UTF8
        $json = $content | ConvertFrom-Json
        $modified = $false
        
        # 需要修改的字段列表
        $telemetryFields = @(
            "telemetryMachineId",
            "machineId", 
            "deviceId",
            "sessionId",
            "userId",
            "installationId",
            "sqmUserId",
            "sqmMachineId"
        )
        
        # 递归修改 JSON 对象
        function Modify-JsonObject {
            param($obj)
            
            $changed = $false
            
            if ($obj -is [PSCustomObject]) {
                $properties = $obj.PSObject.Properties
                
                foreach ($prop in $properties) {
                    $key = $prop.Name
                    $value = $prop.Value
                    
                    # 检查是否是需要修改的字段
                    $shouldModify = $false
                    foreach ($field in $telemetryFields) {
                        if ($key -eq $field -or 
                            $key.ToLower().Contains("machineid") -or
                            $key.ToLower().Contains("deviceid") -or
                            $key.ToLower().Contains("sessionid") -or
                            $key.ToLower().Contains("userid") -or
                            $key.ToLower().Contains("telemetry")) {
                            $shouldModify = $true
                            break
                        }
                    }
                    
                    if ($shouldModify -and $value -is [string]) {
                        $newId = if ($key.ToLower().Contains("machine")) {
                            Generate-UUID
                        } else {
                            Generate-RandomId
                        }
                        
                        if ($Verbose) {
                            Write-Host "    修改字段: $key -> $newId" -ForegroundColor Gray
                        }
                        
                        $obj.$key = $newId
                        $changed = $true
                        $script:totalFieldsModified++
                    }
                    
                    # 递归处理嵌套对象
                    if ($value -is [PSCustomObject] -or $value -is [Array]) {
                        if (Modify-JsonObject $value) {
                            $changed = $true
                        }
                    }
                }
            }
            elseif ($obj -is [Array]) {
                for ($i = 0; $i -lt $obj.Count; $i++) {
                    if (Modify-JsonObject $obj[$i]) {
                        $changed = $true
                    }
                }
            }
            
            return $changed
        }
        
        $modified = Modify-JsonObject $json
        
        if ($modified) {
            if ($DryRun) {
                Write-Warning "  [DRY RUN] 将修改: $JsonPath"
            } else {
                # 备份原文件
                $backupPath = "$JsonPath.backup"
                Copy-Item -Path $JsonPath -Destination $backupPath -Force
                if ($Verbose) {
                    Write-Host "    备份原文件: $backupPath" -ForegroundColor Gray
                }
                
                # 写入修改后的内容
                $newContent = $json | ConvertTo-Json -Depth 100 -Compress:$false
                Set-Content -Path $JsonPath -Value $newContent -Encoding UTF8
                Write-Success "  已修改: $JsonPath"
            }
        } else {
            if ($Verbose) {
                Write-Host "  跳过: $JsonPath (无需修改)" -ForegroundColor Gray
            }
        }
        
        return $modified
    }
    catch {
        Write-Error "  处理失败: $JsonPath - $($_.Exception.Message)"
        return $false
    }
}

# 修改 machineId 文件
function Modify-MachineIdFile {
    param(
        [string]$MachineIdPath,
        [switch]$DryRun
    )
    
    try {
        if ($DryRun) {
            Write-Warning "  [DRY RUN] 将修改 machineId: $MachineIdPath"
            Write-Warning "  [DRY RUN] 将设置为只读: $MachineIdPath"
            return $true
        }
        
        # 备份原文件
        $backupPath = "$MachineIdPath.backup"
        Copy-Item -Path $MachineIdPath -Destination $backupPath -Force
        if ($Verbose) {
            Write-Host "    备份原文件: $backupPath" -ForegroundColor Gray
        }
        
        # 生成新的 machineId
        $newMachineId = Generate-UUID
        
        # 写入新的 machineId
        Set-Content -Path $MachineIdPath -Value $newMachineId -Encoding UTF8
        Write-Success "  已修改 machineId: $MachineIdPath"
        
        # 设置文件为只读
        Set-ItemProperty -Path $MachineIdPath -Name IsReadOnly -Value $true
        Write-Success "  🔒 已设置为只读: $MachineIdPath"
        
        return $true
    }
    catch {
        Write-Error "  处理失败: $MachineIdPath - $($_.Exception.Message)"
        return $false
    }
}

# 主程序
Write-Host "🔧 Cursor 编辑器遥测和 machineId 重置工具" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Warning "运行在 DRY RUN 模式 - 不会实际修改文件"
}

# 初始化计数器
$script:totalFieldsModified = 0
$totalJsonModified = 0
$totalMachineIdsModified = 0

# 获取 Cursor 配置路径
$cursorPaths = Get-CursorConfigPaths

if ($cursorPaths.Count -eq 0) {
    Write-Error "未找到 Cursor 配置目录"
    exit 1
}

foreach ($cursorPath in $cursorPaths) {
    Write-Host ""
    Write-Info "处理目录: $cursorPath"
    
    # 查找并修改 JSON 配置文件
    Write-Host ""
    Write-Info "查找 JSON 配置文件..."
    $jsonFiles = Find-JsonFiles -BasePath $cursorPath
    
    if ($jsonFiles.Count -eq 0) {
        Write-Host "  未找到 JSON 文件" -ForegroundColor Gray
    } else {
        Write-Host "  找到 $($jsonFiles.Count) 个 JSON 文件" -ForegroundColor Gray
        
        foreach ($jsonFile in $jsonFiles) {
            if (Modify-TelemetryIds -JsonPath $jsonFile -DryRun:$DryRun) {
                $totalJsonModified++
            }
        }
    }
    
    # 查找并修改 machineId 文件
    Write-Host ""
    Write-Info "查找 machineId 文件..."
    $machineIdFiles = Find-MachineIdFiles -BasePath $cursorPath
    
    if ($machineIdFiles.Count -eq 0) {
        Write-Host "  未找到 machineId 文件" -ForegroundColor Gray
    } else {
        Write-Host "  找到 $($machineIdFiles.Count) 个 machineId 文件" -ForegroundColor Gray
        
        foreach ($machineIdFile in $machineIdFiles) {
            if (Modify-MachineIdFile -MachineIdPath $machineIdFile -DryRun:$DryRun) {
                $totalMachineIdsModified++
            }
        }
    }
}

# 显示结果
Write-Host ""
Write-Host "🎉 处理完成！" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "修改的 JSON 文件: $totalJsonModified" -ForegroundColor Yellow
Write-Host "修改的字段总数: $script:totalFieldsModified" -ForegroundColor Yellow
Write-Host "修改的 machineId 文件: $totalMachineIdsModified" -ForegroundColor Yellow

if (($totalJsonModified -gt 0 -or $totalMachineIdsModified -gt 0) -and -not $DryRun) {
    Write-Host ""
    Write-Host "💡 建议:" -ForegroundColor Cyan
    Write-Host "1. 重启 Cursor 编辑器以使更改生效"
    Write-Host "2. 检查备份文件是否正确创建"
    Write-Host "3. 如有问题，可以使用备份文件恢复"
    Write-Host "4. 清除 Cursor 缓存目录以确保完全重置"
}

if ($DryRun) {
    Write-Host ""
    Write-Warning "这是 DRY RUN 模式的结果。要实际修改文件，请不使用 -DryRun 参数重新运行脚本。"
}
