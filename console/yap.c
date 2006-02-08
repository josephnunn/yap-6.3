/*************************************************************************
*									 *
*	 Yap Prolog 							 *
*									 *
*	Yap Prolog Was Developed At Nccup - Universidade Do Porto	 *
*									 *
* Copyright L.Damas, V.S.Costa And Universidade Do Porto 1985-1997	 *
*									 *
**************************************************************************
*									 *
* File:		Yap.C							 *
* Last Rev:								 *
* Mods:									 *
* Comments:	Yap's Main File						 *
*									 *
*************************************************************************/
/* static char SccsId[] = "X 4.3.3"; */

#include "config.h"
#include "YapInterface.h"

#ifdef CUT_C
#include "cut_c.h"
#endif


#if (DefTrailSpace < MinTrailSpace)
#undef DefTrailSpace
#define DefTrailSpace	MinTrailSpace
#endif

#if (DefStackSpace < MinStackSpace)
#undef DefStackSpace
#define DefStackSpace	MinStackSpace
#endif

#if (DefHeapSpace < MinHeapSpace)
#undef DefHeapSpace
#define DefHeapSpace	MinHeapSpace
#endif

#define DEFAULT_NUMBERWORKERS       1
#define DEFAULT_SCHEDULERLOOP      10
#define DEFAULT_DELAYEDRELEASELOAD  3

#ifdef _MSC_VER /* Microsoft's Visual C++ Compiler */
#ifdef  HAVE_UNISTD_H
#undef  HAVE_UNISTD_H
#endif
#endif

#include <stdio.h>
#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#if HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#if HAVE_FCNTL_H
#include <fcntl.h>
#endif
#if HAVE_STDARG_H
#include <stdarg.h>
#endif
#include <stdlib.h>
#if HAVE_UNISTD_H
#include <unistd.h>
#endif
#if HAVE_ERRNO_H
#include <errno.h>
#endif
#if HAVE_STRING_H
#include <string.h>
#endif

static int  PROTO(mygetc, (void));
static void PROTO(do_bootfile, (char *));
static void PROTO(do_top_goal,(YAP_Term));
static void PROTO(exec_top_level,(int, YAP_init_args *));

#ifndef LIGHT
void PROTO (exit, (int));
#endif

#ifdef LIGHT
#include <unix.h>
int
  _main (int, char **);
#else
int PROTO (main, (int, char **));
#endif

#ifdef DEBUG
static int output_msg;
#endif

static char BootFile[] = "boot.yap";
static char InitFile[] = "init.yap";

#ifdef lint
/* VARARGS1 */
#endif

#ifdef M_WILLIAMS
long _stksize = 32000;
#endif

static FILE *bootfile;

static int eof_found = FALSE;
static int yap_lineno = 0;

/* nf: Begin preprocessor code */
#define MAXDEFS 100
static char *def_var[MAXDEFS];
static char *def_value[MAXDEFS];
static int  def_c=0;
/* End preprocessor code */


#if USE_MYPUTC
static void
myputc (int ch)
{
  putc(ch,stderr);
}
#endif

static int
mygetc (void)
{
  int ch;
  if (eof_found)
    return (EOF);
  ch = getc (bootfile);
  if (ch == EOF)
    eof_found = TRUE;
  if (ch == '\n') {
#ifdef MPW
    ch = 10;
#endif
    yap_lineno++;
  }
  return (ch);
}

static void
do_top_goal (YAP_Term Goal)
{
#ifdef DEBUG
  if (output_msg)
    fprintf(stderr,"Entering absmi\n");
#endif
  /* PlPutc(0,'a'); PlPutc(0,'\n'); */
  YAP_RunGoal(Goal);
}

/* do initial boot by consulting the file boot.yap */
static void
do_bootfile (char *bootfilename)
{
  YAP_Term t;
  YAP_Term term_nil = YAP_MkAtomTerm(YAP_LookupAtom("[]"));
  YAP_Term term_end_of_file = YAP_MkAtomTerm(YAP_LookupAtom("end_of_file"));
  YAP_Term term_true = YAP_MkAtomTerm(YAP_LookupAtom("true"));
  YAP_Functor functor_query = YAP_MkFunctor(YAP_LookupAtom("?-"),1);


  /* consult boot.pl */
  bootfile = fopen (bootfilename, "r");
  if (bootfile == NULL)
    {
      fprintf(stderr, "[ FATAL ERROR: could not open bootfile %s ]\n", bootfilename);
      exit(1);
    }
  /* the consult mode does not matter here, really */
  /*
    To be honest, YAP_InitConsult does not really do much,
    it's here for the future. It also makes what we want to do clearer.
  */
  YAP_InitConsult(YAP_CONSULT_MODE,bootfilename);
  while (!eof_found)
    {
      t = YAP_Read(mygetc);
      if (eof_found) {
	break;
      }
      if (t == 0)
        {
	  fprintf(stderr, "[ SYNTAX ERROR: while parsing bootfile %s at line %d ]\n", bootfilename, yap_lineno);
	  exit(1);
        }
      if (YAP_IsVarTerm (t) || t == term_nil)
	{
	  continue;
	}
      else if (t == term_true)
	{
	  YAP_Exit(0);
	}
      else if (t == term_end_of_file)
	{
	  break;
	}
      else if (YAP_IsPairTerm (t))
        {
	  fprintf(stderr, "[ SYSTEM ERROR: consult not allowed in boot file ]\n");
	  fprintf(stderr, "error found at line %d and pos %d", yap_lineno, fseek(bootfile,0L,SEEK_CUR));
	}
      else if (YAP_IsApplTerm (t) && YAP_FunctorOfTerm (t) == functor_query) 
	{ 
	  do_top_goal(YAP_ArgOfTerm (1, t));
        }
      else
	{
	  char *ErrorMessage = YAP_CompileClause(t);
	  if (ErrorMessage)
	    fprintf(stderr, ErrorMessage);
	}
      /* do backtrack */
      YAP_Reset();
    }
  YAP_EndConsult();
  fclose (bootfile);
#ifdef DEBUG
  if (output_msg)
    fprintf(stderr,"Boot loaded\n");
#endif
}

static void
print_usage(void)
{
  fprintf(stderr,"\n[ Valid switches for command line arguments: ]\n");
  fprintf(stderr,"  -?   Shows this screen\n");
  fprintf(stderr,"  -b   Boot file \n");
  fprintf(stderr,"  -g   Run Goal Before Top-Level \n");
  fprintf(stderr,"  -z   Run Goal Before Top-Level \n");
  fprintf(stderr,"  -l   load Prolog file\n");
  fprintf(stderr,"  -L   run Prolog file and exit\n");
  fprintf(stderr,"  -p   extra path for file-search-path\n");
  fprintf(stderr,"  -h   Heap area in Kbytes (default: %d, minimum: %d)\n",
	  DefHeapSpace, MinHeapSpace);
  fprintf(stderr,"  -s   Stack area in Kbytes (default: %d, minimum: %d)\n",
	  DefStackSpace, MinStackSpace);
  fprintf(stderr,"  -t   Trail area in Kbytes (default: %d, minimum: %d)\n",
	  DefTrailSpace, MinTrailSpace);
#ifdef TABLING
  fprintf(stderr,"  -ts  Maximum table space area in Mbytes (default: unlimited)\n");
#endif /* TABLING */
#ifdef YAPOR
  fprintf(stderr,"  -w   Number of workers (default: %d)\n",
	  DEFAULT_NUMBERWORKERS);
  fprintf(stderr,"  -sl  Loop scheduler executions before look for hiden shared work (default: %d)\n", 
          DEFAULT_SCHEDULERLOOP);
  fprintf(stderr,"  -d   Value of delayed release of load (default: %d)\n",
	  DEFAULT_DELAYEDRELEASELOAD);
  /* nf: Preprocessor */		
  fprintf(stderr,"  -DVar=Name : persistent definition\n");
#endif /* YAPOR */
  fprintf(stderr,"\n");
}

/*
 * proccess command line arguments: valid switches are: -b    boot -s
 * stack area size (K) -h    heap area size -a    aux stack size -e
 * emacs_mode -m  -DVar=Value  reserved memory for alloc IF DEBUG -p    if you
 * want to check out startup IF MAC -mpw  if we are using the mpw
 * shell
 */

static int
parse_yap_arguments(int argc, char *argv[], YAP_init_args *iap)
{
  char *p;
#if USE_SYSTEM_MALLOC
  int BootMode = YAP_FULL_BOOT_FROM_PROLOG;
#else
  int BootMode = YAP_BOOT_FROM_SAVED_CODE;
#endif
#ifdef MYDDAS_MYSQL
  char *myddas_temp;
#endif
  int *ssize;
  while (--argc > 0)
    {
      p = *++argv;
      if (*p == '-')
	switch (*++p)
	  {
	  case 'b':
	    BootMode = YAP_BOOT_FROM_PROLOG;
	    iap->YapPrologBootFile = *++argv;
	    argc--;
	    break;
          case '?':
	    print_usage();
            exit(EXIT_SUCCESS);
	  case 'w':
	    ssize = &(iap->NumberWorkers);
	    goto GetSize;
          case 'd':
            ssize = &(iap->DelayedReleaseLoad);
	    goto GetSize;
#ifdef USE_SOCKET
          case 'c':          /* running as client */
	    {
	      char *host, *p1;
	      long port;
	      char *ptr;

	      host = *++argv;
	      argc--;
	      if (host == NULL || host[0] == '-')
		YAP_Error(0,0L,"sockets must receive host to connect to");
	      p1 = *++argv;
	      argc--;
	      if (p1 == NULL || p1[0] == '-')
		YAP_Error(0,0L,"sockets must receive port to connect to");
	      port = strtol(p1, &ptr, 10);
	      if (ptr == NULL || ptr[0] != '\0')
		YAP_Error(0,0L,"port argument to socket must be a number");
	      YAP_InitSocks(host,port);
	    }
	    break;
#endif
#ifdef EMACS
	  case 'e':
	    emacs_mode = TRUE;
	    {
	      File fd;
	      strcpy (emacs_tmp, ++p);
	      if ((fd = fopen (emacs_tmp, "w")) == NIL)
		fprintf(stderr, "[ Warning: unable to communicate with emacs: failed to open %s ]\n", emacs_tmp);
	      fclose (fd);
	      unlink (emacs_tmp);
	      p = *++argv;
	      --argc;
	      strcpy (emacs_tmp2, p);
	      if ((fd = fopen (emacs_tmp2, "w")) == NIL)
		fprintf(stderr, "Unable to communicate with emacs: failed to open %s\n", emacs_tmp2);
	      fclose (fd);
	      unlink (emacs_tmp2);
	    }
	    break;
#endif /* EMACS */
	  case 'f':
	    iap->FastBoot = TRUE;
	    break;
#ifdef MYDDAS_MYSQL 
	  case 'm':
	    if (strncmp(p,"myddas_",7) == 0)
	      {
		iap->myddas = 1;
		if ((*argv)[0] == '\0') 
		  myddas_temp = *argv;
		else {
		  argc--;
		  if (argc == 0) {
		    fprintf(stderr," [ YAP unrecoverable error: missing file name with option 'l' ]\n");
		    exit(EXIT_FAILURE);
		  }
		  argv++;
		  myddas_temp = *argv;
		}
		
		if (strstr(p,"user") != NULL)
		  iap->myddas_user = myddas_temp;
		else if (strstr(p,"pass") != NULL)
		  iap->myddas_pass = myddas_temp;
		else if (strstr(p,"db") != NULL)
		  iap->myddas_db = myddas_temp;
		else if (strstr(p,"host") != NULL)
		  iap->myddas_host = myddas_temp;
		else
		  goto myddas_error_print;
		break;
	      }
#endif
#ifdef MPWSHELL
	  case 'm':
	    if (*++p == 'p' && *++p == 'w' && *++p == '\0')
	      mpwshell = TRUE;
	    break;
#endif
	  case 's':
	  case 'S':
	    ssize = &(iap->StackSize);
	    if (p[1] == 'l') {
	      p++;
	      ssize = &(iap->SchedulerLoop);
	    }
	    goto GetSize;
	  case 'h':
	  case 'H':
	    ssize = &(iap->HeapSize);
	    goto GetSize;
	  case 't':
	  case 'T':
	    ssize = &(iap->TrailSize);
	    if (p[1] == 's') {
	      p++;
	      ssize = &(iap->MaxTableSpaceSize);
	    }
	  GetSize:
	    if (*++p == '\0')
	      {
		if (argc > 1)
		  --argc, p = *++argv;
		else
		  {
		    fprintf(stderr,"[ YAP unrecoverable error: missing size in flag %s ]", argv[0]);
		    print_usage();
		    exit(EXIT_FAILURE);
		  }
	      }
	    {
	      int i = 0, ch;
	      while ((ch = *p++) >= '0' && ch <= '9')
		i = i * 10 + ch - '0';
	      if (ch)
		{
		  fprintf(stderr,"[ YAP unrecoverable error: illegal size specification %s ]", argv[-1]);
		  YAP_Exit(1);
		}
	      *ssize = i;
	    }
	    break;
#ifdef DEBUG
	  case 'P':
	    YAP_SetOutputMessage();
	    output_msg = TRUE;
	    break;
#endif
	  case 'L':
           p++;
           iap->HaltAfterConsult = TRUE;
           if (*p != '\0') {
             iap->YapPrologRCFile = p;
             break;
           } else {
             if (--argc == 0) {
               fprintf(stderr,
                       " [ YAP unrecoverable error: missing file name with option 'L' ]\n");
               exit(1);
             }
             p = *++argv;
             if (p[0] == '-' && p[1] == '-' && p[2] == '\0') {
               if (--argc == 0) {
                 fprintf(stderr,
                         " [ YAP unrecoverable error: missing filename with option 'L' ]\n");
                 exit(1);
               }
               p = *++argv;
               iap->YapPrologRCFile = p;
               argc = 1;

             } else {
               iap->YapPrologRCFile = p;
             }
           }
           break;
	  case 'l':
	    if ((*argv)[0] == '\0') 
	      iap->YapPrologRCFile = *argv;
	    else {
	      argc--;
	      if (argc == 0) {
		fprintf(stderr," [ YAP unrecoverable error: missing file name with option 'l' ]\n");
		exit(EXIT_FAILURE);
	      }
	      argv++;
	      iap->YapPrologRCFile = *argv;
	    }
	    break;
	    /* run goal before top-level */
	  case 'g':
	    if ((*argv)[0] == '\0') 
	      iap->YapPrologGoal = *argv;
	    else {
	      argc--;
	      if (argc == 0) {
		fprintf(stderr," [ YAP unrecoverable error: missing initialization goal for option 'g' ]\n");
		exit(EXIT_FAILURE);
	      }
	      argv++;
	      iap->YapPrologGoal = *argv;
	    }
	    break;
	    /* run goal as top-level */
	  case 'z':
	    if ((*argv)[0] == '\0') 
	      iap->YapPrologTopLevelGoal = *argv;
	    else {
	      argc--;
	      if (argc == 0) {
		fprintf(stderr," [ YAP unrecoverable error: missing goal for option 'z' ]\n");
		exit(EXIT_FAILURE);
	      }
	      argv++;
	      iap->YapPrologTopLevelGoal = *argv;
	    }
	    break;
	  case 'p':
	    if ((*argv)[0] == '\0') 
	      iap->YapPrologAddPath = *argv;
	    else {
	      argc--;
	      if (argc == 0) {
		fprintf(stderr," [ YAP unrecoverable error: missing paths for option 'p' ]\n");
		exit(EXIT_FAILURE);
	      }
	      argv++;
	      iap->YapPrologAddPath = *argv;
	    }
	    break;
	    /* nf: Begin preprocessor code */
	  case 'D':
	    {
	      char *var, *value;
	      ++p;
	      var = p;	      
	      if (var == NULL || *var=='\0')
		break;
	      while(*p!='='  && *p!='\0') ++p;
	      if ( *p=='\0' ) break;
	      *p='\0';
	      ++p;
	      value=p;
	      if ( *value == '\0' ) break;
	      //
	      ++def_c;
	      def_var[def_c-1]=var;
	      def_value[def_c-1]=value;
	      //printf("var=value--->%s=%s\n",var,value); 
	      break;
	    }
	    /* End preprocessor code */
	  case '-':
	    /* skip remaining arguments */
	    argc = 1;
	    break;
	  default:
	    {
#ifdef MYDDAS_MYSQL
	    myddas_error_print :
#endif
	      fprintf(stderr,"[ YAP unrecoverable error: unknown switch -%c ]\n", *p);
#ifdef MYDDAS_MYSQL
	    myddas_error :
#endif
	      print_usage();
	      exit(EXIT_FAILURE);
	    }
	  }
      else {
	iap->SavedState = p;
      }
    }
#ifdef MYDDAS_MYSQL
  /* Check MYDDAS Arguments */
  if (iap->myddas_user != NULL || iap->myddas_pass != NULL
      || iap->myddas_db != NULL || iap->myddas_host != NULL)
    if (iap->myddas_user == NULL || iap->myddas_db == NULL){
      fprintf(stderr,"[ YAP unrecoverable error: Missing Mandatory Arguments for MYDDAS ]\n");
      goto myddas_error;
    }
#endif
  return(BootMode);
}

static char boot_file[256];

static int
init_standard_system(int argc, char *argv[], YAP_init_args *iap)
{
  int BootMode;

  iap->SavedState = NULL;
  iap->HeapSize = 0;
  iap->StackSize = 0;
  iap->TrailSize = 0;
  iap->YapLibDir = NULL;
  iap->YapPrologBootFile = NULL;
  iap->YapPrologInitFile = NULL;
  iap->YapPrologRCFile = NULL;
  iap->YapPrologGoal = NULL;
  iap->YapPrologTopLevelGoal = NULL;
  iap->YapPrologAddPath = NULL;
  iap->HaltAfterConsult = FALSE;
  iap->FastBoot = FALSE;
  iap->MaxTableSpaceSize = 0;
  iap->NumberWorkers = DEFAULT_NUMBERWORKERS;
  iap->SchedulerLoop = DEFAULT_SCHEDULERLOOP;
  iap->DelayedReleaseLoad = DEFAULT_DELAYEDRELEASELOAD;
  iap->PrologShouldHandleInterrupts = TRUE;
  iap->Argc = argc;
  iap->Argv = argv;
#ifdef MYDDAS_MYSQL
  iap->myddas = 0;
  iap->myddas_user = NULL;
  iap->myddas_pass = NULL;
  iap->myddas_db = NULL;
  iap->myddas_host = NULL;
#endif  
  iap->ErrorNo = 0;
  iap->ErrorCause = NULL;

  BootMode = parse_yap_arguments(argc,argv,iap);

  if (BootMode == YAP_FULL_BOOT_FROM_PROLOG) {

#if HAVE_STRNCAT
    strncpy(boot_file, PL_SRC_DIR, 256);
#else
    strcpy(boot_file, PL_SRC_DIR);
#endif
#if HAVE_STRNCAT
    strncat(boot_file, BootFile, 256);
#else
    strcat(boot_file, BootFile);
#endif
    iap->YapPrologBootFile = boot_file;
  }
  /* init memory */
  if (BootMode == YAP_BOOT_FROM_PROLOG ||
      BootMode == YAP_FULL_BOOT_FROM_PROLOG) {
    int NewBootMode = YAP_Init(iap);
    if (NewBootMode != YAP_BOOT_FROM_PROLOG && BootMode != YAP_FULL_BOOT_FROM_PROLOG)
      BootMode = NewBootMode;
  } else {
    BootMode = YAP_Init(iap);
  }
  if (iap->ErrorNo) {
    /* boot failed */
    YAP_Error(iap->ErrorNo,0L,iap->ErrorCause);
  }
  return BootMode;
}


static void
exec_top_level(int BootMode, YAP_init_args *iap)
{
  YAP_Term atomfalse;
  YAP_Atom livegoal;

  if (BootMode == YAP_BOOT_FROM_SAVED_STACKS)
    {
      /* continue executing from the frozen stacks */
      YAP_ContinueGoal();
    }
  else if (BootMode == YAP_BOOT_FROM_PROLOG ||
	   BootMode == YAP_FULL_BOOT_FROM_PROLOG)
    {
      YAP_Atom livegoal;
      /* read the bootfile */
      do_bootfile (iap->YapPrologBootFile ? iap->YapPrologBootFile : BootFile);
      livegoal = YAP_FullLookupAtom("$live");
      /* initialise the top-level */
      if (BootMode == YAP_FULL_BOOT_FROM_PROLOG) {
	char init_file[256];
	YAP_Atom atfile;
	YAP_Functor fgoal;
	YAP_Term goal, as[2];

#if HAVE_STRNCAT
	strncpy(init_file, PL_SRC_DIR, 256);
#else
	strcpy(init_file, PL_SRC_DIR);
#endif
#if HAVE_STRNCAT
	strncat(init_file, InitFile, 256);
#else
	strcat(init_file, InitFile);
#endif
	/* consult init file */
	atfile = YAP_LookupAtom(init_file);
	as[0] = YAP_MkAtomTerm(atfile);
	fgoal = YAP_MkFunctor(YAP_FullLookupAtom("$silent_bootstrap"), 1);
	goal = YAP_MkApplTerm(fgoal, 1, as);
	/* launch consult */
	YAP_RunGoal(goal);
	/* set default module to user */
	as[0] = YAP_MkAtomTerm(YAP_LookupAtom("user"));
	fgoal = YAP_MkFunctor(YAP_FullLookupAtom("module"), 1);
	goal = YAP_MkApplTerm(fgoal, 1, as);
	YAP_RunGoal(goal);
      }
      YAP_PutValue(livegoal, YAP_MkAtomTerm (YAP_FullLookupAtom("$true")));
      
    }
      /* the top-level is now ready */

  /* read it before case someone, that is, Ashwin, hides
     the atom false away ;-).
  */
  livegoal = YAP_FullLookupAtom("$live");
  atomfalse = YAP_MkAtomTerm (YAP_FullLookupAtom("$false"));
  while (YAP_GetValue (livegoal) != atomfalse) {
    YAP_Reset();
    do_top_goal (YAP_MkAtomTerm (livegoal));
  }
  YAP_Exit(EXIT_SUCCESS);
}

#ifdef LIGHT
int
_main (int argc, char **argv)
#else
int
main (int argc, char **argv)
#endif
{
  int BootMode;
  YAP_init_args init_args;
  int i;


  BootMode = init_standard_system(argc, argv, &init_args);
  if (BootMode == YAP_BOOT_ERROR) {
    fprintf(stderr,"[ FATAL ERROR: could not find saved state ]\n");
    exit(1);
  }
  /* Begin preprocessor code */
  {
    // load the module
    YAP_Term mod_arg[1];
    mod_arg[0] = YAP_MkAtomTerm(YAP_LookupAtom("ypp"));
    YAP_RunGoal(YAP_MkApplTerm(YAP_MkFunctor(YAP_LookupAtom("use_module"),1), 1, mod_arg)); 
    // process the definitions
    for(i=0;i<def_c;++i) {
      YAP_Term t_args[2],t_goal;
      t_args[0] = YAP_MkAtomTerm(YAP_LookupAtom(def_var[i]));
      t_args[1] = YAP_MkAtomTerm(YAP_LookupAtom(def_value[i])); 
      t_goal  = YAP_MkApplTerm(YAP_MkFunctor(YAP_LookupAtom("ypp_define"),2), 2, t_args); 
      YAP_RunGoal(t_goal);
    }
  }
  YAP_ClearExceptions();
  /* End preprocessor code */

  exec_top_level(BootMode, &init_args);

  return(0);
}

