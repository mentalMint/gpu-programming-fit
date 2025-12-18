# Лабораторная 2
## Задача
Реализовать программу для накладывания фильтров на изображения. Возможные фильтры: размытие, выделение границ, избавление от шума. Реализовать два варианта программы, а именно: с применением разделяемой памяти и текстур. Сравнить время.

## Характеристики устройства GPU
Device Name: Tesla T4 \
Compute Capability: 7.5 \
Total Global Memory (bytes): 15828320256 \
Max Threads per Block: 1024 \
Multiprocessor Count: 40 \
Clock Rate (kHz): 1590000 \
Shared Memory per Block (bytes): 49152 \
Warp Size: 32 \
ECC Enabled: Yes

## Компиляция и запуск
#### *Запуск осуществлялся в Google Colab*
```console
!nvcc -arch=sm_75 --use_fast_math filters.cu -o filters -lpng -lz
!./filters 10000
```

## Вывод программы
Iterations number: 10000 \
Shared memory time (avg): 47764 ns \
Texture memory time (avg): 40803 ns \

## Выводы
Использование текстурной памяти ускоряет программу в ~1.17 раз. Это происходит благодаря переиспользованию значений пикселей. 
