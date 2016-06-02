#import "MovieNPObject.h"

#import <QTKit/QTKit.h>
#import <WebKit/npfunctions.h>

extern NPNetscapeFuncs* browser;


typedef struct {
    // Put the NPObject first so that casting from an NPObject to a 
    // MovieNPObject works as expected.
    NPObject npObject;

    QTMovie *movie;
} MovieNPObject;

enum {
    ID_PLAY,
    ID_PAUSE,
    NUM_METHOD_IDENTIFIERS
};

static NPIdentifier methodIdentifiers[NUM_METHOD_IDENTIFIERS];
static const NPUTF8 *methodIdentifierNames[NUM_METHOD_IDENTIFIERS] = {
    "play",
    "pause",
};

static void initializeIdentifiers(void)
{
    static bool identifiersInitialized;
    if (identifiersInitialized)
        return;

    // Take all method identifier names and convert them to NPIdentifiers.
    browser->getstringidentifiers(methodIdentifierNames, NUM_METHOD_IDENTIFIERS, methodIdentifiers);
    identifiersInitialized = true;
}

static NPObject *movieNPObjectAllocate(NPP npp, NPClass* theClass)
{
    initializeIdentifiers();

    MovieNPObject *movieNPObject = malloc(sizeof(MovieNPObject));
    movieNPObject->movie = 0;

    return (NPObject *)movieNPObject;
}

static void movieNPObjectDeallocate(NPObject *npObject)
{
    MovieNPObject *movieNPObject = (MovieNPObject *)npObject;

    // Release the QTMovie object that this NPObject wraps.
    [movieNPObject->movie release];

    // Free the NPObject memory.
    free(movieNPObject);
}

static bool movieNPObjectHasMethod(NPObject *obj, NPIdentifier name)
{
    // Loop over all the method NPIdentifiers and see if we expose the given method.
    for (int i = 0; i < NUM_METHOD_IDENTIFIERS; i++) {
        if (name == methodIdentifiers[i])
            return true;
    }

    return false;
}

static bool movieNPObjectInvoke(NPObject *npObject, NPIdentifier name, const NPVariant* args, uint32_t argCount, NPVariant* result)
{
    MovieNPObject *movieNPObject = (MovieNPObject *)npObject;

    if (name == methodIdentifiers[ID_PLAY]) {
        [movieNPObject->movie play];
        return true;
    }

    if (name == methodIdentifiers[ID_PAUSE]) {
        [movieNPObject->movie stop];
        return true;
    }

    return false;
}

static NPClass movieNPClass = {
    NP_CLASS_STRUCT_VERSION,
    movieNPObjectAllocate, // NP_Allocate
    movieNPObjectDeallocate, // NP_Deallocate
    0, // NP_Invalidate
    movieNPObjectHasMethod, // NP_HasMethod
    movieNPObjectInvoke, // NP_Invoke
    0, // NP_InvokeDefault
    0, // NP_HasProperty
    0, // NP_GetProperty
    0, // NP_SetProperty
    0, // NP_RemoveProperty
    0, // NP_Enumerate
    0, // NP_Construct
};

NPObject *createMovieNPObject(NPP npp, QTMovie *movie)
{
    MovieNPObject *movieNPObject = (MovieNPObject *)browser->createobject(npp, &movieNPClass);

    movieNPObject->movie = [movie retain];

    return (NPObject *)movieNPObject;
}
