#include <esp_common.h>
#include <fcntl.h>
#include <spiffs/spiffs.h>
#include <spiffs/spiffs_nucleus.h>
#include "fs.h"

static spiffs fs;

static u8_t *spiffs_work_buf;
static u8_t *spiffs_fd_buf;
static u8_t *spiffs_cache_buf;

static const signed char *const task_name = (const signed char *const) "fs";
static xTaskHandle indoorio_task_fs;

static void report_error(char *check, s32_t errors);

#define FLASH_UNIT_SIZE 4

static s32_t ICACHE_FLASH_ATTR hal_readwrite(u32_t addr, u32_t size, u8_t *p, int write) {
    /*
     * With proper configurarion fs never reads or writes more than
     * LOG_PAGE_SIZE
     */

    if (size > fs.cfg.log_page_size) {
        printf("Invalid size provided to read/write (%d)\n\r", (int) size);
        return SPIFFS_ERR_NOT_CONFIGURED;
    }

    char tmp_buf[fs.cfg.log_page_size + FLASH_UNIT_SIZE * 2];
    u32_t aligned_addr = addr & (-FLASH_UNIT_SIZE);
    u32_t aligned_size = ((size + (FLASH_UNIT_SIZE - 1)) & -FLASH_UNIT_SIZE) + FLASH_UNIT_SIZE;

    int res = spi_flash_read(aligned_addr, (u32_t *) tmp_buf, aligned_size);

    if (res != 0) {
        printf("...spi_flash_read failed: %d (%d, %d)\n\r", res, (int) aligned_addr,
               (int) aligned_size);
        return res;
    }

    if (!write) {
        memcpy(p, tmp_buf + (addr - aligned_addr), size);
        return SPIFFS_OK;
    }

    memcpy(tmp_buf + (addr - aligned_addr), p, size);

    res = spi_flash_write(aligned_addr, (u32_t *) tmp_buf, aligned_size);

    if (res != 0) {
        return res;
    }

    return SPIFFS_OK;
}

static s32_t ICACHE_FLASH_ATTR hal_read(u32_t addr, u32_t size, u8_t *dst) {
    return hal_readwrite(addr, size, dst, 0);
}

static s32_t ICACHE_FLASH_ATTR hal_write(u32_t addr, u32_t size, u8_t *src) {
    return hal_readwrite(addr, size, src, 1);
}

static s32_t ICACHE_FLASH_ATTR hal_erase(u32_t addr, u32_t size) {
    /*
     * With proper configurarion fs always
     * provides here sector address & sector size
     */
    if (size != fs.cfg.phys_erase_block || addr % fs.cfg.phys_erase_block != 0) {
        printf("Invalid size provided to esp_spiffs_erase (%d, %d)\n\r",
               (int) addr, (int) size);
        return SPIFFS_ERR_NOT_CONFIGURED;
    }

    return spi_flash_erase_sector(addr / fs.cfg.phys_erase_block);
}

LOCAL s32_t ICACHE_FLASH_ATTR fs_init(struct esp_spiffs_config *config) {
    if (SPIFFS_mounted(&fs)) {
        return -1;
    }

    spiffs_config cfg;
    s32_t ret;

    cfg.phys_size = config->phys_size;
    cfg.phys_addr = config->phys_addr;
    cfg.phys_erase_block = config->phys_erase_block;
    cfg.log_block_size = config->log_block_size;
    cfg.log_page_size = config->log_page_size;

    cfg.hal_read_f = hal_read;
    cfg.hal_write_f = hal_write;
    cfg.hal_erase_f = hal_erase;

    if (spiffs_work_buf != NULL) {
        free(spiffs_work_buf);
        spiffs_work_buf = NULL;
    }
    spiffs_work_buf = malloc(config->log_page_size * 2);

    if (spiffs_work_buf == NULL) {
        return -1;
    }

    if (spiffs_fd_buf != NULL) {
        free(spiffs_fd_buf);
        spiffs_fd_buf = NULL;
    }
    spiffs_fd_buf = malloc(config->fd_buf_size);

    if (spiffs_fd_buf == NULL) {
        free(spiffs_work_buf);
        return -1;
    }

    if (spiffs_cache_buf != NULL) {
        free(spiffs_cache_buf);
        spiffs_cache_buf = NULL;
    }
    spiffs_cache_buf = malloc(config->cache_buf_size);

    if (spiffs_cache_buf == NULL) {
        free(spiffs_work_buf);
        free(spiffs_fd_buf);
        return -1;
    }

//    DEBUG("Mounting filesystem...\n")
    ret = SPIFFS_mount(&fs, &cfg, spiffs_work_buf,
                       spiffs_fd_buf, config->fd_buf_size,
                       spiffs_cache_buf, config->cache_buf_size,
                       0);

//    DEBUG("Filesystem mounted.\n")
    if (ret == -1) {
        free(spiffs_work_buf);
        free(spiffs_fd_buf);
        free(spiffs_cache_buf);
    }
    return ret;
}

void ICACHE_FLASH_ATTR fs_deinit(u8_t format) {
    if (SPIFFS_mounted(&fs)) {
        SPIFFS_unmount(&fs);
        free(spiffs_work_buf);
        free(spiffs_fd_buf);
        free(spiffs_cache_buf);

        if (format) {
            SPIFFS_format(&fs);
        }
    }
}

int ICACHE_FLASH_ATTR open(const char *filename, int flags, ...) {
    spiffs_mode sm = 0;
    int res;
    int rw = (flags & 3);

    if (rw == O_RDONLY || rw == O_RDWR) {
        sm |= SPIFFS_RDONLY;
    }

    if (rw == O_WRONLY || rw == O_RDWR) {
        sm |= SPIFFS_WRONLY;
    }

    if (flags & O_CREAT) {
        sm |= SPIFFS_CREAT;
    }

    if (flags & O_TRUNC) {
        sm |= SPIFFS_TRUNC;
    }

    if (flags & O_APPEND) {
        sm |= SPIFFS_APPEND;
    }

    /* Supported in newer versions of SPIFFS. */
    /* if (flags && O_EXCL) sm |= SPIFFS_EXCL; */
    /* if (flags && O_DIRECT) sm |= SPIFFS_DIRECT; */

    res = SPIFFS_open(&fs, (char *) filename, sm, 0);
    return res;
}

ssize_t ICACHE_FLASH_ATTR read(int fd, void *buf, size_t len) {
    ssize_t res;
    if (fd < 0) {
        res = -1;
    } else {
        res = SPIFFS_read(&fs, fd, buf, len);
        if (res) {
            ERROR("Error reading file: %d\n", fs.err_code);
        }
    }
    return res;
}

ssize_t ICACHE_FLASH_ATTR write(int fd, void *buf, size_t len) {
    if (fd < 0) {
        return -1;
    }

    int res = SPIFFS_write(&fs, fd, (char *) buf, len);
    return res;
}

off_t ICACHE_FLASH_ATTR lseek(int fd, off_t where, int whence) {

    ssize_t res;

    if (fd < 0) {
        res = -1;
    } else {
        res = SPIFFS_lseek(&fs, fd, where, whence);
    }

    return res;
}

int ICACHE_FLASH_ATTR close(int fd) {

    if (fd < 0) {
        return -1;
    }

    SPIFFS_close(&fs, fd);
    return 0;
}

int ICACHE_FLASH_ATTR rename(const char *from, const char *to) {

    int res = SPIFFS_rename(&fs, (char *) from, (char *) to);
    return res;
}

int ICACHE_FLASH_ATTR unlink(const char *filename) {
    int res = SPIFFS_remove(&fs, (char *) filename);
    return res;
}

int ICACHE_FLASH_ATTR fstat(int fd, struct stat *s) {

    int res;
    spiffs_stat ss;
    memset(s, 0, sizeof(struct stat *));

    res = SPIFFS_fstat(&fs, fd, &ss);

    if (res < 0) {
        return res;
    }

    s->st_ino = ss.obj_id;
    s->st_mode = 0666;
    s->st_nlink = 1;
    s->st_size = ss.size;
    return 0;
}

LOCAL void ICACHE_FLASH_ATTR list_files() {
    spiffs_DIR dir;
    SPIFFS_opendir(&fs, "", &dir);
    struct spiffs_dirent entry;
    printf("Flash Content:\n--------------\n");
    while (SPIFFS_readdir(&dir, &entry) != NULL) {
        printf("%s\n", entry.name);
    }
    SPIFFS_closedir(&dir);
}

//uint64_t ICACHE_FLASH_ATTR fs_size(char *filename) {
//    spiffs_stat stat;
//    SPIFFS_stat(&fs, filename, &stat);
//    return (uint64_t) stat.size;
//}
//
//int ICACHE_FLASH_ATTR fs_read_text(char *filename, char *buffer, unsigned long bufferSize) {
//    spiffs_file fh = SPIFFS_open(&fs, filename, SPIFFS_RDONLY, 0);
//    if (!fh) {
//        ERROR("Failed to read file ");
//        ERROR(filename);
//        buffer[0] = '\0';
//        return 0;
//    }
//    INFO("[FS] buffersize: %d", bufferSize);
//    INFO("[FS] pointer: %d", (uint32_t) buffer);
//    s32_t bytesRead = SPIFFS_read(&fs, fh, buffer, bufferSize - 1);
//    buffer[bytesRead] = '\0';
//    SPIFFS_close(&fs, fh);
//    INFO(buffer);
//    return bytesRead;
//}

void ICACHE_FLASH_ATTR fs_task(void *arg) {
    DEBUG("Starting FS task.\n");

    struct esp_spiffs_config config;

    INFO("Initializing Filesystem.\n");

    // physical size of the spi flash
    config.phys_size = SPI_FLASH_PHYS_SIZE;
    // physical offset in spi flash used for fs,
    // must be on block boundary
    config.phys_addr = SPI_FLASH_START_ADDR;
    // physical size when erasing a block
    config.phys_erase_block = SPI_FLASH_SEC_SIZE;

    // logical size of a block, must be on physical
    // block size boundary and must never be less than
    // a physical block
    config.log_block_size = SPI_FLASH_SEC_SIZE;

    // logical size of a page, must be at least
    // log_block_size / 8
    config.log_page_size = LOG_PAGE_SIZE;

    config.fd_buf_size = FS_FILE_DESCRIPTOR_SIZE;
    config.cache_buf_size = FS_CACHE_SIZE;
    if (fs_init(&config)) {
        ERROR("Unable to mount filesystem!!!!");
    } else {
        INFO("Filesystem initialized successfully.\n\n");
        list_files();
    }

    s32_t error = spiffs_lookup_consistency_check(&fs, true);
    report_error("Lookup Consistency", error);
    error = spiffs_page_consistency_check(&fs);
    report_error("Page Consistency", error);
    error = spiffs_object_index_consistency_check(&fs);
    report_error("Index Consistency", error);
    vTaskDelete(indoorio_task_fs);
}

void ICACHE_FLASH_ATTR report_error(char *check, s32_t error) {
    if (error == SPIFFS_OK) {
        DEBUG("%s - OK\n", check);
    } else {
        DEBUG("%s - Error: %d\n", check, error);
    }
}

bool ICACHE_FLASH_ATTR indoorio_fs_init() {

    return xTaskCreate(fs_task, task_name, 512, NULL, 2, &indoorio_task_fs) == pdPASS;
}
