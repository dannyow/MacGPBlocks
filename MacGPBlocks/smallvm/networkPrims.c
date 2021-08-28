//
// networkPrims.c
// Primitives for network communication.
// Created by Daniel Owsiański on 26/08/2021.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h> /* assert() */

#include <curl/curl.h>

#include "mem.h"
#include "interp.h"

/*
 Test files:
 * Very large (26M) https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json
 * Large (660k) https://data.cityofnewyork.us/api/views/82rt-zc4y/rows.json
 */

static CURLM *curlMultiHandle = NULL;
#define MAX_PARALLEL 10 /* number of simultaneous transfers */

typedef enum { IN_PROGRESS,
               DONE,
               FAILED,
               CANCELLED } FetchStatus;

typedef struct {
    int id;
    FetchStatus status;
    int byteCount;
    char *data;
} FetchRequest;

#define MAX_REQUESTS 100
FetchRequest requests[MAX_REQUESTS];

static int nextFetchID = 100;

size_t fetchWriteDataCallback(void *buffer, size_t size, size_t nmemb, void *userData) {
    size_t realSize = size * nmemb;
    FetchRequest *request = (FetchRequest *)userData;

    char *ptr = realloc(request->data, request->byteCount + realSize + 1);
    if (!ptr) {
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

static int indexOfRequestWithID(int requestID) {
    int i;
    for (i = 0; i < MAX_REQUESTS; i++) {
        if (requests[i].id == requestID) break;
    }
    return (i >= MAX_REQUESTS) ? -1 : i;
}

static void cleanupRequestAtIndex(int index) {
    if (index < 0 || index > MAX_REQUESTS) return;

    // mark request as free and free the request data, if any
    requests[index].id = 0;
    if (requests[index].data) {
        free(requests[index].data);
    }
    requests[index].data = NULL;
    requests[index].byteCount = 0;
}

static void processRequestQueue() {
    int stillAlive = 1;
    int messagesLeft = -1;
    CURLMsg *msg = NULL;

    if (!curlMultiHandle) {
        return;
    }

    curl_multi_perform(curlMultiHandle, &stillAlive);
    while ((msg = curl_multi_info_read(curlMultiHandle, &messagesLeft))) {
        if (msg->msg == CURLMSG_DONE) {
            int requestID;

            CURLcode msgCode = msg->data.result;
            CURL *curl = msg->easy_handle;
            curl_easy_getinfo(curl, CURLINFO_PRIVATE, &requestID);

            int requestIndex = indexOfRequestWithID(requestID);
            if (requestIndex > -1) {
                assert(CANCELLED == requests[requestIndex].status || IN_PROGRESS == requests[requestIndex].status);

                if (CANCELLED == requests[requestIndex].status) {
                    cleanupRequestAtIndex(requestIndex);
                } else if (msgCode == CURLE_OK) {
                    requests[requestIndex].status = DONE;
                } else {
                    printf("error on requestID: %d %s\n", requestID, curl_easy_strerror(msgCode));
                    requests[requestIndex].status = FAILED;
                }
            }

            curl_multi_remove_handle(curlMultiHandle, curl);
            curl_easy_cleanup(curl);
        }
    }
}

static OBJ primStartRequest(int nargs, OBJ args[]) {
    if (nargs < 1) return notEnoughArgsFailure();
    OBJ url = args[0];
    if (NOT_CLASS(url, StringClass)) return primFailed("First argument must be a string");

    if (curlMultiHandle == NULL) {
        curl_global_init(CURL_GLOBAL_ALL);
        curlMultiHandle = curl_multi_init();

        if (!curlMultiHandle) {
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
    if (i >= MAX_REQUESTS) return nilObj;  // no free request slots (unlikely)

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

// Returns a BinaryData object on success, false on failure, and nil when fetch is still in progress.
static OBJ primFetchRequestResult(int nargs, OBJ args[]) {
    // https://stackoverflow.com/questions/43662072/anyway-to-avoid-to-loop-monitor-multi-handle-in-libcurl
    //  https://stackoverflow.com/questions/48644383/libcurl-progress-callback-not-working-with-multi
    // https://stackoverflow.com/questions/24413806/libuv-event-loop-and-libcurl

    // First process requests from libcurl queue
    processRequestQueue();

    if (nargs < 1) return notEnoughArgsFailure();
    if (!isInt(args[0])) return primFailed("Expected integer");
    int id = obj2int(args[0]);

    // find the fetch request with the given id
    int i = indexOfRequestWithID(id);
    if (i < 0) return falseObj;  // could not find request with id; report as failure

    OBJ result = nilObj;
    if (IN_PROGRESS == requests[i].status) {
        return result;
    }

    result = falseObj;

    if (DONE == requests[i].status && requests[i].data) {
        // allocate result object
        int byteCount = requests[i].byteCount;
        result = newBinaryData(byteCount);
        if (result) {
            memmove(&FIELD(result, 0), requests[i].data, byteCount);
        } else {
            printf("Insufficient memory for requested file (%ul bytes needed); skipping.\n", byteCount);
        }
    }

    cleanupRequestAtIndex(i);
    return result;
}

static OBJ primCancelRequest(int nargs, OBJ args[]) {
    if (nargs < 1) return notEnoughArgsFailure();
    if (!isInt(args[0])) return primFailed("Expected integer");
    int id = obj2int(args[0]);

    // find the fetch request with the given id
    int i = indexOfRequestWithID(id);
    if (i < 0) return nilObj;

    printf("🔴 primCancelRequest with ID: %d (%d)\n", id, i);
    if (IN_PROGRESS == requests[i].status) {
        requests[i].status = CANCELLED;
    } else {
        printf("?? can't cancel a request that is not in progress (%d), requestID: %d (%d)\n", requests[i].status, id, i);
    }

    processRequestQueue();
    return nilObj;
}

static PrimEntry networkPrimList[] = {
    {"-----", NULL, "Network: HTTP/HTTPS"},
    {"startRequest", primStartRequest, "Start downloading the contents of a URL. Return an id that can be used to get the result. Argument: urlString"},
    {"fetchRequestResult", primFetchRequestResult, "Return the result of the fetch operation with the given id: a BinaryData object (success), false (failure), or nil if in progress. Argument: id"},
    {"cancelRequest", primCancelRequest, "Cancel the request with the given id. Argument: id"},
};

PrimEntry *networkPrimitives(int *primCount) {
    *primCount = sizeof(networkPrimList) / sizeof(PrimEntry);
    return networkPrimList;
}
