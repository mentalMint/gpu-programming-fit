# Лабораторная 3
## Задача
Реализовать программу для накладывания фильтров на изображения. Возможные фильтры: размытие, выделение границ, избавление от шума. Использовать 2 видеокарты.

## Характеристики устройства GPU
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.05              Driver Version: 560.35.05      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla V100-PCIE-16GB           On  |   00000000:61:00.0 Off |                    0 |
| N/A   37C    P0             27W /  250W |     253MiB /  16384MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
|   1  Tesla V100-PCIE-16GB           On  |   00000000:DB:00.0 Off |                    0 |
| N/A   58C    P0            106W /  250W |    7098MiB /  16384MiB |    100%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
                                                                                         
+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A   1527321      G   /usr/libexec/Xorg                             108MiB |
|    0   N/A  N/A   1527558      G   /usr/bin/gnome-shell                          143MiB |
|    1   N/A  N/A   1555503      C   ./LBM_CUDA                                   7094MiB |
+-----------------------------------------------------------------------------------------+

--- Device Number: 0 ---
  Device Name: Tesla V100-PCIE-16GB
  Compute Capability: 7.0
  Total Global Memory (bytes): 16928342016
  Max Threads per Block: 1024
  Multiprocessor Count: 80
  Clock Rate (kHz): 1380000
  Shared Memory per Block (bytes): 49152
  Warp Size: 32
  ECC Enabled: Yes

--- Device Number: 1 ---
  Device Name: Tesla V100-PCIE-16GB
  Compute Capability: 7.0
  Total Global Memory (bytes): 16928342016
  Max Threads per Block: 1024
  Multiprocessor Count: 80
  Clock Rate (kHz): 1380000
  Shared Memory per Block (bytes): 49152
  Warp Size: 32
  ECC Enabled: Yes
```

## Компиляция и запуск
```console
nvcc -o lab3 lab3.cu -lpng
./lab3
```

## Вывод программы
```
GPUs detected: 2
GPU 0 kernel time: 13.9332 ms
GPU 1 kernel time: 4.72755 ms
Done
```
## Выводы
Программа выполняется разное количество времени на каждой из видеокарт так как они загружены по-разному.
