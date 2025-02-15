#include <Python.h>


#if PY_MAJOR_VERSION < 3
# define MODINIT(name)  init ## name
#else
# define MODINIT(name)  PyInit_ ## name
#endif

//PyMODINIT_FUNC MODINIT(primes) (void);
extern "C"  PyObject * PyInit__imgui_bundle();

bool init_modules() {
    static struct _inittab builtin_modules[] = {
        {"_imgui_bundle", PyInit__imgui_bundle},  // Register imgui module
        {NULL, NULL}
    };
    return PyImport_ExtendInittab(builtin_modules)==0;
}
 