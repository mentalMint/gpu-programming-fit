#include <cuda_runtime.h>
#include <png.h>
#include <iostream>
#include <vector>
#include <chrono>
#include <algorithm>

#define BLOCK 32
#define R 1

// =======================================================
// ==================== PNG LOADER =======================
// =======================================================
unsigned char *loadPNG(const char *filename, int &width, int &height)
{
    FILE *fp = fopen(filename, "rb");
    if (!fp)
    {
        std::cerr << "Cannot open " << filename << "\n";
        return nullptr;
    }

    png_structp png = png_create_read_struct(
        PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
    png_infop info = png_create_info_struct(png);

    png_init_io(png, fp);
    png_read_info(png, info);

    width = png_get_image_width(png, info);
    height = png_get_image_height(png, info);

    if (png_get_color_type(png, info) != PNG_COLOR_TYPE_GRAY)
    {
        std::cerr << "Only grayscale PNG supported\n";
        exit(1);
    }

    png_read_update_info(png, info);

    unsigned char *data = new unsigned char[width * height];
    std::vector<png_bytep> rows(height);

    for (int y = 0; y < height; y++)
        rows[y] = data + y * width;

    png_read_image(png, rows.data());
    fclose(fp);
    return data;
}

// =======================================================
// ==================== PNG SAVER ========================
// =======================================================
void savePNG(const char *filename, unsigned char *img, int w, int h)
{
    FILE *fp = fopen(filename, "wb");

    png_structp png =
        png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
    png_infop info = png_create_info_struct(png);

    png_init_io(png, fp);

    png_set_IHDR(
        png, info, w, h, 8,
        PNG_COLOR_TYPE_GRAY,
        PNG_INTERLACE_NONE,
        PNG_COMPRESSION_TYPE_BASE,
        PNG_FILTER_TYPE_BASE);

    png_write_info(png, info);

    std::vector<png_bytep> rows(h);
    for (int y = 0; y < h; y++)
        rows[y] = img + y * w;

    png_write_image(png, rows.data());
    png_write_end(png, nullptr);
    fclose(fp);
}

// =======================================================
// ================= SHARED MEMORY KERNEL ================
// =======================================================
__global__ void conv3_shared(const unsigned char *in,
                             unsigned char *out,
                             int w, int h,
                             const float *kernel)
{
    __shared__ unsigned char tile[BLOCK + 2 * R][BLOCK + 2 * R];

    int x = blockIdx.x * BLOCK + threadIdx.x;
    int y = blockIdx.y * BLOCK + threadIdx.y;
    int lx = threadIdx.x + R;
    int ly = threadIdx.y + R;

    int gx = min(max(x, 0), w - 1);
    int gy = min(max(y, 0), h - 1);

    tile[ly][lx] = in[gy * w + gx];

    if (threadIdx.x < R)
    {
        tile[ly][lx - R] =
            in[gy * w + min(max(x - R, 0), w - 1)];
        tile[ly][lx + BLOCK] =
            in[gy * w + min(max(x + BLOCK, 0), w - 1)];
    }

    if (threadIdx.y < R)
    {
        tile[ly - R][lx] =
            in[min(max(y - R, 0), h - 1) * w + gx];
        tile[ly + BLOCK][lx] =
            in[min(max(y + BLOCK, 0), h - 1) * w + gx];
    }

    if (threadIdx.x < R && threadIdx.y < R)
    {
        tile[ly - R][lx - R] =
            in[min(max(y - R, 0), h - 1) * w +
               min(max(x - R, 0), w - 1)];
        tile[ly - R][lx + BLOCK] =
            in[min(max(y - R, 0), h - 1) * w +
               min(max(x + BLOCK, 0), w - 1)];
        tile[ly + BLOCK][lx - R] =
            in[min(max(y + BLOCK, 0), h - 1) * w +
               min(max(x - R, 0), w - 1)];
        tile[ly + BLOCK][lx + BLOCK] =
            in[min(max(y + BLOCK, 0), h - 1) * w +
               min(max(x + BLOCK, 0), w - 1)];
    }

    __syncthreads();

    if (x >= w || y >= h)
        return;

    float sum = 0.0f;
    for (int dy = -R; dy <= R; dy++)
        for (int dx = -R; dx <= R; dx++)
            sum += kernel[(dy + 1) * 3 + (dx + 1)] *
                   tile[ly + dy][lx + dx];

    out[y * w + x] =
        (unsigned char)min(max(sum, 0.0f), 255.0f);
}

// =======================================================
// ========================== MAIN =======================
// =======================================================
int main()
{
    int W, H;
    unsigned char *h_in = loadPNG("input.png", W, H);
    if (!h_in)
        return 1;

    size_t size = W * H;
    unsigned char *h_out = new unsigned char[size];

    float h_kernel[9] = {
        -1.f, 0.f, 1.f,
        -2.f, 0.f, 2.f,
        -1.f, 0.f, 1.f};

    int gpuCount = 0;
    cudaGetDeviceCount(&gpuCount);
    if (gpuCount == 0)
    {
        std::cerr << "No CUDA devices found\n";
        return 1;
    }

    for (int i = 0; i < gpuCount; ++i)
    {
        cudaDeviceProp prop{};             // Initialize a cudaDeviceProp structure
        cudaGetDeviceProperties(&prop, i); // Get properties for device 'i'

        std::cout << "--- Device Number: " << i << " ---" << std::endl;
        std::cout << "  Device Name: " << prop.name << std::endl;
        std::cout << "  Compute Capability: " << prop.major << "." << prop.minor << std::endl;
        std::cout << "  Total Global Memory (bytes): " << prop.totalGlobalMem << std::endl;
        std::cout << "  Max Threads per Block: " << prop.maxThreadsPerBlock << std::endl;
        std::cout << "  Multiprocessor Count: " << prop.multiProcessorCount << std::endl;
        std::cout << "  Clock Rate (kHz): " << prop.clockRate << std::endl;
        std::cout << "  Shared Memory per Block (bytes): " << prop.sharedMemPerBlock << std::endl;
        std::cout << "  Warp Size: " << prop.warpSize << std::endl;
        std::cout << "  ECC Enabled: " << (prop.ECCEnabled ? "Yes" : "No") << std::endl;
        std::cout << std::endl;
    }

    std::cout << "GPUs detected: " << gpuCount << "\n";

    int rowsPerGPU = H / gpuCount;

    std::vector<cudaEvent_t> start(gpuCount), stop(gpuCount);
    std::vector<cudaStream_t> stream(gpuCount);

    for (int dev = 0; dev < gpuCount; dev++)
    {
        cudaSetDevice(dev);
        cudaEventCreate(&start[dev]);
        cudaEventCreate(&stop[dev]);
        cudaStreamCreate(&stream[dev]);
    }

    for (int dev = 0; dev < gpuCount; dev++)
    {
        cudaSetDevice(dev);

        int yStart = dev * rowsPerGPU;
        int yEnd = (dev == gpuCount - 1) ? H : yStart + rowsPerGPU;
        int localH = yEnd - yStart;

        int haloTop = (yStart == 0) ? 0 : R;
        int haloBottom = (yEnd == H) ? 0 : R;
        int copyH = localH + haloTop + haloBottom;

        unsigned char *d_in, *d_out;
        float *d_kernel;

        cudaMallocAsync(&d_in, W * copyH, stream[dev]);
        cudaMallocAsync(&d_out, W * localH, stream[dev]);
        cudaMallocAsync(&d_kernel, 9 * sizeof(float), stream[dev]);

        cudaMemcpyAsync(d_kernel, h_kernel,
                        9 * sizeof(float),
                        cudaMemcpyHostToDevice, stream[dev]);

        cudaMemcpyAsync(d_in,
                        h_in + (yStart - haloTop) * W,
                        W * copyH,
                        cudaMemcpyHostToDevice,
                        stream[dev]);

        dim3 block(BLOCK, BLOCK);
        dim3 grid((W + BLOCK - 1) / BLOCK,
                  (localH + BLOCK - 1) / BLOCK);

        cudaEventRecord(start[dev], stream[dev]);
        conv3_shared<<<grid, block, 0, stream[dev]>>>(d_in, d_out, W, localH, d_kernel);
        cudaEventRecord(stop[dev], stream[dev]);

        cudaMemcpyAsync(h_out + yStart * W,
                        d_out,
                        W * localH,
                        cudaMemcpyDeviceToHost, stream[dev]);

        cudaFreeAsync(d_in, stream[dev]);
        cudaFreeAsync(d_out, stream[dev]);
        cudaFreeAsync(d_kernel, stream[dev]);
    }

    for (int dev = 0; dev < gpuCount; dev++)
    {
        cudaSetDevice(dev);
        cudaEventSynchronize(stop[dev]);

        float ms = 0.0f;
        cudaEventElapsedTime(&ms, start[dev], stop[dev]);
        std::cout << "GPU " << dev
                  << " kernel time: "
                  << ms << " ms\n";

        cudaEventDestroy(start[dev]);
        cudaEventDestroy(stop[dev]);
        cudaStreamDestroy(stream[dev]);
    }

    savePNG("output.png", h_out, W, H);

    delete[] h_in;
    delete[] h_out;

    std::cout << "Done\n";
    return 0;
}
