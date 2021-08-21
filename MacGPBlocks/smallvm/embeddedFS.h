// embeddedFS.h
// John Maloney, April, 2016

OBJ appPath();
OBJ embeddedFileList(FILE *f);
OBJ extractEmbeddedFile(FILE *f, char *fileName, int isBinary);
gp_boolean importLibrary();
FILE * openAppFile();

// Returns a slash ended path to the runtime library.
// Default path cat be altered with ENV variable GP_RUNTIME_DIR.
// On macOS the default path is in app's Resources
int getPathToRuntimeLibrary(char *path, int pathSize);


