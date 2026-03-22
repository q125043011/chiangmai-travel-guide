#!/bin/bash

# ============================================
# 清迈旅行攻略一键部署脚本
# 作者: OpenClaw AI 助手
# 时间: 2026年3月22日
# ============================================

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "命令 '$1' 未找到，请先安装"
        exit 1
    fi
}

# 函数：检查Git配置
check_git_config() {
    if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
        print_warning "Git用户信息未配置"
        echo ""
        read -p "请输入你的名字（用于Git提交）: " git_name
        read -p "请输入你的邮箱（用于Git提交）: " git_email
        
        git config user.name "$git_name"
        git config user.email "$git_email"
        
        print_success "Git用户信息已配置: $git_name <$git_email>"
    else
        print_info "Git用户信息: $(git config user.name) <$(git config user.email)>"
    fi
}

# 主函数
main() {
    clear
    echo "==========================================="
    echo "  清迈旅行攻略 GitHub 部署脚本"
    echo "==========================================="
    echo ""
    
    # 检查必要命令
    print_info "检查系统依赖..."
    check_command git
    check_command curl
    
    # 进入工作目录
    cd /Users/wangliang/.openclaw/workspace
    
    # 检查Git配置
    check_git_config
    
    echo ""
    print_info "📦 检查本地文件..."
    
    # 检查HTML文件是否存在
    html_files=(
        "chiangmai-tour-beautiful.html"
        "chiangmai-play-tour.html"
        "chiangmai-trip-mobile.html"
        "school-tour-schedule.html"
        "README-travel.html"
        "github-deploy.html"
    )
    
    missing_files=()
    for file in "${html_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "找到文件: $file"
        else
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_warning "以下文件缺失: ${missing_files[*]}"
        read -p "是否继续？(y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "部署取消"
            exit 1
        fi
    fi
    
    echo ""
    print_info "📝 检查Git状态..."
    
    # 检查是否有未提交的更改
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "检测到未提交的更改"
        git status
        
        read -p "是否提交这些更改？(y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "自动提交: $(date '+%Y-%m-%d %H:%M:%S')"
            print_success "更改已提交"
        fi
    else
        print_success "工作区干净，无未提交更改"
    fi
    
    echo ""
    print_info "🔗 配置远程仓库..."
    
    # 检查是否已有远程仓库
    if git remote | grep -q origin; then
        print_info "已配置远程仓库:"
        git remote -v
        
        read -p "是否使用现有远程仓库？(y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            git remote remove origin
            print_success "已移除现有远程仓库"
        fi
    fi
    
    # 如果没有远程仓库，提示用户输入
    if ! git remote | grep -q origin; then
        echo ""
        echo "请选择远程仓库URL类型:"
        echo "1) HTTPS (推荐新手)"
        echo "2) SSH (推荐有SSH密钥的用户)"
        echo ""
        read -p "请选择 (1/2): " url_type
        
        echo ""
        print_info "请在GitHub上创建仓库: https://github.com/new"
        echo "仓库名建议: chiangmai-travel-guide"
        echo ""
        
        case $url_type in
            1)
                read -p "请输入HTTPS URL (例如: https://github.com/用户名/chiangmai-travel-guide.git): " repo_url
                ;;
            2)
                read -p "请输入SSH URL (例如: git@github.com:用户名/chiangmai-travel-guide.git): " repo_url
                ;;
            *)
                print_error "无效选择"
                exit 1
                ;;
        esac
        
        git remote add origin "$repo_url"
        print_success "远程仓库已添加: $repo_url"
    fi
    
    echo ""
    print_info "🚀 推送到GitHub..."
    
    # 尝试推送
    if git push -u origin master; then
        print_success "✅ 推送成功！"
    else
        print_warning "推送失败，尝试拉取远程更改..."
        
        if git pull origin master --allow-unrelated-histories; then
            print_success "拉取成功，重新推送..."
            if git push -u origin master; then
                print_success "✅ 推送成功！"
            else
                print_error "推送仍然失败，请手动检查"
                exit 1
            fi
        else
            print_error "拉取失败，请手动解决冲突"
            exit 1
        fi
    fi
    
    echo ""
    echo "==========================================="
    print_success "🎉 部署完成！"
    echo "==========================================="
    echo ""
    
    # 显示部署信息
    repo_name=$(git config --get remote.origin.url | sed -e 's/.*\///' -e 's/\.git$//')
    user_name=$(git config --get remote.origin.url | grep -o 'github.com[:/][^/]*' | cut -d'/' -f2 | cut -d':' -f2)
    
    if [ -n "$user_name" ] && [ -n "$repo_name" ]; then
        echo "🌐 你的网站将在以下地址上线:"
        echo ""
        echo "   https://$user_name.github.io/$repo_name/"
        echo ""
        echo "📁 具体文件:"
        echo "   https://$user_name.github.io/$repo_name/chiangmai-tour-beautiful.html"
        echo "   https://$user_name.github.io/$repo_name/README-travel.html"
        echo ""
        echo "⚙️ 启用 GitHub Pages:"
        echo "   1. 访问 https://github.com/$user_name/$repo_name/settings/pages"
        echo "   2. 选择 'Deploy from a branch'"
        echo "   3. 分支选择 'master'，文件夹选择 '/(root)'"
        echo "   4. 点击 'Save'"
        echo ""
        echo "⏱️ 等待1-2分钟，网站即可访问"
    else
        echo "🌐 请访问你的GitHub仓库启用Pages功能"
    fi
    
    echo ""
    echo "📞 本地预览仍在运行:"
    echo "   http://localhost:8080/chiangmai-tour-beautiful.html"
    echo ""
    echo "==========================================="
    echo "🦞 由 OpenClaw AI 助手创建"
    echo "==========================================="
}

# 运行主函数
main "$@"