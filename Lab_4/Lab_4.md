# Лабораторная 4
## Задача
Разобрать программы из глав 6, 7 методического пособия, запустить, замерить время, сравнить по производительности, уметь объяснять работу программ детально

## Характеристики устройства GPU
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.05              Driver Version: 560.35.05      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Quadro RTX 4000                On  |   00000000:01:00.0 Off |                  N/A |
| 30%   32C    P8             11W /  125W |     190MiB /   8192MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
                                                                                         
+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A      2263      G   /usr/libexec/Xorg                              94MiB |
|    0   N/A  N/A      2827      G   /usr/bin/gnome-shell                           92MiB |
+-----------------------------------------------------------------------------------------+
Compilation successful!
--- Device Number: 0 ---
  Device Name: Quadro RTX 4000
  Compute Capability: 7.5
  Total Global Memory (bytes): 8167620608
  Max Threads per Block: 1024
  Multiprocessor Count: 36
  Clock Rate (kHz): 1545000
  Shared Memory per Block (bytes): 49152
  Warp Size: 32
  ECC Enabled: No
```

## Компиляция и запуск
```console
nvcc -o specs specs.cu
nvcc -o compare compare.cu
nvcc -o transpose transpose.cu
nvcc -arch=sm_75 --use_fast_math -o multiply multiply.cu
nvcc -arch=sm_75 --use_fast_math -o multiply_opt multiply_opt.cu

echo "Compilation successful!"
./specs

echo "=== Running lab4 ==="
echo "--- Compare ---"
./compare
echo
echo "---------------"
echo "--- Transpose ---"
./transpose
echo
echo "-----------------"
echo "--- Multiply ---"
./multiply
echo
echo "--------------"
echo "--- Multiply optimized ---"
./multiply_opt
echo
echo "--------------------------"
```

## Вывод программы
```
=== Running lab4 ===
--- Compare ---
Start
---------------
--- Transpose ---
rows = 1008
cols = 2000
KernelTime: 1.85 milliseconds

-----------------
--- Multiply ---
Arows = 1008
Acols = 2000
Brows = 2000
Bcols = 1504
KernelTime: 36.49 milliseconds
Test STARTED
Test PASSED

--------------
--- Multiply optimized ---
Arows = 1008
Acols = 2000
Brows = 2000
Bcols = 1504
KernelTime: 36.02 milliseconds
Test STARTED
Test PASSED

--------------------------
```
## Выводы
Оптимизированная программа по умножению матриц выполняется быстрее благодаря использованию разделяемой памяти.
