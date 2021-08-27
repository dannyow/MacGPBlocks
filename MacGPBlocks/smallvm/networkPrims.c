//
// networkPrims.c
// Primitives for network communication.
// Created by Daniel Owsiański on 26/08/2021.
//   

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <curl/curl.h>

#include "mem.h"
#include "interp.h"


static CURLM *curlMultiHandle = NULL;
#define MAX_PARALLEL 10 /* number of simultaneous transfers */

typedef enum {IN_PROGRESS, DONE, FAILED} FetchStatus;

typedef struct {
    int id;
    FetchStatus status;
    int byteCount;
    char *data;
} FetchRequest;

#define MAX_REQUESTS 1000
FetchRequest requests[MAX_REQUESTS];

static int nextFetchID = 100;

size_t fetchWriteDataCallback(void *buffer, size_t size, size_t nmemb, void *userData) {
    size_t realSize = size * nmemb;
    FetchRequest *request = ( FetchRequest *)userData;


    char *ptr = realloc(request->data, request->byteCount + realSize + 1);
    if(!ptr) {
        /* out of memory! */
        printf("not enough memory (realloc returned NULL)\n");
        return 0;
    }

    request->data = ptr;
    memcpy(&(request->data[request->byteCount]), buffer, realSize);
    request->byteCount += realSize;
    request->data[request->byteCount] = 0;


//    printf("*** Data: %ul %ul\n", size, nmemb);

    return realSize;
}

static int findRequestWithID(int requestID){
    int i;
    for (i = 0; i < MAX_REQUESTS; i++) {
        if (requests[i].id == requestID) break;
    }
    return (i >= MAX_REQUESTS) ? -1 : i;
}

static OBJ primStartRequest(int nargs, OBJ args[]) {
    if (nargs < 1) return notEnoughArgsFailure();
    OBJ url = args[0];
    if (NOT_CLASS(url, StringClass)) return primFailed("First argument must be a string");

    if(curlMultiHandle == NULL){
        curl_global_init(CURL_GLOBAL_ALL);
        curlMultiHandle = curl_multi_init();

        if(!curlMultiHandle){
            return primFailed("Could not initate network connection");
        }

        /* Limit the amount of simultaneous connections curl should allow: */
        curl_multi_setopt(curlMultiHandle, CURLMOPT_MAXCONNECTS, (long)MAX_PARALLEL);
    }

    // find an unused request
    int i;

    for (i = 0; i < MAX_REQUESTS; i++) {
        if (!requests[i].id) {
            requests[i].id = nextFetchID++;
            requests[i].status = IN_PROGRESS;
            requests[i].data = NULL;
            requests[i].byteCount = 0;

            break;
        }
    }
    if (i >= MAX_REQUESTS) return nilObj; // no free request slots (unlikely)

    CURL *curl = curl_easy_init();
    if (!curl) {
        return primFailed("Could not initate network connection");
    }

    //https://curl.se/libcurl/c/curl_easy_setopt.html
    curl_easy_setopt(curl, CURLOPT_URL, obj2str(url));

    struct curl_slist *headers = NULL;
    /* Remove a header curl would otherwise add by itself */
    // https://curl.se/libcurl/c/httpcustomheader.html
    // headers = curl_slist_append(headers, "Accept:");
    headers = curl_slist_append(headers, "Accept: application/json");
    headers = curl_slist_append(headers, "Content-Type: application/json; charset=utf-8");
    // headers = curl_slist_append(headers, "Authorization: token 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");

    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    curl_easy_setopt(curl, CURLOPT_URL, obj2str(url));
//    curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);

    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "libcurl-agent/1.0");
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, fetchWriteDataCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&requests[i]);
    curl_easy_setopt(curl, CURLOPT_PRIVATE, requests[i].id);
//    curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS, 1000L);

    curl_multi_add_handle(curlMultiHandle, curl);
    printf("🟢 Request ready to run for URL: %s ID: %d (at: %d)\n", obj2str(url), requests[i].id, i);

    return int2obj(requests[i].id);
}

static OBJ primFetchRequestResult(int nargs, OBJ args[]) {
    // Returns a BinaryData object on success, false on failure, and nil when fetch is still in progress.
    if (nargs < 1) return notEnoughArgsFailure();
    if (!isInt(args[0])) return primFailed("Expected integer");
    int id = obj2int(args[0]);

    // find the fetch request with the given id
    int i = findRequestWithID(id);
    if (i < 0) return falseObj; // could not find request with id; report as failure

    if(!curlMultiHandle){
        return falseObj;
    }

    int stillAlive = 1;
    int messagesLeft = -1;
    CURLMsg *msg = NULL;

    CURLMcode r;

    OBJ result = nilObj;
//    do {

        r = curl_multi_perform(curlMultiHandle, &stillAlive);
//    printf("🟨 code: %d (%s)", r, curl_multi_strerror(r));

        while((msg = curl_multi_info_read(curlMultiHandle, &messagesLeft))) {
            if(msg->msg == CURLMSG_DONE) {

                int requestID;
                CURL *curl = msg->easy_handle;
                CURLcode msgCode = (CURLcode)msg->data.result;
                curl_easy_getinfo(curl, CURLINFO_PRIVATE, &requestID);


                long responseCode = 0;
                curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &responseCode);


                printf("🔈 Response: %ld  Error? %d %s\n", responseCode, msg->data.result, curl_easy_strerror(msgCode));


                if(id == (requestID)){
                    int byteCount = requests[i].byteCount;
                    result = newBinaryData(byteCount);
                    if (result) {
                        memmove(&FIELD(result, 0), requests[i].data, byteCount);
                    } else {
                        printf("Insufficient memory for requested file (%ul bytes needed); skipping.\n", byteCount);
                    }

                    // mark request as free and free the request data, if any
                    requests[i].id = 0;
                    if (requests[i].data){
                        free(requests[i].data);
                    }
                    requests[i].status = DONE;
                    requests[i].data = NULL;
                    requests[i].byteCount = 0;
                }else{
                    printf("🟢 Got message but with ID: %d instead of %d\n", requestID, id);
                }

                //            fprintf(stderr, "R: %d - %s <%s>\n",
                //                    msg->data.result, curl_easy_strerror(msg->data.result), url);
                curl_multi_remove_handle(curlMultiHandle, curl);
                curl_easy_cleanup(curl);
            }
            else {
                fprintf(stderr, "🛑E: CURLMsg (%d)\n", msg->msg);
            }

        }
//        if(stillAlive){
//            curl_multi_wait(curlMultiHandle, NULL, 0, 1000, NULL);
//        }
//    } while(stillAlive);

    printf("primFetchRestResult id=%d result is [%s] \n", id, (result == nilObj)?"nil":"not nil");
//    dumpObj(result);
    return result;

    //
    //    if (IN_PROGRESS == requests[i].status) return nilObj; // in progress
    //
    //    OBJ result = falseObj;
    //
    //    if (DONE == requests[i].status && requests[i].data) {
    //        // allocate result object
    //        int byteCount = requests[i].byteCount;
    //        result = newBinaryData(byteCount);
    //        if (result) {
    //            memmove(&FIELD(result, 0), requests[i].data, byteCount);
    //        } else {
    //            printf("Insufficient memory for requested file (%ul bytes needed); skipping.\n", byteCount);
    //        }
    //    }
    //
    //    // mark request as free and free the request data, if any
    //    requests[i].id = 0;
    //    if (requests[i].data) free(requests[i].data);
    //    requests[i].data = NULL;
    //    requests[i].byteCount = 0;
    //
    //    return result;
}

static OBJ primCancelRequest(int nargs, OBJ args[]){
    printf("🔴 primCancelRequest \n");
    // TODO: search for request with the given ID, and set status to CANCELLED? plus free memory if there is any
    return nilObj;
}

static PrimEntry networkPrimList[] = {
    {"-----", NULL, "Network: HTTP/HTTPS"},
    {"startRequest",  primStartRequest,     "Start downloading the contents of a URL. Return an id that can be used to get the result. Argument: urlString"},
    {"fetchRequestResult", primFetchRequestResult,    "Return the result of the fetch operation with the given id: a BinaryData object (success), false (failure), or nil if in progress. Argument: id"},
    {"cancelRequest", primCancelRequest,    "Cancel the request with the given id. Argument: id"},
};

PrimEntry* networkPrimitives(int *primCount) {
    *primCount = sizeof(networkPrimList) / sizeof(PrimEntry);
    return networkPrimList;
}
