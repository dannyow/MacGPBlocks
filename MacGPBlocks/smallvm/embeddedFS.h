// embeddedFS.h
// John Maloney, April, 2016

OBJ appPath();
OBJ embeddedFileList(FILE *f);
OBJ extractEmbeddedFile(FILE *f, char *fileName, int isBinary);
gp_boolean importLibrary();
FILE * openAppFile();


// Copy the full path for the application (up to pathSize - 1 bytes) into path.
// Return true on success.
int getAppPath(char *path, int pathSize);
