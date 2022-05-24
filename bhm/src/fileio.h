#ifndef _FILEIO_H_
#define _FILEIO_H_

int ihexLoad(unsigned char *buf,const char *file_path,int address_offset);
int binLoad(unsigned char *dst_buf,const char *file_path,int file_offset ,int load_size);
int binSave(unsigned char *dst_buf,const char *file_path,int file_offset ,int save_size);

#endif
