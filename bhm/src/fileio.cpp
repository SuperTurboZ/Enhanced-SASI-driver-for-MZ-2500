/*
	Indel HEX file loader
*/
#include <stdio.h>
#include <memory.h>
#include <ctype.h>
#include <string.h>
#include <stdarg.h>

#ifdef _MSC_VER
__pragma(warning(disable:4996))
#endif

/***************************************************
文字からhexに変換
***************************************************/
static int char2hex(char code)
{
	if(code>='0' && code<='9') return code-'0';
	code |= 0x20;
	if(code>='a' && code<='f') return code-'a'+10;
	return -1; // HEX以外の文字
}

/***************************************************
文字列からhex値を取得
***************************************************/
static int str2hex(const char *src,int digit)
{
	int h;
	int n;
	int result;
	
	result = 0;
	for(n=0;n<digit;n++)
	{
		if( (h=char2hex(src[n])) < 0) return -1; // error
		result = result*16 + h;
	}
	return result;
}

/***************************************************
***************************************************/
int ihexLoad(unsigned char *buf,const char *file_path,int address_offset)
{
	FILE *fp = NULL;
	//
	char lbuf[512];
	int lsize;
	char line;
	//
	int linelen;
	int addr;
	int ext;
	unsigned char ldata[64];
	unsigned char calc_sum;
	int err;
	int i;
	int num_loaded;
	
	num_loaded = 0;
	printf("load intel HEX '%s'\n",file_path);

	if(!(fp = fopen(file_path,"rt")))
	{
		printf("Can't open src file\n");
		return -1;
	}
	// 
	line=1;
	while( fgets(lbuf,512,fp) !=0)
	{
		err = 0;
		lsize = strlen(lbuf);
		
		if(lbuf[0]!=':') continue;
		linelen = str2hex(&lbuf[1],2);
		addr    = str2hex(&lbuf[3],4);
		ext     = str2hex(&lbuf[7],2);
//printf("LEN %02X ADDR %04X EXT %02X\n",linelen,addr,ext);
		if(linelen<0 || addr<0 || ext<0 || lsize<(1+2+4+2+linelen*2+2) )
		{
			err|=1;
		}
		else if(linelen>0)
		{
			for(i=0;i<linelen;i++)
			{
				ldata[i] = str2hex(&(lbuf[1+2+4+2+i*2]),2);
			}
			// sum
			calc_sum = 0;
			for(i=0;i<(1+2+1+linelen+1);i++)
			{
				calc_sum += str2hex(&lbuf[1+i*2],2);
			}
			if(calc_sum != 0 ) err |= 2;
		}
		if(err)
		{
			if(err&1) printf("ERROR:format line %d:%s\n",line,lbuf);
			if(err&2) printf("ERROR:checksum %d:%s:%02X\n",line,lbuf,calc_sum);
		}
		else
		{
			// write line data
			memcpy(&(buf[address_offset +addr]),ldata,linelen);
			num_loaded += linelen;
		}
		line++;
	}
	fclose(fp);
	return num_loaded;
}

/***************************************************
***************************************************/
int binLoad(unsigned char *dst_buf,const char *file_path,int file_offset ,int load_size)
{
	FILE *fp = NULL;
	size_t readed;
	
	//printf("load binary '%s'\n",file_path);

	// open
	if(!(fp = fopen(file_path,"rb")))
	{
		printf("Can't open load file\n");
		return -1;
	}
	// seek
	if(file_offset >0)
	{
		if( fseek(fp,file_offset,SEEK_SET) != 0)
		{
			printf("Seek error\n");
			fclose(fp);
			return -1;
		}
	}
	// read
	if( (readed=fread(dst_buf,1,load_size,fp)) <= 0)
	{
		printf("file read error\n");
		fclose(fp);
		return -1;
	}
	fclose(fp);
	return readed;
}

/***************************************************
***************************************************/
int binSave(unsigned char *dst_buf,const char *file_path,int file_offset ,int save_size)
{
	FILE *fp = NULL;
	size_t writed;
	//
	//char *openMode;
	//printf("save binary '%s'\n",file_path);

	// open write file
	if (file_offset < 0)
	{
		// trunc  mode
		fp = fopen(file_path, "wb");
	}
	else
	{
		// insert mode
		fp = fopen(file_path, "r+b");
	}

	if(!fp)
	{
		printf("Can't open save file\n");
		return -1;
	}
	if(file_offset > 0 && fseek(fp,file_offset,SEEK_SET) != 0)
	{
		printf("Seek error\n");
		fclose(fp);
		return -1;
	}
	if( (writed=fwrite(dst_buf,1,save_size,fp)) != save_size)
	{
		printf("file write error\n");
		fclose(fp);
		return -1;
	}
	fclose(fp);
	return writed;
}
