/* This is a generated file, edit the .stub.php file instead.
 * Stub hash: d916518d96d537ac4c7b3a460144e63e320a4b49 */

ZEND_BEGIN_ARG_INFO_EX(arginfo_class_Zigrite_World___construct, 0, 0, 1)
	ZEND_ARG_TYPE_INFO(0, path, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(0, options, IS_ARRAY, 0, "[]")
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_isSupported, 0, 0, _IS_BOOL, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_importBedrock, 0, 2, IS_ARRAY, 0)
	ZEND_ARG_TYPE_INFO(0, bedrockWorld, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, destination, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_exportBedrock, 0, 2, IS_ARRAY, 0)
	ZEND_ARG_TYPE_INFO(0, world, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, destination, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_verifyBedrock, 0, 2, IS_ARRAY, 0)
	ZEND_ARG_TYPE_INFO(0, world, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, bedrockWorld, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_verify, 0, 1, IS_ARRAY, 0)
	ZEND_ARG_TYPE_INFO(0, world, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_migrate, 0, 2, IS_ARRAY, 0)
	ZEND_ARG_TYPE_INFO(0, source, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, destination, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_getChunk, 0, 3, IS_ARRAY, 1)
	ZEND_ARG_TYPE_INFO(0, dimension, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, chunkX, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, chunkZ, IS_LONG, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_writeChunk, 0, 4, IS_VOID, 0)
	ZEND_ARG_TYPE_INFO(0, dimension, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, chunkX, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, chunkZ, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, records, IS_ARRAY, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_auxGet, 0, 1, IS_STRING, 1)
	ZEND_ARG_TYPE_INFO(0, key, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_auxPut, 0, 2, IS_VOID, 0)
	ZEND_ARG_TYPE_INFO(0, key, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, value, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_auxDelete, 0, 1, IS_VOID, 0)
	ZEND_ARG_TYPE_INFO(0, key, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_listChunks, 0, 1, IS_ARRAY, 0)
	ZEND_ARG_TYPE_INFO(0, dimension, IS_LONG, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_flush, 0, 0, IS_VOID, 0)
ZEND_END_ARG_INFO()

#define arginfo_class_Zigrite_World_close arginfo_class_Zigrite_World_flush

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_class_Zigrite_World_getStatistics, 0, 0, IS_ARRAY, 0)
ZEND_END_ARG_INFO()

ZEND_METHOD(Zigrite_World, __construct);
ZEND_METHOD(Zigrite_World, isSupported);
ZEND_METHOD(Zigrite_World, importBedrock);
ZEND_METHOD(Zigrite_World, exportBedrock);
ZEND_METHOD(Zigrite_World, verifyBedrock);
ZEND_METHOD(Zigrite_World, verify);
ZEND_METHOD(Zigrite_World, migrate);
ZEND_METHOD(Zigrite_World, getChunk);
ZEND_METHOD(Zigrite_World, writeChunk);
ZEND_METHOD(Zigrite_World, auxGet);
ZEND_METHOD(Zigrite_World, auxPut);
ZEND_METHOD(Zigrite_World, auxDelete);
ZEND_METHOD(Zigrite_World, listChunks);
ZEND_METHOD(Zigrite_World, flush);
ZEND_METHOD(Zigrite_World, close);
ZEND_METHOD(Zigrite_World, getStatistics);

static const zend_function_entry class_Zigrite_World_methods[] = {
	ZEND_ME(Zigrite_World, __construct, arginfo_class_Zigrite_World___construct, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, isSupported, arginfo_class_Zigrite_World_isSupported, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	ZEND_ME(Zigrite_World, importBedrock, arginfo_class_Zigrite_World_importBedrock, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	ZEND_ME(Zigrite_World, exportBedrock, arginfo_class_Zigrite_World_exportBedrock, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	ZEND_ME(Zigrite_World, verifyBedrock, arginfo_class_Zigrite_World_verifyBedrock, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	ZEND_ME(Zigrite_World, verify, arginfo_class_Zigrite_World_verify, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	ZEND_ME(Zigrite_World, migrate, arginfo_class_Zigrite_World_migrate, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	ZEND_ME(Zigrite_World, getChunk, arginfo_class_Zigrite_World_getChunk, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, writeChunk, arginfo_class_Zigrite_World_writeChunk, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, auxGet, arginfo_class_Zigrite_World_auxGet, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, auxPut, arginfo_class_Zigrite_World_auxPut, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, auxDelete, arginfo_class_Zigrite_World_auxDelete, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, listChunks, arginfo_class_Zigrite_World_listChunks, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, flush, arginfo_class_Zigrite_World_flush, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, close, arginfo_class_Zigrite_World_close, ZEND_ACC_PUBLIC)
	ZEND_ME(Zigrite_World, getStatistics, arginfo_class_Zigrite_World_getStatistics, ZEND_ACC_PUBLIC)
	ZEND_FE_END
};

static zend_class_entry *register_class_Zigrite_Exception(zend_class_entry *class_entry_RuntimeException)
{
	zend_class_entry ce, *class_entry;

	INIT_NS_CLASS_ENTRY(ce, "Zigrite", "Exception", NULL);
	class_entry = zend_register_internal_class_with_flags(&ce, class_entry_RuntimeException, 0);

	return class_entry;
}

static zend_class_entry *register_class_Zigrite_World(void)
{
	zend_class_entry ce, *class_entry;

	INIT_NS_CLASS_ENTRY(ce, "Zigrite", "World", class_Zigrite_World_methods);
	class_entry = zend_register_internal_class_with_flags(&ce, NULL, ZEND_ACC_FINAL|ZEND_ACC_NO_DYNAMIC_PROPERTIES|ZEND_ACC_NOT_SERIALIZABLE);

	return class_entry;
}
