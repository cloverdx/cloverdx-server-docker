#!/bin/bash

available_memory() {
	if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
		get_mem_limit_cgroupv2
	else
		get_mem_limit_cgroupv1
	fi
}

get_mem_limit_cgroupv1() {
	# The default value (i.e. hard memory limit not set) is LONG_MAX/PAGE_SIZE (i.e. it depends on platform, 
	# for example it is 9223372036854771712 for 4k page size). So we compare the value with the total memory available
	# in the system and if it is lower, we consider it defined. 
	# The value can also be -1 (means remove any existing limit).
	# If the limit is not set, MIN_MEMORY_SIZE is used.
	local mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
	if [[ -r "${mem_file}" ]]; then
		local max_mem_cgroup="$(cat ${mem_file})"
		local max_mem_meminfo_kb="$(< /proc/meminfo awk '/MemTotal/ {print $2}')"
		local max_mem_meminfo=$(("$max_mem_meminfo_kb" * 1024))
		if [[ ${max_mem_cgroup:-0} != -1 && ${max_mem_cgroup:-0} -lt ${max_mem_meminfo:-0} ]]; then
			export SYSTEM_TOTAL_MEMORY=${max_mem_cgroup}
			echo "${max_mem_cgroup}"
		else
			echo ""
		fi
	else
		echo ""
	fi
}

get_mem_limit_cgroupv2() {
	# The default value (i.e. hard memory limit not set) is "max".
	# If the limit is not set, MIN_MEMORY_SIZE is used.
	local mem_file="/sys/fs/cgroup/memory.max"
	if [[ -r "${mem_file}" ]]; then
		local max_mem_cgroup="$(cat ${mem_file})"
		if [[ ${max_mem_cgroup} != "max" ]]; then
			export SYSTEM_TOTAL_MEMORY=${max_mem_cgroup}
			echo "${max_mem_cgroup}"
		else
			echo ""
		fi
	else
		echo ""
	fi
}

bytes_to_megabytes() {
	local val=$(($1 / 1048576))
	echo "${val}"
}

# Gets value from the given parameter and converts it to megabytes;
# the value can be a number (then it is considered as value in MB)
# or a number with units (e.g. "1024m")
# 
# Supported units: 
#	megabytes (m)
#	gigabytes (g)
parse_to_get_megabytes() {
	local value=$1
	if [[ ${value} =~ ([0-9]+)[gG]{1} ]]; then
		value=$((${BASH_REMATCH[1]} * 1024))
	elif [[ ${value} =~ ([0-9]+)[mM]{1} ]]; then	
		value=${BASH_REMATCH[1]}
	fi
	echo ${value}
}

print_mem_info() {
	local info="Total available memory:\t ${SYSTEM_TOTAL_MEMORY_MB}MB\n
	OS memory:\t\t ${OS_MEM}MB\n
	Server memory:\t\t ${CLOVER_SERVER_HEAP_SIZE}MB\n
	Worker memory:\t\t ${CLOVER_WORKER_HEAP_SIZE}MB\n
	ReservedCodeCacheSize:\t ${RESERVED_CODE_CACHE_SIZE}MB\n
	maxCachedBufferSize:\t ${MAX_CACHED_BUFFER_SIZE}"
	echo ${info}
}

compute_memory() {
	local available_mem=$(available_memory)
	
	if [ ! -z ${available_mem} ]; then
		export SYSTEM_TOTAL_MEMORY=${available_mem}
		SYSTEM_TOTAL_MEMORY_MB=$(bytes_to_megabytes "${available_mem}")
		if [ ${available_mem} -lt ${MIN_MEMORY_SIZE} ]; then
			>&2 echo "Insufficient memory set, expected at least $(bytes_to_megabytes "${MIN_MEMORY_SIZE}")MB, got ${SYSTEM_TOTAL_MEMORY_MB}MB."
			exit 1
		fi	
	else
		SYSTEM_TOTAL_MEMORY_MB=$(bytes_to_megabytes "${MIN_MEMORY_SIZE}")
	fi

	export CLOVER_SERVER_HEAP_SIZE=$(parse_to_get_megabytes "$CLOVER_SERVER_HEAP_SIZE")
	export CLOVER_WORKER_HEAP_SIZE=$(parse_to_get_megabytes "$CLOVER_WORKER_HEAP_SIZE")

	if [[ ${SERVER_JAVA_OPTS} =~ -Xmx([0-9]+[mMgG]?) ]]; then
		export CLOVER_SERVER_HEAP_SIZE=$(parse_to_get_megabytes "${BASH_REMATCH[1]}")
	fi
	
	if [ -z ${CLOVER_SERVER_HEAP_SIZE} ] && [ ! -z ${CLOVER_WORKER_HEAP_SIZE} ]; then
		>&2 echo "Parameter CLOVER_SERVER_HEAP_SIZE is not set."
		exit 1
	fi

	if [ ! -z ${CLOVER_SERVER_HEAP_SIZE} ] && [ -z ${CLOVER_WORKER_HEAP_SIZE} ]; then
		>&2 echo "Parameter CLOVER_WORKER_HEAP_SIZE is not set."
		exit 1
	fi

	QUARTER_OF_MEMORY=$((${SYSTEM_TOTAL_MEMORY_MB}/4))

	if [ -z ${CLOVER_SERVER_HEAP_SIZE} ]; then
		export CLOVER_SERVER_HEAP_SIZE=$(($QUARTER_OF_MEMORY > 8192 ? 8192 : $QUARTER_OF_MEMORY))
	fi

	if [ ${SYSTEM_TOTAL_MEMORY_MB} -lt 8192 ]; then
		export RESERVED_CODE_CACHE_SIZE=128
		export MAX_CACHED_BUFFER_SIZE=65536
	elif [ ${SYSTEM_TOTAL_MEMORY_MB} -lt 16384 ]; then
		export RESERVED_CODE_CACHE_SIZE=256
		export MAX_CACHED_BUFFER_SIZE=65536
	elif [ ${SYSTEM_TOTAL_MEMORY_MB} -lt 32768 ]; then
		export RESERVED_CODE_CACHE_SIZE=256
		export MAX_CACHED_BUFFER_SIZE=131072
	elif [ ${SYSTEM_TOTAL_MEMORY_MB} -lt 65536 ]; then
		export RESERVED_CODE_CACHE_SIZE=256
		export MAX_CACHED_BUFFER_SIZE=262144
	else
		export RESERVED_CODE_CACHE_SIZE=512
		export MAX_CACHED_BUFFER_SIZE=262144
	fi

	export OS_MEM=$(($QUARTER_OF_MEMORY-$RESERVED_CODE_CACHE_SIZE > 8192 ? 8192 : $QUARTER_OF_MEMORY-$RESERVED_CODE_CACHE_SIZE))

	if [ -z $CLOVER_WORKER_HEAP_SIZE ]; then
		export CLOVER_WORKER_HEAP_SIZE=$((${SYSTEM_TOTAL_MEMORY_MB} - (${OS_MEM} + ${CLOVER_SERVER_HEAP_SIZE} + ${RESERVED_CODE_CACHE_SIZE})))
	fi

	if [ ${CLOVER_SERVER_HEAP_SIZE} -lt ${MIN_SERVER_HEAP_SIZE} ]; then
		>&2 echo "Server's heap memory is too low. It must be at least ${MIN_SERVER_HEAP_SIZE}MB."
		>&2 echo -e $(print_mem_info)
		exit 1
	fi

	if [ ${CLOVER_WORKER_HEAP_SIZE} -lt ${MIN_WORKER_HEAP_SIZE} ]; then
		>&2 echo "Worker's heap memory is too low. It must be at least ${MIN_WORKER_HEAP_SIZE}MB."
		>&2 echo -e $(print_mem_info)
		exit 1
	fi
}
