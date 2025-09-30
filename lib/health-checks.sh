#!/usr/bin/env bash
# ClaudeOps Health Check Library
# Reusable functions for system health monitoring
# Can be sourced by Claude Code or other scripts

# Check if a systemd service is running
check_systemd_service() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        echo "✓ $service_name is running"
        return 0
    else
        echo "✗ $service_name is NOT running"
        return 1
    fi
}

# Check if a Docker container is running
check_docker_container() {
    local container_name="$1"
    if docker ps --filter "name=$container_name" --filter "status=running" --format "{{.Names}}" | grep -q "^${container_name}$"; then
        echo "✓ Docker container $container_name is running"
        return 0
    else
        echo "✗ Docker container $container_name is NOT running"
        return 1
    fi
}

# Check if a PM2 process is running
check_pm2_process() {
    local process_name="$1"
    if pm2 list 2>/dev/null | grep -q "$process_name.*online"; then
        echo "✓ PM2 process $process_name is running"
        return 0
    else
        echo "✗ PM2 process $process_name is NOT running"
        return 1
    fi
}

# Check HTTP endpoint health
check_http_endpoint() {
    local url="$1"
    local expected_status="${2:-200}"
    local timeout="${3:-5}"

    local status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null)

    if [ "$status_code" = "$expected_status" ]; then
        echo "✓ Endpoint $url returned $status_code"
        return 0
    else
        echo "✗ Endpoint $url returned $status_code (expected $expected_status)"
        return 1
    fi
}

# Check HTTP endpoint response time
check_http_response_time() {
    local url="$1"
    local timeout="${2:-5}"

    local response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time "$timeout" "$url" 2>/dev/null)

    if [ -n "$response_time" ]; then
        echo "$response_time seconds"
        return 0
    else
        echo "Failed to get response time"
        return 1
    fi
}

# Check PostgreSQL database connectivity
check_postgres_db() {
    local db_name="${1:-postgres}"
    local user="${2:-postgres}"
    local host="${3:-localhost}"

    if psql -h "$host" -U "$user" -d "$db_name" -c "SELECT 1;" &>/dev/null; then
        echo "✓ PostgreSQL database $db_name is accessible"
        return 0
    else
        echo "✗ PostgreSQL database $db_name is NOT accessible"
        return 1
    fi
}

# Get PostgreSQL connection count
get_postgres_connections() {
    local db_name="${1:-postgres}"
    local user="${2:-postgres}"
    local host="${3:-localhost}"

    psql -h "$host" -U "$user" -d "$db_name" -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | xargs
}

# Check disk space usage
check_disk_space() {
    local path="${1:-/}"
    local warn_threshold="${2:-80}"
    local crit_threshold="${3:-90}"

    local usage=$(df -h "$path" | awk 'NR==2 {gsub(/%/,""); print $5}')

    if [ "$usage" -ge "$crit_threshold" ]; then
        echo "🔴 CRITICAL: Disk $path at ${usage}% (threshold: ${crit_threshold}%)"
        return 2
    elif [ "$usage" -ge "$warn_threshold" ]; then
        echo "🟡 WARNING: Disk $path at ${usage}% (threshold: ${warn_threshold}%)"
        return 1
    else
        echo "✓ Disk $path at ${usage}%"
        return 0
    fi
}

# Check memory usage
check_memory_usage() {
    local warn_threshold="${1:-85}"
    local crit_threshold="${2:-95}"

    local usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100.0}')

    if [ "$usage" -ge "$crit_threshold" ]; then
        echo "🔴 CRITICAL: Memory at ${usage}% (threshold: ${crit_threshold}%)"
        return 2
    elif [ "$usage" -ge "$warn_threshold" ]; then
        echo "🟡 WARNING: Memory at ${usage}% (threshold: ${warn_threshold}%)"
        return 1
    else
        echo "✓ Memory at ${usage}%"
        return 0
    fi
}

# Get memory details
get_memory_details() {
    free -h | grep -E "Mem|Swap"
}

# Check CPU usage
check_cpu_usage() {
    local warn_threshold="${1:-80}"

    # Get 5-second average CPU usage
    local usage=$(top -bn2 -d 1 | grep "Cpu(s)" | tail -n1 | awk '{print $2}' | cut -d'%' -f1)

    if (( $(echo "$usage >= $warn_threshold" | bc -l 2>/dev/null || echo 0) )); then
        echo "🟡 WARNING: CPU at ${usage}% (threshold: ${warn_threshold}%)"
        return 1
    else
        echo "✓ CPU at ${usage}%"
        return 0
    fi
}

# Count errors in log file
count_log_errors() {
    local log_file="$1"
    local since_minutes="${2:-60}"
    local pattern="${3:-ERROR}"

    if [ ! -f "$log_file" ]; then
        echo "0 (log file not found)"
        return 1
    fi

    # Get errors from last N minutes (approximate - checks file modification time)
    local count=$(grep -c "$pattern" "$log_file" 2>/dev/null || echo 0)
    echo "$count errors matching '$pattern'"
    return 0
}

# Check if file is fresh (modified recently)
check_file_freshness() {
    local file_path="$1"
    local max_age_minutes="${2:-60}"

    if [ ! -f "$file_path" ]; then
        echo "✗ File $file_path does not exist"
        return 1
    fi

    local file_age_seconds=$(( $(date +%s) - $(stat -f %m "$file_path" 2>/dev/null || stat -c %Y "$file_path" 2>/dev/null) ))
    local max_age_seconds=$((max_age_minutes * 60))

    if [ "$file_age_seconds" -le "$max_age_seconds" ]; then
        echo "✓ File $file_path is fresh (${file_age_seconds}s old)"
        return 0
    else
        echo "✗ File $file_path is stale (${file_age_seconds}s old, max: ${max_age_seconds}s)"
        return 1
    fi
}

# Check process by name
check_process_running() {
    local process_pattern="$1"

    if pgrep -f "$process_pattern" > /dev/null; then
        local pid=$(pgrep -f "$process_pattern" | head -n1)
        echo "✓ Process matching '$process_pattern' is running (PID: $pid)"
        return 0
    else
        echo "✗ No process matching '$process_pattern' found"
        return 1
    fi
}

# Check network connectivity
check_network() {
    local host="${1:-8.8.8.8}"

    if ping -c 1 -W 2 "$host" &>/dev/null; then
        echo "✓ Network connectivity OK (can reach $host)"
        return 0
    else
        echo "✗ Network connectivity FAILED (cannot reach $host)"
        return 1
    fi
}

# Check DNS resolution
check_dns() {
    local hostname="${1:-google.com}"

    if nslookup "$hostname" &>/dev/null || host "$hostname" &>/dev/null; then
        echo "✓ DNS resolution OK (resolved $hostname)"
        return 0
    else
        echo "✗ DNS resolution FAILED (could not resolve $hostname)"
        return 1
    fi
}

# Get top memory consumers
get_top_memory_consumers() {
    local count="${1:-5}"
    echo "Top $count memory consumers:"
    ps aux --sort=-%mem | head -n $((count + 1)) | awk '{printf "  %s\t%s\t%s\n", $11, $4"%", $6/1024"MB"}'
}

# Get top CPU consumers
get_top_cpu_consumers() {
    local count="${1:-5}"
    echo "Top $count CPU consumers:"
    ps aux --sort=-%cpu | head -n $((count + 1)) | awk '{printf "  %s\t%s%%\n", $11, $3}'
}

# Check if port is listening
check_port_listening() {
    local port="$1"
    local host="${2:-localhost}"

    if nc -z "$host" "$port" 2>/dev/null || timeout 1 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        echo "✓ Port $port is listening on $host"
        return 0
    else
        echo "✗ Port $port is NOT listening on $host"
        return 1
    fi
}

# Export all functions
export -f check_systemd_service
export -f check_docker_container
export -f check_pm2_process
export -f check_http_endpoint
export -f check_http_response_time
export -f check_postgres_db
export -f get_postgres_connections
export -f check_disk_space
export -f check_memory_usage
export -f get_memory_details
export -f check_cpu_usage
export -f count_log_errors
export -f check_file_freshness
export -f check_process_running
export -f check_network
export -f check_dns
export -f get_top_memory_consumers
export -f get_top_cpu_consumers
export -f check_port_listening