export VM_NAME=alpine
export RAM_SIZE=2048
export CPU_CORES=6
export ISO_FILE=alpine.iso
export DISK_FILE=alpine.qcow2
export DISK_SIZE=20G
export LOG_FILE=qemu.log
# export VERSION=latest-stable
# export ISO_URL=https://dl-cdn.alpinelinux.org/alpine/v${VERSION}/releases/x86_64/alpine-virt-${VERSION}.0-x86_64.iso
export ISO_URL=https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-extended-3.20.0-x86_64.iso


run: alpine.iso alpine.qcow2
	qemu-system-x86_64 -name ${VM_NAME} -m ${RAM_SIZE} -smp ${CPU_CORES} \
		-drive file=${DISK_FILE},if=virtio \
		-netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=tcp::15432-:5432 \
		-device virtio-net,netdev=n1 \
		-vnc :0 -nographic -serial mon:stdio
clean:
	rm alpine.iso alpine.qcow2
reset:
	rm alpine.qcow2

alpine.iso:
	curl -o alpine.iso ${ISO_URL}
alpine.qcow2:
	qemu-img create -f qcow2 alpine.qcow2 ${DISK_SIZE}

build: alpine.iso alpine.qcow2
	qemu-system-x86_64 -name ${VM_NAME} -m ${RAM_SIZE} -smp ${CPU_CORES} \
		-drive file=${DISK_FILE},if=virtio \
		-netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=tcp::15432-:5432 \
		-device virtio-net,netdev=n1 \
		-vnc :1  -display none -nographic \
		-boot d -cdrom ${ISO_FILE}
		# -D $LOG_FILE 2>&1 | tee $LOG_FILE \
