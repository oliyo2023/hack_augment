#!/usr/bin/env rust-script

//! Cursor 编辑器遥测和 machineId 重置脚本
//! 
//! 此脚本用于：
//! 1. 查找 Cursor 编辑器的配置文件
//! 2. 修改所有遥测相关的 ID
//! 3. 查找并修改 machineId 文件
//! 4. 将 machineId 文件设置为只读

use std::fs::{self, File, OpenOptions};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::collections::HashMap;
use serde_json::{Value, Map};
use rand::Rng;

#[cfg(target_os = "windows")]
use std::os::windows::fs::OpenOptionsExt;

/// 生成随机 ID
fn generate_random_id(length: usize) -> String {
    let chars: Vec<char> = "abcdefghijklmnopqrstuvwxyz0123456789".chars().collect();
    let mut rng = rand::thread_rng();
    (0..length)
        .map(|_| chars[rng.gen_range(0..chars.len())])
        .collect()
}

/// 生成 UUID 格式的 ID
fn generate_uuid() -> String {
    let mut rng = rand::thread_rng();
    format!(
        "{:08x}-{:04x}-{:04x}-{:04x}-{:012x}",
        rng.gen::<u32>(),
        rng.gen::<u16>(),
        rng.gen::<u16>(),
        rng.gen::<u16>(),
        rng.gen::<u64>() & 0xffffffffffff
    )
}

/// 获取 Cursor 配置目录路径
fn get_cursor_config_paths() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    
    #[cfg(target_os = "windows")]
    {
        if let Ok(appdata) = std::env::var("APPDATA") {
            paths.push(PathBuf::from(appdata).join("Cursor"));
        }
    }
    
    #[cfg(target_os = "macos")]
    {
        if let Some(home) = dirs::home_dir() {
            paths.push(home.join("Library").join("Application Support").join("Cursor"));
        }
    }
    
    #[cfg(target_os = "linux")]
    {
        if let Some(config) = dirs::config_dir() {
            paths.push(config.join("Cursor"));
        }
    }
    
    paths
}

/// 查找所有 JSON 配置文件
fn find_json_files(base_path: &Path) -> Vec<PathBuf> {
    let mut json_files = Vec::new();
    
    if !base_path.exists() {
        return json_files;
    }
    
    // 递归查找 JSON 文件
    fn walk_dir(dir: &Path, files: &mut Vec<PathBuf>) {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_dir() {
                    walk_dir(&path, files);
                } else if path.extension().and_then(|s| s.to_str()) == Some("json") {
                    files.push(path);
                }
            }
        }
    }
    
    walk_dir(base_path, &mut json_files);
    json_files
}

/// 查找 machineId 文件
fn find_machine_id_files(base_path: &Path) -> Vec<PathBuf> {
    let mut machine_id_files = Vec::new();
    
    if !base_path.exists() {
        return machine_id_files;
    }
    
    // 递归查找 machineId 文件
    fn walk_dir(dir: &Path, files: &mut Vec<PathBuf>) {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_dir() {
                    walk_dir(&path, files);
                } else if let Some(filename) = path.file_name().and_then(|s| s.to_str()) {
                    if filename.to_lowercase().contains("machineid") || 
                       filename == "machineId" || 
                       filename == "machine-id" {
                        files.push(path);
                    }
                }
            }
        }
    }
    
    walk_dir(base_path, &mut machine_id_files);
    machine_id_files
}

/// 修改 JSON 文件中的遥测 ID
fn modify_telemetry_ids(json_path: &Path) -> Result<bool, Box<dyn std::error::Error>> {
    let mut file = File::open(json_path)?;
    let mut content = String::new();
    file.read_to_string(&mut content)?;
    
    let mut json: Value = serde_json::from_str(&content)?;
    let mut modified = false;
    
    // 需要修改的字段列表
    let telemetry_fields = [
        "telemetryMachineId",
        "machineId", 
        "deviceId",
        "sessionId",
        "userId",
        "installationId",
        "sqmUserId",
        "sqmMachineId",
        "telemetry.machineId",
        "telemetry.deviceId",
        "telemetry.sessionId",
        "cursor.deviceId",
        "cursor.userId", 
        "cursor.sessionId",
        "augment.deviceId",
        "augment.userId",
        "augment.sessionId"
    ];
    
    // 递归修改 JSON 对象
    fn modify_json_recursive(value: &mut Value, fields: &[&str]) -> bool {
        let mut changed = false;
        
        match value {
            Value::Object(map) => {
                for (key, val) in map.iter_mut() {
                    // 检查是否是需要修改的字段
                    if fields.iter().any(|&field| {
                        key == field || 
                        key.to_lowercase().contains("machineid") ||
                        key.to_lowercase().contains("deviceid") ||
                        key.to_lowercase().contains("sessionid") ||
                        key.to_lowercase().contains("userid") ||
                        key.to_lowercase().contains("telemetry")
                    }) {
                        if val.is_string() {
                            let new_id = if key.to_lowercase().contains("machine") {
                                generate_uuid()
                            } else {
                                generate_random_id(32)
                            };
                            *val = Value::String(new_id);
                            changed = true;
                            println!("  修改字段: {} -> 新ID", key);
                        }
                    }
                    
                    // 递归处理嵌套对象
                    if modify_json_recursive(val, fields) {
                        changed = true;
                    }
                }
            }
            Value::Array(arr) => {
                for item in arr.iter_mut() {
                    if modify_json_recursive(item, fields) {
                        changed = true;
                    }
                }
            }
            _ => {}
        }
        
        changed
    }
    
    modified = modify_json_recursive(&mut json, &telemetry_fields);
    
    if modified {
        // 备份原文件
        let backup_path = json_path.with_extension("json.backup");
        fs::copy(json_path, &backup_path)?;
        println!("  备份原文件: {}", backup_path.display());
        
        // 写入修改后的内容
        let new_content = serde_json::to_string_pretty(&json)?;
        fs::write(json_path, new_content)?;
        println!("  ✅ 已修改: {}", json_path.display());
    }
    
    Ok(modified)
}

/// 修改 machineId 文件
fn modify_machine_id_file(machine_id_path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    // 备份原文件
    let backup_path = machine_id_path.with_extension("backup");
    fs::copy(machine_id_path, &backup_path)?;
    println!("  备份原文件: {}", backup_path.display());
    
    // 生成新的 machineId
    let new_machine_id = generate_uuid();
    
    // 写入新的 machineId
    fs::write(machine_id_path, &new_machine_id)?;
    println!("  ✅ 已修改 machineId: {}", machine_id_path.display());
    
    // 设置文件为只读
    set_file_readonly(machine_id_path)?;
    println!("  🔒 已设置为只读: {}", machine_id_path.display());
    
    Ok(())
}

/// 设置文件为只读
fn set_file_readonly(file_path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = fs::metadata(file_path)?.permissions();
        perms.set_mode(0o444); // 只读权限
        fs::set_permissions(file_path, perms)?;
    }
    
    #[cfg(windows)]
    {
        use std::os::windows::fs::MetadataExt;
        let metadata = fs::metadata(file_path)?;
        let mut perms = metadata.permissions();
        perms.set_readonly(true);
        fs::set_permissions(file_path, perms)?;
    }
    
    Ok(())
}

/// 主函数
fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🔧 Cursor 编辑器遥测和 machineId 重置工具");
    println!("================================================");
    
    let cursor_paths = get_cursor_config_paths();
    
    if cursor_paths.is_empty() {
        println!("❌ 未找到 Cursor 配置目录");
        return Ok(());
    }
    
    let mut total_modified = 0;
    let mut total_machine_ids = 0;
    
    for cursor_path in cursor_paths {
        if !cursor_path.exists() {
            println!("⚠️  路径不存在: {}", cursor_path.display());
            continue;
        }
        
        println!("\n📁 处理目录: {}", cursor_path.display());
        
        // 查找并修改 JSON 配置文件
        println!("\n🔍 查找 JSON 配置文件...");
        let json_files = find_json_files(&cursor_path);
        
        if json_files.is_empty() {
            println!("  未找到 JSON 文件");
        } else {
            println!("  找到 {} 个 JSON 文件", json_files.len());
            
            for json_file in json_files {
                match modify_telemetry_ids(&json_file) {
                    Ok(true) => {
                        total_modified += 1;
                    }
                    Ok(false) => {
                        println!("  跳过: {} (无需修改)", json_file.display());
                    }
                    Err(e) => {
                        println!("  ❌ 处理失败: {} - {}", json_file.display(), e);
                    }
                }
            }
        }
        
        // 查找并修改 machineId 文件
        println!("\n🔍 查找 machineId 文件...");
        let machine_id_files = find_machine_id_files(&cursor_path);
        
        if machine_id_files.is_empty() {
            println!("  未找到 machineId 文件");
        } else {
            println!("  找到 {} 个 machineId 文件", machine_id_files.len());
            
            for machine_id_file in machine_id_files {
                match modify_machine_id_file(&machine_id_file) {
                    Ok(()) => {
                        total_machine_ids += 1;
                    }
                    Err(e) => {
                        println!("  ❌ 处理失败: {} - {}", machine_id_file.display(), e);
                    }
                }
            }
        }
    }
    
    println!("\n🎉 处理完成！");
    println!("================================================");
    println!("修改的 JSON 文件: {}", total_modified);
    println!("修改的 machineId 文件: {}", total_machine_ids);
    
    if total_modified > 0 || total_machine_ids > 0 {
        println!("\n💡 建议:");
        println!("1. 重启 Cursor 编辑器以使更改生效");
        println!("2. 检查备份文件是否正确创建");
        println!("3. 如有问题，可以使用备份文件恢复");
    }
    
    Ok(())
}

// 依赖项（如果使用 rust-script）
/*
[dependencies]
serde_json = "1.0"
rand = "0.8"
dirs = "5.0"
*/
