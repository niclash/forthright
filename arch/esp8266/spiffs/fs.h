#ifndef __FS_H
#define __FS_H

#define SPI_FLASH_PHYS_SIZE  (0x300000-0x8000)
#define SPI_FLASH_START_ADDR 0x100000

#define SPI_FLASH_SEC_SIZE 4096
#define LOG_PAGE_SIZE (SPI_FLASH_SEC_SIZE/8)
#define FS_FILE_DESCRIPTOR_SIZE 128
#define FS_CACHE_SIZE ((LOG_PAGE_SIZE+32)*4)

bool indoorio_fs_init();

#endif
