#!/usr/bin/env python3
import os
import sqlite3
import pathlib
import platform
from pathlib import Path

def get_db_paths():
    """根据不同操作系统获取Cursor和Code数据库路径"""
    system = platform.system()
    paths = []
    print(Path(os.getenv("APPDATA", "")))
    if system == "Darwin":  # macOS
        paths.append(Path.home() / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "state.vscdb")
        paths.append(Path.home() / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "state.vscdb")
    elif system == "Windows":
        paths.append(Path(os.getenv("APPDATA", "")) / "Cursor" / "User" / "globalStorage" / "state.vscdb")
        paths.append(Path(os.getenv("APPDATA", "")) / "Code" / "User" / "globalStorage" / "state.vscdb")
        paths.append(Path(os.getenv("APPDATA", "")) / "Void" / "User" / "globalStorage" / "state.vscdb")
    elif system == "Linux":
        paths.append(Path.home() / ".config" / "Cursor" / "User" / "globalStorage" / "state.vscdb")
        paths.append(Path.home() / ".config" / "Code" / "User" / "globalStorage" / "state.vscdb")
        paths.append(Path.home() / ".config" / "Void" / "User" / "globalStorage" / "state.vscdb")
    else:
        raise OSError(f"不支持的操作系统: {system}")
        
    # 过滤掉不存在的路径
    return [path for path in paths if path.exists()]

def clean_db(db_path):
    """清理单个数据库文件"""
    app_name = "Void" if "Void" in str(db_path) else "Code"
    print(f"正在处理 {app_name} 数据库...")
    
    # 连接到数据库
    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()
    
    try:
        # 备份数据库
        backup_path = f"{db_path}_backup"
        with open(db_path, 'rb') as source:
            with open(backup_path, 'wb') as dest:
                dest.write(source.read())
        print(f"已创建备份")
        
        # 直接删除记录
        cursor.execute("DELETE FROM ItemTable WHERE key LIKE '%augment%'")
        conn.commit()
        print(f"已清理数据库")
            
    except sqlite3.Error as e:
        print(f"处理出错")
    finally:
        # 关闭连接
        conn.close()
    
    return True

def clean_cursor_db():
    # 获取所有可能的数据库路径
    db_paths = get_db_paths()
    
    if not db_paths:
        print("未找到需要处理的数据库文件")
        return
    
    print(f"找到 {len(db_paths)} 个数据库文件")
    
    # 处理每个数据库
    for db_path in db_paths:
        clean_db(db_path)
    
    print("处理完成")

if __name__ == "__main__":
    clean_cursor_db() 