resource "yandex_compute_disk" "disk" {
  count = 3
  name  = "disk-${count.index + 1}"
  size  = 1
}

# Одиночная ВМ: без count и for_each
resource "yandex_compute_instance" "storage" {
  name        = "storage"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }

  # Диски подключаются через dynamic-блок; ключ — индекс, известный на этапе плана
  dynamic "secondary_disk" {
    for_each = { for i, d in yandex_compute_disk.disk : i => d }
    content {
      disk_id = secondary_disk.value.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = local.vm_metadata
}
