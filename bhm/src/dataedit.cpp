/*******************************************************************************
	Binary & Hex file editor
*******************************************************************************/

/*******************************************************************************
*******************************************************************************/
#include <windows.h>

#include <stdio.h>
//#include <conio.h>
#include <time.h>
#include <string.h>
#include <ctype.h>

#include "fileio.h"

#ifdef _MSC_VER
__pragma(warning(disable:4996))
#endif

/*******************************************************************************
title / version string
*******************************************************************************/
static const char app_name[]=
"Bin/Hex data Manager";

static const char app_version[]=
"Version 2021. 4.22";

static const char strFullSpec[]=" \n";

static const char strPrompt[]="BHM>";

/****************************************************************************
UI parameter handling
****************************************************************************/
static unsigned char mem_buf[16*1024*1024];

static int appResult;

/****************************************************************************
UI parameter handling
****************************************************************************/
#define CMD_STS_OK         0
#define CMD_STS_PARAM_ERR  1
#define CMD_STS_FORMAT_ERR 2
#define CMD_STS_FILE_ERR   4

int ui_get_dec(const char *argv,int *pvalue,int min,int max)
{
	long val = strtol( argv, NULL , 0 );
	*pvalue = (int)val;
	if( (val < min) || (val > max) ) return CMD_STS_PARAM_ERR;
	return CMD_STS_OK;
}

int ui_get_hex(const char *argv,int *pvalue,int min,int max)
{
	if(sscanf(argv,"%x",pvalue)<1) return CMD_STS_FORMAT_ERR;
	if( (*pvalue < min) || (*pvalue > max) ) return CMD_STS_PARAM_ERR;
	return CMD_STS_OK;
}

int ui_get_address(const char *argv,int *paddress)
{
	return ui_get_hex(argv,paddress,0x0000,0xffff);
}

int ui_get_address_border(const char *argv,int *paddress)
{
	if(sscanf(argv,"%x",paddress)<1) return CMD_STS_FORMAT_ERR;

	if( (*paddress < 0) || (*paddress >=0x10000) || (*paddress & 1) )
			return CMD_STS_PARAM_ERR;
	return CMD_STS_OK;
}

/****************************************************************************
Command Table Struct / List
****************************************************************************/
typedef struct struct_cmd_array
{
	const char *name;
	int (*func)(int argc,char **argv);
	const char *help;
}CMD_ARRAY;

static int cmd_help(int argc,char **argv);
static int cmd_reset(int argc,char **argv);
static int cmd_spec(int argc,char **argv);
static int cmd_load(int argc,char **argv);
static int cmd_save(int argc,char **argv);
static int cmd_channel(int argc,char **argv);

static int cmd_dump(int argc,char **argv);
static int cmd_memory(int argc, char** argv);
static int cmd_copy(int argc,char **argv);

static const CMD_ARRAY command[]=
{
	{"?"		,cmd_help	,": HELP"},
	{"HELP"		,cmd_help	,": HELP"},
	{"QUIT"		,NULL		,": QUIT"},
	{"COPY"		,cmd_copy	,"[DST] [SRC] [SIZE] : COPY MEMORY"},
	{"DUMP"		,cmd_dump	,"{[ADDRESS] {[length]} } : DUMP MEMORY"},
	{"MEMORY"	,cmd_memory	,"[ADDRESS] {[DATA] {[SIZE]} } : DISP/SET/FILL memory"},
	{"LOAD"		,cmd_load	,"[file_path] {[memory_offset] {size} } : Load BIN/HEX file"},
	{"SAVE"		,cmd_save	,"[file_path] [memory_offset] [size] {[file_offset]} : Save BIN file"},
	
//	{"SPEC"		,cmd_spec	,":show full specification"},
	//	{"SAVE"		,cmd_load	,"[file_path] [ADDRESS] [SIZE] : Save RAM area"},
	{NULL,NULL,NULL}
};
/****************************************************************************
Command Function
****************************************************************************/

static int cmd_dump(int argc,char **argv)
{
	static int dump_address = 0;
	static int dump_count = 0x100;
	int result;
	int i;

	if(argc>=2)
	{
		result = ui_get_address(argv[1],&dump_address);
		dump_address &= 0xfffe;
	}

	if(argc>=3)
	{
		result = ui_get_hex(argv[2],&dump_count,1,0x10000);
	}

	for(i=0;i<dump_count;i++)
	{
		if((i%16)==0) printf("%06X:",dump_address+i);
		// read memory
		printf("%02X%c",mem_buf[(dump_address+i)] , (i%16)==15 ? '\n' : ' ');
	}
	dump_address += i;

//	printf("DUMP 0x%06x 0x%x\n",dump_address,dump_count);
	return CMD_STS_OK;
}

/****************************************************************************
	COPY [dst] {src] [size] 
 ****************************************************************************/
static int cmd_copy(int argc,char **argv)
{
	int dst = 0;
	int src = 0;
	int size = 0;

	int result;

	if(argc<4) return CMD_STS_PARAM_ERR;
	result |= ui_get_hex(argv[1],&dst ,0,0xffff);
	result |= ui_get_hex(argv[2],&src ,0,0xffff);
	result |= ui_get_hex(argv[3],&size,0,0xffff);
	if(result != CMD_STS_OK)
		return result;

	printf("COPY [%06X-%06X] <- [%06X-%06X]\n"
		,dst,dst+size-1 , src, src + size-1);
	memmove(&mem_buf[dst],&mem_buf[src],size);

	return CMD_STS_OK;
}

/****************************************************************************
	MEMORY [ADDRESS] [DATA] {[LENGTH]}
****************************************************************************/
static int cmd_memory(int argc,char **argv)
{
	int address = 0;
	int writedata = 0;
	int length = 1;

	static int dump_count = 0x100;
	int result;
	int i;

	if(argc<2) return CMD_STS_PARAM_ERR;
	result = ui_get_hex(argv[1],&address,0,0xfffff);

	if(argc<3)
	{
		// MEMORY [ADDRESS] -- show
		printf("MEM[%06X]=%02X\n",address,mem_buf[(address)]);
		return CMD_STS_OK;
	}

	result = ui_get_hex(argv[2],&writedata,0,0xff);

	if(argc<4)
	{
		// MEMORY [ADDRESS] [DATA] -- set
		printf("MEM[%06X]=%02X<-%02X 'set\n",address,mem_buf[(address)],writedata);
		mem_buf[address] = writedata;
		return CMD_STS_OK;
	}

	// MEMORY [ADDRESS] [DATA] [LENGTH] -- fill
	result = ui_get_hex(argv[3],&length,0,0xfffff);
	printf("MEM[%06X-%06X]=%02X 'fill\n",address,address+length-1,writedata);
	for(i=0;i<length;i+=1)
	{
		mem_buf[(address+i)] = writedata;
	}
	return CMD_STS_OK;
}

#if 0
static int cmd_spec(int argc,char **argv)
{
	printf("%s\n%s",app_version,strFullSpec);
	return CMD_STS_OK;
}
#endif

static int cmd_load(int argc,char **argv)
{
	int result = -1;
	const char *filepath;
	int mem_offset   = 0;
	int load_size    = 0xffff;
	int file_offset  = 0;
	int err = CMD_STS_OK;
	int isHex = 0;
	int num_readed;
	
	if(argc<2) return CMD_STS_PARAM_ERR;
	/// filename
	filepath = argv[1];
	if(strstr(filepath,".HEX") || strstr(filepath,".hex") )
	{
		// interl hex mode
		isHex = 1;
	}
	// load address
	if(argc>=3)
	{
		err |= ui_get_dec(argv[2],&mem_offset,0,0xffff);
	}
	// size
	if(argc>=4)
	{
		err |= ui_get_dec(argv[3],&load_size,1,0x10000);
	}
	// file offset
	if(argc>=5)
	{
		err |= ui_get_dec(argv[4],&file_offset,0,0x7fffffff);
	}
	if(err != CMD_STS_OK)
	{
		printf("Parameter error\n");
		return CMD_STS_PARAM_ERR;
	}

	if( (mem_offset+load_size) > 0x10000)
	{
		load_size = 0x10000-mem_offset;
	}
	
	if(isHex)
	{
		printf("load HEX file %s,+0x%06X\n",argv[1],mem_offset);
		num_readed = ihexLoad(mem_buf+mem_offset,filepath ,file_offset);
	}else{ 
		printf("load BIN file %s[0x%06X] -> mem[0x%06X],size[0x%06X]\n",argv[1],file_offset ,mem_offset,load_size);
		
		num_readed= binLoad(mem_buf+mem_offset ,filepath,file_offset ,load_size);
	}
	if( num_readed < 0)
	{
		printf("load Error\n");
		return CMD_STS_FILE_ERR;
	}
	printf("%d bytes loaded\n",num_readed);
	return CMD_STS_OK;
}

static int cmd_save(int argc,char **argv)
{
	const char *filepath;
	int mem_offset   = 0;
	int save_size = 0x10000;
	int file_offset  = -1; // default , create mode
	int err = CMD_STS_OK;
	int isHex = 0;
	
	if(argc<4) return CMD_STS_PARAM_ERR;
	/// filename
	filepath = argv[1];
	if(strstr(filepath,".HEX") || strstr(filepath,".hex") )
	{
		// interl hex mode
		isHex = 1;
		printf("HEX file can't supported\n");
		return CMD_STS_PARAM_ERR;
	}
	// load address
	if(argc>=3)
	{
		err |= ui_get_dec(argv[2],&mem_offset,0,0xffff);
	}
	// size
	if(argc>=4)
	{
		err |= ui_get_dec(argv[3],&save_size,1,0x10000);
	}
	// file offset
	if(argc>=5)
	{
		err |= ui_get_dec(argv[4],&file_offset,0,0x7fffffff);
	}
	if(err != CMD_STS_OK)
	{
		printf("Parameter error\n");
		return CMD_STS_PARAM_ERR;
	}
	// limit data size
	if( (mem_offset+ save_size) > 0x10000)
	{
		save_size = 0x10000-mem_offset;
	}

	if(file_offset<0)
	{
		printf("save file '%s' <- mem[0x%06X],size[0x%06X]\n", argv[1], mem_offset, mem_offset+ save_size -1);
	}
	else
	{
		printf("update file '%s'[=0x%06X - 0x%06X] <- mem[0x%06X-0x%06X]\n", argv[1], file_offset, file_offset+ save_size -1, mem_offset, mem_offset + save_size - 1);
	}
	
	if( binSave(mem_buf+mem_offset ,filepath,file_offset , save_size) < 0)
	{
		printf("save Error\n");
		return CMD_STS_FILE_ERR;
	}
	return CMD_STS_OK;
}

/****************************************************************************
Command List
****************************************************************************/
static int cmd_help(int argc,char **argv)
{
	int cmd_no;

	// search command 
	for(cmd_no=0;command[cmd_no].name;cmd_no++)
	{
		printf("%-8s %s\n",command[cmd_no].name,command[cmd_no].help);
	}
	return 0;
}

/****************************************************************************
Command input
****************************************************************************/
char cmd_line[256];

int search_cmd_list(const CMD_ARRAY *cmd_list,const char *cmd)
{
	int cmd_no,hit_no;
	int cmp_len;

	for(cmp_len=strlen(cmd);cmp_len>=1;cmp_len--)
	{
		// search command 
		for(cmd_no=0;cmd_list[cmd_no].name;cmd_no++)
		{
			if( strncmp(cmd,cmd_list[cmd_no].name,cmp_len)==0)
			{
				// found , confrect check
				hit_no = cmd_no++;
#if 0
				for(;cmd_list[cmd_no].name;cmd_no++)
				{
					if( strncmp(cmd,cmd_list[cmd_no].name,cmp_len)==0) return -1;
				}
#endif
				// OK
				return hit_no;
			}
		}
	}

	return -1;
}

/****************************************************************************
****************************************************************************/
int cmd_main(int argc, char **argv)
{
	int cmd_no;
	int i,j;

	if(argc<=0) return -1;

	// upper convert
	for(i=0;i<argc;i++)
	{
		for(j=0;i<argv[i][j];j++)
			argv[i][j] =toupper(argv[i][j]);
	}

	cmd_no = search_cmd_list(command,argv[0]);
	if(cmd_no>=0)
	{
		printf("CMD[%s]\n",command[cmd_no].name);
		if(command[cmd_no].func==NULL)
		{
			// QUIT command
			return -2;
		}
		// command
		return (command[cmd_no].func)(argc,argv);
	}
	return -1;
}

/****************************************************************************
****************************************************************************/
int ui_main(void)
{
	int cmd_argc;
	char *cmd_argv[16];
	int i;

	// show registers
	// disp_regs();

	while(1)
	{
		// prompt
		printf(strPrompt);
		fflush(stdout);
		// line input
		if( fgets(cmd_line, sizeof(cmd_line), stdin) )
		{
			// upper convert
			for(i=0;i<cmd_line[i];i++)
				cmd_line[i] = toupper(cmd_line[i]);
			// token
			cmd_argc=0;
			cmd_argv[cmd_argc] = strtok(cmd_line, " ,\n");

			while(cmd_argv[cmd_argc])
			{
				cmd_argv[++cmd_argc] = strtok(NULL," ,\n");
			}
			// execute comamnnd
			if( cmd_main(cmd_argc,cmd_argv) <= -2) break;
		}
	}

	return 1;
}

/****************************************************************************
Entry Point
****************************************************************************/
int main(int argc, char **argv, char **env) 
{
	// title message
	appResult = 0;
	
	printf("%s\n%s\n",app_name,app_version);
	fflush(stdout);

	// reset cycle
	if(argc>2)
	{
		cmd_main(argc-1,argv+1);
	}
	else
	{
		ui_main();
	}
	// finalzie
	exit(appResult);
}
